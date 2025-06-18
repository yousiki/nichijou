{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.git = {
    enable = lib.mkEnableOption "Git";

    userName = lib.mkOption {
      type = lib.types.str;
      default = "yousiki";
      description = "The name to configure git with.";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "you.siki@outlook.com";
      description = "The email to configure git with.";
    };
  };

  config =
    let
      cfg = config.${namespace}.programs.git;
    in
    lib.mkIf cfg.enable {
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
        inherit (cfg) userName userEmail;
      };
    };
}
