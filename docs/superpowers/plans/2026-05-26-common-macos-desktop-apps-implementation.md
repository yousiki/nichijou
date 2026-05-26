# Common macOS Desktop Apps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the approved shared macOS desktop app set through Home Manager and enable Tailscale through nix-darwin's native service module.

**Architecture:** Generic GUI apps live in a new shared Home Manager module at `nix/modules/home/programs/desktop-apps.nix`, imported by `nix/modules/home/desktop.nix` next to the existing Kitty module. Tailscale is not a GUI app; it gets a focused Darwin module at `nix/modules/darwin/tailscale.nix` imported by the `sakurai` host.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, nixpkgs, brew-nix.

---

## File Structure

- Create: `nix/modules/home/programs/desktop-apps.nix`
  - Owns generic shared GUI app installation with `home.packages`.
  - Enables `targets.darwin.linkApps.enable` so `.app` bundles are linked into the user environment.
- Modify: `nix/modules/home/desktop.nix`
  - Imports `./programs/desktop-apps.nix` before `./programs/kitty.nix`.
- Create: `nix/modules/darwin/tailscale.nix`
  - Enables the system-level Tailscale daemon with nix-darwin's `services.tailscale.enable`.
- Modify: `nix/hosts/sakurai/darwin-configuration.nix`
  - Imports `flake.darwinModules.tailscale`.

---

### Task 1: Add Shared Desktop Apps Home Manager Module

**Files:**
- Create: `nix/modules/home/programs/desktop-apps.nix`
- Modify: `nix/modules/home/desktop.nix`

- [ ] **Step 1: Verify the current desktop-apps module is absent and Darwin app linking is disabled**

Run:

```bash
test ! -f nix/modules/home/programs/desktop-apps.nix
nix eval --impure --json .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.targets.darwin.linkApps.enable
```

Expected:

```text
false
```

The `test` command should exit 0. The `nix eval` command should print `false`.

- [ ] **Step 2: Create `nix/modules/home/programs/desktop-apps.nix`**

Create the file with exactly this content:

```nix
{ pkgs, ... }:

{
  targets.darwin.linkApps.enable = true;

  home.packages = with pkgs; [
    raycast
    rectangle
    maccy
    iina
    obsidian
    brave
    _1password-gui
    monitorcontrol
    orbstack
    slack
    spotify
    zoom-us
    zed-editor

    brewCasks.chatgpt-atlas
    brewCasks.cloudflare-warp
    brewCasks.dockdoor
    brewCasks.keepingyouawake
    brewCasks.keka
    brewCasks.linearmouse
    brewCasks.thaw
    brewCasks.zotero
  ];
}
```

- [ ] **Step 3: Update `nix/modules/home/desktop.nix`**

Replace the file with exactly this content:

```nix
{ ... }:

{
  imports = [
    ./programs/desktop-apps.nix
    ./programs/kitty.nix
  ];
}
```

- [ ] **Step 4: Verify Home Manager sees the desktop app module**

Run:

```bash
nix eval --impure --json .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.targets.darwin.linkApps.enable
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; packages = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.packages; names = map (pkg: pkg.pname or pkg.name) packages; selected = [ "raycast" "rectangle" "maccy" "iina" "obsidian" "brave" "1password" "MonitorControl" "orbstack" "slack" "spotify" "zoom" "zed-editor" "chatgpt-atlas" "cloudflare-warp" "dockdoor" "keepingyouawake" "keka" "linearmouse" "thaw" "zotero" ]; in builtins.all (name: builtins.elem name names) selected'
```

Expected:

```text
true
true
```

The first command proves Darwin app linking is enabled. The second proves every selected desktop package is in `home.packages`.

- [ ] **Step 5: Dry-run the selected desktop app package set**

Run:

```bash
nix build --impure --dry-run --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in pkgs.symlinkJoin { name = "selected-desktop-apps-dry-run"; paths = [ pkgs.raycast pkgs.rectangle pkgs.maccy pkgs.iina pkgs.obsidian pkgs.brave pkgs._1password-gui pkgs.monitorcontrol pkgs.orbstack pkgs.slack pkgs.spotify pkgs.zoom-us pkgs.zed-editor pkgs.brewCasks.chatgpt-atlas pkgs.brewCasks.cloudflare-warp pkgs.brewCasks.dockdoor pkgs.brewCasks.keepingyouawake pkgs.brewCasks.keka pkgs.brewCasks.linearmouse pkgs.brewCasks.thaw pkgs.brewCasks.zotero ]; }'
```

Expected: command exits 0. A warning about `cloudflare-warp` using nested `nativeBuildInputs` is acceptable with the current lock; any missing attribute or build planning failure is not acceptable.

- [ ] **Step 6: Commit desktop app module**

Run:

```bash
git add nix/modules/home/desktop.nix nix/modules/home/programs/desktop-apps.nix
git commit -m "home: add common macos desktop apps"
```

Expected: commit succeeds and includes only these two files.

---

### Task 2: Enable Tailscale Through nix-darwin

**Files:**
- Create: `nix/modules/darwin/tailscale.nix`
- Modify: `nix/hosts/sakurai/darwin-configuration.nix`

- [ ] **Step 1: Verify the current Tailscale service is disabled**

Run:

```bash
test ! -f nix/modules/darwin/tailscale.nix
nix eval --impure --json .#darwinConfigurations.sakurai.config.services.tailscale.enable
```

Expected:

```text
false
```

The `test` command should exit 0. The `nix eval` command should print `false`.

- [ ] **Step 2: Create `nix/modules/darwin/tailscale.nix`**

Create the file with exactly this content:

```nix
{ ... }:

{
  services.tailscale.enable = true;
}
```

- [ ] **Step 3: Import the Tailscale Darwin module in `sakurai`**

Replace `nix/hosts/sakurai/darwin-configuration.nix` with exactly this content:

```nix
{ flake, hostName, ... }:

{
  imports = [
    flake.darwinModules.common
    flake.darwinModules.nix
    flake.darwinModules.homebrew
    flake.darwinModules.tailscale
  ];

  networking.hostName = hostName;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "yousiki";

  users.users.yousiki = {
    home = "/Users/yousiki";
  };

  system.configurationRevision = flake.rev or flake.dirtyRev or null;

  system.stateVersion = 6;
}
```

- [ ] **Step 4: Verify Tailscale is enabled through nix-darwin**

Run:

```bash
nix eval --impure --json .#darwinConfigurations.sakurai.config.services.tailscale.enable
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; cfg = flake.darwinConfigurations.sakurai.config; in builtins.elem cfg.services.tailscale.package cfg.environment.systemPackages'
```

Expected:

```text
true
true
```

The first command proves the daemon is enabled. The second proves nix-darwin adds the configured Tailscale package to system packages.

- [ ] **Step 5: Commit Tailscale service module**

Run:

```bash
git add nix/modules/darwin/tailscale.nix nix/hosts/sakurai/darwin-configuration.nix
git commit -m "darwin: enable tailscale service"
```

Expected: commit succeeds and includes only these two files.

---

### Task 3: Full Host Verification

**Files:**
- Verify: `flake.nix`
- Verify: `nix/modules/home/programs/desktop-apps.nix`
- Verify: `nix/modules/darwin/tailscale.nix`
- Verify: `nix/hosts/sakurai/darwin-configuration.nix`

- [ ] **Step 1: Verify Blueprint exposes the new modules**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in { homeModules = builtins.hasAttr "desktop" flake.homeModules; darwinModules = builtins.hasAttr "tailscale" flake.darwinModules; }'
```

Expected:

```json
{"darwinModules":true,"homeModules":true}
```

- [ ] **Step 2: Verify excluded apps were not added**

Run:

```bash
if rg -n 'pkgs\.(stats|firefox|discord)|\b(stats|firefox|discord)\b|tailscale-app|tailscale-gui' nix/modules/home nix/modules/darwin nix/hosts/sakurai; then
  exit 1
fi
```

Expected: command exits 0 and prints no matches. Tailscale service references such as `services.tailscale` are allowed; GUI app references are not.

- [ ] **Step 3: Verify Home Manager activation package builds**

Run:

```bash
nix build --impure --no-link .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.activationPackage
```

Expected: command exits 0. The `cloudflare-warp` nested `nativeBuildInputs` warning is acceptable with the current lock; build failure is not acceptable.

- [ ] **Step 4: Verify the Darwin host builds**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: command exits 0. If this fails only because of a known upstream `brew-nix` package warning becoming an error, do not hide it; report the exact failing package and move that package to `homebrew.casks` only after explicit user approval.

- [ ] **Step 5: Verify working tree state**

Run:

```bash
git status --short
```

Expected: no output.

---

## Self-Review

- Spec coverage: Task 1 covers the Home Manager desktop app module, Darwin app linking, selected nixpkgs apps, selected brew-nix casks, and excluded GUI apps. Task 2 covers Tailscale via nix-darwin service. Task 3 covers Blueprint exposure, excluded-app checks, Home Manager build, and full Darwin build.
- Marker scan: No unresolved markers, copy-forward shortcuts, or vague validation steps remain.
- Type and option consistency: Home Manager uses `targets.darwin.linkApps.enable` and `home.packages`; nix-darwin uses `services.tailscale.enable`; package references match the approved spec.
