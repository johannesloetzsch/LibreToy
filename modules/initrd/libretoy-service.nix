{ pkgs, ... }:
{
  boot.initrd.systemd.services = {
    "libretoy" = {
      description = "Repartitioning of LibreToy-USB-Flashdrives.";
      serviceConfig = {
        Type = "simple";
        ExecStart = [ "${pkgs.bash}/bin/bash -i -l" ];
        StandardInput = "tty-force";
      };
      environment."TERM" = "dumb";
    };
  };

  boot.initrd.systemd.targets = {
    "libretoy" = {
      description = "LibreToy Installer";
      requires = [ "libretoy.service" "sysinit.target" ];
    };
  };

  boot.initrd.availableKernelModules = [ "fat" "vfat" "nls_cp437" "nls_iso8859_1" ];
}
