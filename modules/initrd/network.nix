{ pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "e1000"  ## QEMU
    "e1000e"  ## Intel Ethernet
    "iwlwifi"  ## Intel WiFi
  ];

  boot.initrd.network.enable = true;
  networking.useDHCP = true;
}
