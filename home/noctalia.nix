# noctalia.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        systemd.enable = true;

        settings = {
            theme = {
                mode = "dark";
                shell_mode = "follow";
                source = "wallpaper";
                wallpaper_scheme = "m3-content";
                terminal_colors = "palette";
                sync_color_scheme = true;
                pure_black_dark = false;

                templates = {
                    enable_builtin_templates = true;
                    builtin_ids = [
                        "cava"
                        "hyprland"
                        "labwc"
                        "mango"
                        "niri"
                        "scroll"
                        "sway"
                        "umbriel"
                        "emacs"
                        "helix"
                        "btop"
                        "luciole"
                        "gtk3"
                        "gtk4"
                        "kcolorscheme"
                        "qt"
                        "alacritty"
                        "foot"
                        "ghostty"
                        "kitty"
                        "wezterm"
                    ];
                };
            };
        };
    };
}