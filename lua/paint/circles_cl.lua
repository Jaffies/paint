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
	---@param rotation number
	---@return IMesh
	function circles.generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation)
		local meshObj = meshConstructor()

		local r, g, b, a = colors[2].r, colors[2].g, colors[2].b, colors[2].a
		local deltaAngle = endAngle - startAngle

		meshBegin(meshObj, PRIMITIVE_POLYGON, vertexCount + 2) -- vertexcount + center vertex
			meshPosition(originVector)
			meshColor(colors[1].r, colors[1].g, colors[1].b, colors[1].a)
			meshTexCoord(0, 0.5, 0.5)
			meshAdvanceVertex()

			for i = 0, vertexCount do
				local angle = startAngle + deltaAngle * i / vertexCount

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

	local sin, cos = math.sin, math.cos

	---Generates circle mesh with batching being used. Since it's batched, we can't use matrices, so there are also x, y, and radius arguments
	---@param x number
	---@param y number
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

				batchTable[len + 5 + indexI] = x + cos(angle) * w -- second vertex
				batchTable[len + 6 + indexI] = y + sin(angle) * h
				batchTable[len + 7 + indexI] = endColor
			end

			do -- 3rd vertex (next point)
				local angle = startAngle + deltaAngle * (i + 1) / vertexCount

				batchTable[len + 8 + indexI] = x + cos(angle) * w -- second vertex
				batchTable[len + 9 + indexI] = y + sin(angle) * h
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
	local cachedCircleMeshes = {}

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

			local meshObj = cachedCircleMeshes[id]

			if meshObj == nil then
				meshObj = generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation)
				cachedCircleMeshes[id] = meshObj
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
		for k, v in pairs(cachedCircleMeshes) do
			v:Destroy()
			cachedCircleMeshes[k] = nil
		end
	end)
end

-- Now circled outlines!

do
	local meshConstructor = Mesh

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshTexCoord = mesh.TexCoord
	local meshAdvanceVertex = mesh.AdvanceVertex

	local PRIMITIVE_TRIANGLE_STRIP = MATERIAL_TRIANGLE_STRIP
	local sin, cos = math.sin, math.cos


	---Generates single circle mesh, unbatched
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param colors {[1]: Color, [2]: Color}
	---@param startU number
	---@param endU number
	---@param outlineWidth number # note, that this outlineWidth is between 0-1, cuz it's basically a percentage of radius
	---@return IMesh
	function circles.generateOutlineMeshSingle(vertexCount, startAngle, endAngle, colors, startU, endU, outlineWidth)
		local meshObj = meshConstructor()

		local startR, startG, startB, startA = colors[1].r, colors[1].g, colors[1].b, colors[1].a
		local endR, endG, endB, endA = colors[2].r, colors[2].g, colors[2].b, colors[2].a
		
		local deltaAngle = endAngle - startAngle

		local startRadius = 1 - outlineWidth
		meshBegin(meshObj, PRIMITIVE_TRIANGLE_STRIP, vertexCount * 2) -- result vertexcount = innerVertexes + outerVertexes. Count of inner veretxes = count of outer veretxes
			for i = 0, vertexCount do
				local percent = i / vertexCount
				local angle = startAngle + deltaAngle * percent
				local sinn, coss = sin(angle), cos(angle)

				local u = startU + percent * (endU - startU) 

				meshPosition(coss * startRadius, sinn * startRadius, 0)
				meshColor(startR, startG, startB, startA)
				meshTexCoord(0, u, 0)
				meshAdvanceVertex()

				meshPosition(coss, sinn, 0)
				meshColor(endR, endG, endB, endA)
				meshTexCoord(0, u, 1)
				meshAdvanceVertex()
			end
		meshEnd()

		return meshObj
	end
end

do
	local format = string.format

	local meshDraw = FindMetaTable('IMesh').Draw
	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local generateOutlineMeshSingle = circles.generateOutlineMeshSingle

	local matrix = Matrix()
	local setUnpacked = matrix.SetUnpacked

	local renderSetMaterial = render.SetMaterial

	local cachedCircleOutlineMeshes = {}

	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param startU number
	---@param endU number
	---@param outlineWidth number
	---@return string id 
	local function getId(color1, color2, vertexCount, startAngle, endAngle, startU, endU, outlineWidth)
		return format('%x%x%x%x;%x%x%x%x;%u;%f;%f;%f;%f;%e', color1.r, color1.g, color1.b, color1.a, color2.r, color2.g, color2.b, color2.a, vertexCount, startAngle, endAngle, startU, endU, outlineWidth)
	end

	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param colors {[1]: Color, [2]: Color}
	---@param startU number
	---@param endU number
	---@param outlineWidth number # note, that this outlineWidth is between 0-1, cuz it's basically a percentage of radius
	function circles.drawOutlineSingle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, startU, endU, outlineWidth)
		local id = getId(colors[1], colors[2], vertexCount, startAngle, endAngle, startU, endU, outlineWidth)

		local meshObj = cachedCircleOutlineMeshes[id]

		if meshObj == nil then
			meshObj = generateOutlineMeshSingle(vertexCount, startAngle, endAngle, colors, startU, endU, outlineWidth)
			cachedCircleOutlineMeshes[id] = meshObj
		end

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

	timer.Create('paint.circleOutlinesGarbageCollector' .. SysTime(), 60, 0, function()
		for k, v in pairs(cachedCircleOutlineMeshes) do
			v:Destroy()
			cachedCircleOutlineMeshes[k] = nil
		end
	end)
end

do
	local defaultMat = Material('vgui/white')
	local angleConverter = math.pi / 180

	local drawOutlineSingle = circles.drawOutlineSingle
	local max = math.max
	---Draws circled outlines. UNBATCHED ONLY
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param colors Color | {[1]: Color, [2]: Color}
	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param startU number
	---@param endU number
	---@param outlineWidth number
	function circles.drawOutline(x, y, w, h, colors, outlineWidth, vertexCount, startAngle, endAngle, material, startU, endU)
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

		if startU == nil then
			startU = 0
			endU = 1
		end

		material = material or defaultMat

		startAngle = startAngle * angleConverter
		endAngle = endAngle * angleConverter

		outlineWidth = 1 / (1 + max(w, h) / outlineWidth)
		drawOutlineSingle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, startU, endU, outlineWidth)
	end
end

paint.circles = circles