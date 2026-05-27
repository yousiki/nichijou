# cmux and Ghostty Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move cmux out of nix-darwin Homebrew casks, manage cmux app settings through Home Manager, and install/configure Ghostty through its Home Manager module.

**Architecture:** Add focused Home Manager modules at `nix/modules/home/programs/cmux.nix` and `nix/modules/home/programs/ghostty.nix`. The cmux module installs `pkgs.brewCasks.cmux`, uses Home Manager's existing Darwin app copy mechanism, and writes `~/.config/cmux/cmux.json` via `xdg.configFile`. The Ghostty module uses Home Manager's Ghostty module with `pkgs.brewCasks.ghostty`, because the locked nixpkgs `pkgs.ghostty` package is Linux-only. It writes `~/.config/ghostty/config` through `programs.ghostty.settings`, while the existing Catppuccin Home Manager integration owns the Ghostty theme entry.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, brew-nix.

---

## File Structure

- Create: `nix/modules/home/programs/cmux.nix`
  - Owns cmux installation and global cmux config.
- Create: `nix/modules/home/programs/ghostty.nix`
  - Owns Ghostty installation and terminal rendering config used by Ghostty and cmux.
- Modify: `nix/modules/home/desktop.nix`
  - Imports the cmux and Ghostty modules next to the existing desktop program modules.
- Modify: `nix/modules/darwin/homebrew.nix`
  - Removes the cmux cask and the no-longer-needed `manaflow-ai/homebrew-cmux` tap.
- Modify: `flake.nix`
  - Removes the no-longer-needed `homebrew-cmux` input.
- Modify: `flake.lock`
  - Refreshes the root input graph after removing `homebrew-cmux`.

### Task 1: Add cmux Home Manager Module

**Files:**
- Create: `nix/modules/home/programs/cmux.nix`
- Create: `nix/modules/home/programs/ghostty.nix`
- Modify: `nix/modules/home/desktop.nix`

- [ ] **Step 1: Verify target behavior is missing**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; names = map (pkg: pkg.pname or pkg.name) hm.home.packages; in assert builtins.elem "cmux" names; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.ghostty.enable; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; settings = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki.programs.ghostty.settings; in assert settings."font-family" == "Maple Mono NF CN"; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert !(hm.targets.darwin.copyApps.enable && hm.targets.darwin.linkApps.enable); true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert builtins.hasAttr "cmux/cmux.json" hm.xdg.configFile; true'
```

Expected: the cmux package, Ghostty enable, Ghostty font, and cmux config commands fail before implementation. The app-copy conflict command should pass before implementation and remain green after implementation.

- [ ] **Step 2: Create `nix/modules/home/programs/cmux.nix`**

Use:

```nix
{ pkgs, ... }:

let
  cmuxConfig = (pkgs.formats.json { }).generate "cmux.json" {
    "$schema" = "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json";
    schemaVersion = 1;
  };
in
{
  targets.darwin.copyApps.enable = true;

  home.packages = [
    pkgs.brewCasks.cmux
  ];

  xdg.configFile."cmux/cmux.json".source = cmuxConfig;
}
```

- [ ] **Step 3: Import the cmux module from `nix/modules/home/desktop.nix`**

Use:

```nix
{ ... }:

{
  imports = [
    ./programs/desktop-apps.nix
    ./programs/cmux.nix
    ./programs/kitty.nix
  ];
}
```

### Task 2: Remove Homebrew cmux Wiring

**Files:**
- Modify: `nix/modules/darwin/homebrew.nix`
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] **Step 1: Verify cmux is currently in nix-darwin Homebrew casks**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; casks = flake.darwinConfigurations.sakurai.config.homebrew.casks; names = map (cask: cask.name) casks; in assert !(builtins.elem "cmux" names); true'
```

Expected: command fails with `error: assertion failed`.

- [ ] **Step 2: Remove `cmux` from `homebrew.casks` and remove `manaflow-ai/homebrew-cmux` from `nix-homebrew.taps`**

Keep only casks that still need nix-darwin Homebrew installation.

- [ ] **Step 3: Remove the `homebrew-cmux` flake input**

Delete the input block:

```nix
homebrew-cmux = {
  url = "github:manaflow-ai/homebrew-cmux";
  flake = false;
};
```

- [ ] **Step 4: Refresh `flake.lock`**

Run:

```bash
nix flake lock --offline
```

Expected: `flake.lock` no longer lists the root input `homebrew-cmux`.

### Task 3: Verify cmux Home Manager Integration

**Files:**
- Verify: `nix/modules/home/programs/cmux.nix`
- Verify: `nix/modules/home/desktop.nix`
- Verify: `nix/modules/darwin/homebrew.nix`
- Verify: `flake.nix`
- Verify: `flake.lock`

- [ ] **Step 1: Run the green assertions**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; casks = flake.darwinConfigurations.sakurai.config.homebrew.casks; names = map (cask: cask.name) casks; in assert !(builtins.elem "cmux" names); true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; names = map (pkg: pkg.pname or pkg.name) hm.home.packages; in assert builtins.elem "cmux" names; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert !(hm.targets.darwin.copyApps.enable && hm.targets.darwin.linkApps.enable); true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert builtins.hasAttr "cmux/cmux.json" hm.xdg.configFile; true'
```

Expected: each command prints `true`.

- [ ] **Step 2: Verify the generated cmux config content**

Run:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in hm.xdg.configFile."cmux/cmux.json".source'
```

Expected: output is a Nix store path containing `cmux.json`. Reading that path shows `$schema` and `schemaVersion`.

- [ ] **Step 3: Verify cmux package planning**

Run:

```bash
nix build --impure --dry-run --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.brewCasks.cmux'
```

Expected: command exits 0.

- [ ] **Step 4: Verify the host configuration builds**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: command exits 0.

- [ ] **Step 5: Inspect the final diff**

Run:

```bash
git diff --check
git diff --stat
```

Expected: no whitespace errors, and the diff is limited to the cmux Home Manager migration plus the plan file.
