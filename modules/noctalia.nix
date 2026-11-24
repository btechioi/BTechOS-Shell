# noctalia.nix by poligle

{ inputs, config, lib, pkgs, ... }:
{
    imports = [ inputs.noctalia.nixosModules.default ];

    programs.noctalia.enable = true;
    programs.noctalia.recommendedServices.enable = true;
}