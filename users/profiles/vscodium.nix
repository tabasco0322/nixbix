{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        eamodio.gitlens
        fill-labs.dependi
        github.copilot
        github.copilot-chat
        github.github-vscode-theme
        jnoortheen.nix-ide
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        usernamehw.errorlens
        vadimcn.vscode-lldb
        vscodevim.vim
      ];
      userSettings = {
        "diffEditor.hideUnchangedRegions.enabled" = true;
        "editor.formatOnSave" = true;
        "editor.lineNumbers" = "relative";
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "lldb.suppressUpdateNotifications" = true;
        "redhat.telemetry.enabled" = false;
        "workbench.colorTheme" = "GitHub Dark Default";
        "workbench.sideBar.location" = "right";
        "workbench.startupEditor": "none"
      };
    };
  };
}
