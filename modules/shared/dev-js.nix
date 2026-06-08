{ pkgs, ... }: {
  home.packages = with pkgs; [
    bun
    nodejs
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];
}
