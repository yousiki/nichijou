# Cloudflare WARP Exclude Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a repeatable Cloudflare WARP Split Tunnel exclude synchronizer for Tailscale and GitHub, with dry-run safety, backups, restore support, and a same-flake Nix package wrapper.

**Architecture:** The implementation starts as one standard-library Python script under `scripts/` with pure functions for source parsing and plan calculation, plus a small Cloudflare API client for live operations. Unit tests cover the pure logic and API path selection without live network calls. A follow-up package file in `nix/packages/` wraps the checked-in script with `pkgs.python3` so the tool can run through `nix run .#cloudflare-warp-exclude-sync` without storing credentials in the Nix store.

**Tech Stack:** Python 3 standard library, `unittest`, Cloudflare Zero Trust WARP Split Tunnel API, GitHub Meta API, Tailscale DERP map, Nix flakes, Blueprint, `stdenvNoCC`, `makeWrapper`.

---

## File Structure

- Create `scripts/sync-cloudflare-warp-excludes.py`: standalone executable Python tool.
- Create `tests/test_sync_cloudflare_warp_excludes.py`: unit tests for entry generation, plan calculation, API path selection, and CLI parsing.
- Create `nix/packages/cloudflare-warp-exclude-sync.nix`: same-flake wrapper package for the script.
- Do not modify `flake.nix`: Blueprint discovers `nix/packages/cloudflare-warp-exclude-sync.nix` because this repo already uses `prefix = "nix/"`.
- Do not modify Home Manager modules: the package is runnable with `nix run` and is not installed into the user profile in this implementation.
- Do not create a launchd agent, timer, scheduled job, or Cloudflare Gateway HTTP policy.
- Do not write Cloudflare credentials into any checked-in file or generated state file.

Before starting implementation, run:

```bash
git status --short --branch -uall
```

Expected: inspect and preserve unrelated user changes. Do not revert unrelated files.

### Task 1: Add Unit Tests For The Sync Logic

**Files:**
- Create: `tests/test_sync_cloudflare_warp_excludes.py`
- Verify: `scripts/sync-cloudflare-warp-excludes.py` is absent before this task

- [ ] **Step 1: Confirm the script does not exist yet**

Run:

```bash
test ! -f scripts/sync-cloudflare-warp-excludes.py
```

Expected: exit code 0.

- [ ] **Step 2: Create the test file**

Create `tests/test_sync_cloudflare_warp_excludes.py` with exactly:

```python
import importlib.util
import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "sync-cloudflare-warp-excludes.py"

spec = importlib.util.spec_from_file_location("sync_cloudflare_warp_excludes", SCRIPT)
syncer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(syncer)


def entry_set(entries):
    return {(entry.entry_type, entry.value, entry.description) for entry in entries}


class EntryGenerationTests(unittest.TestCase):
    def test_github_domains_are_flattened_and_static_fallbacks_are_added(self):
        meta = {
            "domains": {
                "website": ["GitHub.com", "*.GitHub.com"],
                "raw": ["raw.githubusercontent.com"],
                "nested": {"assets": ["*.githubassets.com"]},
            },
            "web": ["192.30.252.0/22"],
            "api": ["140.82.112.0/20"],
            "git": ["192.30.255.112/32"],
            "packages": ["140.82.121.33/32"],
            "actions": ["10.0.0.0/8"],
        }

        entries = syncer.build_github_entries(meta, include_ips=False)

        self.assertIn(
            ("host", "github.com", "managed:github:static:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "*.github.com", "managed:github:static:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "raw.githubusercontent.com", "managed:github:meta:host"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "192.30.252.0/22", "managed:github:meta:cidr"),
            entry_set(entries),
        )

    def test_github_ip_expansion_uses_selected_meta_categories_only(self):
        meta = {
            "domains": [],
            "web": ["192.30.252.0/22"],
            "api": ["140.82.112.0/20"],
            "git": ["192.30.255.112/32"],
            "packages": ["140.82.121.33"],
            "actions": ["10.0.0.0/8"],
        }

        entries = syncer.build_github_entries(meta, include_ips=True)

        self.assertIn(
            ("address", "192.30.252.0/22", "managed:github:meta:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "140.82.121.33/32", "managed:github:meta:cidr"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "10.0.0.0/8", "managed:github:meta:cidr"),
            entry_set(entries),
        )

    def test_tailscale_entries_include_reserved_ranges_control_hosts_and_derp_hosts(self):
        derp_map = {
            "Regions": {
                "1": {
                    "Nodes": [
                        {
                            "Name": "1a",
                            "HostName": "derp1.tailscale.com",
                            "IPv4": "203.0.113.1",
                        }
                    ]
                },
                "2": {
                    "Nodes": [
                        {
                            "Name": "2a",
                            "HostName": "derp2.tailscale.com",
                            "IPv6": "2001:db8::1",
                        }
                    ]
                },
            }
        }

        entries = syncer.build_tailscale_entries(derp_map, include_derp_ips=False)

        self.assertIn(
            ("address", "100.64.0.0/10", "managed:tailscale:reserved:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "fd7a:115c:a1e0::/48", "managed:tailscale:reserved:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "controlplane.tailscale.com", "managed:tailscale:firewall:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "*.ts.net", "managed:tailscale:firewall:host"),
            entry_set(entries),
        )
        self.assertIn(
            ("host", "derp1.tailscale.com", "managed:tailscale:derpmap:host"),
            entry_set(entries),
        )
        self.assertNotIn(
            ("address", "203.0.113.1/32", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )

    def test_tailscale_derp_ip_expansion_is_explicit(self):
        derp_map = {
            "Regions": {
                "1": {
                    "Nodes": [
                        {
                            "HostName": "derp1.tailscale.com",
                            "IPv4": "203.0.113.1",
                            "IPv6": "2001:db8::1",
                        }
                    ]
                }
            }
        }

        entries = syncer.build_tailscale_entries(derp_map, include_derp_ips=True)

        self.assertIn(
            ("address", "203.0.113.1/32", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )
        self.assertIn(
            ("address", "2001:db8::1/128", "managed:tailscale:derpmap:cidr"),
            entry_set(entries),
        )


class PlanningTests(unittest.TestCase):
    def test_calculate_plan_preserves_unmanaged_entries_and_removes_only_managed_stale_entries(self):
        remote = [
            {"address": "10.0.0.0/8", "description": "manual private range"},
            {"host": "old.example.com", "description": "managed:github:meta:host"},
            {"host": "github.com", "description": "managed:github:old:host"},
        ]
        desired = [
            syncer.SplitTunnelEntry(
                "host",
                "github.com",
                "managed:github:static:host",
            ),
            syncer.SplitTunnelEntry(
                "address",
                "100.64.0.0/10",
                "managed:tailscale:reserved:cidr",
            ),
        ]

        plan = syncer.calculate_plan(remote, desired)

        self.assertEqual(plan.unmanaged, [{"address": "10.0.0.0/8", "description": "manual private range"}])
        self.assertEqual(
            [entry.to_api() for entry in plan.add],
            [{"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"}],
        )
        self.assertEqual(
            [entry.to_api() for entry in plan.update],
            [{"host": "github.com", "description": "managed:github:static:host"}],
        )
        self.assertEqual(
            [entry.to_api() for entry in plan.remove],
            [{"host": "old.example.com", "description": "managed:github:meta:host"}],
        )
        self.assertEqual(
            plan.merged,
            [
                {"address": "10.0.0.0/8", "description": "manual private range"},
                {"address": "100.64.0.0/10", "description": "managed:tailscale:reserved:cidr"},
                {"host": "github.com", "description": "managed:github:static:host"},
            ],
        )

    def test_entry_from_payload_rejects_entries_with_both_host_and_address(self):
        with self.assertRaisesRegex(syncer.SyncError, "exactly one"):
            syncer.entry_from_payload(
                {
                    "host": "github.com",
                    "address": "192.0.2.0/24",
                    "description": "managed:github:meta:host",
                }
            )


class ClientAndCliTests(unittest.TestCase):
    def test_default_profile_endpoint_path(self):
        client = syncer.CloudflareClient("token", "account", None)

        self.assertEqual(
            client.exclude_path(),
            "/accounts/account/devices/policy/exclude",
        )

    def test_custom_profile_endpoint_path(self):
        client = syncer.CloudflareClient("token", "account", "policy")

        self.assertEqual(
            client.exclude_path(),
            "/accounts/account/devices/policy/policy/exclude",
        )

    def test_restore_without_apply_is_parsed_as_dry_run_restore(self):
        args = syncer.parse_args(["--restore", "backup.json"])

        self.assertEqual(args.restore, pathlib.Path("backup.json"))
        self.assertFalse(args.apply)

    def test_provider_filter_accepts_github_and_tailscale(self):
        args = syncer.parse_args(["--provider", "github", "--include-github-ips"])

        self.assertEqual(args.provider, "github")
        self.assertTrue(args.include_github_ips)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 3: Run the tests and verify they fail because the script is absent**

Run:

```bash
python3 -m unittest discover -s tests -p 'test_sync_cloudflare_warp_excludes.py'
```

Expected before script creation: fails with `FileNotFoundError` for `scripts/sync-cloudflare-warp-excludes.py`.

### Task 2: Implement The Standalone Python Synchronizer

**Files:**
- Create: `scripts/sync-cloudflare-warp-excludes.py`
- Test: `tests/test_sync_cloudflare_warp_excludes.py`

- [ ] **Step 1: Create the script**

Create `scripts/sync-cloudflare-warp-excludes.py` with exactly:

```python
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import dataclasses
import datetime
import ipaddress
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request


MANAGED_PREFIX = "managed:"
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
    if value is None:
        return domains
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
    return domains


def build_github_entries(meta: dict, include_ips: bool) -> list[SplitTunnelEntry]:
    entries: list[SplitTunnelEntry] = []
    meta_domains = flatten_domains(meta.get("domains"))
    static_hosts = {normalize_host(host) for host in GITHUB_STATIC_HOSTS}

    for host in sorted(static_hosts):
        entries.append(host_entry(host, "github", "static"))

    for host in sorted(meta_domains - static_hosts):
        entries.append(host_entry(host, "github", "meta"))

    if include_ips:
        for category in GITHUB_IP_CATEGORIES:
            values = meta.get(category) or []
            if not isinstance(values, list):
                raise SyncError(f"GitHub meta category {category!r} is not a list")
            for address in values:
                entries.append(address_entry(str(address), "github", "meta"))

    return dedupe_entries(entries)


def build_tailscale_entries(derp_map: dict, include_derp_ips: bool) -> list[SplitTunnelEntry]:
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
            continue
        nodes = region.get("Nodes") or []
        if not isinstance(nodes, list):
            raise SyncError("Tailscale DERP region Nodes value is not a list")
        for node in nodes:
            if not isinstance(node, dict):
                continue
            host = node.get("HostName") or node.get("Hostname")
            if host:
                entries.append(host_entry(str(host), "tailscale", "derpmap"))
            if include_derp_ips:
                for field in ("IPv4", "IPv6"):
                    address = node.get(field)
                    if address:
                        entries.append(address_entry(str(address), "tailscale", "derpmap"))

    return dedupe_entries(entries)


def calculate_plan(remote_entries: list[dict], desired_entries: list[SplitTunnelEntry]) -> SyncPlan:
    unmanaged: list[dict] = []
    current_managed: dict[tuple[str, str], SplitTunnelEntry] = {}

    for payload in remote_entries:
        if is_managed_payload(payload):
            entry = entry_from_payload(payload)
            current_managed[entry.key()] = entry
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

    merged = [dict(payload) for payload in unmanaged]
    merged.extend(entry.to_api() for entry in sorted_entries(desired))

    return SyncPlan(
        unmanaged=unmanaged,
        add=add,
        update=sorted_entries(update),
        remove=remove,
        keep=sorted_entries(keep),
        desired=sorted_entries(desired),
        merged=merged,
    )


class CloudflareClient:
    def __init__(self, token: str, account_id: str, policy_id: str | None) -> None:
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
            raise SyncError(f"Cloudflare {method} {path} failed: HTTP {exc.code}: {details}") from exc
        except urllib.error.URLError as exc:
            raise SyncError(f"Cloudflare {method} {path} failed: {exc.reason}") from exc

        if not payload.get("success"):
            messages = []
            for item in payload.get("errors") or []:
                messages.append(f"{item.get('code')}: {item.get('message')}")
            raise SyncError(f"Cloudflare {method} {path} failed: {'; '.join(messages) or payload}")
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
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")


def read_json(path: pathlib.Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def plan_manifest(
    account_id: str,
    policy_id: str | None,
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
            "add": len(plan.add),
            "update": len(plan.update),
            "remove": len(plan.remove),
            "keep": len(plan.keep),
            "desired_managed": len(plan.desired),
            "merged_total": len(plan.merged),
        },
        "add": [entry.to_api() for entry in plan.add],
        "update": [entry.to_api() for entry in plan.update],
        "remove": [entry.to_api() for entry in plan.remove],
        "keep": [entry.to_api() for entry in plan.keep],
        "desired_managed": [entry.to_api() for entry in plan.desired],
    }


def print_summary(
    account_id: str,
    policy_id: str | None,
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


def verify_remote_matches_plan(remote_entries: list[dict], desired_entries: list[SplitTunnelEntry]) -> None:
    plan = calculate_plan(remote_entries, desired_entries)
    if plan.add or plan.update or plan.remove:
        raise SyncError("post-apply verification failed: remote managed entries do not match desired state")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
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


def run(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    state_dir = args.state_dir or default_state_dir()
    backups_dir = state_dir / "backups"
    client = load_cloudflare_client()

    if args.restore:
        backup = read_json(args.restore)
        if not isinstance(backup, list):
            raise SyncError(f"restore file does not contain a Cloudflare exclude list: {args.restore}")
        print(f"restore file: {args.restore}")
        print(f"restore entries: {len(backup)}")
        if not args.apply:
            print("mode: dry-run")
            print("restore not applied; pass --apply to write this backup to Cloudflare")
            return 0
        before = client.get_excludes()
        before_path = backups_dir / f"{utc_timestamp()}-before-restore.json"
        write_json_secure(before_path, before)
        client.put_excludes(backup)
        after = client.get_excludes()
        after_path = backups_dir / f"{utc_timestamp()}-after-restore.json"
        write_json_secure(after_path, after)
        print(f"restore backup before write: {before_path}")
        print(f"restore backup after write: {after_path}")
        return 0

    remote = client.get_excludes()
    if args.print_current:
        json.dump(remote, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0

    desired = build_desired_entries(args)
    plan = calculate_plan(remote, desired)
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

    client.put_excludes(plan.merged)
    after = client.get_excludes()
    after_path = backups_dir / f"{utc_timestamp()}-after.json"
    write_json_secure(after_path, after)

    verify_remote_matches_plan(after, desired)
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
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x scripts/sync-cloudflare-warp-excludes.py
```

Expected: exit code 0.

- [ ] **Step 3: Run the focused unit tests**

Run:

```bash
python3 -m unittest discover -s tests -p 'test_sync_cloudflare_warp_excludes.py'
```

Expected output includes:

```text
Ran 10 tests

OK
```

- [ ] **Step 4: Run the help smoke check**

Run:

```bash
python3 scripts/sync-cloudflare-warp-excludes.py --help
```

Expected: exits 0 and prints options including `--apply`, `--restore`, `--provider`, `--include-github-ips`, and `--include-tailscale-derp-ips`.

- [ ] **Step 5: Verify missing credentials fail before network calls**

Run:

```bash
env -u CLOUDFLARE_API_TOKEN -u CLOUDFLARE_ACCOUNT_ID python3 scripts/sync-cloudflare-warp-excludes.py
```

Expected: exits 1 and prints:

```text
error: CLOUDFLARE_API_TOKEN is required
```

- [ ] **Step 6: Commit the tested standalone script**

Run:

```bash
git add tests/test_sync_cloudflare_warp_excludes.py scripts/sync-cloudflare-warp-excludes.py
git commit -m "feat: add cloudflare warp exclude sync script"
```

Expected: commit succeeds and includes only the script and its tests.

### Task 3: Add The Same-Flake Nix Package Wrapper

**Files:**
- Create: `nix/packages/cloudflare-warp-exclude-sync.nix`
- Modify: none
- Test: package evaluation and `nix run` help output

- [ ] **Step 1: Verify the package is not exposed yet**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? cloudflare-warp-exclude-sync; true'
```

Expected before package creation: assertion failure because `cloudflare-warp-exclude-sync` is not exposed yet.

If it fails with Nix daemon access text like this, retry with the needed permissions:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

- [ ] **Step 2: Create the package file**

Create `nix/packages/cloudflare-warp-exclude-sync.nix` with exactly:

```nix
{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) lib makeWrapper python3 stdenvNoCC;
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = "0.1.0";

  src = ../..;

  nativeBuildInputs = [
    makeWrapper
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -D -m755 "$src/scripts/sync-cloudflare-warp-excludes.py" \
      "$out/libexec/${pname}/sync-cloudflare-warp-excludes.py"

    makeWrapper "${python3}/bin/python3" "$out/bin/cloudflare-warp-exclude-sync" \
      --add-flags "$out/libexec/${pname}/sync-cloudflare-warp-excludes.py"

    runHook postInstall
  '';

  meta = {
    description = "Synchronize Cloudflare WARP Split Tunnel exclusions for Tailscale and GitHub";
    homepage = "https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/";
    license = lib.licenses.mit;
    mainProgram = "cloudflare-warp-exclude-sync";
    platforms = lib.platforms.unix;
  };
}
```

- [ ] **Step 3: Make new files visible to git-backed flake evaluation**

Run:

```bash
git add --intent-to-add scripts/sync-cloudflare-warp-excludes.py tests/test_sync_cloudflare_warp_excludes.py nix/packages/cloudflare-warp-exclude-sync.nix
```

Expected: exit code 0.

- [ ] **Step 4: Verify package exposure**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.packages.aarch64-darwin.cloudflare-warp-exclude-sync.meta.mainProgram'
```

Expected output:

```json
"cloudflare-warp-exclude-sync"
```

- [ ] **Step 5: Build the package**

Run:

```bash
nix build .#cloudflare-warp-exclude-sync
```

Expected: build exits 0 and creates a `result` symlink.

- [ ] **Step 6: Run the packaged help smoke check**

Run:

```bash
./result/bin/cloudflare-warp-exclude-sync --help
```

Expected: exits 0 and prints the same help options as the direct script.

- [ ] **Step 7: Verify `nix run` help output**

Run:

```bash
nix run .#cloudflare-warp-exclude-sync -- --help
```

Expected: exits 0 and prints the same help options as the direct script.

- [ ] **Step 8: Commit the package wrapper**

Run:

```bash
git add nix/packages/cloudflare-warp-exclude-sync.nix
git commit -m "nix: package cloudflare warp exclude sync"
```

Expected: commit succeeds and includes only the Nix package file.

### Task 4: Live Dry-Run Check With Cloudflare Credentials

**Files:**
- Modify: none
- Runtime state: `~/.local/state/cloudflare-warp-excludes/last-plan.json`

- [ ] **Step 1: Run a direct-script dry run when credentials are available**

Run:

```bash
CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" \
python3 scripts/sync-cloudflare-warp-excludes.py
```

Expected when credentials are set: exits 0, prints counts for add/update/remove/keep, writes `~/.local/state/cloudflare-warp-excludes/last-plan.json`, and does not print the token.

Expected when credentials are not set: skip this step and record that live Cloudflare dry-run verification was not performed because credentials were absent.

- [ ] **Step 2: Run a packaged dry run when credentials are available**

Run:

```bash
CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" \
CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" \
nix run .#cloudflare-warp-exclude-sync --
```

Expected when credentials are set: exits 0, prints counts for add/update/remove/keep, writes `~/.local/state/cloudflare-warp-excludes/last-plan.json`, and does not print the token.

Expected when credentials are not set: skip this step and record that packaged live dry-run verification was not performed because credentials were absent.

- [ ] **Step 3: Inspect the generated plan file when a live dry run was performed**

Run:

```bash
python3 -m json.tool ~/.local/state/cloudflare-warp-excludes/last-plan.json >/tmp/cloudflare-warp-exclude-last-plan.pretty.json
```

Expected when a live dry run was performed: exits 0. Inspect `/tmp/cloudflare-warp-exclude-last-plan.pretty.json` and confirm it contains no `CLOUDFLARE_API_TOKEN` value.

If no live dry run was performed, skip this step.

### Task 5: Final Verification And Cleanup

**Files:**
- Verify: all created files

- [ ] **Step 1: Run all Python unit tests**

Run:

```bash
python3 -m unittest discover -s tests
```

Expected: all tests pass, including `test_sync_cloudflare_warp_excludes.py` and existing tests.

- [ ] **Step 2: Run direct script help**

Run:

```bash
python3 scripts/sync-cloudflare-warp-excludes.py --help
```

Expected: exits 0.

- [ ] **Step 3: Run package build and help**

Run:

```bash
nix build .#cloudflare-warp-exclude-sync
./result/bin/cloudflare-warp-exclude-sync --help
```

Expected: both commands exit 0.

- [ ] **Step 4: Run `nix run` help**

Run:

```bash
nix run .#cloudflare-warp-exclude-sync -- --help
```

Expected: exits 0.

- [ ] **Step 5: Check formatting whitespace**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 6: Remove the build result symlink if Nix created it**

Run:

```bash
test ! -L result || rm result
```

Expected: exit code 0.

- [ ] **Step 7: Review the final diff**

Run:

```bash
git status --short --branch -uall
git diff --stat HEAD
```

Expected: only intentional files are present if there are uncommitted changes, or the worktree is clean after the task commits. Do not revert unrelated user changes.

## Self-Review

- Spec coverage: Task 1 and Task 2 cover the standalone script, dry-run default, provider filters, source parsing, managed ownership prefix, local state, backups, restore mode, API path selection, credential handling, and unit verification. Task 3 covers the future Nix package wrapper using this repo's `nix/packages/` Blueprint layout. Task 4 covers live dry-run behavior when credentials are available. Task 5 covers final local and Nix verification.
- Gap scan: no deferred fields, vague commands, or missing file paths remain in the plan.
- Type consistency: the plan consistently uses `SplitTunnelEntry`, `SyncPlan`, `CloudflareClient`, `calculate_plan`, `build_github_entries`, `build_tailscale_entries`, and `cloudflare-warp-exclude-sync` across tests, implementation, and Nix packaging.
