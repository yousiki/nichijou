# Zed Home Manager Design

## Goal

Manage Zed as a first-class Home Manager program in this nix-darwin repository, while preserving the user's existing habit of launching the editor with the `zed` command.

The target host for validation is the current Apple Silicon macOS host, `sakurai`, for user `yousiki`.

## Current State

`pkgs.zed-editor` is already installed as a generic desktop package from `nix/modules/home/programs/desktop-apps.nix`.

That installs the app, but it leaves Zed's user configuration unmanaged and exposes the Nix package's command as `zeditor`, not `zed`.

Do not use `pkgs.zed`. In nixpkgs, `pkgs.zed` is a different data lake tool. Zed the editor is `pkgs.zed-editor`.

## Selected Approach

Create a dedicated Home Manager module:

```text
nix/modules/home/programs/zed.nix
```

Import it from:

```text
nix/modules/home/desktop.nix
```

Move Zed ownership out of the generic desktop app list by removing `zed-editor` from `nix/modules/home/programs/desktop-apps.nix`.

This keeps install and configuration ownership in one module, matching the existing `kitty.nix`, `ghostty.nix`, and `cmux.nix` structure.

## Home Manager Zed Module

The new module should enable Home Manager's Zed module:

```nix
programs.zed-editor = {
  enable = true;
  package = pkgs.zed-editor;
};
```

Use Home Manager's `programs.zed-editor.userSettings` for baseline `settings.json` values instead of hand-writing `xdg.configFile."zed/settings.json"`.

Keep `mutableUserSettings = true`, the Home Manager default, so Zed's Settings UI can still update the settings file. This change should establish a sane baseline, not make every Zed preference read-only.

Do not use `programs.zed-editor.defaultEditor`, because that option sets editor variables to the underlying `zeditor` command. This design wants `EDITOR` and `VISUAL` to use the preserved `zed` command.

## Baseline User Settings

Use conservative editor defaults that match the existing machine preferences without over-configuring language servers or AI providers:

```nix
userSettings = {
  auto_update = false;

  telemetry = {
    diagnostics = false;
    metrics = false;
  };

  buffer_font_family = "Maple Mono NF CN";
  buffer_font_size = 14;

  ui_font_family = ".SystemUIFont";
  ui_font_size = 16;

  terminal = {
    font_family = "Maple Mono NF CN";
    font_size = 14;
    option_as_meta = true;
  };

  format_on_save = "on";
};
```

Rationale:

- `auto_update = false` keeps editor updates controlled by the flake and nixpkgs lock.
- Telemetry metrics and diagnostics are disabled at the client settings level.
- Maple Mono NF CN matches the existing terminal/editor font preference already used by Kitty and Ghostty.
- `.SystemUIFont` keeps the Zed interface native on macOS while using Maple Mono for code and the integrated terminal.
- `option_as_meta = true` matches the existing macOS terminal preference of treating Option as an alternate/meta key.
- `format_on_save = "on"` is a useful baseline for a code editor and remains overrideable per project.

Do not enable Vim mode by default. The user did not request modal editing, and changing the base editing model is too invasive for a baseline setup.

Do not configure AI providers, edit prediction, language server paths, or project-specific formatters in this change. Those are better handled once a concrete workflow requires them.

## Theme and Icons

Use the existing `catppuccin/nix` integration rather than hand-writing Zed theme files.

The global Home Manager config already sets:

```nix
catppuccin = {
  enable = true;
  flavor = "mocha";
};
```

The Zed module should explicitly opt into the Zed target for local clarity:

```nix
catppuccin.zed = {
  enable = true;
  icons.enable = true;
};
```

This should generate Catppuccin Mocha Zed theme and icon settings consistently with the rest of the Home Manager Catppuccin setup.

## Extensions

Install only baseline extensions that support the configuration itself:

```nix
extensions = [
  "catppuccin"
  "nix"
];
```

`catppuccin.zed.icons.enable = true` supplies the `catppuccin-icons` extension, so do not list it a second time in `programs.zed-editor.extensions`.

Do not add language extensions for Rust, Go, Python, JavaScript, or other ecosystems in this change. Zed has broad built-in language support, and extra language packages should be added when a real project workflow needs them.

## `zed` Command Wrapper

Create a Home Manager package that exposes a `zed` executable and forwards to `zeditor`:

```nix
let
  zedPackage = pkgs.zed-editor;
  zedCli = pkgs.writeShellApplication {
    name = "zed";
    text = ''
      exec ${lib.getExe' zedPackage "zeditor"} "$@"
    '';
  };
in
{
  home.packages = [
    zedCli
  ];
}
```

Use a package wrapper instead of a shell alias so the command works consistently from shells and subprocesses that use the Home Manager profile `PATH`.

If a future `pkgs.zed-editor` package starts providing `bin/zed` directly, the Home Manager profile may report a file collision. That is an acceptable failure mode: it signals that this wrapper has become unnecessary and should be removed.

## Editor Environment Variables

Set editor variables through Home Manager session variables:

```nix
home.sessionVariables = {
  EDITOR = "zed --wait";
  VISUAL = "zed --wait";
};
```

This follows Zed's documented default-editor pattern while preserving the user's preferred `zed` command.

## Data Flow

```text
home/desktop.nix
  imports programs/zed.nix
    -> programs.zed-editor installs pkgs.zed-editor and writes baseline Zed settings
    -> catppuccin.zed writes Catppuccin Mocha Zed theme/icon integration
    -> home.packages installs the zed wrapper
    -> home.sessionVariables sets EDITOR and VISUAL to zed --wait
```

## Error Handling

If `programs.zed-editor` changes option names, Home Manager evaluation should fail at the option reference.

If `catppuccin/nix` changes the Zed option names, Home Manager evaluation should fail at `catppuccin.zed`.

If `lib.getExe' pkgs.zed-editor "zeditor"` stops resolving, Home Manager evaluation or build should fail before activation. The implementation should then check whether nixpkgs renamed the underlying Zed CLI or started exposing `zed` directly.

If Zed cannot install an extension on startup, that is a runtime extension-gallery issue, not a nix-darwin evaluation failure. The baseline config should still evaluate.

## Verification

Implementation should verify:

```bash
git diff --check
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.zed-editor.enable; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; packageName = hm.programs.zed-editor.package.pname or hm.programs.zed-editor.package.name; in assert packageName == "zed-editor"; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; names = map (pkg: pkg.pname or pkg.name) hm.home.packages; in assert builtins.elem "zed" names; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.programs.zed-editor.userSettings.buffer_font_family == "Maple Mono NF CN"; true'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; hm = flake.darwinConfigurations.sakurai.config.home-manager.users.yousiki; in assert hm.home.sessionVariables.EDITOR == "zed --wait" && hm.home.sessionVariables.VISUAL == "zed --wait"; true'
nix build --impure --no-link --expr 'let flake = builtins.getFlake "git+file:///private/etc/nix-darwin"; pkgs = flake.darwinConfigurations.sakurai.pkgs; in pkgs.zed-editor'
darwin-rebuild build --flake .#sakurai
```

After activation, verify user-visible behavior:

```bash
command -v zed
command -v zeditor
zed --help
printenv EDITOR
printenv VISUAL
```

If the current sandbox cannot access the Nix daemon and reports `cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted`, report that as an environment limitation rather than a configuration failure.

## References

- Zed CLI reference: https://zed.dev/docs/reference/cli
- Zed settings reference: https://zed.dev/docs/reference/all-settings
- Zed appearance/font settings: https://zed.dev/docs/appearance
- Zed telemetry settings: https://zed.dev/docs/telemetry
- Catppuccin Zed Home Manager options: https://nix.catppuccin.com/options/25.05/home/catppuccin.zed/

## Non-Goals

- Do not install `pkgs.zed`.
- Do not install Zed through Homebrew or the upstream macOS app installer.
- Do not add a shell alias for `zed`.
- Do not create `/usr/local/bin/zed`.
- Do not make Zed settings fully read-only.
- Do not configure AI providers, edit prediction, or MCP servers in this baseline change.
- Do not add broad language-specific extensions or LSP packages without a concrete workflow requirement.
