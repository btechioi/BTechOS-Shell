# darkshadow-patches.nix by btechioi
#
# Applies the DarkShadow custom patches that are already in use on this machine
# (from ~/DarkShadowShell-custom) to the DarkShadowShell flake input, and manages
# the patched scripts, QML, portal files and user config through Nix.
{ config, lib, pkgs, inputs ? { }, ... }:
let
    cfg = config.btechos.darkshadow.patches;
    user = config.btechos.user.name;

    src = inputs.darkshadowShell.outPath or null;
    version = if src == null then "" else lib.trim (builtins.readFile "${src}/VERSION");
    # One combined patch per supported base: custom portal/theme/media changes,
    # the iGPU stats fallbacks, and the GPU dial removal + memory dial.
    patch =
        if lib.hasPrefix "6.13" version then
            ../patches/darkshadow/custom-v6.13.patch
        else if lib.hasPrefix "6.55" version then
            ../patches/darkshadow/custom-v6.55-full.patch
        else
            ../patches/darkshadow/custom-v6.82.patch;

    # A copy of the shell source with our patch applied. The upstream Nix module
    # installs the same unpatched nixpkgs packages either way; these are the
    # scripts/QML/portal files that install.sh normally copies into $HOME.
    patched = pkgs.runCommand "darkshadow-shell-patched-${version}"
    {
        nativeBuildInputs = [ pkgs.patch ];
    } ''
        cp -a ${src}/. $out/
        chmod -R u+w $out
        cd $out
        patch -p1 --forward < ${patch}
    '';

    # Every binary the shell ships: keybinds and QML call many of these, so a
    # short list left the other machine with keybinds that did nothing.
    scripts = let
        dir = ../patches/darkshadow;
    in lib.mapAttrsToList (name: _: name)
        (builtins.readDir "${inputs.darkshadowShell.outPath}/bin");

    # Install every file under quickshell/ from the shell source, so a new QML
    # type added in a version bump (e.g. ScreenFrame.qml in V6.82) is never
    # missing from ~/.config/quickshell when the shell loads.
    allQuickshellFiles =
        lib.pipe (lib.filesystem.listFilesRecursive inputs.darkshadowShell)
        [
            (lib.filter (p: lib.hasPrefix "${inputs.darkshadowShell.outPath}/quickshell/" (builtins.toString p)))
            (map (p: {
                src = "${patched}/${lib.removePrefix "${inputs.darkshadowShell.outPath}/" (builtins.toString p)}";
                dst = ".config/quickshell/${lib.removePrefix "${inputs.darkshadowShell.outPath}/quickshell/" (builtins.toString p)}";
            }))
        ];

    # DarkShadowShell's Hyprland Lua config and its rice-* modules. Home Manager
    # owns hypridle.conf/hyprlock.conf, so only the Lua files are installed here;
    # user.lua is a user file and stays copy-if-missing.
    allHyprLuaFiles =
        lib.pipe (lib.filesystem.listFilesRecursive inputs.darkshadowShell)
        [
            (lib.filter (p:
                let
                    s = builtins.toString p;
                    name = builtins.baseNameOf s;
                in
                lib.hasSuffix ".lua" s &&
                name != "rice-settings.lua" && name != "user.lua" && (
                    lib.hasPrefix "${inputs.darkshadowShell.outPath}/config/hypr/" s ||
                    lib.hasPrefix "${inputs.darkshadowShell.outPath}/lua/" s)))
            (map (p: {
                src = "${patched}/${lib.removePrefix "${inputs.darkshadowShell.outPath}/" (builtins.toString p)}";
                dst = ".config/hypr/${builtins.baseNameOf (builtins.toString p)}";
            }))
        ];

    scriptPackage = pkgs.runCommand "darkshadow-patched-scripts" { } ''
        mkdir -p $out/bin
        ${lib.concatMapStringsSep "\n" (n: "install -Dm0755 ${patched}/bin/${n} $out/bin/${n}") scripts}
    '';

    portalPackage = pkgs.runCommand "darkshadow-portal-metadata" { } ''
        mkdir -p $out/share/xdg-desktop-portal/portals
        install -Dm0644 ${patched}/portal/darkshadow.portal \
            $out/share/xdg-desktop-portal/portals/darkshadow.portal
    '';

    plasmaBrowserIntegration = pkgs.kdePackages.plasma-browser-integration;
    plasmaBrowserHostManifest = pkgs.writeText "org.kde.plasma.browser_integration.json" (builtins.toJSON
    {
        name = "org.kde.plasma.browser_integration";
        description = "Native connector for KDE Plasma";
        path = "${plasmaBrowserIntegration}/bin/plasma-browser-integration-host";
        type = "stdio";
        allowed_extensions = [ "plasma-browser-integration@kde.org" ];
    });

    python = pkgs.python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ]);
    portalPython = pkgs.writeShellScriptBin "darkshadow-portal-python" ''exec ${python}/bin/python3 "$@"'';

    # (patched source path, path in $HOME)
    shellFiles =
    [
        (map (n: [ "bin/${n}" ".local/bin/${n}" ]) scripts)
        [
            [ "quickshell/hyprquickpaper/commands.sh" ".config/quickshell/hyprquickpaper/commands.sh" ]
            [ "quickshell/rice-apps/FilesApp.qml" ".config/quickshell/rice-apps/FilesApp.qml" ]
            [ "quickshell/rice-desktop/Bar.qml" ".config/quickshell/rice-desktop/Bar.qml" ]
            [ "quickshell/rice-desktop/ControlCenter.qml" ".config/quickshell/rice-desktop/ControlCenter.qml" ]
            [ "quickshell/rice-desktop/Dock.qml" ".config/quickshell/rice-desktop/Dock.qml" ]
            [ "quickshell/rice-desktop/MediaPick.qml" ".config/quickshell/rice-desktop/MediaPick.qml" ]
            [ "quickshell/rice-desktop/Player.qml" ".config/quickshell/rice-desktop/Player.qml" ]
            [ "quickshell/rice-desktop/VBar.qml" ".config/quickshell/rice-desktop/VBar.qml" ]
            [ "quickshell/rice-desktop/DynIsland.qml" ".config/quickshell/rice-desktop/DynIsland.qml" ]
            [ "quickshell/rice-desktop/GamePanel.qml" ".config/quickshell/rice-desktop/GamePanel.qml" ]
            [ "quickshell/rice-lockscreen/LockPlayer.qml" ".config/quickshell/rice-lockscreen/LockPlayer.qml" ]
            [ "quickshell/rice-settings/WallpaperPage.qml" ".config/quickshell/rice-settings/WallpaperPage.qml" ]
            [ "config/matugen/config.toml" ".config/matugen/config.toml" ]
            [ "portal/portals.conf" ".config/xdg-desktop-portal/portals.conf" ]
            [ "portal/hyprland-portals.conf" ".config/xdg-desktop-portal/hyprland-portals.conf" ]
            [ "portal/org.freedesktop.impl.portal.desktop.darkshadow.service"
                ".local/share/dbus-1/services/org.freedesktop.impl.portal.desktop.darkshadow.service" ]
        ]
    ];

    # Assets from the shell's install.sh that are not user settings: sounds,
    # app icon and pinned download hashes. Installed through Nix so no separate
    # ./install.sh run is needed.
    allAssetFiles =
        (lib.map (p: {
            src = "${patched}/${lib.removePrefix "${inputs.darkshadowShell.outPath}/" (builtins.toString p)}";
            dst = ".local/share/rice/sounds/${lib.removePrefix "${inputs.darkshadowShell.outPath}/sounds/" (builtins.toString p)}";
        }) (lib.filesystem.listFilesRecursive "${inputs.darkshadowShell.outPath}/sounds"))
        ++ [
            { src = "${patched}/assets/icon.png"; dst = ".local/share/rice/icon.png"; }
            { src = "${patched}/install/checksums.txt"; dst = ".local/share/rice/checksums.txt"; }
        ];

    # Patched code (scripts, QML, portal config): always reinstall so fixes and
    # new patches actually reach the running shell. These are not user settings.
    codeFiles = allAssetFiles ++ allQuickshellFiles ++ allHyprLuaFiles ++ lib.concatMap
        (pairs: lib.map (pair: {
            src = "${patched}/${builtins.elemAt pair 0}";
            dst = builtins.elemAt pair 1;
        }) pairs)
        shellFiles;

    # DarkShadowShell owns these settings: its Settings app rewrites them while
    # the system runs. Copy them only when missing, never overwrite the user's
    # layout, widget positions or saved choices.
    configCopies =
        (lib.map (name: {
            src = ../patches/darkshadow/external/home/banumath/.config/rice/${name}.json;
            dst = ".config/rice/${name}.json";
        }) (let
            dir = ../patches/darkshadow/external/home/banumath/.config/rice;
        in lib.mapAttrsToList (name: _: lib.removeSuffix ".json" name)
            (builtins.readDir dir)))
        ++ [
            {
                src = ../patches/darkshadow/external/home/banumath/.config/hypr/user.lua;
                dst = ".config/hypr/user.lua";
            }
            {
                src = plasmaBrowserHostManifest;
                dst = ".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
            }
            {
                src = ../patches/darkshadow/external/home/banumath/.config/gtk-3.0/settings.ini;
                dst = ".config/gtk-3.0/settings.ini";
            }
            {
                src = ../patches/darkshadow/external/home/banumath/.config/gtk-4.0/settings.ini;
                dst = ".config/gtk-4.0/settings.ini";
            }
        ];
in
{
    options.btechos.darkshadow.patches = {
        enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
                Apply the vendored DarkShadowShell custom patches and manage the
                patched scripts, QML, portal files and user config with Nix.
            '';
        };
        patched = lib.mkOption {
            type = lib.types.path;
            readOnly = true;
            description = "The patched DarkShadowShell source tree.";
        };
    };

    config = lib.mkIf (src != null && config.btechos.darkshadow.enable && cfg.enable) {
        btechos.darkshadow.patches.patched = patched;

        environment.systemPackages =
        [
            scriptPackage
            portalPython
            python
            plasmaBrowserIntegration
            pkgs.qt6.qtmultimedia
            pkgs.qt6.qtimageformats
            pkgs.cliphist
            pkgs.wtype
            pkgs.socat
            pkgs.rofi
            pkgs.cmatrix
            pkgs.glib
            pkgs.gtk3
            pkgs.desktop-file-utils
            pkgs.pulseaudio
            pkgs.adw-gtk3
            pkgs.qt6Packages.qt6ct
            pkgs.adwaita-qt
        ];

        environment.sessionVariables = {
            QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
            QT_STYLE_OVERRIDE = lib.mkForce "Adwaita-Dark";
            GTK_USE_PORTAL = lib.mkForce "1";
        };

        xdg.portal.extraPortals = [ portalPackage ];

        home-manager.users.${user} =
            { lib, ... }:
            {
            home.sessionVariables = {
                QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
                QT_STYLE_OVERRIDE = lib.mkForce "Adwaita-Dark";
                GTK_USE_PORTAL = lib.mkForce "1";
            };
            # Create the shell's files once, but never overwrite what
            # DarkShadowShell (or the user, through its Settings app) changed.
            home.activation.btechosDarkshadowConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                copy_if_missing() {
                    [ -e "$HOME/$2" ] || [ -L "$HOME/$2" ] && return 0
                    mkdir -p "$(dirname "$HOME/$2")"
                    cp "$1" "$HOME/$2"
                }
                install_code() {
                    target="$HOME/$2"
                    # The shell installs its scripts read-only (0444/0555), so
                    # cp cannot write over them: remove first, then copy.
                    mkdir -p "$(dirname "$target")"
                    rm -f "$target"
                    cp "$1" "$target"
                }
                ${lib.concatMapStringsSep "\n" (pair:
                    "install_code ${lib.escapeShellArg pair.src} ${lib.escapeShellArg pair.dst}")
                    codeFiles}
                ${lib.concatMapStringsSep "\n" (pair:
                    "copy_if_missing ${lib.escapeShellArg pair.src} ${lib.escapeShellArg pair.dst}")
                    configCopies}

                # install.sh substitutes @HOME@/@USER@ in the shipped Lua files;
                # our Nix copy must do the same or keybind commands (Super+Shift+S
                # screenshot, Super+W, Super+Shift+R) point at @HOME@ literally.
                for f in "$HOME/.config/hypr/hyprland-gui.lua"; do
                    [ -f "$f" ] || continue
                    sed -i "s|@HOME@|$HOME|g; s|@USER@|$(id -un)|g" "$f"
                done

                # rice-settings.lua is generated from ~/.config/rice/hypr.json by
                # the Settings app (hypr-set). Rebuilds must never overwrite it:
                # only create it when missing, from the saved settings.
                if [ ! -f "$HOME/.config/hypr/rice-settings.lua" ] && [ -x "$HOME/.local/bin/hypr-set" ]; then
                    "$HOME/.local/bin/hypr-set" regen >/dev/null 2>&1 || true
                fi

                # Register DarkShadow's own apps (Files, Photos, Music, Videos) in
                # the desktop menu — install.sh does this once; keep it in Nix.
                if [ -x "$HOME/.local/bin/rice-app" ]; then
                    "$HOME/.local/bin/rice-app" install >/dev/null 2>&1 || true
                fi

                # Old installs have the plain Adwaita theme; move them to adw-gtk3
                # so GTK apps follow the dark/material look. Never touch a real
                # user choice that is already adw-gtk3-dark.
                for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
                    [ -f "$f" ] || continue
                    grep -q '^gtk-theme-name=Adwaita-dark$' "$f" && \
                        sed -i 's/^gtk-theme-name=Adwaita-dark$/gtk-theme-name=adw-gtk3-dark/' "$f"
                done
            '';
            # A rebuild can change the patched shell files. Restart the running
            # shell once so the new QML/scripts take effect, but only when the
            # patched tree actually changed (a plain login does not restart it).
            home.activation.btechosDarkshadowRestart = lib.hm.dag.entryAfter [ "btechosDarkshadowConfigs" ] ''
                stamp="$HOME/.cache/btechos/darkshadow-shell-rev"
                want="${patched}"
                if [ "$(cat "$stamp" 2>/dev/null || true)" != "$want" ]; then
                    mkdir -p "$(dirname "$stamp")"
                    printf '%s\n' "$want" > "$stamp"
                    if [ -x "$HOME/.local/bin/rice-desktop" ] && "$HOME/.local/bin/rice-desktop" status >/dev/null 2>&1; then
                        setsid -f "$HOME/.local/bin/rice-desktop" restart >/dev/null 2>&1 </dev/null &
                    fi
                fi
            '';
            # DarkShadow owns the look: stop home-manager from writing GTK files
            # and a cursor theme over it.
            gtk.enable = lib.mkForce false;
            home.pointerCursor.enable = lib.mkForce false;

            # Home Manager's gtk module is off, so GTK settings are seeded once
            # by the activation below (never overwrite runtime changes).
        };
    };
}
