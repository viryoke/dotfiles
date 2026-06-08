{ pkgs, ... }: {
  home.packages = with pkgs; [
    uv
    pixi
    ruff
  ];
}
