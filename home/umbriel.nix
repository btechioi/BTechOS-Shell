# umbriel.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
    imports = [ inputs.umbriel.homeModules.default ];

    programs.umbriel = {
        enable = true;
        package = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
            general.autostart = [ "noctalia" ];
        };
    };
}