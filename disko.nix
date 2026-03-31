{ pkgs, ... }:

let
  InfOS = builtins.fromJSON (builtins.readFile ./InfOS.json);
in
{
  boot.zfs.devNodes = "/dev/disk/by-partlabel/disk-${InfOS.hostName}-ZFS";
  networking.hostId = "00012f05";

  LibreToy.imageLastPartitionName = "ZFS";

  disko.imageBuilder.extraDependencies = with pkgs; [ exfat ];
  disko.devices = {
    disk = {
      ${InfOS.hostName} = {

        device = "${InfOS.device}";

        type = "disk";
        imageSize = "6G";
        content = {
          type = "gpt";
          partitions = {

            BBP = {  # BIOS boot partition
              priority = 1;
              type = "EF02";  # for grub MBR
              size = "1M";
            };
            ESP = {  # EFI system partition
              priority = 2;
              type = "EF00";
              size = "100M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ] ++ [ "nofail" ];
              };
            };

            ZFS = {
              priority = 10;
              size = "5G";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };

            GENODE = {  # Genode + ISOs
              priority = 100;
              size = "10M";
              content = {
                type = "filesystem";
                format = "ext2";
                #mountpoint = "/mnt/ext2";
                mountOptions = [ "noatime" "nodiratime" "barrier=0" ];
              };
            };

            EXFAT = {  # Win-Share
              priority = 101;
              size = "100%";
              content = {
                type = "filesystem";
                format = "exfat";
                #mountpoint = "/mnt/exfat";
                mountOptions = [ "umask=0077" ] ++ [ "nofail" ];
              };
            };

          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "root/nix/store" = {
            type = "zfs_fs";
            mountpoint = "/nix/store";
            options.mountpoint = "legacy";
          };
          "root/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
