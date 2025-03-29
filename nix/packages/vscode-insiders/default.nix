{ lib, pkgs, ... }:
(pkgs.vscode.override { isInsiders = true; }).overrideAttrs (
  oldAttrs:
  let
    inherit (pkgs.stdenv) system;

    throwSystem = throw "Unsupported system: ${system}";

    plat =
      {
        x86_64-linux = "linux-x64";
        x86_64-darwin = "darwin";
        aarch64-linux = "linux-arm64";
        aarch64-darwin = "darwin-arm64";
        armv7l-linux = "linux-armhf";
      }
      .${system} or throwSystem;

    sha256 = lib.trim (builtins.readFile ./sha256/${plat});
  in
  {
    src = builtins.fetchTarball {
      url = "https://code.visualstudio.com/sha/download?build=insider&os=${plat}";
      inherit sha256;
    };

    version = "latest";

    buildInputs = oldAttrs.buildInputs ++ [ pkgs.krb5 ];

    meta = oldAttrs.meta // {
      mainProgram = "code-insiders";
    };
  }
)
