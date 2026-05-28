# Jcode Home Manager Design

## Goal

Package `jcode` from upstream prebuilt release binaries and expose it to user
`yousiki` through Home Manager, matching the repository pattern for coding
agent CLIs such as Claude Code, Codex, and OpenCode.

The target validation host is the current Apple Silicon macOS host, `sakurai`.

## Selected Approach

Use Blueprint's package folder convention:

```text
nix/packages/jcode.nix
nix/modules/home/programs/jcode.nix
```

`nix/packages/jcode.nix` owns the derivation. It downloads the pinned upstream
GitHub release asset for the current system and installs a `jcode` executable.
The package file receives Blueprint's per-system arguments and uses `pkgs` for
`fetchurl`, `lib`, and `stdenvNoCC`.

`nix/modules/home/programs/jcode.nix` owns the Home Manager integration and
consumes the local package through `perSystem.self.jcode`.

This follows Blueprint's documented structure: with `prefix = "nix/"`,
packages belong under `nix/packages/`, modules belong under `nix/modules/`, and
packages from the same flake should be consumed inside host/home configuration
through `perSystem.self.<pname>`.

## Non-Selected Approaches

Do not put the package definition in an overlay. Blueprint documents overlays as
useful for consumers that need packages rebuilt against their own nixpkgs
instance, but also recommends per-system composition when possible. This repo
only needs to consume the package from its own flake.

Do not use the upstream Homebrew tap. The user explicitly asked to package this
ourselves and install it through Home Manager like the other coding-agent CLIs.

Do not build from source. The user chose prebuilt binaries. Source builds would
increase build time and introduce Cargo dependency hash maintenance for no
current benefit.

## Package Definition

Create:

```text
nix/packages/jcode.nix
```

The package should:

- Pin `version = "0.14.3"`.
- Fetch assets from `https://github.com/1jehuang/jcode/releases/download/v0.14.3/`.
- Select the correct release asset by `stdenvNoCC.hostPlatform.system`.
- Support `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, and
  `aarch64-linux`, because upstream publishes all four assets and this flake
  already declares Darwin and Linux systems.
- Install a stable `$out/bin/jcode`.

The upstream `x86_64-linux` archive includes a shell launcher, a companion
`.bin`, and bundled OpenSSL shared libraries. The package must keep those files
together under `$out/libexec/jcode` and symlink the launcher to `$out/bin/jcode`
so the launcher's relative library lookup continues to work.

The other checked archive shapes are single executable files and can be
installed directly as `$out/bin/jcode`.

## Home Manager Module

Create:

```text
nix/modules/home/programs/jcode.nix
```

It should be intentionally small:

```nix
{ perSystem, ... }:

{
  home.packages = [
    perSystem.self.jcode
  ];
}
```

Wire it into:

```text
nix/modules/home/cli.nix
```

Import order should keep AI coding tools grouped:

```nix
imports = [
  ./programs/claude-code.nix
  ./programs/codex.nix
  ./programs/opencode.nix
  ./programs/jcode.nix
  ./programs/git.nix
  ./programs/shell.nix
];
```

## Runtime Behavior

After Home Manager activation, `jcode` should be available on the user's PATH
from the Home Manager generation.

Provider login, OAuth state, MCP config, API keys, and files under `~/.jcode`
remain runtime state and should not be declared in this Nix change.

## Verification

Before implementation, a package existence assertion should fail:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? jcode; true'
```

After implementation, run:

```bash
git diff --check
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.packages.aarch64-darwin.jcode.version'
nix build .#packages.aarch64-darwin.jcode
JCODE_NO_TELEMETRY=1 ./result/bin/jcode --version
nix build .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.activationPackage
```

If Nix daemon access is blocked by the execution sandbox, rerun with the required
permissions or report the daemon-access failure explicitly. Remove any `result`
symlink left by `nix build`.

## References

- Blueprint configuration: `prefix = "nix/"` means standard folders live under
  `nix/`.
- Blueprint folder structure: `packages/<pname>.nix` maps to
  `packages.<system>.<pname>`, and same-flake host consumption uses
  `perSystem.self.<pname>`.
- Upstream jcode latest release checked through GitHub API: `v0.14.3`, published
  on 2026-05-27, with prebuilt macOS and Linux release assets.
