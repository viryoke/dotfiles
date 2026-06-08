{ pkgs, ... }: {
  home.packages = with pkgs; [
    python3
    uv
    pixi
    ruff
    python3Packages.pip
  ];
}
