# packages.nix by poligle

{ config, lib, pkgs, freesmlauncher, system, ... }:
let
    freesm = freesmlauncher.packages.${system}.freesmlauncher;

in
{
    environment.systemPackages = with pkgs; 
    [
        wev
        wget
        git
        unzip
        fastfetch
        btop
        brightnessctl
        playerctl
        trash-cli
        sound-theme-freedesktop
        android-tools
        libva-utils
        intel-gpu-tools
        freesm
        wl-clipboard
        kdePackages.plasma-browser-integration

        # Dynamic theming: matugen generates the app palette from the wallpaper.
        matugen
        imagemagick

        # Game mode: MangoHud's FPS log feeds the shell's game bar, and
        # gamemode gives games the daemon's performance tweaks when launched
        # with `gamemoderun`.
        mangohud
        gamemode

        # Dev tooling
        uv
        fnm
        nodejs
        rustup
        fvm
        go
        python3
    ];

    programs.nix-ld.enable = true;

    # Libraries for programs that arrive as ordinary Linux binaries
    programs.nix-ld.libraries = with pkgs;
    [
        glib
        alsa-lib
        vulkan-loader
        libGL
        wayland
        libxkbcommon
        libx11
        libxcb
        fontconfig
        freetype
        dbus
    ];

    nixpkgs.config.allowUnfree = true;

    # AppImages
    programs.appimage =
    {
        enable = true;
        binfmt = true;
    };

    # Flatpak
    services.flatpak.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    systemd.services.flatpak-flathub =
    {
        description = "Add Flathub as a Flatpak remote";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "flatpak-system-helper.service" ];
        serviceConfig.Type = "oneshot";
        script = "${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
    };

    fonts.packages = with pkgs; 
    [
        nerd-fonts.jetbrains-mono
        nerd-fonts.hack
    ];
}
