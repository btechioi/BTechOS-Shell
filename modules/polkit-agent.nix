# polkit-agent.nix — hyprpolkitagent, themed from the shell's dynamic palette.
{ config, lib, pkgs, inputs, ... }:
let
    user = config.btechos.user.name;
    agent = "${inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hyprpolkitagent}/libexec/hyprpolkitagent";

    # hyprtoolkit.conf keys, from the shell's matugen palette (material colours).
    render = pkgs.writeShellApplication {
        name = "btechos-hyprtoolkit";
        runtimeInputs = [ pkgs.jq ];
        text = ''
            set -eu
            palette="$HOME/.config/rice/palette.json"
            out="$HOME/.config/hypr/hyprtoolkit.conf"
            [ -f "$palette" ] || exit 0
            mkdir -p "$(dirname "$out")"

            c() { jq -r --arg k "$1" '.[$k] // "#000000"' "$palette" | tr -d '\n'; }
            hex() { printf '0xFF%s' "$(c "$1" | sed 's/^#//')"; }

            tmp="$out.tmp"
            cat > "$tmp" <<EOF
            background = $(hex surface)
            base = $(hex surface_high)
            text = $(hex on_surface)
            alternate_base = $(hex surface_container)
            bright_text = $(hex on_surface_variant)
            accent = $(hex primary)
            accent_secondary = $(hex tertiary)

            font_family = Inter
            font_family_monospace = JetBrains Mono
            font_size = 11
            small_font_size = 10
            h1_size = 19
            h2_size = 15
            h3_size = 13

            rounding_large = 0
            rounding_small = 0
            EOF
            if [ -f "$out" ] && cmp -s "$tmp" "$out"; then
                rm -f "$tmp"
            else
                mv -f "$tmp" "$out"
            fi
        '';
    };
in
{
    config = {
        # One polkit agent only: hyprpolkitagent, not LXQt's.
        environment.systemPackages = [ render inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.hyprpolkitagent ];
        security.polkit.enable = true;

        home-manager.users.${user} =
            { lib, ... }:
            {
            home.file.".local/bin/btechos-hyprtoolkit".source = "${render}/bin/btechos-hyprtoolkit";

            # Render once at activation, and again whenever matugen rewrites the palette.
            home.activation.hyprtoolkitTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                [ -x "$HOME/.local/bin/btechos-hyprtoolkit" ] && "$HOME/.local/bin/btechos-hyprtoolkit" >/dev/null 2>&1 || true
            '';

            systemd.user.services.hyprpolkitagent = {
                Unit = {
                    Description = "hyprpolkitagent (themed)";
                    After = [ "graphical-session.target" ];
                    PartOf = [ "graphical-session.target" ];
                };
                Service = {
                    ExecStart = agent;
                    Restart = "on-failure";
                    RestartSec = 2;
                };
                Install.WantedBy = [ "graphical-session.target" ];
            };

            # Watch the palette: a new wallpaper/theme regenerates the agent
            # config and restarts it so it picks up the new colours.
            systemd.user.services.hyprtoolkit-watcher = {
                Unit = { Description = "Re-theme hyprpolkitagent from the shell palette"; };
                Service = {
                    Type = "oneshot";
                    ExecStart = ''
                        ${lib.getExe pkgs.bash} -c '${render}/bin/btechos-hyprtoolkit >/dev/null 2>&1 && systemctl --user try-restart hyprpolkitagent.service >/dev/null 2>&1 || true'
                    '';
                };
            };
            # The shell's matugen rewrites palette.json on every wallpaper or
            # theme change. Watch the directory too: matugen may replace the
            # file atomically, which a PathChanged on the file can miss.
            systemd.user.paths.hyprtoolkit-watcher = {
                Unit = { Description = "Watch the shell palette for hyprpolkitagent"; };
                Path = {
                    PathChanged = [ "%h/.config/rice/palette.json" "%h/.config/rice" ];
                    Unit = "hyprtoolkit-watcher.service";
                };
                Install.WantedBy = [ "paths.target" ];
            };
            systemd.user.timers.hyprtoolkit-watcher = {
                Unit = { Description = "Periodic re-theme of hyprpolkitagent"; };
                Timer = {
                    OnBootSec = "1min";
                    OnUnitActiveSec = "1min";
                    Unit = "hyprtoolkit-watcher.service";
                };
                Install.WantedBy = [ "timers.target" ];
            };
        };
    };
}
