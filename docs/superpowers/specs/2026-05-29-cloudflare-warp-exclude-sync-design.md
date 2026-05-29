# Cloudflare WARP Exclude Sync Design

## Goal

Create a standalone Python synchronizer for Cloudflare Zero Trust WARP Split
Tunnel exclude rules. The tool should keep the Tailscale and GitHub bypass
rules current without wiring this behavior into nix-darwin activation or
Home Manager.

This design treats the earlier "TLS" wording as Tailscale. It does not add
TLS inspection, SSL bypass, or Gateway HTTP policy automation.

## Research Findings

Cloudflare WARP Split Tunnels can exclude traffic by IP/CIDR or domain. The
Cloudflare API exposes default and custom device-profile exclude lists as
whole-list resources, so updates must read the current list, merge desired
entries, and write back the full result. Each entry uses either `address` or
`host`; `description` is the only practical Cloudflare-side place to store a
short ownership/source marker.

Cloudflare documentation recommends keeping Split Tunnel lists short. Domain
rules are useful for desktop WARP clients because the client can add routes as
hostnames resolve, but browser secure DNS, system DNS cache, and WARP profile
propagation can delay or bypass the expected behavior.

Tailscale has stable reserved tailnet ranges:

```text
100.64.0.0/10
fd7a:115c:a1e0::/48
```

Tailscale also documents control-plane domains and says domain-based firewall
rules are preferred when possible. DERP server addresses are dynamic enough
that the synchronizer should derive DERP hostnames from a current DERP map
rather than hard-code every public DERP IP by default.

GitHub's REST meta endpoint exposes `domains` and IP categories such as `web`,
`api`, `git`, and `packages`. GitHub warns that the IP lists are not an
exhaustive allowlist of all GitHub traffic. For the current problem, the safer
default is domain-first GitHub exclusion, with IP expansion available only as
an explicit option.

## Selected Approach

Add one standalone script:

```text
scripts/sync-cloudflare-warp-excludes.py
```

The script should use only the Python standard library:

```text
argparse
dataclasses
datetime
ipaddress
json
os
pathlib
sys
urllib.error
urllib.request
```

No Python package dependency should be added to the repo. The script should run
with the system Python or a Nix shell-provided Python, but it should not require
flake wiring.

The script should default to dry-run mode. It should write Cloudflare only when
the user passes:

```bash
scripts/sync-cloudflare-warp-excludes.py --apply
```

Cloudflare credentials and target profile should come from environment
variables:

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
CLOUDFLARE_DEVICE_POLICY_ID
```

If `CLOUDFLARE_DEVICE_POLICY_ID` is absent, the script manages the default WARP
device profile. If it is present, the script manages that custom device
profile.

## Ownership Contract

The script must only create, update, and delete entries whose `description`
starts with this exact prefix:

```text
managed:
```

Manual entries, Cloudflare default entries, and entries created by other tools
must be preserved byte-for-byte except for ordering differences required by
Cloudflare's API.

Managed descriptions should fit Cloudflare's short description field and use
this format:

```text
managed:<provider>:<source>:<kind>
```

Examples:

```text
managed:tailscale:reserved:cidr
managed:tailscale:firewall:host
managed:tailscale:derpmap:host
managed:github:meta:host
managed:github:static:host
managed:github:meta:cidr
```

The detailed audit trail should live in a local manifest, not in the Cloudflare
entry description.

## Local State and Backups

Use XDG-style state paths:

```text
~/.local/state/cloudflare-warp-excludes/
```

The script should create:

```text
last-plan.json
last-apply.json
backups/YYYYMMDDTHHMMSSZ-before.json
backups/YYYYMMDDTHHMMSSZ-after.json
```

`last-plan.json` should contain:

- Cloudflare account ID.
- Device policy ID or `default`.
- Timestamp.
- Source URLs used for Tailscale and GitHub data.
- Generated managed entries.
- Current remote managed entries.
- Add, keep, update, and remove lists.

Before any `PUT`, the script must write the full current remote exclude list to
a backup file. A restore mode should accept that file and replace the remote
list with the saved content:

```bash
scripts/sync-cloudflare-warp-excludes.py --restore ~/.local/state/cloudflare-warp-excludes/backups/20260529T120000Z-before.json --apply
```

## Rule Sources

### Tailscale Reserved Ranges

Always include:

```text
100.64.0.0/10
fd7a:115c:a1e0::/48
```

Descriptions:

```text
managed:tailscale:reserved:cidr
```

### Tailscale Control Hosts

Always include these hosts:

```text
console.tailscale.com
controlplane.tailscale.com
login.tailscale.com
log.tailscale.com
*.tailscale.com
*.ts.net
```

Descriptions:

```text
managed:tailscale:firewall:host
```

`*.tailscale.com` and `*.ts.net` intentionally trade precision for operational
stability. If the first implementation proves too broad, a later revision can
replace them with the narrower control-plane and MagicDNS host set.

### Tailscale DERP Hosts

Fetch the current DERP map:

```text
https://controlplane.tailscale.com/derpmap/default
```

Generate host entries for the public DERP regions. Host entries should use the
documented DERP hostname shape when the map exposes it. If the map cannot be
fetched or parsed, the script should fail closed and keep the remote list
unchanged.

Descriptions:

```text
managed:tailscale:derpmap:host
```

DERP IP expansion should be opt-in:

```bash
scripts/sync-cloudflare-warp-excludes.py --include-tailscale-derp-ips --apply
```

### GitHub Domains

Fetch:

```text
https://api.github.com/meta
```

Use the `domains` array from the response. Merge it with static fallback
domains that are directly relevant to normal Git, package, release, and raw
asset traffic:

```text
github.com
*.github.com
*.githubusercontent.com
*.githubassets.com
ghcr.io
*.pkg.github.com
```

Descriptions:

```text
managed:github:meta:host
managed:github:static:host
```

GitHub IP expansion should be opt-in:

```bash
scripts/sync-cloudflare-warp-excludes.py --include-github-ips --apply
```

When enabled, include only these GitHub meta categories:

```text
web
api
git
packages
```

Descriptions:

```text
managed:github:meta:cidr
```

Do not include every GitHub IP category by default because the current problem
is GitHub traffic exiting through Cloudflare WARP, not a complete enterprise
firewall allowlist.

## Cloudflare API Contract

Default device profile:

```text
GET /client/v4/accounts/{account_id}/devices/policy/exclude
PUT /client/v4/accounts/{account_id}/devices/policy/exclude
```

Custom device profile:

```text
GET /client/v4/accounts/{account_id}/devices/policy/{policy_id}/exclude
PUT /client/v4/accounts/{account_id}/devices/policy/{policy_id}/exclude
```

The script should send:

```text
Authorization: Bearer <CLOUDFLARE_API_TOKEN>
Content-Type: application/json
```

It should parse Cloudflare's standard response envelope and treat
`success: false` as a hard failure. It should print the Cloudflare error codes
and messages without printing the token.

## CLI Behavior

Supported commands:

```bash
scripts/sync-cloudflare-warp-excludes.py
scripts/sync-cloudflare-warp-excludes.py --apply
scripts/sync-cloudflare-warp-excludes.py --print-current
scripts/sync-cloudflare-warp-excludes.py --restore <backup.json>
scripts/sync-cloudflare-warp-excludes.py --include-github-ips
scripts/sync-cloudflare-warp-excludes.py --include-tailscale-derp-ips
scripts/sync-cloudflare-warp-excludes.py --provider github
scripts/sync-cloudflare-warp-excludes.py --provider tailscale
```

Default behavior without arguments:

- Fetch current Cloudflare exclude list.
- Fetch Tailscale and GitHub source data.
- Generate desired managed entries.
- Print a dry-run summary.
- Write `last-plan.json`.
- Exit without modifying Cloudflare.

Dry-run summary should include:

```text
target profile
remote total entries
remote managed entries
manual/unmanaged entries preserved
entries to add
entries to update
entries to remove
entries unchanged
```

## Data Flow

```text
Cloudflare GET exclude list
  -> classify remote entries as managed or unmanaged
  -> fetch Tailscale reserved/control/DERP sources
  -> fetch GitHub meta domains
  -> build desired managed entries
  -> compute add/update/remove/keep plan
  -> dry-run output and last-plan.json
  -> optional backup current remote list
  -> optional Cloudflare PUT merged full list
  -> Cloudflare GET verification
  -> last-apply.json
```

## Error Handling

Missing `CLOUDFLARE_API_TOKEN` or `CLOUDFLARE_ACCOUNT_ID` should fail before any
network request.

Invalid CIDR values should fail during local generation before Cloudflare is
called.

Source-fetch failures should fail closed by default. The script should not push
a partial list after failing to fetch GitHub metadata or DERP data. A future
explicit `--use-stale-source-cache` flag can be added only if repeated manual
use proves it is needed.

A Cloudflare `GET` failure should stop the run.

A Cloudflare `PUT` failure should leave the local backup file in place and
print the restore command template.

Post-apply verification should run a second `GET` and compare the remote
managed entries with the planned managed entries. Any mismatch should exit
non-zero and preserve both before and after backup files.

## Security

The script must never print the Cloudflare API token.

The script should not store the API token in `last-plan.json`, `last-apply.json`,
or backups.

The Cloudflare token should have the minimum permission needed to read and edit
Zero Trust device profile settings for the target account.

Backups contain network policy data and should be created with user-only file
permissions when the platform allows it.

## Verification

Implementation should verify local logic with tests before making live API
calls:

```bash
python3 -m unittest discover -s tests -p 'test_sync_cloudflare_warp_excludes.py'
python3 scripts/sync-cloudflare-warp-excludes.py --help
```

With Cloudflare credentials available, run a dry run:

```bash
CLOUDFLARE_API_TOKEN=... \
CLOUDFLARE_ACCOUNT_ID=... \
python3 scripts/sync-cloudflare-warp-excludes.py
```

Expected dry-run result:

- Exits 0.
- Prints add/update/remove/keep counts.
- Writes `last-plan.json`.
- Does not call Cloudflare `PUT`.

Apply should be a separate explicit command:

```bash
CLOUDFLARE_API_TOKEN=... \
CLOUDFLARE_ACCOUNT_ID=... \
python3 scripts/sync-cloudflare-warp-excludes.py --apply
```

Expected apply result:

- Writes a before backup.
- Calls Cloudflare `PUT` exactly once.
- Runs a post-apply `GET`.
- Writes `last-apply.json`.
- Exits 0 only if the remote managed entries match the desired managed entries.

Network behavior should be checked after WARP profile propagation:

```bash
curl -sS https://api.github.com/rate_limit
tailscale status
```

Cloudflare dashboard or Gateway logs should confirm that GitHub traffic covered
by the managed host rules no longer exits through Cloudflare WARP.

## Non-Goals

- Do not modify nix-darwin modules, Home Manager modules, or flake inputs.
- Do not create a launchd timer or scheduled job in the first implementation.
- Do not manage Cloudflare Gateway HTTP policies.
- Do not manage Local Domain Fallback in the first implementation.
- Do not delete Cloudflare exclude entries unless their description starts with
  `managed:`.
- Do not default to expanding all GitHub or Tailscale DERP IP ranges.
- Do not persist Cloudflare credentials.

## References

- Cloudflare API: Device profile Split Tunnel exclude list.
  `https://developers.cloudflare.com/api/operations/devices-set-split-tunnel-exclude-list`
- Cloudflare WARP Split Tunnels documentation.
  `https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/`
- Cloudflare Python API documentation for Zero Trust device policies.
  `https://developers.cloudflare.com/api/python/resources/zero_trust/subresources/devices/`
- Tailscale reserved IP addresses.
  `https://tailscale.com/kb/1610/reserved-ip-addresses`
- Tailscale firewall ports.
  `https://tailscale.com/docs/reference/faq/firewall-ports`
- Tailscale DERP servers.
  `https://tailscale.com/docs/reference/derp-servers`
- GitHub REST API meta endpoint.
  `https://docs.github.com/en/rest/meta/meta?apiVersion=2022-11-28`
- GitHub IP address guidance.
  `https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-githubs-ip-addresses`
