{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  logDir = "${homeDir}/.cliproxyapi/logs";
  configFile = "${homeDir}/.cliproxyapi/config.yaml";
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  launchdPath = lib.concatStringsSep ":" [
    profileBin
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
in
{
  home.packages = [
    perSystem.self.cliproxyapi
  ];

  home.activation.createCliproxyapiLogDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  launchd.agents.cliproxyapi = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;

    config = {
      Label = "com.cliproxyapi";
      ProgramArguments = [
        "${lib.getExe perSystem.self.cliproxyapi}"
        "-config"
        configFile
      ];
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = "${homeDir}/.cliproxyapi";
      StandardOutPath = "${logDir}/stdout.log";
      StandardErrorPath = "${logDir}/stderr.log";
      EnvironmentVariables = {
        PATH = launchdPath;
      };
    };
  };
}
