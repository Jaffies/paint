---@diagnostic disable: deprecated
local paint = paint --[[@as paint]]

--```
--What makes paint outlines better than stencils:
--1) Support for materials!
--2) Support for gradients within the outline!
--3) Curviness!
--```
--# Simple example:
---
--Drawing outlines with different thicknesses on each side.
--```lua
--paint.outlines.drawOutline( 32, 16, 10, 64, 64, { COLOR_WHITE, COLOR_BLACK }, nil, 8 )
--paint.outlines.drawOutline( 32, 102, 10, 64, 64, { COLOR_WHITE, color_transparent }, nil, 8 )
--paint.outlines.drawOutline( 32, 192, 10, 64, 64, { COLOR_BLACK, ColorAlpha( COLOR_BLACK, 0 ) }, nil, 8 )
---```
---# Asymmetrical Example
---
---Drawing outlines with a different inner and outer color.
---```lua
-- paint.outlines.drawOutline( 32, 16, 10, 64, 64, { COLOR_WHITE, COLOR_BLACK }, nil, 8 )
-- paint.outlines.drawOutline( 32, 102, 10, 64, 64, { COLOR_WHITE, color_transparent }, nil, 8 )
-- paint.outlines.drawOutline( 32, 192, 10, 64, 64, { COLOR_BLACK, ColorAlpha( COLOR_BLACK, 0 ) }, nil, 8 )
---```
---# Draw Outline Animated Gradient Example
---
---Drawing an animated, colorful outline with a gradient.
---```lua
-- local color1, color2 = HSVToColor( RealTime() * 120, 1, 1 ), HSVToColor( RealTime() * 120 + 30, 1, 1 )
-- paint.outlines.drawOutline( 32, 32, 18, 64, 64, { color1, color2 }, nil, 16 )
---```
---@class paint.outlines
local outlines = {}

do
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshTexCoord = mesh.TexCoord
	local meshAdvanceVertex = mesh.AdvanceVertex

	---@type boolean
	local isFirst = true
	---@type number?
	local prevU
	---@type boolean?
	local isInside

	---@type number?
	local cornerness = 1

	---@type number
	local outlineLeft = 0
	---@type number
	local outlineRight = 0
	---@type number
	local outlineTop = 0
	---@type number
	local outlineBottom = 0

	local atan2 = math.atan2

	---@type paint.createVertexFunc
	local function createVertex(x, y, u, v, colors)
		if isFirst then
			isFirst = false
			return
		end

		local texU = 1 - (atan2((1 - v) - 0.5, u - 0.5) / (2 * math.pi) + 0.5)

		if prevU and prevU > texU then
			texU = texU + 1
		else
			prevU = texU
		end

		local newX, newY

		if u < 0.5 then
			newX = x - outlineLeft * (((1 - u) - 0.5) * 2) ^ cornerness
		elseif u ~= 0.5 then
			newX = x + outlineRight * ((u - 0.5) * 2) ^ cornerness
		else
			newX = x
		end

		if v < 0.5 then
			newY = y - outlineTop * (((1 - v) - 0.5) * 2) ^ cornerness
		elseif v ~= 0.5 then
			newY = y + outlineBottom * ((v - 0.5) * 2) ^ cornerness
		else
			newY = y
		end

		if isInside then
			meshPosition(newX, newY, 0)
			meshColor(colors[2].r, colors[2].g, colors[2].b, colors[2].a)
			meshTexCoord(0, texU, 0.02)
			meshAdvanceVertex()

			meshPosition(x, y, 0)
			meshColor(colors[1].r, colors[1].g, colors[1].b, colors[1].a)
			meshTexCoord(0, texU, 1)
			meshAdvanceVertex()
		else
			meshPosition(x, y, 0)
			meshColor(colors[1].r, colors[1].g, colors[1].b, colors[1].a)
			meshTexCoord(0, texU, 1)
			meshAdvanceVertex()

			meshPosition(newX, newY, 0)
			meshColor(colors[2].r, colors[2].g, colors[2].b, colors[2].a)
			meshTexCoord(0, texU, 0.02)
			meshAdvanceVertex()
		end
	end

	---@diagnostic disable-next-line: invisible
	local generateSingleMesh = paint.roundedBoxes.generateSingleMesh

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End


	local PRIMITIVE_TRIANGLE_STRIP = MATERIAL_TRIANGLE_STRIP

	local getMeshVertexCount = paint.roundedBoxes.getMeshVertexCount
	--- draw single outline

	--- Generates outline mesh
	---@param mesh IMesh
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param colors {[1]: Color, [2]: Color}
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	---@param curviness number?
	---@param inside boolean?
	---@param cornernessArg number?
	---@private Internal variable, not meant to be used outside.
	function outlines.generateOutlineSingle(mesh, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors,
											l, t, r, b, curviness, inside, cornernessArg)
		isInside = inside or false
		outlineTop, outlineRight, outlineBottom, outlineLeft = t or 0, r or 0, b or 0, l or 0
		curviness = curviness or 2
		cornerness = cornernessArg or 1

		isFirst = true
		prevU = nil

		meshBegin(mesh, PRIMITIVE_TRIANGLE_STRIP,
			getMeshVertexCount(radius, rightTop, rightBottom, leftBottom, leftTop) * 2)
		generateSingleMesh(createVertex, nil, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, 0,
			0, 1, 1, curviness)
		meshEnd()
	end
end

do
	---@type {[string]: IMesh}
	local cachedOutlinedMeshes = {}

	local format = string.format
	--- Helper function to get id
	---@param radius number
	---@param w number
	---@param h number
	---@param corners number
	---@param color1 Color
	---@param color2 Color
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	---@param curviness number?
	---@param inside boolean?
	---@return string id
	local function getId(radius, w, h, corners, color1, color2, l, t, r, b, curviness, inside, cornerness)
		return format('%f;%f;%f;%u;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f;%f;%u;%f',
			radius, w, h, corners,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			l, t, r, b, curviness or 2, inside and 1 or 0, cornerness
		)
	end

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local meshConstructor = Mesh
	local generateOutlineSingle = outlines.generateOutlineSingle

	local matrix = Matrix()
	local setField = matrix.SetField

	local setMaterial = render.SetMaterial

	local meshDraw = FindMetaTable('IMesh') --[[@as IMesh]].Draw

	---Draws outline. Unbatched
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param colors {[1]: Color, [2]: Color}
	---@param material? IMaterial # Default material is vgui/white
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	---@param curviness number?
	---@param inside boolean
	---@param cornerness number? Number in which corner fraction (value between 0 and 1) will be powered to. Default is 1
	---@private Internal variable, not meant to be used outside.
	function outlines.drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material,
										l, t, r, b, curviness, inside, cornerness)
		curviness = curviness or 2
		inside = inside or false
		cornerness = cornerness or 1


		local id = getId(radius, w, h,
			(leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0), colors[1],
			colors[2], l, t, r, b, curviness, inside, cornerness)

		local meshObj = cachedOutlinedMeshes[id]

		if meshObj == nil then
			meshObj = meshConstructor()
			generateOutlineSingle(meshObj, radius, 0, 0, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, l, t,
				r, b, curviness, inside, cornerness)

			cachedOutlinedMeshes[id] = meshObj
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		pushModelMatrix(matrix, true)
		setMaterial(material or paint.defaultMaterial)
		meshDraw(meshObj)
		popModelMatrix()
	end

	timer.Create('paint.outlinesGarbageCollector' .. SysTime(), 15, 0, function()
		for k, v in pairs(cachedOutlinedMeshes) do
			v:Destroy()
			cachedOutlinedMeshes[k] = nil
		end
	end)
end

do
	---@diagnostic disable-next-line: invisible
	local generateSingleMesh = paint.roundedBoxes.generateSingleMesh

	---@type number?, number?, number?, number?
	local outlineL, outlineT, outlineR, outlineB -- use it to get outline widths per side
	---@type boolean?
	local first                               -- to skip first vertex since it is center of rounded box
	---@type number?, number?, number?, number?
	local prevX, prevY, prevU, prevV
	---@type number?
	local z

	local atan2 = math.atan2
	local batch = paint.batch

	---@param x number
	---@param y number
	---@param u number
	---@param v number
	---@param colors {[1] : Color, [2]: Color}
	local function createVertex(x, y, u, v, colors)
		if first then
			first = false
			return
		elseif first == false then
			prevX, prevY, prevU, prevV = x, y, u, v
			first = nil
			return
		end

		local batchTable = batch.batchTable
		local len = batchTable[0]

		local color1, color2 = colors[1], colors[2]
		local cell = batch.getDrawCell()

		batchTable[len + 1] = prevX
		batchTable[len + 2] = prevY
		batchTable[len + 3] = z
		batchTable[len + 4] = color1

		do -- make some calculations to get outer border
			if prevU < 0.5 then
				prevX = prevX - outlineL * ((1 - prevU) - 0.5) * 2
			elseif prevU ~= 0.5 then
				prevX = prevX + outlineR * (prevU - 0.5) * 2
			end

			if prevV < 0.5 then
				prevY = prevY - outlineT * ((1 - prevV) - 0.5) * 2
			elseif prevV ~= 0.5 then
				prevY = prevY + outlineB * (prevV - 0.5) * 2
			end
		end

		batchTable[len + 5] = prevX
		batchTable[len + 6] = prevY
		batchTable[len + 7] = color2

		batchTable[len + 8] = x
		batchTable[len + 9] = y
		batchTable[len + 10] = color1

		local texPrevU = 1 - (atan2((1 - prevV) - 0.5, prevU - 0.5) / (2 * math.pi) + 0.5)
		local texU = 1 - (atan2((1 - v) - 0.5, u - 0.5) / (2 * math.pi) + 0.5)

		if texPrevU and texPrevU > texU then
			texU = texU + 1
		else
			texPrevU = texU
		end

		batchTable[len + 11] = texPrevU
		batchTable[len + 12] = 0.02
		batchTable[len + 13] = texPrevU
		batchTable[len + 14] = 1
		batchTable[len + 15] = texU
		batchTable[len + 16] = 0.02
		batchTable[len + 17] = cell


		batchTable[len + 18] = x
		batchTable[len + 19] = y
		batchTable[len + 20] = z
		batchTable[len + 21] = color1

		batchTable[len + 22] = prevX
		batchTable[len + 23] = prevY
		batchTable[len + 24] = color2

		prevX, prevY, prevU, prevV = x, y, u, v
		do
			if u < 0.5 then
				x = x - outlineL * (((1 - u) - 0.5) * 2)
			elseif u ~= 0.5 then
				x = x + outlineR * (u - 0.5) * 2
			end

			if v < 0.5 then
				y = y - outlineT * ((1 - v) - 0.5) * 2
			elseif v ~= 0.5 then
				y = y + outlineB * (v - 0.5) * 2
			end
		end

		batchTable[len + 25] = x
		batchTable[len + 26] = y
		batchTable[len + 27] = color2

		batchTable[len + 28] = texU
		batchTable[len + 29] = 0.02
		batchTable[len + 30] = texPrevU
		batchTable[len + 31] = 1
		batchTable[len + 32] = texU
		batchTable[len + 33] = 1
		batchTable[len + 34] = cell

		batchTable[0] = len + 34
	end

	local incrementZ = paint.incrementZ

	---Draws outline. Batched
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param colors {[1]: Color, [2]: Color}
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	---@param curviness number?
	---@private Internal variable, not meant to be used outside.
	function outlines.drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, _, l, t,
										 r, b, curviness)
		outlineL, outlineT, outlineR, outlineB = l, t, r, b
		first = true
		curviness = curviness or 2

		z = incrementZ()
		generateSingleMesh(createVertex, nil, radius, x, y, x + w, y + h, leftTop, rightTop, rightBottom, leftBottom,
			colors, 0, 0, 1, 1, curviness)
	end
end

do
	local batch = paint.batch
	local drawOutlineSingle = outlines.drawOutlineSingle
	local drawOutlineBatched = outlines.drawOutlineBatched

	local getColorTable = paint.getColorTable

	---Identical to drawOutline other than that it allows you to specify specific corners to be rounded.
	---@param radius number
	---@param x number start X position of outline
	---@param y number start Y position of outline
	---@param w number width of outline
	---@param h number height of outline
	---@param colors linearGradient Colors of outline. Either a color, or table with 2 colors inside.
	---@param material? IMaterial # Default material is vgui/white
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param l number Left outline width
	---@param t number Top outline width
	---@param r number Right outline width
	---@param b number Botton outline width
	---@param curviness number? Curviness of rounded box. Default is 2. Makes rounded box behave as with formula ``x^curviness+y^curviness=radius^curviness`` (this is circle formula btw. Rounded boxes are superellipses)
	---@param inside boolean? Revert vertex order to make outlines visible only on inside (when outline thickness is below 0.). Default - false
	---@param cornerness number? Value, by which corner fraction (which value is between 0 and 1) will be powered to. Default - 1.
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineThickness: number)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineWidth: number, outlineHeight: number)
	function outlines.drawOutlineEx(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l,
									t, r, b, curviness, inside, cornerness)
		if colors[2] == nil then
			---@cast colors Color
			---@diagnostic disable-next-line: cast-local-type
			colors = getColorTable(2, colors)
		end

		if radius == 0 then
			leftTop, rightTop, rightBottom, leftBottom = false, false, false, false
		end

		if t == nil then
			t, r, b = l, l, l
		elseif r == nil then
			r, b = l, t
		end

		inside = inside or false
		curviness = curviness or 2
		cornerness = cornerness or 1

		if batch.batching then
			drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r,
				b, curviness)
		else
			drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r,
				b, curviness, inside, cornerness)
		end
	end

	local drawOutlineEx = outlines.drawOutlineEx

	---Draws an outline with the specified parameters. Bases on rounded box, but makes outline of them.
	---@param radius number radius of roundedBox the outline will 'outline'
	---@param x number start X position of outline
	---@param y number start Y position of outline
	---@param w number width of outline
	---@param h number height of outline
	---@param colors linearGradient Colors of outline. Either a color, or table with 2 colors inside.
	---@param material? IMaterial # Default material is vgui/white
	---@param l number Left outline width
	---@param t number Top outline width
	---@param r number Right outline width
	---@param b number Botton outline width
	---@param curviness number? Curviness of rounded box. Default is 2. Makes rounded box behave as with formula ``x^curviness+y^curviness=radius^curviness`` (this is circle formula btw. Rounded boxes are superellipses)
	---@param inside boolean?
	---@param cornerness number? Value, by which corner fraction (which value is between 0 and 1) will be powered to. Default - 1.
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors: gradients, material?: IMaterial, outlineThickness: number, _ : nil, _ : nil, _ : nil, curviness: number?, inside : boolean?, cornerness: number?)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors: gradients, material?: IMaterial, outlineWidth: number, outlineHeight: number, _ : nil, _ : nil, curviness: number?, inside : boolean?, cornerness: number?)
	function outlines.drawOutline(radius, x, y, w, h, colors, material, l, t, r, b, curviness, inside, cornerness)
		drawOutlineEx(radius, x, y, w, h, true, true, true, true, colors, material, l, t, r, b, curviness, inside,
			cornerness)
	end
end

paint.outlines = outlines
