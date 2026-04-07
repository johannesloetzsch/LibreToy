{ self, cfg, pkgs, ... }:

let
  partition_json = self.nixosConfigurations.${cfg.networking.hostName}.config.LibreToy.partitions_json;
  runtimeInputs = with pkgs; [
    gptfdisk  ## fdisk
    systemd  ## udevadm
    e2fsprogs.bin  ## resize2fs
    exfat  ## mkfs.exfat
    fatresize
    dosfstools  ## fatlabel
    jq
  ];
in
{ inherit runtimeInputs partition_json; } // pkgs.writeShellApplication {
  name = "libretoy-repartition";
  inherit runtimeInputs;
  text = ''
    set -e

    if [ $# -lt 2 ]; then
      echo "Usage: $0 <DEVICE> <KEEP_PARTITIONS> [<PARTITIONS.JSON>]"
      exit 1
    fi
    DEVICE=$1
    KEEP_PARTITIONS=$2

    if [ $# -ge 3 ]; then
      PARTITIONS_JSON=$3
    else
      PARTITIONS_JSON=${partition_json}
    fi

    [ -w "$DEVICE" ] || (echo "No permissions to access $DEVICE. You may want use sudo." && exit 1)


    function trace() {
      set -x
      "$@"
      { set +x; } 2>/dev/null
    }


    function delete_partitions() {
      for INDEX in $(sgdisk --print "$DEVICE" | awk '/^ *[0-9]+/ {print $1}'); do
        if [ "$INDEX" -ge $((START_OFFSET + KEEP_PARTITIONS + 1)) ]; then
          trace sgdisk --delete="$INDEX" "$DEVICE"
        fi
      done
      echo
    }


    function create_partition() {
        trace sgdisk \
        --new="$INDEX":"$START":"$END" \
        --change-name="$INDEX":"$LABEL" \
        --typecode="$INDEX":"$TYPECODE" \
        "$DEVICE"

        udevadm trigger --subsystem-match=block
        udevadm settle --timeout 120
    }


    function resize() {
      if [ "$TYPE" = "filesystem" ]; then
        if [ "$FORMAT" = "ext2" ] || [ "$FORMAT" = "ext3" ] || [ "$FORMAT" = "ext4" ]; then
          trace resize2fs "$DEVICE_PART"
          trace tune2fs -L "$NAME" "$DEVICE_PART"
        elif [ "$FORMAT" = "vfat" ]; then
          trace fatresize -s max "$DEVICE_PART" || true
          trace fatlabel "$DEVICE_PART" "$NAME"
        else
          echo "TODO: Implement resizing of $FORMAT."
          echo "$DEVICE_PART was not resized."
        fi
      else
        echo "Not a filesystem: $DEVICE_PART -> not resizing."
        echo "TODO: Implement resizing of TYPE=$TYPE, FORMAT=$FORMAT."
      fi
    }


    function format() {
      if [ "$TYPE" = "filesystem" ]; then
        if [ "$FORMAT" = "ext2" ] || [ "$FORMAT" = "ext3" ] || [ "$FORMAT" = "ext4" ]; then
          ARGS=(-L "$NAME" -F -E lazy_itable_init=1 -T largefile)
        elif [ "$FORMAT" = "exfat" ]; then
          ARGS=(-n "$NAME")
        else
          echo "TODO: Implement filessystem-label for $FORMAT."
          ARGS=()
        fi
        trace mkfs."$FORMAT" "''${ARGS[@]}" "$DEVICE_PART"
      else
        echo "Not a filesystem: $DEVICE_PART -> not formating."
        echo "TODO: Implement initialization of $TYPE $FORMAT."
      fi
    }


    function repartition() {
      PARTITIONS_COUNT=$(cat "$PARTITIONS_JSON" | jq ".[$KEEP_PARTITIONS:] | length")

      if [ "$KEEP_PARTITIONS" -ge 1 ]; then
        ## There is a preceding partiton, we try to resize it
        START_OFFSET=-1
      else
        START_OFFSET=0
      fi

      delete_partitions

      for OFFSET in $(seq "$START_OFFSET" $((PARTITIONS_COUNT-1))); do
        INDEX=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].index")
        LABEL=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].label")
        NAME=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].name")
        TYPECODE=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].type")
        FORMAT=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].content.format")
        TYPE=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].content.type")
        START=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].start")
        END=$(cat "$PARTITIONS_JSON" | jq -r ".[$((KEEP_PARTITIONS + OFFSET))].end")

        echo "$OFFSET" "$INDEX" "$LABEL" "$NAME" "$TYPECODE" "$TYPE" "$FORMAT" "$START" "$END"

        create_partition

        if [ -b "$DEVICE-part$INDEX" ]; then
          DEVICE_PART=$DEVICE-part$INDEX
        elif [ -b "$DEVICE$INDEX" ]; then
          DEVICE_PART=$DEVICE$INDEX
        else
          echo "Device for partition $INDEX of $DEVICE not found!"
          exit 2
        fi

        if [ "$OFFSET" -eq -1 ]; then
          resize
        else
          format
        fi

        echo
      done
    }


    repartition
  '';
}
