{
  adminUser,
  config,
  lib,
  ...
}:
{
  publicKey = "";

  imports = [
    #../../profiles/hardware/usbcore.nix
    ../../profiles/hardware/intel.nix
    #../../profiles/admin-user/home-manager.nix
    ../../profiles/admin-user/user.nix
    ../../profiles/disk/btrfs-on-luks.nix
    ../../profiles/uuid_disk_crypt.nix
    ../../profiles/k3s.nix
    #../../profiles/greetd.nix
    #../../profiles/home-manager.nix
    #../../profiles/restic-backup.nix
    ../../profiles/server.nix
    ../../profiles/state.nix
    #../../profiles/tailscale.nix
    ../../profiles/zram.nix
  ];

  #boot.loader.systemd-boot.memtest86.enable = true;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";

  # btrfs.disks = ["/dev/nvme0n1"];

  #services.ratbagd.enable = true;

  #age.secrets = {
  #  id_ed25519 = {
  #    file = ../../secrets/id_ed25519.age;
  #    owner = "${toString adminUser.uid}";
  #    path = "/home/${adminUser.name}/.ssh/id_ed25519";
  #  };
  #};

  btrfs = {
    disks = [
      "/dev/sda"
      "/dev/sdb"
    ];
  };

}
