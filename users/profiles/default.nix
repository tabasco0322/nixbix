{
  pkgs,
  ...
}:{
  imports = [
    ./alacritty.nix
    ./bat.nix
    ./firefox.nix
    ./dunst.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
  ];

  home.sessionVariables = {
    COLORTERM = "truecolor";
  };

  home.packages = with pkgs; [
    carapace
    devenv
    fzf
    lm_sensors
    nix-index
  ];

  xdg.enable = true;

  programs.command-not-found.enable = false;

  programs.lsd = {
    enable = true;
    enableAliases = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.skim.enable = true;

  systemd.user.services.nix-index = {
    Unit.Description = "Nix-index indexes all files in nixpkgs";
    Service.ExecStart = "${pkgs.nix-index}/bin/nix-index";
  };

  systemd.user.timers.nix-index = {
    Unit.Description = "Nix-index indexes all files in nixpkgs";
    Timer = {
      OnCalendar = "*-*-* 4:00:00";
      Unit = "nix-index.service";
    };
    Install.WantedBy = ["timers.target"];
  };

  home.stateVersion = "21.05";
}
