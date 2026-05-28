# CLIProxyAPI Home Manager Service Design

## Goal

Replace the discarded VibeProxy cask with a Nix-managed CLIProxyAPI service for
user `yousiki` on the Apple Silicon macOS host `sakurai`.

The service should behave like a user-level long-running daemon: start at login,
restart when it exits, write predictable logs, and run the upstream CLIProxyAPI
binary from the Nix store. Homebrew must not install, start, or manage
CLIProxyAPI.

## Selected Approach

Use a local Nix package plus a Home Manager LaunchAgent module:

```text
nix/packages/cliproxyapi.nix
nix/modules/home/programs/cliproxyapi.nix
```

`nix/packages/cliproxyapi.nix` packages the pinned upstream release binary. It
downloads the upstream GitHub release tarball, extracts the published
`cli-proxy-api` binary, and installs it into the Nix store.

`nix/modules/home/programs/cliproxyapi.nix` installs the package into the Home
Manager user profile, creates the runtime log directory, and declares a
per-user launchd agent through Home Manager's native `launchd.agents` option.

The current upstream release checked during design is `v7.1.24`, published on
2026-05-27. The implementation should pin that version and commit the fixed
Nix hash for the selected release asset.

## Non-Selected Approaches

Do not use `homebrew.brews`, `brew services`, or manual `launchctl` commands.
The user explicitly rejected Homebrew-managed CLIProxyAPI after the initial
mistaken implementation.

Do not use nix-darwin `launchd.user.agents` first. CLIProxyAPI is a per-user
service that reads user-owned auth/config state under `~/.cli-proxy-api`, so
Home Manager is the correct owner. nix-darwin is the fallback only if Home
Manager's launchd integration cannot express the required agent.

Do not build from source. The user selected upstream binary packaging. Building
from source would add Go dependency and build maintenance that is not needed for
this change.

Do not manage `~/.cli-proxy-api/config.yaml` in Home Manager. That file can
contain provider credentials, API keys, OAuth-derived settings, and user-edited
routing policy. This change should only point the service at that path.

## Package Definition

Create:

```text
nix/packages/cliproxyapi.nix
```

The package should:

- Pin `version = "7.1.24"`.
- Fetch upstream release assets from
  `https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/`.
- Select release assets by `stdenvNoCC.hostPlatform.system`.
- Support at least `aarch64-darwin`, because that is the current host.
- Prefer supporting the flake's other declared systems when matching upstream
  binary assets are available: `x86_64-linux` and `aarch64-linux`.
- Install the upstream executable as `$out/bin/cli-proxy-api`.
- Add a `$out/bin/cliproxyapi` symlink to preserve the common command name used
  by the Homebrew formula and by the user's request.
- Set `meta.mainProgram = "cliproxyapi"` so `lib.getExe` resolves to the stable
  command-name-preserving wrapper.

The package should use `stdenvNoCC.mkDerivation` and `fetchurl`, following the
existing `nix/packages/jcode.nix` pattern for upstream prebuilt binaries.

## Home Manager Module

Create:

```text
nix/modules/home/programs/cliproxyapi.nix
```

Wire it into:

```text
nix/modules/home/cli.nix
```

Place it near the other AI/coding-tool modules:

```nix
imports = [
  ./programs/claude-code.nix
  ./programs/codex.nix
  ./programs/opencode.nix
  ./programs/jcode.nix
  ./programs/cliproxyapi.nix
  ./programs/git.nix
  ./programs/shell.nix
];
```

The module should add:

```nix
home.packages = [
  perSystem.self.cliproxyapi
];
```

The module should also create the log directory through Home Manager activation:

```text
~/.cli-proxy-api/logs
```

It should not create, modify, template, symlink, or validate:

```text
~/.cli-proxy-api/config.yaml
```

## LaunchAgent

The Home Manager module should declare a Darwin-only launchd agent:

```text
launchd.agents.cliproxyapi
```

The generated plist should use these semantics:

- `Label = "com.cliproxyapi"`
- `ProgramArguments = [ <nix-store-binary> "-config" "/Users/yousiki/.cli-proxy-api/config.yaml" ]`
- `RunAtLoad = true`
- `KeepAlive = true`
- `WorkingDirectory = "/Users/yousiki/.cli-proxy-api"`
- `StandardOutPath = "/Users/yousiki/.cli-proxy-api/logs/stdout.log"`
- `StandardErrorPath = "/Users/yousiki/.cli-proxy-api/logs/stderr.log"`

The agent should set a deterministic `PATH` containing the Home Manager user
profile and normal system paths. This matters because CLIProxyAPI wraps tools
such as Codex and Claude Code, and launchd jobs do not inherit an interactive
shell environment.

The `PATH` should be Nix/Home Manager oriented. It should not require
`/opt/homebrew/bin` for CLIProxyAPI itself.

## Runtime Behavior

After Home Manager activation, `cliproxyapi` and `cli-proxy-api` should both be
available from the user profile.

At login, launchd should start CLIProxyAPI as the `yousiki` user with:

```text
-config /Users/yousiki/.cli-proxy-api/config.yaml
```

If the config file is missing or invalid, the service may fail and retry. That
is expected runtime behavior; this Nix change should not create a placeholder
config because a placeholder would either be incomplete or risk overwriting
private user state.

Logs should be written under:

```text
/Users/yousiki/.cli-proxy-api/logs/
```

## VibeProxy Removal

Keep removing `vibeproxy` from:

```text
nix/modules/darwin/homebrew.nix
```

Because `homebrew.onActivation.cleanup = "none"` in this repository, deleting
the cask from the Brewfile stops declarative management but does not by itself
guarantee uninstallation on machines where the cask is already installed. The
mistaken local install was already removed manually; implementation should
verify that VibeProxy is absent from the generated cask list.

## Verification

Before implementation, assertions for the new package and LaunchAgent should
fail because they do not exist yet.

After implementation, run:

```bash
git diff --check
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; in assert flake.packages.aarch64-darwin ? cliproxyapi; true'
nix build .#packages.aarch64-darwin.cliproxyapi
./result/bin/cliproxyapi --help
nix build .#darwinConfigurations.sakurai.config.home-manager.users.yousiki.home.activationPackage
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; cfg = flake.darwinConfigurations.sakurai.config; casks = map (cask: cask.name) cfg.homebrew.casks; agent = cfg.home-manager.users.yousiki.launchd.agents.cliproxyapi; in assert !(builtins.elem "vibeproxy" casks); assert agent.enable == true; true'
```

If `nix build` creates a `result` symlink, remove it before finishing.

If Nix daemon access is blocked by the execution sandbox, rerun the Nix commands
with the required permissions or report the daemon-access failure explicitly.

After activation on the host, verify runtime state:

```bash
launchctl print gui/$(id -u)/com.cliproxyapi
test -d ~/.cli-proxy-api/logs
```

Only run health checks such as `curl http://localhost:8317/health` when the
user-managed config file exists and is expected to start successfully.

## References

- Upstream CLIProxyAPI installation docs publish macOS and Linux binary release
  assets and show a launchd service using `-config ~/.cli-proxy-api/config.yaml`.
- Upstream configuration docs state that the server reads `config.yaml` by
  default and accepts `--config` to point at a specific file.
- The repository's existing `jcode` package shows the local pattern for
  packaging upstream prebuilt binaries under `nix/packages/` and consuming them
  through a per-tool Home Manager module.
