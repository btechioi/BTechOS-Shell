# home.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
	imports =
	[
		./home/gtk.nix
		./home/nvim.nix
		./home/zsh.nix
		./home/kitty.nix
		./home/desktop-entries.nix
		./home/default-apps.nix
		./home/viewers.nix
		./home/zen.nix
		./home/bluetooth.nix
		./home/cli.nix
		./home/fastfetch.nix
		./home/editors.nix
		./home/noctalia.nix
		./home/umbriel.nix
		./home/luciole.nix
	];

	home.stateVersion = "26.05";
	programs.home-manager.enable = true;

	home.sessionPath = [ "$HOME/.opencode/bin" "$HOME/.local/bin" ];

	home.sessionVariables.MOZ_DISABLE_RDD_SANDBOX = "1";

	home.packages =
	[
		pkgs.pavucontrol
		pkgs.networkmanagerapplet
		pkgs.libnotify
		pkgs.awww
		pkgs.grim
		pkgs.slurp
		pkgs.hyprpicker
	];
}
