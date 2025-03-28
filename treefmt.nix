_: {
  # Used to find the project root
  projectRootFile = "flake.nix";

  # Enabled programs
  programs = {
    # Enable alejandra for nix formatting
    alejandra.enable = true;
    # Enable deadnix for nix checking
    deadnix.enable = true;
    # Enable keep-sorted for general sorting
    keep-sorted.enable = true;
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
    # Enable yamlfmt for yaml formatting
    yamlfmt.enable = true;
  };

  # Settings
  settings.formatter = {
    typos.excludes = [
      "secrets/*"
      "static/*"
    ];
  };
}
