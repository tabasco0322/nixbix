{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
let
  inherit (import ../../hostvars/${hostName}.nix)
    modKey
    enableVNC
    ;
  inherit (lib.generators) mkLuaInline;

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.hyprshot ];
    text = ''
      hyprshot -m region --clipboard-only
    '';
  };

  xcursor_theme = config.gtk.cursorTheme.name;
  terminal-bin = "${pkgs.alacritty}/bin/alacritty";

  # Binds are `hl.bind(key, dispatcher, opts?)`. The key is built off the `mod`
  # local emitted from settings.mod, so it stays a Lua expression rather than a
  # baked-in string.
  modKeyExpr = combo: mkLuaInline ''mod .. " + ${combo}"'';

  bind = combo: dispatcher: {
    _args = [
      (modKeyExpr combo)
      (mkLuaInline dispatcher)
    ];
  };
  bindOpts = combo: dispatcher: opts: {
    _args = [
      (modKeyExpr combo)
      (mkLuaInline dispatcher)
      opts
    ];
  };
  # Media keys carry no modifier, so the key is a plain string.
  bindBare = key: dispatcher: opts: {
    _args = [
      key
      (mkLuaInline dispatcher)
      opts
    ];
  };

  exec = cmd: "hl.dsp.exec_cmd(${builtins.toJSON cmd})";

  powerSubmap = "(p)oweroff, (s)uspend, (h)ibernate, (r)eboot, (l)ogout";

  workspaceNums = builtins.genList (x: x + 1) 9 ++ [ 10 ];

  autostart =
    if enableVNC then
      [
        "[workspace 1 silent] ${pkgs.firefox}/bin/firefox"
        "[workspace 2 silent] ${pkgs.signal-desktop}/bin/signal-desktop"
        "[workspace 2 silent] ${pkgs.telegram-desktop}/bin/Telegram"
        "[workspace 2 silent] ${pkgs.vesktop}/bin/vesktop"
      ]
    else
      [
        "[workspace 2 silent] ${pkgs.firefox}/bin/firefox"
        "[workspace 4 silent] ${pkgs.signal-desktop}/bin/signal-desktop"
        "[workspace 4 silent] ${pkgs.telegram-desktop}/bin/Telegram"
        "[workspace 4 silent] ${pkgs.spotify}/bin/spotify"
        "[workspace 5 silent] ${pkgs.steam}/bin/steam"
        "[workspace 5 silent] ${pkgs.lutris}/bin/lutris"
        "[workspace 5 silent] ${pkgs.faugus-launcher}/bin/faugus-launcher"
        "[workspace 7 silent] ${pkgs.vesktop}/bin/vesktop"
      ];

  startupCommands = [
    "${pkgs.hyprland}/bin/hyprctl setcursor ${xcursor_theme} 24"
    "${pkgs.polkit_gnome.out}/libexec/polkit-gnome-authentication-agent-1"
  ]
  ++ autostart;
in
{
  home.sessionVariables = {
    GDK_BACKEND = "wayland";
    CLUTTER_BACKEND = "wayland";
    QT_QPA_PLATFORM = "";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_WAYLAND_FORCE_DPI = "physical";
    SDL_VIDEODRIVER = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XCURSOR_THEME = xcursor_theme;
    XCURSOR_SIZE = "24";
    QT_STYLE_OVERRIDE = lib.mkForce "gtk";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    NIXOS_OZONE_WL = "1";
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 5;
        hide_cursor = true;
        no_fade_in = false;
      };
      auth = [
        {
          "fingerprint:enabled" = true;
        }
      ];
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span foreground='##660000'>"$(date +"%H:%M")"</span>"'';
          color = "rgba(102, 0, 0, 0.75)";
          font_size = 95;
          font_family = "JetBrains Mono Extrabold";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  wayland.windowManager.hyprland.enable = true;
  # Hyprland 0.56 dropped hyprlang entirely; hyprland.conf is no longer read.
  wayland.windowManager.hyprland.configType = "lua";

  # The submap name is what waybar's hyprland/submap module renders, so it
  # doubles as the on-screen key hint. Keep it verbatim.
  wayland.windowManager.hyprland.submaps.${powerSubmap} = {
    settings.bind = [
      {
        _args = [
          "P"
          (mkLuaInline (exec "systemctl poweroff"))
        ];
      }
      {
        _args = [
          "S"
          (mkLuaInline (exec "systemctl suspend-then-hibernate"))
        ];
      }
      {
        _args = [
          "H"
          (mkLuaInline (exec "systemctl hibernate"))
        ];
      }
      {
        _args = [
          "R"
          (mkLuaInline (exec "systemctl reboot"))
        ];
      }
      {
        _args = [
          "L"
          (mkLuaInline "hl.dsp.exit()")
        ];
      }
      {
        _args = [
          "escape"
          (mkLuaInline ''hl.dsp.submap("reset")'')
        ];
      }
      {
        _args = [
          "Return"
          (mkLuaInline ''hl.dsp.submap("reset")'')
        ];
      }
    ];
  };

  wayland.windowManager.hyprland.settings = {
    mod = {
      _var = modKey;
    };

    monitor =
      if enableVNC then
        [
          {
            output = "";
            mode = "1920x1080@60";
            position = "0x0";
            scale = "1";
          }
        ]
      else
        [
          {
            output = "DP-3";
            mode = "preferred";
            position = "0x0";
            scale = "1.333333";
          }
          {
            output = "DP-4";
            mode = "preferred";
            position = "-1440x0";
            scale = "1";
            transform = 1;
          }
          {
            output = "DP-5";
            mode = "preferred";
            position = "2880x0";
            scale = "1";
            transform = 3;
          }
        ];

    workspace_rule = lib.optionals (!enableVNC) [
      {
        workspace = "1";
        monitor = "DP-3";
        default = true;
      }
      {
        workspace = "3";
        monitor = "DP-3";
      }
      {
        workspace = "5";
        monitor = "DP-3";
      }
      {
        workspace = "7";
        monitor = "DP-5";
        default = true;
        layout_opts.orientation = "top";
      }
      {
        workspace = "9";
        monitor = "DP-5";
        layout_opts.orientation = "bottom";
      }
      {
        workspace = "2";
        monitor = "DP-4";
        default = true;
        layout_opts.orientation = "bottom";
      }
      {
        workspace = "4";
        monitor = "DP-4";
        layout_opts.orientation = "top";
      }
    ];

    bind = [
      (bind "Return" (exec terminal-bin))
      (bind "SHIFT + Q" "hl.dsp.window.close()")
      (bind "D" (exec "${pkgs.rofi}/bin/rofi -show drun"))
      (bind "SHIFT + S" (exec "${screenshot}/bin/screenshot"))
      (bind "I" (exec "hyprlock"))
      (bind "SHIFT + E" (exec "${pkgs.neovide}/bin/neovide"))
      (bind "escape" "hl.dsp.submap(${builtins.toJSON powerSubmap})")
      (bind "left" ''hl.dsp.focus({ direction = "l" })'')
      (bind "right" ''hl.dsp.focus({ direction = "r" })'')
      (bind "up" ''hl.dsp.focus({ direction = "u" })'')
      (bind "down" ''hl.dsp.focus({ direction = "d" })'')
      (bind "SHIFT + left" ''hl.dsp.window.move({ direction = "l", group_aware = true })'')
      (bind "SHIFT + right" ''hl.dsp.window.move({ direction = "r", group_aware = true })'')
      (bind "SHIFT + up" ''hl.dsp.window.move({ direction = "u", group_aware = true })'')
      (bind "SHIFT + down" ''hl.dsp.window.move({ direction = "d", group_aware = true })'')
      (bind "F" "hl.dsp.window.fullscreen()")
      (bind "G" "hl.dsp.group.toggle()")
      (bind "SHIFT + G" ''hl.dsp.group.lock_active({ action = "toggle" })'')
      (bind "Tab" "hl.dsp.group.next()")
      (bind "SHIFT + Tab" "hl.dsp.group.prev()")
      (bind "space" ''hl.dsp.layout("swapwithmaster")'')
      (bind "M" ''hl.dsp.workspace.move({ monitor = "+1" })'')
      (bind "SHIFT + space" ''hl.dsp.window.float({ action = "toggle" })'')
    ]
    # Workspace 10 is bound to the 0 key, the rest map onto their own digit.
    ++ (map (
      num: bind (toString (lib.mod num 10)) "hl.dsp.focus({ workspace = ${toString num} })"
    ) workspaceNums)
    ++ (map (
      num:
      bind "SHIFT + ${toString (lib.mod num 10)}" "hl.dsp.window.move({ workspace = ${toString num}, follow = false })"
    ) workspaceNums)
    ++ [
      (bindBare "XF86AudioRaiseVolume"
        (exec "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%")
        { repeating = true; }
      )
      (bindBare "XF86AudioLowerVolume"
        (exec "${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%")
        { repeating = true; }
      )
      (bindBare "XF86AudioMute" (exec "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle")
        {
          repeating = true;
        }
      )
      (bindBare "XF86MonBrightnessUp" (exec "light -A 5") { repeating = true; })
      (bindBare "XF86MonBrightnessDown" (exec "light -U 5") { repeating = true; })
      (bindOpts "mouse:272" "hl.dsp.window.drag()" { mouse = true; })
      (bindOpts "mouse:273" "hl.dsp.window.resize()" { mouse = true; })
    ];

    config = {
      xwayland = {
        force_zero_scaling = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        background_color = "0x000000";
      };

      group = {
        groupbar = {
          font_size = 12;
          gradients = false;
          "col.inactive" = "0x2E344000";
          "col.active" = "0x5E81AC00";
        };
      };

      binds = {
        workspace_back_and_forth = true;
        allow_workspace_cycles = true;
      };

      animations = {
        enabled = true;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 7;
          passes = 4;
          xray = true;
          ignore_opacity = false;
          new_optimizations = true;
          noise = 0.02;
          contrast = 1.05;
          brightness = 1.3;
        };
        shadow = {
          enabled = true;
          range = 20;
          render_power = 2;
          color = "0x99000000";
          color_inactive = "0x55000000";
        };
      };

      general = {
        layout = "master";
        border_size = 0;
        gaps_in = 2;
        gaps_out = 0;
        col.active_border = "0x36393Eaa";
      };

      master = {
        new_status = "master";
        orientation = "right";
        mfact = 0.7;
      };

      input = {
        kb_layout = "us";
        kb_options = "compose:ralt";

        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          # Lua normalizes registered option names, so hyphens become
          # underscores: input:touchpad:tap-to-click -> tap_to_click.
          tap_to_click = true;
        };
      };

      ecosystem = {
        no_donation_nag = true;
        no_update_news = true;
      };
    };

    animation = [
      {
        leaf = "workspaces";
        enabled = true;
        speed = 2;
        bezier = "default";
      }
      {
        leaf = "windows";
        enabled = true;
        speed = 1;
        bezier = "default";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 3;
        bezier = "default";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 1;
        bezier = "default";
      }
      {
        leaf = "borderangle";
        enabled = true;
        speed = 1;
        bezier = "default";
      }
    ];

    layer_rule = [
      {
        name = "waybar-no-blur";
        match.namespace = "waybar";
        blur = false;
      }
    ];

    window_rule = [
      {
        name = "gitui-float";
        match.class = "gitui";
        dim_around = true;
        float = true;
        size = "60% 60%";
        center = true;
      }
      {
        name = "open-file-float";
        match.title = "Open File";
        dim_around = true;
        float = true;
        center = true;
      }
    ];

    on = [
      {
        _args = [
          "hyprland.start"
          (mkLuaInline ''
            function()
            ${lib.concatMapStrings (cmd: "  hl.exec_cmd(${builtins.toJSON cmd})\n") startupCommands}end'')
        ];
      }
    ];
  };
}
