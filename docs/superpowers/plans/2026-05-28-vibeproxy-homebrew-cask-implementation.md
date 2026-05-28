# VibeProxy Homebrew Cask Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install VibeProxy through nix-darwin's declarative Homebrew cask list.

**Architecture:** Keep VibeProxy in the Darwin-level Homebrew module because it is an official Homebrew cask and should install as a normal macOS app in `/Applications`. No Home Manager module, new tap, or custom Nix package is needed.

**Tech Stack:** nix-darwin, nix-homebrew, Homebrew casks.

---

### Task 1: Add VibeProxy Cask

**Files:**
- Modify: `nix/modules/darwin/homebrew.nix`
- Test: Nix eval and host build commands

- [ ] **Step 1: Add the cask**

In `nix/modules/darwin/homebrew.nix`, update the cask list:

```nix
casks = [
  "1password"
  "cloudflare-warp"
  "vibeproxy"
];
```

- [ ] **Step 2: Check whitespace**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 3: Verify nix-darwin config contains the cask**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; casks = map (cask: cask.name) flake.darwinConfigurations.sakurai.config.homebrew.casks; in assert builtins.elem "vibeproxy" casks; true'
```

Expected output:

```json
true
```

- [ ] **Step 4: Verify the host build**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: build exits 0. If the command leaves a `result` symlink, remove it after inspection.
