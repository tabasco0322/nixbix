{
  adminUser,
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:
let
  inherit (import ../hostvars/${hostName}.nix)
    ;
in
{
  imports = [
    ./defaults.nix
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 12288;
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.graphics.extraPackages = [ ];

  hardware.graphics.extraPackages32 = [ ];

  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
  networking.wireless.iwd.enable = true;

  environment.pathsToLink = [ "/etc/gconf" ];

  security.pam.services.gdm.enableGnomeKeyring = true; # load gnome-keyring at startup
  programs.seahorse.enable = true; # enable the graphical frontend for managing

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  environment.persistence."/keep".directories = [ "/var/cache/powertop" ];

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = false;
  virtualisation.podman.dockerCompat = false;

  virtualisation.vmware.host.enable = false;

  virtualisation.libvirtd = {
    enable = false;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  programs.ssh.startAgent = true;

  # Local checkout, so a bare `nh os switch` picks up uncommitted changes.
  # Only workstations have one; servers are deployed to remotely.
  programs.nh.flake = "/home/${adminUser.name}/git/nixbix";

  programs.gamemode.enable = true;

  services.pcscd.enable = true;

  programs.dconf.enable = true;

  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  services.openssh.enable = true;

  services.fwupd.enable = true;

  services.dbus.packages = with pkgs; [
    gcr
    dconf
    sushi
  ];
  services.udev.packages = with pkgs; [
    wooting-udev-rules
    gnome-settings-daemon
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
          bluez_monitor.properties = {
            ["bluez5.enable-sbc-xq"] = true,
            ["bluez5.enable-msbc"] = true,
            ["bluez5.enable-hw-volume"] = true,
            ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
          }
        '')
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
    # Keyed off XDG_CURRENT_DESKTOP lowercased, so this must say hyprland.
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };

  fonts.packages = with pkgs; [
    google-fonts
    font-awesome_5
    powerline-fonts
    roboto
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    nerd-fonts.roboto-mono
  ];

  machinePurpose = "workstation";
}
