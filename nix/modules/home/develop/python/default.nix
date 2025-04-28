{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.develop.python;
in
{
  options.${namespace}.develop.python = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable python programming language support.";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Install required packages.
      packages = with pkgs; [
        micromamba
        python3
        ruff
        rye
        uv
      ];

      # Configure tools.
      file = {
        ".condarc".source = ./.condarc;
        ".mambarc".source = ./.condarc;
        ".rye/config.toml".source = ./rye.toml;
        ".config/uv/uv.toml".source = ./uv.toml;
        ".config/pip/pip.conf".source = ./pip.conf;
      };
    };

    # Configure shells to use micromamba.
    programs = {
      bash.initExtra = ''
        if [[ -x "$(command -v micromamba)" ]]; then
          eval "$(micromamba shell hook --shell bash)"
        fi
      '';
      zsh.initContent = ''
        if [[ -x "$(command -v micromamba)" ]]; then
          eval "$(micromamba shell hook --shell zsh)"
        fi
      '';
    };
  };
}
