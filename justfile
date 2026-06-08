update:
    nix flake update --access-tokens "github.com=$(gh auth token)"
    GITHUB_TOKEN="$(gh auth token)" ./scripts/update-nix-packages.py
