# Virtualisation for darwin systems using Orbstack.
# Only applied to systems tagged with "virtualisation".
{
  config,
  lib,
  namespace,
  ...
}:
let
  enableVirtualisation = builtins.elem "virtualisation" config.${namespace}.tags;
in
lib.mkIf enableVirtualisation {
  # Install Orbstack via Homebrew cask.
  homebrew.casks = [
    "orbstack"
  ];

  # Add SSH config for Orbstack.
  programs.ssh.extraConfig = ''
    Include /Users/${config.homebrew.user}/.orbstack/ssh/config
  '';
}
