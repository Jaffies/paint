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

-- Load Examples
load('paint/examples/examples_cl.lua')

-- Load custom UI elements
load('paint/examples/vgui/markup_richtext_cl.lua')

-- Load tabs
-- Order here determines tab order
load('paint/examples/controls/lines_cl.lua')
load('paint/examples/controls/rects_cl.lua')
load('paint/examples/controls/rounded_boxes_cl.lua')
load('paint/examples/controls/outlines_cl.lua')
load('paint/examples/controls/batch_cl.lua')
load('paint/examples/controls/blur_cl.lua')
load('paint/examples/controls/main_cl.lua')

--#endregion Load Examples

local VERSION = 1.10

local function coloredMsgC(text)
	local prevRandom
	for i = 1, #text do
		local nowRandom = math.random(0, 360)
		nowRandom = (nowRandom + (prevRandom or nowRandom)) / 2
		prevRandom = nowRandom

		MsgC(HSVToColor(nowRandom, 0.5, 1), string.sub(text, i, i) )
	end
	MsgC('\n')
end

coloredMsgC('paint library has been loaded. Version is: ' .. VERSION)
coloredMsgC('copyright @jaffies, aka @mikhail_svetov')
MsgC(Color(255, 20, 20), '[Warning] ', color_white, 'paint library in recent update (1.1) removed safeguards for radius in outlines/roundedboxes.\n', Color(100, 255, 100), 'It will likely break stuff. Sorry for that.\n')