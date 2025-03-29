{ pkgs, ... }:
{
  # Default user shell: zsh.
  users.defaultUserShell = pkgs.zsh;

  # Use sudo without password.
  security.sudo.wheelNeedsPassword = false;

  # Set timezone.
  time.timeZone = "Asia/Shanghai";

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = "24.11";
}
