{
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    # temp fix since 10.1p1 was super slow, remember to delete pkgs import
    package = pkgs.openssh_10_2;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        controlPersist = "30m";
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%n:%p";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        forwardAgent = true;
        addKeysToAgent = "no";
        compression = false;
    };
    "github github.com" = {
        hostname = "github.com";
        user = "git";
        forwardAgent = false;
        extraOptions = {
          preferredAuthentications = "publickey";
          controlMaster = "no";
          controlPath = "none";
        };
      };
      "framenix" = {
        user = "nemko";
        forwardAgent = true;
      };
    };
  };
}
