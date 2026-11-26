# darkshadow.nix by btechioi

# DarkShadow's Shell: full desktop shell (bar, launcher, widgets, dock, settings).
# Disabled by default; enable in local.nix.
{ config, lib, ... }:
{
    options.btechos.darkshadow =
    {
        enable = lib.mkOption
        {
            type = lib.types.bool;
            default = false;
            description = "Enable DarkShadow's Shell (replaces the BTechOS quickshell shell).";
        };

        user = lib.mkOption
        {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "User for the login screen wallpaper/colors.";
        };
    };

    config = lib.mkIf config.btechos.darkshadow.enable
    {
        programs.shadows-shell =
        {
            enable = true;
            user = config.btechos.darkshadow.user;
            inputGroup = true;
            sddm = false;
        };
    };
}
