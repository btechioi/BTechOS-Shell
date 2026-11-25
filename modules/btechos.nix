# btechos.nix by poligle

{ config, lib, pkgs, ... }:
let
    cfg = config.btechos;

    outputType = lib.types.submodule
    {
        options =
        {
            width = lib.mkOption
            {
                type = lib.types.ints.positive;
                description = "Width in pixels of its mode, after rotation (not divided by the scale).";
            };
            height = lib.mkOption
            {
                type = lib.types.ints.positive;
                description = "Height in pixels of its mode, after rotation (not divided by the scale).";
            };
            bar = lib.mkOption
            {
                type = lib.types.bool;
                default = true;
                description = "Whether the frame widens into the bar on this output.";
            };
            pitch = lib.mkOption
            {
                type = lib.types.ints.positive;
                default = 9;
                description = "Distance between wallpaper dots in px.";
            };
            mode = lib.mkOption
            {
                type = lib.types.str;
                default = "preferred";
                description = "Hyprland's mode for it: preferred, or one like 2560x1440@144.";
            };
            position = lib.mkOption
            {
                type = lib.types.str;
                default = "auto";
                description = "Where it sits among the others: auto, or a position like 2560x0.";
            };
            scale = lib.mkOption
            {
                type = lib.types.number;
                default = 1;
                description = "Hyprland's scale for it.";
            };
            transform = lib.mkOption
            {
                type = lib.types.ints.between 0 7;
                default = 0;
                description = "Rotation: 0 none, 1 90°, 2 180°, 3 270°; 4 to 7 the same, flipped.";
            };
        };
    };
in
{
    imports =
    [
        ./nilo.nix
        ./settings.nix
        (lib.mkRemovedOptionModule [ "btechos" "soundPack" ] "BTechOS has one pack of sounds, sounds/btechos.")
    ];

    options.btechos =
    {
        tokens = lib.mkOption
        {
            type = lib.types.attrs;
            default = import ../theme/btechos.nix;
            readOnly = true;
            description = "BTechOS design tokens (theme/btechos.nix).";
        };

        outputs = lib.mkOption
        {
            type = lib.types.attrsOf outputType;
            default = { };
            description = "Outputs of this host, keyed by connector name.";
        };

        primaryOutput = lib.mkOption
        {
            type = lib.types.str;
            description = "Output for the desktop widgets and the lock/login backgrounds.";
        };

        wallpaper = lib.mkOption
        {
            type = lib.types.str;
            default = "night";
            description = ''
                Default wallpaper: a picture's name, its file name without the
                extension in letters, digits, "_" and "-" (theme/wallpapers.nix).
            '';
        };

        language = lib.mkOption
        {
            type = lib.types.enum [ "es" "en" ];
            default = "en";
            description = "Language of the shell, the lock screen, the greeter, the boot and the notices scripts send (theme/i18n.nix); the commands answer in English.";
        };

        strings = lib.mkOption
        {
            type = lib.types.attrsOf lib.types.str;
            default = (import ../theme/i18n.nix).${cfg.language};
            defaultText = lib.literalExpression "(import ../theme/i18n.nix).\${config.btechos.language}";
            readOnly = true;
            description = "Strings of the selected language.";
        };

        clipboard = lib.mkOption
        {
            type = lib.types.ints.between 0 100;
            default = 8;
            description = ''
                How many copies the clipboard history keeps, text and pictures
                (home/clipboard.nix; SUPER + V held down brings it out); 0 turns
                it off, and SUPER + V only pastes.
            '';
        };

        extraWallpapers = lib.mkOption
        {
            type = lib.types.listOf lib.types.path;
            default = [ ];
            example = lib.literalExpression "[ ./wallpapers ]";
            description = ''
                More folders of pictures (PNG, JPEG, GIF or WebP, any name), drawn
                as dots like BTechOS's own; a name repeated replaces BTechOS's.
            '';
        };

        trayHidden = lib.mkOption
        {
            type = lib.types.listOf lib.types.str;
            default = [ "nm-applet" "blueman" ];
            example = [ "nm-applet" "blueman" "steam" ];
            description = ''
                Tray items the bar leaves out, matched case-insensitively against
                part of each item's id or title. The Wi-Fi and Bluetooth applets
                are hidden because the bar has its own icons for both; they keep
                running for password and pairing prompts.
            '';
        };

        sounds = lib.mkOption
        {
            type = lib.types.attrsOf lib.types.path;
            readOnly = true;
            description = "Sound file for each interface event (sounds/btechos).";
        };

        wallpapers = lib.mkOption
        {
            type = lib.types.package;
            readOnly = true;
            description = "Dot-matrix renders of every wallpaper for every output.";
        };

        fonts = lib.mkOption
        {
            type = lib.types.package;
            readOnly = true;
            description = "BTechOS font families.";
        };
    };

    config =
    {
        assertions =
        [
            {
                assertion = cfg.outputs ? ${cfg.primaryOutput};
                message = "btechos.primaryOutput must be one of btechos.outputs.";
            }
            {
                assertion = builtins.elem cfg.wallpaper cfg.wallpapers.names;
                message = "btechos.wallpaper must be one of the wallpapers: ${lib.concatStringsSep ", " cfg.wallpapers.names}.";
            }
            {
                assertion = let languages = builtins.attrValues (import ../theme/i18n.nix); in
                    lib.all (strings: builtins.attrNames strings == builtins.attrNames (lib.head languages)) languages;
                message = "theme/i18n.nix: every language needs the same keys.";
            }
        ];

        # The lock screen's date is in the language's own locale, which the machine's may not be.
        i18n.extraLocales = lib.optional (cfg.strings.lockLocale != "C.UTF-8") "${cfg.strings.lockLocale}/UTF-8";

        btechos.wallpapers = import ../theme/wallpapers.nix
        {
            inherit pkgs lib;
            outputs = cfg.outputs;
            dirs = [ ../wallpapers ] ++ cfg.extraWallpapers;
        };
        btechos.fonts = import ../theme/fonts.nix { inherit pkgs; };

        btechos.sounds = lib.genAttrs [ "switch" "open" "close" "special" "fullscreen" "lock" "power" "menu" "notify" "critical" "volume" "charge" ]
            (event: ../sounds/btechos + "/${event}.ogg");

        fonts.packages = [ cfg.fonts ];

        services.upower.enable = lib.mkDefault true;
    };
}
