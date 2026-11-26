# my-pc: the desktop machine.
{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	btechos.flake = "/home/banumath/BTechOS";

	users.users.banumath.extraGroups = [ "input" "dialout" "uinput" ];

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;

	btechos.flatpaks.enable = true;
}
