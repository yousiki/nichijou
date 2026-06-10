{
  lib,
  pkgs,
  ...
}: let
  languagePackages = with pkgs; [
    alejandra
    basedpyright
    docker-compose-language-service
    docker-language-server
    markdown-oxide
    markdownlint-cli2
    marksman
    nil
    nixd
    nixfmt
    prettier
    prettierd
    ruff
    rust-analyzer
    rustfmt
    taplo
    ty
    uv
    yaml-language-server
    yamlfmt
  ];
in {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    extraPackages = languagePackages;

    ignores = [
      ".DS_Store"
      ".direnv/"
      ".git/"
      ".mypy_cache/"
      ".ruff_cache/"
      ".venv/"
      "__pycache__/"
      "node_modules/"
      "result"
      "result-*"
      "target/"
    ];

    settings = {
      editor = {
        true-color = true;
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        bufferline = "multiple";
        completion-trigger-len = 1;
        popup-border = "all";
        rulers = [80 100 120];
        text-width = 100;
        end-of-line-diagnostics = "hint";

        cursor-shape = {
          insert = "bar";
          select = "underline";
        };

        file-picker.hidden = false;

        indent-guides = {
          render = true;
          skip-levels = 1;
        };

        inline-diagnostics = {
          cursor-line = "warning";
          other-lines = "disable";
        };

        lsp = {
          display-inlay-hints = true;
          display-progress-messages = true;
          goto-reference-include-declaration = false;
        };

        soft-wrap = {
          enable = true;
          wrap-at-text-width = true;
        };

        statusline = {
          center = ["version-control"];
          right = [
            "diagnostics"
            "selections"
            "register"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };
      };

      keys = {
        normal = {
          "C-s" = ":w";
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
          space = {
            space = "file_picker";
            b = "buffer_picker";
            f = "file_picker";
            F = "global_search";
            g = [":new" ":insert-output lazygit" ":buffer-close!" ":redraw"];
            q = ":q";
            w = ":w";
            x = ":buffer-close";
            c = ":config-open";
            C = ":config-reload";
          };
        };

        insert = {
          "C-s" = ["normal_mode" ":w"];
        };
      };
    };

    languages = {
      language-server = {
        rust-analyzer.config = {
          check.command = "clippy";
          cargo.features = "all";
          procMacro.enable = true;
        };

        ruff.config.settings = {
          lineLength = 100;
          lint = {
            preview = true;
            select = [
              "E"
              "F"
              "I"
              "UP"
              "B"
              "SIM"
              "RUF"
            ];
          };
          format.preview = true;
        };

        basedpyright.config = {
          basedpyright = {
            disableOrganizeImports = true;
            analysis = {
              autoImportCompletions = true;
              autoSearchPaths = true;
              diagnosticMode = "workspace";
              typeCheckingMode = "recommended";
              useLibraryCodeForTypes = true;
              inlayHints = {
                callArgumentNames = true;
                functionReturnTypes = true;
                genericTypes = true;
                variableTypes = true;
              };
            };
          };
        };

        nixd.config.nixd = {
          formatting.command = [
            (lib.getExe pkgs.alejandra)
            "-q"
          ];
        };

        nil.config.nil.formatting.command = [
          (lib.getExe pkgs.alejandra)
          "-q"
        ];

        yaml-language-server.config.yaml = {
          completion = true;
          hover = true;
          validate = true;
          format.enable = false;
          schemaStore.enable = true;
        };

        docker-language-server = {
          command = lib.getExe pkgs.docker-language-server;
          args = ["start" "--stdio"];
        };
      };

      language = [
        {
          name = "rust";
          formatter.command = lib.getExe pkgs.rustfmt;
        }
        {
          name = "python";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.ruff;
            args = ["format" "-"];
          };
          roots = [
            "pyproject.toml"
            "uv.lock"
            "ruff.toml"
            ".ruff.toml"
            "pyrightconfig.json"
            "basedpyrightconfig.json"
            "setup.py"
            "requirements.txt"
          ];
          language-servers = [
            {
              name = "ruff";
              only-features = [
                "diagnostics"
                "code-action"
              ];
            }
            {
              name = "basedpyright";
              except-features = ["format"];
            }
            {
              name = "ty";
              only-features = ["diagnostics"];
            }
          ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.alejandra;
            args = ["-q"];
          };
          roots = [
            "flake.nix"
            "default.nix"
            "shell.nix"
            ".git"
          ];
          language-servers = [
            "nixd"
            "nil"
          ];
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.prettier;
            args = ["--parser" "markdown"];
          };
          roots = [
            ".marksman.toml"
            ".git"
          ];
          text-width = 100;
          soft-wrap.enable = true;
        }
        {
          name = "toml";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.taplo;
            args = ["fmt" "-"];
          };
          language-servers = ["taplo"];
        }
        {
          name = "yaml";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.prettier;
            args = ["--parser" "yaml"];
          };
          language-servers = ["yaml-language-server"];
        }
        {
          name = "docker-compose";
          language-id = "dockercompose";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.prettier;
            args = ["--parser" "yaml"];
          };
          language-servers = [
            "docker-compose-langserver"
            "docker-language-server"
            "yaml-language-server"
          ];
        }
      ];
    };
  };
}
