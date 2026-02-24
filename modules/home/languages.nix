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

  # Make rustup-managed binaries (rustc, cargo, clippy…) available in PATH
  home.sessionPath = ["$HOME/.cargo/bin"];
}
