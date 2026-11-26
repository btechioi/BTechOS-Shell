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

	# DarkShadow's own SDDM login screen; the older greeters stay off.
	programs.shadows-shell.sddm = lib.mkForce true;
	services.greetd.enable = lib.mkForce false;
	programs.regreet.enable = lib.mkForce false;

	hardware.uinput.enable = true;
	fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: { options = [ "compress=zstd" "noatime" ]; });
	services.btrfs.autoScrub = { enable = true; fileSystems = [ "/" ]; };
	nix.settings.trusted-users = [ "root" "banumath" ];
}
