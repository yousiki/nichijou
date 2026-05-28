#!/usr/bin/env python3
import argparse
import base64
import dataclasses
import difflib
import hashlib
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request


DEFAULT_SPEC = "nix/packages/update-specs.json"
VERSION_RE = re.compile(r'(?m)^(\s*version\s*=\s*")([^"]+)(";\s*)$')


class UpdateError(Exception):
    pass


@dataclasses.dataclass
class AssetUpdate:
    system: str
    nix_asset: str
    release_asset: str
    sri_hash: str
    url: str


@dataclasses.dataclass
class UpdatePlan:
    package: str
    package_file: pathlib.Path
    current_version: str
    latest_version: str
    changed: bool
    new_text: str
    assets: list


def github_headers(token=None, accept="application/vnd.github+json"):
    headers = {
        "Accept": accept,
        "User-Agent": "nix-packages-updater",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def fetch_json(url, token=None):
    request = urllib.request.Request(url, headers=github_headers(token))
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        raise UpdateError(f"GitHub request failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise UpdateError(f"GitHub request failed for {url}: {exc.reason}") from exc


def fetch_latest_release(repo, token=None):
    release = fetch_json(f"https://api.github.com/repos/{repo}/releases/latest", token)
    if release.get("draft") or release.get("prerelease"):
        raise UpdateError(f"{repo} latest release is draft or prerelease")
    if not release.get("tag_name"):
        raise UpdateError(f"{repo} latest release does not include tag_name")
    return release


def sri_from_digest(digest):
    algorithm, separator, hex_digest = digest.partition(":")
    if algorithm != "sha256" or not separator:
        raise UpdateError(f"unsupported asset digest: {digest}")
    try:
        raw = bytes.fromhex(hex_digest)
    except ValueError as exc:
        raise UpdateError(f"invalid sha256 digest: {digest}") from exc
    if len(raw) != 32:
        raise UpdateError(f"invalid sha256 digest length: {digest}")
    return "sha256-" + base64.b64encode(raw).decode("ascii")


def sri_from_url(url, token=None):
    request = urllib.request.Request(
        url,
        headers=github_headers(token, accept="application/octet-stream"),
    )
    hasher = hashlib.sha256()
    try:
        with urllib.request.urlopen(request) as response:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                hasher.update(chunk)
    except urllib.error.HTTPError as exc:
        raise UpdateError(f"asset download failed for {url}: HTTP {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise UpdateError(f"asset download failed for {url}: {exc.reason}") from exc
    return "sha256-" + base64.b64encode(hasher.digest()).decode("ascii")


def tag_to_version(tag, version_prefix):
    if version_prefix and tag.startswith(version_prefix):
        return tag[len(version_prefix) :]
    if version_prefix:
        raise UpdateError(f"tag {tag!r} does not start with {version_prefix!r}")
    return tag


def render_template(template, version, tag):
    try:
        return template.format(version=version, tag=tag)
    except KeyError as exc:
        raise UpdateError(f"unknown template variable {{{exc.args[0]}}}") from exc


def current_version(package, text):
    match = VERSION_RE.search(text)
    if not match:
        raise UpdateError(f"{package}: could not find version attribute")
    return match.group(2)


def replace_version(package, text, version):
    new_text, count = VERSION_RE.subn(
        lambda match: f"{match.group(1)}{version}{match.group(3)}",
        text,
        count=1,
    )
    if count != 1:
        raise UpdateError(f"{package}: could not replace version attribute")
    return new_text


def replace_attr(package, system, body, attr, value):
    pattern = re.compile(rf'(?m)^(\s*{re.escape(attr)}\s*=\s*")[^"]+(";\s*)$')
    new_body, count = pattern.subn(
        lambda match: f"{match.group(1)}{value}{match.group(2)}",
        body,
        count=1,
    )
    if count != 1:
        raise UpdateError(f"{package}: could not replace {attr} for {system}")
    return new_body


def replace_system_source(package, text, update):
    pattern = re.compile(
        rf"(?ms)^(\s*{re.escape(update.system)}\s*=\s*\{{\n)(.*?)(^\s*\}};)"
    )

    def replace_block(match):
        body = replace_attr(
            package, update.system, match.group(2), "asset", update.nix_asset
        )
        body = replace_attr(package, update.system, body, "hash", update.sri_hash)
        return f"{match.group(1)}{body}{match.group(3)}"

    new_text, count = pattern.subn(replace_block, text, count=1)
    if count != 1:
        raise UpdateError(f"{package}: could not find source block for {update.system}")
    return new_text


def release_assets_by_name(release):
    assets = {}
    for asset in release.get("assets", []):
        name = asset.get("name")
        if name:
            assets[name] = asset
    return assets


def asset_sri_hash(asset, token=None):
    digest = asset.get("digest")
    if digest:
        return sri_from_digest(digest)
    url = asset.get("browser_download_url")
    if not url:
        raise UpdateError(f"{asset.get('name', '<unknown>')}: missing download URL")
    return sri_from_url(url, token)


def plan_update(package, package_spec, package_file, release, token=None):
    text = package_file.read_text(encoding="utf-8")
    old_version = current_version(package, text)
    tag = release["tag_name"]
    new_version = tag_to_version(tag, package_spec.get("versionPrefix", ""))
    if old_version == new_version:
        return UpdatePlan(
            package=package,
            package_file=package_file,
            current_version=old_version,
            latest_version=new_version,
            changed=False,
            new_text=text,
            assets=[],
        )

    assets_by_name = release_assets_by_name(release)
    updates = []
    for system, asset_spec in package_spec["systems"].items():
        nix_asset = render_template(asset_spec["nixAsset"], new_version, tag)
        release_asset = render_template(asset_spec["releaseAsset"], new_version, tag)
        release_entry = assets_by_name.get(release_asset)
        if release_entry is None:
            raise UpdateError(f"{package}: {system} missing release asset {release_asset}")
        updates.append(
            AssetUpdate(
                system=system,
                nix_asset=nix_asset,
                release_asset=release_asset,
                sri_hash=asset_sri_hash(release_entry, token),
                url=release_entry.get("browser_download_url", ""),
            )
        )

    new_text = replace_version(package, text, new_version)
    for update in updates:
        new_text = replace_system_source(package, new_text, update)
    return UpdatePlan(
        package=package,
        package_file=package_file,
        current_version=old_version,
        latest_version=new_version,
        changed=True,
        new_text=new_text,
        assets=updates,
    )


def load_specs(path):
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    packages = data.get("packages")
    if not isinstance(packages, dict) or not packages:
        raise UpdateError(f"{path}: expected non-empty packages object")
    return packages


def selected_specs(specs, names):
    if not names:
        return specs
    missing = [name for name in names if name not in specs]
    if missing:
        raise UpdateError("unknown package(s): " + ", ".join(missing))
    return {name: specs[name] for name in names}


def diff_for_plan(plan):
    old_lines = plan.package_file.read_text(encoding="utf-8").splitlines(keepends=True)
    new_lines = plan.new_text.splitlines(keepends=True)
    return "".join(
        difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile=str(plan.package_file),
            tofile=str(plan.package_file),
        )
    )


def run(args):
    root = pathlib.Path(args.root).resolve()
    specs = selected_specs(load_specs(root / args.spec), args.package)
    token = args.github_token or os.environ.get("GITHUB_TOKEN")
    plans = []

    for package, package_spec in specs.items():
        package_file = root / package_spec["file"]
        release = fetch_latest_release(package_spec["repo"], token)
        plans.append(plan_update(package, package_spec, package_file, release, token))

    changed = [plan for plan in plans if plan.changed]
    for plan in plans:
        if plan.changed:
            print(f"{plan.package}: {plan.current_version} -> {plan.latest_version}")
            for asset in plan.assets:
                print(f"  {asset.system}: {asset.release_asset} {asset.sri_hash}")
        else:
            print(f"{plan.package}: current at {plan.current_version}")

    if args.diff:
        for plan in changed:
            print(diff_for_plan(plan), end="")

    if not args.check and not args.dry_run:
        for plan in changed:
            plan.package_file.write_text(plan.new_text, encoding="utf-8")

    if args.check and changed:
        return 1
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Update pinned GitHub release assets under nix/packages."
    )
    parser.add_argument("--root", default=".", help="repository root")
    parser.add_argument("--spec", default=DEFAULT_SPEC, help="update spec JSON path")
    parser.add_argument(
        "--package",
        action="append",
        help="package name to update; may be passed more than once",
    )
    parser.add_argument(
        "--github-token",
        default=None,
        help="GitHub token; defaults to GITHUB_TOKEN when set",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        action="store_true",
        help="exit 1 when one or more package updates are available",
    )
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="print planned updates without writing files",
    )
    parser.add_argument("--diff", action="store_true", help="print unified diffs")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return run(args)
    except UpdateError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
