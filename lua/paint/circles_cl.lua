---@class circles
local circles = {}
local paint = paint

do
	local meshConstructor = Mesh

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshTexCoord = mesh.TexCoord
	local meshAdvanceVertex = mesh.AdvanceVertex

	local PRIMITIVE_POLYGON = MATERIAL_POLYGON

	local originVector = Vector(0, 0, 0)

	local sin, cos = math.sin, math.cos

	---Generates single circle mesh, unbatched
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param colors {[1]: Color, [2]: Color}
	---@return IMesh
	function circles.generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation)
		local meshObj = meshConstructor()

		meshBegin(meshObj, PRIMITIVE_POLYGON, vertexCount + 2) -- vertexcount + center vertex
			meshPosition(originVector)
			meshColor(colors[1]:Unpack())
			meshTexCoord(0, 0.5, 0.5)
			meshAdvanceVertex()

			local r, g, b, a = colors[2]:Unpack()
			
			local deltaAngle = endAngle - startAngle
			for i = 0, vertexCount do
				local angle = startAngle + deltaAngle * i / vertexCount

				local sinn, coss = sin(angle), cos(angle)

				meshPosition(cos(angle), sin(angle), 0)
				meshColor(r, g, b, a)
				meshTexCoord(0, sin(angle + rotation) / 2 + 0.5, cos(angle + rotation) / 2 + 0.5)
				meshAdvanceVertex()
			end
		meshEnd()

		return meshObj
	end
end

do
	local batch = paint.batch
	local incrementZ = paint.incrementZ

	---Generates circle mesh with batching being used. Since it's batched, we can't use matrices, so there are also x, y, and radius arguments
	---@param x number
	---@param y number
	---@param radius number
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param colors {[1]: Color, [2]: Color}
	function circles.generateMeshBatched(x, y, w, h, vertexCount, startAngle, endAngle, colors)
		local startColor, endColor = colors[1], colors[2]

		local batchTable = batch.batchTable
		local len = batchTable[0]

		local z = incrementZ()

		local deltaAngle = endAngle - startAngle
		for i = 0, vertexCount - 1 do -- we make a triangle each time, we need to get next point, so yeah...
			local indexI = i * 10

			do -- 1st vertex (middle)
				batchTable[len + 1 + indexI] = x
				batchTable[len + 2 + indexI] = y
				batchTable[len + 3 + indexI] = z
				batchTable[len + 4 + indexI] = startColor
			end

			do -- 2nd vertex (current point)
				local angle = startAngle + deltaAngle * i / vertexCount

				batchTable[len + 5 + indexI] = x + cos(angle) * radius -- second vertex
				batchTable[len + 6 + indexI] = y + sin(angle) * radius
				batchTable[len + 7 + indexI] = endColor
			end

			do -- 3rd vertex (next point)
				local angle = startAngle + deltaAngle * (i + 1) / vertexCount

				batchTable[len + 8 + indexI] = x + cos(angle) * radius -- second vertex
				batchTable[len + 9 + indexI] = y + sin(angle) * radius
				batchTable[len + 10+ indexI] = endColor
			end
		end

		batchTable[0] = len + 10 * vertexCount
	end
end

do
	local angleConverter = math.pi / 180

	local batch = paint.batch

	local matrix = Matrix()
	local setUnpacked = matrix.SetUnpacked

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	---@type {[string] : IMesh}
	local cachedCircles = {}

	local format = string.format

	---@param color1 Color
	---@param color2 Color
	---@param vertexCount integer
	---@param startAngle number
	---@return string id
	local function getId(color1, color2, vertexCount, startAngle, endAngle, rotation)
		return format('%x%x%x%x;%x%x%x%x;%u;%f;%f;%f',
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			vertexCount, startAngle, endAngle, rotation
		)
	end

	local defaultMat = Material('vgui/white')
	local renderSetMaterial = render.SetMaterial

	local generateSingleMesh = circles.generateSingleMesh
	local generateMeshBatched = circles.generateMeshBatched

	local meshDraw = FindMetaTable('IMesh').Draw

	---@param x number # CENTER of circle
	---@param y number # CENTER of circle
	---@param w number x xradius # Width/X radius of circle
	---@param h number y radius # Height/Y radius of circle
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle  number
	---@param colors Color | {[1]: Color, [2]: Color}
	function circles.drawCircle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, rotation)
		if colors[2] == nil then
			colors[1] = colors
			colors[2] = colors
		end

		if vertexCount == nil then
			vertexCount = 24
		end

		if startAngle == nil then
			startAngle = 0
			endAngle = 360
		end

		if rotation == nil then
			rotation = 0
		end

		rotation = rotation * angleConverter
		startAngle = startAngle * angleConverter
		endAngle = endAngle * angleConverter

		if batch.batching then
			generateMeshBatched(x, y, w, h, vertexCount, startAngle, endAngle, colors)
		else
			local id = getId(colors[1], colors[2], vertexCount, startAngle, endAngle, rotation)

			local meshObj = cachedCircles[id]

			if meshObj == nil then
				meshObj = generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation)
				cachedCircles[id] = meshObj
			end

			material = material or defaultMat

			setUnpacked(matrix,
                w, 0, 0, x,
                0, h, 0, y,
                0, 0, 1, 0,
                0, 0, 0, 1
            )

            renderSetMaterial(material)

			pushModelMatrix(matrix, true)
				meshDraw(meshObj)
			popModelMatrix()
		end
	end

	timer.Create('paint.circlesGarbageCollector' .. SysTime(), 60, 0, function()
		for k, v in pairs(cachedCircles) do
			v:Destroy()
			cachedCircles[k] = nil
		end
	end)
end

paint.circles = circles