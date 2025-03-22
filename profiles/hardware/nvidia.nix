{
  config,
  ...
}: 
{
  hardware.graphics = {
    enable = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
  };

  #boot.initrd.kernelModules = [ "nvidia" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
}
