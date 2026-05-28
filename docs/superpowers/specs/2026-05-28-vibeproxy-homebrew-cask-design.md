# VibeProxy Homebrew Cask Design

## Goal

Install VibeProxy on the `sakurai` macOS host through this nix-darwin repository.

## Selected Approach

Use nix-darwin's declarative Homebrew integration:

```nix
homebrew.casks = [
  "vibeproxy"
];
```

VibeProxy is available from the official `homebrew/cask` tap, which this repository already pins and manages through `nix-homebrew`. Do not add a third-party tap, new flake input, or hand-written Nix derivation for this app.

## Rationale

`vibeproxy` is not available in nixpkgs. It is a signed and notarized macOS menu bar application distributed as a Homebrew cask, and the cask declares Apple Silicon and macOS Ventura-or-newer requirements that match the current host.

Installing it via nix-darwin `homebrew.casks` keeps the app in `/Applications`, follows the repository's existing policy for macOS apps that need normal Homebrew installation behavior, and avoids maintaining a custom DMG derivation.

## Implementation

Modify:

```text
nix/modules/darwin/homebrew.nix
```

Add `"vibeproxy"` to the existing `homebrew.casks` list.

## Verification

Run:

```bash
git diff --check
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; casks = map (cask: cask.name) flake.darwinConfigurations.sakurai.config.homebrew.casks; in assert builtins.elem "vibeproxy" casks; true'
darwin-rebuild build --flake .#sakurai
```

If Nix daemon access is blocked by the execution sandbox, rerun the Nix commands with the required permissions or report the sandbox limitation explicitly.

## Non-Goals

- Do not install Quotio.
- Do not add a VibeProxy-specific Home Manager module.
- Do not configure VibeProxy accounts, launch-at-login behavior, proxy ports, or provider credentials.
- Do not refresh unrelated flake inputs.
