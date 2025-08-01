{
  pkgs,
  modulesPath,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  services.openssh.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Europe/Stockholm";
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.timeout = lib.mkForce 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.supportedFilesystems = lib.mkForce [
    "btrfs"
    "cifs"
    "f2fs"
    "jfs"
    "ntfs"
    "reiserfs"
    "vfat"
    "xfs"
    "bcachefs"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGWqiT3pihX88HrCvpnnsWANv3RJm5SdMJwZkRHpfHj5AAAABHNzaDo= nemko@nixbox"
  ];

  nix = {
    settings.trusted-users = [ "root" ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      tarball-ttl = 900
    '';
  };

  environment.systemPackages = with pkgs; [
    git
    nixos-install-tools
    bcachefs-tools
    btrfs-progs
    jq
  ];
}
