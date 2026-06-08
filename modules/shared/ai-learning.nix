{ ... }: {
  home.file.".config/pixi/config.toml".text = ''
    [mirrors]
    "https://pypi.org/simple" = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
  '';
}
