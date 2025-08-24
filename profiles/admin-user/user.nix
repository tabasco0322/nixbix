{
  adminUser,
  pkgs,
  ...
}:
{
  nix.settings.trusted-users = [ adminUser.name ];
  users = {
    users.${adminUser.name} = {
      inherit (adminUser) uid;
      shell = pkgs.fish;
      isNormalUser = true;
      hashedPassword = "$y$j9T$0xLNGg.oTsEj2CyRu3SCZ/$Y9reP3QJWI2rWkuYpYdHoDUVdazAp4RxA6xhiKATuz0";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5F3BVlkYb6CimwNHkKxMC+FvoLLbhBEPtJEa31BLxq"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOu2XRGagRGIG7uCvcwhsDkB4YtoXqMIcKhXFK1pW8Nr"
      ];
      extraGroups = [
        "wheel"
        "docker"
        "video"
        "audio"
        "kvm"
        "libvirtd"
        "podman"
      ];
    };
  };
}
