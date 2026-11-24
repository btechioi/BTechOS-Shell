# luciole.nix by poligle

{ inputs, config, lib, pkgs, ... }:
{
    environment.systemPackages = [ inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    services.gvfs.enable = lib.mkDefault true;
    services.tumbler.enable = lib.mkDefault true;

    xdg.portal = {
        enable = lib.mkDefault true;
        extraPortals = [
            inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.xdg-desktop-portal-gtk
        ];
        config.umbriel."org.freedesktop.impl.portal.FileChooser" = [ "luciole" "gtk" ];
    };
}