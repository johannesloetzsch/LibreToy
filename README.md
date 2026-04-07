# LibreToy

Bootable USB creator — Like Ventoy, but 100% open source

![logo](./doc/img/LibreToy.png)


## Installation

### Using Nix (build from scratch)

```bash
sudo nix run .#libretoy-dd $DEVICE
```

This will:
1. build LibreToy (`diskoImage`)
2. copy the `libretoy-bootloader` to `$DEVICE`
3. run `libretoy-repartition` (using free space of `$DEVICE` as defined in disko.nix)

### Using prebuild bootloader (CI-build)

1. Download [`libretoy.img`](https://gradient.c3d2.de/api/v1/projects/test/libretoy/entry-point-downloads?eval=packages.x86_64-linux.%22libretoy-bootloader%22&filename=libretoy.img)
2. Copy the image to $DEVICE (`dd if=libretoy.img of=$DEVICE bs=4M`)
