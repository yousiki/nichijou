{pkgs, ...}: {
  nix.package = pkgs.lix;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.substituters = [
    "https://claude-code.cachix.org"
    "https://codex-cli.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
    "nix-community.cachix.org-1:mB9xqOL1VVRz08zVYTy4DXc8nOaNvuFY7z42wSQuepA="
  ];
}
