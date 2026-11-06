-- Keybindings + the window rules that belong to them.

local mod = "SUPER"
local function k(keys) return mod .. " + " .. keys end
local exec = hl.dsp.exec_cmd

---- SPECIAL WORKSPACES ----
hl.bind(k("S"),         hl.dsp.workspace.toggle_special("quick"))
hl.bind(k("I"),         hl.dsp.workspace.toggle_special("home"))
hl.bind(k("SHIFT + I"), hl.dsp.window.move({ workspace = "special:home" }))

---- APPS ----
hl.bind(k("Q"),         exec("ghostty"))
hl.bind(k("SHIFT + Q"), exec("ghostty --class=com.ghostty.floating")) -- floating terminal
hl.bind(k("E"),         exec("thunar"))
hl.bind(k("SPACE"),     exec("wofi"))
hl.bind(k("SHIFT + P"), exec("hyprpicker"))
hl.bind(k("W"),         exec("brave-beta --profile-directory='Default'"))
hl.bind(k("R"),         exec("obsidian --ozone-platform-hint=auto"))
hl.bind(k("SHIFT + N"), exec("swaync-client -t -sw"))
hl.bind(k("SHIFT + E"), exec("bemoji -t"))
hl.bind(k("CONTROL + SPACE"), exec("~/.config/hypr/scripts/switch_layout.sh"))

-- floating terminal + thunar: float, 60%x65%, centered
for _, class in ipairs({ "^(com\\.ghostty\\.floating)$", "^(thunar)$" }) do
    hl.window_rule({
        match  = { class = class },
        float  = true,
        size   = "(monitor_w*0.6) (monitor_h*0.65)",
        center = true,
    })
end

---- WINDOW MANAGEMENT ----
hl.bind(k("X"),                 hl.dsp.window.close())
hl.bind(k("SHIFT + CTRL + M"),  hl.dsp.exit())
hl.bind(k("V"),                 hl.dsp.window.float({ action = "toggle" }))
hl.bind(k("F"),                 hl.dsp.window.fullscreen())
hl.bind(k("P"),                 hl.dsp.window.pseudo())
hl.bind("ALT + TAB",            hl.dsp.window.cycle_next())

---- WAYBAR / DOCK ----
hl.bind(k("SHIFT + B"), exec("/home/bastel/.config/hypr/scripts/toggle_dock.sh"))
hl.bind(k("B"),         exec("/home/bastel/.config/hypr/scripts/toggle_waybar.sh"))

---- LOCK ----
hl.bind(k("O"),                exec("swaylock --image ~/Wallpapers/tuksgrey.jpg --scaling fill"))
hl.bind(k("SHIFT + O"),        exec("swaylock -f -c 000000 --scaling fill --clock --indicator"))
hl.bind(k("SHIFT + CTRL + O"), exec("wlogout"))

---- SCREENSHOTS ----
hl.bind(k("SHIFT + CTRL + S"), exec([[bash -c 'FILE=~/Photos/Screenshots/Screenshot$(date +%Y-%m-%d%H-%M-%S).png; GEOM=$(slurp -b 00000088 -w 0); sleep 0.05; grim -s 1 -g "$GEOM" "$FILE" && wl-copy < "$FILE" && notify-send "Screenshot saved and copied" "$FILE"']]))
hl.bind(k("SHIFT + S"),        exec([[bash -c 'GEOM=$(slurp -b 00000088 -w 0); sleep 0.05; grim -s 1 -g "$GEOM" - | wl-copy && notify-send "Screenshot copied to clipboard"']]))

---- HARDWARE KEYS (ROG G15 keycodes) ----
hl.bind("code:121", exec("pamixer -t"))                   -- speaker mute
hl.bind("code:122", exec("pamixer -d 5"))                 -- volume down
hl.bind("code:123", exec("pamixer -i 5"))                 -- volume up
hl.bind("code:248", exec("pamixer --default-source -t"))  -- mic mute
hl.bind("code:232", exec("brightnessctl set 5%-"))        -- brightness down
hl.bind("code:233", exec("brightnessctl set 5%+"))        -- brightness up
hl.bind(k("code:232"), exec("brightnessctl set 100%-"))
hl.bind(k("code:233"), exec("brightnessctl set 50%+"))

---- FOCUS (vim keys) ----
hl.bind(k("H"), hl.dsp.focus({ direction = "left" }))
hl.bind(k("L"), hl.dsp.focus({ direction = "right" }))
hl.bind(k("K"), hl.dsp.focus({ direction = "up" }))
hl.bind(k("J"), hl.dsp.focus({ direction = "down" }))

---- WORKSPACES ----
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(k(key),             hl.dsp.focus({ workspace = i }))
    hl.bind(k("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
end

hl.bind(k("A"),         hl.dsp.focus({ workspace = "r-1" }))
hl.bind(k("D"),         hl.dsp.focus({ workspace = "r+1" }))
hl.bind(k("SHIFT + A"), hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(k("SHIFT + D"), hl.dsp.window.move({ workspace = "r+1" }))

---- MOUSE ----
hl.bind(k("mouse:272"),         hl.dsp.window.drag(),   { mouse = true })
hl.bind(k("SHIFT + mouse:272"), hl.dsp.window.resize(), { mouse = true })
