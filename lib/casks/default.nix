{
  inputs,
  lib,
  ...
}:
let
  casksJSON = inputs.brew-api + "/cask.json";
  casksList = lib.importJSON casksJSON;
  casks = lib.attrsets.listToAttrs (
    lib.lists.map (cask: {
      name = cask.token;
      value = cask;
    }) casksList
  );
in
{
  inherit casks;
}
