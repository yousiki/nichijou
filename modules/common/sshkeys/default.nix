{
  config,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
let
  githubKeys = pkgs.fetchurl {
    url = "https://github.com/yousiki.keys";
    sha256 = "sha256-0nVK4I3w8aF34Pzy6gROoJAFlH4HjzCLsjGmim0celE=";
  };

  authorizedKeys = lib.splitString "\n" (builtins.readFile githubKeys);
in
{
  options.${namespace}.sshkeys = {
    enable = lib.mkEnableOption "SSH keys";
  };

  config = lib.mkIf config.${namespace}.sshkeys.enable (
    lib.mkMerge (
      [
        {
          users.users.yousiki.openssh.authorizedKeys.keys = authorizedKeys;
        }
      ]
      ++ (lib.optional (lib.snowfall.system.is-linux system) {
        users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
      })
    )
  );
}
