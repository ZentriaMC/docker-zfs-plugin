{
  imports = [
    ./module.nix
  ];

  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];
}
