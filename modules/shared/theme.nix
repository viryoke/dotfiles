{ pkgs, lib, isDarwin, ... }: {
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
  ];

  # macOS: register fonts with the system
  home.activation.registerFonts = lib.mkIf isDarwin (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/Library/Fonts
    $DRY_RUN_CMD for font in ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/*.ttf; do
      $DRY_RUN_CMD ln -sf "$font" "$HOME/Library/Fonts/" 2>/dev/null || true
    done
    $DRY_RUN_CMD for font in ${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto/*.otf; do
      $DRY_RUN_CMD ln -sf "$font" "$HOME/Library/Fonts/" 2>/dev/null || true
    done
  '');
}
