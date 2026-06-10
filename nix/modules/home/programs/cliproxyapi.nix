{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  logDir = "${homeDir}/.cliproxyapi/logs";
  sourceConfigFile = "${homeDir}/.cliproxyapi/config.yaml";
  runtimeConfigFileDescription = "$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)/cliproxyapi/config.yaml";
  apiKeyFile = config.sops.secrets."cliproxyapi-api-key".path;
  managementKeyFile = config.sops.secrets."cliproxyapi-management-key".path;
  python = pkgs.python3.withPackages (pythonPackages: [pythonPackages.pyyaml]);
  generateRuntimeConfig = pkgs.writeText "generate-cliproxyapi-runtime-config.py" ''
    from pathlib import Path
    import os
    import yaml

    source_config = Path(os.environ["CLIPROXYAPI_SOURCE_CONFIG"])
    runtime_config = Path(os.environ["CLIPROXYAPI_RUNTIME_CONFIG"])
    api_key_file = Path(os.environ["CLIPROXYAPI_API_KEY_FILE"])
    management_key_file = Path(os.environ["CLIPROXYAPI_MANAGEMENT_KEY_FILE"])

    api_key = api_key_file.read_text().strip()
    management_key = management_key_file.read_text().strip()

    if source_config.exists():
        data = yaml.safe_load(source_config.read_text()) or {}
    else:
        data = {}

    if not isinstance(data, dict):
        raise TypeError(f"{source_config} must contain a YAML mapping")

    remote_management = data.setdefault("remote-management", {})
    if not isinstance(remote_management, dict):
        raise TypeError("remote-management must be a YAML mapping")

    remote_management["secret-key"] = management_key
    data["api-keys"] = [api_key]

    runtime_config.parent.mkdir(parents=True, exist_ok=True)
    temporary_config = runtime_config.with_name(runtime_config.name + ".tmp")
    temporary_config.write_text(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
    temporary_config.chmod(0o600)
    temporary_config.replace(runtime_config)
    runtime_config.chmod(0o600)
  '';
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
in {
  home.packages = [
    perSystem.self.cliproxyapi
  ];

  home.activation.createCliproxyapiLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "${logDir}"
  '';

  home.activation.generateCliproxyapiRuntimeConfig = lib.hm.dag.entryAfter ["sops-nix" "createCliproxyapiLogDir"] ''
    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      echo "Would generate ${runtimeConfigFileDescription} from ${sourceConfigFile} with sops-managed cliproxyapi keys"
    else
      export CLIPROXYAPI_SOURCE_CONFIG=${lib.escapeShellArg sourceConfigFile}
      export CLIPROXYAPI_RUNTIME_CONFIG="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)/cliproxyapi/config.yaml"
      export CLIPROXYAPI_API_KEY_FILE=${lib.escapeShellArg apiKeyFile}
      export CLIPROXYAPI_MANAGEMENT_KEY_FILE=${lib.escapeShellArg managementKeyFile}

      ${python}/bin/python ${generateRuntimeConfig}
    fi
  '';

  launchd.agents.cliproxyapi = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;

    config = {
      Label = "com.cliproxyapi";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          runtime_config="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)/cliproxyapi/config.yaml"
          exec ${lib.getExe perSystem.self.cliproxyapi} -config "$runtime_config"
        ''
      ];
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = "${homeDir}/.cliproxyapi";
      StandardOutPath = "${logDir}/stdout.log";
      StandardErrorPath = "${logDir}/stderr.log";
      EnvironmentVariables = {
        PATH = launchdPath;
        CLIPROXYAPI_API_KEY_FILE = apiKeyFile;
        CLIPROXYAPI_MANAGEMENT_KEY_FILE = managementKeyFile;
      };
    };
  };
}
