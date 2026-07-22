-- Primary monitor
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080",
	position = "0x0",
	scale = 1.2,
})

-- Any connected monitor
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
	mirror = "eDP-1",
})
