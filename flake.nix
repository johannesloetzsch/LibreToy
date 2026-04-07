{
  description = "LibreToy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, disko, nixpkgs, ... }:
  let
    cfg = {
      nixpkgs.system = "x86_64-linux";
      networking.hostName = "libretoy";
    };

    pkgs = import nixpkgs { inherit (cfg.nixpkgs) system; } //
    { inherit (disko.packages.${cfg.nixpkgs.system}) disko; };
  in
  rec {

    nixosConfigurations."${cfg.networking.hostName}" = nixpkgs.lib.nixosSystem {
      modules = [
        cfg
        disko.nixosModules.disko ./disko.nix
        ./modules/setup/partitions.nix
        ./configuration.nix
      ];
    };

    packages.${cfg.nixpkgs.system} = {
      inherit (pkgs) disko;
      "diskoImage" = nixosConfigurations.${cfg.networking.hostName}.config.system.build.diskoImages;
      "diskoImage-qemu" = import ./src/diskoImage-qemu { inherit self cfg pkgs; };

      "initrd-qemu" = import ./src/initrd-qemu { inherit self cfg pkgs; };

      "iso" = nixosConfigurations.${cfg.networking.hostName}.config.system.build.images.iso-installer;
      "iso-qemu" = import ./src/iso-qemu { inherit self cfg pkgs; };

      "libretoy-bootloader" = import ./src/libretoy-bootloader { inherit self cfg pkgs; };
      "libretoy-dd" = import ./src/libretoy-dd { inherit self cfg pkgs; };
      "libretoy-repartition" = import ./src/libretoy-repartition { inherit self cfg pkgs; };
    };

  };
}
