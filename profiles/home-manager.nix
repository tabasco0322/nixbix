{
  hostName,
  inputs,
  adminUser,
  ...
}:
{
  home-manager.extraSpecialArgs = { inherit hostName inputs adminUser; };
  home-manager.sharedModules = [
    ../users/modules/theme.nix
    ../users/modules/userinfo.nix
  ];
}
