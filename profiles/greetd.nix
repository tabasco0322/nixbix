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

  # VNC wrapper: starts Hyprland, waits for its socket, creates a headless
  # output, launches wayvnc, then waits on Hyprland so greetd tracks the
  # session lifetime correctly.
  runHyprlandVNC = pkgs.writeShellApplication {
    name = "HyprlandVNC";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.wayvnc
      pkgs.jq
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

      # Start Hyprland in the background
      start-hyprland &
      HYPRLAND_PID=$!

      # Wait for the Hyprland IPC socket to appear
      INSTANCE_DIR=""
      for _i in $(seq 1 30); do
        INSTANCE_DIR=$(find "$XDG_RUNTIME_DIR/hypr/" -maxdepth 1 -mindepth 1 -type d -newer "/proc/$HYPRLAND_PID" 2>/dev/null | head -1 || true)
        if [ -n "$INSTANCE_DIR" ] && [ -e "$INSTANCE_DIR/.socket.sock" ]; then
          break
        fi
        INSTANCE_DIR=""
        sleep 0.5
      done

      if [ -z "$INSTANCE_DIR" ]; then
        echo "ERROR: Hyprland socket did not appear within 15s" >&2
        kill "$HYPRLAND_PID" 2>/dev/null || true
        exit 1
      fi

      export HYPRLAND_INSTANCE_SIGNATURE
      HYPRLAND_INSTANCE_SIGNATURE=$(basename "$INSTANCE_DIR")

      # Discover WAYLAND_DISPLAY for wayvnc
      WAYLAND_DISPLAY=""
      for _i in $(seq 1 10); do
        for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
          case "$sock" in
            *.lock) continue ;;
          esac
          if [ -e "$sock" ]; then
            WAYLAND_DISPLAY=$(basename "$sock")
            break
          fi
        done
        [ -n "$WAYLAND_DISPLAY" ] && break
        sleep 0.5
      done
      export WAYLAND_DISPLAY

      if [ -z "$WAYLAND_DISPLAY" ]; then
        echo "ERROR: WAYLAND_DISPLAY not found" >&2
        kill "$HYPRLAND_PID" 2>/dev/null || true
        exit 1
      fi

      # Create a headless output if none exists
      existing=$(hyprctl monitors -j | jq -r '[.[] | select(.name | startswith("HEADLESS-"))][0].name // empty')
      if [ -z "$existing" ]; then
        hyprctl output create headless
        sleep 1
        existing=$(hyprctl monitors -j | jq -r '[.[] | select(.name | startswith("HEADLESS-"))][0].name // empty')
      fi

      if [ -z "$existing" ]; then
        echo "ERROR: Failed to get a headless monitor" >&2
        kill "$HYPRLAND_PID" 2>/dev/null || true
        exit 1
      fi

      # Launch wayvnc in the background bound to the headless output
      wayvnc --gpu --max-fps=60 --render-cursor -o "$existing" &

      # Wait on Hyprland so greetd tracks session lifetime
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
      curser_theme_name = lib.mkForce "Nordzy-cursors";
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
