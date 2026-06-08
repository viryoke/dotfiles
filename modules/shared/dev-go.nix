{ pkgs, ... }: {
  programs.go = {
    enable = true;
  };

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };

  home.packages = with pkgs; [
    gopls
    golangci-lint
    delve
  ];
}
