{
  pkgs,
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    # RTX 5090 (Blackwell) needs a recent driver; `beta` (595.x) fails to build
    # against linuxPackages_latest (kernel 7.0). `latest` tracks the newest packaged driver.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  #boot.initrd.kernelModules = [ "nvidia" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  environment.systemPackages = with pkgs; [
    btop-cuda
  ];
}
