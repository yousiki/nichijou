_:
let
  # Common exclusion patterns for all formatters
  commonExcludes = [
    "^.*\/[^\/\.]+$"
    "secrets/*"
    "static/*"
  ];
in
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  # Enabled programs
  programs = {
    # Enable deadnix for nix checking
    deadnix.enable = true;
    # Enable keep-sorted for general sorting
    keep-sorted.enable = true;
    # Enable nixfmt for nix formatting
    nixfmt.enable = true;
    # Enable prettier for formatting
    prettier.enable = true;
    # Enable stylua for lua formatting
    stylua.enable = true;
    # Enable shellcheck for shell checking
    shellcheck.enable = true;
    # Enable shfmt for shell formatting
    shfmt.enable = true;
    # Enable statix for nix checking
    statix.enable = true;
    # Enable typos for spell checking
    typos.enable = true;
  };

  # Settings
  settings.formatter = {
    deadnix.excludes = commonExcludes;
    keep-sorted.excludes = commonExcludes;
    nixfmt.excludes = commonExcludes;
    prettier.excludes = commonExcludes;
    stylua.excludes = commonExcludes;
    shellcheck.excludes = commonExcludes;
    shfmt.excludes = commonExcludes;
    statix.excludes = commonExcludes;
    typos.excludes = commonExcludes;
  };
}
