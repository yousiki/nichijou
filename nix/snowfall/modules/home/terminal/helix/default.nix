{
  config,
  lib,
  namespace,
  ...
}:
lib.mkIf (builtins.elem "terminal" config.${namespace}.tags) {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        cursorline = true;
        bufferline = "multiple";
        inline-diagnostics = {
          cursor-line = "warning";
          other-lines = "warning";
        };
        lsp = {
          display-progress-messages = true;
          display-inlay-hints = true;
        };
        indent-guides.render = true;
        soft-wrap.enable = true;
      };
    };
  };
}
