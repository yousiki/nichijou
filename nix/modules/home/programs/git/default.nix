{
  lib,
  pkgs,
  namespace,
  config,
  ...
}:
let
  username = config.snowfallorg.user.name;

  cfg = config.${namespace}.programs.git;
in
{
  options.${namespace}.programs.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable git.";
    };

    userName = lib.mkOption {
      type = lib.types.str;
      default = config.${namespace}.users.${username}.name;
      description = "The name to configure git with.";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      default = config.${namespace}.users.${username}.email;
      description = "The email to configure git with.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        inherit (cfg) userName userEmail;

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
      };

      gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        extensions = with pkgs; [
          gh-actions-cache # cache actions
          gh-cal # contributions calender terminal viewer
          gh-copilot # github copilot integration
          gh-dash # dashboard with pull requests and issues
          gh-eco # explore the ecosystem
          gh-markdown-preview # preview markdown files
          gh-poi # clean up local branches safely
        ];
      };

      gitui = {
        enable = true;
      };
    };
  };
}
