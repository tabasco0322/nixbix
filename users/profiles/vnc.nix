{ lib, pkgs, ... }:
{
  services.wayvnc = {
    enable = true;
    autoStart = true;

    settings = {
      address = "0.0.0.0";
      port = 5900;
      xkb_layout = "us";
      xkb_variant = "altgr-intl";
      xkb_options = "compose:ralt";
    };
  };

  systemd.user.services.wayvnc.Service = {
    ExecStart = lib.mkForce "${lib.getExe pkgs.wayvnc} --max-fps=60 --gpu 0.0.0.0 5900";
    Restart = "always";
    RestartSec = 10;
  };
}
