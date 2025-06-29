---@diagnostic disable: deprecated
local paint = paint --[[@as paint]]

---	What makes paint rectangles different from surface and draw rectangles?
---	1) Support for linear, per-corner gradients!
---	2) Vastly improved performance when drawing multiple rectangles, thanks to batching!
---
--- Examples!
---
--- Simple Example:
---
---Drawing an uncolored rectangle with a material, a rectangle with a material and per-corner colors, and a rectangle with just per-color corners.
---```lua
--- 	local mat = Material( "icon16/application_xp.png" )
--- 	paint.rects.drawRect( 0, 0, 64, 64, color_white, mat, 0.5, 0, 1, 0.75 )
--- 	paint.rects.drawRect( 64, 0, 64, 64, { Color(255, 0, 0 ), Color( 0, 255, 0 ), Color( 0, 0, 255 ), color_white }, mat )
--- 	paint.rects.drawRect( 128, 0, 64, 64, { Color(255, 0, 0 ), Color( 0, 255, 0 ), Color( 0, 0, 255 ), color_white } )
---```
---Batched Example
---
---Drawing 25 rectangles with improved performance by using batching.
---```lua
---paint.rects.startBatching()
---	for i = 1, 25 do
---		paint.rects.drawRect( i * 15, 0, 15, 50, { COLOR_WHITE, COLOR_BLACK, COLOR_BLACK, COLOR_WHITE } )
---	end
---paint.rects.stopBatching()
---```
---@class paint.rects
local rects = {}

do
	--[[
		Purpose: makes a table, containing Rectangular mesh.
		Same params as drawSingleRect, except:
			w, h are replaced to endX, endY.
				They are end coordinates, not width, or height.
				It means they are calculated as startX + w and startY + h in drawSingleRect
			colors can accept only table of colors.
			And there's no material parameter
	]]

	--[[ 	function rects.generateRectMesh(startX, startY, endX, endY, colors, u1, v1, u2, v2)

		local leftBottom = { pos = vector(startX, endY), color = colors[4], u = u1, v = v2 }
		local rightTop = { pos = vector(endX, startY), color = colors[2], u = u2, v = v1 }

		return {
			leftBottom, -- first triangle
			{ pos = vector(startX, startY), color = colors[1], u = u1, v = v1 },
			rightTop,

			leftBottom, -- second one
			rightTop,
			{ pos = vector(endX, endY), color = colors[3], u = u2, v = v2 }
		}
	end--]]

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshTexCoord = mesh.TexCoord
	local meshAdvanceVertex = mesh.AdvanceVertex

	local PRIMITIVE_QUADS = MATERIAL_QUADS

	--- Helper function to unpack color
	---@param color Color
	---@return integer r
	---@return integer g
	---@return integer b
	---@return integer a
	local function unpackColor(color) return color.r, color.g, color.b, color.a end -- FindMetaTable still works shitty.

	--- generates quad onto IMesh
	---@param mesh IMesh
	---@param startX number
	---@param startY number
	---@param endX number
	---@param endY number
	---@param colors gradients # Color or colors used by gradient. Can be a single color, or a table of colors.
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@param skew number? sets skew for top side of rect.
	---@param topSize number? overrides size for top side of rect
	---@private Internal variable. Not meant to use outside
	function rects.generateRectMesh(mesh, startX, startY, endX, endY, colors, u1, v1, u2, v2, skew, topSize)
		local startTopX = startX + (skew or 0)
		local endTopX = topSize and topSize > 0 and startTopX + topSize or endX + (skew or 0)

		meshBegin(mesh, PRIMITIVE_QUADS, 1)
		meshPosition(startX, endY, 0)
		meshColor(unpackColor(colors[4]))
		meshTexCoord(0, u1, v2)
		meshAdvanceVertex()

		meshPosition(startTopX, startY, 0)
		meshColor(unpackColor(colors[1]))
		meshTexCoord(0, u1, v1)
		meshAdvanceVertex()

		meshPosition(endTopX, startY, 0)
		meshColor(unpackColor(colors[2]))
		meshTexCoord(0, u2, v1)
		meshAdvanceVertex()

		meshPosition(endX, endY, 0)
		meshColor(unpackColor(colors[3]))
		meshTexCoord(0, u2, v2)
		meshAdvanceVertex()
		meshEnd()
	end
end

do
	-- purpose: draws batched rectangle.
	local incrementZ = paint.incrementZ
	local batch = paint.batch

	--- Adds rect to triangle batch queue
	---@private Internal variable. Not meant to use outside
	---@param startX number
	---@param startY number
	---@param endX number
	---@param endY number
	---@param colors gradients # Color or colors used by gradient. Can be a single color, or a table of colors
	function rects.drawBatchedRect(startX, startY, endX, endY, colors, u1, v1, u2, v2, skew, topSize)
		local tab = batch.batchTable
		local len = tab[0]
		local z = incrementZ()

		local startTopX = startX + (skew or 0)
		local endTopX = topSize and topSize > 0 and startTopX + topSize or endX + (skew or 0)

		tab[len + 1] = startX
		tab[len + 2] = endY
		tab[len + 3] = z
		tab[len + 4] = colors[4]

		tab[len + 5] = startTopX
		tab[len + 6] = startY
		tab[len + 7] = colors[1]

		tab[len + 8] = endTopX
		tab[len + 9] = startY
		tab[len + 10] = colors[2]

		tab[len + 11] = u1
		tab[len + 12] = v2
		tab[len + 13] = u1
		tab[len + 14] = v1
		tab[len + 15] = u2
		tab[len + 16] = v1
		tab[len + 17] = batch.getDrawCell()


		tab[len + 18] = startX
		tab[len + 19] = endY
		tab[len + 20] = z
		tab[len + 21] = colors[4]

		tab[len + 22] = endX
		tab[len + 23] = startY
		tab[len + 24] = colors[2]

		tab[len + 25] = endX
		tab[len + 26] = endY
		tab[len + 27] = colors[3]

		tab[len + 28] = u1
		tab[len + 29] = v2
		tab[len + 30] = u2
		tab[len + 31] = v1
		tab[len + 32] = u2
		tab[len + 33] = v2
		tab[len + 34] = batch.getDrawCell()

		tab[0] = len + 34
	end
end

do
	---@type {[string] : IMesh}
	local cachedRectMeshes = {}
	local defaultMat = paint.defaultMaterial or Material('vgui/white')

	--[[
		Purpose: draws Rectangle on screen.
		Params:
			x - startX (absolute screen position)
			y - startY (too)
			w - width
			h - height
			colors - color table (or just color).
				if table of colors is supplied, then it will be gradient one
					Basically, color per corner. order is: left top, right top, right bottom, left bottom
				if single color supplied, then will be solid color.
			u1, v1, u2, v2 - UV's
	-- ]]

	local format = string.format

	local meshConstructor = Mesh
	local meshDraw = FindMetaTable('IMesh') --[[@as IMesh]].Draw

	local renderSetMaterial = render.SetMaterial

	local generateRectMesh = rects.generateRectMesh

	-- why is it a standalone function?
	-- This GETS JIT compiled as it does not contain any C API code and it does not have %s in them
	-- It means string.format gets compiled as native code, and speed of that will be 100 faster than default
	-- Mastermind tricks?

	--- Function used to get id of rect's IMesh. Used as tricky optimisation to make it JIT compiled
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param color1 Color
	---@param color2 Color
	---@param color3 Color
	---@param color4 Color
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@param skew number sets elevation for top side of rect.
	---@param topSize number overrides size for top side of rect
	---@return string
	local function getId(x, y, w, h, color1, color2, color3, color4, u1, v1, u2, v2, skew, topSize)
		return format('%f;%f;%f;%f;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f;%f;%f',
			x, y, w, h,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			color3.r, color3.g, color3.b, color3.a,
			color4.r, color4.g, color4.b, color4.a,
			u1, v1, u2, v2, skew, topSize
		)
	end

	--- Draws single rect (quad)
	---@private Internal variable. Not meant to use outside
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors gradients # Color or colors used by gradient. Can be a single color, or a table of colors
	---@param material? IMaterial
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@param skew number sets elevation for top side of rect.
	---@param topSize number overrides size for top side of rect
	---@overload fun(x : number, y : number, w : number, h : number, colors: gradients, material?: Material)
	function rects.drawSingleRect(x, y, w, h, colors, material, u1, v1, u2, v2, skew, topSize)
		local id = getId(x, y, w, h, colors[1], colors[2], colors[3], colors[4], u1, v1, u2, v2, skew, topSize)

		local mesh = cachedRectMeshes[id]
		if mesh == nil then
			mesh = meshConstructor()

			generateRectMesh(mesh, x, y, x + w, y + h, colors, u1, v1, u2, v2, skew, topSize)

			cachedRectMeshes[id] = mesh
		end

		renderSetMaterial(material or defaultMat)
		meshDraw(mesh)
	end

	timer.Create('paint.rectMeshGarbageCollector' .. SysTime(), 60, 0, function()
		for k, v in pairs(cachedRectMeshes) do
			cachedRectMeshes[k] = nil
			v:Destroy()
		end
	end)
end

do
	-- batching doesn't support materials at all!
	local drawSingleRect = rects.drawSingleRect
	local drawBatchedRect = rects.drawBatchedRect

	local batch = paint.batch

	local getColorTable = paint.getColorTable

	--- Main function to draw rects
	---@param x number # start X position of the rectangle
	---@param y number # start Y position of the rectangle
	---@param w number # width of the rectangle
	---@param h number # height of the rectangle
	---@param colors gradients # Either a table of Colors, or a single Color.
	---      If it is a table, it must have 4 elements, one for each corner.
	---
	---      The order of the corners is:
	---            1. Top-Left
	---            2. Top-Right
	---            3. Bottom-Right
	---            4. Bottom-Left
	---@param material? IMaterial # Either a Material, or nil.  Default: vgui/white
	---@param u1 number # The texture U coordinate of the Top-Left corner of the rectangle. Default : 0
	---@param v1 number # The texture V coordinate of the Top-Left corner of the rectangle. Default : 0
	---@param u2 number # The texture U coordinate of the Bottom-Right corner of the rectangle. Default : 1
	---@param v2 number # The texture V coordinate of the Bottom-Right corner of the rectangle. Default : 1
	---@param skew number? sets elevation for top side of rect.
	---@param topSize number? overrides size for top side of rect
	---@overload fun(x : number, y : number, w : number, h : number, colors: gradients, material? : IMaterial) # Overloaded variant without UV's. They are set to 0, 0, 1, 1
	function rects.drawRect(x, y, w, h, colors, material, u1, v1, u2, v2, skew, topSize)
		if colors[4] == nil then
			---@cast colors Color
			---@diagnostic disable-next-line: cast-local-type
			colors = getColorTable(4, colors)
		end
		---@cast colors paint.gradientsTable

		if u1 == nil then
			u1, v1 = 0, 0
			u2, v2 = 1, 1
		end

		skew, topSize = skew or 0, topSize or 0

		if batch.batching then
			drawBatchedRect(x, y, x + w, y + h, colors, u1, v1, u2, v2, skew, topSize)
		else
			drawSingleRect(x, y, w, h, colors, material, u1, v1, u2, v2, skew, topSize)
		end
	end
end

paint.rects = rects
