{ pkgs, lib, ... }: {
  imports = [
    ../../modules/shared/nix.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/shell.nix
    ../../modules/shared/editors.nix
    ../../modules/shared/theme.nix
    ../../modules/shared/dev-java.nix
    ../../modules/shared/dev-go.nix
    ../../modules/shared/dev-python.nix
    ../../modules/shared/dev-rust.nix
    ../../modules/shared/dev-cc.nix
    ../../modules/shared/dev-js.nix
    ../../modules/shared/dev-lua.nix
    ../../modules/shared/ai-ml.nix
    ../../modules/shared/exam-prep.nix
    ../../modules/shared/ai-learning.nix
    ../../modules/shared/hermes-agent.nix
    ../../modules/shared/secrets.nix
    ../../modules/linux/packages.nix
    ../../modules/linux/clash-verge.nix
    ../../modules/linux/secrets.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "viryoke";
    homeDirectory = "/home/viryoke";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
