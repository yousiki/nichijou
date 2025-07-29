{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.git = {
    enable = true;
    package = pkgs.git;
    lfs.enable = true;
    delta.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push = {
        autoSetRemote = true;
        default = "current";
        followTags = true;
      };
      rebase.autoStash = true;
    };
    userName = "yousiki";
    userEmail = "you.siki@outlook.com";
  };
}
