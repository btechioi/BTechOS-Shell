# plymouth.nix by poligle

{ config, lib, pkgs, ... }:
let
    splashSeconds = "4.5";
    waitForSound = config.btechos.bootSound;
    litSeconds = "1.5";

    splashWait = pkgs.writeShellScript "btechos-splash-wait" ''
        read -r pid 2>/dev/null < /run/plymouth/pid || exit 0
        [ -r "/proc/$pid/stat" ] || exit 0
        read -r -a stat < "/proc/$pid/stat"
        read -r now _ < /proc/uptime
        opened=0
        if ${lib.boolToString waitForSound}; then
            read -r opened _ 2>/dev/null < /run/btechos/splash-open || opened=""
            if [ -z "$opened" ]; then
                ${config.boot.plymouth.package}/bin/plymouth update --status=btechos-open 2>/dev/null || true
                opened=$now
            fi
        fi
        wall=$(${pkgs.coreutils}/bin/date +%s.%N)
        card=$(${pkgs.coreutils}/bin/stat -c %.3Z /dev/dri/card* 2>/dev/null | ${pkgs.coreutils}/bin/sort -n | ${pkgs.coreutils}/bin/tail -n 1)
        left=$(${pkgs.gawk}/bin/awk -v started="''${stat[21]}" -v now="$now" -v wall="$wall" -v card="''${card:-0}" \
            -v want=${splashSeconds} -v opened="$opened" -v lit=${litSeconds} 'BEGIN {
                shown = started / 100
                if (card > 0 && now - (wall - card) > shown) shown = now - (wall - card)
                w = want - (now - shown); if (w > want) w = want
                if (opened > 0 && opened + lit - now > w) w = opened + lit - now
                printf "%.2f", (w > 0 ? w : 0) }')
        exec ${pkgs.coreutils}/bin/sleep "$left"
    '';
in
{
    options.btechos.plymouth.currentWallpaper = lib.mkOption
    {
        type = lib.types.nullOr lib.types.path;
        default = if builtins.pathExists ../wallpapers/current.jpg then ../wallpapers/current.jpg else null;
        defaultText = lib.literalExpression "wallpapers/current.jpg";
        description = ''
            The still picture the shell is currently showing. Kept in sync with
            ~/.cache/hyprquickpaper-current by a Home Manager activation, so the
            boot splash follows the wallpaper instead of the settings.json default.
        '';
    };

    config =
    {
        boot.plymouth =
        {
            enable = lib.mkDefault true;
            theme = lib.mkDefault "btechos";
            themePackages = [ (import ../theme/plymouth.nix {
                inherit pkgs waitForSound;
                wallpaper = config.btechos.plymouth.currentWallpaper;
                passphrase = config.btechos.strings.diskPassphrase;
            }) ];
        };

        boot.consoleLogLevel = lib.mkDefault 3;
        boot.initrd.verbose = lib.mkDefault false;
        boot.kernelParams =
        [
            "quiet"
            "splash"
            "udev.log_level=3"
            "systemd.show_status=auto"
            "rd.udev.log_level=3"
        ];

        systemd.services = lib.genAttrs [ "plymouth-poweroff" "plymouth-reboot" "plymouth-halt" "plymouth-kexec" ] (_:
        {
            serviceConfig.ExecStartPost = [ "-${pkgs.coreutils}/bin/sleep ${splashSeconds}" ];
        }) // {
            plymouth-quit.serviceConfig.ExecStartPre = [ "${splashWait}" ];
        };
    };
}
