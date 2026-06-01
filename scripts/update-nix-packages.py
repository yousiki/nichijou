#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///

import argparse
import base64
import difflib
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request


DEFAULT_SPEC = "nix/packages/update-specs.json"
FAKE_SHA256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
VERSION_RE = re.compile(r'(?m)^(\s*version\s*=\s*")([^"]+)(";\s*)$')
FETCH_FROM_GITHUB_RE = re.compile(
    r"(?ms)^(\s*src\s*=\s*fetchFromGitHub\s*\{\n)(.*?)(^\s*\};)"
)
GOT_HASH_RE = re.compile(r"got:\s*(sha256-[A-Za-z0-9+/=]+)")


class UpdateError(Exception):
    pass


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


def replace_attr(package, context, text, attr, value):
    pattern = re.compile(rf'(?m)^(\s*{re.escape(attr)}\s*=\s*")[^"]+(";\s*)$')
    new_text, count = pattern.subn(
        lambda match: f"{match.group(1)}{value}{match.group(2)}",
        text,
        count=1,
    )
    if count != 1:
        raise UpdateError(f"{package}: could not replace {attr} for {context}")
    return new_text


def replace_fetch_from_github_attr(package, text, attr, value):
    def replace_block(match):
        body = replace_attr(package, "fetchFromGitHub src", match.group(2), attr, value)
        return f"{match.group(1)}{body}{match.group(3)}"

    new_text, count = FETCH_FROM_GITHUB_RE.subn(replace_block, text, count=1)
    if count != 1:
        raise UpdateError(f"{package}: could not find fetchFromGitHub src block")
    return new_text


def replace_system_source(package, text, update):
    pattern = re.compile(
        rf"(?ms)^(\s*{re.escape(update['system'])}\s*=\s*\{{\n)(.*?)(^\s*\}};)"
    )

    def replace_block(match):
        body = replace_attr(
            package, update["system"], match.group(2), "asset", update["asset"]
        )
        body = replace_attr(package, update["system"], body, "hash", update["hash"])
        return f"{match.group(1)}{body}{match.group(3)}"

    new_text, count = pattern.subn(replace_block, text, count=1)
    if count != 1:
        raise UpdateError(
            f"{package}: could not find source block for {update['system']}"
        )
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


def run_command(command, cwd=None):
    return subprocess.run(command, cwd=cwd, check=False, capture_output=True, text=True)


def command_tail(result, line_count=12):
    output = f"{result.stdout}\n{result.stderr}".strip()
    if not output:
        return "<no output>"
    return "\n".join(output.splitlines()[-line_count:])


def split_repo(repo):
    parts = repo.split("/", 1)
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise UpdateError(f"invalid GitHub repo: {repo}")
    return parts


def prefetch_github_hash(repo, rev):
    _, name = split_repo(repo)
    safe_rev = re.sub(r"[^A-Za-z0-9._+-]+", "-", rev).strip("-")
    url = "https://github.com/{}/archive/refs/tags/{}.tar.gz".format(
        repo,
        urllib.parse.quote(rev, safe=""),
    )
    result = run_command(
        [
            "nix",
            "store",
            "prefetch-file",
            "--json",
            "--unpack",
            "--name",
            f"{name.lower()}-{safe_rev}-source",
            url,
        ]
    )
    if result.returncode != 0:
        raise UpdateError(
            f"source prefetch failed for {repo}@{rev}: {command_tail(result)}"
        )
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise UpdateError(
            f"source prefetch returned invalid JSON: {command_tail(result)}"
        ) from exc
    if not isinstance(data.get("hash"), str):
        raise UpdateError(
            f"source prefetch did not return a hash: {command_tail(result)}"
        )
    return data["hash"]


def prefetch_vendor_hash(root, package_file, package_attr, package_text):
    package_path = package_file.resolve().relative_to(root.resolve())
    with tempfile.TemporaryDirectory(
        prefix="nix-package-update-", dir="/private/tmp"
    ) as tmp:
        temp_root = pathlib.Path(tmp) / "repo"
        shutil.copytree(
            root,
            temp_root,
            symlinks=True,
            ignore=shutil.ignore_patterns(".git", ".direnv", ".worktrees", "result"),
        )
        (temp_root / package_path).write_text(package_text, encoding="utf-8")
        result = run_command(
            ["nix", "build", "--no-link", f"{temp_root}#{package_attr}"], temp_root
        )

    output = f"{result.stdout}\n{result.stderr}"
    if result.returncode == 0:
        raise UpdateError(f"{package_attr}: fake vendor hash unexpectedly built")
    if FAKE_SHA256 not in output:
        raise UpdateError(
            f"{package_attr}: nix build failed before vendor hash mismatch: {command_tail(result)}"
        )
    match = GOT_HASH_RE.search(output)
    if not match:
        raise UpdateError(
            f"{package_attr}: could not parse vendor hash: {command_tail(result)}"
        )
    return match.group(1)


def unchanged_plan(package, package_file, old_version, new_version, text):
    return {
        "package": package,
        "file": package_file,
        "old": old_version,
        "new": new_version,
        "changed": False,
        "text": text,
        "details": [],
    }


def plan_release_asset_update(package, package_spec, package_file, release, token=None):
    text = package_file.read_text(encoding="utf-8")
    old_version = current_version(package, text)
    tag = release["tag_name"]
    new_version = tag_to_version(tag, package_spec.get("versionPrefix", ""))
    if old_version == new_version:
        return unchanged_plan(package, package_file, old_version, new_version, text)

    assets_by_name = release_assets_by_name(release)
    updates = []
    for system, asset_spec in package_spec["systems"].items():
        release_asset = render_template(asset_spec["releaseAsset"], new_version, tag)
        release_entry = assets_by_name.get(release_asset)
        if release_entry is None:
            raise UpdateError(
                f"{package}: {system} missing release asset {release_asset}"
            )
        updates.append(
            {
                "kind": "asset",
                "system": system,
                "asset": render_template(asset_spec["nixAsset"], new_version, tag),
                "release_asset": release_asset,
                "hash": asset_sri_hash(release_entry, token),
            }
        )

    new_text = replace_version(package, text, new_version)
    for update in updates:
        new_text = replace_system_source(package, new_text, update)
    return changed_plan(
        package, package_file, old_version, new_version, new_text, updates
    )


def plan_github_source_update(package, package_spec, package_file, release, root):
    text = package_file.read_text(encoding="utf-8")
    old_version = current_version(package, text)
    tag = release["tag_name"]
    new_version = tag_to_version(tag, package_spec.get("versionPrefix", ""))
    if old_version == new_version:
        return unchanged_plan(package, package_file, old_version, new_version, text)

    source_hash_attr = package_spec.get("sourceHashAttr", "hash")
    vendor_hash_attr = package_spec.get("vendorHashAttr", "vendorHash")
    package_attr = package_spec.get("packageAttr", package)
    rev = render_template(package_spec.get("rev", "{tag}"), new_version, tag)
    source_hash = prefetch_github_hash(package_spec["repo"], rev)

    with_source = replace_version(package, text, new_version)
    with_source = replace_fetch_from_github_attr(
        package,
        with_source,
        source_hash_attr,
        source_hash,
    )
    fake_vendor = replace_attr(
        package, "package", with_source, vendor_hash_attr, FAKE_SHA256
    )
    vendor_hash = prefetch_vendor_hash(root, package_file, package_attr, fake_vendor)
    new_text = replace_attr(
        package, "package", with_source, vendor_hash_attr, vendor_hash
    )
    return changed_plan(
        package,
        package_file,
        old_version,
        new_version,
        new_text,
        [
            {"kind": "source", "attr": source_hash_attr, "hash": source_hash},
            {"kind": "source", "attr": vendor_hash_attr, "hash": vendor_hash},
        ],
    )


def changed_plan(package, package_file, old_version, new_version, text, details):
    return {
        "package": package,
        "file": package_file,
        "old": old_version,
        "new": new_version,
        "changed": True,
        "text": text,
        "details": details,
    }


def plan_update(package, package_spec, package_file, release, root, token=None):
    package_type = package_spec.get("type", "githubReleaseAssets")
    if package_type == "githubReleaseAssets":
        return plan_release_asset_update(
            package, package_spec, package_file, release, token
        )
    if package_type == "githubSource":
        return plan_github_source_update(
            package, package_spec, package_file, release, root
        )
    raise UpdateError(f"{package}: unknown package type {package_type!r}")


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
    old_lines = plan["file"].read_text(encoding="utf-8").splitlines(keepends=True)
    new_lines = plan["text"].splitlines(keepends=True)
    return "".join(
        difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile=str(plan["file"]),
            tofile=str(plan["file"]),
        )
    )


def print_plan(plan):
    if not plan["changed"]:
        print(f"{plan['package']}: current at {plan['old']}")
        return
    print(f"{plan['package']}: {plan['old']} -> {plan['new']}")
    for detail in plan["details"]:
        if detail["kind"] == "asset":
            print(f"  {detail['system']}: {detail['release_asset']} {detail['hash']}")
        else:
            print(f"  {detail['attr']}: {detail['hash']}")


def run(args):
    root = pathlib.Path(args.root).resolve()
    specs = selected_specs(load_specs(root / args.spec), args.package)
    token = args.github_token or os.environ.get("GITHUB_TOKEN")
    plans = []

    for package, package_spec in specs.items():
        package_file = root / package_spec["file"]
        release = fetch_latest_release(package_spec["repo"], token)
        plans.append(
            plan_update(package, package_spec, package_file, release, root, token)
        )

    changed = [plan for plan in plans if plan["changed"]]
    for plan in plans:
        print_plan(plan)

    if args.diff:
        for plan in changed:
            print(diff_for_plan(plan), end="")

    if not args.check and not args.dry_run:
        for plan in changed:
            plan["file"].write_text(plan["text"], encoding="utf-8")

    if args.check and changed:
        return 1
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Update pinned GitHub releases under nix/packages."
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
