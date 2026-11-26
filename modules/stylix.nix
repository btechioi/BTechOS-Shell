# stylix.nix by poligle

{ config, lib, pkgs, ... }:
let
    btechos = config.btechos;
    tokens = btechos.tokens;
in
{
    stylix = 
    {
        enable = true;
        autoEnable = false;
        image = /home/banumath/DarkShadowShell/wallpapers/city-night.jpg;
        base16Scheme = tokens.base16;
        polarity = lib.mkDefault "dark";

        cursor = 
        {
            package = lib.mkDefault pkgs.bibata-cursors;
            name = lib.mkDefault "Bibata-Modern-Ice";
            size = lib.mkDefault 24;
        };

        fonts = 
        {
            monospace = 
            {
                package = lib.mkDefault pkgs.nerd-fonts.jetbrains-mono;
                name = lib.mkDefault tokens.fonts.code;
            };
            sansSerif = 
            {
                package = lib.mkDefault btechos.fonts;
                name = lib.mkDefault tokens.fonts.sans;
            };
            emoji = 
            {
                package = lib.mkDefault pkgs.noto-fonts-color-emoji;
                name = lib.mkDefault "Noto Color Emoji";
            };
            sizes = 
            {
                terminal = lib.mkDefault 11;
                applications = lib.mkDefault 11;
                desktop = lib.mkDefault 10;
                popups = lib.mkDefault 10;
            };
        };

        opacity = 
        {
            terminal = lib.mkDefault 0.9;
            popups = lib.mkDefault 0.8;
        };
    };
}
