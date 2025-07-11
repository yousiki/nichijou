{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
{
  options.${namespace}.programs.vscode = {
    enable = lib.mkEnableOption "VSCode";
  };

  config =
    let
      cfg = config.${namespace}.programs.vscode;
    in
    lib.mkIf cfg.enable {
      programs.vscode = {
        enable = true;
        mutableExtensionsDir = true;
        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
          extensions = with pkgs.vscode-extensions; [
            aaron-bond.better-comments
            arrterian.nix-env-selector
            astro-build.astro-vscode
            bierner.github-markdown-preview
            bierner.markdown-checkbox
            bierner.markdown-emoji
            bierner.markdown-footnotes
            bierner.markdown-mermaid
            bierner.markdown-preview-github-styles
            brettm12345.nixfmt-vscode
            catppuccin.catppuccin-vsc
            catppuccin.catppuccin-vsc-icons
            charliermarsh.ruff
            davidanson.vscode-markdownlint
            esbenp.prettier-vscode
            github.copilot
            github.copilot-chat
            github.vscode-github-actions
            github.vscode-pull-request-github
            james-yu.latex-workshop
            jeff-hykin.better-nix-syntax
            jnoortheen.nix-ide
            ms-azuretools.vscode-docker
            ms-python.debugpy
            ms-python.python
            ms-python.vscode-pylance
            ms-toolsai.jupyter
            ms-toolsai.jupyter-keymap
            ms-toolsai.jupyter-renderers
            ms-toolsai.vscode-jupyter-cell-tags
            ms-toolsai.vscode-jupyter-slideshow
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode.cmake-tools
            ms-vscode.cpptools
            ms-vscode.makefile-tools
            njpwerner.autodocstring
            oderwat.indent-rainbow
            redhat.vscode-xml
            redhat.vscode-yaml
            rooveterinaryinc.roo-cline
            rust-lang.rust-analyzer
            tamasfe.even-better-toml
            tecosaur.latex-utilities
            visualstudioexptteam.intellicode-api-usage-examples
            visualstudioexptteam.vscodeintellicode
            vscodevim.vim
            vue.volar
            yzhang.markdown-all-in-one
          ];
          userSettings = {
            "accessibility.dimUnfocused.enabled" = true;
            "accessibility.dimUnfocused.opacity" = 0.8;
            "chat.tools.autoApprove" = true;
            "diffEditor.codeLens" = true;
            "diffEditor.experimental.showMoves" = true;
            "diffEditor.experimental.useTrueInlineView" = true;
            "editor.fontFamily" = "'CaskaydiaCove Nerd Font', 'Cascadia Code NF', 'Cascadia Code'";
            "editor.fontLigatures" = true;
            "editor.fontSize" = 13;
            "editor.minimap.autohide" = true;
            "editor.renderWhitespace" = "trailing";
            "editor.wordWrap" = "on";
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "explorer.confirmPasteNative" = false;
            "extensions.experimental.affinity" = {
              "vscodevim.vim" = 1;
            };
            "files.exclude" = {
              "**/__pycache__" = true;
              "**/.pytest_cache" = true;
              "**/.ropeproject" = true;
              "**/.ruff_cache" = true;
              "**/.venv" = true;
            };
            "git.autofetch" = true;
            "git.confirmSync" = false;
            "git.enableSmartCommit" = true;
            "github.copilot.advanced" = {
              "useLanguageServer" = true;
            };
            "github.copilot.chat.agent.thinkingTool" = true;
            "github.copilot.chat.codesearch.enabled" = true;
            "github.copilot.chat.completionContext.typescript.mode" = "on";
            "github.copilot.chat.editor.temporalContext.enabled" = true;
            "github.copilot.chat.edits.temporalContext.enabled" = true;
            "github.copilot.chat.generateTests.codeLens" = true;
            "github.copilot.chat.languageContext.fix.typescript.enabled" = true;
            "github.copilot.chat.languageContext.inline.typescript.enabled" = true;
            "github.copilot.chat.languageContext.typescript.enabled" = true;
            "github.copilot.chat.newWorkspaceCreation.enabled" = true;
            "github.copilot.nextEditSuggestions.enabled" = true;
            "githubPullRequests.experimental.chat" = true;
            "githubPullRequests.experimental.notificationsView" = true;
            "githubPullRequests.experimental.useQuickChat" = true;
            "latex-workshop.latex.recipes" = [
              {
                name = "latexmk";
                tools = [
                  "latexmk"
                ];
              }
              {
                name = "pdflatex -> bibtex -> pdflatex * 2";
                tools = [
                  "pdflatex"
                  "bibtex"
                  "pdflatex"
                  "pdflatex"
                ];
              }
              {
                name = "tectonic";
                tools = [
                  "tectonic"
                ];
              }
            ];
            "latex-workshop.latex.tools" = [
              {
                "name" = "tectonic";
                "command" = "tectonic";
                "args" = [
                  "-X"
                  "build"
                  "--keep-intermediates"
                  "--keep-logs"
                ];
              }
              {
                "name" = "latexmk";
                "command" = "latexmk";
                "args" = [
                  "-synctex=1"
                  "-interaction=nonstopmode"
                  "-file-line-error"
                  "-pdf"
                  "-outdir=%OUTDIR%"
                  "%DOC%"
                ];
                "env" = { };
              }
              {
                "name" = "pdflatex";
                "command" = "pdflatex";
                "args" = [
                  "-synctex=1"
                  "-interaction=nonstopmode"
                  "-file-line-error"
                  "%DOC%"
                ];
                "env" = { };
              }
              {
                "name" = "bibtex";
                "command" = "bibtex";
                "args" = [
                  "%DOCFILE%"
                ];
                "env" = { };
              }
            ];
            "nix.enableLanguageServer" = true;
            "nix.formatterPath" = "nixfmt";
            "nix.serverPath" = "nil";
            "nix.serverSettings" = {
              "nil" = {
                "flake" = {
                  "autoArchive" = true;
                  "autoEvalInputs" = true;
                };
                "formatting" = {
                  "command" = [ "nixfmt" ];
                };
              };
              "nixd" = {
                "formatting" = {
                  "command" = [ "nixfmt" ];
                };
              };
            };
            "nixEnvSelector.useFlakes" = true;
            "python.analysis.addHoverSummaries" = true;
            "python.analysis.aiCodeActions" = {
              "generateDocstring" = true;
              "generateSymbol" = true;
              "implementAbstractClasses" = true;
            };
            "python.analysis.autoFormatStrings" = true;
            "python.analysis.autoImportCompletions" = true;
            "python.analysis.completeFunctionParens" = true;
            "python.analysis.fixAll" = [ "source.unusedImports" ];
            "python.analysis.generateWithTypeAnnotation" = true;
            "python.analysis.inlayHints.functionReturnTypes" = true;
            "python.analysis.inlayHints.pytestParameters" = true;
            "python.analysis.inlayHints.variableTypes" = true;
            "python.analysis.supportDocstringTemplate" = true;
            "python.analysis.typeCheckingMode" = "strict";
            "python.analysis.typeEvaluation.enableExperimentalFeatures" = true;
            "python.analysis.typeEvaluation.enableReachabilityAnalysis" = true;
            "python.terminal.activateEnvironment" = false;
            "redhat.telemetry.enabled" = false;
            "remote.SSH.remotePlatform" = {
              "hakase" = "linux";
              "nano" = "macOS";
              "sakamoto" = "macOS";
              "yukko" = "linux";
            };
            "security.workspace.trust.untrustedFiles" = "open";
            "terminal.integrated.enableImages" = true;
            "terminal.integrated.enableMultiLinePasteWarning" = "auto";
            "terminal.integrated.env.linux" = {
              "EDITOR" = "code --wait";
              "VISUAL" = "code --wait";
            };
            "terminal.integrated.fontLigatures.enabled" = true;
            "terminal.integrated.inheritEnv" = true;
            "update.mode" = "manual";
            "update.showReleaseNotes" = false;
            "vim.easymotion" = true;
            "vim.highlightedyank.enable" = true;
            "vim.insertModeKeyBindings" = [
              {
                "after" = [ "<Esc>" ];
                "before" = [
                  "j"
                  "k"
                ];
              }
            ];
            "vim.leader" = ",";
            "vim.useSystemClipboard" = true;
            "vim.visualstar" = true;
            "window.confirmSaveUntitledWorkspace" = false;
            "window.newWindowProfile" = "Default";
            "workbench.colorTheme" = "Catppuccin Mocha";
            "workbench.iconTheme" = "catppuccin-mocha";
            "workbench.preferredDarkColorTheme" = "Catppuccin Mocha";
            "workbench.startupEditor" = "none";
            "[jsonc]" = {
              "editor.codeActionsOnSave" = {
                "source.sort.json" = "explicit";
              };
              "editor.defaultFormatter" = "esbenp.prettier-vscode";
              "editor.formatOnSave" = true;
            };
            "[markdown]" = {
              "editor.defaultFormatter" = "esbenp.prettier-vscode";
            };
            "[nix]" = {
              "editor.defaultFormatter" = "jnoortheen.nix-ide";
              "editor.formatOnSave" = true;
              "editor.tabSize" = 2;
            };
            "[python]" = {
              "editor.defaultFormatter" = "charliermarsh.ruff";
              "editor.tabSize" = 2;
            };
            "[toml]" = {
              "editor.defaultFormatter" = "tamasfe.even-better-toml";
              "editor.formatOnSave" = true;
            };
            "[yaml]" = {
              "editor.defaultFormatter" = "esbenp.prettier-vscode";
              "editor.formatOnSave" = true;
            };
          };
        };
      };
    };
}
