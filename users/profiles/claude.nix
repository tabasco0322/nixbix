{
  programs.claude-code = {
    enable = true;
    settings = {
      model = "opus";
      permissions = {
        allow = [
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(git status:*)"
          "Bash(git blame:*)"
          "Bash(nix build:*)"
          "Bash(nix flake:*)"
          "Bash(nix fmt:*)"
          "Bash(nix eval:*)"
          "Edit"
          "Read"
          "Grep"
          "Glob"
          "Write"
        ];
        deny = [
          "Bash(curl:*)"
          "Read(./.env)"
          "Read(./secrets/**)"
        ];
      };
    };
  };
}
