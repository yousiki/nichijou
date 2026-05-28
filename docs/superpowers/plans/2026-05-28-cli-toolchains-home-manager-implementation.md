# CLI Toolchains Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Bun, Node.js Active LTS, rustup-managed Rust toolchains, and uv to the `yousiki` Home Manager CLI profile.

**Architecture:** Create one dedicated Home Manager module at `nix/modules/home/programs/toolchains.nix` and import it from `nix/modules/home/cli.nix`. Use native Home Manager modules for Bun and uv, and use `home.packages` for Node.js 24 and rustup.

**Tech Stack:** nix-darwin, Home Manager, nixpkgs unstable locked by this flake, Apple Silicon macOS host `sakurai`.

---

### Task 1: Add The Toolchains Module

**Files:**
- Create: `nix/modules/home/programs/toolchains.nix`
- Modify: `nix/modules/home/cli.nix`

- [ ] **Step 1: Run the pre-change Home Manager eval**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; versionOf = name: let matches = builtins.filter (pkg: (pkg.pname or pkg.name) == name) hm.home.packages; in if matches == [ ] then null else (builtins.head matches).version or null; nodejs = versionOf "nodejs"; rustup = versionOf "rustup"; in { bun = hm.programs.bun.enable or false; uv = hm.programs.uv.enable or false; nodejs = nodejs; rustup = rustup; hasNode24 = nodejs == "24.15.0"; hasRustup = rustup != null; }'
```

Expected before implementation:

```json
{"bun":false,"hasNode24":false,"hasRustup":false,"nodejs":null,"rustup":null,"uv":false}
```

The important red-state checks are `bun = false`, `uv = false`, `nodejs = null`, and `rustup = null`.

- [ ] **Step 2: Create `nix/modules/home/programs/toolchains.nix`**

Write:

```nix
{ pkgs, ... }:

{
  programs.bun = {
    enable = true;
    package = pkgs.bun;
  };

  home.packages = [
    pkgs.nodejs_24
    pkgs.rustup
  ];

  programs.uv = {
    enable = true;
    package = pkgs.uv;
  };
}
```

- [ ] **Step 3: Import the module from `nix/modules/home/cli.nix`**

Change the imports list to include the new module with the other CLI program modules:

```nix
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/jcode.nix
    ./programs/cliproxyapi.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/toolchains.nix
  ];
```

- [ ] **Step 4: Run the post-change Home Manager eval**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; versionOf = name: let matches = builtins.filter (pkg: (pkg.pname or pkg.name) == name) hm.home.packages; in if matches == [ ] then null else (builtins.head matches).version or null; nodejs = versionOf "nodejs"; rustup = versionOf "rustup"; in { bun = hm.programs.bun.enable; uv = hm.programs.uv.enable; nodejs = nodejs; rustup = rustup; hasNode24 = nodejs == "24.15.0"; hasRustup = rustup != null; }'
```

Expected after implementation:

```json
{"bun":true,"hasNode24":true,"hasRustup":true,"nodejs":"24.15.0","rustup":"1.29.0","uv":true}
```

- [ ] **Step 5: Verify the selected Node.js package version**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; }; in { nodejs = pkgs.nodejs.version; nodejs22 = pkgs.nodejs_22.version; nodejs24 = pkgs.nodejs_24.version; }'
```

Expected current output:

```json
{"nodejs":"24.15.0","nodejs22":"22.22.3","nodejs24":"24.15.0"}
```

- [ ] **Step 6: Run formatting and whitespace checks**

Run:

```bash
nix fmt
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 7: Build the host configuration**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: build exits 0. If this fails with daemon socket access errors, report the environment blocker and keep the Nix diff available for review.

- [ ] **Step 8: Commit the implementation**

Run:

```bash
git add nix/modules/home/cli.nix nix/modules/home/programs/toolchains.nix
git diff --cached --check
git commit -m "home: add cli language toolchains"
```

Expected: commit succeeds with only the two implementation files staged.
