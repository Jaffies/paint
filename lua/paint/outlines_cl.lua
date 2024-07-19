local paint = paint--[[@as paint]]

---@class outlines
local outlines = {}

do
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshTexCoord = mesh.TexCoord
	local meshAdvanceVertex = mesh.AdvanceVertex

	---@type boolean
	local isFirst = true
	---@type number
	local prevU

	---@type number
	local outlineLeft = 0
	---@type number
	local outlineRight = 0
	---@type number
	local outlineTop = 0
	---@type number
	local outlineBottom = 0

	local abs, atan2 = math.abs, math.atan2

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

		meshPosition(x, y, 0)
		meshColor(colors[1].r, colors[1].g, colors[1].b, colors[1].a)
		meshTexCoord(0, texU, 1)
		meshAdvanceVertex()

		local newX, newY

		if u < 0.5 then
			newX = x - outlineLeft * ((1 - u) - 0.5) * 2
		elseif u ~= 0.5 then
			newX = x + outlineRight * (u - 0.5) * 2
		else
			newX = x
		end

		if v < 0.5 then
			newY = y - outlineTop * ((1 - v) - 0.5) * 2
		elseif v ~= 0.5 then
			newY = y + outlineBottom * (v - 0.5) * 2
		else
			newY = y
		end

		meshPosition(newX, newY, 0)
		meshColor(colors[2].r, colors[2].g, colors[2].b, colors[2].a)
		meshTexCoord(0, texU, 0.02)
		meshAdvanceVertex()
	end

	local generateSingleMesh = paint.roundedBoxes.generateSingleMesh

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End

	local clamp = math.Clamp

	local PRIMITIVE_TRIANGLE_STRIP = MATERIAL_TRIANGLE_STRIP
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
	---@param colors Color[]
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	function outlines.generateOutlineSingle(mesh, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, l, t, r, b)
		local count = 6
		local vertsPerEdge = clamp(radius * 0.6, 3, 16)

		local isRadiusBig = radius > 6

		if isRadiusBig then
			count = count + (rightTop and vertsPerEdge or 0)
			count = count + (rightBottom and vertsPerEdge or 0)
			count = count + (leftBottom and vertsPerEdge or 0)
			count = count + (leftTop and vertsPerEdge or 0)
		else
			count = count + (rightTop and 1 or 0)
			count = count + (rightBottom and 1 or 0)
			count = count + (leftBottom and 1 or 0)
			count = count + (leftTop and 1 or 0)
		end

		outlineTop, outlineRight, outlineBottom, outlineLeft = t or 0, r or 0, b or 0, l or 0

		count = count * 2

		isFirst = true
		prevU = nil

		meshBegin(mesh, PRIMITIVE_TRIANGLE_STRIP, count)
			generateSingleMesh(createVertex, nil, radius, 0, 0, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1)
		meshEnd()
	end
end

do
	---@type table[string, IMesh]
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
	---@return string id
	local function getId(radius, w, h, corners, color1, color2, l, t, r, b)
		return format('%u;%u;%u;%u;%x%x%x%x;%x%x%x%x;%u;%u;%u;%u',
			radius, w, h, corners,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			l, t, r, b
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

	---@type fun(mesh : IMesh)
	local meshDraw = FindMetaTable('IMesh').Draw

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
	---@param colors gradients
	---@param material? IMaterial # Default material is vgui/white
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineThickness: number)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineWidth: number, outlineHeight: number)
	function outlines.drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b)
		local id = getId(radius, w, h, (leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0), colors[1], colors[2], l, t, r, b)

		local meshObj = cachedOutlinedMeshes[id]

		if meshObj == nil then
			meshObj = meshConstructor()
			generateOutlineSingle(meshObj, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, l, t, r, b)

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

	local outlineL, outlineT, outlineR, outlineB -- use it to get outline widths per side
	local first -- to skip first vertex since it is center of rounded box
	local prevX, prevY, prevU, prevV
	local z

	local batch = paint.batch
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
				x = x - outlineL * ((1 - u) - 0.5) * 2
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
	---@param colors gradients
	---@param l number
	---@param t number
	---@param r number
	---@param b number
	function outlines.drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, _, l, t, r, b)
		outlineL, outlineT, outlineR, outlineB = l, t, r, b
		first = true
		z = incrementZ()
		generateSingleMesh(createVertex, nil, radius, x, y, x + w, y + h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1)
	end
end

do
	local batch = paint.batch
	local drawOutlineSingle = outlines.drawOutlineSingle
	local drawOutlineBatched = outlines.drawOutlineBatched

	---Draws outline (extended)
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param colors gradients
	---@param material? IMaterial # Default material is vgui/white
	---@param l number outline left size
	---@param t number outline top size 
	---@param r number outline right size
	---@param b number outline bottom size
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineThickness: number)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, colors: Color[], material?: IMaterial, outlineWidth: number, outlineHeight: number)
	function outlines.drawOutlineEx(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b)
		if colors[1] == nil then
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

		if batch.batching then
			drawOutlineBatched(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b)
		else
			drawOutlineSingle(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, l, t, r, b)
		end
	end

	local drawOutlineEx = outlines.drawOutlineEx

	---Draws outline
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors gradients
	---@param material? IMaterial # Default material is vgui/white
	---@param l number outline left size
	---@param t number outline top size 
	---@param r number outline right size
	---@param b number outline bottom size
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors: gradients, material?: IMaterial, outlineThickness: number)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors: gradients, material?: IMaterial, outlineWidth: number, outlineHeight: number)
	function outlines.drawOutline(radius, x, y, w, h, colors, material, l, t, r, b)
		drawOutlineEx(radius, x, y, w, h, true, true, true, true, colors, material, l, t, r, b)
	end
end
_G.paint.outlines = outlines