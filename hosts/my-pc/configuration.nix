# my-pc: the desktop machine.
{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	btechos.flake = "/home/banumath/BTechOS";

	users.users.banumath.extraGroups = [ "input" "dialout" "uinput" ];

	btechos.darkshadow.enable = true;
	btechos.darkshadow.user = config.btechos.user.name;

	# Boot to DarkShadow's SDDM login screen, not a TTY.
	programs.shadows-shell.sddm = lib.mkForce true;
	services.greetd.enable = lib.mkForce false;

	btechos.flatpaks.enable = true;

	# Keep the machine's own disk layout and input device.
	fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: { options = [ "compress=zstd" "noatime" ]; });
	services.btrfs.autoScrub = { enable = true; fileSystems = [ "/" ]; };
	hardware.uinput.enable = true;
	hardware.amdgpu.initrd.enable = true;

	# Open the KVM port and keep the PC's wired static address.
	networking.firewall.allowedTCPPorts = [ 24850 ];
	networking.networkmanager.ensureProfiles.profiles."btechos-wired" = {
		connection = {
			id = "btechos-wired";
			uuid = "970f961d-d241-42da-a7cf-1354b9cbf140";
			type = "ethernet";
			"interface-name" = "enp2s0";
			autoconnect = true;
			"autoconnect-priority" = 100;
		};
		ipv4 = {
			method = "manual";
			addresses = "192.168.1.3/24";
			gateway = "192.168.1.1";
			dns = "192.168.1.1;";
			"may-fail" = false;
		};
		ipv6.method = "auto";
	};

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
