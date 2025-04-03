{adminUser, ...}: {
  environment.persistence."/keep" = {
    hideMounts = true;
    directories = [
      "/root"
      "/var/lib/bluetooth"
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/flatpak"
      "/var/lib/libvirt"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/tailscale"
      "/var/lib/wireguard"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.${adminUser.name} = {
      directories = [
        ".aws"
        ".backup/undo"
        ".cache/chromium"
        ".cache/monero-project"
        ".cache/mu"
        ".cache/nix"
        ".cache/nix-index"
        ".cache/nvim"
        ".cache/rbw"
        ".cache/zellij"
        ".cargo"
        ".config/Signal"
        ".config/WowUpCf"
        ".config/beekeeper-studio"
        ".config/bruno"
        ".config/chromium"
        ".config/discord"
        ".config/vesktop"
        ".config/easyeffects"
        ".config/gcloud"
        ".config/gh"
        ".config/github-copilot"
        ".config/lutris"
        ".config/monero-project"
        ".config/obs-studio"
        ".config/pipewire"
        ".config/pulse"
        ".config/spotify"
        ".config/warcraftlogs"
        ".factorio"
        ".gnupg"
        ".local/share/Steam"
        ".local/share/TelegramDesktop"
        ".local/share/atuin"
        ".local/share/containers"
        ".local/share/direnv"
        ".local/share/fish"
        ".local/share/flatpak"
        ".local/share/lutris"
        ".local/share/nix"
        ".local/share/vulkan"
        ".local/share/zoxide"
        ".local/state/pipewire/media-session.d"
        ".local/state/wireplumber"
        ".mail"
        ".mozilla"
        ".steam"
        ".terraform.d"
        ".var"
        ".wine"
        "Documents"
        "Downloads"
        "Games"
        "Photos"
        "Pictures"
        "code"
        "git"
	".ssh"
      ];
      files = [
        ".cockroachsql_history"
        ".config/nushell/history.txt"
        ".kube/config"
      ];
    };
  };
}
