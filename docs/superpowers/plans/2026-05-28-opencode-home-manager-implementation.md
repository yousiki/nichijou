# OpenCode Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `opencode` as a dedicated Home Manager-managed CLI coding tool for user `yousiki`.

**Architecture:** Create `nix/modules/home/programs/opencode.nix` and wire it into `nix/modules/home/cli.nix` beside `claude-code` and `codex`. Use Home Manager's native `programs.opencode` module so installation and generated OpenCode config files are owned by the same module. Keep provider/model/API-key configuration out of Nix.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, `programs.opencode`, OpenCode.

---

## File Structure

- Create `nix/modules/home/programs/opencode.nix`: owns OpenCode installation and conservative global user config.
- Modify `nix/modules/home/cli.nix`: imports the OpenCode module from the existing CLI Home Manager aggregator.
- Do not modify `flake.nix` or `flake.lock`: the locked inputs already expose `pkgs.opencode` and Home Manager's `programs.opencode` option set.
- Do not modify existing user-owned files such as `nix/modules/darwin/homebrew.nix`, `nix/modules/home/programs/claude-code.nix`, `nix/modules/home/programs/codex.nix`, `nix/modules/home/programs/ghostty.nix`, `nix/modules/home/programs/git.nix`, or the untracked vibeproxy docs.

Before starting implementation, run:

```bash
git status --short --untracked-files=all
```

Expected unrelated local changes may include staged or unstaged entries like:

```text
A  docs/superpowers/plans/2026-05-28-vibeproxy-homebrew-cask-implementation.md
A  docs/superpowers/specs/2026-05-28-vibeproxy-homebrew-cask-design.md
M  nix/modules/darwin/homebrew.nix
M  nix/modules/home/programs/claude-code.nix
M  nix/modules/home/programs/codex.nix
M  nix/modules/home/programs/ghostty.nix
M  nix/modules/home/programs/git.nix
```

Treat those as user-owned. Do not revert, unstage, stage, or reformat them.

## Task 1: Add the OpenCode Home Manager Module

**Files:**
- Create: `nix/modules/home/programs/opencode.nix`
- Modify: `nix/modules/home/cli.nix`

- [ ] **Step 1: Verify OpenCode is not currently enabled**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.opencode.enable; true'
```

Expected before implementation: evaluation fails with an assertion failure because `programs.opencode.enable` is not true yet.

If it instead fails with this Nix daemon error, rerun the command with sandbox escalation and continue from the escalated result:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

- [ ] **Step 2: Create the OpenCode module**

Create `nix/modules/home/programs/opencode.nix` with exactly:

```nix
{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    settings = {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
      share = "manual";
    };

    tui = {
      "$schema" = "https://opencode.ai/tui.json";
      mouse = true;
    };
  };
}
```

- [ ] **Step 3: Import the OpenCode module from the CLI aggregator**

Modify `nix/modules/home/cli.nix` so the `imports` list includes `./programs/opencode.nix` after `./programs/codex.nix` and before `./programs/git.nix`.

The imports section should be:

```nix
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/git.nix
    ./programs/shell.nix
  ];
```

Leave the existing `home.packages` list unchanged.

- [ ] **Step 4: Make the new module visible to git-backed flake evaluation**

Run:

```bash
git add --intent-to-add nix/modules/home/programs/opencode.nix
```

This is required because `builtins.getFlake "git+file:///private/etc/nix-darwin"` only sees files known to Git.

- [ ] **Step 5: Verify OpenCode is enabled**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in hm.programs.opencode.enable'
```

Expected output:

```text
true
```

- [ ] **Step 6: Verify the OpenCode package selection**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in hm.programs.opencode.package.pname'
```

Expected output:

```text
"opencode"
```

- [ ] **Step 7: Verify the runtime config values**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in { schema = hm.programs.opencode.settings."$schema"; autoupdate = hm.programs.opencode.settings.autoupdate; share = hm.programs.opencode.settings.share; }'
```

Expected output:

```json
{"autoupdate":false,"schema":"https://opencode.ai/config.json","share":"manual"}
```

- [ ] **Step 8: Verify the TUI config values**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in { schema = hm.programs.opencode.tui."$schema"; theme = hm.programs.opencode.tui.theme; mouse = hm.programs.opencode.tui.mouse; catppuccinOpenCode = hm.catppuccin.opencode.enable; }'
```

Expected output:

```json
{"catppuccinOpenCode":true,"mouse":true,"schema":"https://opencode.ai/tui.json","theme":"catppuccin"}
```

## Task 2: Verify Build and Commit the OpenCode Change

**Files:**
- Verify: `nix/modules/home/programs/opencode.nix`
- Verify: `nix/modules/home/cli.nix`

- [ ] **Step 1: Check the implementation diff**

Run:

```bash
git diff -- nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

Expected: only `cli.nix` and the new `opencode.nix` are part of the OpenCode implementation diff. The diff must not include unrelated edits from existing user-owned files.

- [ ] **Step 2: Check whitespace**

Run:

```bash
git diff --check -- nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

Expected: no output and exit code 0.

- [ ] **Step 3: Verify the host build**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: build exits 0.

If it fails with this Nix daemon error, report the daemon-access failure and do not treat it as a configuration failure:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

- [ ] **Step 4: Stage only the OpenCode implementation files**

Run:

```bash
git add nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

- [ ] **Step 5: Verify the OpenCode files are staged**

Run:

```bash
git diff --cached --name-only -- nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

Expected output:

```text
nix/modules/home/cli.nix
nix/modules/home/programs/opencode.nix
```

Do not inspect or modify unrelated staged files for this step. They are user-owned and may remain staged while the OpenCode commit uses an explicit pathspec.

- [ ] **Step 6: Verify staged whitespace**

Run:

```bash
git diff --cached --check -- nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

Expected: no output and exit code 0.

- [ ] **Step 7: Commit the implementation**

If `git config user.name` and `git config user.email` are unset, use the last commit author as a one-off identity:

```bash
git -c user.name=YouSiki -c user.email=yousiki@sakurai.tail5d997.ts.net commit -m "home: configure opencode" -- nix/modules/home/cli.nix nix/modules/home/programs/opencode.nix
```

Expected: one commit containing only `nix/modules/home/cli.nix` and `nix/modules/home/programs/opencode.nix`.

## Final Verification

After the commit, run:

```bash
git status --short --untracked-files=all
git show --stat --oneline --name-only HEAD
```

Expected:

- `git status` still shows any pre-existing unrelated user-owned changes, including staged entries that were already present before this implementation.
- `git show` lists only:

```text
nix/modules/home/cli.nix
nix/modules/home/programs/opencode.nix
```

Activation is intentionally out of scope for this implementation because it requires a privileged interactive step. The user can activate later with:

```bash
sudo darwin-rebuild switch --flake .#sakurai
```
