# CLI Toolchains Home Manager Design

## Goal

Install common development toolchains for user `yousiki` through Home Manager:

- Bun
- Node.js Active LTS
- Rust toolchains
- uv

The target host for validation is the current Apple Silicon macOS host, `sakurai`.

## Selected Approach

Create one focused Home Manager module for CLI toolchains:

```text
nix/modules/home/programs/toolchains.nix
```

Import it from the existing CLI aggregator:

```text
nix/modules/home/cli.nix
```

This keeps language/runtime tooling separate from shell UX configuration and AI coding tools while matching the repository's existing dedicated-module pattern.

## Tool Choices

Use these package and module choices:

```nix
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
```

Node.js must use the current Active LTS line, not a stale remembered LTS. On 2026-05-28, the official Node.js release schedule has Node.js 24 as Active LTS, Node.js 22 as Maintenance LTS, and Node.js 26 as Current. The locked flake's nixpkgs input exposes `pkgs.nodejs_24.version` as `24.15.0`.

Rust should use `rustup` instead of fixed `rustc` and `cargo` packages because the requested scope is Rust toolchains. `rustup` allows project-specific stable, beta, nightly, target, and component selection without encoding those choices in the shared machine config.

Do not add npm, yarn, pnpm, global npm packages, Rust targets, Rust components, Python versions, uv-managed projects, or shell aliases in this change. Those are project-specific policy decisions.

## Runtime Behavior

After Home Manager activation, the user profile should expose:

```text
bun
node
npm
npx
corepack
rustup
cargo
rustc
uv
uvx
```

`cargo` and `rustc` come from the active rustup-managed toolchain after rustup has initialized or selected a default toolchain. The Nix profile owns the `rustup` command; rustup owns downloaded Rust toolchains under the user's home directory.

Home Manager should own Bun and uv installation/configuration through their native modules. No Bun or uv settings are required for this baseline.

## Data Flow

```text
nix/modules/home/cli.nix
  imports ./programs/toolchains.nix
    -> programs.bun.enable installs pkgs.bun
    -> home.packages installs pkgs.nodejs_24 and pkgs.rustup
    -> programs.uv.enable installs pkgs.uv
      -> activation exposes commands in the Home Manager generation
```

## Error Handling

If Home Manager removes or renames `programs.bun` or `programs.uv`, evaluation should fail in the new module.

If nixpkgs removes `pkgs.nodejs_24` after its upstream EOL, evaluation should fail instead of silently moving to a different Node major. That failure is desirable because it forces a deliberate LTS review.

If `rustup` cannot download toolchains at runtime, that is a network/runtime issue outside the Nix build. The Nix verification only proves that the rustup command is installed.

## Verification

Before implementation, confirm the current locked packages and the Node LTS choice:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; }; in { nodejs = pkgs.nodejs.version; nodejs22 = pkgs.nodejs_22.version; nodejs24 = pkgs.nodejs_24.version; }'
```

Expected current output:

```json
{"nodejs":"24.15.0","nodejs22":"22.22.3","nodejs24":"24.15.0"}
```

After implementation, verify Home Manager state:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in { bun = hm.programs.bun.enable; uv = hm.programs.uv.enable; packages = map (pkg: pkg.pname or pkg.name) hm.home.packages; }'
```

Expected output should show Bun and uv enabled, and include Node.js 24 plus rustup in `home.packages`.

Verify the host build:

```bash
darwin-rebuild build --flake .#sakurai
```

If build or evaluation fails with `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted`, report the daemon-access failure and do not treat it as a configuration failure.

## Non-Goals

- Do not add a new flake input.
- Do not use ad hoc installers outside Nix/Home Manager.
- Do not install Node Current or Maintenance LTS when Active LTS is available.
- Do not configure global npm, Bun, uv, Cargo, or Rust project defaults.
- Do not add project-specific language versions or package manager policies.
