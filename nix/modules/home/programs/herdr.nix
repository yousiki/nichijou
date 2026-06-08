{ lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;
  };
in
{
  home.packages = [
    pkgs.herdr
  ];

  xdg.configFile."herdr/config.toml" = {
    source = tomlFormat.generate "herdr-config.toml" settings;
    onChange = ''
      ${lib.getExe pkgs.herdr} server reload-config >/dev/null 2>&1 || true
    '';
  };
}
