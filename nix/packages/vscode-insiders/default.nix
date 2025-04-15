{ lib, pkgs, ... }:
let
  plat =
    {
      x86_64-linux = "linux-x64";
      x86_64-darwin = "darwin";
      aarch64-linux = "linux-arm64";
      aarch64-darwin = "darwin-arm64";
      armv7l-linux = "linux-armhf";
    }
    .${pkgs.stdenv.system} or (throw "Unsupported system: ${pkgs.stdenv.system}");

  fetcher = if pkgs.stdenv.isDarwin then pkgs.fetchzip else builtins.fetchTarball;
  version = lib.trim (builtins.readFile ./. + "/version/${plat}");
  sha256 = lib.trim (builtins.readFile ./. + "/sha256/${plat}");
  url = "https://update.code.visualstudio.com/${version}/${plat}/insider";
  src = fetcher {
    inherit url sha256;
  };
in
(pkgs.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: {
  inherit version src;

  buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];

  meta = oldAttrs.meta // {
    mainProgram = "code-insiders";
  };
})
