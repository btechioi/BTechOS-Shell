# my-pc: the desktop machine.
{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	btechos.flake = "/home/banumath/BTechOS";

	users.users.banumath.extraGroups = [ "input" "dialout" "uinput" ];

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;

	btechos.flatpaks.enable = true;

	nix.settings.trusted-users = [ "root" "banumath" ];
	nix.settings.substituters = [
		"https://cache.nixos.org/"
		"https://freesmlauncher.cachix.org"
	];
	nix.settings.trusted-public-keys = [
		"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
		"freesmlauncher.cachix.org-1:Jcp5Q9wiLL+EDv8Mh7c6L9xGk+lXr7/otpKxMOuBuDs="
	];
}
