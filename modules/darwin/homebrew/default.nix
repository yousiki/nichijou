# Homebrew configurations for all darwin systems.
{
  config,
  lib,
  namespace,
  system,
  ...
}:
{
  options.${namespace}.homebrew = {
    enable = lib.mkEnableOption "Homebrew";
    enableChina = lib.mkEnableOption "China mirror";
  };

  config =
    let
      cfg = config.${namespace}.homebrew;
    in
    lib.mkIf cfg.enable {
      homebrew = {
        # Enable Homebrew.
        enable = true;
        # Upgrade homebrew casks automatically.
        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "none";
        };
        # Add homebrew taps.
        taps = [ "buo/cask-upgrade" ];
      };

      # Enable TUNA mirror for homebrew if the system is tagged with "china".
      environment.variables = lib.optionalAttrs cfg.enableChina {
        HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
        HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
        HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
        HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
        HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
      };

      # Add `/opt/homebrew/bin` to PATH on Apple silicon systems.
      environment.systemPath =
        let
          # Check if the system is Apple silicon.
          isArm = system == "aarch64-darwin";
        in
        lib.optional isArm "/opt/homebrew/bin";
    };
}
