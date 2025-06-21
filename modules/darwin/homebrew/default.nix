# Homebrew configurations that applied to all nix-darwin systems
# Homebrew is enabled by default, but can be disabled by setting `${namespace}.homebrew.enable = false;`
{
  lib,
  config,
  system,
  namespace,
  ...
}:
{
  options.${namespace}.homebrew = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable homebrew.";
    };
    enableMirror = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable homebrew mirror (Tsinghua TUNA).";
    };
    upgrade = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically upgrade homebrew casks on activation.";
    };
    cleanup = lib.mkOption {
      type = lib.types.str;
      default = "none";
      description = "What to do with outdated casks on activation. Options are 'uninstall' or 'none'.";
    };
  };

  config =
    let
      cfg = config.${namespace}.homebrew;
    in
    lib.mkIf cfg.enable {
      homebrew = {
        # Enable Homebrew.
        enable = true;
        # Upgrade and uninstall homebrew casks automatically.
        onActivation = {
          autoUpdate = true;
          upgrade = false;
          cleanup = "uninstall";
        };
        # Add homebrew taps.
        taps = [
          "buo/cask-upgrade"
          "mihomo-party-org/mihomo-party"
        ];
      };
      # Set environment variables for homebrew mirror.
      environment.variables = lib.mkIf cfg.enableMirror {
        HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
        HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
        HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
        HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
        HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
      };
      # Add `/opt/homebrew/bin` to PATH on Apple silicon hosts.
      environment.systemPath = lib.optional (lib.hasPrefix "aarch64" system) "/opt/homebrew/bin";
    };
}
