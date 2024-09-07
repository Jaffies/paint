---@diagnostic disable: deprecated
local paint = paint--[[@as paint]]

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
---@class outlines
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

	---@type createVertexFunc
	local function createVertex(x, y, u, v, colors)
		if isFirst then
			isFirst = false
			return
		end

		local texU = 1 - (atan2( (1 - v) - 0.5, u - 0.5) / (2 * math.pi) + 0.5)

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
	---@deprecated Internal variable, not meant to be used outside.
	function outlines.generateOutlineSingle(mesh, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, l, t, r, b, curviness, inside, cornernessArg)
		isInside = inside or false
		outlineTop, outlineRight, outlineBottom, outlineLeft = t or 0, r or 0, b or 0, l or 0
		curviness = curviness or 2
		cornerness = cornernessArg or 1

		isFirst = true
		prevU = nil

		meshBegin(mesh, PRIMITIVE_TRIANGLE_STRIP, getMeshVertexCount(radius, rightTop, rightBottom, leftBottom, leftTop) * 2)
			generateSingleMesh(createVertex, nil, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1, curviness)
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
		return format('%u;%u;%u;%u;%x%x%x%x;%x%x%x%x;%u;%u;%u;%u;%f;%u;%f',
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
	local defaultMat = Material('vgui/white')

	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw

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
	---@deprecated Internal variable, not meant to be used outside.
	function outlines.drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b, curviness, inside, cornerness)
		curviness = curviness or 2
		inside = inside or false
		cornerness = cornerness or 1


		local id = getId(radius, w, h, (leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0), colors[1], colors[2], l, t, r, b, curviness, inside, cornerness)

		local meshObj = cachedOutlinedMeshes[id]

		if meshObj == nil then
			meshObj = meshConstructor()
			generateOutlineSingle(meshObj, radius, 0, 0, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, l, t, r, b, curviness, inside, cornerness)

			cachedOutlinedMeshes[id] = meshObj
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		pushModelMatrix(matrix, true)
			setMaterial(material or defaultMat)
			meshDraw(meshObj)
		popModelMatrix()
	end

	timer.Create('paint.outlinesGarbageCollector', 60, 0, function()
		for k, v in pairs(cachedOutlinedMeshes) do
			v:Destroy()
			cachedOutlinedMeshes[k] = nil
		end
	end)
end

do
	local generateSingleMesh = paint.roundedBoxes.generateSingleMesh

	---@type number?, number?, number?, number?
	local outlineL, outlineT, outlineR, outlineB -- use it to get outline widths per side
	---@type boolean?
	local first -- to skip first vertex since it is center of rounded box
	---@type number?, number?, number?, number?
	local prevX, prevY, prevU, prevV
	---@type number?
	local z

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

		batchTable[len + 11] = x
		batchTable[len + 12] = y
		batchTable[len + 13] = z
		batchTable[len + 14] = color1

		batchTable[len + 15] = prevX
		batchTable[len + 16] = prevY
		batchTable[len + 17] = color2

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

		batchTable[len + 18] = x
		batchTable[len + 19] = y
		batchTable[len + 20] = color2

		batchTable[0] = len + 20
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
	---@param inside boolean?
	---@deprecated Internal variable, not meant to be used outside.
	function outlines.drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, _, l, t, r, b, curviness, inside)
		outlineL, outlineT, outlineR, outlineB = l, t, r, b
		first = true
		curviness = curviness or 2

		z = incrementZ()
		generateSingleMesh(createVertex, nil, radius, x, y, x + w, y + h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1, curviness)
	end
end

do
	local batch = paint.batch
	local drawOutlineSingle = outlines.drawOutlineSingle
	local drawOutlineBatched = outlines.drawOutlineBatched

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
	function outlines.drawOutlineEx(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b, curviness, inside, cornerness)
		if colors[2] == nil then
			colors[1] = colors
			colors[2] = colors
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
			drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b, curviness, inside)
		else
			drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b, curviness, inside, cornerness)
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
		drawOutlineEx(radius, x, y, w, h, true, true, true, true, colors, material, l, t, r, b, curviness, inside, cornerness)
	end
end

do
	local meshConstructor = Mesh
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End

	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex

	local PRIMITIVE_TRIANGLE_STRIP = MATERIAL_TRIANGLE_STRIP

	---Creates mesh for box outline
	---@param x number
	---@param y number
	---@param endX number
	---@param endY number
	---@param colors {[1]: Color, [2]: Color}
	---@param outlineL number
	---@param outlineT number
	---@param outlineR number
	---@param outlineB number
	---@return IMesh
	---@deprecated Internal variable, not meant to be used outside.
	function outlines.generateBoxOutline(x, y, endX, endY, colors, outlineL, outlineT, outlineR, outlineB)
		local meshObj = meshConstructor()

		local innerR, innerG, innerB, innerA = colors[1].r, colors[1].g, colors[1].b, colors[1].a
		local outerR, outerG, outerB, outerA = colors[2].r, colors[2].g, colors[2].b, colors[2].a

		meshBegin(meshObj, PRIMITIVE_TRIANGLE_STRIP, 17)
			meshPosition(x, y, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(x, y - outlineT, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(endX, y, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(endX, y - outlineT, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(endX, y, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(endX + outlineR, y, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(endX, endY, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(endX + outlineR, endY, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(endX, endY, 0)
			meshColor(innerR, innerB, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(endX, endY + outlineB, 0)
			meshColor(outerR, outerB, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(x, endY, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(x, endY + outlineB, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(x, endY, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(x - outlineL, endY, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(x, y, 0)
			meshColor(innerR, innerG, innerB, innerA)
			meshAdvanceVertex()

			meshPosition(x - outlineL, y, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()

			meshPosition(x, y - outlineL, 0)
			meshColor(outerR, outerG, outerB, outerA)
			meshAdvanceVertex()
		meshEnd()

		return meshObj
	end

	local format = string.format

	---@param w number
	---@param h number
	---@param color1 Color
	---@param color2 Color
	---@param outlineL number
	---@param outlineT number
	---@param outlineR number
	---@param outlineB number
	local function getId(w, h, color1, color2, outlineL, outlineT, outlineR, outlineB)
		return format('%f;%f;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f',
			w, h,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			outlineL, outlineT, outlineR, outlineB
		)
	end

	local generateBoxOutline = outlines.generateBoxOutline

	---@type {[string]: IMesh}
	local cachedBoxOutlineMeshes = {}

	local camPushModelMatrix = cam.PushModelMatrix
	local camPopModelMatrix = cam.PopModelMatrix

	local matrix = Matrix()
	local setField = matrix.SetField

	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw

	local defaultMat = Material('vgui/white')
	local renderSetMaterial = render.SetMaterial

	---@param x number start X position
	---@param y number start Y position
	---@param w number width
	---@param h number height
	---@param colors Color | {[1]: Color,[2]: Color}
	---@param outlineL number
	---@param outlineT number
	---@param outlineR number
	---@param outlineB number
	---@overload fun(x : number, y: number, w: number, h: number, colors: linearGradient, outlineThickness: number)
	---@overload fun(x : number, y: number, w: number, h: number, colors: linearGradient, outlineX: number, outlineY: number)
	function outlines.drawBoxOutline(x, y, w, h, colors, outlineL, outlineT, outlineR, outlineB)
		if colors[2] == nil then
			colors[1] = colors
			colors[2] = colors
		end

		if outlineT == nil then
			outlineT, outlineR, outlineB = outlineL, outlineL, outlineL
		elseif outlineR == nil then
			outlineR, outlineB = outlineL, outlineT
		end

		local id = getId(w, h, colors[1], colors[2], outlineL, outlineT, outlineR, outlineB)

		local mesh = cachedBoxOutlineMeshes[id]

		if mesh == nil then
			mesh = generateBoxOutline(0, 0, w, h, colors, outlineL, outlineT, outlineR, outlineB)
			cachedBoxOutlineMeshes[id] = mesh
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		renderSetMaterial(defaultMat)

		camPushModelMatrix(matrix, true)
			meshDraw(mesh)
		camPopModelMatrix()
	end

	timer.Create('paint.cachedBoxOutlineGarbageCollector', 60, 0, function()
		for k, v in pairs(cachedBoxOutlineMeshes) do
			v:Destroy()
			cachedBoxOutlineMeshes[k] = nil
		end
	end)
end

_G.paint.outlines = outlines