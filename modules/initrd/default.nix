{ self, cfg, pkgs, ... }:

let
  libretoy-repartition = import ../../src/libretoy-repartition { inherit self cfg pkgs; };
in
{
  imports = [
    ./hardware.nix
    ./network.nix
    ./libretoy-service.nix
  ];

  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true;  ## For debugging via this kernel parameters:
                             ##   systemd.unit=rescue.target (stage2) rd.systemd.unit=rescue.target (stage1)
                             ##   systemd.debug_shell (stage2)        rd.systemd.debug_shell (stage1)        -> (ctrl + alt + F9)
                             ## systemctl only works after `unset TERM`
                             ## networking in stage1 can be started by `systemctl start systemd-networkd`
    initrdBin = with pkgs; [
      kbd  ## loadkeys
      util-linuxMinimal  ## lsblk, … — We need the version used by config.system.build.images.iso-installer
      busybox  ## optional, could be removed
    ] ++
    [ libretoy-repartition ] ++ libretoy-repartition.runtimeInputs;

    contents = {
      "/etc/partitions.json".source = libretoy-repartition.partition_json;
    };
  };

  boot.kernelParams = [ "rd.systemd.unit=libretoy.target" ];
  boot.initrd.stage1Greeting = "Welcome to LibreToy";
}
