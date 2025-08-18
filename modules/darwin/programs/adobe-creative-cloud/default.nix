{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.adobe-creative-cloud = {
    enable = lib.mkEnableOption "Adobe Creative Cloud";
  };

  config = lib.mkIf config.${namespace}.programs.adobe-creative-cloud.enable {
    # Adobe Creative Cloud must be installed via Homebrew
    assertions = [
      {
        assertion = config.homebrew.enable;
        message = "Adobe Creative Cloud requires Homebrew to install";
      }
    ];

    homebrew.casks = [ "adobe-creative-cloud" ];
  };
}
