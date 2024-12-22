{
  description = "docker-zfs-plugin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    let forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in {
      overlays.docker-zfs-plugin = import ./nixos/overlay.nix;
      nixosModules.docker-zfs-plugin = import ./nixos/module.nix;
      checks = forAllSystems (system:
        let
          checkArgs = {
            # reference to nixpkgs for the current system
            pkgs = nixpkgs.legacyPackages.${system};
            # this gives us a reference to our flake but also all flake inputs
            inherit self;
          };
        in {
          # import our test
          vm = import ./tests/vm.nix checkArgs;
        });
    };
}
