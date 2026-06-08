{ pkgs, lib, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--color=bg+:#3c3836,bg:#282828,spinner:#d8a657,hl:#7daea3"
      "--color=fg:#ebdbb2,header:#7daea3,info:#d8a657,pointer:#d8a657"
      "--color=marker:#d8a657,fg+:#ebdbb2,prompt:#d8a657,hl+:#7daea3"
    ];
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
      pager = "less -FR";
    };
  };

  home.packages = with pkgs; [
    lazygit
    htop
    btop
    tree
    jq
    curl
    wget
    unzip
    delta
  ];
}
