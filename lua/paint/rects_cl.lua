local paint = paint--[[@as paint]]

---@class rects
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

	local vector = Vector

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
	function rects.generateRectMesh(mesh, startX, startY, endX, endY, colors, u1, v1, u2, v2)
		meshBegin(mesh, PRIMITIVE_QUADS, 1)
			meshPosition(startX, endY, 0)
			meshColor(unpackColor(colors[4]))
			meshTexCoord(0, u1, v2)
			meshAdvanceVertex()

			meshPosition(startX, startY, 0)
			meshColor(unpackColor(colors[1]))
			meshTexCoord(0, u1, v1)
			meshAdvanceVertex()

			meshPosition(endX, startY, 0)
			meshColor(unpackColor(colors[2]))
			meshTexCoord(0, u2, v1)
			meshAdvanceVertex()

			meshPosition(endX, endY, 0)
			meshColor(unpackColor(colors[3]))
			meshTexCoord(0, u2, v2)
			meshAdvanceVertex()
		meshEnd()
	end

	--Quad batching (NON TRIANGLE, used for only rects!)

	local mat = Material('vgui/white')
	local renderSetMaterial = render.SetMaterial

	--- Draws batched rects (quads)
	---@param array table # {x, y, endX, endY, color1, color2, color3, color4, ...}
	function rects.drawBatchedRects(array)
		renderSetMaterial(mat)
		meshBegin(PRIMITIVE_QUADS, array[0] / 8)
			for i = 1, array[0], 8 do
				local x, y, endX, endY = array[i], array[i + 1], array[i + 2], array[i + 3]
				local color1, color2, color3, color4 = array[i + 4], array[i + 5], array[i + 6], array[i + 7]

				meshPosition(x, endY, 0)
				meshColor(color4.r, color4.g, color4.b, color4.a)

				meshAdvanceVertex()

				meshPosition(x, y, 0)
				meshColor(color1.r, color1.g, color1.b, color1.a)

				meshAdvanceVertex()

				meshPosition(endX, y, 0)
				meshColor(color2.r, color2.g, color2.b, color2.a)

				meshAdvanceVertex()

				meshPosition(endX, endY, 0)
				meshColor(color3.r, color3.g, color3.b, color3.a)

				meshAdvanceVertex()
			end
		meshEnd()
	end
end

do
	-- purpose: draws batched rectangle.
	local incrementZ = paint.incrementZ
	local batch = paint.batch

	--- Adds rect to triangle batch queue
	---@param startX number
	---@param startY number
	---@param endX number
	---@param endY number
	---@param colors gradients # Color or colors used by gradient. Can be a single color, or a table of colors
	function rects.drawBatchedRect(startX, startY, endX, endY, colors)
		local tab = batch.batchTable
		local len = tab[0]
		local z = incrementZ()

		tab[len + 1] = startX
		tab[len + 2] = endY
		tab[len + 3] = z
		tab[len + 4] = colors[4]

		tab[len + 5] = startX
		tab[len + 6] = startY
		tab[len + 7] = colors[1]

		tab[len + 8] = endX
		tab[len + 9] = startY
		tab[len + 10] = colors[2]

		tab[len + 11] = startX
		tab[len + 12] = endY
		tab[len + 13] = z
		tab[len + 14] = colors[4]

		tab[len + 15] = endX
		tab[len + 16] = startY
		tab[len + 17] = colors[2]

		tab[len + 18] = endX
		tab[len + 19] = endY
		tab[len + 20] = colors[3]

		tab[0] = len + 20
	end
end

do
	---@type {[string] : IMesh}
	local cachedRectMeshes = {}
	local defaultMat = Material('vgui/white')

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
	local meshDraw = FindMetaTable('IMesh').Draw

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
	---@return string
	local function getId(x, y, w, h, color1, color2, color3, color4, u1, v1, u2, v2)
		return format('%u;%u;%u;%u;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f',
			x, y, w, h,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			color3.r, color3.g, color3.b, color3.a,
			color4.r, color4.g, color4.b, color4.a,
			u1, v1, u2, v2
		)
	end

	--- Draws single rect (quad)
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
	---@overload fun(x : number, y : number, w : number, h : number, colors: gradients, material?: Material)
	function rects.drawSingleRect(x, y, w, h, colors, material, u1, v1, u2, v2)
		local id = getId(x, y, w, h, colors[1], colors[2], colors[3], colors[4], u1, v1, u2, v2)

		local mesh = cachedRectMeshes[id]
		if mesh == nil then
			mesh = meshConstructor()

			generateRectMesh(mesh, x, y, x + w, y + h, colors, u1, v1, u2, v2)

			cachedRectMeshes[id] = mesh
		end

		renderSetMaterial(material or defaultMat)
		meshDraw(mesh)
	end

	timer.Create('paint.rectMeshGarbageCollector', 60, 0, function()
		for k, v in pairs(cachedRectMeshes) do
			cachedRectMeshes[k] = nil
			v:Destroy()
		end
	end)
end

do --- Rect specific batching
	-- Starts quad batching. Literally only for MEGA specific cases. Consider using paint.batch.startBatching
	function rects.startBatching()
		rects.batching = {
			[0] = 0
		}
		rects.isBatching = true
	end

	local drawBatchedRects = rects.drawBatchedRects

	--- Stops quad batching. Litterally only for MEGA specific cases. Consider using paint.batch.startBatching
	function rects.stopBatching()
		rects.isBatching = false

		drawBatchedRects(rects.batching)
	end

	--- Adds rect (quad) to quad batching queue (rects.startBatching)
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors Color[]
	function rects.drawQuadBatchedRect(x, y, w, h, colors)
		local tab = rects.batching
		local len = tab[0]

		tab[len + 1] = x
		tab[len + 2] = y
		tab[len + 3] = x + w
		tab[len + 4] = y + h
---@diagnostic disable-next-line: assign-type-mismatch
		tab[len + 5] = colors[1]
---@diagnostic disable-next-line: assign-type-mismatch
		tab[len + 6] = colors[2]
---@diagnostic disable-next-line: assign-type-mismatch
		tab[len + 7] = colors[3]
---@diagnostic disable-next-line: assign-type-mismatch
		tab[len + 8] = colors[4]

		tab[0] = len + 8
	end
end

do
	-- batching doesn't support materials at all!
	local drawSingleRect = rects.drawSingleRect
	local drawBatchedRect = rects.drawBatchedRect

	local drawQuadBatchedRect = rects.drawQuadBatchedRect

	local batch = paint.batch

	--- Main function to draw rects
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors gradients # Color or colors used by gradient. Can be a single color, or a table of colors
	---@param material? IMaterial # vgui/white will be used as default material
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@overload fun(x : number, y : number, w : number, h : number, colors: gradients, material? : IMaterial) # Overloaded variant without UV's. They are set to 0, 0, 1, 1
	function rects.drawRect(x, y, w, h, colors, material, u1, v1, u2, v2)
		if colors[4] == nil then
			colors[1] = colors
			colors[2] = colors
			colors[3] = colors
			colors[4] = colors
		end

		if u1 == nil then
			u1, v1 = 0, 0
			u2, v2 = 1, 1
		end

		if batch.batching then
			drawBatchedRect(x, y, x + w, y + h, colors)
		else
			if rects.isBatching then
				drawQuadBatchedRect(x, y, w, h, colors)
			else
				drawSingleRect(x, y, w, h, colors, material, u1, v1, u2, v2)
			end
		end
	end
end

--- Rects library for paint lib
_G.paint.rects = rects