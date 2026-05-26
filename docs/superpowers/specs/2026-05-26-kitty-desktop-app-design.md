# Kitty Desktop App Design

## Goal

Add Kitty Terminal as the first shared Home Manager managed desktop app for this configuration repository. Kitty should be installed and configured through Home Manager, not Homebrew, and should use Catppuccin Mocha plus Maple Mono on macOS.

## Scope

This design covers the shared Home Manager structure, the Catppuccin integration, and the Kitty user configuration. It does not apply the implementation yet.

The target host for validation is the current Apple Silicon macOS host, `sakurai`, for user `yousiki`.

## Module Structure

Add a shared desktop-app entry point under Home Manager:

```text
nix/modules/home/
  common.nix
  cli.nix
  desktop.nix
  programs/
    kitty.nix
```

`desktop.nix` will represent shared GUI and desktop applications. It will initially import only `./programs/kitty.nix`.

The current host user configuration will import the new shared desktop module alongside the existing common and CLI modules:

```nix
imports = [
  flake.homeModules.common
  flake.homeModules.cli
  flake.homeModules.desktop
];
```

Kitty will not be imported from `cli.nix`. Even though it is a terminal emulator, it is a macOS desktop application in this repository's configuration model.

## Catppuccin Integration

Add `catppuccin/nix` as a flake input and import its Home Manager module through the existing shared Home Manager configuration.

`common.nix` will own global appearance settings because they apply across programs rather than to a single application:

```nix
imports = [
  inputs.catppuccin.homeModules.catppuccin
];

catppuccin = {
  enable = true;
  flavor = "mocha";
};
```

The configuration will set `mocha` explicitly even though it is the Catppuccin default, so the intended theme is visible in the repo.

This global Catppuccin setting may affect current and future Home Manager programs supported by `catppuccin/nix`. That is intentional: the desired policy is a shared Home Manager appearance theme rather than a Kitty-only theme.

## Kitty Configuration

Create `nix/modules/home/programs/kitty.nix` and enable Home Manager's Kitty module.

Kitty should use the nixpkgs `kitty` package through Home Manager. It should use Maple Mono as its font, relying on the existing Darwin font package already installed by the system configuration.

The initial Kitty settings should cover macOS-friendly defaults:

```nix
programs.kitty = {
  enable = true;
  font = {
    name = "Maple Mono NF CN";
    size = 14;
  };
  settings = {
    macos_option_as_alt = "both";
    macos_quit_when_last_window_closed = "yes";
    confirm_os_window_close = 0;
    window_padding_width = 6;
    hide_window_decorations = "titlebar-only";
    shell_integration = "enabled";
    copy_on_select = "clipboard";
    scrollback_lines = 10000;
    enable_audio_bell = false;
  };
};
```

Do not set a Home Manager `programs.kitty.themeFile` in this module. Catppuccin should provide Kitty theming through the `catppuccin/nix` Home Manager module, avoiding a second independent theme mechanism.

## Data Flow

```text
flake.nix
  adds catppuccin/nix input
    -> Blueprint exposes inputs to modules
      -> home/common.nix imports catppuccin Home Manager module
      -> home/common.nix sets global Mocha theme
      -> home/desktop.nix imports programs/kitty.nix
      -> sakurai/yousiki imports desktop.nix
```

## Error Handling

If the Catppuccin flake input or Home Manager module path changes, flake evaluation should fail early.

Kitty `settings` are written to `kitty.conf` as free-form configuration. Unsupported Kitty setting names may not be caught by Nix evaluation, so the implementation should use stable Kitty option names and keep the settings list conservative.

If the Maple Mono font family name does not match the installed font exactly, Kitty may fall back to another font at runtime. Nix evaluation cannot fully verify runtime font selection, so this should be checked after activation if the rendered font looks wrong.

## Verification

Implementation should verify at least:

```bash
nix flake show
darwin-rebuild build --flake .#sakurai
```

If Blueprint exposes a convenient standalone Home Manager output for `yousiki@sakurai`, the implementation should also evaluate or build that output. If the exact output name is not obvious, inspect `nix flake show` first and document the targeted command used.

## Non-Goals

- Do not add Kitty to `homebrew.casks`.
- Do not put Kitty under the CLI module.
- Do not introduce a broader desktop application framework beyond the shared `desktop.nix` import entry point.
- Do not hand-write a Kitty Catppuccin theme file.
- Do not configure per-host Kitty behavior unless a host-specific need appears later.
