# hardware.nix by poligle

{ config, lib, pkgs, ... }:
let
    greeter = config.services.greetd.settings.default_session.user;
    # Says 1 to skip the fingerprint, 0 not to: pam_exec logs every exit but 0 as an error, and
    # not skipping is what happens nearly always. If it fails itself, the password is asked for.
    skipReader = pkgs.writeShellScript "skip-fingerprint" ''
        for state in /proc/acpi/button/lid/*/state; do
            [ -r "$state" ] || continue
            ${pkgs.gnugrep}/bin/grep -q closed "$state" && exit 1
        done
        # A regular file, and no more of it than a PID: a FIFO or a link to /dev/zero, the user's
        # own to make, would hang sudo or read forever.
        if [ "''${PAM_SERVICE:-}" = sudo ] && uid=$(${pkgs.coreutils}/bin/id -u -- "''${PAM_USER:-}" 2> /dev/null); then
            flag="/run/user/$uid/nihil-sudo-password"
            if [ -f "$flag" ] && [ ! -L "$flag" ] && [ "$(${pkgs.coreutils}/bin/head -c 16 -- "$flag")" = "$PPID" ]; then
                exit 1
            fi
        fi
        # Once: after a password typed in the greeter, the next login offers the finger again.
        if [ "''${PAM_SERVICE:-}" = greetd ] && uid=$(${pkgs.coreutils}/bin/id -u -- ${greeter} 2> /dev/null) \
            && [ -e "/run/user/$uid/nihil-greeter-password" ]; then
            ${pkgs.coreutils}/bin/rm -f "/run/user/$uid/nihil-greeter-password"
            exit 1
        fi
        exit 0
    '';

    skipFingerprint = service:
    {
        rules.auth.skipFingerprint =
        {
            enable = config.security.pam.services.${service}.fprintAuth;
            order = config.security.pam.services.${service}.rules.auth.fprintd.order - 1;
            # pam_exec answers setcred with PAM_IGNORE, which a jump would make the whole stack's
            # answer: greetd starts its greeter without authenticating, and it would never show.
            control = "[success=ignore ignore=ignore default=1]";
            modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
            args = [ "quiet" "${skipReader}" ];
        };
    };
in
{
    services.libinput.enable = lib.mkDefault true;

    services.logind.settings.Login =
    {
        HandleLidSwitch = lib.mkDefault "suspend";
        HandleLidSwitchExternalPower = lib.mkDefault "suspend";
        HandleLidSwitchDocked = lib.mkDefault "ignore";
    };
    services.fprintd.enable = lib.mkDefault config.nihil.fingerprint;

    hardware.enableRedistributableFirmware = lib.mkDefault true;
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    security.pam.services = lib.genAttrs [ "sudo" "su" "login" "polkit-1" "greetd" ] skipFingerprint //
    {
        greetd.enableGnomeKeyring = true;
    };
    zramSwap.enable = lib.mkDefault true;

    # Secret Service provider
    services.gnome.gnome-keyring.enable = true;

    # sudo preserves Wayland env for `sudo nvim` clipboard
    security.sudo.extraConfig = ''
        Defaults env_keep += "WAYLAND_DISPLAY XDG_RUNTIME_DIR"
    '';

    # PAM: greetd keyring (merged into the genAttrs block above is not possible;
    # instead set it via the existing block — but it's already defined. Use mkMerge.)


    # Performance: universal
    boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
    };
    nix.settings.auto-optimise-store = true;

    # Intel-specific
    boot.kernelParams = lib.optionals (config.nihil.gpu == "intel" || config.nihil.gpu == "auto") [
        "i915.enable_guc=3"
        "i915.enable_fbc=1"
        "i915.enable_psr=1"
        "intel_pstate=active"
    ];
    services.thermald.enable = lib.mkDefault (config.nihil.gpu == "intel" || config.nihil.gpu == "auto");
    hardware.graphics.enable = lib.mkDefault true;
    hardware.graphics.extraPackages = lib.optionals (config.nihil.gpu == "intel" || config.nihil.gpu == "auto") (with pkgs; [
        intel-media-driver intel-vaapi-driver libva-vdpau-driver vpl-gpu-rt
    ]);
    hardware.graphics.extraPackages32 = lib.optionals (config.nihil.gpu == "intel" || config.nihil.gpu == "auto") (with pkgs; [
        intel-media-driver intel-vaapi-driver
    ]);

    # Power management
    services.tlp = {
        enable = false;
        settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        } // lib.optionalAttrs (config.nihil.gpu == "intel" || config.nihil.gpu == "auto") {
            INTEL_GPU_MIN_FREQ_ON_AC = 0;
            INTEL_GPU_MAX_FREQ_ON_AC = 0;
        };
    };

    services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", RUN+="${pkgs.coreutils}/bin/chgrp nihil-leds /sys/class/leds/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"

        ACTION=="add|change", KERNEL=="sd[a-z]*|nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"
    '';
    
    # uinput for KVM (disabled autostart, but keep support)
    hardware.uinput.enable = true;
}
