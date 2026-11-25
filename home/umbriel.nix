# umbriel.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
let
    xkb = osConfig.services.xserver.xkb;
in
{
    imports = [ inputs.umbriel.homeModules.default ];

    programs.umbriel = {
        enable = true;
        package = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
            general.autostart = [ "noctalia" ] ++
                (if osConfig.networking.hostName == "my-laptop" then [ "deskflow-core server" ]
                 else if osConfig.networking.hostName == "my-pc" then [ "deskflow-core client my-laptop" ]
                 else [ ]);

            include.optional.files = [ "${config.home.homeDirectory}/.config/umbriel/noctalia.toml" ];

            appearance.blur = {
                enabled = true;
                optimized = true;
                passes = 2;
                radius = 8;
                noise = 0.02;
                brightness = 0.9;
                contrast = 0.9;
                saturation = 1.1;
            };

            window_rule = [
                { blur = true; blur_optimized = true; }
                { match.app_id = "^dev\\.noctalia\\.Noctalia$"; default_floating = true; default_floating_size_px = { width = 1020; height = 900; }; }
                { match.app_id = "^org\\.pulseaudio\\.pavucontrol$"; default_floating = true; }
                { match.app_id = "^nm-connection-editor$"; default_floating = true; }
                { match.app_id = "^blueman-manager$"; default_floating = true; }
                { match.is_dialog = true; default_floating = true; }
            ];

            layer_rule = [
                { match.namespace = "^noctalia-(bar-[^\\\"]+|notification|dock|panel|attached-panel|osd)$"; blur = true; blur_ignore_alpha = 0.6; blur_optimized = false; }
            ];

            input.touchpad.natural_scroll = true;

            output."eDP-1" = { scale = 0.75; };

            input.keyboard = {
                layout = xkb.layout;
                variant = xkb.variant;
                model = xkb.model;
            };

            keybinds = {
                "Mod" = "spawn noctalia msg panel-toggle launcher";
                "Mod+Space" = "spawn noctalia msg panel-toggle launcher";
                "Mod+Return" = "spawn kitty";
                "Mod+E" = "spawn luciole";
                "Mod+X" = "spawn zen-beta";
                "Mod+Q" = "window-close";
                "Mod+F" = "window-toggle-fullscreen";
                "Mod+Shift+F" = "window-toggle-maximize";
                "Mod+Shift+Space" = "window-toggle-floating";
                "Mod+A" = "overview-toggle";
                "Mod+L" = "spawn noctalia msg session lock";
                "Mod+O" = "spawn noctalia msg settings-toggle";
                "Mod+W" = "spawn noctalia msg panel-toggle wallpaper";
                "Mod+V" = "spawn noctalia msg panel-toggle clipboard";
                "Mod+P" = "spawn noctalia msg panel-toggle control-center";
                "Mod+Tab" = "workspace-next";

                "Mod+1" = "workspace-switch 1";
                "Mod+2" = "workspace-switch 2";
                "Mod+3" = "workspace-switch 3";
                "Mod+4" = "workspace-switch 4";
                "Mod+5" = "workspace-switch 5";
                "Mod+6" = "workspace-switch 6";
                "Mod+7" = "workspace-switch 7";
                "Mod+8" = "workspace-switch 8";
                "Mod+9" = "workspace-switch 9";
                "Mod+0" = "workspace-switch 10";

                "Mod+Shift+1" = "window-move-to-workspace 1";
                "Mod+Shift+2" = "window-move-to-workspace 2";
                "Mod+Shift+3" = "window-move-to-workspace 3";
                "Mod+Shift+4" = "window-move-to-workspace 4";
                "Mod+Shift+5" = "window-move-to-workspace 5";

                "Print" = "spawn grim";
                "XF86AudioRaiseVolume" = "spawn noctalia msg volume-up";
                "XF86AudioLowerVolume" = "spawn noctalia msg volume-down";
                "XF86AudioMute" = "spawn noctalia msg volume-mute";
                "XF86MonBrightnessUp" = "spawn noctalia msg brightness-up";
                "XF86MonBrightnessDown" = "spawn noctalia msg brightness-down";
            };
        };
    };
}