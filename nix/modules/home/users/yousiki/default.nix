{
  lib,
  namespace,
  config,
  ...
}: let
  cfg = config.${namespace}.users.yousiki;
in {
  options.${namespace}.users.yousiki = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "YouSiki";
      description = "The name of the user yousiki.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "you.siki@outlook.com";
      description = "The email of the user yousiki.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.name != null;
        message = "${namespace}.users.yousiki.name must be set";
      }
      {
        assertion = cfg.email != null;
        message = "${namespace}.users.yousiki.email must be set";
      }
    ];
  };
}
