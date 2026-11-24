# noctalia.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        systemd.enable = true;

        customPalettes = {
            Nihil = {
                version = 2;
                dark = {
                    primary = "#F2F2F2";
                    on_primary = "#000000";
                    secondary = "#7A7A7A";
                    on_secondary = "#000000";
                    tertiary = "#D71921";
                    on_tertiary = "#000000";
                    error = "#D71921";
                    on_error = "#000000";
                    surface = "#000000";
                    on_surface = "#F2F2F2";
                    surface_container = "#0E0E0E";
                    on_surface_variant = "#7A7A7A";
                    outline_variant = "#2A2A2A";
                    shadow = "#000000";
                    hover = "#1A1A1A";
                    on_hover = "#F2F2F2";
                    terminal = {
                        background = "#000000";
                        foreground = "#F2F2F2";
                        cursor = "#F2F2F2";
                        cursor_text = "#000000";
                        selection_bg = "#F2F2F2";
                        selection_fg = "#000000";
                        normal = {
                            black = "#000000";
                            red = "#D71921";
                            green = "#9E9E9E";
                            yellow = "#CFCFCF";
                            blue = "#8A8A8A";
                            magenta = "#B5B5B5";
                            cyan = "#8A8A8A";
                            white = "#F2F2F2";
                        };
                        bright = {
                            black = "#2A2A2A";
                            red = "#D71921";
                            green = "#A3A3A3";
                            yellow = "#E6E6E6";
                            blue = "#7A7A7A";
                            magenta = "#CFCFCF";
                            cyan = "#7A7A7A";
                            white = "#FFFFFF";
                        };
                    };
                };
            };
        };

        settings = {
            shell = {
                umbriel_overview_type_to_launch_enabled = true;
                umbriel_overview_close_on_launch_enabled = true;
                umbriel_audio_provider_enabled = true;
            };

            theme = {
                mode = "dark";
                shell_mode = "follow";
                source = "custom";
                custom_palette = "Nihil";
                terminal_colors = "palette";
                sync_color_scheme = true;
                pure_black_dark = true;

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
                        "zed"
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


        };
    };
}