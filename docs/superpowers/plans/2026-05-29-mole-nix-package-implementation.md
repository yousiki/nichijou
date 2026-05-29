# Mole Nix Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package `tw93/Mole` from source in this flake and install it through the `sakurai` Home Manager profile.

**Architecture:** Add a same-flake package at `nix/packages/mole.nix` that builds Mole's Go helper commands, installs the Bash entrypoint and shell library under `libexec`, and disables upstream self-update/self-remove paths. Add a focused Home Manager module at `nix/modules/home/programs/mole.nix`, then import it from the existing CLI module.

**Tech Stack:** nix-darwin, Blueprint `nix/packages`, Home Manager, `buildGo125Module`, `stdenvNoCC`, `fetchFromGitHub`.

---

## File Structure

- Create `nix/packages/mole.nix`: owns the `tw93/Mole` package definition, source hash, Go helper build, shell script installation, entrypoint patching, smoke checks, and package metadata.
- Create `nix/modules/home/programs/mole.nix`: installs `perSystem.self.mole` into the user profile.
- Modify `nix/modules/home/cli.nix`: imports the Mole Home Manager module.
- Use `docs/superpowers/specs/2026-05-29-mole-nix-package-design.md` as the implementation contract.

---

### Task 1: Add the Same-Flake Mole Package

**Files:**
- Create: `nix/packages/mole.nix`

- [ ] **Step 1: Verify the package does not exist yet**

Run:

```bash
nix build .#mole
```

Expected: FAIL with an error indicating that flake output package `mole` is missing.

- [ ] **Step 2: Create `nix/packages/mole.nix`**

Write this complete file:

```nix
{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs)
    buildGo125Module
    fetchFromGitHub
    lib
    stdenvNoCC
    ;

  version = "1.39.1";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${version}";
    hash = "sha256-NrDUdDx4O/QE0+UgM0aw681vAUbwO0fJ+0t0H5QBm0M=";
  };

  goBins = buildGo125Module {
    pname = "${pname}-go";
    inherit version src;

    vendorHash = "sha256-+JxttzU6y/ETUS8VWKIGCvAs/sM1Xz9DBU4eVniVIes=";

    subPackages = [
      "cmd/analyze"
      "cmd/status"
    ];

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
      "-X main.BuildTime=1970-01-01T00:00:00Z"
    ];

    # Upstream tests assume BSD/macOS du -I behavior; the Nix build
    # environment used in verification hit GNU du's incompatible flags.
    doCheck = false;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/mole"
    cp -R bin lib "$out/libexec/mole/"

    install -m755 "${goBins}/bin/analyze" "$out/libexec/mole/bin/analyze-go"
    install -m755 "${goBins}/bin/status" "$out/libexec/mole/bin/status-go"

    install -m755 mole "$out/bin/mole"

    substituteInPlace "$out/bin/mole" \
      --replace-fail 'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' \
      "SCRIPT_DIR='$out/libexec/mole'" \
      --replace-fail '            update_mole "$force_update" "$nightly_update"' \
      '            echo "Mole is managed by Nix. Update /private/etc/nix-darwin and rebuild with: darwin-rebuild switch --flake /private/etc/nix-darwin#sakurai"' \
      --replace-fail '            remove_mole "$dry_run_remove"' \
      '            echo "Mole is managed by Home Manager. Remove or disable nix/modules/home/programs/mole.nix, then rebuild the sakurai profile."'

    ln -s "$out/bin/mole" "$out/bin/mo"

    patchShebangs "$out/bin" "$out/libexec/mole/bin" "$out/libexec/mole/lib"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/mole" --version | grep -F "Mole version ${version}"
    "$out/bin/mo" --version | grep -F "Mole version ${version}"
    "$out/bin/mo" analyze --help 2>&1 | grep -F "output analysis as JSON"
    "$out/bin/mo" status --help 2>&1 | grep -F "output metrics as JSON"
    "$out/bin/mo" update | grep -F "Mole is managed by Nix"
    "$out/bin/mo" remove --dry-run | grep -F "Mole is managed by Home Manager"

    runHook postInstallCheck
  '';

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    license = lib.licenses.mit;
    mainProgram = "mole";
    platforms = lib.platforms.darwin;
  };
}
```

- [ ] **Step 3: Add the new package file to the index for flake visibility**

Run:

```bash
git add --intent-to-add nix/packages/mole.nix
```

Expected: no output.

- [ ] **Step 4: Build the package**

Run:

```bash
nix build .#mole
```

Expected: PASS and a `result` symlink pointing to the Mole package output.

- [ ] **Step 5: Run package smoke checks manually**

Run:

```bash
./result/bin/mole --version
./result/bin/mo --version
./result/bin/mo analyze --help 2>&1
./result/bin/mo status --help 2>&1
./result/bin/mo update
./result/bin/mo remove --dry-run
```

Expected:

```text
mole --version: contains "Mole version 1.39.1"
mo --version: contains "Mole version 1.39.1"
mo analyze --help: contains "output analysis as JSON"
mo status --help: contains "output metrics as JSON"
mo update: contains "Mole is managed by Nix"
mo remove --dry-run: contains "Mole is managed by Home Manager"
```

- [ ] **Step 6: Run a runtime dry-run with an isolated HOME**

Run:

```bash
MOLE_TEST_HOME="$(mktemp -d /private/tmp/mole-home.XXXXXX)"
HOME="$MOLE_TEST_HOME" MO_NO_OPLOG=1 ./result/bin/mo clean --dry-run
```

Expected: PASS with output containing:

```text
Dry run complete - no changes made
```

- [ ] **Step 7: Commit the package**

Run:

```bash
git add nix/packages/mole.nix
git commit -m "package mole from source"
```

Expected: commit succeeds with only `nix/packages/mole.nix` staged.

---

### Task 2: Add Home Manager Integration

**Files:**
- Create: `nix/modules/home/programs/mole.nix`
- Modify: `nix/modules/home/cli.nix`

- [ ] **Step 1: Verify Mole is not installed through Home Manager yet**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in builtins.elem flake.packages.aarch64-darwin.mole hm.home.packages'
```

Expected: evaluates to `false`, or fails because the package file is not visible before indexing. If it fails with a flake visibility error, run `git add --intent-to-add nix/packages/mole.nix` and rerun the command.

- [ ] **Step 2: Create `nix/modules/home/programs/mole.nix`**

Write this complete file:

```nix
{ perSystem, ... }:

{
  home.packages = [
    perSystem.self.mole
  ];
}
```

- [ ] **Step 3: Import the Mole module from `nix/modules/home/cli.nix`**

Change the `imports` list to include `./programs/mole.nix` after `./programs/jcode.nix`:

```nix
{ pkgs, ... }:

{
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/jcode.nix
    ./programs/mole.nix
    ./programs/cliproxyapi.nix
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/toolchains.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];
}
```

- [ ] **Step 4: Add the new module file to the index for flake visibility**

Run:

```bash
git add --intent-to-add nix/modules/home/programs/mole.nix
```

Expected: no output.

- [ ] **Step 5: Verify Home Manager package membership**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in builtins.elem flake.packages.aarch64-darwin.mole hm.home.packages'
```

Expected:

```json
true
```

- [ ] **Step 6: Commit Home Manager integration**

Run:

```bash
git add nix/modules/home/programs/mole.nix nix/modules/home/cli.nix
git commit -m "home: install mole"
```

Expected: commit succeeds with only the Mole Home Manager module and `cli.nix` staged.

---

### Task 3: Verify the Host Build

**Files:**
- No source edits.
- Generated `result` symlink may appear after build commands.

- [ ] **Step 1: Check staged and unstaged diff hygiene**

Run:

```bash
git status --short --branch -uall
git diff --check
```

Expected:

```text
git status: clean except for a generated result symlink if one exists
git diff --check: no output
```

- [ ] **Step 2: Build the full host configuration**

Run:

```bash
darwin-rebuild build --flake .#sakurai
```

Expected: PASS. If Nix daemon access is blocked by the sandbox, rerun with the required permissions and record the exact output.

- [ ] **Step 3: Inspect the generated Home Manager package path**

Run:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in flake.packages.aarch64-darwin.mole.meta.mainProgram'
```

Expected:

```text
mole
```

- [ ] **Step 4: Remove only the generated build symlink from this task**

Run this only if `result` is a symlink generated by `nix build .#mole` or `darwin-rebuild build --flake .#sakurai` during this task:

```bash
test -L result
ls -l result
unlink result
```

Expected: `result` is removed and no tracked source file changes.

- [ ] **Step 5: Final status check**

Run:

```bash
git status --short --branch -uall
```

Expected: output contains only the branch summary line. No modified, staged, or untracked files should remain from this implementation.
