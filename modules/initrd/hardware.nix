{ pkgs, ... }:
{
  ## Keyboard of Fujitsu Lifebooks
  boot.kernelParams = [ "i8042.nomux=1" "i8042.reset=1" ];
}
