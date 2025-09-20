_: {
  flake.modules =
    let
      darwinModule =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          tags = config.manifest.tags or [ ];
        in
        {
          homebrew = {
            # Enable Homebrew.
            enable = true;
            # Upgrade and uninstall homebrew casks automatically.
            onActivation = {
              autoUpdate = true;
              upgrade = false;
              cleanup = "zap";
            };
            # Add homebrew taps.
            taps = [
              "buo/cask-upgrade"
            ];
          };

          # Add `/opt/homebrew/bin` to PATH on Apple silicon (aarch64-darwin) hosts.
          environment.systemPath = lib.optional (pkgs.system == "aarch64-darwin") "/opt/homebrew/bin";

          # Set environment variables for homebrew mirror.
          environment.variables = lib.optionalAttrs (builtins.elem "china" tags) {
            HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
            HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
            HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
            HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
            HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
          };
        };
    in
    {
      darwin.homebrew = darwinModule;
    };
}
