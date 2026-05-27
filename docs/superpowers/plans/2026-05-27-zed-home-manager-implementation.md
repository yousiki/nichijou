# Zed Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure Zed through Home Manager and preserve the user's preferred `zed` CLI command by wrapping `zeditor`.

**Architecture:** Add a focused `nix/modules/home/programs/zed.nix` module that owns Zed installation, settings, Catppuccin integration, the `zed` wrapper, and editor environment variables. Import it from the shared desktop module, and remove the generic `zed-editor` package entry from `desktop-apps.nix` so Zed is not split across two owners.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, catppuccin/nix, nixpkgs `zed-editor`.

---

## File Structure

- Create: `nix/modules/home/programs/zed.nix`
  - Owns Zed as a Home Manager program, including package, extensions, user settings, Catppuccin target settings, `zed` command wrapper, and `EDITOR`/`VISUAL`.
- Modify: `nix/modules/home/desktop.nix`
  - Imports the new Zed module next to other desktop program modules.
- Modify: `nix/modules/home/programs/desktop-apps.nix`
  - Removes the generic `zed-editor` package entry, because Zed becomes a configured first-class Home Manager program.
- Reference: `docs/superpowers/specs/2026-05-27-zed-home-manager-design.md`
  - Approved design and verification contract.

## Task 1: Verify Target Behavior Is Missing

**Files:**
- Inspect: `nix/modules/home/programs/zed.nix`
- Inspect: `nix/modules/home/programs/desktop-apps.nix`
- Inspect: `nix/modules/home/desktop.nix`

- [ ] **Step 1: Confirm the dedicated Zed module does not exist yet**

Run:

```bash
test -f nix/modules/home/programs/zed.nix
```

Expected: command exits non-zero because the module has not been created.

- [ ] **Step 2: Confirm Zed is still owned by generic desktop packages**

Run:

```bash
rg -n '^    zed-editor$' nix/modules/home/programs/desktop-apps.nix
```

Expected: command exits 0 and prints the existing `zed-editor` line.

- [ ] **Step 3: Confirm `desktop.nix` does not import a Zed module**

Run:

```bash
rg -n 'programs/zed\.nix' nix/modules/home/desktop.nix
```

Expected: command exits non-zero because the import is not present yet.

- [ ] **Step 4: Run the pre-change Home Manager assertions**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.zed-editor.enable; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; names = map (pkg: pkg.pname or pkg.name) hm.home.packages; in assert builtins.elem "zed" names; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.home.sessionVariables.EDITOR == "zed --wait" && hm.home.sessionVariables.VISUAL == "zed --wait"; true'
```

Expected with Nix daemon access: these commands fail before implementation because `programs.zed-editor` is not enabled, the `zed` wrapper package is not installed, and the editor variables are not set.

If the commands fail with:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

rerun them with sandbox escalation if available. If daemon access is still unavailable, record the daemon limitation and continue to file edits; run the same assertions again after implementation in an environment with daemon access.

## Task 2: Add the Zed Home Manager Module

**Files:**
- Create: `nix/modules/home/programs/zed.nix`

- [ ] **Step 1: Create `nix/modules/home/programs/zed.nix`**

Use exactly this module:

```nix
{ lib, pkgs, ... }:

let
  zedPackage = pkgs.zed-editor;
  zedCli = pkgs.writeShellApplication {
    name = "zed";
    text = ''
      exec ${lib.getExe' zedPackage "zeditor"} "$@"
    '';
  };
in
{
  home.packages = [
    zedCli
  ];

  catppuccin.zed = {
    enable = true;
    icons.enable = true;
  };

  programs.zed-editor = {
    enable = true;
    package = zedPackage;

    extensions = [
      "catppuccin"
      "nix"
    ];

    userSettings = {
      auto_update = false;

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 14;

      ui_font_family = ".SystemUIFont";
      ui_font_size = 16;

      terminal = {
        font_family = "Maple Mono NF CN";
        font_size = 14;
        option_as_meta = true;
      };

      format_on_save = "on";
    };
  };

  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
  };
}
```

- [ ] **Step 2: Verify the file exists**

Run:

```bash
test -f nix/modules/home/programs/zed.nix
```

Expected: command exits 0.

- [ ] **Step 3: Check the new file for whitespace issues**

Run:

```bash
git diff --check -- nix/modules/home/programs/zed.nix
```

Expected: command exits 0 with no output.

## Task 3: Wire Zed Into the Desktop Module

**Files:**
- Modify: `nix/modules/home/desktop.nix`
- Modify: `nix/modules/home/programs/desktop-apps.nix`

- [ ] **Step 1: Update `nix/modules/home/desktop.nix`**

Replace the file with:

```nix
{ ... }:

{
  imports = [
    ./programs/desktop-apps.nix
    ./programs/cmux.nix
    ./programs/ghostty.nix
    ./programs/kitty.nix
    ./programs/zed.nix
  ];
}
```

- [ ] **Step 2: Remove `zed-editor` from `nix/modules/home/programs/desktop-apps.nix`**

Replace the file with:

```nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    raycast
    rectangle
    maccy
    iina
    obsidian
    brave
    monitorcontrol
    orbstack
    keka
    slack
    spotify
    zoom-us

    brewCasks.chatgpt-atlas
    brewCasks.dockdoor
    brewCasks.feishu
    brewCasks.keepingyouawake
    brewCasks.linearmouse
    brewCasks.tencent-meeting
    brewCasks.thaw
    brewCasks.zotero
  ];
}
```

- [ ] **Step 3: Verify the import was added**

Run:

```bash
rg -n 'programs/zed\.nix' nix/modules/home/desktop.nix
```

Expected: command exits 0 and prints the `./programs/zed.nix` import.

- [ ] **Step 4: Verify the generic package entry was removed**

Run:

```bash
rg -n '^    zed-editor$' nix/modules/home/programs/desktop-apps.nix
```

Expected: command exits non-zero with no output.

- [ ] **Step 5: Check wired files for whitespace issues**

Run:

```bash
git diff --check -- nix/modules/home/desktop.nix nix/modules/home/programs/desktop-apps.nix
```

Expected: command exits 0 with no output.

## Task 4: Verify Home Manager Evaluation and Package Build

**Files:**
- Verify: `nix/modules/home/programs/zed.nix`
- Verify: `nix/modules/home/desktop.nix`
- Verify: `nix/modules/home/programs/desktop-apps.nix`

- [ ] **Step 1: Make the new Zed module visible to Git flake evaluation**

Run:

```bash
git add --intent-to-add nix/modules/home/programs/zed.nix
```

Expected: command exits 0. This does not stage file contents for commit, but it makes the new module visible to `builtins.getFlake "git+file:///private/etc/nix-darwin"`.

- [ ] **Step 2: Verify Zed's Home Manager module is enabled**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.zed-editor.enable; true'
```

Expected: prints `true`.

- [ ] **Step 3: Verify Zed uses `pkgs.zed-editor`**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; packageName = hm.programs.zed-editor.package.pname or hm.programs.zed-editor.package.name; in assert packageName == "zed-editor"; true'
```

Expected: prints `true`.

- [ ] **Step 4: Verify the `zed` wrapper package is in Home Manager packages**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; names = map (pkg: pkg.pname or pkg.name) hm.home.packages; in assert builtins.elem "zed" names; true'
```

Expected: prints `true`.

- [ ] **Step 5: Verify baseline Zed settings**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; settings = hm.programs.zed-editor.userSettings; in assert settings.auto_update == false && settings.telemetry.diagnostics == false && settings.telemetry.metrics == false && settings.buffer_font_family == "Maple Mono NF CN" && settings.buffer_font_size == 14 && settings.ui_font_family == ".SystemUIFont" && settings.ui_font_size == 16 && settings.terminal.font_family == "Maple Mono NF CN" && settings.terminal.font_size == 14 && settings.terminal.option_as_meta == true && settings.format_on_save == "on"; true'
```

Expected: prints `true`.

- [ ] **Step 6: Verify baseline extensions**

`catppuccin.zed.icons.enable = true` supplies `catppuccin-icons`, so the explicit Zed extension list should only contain `catppuccin` and `nix`. The evaluated extension list should still contain `catppuccin-icons` exactly once.

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; exts = hm.programs.zed-editor.extensions; in assert builtins.length exts == 3 && builtins.elem "catppuccin" exts && builtins.elem "catppuccin-icons" exts && builtins.elem "nix" exts; true'
```

Expected: prints `true`.

- [ ] **Step 7: Verify Catppuccin Zed integration**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.catppuccin.zed.enable && hm.catppuccin.zed.icons.enable; true'
```

Expected: prints `true`.

- [ ] **Step 8: Verify editor environment variables**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.home.sessionVariables.EDITOR == "zed --wait" && hm.home.sessionVariables.VISUAL == "zed --wait"; true'
```

Expected: prints `true`.

- [ ] **Step 9: Verify the Zed package builds or is available**

Run:

```bash
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in pkgs.zed-editor'
```

Expected: command exits 0.

- [ ] **Step 10: Verify the full host configuration builds**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: command exits 0.

For any command in this task that fails with:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

rerun the same command with sandbox escalation. If daemon access is still unavailable, report the daemon limitation and do not treat it as a configuration failure.

## Task 5: Inspect Diff and Commit

**Files:**
- Verify: `nix/modules/home/programs/zed.nix`
- Verify: `nix/modules/home/desktop.nix`
- Verify: `nix/modules/home/programs/desktop-apps.nix`
- Verify: `docs/superpowers/plans/2026-05-27-zed-home-manager-implementation.md`

- [ ] **Step 1: Make new files visible to Git diff**

Run:

```bash
git add --intent-to-add docs/superpowers/plans/2026-05-27-zed-home-manager-implementation.md nix/modules/home/programs/zed.nix
```

Expected: command exits 0. This does not stage file contents for commit, but it makes new files visible to `git diff`.

- [ ] **Step 2: Run final whitespace check**

Run:

```bash
git diff --check
```

Expected: command exits 0 with no output.

- [ ] **Step 3: Inspect changed files**

Run:

```bash
git diff --stat
git diff -- nix/modules/home/programs/zed.nix nix/modules/home/desktop.nix nix/modules/home/programs/desktop-apps.nix
```

Expected: the diff is limited to the new Zed module, the desktop module import, and removing `zed-editor` from the generic desktop app package list. If the plan file is still uncommitted, it should also appear as documentation-only change.

- [ ] **Step 4: Stage and run cached whitespace check**

Run:

```bash
git add docs/superpowers/plans/2026-05-27-zed-home-manager-implementation.md nix/modules/home/programs/zed.nix nix/modules/home/desktop.nix nix/modules/home/programs/desktop-apps.nix
git diff --cached --check
```

Expected: command exits 0 with no output.

- [ ] **Step 5: Commit the implementation**

Run:

```bash
git commit -m "home: configure zed editor"
```

Expected: commit succeeds. If Git reports an index lock permission error under `/etc/nix-darwin/.git/index.lock`, rerun the same Git commands with sandbox escalation.

## Task 6: Post-Activation User Check

**Files:**
- Runtime verification only.

- [ ] **Step 1: Apply the configuration outside this plan if requested**

Run only after the user explicitly wants activation:

```bash
darwin-rebuild switch --flake .#sakurai
```

Expected: activation succeeds. This is intentionally separate from the build verification because it applies persistent system/user state.

- [ ] **Step 2: Verify user-visible commands after activation**

Run:

```bash
command -v zed
command -v zeditor
zed --help
printenv EDITOR
printenv VISUAL
```

Expected:

```text
command -v zed prints a Home Manager profile path ending in /bin/zed
command -v zeditor prints a Home Manager profile path ending in /bin/zeditor
zed --help exits 0 and shows Zed CLI help
printenv EDITOR prints zed --wait
printenv VISUAL prints zed --wait
```
