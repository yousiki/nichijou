# OpenCode Home Manager Design

## Goal

Install and configure `opencode` for user `yousiki` through Home Manager, matching the existing dedicated-module pattern used for AI coding tools such as `claude-code` and `codex`.

The target host for validation is the current Apple Silicon macOS host, `sakurai`.

## Selected Approach

Use Home Manager's native `programs.opencode` module with conservative global settings.

This is preferred over adding `pkgs.opencode` directly to `home.packages` because the Home Manager module owns both installation and generated configuration under `XDG_CONFIG_HOME/opencode`. The locked flake already exposes `pkgs.opencode` and the `programs.opencode` option set, so no new flake input is needed.

Do not configure provider, model, or API-key values in this change. Those are runtime/account-specific choices and should remain outside this shared machine configuration unless the user explicitly chooses a provider policy later.

## Home Manager Module Structure

Create a focused module:

```text
nix/modules/home/programs/opencode.nix
```

Import it from the existing CLI aggregator:

```nix
{
  imports = [
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./programs/git.nix
    ./programs/opencode.nix
    ./programs/shell.nix
  ];
}
```

The module should use the Home Manager option rather than a plain package list entry:

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

## Runtime Behavior

After activation, the user profile should expose the `opencode` command from the Home Manager generation.

Home Manager should write:

```text
~/.config/opencode/opencode.json
~/.config/opencode/tui.json
```

The global `opencode.json` should disable OpenCode's own updater because Nix owns package updates. Sharing remains manual, which keeps the upstream default behavior explicit without disabling the feature completely.

The TUI config should set a small baseline for interactive use while avoiding model/provider assumptions. It should not set a theme because the existing Catppuccin Home Manager integration already owns `programs.opencode.tui.theme`.

## Data Flow

```text
nix/modules/home/cli.nix
  imports ./programs/opencode.nix
    -> programs.opencode.enable installs pkgs.opencode
    -> programs.opencode.settings writes opencode/opencode.json
    -> programs.opencode.tui writes opencode/tui.json
      -> activation exposes the opencode command and config files
```

## Error Handling

If the locked Home Manager input changes or removes `programs.opencode`, evaluation should fail at the new module.

If `pkgs.opencode` is renamed or unavailable on `aarch64-darwin`, evaluation or build should fail when resolving `programs.opencode.package`.

If the upstream OpenCode config schema changes, OpenCode may warn at runtime, but the Home Manager evaluation should still catch type-level mistakes in Nix values.

## Verification

Implementation should verify the configuration before and after the change:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in hm.programs.opencode.enable'
```

Before the module is imported, this should evaluate to `false` or otherwise show that OpenCode is not enabled for the user. After implementation, it should return:

```text
true
```

Verify generated config ownership:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in { settings = hm.programs.opencode.settings; tui = hm.programs.opencode.tui; }'
```

Expected output should include `autoupdate = false`, `share = "manual"`, and the TUI schema/mouse settings. A separate check may confirm that the effective TUI theme remains `catppuccin` from the repository's global Catppuccin integration.

Verify the host build:

```bash
darwin-rebuild build --flake .#sakurai
```

If build or evaluation fails with `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted`, report the daemon-access failure and do not treat it as a configuration failure.

## Non-Goals

- Do not add a new flake input for OpenCode.
- Do not add `pkgs.opencode` directly to `home.packages`.
- Do not configure provider, model, or API-key values.
- Do not add custom shell aliases or wrappers for `opencode`.
- Do not modify existing `claude-code`, `codex`, `git`, `ghostty`, Homebrew, or vibeproxy files as part of this change.
