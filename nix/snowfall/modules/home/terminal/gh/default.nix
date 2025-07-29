{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
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
}
