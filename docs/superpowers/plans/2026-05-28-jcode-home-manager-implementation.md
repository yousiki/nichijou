# Jcode Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package upstream `jcode` prebuilt binaries as a Blueprint package and install it for user `yousiki` through Home Manager.

**Architecture:** Define `jcode` in Blueprint's `nix/packages/` tree so it becomes `packages.<system>.jcode`. Add a focused Home Manager module that consumes the package with `perSystem.self.jcode`, avoiding overlays and Homebrew.

**Tech Stack:** Nix flakes, Blueprint, nix-darwin, Home Manager, prebuilt GitHub release assets.

---

## File Structure

- Create `nix/packages/jcode.nix`: the prebuilt-binary package derivation.
- Create `nix/modules/home/programs/jcode.nix`: the Home Manager integration.
- Modify `nix/modules/home/cli.nix`: import the new module beside the other coding-agent CLIs.
- Do not modify `flake.nix`: Blueprint automatically discovers `nix/packages/jcode.nix` because the flake already uses `prefix = "nix/"`.
- Do not add `nix/overlays/`: the package is consumed through `perSystem.self.jcode`.
- Do not modify provider credentials, login state, MCP config, or files under `~/.jcode`.

Before starting implementation, run:

```bash
git status --short --untracked-files=all
```

Expected: inspect and preserve any unrelated user changes. Do not revert unrelated files.

### Task 1: Add The Blueprint Package

**Files:**
- Create: `nix/packages/jcode.nix`
- Test: package evaluation and package build commands

- [ ] **Step 1: Verify the package does not exist yet**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? jcode; true'
```

Expected before implementation: assertion failure because `jcode` is not exposed yet.

If it fails with Nix daemon access text like this, retry with the needed permissions:

```text
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

- [ ] **Step 2: Create the package file**

Create `nix/packages/jcode.nix` with exactly:

```nix
{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "0.14.3";

  sources = {
    aarch64-darwin = {
      asset = "jcode-macos-aarch64";
      hash = "sha256-7+NSKBZM6Fi14xhosvaqu32QZH3wlAyWJSGxPopxfXQ=";
    };

    x86_64-darwin = {
      asset = "jcode-macos-x86_64";
      hash = "sha256-2lC5KLqkVfq9zggsgO9uhPgU9r7JyMA+wMmfkr+gG2M=";
    };

    x86_64-linux = {
      asset = "jcode-linux-x86_64";
      hash = "sha256-Mp61GnTBuUuV8vEJlZpFkMaKlbeFkRdB4h8q78+jCQU=";
    };

    aarch64-linux = {
      asset = "jcode-linux-aarch64";
      hash = "sha256-x9RddW0mBhbl5ZgyBW4ycTgOlumP2sR62gta5a70HdY=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "jcode is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/1jehuang/jcode/releases/download/v${version}/${source.asset}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    if [ -f "${source.asset}.bin" ]; then
      mkdir -p "$out/libexec/jcode"
      install -m755 "${source.asset}" "$out/libexec/jcode/${source.asset}"
      install -m755 "${source.asset}.bin" "$out/libexec/jcode/${source.asset}.bin"

      for library in libssl.so* libcrypto.so*; do
        if [ -e "$library" ]; then
          install -m644 "$library" "$out/libexec/jcode/$library"
        fi
      done

      ln -s "$out/libexec/jcode/${source.asset}" "$out/bin/jcode"
    else
      install -m755 "${source.asset}" "$out/bin/jcode"
    fi

    runHook postInstall
  '';

  meta = {
    description = "Coding agent harness for multi-session workflows";
    homepage = "https://github.com/1jehuang/jcode";
    license = lib.licenses.mit;
    mainProgram = "jcode";
    platforms = builtins.attrNames sources;
  };
}
```

- [ ] **Step 3: Make the package visible to git-backed flake evaluation**

Run:

```bash
git add --intent-to-add nix/packages/jcode.nix
```

Expected: exit code 0.

- [ ] **Step 4: Verify the package version output**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.packages.aarch64-darwin.jcode.version'
```

Expected output:

```json
"0.14.3"
```

- [ ] **Step 5: Build the package**

Run:

```bash
nix build .#packages.aarch64-darwin.jcode
```

Expected: build exits 0 and creates a `result` symlink.

- [ ] **Step 6: Smoke test the built binary**

Run:

```bash
JCODE_NO_TELEMETRY=1 ./result/bin/jcode --version
```

Expected: output contains `jcode v0.14.3`.

- [ ] **Step 7: Remove the package build symlink**

Run:

```bash
rm result
```

Expected: `result` is removed.

### Task 2: Add The Home Manager Module

**Files:**
- Create: `nix/modules/home/programs/jcode.nix`
- Modify: `nix/modules/home/cli.nix`
- Test: Home Manager package evaluation and activation package build

- [ ] **Step 1: Create the Home Manager module**

Create `nix/modules/home/programs/jcode.nix` with exactly:

```nix
{ perSystem, ... }:

{
  home.packages = [
    perSystem.self.jcode
  ];
}
```

- [ ] **Step 2: Import the module**

Modify `nix/modules/home/cli.nix` so the imports list is exactly:

```nix
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/jcode.nix
    ./programs/git.nix
    ./programs/shell.nix
  ];
```

Leave the existing `home.packages` list unchanged.

- [ ] **Step 3: Make the new module visible to git-backed flake evaluation**

Run:

```bash
git add --intent-to-add nix/modules/home/programs/jcode.nix
```

Expected: exit code 0.

- [ ] **Step 4: Verify Home Manager includes the package**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in builtins.any (pkg: pkg.pname or null == "jcode") hm.home.packages'
```

Expected output:

```json
true
```

- [ ] **Step 5: Build the Home Manager activation package**

Run:

```bash
nix build .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.activationPackage
```

Expected: build exits 0 and may create a `result` symlink.

- [ ] **Step 6: Remove the activation build symlink if present**

Run:

```bash
rm -f result
```

Expected: no `result` symlink remains.

### Task 3: Final Verification

**Files:**
- Verify: repository diff and formatting

- [ ] **Step 1: Check whitespace**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 2: Review the final diff**

Run:

```bash
git diff -- docs/superpowers/specs/2026-05-28-jcode-home-manager-design.md docs/superpowers/plans/2026-05-28-jcode-home-manager-implementation.md nix/packages/jcode.nix nix/modules/home/programs/jcode.nix nix/modules/home/cli.nix
```

Expected: diff only contains the jcode package, Home Manager module, CLI import, and jcode spec/plan docs.
