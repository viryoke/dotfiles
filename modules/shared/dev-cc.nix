{ pkgs, ... }: {
  home.packages = with pkgs; [
    gcc
    clang-tools
    cmake
    gnumake
    pkg-config
  ];
}
