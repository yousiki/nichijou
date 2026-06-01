{ inputs }:

final: prev:
if prev.stdenv.hostPlatform.isDarwin then
  let
    brewNixOverlay = inputs.brew-nix.overlays.default final prev;
  in
  brewNixOverlay
  // {
    brewCasks = brewNixOverlay.brewCasks // {
      microsoft-outlook = brewNixOverlay.brewCasks.microsoft-outlook.overrideAttrs (oldAttrs: {
        nativeBuildInputs = final.lib.flatten (oldAttrs.nativeBuildInputs or [ ]);
      });
    };
  }
else
  { }
