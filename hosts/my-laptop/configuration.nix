# my-laptop: this Dell Latitude 5480.
{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	users.users.banumath.extraGroups = [ "input" "dialout" "uinput" ];

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;

	# The laptop panel is the main screen: 1366x768 at 0.67 scale.
	btechos.primaryOutput = lib.mkForce "eDP-1";
	btechos.outputs.eDP-1 =
	{
		width = 1366;
		height = 768;
		mode = "1366x768@60";
		scale = lib.mkForce 0.67;
	};

	# Laptop power and thermal tuning.
	services.tlp.enable = lib.mkDefault true;
	services.thermald.enable = lib.mkDefault true;
	powerManagement.enable = lib.mkDefault true;
}
