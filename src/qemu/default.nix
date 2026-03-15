{ pkgs, ... }:

let
  InfOS = builtins.fromJSON (builtins.readFile ../../InfOS.json);
in
with pkgs; writeShellApplication {
  name = "disko-image-test";
  runtimeInputs = [ qemu ];
  text = ''
    if [ $# -ge 1 ]; then
      IMAGE=$1
    else
      nix build .#disko-image
      IMAGE="result/${InfOS.hostName}.raw"
    fi
    tmpFile=$(mktemp /tmp/test-image.XXXXXX)
    trap 'rm -f $tmpFile' EXIT
    cp "$IMAGE" "$tmpFile" || (echo "This might fail, when $IMAGE is too large"; false) || exit
    qemu-system-x86_64 \
      -enable-kvm \
      -m 2G \
      -cpu max \
      -smp 2 \
      -netdev user,id=net0,hostfwd=tcp::2222-:22 \
      -device virtio-net-pci,netdev=net0 \
      -drive if=pflash,format=raw,readonly=on,file=${OVMF.firmware} \
      -drive if=pflash,format=raw,readonly=on,file=${OVMF.variables} \
      -drive "if=virtio,format=raw,file=$tmpFile"
  '';
}
