{
  pname,
  pkgs,
  ...
}: let
  inherit (pkgs) bun fetchurl git lib makeWrapper stdenvNoCC;

  version = "2.2.20";
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
      hash = "sha256-k7w9y54dq8y/WBzYMgf9gW1p6WrPacxTl4I2UqLFoWU=";
    };

    nativeBuildInputs = [makeWrapper];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/libexec/ccstatusline"
      cp -R . "$out/libexec/ccstatusline/"

      makeWrapper ${lib.getExe bun} "$out/bin/ccstatusline" \
        --prefix PATH : ${lib.makeBinPath [git]} \
        --add-flags "$out/libexec/ccstatusline/dist/ccstatusline.js"

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      test -x "$out/bin/ccstatusline"
      test -f "$out/libexec/ccstatusline/dist/ccstatusline.js"

      runHook postInstallCheck
    '';

    meta = {
      description = "Customizable status line formatter for Claude Code CLI";
      homepage = "https://github.com/sirmalloc/ccstatusline";
      license = lib.licenses.mit;
      mainProgram = "ccstatusline";
      platforms = bun.meta.platforms;
    };
  }
