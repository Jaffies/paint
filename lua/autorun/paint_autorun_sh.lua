local function load(path)
	AddCSLuaFile(path)
	if CLIENT then
		include(path)
	end
end

if CLIENT and BRANCH ~= 'x64-86' then
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

-- EXAMPLES
load('paint/examples/examples_cl.lua')

local VERSION = 0.99

print('paint library has been loaded. Versions is: ' .. VERSION)
print('copyright @jaffies, aka @mikhail_svetov')