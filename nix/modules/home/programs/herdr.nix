{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.herdr;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "Herdr";

    package = lib.mkPackageOption pkgs "herdr" { };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          onboarding = false;

          terminal = {
            shell_mode = "auto";
            new_cwd = "follow";
          };

          keys = {
            prefix = "ctrl+a";
            command = [
              {
                key = "prefix+alt+g";
                type = "pane";
                command = "lazygit";
                description = "run lazygit";
              }
            ];
          };

          ui = {
            confirm_close = false;
            mouse_capture = true;
          };
        }
      '';
      description = ''
        Herdr configuration written as TOML to
        {file}`$XDG_CONFIG_HOME/herdr/config.toml`.

        See the official Herdr configuration documentation at
        <https://herdr.dev/docs/configuration/> for supported options. Herdr also
        supports overriding this path with the {env}`HERDR_CONFIG_PATH`
        environment variable; this module manages the default XDG config path.
      '';
    };

    reloadOnChange = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to run {command}`herdr server reload-config` after the generated
        configuration file changes. Failures are ignored because the Herdr server
        may not be running during Home Manager activation.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [
          cfg.package
        ];
      }

      (lib.mkIf (cfg.settings != { }) {
        xdg.configFile."herdr/config.toml" = {
          source = tomlFormat.generate "herdr-config.toml" cfg.settings;
        }
        // lib.optionalAttrs cfg.reloadOnChange {
          onChange = ''
            ${lib.getExe cfg.package} server reload-config >/dev/null 2>&1 || true
          '';
        };
      })
    ]
  );
}
