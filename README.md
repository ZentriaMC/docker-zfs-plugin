# docker-zfs-plugin

Docker volume plugin for creating persistent volumes as dedicated zfs datasets.

## Installation

Assuming you use NixOS

```nix
{
  imports = [
    (import "${builtins.fetchTarball "https://github.com/ZentriaMC/docker-zfs-plugin/archive/master.tar.gz"}/nixos")
  ];

  services.docker-zfs-plugin = {
    enable = true;
    datasets = [ "dpool" ];
  };
}
```

## Usage

After the plugin is running, you can interact with it through normal `docker volume` commands. Driver name is `zfs`

You can pass in ZFS attributes from the `docker volume create` command:

`docker volume create -d zfs -o compression=lz4 -o dedup=on --name=tank/docker-volumes/data`
