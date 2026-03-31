{ pkgs, ... }:

let
  grub-iso-multiboot = pkgs.fetchFromGitHub {
    owner = "mpolitzer";
    repo = "grub-iso-multiboot";
    rev = "cd01b5c066080ab821d50bfbd61a568f3dc2a68f";
    sha256 = "sha256-mF/i8VPbOsNE7Pqeq3esIAoTaumHbSPUa5twyrGOC0s=";
  };
in
{
  boot.loader.grub = {
    extraFiles = {
      "grub/autoiso.cfg" = "${grub-iso-multiboot}/boot/grub/script/autoiso.cfg";
    };

    extraEntries = ''
      menuentry "Scan ISOs (using grub-iso-multiboot)" "/grub/autoiso.cfg" {
          savedefault
          set iso_dirs="/ /iso"
          export iso_dirs
          configfile "$2"
      }
    '';
  };
}
