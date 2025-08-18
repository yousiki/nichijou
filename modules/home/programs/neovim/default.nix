{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.neovim = {
    enable = lib.mkEnableOption "neovim";
  };

  config = lib.mkIf config.${namespace}.programs.neovim.enable {
    home.packages = with pkgs; [ neovim ];
  };
}
