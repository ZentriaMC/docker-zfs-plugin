{ config, pkgs, lib, ... }:

with lib;
let cfg = config.services.docker-zfs-plugin;
in {
  options = {
    services.docker-zfs-plugin = {
      enable = mkEnableOption "docker-zfs-plugin";

      datasets = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "What datasets should be exposed to the plugin";
      };
      mountDir = mkOption {
        type = types.str;
        default = null;
        description =
          "Directory were datasets are mounted before being passed to Docker.";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.enable -> (cfg.datasets != [ ]);
        message =
          "Must specify atleast one dataset when Docker ZFS volume plugin is desired";
      }
      {
        assertion = cfg.enable -> (cfg.mountDir != null);
        message = "Must specify the mountDir";
      }
      {
        assertion = cfg.enable -> config.boot.zfs.enabled;
        message = "ZFS support must be enabled for docker-zfs-plugin to work";
      }
    ];

    nixpkgs.overlays = [ (import ./overlay.nix) ];

    systemd.services.docker-zfs-plugin = mkIf cfg.enable {
      description =
        "Docker volume plugin for creating persistent volumes as a dedicated zfs datasets.";
      serviceConfig = {
        Restart = "on-abnormal";
        ExecStart = with cfg;
          toString ([
            "${pkgs.docker-zfs-plugin}/bin/docker-zfs-plugin"
            "--mount-dir ${cfg.mountDir}"
          ] ++ map (d: " --dataset-name ${d}") datasets);
      };

      after = [ "docker-zfs-plugin.socket" ];
      requires = [ "zfs.target" "docker-zfs-plugin.socket" ];
      path = [ pkgs.zfs ];
    };

    systemd.sockets.docker-zfs-plugin = mkIf cfg.enable {
      description = "docker-zfs-plugin listen socket";
      wantedBy = [ "sockets.target" ];
      requires = [ "docker.socket" ];
      before = [ "docker.service" ];

      socketConfig = {
        ListenStream =
          "/run/docker/plugins/zfs.sock"; # TODO: configurable path?
        SocketMode = "0660";
        SocketUser = "root";
        SocketGroup = "root";
      };
    };
  };
}
