# Common macOS Desktop Apps Design

## Goal

Add a shared set of common macOS desktop applications to this nix-darwin repository, following the existing Kitty desktop-app structure and the repository's Darwin package policy.

The target host for validation is the current Apple Silicon macOS host, `sakurai`, for user `yousiki`.

## Selected Apps

Install these desktop applications:

- `raycast`
- `rectangle`
- `maccy`
- `iina`
- `obsidian`
- `brave`
- `chatgpt-atlas`
- `cloudflare-warp`
- `_1password-gui`
- `dockdoor`
- `keepingyouawake`
- `keka`
- `linearmouse`
- `monitorcontrol`
- `orbstack`
- `slack`
- `spotify`
- `thaw`
- `zoom-us`
- `zed-editor`
- `zotero`

Do not install these applications in this change:

- `stats`
- `firefox`
- `discord`

## Package Source Policy

Use a Nix-first hybrid model, but avoid nix-darwin `homebrew.casks` for this set because every selected app is available through either nixpkgs or `brew-nix`.

Use nixpkgs packages for:

```nix
pkgs.raycast
pkgs.rectangle
pkgs.maccy
pkgs.iina
pkgs.obsidian
pkgs.brave
pkgs._1password-gui
pkgs.monitorcontrol
pkgs.orbstack
pkgs.slack
pkgs.spotify
pkgs.zoom-us
pkgs.zed-editor
```

Use `brew-nix` for fixed-output casks that are unavailable in nixpkgs, are materially better as current macOS app casks, or avoid expensive nixpkgs source builds:

```nix
pkgs.brewCasks.chatgpt-atlas
pkgs.brewCasks.cloudflare-warp
pkgs.brewCasks.dockdoor
pkgs.brewCasks.keepingyouawake
pkgs.brewCasks.keka
pkgs.brewCasks.linearmouse
pkgs.brewCasks.thaw
pkgs.brewCasks.zotero
```

`dockdoor` was checked in the current `sakurai` nix-darwin package set. `pkgs.brewCasks.dockdoor` exists, evaluates as `dockdoor-1.38.1`, supports `aarch64-darwin`, is not marked broken, has a fixed SHA-256 source hash, and builds successfully with the locked inputs.

Do not add DockDoor to `homebrew.casks` unless `brew-nix` breaks in a future lock update.

`keepingyouawake` was checked in the current `sakurai` nix-darwin package set. It is not available as a nixpkgs package, but `pkgs.brewCasks.keepingyouawake` exists, evaluates as `keepingyouawake-1.6.8`, supports `aarch64-darwin`, is not marked broken, has a fixed SHA-256 source hash, and builds successfully with the locked inputs.

Do not add KeepingYouAwake to `homebrew.casks` unless `brew-nix` breaks in a future lock update.

Zed should use the nixpkgs package `pkgs.zed-editor`, not `pkgs.zed`. The `pkgs.zed` attribute is a different data tool. `pkgs.zed-editor` was checked in the current `sakurai` nix-darwin package set, evaluates as `zed-editor-1.3.6`, supports `aarch64-darwin`, is not marked broken, and builds successfully with the locked inputs.

The additional requested apps were checked in the current `sakurai` nix-darwin package set:

- `pkgs.spotify` evaluates as `spotify-1.2.89.539`, supports `aarch64-darwin`, and enters a dry-run build plan. The `brew-nix` `spotify` cask currently has a placeholder hash, so use nixpkgs instead.
- `pkgs.orbstack` evaluates as `orbstack-2.1.3-20115`, supports `aarch64-darwin`, and enters a dry-run build plan. A `brew-nix` cask also exists at the same upstream version, but nixpkgs is sufficient here.
- `pkgs.brewCasks.zotero` evaluates as `zotero-9.0.4`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan. Prefer this over `pkgs.zotero` for now because the current `aarch64-darwin` nixpkgs output is not available from the checked binary caches and would trigger a large source build. Switch Zotero back to `pkgs.zotero` later if a suitable binary cache is added or the current output becomes cached.
- `pkgs.brewCasks.thaw` evaluates as `thaw-1.2.0`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan.
- `pkgs.brewCasks.linearmouse` evaluates as `linearmouse-0.11.2`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan.
- `pkgs.brewCasks.keka` evaluates as `keka-1.6.4`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan. Prefer this over the older nixpkgs `keka` package in the current lock.
- `pkgs.brewCasks.cloudflare-warp` evaluates as `cloudflare-warp-2026.4.1350.0`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan. Prefer this over the older nixpkgs `cloudflare-warp` package in the current lock.
- `pkgs.brewCasks.chatgpt-atlas` evaluates as `chatgpt-atlas-1.2026.119.1-20260504231115000`, supports `aarch64-darwin`, has a fixed SHA-256 source hash, and enters a dry-run build plan. The nixpkgs `chatgpt` package is the ChatGPT desktop app, not the Atlas browser.

Do not install Tailscale as a desktop app. The most Nix-native path is the nix-darwin Tailscale service:

```nix
services.tailscale.enable = true;
```

The nix-darwin option `services.tailscale.enable` exists and enables the Tailscale client daemon. Add a Darwin module for this service instead of adding `pkgs.tailscale-gui`, `pkgs.brewCasks.tailscale-app`, or a Home Manager desktop package.

## Module Structure

Keep `nix/modules/home/desktop.nix` as the shared Home Manager entry point for GUI and desktop applications.

Add a new Home Manager module:

```text
nix/modules/home/
  desktop.nix
  programs/
    desktop-apps.nix
    kitty.nix
```

Add a new Darwin module for the system-level Tailscale daemon:

```text
nix/modules/darwin/
  tailscale.nix
```

The current `sakurai` Darwin host should import this module through Blueprint:

```nix
imports = [
  flake.darwinModules.common
  flake.darwinModules.nix
  flake.darwinModules.homebrew
  flake.darwinModules.tailscale
];
```

`desktop.nix` should import both desktop modules:

```nix
imports = [
  ./programs/desktop-apps.nix
  ./programs/kitty.nix
];
```

`desktop-apps.nix` should own generic desktop application installation through `home.packages`. Kitty remains in `kitty.nix` because it has first-class Home Manager options and app-specific configuration.

## Darwin App Linking

Enable Home Manager's Darwin app linking so Nix-installed `.app` bundles are discoverable from the user environment:

```nix
targets.darwin.linkApps.enable = true;
```

Keep this in `desktop-apps.nix`, close to the desktop packages it supports.

## Data Flow

```text
flake.nix
  applies brew-nix overlay on Darwin
    -> sakurai nix-darwin package set exposes pkgs.brewCasks
      -> home/desktop.nix imports programs/desktop-apps.nix
        -> desktop-apps.nix adds nixpkgs GUI apps and selected pkgs.brewCasks apps
          -> targets.darwin.linkApps links .app bundles into the user environment
      -> darwin/tailscale.nix enables services.tailscale
```

## Error Handling

If a nixpkgs GUI package is removed or renamed, Home Manager evaluation should fail at the package reference.

If `brew-nix` removes any selected cask or changes its packaging behavior, Home Manager evaluation or build should fail at the corresponding `pkgs.brewCasks` reference. The fallback is nix-darwin `homebrew.casks`, but that should be a deliberate future change rather than the default for this implementation.

The current dry-run emits a `nativeBuildInputs` deprecation warning for the `cloudflare-warp` brew-nix cask. It is a warning in the current lock, not a build failure. If a future nixpkgs release turns it into a failure before `brew-nix` fixes it, move Cloudflare WARP to nix-darwin `homebrew.casks`.

Some GUI apps may require macOS privacy permissions, login item approval, browser sign-in, or app-specific first-run setup after activation. Nix can install them but cannot complete those runtime approvals.

## Verification

Implementation should verify at least:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in builtins.hasAttr "dockdoor" pkgs.brewCasks'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in builtins.hasAttr "keepingyouawake" pkgs.brewCasks'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.brewCasks.dockdoor'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.brewCasks.keepingyouawake'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.zed-editor'
nix build --impure --dry-run --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in pkgs.symlinkJoin { name = "selected-new-desktop-apps-dry-run"; paths = [ pkgs.spotify pkgs.orbstack pkgs.brewCasks.zotero pkgs.brewCasks.thaw pkgs.brewCasks.linearmouse pkgs.brewCasks.keka pkgs.brewCasks.cloudflare-warp pkgs.brewCasks.chatgpt-atlas ]; }'
nix eval --impure --json .#darwinConfigurations.sakurai.config.services.tailscale.enable
darwin-rebuild build --flake .#sakurai
```

If `darwin-rebuild build` is too expensive, run the most targeted Home Manager build output available from `nix flake show` and document why the full host build was skipped.

## Non-Goals

- Do not add `stats`.
- Do not add Firefox; Brave is the selected browser.
- Do not add Discord.
- Do not add Tailscale as a GUI desktop app; use the nix-darwin Tailscale daemon.
- Do not add VS Code or Cursor in this change; Zed is the selected GUI code editor.
- Do not configure app preferences unless the app has an existing first-class Home Manager module or a clear, stable declarative settings interface.
- Do not add selected apps to nix-darwin `homebrew.casks` while nixpkgs or `brew-nix` package references work.
