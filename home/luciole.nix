# luciole.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
    imports = [ inputs.luciole.homeModules.default ];

    programs.luciole = {
        enable = true;
        package = inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
}