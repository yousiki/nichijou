# Blueprint Nix Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the current minimal nix-darwin flake into a Blueprint-based multi-host configuration repo using `prefix = "nix/"`.

**Architecture:** Keep `flake.nix` small and let Blueprint map files under `nix/` to flake outputs. The current `sakurai` macOS host will be represented by `nix/hosts/sakurai/darwin-configuration.nix`, reusable Darwin/Home/NixOS modules will live under `nix/modules/`, and Home Manager will be wired through Blueprint's host user convention.

**Tech Stack:** Nix flakes, Lix, nix-darwin, Home Manager, numtide/blueprint, nix-homebrew, brew-nix.

---

## File Structure

- Modify: `flake.nix`
  - Replace the generated nix-darwin-only outputs with a Blueprint invocation.
  - Add inputs for Blueprint, Home Manager, nix-homebrew, brew-nix, brew-api, and Homebrew taps.
  - Apply the `brew-nix` overlay only on Darwin systems.
- Modify: `flake.lock`
  - Regenerate after new inputs are added.
- Create: `nix/hosts/sakurai/darwin-configuration.nix`
  - Host-local macOS settings and imports for shared Darwin modules.
- Create: `nix/hosts/sakurai/users/yousiki/home-configuration.nix`
  - Host-local Home Manager entry point for user `yousiki`.
- Create: `nix/modules/darwin/common.nix`
  - Shared nix-darwin packages and shell/system defaults.
- Create: `nix/modules/darwin/nix.nix`
  - Lix and Nix settings.
- Create: `nix/modules/darwin/homebrew.nix`
  - nix-homebrew setup and nix-darwin Homebrew bundle defaults.
- Create: `nix/modules/home/common.nix`
  - Shared Home Manager base settings.
- Create: `nix/modules/home/cli.nix`
  - Shared CLI-oriented Home Manager packages and program settings.
- Create: `nix/modules/nixos/common.nix`
  - Empty but valid shared NixOS module for future hosts.

## Task 1: Convert `flake.nix` To Blueprint

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Replace `flake.nix` with Blueprint-based flake code**

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

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
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

  outputs = inputs:
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
        (final: prev:
          if prev.stdenv.hostPlatform.isDarwin
          then inputs.brew-nix.overlays.default final prev
          else { })
      ];
    };
}
```

- [ ] **Step 2: Check syntax before updating the lock file**

Run:

```bash
nix eval --extra-experimental-features 'nix-command flakes' --file flake.nix description
```

Expected: command exits 0 and prints:

```text
"Multi-host nix-darwin and NixOS configuration"
```

- [ ] **Step 3: Commit the flake conversion**

Run:

```bash
git add flake.nix
git commit -m "flake: switch to blueprint"
```

Expected: commit succeeds and includes only `flake.nix`.

## Task 2: Add Darwin Host And Shared Darwin Modules

**Files:**
- Create: `nix/hosts/sakurai/darwin-configuration.nix`
- Create: `nix/modules/darwin/common.nix`
- Create: `nix/modules/darwin/nix.nix`
- Create: `nix/modules/darwin/homebrew.nix`

- [ ] **Step 1: Create `nix/modules/darwin/nix.nix`**

```nix
{ pkgs, ... }:

{
  nix.package = pkgs.lix;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
```

- [ ] **Step 2: Create `nix/modules/darwin/common.nix`**

```nix
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.vim
  ];

  programs.zsh.enable = true;
}
```

- [ ] **Step 3: Create `nix/modules/darwin/homebrew.nix`**

```nix
{ config, inputs, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = config.system.primaryUser;
    autoMigrate = true;
    mutableTaps = false;

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    global = {
      autoUpdate = false;
      brewfile = true;
    };

    casks = [ ];
    brews = [ ];
  };
}
```

- [ ] **Step 4: Create `nix/hosts/sakurai/darwin-configuration.nix`**

```nix
{ flake, hostName, ... }:

{
  imports = [
    flake.darwinModules.common
    flake.darwinModules.nix
    flake.darwinModules.homebrew
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

- [ ] **Step 5: Run Blueprint output discovery**

Run:

```bash
nix flake show --extra-experimental-features 'nix-command flakes' --allow-import-from-derivation --no-write-lock-file
```

Expected: if the lock file does not yet contain new inputs, this may fail with a message about the lock file needing updates. It must not fail with a Nix syntax error in any newly created file.

- [ ] **Step 6: Commit Darwin host modules**

Run:

```bash
git add nix/hosts/sakurai/darwin-configuration.nix nix/modules/darwin/common.nix nix/modules/darwin/nix.nix nix/modules/darwin/homebrew.nix
git commit -m "darwin: add sakurai blueprint host"
```

Expected: commit succeeds and includes only the Darwin host and Darwin module files.

## Task 3: Add Home Manager Modules

**Files:**
- Create: `nix/hosts/sakurai/users/yousiki/home-configuration.nix`
- Create: `nix/modules/home/common.nix`
- Create: `nix/modules/home/cli.nix`

- [ ] **Step 1: Create `nix/modules/home/common.nix`**

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.git
  ];

  programs.home-manager.enable = true;
}
```

- [ ] **Step 2: Create `nix/modules/home/cli.nix`**

```nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];

  programs.git = {
    enable = true;
  };
}
```

- [ ] **Step 3: Create `nix/hosts/sakurai/users/yousiki/home-configuration.nix`**

```nix
{ flake, ... }:

{
  imports = [
    flake.homeModules.common
    flake.homeModules.cli
  ];

  home.stateVersion = "26.05";
}
```

- [ ] **Step 4: Evaluate the Home Manager module output**

Run:

```bash
nix eval --extra-experimental-features 'nix-command flakes' --no-write-lock-file .#homeModules.common --apply 'x: builtins.isPath x || builtins.isString x'
```

Expected: prints:

```text
true
```

If this fails because the lock file needs the new inputs, continue to Task 5 and re-run this step after the lock update.

- [ ] **Step 5: Commit Home Manager modules**

Run:

```bash
git add nix/hosts/sakurai/users/yousiki/home-configuration.nix nix/modules/home/common.nix nix/modules/home/cli.nix
git commit -m "home: add yousiki shared modules"
```

Expected: commit succeeds and includes only the Home Manager files.

## Task 4: Add Future NixOS Module Scaffold

**Files:**
- Create: `nix/modules/nixos/common.nix`

- [ ] **Step 1: Create `nix/modules/nixos/common.nix`**

```nix
{ ... }:

{
}
```

- [ ] **Step 2: Evaluate the NixOS module output**

Run:

```bash
nix eval --extra-experimental-features 'nix-command flakes' --no-write-lock-file .#nixosModules.common --apply 'x: builtins.isAttrs x || builtins.isPath x || builtins.isString x'
```

Expected: prints:

```text
true
```

If this fails because the lock file needs the new inputs, continue to Task 5 and re-run this step after the lock update.

- [ ] **Step 3: Commit NixOS module scaffold**

Run:

```bash
git add nix/modules/nixos/common.nix
git commit -m "nixos: add shared module scaffold"
```

Expected: commit succeeds and includes only `nix/modules/nixos/common.nix`.

## Task 5: Update Lock File And Evaluate Outputs

**Files:**
- Modify: `flake.lock`

- [ ] **Step 1: Regenerate `flake.lock`**

Run:

```bash
nix flake lock --extra-experimental-features 'nix-command flakes'
```

Expected: command exits 0 and adds lock entries for `blueprint`, `home-manager`, `nix-homebrew`, `brew-nix`, `brew-api`, `homebrew-core`, and `homebrew-cask`.

- [ ] **Step 2: Show flake outputs**

Run:

```bash
nix flake show --extra-experimental-features 'nix-command flakes' --allow-import-from-derivation
```

Expected output includes these paths:

```text
darwinConfigurations
darwinConfigurations.sakurai
homeModules
homeModules.common
homeModules.cli
nixosModules
nixosModules.common
```

- [ ] **Step 3: Evaluate Darwin system derivation path**

Run:

```bash
nix eval --extra-experimental-features 'nix-command flakes' .#darwinConfigurations.sakurai.system.drvPath
```

Expected: prints a quoted `/nix/store/...-darwin-system-...drv` path.

- [ ] **Step 4: Commit lock file update**

Run:

```bash
git add flake.lock
git commit -m "flake: lock blueprint inputs"
```

Expected: commit succeeds and includes only `flake.lock`.

## Task 6: Build The Current Darwin Host

**Files:**
- No file edits expected.

- [ ] **Step 1: Build `sakurai` without switching**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: command exits 0 and builds the system closure. The command should not activate the new generation.

- [ ] **Step 2: Inspect the build result**

Run:

```bash
ls -l ./result
```

Expected: `./result` points to a `/nix/store/...-darwin-system-...` path.

- [ ] **Step 3: Record verification**

Run:

```bash
git status --short
```

Expected: no new tracked file modifications from the build. `result` may appear as an untracked symlink if not ignored.

If `result` appears, remove the symlink with:

```bash
rm result
```

Expected: only planned repository changes remain.

## Task 7: Final Review

**Files:**
- Modify only if verification exposes a concrete error.

- [ ] **Step 1: Run final status check**

Run:

```bash
git status --short --branch
```

Expected: clean working tree except for pre-existing staged `flake.nix` and `flake.lock` if those were intentionally left staged before implementation. If the implementation commits consume those staged files, the tree should be clean.

- [ ] **Step 2: Review commit history**

Run:

```bash
git log --oneline -6
```

Expected: recent commits include:

```text
flake: switch to blueprint
darwin: add sakurai blueprint host
home: add yousiki shared modules
nixos: add shared module scaffold
flake: lock blueprint inputs
```

- [ ] **Step 3: Summarize outcome**

Report:

```text
Blueprint migration completed.
Verified nix flake show.
Verified darwinConfigurations.sakurai evaluates.
Verified darwin-rebuild build --flake .#sakurai.
```

If any verification command failed, report the exact command, the failure, and the file changed to fix it.

---

## Self-Review

Spec coverage:

- Blueprint with `prefix = "nix/"`: Task 1.
- Initial `sakurai` Darwin host: Task 2.
- Darwin shared modules for Lix, system packages, and Homebrew: Task 2.
- Home Manager host user and shared modules: Task 3.
- Future NixOS module location: Task 4.
- brew-nix and nix-homebrew inputs: Tasks 1 and 5.
- Testing and verification: Tasks 5, 6, and 7.
- Deferred `sops-nix` and claude-code overlay: no implementation task by design.

Marker scan:

- No marker strings or open-ended implementation instructions remain.

Type consistency:

- Blueprint module references use `flake.darwinModules.*`, `flake.homeModules.*`, and `flake.nixosModules.*`.
- Host name comes from Blueprint's `hostName` argument.
- Homebrew tap names match nix-homebrew's expected keys.
