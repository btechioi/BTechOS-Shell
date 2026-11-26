# deck.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	deck = import ./deck
	{
		inherit pkgs lib osConfig;
		profile = "${config.home.profileDirectory}/bin";
		iconTheme = config.gtk.iconTheme.name;
	};
	watch = pkgs.writeShellApplication
	{
		name = "btechos-watch";
		runtimeInputs = [ deck pkgs.android-tools pkgs.avahi pkgs.curl pkgs.jq pkgs.gawk pkgs.gnugrep pkgs.coreutils ];
		# Its words, in the machine's language, as the rest of BTechOS's.
		runtimeEnv.BTechOS_WATCH_STRINGS = pkgs.writeText "btechos-watch-strings.json" (builtins.toJSON osConfig.btechos.strings);
		text = builtins.readFile ./deck/watch.sh;
	};
in
{
	config = lib.mkIf osConfig.btechos.deck.enable
	{
		home.packages = [ deck watch ];

		systemd.user.services.btechos-deck =
		{
			Unit =
			{
				Description = "BTechOS deck: your devices open apps and pages here (docs/deck.md)";
				After = [ "graphical-session.target" ];
				PartOf = [ "graphical-session.target" ];
			};

			Service =
			{
				ExecStart = "${deck}/bin/btechos-deck serve";
				Restart = "on-failure";
				RestartSec = 5;
			};

			Install.WantedBy = [ "graphical-session.target" ];
		};
	};
}
