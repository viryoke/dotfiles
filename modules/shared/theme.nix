{ pkgs, ... }: {
  home.packages = with pkgs; [
    jetbrains-mono
  ];

  home.sessionVariables = {
    FZF_DEFAULT_OPTS = "--color=bg+:#3c3836,bg:#282828,spinner:#d8a657,hl:#7daea3,fg:#ebdbb2,header:#7daea3,info:#d8a657,pointer:#d8a657,marker:#d8a657,fg+:#ebdbb2,prompt:#d8a657,hl+:#7daea3";
  };
}
