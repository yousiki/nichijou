{
  inputs,
  pkgs,

  lib,
  stdenv,

  apple-sdk_15,
  darwin,
  darwinMinVersionHook,

  cargo-about,
  cargo-bundle,
  rustPlatform,

  copyDesktopItems,
  envsubst,
  fetchFromGitHub,
  makeFontsConf,
  makeWrapper,

  alsa-lib,
  cmake,
  curl,
  fontconfig,
  freetype,
  git,
  libgit2,
  libglvnd,
  libxkbcommon,
  livekit-libwebrtc,
  nodejs,
  openssl,
  perl,
  pkg-config,
  protobuf,
  sqlite,
  vulkan-loader,
  wayland,
  xorg,
  zlib,
  zstd,

  withGLES ? false,
  profile ? "release",
}:
assert withGLES -> stdenv.hostPlatform.isLinux;
let
  version = "0.191.6";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-GQzAXjOvtjbkBgBkX9Xp6mn3uP5wXStpsaC6rQMwTvs=";
  };

  crane = inputs.crane.mkLib pkgs;
  rustBin = inputs.rust-overlay.lib.mkRustBin { } pkgs;
  rustToolchain = rustBin.fromRustupToolchainFile "${src}/rust-toolchain.toml";

  craneLib = crane.overrideToolchain rustToolchain;
  gpu-lib = if withGLES then libglvnd else vulkan-loader;
  commonArgs =
    let
      stdenv' = stdenv;
    in
    rec {
      pname = "zed-editor";
      inherit version src;

      cargoLock = "${src}/Cargo.lock";

      nativeBuildInputs =
        [
          cmake
          copyDesktopItems
          curl
          perl
          pkg-config
          protobuf
          cargo-about
          rustPlatform.bindgenHook
        ]
        ++ lib.optionals stdenv'.hostPlatform.isLinux [ makeWrapper ]
        ++ lib.optionals stdenv'.hostPlatform.isDarwin [
          (cargo-bundle.overrideAttrs (
            new: _old: {
              version = "0.6.1-zed";
              src = fetchFromGitHub {
                owner = "zed-industries";
                repo = "cargo-bundle";
                rev = "2be2669972dff3ddd4daf89a2cb29d2d06cad7c7";
                hash = "sha256-cSvW0ND148AGdIGWg/ku0yIacVgW+9f1Nsi+kAQxVrI=";
              };
              cargoHash = "sha256-urn+A3yuw2uAO4HGmvQnKvWtHqvG9KHxNCCWTiytE4k=";

              # NOTE: can drop once upstream uses `finalAttrs` here:
              # https://github.com/NixOS/nixpkgs/blob/10214747f5e6e7cb5b9bdf9e018a3c7b3032f5af/pkgs/build-support/rust/build-rust-package/default.nix#L104
              #
              # See (for context): https://github.com/NixOS/nixpkgs/pull/382550
              cargoDeps = rustPlatform.fetchCargoVendor {
                inherit (new) src;
                hash = new.cargoHash;
                patches = new.cargoPatches or [ ];
                name = new.cargoDepsName or new.finalPackage.name;
              };
            }
          ))
        ];

      buildInputs =
        [
          curl
          fontconfig
          freetype
          # TODO: need staticlib of this for linking the musl remote server.
          # should make it a separate derivation/flake output
          # see https://crane.dev/examples/cross-musl.html
          libgit2
          openssl
          sqlite
          zlib
          zstd
        ]
        ++ lib.optionals stdenv'.hostPlatform.isLinux [
          alsa-lib
          libxkbcommon
          wayland
          gpu-lib
          xorg.libX11
          xorg.libxcb
        ]
        ++ lib.optionals stdenv'.hostPlatform.isDarwin [
          apple-sdk_15
          darwin.apple_sdk.frameworks.System
          (darwinMinVersionHook "10.15")
        ];

      cargoExtraArgs = "-p zed -p cli --locked --features=gpui/runtime_shaders";

      stdenv =
        pkgs:
        let
          base = pkgs.llvmPackages.stdenv;
          addBinTools = old: {
            cc = old.cc.override {
              inherit (pkgs.llvmPackages) bintools;
            };
          };
          custom = lib.pipe base [
            (stdenv: stdenv.override addBinTools)
            pkgs.stdenvAdapters.useMoldLinker
          ];
        in
        if stdenv'.hostPlatform.isLinux then custom else base;

      env = {
        ZSTD_SYS_USE_PKG_CONFIG = true;
        FONTCONFIG_FILE = makeFontsConf {
          fontDirectories = [
            "${src}/assets/fonts/plex-mono"
            "${src}/assets/fonts/plex-sans"
          ];
        };
        ZED_UPDATE_EXPLANATION = "Zed has been installed using Nix. Auto-updates have thus been disabled.";
        RELEASE_VERSION = version;
        LK_CUSTOM_WEBRTC = livekit-libwebrtc;

        CARGO_PROFILE = profile;
        # need to handle some profiles specially https://github.com/rust-lang/cargo/issues/11053
        TARGET_DIR = "target/" + (if profile == "dev" then "debug" else profile);

        # for some reason these deps being in buildInputs isn't enough, the only thing
        # about them that's special is that they're manually dlopened at runtime
        NIX_LDFLAGS = lib.optionalString stdenv'.hostPlatform.isLinux "-rpath ${
          lib.makeLibraryPath [
            gpu-lib
            wayland
          ]
        }";

        NIX_OUTPATH_USED_AS_RANDOM_SEED = "norebuilds";
      };

      # prevent nix from removing the "unused" wayland/gpu-lib rpaths
      dontPatchELF = stdenv'.hostPlatform.isLinux;

      # TODO: try craneLib.cargoNextest separate output
      # for now we're not worried about running our test suite (or tests for deps) in the nix sandbox
      doCheck = false;

      cargoVendorDir = craneLib.vendorCargoDeps {
        inherit src cargoLock;
        overrideVendorGitCheckout =
          let
            hasWebRtcSys = builtins.any (crate: crate.name == "webrtc-sys");
            # we can't set $RUSTFLAGS because that clobbers the cargo config
            # see https://github.com/rust-lang/cargo/issues/5376#issuecomment-2163350032
            glesConfig = builtins.toFile "config.toml" ''
              [target.'cfg(all())']
              rustflags = ["--cfg", "gles"]
            '';

            # `webrtc-sys` expects a staticlib; nixpkgs' `livekit-webrtc` has been patched to
            # produce a `dylib`... patching `webrtc-sys`'s build script is the easier option
            # TODO: send livekit sdk a PR to make this configurable
            postPatch =
              ''
                substituteInPlace webrtc-sys/build.rs --replace-fail \
                  "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
              ''
              + lib.optionalString withGLES ''
                cat ${glesConfig} >> .cargo/config/config.toml
              '';
          in
          crates: drv:
          if hasWebRtcSys crates then
            drv.overrideAttrs (o: {
              postPatch = (o.postPatch or "") + postPatch;
            })
          else
            drv;
      };
    };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  lib.recursiveUpdate commonArgs {
    inherit cargoArtifacts;

    dontUseCmakeConfigure = true;

    # without the env var generate-licenses fails due to crane's fetchCargoVendor, see:
    # https://github.com/zed-industries/zed/issues/19971#issuecomment-2688455390
    # TODO: put this in a separate derivation that depends on src to avoid running it on every build
    preBuild = ''
      ALLOW_MISSING_LICENSES=yes bash script/generate-licenses
      echo stable > crates/zed/RELEASE_CHANNEL
    '';

    installPhase =
      if stdenv.hostPlatform.isDarwin then
        ''
          runHook preInstall

          pushd crates/zed
          sed -i "s/package.metadata.bundle-stable/package.metadata.bundle/" Cargo.toml
          export CARGO_BUNDLE_SKIP_BUILD=true
          app_path="$(cargo bundle --profile $CARGO_PROFILE | xargs)"
          popd

          mkdir -p $out/Applications $out/bin
          # Zed expects git next to its own binary
          ln -s ${git}/bin/git "$app_path/Contents/MacOS/git"
          mv $TARGET_DIR/cli "$app_path/Contents/MacOS/cli"
          mv "$app_path" $out/Applications/

          # Physical location of the CLI must be inside the app bundle as this is used
          # to determine which app to start
          ln -s "$out/Applications/Zed.app/Contents/MacOS/cli" $out/bin/zeditor

          runHook postInstall
        ''
      else
        ''
          runHook preInstall

          mkdir -p $out/bin $out/libexec

          install -Dm755 $TARGET_DIR/zed $out/libexec/zed-editor
          install -Dm755 $TARGET_DIR/cli $out/bin/zeditor

          install -Dm644 "crates/zed/resources/app-icon@2x.png" \
            "$out/share/icons/hicolor/1024x1024@2x/apps/zed.png"
          install -Dm644 crates/zed/resources/app-icon.png \
            $out/share/icons/hicolor/512x512/apps/zed.png

          (
            export DO_STARTUP_NOTIFY="true"
            export APP_CLI="zeditor"
            export APP_ICON="zed"
            export APP_NAME="Zed"
            export APP_ARGS="%U"
            mkdir -p "$out/share/applications"
            ${lib.getExe envsubst} < "crates/zed/resources/zed.desktop.in" > "$out/share/applications/dev.zed.Zed.desktop"
          )

          runHook postInstall
        '';

    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/libexec/zed-editor --suffix PATH : ${lib.makeBinPath [ nodejs ]}
    '';

    meta = {
      description = "High-performance, multiplayer code editor from the creators of Atom and Tree-sitter";
      homepage = "https://zed.dev/";
      changelog = "https://zed.dev/releases/stable";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
      mainProgram = "zeditor";
    };
  }
)
