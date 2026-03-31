{
  description = "A disko images example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, disko, nixpkgs, ... }:
  let
    InfOS = builtins.fromJSON (builtins.readFile ./InfOS.json);
    pkgs = import nixpkgs { inherit (InfOS) system; } //
           { inherit (disko.packages.${InfOS.system}) disko; };
  in
  rec {

    nixosModules = {
      disko = import ./disko.nix;
    };
    
#    nixosConfigurations."TODO" = libretoySystem {
#      partitions = {
#        bootloader = { "EFI".size = "100M"; };
#        nixos = { "ZFS".size = "10G"; };
#        misc = { "EXFAT".size = "5G"; "GENODE".size = "100%"; };
#      };
#      partitionsSorted = [ … ];
#      images = …
#      modules = [
#        ./configuration.nix
#      ];
#    };

    nixosConfigurations."${InfOS.hostName}" = nixpkgs.lib.nixosSystem {
      inherit (InfOS) system;
      modules = [
        disko.nixosModules.disko ./disko.nix
        ./modules/setup/partitions.nix
        ./configuration.nix
      ];
    };

    packages.${InfOS.system} = {
      inherit (pkgs) disko;
      "disko-image" = nixosConfigurations.${InfOS.hostName}.config.system.build.diskoImages;
      "disko-image-test" = import ./src/qemu { inherit pkgs; };
      "libretoy-dd" = import ./src/dd { inherit self pkgs; };
      "libretoy-iso" = nixosConfigurations.${InfOS.hostName}.config.system.build.images.iso-installer;
      "partition-incremental" = import ./src/disko { inherit pkgs; };
    };

  };
}
