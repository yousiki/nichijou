{
  fetchzip,
  keka,
  nix-update-script,
}:
keka.overrideAttrs (
  finalAttrs: _prevAttrs: {
    version = "1.5.2";

    src = fetchzip {
      url = "https://github.com/aonez/Keka/releases/download/v${finalAttrs.version}/Keka-${finalAttrs.version}.zip";
      hash = "sha256-NtmHdKu15EnAk7izZVEjpAZ6KgwfT7W2biwJT3jo9o0=";
    };

    passthru.updateScript = nix-update-script { };
  }
)
