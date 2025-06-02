local function load(path)
	AddCSLuaFile(path)
	if CLIENT then
		include(path)
	end
end

load('paint/main_cl.lua')
load('paint/batch_cl.lua')
load('paint/lines_cl.lua')
load('paint/rects_cl.lua')
load('paint/rounded_boxes_cl.lua')
load('paint/outlines_cl.lua')
load('paint/blur_cl.lua')
load('paint/circles_cl.lua')
load('paint/svg_cl.lua')
load('paint/masks_cl.lua')
load('paint/downsampling_cl.lua')

--#endregion Load Examples

local VERSION = 1.12
local SHOW_MSG = true

if SHOW_MSG then
	local function coloredMsgC(text)
		local prevRandom
		for i = 1, #text do
			local nowRandom = math.random(0, 360)
			nowRandom = (nowRandom + (prevRandom or nowRandom)) / 2
			prevRandom = nowRandom
			MsgC(HSVToColor(nowRandom, 0.5, 1), string.sub(text, i, i))
		end
		MsgC('\n')
	end
	coloredMsgC('paint library has been loaded. Version is: ' .. VERSION)
	coloredMsgC('copyright @jaffies, aka @mikhail_svetov')
end
