{ pkgs, ... }: {
  home.packages = with pkgs; [
    gcc
    clang
    clang-tools
    cmake
    gnumake
    pkg-config
  ];
}
