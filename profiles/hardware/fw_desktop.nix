{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
  ];

  environment.systemPackages = with pkgs; [
    btop-rocm
  ];
}
