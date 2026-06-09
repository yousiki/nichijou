{inputs}: final: prev:
if prev.stdenv.hostPlatform.isDarwin
then inputs.brew-nix.overlays.default final prev
else {}
