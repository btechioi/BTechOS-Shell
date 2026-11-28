# my-laptop: this Dell Latitude 5480.
{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	# `btechos rebuild` / `btechos update` operate on this checkout, like the old
	# `btechos rebuild` did on /etc/nixos.
	btechos.flake = "/home/banumath/BTechOS";

	users.users.banumath.extraGroups = [ "input" "dialout" "uinput" ];

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;

	btechos.flatpaks.enable = true;

	# The laptop panel is the main screen: 1366x768 at 0.67 scale.
	btechos.primaryOutput = lib.mkForce "eDP-1";
	btechos.outputs.eDP-1 =
	{
		width = 1366;
		height = 768;
		mode = "1366x768@60";
		scale = lib.mkForce 0.67;
	};

	# Laptop power: the shell's own power modes via power-profiles-daemon.
	services.power-profiles-daemon.enable = true;
	services.tlp.enable = false;
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

	# Pull prebuilt packages from the binary caches instead of building them here.
	nix.settings.substituters = [
		"https://cache.nixos.org/"
		"https://freesmlauncher.cachix.org"
	];
	nix.settings.trusted-public-keys = [
		"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
		"freesmlauncher.cachix.org-1:Jcp5Q9wiLL+EDv8Mh7c6L9xGk+lXr7/otpKxMOuBuDs="
	];
}
