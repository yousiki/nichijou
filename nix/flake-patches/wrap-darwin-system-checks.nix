{
  inputs,
  systems,
  nixpkgs,
}:

blueprintOutputs:

let
  lib = inputs.nixpkgs.lib;

  pkgsFor = system: import inputs.nixpkgs ({ inherit system; } // nixpkgs);

  wrapDarwinSystemChecks =
    system:
    let
      pkgs = pkgsFor system;
      darwinConfigurations = blueprintOutputs.darwinConfigurations or { };
      matchingDarwinConfigurations = lib.filterAttrs (
        _: configuration: configuration.pkgs.stdenv.hostPlatform.system == system
      ) darwinConfigurations;
    in
    lib.mapAttrs' (name: configuration: {
      name = "darwin-${name}";
      value = pkgs.runCommandLocal "darwin-${name}-check" { } ''
        mkdir -p $out
        ln -s ${configuration.system} $out/system
      '';
    }) matchingDarwinConfigurations;

  checkSystems = lib.unique (systems ++ lib.attrNames (blueprintOutputs.checks or { }));
in
blueprintOutputs
// {
  checks = lib.genAttrs checkSystems (
    system: (blueprintOutputs.checks.${system} or { }) // wrapDarwinSystemChecks system
  );
}
