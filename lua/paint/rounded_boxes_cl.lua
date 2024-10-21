---@diagnostic disable: deprecated
local paint = _G.paint--[[@as paint]]

--What makes paint rounded boxes better than the draw library's rounded boxes?
--1) Support for per-corner gradients!
--2) Improved performance when drawing multiple rounded boxes, thanks to batching!
--3) Stencil support!
--4) Material support!
--5) Curviness support (squircles/superellipses support)
--
--Simple Example
--Drawing rounded boxes with different corner radius and colors.
--```lua
-- -- A colorful rounded box
-- paint.roundedBoxes.roundedBox( 20, 5, 5, 64, 64, {
-- 	Color( 255, 0, 0 ), -- Top Left
-- 	Color( 0, 255, 0 ), -- Top Right
-- 	Color( 0, 0, 255 ), -- Bottom Right
-- 	color_white,	-- Bottom Left
-- 	color_black	-- Center
-- } )
-- -- An icon with rounded corners
-- paint.roundedBoxes.roundedBox( 32, 72, 5, 64, 64, COLOR_WHITE, ( Material( "icon16/application_xp.png" ) ) )
--```
--
--Asymmetrical Example
--Drawing a rounded box with only the top-right and bottom-left corners rounded.
--```lua
--paint.roundedBoxes.roundedBoxEx( 16, 10, 10, 64, 64, COLOR_WHITE, false, true, false, true )
--```
--
--Stencil Masked Example
--```lua
	-- local function mask(drawMask, draw)
	-- 	render.ClearStencil()
	-- 	render.SetStencilEnable(true)
	--
	-- 	render.SetStencilWriteMask(1)
	-- 	render.SetStencilTestMask(1)
	--
	-- 	render.SetStencilFailOperation(STENCIL_REPLACE)
	-- 	render.SetStencilPassOperation( STENCIL_REPLACE)
	-- 	render.SetStencilZFailOperation(STENCIL_KEEP)
	-- 	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	-- 	render.SetStencilReferenceValue(1)
	--
	-- 	drawMask()
	--
	-- 	render.SetStencilFailOperation(STENCIL_KEEP)
	-- 	render.SetStencilPassOperation(STENCIL_REPLACE)
	-- 	render.SetStencilZFailOperation(STENCIL_KEEP)
	-- 	render.SetStencilCompareFunction(STENCIL_EQUAL)
	-- 	render.SetStencilReferenceValue(1)
	--
	-- 	draw()
	--
	-- 	render.SetStencilEnable(false)
	-- 	render.ClearStencil()
	-- end
	--
	-- local RIPPLE_DIE_TIME = 1
	-- local RIPPLE_START_ALPHA = 50
	--
	-- function button:Paint(w, h)
	-- 	paint.startPanel(self)
	-- 		mask(function()
	-- 			paint.roundedBoxes.roundedBox( 32, 0, 0, w, h, COLOR_RED )
	-- 		end,
	-- 		function()
	-- 			local ripple = self.rippleEffect
	--
	-- 			if ripple == nil then return end
	--
	-- 			local rippleX, rippleY, rippleStartTime = ripple[1], ripple[2], ripple[3]
	--
	-- 			local percent = (RealTime() - rippleStartTime)  / RIPPLE_DIE_TIME
	--
	-- 			if percent >= 1 then
	-- 				self.rippleEffect = nil
	-- 			else
	-- 				local alpha = RIPPLE_START_ALPHA * (1 - percent)
	-- 				local radius = math.max(w, h) * percent * math.sqrt(2)
	--
	-- 				paint.roundedBoxes.roundedBox(radius, rippleX - radius, rippleY - radius, radius * 2, radius * 2, ColorAlpha(COLOR_WHITE, alpha))
	-- 			end
	-- 		end)
	-- 	paint.endPanel()
	-- end
--```
--
--Animated Rainbow Colors Example
--Drawing a rounded box with a rainbow gradient.
--```lua
-- local time1, time2 = RealTime() * 100, RealTime() * 100 + 30
-- local time3 = (time1 + time2) / 2
--
-- local color1, color2, color3 = HSVToColor(time1, 1, 1), HSVToColor(time2, 1, 1), HSVToColor(time3, 1, 1)
--
-- paint.roundedBoxes.roundedBox(32, 10, 10, 300, 128, {color1, color3, color2, color3})
-- -- Center is color3 not nil because interpolating between colors and between HSV is different
--```
---@class paint.roundedBoxes
local roundedBoxes = {}

---@alias paint.createVertexFunc fun(x : number, y : number, u : number, v: number, colors : Color[], u1 : number, v1 : number, u2 : number, v2 : number)

do
	-- NOTE: it's likely implied that radius cant be 0, and can't be higher than width / 2 or height / 2
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End

	local PRIMITIVE_POLYGON = MATERIAL_POLYGON
	local clamp = math.Clamp
	local halfPi = math.pi / 2

	local sin = math.sin
	local cos = math.cos

	---@param num number
	---@param power number
	---@return number
	local function fpow(num, power)
		if num > 0 then
			return num ^ power
		else
			return -((-num) ^ power)
		end
	end

	---@param radius number
	---@param rightTop boolean?
	---@param rightBottom boolean?
	---@param leftBottom boolean?
	---@param leftTop boolean?
	---@return integer vertex count 
	function roundedBoxes.getMeshVertexCount(radius, rightTop, rightBottom, leftBottom, leftTop)
		if radius > 3 then
			local vertsPerEdge = clamp(radius / 2, 3, 24)
			return 10
				+ (rightTop and vertsPerEdge or 0)
				+ (rightBottom and vertsPerEdge or 0)
				+ (leftBottom and vertsPerEdge or 0)
				+ (leftTop and vertsPerEdge or 0)
		else
			return 10
				+ (rightTop and 1 or 0)
				+ (rightBottom and 1 or 0)
				+ (leftBottom and 1 or 0)
				+ (leftTop and 1 or 0)
		end
	end

	local getMeshVertexCount = roundedBoxes.getMeshVertexCount

	---@type Color[]
	local centreTab = {}
	--- Generates roundedBox mesh, used by outlines, 
	---@param createVertex paint.createVertexFunc # function used to create vertex.
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
	---@param colors Color[]
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@param curviness number?
	---@private Internal variable. Not meant to use outside
	function roundedBoxes.generateSingleMesh(createVertex, mesh, radius, x, y, endX, endY, leftTop, rightTop, rightBottom, leftBottom, colors, u1, v1, u2, v2, curviness)
		local vertsPerEdge = clamp(radius / 2, 3, 24)

		local isRadiusBig = radius > 3

		curviness = 2 / (curviness or 2)

		local w, h = endX - x, endY - y

		if mesh then
			meshBegin(mesh, PRIMITIVE_POLYGON, getMeshVertexCount(radius, rightTop, rightBottom, leftBottom, leftTop))
		end

		local fifthColor = colors[5]
		if fifthColor == nil then
			createVertex((x + endX) * 0.5, (y + endY) * 0.5, 0.5, 0.5, colors, u1, v1, u2, v2)
		else
			centreTab[1], centreTab[2], centreTab[3], centreTab[4] = fifthColor, fifthColor, fifthColor, fifthColor
			createVertex((x + endX) * 0.5, (y + endY) * 0.5, 0.5, 0.5, centreTab, u1, v1, u2, v2)
		end

		createVertex(x + (leftTop and radius or 0), y, (leftTop and radius or 0) / w, 0, colors, u1, v1, u2, v2)

		createVertex( (x + endX) * 0.5, y, 0.5, 0, colors, u1, v1, u2, v2)

		createVertex(endX - (rightTop and radius or 0), y, 1 - (rightTop and radius or 0) / w, 0, colors, u1, v1, u2, v2)
		-- 3 vertices

		if rightTop then
			if isRadiusBig then
				local deltaX = endX - radius
				local deltaY = y + radius

				for i = 1, vertsPerEdge - 1 do
					local angle = halfPi * (i / vertsPerEdge)

					local sinn, coss = fpow(sin(angle), curviness), fpow(cos(angle), curviness)

					local newX, newY = deltaX + sinn * radius, deltaY - coss * radius

					createVertex(newX, newY, 1 - (1-sinn) * radius / w, ( 1 - coss) * radius / h, colors, u1, v1, u2, v2 )
				end
			end

			createVertex(endX, y + radius, 1, radius / h, colors, u1, v1, u2, v2)
		end

		createVertex(endX, (y + endY) * 0.5, 1, 0.5, colors, u1, v1, u2, v2)

		createVertex(endX, endY - (rightBottom and radius or 0), 1, 1 - (rightBottom and radius or 0) / h, colors, u1, v1, u2, v2)

		if rightBottom then
			if isRadiusBig then
				local deltaX = endX - radius
				local deltaY = endY - radius

				for i = 1, vertsPerEdge - 1 do
					local angle = halfPi * (i / vertsPerEdge)

					local sinn, coss = fpow(sin(angle), curviness), fpow(cos(angle), curviness)

					local newX, newY = deltaX + coss * radius, deltaY + sinn * radius

					createVertex(newX, newY, 1 - ((1 - coss) * radius) / w, 1 - ( (1 - sinn) * radius ) / h, colors, u1, v1, u2, v2)
				end
			end

			createVertex(endX - radius, endY, 1 - radius / w, 1, colors, u1, v1, u2, v2)
		end

		createVertex( (x + endX) * 0.5, endY, 0.5, 1, colors, u1, v1, u2, v2 )

		createVertex(x + (leftBottom and radius or 0), endY, (leftBottom and radius or 0) / w, 1, colors, u1, v1, u2, v2)

		if leftBottom then
			if isRadiusBig then
				local deltaX = x + radius
				local deltaY = endY - radius

				for i = 1, vertsPerEdge - 1 do
					local angle = halfPi * (i / vertsPerEdge)

					local sinn, coss = fpow(sin(angle), curviness), fpow(cos(angle), curviness)

					local newX, newY = deltaX - sinn * radius, deltaY + coss * radius

					createVertex(newX, newY, (1 - sinn) * radius / w, 1 - (1 - coss) * radius / h, colors, u1, v1, u2, v2)
				end
			end

			createVertex(x, endY - radius, 0, 1 - radius / h, colors, u1, v1, u2, v2)
		end

		createVertex(x, (y + endY) * 0.5, 0, 0.5, colors, u1, v1, u2, v2 )

		createVertex(x, y + (leftTop and radius or 0), 0, (leftTop and radius or 0) / h, colors, u1, v1, u2, v2)

		if leftTop then
			if isRadiusBig then
				local deltaX = x + radius
				local deltaY = y + radius

				for i = 1, vertsPerEdge - 1 do
					local angle = halfPi * (i / vertsPerEdge)

					local sinn, coss = fpow(sin(angle), curviness), fpow(cos(angle), curviness)

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

---@diagnostic disable-next-line: deprecated
	local bilinearInterpolation = paint.bilinearInterpolation

	---Internal function used in pair with mesh.Begin(PRIMITIVE_POLYGON). Used for single batched rounded boxes.
	---@type paint.createVertexFunc
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
	---@param curviness number
	---@return string id
	local function getId(radius, w, h, corners, colors, u1, v1, u2, v2, curviness)
		local color1, color2, color3, color4, color5 = colors[1], colors[2], colors[3], colors[4], colors[5]

		if color5 == nil then
			return format('%f;%f;%f;%u;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f;%f',
				radius, w, h, corners,
				color1.r, color1.g, color1.b, color1.a,
				color2.r, color2.g, color2.b, color2.a,
				color3.r, color3.g, color3.b, color3.a,
				color4.r, color4.g, color4.b, color4.a,
				u1, v1, u2, v2, curviness
			)
		else
			return format('%f;%f;%f;%u;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%f;%f;%f;%f;%f',
				radius, w, h, corners,
				color1.r, color1.g, color1.b, color1.a,
				color2.r, color2.g, color2.b, color2.a,
				color3.r, color3.g, color3.b, color3.a,
				color4.r, color4.g, color4.b, color4.a,
				color5.r, color5.g, color5.b, color5.a,
				u1, v1, u2, v2, curviness
			)
		end

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
	---@param curviness number?
	---@private Internal variable. Not meant to use outside
	function roundedBoxes.roundedBoxExSingle(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2, curviness)
		curviness = curviness or 2
		local id = getId(radius, w, h, (leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0), colors, u1, v1, u2, v2, curviness)

		local meshObj = cachedRoundedBoxMeshes[id]

		if meshObj == nil then
			meshObj = meshConstructor()
			generateSingleMesh(createVertex, meshObj, radius, 0, 0, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, u1, v1, u2, v2, curviness)

			cachedRoundedBoxMeshes[id] = meshObj
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		pushModelMatrix(matrix, true)
			setMaterial(material)
			meshDraw(meshObj)
		popModelMatrix()
	end

	timer.Create('paint.roundedBoxesGarbageCollector', 30, 0, function()
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

	---@type paint.createVertexFunc
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
	---@param curviness number?
	---@private Internal variable. Not meant to use outside
	function roundedBoxes.roundedBoxExBatched(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, curviness)
		prev1 = nil
		prev2 = nil
		generateSingleMesh(createVertex, nil, radius, x, y, x + w, y + h, leftTop, rightTop, rightBottom, leftBottom, colors, 0, 0, 1, 1, curviness)
	end
end

do
	local defaultMat = Material('vgui/white')

	local roundedBoxExSingle = roundedBoxes.roundedBoxExSingle
	local roundedBoxExBatched = roundedBoxes.roundedBoxExBatched

	local batch = paint.batch

	-- Identical to roundedBox other than that it allows you to specify specific corners to be rounded.
	-- For brevity, arguments duplicated from roundedBox are not repeated here.
	---@param radius number # radius of the rounded corners
	---@param x number #start X position of rounded box (upper left corner)
	---@param y number #start X position of rounded box (upper left corner)
	---@param w number #width of rounded box
	---@param h number #height of rounded box
	---@param colors gradients #colors of rounded box. Either a table of Colors, or a single Color.
	---@param material? IMaterial #Either a Material, or nil.  Default: vgui/white
	---@param u1 number #The texture U coordinate of the Top-Left corner of the rounded box.
	---@param v1 number #The texture V coordinate of the Top-Left corner of the rounded box.
	---@param u2 number #The texture U coordinate of the Bottom-Right corner of the rounded box.
	---@param v2 number #The texture V coordinate of the Bottom-Right corner of the rounded box.
	---@param curviness number? Curviness of rounded box. Default is 2. Makes rounded box behave as with formula ``x^curviness+y^curviness=radius^curviness`` (this is circle formula btw. Rounded boxes are superellipses)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, material? : IMaterial)
	---@param leftTop? boolean
	---@param rightTop? boolean
	---@param rightBottom? boolean
	---@param leftBottom? boolean
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, leftTop? : boolean, rightTop? : boolean, rightBottom? : boolean, leftBottom? : boolean, material? : IMaterial)
	function roundedBoxes.roundedBoxEx(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2, curviness)
		if colors[4] == nil then
			colors[1] = colors
			colors[2] = colors
			colors[3] = colors
			colors[4] = colors
		end

		if u1 == nil then
			u1, v1, u2, v2 = 0, 0, 1, 1
		end

		curviness = curviness or 2

		if radius == 0 then
			leftTop, rightTop, rightBottom, leftBottom = false, false, false, false
		end

		material = material or defaultMat

		if batch.batching then
			roundedBoxExBatched(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, curviness)
		else
			roundedBoxExSingle(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom, material, u1, v1, u2, v2, curviness)
		end
	end

	local roundedBoxEx = roundedBoxes.roundedBoxEx

	---Draws a rounded box with the specified parameters.
	---@param radius number # radius of the rounded corners
	---@param x number #start X position of rounded box (upper left corner)
	---@param y number #start X position of rounded box (upper left corner)
	---@param w number #width of rounded box
	---@param h number #height of rounded box
	---@param colors gradients #colors of rounded box. Either a table of Colors, or a single Color.
	---@param material? IMaterial #Either a Material, or nil.  Default: vgui/white
	---@param u1 number #The texture U coordinate of the Top-Left corner of the rounded box.
	---@param v1 number #The texture V coordinate of the Top-Left corner of the rounded box.
	---@param u2 number #The texture U coordinate of the Bottom-Right corner of the rounded box.
	---@param v2 number #The texture V coordinate of the Bottom-Right corner of the rounded box.
	---@param curviness number? Curviness of rounded box. Default is 2. Makes rounded box behave as with formula ``x^curviness+y^curviness=radius^curviness`` (this is circle formula btw. Rounded boxes are superellipses)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, material? : IMaterial)
	---@overload fun(radius : number, x : number, y : number, w : number, h : number, colors : gradients, material? : IMaterial, _ : nil, _ : nil, _: nil, _: nil, curviness : number)
	function roundedBoxes.roundedBox(radius, x, y, w, h, colors, material, u1, v1, u2, v2, curviness)
		roundedBoxEx(radius, x, y, w, h, colors, true, true, true, true, material, u1, v1, u2, v2, curviness)
	end

	roundedBoxes.drawRoundedBox = roundedBoxes.roundedBox
	roundedBoxes.drawRoundedBoxEx = roundedBoxes.roundedBoxEx
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

	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number
	---@param leftTop boolean?
	---@param rightTop  boolean?
	---@param rightBottom boolean?
	---@param leftBottom boolean?
	---@param u1 number
	---@param v1 number
	---@param u2 number
	---@param v2 number
	---@param curviness number? Curviness of rounded box. Default is 2. Makes rounded box behave as with formula ``x^curviness+y^curviness=radius^curviness`` (this is circle formula btw. Rounded boxes are superellipses)
	---@return {x : number, y: number, u: number, v: number}[] # table that is supposed to be put into surface.DrawPoly
	---@see surface.DrawPoly
	function roundedBoxes.generateDrawPoly(radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, u1, v1, u2, v2, curviness)
		createdTable = {}
		len = 0
		generateSingleMesh(createVertex, nil, radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, emptyTab, u1, v1, u2, v2, curviness)

		local tab = createdTable

		createdTable = nil
		len = nil
		return tab
	end
end

do
	local meshConstructor = Mesh

	local PRIMITIVE_POLYGON = MATERIAL_POLYGON

	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshTexCoord = mesh.TexCoord
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex

	---@param radius number radius of corners
	---@param x number startX position
	---@param y number startY position
	---@param w number width
	---@param h number height
	---@param colors {[1]: Color, [2]: Color, [3]: Color, [4]: Color}
	---@param leftTop boolean?
	---@param rightTop boolean?
	---@param rightBottom boolean?
	---@param leftBottom boolean?
	---@return IMesh
	function roundedBoxes.generateSimpleRoundedBox(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom)
		local iMesh = meshConstructor()

		local color1, color2, color3, color4 = colors[1], colors[2], colors[3], colors[4]

		local color1R, color1G, color1B, color1A = color1.r, color1.g, color1.b, color1.a
		local color2R, color2G, color2B, color2A = color2.r, color2.g, color2.b, color2.a
		local color3R, color3G, color3B, color3A = color3.r, color3.g, color3.b, color3.a
		local color4R, color4G, color4B, color4A = color4.r, color4.g, color4.b, color4.a

		local halfW = w / 2
		local halfH = h / 2

		local radiusW, radiusH = halfW / radius, halfH / radius

		meshBegin(iMesh, PRIMITIVE_POLYGON, 10)
			meshPosition(x + halfW, y + halfH, 0) -- center
			meshColor(
				(color1R + color2R + color3R + color4R) * 0.25,
				(color1G + color2G + color3G + color4G) * 0.25,
				(color1B + color2B + color3B + color4B) * 0.25,
				(color1A + color2A + color3A + color4A) * 0.25
			)
			meshTexCoord(0, radiusW, radiusH)
			meshAdvanceVertex()

			meshPosition(x, y, 0)
			meshColor(
				color1R, color1G, color1B, color1A
			)
			meshTexCoord(0, leftTop and 0 or radiusW, leftTop and 0 or radiusH)
			meshAdvanceVertex()

			meshPosition(x + halfW, y, 0)
			meshColor(
				(color1R + color2R) * 0.5,
				(color1G + color2G) * 0.5,
				(color1B + color2B) * 0.5,
				(color1A + color2A) * 0.5
			)
			meshTexCoord(0, radiusW, 0)
			meshAdvanceVertex()

			meshPosition(x + w, y, 0)
			meshColor(
				color2R, color2G, color2B, color2A
			)
			meshTexCoord(0, rightTop and 0 or radiusW, rightTop and 0 or radiusH)
			meshAdvanceVertex()

			meshPosition(x + w, y + halfH, 0)
			meshColor(
				(color3R + color2R) * 0.5,
				(color3G + color2G) * 0.5,
				(color3B + color2B) * 0.5,
				(color3A + color2A) * 0.5
			)
			meshTexCoord(0, 0, radiusH)
			meshAdvanceVertex()

			meshPosition(x + w, y + w, 0)
			meshColor(
				color3R, color3G, color3B, color3A
			)
			meshTexCoord(0, rightBottom and 0 or radiusW, rightBottom and 0 or radiusH)
			meshAdvanceVertex()

			meshPosition(x + halfW, y + w, 0)
			meshColor(
				(color3R + color4R) * 0.5,
				(color3G + color4G) * 0.5,
				(color3B + color4B) * 0.5,
				(color3A + color4A) * 0.5
			)
			meshTexCoord(0, radiusW, 0)
			meshAdvanceVertex()

			meshPosition(x, y + w, 0)
			meshColor(
				color4R, color4G, color4B, color4A
			)
			meshTexCoord(0, leftBottom and 0 or radiusW, leftBottom and 0 or radiusH)
			meshAdvanceVertex()

			meshPosition(x, y + halfW, 0)
			meshColor(
				(color1R + color4R) * 0.5,
				(color1G + color4G) * 0.5,
				(color1B + color4B) * 0.5,
				(color1A + color4A) * 0.5
			)
			meshTexCoord(0, 0, radiusH)
			meshAdvanceVertex()

			meshPosition(x, y, 0)
			meshColor(
				color1R, color1G, color1B, color1A
			)
			meshTexCoord(0, leftTop and 0 or radiusW, leftTop and 0 or radiusH)
			meshAdvanceVertex()
		meshEnd()

		return iMesh
	end

	local function getClampedTexture(name)
		if file.Exists('paint/' .. name .. '.vmt', 'DATA') then
			return Material('../data/paint/' .. name)
		end

		file.CreateDir('paint/' .. string.GetPathFromFilename(name))

		local vtfData = file.Open('materials/' .. name .. '.vtf', 'rb', 'MOD')
		local newVtf = file.Open('paint/' .. name .. '.vtf', 'wb', 'DATA')

		newVtf:Write(vtfData:Read(20))
		newVtf:WriteULong(bit.bor(vtfData:ReadULong(), 4, 8))
		newVtf:Write(vtfData:Read(vtfData:Size() - 24))
		newVtf:Flush()

		vtfData:Close()
		newVtf:Close()

		file.Write('paint/' .. name .. '.vmt',
			string.format([[
				"UnlitGeneric"
				{
					"$basetexture" "../data/paint/%s"
					"$ignorez" "1"
					"$vertexcolor" "1"
					"$vertexalpha" "1"
					"$nolod" "1"
				}]], name)
		)

		return Material('../data/paint/' .. name)
	end

	local texCorner8 = getClampedTexture( 'gui/corner8')
	local texCorner16 = getClampedTexture( 'gui/corner16')
	local texCorner32 = getClampedTexture( 'gui/corner32')
	local texCorner64 = getClampedTexture( 'gui/corner64')
	local texCorner512 = getClampedTexture( 'gui/corner512')

	local generateSimpleRoundedBox = roundedBoxes.generateSimpleRoundedBox

	---@type {[string]: IMesh}
	local cachedSimpleRoundedBoxMeshes = {}

	local matrix = Matrix()
	local setField = matrix.SetField

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw
	local setMaterial = render.SetMaterial
	local format = string.format

	---@param radius number
	---@param w number
	---@param h number
	---@param color1 Color
	---@param color2 Color
	---@param color3 Color
	---@param color4 Color
	---@param corners integer
	---@return string
	local function getId(radius, w, h, color1, color2, color3, color4, corners)
		return format('%f;%f;%f;%x%x%x%x;%x%x%x%x;%x%x%x%x;%x%x%x%x;%u', radius, w, h,
			color1.r, color1.g, color1.b, color1.a,
			color2.r, color2.g, color2.b, color2.a,
			color3.r, color3.g, color3.b, color3.a,
			color4.r, color4.g, color4.b, color4.a,
			corners
		)
	end

	---@param radius integer radius of rounded box corners
	---@param x integer start x position
	---@param y integer start y position
	---@param w integer width
	---@param h integer height
	---@param colors Color | {[1] : Color, [2]: Color, [3]: Color, [4]: Color}
	---@param leftTop boolean?
	---@param rightTop boolean?
	---@param rightBottom boolean?
	---@param leftBottom boolean?
	function roundedBoxes.drawSimpleRoundedBoxEx(radius, x, y, w, h, colors, leftTop, rightTop, rightBottom, leftBottom)
		if colors[4] == nil then
			colors[1] = colors
			colors[2] = colors
			colors[3] = colors
			colors[4] = colors
		end

		local id = getId(radius, w, h, colors[1], colors[2], colors[3], colors[4], (leftTop and 8 or 0) + (rightTop and 4 or 0) + (rightBottom and 2 or 0) + (leftBottom and 1 or 0) )

		local meshObj = cachedSimpleRoundedBoxMeshes[id]

		if meshObj == nil then
			meshObj = generateSimpleRoundedBox(radius, 0, 0, w, h, colors, leftTop, rightTop, rightBottom, leftBottom)
			cachedSimpleRoundedBoxMeshes[id] = meshObj
		end

		setField(matrix, 1, 4, x)
		setField(matrix, 2, 4, y)

		local material = texCorner8
		if radius > 64 then material = texCorner512
		elseif radius > 32 then material = texCorner64
		elseif radius > 16 then material = texCorner32
		elseif radius > 8 then material = texCorner16 end

		pushModelMatrix(matrix, true)
			setMaterial(material)
			meshDraw(meshObj)
		popModelMatrix()
	end

	local drawSimpleRoundedBoxEx = roundedBoxes.drawSimpleRoundedBoxEx

	function roundedBoxes.drawSimpleRoundedBox(radius, x, y, w, h, colors)
		drawSimpleRoundedBoxEx(radius, x, y ,w, h, colors, true, true, true, true)
	end

	timer.Create('paint.simpleRoundedBoxesGarbageCollector', 60, 0, function()
		for k, v in pairs(cachedSimpleRoundedBoxMeshes) do
			v:Destroy()
			cachedSimpleRoundedBoxMeshes[k] = nil
		end
	end)
end

_G.paint.roundedBoxes = roundedBoxes