{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  options.${namespace}.programs.keka = {
    enable = lib.mkEnableOption "Keka";
  };

  config = lib.mkIf config.${namespace}.programs.keka.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Keka is only supported on macOS.";
      }
    ];

    warnings =
      let
        isOlder = v: (builtins.compareVersions pkgs.${namespace}.keka.version v) == -1;
        nixpkgsVer = pkgs.keka.version;
        homebrewVer = lib.${namespace}.casks.keka.version;
        mkWarn = name: ver: lib.optional (isOlder ver) "Keka is older than ${name}. Consider updating it.";
      in
      (mkWarn "nixpkgs" nixpkgsVer) ++ (mkWarn "homebrew" homebrewVer);

    home.packages = [ pkgs.${namespace}.keka ];
  };
}
