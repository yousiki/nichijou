_: {
  # Ensure this is unique among all clans you want to use.
  meta.name = "nichijou";

  inventory.machines = {
    mio = {
      machineClass = "darwin";
    };
  };

  # Docs: See https://docs.clan.lol/reference/clanServices
  inventory.instances = {
  };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
  };
}
