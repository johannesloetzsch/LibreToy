{ config, pkgs, lib, ... }:

{
  system.stateVersion = config.system.nixos.release;

  imports = [
    ./modules/bootloader/grub
    ./modules/bootloader/grub/isoboot/grub-iso-multiboot.nix
    ./modules/images
  ];

  hardware.enableAllHardware = true;

  users.users.root.initialPassword = "";
}
