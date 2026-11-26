{
	description = "A machine running BTechOS";

	inputs.btechos.url = "github:btechioi/BTechOS-Shell";

	outputs = { btechos, ... }:
	let
		settings = builtins.fromJSON (builtins.readFile ./settings.json);
	in
	{
		nixosConfigurations.${settings.host.name or "btechos"} = btechos.lib.mkSystem
		{
			inherit settings;
			modules = [ ./hardware-configuration.nix ./local.nix ];
			home = [ ./home.nix ];
		};
	};
}
