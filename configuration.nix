{ config, pkgs, lib, ... }:

{
  system.stateVersion = config.system.nixos.release;

  imports = [
    ./modules/bootloader/grub
    ./modules/bootloader/grub/isoboot/grub-iso-multiboot.nix
    ./modules/initrd
    ./modules/images
    ./modules/nix
  ];

  hardware.enableAllHardware = true;

  users.users.root.initialHashedPassword = "";
}
