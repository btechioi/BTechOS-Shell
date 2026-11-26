{
	description = "A machine running BTechOS";

	inputs.btechos.url = "github:btechioi/BTechOS-Shell";

	outputs = { btechos, ... }:
	let
		settings = builtins.fromJSON (builtins.readFile ./settings.json);
	in
	{
		nixosConfigurations.${settings.host.name} = btechos.lib.mkSystem
		{
			inherit settings;
			modules = [ ./hardware-configuration.nix ./configuration.nix ./local.nix ];
			home = [ ./home.nix ];
		};
	};
}
