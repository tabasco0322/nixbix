{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        redhat.vscode-yaml
        vscodevim.vim
        github.github-vscode-theme
        github.copilot
        github.copilot-chat
        vadimcn.vscode-lldb
        fill-labs.dependi
        usernamehw.errorlens
        eamodio.gitlens
        rust-lang.rust-analyzer
      ];
      userSettings = {
        "editor.formatOnSave" = true;
        "diffEditor.hideUnchangedRegions.enabled" = true;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "redhat.telemetry.enabled" = false;
        "workbench.colorTheme" = "GitHub Dark Default";
        "workbench.sideBar.location" = "right";
        "lldb.suppressUpdateNotifications" = true;
        "editor.lineNumbers" = "relative";
      };
    };
  };
}
