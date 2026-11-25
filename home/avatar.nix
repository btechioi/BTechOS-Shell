# avatar.nix by poligle

{ pkgs, ... }:
{
    home.file.".face" =
    {
        source = pkgs.fetchurl
        {
            url = "https://github.com/btechioi.png";
            sha256 = "0h6qy1ydq74l7xw88sl3jr8cahl2740bn46jnv11k10vrmbmk67d";
        };
    };
}