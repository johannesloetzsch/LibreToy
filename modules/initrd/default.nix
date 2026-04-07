{ pkgs, ... }:
{
  ## Without this fix, the keyboard might not work during systemd-boot, so luks-partitions can't be unlocked.
  #boot.kernelParams = [ "i8042.nomux=1" "i8042.reset=1" ];
  boot.kernelParams = [ "i8042.nomux=1" "i8042.reset=1" "rd.systemd.unit=rescue.target" ];

  boot.initrd.availableKernelModules = [ "e1000" "e1000e" "iwlwifi" ];

  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true;  ## For debugging via this kernel parameters:
                             ##   systemd.unit=rescue.target (stage2) rd.systemd.unit=rescue.target (stage1)
                             ##   systemd.debug_shell (stage2)        rd.systemd.debug_shell (stage1)        -> (ctrl + alt + F9)
                             ## systemctl only works after `unset TERM`
                             ## networking in stage1 can be started by `systemctl start systemd-networkd`

    initrdBin = with pkgs; [
      busybox
      util-linux
      kbd
      (import ../../src/libretoy-repartition/tmp.nix { inherit pkgs; })
    ];

    #contents = {};  ## TODO /etc/ssl/certs


  };

  boot.initrd.network.enable = true;
  networking.useDHCP = true;

  boot.initrd.stage1Greeting = ''Welcome to LibreToy
    This is a multiline greeting :)
    '';

  #boot.initrd.prepend = [];
}
