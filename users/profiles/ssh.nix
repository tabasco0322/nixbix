{
  _,
  ...
}:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ControlPersist = "30m";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        ForwardAgent = true;
        AddKeysToAgent = "no";
        Compression = false;
      };
      "github github.com" = {
        Hostname = "github.com";
        User = "git";
        ForwardAgent = false;
        PreferredAuthentications = "publickey";
        ControlMaster = "no";
        ControlPath = "none";
      };
      "framenix" = {
        User = "nemko";
        ForwardAgent = true;
      };
    };
  };
}
