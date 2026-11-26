{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	btechos.extraWallpapers = lib.optional (builtins.pathExists ./wallpapers) ./wallpapers;

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;
}
