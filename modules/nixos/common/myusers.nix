# List of users for darwin or nixos system and their top-level configuration.
{
  flake,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (flake.inputs) self;
  mapListToAttrs = m: f:
    lib.listToAttrs (
      map (name: {
        inherit name;
        value = f name;
      })
      m
    );
in {
  options = {
    myusers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of usernames";
      defaultText = "All users under ./configuration/users are included by default";
      default = let
        dirContents = builtins.readDir (self + /configurations/home);
        # Accept both "user.nix" files and "user/" directories
        baseNames =
          lib.mapAttrsToList (
            name: type:
              if type == "regular" && lib.hasSuffix ".nix" name
              then lib.removeSuffix ".nix" name
              else if type == "directory"
              then name
              else null
          )
          dirContents;
      in
        builtins.filter (x: x != null) baseNames;
    };
  };

  config = {
    # For home-manager to work.
    # https://github.com/nix-community/home-manager/issues/4026#issuecomment-1565487545
    users.users = mapListToAttrs config.myusers (
      name:
        lib.optionalAttrs pkgs.stdenv.isDarwin {
          home = "/Users/${name}";
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          isNormalUser = true;
        }
    );

    # Enable home-manager for our user
    home-manager.users = mapListToAttrs config.myusers (name: let
      filePath = self + /configurations/home/${name}.nix;
      dirPath = self + /configurations/home/${name};
      path =
        if builtins.pathExists filePath
        then filePath
        else dirPath;
    in {
      imports = [path];
    });

    # All users can add Nix caches.
    nix.settings.trusted-users =
      [
        "root"
      ]
      ++ config.myusers;
  };
}
