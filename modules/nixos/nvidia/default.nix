{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";
  };

  config =
    let
      cfg = config.${namespace}.nvidia;
    in
    lib.mkIf cfg.enable {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware = {
        nvidia = {
          modesetting.enable = true; # Enable modesetting.
          nvidiaSettings = true; # Enable nvidia settings.
          open = false; # Use proprietary driver.
        };

        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [ libGL ];
        };

        # Enable nvidia container toolkit.
        nvidia-container-toolkit.enable = true;
      };

      environment.sessionVariables = {
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
    };
}
