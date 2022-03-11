{ nixosTest
, system ? "x86_64-linux"
, dockerZfsPluginModule
, dockerZfsPluginOverlay
}:

let
  zfsInitScript = ''
    # Set up ZFS pool and a dataset
    machine.succeed(
      "modprobe zfs",
      "udevadm settle",
      "parted --script /dev/vdb mklabel msdos",
      "parted --script /dev/vdb -- mkpart primary 1024M -1s",
      "udevadm settle",
      "zpool create dpool /dev/vdb1",
      "zfs create -o mountpoint=legacy dpool/legacy-data",
      "zfs create -o mountpoint=/data dpool/data",
      "mkdir -p /legacy-data",
      "mount -t zfs dpool/legacy-data /legacy-data",
      "udevadm settle"
    )
  '';
in
nixosTest {
  inherit system;
  name = "docker-zfs-plugin";
  nodes = {
    machine = { config, lib, pkgs, ... }: {
      imports = [
        dockerZfsPluginModule
      ];

      nixpkgs.overlays = [
        dockerZfsPluginOverlay
      ];

      virtualisation.graphics = false;

      # ZFS setup
      virtualisation.emptyDiskImages = [ 4096 ];
      networking.hostId = "deadbeef";
      boot.supportedFilesystems = [ "zfs" ];
      boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      environment.systemPackages = [ pkgs.parted ];

      services.docker-zfs-plugin = {
        enable = true;
        debug = true;
        snapshotOnCreate = true;
        datasets = [ "dpool/data" "dpool/legacy-data" ];
      };

      virtualisation.docker.enable = true;
    };
  };

  testScript = ''
    ${zfsInitScript}

    machine.wait_for_unit("sockets.target")
    machine.succeed("tar cv --files-from /dev/null | docker import - scratchimg") # Create a scratch image for later testing. Also starts up docker service

    # Create legacy ZFS volumes
    machine.succeed(
      "docker volume create --driver zfs dpool/legacy-data/zfstest",
      "docker volume ls --format '{{ .Driver }}\t{{ .Name }}' | grep '^zfs' | grep -q 'dpool/legacy-data/zfstest$'",
      "zfs list -H -p -s name -o name dpool/legacy-data/zfstest@initial &>/dev/null"
    )
    machine.succeed(
      "docker volume create --driver zfs dpool/data/zfstest",
      "docker volume ls --format '{{ .Driver }}\t{{ .Name }}' | grep '^zfs' | grep -q 'dpool/data/zfstest$'",
      "zfs list -H -p -s name -o name dpool/data/zfstest@initial &>/dev/null"
    )
    machine.succeed("docker system info -f '{{ .Plugins.Volume }}' | grep -q -F 'zfs'") # NOTE: appears only after zfs plugin is being used for at least once

    # Test if legacy ZFS dataset volume usage works
    machine.succeed(
      "mkdir -p /legacy-data/zfstest",
      "mount -t zfs dpool/legacy-data/zfstest /legacy-data/zfstest",
      "docker run --rm -i --name=zfs-volume-test -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin -v dpool/legacy-data/zfstest:/zfsvol scratchimg /bin/bash -c 'echo foo > /zfsvol/test.txt'",
      "grep -q -F 'foo' /legacy-data/zfstest/test.txt"
    )

    # Test if automounted ZFS dataset volume usage works
    machine.succeed(
      "docker run --rm -i --name=zfs-volume-test -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin -v dpool/data/zfstest:/zfsvol scratchimg /bin/bash -c 'echo bar > /zfsvol/test.txt'",
      "grep -q -F 'bar' /data/zfstest/test.txt"
    )
  '';
}
