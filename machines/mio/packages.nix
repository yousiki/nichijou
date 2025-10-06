{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ffmpeg # required by Minecraft Replay Mod
  ];
}
