{ lib, buildGoModule }:
buildGoModule rec {
  pname = "docker-zfs-plugin";
  version = "2.0.0";

  src = lib.cleanSource ./.;

  vendorSha256 = "sha256-wK4nN+x9YdUgCAMPlWUj5E34txergeLlaapT+282ES8=";
  subPackages = [ "." ];

  meta = with lib; {
    supportedPlatforms = platforms.linux;
  };
}
