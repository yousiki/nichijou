# Kitty Desktop App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Kitty Terminal as the first shared Home Manager managed desktop app, with global Catppuccin Mocha theming and Maple Mono font configuration.

**Architecture:** Add `catppuccin/nix` as a flake input and import its Home Manager module from shared `home/common.nix`. Add a new shared `home/desktop.nix` entry point for GUI and desktop applications, with Kitty isolated in `home/programs/kitty.nix`. Wire the current `yousiki@sakurai` Home Manager configuration into the new desktop module.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, catppuccin/nix, Kitty.

---

## File Structure

- Modify: `flake.nix`
  - Add the `catppuccin/nix` input.
  - Make the Catppuccin input follow the repository's existing `nixpkgs` input.
- Modify: `flake.lock`
  - Add the locked Catppuccin input after updating the flake lock.
- Modify: `nix/modules/home/common.nix`
  - Import `inputs.catppuccin.homeModules.catppuccin`.
  - Enable Catppuccin globally with the Mocha flavor.
- Create: `nix/modules/home/desktop.nix`
  - Shared Home Manager entry point for GUI and desktop applications.
  - Initially imports only `./programs/kitty.nix`.
- Create: `nix/modules/home/programs/kitty.nix`
  - Enables Kitty through Home Manager.
  - Uses `pkgs.kitty`, Maple Mono, and macOS-oriented Kitty settings.
- Modify: `nix/hosts/sakurai/users/yousiki/home-configuration.nix`
  - Import `flake.homeModules.desktop` for the current user.

## References

- `docs/superpowers/specs/2026-05-26-kitty-desktop-app-design.md`
- Catppuccin flakes guide: https://nix.catppuccin.com/getting-started/flakes/
- Catppuccin Home Manager options: https://nix.catppuccin.com/options/main/home/catppuccin/
- Catppuccin Kitty options: https://nix.catppuccin.com/options/main/home/catppuccin.kitty/

## Task 1: Add The Catppuccin Flake Input

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] **Step 1: Replace `flake.nix` with the Catppuccin input added**

Use this complete file:

```nix
{
  description = "Multi-host nix-darwin and NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = "nix/";

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
        inputs.claude-code.overlays.default
        (
          final: prev:
          if prev.stdenv.hostPlatform.isDarwin then inputs.brew-nix.overlays.default final prev else { }
        )
      ];
    };
}
```

- [ ] **Step 2: Update `flake.lock` for the new input**

Run:

```bash
nix flake lock
```

Expected: command exits 0 and `flake.lock` gains a `catppuccin` node.

- [ ] **Step 3: Verify the lock contains Catppuccin**

Run:

```bash
nix flake metadata --json | jq -e '.locks.nodes.catppuccin.locked.owner == "catppuccin" and .locks.nodes.catppuccin.locked.repo == "nix"'
```

Expected output:

```text
true
```

- [ ] **Step 4: Commit the flake input change**

Run:

```bash
git add flake.nix flake.lock
git commit -m "flake: add catppuccin input"
```

Expected: commit succeeds and includes only `flake.nix` and `flake.lock`.

## Task 2: Enable Global Catppuccin In Shared Home Manager Common

**Files:**
- Modify: `nix/modules/home/common.nix`

- [ ] **Step 1: Replace `nix/modules/home/common.nix` with the global Catppuccin import**

Use this complete file:

```nix
{ inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  home.enableNixpkgsReleaseCheck = false;

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  programs.home-manager.enable = true;
}
```

- [ ] **Step 2: Verify Home Manager module evaluation still exposes common modules**

Run:

```bash
nix eval --json --no-write-lock-file .#homeModules --apply builtins.attrNames
```

Expected output includes:

```json
["cli","common","programs"]
```

The order may differ, but `common` must be present and the command must exit 0.

- [ ] **Step 3: Commit the global Catppuccin Home Manager module change**

Run:

```bash
git add nix/modules/home/common.nix
git commit -m "home: enable catppuccin mocha"
```

Expected: commit succeeds and includes only `nix/modules/home/common.nix`.

## Task 3: Add The Shared Desktop Entry Point And Kitty Module

**Files:**
- Create: `nix/modules/home/desktop.nix`
- Create: `nix/modules/home/programs/kitty.nix`

- [ ] **Step 1: Create `nix/modules/home/desktop.nix`**

Use this complete file:

```nix
{ ... }:

{
  imports = [
    ./programs/kitty.nix
  ];
}
```

- [ ] **Step 2: Create `nix/modules/home/programs/kitty.nix`**

Use this complete file:

```nix
{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;

    font = {
      name = "Maple Mono NF CN";
      size = 14;
    };

    settings = {
      macos_option_as_alt = "both";
      macos_quit_when_last_window_closed = "yes";
      confirm_os_window_close = 0;
      window_padding_width = 6;
      hide_window_decorations = "titlebar-only";
      shell_integration = "enabled";
      copy_on_select = "clipboard";
      scrollback_lines = 10000;
      enable_audio_bell = false;
    };
  };
}
```

- [ ] **Step 3: Verify Blueprint exposes the new desktop home module**

Run:

```bash
nix eval --json --no-write-lock-file .#homeModules --apply builtins.attrNames
```

Expected output includes:

```json
["cli","common","desktop","programs"]
```

The order may differ, but `desktop` must be present and the command must exit 0.

- [ ] **Step 4: Commit the desktop and Kitty modules**

Run:

```bash
git add nix/modules/home/desktop.nix nix/modules/home/programs/kitty.nix
git commit -m "home: add kitty desktop module"
```

Expected: commit succeeds and includes only the two new module files.

## Task 4: Wire The Desktop Module Into `yousiki@sakurai`

**Files:**
- Modify: `nix/hosts/sakurai/users/yousiki/home-configuration.nix`

- [ ] **Step 1: Replace `nix/hosts/sakurai/users/yousiki/home-configuration.nix` with the desktop import added**

Use this complete file:

```nix
{ flake, ... }:

{
  imports = [
    flake.homeModules.common
    flake.homeModules.cli
    flake.homeModules.desktop
  ];

  home.stateVersion = "26.05";
}
```

- [ ] **Step 2: Verify the standalone Home Manager output still exists**

Run:

```bash
nix eval --json --no-write-lock-file .#homeConfigurations --apply builtins.attrNames
```

Expected output:

```json
["yousiki@sakurai"]
```

- [ ] **Step 3: Build the standalone Home Manager activation package**

Run:

```bash
nix build --no-link --print-out-paths '.#homeConfigurations."yousiki@sakurai".activationPackage'
```

Expected: command exits 0 and prints one `/nix/store/...-home-manager-generation` path.

- [ ] **Step 4: Verify the generated Kitty config exists**

Run:

```bash
home_out="$(nix build --no-link --print-out-paths '.#homeConfigurations."yousiki@sakurai".activationPackage')"
test -f "$home_out/home-files/.config/kitty/kitty.conf"
```

Expected: command exits 0.

- [ ] **Step 5: Verify key Kitty settings are rendered**

Run:

```bash
home_out="$(nix build --no-link --print-out-paths '.#homeConfigurations."yousiki@sakurai".activationPackage')"
rg -n 'font_family|font_size|macos_option_as_alt|copy_on_select|scrollback_lines' "$home_out/home-files/.config/kitty/kitty.conf"
```

Expected output contains lines for:

```text
font_family Maple Mono NF CN
font_size 14
macos_option_as_alt both
copy_on_select clipboard
scrollback_lines 10000
```

- [ ] **Step 6: Commit the host user desktop import**

Run:

```bash
git add nix/hosts/sakurai/users/yousiki/home-configuration.nix
git commit -m "home: enable desktop apps for sakurai"
```

Expected: commit succeeds and includes only `nix/hosts/sakurai/users/yousiki/home-configuration.nix`.

## Task 5: Run Final System Verification

**Files:**
- No file changes expected.

- [ ] **Step 1: Verify flake outputs evaluate**

Run:

```bash
nix flake show --no-write-lock-file
```

Expected: command exits 0 and output includes:

```text
darwinConfigurations
homeModules
nixosModules
```

- [ ] **Step 2: Build the current Darwin host**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: command exits 0 and builds the `sakurai` system closure.

- [ ] **Step 3: Confirm no Homebrew cask was added for Kitty**

Run:

```bash
if rg -n 'homebrew\.casks|casks = .*kitty|"kitty"' nix/modules/darwin; then
  exit 1
else
  exit 0
fi
```

Expected: command exits 0 and prints no match that places Kitty in Darwin Homebrew casks.

- [ ] **Step 4: Check the final Git state**

Run:

```bash
git status --short
```

Expected: no output.

## Plan Self-Review

- Spec coverage: Task 1 covers the Catppuccin input; Task 2 covers global Mocha theming; Task 3 covers the shared desktop entry point and Kitty module; Task 4 wires `yousiki@sakurai`; Task 5 covers final flake and Darwin verification.
- Scope check: The plan stays within Home Manager managed Kitty and does not introduce Homebrew casks or a broader desktop app framework.
- Placeholder scan: No placeholder markers remain.
- Type and option consistency: The plan uses Home Manager `programs.kitty`, Catppuccin `catppuccin.enable`, Catppuccin `catppuccin.flavor`, and Blueprint `homeModules.desktop` consistently.
