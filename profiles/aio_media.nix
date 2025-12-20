{
  pkgs,
  lib,
  config,
  ...
}:
let
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
    torrentingPort = 63333;
    openFirewall = true;
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
          Port = 63333;
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

  services.jellyseerr = {
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

    jellyseerr = {
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
      after = [ "mnt-media.mount" ];
    };
  };

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
