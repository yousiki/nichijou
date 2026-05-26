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
- `_1password-gui`
- `dockdoor`
- `keepingyouawake`
- `monitorcontrol`
- `slack`
- `zoom-us`
- `zed-editor`

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
pkgs.slack
pkgs.zoom-us
pkgs.zed-editor
```

Use `brew-nix` for apps not available in nixpkgs but available as fixed-output casks:

```nix
pkgs.brewCasks.dockdoor
pkgs.brewCasks.keepingyouawake
```

`dockdoor` was checked in the current `sakurai` nix-darwin package set. `pkgs.brewCasks.dockdoor` exists, evaluates as `dockdoor-1.38.1`, supports `aarch64-darwin`, is not marked broken, has a fixed SHA-256 source hash, and builds successfully with the locked inputs.

Do not add DockDoor to `homebrew.casks` unless `brew-nix` breaks in a future lock update.

`keepingyouawake` was checked in the current `sakurai` nix-darwin package set. It is not available as a nixpkgs package, but `pkgs.brewCasks.keepingyouawake` exists, evaluates as `keepingyouawake-1.6.8`, supports `aarch64-darwin`, is not marked broken, has a fixed SHA-256 source hash, and builds successfully with the locked inputs.

Do not add KeepingYouAwake to `homebrew.casks` unless `brew-nix` breaks in a future lock update.

Zed should use the nixpkgs package `pkgs.zed-editor`, not `pkgs.zed`. The `pkgs.zed` attribute is a different data tool. `pkgs.zed-editor` was checked in the current `sakurai` nix-darwin package set, evaluates as `zed-editor-1.3.6`, supports `aarch64-darwin`, is not marked broken, and builds successfully with the locked inputs.

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
```

## Error Handling

If a nixpkgs GUI package is removed or renamed, Home Manager evaluation should fail at the package reference.

If `brew-nix` removes `dockdoor` or `keepingyouawake`, or changes their packaging behavior, Home Manager evaluation or build should fail at the corresponding `pkgs.brewCasks` reference. The fallback is nix-darwin `homebrew.casks`, but that should be a deliberate future change rather than the default for this implementation.

Some GUI apps may require macOS privacy permissions, login item approval, browser sign-in, or app-specific first-run setup after activation. Nix can install them but cannot complete those runtime approvals.

## Verification

Implementation should verify at least:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in builtins.hasAttr "dockdoor" pkgs.brewCasks'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in builtins.hasAttr "keepingyouawake" pkgs.brewCasks'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.brewCasks.dockdoor'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.brewCasks.keepingyouawake'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.zed-editor'
darwin-rebuild build --flake .#sakurai
```

If `darwin-rebuild build` is too expensive, run the most targeted Home Manager build output available from `nix flake show` and document why the full host build was skipped.

## Non-Goals

- Do not add `stats`.
- Do not add Firefox; Brave is the selected browser.
- Do not add Discord.
- Do not add VS Code or Cursor in this change; Zed is the selected GUI code editor.
- Do not configure app preferences unless the app has an existing first-class Home Manager module or a clear, stable declarative settings interface.
- Do not add selected apps to nix-darwin `homebrew.casks` while nixpkgs or `brew-nix` package references work.
