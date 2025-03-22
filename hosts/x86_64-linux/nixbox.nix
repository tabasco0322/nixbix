{
  adminUser,
  config,
  ...
}: {
  publicKey = "";

  imports = [
    ../../profiles/hardware/usbcore.nix
    ../../profiles/hardware/x570.nix
    ../../profiles/admin-user/home-manager.nix
    ../../profiles/admin-user/user.nix
    ../../profiles/disk/btrfs-on-luks.nix
    ../../profiles/desktop.nix
    #../../profiles/greetd.nix
    ../../profiles/home-manager.nix
    #../../profiles/restic-backup.nix
    ../../profiles/state.nix
    #../../profiles/tailscale.nix
    ../../profiles/zram.nix
  ];

  boot.loader.systemd-boot.memtest86.enable = true;

  boot.initrd = {
    systemd.enable = true;
  };

  services.ratbagd.enable = true;

  #age.secrets = {
  #  id_ed25519 = {
  #    file = ../../secrets/id_ed25519.age;
  #    owner = "${toString adminUser.uid}";
  #    path = "/home/${adminUser.name}/.ssh/id_ed25519";
  #  };
  #};

  #programs.steam.enable = true;
  #services.flatpak.enable = true;

 home-manager = {
   users.${adminUser.name} = {
     imports = [../../users/profiles/workstation.nix];
#      programs.git.extraConfig.user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH8FItRsdPvpg8mTCF7gsKQJ4ABaOCE8a6PzamumRWe3AAAABHNzaDo=";
#      programs.jujutsu.settings.signing = {
#        sign-all = true;
#        backend = "ssh";
#        key = config.age.secrets.id_ed25519.path;
#      };
   };
 };
}
