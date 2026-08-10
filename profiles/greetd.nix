{
  adminUser,
  config,
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

  # Derived from the user's wayvnc settings so the greeter and the post-login
  # session can never disagree on port or keyboard layout.
  wayvncConfig = pkgs.writeText "wayvnc-greeter.conf" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value: "${key}=${toString value}"
      ) config.home-manager.users.${adminUser.name}.services.wayvnc.settings
    )
  );

  # Runs inside the greeter's Hyprland. hl.exec_cmd is fire-and-forget, so poll
  # for the output rather than assuming it exists by the time wayvnc starts.
  greeterVNC = pkgs.writeShellApplication {
    name = "greeter-vnc";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.wayvnc
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      hyprctl output create headless

      for _i in $(seq 1 30); do
        if hyprctl -j monitors | jq -e 'length > 0' >/dev/null 2>&1; then
          break
        fi
        sleep 0.5
      done

      exec wayvnc --config=${wayvncConfig} --max-fps=60 --gpu
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
    # Headless hosts have no output of their own, so give the greeter the same
    # virtual 1920x1080 the session gets and serve it over VNC.
    compositor.customConfig = lib.optionalString enableVNC ''
      hl.monitor({ ["output"] = "", ["mode"] = "1920x1080@60", ["position"] = "0x0", ["scale"] = "1" })

      hl.on("hyprland.start", function()
        hl.exec_cmd("${greeterVNC}/bin/greeter-vnc")
      end)
    '';
  };

  services.displayManager = {
    inherit defaultSession;
    sessionPackages = [ sessions ];
  };

  services.greetd.restart = true;

  systemd.services.greetd.serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/kill -SIGRTMIN+21 1";
    ExecStopPost = "${pkgs.util-linux}/bin/kill -SIGRTMIN+20 1";
  };
}
