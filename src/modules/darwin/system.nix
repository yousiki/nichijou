_: {
  flake.modules =
    let
      darwinModule = _: {
        system = {
          stateVersion = 6;
          primaryUser = "yousiki";
        };
      };
    in
    {
      darwin.darwim-system = darwinModule;
    };
}
