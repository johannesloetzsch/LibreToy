{ self, cfg, pkgs }:

let
  kernel = "${self.nixosConfigurations.${cfg.networking.hostName}.config.system.build.kernel}/bzImage";
  initrd = "${self.nixosConfigurations.${cfg.networking.hostName}.config.system.build.initialRamdisk}/initrd";
  ram = "2G";
in
with pkgs; writeShellApplication {
  name = "initrd-qemu";
  runtimeInputs = [ qemu kernel initrd ];
  text = ''
    qemu-system-x86_64 \
      -enable-kvm \
      -m ${ram} \
      -kernel ${kernel} \
      -initrd ${initrd} \
      -append "loglevel=4 rd.systemd.unit=rescue.target"
  '';
}
