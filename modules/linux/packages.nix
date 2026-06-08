{ pkgs, ... }: {
  home.packages = with pkgs; [
    yazi
    zellij
    cliphist
  ];
}
