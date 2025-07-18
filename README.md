# bisnix

## ToC

* [Initial Setup](#initial-setup)
* [Nix misc](#nix-misc)
    + [Update system](#update-system)
* [Wow things](#wow-things)
* [Discord things](#discord-things)

## Initial setup

### On the host

1) Set password on nixos user, ```passwd```

### SSH to the host

1) sudo -i
1) git clone $repourl
1) cd $repo
1) nix build .#$hostname-diskformat
1) Set hdd encryption key
    1) ```./result/bin/diskformat```
1) ```nixos-install --flake .#$hostname --no-root-passwd```
1) ```chown -R 1100:100 /mnt/keep/home/nemko```
1) ```reboot```
    * *Might need to change boot disk*

## Nix misc

### Update system

* ```cd $gitrepo```
* ```nix flake update```

### Test build
* ```nixos-rebuild build --flake .#$hostname ```

### Switch to build
* ```nixos-rebuild switch --flake .#$hostname --sudo```

### Build on Mac

https://github.com/DeterminateSystems/nix-installer

* ```nix build .#nixosConfigurations.nixbox.config.system.build.toplevel```
    * *Remember that building x86 on arm64 is really hard...*

### Create iso

```shell
cd $repo
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=hosts/x86_64-linux/installer.nix
```

## Wow things

1) ```flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo```
    * *Might need to reboot so things gets added to $PATH*
1) ```flatpak install flathub com.usebottles.bottles```
    1) Usual Wizard crap
    1) Create New called Games with profile Gaming
    1) Hamburger > Preferences > General > Dark Mode
1) Click Games, *Might need to switch to Bottles*
    1) Install Programs
    1) Blizzard Battle.net
    1) Probably bugs out after installation, need to add better runner
    1) Wait for Social buttons to appear
1) Hamburger menu > Preferences > Runners > Proton GE version $
    1) Runner is set on application level
1) ```flatpak update``` To update flatpak, duh
1) Addons location ```/home/nemko/.var/app/com.usebottles.bottles/data/bottles/bottles/Games/drive_c/Program Files (x86)/World of Warcraft/_classic_era_``` 

### Wowup

1) Visit https://wowup.io
    * Download latest appimage
1) ```nix shell nixpkgs#appimage-run -c appimage-run WowUp-CF-2.$version.AppImage```
    * ```Ctrl+H``` To show hidden files
    * ```/home/$USER/.var/app/com.usebottles.bottles/data/bottles/bottles/Games/drive_c/Program Files (x86)/World of Warcraft/_classic_era_```

## Discord things

Since NixOS patches the discord binary, [Krisp yeetus deletus itself](https://nixos.wiki/wiki/Discord#Krisp_noise_suppression). Vesktop is used instead.


