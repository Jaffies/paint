local paint = _G.paint--[[@as paint]]

---@class roundedBoxes
local roundedBoxes = {}

---@alias createVertexFunc fun(x : number, y : number, u : number, v: number, colors : Color[], u1 : number, v1 : number, u2 : number, v2 : number)

do
	-- NOTE: it's likely implied that radius cant be 0, and can't be higher than width / 2 or height / 2
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End

	local PRIMITIVE_POLYGON = MATERIAL_POLYGON
	local clamp = math.Clamp
	local halfPi = math.pi / 2

	local sin = math.sin
	local cos = math.cos

	---@type Color[]
	local centreTab = {}
	--- Generates roundedBox mesh, used by outlines, 
	---@param createVertex createVertexFunc # function used to create vertex.
	---@param mesh? IMesh
	---@param radius number
	---@param x number
	---@param y number
	---@param endX number
	---@param endY number
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param colors {[1] : Color, [2]: Color, [3]: Color, [4]:Color, [5] : Color?}
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	function roundedBoxes.generateSingleMesh(createVertex, mesh, radius, x, y, endX, endY, leftTop, rightTop, rightBottom, leftBottom, colors, u1, v1, u2, v2)
		local count = 6
		local vertsPerEdge = clamp(radius / 2, 3, 24)

		local isRadiusBig = radius > 3

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

		local w, h = endX - x, endY - y

		if mesh then
			meshBegin(mesh, PRIMITIVE_POLYGON, count)
		end

			local fifthColor = colors[5]
			if fifthColor == nil then
				createVertex((x + endX) * 0.5, (y + endY) * 0.5, 0.5, 0.5, colors, u1, v1, u2, v2)
			else
				centreTab[1], centreTab[2], centreTab[3], centreTab[4] = fifthColor, fifthColor, fifthColor, fifthColor
				createVertex((x + endX) * 0.5, (y + endY) * 0.5, 0.5, 0.5, centreTab, u1, v1, u2, v2)
			end

			createVertex(x + (leftTop and radius or 0), y, (leftTop and radius or 0) / w, 0, colors, u1, v1, u2, v2)

			createVertex(endX - (rightTop and radius or 0), y, 1 - (rightTop and radius or 0) / w, 0, colors, u1, v1, u2, v2)
			-- 3 vertices

			if rightTop then
				if isRadiusBig then
					local deltaX = endX - radius
					local deltaY = y + radius

					for i = 1, vertsPerEdge - 1 do
						local angle = halfPi * (i / vertsPerEdge)

						local sinn, coss = sin(angle), cos(angle)

						local newX, newY = deltaX + sinn * radius, deltaY - coss * radius

						createVertex(newX, newY, 1 - (1-sinn) * radius / w, ( 1 - coss) * radius / h, colors, u1, v1, u2, v2 )
					end
				end

				createVertex(endX, y + radius, 1, radius / h, colors, u1, v1, u2, v2)
			end

			createVertex(endX, endY - (rightBottom and radius or 0), 1, 1 - (rightBottom and radius or 0) / h, colors, u1, v1, u2, v2)

			if rightBottom then
				if isRadiusBig then
					local deltaX = endX - radius
					local deltaY = endY - radius

					for i = 1, vertsPerEdge - 1 do
						local angle = halfPi * (i / vertsPerEdge)

						local sinn, coss = sin(angle), cos(angle)

						local newX, newY = deltaX + coss * radius, deltaY + sinn * radius

						createVertex(newX, newY, 1 - ((1 - coss) * radius) / w, 1 - ( (1 - sinn) * radius ) / h, colors, u1, v1, u2, v2)
					end
				end

				createVertex(endX - radius, endY, 1 - radius / w, 1, colors, u1, v1, u2, v2)
			end

			createVertex(x + (leftBottom and radius or 0), endY, (leftBottom and radius or 0) / w, 1, colors, u1, v1, u2, v2)

			if leftBottom then
				if isRadiusBig then
					local deltaX = x + radius
					local deltaY = endY - radius

					for i = 1, vertsPerEdge - 1 do
						local angle = halfPi * (i / vertsPerEdge)

						local sinn, coss = sin(angle), cos(angle)

						local newX, newY = deltaX - sinn * radius, deltaY + coss * radius

						createVertex(newX, newY, (1 - sinn) * radius / w, 1 - (1 - coss) * radius / h, colors, u1, v1, u2, v2)
					end
				end

				createVertex(x, endY - radius, 0, 1 - radius / h, colors, u1, v1, u2, v2)
			end

			createVertex(x, y + (leftTop and radius or 0), 0, (leftTop and radius or 0) / h, colors, u1, v1, u2, v2)

			if leftTop then
				if isRadiusBig then
					local deltaX = x + radius
					local deltaY = y + radius

					for i = 1, vertsPerEdge - 1 do
						local angle = halfPi * (i / vertsPerEdge)

						local sinn, coss = sin(angle), cos(angle)

						local newX, newY = deltaX - coss * radius, deltaY - sinn * radius

						createVertex(newX, newY, (1 - coss) * radius / w, (1 - sinn) * radius / h, colors, u1, v1, u2, v2)
					end
				end

				createVertex(x + radius, y, radius / w, 0, colors, u1, v1, u2, v2)
			end

		if mesh then
			meshEnd()
		end
	end
end

do
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex
	local meshTexCoord = mesh.TexCoord

	local bilinearInterpolation = paint.bilinearInterpolation

	---Internal function used in pair with mesh.Begin(PRIMITIVE_POLYGON). Used for single batched rounded boxes.
	---@type createVertexFunc
	local function createVertex(x, y, u, v, colors, u1, v1, u2, v2)
		local leftTop, rightTop, rightBottom, leftBottom = colors[1], colors[2], colors[3], colors[4]
		meshPosition(x, y, 0)
		meshTexCoord(0, u * (u2 - u1) + u1, v * (v2 - v1) + v1)
		meshColor(
			bilinearInterpolation(u, v, leftTop.r, rightTop.r, rightBottom.r, leftBottom.r),
			bilinearInterpolation(u, v, leftTop.g, rightTop.g, rightBottom.g, leftBottom.g),
			bilinearInterpolation(u, v, leftTop.b, rightTop.b, rightBottom.b, leftBottom.b),
			bilinearInterpolation(u, v, leftTop.a, rightTop.a, rightBottom.a, leftBottom.a)
		)

		meshAdvanceVertex()
	end


	local meshConstructor = Mesh
	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw

	local format = string.format

	local setMaterial = render.SetMaterial

	local matrix = Matrix()
	local setField = matrix.SetField

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local generateSingleMesh = roundedBoxes.generateSingleMesh

	--- Helper function to get ID
	---@param radius number
	---@param w number
	---@param h number
	---@param corners number
	---@param colors Color[]
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@return string id
	local function getId(radius, w, h, corners, colors, u1, v1, u2, v2)
		local color1, color2, color3, color4 = colors[1], colors[2], colors[3], colors[4]

		return format('%u;%u;%u;%u;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f',
			radius, w, h, corners,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			color3.r, color3.g, color3.b, color3.a,
			color4.r, color4.g, color4.b, color4.a,
			u1, v1, u2, v2
		)
	end

	---@type table<string, IMesh>
	local cachedRoundedBoxMeshes = {}

	--- Draws single unbached rounded box
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors Color[]
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param material IMaterial
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	function roundedBoxes.roundedBoxExSingle(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2)
		local id = getId(radius, w, h, (leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0), colors, u1, v1, u2, v2)

		local meshObj = cachedRoundedBoxMeshes[id]

		if meshObj == nil then
			meshObj = meshConstructor()
			generateSingleMesh(createVertex, meshObj, radius, 0, 0, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, u1, v1, u2, v2)

			cachedRoundedBoxMeshes[id] = meshObj
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		pushModelMatrix(matrix, true)
			setMaterial(material)
			meshDraw(meshObj)
		popModelMatrix()
	end

	timer.Create('paint.roundedBoxesGarbageCollector', 60, 0, function()
		for k, v in pairs(cachedRoundedBoxMeshes) do
			v:Destroy()
			cachedRoundedBoxMeshes[k] = nil
		end
	end)
end

do
	---@type {[1] : number, [2]:number, [3]: Color, [4] : number} | nil
	local prev1
	---@type {[1] : number, [2] : number, [3] : Color} | nil
	local prev2 = {}

	local batch = paint.batch
	local incrementZ = paint.incrementZ

	local color = Color
	local bilinearInterpolation = paint.bilinearInterpolation 

	---@type createVertexFunc
	local function createVertex(x, y, u, v, colors)
		if prev1 == nil then
			local z = incrementZ()
			local blendedColor = color(
				(colors[1].r + colors[2].r + colors[3].r + colors[4].r) / 4,
				(colors[1].g + colors[2].g + colors[3].g + colors[4].g) / 4,
				(colors[1].b + colors[2].b + colors[3].b + colors[4].b) / 4,
				(colors[1].a + colors[2].a + colors[3].a + colors[4].a) / 4
			)

			prev1 = {x, y, blendedColor, z}
			return
		end

		---@type Color
		local prefferedColor = color(
			bilinearInterpolation(u, v, colors[1].r, colors[2].r, colors[3].r, colors[4].r),
			bilinearInterpolation(u, v, colors[1].g, colors[2].g, colors[3].g, colors[4].g),
			bilinearInterpolation(u, v, colors[1].b, colors[2].b, colors[3].b, colors[4].b),
			bilinearInterpolation(u, v, colors[1].a, colors[2].a, colors[3].a, colors[4].a)
		)
		if prev2 == nil then
			prev2 = {x, y, prefferedColor}
			return
		end

		---@type table
		local batchTable = batch.batchTable

		local len = batchTable[0]
		batchTable[len + 1] = prev1[1]
		batchTable[len + 2] = prev1[2]
		batchTable[len + 3] = prev1[4]
		batchTable[len + 4] = prev1[3]

		batchTable[len + 5] = prev2[1]
		batchTable[len + 6] = prev2[2]
		batchTable[len + 7] = prev2[3]

		batchTable[len + 8] = x
		batchTable[len + 9] = y
		batchTable[len + 10] = prefferedColor

		batchTable[0] = len + 10

		prev2[1] = x
		prev2[2] = y
		prev2[3] = prefferedColor
	end

	local generateSingleMesh = roundedBoxes.generateSingleMesh

	--- Adds rounded box to batched queue
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param colors Color[]
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	function roundedBoxes.roundedBoxExBatched(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom)
		prev1 = nil
		prev2 = nil
		generateSingleMesh(createVertex, nil, radius, x, y, x + w, y + h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1)
	end
end

do
	local defaultMat = Material('vgui/white')
	local min = math.min

	local roundedBoxExSingle = roundedBoxes.roundedBoxExSingle
	local roundedBoxExBatched = roundedBoxes.roundedBoxExBatched

	local batch = paint.batch

	--- Draws rounded box (extended)
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors gradients
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@param material? IMaterial
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, material? : IMaterial)
	function roundedBoxes.roundedBoxEx(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2)
		if colors[4] == nil then
			colors[1] = colors
			colors[2] = colors
			colors[3] = colors
			colors[4] = colors
		end

		if u1 == nil then
			u1, v1, u2, v2 = 0, 0, 1, 1
		end

		if radius == 0 then
			leftTop, rightTop, rightBottom, leftBottom = false, false, false, false
		else
			radius = min(w / 2, h / 2, radius)
		end

		material = material or defaultMat

		if batch.batching then
			roundedBoxExBatched(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom)
		else
			roundedBoxExSingle(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2)
		end
	end

	local roundedBoxEx = roundedBoxes.roundedBoxEx

	--- Draws rounded box with all rounded corners
	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors gradients
	---@param material? IMaterial
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, material? : IMaterial)
	function roundedBoxes.roundedBox(radius, x, y, w, h, colors, material, u1, v1, u2, v2)
		roundedBoxEx(radius, x, y, w, h, colors, true, true, true, true, material, u1, v1, u2 ,v2)
	end
end

do
	local generateSingleMesh = roundedBoxes.generateSingleMesh
	local createdTable
	local len

	local function createVertex(x, y, u, v, _, u1, v1, u2, v2)
		if createdTable == nil then return end

		len = len + 1
		createdTable[len] = {x = x, y = y, u = u1 + u * (u2 - u1), v = v1 + v * (v2 - v1)}
	end

	local emptyTab = {} -- We do not use colors, so fuck them and place empty table here

	function roundedBoxes.generateDrawPoly(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, u1, v1, u2, v2)
		createdTable = {}
		len = 0
		generateSingleMesh(createVertex, nil, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, emptyTab, u1, v1, u2, v2)

		local tab = createdTable

		createdTable = nil
		len = nil
		return tab
	end
end

_G.paint.roundedBoxes = roundedBoxes