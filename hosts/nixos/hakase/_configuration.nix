{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "hakase";

  services.autosuspend.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver = {
    layout = "cn";
    xkbVariant = "";
  };
  programs.xwayland.enable = true;

  users.users.yousiki = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "lxd" "yousiki"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    cloudflare-warp
  ];
}
