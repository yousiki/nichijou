{...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "yousiki";
        email = "you.siki@outlook.com";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
