# A module that automatically imports everything else in the parent folder.
{
  imports = with builtins;
    map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));

  home.stateVersion = "26.05";
}
