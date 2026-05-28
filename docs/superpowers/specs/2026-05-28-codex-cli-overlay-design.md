# Codex CLI Overlay Design

## Goal

Keep the Home Manager-managed `codex` command closer to upstream OpenAI Codex CLI releases than the package currently available through the locked `nixpkgs` input.

The target host for validation is the current Apple Silicon macOS host, `sakurai`.

## Selected Approach

Use `sadjow/codex-cli-nix` as a flake input and apply its default overlay in the existing Blueprint `nixpkgs.overlays` list.

This matches the repository's existing `claude-code` integration: a community-maintained flake provides the package overlay, the Home Manager program module continues to select `pkgs.codex`, and the Darwin Nix module owns the binary cache trust settings. It avoids Homebrew, manual npm installs, and ad hoc wrappers.

The existing Home Manager module stays unchanged:

```nix
programs.codex = {
  enable = true;
  package = pkgs.codex;
};
```

After the overlay is applied, `pkgs.codex` resolves to the overlaid package.

## Flake Input And Overlay

Add a new input:

```nix
codex-cli = {
  url = "github:sadjow/codex-cli-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add the overlay beside the existing `claude-code` overlay:

```nix
nixpkgs.overlays = [
  inputs.claude-code.overlays.default
  inputs.codex-cli.overlays.default
  ...
];
```

The input follows the repository's `nixpkgs` input so dependency resolution stays aligned with the rest of the machine configuration.

## Cachix Trust

Add the upstream binary cache to `nix/modules/darwin/nix.nix`:

```nix
nix.settings.substituters = [
  "https://claude-code.cachix.org"
  "https://codex-cli.cachix.org"
];

nix.settings.trusted-public-keys = [
  "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
  "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
];
```

This keeps cache trust in the existing Darwin Nix settings module rather than scattering it across Home Manager modules.

## Data Flow

```text
flake.nix
  declares inputs.codex-cli
  applies inputs.codex-cli.overlays.default
    -> pkgs.codex comes from codex-cli-nix
      -> nix/modules/home/programs/codex.nix selects pkgs.codex
        -> Home Manager exposes the codex command

nix/modules/darwin/nix.nix
  trusts https://codex-cli.cachix.org
    -> Nix may substitute prebuilt Codex CLI outputs when available
```

## Error Handling

If `sadjow/codex-cli-nix` changes or removes `overlays.default`, evaluation should fail at `flake.nix`.

If the overlay stops exposing `pkgs.codex`, Home Manager evaluation should fail in `nix/modules/home/programs/codex.nix`.

If the Cachix key is wrong, Nix should reject substitutions from `https://codex-cli.cachix.org`; the derivation can still build or fetch normally if its fixed-output hashes are valid.

## Verification

Before implementation, verify that the current effective `pkgs.codex.version` does not satisfy the target version:

```bash
nix eval --impure --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; overlays = flake.outputs.overlays or []; }; in assert pkgs.lib.versionAtLeast pkgs.codex.version "0.134.0"; pkgs.codex.version'
```

Expected before implementation: assertion failure.

After implementation, verify:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; overlays = flake.outputs.overlays or []; }; in pkgs.codex.version'
```

Expected output:

```text
0.134.0
```

Also verify the host build:

```bash
darwin-rebuild build --flake .#sakurai
```

If build or evaluation fails with `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted`, rerun with the required sandbox escalation or report the daemon-access failure as an environment problem.

## Non-Goals

- Do not replace Home Manager's `programs.codex` module.
- Do not install Codex through Homebrew, npm, or a shell wrapper.
- Do not add provider, model, API-key, or runtime Codex settings.
- Do not change unrelated AI coding tools such as `claude-code`, `opencode`, `jcode`, or `cmux`.
