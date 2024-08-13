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

local VERSION = 1.09

print('paint library has been loaded. Version is: ' .. VERSION)
print('copyright @jaffies, aka @mikhail_svetov')