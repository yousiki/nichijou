{
  pname,
  pkgs,
  ...
}:

let
  inherit (pkgs) lib makeWrapper python3 stdenvNoCC;
in
stdenvNoCC.mkDerivation {
  inherit pname;
  version = "0.1.0";

  src = ../../scripts/sync-cloudflare-warp-excludes.py;

  nativeBuildInputs = [
    makeWrapper
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -D -m755 "$src" \
      "$out/libexec/${pname}/sync-cloudflare-warp-excludes.py"

    makeWrapper "${python3}/bin/python3" "$out/bin/cloudflare-warp-exclude-sync" \
      --add-flags "$out/libexec/${pname}/sync-cloudflare-warp-excludes.py"

    runHook postInstall
  '';

  meta = {
    description = "Synchronize Cloudflare WARP Split Tunnel exclusions for Tailscale and GitHub";
    homepage = "https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/route-traffic/split-tunnels/";
    license = lib.licenses.mit;
    mainProgram = "cloudflare-warp-exclude-sync";
    platforms = lib.platforms.unix;
  };
}
