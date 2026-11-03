{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      config,
      system,
      ...
    }:
    let
      inherit (lib // builtins) filterAttrs match;
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          # Until https://github.com/Sonarr/Sonarr/pull/7443 has been merged
          "aspnetcore-runtime-wrapped-6.0.36"
          "aspnetcore-runtime-6.0.36"
          "dotnet-sdk-6.0.428"
        ];
        overlays = [
          inputs.agenix.overlays.default
          inputs.nur.overlays.default
          # Host 1.0.2365 rejects nix store symlinked native modules
          (_final: _prev: {
            inherit
              (import inputs.nixpkgs-discord {
                inherit system;
                config.allowUnfree = true;
              })
              discord-canary
              ;
          })
          (_final: prev: {
            pkgsi686Linux = prev.pkgsi686Linux.extend (
              _: pp: {
                openldap = pp.openldap.overrideAttrs (_: {
                  doCheck = false;
                });
              }
            );
          })
          (
            _final: _prev:
            (filterAttrs (
              name: _: ((match "nu-.*" name == null) && (match "nu_.*" name == null))
            ) config.packages)
          )
        ];
      };
    };
}
