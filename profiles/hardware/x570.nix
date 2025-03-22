{inputs, ...}: {
  imports = [
    ./amd.nix
    ./nvidia.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
  ];
}
