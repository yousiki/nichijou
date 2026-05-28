# CLIProxyAPI Home Manager Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package upstream CLIProxyAPI release binaries with Nix, run CLIProxyAPI as a Home Manager-managed LaunchAgent for `yousiki`, and remove VibeProxy from declarative Homebrew management.

**Architecture:** A local package under `nix/packages/cliproxyapi.nix` owns upstream binary fetching and installation. A focused Home Manager module under `nix/modules/home/programs/cliproxyapi.nix` installs the package, creates the log directory, and declares the per-user launchd agent. `nix/modules/darwin/homebrew.nix` only removes the obsolete `vibeproxy` cask.

**Tech Stack:** Nix flakes, numtide Blueprint package discovery, Home Manager, nix-darwin, launchd LaunchAgents, upstream CLIProxyAPI v7.1.24 release binaries.

---

## File Structure

- Create: `nix/packages/cliproxyapi.nix`
  - Local Nix package for the pinned upstream CLIProxyAPI release binary.
  - Provides both `cli-proxy-api` and `cliproxyapi` executable names.
- Create: `nix/modules/home/programs/cliproxyapi.nix`
  - Home Manager package installation, log directory activation, and LaunchAgent declaration.
  - Does not manage `~/.cli-proxy-api/config.yaml`.
- Modify: `nix/modules/home/cli.nix`
  - Imports the new `cliproxyapi` Home Manager program module near the other AI/coding tools.
- Modify: `nix/modules/darwin/homebrew.nix`
  - Removes `vibeproxy` from `homebrew.casks`.
  - Keeps `homebrew.brews = [ ];` and does not add `cliproxyapi`.
- Do not modify: `flake.nix`
  - Blueprint already auto-discovers `nix/packages/*.nix` and `nix/modules/**/*.nix` under `prefix = "nix/"`.
- Do not modify: `~/.cli-proxy-api/config.yaml`
  - User-owned runtime config remains outside Nix.

## Source Facts

Actual upstream v7.1.24 release asset names differ from older CLIProxyAPI docs. Use these assets and hashes:

```nix
sources = {
  aarch64-darwin = {
    asset = "CLIProxyAPI_7.1.24_darwin_aarch64.tar.gz";
    hash = "sha256-iqydNqPCniQ7jicb/RPMYPJnohv1G+yZIdjo0OHx2Gs=";
  };

  x86_64-darwin = {
    asset = "CLIProxyAPI_7.1.24_darwin_amd64.tar.gz";
    hash = "sha256-W12WbL5GX9dTTx6mljtgSCQeSEkpvaj6ZpRZ1JwiZfo=";
  };

  x86_64-linux = {
    asset = "CLIProxyAPI_7.1.24_linux_amd64.tar.gz";
    hash = "sha256-ih5BKXqXEsCRbMAvhJxdukayaFvHoZuWzWJ8JoTznZ4=";
  };

  aarch64-linux = {
    asset = "CLIProxyAPI_7.1.24_linux_aarch64.tar.gz";
    hash = "sha256-fOMu4tdDFFszPoBxJ1MjuQ3GMIzWak8rRFk8sJ+4sTw=";
  };
};
```

The macOS ARM64 archive contains:

```text
LICENSE
README.md
README_CN.md
config.example.yaml
cli-proxy-api
```

---

### Task 1: Write Failing Evaluation Checks

**Files:**
- No file changes.

- [ ] **Step 1: Verify the package does not exist yet**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? cliproxyapi; true'
```

Expected: FAIL with an assertion failure because `flake.packages.aarch64-darwin.cliproxyapi` is not defined before `nix/packages/cliproxyapi.nix` exists.

- [ ] **Step 2: Verify the LaunchAgent does not exist yet**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.launchd.agents ? cliproxyapi; true'
```

Expected: FAIL with an assertion failure because `hm.launchd.agents.cliproxyapi` is not defined before the Home Manager module exists.

- [ ] **Step 3: Commit**

No commit. This task only proves the checks fail before implementation.

---

### Task 2: Add the CLIProxyAPI Nix Package

**Files:**
- Create: `nix/packages/cliproxyapi.nix`

- [ ] **Step 1: Create the package file**

Add `nix/packages/cliproxyapi.nix`:

```nix
{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl lib stdenvNoCC;

  version = "7.1.24";

  sources = {
    aarch64-darwin = {
      asset = "CLIProxyAPI_7.1.24_darwin_aarch64.tar.gz";
      hash = "sha256-iqydNqPCniQ7jicb/RPMYPJnohv1G+yZIdjo0OHx2Gs=";
    };

    x86_64-darwin = {
      asset = "CLIProxyAPI_7.1.24_darwin_amd64.tar.gz";
      hash = "sha256-W12WbL5GX9dTTx6mljtgSCQeSEkpvaj6ZpRZ1JwiZfo=";
    };

    x86_64-linux = {
      asset = "CLIProxyAPI_7.1.24_linux_amd64.tar.gz";
      hash = "sha256-ih5BKXqXEsCRbMAvhJxdukayaFvHoZuWzWJ8JoTznZ4=";
    };

    aarch64-linux = {
      asset = "CLIProxyAPI_7.1.24_linux_aarch64.tar.gz";
      hash = "sha256-fOMu4tdDFFszPoBxJ1MjuQ3GMIzWak8rRFk8sJ+4sTw=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "cliproxyapi is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -D -m755 cli-proxy-api "$out/bin/cli-proxy-api"
    ln -s "$out/bin/cli-proxy-api" "$out/bin/cliproxyapi"

    runHook postInstall
  '';

  meta = {
    description = "OpenAI/Gemini/Claude/Codex compatible API service for CLI coding tools";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = lib.licenses.mit;
    mainProgram = "cliproxyapi";
    platforms = builtins.attrNames sources;
  };
}
```

- [ ] **Step 2: Make the new package visible to Git-based flake evaluation**

Run:

```bash
git add --intent-to-add nix/packages/cliproxyapi.nix
```

Expected: `git status --short` shows ` A nix/packages/cliproxyapi.nix`.

- [ ] **Step 3: Verify the package now exists in flake outputs**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? cliproxyapi; true'
```

Expected: PASS and prints `true`.

- [ ] **Step 4: Build the package**

Run:

```bash
nix build .#packages.aarch64-darwin.cliproxyapi
```

Expected: PASS and creates a `result` symlink containing `bin/cli-proxy-api` and `bin/cliproxyapi`.

- [ ] **Step 5: Verify both command names exist**

Run:

```bash
test -x ./result/bin/cli-proxy-api
test -x ./result/bin/cliproxyapi
./result/bin/cliproxyapi --help
```

Expected: both `test` commands exit 0, and `./result/bin/cliproxyapi --help` exits 0 after printing CLIProxyAPI help text.

- [ ] **Step 6: Remove the build result symlink**

Run:

```bash
rm result
```

Expected: `test ! -e result` exits 0.

- [ ] **Step 7: Commit**

Run:

```bash
git add nix/packages/cliproxyapi.nix
git commit -m "home: add cliproxyapi package"
```

Expected: commit succeeds and includes only `nix/packages/cliproxyapi.nix`.

---

### Task 3: Add the Home Manager LaunchAgent Module

**Files:**
- Create: `nix/modules/home/programs/cliproxyapi.nix`
- Modify: `nix/modules/home/cli.nix`

- [ ] **Step 1: Create the Home Manager module**

Add `nix/modules/home/programs/cliproxyapi.nix`:

```nix
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  logDir = "${homeDir}/.cli-proxy-api/logs";
  configFile = "${homeDir}/.cli-proxy-api/config.yaml";
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  launchdPath = lib.concatStringsSep ":" [
    profileBin
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  home.packages = [
    perSystem.self.cliproxyapi
  ];

  home.activation.createCliproxyapiLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  launchd.agents.cliproxyapi = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;

    config = {
      Label = "com.cliproxyapi";
      ProgramArguments = [
        "${lib.getExe perSystem.self.cliproxyapi}"
        "-config"
        configFile
      ];
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = "${homeDir}/.cli-proxy-api";
      StandardOutPath = "${logDir}/stdout.log";
      StandardErrorPath = "${logDir}/stderr.log";
      EnvironmentVariables = {
        PATH = launchdPath;
      };
    };
  };
}
```

- [ ] **Step 2: Import the module from `cli.nix`**

Modify `nix/modules/home/cli.nix` so the import list is:

```nix
{ pkgs, ... }:

{
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/opencode.nix
    ./programs/jcode.nix
    ./programs/cliproxyapi.nix
    ./programs/git.nix
    ./programs/shell.nix
  ];

  home.packages = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
  ];
}
```

- [ ] **Step 3: Make the new module visible to Git-based flake evaluation**

Run:

```bash
git add --intent-to-add nix/modules/home/programs/cliproxyapi.nix
```

Expected: `git status --short` shows ` A nix/modules/home/programs/cliproxyapi.nix`.

- [ ] **Step 4: Verify the Home Manager LaunchAgent evaluates**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; agent = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki.launchd.agents.cliproxyapi; in { enable = agent.enable; label = agent.config.Label; args = agent.config.ProgramArguments; stdout = agent.config.StandardOutPath; stderr = agent.config.StandardErrorPath; path = agent.config.EnvironmentVariables.PATH; }'
```

Expected: PASS and prints JSON with:

```json
{
  "enable": true,
  "label": "com.cliproxyapi",
  "args": [
    "/nix/store/...",
    "-config",
    "/Users/yousiki/.cli-proxy-api/config.yaml"
  ],
  "stdout": "/Users/yousiki/.cli-proxy-api/logs/stdout.log",
  "stderr": "/Users/yousiki/.cli-proxy-api/logs/stderr.log",
  "path": "/etc/profiles/per-user/yousiki/bin:..."
}
```

- [ ] **Step 5: Verify the Home Manager activation package builds**

Run:

```bash
nix build .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.activationPackage
```

Expected: PASS and creates a `result` symlink for the Home Manager activation package.

- [ ] **Step 6: Remove the build result symlink**

Run:

```bash
rm result
```

Expected: `test ! -e result` exits 0.

- [ ] **Step 7: Commit**

Run:

```bash
git add nix/modules/home/cli.nix nix/modules/home/programs/cliproxyapi.nix
git commit -m "home: run cliproxyapi as a launchd agent"
```

Expected: commit succeeds and includes only the Home Manager module and `cli.nix` import.

---

### Task 4: Remove VibeProxy From Declarative Homebrew Management

**Files:**
- Modify: `nix/modules/darwin/homebrew.nix`

- [ ] **Step 1: Remove `vibeproxy` from the cask list**

Update `nix/modules/darwin/homebrew.nix` so the cask and brew section is:

```nix
    casks = [
      "1password"
      "cloudflare-warp"
    ];
    brews = [ ];
```

There must be no `cliproxyapi` entry in `homebrew.brews`.

- [ ] **Step 2: Verify Homebrew casks and brews evaluate correctly**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; cfg = flake.darwinConfigurations.sakurai.config.homebrew; casks = map (cask: cask.name) cfg.casks; brews = map (brew: brew.name) cfg.brews; in assert !(builtins.elem "vibeproxy" casks); assert !(builtins.elem "cliproxyapi" brews); { inherit casks brews; }'
```

Expected: PASS and prints:

```json
{"brews":[],"casks":["1password","cloudflare-warp"]}
```

- [ ] **Step 3: Commit**

Run:

```bash
git add nix/modules/darwin/homebrew.nix
git commit -m "darwin: remove vibeproxy cask"
```

Expected: commit succeeds and includes only `nix/modules/darwin/homebrew.nix`.

---

### Task 5: Final Integration Verification

**Files:**
- No file changes.

- [ ] **Step 1: Check formatting whitespace**

Run:

```bash
git diff --check
```

Expected: PASS with no output.

- [ ] **Step 2: Verify the package and service configuration together**

Run:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; cfg = flake.darwinConfigurations.sakurai.config; casks = map (cask: cask.name) cfg.homebrew.casks; brews = map (brew: brew.name) cfg.homebrew.brews; hm = cfg.home-manager.users.yousiki; agent = hm.launchd.agents.cliproxyapi; in assert flake.packages.aarch64-darwin ? cliproxyapi; assert !(builtins.elem "vibeproxy" casks); assert !(builtins.elem "cliproxyapi" brews); assert agent.enable == true; assert agent.config.Label == "com.cliproxyapi"; assert builtins.elem "-config" agent.config.ProgramArguments; true'
```

Expected: PASS and prints `true`.

- [ ] **Step 3: Build the Darwin system closure without a result symlink**

Run:

```bash
nix build --no-link .#darwinConfigurations.sakurai.system
```

Expected: PASS.

- [ ] **Step 4: Confirm no build result symlink remains**

Run:

```bash
test ! -e result
```

Expected: PASS.

- [ ] **Step 5: Verify Homebrew no longer owns CLIProxyAPI**

Run:

```bash
brew services list
brew list --formula cliproxyapi
launchctl print gui/$(id -u)/homebrew.mxcl.cliproxyapi
```

Expected:

- `brew services list` does not list `cliproxyapi`.
- `brew list --formula cliproxyapi` fails with `No such keg`.
- `launchctl print gui/$(id -u)/homebrew.mxcl.cliproxyapi` fails with `Could not find service`.

- [ ] **Step 6: Verify Git state**

Run:

```bash
git status --short
```

Expected: no uncommitted files.

---

### Task 6: Optional Host Activation Check

**Files:**
- No file changes.

- [ ] **Step 1: Apply the nix-darwin configuration if interactive sudo is available**

Run:

```bash
sudo darwin-rebuild switch --flake .#sakurai
```

Expected: PASS. If sudo requires a password and the current session cannot provide one, stop and report that activation was not run.

- [ ] **Step 2: Verify the Nix-managed LaunchAgent after activation**

Run:

```bash
launchctl print gui/$(id -u)/com.cliproxyapi
test -d ~/.cli-proxy-api/logs
command -v cliproxyapi
command -v cli-proxy-api
```

Expected:

- `launchctl print` finds `com.cliproxyapi` after Home Manager activation.
- `test -d ~/.cli-proxy-api/logs` exits 0.
- `command -v cliproxyapi` resolves to the Home Manager profile.
- `command -v cli-proxy-api` resolves to the Home Manager profile.

- [ ] **Step 3: Only run an HTTP health check when user config exists**

Run:

```bash
test -f ~/.cli-proxy-api/config.yaml && curl -fsS http://localhost:8317/health
```

Expected:

- If `~/.cli-proxy-api/config.yaml` exists and the service starts successfully, curl prints the health response.
- If the config file is absent, this command exits 1 at `test -f`; report that no health check was run because the user-managed config is absent.
