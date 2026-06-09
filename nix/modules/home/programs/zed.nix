{
  lib,
  pkgs,
  ...
}: let
  zedPackage = pkgs.zed-editor;
  zedCli = pkgs.writeShellApplication {
    name = "zed";
    text = ''
      exec ${lib.getExe' zedPackage "zeditor"} "$@"
    '';
  };
in {
  home.packages = [
    zedCli
  ];

  catppuccin.zed = {
    enable = true;
    icons.enable = true;
  };

  programs.zed-editor = {
    enable = true;
    package = zedPackage;

    extraPackages = with pkgs; [
      alejandra
      basedpyright
      nil
      nixd
      nixfmt
      ruff
      rust-analyzer
      rustfmt
      ty
    ];

    extensions = [
      "astro"
      "biome"
      "caddyfile"
      "catppuccin"
      "comment"
      "csv"
      "docker-compose"
      "dockerfile"
      "git-firefly"
      "html"
      "ini"
      "just"
      "latex"
      "lua"
      "make"
      "nix"
      "python-requirements"
      "rainbow-csv"
      "sql"
      "ssh-config"
      "swift"
      "terraform"
      "toml"
      "typst"
      "vue"
      "xml"
    ];

    userSettings = {
      auto_update = false;

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 14;

      ui_font_family = "Maple Mono NF CN";
      ui_font_size = 16;

      terminal = {
        font_family = "Maple Mono NF CN";
        font_size = 14;
        option_as_meta = true;
      };

      vim_mode = true;

      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "nil"
          ];
        };
      };

      lsp = {
        nil = {
          binary.path = lib.getExe pkgs.nil;
        };

        nixd = {
          binary.path = lib.getExe pkgs.nixd;
        };
      };

      format_on_save = "off";
    };
  };
}
