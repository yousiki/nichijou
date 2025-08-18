# Basic system configurations for all systems.
{
  inputs,
  pkgs,
  ...
}:
{
  system = {
    # The Git revision of the top-level flake from which this configuration was built.
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

    # Used for backwards compatibility.
    stateVersion = if pkgs.stdenv.hostPlatform.isLinux then "25.05" else 6;
  };
}
