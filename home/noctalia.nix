# noctalia.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        systemd.enable = true;

        settings = {
            shell = {
                umbriel_overview_type_to_launch_enabled = true;
                umbriel_overview_close_on_launch_enabled = true;
                umbriel_audio_provider_enabled = true;
            };

            bar.main = {
                position = "left";
                thickness = 40;
                radius = 10;
                margin_ends = 0;
                margin_edge = 0;
                padding = 6;
                widget_spacing = 3;
                capsule = true;
                start = [ "launcher" "workspaces" ];
                center = [ "clock" ];
                end = [ "control-center" "session" ];
            };

            widget.launcher = {
                custom_image = "/run/current-system/sw/share/icons/hicolor/48x48/apps/nix-snowflake.png";
                custom_image_colorize = false;
            };

            widget.workspaces = {
                show_labels = false;
            };

            widget.clock = {
                show_label = false;
            };

            widget.control-center = {
                show_label = false;
            };

            widget.session = {
                show_label = false;
            };

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
                    enable_community_templates = true;
                    community_ids = [ "zen-browser" "pywalfox" ];
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