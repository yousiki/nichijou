{
  pkgs,
  ...
}:
pkgs.zed-editor.overrideAttrs (_oldAttrs: rec {
  version = "0.189.5";
  src = pkgs.fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    tag = "v${version}";
    hash = "sha256-d1d3WgUVamrYWVosljQiEPZGNNDldtM1YwZhxseX4+w=";
  };
})
