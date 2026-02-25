{pkgs, ...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        line-number = "relative";
        indent-guides.render = true;
      };
      keys.normal = {
        space.space = "file_picker";
      };
    };
    languages = {
      language-server = {
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
      };
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
          };
          language-servers = ["nil"];
        }
      ];
    };
  };
}
