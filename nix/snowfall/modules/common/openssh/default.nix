# SSH server configuration for all systems.
# Fetch my keys from GitHub and set them as authorized keys for users.
{ pkgs, lib, ... }:
let
  githubKeys = pkgs.fetchurl {
    url = "https://github.com/yousiki.keys";
    sha256 = "sha256-0nVK4I3w8aF34Pzy6gROoJAFlH4HjzCLsjGmim0celE=";
  };
  authorizedKeys = lib.splitString "\n" (builtins.readFile githubKeys);
  users = [ "yousiki" ] ++ lib.optional pkgs.stdenv.hostPlatform.isLinux "root";
in
{
  services.openssh.enable = true;

  users.users = builtins.listToAttrs (
    builtins.map (user: {
      name = user;
      value = {
        openssh.authorizedKeys.keys = authorizedKeys;
      };
    }) users
  );
}
