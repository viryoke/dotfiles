{
  description = "viryoke's cross-platform dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, agenix, devenv, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      overlays.default = import ./overlays;

      homeConfigurations = {
        "viryoke@cachyos-desktop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./hosts/cachyos-desktop
            agenix.homeManagerModules.default
          ];
          extraSpecialArgs = {
            inherit self;
            isLinux = true;
            isDarwin = false;
            hostname = "cachyos-desktop";
          };
        };

        "viryoke@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./hosts/macbook
            agenix.homeManagerModules.default
          ];
          extraSpecialArgs = {
            inherit self;
            isLinux = false;
            isDarwin = true;
            hostname = "macbook";
          };
        };

        "viryoke@arch-arm" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [
            ./hosts/arch-arm
            agenix.homeManagerModules.default
          ];
          extraSpecialArgs = {
            inherit self;
            isLinux = true;
            isDarwin = false;
            hostname = "arch-arm";
          };
        };
      };
    };
}
