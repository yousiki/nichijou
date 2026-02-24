# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix run              # Activate/apply the configuration to the current system
just lint            # Format all Nix files (runs `nix fmt`)
just check           # Validate the flake (runs `nix flake check`)
just update          # Update all flake inputs (runs `nix flake update`)
just dev             # Enter the development shell (runs `nix develop`)
```

## Architecture

This is a personal Nix configuration repo based on [nixos-unified-template](https://github.com/juspay/nixos-unified-template), managing home environments (home-manager), macOS systems (nix-darwin), and NixOS systems.

**Autowiring via nixos-unified**: `flake.nix` delegates entirely to `inputs.nixos-unified.lib.mkFlake`. This means configurations and modules are discovered automatically by directory convention — no manual wiring needed.

**Directory layout**:
- `modules/flake/` — flake-level outputs: formatter (`nix fmt`), `activate` package (`nix run`), neovim app, devshell
- `modules/home/` — home-manager modules shared across all users/hosts; `default.nix` auto-imports every other `.nix` file in the folder
- `modules/darwin/` — nix-darwin system-level settings (macOS defaults, TouchID sudo, etc.)
- `modules/nixos/` — NixOS-specific modules (common system config, GUI/GNOME, user management)
- `configurations/darwin/<hostname>.nix` — per-machine nix-darwin entrypoints
- `configurations/home/<username>.nix` — standalone home-manager configs (non-NixOS/non-darwin)
- `configurations/nixos/<hostname>/` — per-machine NixOS configs

**User identity via `me` module** (`modules/home/me.nix`): defines custom options `me.username`, `me.fullname`, `me.email` consumed by `git.nix` and `home.username`. Each configuration must set these values.

**Adding new home-manager config**: create a new `.nix` file under `modules/home/` — it is auto-imported by `modules/home/default.nix`.

**Adding a new host**: create `configurations/darwin/<hostname>.nix` (or nixos equivalent), import `self.darwinModules.default`, set `nixpkgs.hostPlatform` and `networking.hostName`.

**CI** (`vira.hs`): builds on `x86_64-linux` and `aarch64-darwin` via [Vira](https://vira.nixos.asia/).
