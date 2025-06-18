{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
{
  options.${namespace}.programs.helix = {
    enable = lib.mkEnableOption "helix editor";
  };

  config =
    let
      cfg = config.${namespace}.programs.helix;
    in
    lib.mkIf cfg.enable {
      programs.helix = {
        enable = true;
        defaultEditor = true;
        extraPackages = with pkgs; [
          helix-gpt
        ];
        languages = {
          language-server = {
            gpt = {
              command = "${pkgs.helix-gpt}/bin/helix-gpt";
            };
          };
          language = [
            {
              name = "nix";
              auto-format = true;
              language-servers = [
                "nil"
                "nixd"
                "gpt"
              ];
            }
          ];
        };
      };
      home.packages = with pkgs; [
        helix-gpt
      ];
    };
}
