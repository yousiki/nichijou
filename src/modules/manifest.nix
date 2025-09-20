_: {
  flake.modules =
    let
      commonModule =
        { lib, ... }:
        {
          options.manifest = {
            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Tags for the machine.";
            };
          };
        };
    in
    {
      nixos.manifest = commonModule;
      darwin.manifest = commonModule;
    };
}
