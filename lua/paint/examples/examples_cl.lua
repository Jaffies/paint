local examples = {}
local paint = paint

--- NO clean code here
--- Since it's made only for example
function examples.create()
	local frame = vgui.Create('DFrame')

	frame:SetSize(640, 480)
	frame:Center()
	frame:SetTitle('Paint Library Examples')
	frame:SetSizable(true)

	local propertySheet = frame:Add('DPropertySheet')
	propertySheet:Dock(FILL)

	for k, v in pairs(examples.controls) do
		propertySheet:AddSheet(v.name, v.func(), v.icon)
	end
end

examples.controls = {}
function examples.addControl(name, func, icon)
	examples.controls[name] = {name = name, func = func, icon = icon}
end

--#region Load Examples

local function load(path)
	AddCSLuaFile(path)
	if CLIENT then
		include(path)
	end
end

load('paint/examples/vgui/markup_richtext_cl.lua')
load('paint/examples/controls/lines_cl.lua')
load('paint/examples/controls/rects_cl.lua')
load('paint/examples/controls/rounded_boxes_cl.lua')
load('paint/examples/controls/outlines_cl.lua')
load('paint/examples/controls/batch_cl.lua')
load('paint/examples/controls/blur_cl.lua')
load('paint/examples/controls/main_cl.lua')

--#endregion Load Examples