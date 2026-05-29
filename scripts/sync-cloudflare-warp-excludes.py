#!/usr/bin/env python3
import argparse
import dataclasses
import datetime
import ipaddress
import json
import os
import pathlib
import sys
import typing
import urllib.error
import urllib.request


MANAGED_PREFIX = "managed:"
SUPPORTED_MANAGED_PROVIDERS = {"github", "tailscale"}
CLOUDFLARE_API_BASE = "https://api.cloudflare.com/client/v4"
GITHUB_META_URL = "https://api.github.com/meta"
TAILSCALE_DERP_MAP_URL = "https://controlplane.tailscale.com/derpmap/default"
DEFAULT_STATE_DIR = "cloudflare-warp-excludes"

TAILSCALE_RESERVED_RANGES = (
    "100.64.0.0/10",
    "fd7a:115c:a1e0::/48",
)

TAILSCALE_CONTROL_HOSTS = (
    "console.tailscale.com",
    "controlplane.tailscale.com",
    "login.tailscale.com",
    "log.tailscale.com",
    "*.tailscale.com",
    "*.ts.net",
)

GITHUB_STATIC_HOSTS = (
    "github.com",
    "*.github.com",
    "*.githubusercontent.com",
    "*.githubassets.com",
    "ghcr.io",
    "*.pkg.github.com",
)

GITHUB_IP_CATEGORIES = (
    "web",
    "api",
    "git",
    "packages",
)

class SyncError(Exception):
    pass


@dataclasses.dataclass(frozen=True, order=True)
class SplitTunnelEntry:
    entry_type: str
    value: str
    description: str

    def __post_init__(self) -> None:
        if self.entry_type not in {"address", "host"}:
            raise SyncError(f"unsupported entry type: {self.entry_type}")
        if not self.description:
            raise SyncError("description is required")
        if len(self.description) > 100:
            raise SyncError(f"description is longer than 100 characters: {self.description}")

    def key(self) -> tuple[str, str]:
        return (self.entry_type, self.value)

    def to_api(self) -> dict[str, str]:
        return {
            self.entry_type: self.value,
            "description": self.description,
        }


@dataclasses.dataclass
class SyncPlan:
    unmanaged: list[dict]
    out_of_scope_managed: list[dict]
    current_managed: list[dict]
    add: list[SplitTunnelEntry]
    update: list[SplitTunnelEntry]
    remove: list[SplitTunnelEntry]
    keep: list[SplitTunnelEntry]
    desired: list[SplitTunnelEntry]
    merged: list[dict]


def utc_timestamp() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def normalize_host(host: str) -> str:
    value = host.strip().lower().rstrip(".")
    if not value:
        raise SyncError("host must not be empty")
    if "://" in value or "/" in value:
        raise SyncError(f"host must be a domain name, got {host!r}")
    return value


def normalize_address(address: str) -> str:
    value = address.strip()
    if not value:
        raise SyncError("address must not be empty")
    try:
        return str(ipaddress.ip_network(value, strict=False))
    except ValueError as exc:
        raise SyncError(f"invalid CIDR or IP address: {address}") from exc


def managed_description(provider: str, source: str, kind: str) -> str:
    description = f"{MANAGED_PREFIX}{provider}:{source}:{kind}"
    if len(description) > 100:
        raise SyncError(f"managed description is too long: {description}")
    return description


def host_entry(host: str, provider: str, source: str) -> SplitTunnelEntry:
    return SplitTunnelEntry(
        "host",
        normalize_host(host),
        managed_description(provider, source, "host"),
    )


def address_entry(address: str, provider: str, source: str) -> SplitTunnelEntry:
    return SplitTunnelEntry(
        "address",
        normalize_address(address),
        managed_description(provider, source, "cidr"),
    )


def entry_from_payload(payload: dict) -> SplitTunnelEntry:
    has_host = "host" in payload and payload.get("host") not in (None, "")
    has_address = "address" in payload and payload.get("address") not in (None, "")
    if has_host == has_address:
        raise SyncError(f"Cloudflare entry must contain exactly one of host/address: {payload}")
    description = str(payload.get("description") or "")
    if has_host:
        return SplitTunnelEntry("host", normalize_host(str(payload["host"])), description)
    return SplitTunnelEntry("address", normalize_address(str(payload["address"])), description)


def is_managed_payload(payload: dict) -> bool:
    return str(payload.get("description") or "").startswith(MANAGED_PREFIX)


def payload_provider(payload: dict) -> str:
    description = str(payload.get("description") or "")
    parts = description.split(":", 2)
    if len(parts) < 3 or parts[0] != "managed":
        return ""
    return parts[1]


def provider_in_scope(payload: dict, provider: str) -> bool:
    found_provider = payload_provider(payload)
    if provider == "all":
        return found_provider in SUPPORTED_MANAGED_PROVIDERS
    return found_provider == provider


def payload_key(payload: dict) -> typing.Optional[tuple[str, str]]:
    has_host = "host" in payload and payload.get("host") not in (None, "")
    has_address = "address" in payload and payload.get("address") not in (None, "")
    if has_host == has_address:
        return None
    if has_host:
        return ("host", normalize_host(str(payload["host"])))
    return ("address", normalize_address(str(payload["address"])))


def sorted_entries(entries: list[SplitTunnelEntry]) -> list[SplitTunnelEntry]:
    return sorted(entries, key=lambda entry: (entry.entry_type, entry.value, entry.description))


def dedupe_entries(entries: list[SplitTunnelEntry]) -> list[SplitTunnelEntry]:
    by_key: dict[tuple[str, str], SplitTunnelEntry] = {}
    for entry in entries:
        existing = by_key.get(entry.key())
        if existing and existing.description != entry.description:
            raise SyncError(
                f"conflicting managed descriptions for {entry.entry_type} {entry.value}: "
                f"{existing.description!r} and {entry.description!r}"
            )
        by_key[entry.key()] = entry
    return sorted_entries(list(by_key.values()))


def flatten_domains(value) -> set[str]:
    domains: set[str] = set()
    if isinstance(value, str):
        domains.add(normalize_host(value))
        return domains
    if isinstance(value, list):
        for item in value:
            domains.update(flatten_domains(item))
        return domains
    if isinstance(value, dict):
        for item in value.values():
            domains.update(flatten_domains(item))
        return domains
    raise SyncError(f"unsupported GitHub domains shape: {type(value).__name__}")


def build_github_entries(meta: dict, include_ips: bool) -> list[SplitTunnelEntry]:
    if not isinstance(meta, dict):
        raise SyncError("GitHub meta response must be an object")
    if meta.get("domains") is None:
        raise SyncError("GitHub meta response must contain a domains value")

    entries: list[SplitTunnelEntry] = []
    meta_domains = flatten_domains(meta.get("domains"))
    static_hosts = {normalize_host(host) for host in GITHUB_STATIC_HOSTS}

    for host in sorted(static_hosts):
        entries.append(host_entry(host, "github", "static"))

    for host in sorted(meta_domains - static_hosts):
        entries.append(host_entry(host, "github", "meta"))

    if include_ips:
        for category in GITHUB_IP_CATEGORIES:
            if category in meta:
                values = meta[category]
            else:
                values = []
            if not isinstance(values, list):
                raise SyncError(f"GitHub meta category {category!r} is not a list")
            for address in values:
                entries.append(address_entry(str(address), "github", "meta"))

    return dedupe_entries(entries)


def build_tailscale_entries(derp_map: dict, include_derp_ips: bool) -> list[SplitTunnelEntry]:
    if not isinstance(derp_map, dict):
        raise SyncError("Tailscale DERP map response must be an object")

    entries: list[SplitTunnelEntry] = []

    for address in TAILSCALE_RESERVED_RANGES:
        entries.append(address_entry(address, "tailscale", "reserved"))

    for host in TAILSCALE_CONTROL_HOSTS:
        entries.append(host_entry(host, "tailscale", "firewall"))

    regions = derp_map.get("Regions")
    if not isinstance(regions, dict):
        raise SyncError("Tailscale DERP map does not contain a Regions object")

    for region in regions.values():
        if not isinstance(region, dict):
            raise SyncError("Tailscale DERP region value is not an object")
        nodes = region.get("Nodes")
        if not isinstance(nodes, list):
            raise SyncError("Tailscale DERP region Nodes value is not a list")
        for node in nodes:
            if not isinstance(node, dict):
                raise SyncError("Tailscale DERP node value is not an object")
            host = node.get("HostName") or node.get("Hostname")
            if host:
                entries.append(host_entry(str(host), "tailscale", "derpmap"))
            if include_derp_ips:
                for field in ("IPv4", "IPv6"):
                    address = node.get(field)
                    if address:
                        entries.append(address_entry(str(address), "tailscale", "derpmap"))

    return dedupe_entries(entries)


def calculate_plan(
    remote_entries: list[dict],
    desired_entries: list[SplitTunnelEntry],
    provider: str = "all",
) -> SyncPlan:
    unmanaged: list[dict] = []
    out_of_scope_managed: list[dict] = []
    seen_managed_keys: set[tuple[str, str]] = set()
    current_managed: dict[tuple[str, str], SplitTunnelEntry] = {}
    current_managed_payloads: dict[tuple[str, str], dict] = {}

    for payload in remote_entries:
        if is_managed_payload(payload):
            entry = entry_from_payload(payload)
            if entry.key() in seen_managed_keys:
                raise SyncError(f"duplicate remote managed entry for {entry.entry_type} {entry.value}")
            seen_managed_keys.add(entry.key())
            if not provider_in_scope(payload, provider):
                out_of_scope_managed.append(dict(payload))
                continue
            current_managed[entry.key()] = entry
            current_managed_payloads[entry.key()] = dict(payload)
        else:
            unmanaged.append(dict(payload))

    desired = dedupe_entries(desired_entries)
    desired_map = {entry.key(): entry for entry in desired}
    current_keys = set(current_managed)
    desired_keys = set(desired_map)

    add = sorted_entries([desired_map[key] for key in desired_keys - current_keys])
    remove = sorted_entries([current_managed[key] for key in current_keys - desired_keys])
    keep: list[SplitTunnelEntry] = []
    update: list[SplitTunnelEntry] = []

    for key in sorted(current_keys & desired_keys):
        current = current_managed[key]
        wanted = desired_map[key]
        if current.description == wanted.description:
            keep.append(wanted)
        else:
            update.append(wanted)

    for payload in unmanaged + out_of_scope_managed:
        key = payload_key(payload)
        if key in desired_keys:
            entry_type, value = key
            raise SyncError(f"desired managed entry {entry_type} {value} conflicts with preserved entry")

    merged = [dict(payload) for payload in unmanaged]
    merged.extend(dict(payload) for payload in out_of_scope_managed)
    merged.extend(entry.to_api() for entry in sorted_entries(desired))

    return SyncPlan(
        unmanaged=unmanaged,
        out_of_scope_managed=out_of_scope_managed,
        current_managed=[current_managed_payloads[key] for key in sorted(current_managed_payloads)],
        add=add,
        update=sorted_entries(update),
        remove=remove,
        keep=sorted_entries(keep),
        desired=sorted_entries(desired),
        merged=merged,
    )


class CloudflareClient:
    def __init__(self, token: str, account_id: str, policy_id: typing.Optional[str]) -> None:
        self.token = token
        self.account_id = account_id
        self.policy_id = policy_id

    def exclude_path(self) -> str:
        if self.policy_id:
            return f"/accounts/{self.account_id}/devices/policy/{self.policy_id}/exclude"
        return f"/accounts/{self.account_id}/devices/policy/exclude"

    def _request(self, method: str, path: str, body=None):
        data = None
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "cloudflare-warp-exclude-sync",
        }
        if body is not None:
            data = json.dumps(body, indent=None, separators=(",", ":")).encode("utf-8")

        request = urllib.request.Request(
            CLOUDFLARE_API_BASE + path,
            data=data,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.load(response)
        except urllib.error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="replace")
            details = redact_secret(details, self.token)
            raise SyncError(f"Cloudflare {method} {path} failed: HTTP {exc.code}: {details}") from exc
        except urllib.error.URLError as exc:
            details = redact_secret(str(exc.reason), self.token)
            raise SyncError(f"Cloudflare {method} {path} failed: {details}") from exc
        except TimeoutError as exc:
            details = redact_secret(str(exc), self.token)
            raise SyncError(f"Cloudflare {method} {path} failed: {details}") from exc
        except OSError as exc:
            details = redact_secret(str(exc), self.token)
            raise SyncError(f"Cloudflare {method} {path} failed: {details}") from exc
        except json.JSONDecodeError as exc:
            raise SyncError(f"Cloudflare {method} {path} failed: invalid JSON response") from exc

        if not isinstance(payload, dict):
            raise SyncError(f"Cloudflare {method} {path} failed: response is not an object")

        if not payload.get("success"):
            messages = []
            for item in payload.get("errors") or []:
                messages.append(f"{item.get('code')}: {item.get('message')}")
            details = redact_secret("; ".join(messages) or str(payload), self.token)
            raise SyncError(f"Cloudflare {method} {path} failed: {details}")
        return payload.get("result")

    def get_excludes(self) -> list[dict]:
        result = self._request("GET", self.exclude_path())
        if not isinstance(result, list):
            raise SyncError("Cloudflare exclude list response result is not a list")
        return result

    def put_excludes(self, entries: list[dict]) -> list[dict]:
        result = self._request("PUT", self.exclude_path(), body=entries)
        if not isinstance(result, list):
            raise SyncError("Cloudflare exclude list update result is not a list")
        return result


def fetch_json(url: str):
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "cloudflare-warp-exclude-sync",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise SyncError(f"source fetch failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise SyncError(f"source fetch failed for {url}: {exc.reason}") from exc
    except TimeoutError as exc:
        raise SyncError(f"source fetch failed for {url}: {exc}") from exc
    except OSError as exc:
        raise SyncError(f"source fetch failed for {url}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise SyncError(f"source fetch failed for {url}: invalid JSON response") from exc


def redact_secret(text: str, secret: str) -> str:
    if not secret:
        return text
    return text.replace(secret, "[redacted]")


def default_state_dir() -> pathlib.Path:
    state_home = os.environ.get("XDG_STATE_HOME")
    if state_home:
        return pathlib.Path(state_home) / DEFAULT_STATE_DIR
    home = pathlib.Path.home()
    return home / ".local" / "state" / DEFAULT_STATE_DIR


def write_json_secure(path: pathlib.Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    fd = os.open(path, flags, 0o600)
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")


def read_json(path: pathlib.Path):
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except OSError as exc:
        raise SyncError(f"could not read JSON file {path}: {exc.strerror or exc}") from exc
    except json.JSONDecodeError as exc:
        raise SyncError(f"invalid JSON in {path}: {exc.msg}") from exc


def validate_restore_entries(entries: list, path: pathlib.Path) -> None:
    for index, payload in enumerate(entries):
        if not isinstance(payload, dict):
            raise SyncError(f"restore entry {index} in {path} is not an object")
        key = payload_key(payload)
        if key is None:
            raise SyncError(f"restore entry {index} in {path} must contain exactly one of host/address")


def normalized_restore_payload(payload: dict) -> dict[str, str]:
    key = payload_key(payload)
    if key is None:
        raise SyncError(f"restore entry must contain exactly one of host/address: {payload}")
    entry_type, value = key
    normalized = {entry_type: value}
    if payload.get("description") not in (None, ""):
        normalized["description"] = str(payload["description"])
    return normalized


def normalized_restore_list(entries: list[dict]) -> list[dict[str, str]]:
    return sorted(
        [normalized_restore_payload(payload) for payload in entries],
        key=lambda payload: (
            "host" if "host" in payload else "address",
            payload.get("host") or payload.get("address") or "",
            payload.get("description") or "",
        ),
    )


def verify_restore_matches_backup(remote_entries: list[dict], backup_entries: list[dict]) -> None:
    if normalized_restore_list(remote_entries) != normalized_restore_list(backup_entries):
        raise SyncError("restore verification failed: remote entries do not match restore file")


def plan_manifest(
    account_id: str,
    policy_id: typing.Optional[str],
    provider: str,
    plan: SyncPlan,
    include_github_ips: bool,
    include_tailscale_derp_ips: bool,
) -> dict:
    return {
        "account_id": account_id,
        "device_policy_id": policy_id or "default",
        "timestamp": utc_timestamp(),
        "provider": provider,
        "sources": {
            "github_meta": GITHUB_META_URL,
            "tailscale_derp_map": TAILSCALE_DERP_MAP_URL,
        },
        "options": {
            "include_github_ips": include_github_ips,
            "include_tailscale_derp_ips": include_tailscale_derp_ips,
        },
        "counts": {
            "unmanaged": len(plan.unmanaged),
            "out_of_scope_managed": len(plan.out_of_scope_managed),
            "current_managed": len(plan.current_managed),
            "add": len(plan.add),
            "update": len(plan.update),
            "remove": len(plan.remove),
            "keep": len(plan.keep),
            "desired_managed": len(plan.desired),
            "merged_total": len(plan.merged),
        },
        "out_of_scope_managed": plan.out_of_scope_managed,
        "current_managed": plan.current_managed,
        "add": [entry.to_api() for entry in plan.add],
        "update": [entry.to_api() for entry in plan.update],
        "remove": [entry.to_api() for entry in plan.remove],
        "keep": [entry.to_api() for entry in plan.keep],
        "desired_managed": [entry.to_api() for entry in plan.desired],
    }


def print_summary(
    account_id: str,
    policy_id: typing.Optional[str],
    remote_total: int,
    plan: SyncPlan,
    dry_run: bool,
) -> None:
    target = policy_id or "default"
    mode = "dry-run" if dry_run else "apply"
    print(f"mode: {mode}")
    print(f"account: {account_id}")
    print(f"target profile: {target}")
    print(f"remote total entries: {remote_total}")
    print(f"manual/unmanaged entries preserved: {len(plan.unmanaged)}")
    print(f"remote managed entries: {len(plan.keep) + len(plan.update) + len(plan.remove)}")
    print(f"entries to add: {len(plan.add)}")
    print(f"entries to update: {len(plan.update)}")
    print(f"entries to remove: {len(plan.remove)}")
    print(f"entries unchanged: {len(plan.keep)}")


def build_desired_entries(args: argparse.Namespace) -> list[SplitTunnelEntry]:
    desired: list[SplitTunnelEntry] = []
    if args.provider in ("all", "tailscale"):
        derp_map = fetch_json(TAILSCALE_DERP_MAP_URL)
        desired.extend(
            build_tailscale_entries(
                derp_map,
                include_derp_ips=args.include_tailscale_derp_ips,
            )
        )
    if args.provider in ("all", "github"):
        github_meta = fetch_json(GITHUB_META_URL)
        desired.extend(
            build_github_entries(
                github_meta,
                include_ips=args.include_github_ips,
            )
        )
    return dedupe_entries(desired)


def verify_remote_matches_plan(
    remote_entries: list[dict],
    desired_entries: list[SplitTunnelEntry],
    provider: str = "all",
) -> None:
    plan = calculate_plan(remote_entries, desired_entries, provider=provider)
    if plan.add or plan.update or plan.remove:
        raise SyncError("post-apply verification failed: remote managed entries do not match desired state")


def parse_args(argv: typing.Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Synchronize Cloudflare WARP Split Tunnel exclude rules for Tailscale and GitHub.",
    )
    parser.add_argument("--apply", action="store_true", help="write the planned list to Cloudflare")
    parser.add_argument("--print-current", action="store_true", help="print the current remote exclude list as JSON")
    parser.add_argument("--restore", type=pathlib.Path, help="restore a backup JSON file")
    parser.add_argument(
        "--provider",
        choices=("all", "github", "tailscale"),
        default="all",
        help="limit generated managed entries to one provider",
    )
    parser.add_argument("--include-github-ips", action="store_true", help="also exclude selected GitHub CIDR ranges")
    parser.add_argument("--include-tailscale-derp-ips", action="store_true", help="also exclude DERP node IPs")
    parser.add_argument("--state-dir", type=pathlib.Path, default=None, help="override the local state directory")
    return parser.parse_args(argv)


def load_cloudflare_client() -> CloudflareClient:
    token = os.environ.get("CLOUDFLARE_API_TOKEN")
    account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID")
    policy_id = os.environ.get("CLOUDFLARE_DEVICE_POLICY_ID") or None
    if not token:
        raise SyncError("CLOUDFLARE_API_TOKEN is required")
    if not account_id:
        raise SyncError("CLOUDFLARE_ACCOUNT_ID is required")
    return CloudflareClient(token, account_id, policy_id)


def run(argv: typing.Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    state_dir = args.state_dir or default_state_dir()
    backups_dir = state_dir / "backups"

    if args.restore:
        backup = read_json(args.restore)
        if not isinstance(backup, list):
            raise SyncError(f"restore file does not contain a Cloudflare exclude list: {args.restore}")
        validate_restore_entries(backup, args.restore)
        print(f"restore file: {args.restore}")
        print(f"restore entries: {len(backup)}")
        if not args.apply:
            print("mode: dry-run")
            print("restore not applied; pass --apply to write this backup to Cloudflare")
            return 0
        client = load_cloudflare_client()
        before = client.get_excludes()
        before_path = backups_dir / f"{utc_timestamp()}-before-restore.json"
        write_json_secure(before_path, before)
        print(f"backup before write: {before_path}")
        try:
            client.put_excludes(backup)
            after = client.get_excludes()
            after_path = backups_dir / f"{utc_timestamp()}-after-restore.json"
            write_json_secure(after_path, after)
            verify_restore_matches_backup(after, backup)
        except (SyncError, OSError) as exc:
            print(f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply")
            if isinstance(exc, OSError):
                raise SyncError(f"post-restore audit write failed: {exc}") from exc
            raise
        print(f"restore backup before write: {before_path}")
        print(f"restore backup after write: {after_path}")
        return 0

    client = load_cloudflare_client()
    remote = client.get_excludes()
    if args.print_current:
        json.dump(remote, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0

    desired = build_desired_entries(args)
    plan = calculate_plan(remote, desired, provider=args.provider)
    manifest = plan_manifest(
        client.account_id,
        client.policy_id,
        args.provider,
        plan,
        args.include_github_ips,
        args.include_tailscale_derp_ips,
    )
    write_json_secure(state_dir / "last-plan.json", manifest)
    print_summary(client.account_id, client.policy_id, len(remote), plan, dry_run=not args.apply)
    print(f"plan file: {state_dir / 'last-plan.json'}")

    if not args.apply:
        return 0

    before_path = backups_dir / f"{utc_timestamp()}-before.json"
    write_json_secure(before_path, remote)
    print(f"backup before write: {before_path}")

    try:
        client.put_excludes(plan.merged)
        after = client.get_excludes()
        after_path = backups_dir / f"{utc_timestamp()}-after.json"
        write_json_secure(after_path, after)
        verify_remote_matches_plan(after, desired, provider=args.provider)
    except (SyncError, OSError) as exc:
        print(f"restore command: scripts/sync-cloudflare-warp-excludes.py --restore {before_path} --apply")
        if isinstance(exc, OSError):
            raise SyncError(f"post-apply audit write failed: {exc}") from exc
        raise

    apply_manifest = dict(manifest)
    apply_manifest["applied_at"] = utc_timestamp()
    apply_manifest["before_backup"] = str(before_path)
    apply_manifest["after_backup"] = str(after_path)
    write_json_secure(state_dir / "last-apply.json", apply_manifest)
    print(f"backup after write: {after_path}")
    print(f"apply file: {state_dir / 'last-apply.json'}")
    return 0


def main() -> None:
    try:
        raise SystemExit(run())
    except SyncError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
