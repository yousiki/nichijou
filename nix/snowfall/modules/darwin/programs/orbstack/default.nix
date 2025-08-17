{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.orbstack = {
    enable = lib.mkEnableOption "OrbStack";
  };

  config = lib.mkIf config.${namespace}.programs.orbstack.enable {
    # OrbStack must be installed via Homebrew
    assertions = [
      {
        assertion = config.homebrew.enable;
        message = "OrbStack requires Homebrew to install";
      }
    ];

    homebrew.casks = [ "orbstack" ];

    # Add Orbstack SSH config.
    programs.ssh.extraConfig = ''
      Include /Users/${config.system.primaryUser}/.orbstack/ssh/config
    '';
  };
}
