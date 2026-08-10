{
  adminUser,
  inputs,
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

  # dms-greeter resolves autologin by reading Exec= out of the chosen session's
  # desktop file, so HyprlandVNC has to exist as a session of its own.
  sessions =
    pkgs.runCommand "nixbix-wayland-sessions"
      {
        passthru.providedSessions = [
          "Hyprland"
          "HyprlandVNC"
          "nushell"
          "bash"
        ];
      }
      ''
        mkdir -p "$out/share/wayland-sessions"
        ln -s ${desktopSession "Hyprland" "${runHyprland}/bin/Hyprland"} "$out/share/wayland-sessions/Hyprland.desktop"
        ln -s ${desktopSession "HyprlandVNC" "${runHyprlandVNC}/bin/HyprlandVNC"} "$out/share/wayland-sessions/HyprlandVNC.desktop"
        ln -s ${desktopSession "nushell" "${pkgs.nushell}/bin/nu"} "$out/share/wayland-sessions/nushell.desktop"
        ln -s ${desktopSession "bash" "${pkgs.bashInteractive}/bin/bash"} "$out/share/wayland-sessions/bash.desktop"
      '';

  defaultSession = if enableVNC then "HyprlandVNC" else "Hyprland";
in
{
  imports = [ inputs.dank-greeter.nixosModules.default ];

  programs.dms-greeter = {
    enable = true;
    package = inputs.dank-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
    compositor.name = "hyprland";
    configHome = "/home/${adminUser.name}";
  };

  services.displayManager = {
    inherit defaultSession;
    sessionPackages = [ sessions ];
    autoLogin = lib.mkIf enableVNC {
      enable = true;
      user = adminUser.name;
    };
  };

  services.greetd.restart = true;

  systemd.services.greetd.serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/kill -SIGRTMIN+21 1";
    ExecStopPost = "${pkgs.util-linux}/bin/kill -SIGRTMIN+20 1";
  };
}
