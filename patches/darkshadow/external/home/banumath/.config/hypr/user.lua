-- Your own Hyprland settings. DarkShadow's Shell never changes this file (updates leave it alone).
-- It is loaded last, so whatever you set here wins over the shell's config. Put your changes here instead of
-- hyprland.lua (an update brings a new hyprland.lua; your old one is in ~/.config/darkshadows-shell-backup-*).
-- Docs: https://wiki.hypr.land
--
-- Examples:
-- hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
-- hl.config({ input = { repeat_delay = 300, repeat_rate = 40 } })
-- hl.config({ general = { gaps_in = 4, gaps_out = 8 } })
-- hl.on("hyprland.start", function() hl.exec_cmd("discord") end)

-- SUPER alone opens the DarkShadow launcher
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("$HOME/.local/bin/rice-launch"), { release = true })
