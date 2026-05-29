{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs)
    buildGo125Module
    fetchFromGitHub
    lib
    stdenvNoCC
    ;

  version = "1.39.1";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${version}";
    hash = "sha256-NrDUdDx4O/QE0+UgM0aw681vAUbwO0fJ+0t0H5QBm0M=";
  };

  goBins = buildGo125Module {
    pname = "${pname}-go";
    inherit version src;

    vendorHash = "sha256-+JxttzU6y/ETUS8VWKIGCvAs/sM1Xz9DBU4eVniVIes=";

    subPackages = [
      "cmd/analyze"
      "cmd/status"
    ];

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
      "-X main.BuildTime=1970-01-01T00:00:00Z"
    ];

    # Upstream tests assume BSD/macOS du -I behavior; the Nix build
    # environment used in verification hit GNU du's incompatible flags.
    doCheck = false;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/mole"
    cp -R bin lib "$out/libexec/mole/"

    install -m755 "${goBins}/bin/analyze" "$out/libexec/mole/bin/analyze-go"
    install -m755 "${goBins}/bin/status" "$out/libexec/mole/bin/status-go"

    install -m755 mole "$out/bin/mole"

    substituteInPlace "$out/bin/mole" \
      --replace-fail 'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' \
      "SCRIPT_DIR='$out/libexec/mole'" \
      --replace-fail '    local sudo_keepalive_pid=""' \
      '    local sudo_keepalive_pid=""

    echo "Mole is managed by Nix. Update /private/etc/nix-darwin and rebuild with: darwin-rebuild switch --flake /private/etc/nix-darwin#sakurai"
    return 0' \
      --replace-fail '    local installer_url="https://raw.githubusercontent.com/tw93/mole/''${installer_ref}/install.sh"' \
      '    local installer_url="nix-managed-update-disabled"' \
      --replace-fail '            update_mole "$force_update" "$nightly_update"' \
      '            echo "Mole is managed by Nix. Update /private/etc/nix-darwin and rebuild with: darwin-rebuild switch --flake /private/etc/nix-darwin#sakurai"' \
      --replace-fail '            remove_mole "$dry_run_remove"' \
      '            echo "Mole is managed by Home Manager. Remove or disable nix/modules/home/programs/mole.nix, then rebuild the sakurai profile."'

    ln -s "$out/bin/mole" "$out/bin/mo"

    patchShebangs "$out/bin" "$out/libexec/mole/bin" "$out/libexec/mole/lib"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/mole" --version | grep -F "Mole version ${version}"
    "$out/bin/mo" --version | grep -F "Mole version ${version}"
    "$out/bin/mo" analyze --help 2>&1 | grep -F "output analysis as JSON"
    "$out/bin/mo" status --help 2>&1 | grep -F "output metrics as JSON"
    "$out/bin/mo" update | grep -F "Mole is managed by Nix"
    "$out/bin/mo" remove --dry-run | grep -F "Mole is managed by Home Manager"
    grep -A8 -F "update_mole() {" "$out/bin/mole" | grep -F "Mole is managed by Nix"
    if grep -F "raw.githubusercontent.com/tw93/mole/" "$out/bin/mole" | grep -F "install.sh"; then
      echo "upstream Mole installer URL remains" >&2
      exit 1
    fi

    runHook postInstallCheck
  '';

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    license = lib.licenses.mit;
    mainProgram = "mole";
    platforms = lib.platforms.darwin;
  };
}
