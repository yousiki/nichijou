{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.programs.uv = {
    enable = lib.mkEnableOption "uv";
  };

  config =
    let
      cfg = config.${namespace}.programs.uv;
    in
    lib.mkIf cfg.enable {
      programs.uv = {
        enable = true;
        settings = {
          pip.link-mode = "symlink";
          index = [
            {
              default = true;
              url = "https://pypi.tuna.tsinghua.edu.cn/simple";
            }
          ];
        };
      };
    };
}
