# default.nix by poligle (modules)

{ ... }:
{
    imports =
    [
        ./boot.nix
        ./network.nix
        ./locale.nix
        ./audio.nix
        ./hardware.nix
        ./users.nix
        ./root.nix
        ./packages.nix
        ./hyprland.nix
        # ./regreet.nix  # replaced by DarkShadow's SDDM greeter
        # ./greeter.nix  # replaced by DarkShadow's SDDM greeter
        ./desktop.nix
        ./storage.nix
        ./nix.nix
        ./plymouth.nix
        ./boot-sound.nix
        ./stylix.nix
        ./direnv.nix
        ./btechos.nix
        ./btechos-cli.nix
        ./binds.nix
        ./deck.nix
        ./darkshadow.nix
        ./darkshadow-patches.nix
    ];
}
