{
  hostName,
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib // builtins)
    attrNames
    hasAttr
    mkIf
    length
    ;
  hasState =
    hasAttr "persistence" config.environment && (length (attrNames config.environment.persistence)) > 0;
  hasSecrets = config.age.secrets != { };
in
{
  nix = {
    settings.trusted-users = [ "root" ];
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      tarball-ttl = 900
    '';

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    package = pkgs.nix;
  };

  environment.systemPackages = [
    pkgs.binutils
    pkgs.blueman
    pkgs.bmon
    pkgs.bottom
    pkgs.bridge-utils
    pkgs.cacert
    pkgs.curl
    pkgs.fd
    pkgs.file
    pkgs.fish
    pkgs.git
    pkgs.gnupg
    pkgs.btop
    pkgs.hyperfine
    pkgs.iftop
    pkgs.iptables
    pkgs.jq
    pkgs.lsof
    pkgs.man-pages
    pkgs.mkpasswd
    pkgs.nmap
    pkgs.openssl
    pkgs.pavucontrol
    pkgs.pciutils
    pkgs.powertop
    pkgs.procs
    pkgs.psmisc
    pkgs.ripgrep
    pkgs.sd
    pkgs.socat
    pkgs.tmux
    pkgs.tree
    pkgs.unzip
    pkgs.usbutils
    pkgs.vim
    pkgs.wget
    pkgs.zip
  ];

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Europe/Stockholm";

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "524288";
    }
  ];

  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];

  programs.fish.enable = true;

  programs.command-not-found.dbPath = "${./..}/programs.sqlite";

  security.sudo.extraConfig = ''
    Defaults  lecture="never"
  '';

  networking = {
    firewall.enable = true;
    inherit hostName;
  };

  services.sshguard.enable = true;
  services.fstrim.enable = true;

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=90
  '';

  users.mutableUsers = false;

  system.stateVersion = "24.05";

  system.activationScripts.agenixNewGeneration = mkIf (hasSecrets && hasState) {
    deps = [ "persist-files" ];
  };

  services.nix-dirs.enable = true;
}
