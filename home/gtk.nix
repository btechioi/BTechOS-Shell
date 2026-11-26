# gtk.nix by poligle

{ config, pkgs, lib, ... }:
{
    gtk =
    {
        enable = true; 

        theme.name = lib.mkForce "adw-gtk3-dark";

        iconTheme =
        {
            name = "Colloid-Grey-Dark";
            package = pkgs.colloid-icon-theme.override { colorVariants = [ "grey" ]; };
        };

        gtk3.extraConfig = 
        {
            gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
            gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
            gtk-button-images = 0;
            gtk-menu-images = 0;
            gtk-enable-event-sounds = 1;
            gtk-enable-input-feedback-sounds = 0;
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintslight";
            gtk-xft-rgba = "rgb";
        };

        # GTK 4 has no toolbar style or button and menu images: it warns of each key it doesn't know.
        gtk4.extraConfig = 
        {
            gtk-enable-event-sounds = 1;
            gtk-enable-input-feedback-sounds = 0;
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintslight";
            gtk-xft-rgba = "rgb";
        };
    };

    home.packages = 
    [
        pkgs.noto-fonts-cjk-sans
    ];
}