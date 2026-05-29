# Mole Nix Package Design

## Goal

Package `tw93/Mole` from upstream source in this flake and install it through Home Manager for the `sakurai` user profile.

The target version is `1.39.1`, upstream tag `V1.39.1`.

## Selected Approach

Create a same-flake package:

```text
nix/packages/mole.nix
```

Expose it through a dedicated Home Manager program module:

```text
nix/modules/home/programs/mole.nix
```

Import the module from:

```text
nix/modules/home/cli.nix
```

This follows the repository's existing Blueprint layout: same-flake package definitions live under `nix/packages/`, and configurable or named CLI tools get a focused Home Manager module under `nix/modules/home/programs/`.

## Package Source

Use `pkgs.fetchFromGitHub` for the upstream source archive:

```nix
owner = "tw93";
repo = "Mole";
rev = "V1.39.1";
hash = "sha256-NrDUdDx4O/QE0+UgM0aw681vAUbwO0fJ+0t0H5QBm0M=";
```

Do not use `pkgs.mole`: that package is `davrodpin/mole`, an SSH tunnel CLI, not `tw93/Mole`.

Do not use Homebrew for this package. Homebrew is a valid upstream installation path, but this change intentionally keeps Mole managed by Nix and this flake.

## Build Layout

`tw93/Mole` is not a single Go binary. It is a Bash CLI entrypoint plus a script library plus two Go helper commands:

```text
mole                  main Bash entrypoint
bin/*.sh              command scripts
lib/**/*.sh           shared shell library
cmd/analyze           Go disk analyzer helper
cmd/status            Go status helper
```

Build the Go helpers with `pkgs.buildGo125Module`, matching upstream `go.mod`:

```nix
vendorHash = "sha256-+JxttzU6y/ETUS8VWKIGCvAs/sM1Xz9DBU4eVniVIes=";
subPackages = [
  "cmd/analyze"
  "cmd/status"
];
ldflags = [
  "-s"
  "-w"
  "-X main.Version=${version}"
  "-X main.BuildTime=1970-01-01T00:00:00Z"
];
doCheck = false;
```

Disable the default Go check phase. A probe build with checks enabled failed because upstream tests assume BSD/macOS `du -I` behavior while the Nix build environment hit a `du: invalid option -- 'I'` failure. This is a test-environment mismatch, not a compile failure. Use package smoke tests instead.

Assemble the package with `stdenvNoCC.mkDerivation`:

```text
$out/bin/mole
$out/bin/mo -> $out/bin/mole
$out/libexec/mole/bin/*.sh
$out/libexec/mole/bin/analyze-go
$out/libexec/mole/bin/status-go
$out/libexec/mole/lib/**/*.sh
```

Patch the main entrypoint so `SCRIPT_DIR` points to `$out/libexec/mole`. Run `patchShebangs` over `$out/bin`, `$out/libexec/mole/bin`, and `$out/libexec/mole/lib`.

The Go build outputs are named `analyze` and `status`; install them as `analyze-go` and `status-go` because upstream wrapper scripts expect those exact names.

## Nix-Managed Self-Management Commands

Patch `mo update` and `mo remove` because Mole is managed by Nix in this repository.

`mo update` must not download upstream `install.sh` or mutate a profile-installed executable. It should print a short message telling the user to update this flake and rebuild the `sakurai` profile.

`mo remove` must not try to delete the Home Manager profile executable or remove `~/.config/mole`, `~/.cache/mole`, or `~/Library/Logs/mole` on behalf of Nix. It should print a short message telling the user to remove or disable the Home Manager module.

Keep runtime commands such as `clean`, `purge`, `analyze`, `status`, `optimize`, `installer`, `uninstall`, `completion`, and `touchid` intact.

## Home Manager Integration

Create a focused Home Manager module that installs the package:

```nix
{ perSystem, ... }:

{
  home.packages = [
    perSystem.self.mole
  ];
}
```

Use `perSystem.self.mole` directly. The current Blueprint setup exposes existing same-flake packages such as `jcode` and `cliproxyapi` through `perSystem.self.<name>`, not `pkgs.<name>`.

Do not add Mole to `nix/modules/home/programs/desktop-apps.nix`; it is a CLI system maintenance tool, not a GUI app.

Do not add shell aliases. The package provides both `mole` and `mo` executables.

Do not make Home Manager own user runtime state under `~/.config/mole`, `~/.cache/mole`, or `~/Library/Logs/mole`. Mole manages those files at runtime, and some commands intentionally write previews, whitelists, purge paths, and logs.

## Runtime Behavior

Expected smoke-test behavior:

```bash
mole --version
mo --version
mo analyze --help
mo status --help
HOME=/private/tmp/mole-home MO_NO_OPLOG=1 mo clean --dry-run
```

The `mo clean --dry-run` probe must use a temporary HOME. The tool writes `~/.config/mole/clean-list.txt` and may inspect local application state, so the verification should avoid mutating the user's real HOME during package testing.

## Verification

Run these checks during implementation:

```bash
git diff --check
nix build .#mole
./result/bin/mole --version
./result/bin/mo --version
./result/bin/mo analyze --help
./result/bin/mo status --help
rm -rf /private/tmp/mole-home
mkdir -p /private/tmp/mole-home
HOME=/private/tmp/mole-home MO_NO_OPLOG=1 ./result/bin/mo clean --dry-run
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in builtins.elem flake.packages.aarch64-darwin.mole hm.home.packages'
darwin-rebuild build --flake .#sakurai
```

If `builtins.getFlake "git+file://..."` cannot see newly added files, add the new files to the index with `git add --intent-to-add` before running the eval.

If Nix daemon access is blocked by the sandbox, rerun the Nix commands with the required permissions or report the exact sandbox error.

## Non-Goals

- Do not install Homebrew formula `mole`.
- Do not add `homebrew.brews = [ "mole" ];`.
- Do not add a Homebrew cask.
- Do not use `pkgs.mole` from nixpkgs unless it is proven to be `tw93/Mole` in a future nixpkgs revision.
- Do not manage Mole runtime config, whitelist, cache, or logs declaratively in Home Manager.
- Do not configure destructive cleanup preferences in this change.
