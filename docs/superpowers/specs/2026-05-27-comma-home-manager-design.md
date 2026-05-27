# Comma Home Manager Design

## Goal

Install and configure the `comma` command for user `yousiki` through Home Manager so the user can run temporary nixpkgs-provided CLI programs with the `,` command without permanently installing those programs.

The target host for validation is the current Apple Silicon macOS host, `sakurai`.

## Selected Approach

Use the `nix-community/nix-index-database` flake and its Home Manager module.

This is preferred over adding `pkgs.comma` directly to `home.packages` because `comma` depends on a nix-index database to resolve executable names to packages. The database flake provides a prebuilt database and a Home Manager integration that exposes the `,` wrapper declaratively.

Do not install `pkgs.comma` directly in this change.

## Flake Input

Add a new flake input:

```nix
nix-index-database = {
  url = "github:nix-community/nix-index-database";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

The input follows the repository's existing `nixpkgs` input so package resolution stays aligned with the rest of the configuration.

## Home Manager Module Structure

Keep the change in the shared Home Manager layer.

Modify `nix/modules/home/common.nix` to import the nix-index database Home Manager module next to the existing Catppuccin Home Manager module:

```nix
imports = [
  inputs.catppuccin.homeModules.catppuccin
  inputs.nix-index-database.homeModules.nix-index
];
```

Enable nix-index and the `comma` wrapper from the same file:

```nix
programs.nix-index = {
  enable = true;
  enableZshIntegration = true;
};

programs.nix-index-database.comma.enable = true;
```

`nix/modules/home/cli.nix` should remain focused on directly installed CLI packages and program-specific imports. It should not add `pkgs.comma` to `home.packages`.

`nix/modules/home/programs/shell.nix` already owns general shell program setup. No shell alias is needed because the module provides the `,` command.

## Runtime Behavior

After activation, the user shell should resolve `,` from the Home Manager profile.

Example usage:

```bash
, hello
, cowsay test
```

When invoked, `comma` uses the nix-index database to find the package providing the requested executable, then runs that package through Nix without adding it as a permanent Home Manager package.

## Data Flow

```text
flake.nix
  declares nix-index-database input following nixpkgs
    -> nix/modules/home/common.nix imports nix-index-database.homeModules.nix-index
      -> Home Manager enables programs.nix-index
      -> Home Manager enables programs.nix-index-database.comma
        -> user profile exposes the "," command
```

## Error Handling

If the `nix-index-database` flake changes or removes the Home Manager module path, Home Manager evaluation should fail at the import.

If the module option for `comma` changes, Home Manager evaluation should fail at `programs.nix-index-database.comma.enable`.

If a requested executable is not present in the nix-index database, `comma` should report that no matching package was found. That is runtime lookup behavior, not a configuration failure.

## Verification

Implementation should verify:

```bash
git diff --check
nix flake update nix-index-database
darwin-rebuild build --flake .#sakurai
```

After activation, verify the user-visible command:

```bash
command -v ,
, hello
```

If `darwin-rebuild build` cannot run in the current environment because the Nix daemon is unavailable, report the daemon-access failure and do not treat it as a configuration failure.

## Non-Goals

- Do not make `comma` a Darwin system-level package in this change.
- Do not install `pkgs.comma` directly in `home.packages`.
- Do not add custom shell aliases for `,`.
- Do not configure command-not-found behavior beyond the nix-index integration needed for `comma`.
