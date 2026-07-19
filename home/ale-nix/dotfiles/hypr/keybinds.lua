local mainMod = _G.mainMod or "SUPER"

-- Apps and system
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("kitty -o allow_remote_control=yes"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("swaylock -K"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave-origin --password-store=basic"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -theme ~/.config/rofi/app_launcher.rasi -show drun"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash -c $HOME/.config/scripts/theme_changer/theme_chooser.sh"))
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd(
		"cliphist list | rofi -dmenu -theme ~/.config/rofi/clipboard.rasi | cliphist decode | wl-copy && wtype -M ctrl v -m ctrl"
	)
)

-- Move focus with mainMod + vim keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Workspaces 1-10; key 0 maps to workspace 10
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Open custom websites as apps
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("brave-origin --password-store=basic --app=https://chat.openai.com/"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("brave-origin --password-store=basic --app=https://gemini.google.com/"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("brave-origin --password-store=basic --app=https://teams.microsoft.com/v2/"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("brave-origin --password-store=basic --app=https://web.whatsapp.com/"))

require("modules.custom-keybinds")
