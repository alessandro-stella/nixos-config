local mainMod = _G.mainMod or "SUPER"

-- Discord
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))

-- Spotify
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("spotify"))
