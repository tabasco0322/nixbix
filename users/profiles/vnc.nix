{ pkgs, ... }:
{
  home.packages = [ pkgs.wayvnc ];

  xdg.configFile."wayvnc/config".text = ''
    address=0.0.0.0
    port=5900
    xkb_options=compose:ralt
  '';
}
