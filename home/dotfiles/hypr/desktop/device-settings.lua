-- Default workspaces
hl.workspace_rule({
	workspace = "1",
	monitor = "DP-3",
	default = true,
})

hl.workspace_rule({
	workspace = "9",
	monitor = "DP-1",
	default = true,
})

-- Autostart
hl.on("hyprland.start", function()
	-- Focus main monitor
	hl.dispatch(hl.dsp.focus({
		monitor = "DP-3",
	}))

	-- Set btop as sensor panel
	hl.exec_cmd(
		'sleep 5 && hyprctl dispatch \'hl.dsp.exec_cmd("foot --title=btop-panel btop", { workspace = "9 silent", fullscreen = true })\''
	)
end)
