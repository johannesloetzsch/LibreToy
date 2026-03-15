{ pkgs, ... }:

let
  InfOS = builtins.fromJSON (builtins.readFile ../../InfOS.json);
in
with pkgs; writeShellApplication {
  name = "install-bootloader";
  runtimeInputs = [
    coreutils  ## dd
    busybox    ## partprobe
    gptfdisk   ## sgdisk gdisk
  ];
  text = ''
    if [ $# -lt 1 ]; then
      echo "Usage: $0 <DEVICE>"
      exit 1
    fi
    DEVICE=$1

    nix build .#disko-image
    IMAGE="result/${InfOS.hostName}.raw"


    function copy() {
      ## Copy all partitions up to $PARTNAME_LAST

      PARTNAME_LAST="disk-${InfOS.hostName}-ESP"  ## The last partition to be copied
      SECTOR_SIZE=$(sgdisk -p $IMAGE | awk '/Sector size \(logical\)/ {print $4}')
      SECTORS=$(sgdisk -p $IMAGE | awk -v PARTNAME="$PARTNAME_LAST" '$7 ~ PARTNAME {print $3}')

      BYTES=$((SECTOR_SIZE * SECTORS))
      BS=$((8 * 1024 * 1024))  ## 8MiB should be lange enough for good performance
      COUNT=$(( (BYTES + BS-1) / BS ))  ## Round up

      dd if="$IMAGE" of="$DEVICE" bs="$BS" count="$COUNT" status=progress

      echo -e "v\nw\ny\ny" | gdisk "$DEVICE"  ## Fix backup header
      partprobe "$DEVICE"
      sgdisk -p "$DEVICE"  ## For debugging
    }
    copy
  '';
}
