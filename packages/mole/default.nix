{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
}:
buildGoModule rec {
  pname = "mole";
  version = "1.28.1";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${version}";
    hash = "sha256-7a5oQfJJIESjit+gl7FrbkT5wptxBhhWuTLCpULlQ6w=";
  };

  vendorHash = "sha256-OKM5rmbLxqh5Khw5BlR/gPJlwmQhklGdZst92aUTZhM=";

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version-regex"
      "V(.*)"
    ];
  };

  # Tests require macOS Trash access and fail in the Nix sandbox
  doCheck = false;

  # Build only the two Go sub-commands; the rest is shell scripts
  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    mkdir -p $out/share/mole/bin

    mv $out/bin/analyze $out/share/mole/bin/analyze-go
    mv $out/bin/status  $out/share/mole/bin/status-go

    cp $src/bin/*.sh $out/share/mole/bin/
    chmod +x $out/share/mole/bin/*.sh

    cp -r $src/lib $out/share/mole/lib

    install -m 0755 $src/mole $out/share/mole/mole

    makeWrapper $out/share/mole/mole $out/bin/mole
  '';

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    changelog = "https://github.com/tw93/Mole/releases/tag/V${version}";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = lib.platforms.darwin;
    mainProgram = "mole";
  };
}
