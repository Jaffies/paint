local function load(path)
	AddCSLuaFile(path)
	if CLIENT then
		include(path)
	end
end

if CLIENT and BRANCH ~= 'x86-64' then
	print('paint library detoured mesh.Position to support (x, y, z) overload because gmod hasn\'t updated yet on non x64-86')
	local vec = Vector()
	local vecSetUnpacked = vec.SetUnpacked


	mesh.OldPosition = mesh.OldPosition or mesh.Position
	---@param x number|Vector
	---@param y? number
	---@param z? number
	---@overload fun(x: Vector)
	function mesh.Position(x, y, z)
		if y == nil then
			---@cast x Vector
			mesh.OldPosition(x)
			return
		end
		---@cast y number
		---@cast z number
		---@cast x number
		vecSetUnpacked(vec, x, y, z)
		mesh.OldPosition(vec)
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

local VERSION = 1.07

print('paint library has been loaded. Version is: ' .. VERSION)
print('copyright @jaffies, aka @mikhail_svetov')