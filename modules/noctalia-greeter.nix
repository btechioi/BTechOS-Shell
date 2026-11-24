# noctalia-greeter.nix by poligle

{ inputs, config, lib, pkgs, ... }:
{
    imports = [ inputs.noctalia-greeter.nixosModules.default ];

    services.displayManager.noctalia-greeter.enable = true;
}