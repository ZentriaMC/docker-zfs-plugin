{ lib, buildGoModule }:
buildGoModule {
  pname = "docker-zfs-plugin";
  version = "3.0.0";

  src = lib.cleanSource ./.;

  vendorHash = "sha256-9bIVchjrNqXDYdLLS634QVqXmpR4NQ4ANeiwkkLEi+E=";
  subPackages = [ "." ];

  meta = with lib; { supportedPlatforms = platforms.linux; };
}
