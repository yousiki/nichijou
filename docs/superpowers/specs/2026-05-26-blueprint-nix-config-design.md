# Blueprint Nix Configuration Repository Design

## Goal

Build this repository into a multi-host configuration flake for nix-darwin and NixOS. The first target host is the current Apple Silicon macOS machine, `sakurai`. The structure must remain suitable for future Linux hosts and for small helper tools, including possible Rust binaries, without mixing project source with system configuration.

## Framework Choice

Use `numtide/blueprint` as the primary flake framework.

Blueprint maps a standard folder structure to flake outputs and supports NixOS hosts, nix-darwin hosts, Home Manager users, modules, packages, checks, and templates. Its `nixos-and-darwin-shared-homes` template matches this repository's intended shape: multiple operating systems, shared Home Manager modules, and host-local configuration.

Use Blueprint with `prefix = "nix/"`. This keeps the repository root available for documentation, scripts, and future helper tools while keeping flake-managed configuration under one directory.

## Initial Repository Layout

```text
flake.nix
flake.lock
nix/
  hosts/
    sakurai/
      darwin-configuration.nix
      users/
        yousiki/
          home-configuration.nix
  modules/
    darwin/
      common.nix
      homebrew.nix
      nix.nix
    home/
      common.nix
      cli.nix
    nixos/
      common.nix
  packages/
  checks/
```

`nix/hosts/<hostname>/darwin-configuration.nix` produces `darwinConfigurations.<hostname>`.

`nix/hosts/<hostname>/configuration.nix` will produce `nixosConfigurations.<hostname>` for future NixOS machines.

`nix/hosts/<hostname>/users/<username>/home-configuration.nix` defines a Home Manager configuration. Blueprint will also expose standalone Home Manager outputs and wire users into nix-darwin or NixOS hosts when `home-manager` is present.

`nix/modules/darwin`, `nix/modules/nixos`, and `nix/modules/home` hold reusable modules exposed as Blueprint module outputs.

## Flake Inputs

Initial inputs:

- `nixpkgs`, using an unstable branch.
- `blueprint`.
- `nix-darwin`, following `nixpkgs`.
- `home-manager`, following `nixpkgs`.
- `nix-homebrew`.
- `brew-nix`.
- `brew-api`, with `flake = false`, followed by `brew-nix.inputs.brew-api`.
- `homebrew-core`, with `flake = false`.
- `homebrew-cask`, with `flake = false`.

Deferred inputs:

- `sops-nix`, until secret management is needed.
- A community-maintained auto-updating `claude-code` overlay, after selecting a suitable project.

## Systems

Declare these systems in Blueprint:

```nix
[
  "aarch64-darwin"
  "x86_64-linux"
  "aarch64-linux"
]
```

This covers the current Mac and likely future NixOS hosts. `x86_64-darwin` is not needed initially.

## macOS Package Policy

Use a tiered package policy on Darwin:

1. Prefer `nixpkgs` packages.
2. Use `brew-nix` for supported Homebrew casks that work well as Nix derivations.
3. Use nix-darwin `homebrew.casks` for GUI apps that need normal Homebrew installation behavior.
4. Use nix-darwin `homebrew.brews` only when the package is unavailable or unsuitable in `nixpkgs`.

`nix-homebrew` manages Homebrew installation, Rosetta support on Apple Silicon, and pinned taps. It does not manage formulae or casks directly; nix-darwin `homebrew.*` remains responsible for declarative Homebrew package lists.

## Lix and Nix Settings

Keep Lix as the configured Nix implementation. The Darwin Nix module should set:

- `nix.package = pkgs.lix` or a selected Lix package set when needed.
- `nix.settings.experimental-features = [ "nix-command" "flakes" ]`.
- Trusted users and substituters can be added later when concrete caches are introduced.

## Secrets

Do not enable secret management initially. Reserve room for:

- `nix/modules/nixos/secrets.nix`
- `nix/modules/darwin/secrets.nix`
- `secrets/`

When needed, evaluate `sops-nix` first. Clan's secret and vars model may be revisited later if the repository evolves into a multi-machine deployment framework.

## Testing and Verification

The first implementation should verify:

- `nix flake show` evaluates.
- `darwin-rebuild build --flake .#sakurai` builds the current host.
- If Home Manager is wired through Blueprint, the standalone home output for `yousiki@sakurai` evaluates.

Full `nix flake check` may build host closures through Blueprint checks. If it is too expensive, document the skipped checks and run targeted build commands instead.

## Non-Goals

- Do not introduce `sops-nix` until there are actual secrets to manage.
- Do not write a custom host factory unless Blueprint's native host mapping becomes insufficient.
- Do not use Blueprint `hosts/<host>/default.nix` escape hatches for the initial host unless normal Blueprint mapping cannot express the configuration.
