{
  adminUser,
  config,
  pkgs,
  inputs,
  ...
}:
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

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };
  security.pam.services.hyprlock = { };

  security.pam.services.gdm.enableGnomeKeyring = true; # load gnome-keyring at startup
  programs.seahorse.enable = true; # enable the graphical frontend for managing

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  environment.persistence."/keep".directories = [ "/var/cache/powertop" ];

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = false;
  virtualisation.podman.dockerCompat = false;

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
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

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
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config =
      let
        wlrConf = {
          default = [
            "wlr"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      in
      {
        common = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        sway = wlrConf;
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
