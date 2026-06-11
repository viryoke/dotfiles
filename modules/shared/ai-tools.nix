{ pkgs, lib, isLinux, ... }: {
  home.packages = with pkgs; [
    jupyter
    opencode
  ] ++ lib.optionals isLinux [
    ollama
  ];
}
