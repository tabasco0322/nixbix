{
  imports = [
    ./home.nix
    ./host-config.nix
    ./k3s.nix
    ./private-wireguard.nix
    ./services.nix
    ./tailscale-auth.nix
  ];
}
