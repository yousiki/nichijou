{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.microsoft-office = {
    enable = lib.mkEnableOption "Microsoft Office";
  };

  config = lib.mkIf config.${namespace}.programs.microsoft-office.enable {
    # Microsoft Office must be installed via Homebrew
    assertions = [
      {
        assertion = config.homebrew.enable;
        message = "Microsoft Office requires Homebrew to install";
      }
    ];

    homebrew.casks = [
      "microsoft-auto-update"
      "microsoft-office"
    ];
  };
}
