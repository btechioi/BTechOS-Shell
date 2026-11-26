{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	# The built-in wallpapers come from the DarkShadowShell flake input
	# (see modules/btechos.nix); this folder is only for your own pictures.
	btechos.extraWallpapers = lib.optional (builtins.pathExists ./wallpapers) ./wallpapers;

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;
}
