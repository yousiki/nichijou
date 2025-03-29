{
  lib,
  namespace,
  config,
  ...
}:
let
  cfg = config.${namespace}.programs.tmux;
in
{
  options.${namespace}.programs.tmux = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable tmux.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      # Default terminal
      terminal = "screen-256color";
      # Start windows and panes at 1, not 0
      baseIndex = 1;
      # Enable mouse support
      mouse = true;
      # Set prefix to Ctrl-a (like screen)
      prefix = "C-b";
      # Enable vi mode-keys
      keyMode = "vi";
      # Keep current path when creating new windows/panes
      extraConfig = ''
        # Keep current path when creating new windows/panes
        bind c new-window -c "#{pane_current_path}"
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
      '';
    };
  };
}
