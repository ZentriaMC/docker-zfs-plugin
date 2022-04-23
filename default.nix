{ lib, buildGoModule }:
buildGoModule rec {
  pname = "docker-zfs-plugin";
  version = "2.0.0";

  src = lib.cleanSource ./.;

  vendorSha256 = "sha256-/oAk/gFNlS4zRBMrp1KWeyeunDKgV+p6C+jP+OwcfGg=";
  subPackages = [ "." ];

  meta = with lib; {
    supportedPlatforms = platforms.linux;
  };
}
