# docker-zfs-plugin

Docker volume plugin for creating persistent volumes as dedicated zfs datasets.

This is a fork of [ZentriaMC/docker-zfs-plugin](https://github.com/ZentriaMC/docker-zfs-plugin), which is a fork of [TrilliumIT/docker-zfs-plugin](https://github.com/TrilliumIT/docker-zfs-plugin).

## Installation

Create a dataset with `mountpoint=legacy` which is used as the root for all other datasets created by this driver:
```sh
zfs create -p -o mountpoint=legacy pool/my/root/dataset/for/docker
```

Assuming you use NixOS:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    docker-zfs-plugin.url = "github:ReneHollander/docker-zfs-plugin";

    docker-zfs-plugin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations."hostname" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        inputs.docker-zfs-plugin.nixosModule
      ];
    };
  };
}
```

Configure the service:

```nix
{
  services.docker-zfs-plugin = {
    enable = true;
    datasets = [ "pool/my/root/dataset/for/docker" ];
    mountDir = "/tmp/docker-volumes/zfs";
  };
}
```

## Usage

Example docker-compose.yml

```yml
services:
  mycontainer:
    # ...
    volumes:
      - myvolume:/workingdir
    # ...
volumes:
  myvolume:
    driver: zfs
    name: "pool/my/root/dataset/for/docker/myvolume"
```
