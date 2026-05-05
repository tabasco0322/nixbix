{
  pkgs,
  lib,
  config,
  ...
}:
let
  webuiPort = 8080;
  netnsPath = "/var/run/netns/private";
  qbWebUIUser = "admin";
  qbPasswordFile = "/run/agenix/qb-webui-password";
  acmehosts = [
    {
      domain = "fin.cronge.ai";
      port = 8096;
    }
    {
      domain = "jelly.cronge.ai";
      port = 8096;
    }
    {
      domain = "qb.cronge.ai";
      port = 8080;
    }
    {
      domain = "son.cronge.ai";
      port = 8989;
    }
    {
      domain = "rad.cronge.ai";
      port = 7878;
    }
    {
      domain = "prwl.cronge.ai";
      port = 9696;
    }
    {
      domain = "flr.cronge.ai";
      port = 8191;
    }
    {
      domain = "seer.cronge.ai";
      port = 5055;
    }
    {
      domain = "over.cronge.ai";
      port = 5055;
    }
  ];
in
{

  users = {
    users = {
      media = {
        isNormalUser = true;
        uid = 1110;
        description = "User for media server related applications";
        group = "media";
      };
    };
    groups = {
      media = {
        gid = 1110;
      };
    };
  };

  services.qbittorrent = {
    enable = true;
    inherit webuiPort;
    torrentingPort = null;
    openFirewall = false;
    user = "media";
    group = "media";
    serverConfig = {
      LegalNotice.Accepted = true;
      Application = {
        FileLogger = {
          Age = 1;
          AgeType = 1;
          Backup = true;
          DeleteOld = true;
          Enabled = true;
          MaxSizeBytes = 66560;
          Path = "/var/lib/qBittorrent/qBittorrent/data/logs";
        };
      };
      BitTorrent = {
        Session = {
          AddTorrentStopped = "false";
          DefaultSavePath = "/mnt/media/qb/downloads";
          ExcludedFileNames = "";
          GlobalDLSpeedLimit = 25000;
          MaxActiveDownloads = 5;
          MaxActiveTorrents = 500;
          MaxActiveUploads = 500;
          MaxConnections = 1000;
          MaxConnectionsPerTorrent = 200;
          MaxUploads = 40;
          MaxUploadsPerTorrent = 10;
          # Placeholder; natpmp-forward overwrites listen_port via the Web API once
          # Proton grants a lease. Explicit value avoids a random-port window before
          # the first refresh.
          Port = 6881;
          UseRandomPort = false;
          UseNATForwarding = false;
          QueueingSystemEnabled = true;
          ShareLimitAction = "Stop";
          TempPath = "/mnt/media/qb/temp";
          TempPathEnabled = true;
          TorrentExportDirectory = "/mnt/media/qb/torrents";
        };
      };
      Core = {
        AutoDeleteAddedTorrentFile = "Never";
      };
      Meta = {
        MigrationVersion = 8;
      };
      Network = {
        PortForwardingEnabled = false;
      };
      Preferences = {
        General = {
          Locale = "en";
        };
        MailNotification = {
          req_auth = true;
        };
        WebUI = {
          Username = "admin";
          Password_PBKDF2 = "@ByteArray(yJZO1x0imoPCwWQIrjkRBQ==:pLI8ONQ2sr+Wk5AKHx4zMpyxZN2BWrsMBcu4qQ0kN6LuwqHiCuylSGZw8hc27IIqhmFepNjZL5sRlsU+y4UNsA==)";
        };
      };
      RSS = {
        AutoDownloader = {
          DownloadRepacks = false;
          SmartEpisodeFilter = "";
        };
      };
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
  };

  environment.systemPackages = with pkgs; [
    jellyfin-ffmpeg
  ];

  services.seerr = {
    enable = true;
  };

  services.sonarr = {
    enable = true;
    user = "media";
    group = "media";
  };

  services.radarr = {
    enable = true;
    user = "media";
    group = "media";
  };

  services.prowlarr = {
    enable = true;
  };

  services.flaresolverr = {
    enable = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "wiro1037@gmail.com";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      environmentFile = "/run/agenix/acme-cf";
      reloadServices = [ "caddy" ];
    };

    certs = builtins.listToAttrs (
      map (h: {
        name = h.domain;
        value = {
          inherit (config.services.caddy) group;
          domain = "${h.domain}";
        };
      }) acmehosts
    );
  };

  services.caddy = {
    enable = true;
    virtualHosts = builtins.listToAttrs (
      map (h: {
        name = h.domain;
        value = {
          extraConfig = ''
            reverse_proxy http://localhost:${toString h.port}
            tls /var/lib/acme/${h.domain}/cert.pem /var/lib/acme/${h.domain}/key.pem {
              protocols tls1.3
            }
          '';
        };
      }) acmehosts
    );
  };

  systemd.services = {
    jellyfin = {
      after = [ "mnt-media.mount" ];
    };

    seerr = {
      after = [ "mnt-media.mount" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "media";
        Group = "media";
      };
    };

    prowlarr = {
      after = [ "mnt-media.mount" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        StateDirectory = lib.mkForce null;
        User = "media";
        Group = "media";
      };
    };

    radarr = {
      after = [ "mnt-media.mount" ];
    };

    sonarr = {
      after = [ "mnt-media.mount" ];
    };

    qbittorrent = {
      bindsTo = [ "wireguard-private.service" ];
      after = [
        "wireguard-private.service"
        "mnt-media.mount"
      ];
      serviceConfig = {
        NetworkNamespacePath = netnsPath;
        BindReadOnlyPaths = [
          netnsPath
          "/etc/netns/private/resolv.conf:/etc/resolv.conf"
        ];
      };
    };

    # Bridge the host's WebUI port to qBittorrent inside the private netns.
    # Outer socat runs in the root netns (listens on all interfaces so LAN clients
    # and the Caddy reverse proxy can reach it); inner socat is re-executed per
    # connection via nsenter into the private netns.
    qbittorrent-forwarder = {
      description = "Forward qBittorrent WebUI from host to private netns";
      after = [ "qbittorrent.service" ];
      bindsTo = [ "qbittorrent.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${pkgs.socat}/bin/socat tcp-listen:${toString webuiPort},fork,reuseaddr exec:'${pkgs.util-linux}/bin/nsenter --net=${netnsPath} ${pkgs.socat}/bin/socat STDIO "tcp-connect:127.0.0.1:${toString webuiPort}"',nofork
      '';
    };

    natpmp-forward = {
      description = "Refresh Proton VPN NAT-PMP port lease and push it to qBittorrent";
      bindsTo = [
        "wireguard-private.service"
        "qbittorrent.service"
      ];
      after = [
        "wireguard-private.service"
        "qbittorrent.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.libnatpmp
        pkgs.curl
        pkgs.gawk
        pkgs.coreutils
      ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "10s";
        NetworkNamespacePath = netnsPath;
        RuntimeDirectory = "natpmp-forward";
        RuntimeDirectoryMode = "0700";
        BindReadOnlyPaths = [
          netnsPath
          "/etc/netns/private/resolv.conf:/etc/resolv.conf"
          "${qbPasswordFile}:${qbPasswordFile}"
        ];
      };
      script = ''
        set -u
        cookie_jar="$RUNTIME_DIRECTORY/cookies.txt"
        webui="http://127.0.0.1:${toString webuiPort}"

        qb_login() {
          rm -f "$cookie_jar"
          local pw
          pw=$(tr -d '\n' < "${qbPasswordFile}")
          local resp
          resp=$(curl -fsS -c "$cookie_jar" -X POST \
            "$webui/api/v2/auth/login" \
            --header "Referer: $webui" \
            --data-urlencode "username=${qbWebUIUser}" \
            --data-urlencode "password=$pw") || return 1
          [ "$resp" = "Ok." ]
        }

        qb_set_port() {
          curl -fsS -b "$cookie_jar" -X POST \
            "$webui/api/v2/app/setPreferences" \
            --header "Referer: $webui" \
            --data-urlencode "json={\"listen_port\":$1,\"random_port\":false,\"upnp\":false}"
        }

        qb_login || echo "initial login failed; will retry on first port change"

        last_port=""
        while :; do
          if ! out=$(natpmpc -a 1 0 udp 60 -g 10.2.0.1 && natpmpc -a 1 0 tcp 60 -g 10.2.0.1); then
            echo "natpmpc failed; retrying in 5s"
            sleep 5
            continue
          fi
          port=$(echo "$out" | awk '/Mapped public port/ {print $4; exit}')
          if [ -n "$port" ] && [ "$port" != "$last_port" ]; then
            echo "Updating qBittorrent listen_port: ''${last_port:-unset} -> $port"
            if qb_set_port "$port" || (qb_login && qb_set_port "$port"); then
              last_port=$port
            else
              echo "qBittorrent API update failed; will retry"
            fi
          fi
          sleep 45
        done
      '';
    };
  };

  # Per-netns resolv.conf for services pinned via NetworkNamespacePath.
  # systemd does not bind-mount /etc/netns/<ns>/resolv.conf the way
  # `ip netns exec` does, so sandboxed services inherit the host resolver —
  # which is usually unreachable from inside the VPN netns. Point at the
  # VPN's in-tunnel resolver instead (10.2.0.1 for Proton).
  environment.etc."netns/private/resolv.conf".text = ''
    nameserver 10.2.0.1
  '';

  networking.firewall.allowedTCPPorts = [ webuiPort ];

  environment.persistence."/keep" = {
    hideMounts = true;
    directories = [
      "/var/lib/acme"
      "/var/lib/caddy"
      "/var/lib/jellyfin"
      "/var/cache/jellyfin/" # transcoding hurts
      "/var/lib/jellyseerr"
      "/var/lib/prowlarr"
      "/var/lib/radarr"
      "/var/lib/sonarr"
      "/var/lib/qBittorrent"
    ];
  };
}
