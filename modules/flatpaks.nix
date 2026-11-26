# flatpaks.nix by btechioi
#
# Declares the Flatpak apps that are installed on this machine and installs
# them for the user through home-manager activation. Gear Lever itself comes
# from nixpkgs, so it does not need a Flatpak copy.
{ config, lib, pkgs, ... }:
let
    cfg = config.btechos.flatpaks;
    flatpak = "${pkgs.flatpak}/bin/flatpak";

    install = pkgs.writeShellScript "btechos-flatpak-install" ''
        set -eu
        ${flatpak} remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        ${flatpak} remote-add --user --if-not-exists artcraft-oci https://getartcraft.com/artcraft-oci.flatpakrepo
        ${lib.concatMapStringsSep "\n" (app:
            "${flatpak} info --user ${lib.escapeShellArg app.id} >/dev/null 2>&1 || ${flatpak} install --user --assumeyes ${lib.escapeShellArg app.remote} ${lib.escapeShellArg app.id}") cfg.apps}
    '';
in
{
    options.btechos.flatpaks = {
        enable = lib.mkEnableOption "declarative user Flatpak apps";

        apps = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
                options = {
                    remote = lib.mkOption {
                        type = lib.types.str;
                        description = "Flatpak remote to install this app from.";
                    };
                    id = lib.mkOption {
                        type = lib.types.str;
                        description = "Flatpak application id.";
                    };
                };
            });
            default = [
                { remote = "artcraft-oci"; id = "ai.storyteller.artcraft-launcher"; }
                { remote = "artcraft-oci"; id = "ai.storyteller.photocraft"; }
            ];
            description = "User Flatpaks kept in sync by NixOS.";
        };
    };

    config = lib.mkIf cfg.enable {
        services.flatpak.enable = true;
        environment.systemPackages = [ pkgs.gearlever ];

        home-manager.users.${config.btechos.user.name} =
            { lib, ... }:
            {
                home.activation.btechosFlatpaks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    if [ -n "''${DRY_RUN:-}" ]; then
                        $VERBOSE_ECHO "would install Flatpak apps"
                    else
                        ${install}
                    fi
                '';
            };
    };
}
