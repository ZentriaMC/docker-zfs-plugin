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

      allSystems = supportedSystems ++ [
        "aarch64-darwin"
        "x86_64-darwin"
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
        };
      })) // (flake-utils.lib.eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ go golangci-lint gopls ];
        };
      }
    )) // {
      overlays.docker-zfs-plugin = import ./nixos/overlay.nix;
      overlay = self.overlays.docker-zfs-plugin;
      nixosModules.docker-zfs-plugin = import ./nixos/module.nix;
      nixosModule = self.nixosModules.docker-zfs-plugin;
    };
}
