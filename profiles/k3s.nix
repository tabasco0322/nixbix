{
  hostName,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../profiles/tailscale.nix
  ];

  networking.firewall = {
    trustedInterfaces = [
      "lo"
      "cilium_host"
      "cilium_net"
      "cilium_vxlan"
      "lxc+"
    ];
  };

  # Cilium marks pod traffic with fwmark (identity<<16 | magic), e.g. 0xf00 for
  # identity and 0x400 for overlay. Identities with low byte 0x08 set bit 0x80000,
  # which Tailscale's rules (5210-5250) treat as its own bypass mark and route via
  # main, so VXLAN to other nodes leaves the LAN NIC instead of tailscale0. Look up
  # table 52 first for Cilium-marked traffic and anything to tailnet addresses
  # (Tailscale's own bypass traffic goes to public IPs); lookups with no match
  # there fall through to the normal rules.
  systemd.services.cilium-tailscale-fwmark =
    let
      rules = [
        "priority 5200 fwmark 0xf00/0xf00 lookup 52"
        "priority 5200 to 100.64.0.0/10 lookup 52"
      ];
      forRules = cmd: lib.concatMapStringsSep "\n" (rule: cmd rule) rules;
    in
    {
      description = "Route Cilium-marked traffic via Tailscale table";
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      before = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = forRules (rule: ''
        ip rule del ${rule} 2>/dev/null || true
        ip rule add ${rule}
      '');
      preStop = forRules (rule: ''
        ip rule del ${rule} 2>/dev/null || true
      '');
    };

  systemd.services.metadata =
    let
      cloudInitScript = pkgs.writeShellScript "cloud-init" ''
        mkdir -p /run/nixos
        touch /run/nixos/metadata
        cat<<META>/run/nixos/metadata
        NODENAME=${hostName}
        REGION=se
        ZONE=se-a
        META
      '';
    in
    {
      description = "Metadata Service";
      after = [ "network.target" ];
      before = [
        "k3s.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cloudInitScript;
      };
    };

  services.k3s = {
    enable = true;
    serverAddr = "https://nixbox.tail754457.ts.net:6443";
    tokenFile = "/run/agenix/k3s-token";
    after = [
      "tailscale-auth.service"
      "metadata.service"
    ];
    settings = {
      node-name = hostName;
      node-ip = "\"$(get-iface-ip tailscale0)\"";
      node-external-ip = "\"$(get-default-route-ip)\"";
      node-label."topology.kubernetes.io/region" = "\"$REGION\"";
      node-label."topology.kubernetes.io/zone" = "\"$ZONE\"";
      node-label."hostname" = hostName;
      kubelet-arg = "register-with-taints=node.cilium.io/agent-not-ready:NoExecute";
    };
  };

  services.tailscale.auth = {
    enable = true;
    args.advertise-tags = [ "tag:server" ];
    args.ssh = true;
    args.accept-routes = false;
    args.accept-dns = true;
    args.auth-key = "file:/var/run/agenix/ts";
  };

  environment.persistence."/keep" = {
    directories = [
      "/etc/cni"
      "/etc/rancher"
      "/var/lib/cni"
      "/var/lib/containerd"
      "/var/lib/dockershim"
      "/var/lib/kubelet"
      "/var/lib/rancher"
    ];
  };

  # fileSystems."/mnt/persistentvolume" = {
  #   device = "storage01:/volume1/persistentvolume";
  #   fsType = "nfs";
  # };
}
