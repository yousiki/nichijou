{ namespace, ... }:
{
  networking = {
    hostName = "mio";
    computerName = "yousiki-mio";
  };

  ${namespace} = {
    fonts.enable = true;
    homebrew = {
      enable = true;
      enableChina = true;
    };
    nix = {
      enableChina = true;
      enableCachix = true;
      enableGarnix = true;
    };
    services = {
      openssh.enable = true;
      tailscale.enable = true;
    };
    programs = {
      _1password.enable = true;
      adobe-creative-cloud.enable = true;
      orbstack.enable = true;
    };
  };
}
