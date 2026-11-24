# desktop.nix by poligle

{ config, lib, pkgs, ... }:
{
    services.gvfs.enable = lib.mkDefault true;
    services.tumbler.enable = lib.mkDefault true;
}