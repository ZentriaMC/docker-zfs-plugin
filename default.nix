{ lib, stdenv, buildGoModule }:
buildGoModule rec {
  pname = "docker-zfs-plugin";
  version = "2.0.0";

  src = lib.cleanSource ./.;

  vendorSha256 = "1kajw2qvxlp0p1x4ixh1f318rg93qn5fs21mgz6p05rqcb0mr5k9";
  subPackages = [ "." ];
}
