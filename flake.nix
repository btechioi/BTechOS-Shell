# flake.nix by poligle

{
	description = "BTechOS: a monochrome, dot-matrix desktop for NixOS";

	inputs =
	{
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

		home-manager =
		{
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		zen-browser =
		{
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.home-manager.follows = "home-manager";
		};

		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

		freesmlauncher =
		{
			url = "github:FreesmTeam/FreesmLauncher";
			inputs.nixpkgs.follows = "nixpkgs-unstable";
		};

		darkshadowShell =
		{
			url = "github:shadowww-dev/DarkShadowShell";
		};
	};
	outputs = inputs@{ self, nixpkgs, home-manager, zen-browser, nixpkgs-unstable, freesmlauncher, darkshadowShell, ... }:
	let
		system = "x86_64-linux";
		pkgs = nixpkgs.legacyPackages.${system};

		date = self.lastModifiedDate or "19700101000000";
		at = start: length: builtins.substring start length date;
		revision = "${self.shortRev or self.dirtyShortRev or "local"} (${at 0 4}-${at 4 2}-${at 6 2} ${at 8 2}:${at 10 2})";
	in
	{
		nixosModules.default = { config, ... }:
		{
			imports =
			[
				home-manager.nixosModules.home-manager
				inputs.darkshadowShell.nixosModules.default
				./modules
			];

			home-manager =
			{
				useGlobalPkgs = true;
				useUserPackages = true;
				backupFileExtension = "hm-backup";
				# A second collision (an app rewrites mimeapps.list again) would find the old backup
				# there and stop Home Manager on every rebuild; the newest one replaces it.
				overwriteBackup = true;
				extraSpecialArgs = { inherit inputs; };
				users.${config.btechos.user.name}.imports = [ ./home.nix ] ++ config.btechos.home;
			};
		};

		# Where BTechOS comes from, for the installer; a machine's flake writes it too, as inputs can't
		# be worked out.
		lib.source = "github:btechioi/BTechOS-Shell";

		lib.mkSystem = { settings ? { }, modules ? [ ], home ? [ ] }: nixpkgs.lib.nixosSystem
		{
			inherit system;
			specialArgs = { inherit freesmlauncher inputs; system = "x86_64-linux"; };
			# Unfree packages are the machine's choice, not the module's: local.nix, after, can change it.
			modules = [ self.nixosModules.default { btechos = { inherit settings home revision; }; nixpkgs.config.allowUnfree = true; } ] ++ modules;
		};

		nixosConfigurations =
		{
			installer = nixpkgs.lib.nixosSystem
			{
				inherit system;
				specialArgs = { btechos = self; };
				modules = [ ./installer/iso.nix ];
			};

			example = self.lib.mkSystem
			{
				settings = builtins.fromJSON (builtins.readFile ./templates/machine/settings.json);
				modules = [ ./templates/example/hardware-configuration.nix ./templates/example/vm.nix ./templates/machine/local.nix ];
				home = [ ./templates/machine/home.nix ];
			};

			my-laptop = self.lib.mkSystem
			{
				settings = builtins.fromJSON (builtins.readFile ./hosts/my-laptop/settings.json);
				modules = [ ./hosts/my-laptop/hardware-configuration.nix ./hosts/my-laptop/configuration.nix ];
				home = [ ./hosts/my-laptop/home.nix ];
			};

			my-pc = self.lib.mkSystem
			{
				settings = builtins.fromJSON (builtins.readFile ./hosts/my-pc/settings.json);
				modules = [ ./hosts/my-pc/hardware-configuration.nix ./hosts/my-pc/configuration.nix ];
				home = [ ./hosts/my-pc/home.nix ];
			};
		};

		packages.${system}.iso = self.nixosConfigurations.installer.config.system.build.isoImage;

		# BTechOS as it comes, in a window (templates/example/vm.nix): nix run .#vm, from the folder to
		# find in it at /mnt/btechos. --fresh starts it on a new disk; it keeps its own otherwise.
		apps.${system}.vm =
		{
			type = "app";
			meta.description = "BTechOS as it comes, in a window: user btechos, password btechos";
			program = nixpkgs.lib.getExe (pkgs.writeShellApplication
			{
				name = "btechos-vm";
				text = ''
					disk="''${XDG_CACHE_HOME:-$HOME/.cache}/btechos-vm/btechos.qcow2"
					if [ "''${1:-}" = --fresh ]; then
						rm -f "$disk"
						shift
					fi
					mkdir -p "$(dirname "$disk")"
					echo "btechos-vm: user btechos, password btechos; $PWD is at /mnt/btechos" >&2
					NIX_DISK_IMAGE="$disk" BTechOS_VM_SOURCE="$PWD" exec ${nixpkgs.lib.getExe self.nixosConfigurations.example.config.system.build.vm} "$@"
				'';
			});
		};

		templates.default =
		{
			path = ./templates/machine;
			description = "A machine running BTechOS: settings.json, local.nix and home.nix";
			welcomeText = "Write this computer's hardware-configuration.nix (nixos-generate-config --show-hardware-config > hardware-configuration.nix), then settings.json.";
		};
	};
}
