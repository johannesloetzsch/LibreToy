{ config, lib, ... }:

let
  hostname = "infos";

  partitions = config.disko.devices.disk.${hostname}.content.partitions;
  sortedPartitions = lib.sort (x: y: x.priority < y.priority) (lib.attrValues partitions);

  partitionToJSON = partition: {
    index = partition._index;
    name = partition.name;
    label = partition.label;
    type = partition.type;
    start = partition.start;
    end = partition.end;
    content = if builtins.isAttrs partition.content then
      lib.filterAttrs (k: v: k == "type" || k == "format" ) partition.content
    else {};
  };
in
{
  options.LibreToy = {

    "sortedPartitions" = lib.mkOption {
      default = sortedPartitions;
      description = "The partitions defined via disko (sorted as array)";
    };

    "partitions_json" = lib.mkOption {
      default = builtins.toFile "partitions.json" (lib.toJSON (map partitionToJSON sortedPartitions));
      description = "Sorted partitions (json export)";
    };

  };
}
