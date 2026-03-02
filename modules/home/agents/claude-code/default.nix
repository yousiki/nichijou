{
  pkgs,
  lib,
  flake,
  ...
}: let
  selfPackages = flake.inputs.self.packages.${pkgs.system};

  plugins = [
    selfPackages.claude-code-plugin-astral
    selfPackages.claude-code-plugin-claude-code-setup
    selfPackages.claude-code-plugin-claude-md-management
    selfPackages.claude-code-plugin-clangd-lsp
    selfPackages.claude-code-plugin-code-review
    selfPackages.claude-code-plugin-code-simplifier
    selfPackages.claude-code-plugin-commit-commands
    selfPackages.claude-code-plugin-context7
    selfPackages.claude-code-plugin-csharp-lsp
    selfPackages.claude-code-plugin-feature-dev
    selfPackages.claude-code-plugin-gopls-lsp
    selfPackages.claude-code-plugin-hookify
    selfPackages.claude-code-plugin-jdtls-lsp
    selfPackages.claude-code-plugin-kotlin-lsp
    selfPackages.claude-code-plugin-lua-lsp
    selfPackages.claude-code-plugin-php-lsp
    selfPackages.claude-code-plugin-pr-review-toolkit
    selfPackages.claude-code-plugin-pyright-lsp
    selfPackages.claude-code-plugin-ralph-loop
    selfPackages.claude-code-plugin-rust-analyzer-lsp
    selfPackages.claude-code-plugin-skill-creator
    selfPackages.claude-code-plugin-superpowers
    selfPackages.claude-code-plugin-swift-lsp
    selfPackages.claude-code-plugin-typescript-lsp
  ];

  basePackage = pkgs.claude-code;

  pluginArgs = lib.concatMapStringsSep " " (p: ''--add-flags "--plugin-dir ${p}"'') plugins;

  wrappedPackage = pkgs.symlinkJoin {
    name = "${basePackage.name}-with-plugins";
    paths = [basePackage];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude ${pluginArgs}
    '';
  };
in {
  programs.claude-code = {
    enable = true;
    package = wrappedPackage;
    enableMcpIntegration = true;
    settings = {
      theme = "dark";
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      sandbox = {
        enabled = true;
        network = {
          allowedDomains = [
            # GitHub
            "github.com"
            "*.github.com"
            "raw.githubusercontent.com"
          ];
        };
      };
      permissions = {
        allow = [
          # Built-in tools
          "Read"
          "Glob"
          "Grep"
          "WebFetch"
          "WebSearch"
          # Skills
          "Skill(commit-commands:commit)"
          "Skill(commit-commands:commit-push-pr)"
          # File viewing
          "Bash(cat *)"
          "Bash(head *)"
          "Bash(tail *)"
          "Bash(wc *)"
          "Bash(file *)"
          "Bash(stat *)"
          # Directory listing
          "Bash(ls)"
          "Bash(ls *)"
          "Bash(tree)"
          "Bash(tree *)"
          "Bash(pwd)"
          # Search
          "Bash(find *)"
          "Bash(fd *)"
          "Bash(grep *)"
          "Bash(rg *)"
          "Bash(which *)"
          "Bash(type *)"
          # Text processing
          "Bash(echo *)"
          "Bash(sort *)"
          "Bash(uniq *)"
          "Bash(cut *)"
          "Bash(tr *)"
          "Bash(awk *)"
          "Bash(jq *)"
          "Bash(printf *)"
          # Path utilities
          "Bash(realpath *)"
          "Bash(dirname *)"
          "Bash(basename *)"
          # System info
          "Bash(uname *)"
          "Bash(whoami)"
          "Bash(id)"
          "Bash(env)"
          "Bash(printenv)"
          "Bash(printenv *)"
          "Bash(hostname)"
          "Bash(date)"
          "Bash(date *)"
          # Disk & process info
          "Bash(df)"
          "Bash(df *)"
          "Bash(du *)"
          "Bash(ps)"
          "Bash(ps *)"
          "Bash(pgrep *)"
          # Checksums
          "Bash(shasum *)"
          "Bash(md5 *)"
          # Git (read-only)
          "Bash(git status)"
          "Bash(git status *)"
          "Bash(git log)"
          "Bash(git log *)"
          "Bash(git diff)"
          "Bash(git diff *)"
          "Bash(git show *)"
          "Bash(git branch)"
          "Bash(git branch *)"
          "Bash(git remote)"
          "Bash(git remote *)"
          "Bash(git stash list)"
          "Bash(git rev-parse *)"
          "Bash(git describe *)"
          "Bash(git tag)"
          "Bash(git tag *)"
          "Bash(git ls-files)"
          "Bash(git ls-files *)"
          "Bash(git blame *)"
          # Nix (read-only)
          "Bash(nix eval *)"
          "Bash(nix flake show)"
          "Bash(nix flake show *)"
          "Bash(nix flake metadata)"
          "Bash(nix flake metadata *)"
          "Bash(nix search *)"
          "Bash(nix path-info *)"
          "Bash(nix why-depends *)"
          "Bash(nix store *)"
          "Bash(nix hash *)"
          "Bash(nix derivation show *)"
          "Bash(nix log *)"
          # GitHub CLI (read-only)
          "Bash(gh api *)"
          "Bash(gh pr list)"
          "Bash(gh pr list *)"
          "Bash(gh pr view *)"
          "Bash(gh issue list)"
          "Bash(gh issue list *)"
          "Bash(gh issue view *)"
          "Bash(gh repo view *)"
          # Homebrew (read-only)
          "Bash(brew info *)"
          "Bash(brew list)"
          "Bash(brew list *)"
          "Bash(brew search *)"
        ];
      };
    };
  };
}
