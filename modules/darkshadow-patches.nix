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
    patch =
        if lib.hasPrefix "6.13" version then
            ../patches/darkshadow/custom-v6.13.patch
        else
            ../patches/darkshadow/custom-v6.55.patch;

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

    scripts = [ "darkshadow-portal" "rice-app" "rice-apps-helper" "rice-hotcorner"
        "rice-idle-guard" "rice-lock" "rice-sddm" "rice-theme" ];

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
            [ "quickshell/rice-lockscreen/LockPlayer.qml" ".config/quickshell/rice-lockscreen/LockPlayer.qml" ]
            [ "quickshell/rice-lockscreen/MediaPick.qml" ".config/quickshell/rice-lockscreen/MediaPick.qml" ]
            [ "quickshell/rice-settings/WallpaperPage.qml" ".config/quickshell/rice-settings/WallpaperPage.qml" ]
            [ "config/matugen/config.toml" ".config/matugen/config.toml" ]
            [ "portal/portals.conf" ".config/xdg-desktop-portal/portals.conf" ]
            [ "portal/hyprland-portals.conf" ".config/xdg-desktop-portal/hyprland-portals.conf" ]
            [ "portal/org.freedesktop.impl.portal.desktop.darkshadow.service"
                ".local/share/dbus-1/services/org.freedesktop.impl.portal.desktop.darkshadow.service" ]
        ]
    ];

    homeFiles = lib.listToAttrs (lib.concatMap
        (pairs: lib.map (pair: lib.nameValuePair (builtins.elemAt pair 1) { source = "${patched}/${builtins.elemAt pair 0}"; }) pairs)
        shellFiles)
    // builtins.listToAttrs (lib.map (name: lib.nameValuePair ".config/rice/${name}.json" {
        source = ../patches/darkshadow/external/home/banumath/.config/rice/${name}.json;
    }) [ "bar" "desktop" "effects" "vibe" "wallpapers" ])
    // {
        ".config/hypr/user.lua".source = ../patches/darkshadow/external/home/banumath/.config/hypr/user.lua;
        ".config/opencode/cli.json".source = ../patches/darkshadow/external/home/banumath/.config/opencode/cli.json;
        ".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = plasmaBrowserHostManifest;
    };
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

        home-manager.users.${user} = {
            home.sessionVariables = {
                QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
                QT_STYLE_OVERRIDE = lib.mkForce "Adwaita-Dark";
                GTK_USE_PORTAL = lib.mkForce "1";
            };
            home.file = homeFiles;
            # DarkShadow owns the look: stop home-manager from writing GTK files
            # and a cursor theme over it.
            gtk.enable = lib.mkForce false;
            home.pointerCursor.enable = lib.mkForce false;
        };
    };
}
