{ pkgs, lib, ... }: {
  imports = [
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
    ../../modules/shared/exam-prep.nix
    ../../modules/shared/ai-learning.nix
    ../../modules/shared/hermes-agent.nix
    ../../modules/darwin/packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "viryoke";
    homeDirectory = "/Users/viryoke";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
