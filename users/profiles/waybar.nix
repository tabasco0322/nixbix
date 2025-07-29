{ lib, ... }:
{
  programs.waybar.enable = true;
  programs.waybar.settings.topBar = {
    bar_id = "top";
    ipc = true;
    position = "top";
    modules-left = [
      "hyprland/workspaces"
      "sway/workspaces"
      "sway/mode"
      "hyprland/submap"
    ];
    # modules-center = ["hyprland/window"];
    modules-right = [
      "custom/gpu_powerdraw"
      "network"
      "network#wifi"
      "memory"
      "cpu"
      "temperature"
      "idle_inhibitor"
      "pulseaudio"
      "blacklight"
      "battery"
      "clock"
      "tray"
    ];
    "sway/workspaces" = {
      disable-scroll-wraparound = true;
    };
    "hyprland/workspaces" = {
      format = "{id}";
      on-scroll-up = "hyprctl dispatch workspace e-1";
      on-scroll-down = "hyprctl dispatch workspace e+1";
      all-outputs = false;
    };
    "hyprland/submap" = {
      format = "✌️ {}";
      tooltip = false;
    };
    "custom/gpu_powerdraw" = {
      format = "🥵 {text}W ";
      exec = "nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits";
      interval = 5;
    };
    network = {
      interface = lib.mkDefault "enp*";
      format-ethernet = " {bandwidthDownBits:>}  {bandwidthUpBits:>} {ipaddr} ";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "";
      format-alt = "{ifname}: {ipaddr}";
      interval = 1;
    };
    "network#wifi" = {
      interface = lib.mkDefault "wlan*";
      format-wifi = " {essid} {signalStrength}% {ipaddr} {bandwidthDownBits:>} {bandwidthUpBits:>}";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "";
      format-alt = "{ifname}: {ipaddr}";
      interval = 1;
    };
    memory = {
      format = "{used:0.1f}G ";
    };
    cpu = {
      format = "{}% ";
    };
    temperature = {
      format = "{temperatureC}°C ";
    };
    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };
    pulseaudio = {
      format = "{volume}% {icon}";
      format-bluetooth = "{volume}% {icon}";
      format-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [
          ""
          ""
        ];
      };
      scroll-step = 1;
      ignored-sinks = [
        "Easy Effects Sink"
        "SteelSeries Arctis 7 Chat"
      ];
    };
    clock = {
      format = "{:%F %H:%M}";
    };
  };
  programs.waybar.systemd.enable = true;
  programs.waybar.style = ''
    * {
      border: none;
      border-radius: 0;
      font-family: "Roboto Mono, Font Awesome 5 Free, Font Awesome 5 Brands, Arial, sans-serif";
    }

    window {
      font-weight: bold;
      font-family: "Roboto Mono, Font Awesome 5 Free, Font Awesome 5 Brands, Arial, sans-serif";
    }

    window#waybar {
      background: rgba(0, 0, 0, 0.8);
      color: white;
    }

    #workspaces button {
      padding: 0 5px;
      background: transparent;
      color: #bababa;
      border-top: 2px solid transparent;
    }

    #workspaces button.visible {
      border-top: 2px solid #606060;
    }

    #workspaces button.active {
      border-top: 2px solid #c9545d;
    }

    #mode {
      background: #64727D;
      border-bottom: 2px solid white;
    }

    #network, #memory, #cpu, #temperature, #idle_inhibitor, #pulseaudio, #clock, #tray, #mode {
      padding: 0 3px;
      margin: 0 2px;
    }
  '';
}
