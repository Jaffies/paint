---@diagnostic disable: deprecated
---# paint.circles!
---### Forget about Circles! from sneakysquid
---he's a f***** btw ;)
---
---This library allows you to create and draw circles and ellipses
---```
---But with a twist:
---1) They have gradients of course
---2) They can be sliced
---3) They support stencils 
---4) They can have various curviness (squircles/SwiftUI/IOS rounded square )
---@class paint.circles
local circles = {}
local paint = paint

---@param num number
---@param power number
---@return number
local function fpow( num, power )
	if num > 0 then
		return num ^ power
	else
		return -((-num) ^ power)
	end
end

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
	---@param curviness number
	---@param rotation number
	---@private Internal variable, not meant to be used outside.
	---@return IMesh
	function circles.generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation, curviness)
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

				meshPosition(fpow(cos(angle), curviness), fpow(sin(angle), curviness), 0)
				meshColor(r, g, b, a)
				meshTexCoord(0, fpow(sin(angle + rotation), curviness) / 2 + 0.5, fpow(cos(angle + rotation), curviness) / 2 + 0.5)
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
	---@param curviness number
	---@private Internal variable, not meant to be used outside.
	function circles.generateMeshBatched(x, y, w, h, vertexCount, startAngle, endAngle, colors, curviness)
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

				batchTable[len + 5 + indexI] = x + fpow(cos(angle), curviness) * w -- second vertex
				batchTable[len + 6 + indexI] = y + fpow(sin(angle),curviness) * h
				batchTable[len + 7 + indexI] = endColor
			end

			do -- 3rd vertex (next point)
				local angle = startAngle + deltaAngle * (i + 1) / vertexCount

				batchTable[len + 8 + indexI] = x + fpow(cos(angle), curviness) * w -- second vertex
				batchTable[len + 9 + indexI] = y + fpow(sin(angle), curviness) * h
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
	---@param curviness number
	---@return string id
	local function getId(color1, color2, vertexCount, startAngle, endAngle, rotation, curviness)
		return format('%x%x%x%x;%x%x%x%x;%u;%f;%f;%f;%f',
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			vertexCount, startAngle, endAngle, rotation, curviness
		)
	end

	local defaultMat = Material('vgui/white')
	local renderSetMaterial = render.SetMaterial

	local generateSingleMesh = circles.generateSingleMesh
	local generateMeshBatched = circles.generateMeshBatched

	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw

	local getColorTable = paint.getColorTable

	---@param x number # CENTER X coordinate of circle
	---@param y number # CENTER Y coordinate of circle
	---@param w number x xradius # Width/X radius of circle
	---@param h number y radius # Height/Y radius of circle
	---@param vertexCount integer? Vertex count that circle will have
	---@param startAngle number? Starting angle of sliced circle. Default is 0. MUST BE LOWER THAN END ANGLE
	---@param endAngle  number? Ending angle of sliced circle. Default is 360. MUST BE HIGHER THAN START ANGLE
	---@param colors Color | {[1]: Color, [2]: Color} Color of circle. Can be a Color, or table with 2 colors inside.
	---@param curviness number? Curviness ratio of circle. Think of circle defined as a formula like ``x^2+y^2=1``. But replace 2 with curviness.
	---For squircle like in IOS, curviness is 4, resulting in ``x^4+y^4=1``
	function circles.drawCircle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, rotation, curviness)
		if colors[2] == nil then
			colors = getColorTable(2, colors)
		end

		curviness = 2 / (curviness or 2)

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
			generateMeshBatched(x, y, w, h, vertexCount, startAngle, endAngle, colors, curviness)
		else
			local id = getId(colors[1], colors[2], vertexCount, startAngle, endAngle, rotation, curviness)

			local meshObj = cachedCircleMeshes[id]

			if meshObj == nil then
				meshObj = generateSingleMesh(vertexCount, startAngle, endAngle, colors, rotation, curviness)
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
	---@param curviness number
	---@private Internal variable, not meant to be used outside .
	---@return IMesh
	function circles.generateOutlineMeshSingle(vertexCount, startAngle, endAngle, colors, startU, endU, outlineWidth, curviness)
		local meshObj = meshConstructor()

		local startR, startG, startB, startA = colors[1].r, colors[1].g, colors[1].b, colors[1].a
		local endR, endG, endB, endA = colors[2].r, colors[2].g, colors[2].b, colors[2].a

		local deltaAngle = endAngle - startAngle

		local startRadius = 1 - outlineWidth
		meshBegin(meshObj, PRIMITIVE_TRIANGLE_STRIP, vertexCount * 2) -- result vertexcount = innerVertexes + outerVertexes. Count of inner veretxes = count of outer veretxes
			for i = 0, vertexCount do
				local percent = i / vertexCount
				local angle = startAngle + deltaAngle * percent
				local sinn, coss = fpow(sin(angle), curviness), fpow(cos(angle), curviness)

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
	local batch = paint.batch
	local incrementZ = paint.incrementZ

	local sin, cos = math.sin, math.cos

	---@param vertexCount integer
	---@param startAngle number
	---@param endAngle number
	---@param colors {[1]: Color, [2]: Color}
	---@param x number
	---@param y number
	---@param radiusW number
	---@param radiusH number
	---@param outlineWidth number
	---@param curviness number
	function circles.generateOutlineMeshBatched(vertexCount, startAngle, endAngle, colors, x, y, radiusW, radiusH, outlineWidth, curviness)
		local startColor, endColor = colors[1], colors[2]

		local batchTable = batch.batchTable
		local len = batchTable[0]

		local z = incrementZ()

		local deltaAngle = endAngle - startAngle

		for i = 0, vertexCount - 1 do
			local indexI = i * 20

			local angle = startAngle + deltaAngle * i / vertexCount

			batchTable[len + 1 + indexI] = x + fpow(cos(angle), curviness) * radiusW
			batchTable[len + 2 + indexI] = y + fpow(sin(angle), curviness) * radiusH
			batchTable[len + 3 + indexI] = z
			batchTable[len + 4 + indexI] = startColor

			batchTable[len + 5 + indexI] = x + fpow(cos(angle), curviness) * (radiusW + outlineWidth)
			batchTable[len + 6 + indexI] = y + fpow(sin(angle), curviness) * (radiusH + outlineWidth)
			batchTable[len + 7 + indexI] = endColor

			local angle2 = startAngle + deltaAngle * (i + 1) / vertexCount

			batchTable[len + 8 + indexI] = x + fpow(cos(angle2), curviness) * radiusW
			batchTable[len + 9 + indexI] = y + fpow(sin(angle2), curviness) * radiusH
			batchTable[len + 10 + indexI] = startColor

			batchTable[len + 11 + indexI] = x + fpow(cos(angle2), curviness) * radiusW
			batchTable[len + 12 + indexI] = y + fpow(sin(angle2), curviness) * radiusH
			batchTable[len + 13 + indexI] = z
			batchTable[len + 14 + indexI] = startColor

			batchTable[len + 15 + indexI] = x + fpow(cos(angle), curviness) * (radiusW + outlineWidth)
			batchTable[len + 16 + indexI] = y + fpow(sin(angle), curviness) * (radiusH + outlineWidth)
			batchTable[len + 17 + indexI] = endColor

			batchTable[len + 18 + indexI] = x + fpow(cos(angle2), curviness) * (radiusW + outlineWidth)
			batchTable[len + 19 + indexI] = y + fpow(sin(angle2), curviness) * (radiusH + outlineWidth)
			batchTable[len + 20 + indexI] = endColor
		end

		batchTable[0] = len + 20 * vertexCount
	end
end

do
	local format = string.format

	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw
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
	---@param curviness number
	---@return string id 
	local function getId(color1, color2, vertexCount, startAngle, endAngle, startU, endU, outlineWidth, curviness)
		return format('%x%x%x%x;%x%x%x%x;%u;%f;%f;%f;%f;%f;%f', color1.r, color1.g, color1.b, color1.a, color2.r, color2.g, color2.b, color2.a, vertexCount, startAngle, endAngle, startU, endU, outlineWidth, curviness)
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
	---@param curviness number
	---@param outlineWidth number # note, that this outlineWidth is between 0-1, cuz it's basically a percentage of radius
	---@private Internal variable, not meant to be used outside.
	function circles.drawOutlineSingle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, startU, endU, outlineWidth, curviness)
		local id = getId(colors[1], colors[2], vertexCount, startAngle, endAngle, startU, endU, outlineWidth, curviness)

		local meshObj = cachedCircleOutlineMeshes[id]

		if meshObj == nil then
			meshObj = generateOutlineMeshSingle(vertexCount, startAngle, endAngle, colors, startU, endU, outlineWidth, curviness)
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

	local batch = paint.batch

	local getColorTable = paint.getColorTable

	local generateOutlineMeshBatched = circles.generateOutlineMeshBatched
	---Draws circled outline. UNBATCHED ONLY.
	---@param x number # CENTER X coordinate of circled outline
	---@param y number # CENTER Y coordinate of circled outline
	---@param w number x xradius # Width/X radius of circled outline
	---@param h number y radius # Height/Y radius of circled outline
	---@param colors Color | {[1]: Color, [2]: Color} Color of circledOutline. Can be a Color, or table with 2 colors inside.
	---@param outlineWidth number
	---@param vertexCount integer? Vertex count that circled outline will have
	---@param startAngle number? Starting angle of sliced circled outline. Default is 0. MUST BE LOWER THAN END ANGLE
	---@param endAngle  number? Ending angle of sliced circled outline. Default is 360. MUST BE HIGHER THAN START ANGLE
	---@param startU? number
	---@param endU? number
	---@param curviness number? Curviness ratio of circledOutline. Think of circledOutline defined as a formula like ``outlineRatio^2<=x^2+y^2<=1``. But replace 2 with curviness.
	---For squircle like in IOS, curviness is 4, resulting in ``outlineRatio^4<=x^4+y^4<=1``
	function circles.drawOutline(x, y, w, h, colors, outlineWidth, vertexCount, startAngle, endAngle, material, startU, endU, curviness)
		if colors[2] == nil then
			colors = getColorTable(2, colors)
		end

		if vertexCount == nil then
			vertexCount = 24
		end

		curviness = 2 / (curviness or 2)

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


		if batch.batching then
			generateOutlineMeshBatched(vertexCount, startAngle, endAngle, colors, x, y, w, h, outlineWidth, curviness)
		else
			outlineWidth = outlineWidth / max(w, h)
			---@diagnostic disable-next-line: param-type-mismatch
			drawOutlineSingle(x, y, w, h, colors, vertexCount, startAngle, endAngle, material, startU, endU, outlineWidth, curviness)
		end

	end
end

paint.circles = circles