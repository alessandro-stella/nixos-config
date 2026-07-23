-- Primary monitor
hl.monitor({
	output = "DP-3",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
})

-- Secondary monitor
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@75",
	position = "-1920x0",
	scale = 1,
})

-- Sensor panel
hl.monitor({
	output = "DP-1",
	mode = "800x1280@60",
	position = "-1920x1080",
	scale = 1.25,
	transform = 1,
})
