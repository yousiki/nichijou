{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf config.${namespace}.programs.git.enable {
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
  };
}
