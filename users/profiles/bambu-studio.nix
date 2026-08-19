{ pkgs, osConfig, ... }:
{
  home.packages = [
    (pkgs.bambu-studio.override {
      # 3D viewport is blank on the NVIDIA proprietary GL stack; this routes
      # rendering through Mesa + zink instead.
      # https://github.com/NixOS/nixpkgs/issues/498311
      withNvidiaGLWorkaround = builtins.elem "nvidia" osConfig.services.xserver.videoDrivers;
    })
  ];
}
