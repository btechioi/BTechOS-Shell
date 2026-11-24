# umbriel.nix by poligle

{ inputs, config, lib, pkgs, ... }:
{
    imports = [ inputs.umbriel.nixosModules.default ];

    programs.umbriel.enable = true;
}