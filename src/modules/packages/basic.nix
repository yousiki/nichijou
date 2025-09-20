_: {
  flake.modules =
    let
      packages =
        pkgs: with pkgs; [
          curl
          git
          htop
          rsync
          tmux
          vim
          wget
        ];

      commonModule =
        { pkgs, ... }:
        {
          environment.systemPackages = packages pkgs;
        };

      homeModule =
        { pkgs, ... }:
        {
          home.packages = packages pkgs;
        };
    in
    {
      nixos.packages-basic = commonModule;
      darwin.packages-basic = commonModule;
      home.packages-basic = homeModule;
    };
}
