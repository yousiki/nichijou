_: {
  users.users.yousiki = {
    isNormalUser = true;
    group = "yousiki";
    extraGroups = [
      "users"
      "wheel"
      "docker"
      "sudo"
    ];
  };

  users.groups.yousiki = { };
}
