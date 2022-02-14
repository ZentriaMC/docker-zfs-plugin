{ config, pkgs, lib, ... }:

with lib;
let
  zfs-cfg = config.services.docker-zfs-plugin;
in
{
  options = {
    services.docker-zfs-plugin = {
      enable = mkEnableOption "docker-zfs-plugin";
      debug = mkEnableOption "debug";
      snapshotOnCreate = mkEnableOption "snapshot-on-create";

      datasets = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "What datasets should be exposed to the plugin";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = zfs-cfg.enable -> (zfs-cfg.datasets != [ ]);
        message = "Must specify atleast one dataset when Docker ZFS volume plugin is desired";
      }
      {
        assertion = zfs-cfg.enable -> config.boot.zfs.enabled;
        message = "ZFS support must be enabled for docker-zfs-plugin to work";
      }
    ];

    systemd.services.docker-zfs-plugin = mkIf zfs-cfg.enable {
      description = "Docker volume plugin for creating persistent volumes as a dedicated zfs datasets.";
      serviceConfig = {
        Restart = "on-abnormal";
        ExecStart = "${pkgs.docker-zfs-plugin}/bin/docker-zfs-plugin "
          + "${lib.optionalString zfs-cfg.debug "--debug"} "
          + "${lib.optionalString zfs-cfg.snapshotOnCreate "--snapshot-on-create"} "
          + "${concatMapStrings (x: " --dataset-name " + x) zfs-cfg.datasets}";
      };

      after = [ "docker-zfs-plugin.socket" ];
      requires = [ "zfs.target" "docker-zfs-plugin.socket" ];
      path = [ pkgs.zfs ];
    };

    systemd.sockets.docker-zfs-plugin = mkIf zfs-cfg.enable {
      description = "docker-zfs-plugin listen socket";
      wantedBy = [ "sockets.target" ];
      requires = [ "docker.socket" ];
      before = [ "docker.service" ];

      socketConfig = {
        ListenStream = "/run/docker/plugins/zfs.sock"; # TODO: configurable path?
        SocketMode = "0660";
        SocketUser = "root";
        SocketGroup = "root";
      };
    };
  };
}
