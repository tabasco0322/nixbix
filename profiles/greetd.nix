{
  adminUser,
  pkgs,
  lib,
  hostName,
  ...
}:
let
  inherit (import ../hostvars/${hostName}.nix)
    enableVNC
    ;
  runViaSystemdCat =
    {
      name,
      cmd,
      systemdSession,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        trap 'systemctl --user stop ${systemdSession} || true' EXIT
        exec ${pkgs.systemd}/bin/systemd-cat --identifier=${name} ${cmd}
      '';
    };

  runViaShell =
    {
      env ? { },
      sourceHmVars ? true,
      viaSystemdCat ? true,
      name,
      cmd,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}
        ${
          if sourceHmVars then
            ''
              if [ -e /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh ]; then
                set +u
                # shellcheck disable=SC1090
                source /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh
                set -u
              fi
            ''
          else
            ""
        }
        ${
          if viaSystemdCat then
            ''
              exec ${
                runViaSystemdCat {
                  inherit name cmd;
                  systemdSession = "${lib.toLower name}-session.target";
                }
              }/bin/${name}
            ''
          else
            ''
              exec ${cmd}
            ''
        }
      '';
    };

  runHyprland = runViaShell {
    env = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };
    name = "Hyprland";
    cmd = "${pkgs.hyprland}/bin/start-hyprland";
  };

  # VNC session: starts Hyprland headlessly and creates a virtual output.
  # wayvnc is managed by home-manager's services.wayvnc systemd user service,
  # which auto-starts once hyprland-session.target is reached (triggered by
  # Hyprland's exec-once after the headless output exists).
  runHyprlandVNC = pkgs.writeShellApplication {
    name = "HyprlandVNC";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      export XDG_SESSION_TYPE="wayland"
      export XDG_CURRENT_DESKTOP="Hyprland"
      export XDG_SESSION_DESKTOP="Hyprland"

      if [ -e /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh ]; then
        set +u
        # shellcheck disable=SC1090
        source /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh
        set -u
      fi

      XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export XDG_RUNTIME_DIR

      start-hyprland &
      HYPRLAND_PID=$!

      # Wait for Hyprland socket, then create headless output
      for _i in $(seq 1 30); do
        SOCKET=$(find "$XDG_RUNTIME_DIR/hypr/" -name ".socket.sock" -newer "/proc/$HYPRLAND_PID" 2>/dev/null | head -1 || true)
        if [ -n "$SOCKET" ]; then
          export HYPRLAND_INSTANCE_SIGNATURE
          HYPRLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$SOCKET")")
          hyprctl output create headless
          break
        fi
        sleep 0.5
      done

      wait "$HYPRLAND_PID"
    '';
  };

  desktopSession =
    name: command:
    pkgs.writeText "${name}.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=${name}
      Exec=${command}
    '';

  sessions = [
    {
      name = "Hyprland.desktop";
      path = desktopSession "Hyprland" "${runHyprland}/bin/Hyprland";
    }
    {
      name = "nushell.desktop";
      path = desktopSession "nushell" "${pkgs.nushell}/bin/nu";
    }
    {
      name = "bash.desktop";
      path = desktopSession "bash" "${pkgs.bashInteractive}/bin/bash";
    }
  ];

  createGreeter =
    default: sessions:
    let
      sessionDir = pkgs.linkFarm "sessions" (
        builtins.filter (item: item.name != "${default}.desktop") sessions
      );
    in
    pkgs.writeShellApplication {
      name = "greeter";
      runtimeInputs = [
        runHyprland
        pkgs.bashInteractive
        pkgs.nushell
        pkgs.systemd
        pkgs.tuigreet
      ];
      text = ''
        tuigreet --sessions ${sessionDir} --time -r --remember-session --power-shutdown 'systemctl poweroff' --power-reboot 'systemctl reboot' --cmd ${default}
      '';
    };
in
{
  programs.regreet.enable = true;

  environment.systemPackages = [
    pkgs.nordic
    pkgs.nordzy-cursor-theme
    pkgs.arc-icon-theme
  ];

  programs.regreet.settings = {
    commands = {
      reboot = [
        "systemctl"
        "reboot"
      ];
      poweroff = [
        "systemctl"
        "poweroff"
      ];
    };
    appearance = {
      greeting_msg = "Welcome back!";
    };
    GTK = {
      cursor_theme_name = lib.mkForce "Nordzy-cursors";
      font_name = lib.mkForce "Roboto Medium 14";
      icon_theme_name = lib.mkForce "Nordzy-dark";
      theme_name = lib.mkForce "Nordic-darker";
      application_prefer_dark_theme = lib.mkForce true;
    };
  };

  services.greetd = {
    enable = true;
    restart = true;
    settings = {
      initial_session = lib.mkIf enableVNC {
        user = "${adminUser.name}";
        command = "${runHyprlandVNC}/bin/HyprlandVNC";
      };
      default_session.command = "${createGreeter "${runHyprland}/bin/Hyprland" sessions}/bin/greeter";
    };
  };
  systemd.services.greetd.serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/kill -SIGRTMIN+21 1";
    ExecStopPost = "${pkgs.util-linux}/bin/kill -SIGRTMIN+20 1";
  };
}
