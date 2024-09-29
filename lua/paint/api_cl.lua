---@diagnostic disable: deprecated

---@class paint.api for paint library, provides different way to 
---@field surface paint.api.surface surface library wrapper for paint library
---@field draw paint.api.draw draw library wrapper for paint library
---@field new paint.api.new New API for paint library. Will contain refactored api that will have better documentation, etc.
---@field circles paint.api.circles wrapper for Circles! library, which will use paint's functions
local api = {}
local paint = paint

---@type boolean # Overrides (Detours) surface library
local OVERRIDE_SURFACE = false
---@type boolean # Overrides (Detours) draw library
local OVERRIDE_DRAW = false
---@type boolean # Overrides (Detours) Circles! library
local OVERRIDE_CIRCLES = false

do
	local getPanelPaintState = surface.GetPanelPaintState--[[@as fun() : { translate_x: number, translate_y: number, scissor_enabled: boolean, scissor_left: number, scissor_top: number, scissor_right: number, scissor_bottom: number}]]
	local getAlphaMultiplier = surface.GetAlphaMultiplier
	local getTextureNameById = surface.GetTextureNameByID
	local surfaceGetDrawColor = surface.GetDrawColor--[[@as fun(): Color]]
	local getDrawColor = function()
		local color = surfaceGetDrawColor()

		color.a = color.a * getAlphaMultiplier()

		return color
	end

	local pushScissorRect = paint.pushScissorRect
	local popScissorRect = paint.popScissorRect

	---@class paint.api.surface
	local surface = {}

	local material = Material

	local vguiWhite = material('vgui/white')
	local renderSetMaterial = render.SetMaterial

	local getMaterial

	if OVERRIDE_SURFACE then

		---@type IMaterial?
		local currentMaterial

		local oldSetMaterial = _G.surface.OldSetMaterial or _G.surface.SetMaterial
		local oldSetTexture = _G.surface.OldSetTexture or _G.surface.SetTexture

		---@param mat IMaterial
		function surface.SetMaterial(mat)
			currentMaterial = mat
			oldSetMaterial(mat)
		end

		---@return IMaterial
		function surface.GetMaterial()
			return currentMaterial or vguiWhite
		end

		---@param texId integer
		function surface.SetTexture(texId)
			currentMaterial = material(getTextureNameById(texId))
			oldSetTexture(texId)
		end

		getMaterial = surface.GetMaterial
		surface.OldSetMaterial = oldSetMaterial
		surface.OldSetTexture = oldSetTexture
	else
		---@type IMaterial?
		local currentMaterial

		---@param mat IMaterial
		function surface.SetMaterial(mat)
			currentMaterial = mat
		end

		---@return IMaterial
		function surface.GetMaterial()
			return currentMaterial or vguiWhite
		end

		getMaterial = surface.GetMaterial
	end

	do -- Rects
		local drawRect = paint.rects.drawRect

		---@param x number
		---@param y number
		---@param w number
		---@param h number
		function surface.DrawRect( x, y, w, h )
			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end
			drawRect(x + tab.translate_x, y + tab.translate_y, w, h, getDrawColor() )

			if tab.scissor_enabled then
				popScissorRect()
			end
		end

		---@param x number
		---@param y number
		---@param w number
		---@param h number
		function surface.DrawTexturedRect(x, y, w, h)
			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end

			drawRect(x + tab.translate_x, y + tab.translate_y, w, h, getDrawColor(), getMaterial())

			if tab.scissor_enabled then
				popScissorRect()
			end
		end

		---@param x number
		---@param y number
		---@param w number
		---@param h number
		---@param u1 number
		---@param v1 number
		---@param u2 number
		---@param v2 number
		function surface.DrawTexturedRectUV(x, y, w, h, u1, v1, u2, v2)
			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end

			drawRect(x + tab.translate_x, y + tab.translate_y, w, h, getDrawColor(), getMaterial(), u1, v1, u2, v2)

			if tab.scissor_enabled then
				popScissorRect()
			end
		end

		local drawOutline = paint.outlines.drawOutline

		---@param x number
		---@param y number
		---@param w number
		---@param h number
		---@param thickness number?
		function surface.DrawOutlinedRect(x, y, w, h, thickness)
			thickness = thickness or 1

			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end

			drawOutline(0, x + tab.translate_x, y + tab.translate_y, w, h, getDrawColor(), getMaterial(), thickness)

			if tab.scissor_enabled then
				popScissorRect()
			end
		end
	end

	do
		local meshBegin = mesh.Begin
		local meshEnd = mesh.End
		local meshPosition = mesh.Position
		local meshColor = mesh.Color
		local meshTexCoord = mesh.TexCoord
		local meshAdvanceVertex = mesh.AdvanceVertex

		local PRIMITIVE_POLYGON = MATERIAL_POLYGON

		---@class paint.api.verts
		---@field x number
		---@field y number
		---@field u number?
		---@field v number? # If `u` component is not nil, then it has to be nil too.

		---@param vertices paint.api.verts # Same structure as Struct/PolygonVertex
		function surface.DrawPoly(vertices)
			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end

			local len = #vertices

			renderSetMaterial(getMaterial())

			local color = getDrawColor()

			local r, g, b, a = color.r, color.g, color.b, color.a

			meshBegin(PRIMITIVE_POLYGON, len)
				for i = 1, len do
					local v = vertices[i]

					meshPosition(v.x, v.y, 0)
					meshColor(r, g, b, a)

					if v.u then
						meshTexCoord(0, v.u, v.v)
					end

					meshAdvanceVertex()
				end
			meshEnd()

			if tab.scissor_enabled then
				popScissorRect()
			end
		end
	end

	do
		local drawLine = paint.lines.drawLine
		function surface.DrawLine(x, y, endX, endY)
			local tab = getPanelPaintState()

			if tab.scissor_enabled then
				pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
			end

			local color = getDrawColor()
			drawLine(x, y, endX, endY, color, color)

			if tab.scissor_enabled then
				popScissorRect()
			end
		end
	end

	if OVERRIDE_SURFACE then
		local originalSurface = _G.surface

		for k, v in pairs(surface) do
			originalSurface[k] = v
		end
	end

	api.surface = surface
end

do
	local getPanelPaintState = surface.GetPanelPaintState--[[@as fun() : { translate_x: number, translate_y: number, scissor_enabled: boolean, scissor_left: number, scissor_top: number, scissor_right: number, scissor_bottom: number}]]
	local pushScissorRect = paint.pushScissorRect
	local popScissorRect = paint.popScissorRect

	---@class paint.api.draw
	local draw = {}

	local drawSimpleRoundedBox = paint.roundedBoxes.drawSimpleRoundedBox
	local drawSimpleRoundedBoxEx = paint.roundedBoxes.drawSimpleRoundedBoxEx

	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number 
	---@param colors Color | {[1]: number, [2]: number, [3]: number, [4]: number}
	function draw.RoundedBox(radius, x, y, w, h, colors)
		local tab = getPanelPaintState()

		if tab.scissor_enabled then
			pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
		end

		drawSimpleRoundedBox(radius, x, y, w, h, colors)

		if tab.scissor_enabled then
			popScissorRect()
		end
	end

	---@param radius number
	---@param x number
	---@param y number
	---@param w number
	---@param h number 
	---@param topLeft boolean?
	---@param topRight boolean?
	---@param bottomLeft boolean?
	---@param bottomRight boolean?
	---@param colors Color | {[1]: number, [2]: number, [3]: number, [4]: number}
	function draw.RoundedBoxEx(radius, x, y, w, h, colors, topLeft, topRight, bottomLeft, bottomRight)
		local tab = getPanelPaintState()

		if tab.scissor_enabled then
			pushScissorRect(tab.scissor_left, tab.scissor_top, tab.scissor_right, tab.scissor_bottom)
		end

		drawSimpleRoundedBoxEx(radius, x, y, w, h, colors, topLeft, topRight, bottomRight, bottomLeft)

		if tab.scissor_enabled then
			popScissorRect()
		end
	end

	if OVERRIDE_DRAW then
		local originalDraw = _G.draw
		for k, v in pairs(draw) do
			originalDraw[k] = v
		end
	end

	api.draw = draw
end

do
	---@class paint.api.new
	local new = {} -- Needs to be brainstormed

	for k, v in pairs(new) do
		paint[k] = v
	end

	api.new = new
end

do
	---@class paint.api.circles
	local circles = {}

	local CIRCLE_FILLED = 0
	local CIRCLE_OUTLINED = 1
	local CIRCLE_BLURRED = 2

	---@alias paint.api.circles.circleType 0 | 1 | 2

	---@class paint.api.circles.circle
	---@field m_Type paint.api.circles.circleType
	---@field private m_X number
	---@field private m_Y number
	---@field private m_Radius number
	---@field private m_Rotation number
	---@field private m_StartAngle number
	---@field private m_EndAngle number
	---@field private m_BlurLayers? integer
	---@field private m_BlurDensity? number
	---@field private m_Dirty boolean
	---@field private m_Color Color
	---@field private m_Material IMaterial
	---@field private m_OutlineWidth number
	---@field private m_VertexCount integer
	---@field SetX fun(self : paint.api.circles.circle, value : number)
	---@field GetX fun(self : paint.api.circles.circle) : number
	---@field SetY fun(self : paint.api.circles.circle, value : number)
	---@field GetY fun(self : paint.api.circles.circle) : number
	---@field SetRadius fun(self : paint.api.circles.circle, value : number)
	---@field GetRadius fun(self : paint.api.circles.circle) : number
	---@field SetRotation fun(self : paint.api.circles.circle, value : number)
	---@field GetRotation fun(self : paint.api.circles.circle) : number
	---@field SetStartAngle fun(self : paint.api.circles.circle, value : number)
	---@field GetStartAngle fun(self : paint.api.circles.circle) : number
	---@field SetEndAngle fun(self : paint.api.circles.circle, value : number)
	---@field GetEndAngle fun(self : paint.api.circles.circle) : number
	---@field SetDirty fun(self: paint.api.circles.circle, value : boolean)
	---@field GetDirty fun(self : paint.api.circles.circle) : boolean
	---@field SetColor fun(self: paint.api.circles.circle, color : Color)
	---@field GetColor fun(self : paint.api.circles.circle) : Color
	---@field SetType fun(self: paint.api.circles.circle, type : paint.api.circles.circleType)
	---@field GetType fun(self : paint.api.circles.circle) : paint.api.circles.circleType
	---@field SetOutlineWidth fun(self: paint.api.circles.circle, width : integer)
	---@field GetOutlineWidth fun(self : paint.api.circles.circle) : integer
	---@field SetBlurLayers fun(self: paint.api.circles.circle, value : integer)
	---@field GetBlurLayers fun(self : paint.api.circles.circle) : integer
	---@field SetBlurDensity fun(self: paint.api.circles.circle, value : integer)
	---@field GetBlurDensity fun(self : paint.api.circles.circle) : integer
	---@field SetVertexCount fun(self: paint.api.circles.circle, value : integer)
	---@field GetVertexCount fun(self : paint.api.circles.circle) : integer
	---@field SetMaterial fun(self : paint.api.circles.circle, material : IMaterial | boolean)
	---@field GetMaterial fun(self : paint.api.circles.circle) : IMaterial
	---@operator call() : nil # Draws Circle
	local circleClass = {}

	do
		circleClass.__index = circleClass
		circleClass.m_X = 0
		circleClass.m_Y = 0
		circleClass.m_Dirty = false
		circleClass.m_Radius = 0
		circleClass.m_Rotation = 0
		circleClass.m_Color = color_white
		circleClass.m_Material = Material('vgui/white')
		circleClass.m_Type = CIRCLE_FILLED
		circleClass.m_StartAngle = 0
		circleClass.m_EndAngle = 360
		circleClass.m_Distance = 10
		circleClass.m_VertexCount = 24

		local tonumber = tonumber

		---@param x number|string
		---@param y number|string
		function circleClass:SetPos(x, y)
			x = tonumber(x) or self.m_X
			y = tonumber(y) or self.m_Y

			self.m_X = x
			self.m_Y = y
		end

		---@param s number|string
		---@param e number|string
		function circleClass:SetAngles(s, e)
			s = tonumber(s) or self.m_StartAngle
			e = tonumber(e) or self.m_EndAngle

			self.m_StartAngle = s
			self.m_EndAngle = e
		end

		---@return number x
		---@return number y
		function circleClass:GetPos()
			return self.m_X, self.m_Y
		end

		---@param rotation number
		function circleClass:Rotate(rotation)
			self.m_Rotation = self.m_Rotation + (tonumber(rotation) or 0)
		end

		---@param x number|string
		---@param y number|string
		function circleClass:Translate(x, y)
			self.m_X = self.m_X + x
			self.m_Y = self.m_Y + y
		end

		do

			local drawCircle = paint.circles.drawCircle
			local drawOutlinedCircle = paint.circles.drawOutline

			local drawRoundedBox = paint.roundedBoxes.roundedBox
			local getBlurMaterial = paint.blur.getBlurMaterial

			local getPanelPaintState = surface.GetPanelPaintState

			local scrW, scrH = ScrW, ScrH

			local setScissorRect = render.SetScissorRect

			function circleClass:__call()
				local state = getPanelPaintState()

				if state.scissor_enabled then
					setScissorRect(state.scissor_left, state.scissor_top, state.scissor_right, state.scissor_bottom, true)
				end

				if self.m_Type == CIRCLE_OUTLINED then
					drawOutlinedCircle(self.m_X, self.m_Y, self.m_Radius, self.m_Radius, self.m_Color, self.m_OutlineWidth, self.m_VertexCount, self.m_StartAngle + self.m_Rotation, self.m_EndAngle + self.m_Rotation, self.m_Material, 0, 1, 2)
					--drawOutlinedCircle(self.m_X + state.translate_x, self.m_Y + state.translate_y, self.m_Radius, self.m_Radius, self.m_Color, self.m_OutlineWidth, self.m_VertexCount, self.m_StartAngle, self.m_EndAngle, self.m_Material, 0, 1, 1)
				elseif self.m_Type == CIRCLE_BLURRED then
					-- It's actually better to use stencils, but i'm lazy and i don't think
					-- That people who use CIRCLE_BLURRED will modify it's start/end angle.

					local material = getBlurMaterial('paintCircles', 0)
					local x, y = self.m_X - self.m_Radius / 2 + state.translate_x, self.m_Y - self.m_Radius / 2 + state.translate_y

					drawRoundedBox(self.m_Radius / 2, x, y, self.m_Radius, self.m_Radius, self.m_Color, material, x / scrW(), y / scrH(), (x+self.m_Radius) / scrW(), (y+self.m_Radius) / scrH() )
				else
					drawCircle(self.m_X + state.translate_x, self.m_Y + state.translate_y, self.m_Radius, self.m_Radius, self.m_Color, self.m_VertexCount, self.m_StartAngle + self.m_Rotation, self.m_EndAngle + self.m_Rotation, self.m_Material)
				end

				if state.scissor_enabled then
					setScissorRect(0, 0, 0, 0, false)
				end
			end
		end

		AccessorFunc(circleClass, 'm_X', 'X', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Y', 'Y', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Type', 'Type', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Radius', 'Radius', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_StartAngle', 'StartAngle', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_EndAngle', 'EndAngle', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Rotation', 'Rotation', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Distance', 'Distance', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_VertexCount', 'VertexCount', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_BlurLayers', 'BlurLayers', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_BlurDensity', 'BlurDensity', FORCE_NUMBER)
		AccessorFunc(circleClass, 'm_Dirty', 'Dirty', FORCE_BOOL)
		AccessorFunc(circleClass, 'm_Color', 'Color')
		AccessorFunc(circleClass, 'm_Material', 'Material')
		AccessorFunc(circleClass, 'm_OutlineWidth', 'OutlineWidth', FORCE_NUMBER)

		---@param material IMaterial|boolean
		function circleClass:SetMaterial(material)
			if isbool(material) then return end
			---@cast material IMaterial

			self.m_Material = material
		end
	end

	---@param type paint.api.circles.circleType
	---@param radius number radius of circle
	---@param x number x position of circle
	---@param y number y position of circle
	---@param blurLayers integer number of layers blur will be having
	---@param blurDensity number blur density
	---@overload fun(type : paint.api.circles.circleType, radius: number, x : number, y : number)
	---@overload fun(type : paint.api.circles.circleType, radius: number, x : number, y : number, outlineWidth : number)
	---@return paint.api.circles.circle
	function circles.New(type, radius, x, y, blurLayers, blurDensity)
		---@type paint.api.circles.circle
		local circle = setmetatable({}, circleClass)

		circle:SetType(type)
		circle:SetRadius(radius)
		circle:SetX(x)
		circle:SetY(y)

		if type == CIRCLE_OUTLINED then
			circle:SetOutlineWidth(tonumber(blurLayers) or 0)
		elseif type == CIRCLE_BLURRED then
			circle:SetBlurLayers(blurLayers)
			circle:SetBlurDensity(blurDensity)
		end

		return circle
	end

	circles.CIRCLE_FILLED = CIRCLE_FILLED
	circles.CIRCLE_OUTLINED = CIRCLE_OUTLINED
	circles.CIRCLE_BLURRED = CIRCLE_BLURRED

	api.circles = circles

	if OVERRIDE_CIRCLES then
		_G.CIRCLE_FILLED = CIRCLE_FILLED
		_G.CIRCLE_OUTLINED = CIRCLE_OUTLINED
		_G.CIRCLE_BLURRED = CIRCLE_BLURRED

		RegisterMetaTable('Circles', circle)
	end
end

paint.api = api