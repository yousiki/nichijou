_: {
  users.users.yousiki = {
    isNormalUser = true;
    group = "yousiki";
    extraGroups = [
      "docker"
      "podman"
      "sudo"
      "users"
      "wheel"
    ];
  };

  users.groups.yousiki = { };
}
