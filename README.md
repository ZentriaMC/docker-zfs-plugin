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

Or with Nix Flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    docker-zfs-plugin.url = "github:ZentriaMC/docker-zfs-plugin";

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

## Usage

After the plugin is running, you can interact with it through normal `docker volume` commands. Driver name is `zfs`

You can pass in ZFS attributes from the `docker volume create` command:

`docker volume create -d zfs -o compression=lz4 -o dedup=on --name=tank/docker-volumes/data`
