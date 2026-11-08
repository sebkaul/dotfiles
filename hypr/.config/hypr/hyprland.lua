--       ░▒▒▒▒▒▒▒░░░
--     ░░▒▒▒▒▒▒░░░░▓▓
--    ░░▒▒▒▒▒░░░░░▓▓
--   ░░░▒▒▒░░░░░░▓▓
--   ░░░▒▒▒░░░░░▓▓▓▓▓▓
--    ░░░▒▒░░░░▓▓   ▓▓
--     ░░░▒▒░░▓▓   ▓▓
--       ░░▒▒▓▓   ▓▓ YPRLAND config (Lua, Hyprland >= 0.57)
--
-- Ported 1:1 from the old hyprland.conf / keybindings.conf / animations.conf.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "eDP-1",    mode = "1920x1080@60", position = "0x0",  scale = 1 })
hl.monitor({ output = "DP-1",     mode = "1360x780@60",  position = "auto", scale = "auto" })
-- old line had a bare "mirror" with no target; add mirror = "eDP-1" if you want mirroring
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@30", position = "auto", scale = 2 })


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- bar / tray
    hl.exec_cmd("waybar")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet --no-agent --indicator")
    hl.exec_cmd("sleep 2 && nwg-dock-hyprland -i 32 -nolauncher -l top -mb -49")

    -- wallpaper
    hl.exec_cmd("swaybg -o eDP-1 -i /home/bastel/Wallpapers/tuksgrey.jpg -m fill")

    -- notifications
    hl.exec_cmd("swaync")
    hl.exec_cmd("/home/bastel/.local/bin/battery_notify.sh")

    -- user apps
    hl.exec_cmd("brave-beta --profile-directory='Default'")
    hl.exec_cmd("signal-desktop")
    hl.exec_cmd("nextcloud --background")
    hl.exec_cmd("obsidian")

    -- system
    hl.exec_cmd("sudo modprobe cp210x")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("iio-hyprland") -- automatic screen rotation
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("GDK_SCALE", "1")
hl.env("XCURSOR_SIZE", "21")
hl.env("GDK_DPI_SCALE", "1")
hl.env("GTK_THEME", "Fluent-round-Dark-compact")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    xwayland = {
        force_zero_scaling = true, -- unscale XWayland
    },

    input = {
        kb_layout  = "us,no",
        kb_variant = ",nodeadkeys",
        kb_rules   = "",

        follow_mouse = 1,

        accel_profile = "flat",
        sensitivity   = 0.25, -- -1.0 - 1.0, 0 means no modification

        touchpad = {
            natural_scroll       = false,
            disable_while_typing = false,
            scroll_factor        = 0.2,
        },
    },

    general = {
        gaps_in     = 4,
        gaps_out    = 7,
        border_size = 1,
        col = {
            active_border   = "rgba(eeeeee44)",
            inactive_border = "rgba(00000044)",
        },
        layout = "dwindle",
    },

    misc = {
        disable_hyprland_logo  = true,
        animate_manual_resizes = true,
        vrr                    = 0,
    },

    ecosystem = {
        no_update_news = true,
    },

    render = {
        -- 0.57 default (1) flips the monitor into HDR when a fullscreen app
        -- advertises HDR (Brave/Signal/Electron): ~2s black, then dim/washed out.
        cm_auto_hdr = 0,
    },

    decoration = {
        rounding = 14,
    },

    dwindle = {
        preserve_split = true,
    },

    gestures = {
        workspace_swipe_forever = true,
    },
})

require("animations")
require("keybindings")
