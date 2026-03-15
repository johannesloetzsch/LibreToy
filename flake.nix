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

    nixosConfigurations."${InfOS.hostName}" = nixpkgs.lib.nixosSystem {
      inherit (InfOS) system;
      modules = [
        disko.nixosModules.disko ./disko.nix
        ./modules/setup/partitions.nix
        ./configuration.nix
      ];
    };

    nixosConfigurations."${InfOS.hostName}_iso" = nixpkgs.lib.nixosSystem {
      ## Usage: nix run nixpkgs#nixos-generators -- -f iso --flake .#infos_iso -o result.iso
      inherit (InfOS) system;
      modules = [
        ./configuration.nix
      ];
    };

    packages.${InfOS.system} = {
      inherit (pkgs) disko;
      "disko-image" = nixosConfigurations.${InfOS.hostName}.config.system.build.diskoImages;
      "disko-image-test" = import ./src/qemu { inherit pkgs; };

      "libretoy-dd" = import ./src/dd { inherit pkgs; };

      "partition-incremental" = import ./src/disko { inherit pkgs; };
    };

  };
}
