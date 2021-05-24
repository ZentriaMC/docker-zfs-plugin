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
          + "${if (zfs-cfg.debug) then "--debug" else ""} "
          + "${concatMapStrings (x: " --dataset-name " + x) zfs-cfg.datasets}";
      };

      before = [ "docker.service" ];
      wantedBy = [ "docker.service" ];
      requires = [ "zfs.target" ];
      path = [ pkgs.zfs ];
    };
  };
}
