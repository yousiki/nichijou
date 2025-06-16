# Configure homebrew on Darwin.
{ lib, system, ... }:
{
  homebrew = {
    # Enable Homebrew.
    enable = true;

    # Upgrade and uninstall homebrew casks automatically.
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    # Add homebrew taps.
    taps = [
      "buo/cask-upgrade"
      "mihomo-party-org/mihomo-party"
    ];
  };

  # Set environment variables for homebrew mirror.
  environment.variables = {
    HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
  };

  # Add `/opt/homebrew/bin` to PATH on Apple silicon hosts.
  environment.systemPath = lib.optional (system == "aarch64-darwin") "/opt/homebrew/bin";
}
