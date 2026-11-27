# hypridle.nix by poligle

{ config, osConfig, pkgs, ... }:
let
	brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
	dpms = state: "${osConfig.programs.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";

	# Defer every idle action while something is playing (e.g. YouTube in a
	# browser). The guard lives in the repo so Home Manager owns it; exit 0
	# lets hypridle act, exit 1 makes it retry in 30s.
	guard = ../patches/darkshadow/external/home/banumath/.local/bin/rice-idle-guard;
in
{
	services.hypridle =
	{
		enable = true;

		settings =
		{
			general =
			{
				# In a scope of its own: a restart of hypridle (any update) would kill it with its
				# children and leave the session locked with nothing on it.
				lock_cmd = "pidof hyprlock || ${pkgs.systemd}/bin/systemd-run --user --scope --collect --quiet ${config.programs.hyprlock.package}/bin/hyprlock";
				before_sleep_cmd = "loginctl lock-session";
				after_sleep_cmd = dpms "on";
			};

			listener =
			[
				{
					timeout = 150;
					on-timeout = "${brightnessctl} -s set 10";
					on-resume = "${brightnessctl} -r";
					condition_cmd = "${guard}";
					condition_retry = 30;
				}
				{
					timeout = 240;
					on-timeout = "loginctl lock-session";
					condition_cmd = "${guard}";
					condition_retry = 30;
				}
				{
					timeout = 270;
					on-timeout = dpms "off";
					on-resume = dpms "on";
					condition_cmd = "${guard}";
					condition_retry = 30;
				}
				{
					timeout = 900;
					on-timeout = "systemctl suspend";
					condition_cmd = "${guard}";
					condition_retry = 30;
				}
			];
		};
	};
}
