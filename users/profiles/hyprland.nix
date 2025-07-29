{
  config,
  lib,
  pkgs,
  ...
}:
let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = [ pkgs.hyprshot ];
    text = ''
      hyprshot -m region --clipboard-only
    '';
  };

  xcursor_theme = config.gtk.cursorTheme.name;
  terminal-bin = "${pkgs.alacritty}/bin/alacritty";
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
          text = ''cmd[update:1000] echo "<span foreground='##660000'>"$(date +"%-H:%M")"</span>"'';
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
  wayland.windowManager.hyprland.extraConfig = ''
    bind=$mod,escape,submap,(p)oweroff, (s)uspend, (h)ibernate, (r)eboot, (l)ogout
    submap=(p)oweroff, (s)uspend, (h)ibernate, (r)eboot, (l)ogout

    bind=,p,exec,systemctl poweroff
    bind=,p,submap,reset

    bind=,s,exec,systemctl suspend-then-hibernate
    bind=,s,submap,reset

    bind=,h,exec,systemctl hibernate
    bind=,h,submap,reset

    bind=,r,exec,systemctl reboot
    bind=,r,submap,reset

    bind=,l,exit
    bind=,l,submap,reset

    bind=,escape,submap,reset
    bind=,return,submap,reset
    submap=reset

    workspace=1,monitor:DP-3,default:true
    workspace=3,monitor:DP-3
    workspace=5,monitor:DP-3

    workspace=7,monitor:DP-5,default:true,layoutopt:orientation:top
    workspace=9,monitor:DP-5,layoutopt:orientation:bottom

    workspace=2,monitor:DP-4,default:true,layoutopt:orientation:bottom
    workspace=4,monitor:DP-4,layoutopt:orientation:top
  '';

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-4, 2560x1440@144.000, 0x0, 1, transform, 1"
      "DP-3, 3840x2160@240.000, 1440x0, 1"
      "DP-5, 2560x1440@144.000, 5280x0, 1, transform, 3"
    ];
    "$mod" = "SUPER";
    bind =
      [
        "$mod, Return, exec, ${terminal-bin}"
        "$mod SHIFT, q, killactive"
        "$mod, d, exec, ${pkgs.rofi-wayland}/bin/rofi -show drun"
        "$mod SHIFT, s, exec, ${screenshot}/bin/screenshot"
        "$mod, i, exec, hyprlock"
        "$mod SHIFT, e, exec, ${pkgs.neovide}/bin/neovide"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod SHIFT, left, movewindoworgroup, l"
        "$mod SHIFT, right, movewindoworgroup, r"
        "$mod SHIFT, up, movewindoworgroup, u"
        "$mod SHIFT, down, movewindoworgroup, d"
        "$mod, f, fullscreen"
        "$mod, g, togglegroup"
        "$mod SHIFT, g, lockactivegroup, toggle"
        "$mod, Tab, changegroupactive, f"
        "$mod SHIFT, Tab, changegroupactive, b"
        "$mod, space, layoutmsg, swapwithmaster"
        "$mod, m, movecurrentworkspacetomonitor, +1"
        "$mod SHIFT, space, togglefloating"
      ]
      ++ (map (num: "$mod, ${num}, workspace, ${num}") (
        builtins.genList (x: builtins.toString (x + 1)) 9
      ))
      ++ (map (num: "$mod SHIFT, ${num}, movetoworkspacesilent, ${num}") (
        builtins.genList (x: builtins.toString (x + 1)) 9
      ))
      ++ [
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 0, movetoworkspacesilent, 10"
      ];

    binde = [
      ", XF86AudioRaiseVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ", XF86AudioLowerVolume, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%"
      ", XF86AudioMute, exec, ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle"
      ", XF86MonBrightnessUp, exec, light -A 5"
      ", XF86MonBrightnessDown, exec, light -U 5"
    ];

    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    misc.disable_hyprland_logo = true;
    misc.disable_splash_rendering = true;

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
      animation = [
        "workspaces,1,2,default"
        "windows,1,1,default"
        "fade,1,3,default"
        "border,1,1,default"
        "borderangle,1,1,default"
      ];
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
      # drop_shadow = false;
      # shadow_range = 20;
      # shadow_render_power = 2;
      # shadow_offset = "3 3";
      # "col.shadow" = "0x99000000";
      # "col.shadow_inactive" = "0x55000000";
      active_opacity = 0.95;
      inactive_opacity = 0.85;
      fullscreen_opacity = 1.0;
    };

    general = {
      layout = "master";
      border_size = 0;
      gaps_in = 2;
      gaps_out = 0;
      "col.active_border" = "0x36393Eaa";
    };

    master = {
      new_status = "master";
      orientation = "right";
      mfact = 0.7;
    };

    layerrule = [
      "blur,waybar"
      "ignorealpha,waybar"
    ];

    input = {
      kb_layout = "us";
      #kb_variant = "colemak";
      kb_options = "compose:ralt";

      follow_mouse = 1;

      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        tap-to-click = true;
      };
    };

    ecosystem = {
      no_donation_nag = true;
      no_update_news = true;
    };

    windowrulev2 = [
      "dimaround,class:gitui"
      "float,class:gitui"
      "size 60% 60%,class:gitui"
      "center,class:gitui"
      "dimaround,class:chrome-nngceckbapebfimnlniiiahkandclblb-Default"
      "float,class:chrome-nngceckbapebfimnlniiiahkandclblb-Default"
      "size 60% 60%,class:chrome-nngceckbapebfimnlniiiahkandclblb-Default"
      "center,class:chrome-nngceckbapebfimnlniiiahkandclblb-Default"
      "dimaround,title:Open File"
      "float,title:Open File"
      "center,title:Open File"
    ];

    exec = [
      # "${pkgs.kanshi}/bin/kanshi"
    ];

    exec-once = [
      "${pkgs.wpaperd}/bin/wpaperd"
      "${pkgs.hyprland}/bin/hyprctl setcursor ${xcursor_theme} 24"
      "${pkgs.polkit_gnome.out}/libexec/polkit-gnome-authentication-agent-1"
      "[workspace 2 silent] ${pkgs.firefox}/bin/firefox"
      "[workspace 4 silent] ${pkgs.signal-desktop}/bin/signal-desktop"
      "[workspace 4 silent] ${pkgs.tdesktop}/bin/Telegram"
      "[workspace 4 silent] ${pkgs.spotify}/bin/spotify"
      "[workspace 5 silent] ${pkgs.steam}/bin/steam"
      "[workspace 5 silent] ${pkgs.lutris}/bin/lutris"
      "[workspace 7 silent] ${pkgs.vesktop}/bin/vesktop"
    ];
  };
}
