{
  buildLinux,
  fetchFromGitHub,
  lib,
  ...
}:
let
  inherit (builtins)
    attrNames
    filter
    fromJSON
    getAttr
    pathExists
    readDir
    readFile
    ;

  inherit (lib.strings)
    hasSuffix
    ;

  source = fromJSON (readFile ./source.json);

  linux_jhovold_src = fetchFromGitHub {
    inherit (source)
      hash
      owner
      repo
      rev
      ;
  };

  patches =
    let
      basePatchDir = ./patches/${source.rev};
      entries = readDir basePatchDir;
      files = filter (key: (getAttr key entries) == "regular" && (hasSuffix ".patch" key)) (
        attrNames entries
      );
    in
    if pathExists basePatchDir then
      map (filename: {
        name = filename;
        patch = basePatchDir + "/${filename}";
      }) files
    else
      [ ];

in
buildLinux {
  modDirVersion = source.version;

  src = linux_jhovold_src;
  version = source.version;
  defconfig = "johan_defconfig";

  # NOTE: Disables configs that are applied by the NixOS
  enableCommonConfig = false; 

  # Simplified configuration with required options
  structuredConfig = with lib.kernel; {
    
    # Disable conflicting platform options explicitly
    ARCH_BCM2835 = no;
    BCM2835_MBOX = no;
    BCM2835_WDT = no;
    PCI_TEGRA = no;
    RASPBERRYPI_FIRMWARE = no;
    RASPBERRYPI_POWER = no;
    SERIAL_8250_BCM2835AUX = no;
    USB_XHCI_TEGRA = no;
  };

  kernelPatches = patches;

  extraMeta.branch = source.rev;
}
