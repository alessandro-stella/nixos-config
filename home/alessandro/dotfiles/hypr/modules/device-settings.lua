-- NVIDIA / Wayland
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")

-- Workspaces
hl.workspace_rule({
	workspace = "1",
	monitor = "DP-3",
})

hl.workspace_rule({
	workspace = "9",
	monitor = "DP-1",
	default = true,
})

-- Autostart
hl.on("hyprland.start", function()
	-- Focus main monitor
	hl.exec_cmd("sleep 0.5 && hyprctl dispatch 'hl.dsp.focus({ monitor = \"DP-3\" })'")

	-- Start btop as sensor panel
	hl.exec_cmd(
		'sleep 5 && hyprctl dispatch \'hl.dsp.exec_cmd("kitty --class=btop-panel --title=btop-panel btop", { workspace = "9 silent", fullscreen = true })\''
	)
end)
