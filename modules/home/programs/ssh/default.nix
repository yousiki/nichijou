{
  config,
  lib,
  namespace,
  system,
  ...
}:
{
  options.${namespace}.programs.ssh = {
    enable = lib.mkEnableOption "SSH client configuration";
  };

  config = lib.mkIf config.${namespace}.programs.ssh.enable {
    programs.ssh = {
      enable = true;
      includes = [
        "~/.ssh/config.d/*"
      ] ++ (lib.optional (lib.snowfall.system.is-darwin system) "~/.orbstack/ssh/config");
      extraConfig =
        let
          configFiles = [
            ./config.d/hakase
            ./config.d/nano
            ./config.d/satoshi
            ./config.d/yukko
          ];

          configText = lib.concatStringsSep "\n" (map (file: lib.readFile file) configFiles);
        in
        configText;
    };
  };
}
