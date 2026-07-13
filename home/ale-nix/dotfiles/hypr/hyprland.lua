-- Device-specific imports
require("modules.device-settings")
require("modules.monitors")

-- Customizations
require("modules.dynamic-border")

-- Starting scripts
hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/xdg-portals.sh") -- Make sure the correct portals are running
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Wayland magic
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- More Wayland magic
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1") -- graphical sudo elevation
	hl.exec_cmd("blueman-applet") -- Systray app for BT
	hl.exec_cmd("nm-applet --indicator") -- Systray app for Network/Wifi
	hl.exec_cmd("waybar") -- Status bar
	hl.exec_cmd("swaync") -- Notification center
	hl.exec_cmd(
		"awww-daemon && awww img ~/.config/themes/current_wallpaper/wallpaper.png --transition-type fade --transition-duration 0.5"
	) -- Wallpaper

	-- Utility and customization scripts
	hl.exec_cmd("~/.config/scripts/clean_screenshots.sh")
	hl.exec_cmd("~/.config/scripts/clean_java_workspaces.sh")
	hl.exec_cmd("~/.config/scripts/update_configs.sh")

	-- Clipboard
	hl.exec_cmd("cliphist wipe")
	hl.exec_cmd("wl-paste --type text -w cliphist store")
end)

hl.config({
	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},

	input = {
		kb_layout = "it",
		follow_mouse = 1,
		repeat_rate = 50,
		repeat_delay = 300,
		accel_profile = "flat",
	},

	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		col = {
			inactive_border = "rgba(595959aa)",
		},
		layout = "dwindle",
	},

	misc = {
		disable_hyprland_logo = true,
	},

	decoration = {
		rounding = 5,
		blur = {
			enabled = true,
			size = 7,
			passes = 4,
			new_optimizations = true,
		},
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		new_status = "master",
	},
})

hl.curve("myBezier", { type = "bezier", points = { { 0.10, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default" })

-- Set utilities to floating
hl.window_rule({ name = "float-pavucontrol", match = { class = "pavucontrol" }, float = true })
hl.window_rule({ name = "float-blueman-manager", match = { class = "blueman-manager" }, float = true })
hl.window_rule({ name = "float-nm-connection-editor", match = { class = "nm-connection-editor" }, float = true })

-- Disable rofi animation for resizing
hl.layer_rule({ name = "rofi-no-anim", match = { namespace = "rofi" }, no_anim = true })

-- Keybinds
_G.mainMod = "SUPER"
require("keybinds")
