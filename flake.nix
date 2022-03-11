{
  description = "docker-zfs-plugin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    (flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages.docker-zfs-plugin = pkgs.callPackage ./. { };
        defaultPackage = packages.docker-zfs-plugin;

        checks.vm = pkgs.callPackage ./test/vm.nix {
          inherit system;
          dockerZfsPluginModule = self.nixosModule;
          dockerZfsPluginOverlay = self.overlay;
        };
      })) // {
      overlay = import ./nixos/overlay.nix;
      nixosModule = import ./nixos/module.nix;
    };
}
