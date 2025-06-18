{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.gh = {
    enable = lib.mkEnableOption "gh";
  };

  config =
    let
      cfg = config.${namespace}.programs.gh;
    in
    lib.mkIf cfg.enable {
      programs.gh = {
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
    };
}
