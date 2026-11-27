# hypridle.nix by poligle

{ config, osConfig, pkgs, ... }:
let
	brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
	dpms = state: "${osConfig.programs.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";

	# hypridle 0.1.x (what nixpkgs ships) does NOT support condition_cmd, so the
	# guard has to be part of the command itself. If anything is playing (e.g.
	# YouTube in a browser) the action is skipped; hypridle will try again on
	# the next timeout/resume. `pgrep`-free and works with any player MPRIS
	# exposes via playerctl.
	guard = "${pkgs.bash}/bin/bash -c 'if command -v playerctl >/dev/null 2>&1 && playerctl -a status 2>/dev/null | grep -qx Playing; then exit 0; fi; exec \"$@\"' _";
	guarded = cmd: "${guard} ${cmd}";
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
					on-timeout = guarded "${brightnessctl} -s set 10";
					on-resume = "${brightnessctl} -r";
				}
				{
					timeout = 240;
					on-timeout = guarded "loginctl lock-session";
				}
				{
					timeout = 270;
					on-timeout = guarded (dpms "off");
					on-resume = dpms "on";
				}
				{
					timeout = 900;
					on-timeout = guarded "systemctl suspend";
				}
			];
		};
	};
}
