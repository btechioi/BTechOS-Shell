# plymouth.nix by poligle

{ config, lib, pkgs, ... }:
let
    splashSeconds = "4.5";
    waitForSound = config.btechos.bootSound;
    litSeconds = "1.5";

    user = config.btechos.user.name;
    home = config.users.users.${user}.home;
    host = config.networking.hostName;
    flake = config.btechos.flake;
    wallpaperCache = "${home}/.cache/hyprquickpaper-current";

    # Each machine keeps its own still of the wallpaper it is showing. The
    # theme is built from this at rebuild time (Plymouth's script plugin
    # cannot read files and the theme lives in the initrd, so colour changes
    # need a new boot generation).
    hostWallpaper = ../wallpapers/current-${host}.jpg;
    fallbackWallpaper = ../wallpapers/current.jpg;

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

    # Written by a root path unit when the shell changes the wallpaper: copy
    # it to this host's file in the flake, then prepare a boot generation with
    # a Plymouth theme tinted from it. `boot` (not `switch`) is enough: the
    # splash is only seen on the next start, and the running session is left
    # completely alone.
    syncWallpaper = pkgs.writeShellApplication {
        name = "btechos-plymouth-wallpaper";
        runtimeInputs = [ pkgs.coreutils pkgs.util-linux ];
        text = ''
            set -eu
            cache=${lib.escapeShellArg wallpaperCache}
            dest=${lib.escapeShellArg "${flake}/wallpapers/current-${host}.jpg"}
            [ -r "$cache" ] || exit 0
            wall=$(cat "$cache")
            [ -f "$wall" ] || exit 0
            mkdir -p "$(dirname "$dest")"
            # The watched cache directory changes often; leave immediately
            # when this is not a wallpaper change.
            if cmp -s "$wall" "$dest"; then exit 0; fi
            # Matugen and the wallpaper daemon write in a few steps; settle.
            sleep 3
            [ -r "$wall" ] || exit 0
            if cmp -s "$wall" "$dest"; then exit 0; fi
            tmp="$dest.tmp.$$"
            cp "$wall" "$tmp"
            chown ${lib.escapeShellArg user}:${lib.escapeShellArg (config.users.users.${user}.group)} "$tmp" 2>/dev/null || true
            chmod 644 "$tmp"
            mv -f "$tmp" "$dest"

            # One Plymouth rebuild at a time: keep the lock fd open.
            exec 9>/run/btechos-plymouth-rebuild.lock
            flock -w 1800 9
            ${config.system.build.nixos-rebuild}/bin/nixos-rebuild boot \
                --flake ${lib.escapeShellArg "${flake}#${host}"} >/dev/null 2>&1
        '';
    };
in
{
    options.btechos.plymouth.currentWallpaper = lib.mkOption
    {
        type = lib.types.nullOr lib.types.path;
        default = if builtins.pathExists hostWallpaper then hostWallpaper
                  else if builtins.pathExists fallbackWallpaper then fallbackWallpaper
                  else null;
        defaultText = lib.literalExpression "wallpapers/current-<hostname>.jpg";
        description = ''
            The still picture this machine is showing. The live wallpaper is
            copied here by btechos-plymouth-wallpaper.service whenever it
            changes, so the boot splash is tinted from it on the next boot.
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
            btechos-plymouth-wallpaper = {
                description = "Tint Plymouth from this machine's live wallpaper";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${syncWallpaper}/bin/btechos-plymouth-wallpaper";
                    TimeoutStartSec = 1800;
                };
            };
        };

        # Watching the directory as well as the file catches wallpapers that
        # are replaced atomically instead of written in place.
        systemd.paths.btechos-plymouth-wallpaper = {
            description = "Rebuild the Plymouth theme when the wallpaper changes";
            wantedBy = [ "paths.target" ];
            pathConfig = {
                PathChanged = [ wallpaperCache "${home}/.cache" ];
                Unit = "btechos-plymouth-wallpaper.service";
            };
        };
    };
}
