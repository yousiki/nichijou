{pkgs, ...}: {
  # Language runtimes
  home.packages = with pkgs; [
    # JavaScript / TypeScript all-in-one toolchain
    bun
    # Node.js LTS
    nodejs
    # Python package manager, venv, and tool runner
    uv
    # Rust toolchain installer
    rustup
  ];

  # Make user-managed language tool binaries available in PATH
  home.sessionPath = ["$HOME/.bun/bin" "$HOME/.cargo/bin"];
}
