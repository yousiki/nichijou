{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (_finalAttrs: {
  pname = "gemini-cli";
  version = "main";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "121bba3";
    hash = "sha256-2w28N6Fhm6k3wdTYtKH4uLPBIOdELd/aRFDs8UMWMmU=";
  };

  npmDepsHash = "sha256-yoUAOo8OwUWG0gyI5AdwfRFzSZvSCd3HYzzpJRvdbiM=";

  # Use the bundled version as the main executable
  npmBuildScript = "bundle";

  # Handle the broken symlinks by removing them and creating proper structure
  postInstall = ''
    # Remove broken symlinks
    find $out -type l -exec test ! -e {} \; -delete 2>/dev/null || true

    # The bundle script creates bundle/gemini.js which is the main executable
    # Make sure it's properly linked
    if [ -f "$out/lib/node_modules/@google/gemini-cli/bundle/gemini.js" ]; then
      mkdir -p $out/bin
      ln -sf $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js $out/bin/gemini
      chmod +x $out/lib/node_modules/@google/gemini-cli/bundle/gemini.js
    fi
  '';

  meta = {
    description = "An open-source AI agent that brings the power of Gemini directly into your terminal.";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
})
