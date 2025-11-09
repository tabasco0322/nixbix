{
  adminUser,
  lib,
  config,
  ...
}:
{
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILWkKCvGPLYGiz8bY0cHI5INItAT8t6cQcfurKLd7nSz";

  imports = [
    ../../profiles/hardware/usbcore.nix
    ../../profiles/hardware/fw_desktop.nix
    ../../profiles/admin-user/home-manager.nix
    ../../profiles/admin-user/user.nix
    ../../profiles/disk/btrfs-on-luks.nix
    ../../profiles/uuid_disk_crypt.nix 
    ../../profiles/desktop.nix
    ../../profiles/greetd.nix
    ../../profiles/home-manager.nix
    ../../profiles/k3s-agent.nix
    ../../profiles/nfs.nix
    ../../profiles/aio_media.nix
    #../../profiles/restic-backup.nix
    ../../profiles/state.nix
    ../../profiles/tailscale.nix
    ../../profiles/zram.nix
  ];

  boot.loader.systemd-boot.memtest86.enable = true;

  boot.initrd = {
    systemd.enable = true;
  };


  #age.secrets = {
  #  id_ed25519 = {
  #    file = ../../secrets/id_ed25519.age;
  #    owner = "${toString adminUser.uid}";
  #    path = "/home/${adminUser.name}/.ssh/id_ed25519";
  #  };
  #};

  networking.firewall.allowedTCPPorts = [
    5900
  ];

  programs.steam.enable = true;
  services.flatpak.enable = true;

  home-manager = {
    users.${adminUser.name} = {
      imports = [ ../../users/profiles/workstation.nix ];
      #      programs.git.extraConfig.user.signingKey = "key::sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH8FItRsdPvpg8mTCF7gsKQJ4ABaOCE8a6PzamumRWe3AAAABHNzaDo=";
      #      programs.jujutsu.settings.signing = {
      #        sign-all = true;
      #        backend = "ssh";
      #        key = config.age.secrets.id_ed25519.path;
      #      };
    };
  };

  age.secrets = {
    k3s-token = {
      file = ../../secrets/k3s/token.age;
    };
    ts = {
      file = ../../secrets/ts.age;
      owner = "1100";
    };
    acme-cf = {
      file = ../../secrets/acme-cf.age;
    };
  };

  #services.k3s.settings = {
  #  server = lib.mkForce "";
  #  node-external-ip = lib.mkForce "\"$(get-iface-ip enp191s0)\"";
  #};
}
