{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    font = "monofur 13";
    theme = "Arc-Dark";
  };
}
