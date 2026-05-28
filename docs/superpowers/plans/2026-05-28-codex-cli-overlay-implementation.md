# Codex CLI Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Home Manager's `codex` command use the fresher `sadjow/codex-cli-nix` overlay package instead of waiting for the locked `nixpkgs` package.

**Architecture:** Add `sadjow/codex-cli-nix` as a flake input following the repository's `nixpkgs` input, then apply its default overlay in Blueprint's `nixpkgs.overlays`. Keep `nix/modules/home/programs/codex.nix` unchanged so Home Manager still selects `pkgs.codex`; add the Codex CLI Cachix substituter and trust key to the existing Darwin Nix settings module.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, `sadjow/codex-cli-nix`, Cachix.

---

## File Structure

- Modify `flake.nix`: declare the `codex-cli` input and add `inputs.codex-cli.overlays.default` to the existing overlay list.
- Modify `flake.lock`: refresh through `nix flake lock --update-input codex-cli` after the input is declared.
- Modify `nix/modules/darwin/nix.nix`: add the Codex CLI Cachix substituter and trusted public key.
- Do not modify `nix/modules/home/programs/codex.nix`: the existing `package = pkgs.codex;` line should consume the overlay.

Before starting implementation, run:

```bash
git status --short --branch -uall
```

Expected state after the design and plan commits:

```text
## main...origin/main [ahead 2]
```

If unrelated files are modified or untracked, treat them as user-owned and do not stage, revert, or reformat them.

## Task 1: Verify The Current Codex Package Is Still Behind

**Files:**
- Test only: current flake evaluation

- [ ] **Step 1: Run the failing version assertion**

Run:

```bash
nix eval --impure --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in assert pkgs.lib.versionAtLeast pkgs.codex.version "0.134.0"; pkgs.codex.version'
```

Expected before implementation: FAIL with an assertion failure because the current effective `pkgs.codex.version` is below `0.134.0`.

If it instead fails with this Nix daemon error, rerun the command with sandbox escalation and continue from the escalated result:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

## Task 2: Add The Codex CLI Overlay Input

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`

- [ ] **Step 1: Add the `codex-cli` input**

Modify `flake.nix` so the input block includes:

```nix
    codex-cli = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

Place it next to the existing `claude-code` input.

- [ ] **Step 2: Add the overlay**

Modify the `nixpkgs.overlays` list in `flake.nix` so it begins:

```nix
      nixpkgs.overlays = [
        inputs.claude-code.overlays.default
        inputs.codex-cli.overlays.default
        (
          final: prev:
          if prev.stdenv.hostPlatform.isDarwin then inputs.brew-nix.overlays.default final prev else { }
        )
      ];
```

- [ ] **Step 3: Refresh the lock entry**

Run:

```bash
nix flake lock --update-input codex-cli
```

If this Nix version reports that `--update-input` has been replaced, run:

```bash
nix flake update codex-cli
```

If anonymous GitHub API requests are rate-limited while resolving HEAD, first get the current target revision with:

```bash
git ls-remote --symref https://github.com/sadjow/codex-cli-nix HEAD
```

Then write the lock entry with:

```bash
nix flake lock --override-input codex-cli 'github:sadjow/codex-cli-nix/26c2ba2aed14632a04335a2f0a99d14abfb63f14'
```

Expected: `flake.lock` gains a `codex-cli` node and records it in the root inputs.

## Task 3: Add The Codex CLI Cachix Trust Settings

**Files:**
- Modify: `nix/modules/darwin/nix.nix`

- [ ] **Step 1: Add the substituter**

Modify `nix/modules/darwin/nix.nix` so `nix.settings.substituters` is:

```nix
  nix.settings.substituters = [
    "https://claude-code.cachix.org"
    "https://codex-cli.cachix.org"
  ];
```

- [ ] **Step 2: Add the trusted public key**

Modify `nix/modules/darwin/nix.nix` so `nix.settings.trusted-public-keys` is:

```nix
  nix.settings.trusted-public-keys = [
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
  ];
```

## Task 4: Verify The Overlay And Host Build

**Files:**
- Test only: effective flake evaluation and host build

- [ ] **Step 1: Verify the effective Codex package version**

Run:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.darwinConfigurations.sakurai.pkgs.codex.version'
```

Expected output:

```text
0.134.0
```

- [ ] **Step 2: Verify the Darwin Nix trust settings**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; cfg = flake.darwinConfigurations.sakurai.config.nix.settings; in { substituters = cfg.substituters; trustedPublicKeys = cfg.trusted-public-keys; }'
```

Expected output includes:

```json
{
  "substituters": [
    "https://claude-code.cachix.org",
    "https://codex-cli.cachix.org"
  ],
  "trustedPublicKeys": [
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=",
    "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
  ]
}
```

- [ ] **Step 3: Verify the host build**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: build finishes with exit code 0.

If the build leaves a `result` symlink, remove the symlink after recording the successful build result:

```bash
rm result
```

- [ ] **Step 4: Inspect the final diff**

Run:

```bash
git status --short --branch -uall
git diff --check
git diff --stat
git diff
```

Expected changed files:

```text
flake.lock
flake.nix
nix/modules/darwin/nix.nix
```

- [ ] **Step 5: Commit the implementation**

Run:

```bash
git add flake.nix flake.lock nix/modules/darwin/nix.nix
git commit -m "flake: add codex cli overlay"
```

Do not include AI co-author attribution.
