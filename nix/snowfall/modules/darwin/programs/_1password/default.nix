{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs._1password = {
    enable = lib.mkEnableOption "1Password";
  };

  config = lib.mkIf config.${namespace}.programs._1password.enable {
    # 1Password must be installed via Homebrew
    assertions = [
      {
        assertion = config.homebrew.enable;
        message = "1Password requires Homebrew to install";
      }
    ];

    homebrew.casks = [ "1password" ];
  };
}
