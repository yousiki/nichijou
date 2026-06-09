{
  lib,
  perSystem ? null,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  availableNamedPackages = packageSet: names:
    lib.filter (package: package != null && lib.meta.availableOn pkgs.stdenv.hostPlatform package) (
      map (name: packageSet.${name} or null) names
    );

  nixDesktopPackages =
    availableNamedPackages pkgs [
      "brave"
      "obsidian"
      "slack"
      "spotify"
      "telegram-desktop"
      "zoom-us"
    ]
    ++ lib.optionals isDarwin (
      availableNamedPackages pkgs [
        "alt-tab-macos"
        "iina"
        "keka"
        "maccy"
        "monitorcontrol"
        "orbstack"
        "raycast"
        "rectangle"
        "wechat"
      ]
    );

  darwinBrewCaskPackages = lib.optionals isDarwin (
    availableNamedPackages (pkgs.brewCasks or {}) [
      "chatgpt-atlas"
      "feishu"
      "keepingyouawake"
      "linearmouse"
      "linear"
      "tencent-meeting"
      "thaw"
      "zotero"
    ]
  );
in {
  imports = [
    ./programs/clawd.nix
    ./programs/ghostty.nix
    ./programs/kitty.nix
    ./programs/zed.nix
  ];

  home.packages = nixDesktopPackages ++ darwinBrewCaskPackages;

  programs.clawd.enable = isDarwin && perSystem != null;
}
