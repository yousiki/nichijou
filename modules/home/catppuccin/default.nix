# Catppuccin configuration for all users
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.catppuccin = {
    enable = lib.mkEnableOption "Catppuccin theme for terminal applications";
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "mocha";
      description = "The flavor of the Catppuccin theme to use.";
      example = "macchiato";
    };
  };

  config =
    let
      cfg = config.${namespace}.catppuccin;
    in
    lib.mkIf cfg.enable {
      catppuccin = {
        enable = lib.mkDefault true;
        flavor = lib.mkDefault cfg.flavor;
      };
      programs.zsh = {
        oh-my-zsh = {
          theme = "catppuccin";
          custom = "${config.home.homeDirectory}/.oh-my-zsh";
        };
        sessionVariables = {
          CATPPUCCIN_FLAVOR = cfg.flavor;
        };
      };
      home.file =
        let
          catppuccin-zsh = pkgs.fetchFromGitHub {
            owner = "JannoTjarks";
            repo = "catppuccin-zsh";
            rev = "main";
            sha256 = "sha256-5mivlJpfp89VNMg9PS20DaMYnws+62Yrktlx5On2Puw=";
          };
        in
        lib.mkIf (config.programs.zsh.enable && config.programs.zsh.oh-my-zsh.enable) {
          ".oh-my-zsh/themes/catppuccin.zsh-theme".source = "${catppuccin-zsh}/catppuccin.zsh-theme";
          ".oh-my-zsh/themes/catppuccin-flavors".source = "${catppuccin-zsh}/catppuccin-flavors";
        };
    };
}
