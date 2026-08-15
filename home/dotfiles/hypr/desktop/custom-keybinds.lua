-- Open apps
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))

-- Corsair VOID Wireless V2
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
