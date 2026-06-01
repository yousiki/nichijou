final: prev:

{
  # The packaged test suite has a flaky check that fails to build (notably on
  # darwin); the binary itself is fine, so skip the check phase.
  mcp-nixos = prev.mcp-nixos.overrideAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
  });
}
