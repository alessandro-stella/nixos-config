-- Monitor configurations

hl.monitor({
	output = "DP-3",
	mode = "1920x1080@143.98Hz",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@74.97Hz",
	position = "-1920x0",
	scale = 1,
})

hl.monitor({
	output = "DP-1",
	mode = "800x1280@59.97Hz",
	position = "-1920x1080",
	scale = 1,
	transform = 1,
})
