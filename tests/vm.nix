(import ./lib.nix) {

  name = "docker-zfs-plugin";
  nodes = {
    machine = { self, config, lib, pkgs, ... }: {
      imports = [ self.nixosModules.docker-zfs-plugin ];

      virtualisation.graphics = false;

      # ZFS setup
      virtualisation.emptyDiskImages = [ 4096 ];
      networking.hostId = "deadbeef";
      boot.supportedFilesystems = [ "zfs" ];
      environment.systemPackages = [ pkgs.parted ];

      services.docker-zfs-plugin = {
        enable = true;
        datasets = [ "dpool/data" ];
        mountDir = "/my/mount/point";
      };

      virtualisation.docker.enable = true;
    };
  };

  testScript = ''
    # Set up ZFS pool and a dataset
    machine.succeed(
      "modprobe zfs",
      "udevadm settle",
      "parted --script /dev/vdb mklabel msdos",
      "parted --script /dev/vdb -- mkpart primary 1024M -1s",
      "udevadm settle",
      "zpool create dpool /dev/vdb1",
      "zfs create -o mountpoint=legacy dpool/data",
      "mkdir -p /my/mount/point",
      "udevadm settle"
    )

    machine.wait_for_unit("sockets.target")
    machine.succeed("tar cv --files-from /dev/null | docker import - scratchimg") # Create a scratch image for later testing. Also starts up docker service

    machine.succeed(
      # Create the volume
      "docker volume create --driver zfs dpool/data/zfstest",
      # Verify the driver can list it
      "docker volume ls --format '{{ .Driver }}\t{{ .Name }}' | grep '^zfs' | grep -q 'dpool/data/zfstest$'",
      # Verify the dataset exists
      "zfs list -H -p -s name -o name dpool/data/zfstest &>/dev/null",
      # Verify the dataset is not mounted (we only created it, not mounted)
      "! mount | grep dpool/data/zfstest"
    )
    machine.succeed("docker system info -f '{{ .Plugins.Volume }}' | grep -q -F 'zfs'") # NOTE: appears only after zfs plugin is being used for at least once

    machine.succeed(
      # Start a container with the volume
      "docker run --rm -i --name=zfs-volume-test -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin -v dpool/data/zfstest:/zfsvol scratchimg /bin/bash -c 'echo bar > /zfsvol/test.txt'",
      # After container exits, verify dataset is unmounted
      "! mount | grep dpool/data/zfstest",
      # Mount the dataset and check if the value we wrote in the container is there
      "mkdir -p /tmp/zfstest",
      "mount -t zfs dpool/data/zfstest /tmp/zfstest",
      "grep -q -F 'bar' /tmp/zfstest/test.txt",
      "umount /tmp/zfstest"
    )

    # Test mounted multiple times
    machine.succeed(
      # Start a container with the volume
      "docker run --rm -d --name=zfs-volume-test1 -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin -v dpool/data/zfstest:/zfsvol scratchimg /bin/bash -c 'sleep infinity'",
      "docker run --rm -d --name=zfs-volume-test2 -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin -v dpool/data/zfstest:/zfsvol scratchimg /bin/bash -c 'sleep infinity'",
      # check dataset is mounted
      "mount | grep dpool/data/zfstest",
      "docker stop zfs-volume-test1",
      # check dataset is still mounted
      "mount | grep dpool/data/zfstest",
      "docker stop zfs-volume-test2",
      # check dataset is no longer mounted
      "! mount | grep dpool/data/zfstest",
    )

    machine.succeed(
      # Remove the volume
      "docker volume rm dpool/data/zfstest",
      # Verify ZFS no longer knows about it
      "! zfs list -H -p -s name -o name dpool/data/zfstest &>/dev/null"
    )

    # Invalid root dataset
    machine.fail("docker volume create --driver zfs dpool/invalid/mydataset")
  '';
}
