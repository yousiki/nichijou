{ lib, pkgs, ... }:
{
  programs.ssh.includes = lib.optional pkgs.stdenv.isDarwin "~/.orbstack/ssh/config";

  programs.zsh.profileExtra = lib.optionalString pkgs.stdenv.isDarwin ''
    if [ -f ~/.orbstack/shell/init.zsh ]; then
      source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    fi
  '';
}
