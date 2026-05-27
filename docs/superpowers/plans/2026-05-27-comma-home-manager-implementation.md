# Comma Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `,` command for user `yousiki` through Home Manager using `nix-index-database`.

**Architecture:** The flake declares `nix-index-database` as an input following the repository's existing `nixpkgs`. The shared Home Manager module imports `inputs.nix-index-database.homeModules.nix-index`, enables `programs.nix-index`, and enables `programs.nix-index-database.comma`. Runtime activation remains a separate privileged step after the host build passes.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, `nix-community/nix-index-database`, `comma`.

---

## File Structure

- Modify `flake.nix`: add the `nix-index-database` flake input beside the other shared inputs.
- Modify `flake.lock`: lock the new `nix-index-database` input with `nix flake update nix-index-database`.
- Modify `nix/modules/home/common.nix`: import the nix-index database Home Manager module and enable the Home Manager options for nix-index and comma.
- Do not modify `nix/modules/home/cli.nix`: `pkgs.comma` must not be added to `home.packages`.
- Do not modify `nix/modules/home/programs/shell.nix`: no shell alias is required.

Before starting implementation, run:

```bash
git status --short
```

Expected current unrelated local changes may include:

```text
 M flake.lock
M  nix/modules/darwin/homebrew.nix
M  nix/modules/home/programs/desktop-apps.nix
```

Treat any pre-existing unrelated changes as user-owned. Do not revert them. Use explicit pathspecs when staging and committing.

If `flake.lock` is already modified before Task 1, inspect it with:

```bash
git diff -- flake.lock
```

If the dirty lockfile does not already contain only the `nix-index-database` change described in this plan, stop and ask the user how they want to handle the pre-existing lockfile edit. Do not mix unrelated lockfile changes into the comma input commit.

### Task 1: Add and Lock the nix-index-database Flake Input

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] **Step 1: Verify the input is absent before adding it**

Run:

```bash
nix flake metadata --json . | jq -e '.locks.nodes | has("nix-index-database")'
```

Expected before this task: exit 1 with output:

```text
false
```

If it returns `true`, inspect `git diff -- flake.nix flake.lock` before continuing. Only proceed if the existing input and lockfile change match this design exactly.

- [ ] **Step 2: Add the flake input**

Modify `flake.nix` so the `inputs` attrset contains this block after `home-manager` and before `catppuccin`:

```nix
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

The surrounding section should look like this:

```nix
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 3: Lock the new input**

Run:

```bash
nix flake update nix-index-database
```

Expected: `flake.lock` gains a `nix-index-database` node and any transitive lock nodes required by that input. If this fails with a network, daemon, or sandbox access error, rerun with the required approval rather than editing `flake.lock` by hand.

- [ ] **Step 4: Verify the input is present in the lock**

Run:

```bash
nix flake metadata --json . | jq -e '.locks.nodes | has("nix-index-database")'
```

Expected output:

```text
true
```

- [ ] **Step 5: Check the exact diff for this task**

Run:

```bash
git diff -- flake.nix flake.lock
```

Expected: the diff adds the `nix-index-database` input to `flake.nix` and the corresponding lock nodes to `flake.lock`. It must not include changes to `nix/modules/darwin/homebrew.nix` or `nix/modules/home/programs/desktop-apps.nix`.

- [ ] **Step 6: Commit the input and lock update**

Run:

```bash
git add flake.nix flake.lock
git diff --cached --check -- flake.nix flake.lock
git commit -m "flake: add nix-index database input" -- flake.nix flake.lock
```

Expected: a commit containing only `flake.nix` and `flake.lock`.

### Task 2: Enable comma Through Home Manager

**Files:**
- Modify: `nix/modules/home/common.nix`

- [ ] **Step 1: Write the failing configuration check**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki.programs.nix-index-database.comma.enable'
```

Expected before this task: evaluation fails because `programs.nix-index-database.comma.enable` is not defined in the Home Manager user configuration yet.

- [ ] **Step 2: Update the shared Home Manager module**

Replace `nix/modules/home/common.nix` with:

```nix
{ inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.enableNixpkgsReleaseCheck = false;

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  programs.home-manager.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;
}
```

- [ ] **Step 3: Verify the configuration check passes**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki.programs.nix-index-database.comma.enable'
```

Expected output:

```text
true
```

- [ ] **Step 4: Verify the regular host build**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: build exits 0. If it fails with `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted`, report that the current environment lacks Nix daemon access and do not treat it as a configuration failure.

- [ ] **Step 5: Check the exact diff for this task**

Run:

```bash
git diff -- nix/modules/home/common.nix
```

Expected: only `nix/modules/home/common.nix` changes, importing `inputs.nix-index-database.homeModules.nix-index` and enabling `programs.nix-index` plus `programs.nix-index-database.comma.enable`.

- [ ] **Step 6: Commit the Home Manager configuration**

Run:

```bash
git add nix/modules/home/common.nix
git diff --cached --check -- nix/modules/home/common.nix
git commit -m "home: enable comma via nix-index database" -- nix/modules/home/common.nix
```

Expected: a commit containing only `nix/modules/home/common.nix`.

### Task 3: Activate and Verify Runtime Behavior

**Files:**
- No file changes.

- [ ] **Step 1: Run final whitespace check**

Run:

```bash
git diff --check
```

Expected: no output and exit 0. If unrelated user-owned changes produce whitespace errors, report the exact file and line instead of changing those files.

- [ ] **Step 2: Switch the current host**

Run:

```bash
sudo darwin-rebuild switch --flake .#sakurai
```

Expected: activation exits 0. This step is privileged and should only run with explicit user approval.

- [ ] **Step 3: Verify the comma command is visible in a login zsh**

Run:

```bash
zsh -lc 'command -v ,'
```

Expected: prints a path ending in:

```text
,
```

- [ ] **Step 4: Verify comma can run an ephemeral program**

Run:

```bash
zsh -lc ', hello'
```

Expected output includes:

```text
Hello, world!
```

- [ ] **Step 5: Report final status**

Run:

```bash
git status --short
```

Expected: only pre-existing unrelated user-owned changes remain, or the working tree is clean if those changes were handled separately.

Report:

```text
Implemented comma through Home Manager using nix-index-database.
Verified: nix-index-database lock presence, Home Manager option evaluates true, darwin-rebuild build, darwin-rebuild switch, command -v ,, and , hello.
```
