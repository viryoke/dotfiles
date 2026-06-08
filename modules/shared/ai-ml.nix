{ pkgs, lib, isLinux, ... }: {
  home.packages = with pkgs; [
    jupyter
  ] ++ lib.optionals isLinux [
    ollama
  ];
}
