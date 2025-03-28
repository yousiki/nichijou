{
  lib,
  ...
}: let
  configFiles = [
    ./config.d/hakase
    ./config.d/nano
    ./config.d/satoshi
  ];

  configText =
    lib.concatStringsSep "\n"
    (map (file: lib.readFile file) configFiles);
in {
  programs.ssh = {
    enable = true;
    includes = [
      "~/.ssh/config.d/*"
      "~/.orbstack/ssh/config"
    ];
    extraConfig = configText;
  };
}
