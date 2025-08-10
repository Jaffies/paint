---@diagnostic disable: deprecated
---Paint library for GMod!
---
---Purpose: drop in replacement to all surface/draw functions. Now there's no need to use them
---
---	Features:
---
---		1) Enchanced lines, with support of linear gradients.
---
---		2) Enchanced rounded boxes. They support stencils, materials and outlines.
---
---		3) Circles. Super fast.
---
--- 	4) Batching. Everything here can be batched to save draw calls. Saves a lot of performance.
---
--- 	5) This library is SUPER fast. Some functions here are faster than default ones.
---
--- 	6) Rectangle support, with support of per-corner gradienting
---
--- 	7) Coordinates do not end up being rounded. Good for markers and other stuff.
---
--- Coded by [@jaffies](https://github.com/jaffies), aka [@mikhail_svetov](https://github.com/jaffies) (formely @michael_svetov) in discord.
--- Thanks to [A1steaksa](https://github.com/Jaffies/paint/pull/1), PhoenixF, [Riddle](https://github.com/Jaffies/paint/pull/2) and other people in gmod discord for various help
---
--- Please, keep in mind that this library is still in development.
--- You can help the project by contributing to it at [github repository](https://github.com/jaffies/paint)
---@class paint # paint library. Provides ability to draw shapes with mesh power
---@field lines paint.lines # lines module of paint library. Can make batched and gradient lines out of the box
---@field roundedBoxes paint.roundedBoxes # roundedBoxes provide better rounded boxes drawing because it makes them via meshes/polygons you name it.
---@field rects paint.rects # Rect module, gives rects with ability to batch and gradient per corner support
---@field outlines paint.outlines # outline module, gives you ability to create hollow outlines with
---@field batch paint.batch Unfinished module of batching. Provides a way to create IMeshes
---@field blur paint.blur blur library, provides a nice way to retrieve a cheap blur textures/materials
---@field circles paint.circles Circles! killer.
---@field svg paint.svg
---@field downsampling paint.downsampling
local paint = paint or {}

---@alias gradients Color | paint.gradientsTable
---@alias linearGradient Color | paint.linearGradientsTable

---@class paint.gradientsTable
---@field [1] Color # top left
---@field [2] Color # top right
---@field [3] Color # bottom right
---@field [4] Color # bottom left
---@field [5] Color? # center (rounded boxes only)

---@class paint.linearGradientsTable
---@field [1] Color # inner
---@field [2] Color # outer


do
	-- this fixes rendering issues with batching

	---Internal variable made for batching to store Z pos meshes won't overlap each other
	---@private Internal variable. Not meant to use outside
	paint.Z = 0

	---resets paint.Z to 0
	function paint.resetZ()
		paint.Z = 0
	end

	--- Increments Z, meaning that next draw operation will be on top of others while batching (because of it's Z position heh)
	---@return number Z # current Z position
	function paint.incrementZ()
		paint.Z = paint.Z + 1

		if paint.Z > 16384 then
			paint.resetZ()
		end

		return paint.getZ()
	end

	--- Calculates Z position, depending of paint.Z value. Made for batching
	---@return number z # calculated Z position. Is not equal to paint.Z
	function paint.getZ()
		return -1 + paint.Z / 8192
	end
end

do -- Additional stuff to scissor rect.
	-- needed for panels, i.e. multiple DScrollPanels clipping.
	local tab = {}
	local len = 0

	local setScissorRect = render.SetScissorRect
	local max = math.max
	local min = math.min

	--- Pushes new scissor rect boundaries to stack. Simmilar to Push ModelMatrix/RenderTarget/Filter(Mag/Min)
	---@see render.PushRenderTarget # A simmilar approach to render targets.
	---@param x number # start x position
	---@param y number # start y position
	---@param endX number # end x position. Must be bigger than x
	---@param endY number # end y position. Must be bigger than y
	function paint.pushScissorRect(x, y, endX, endY)
		local prev = tab[len]

		if prev then
			x = max(prev[1], x)
			y = max(prev[2], y)
			endX = min(prev[3], endX)
			endY = min(prev[4], endY)
		end

		len = len + 1

		tab[len] = { x, y, endX, endY }
		setScissorRect(x, y, endX, endY, true)
	end

	--- Pops last scissor rect's boundaries from the stack. Simmilar to Pop ModelMatrix/RenderTarget/Filter(Mag/Min)
	---@see paint.pushScissorRect
	function paint.popScissorRect()
		tab[len] = nil
		len = max(0, len - 1)

		local newTab = tab[len]

		if newTab then
			setScissorRect(newTab[1], newTab[2], newTab[3], newTab[4], true)
		else
			setScissorRect(0, 0, 0, 0, false)
		end
	end
end

do
	local vector = Vector()
	local paintColoredMaterial = CreateMaterial("testMaterial" .. SysTime(), "UnlitGeneric", {
		["$basetexture"] = "color/white",
		["$model"] = 1,
		["$translucent"] = 1,
		["$vertexalpha"] = 1,
		["$vertexcolor"] = 1
	})

	local recompute = paintColoredMaterial.Recompute
	local setVector = paintColoredMaterial.SetVector
	local setUnpacked = vector.SetUnpacked

	local currentR, currentG, currentB, currentA = 255, 255, 255, 255

	---This function provides you a material with solid color, allowing you to replicate ``render.SetColorModulation``/``surface.SetDrawColor``
	---
	---Meant to be used to have paint's shapes have animated colors without rebuilding mesh every time color changes
	---
	---It will tint every color of shape, but not override it. Meaning that yellow color wont be overriden to blue.
	---
	---instead it will be black because red/green components will be multiplied to 0, and blue component (which is 0, because its yellow) will be mutliplied by 1. Which equeals 0
	---
	---**Note:** You will have to call this function every time the color of coloredMaterial changes, because it uses 1 material and sets its color to what you want
	---Example:
	---```lua
	---paint.outlines.drawOutline(32, 100, 100, 256, 256, {color_white, color_transparent}, paint.getColoredMaterial( HSVToColor(RealTime() * 100, 1, 1) ), 16 )
	-----[[It will make halo/shadow with animated color]]
	---```
	---@param color Color color that material will have
	---@return IMaterial coloredMaterial
	function paint.getColoredMaterial(color)
		local r, g, b, a = color.r, color.g, color.b, color.a

		if currentR ~= r or currentG ~= g or currentB ~= b or currentA ~= a then
			currentR, currentG, currentB, currentA = r, g, b, a
			setUnpacked(vector, r / 255, g / 255, b / 255)
			setVector(paintColoredMaterial, '$color', vector)
		end

		return paintColoredMaterial
	end

	---@param color Color
	---@param mat IMaterial
	function paint.colorMaterial(color, mat)
		local r, g, b, a = color.r, color.g, color.b, color.a

		setUnpacked(vector, r / 255, g / 255, b / 255)
		setVector(mat, '$color', vector)
	end
end

do
	-- Helper functions
	-- startPanel - pops model matrix and pushes

	local matrix = Matrix()
	local setField = matrix.SetField

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local panelTab = FindMetaTable('Panel')
	---@cast panelTab Panel

	local localToScreen = panelTab.LocalToScreen
	local getSize = panelTab.GetSize

	local pushScissorRect = paint.pushScissorRect
	local popScissorRect = paint.popScissorRect

	local setScissorRect = render.SetScissorRect

	---
	---Unfortunately, the paint library cannot integrate seamlessly with VGUI and Derma in the way that the surface and draw libraries do.
	---This is because Meshes, which are used by the paint library, can only use absolute screen coordinates whereas the surface and draw libraries are automatically provided with panel-relative coordinates by the VGUI system.
	---
	---In addition, meshes cannot be clipped with the default VGUI clipping system and will behave as though it is disabled.
	---
	---To work around these limitations, you can use this function.
	---@param panel Panel # The panel to draw on.
	---@param pos? boolean # Set to true to autoamtically adjust all future paint operations to be relative to the panel.  Default: true
	---@param boundaries? boolean # Set to true to enable ScissorRect to the size of the panel. Default: false
	function paint.startPanel(panel, pos, boundaries, multiply)
		local x, y = localToScreen(panel, 0, 0)

		if pos or pos == nil then
			setField(matrix, 1, 4, x)
			setField(matrix, 2, 4, y)

			pushModelMatrix(matrix, multiply)
		end

		if boundaries then
			local w, h = getSize(panel)

			pushScissorRect(x, y, x + w, y + h)
		end
	end

	---@see paint.startPanel # Note: You need to have same arguments for position and boundaries between start and end panel functions.
	---@param pos? boolean # Set to true to autoamtically adjust all future paint operations to be relative to the panel.  Default: true
	---@param boundaries? boolean # Set to true to enable ScissorRect to the size of the panel. Default: false
	function paint.endPanel(pos, boundaries)
		if pos or pos == nil then
			popModelMatrix()
		end

		if boundaries then
			popScissorRect()
		end
	end

	do -- since startPanel and endPanel sound stupid and i figured it out only now, i'll make an aliases for them
		paint.beginPanel = paint.startPanel
		paint.stopPanel = paint.endPanel

		-- paint.beginPanel -> paint.endPanel (like in Pascal language, or mesh.Begin -> mesh.End)
		-- paint.startPanel -> paint.stopPanel (start/stop sound cool in pairs)
	end

	local getPanelPaintState = surface.GetPanelPaintState

	---# Starts new VGUI context
	---A modern alternative to paint.startPanel without the need to pass a reference of panel
	---and without the need to manually clip ``DScrollPanel``s.
	---## Example:
	---```lua
	---function PANEL:Paint(w, h)
	---	paint.startVGUI()
	---		paint.roundedBoxes.roundedBox(32, 0, 0, w, h, color_white)
	---		--Any other stuff here. Note that surface.* (or surface.* derived) functions will double it's positioning.
	---		--This is all because of surface internal positioning + matrix translation.
	---		--You will need to use only paint.* functions inside paint.start/endVGUI() block.
	---	paint.endVGUI()
	---end
	---```
	---@see paint.startPanel
	function paint.startVGUI()
		local state = getPanelPaintState()

		setField(matrix, 1, 4, state.translate_x)
		setField(matrix, 2, 4, state.translate_y)
		pushModelMatrix(matrix, true)

		if state.scissor_enabled then
			setScissorRect(state.scissor_left, state.scissor_top, state.scissor_right, state.scissor_bottom, true)
		end
	end

	---# Ends new VGUI context
	---A modern alternative to paint.startPanel without the need to pass a reference of panel
	---and without the need to manually clip ``DScrollPanel``s.
	---@see paint.startPanel
	function paint.endVGUI()
		popModelMatrix()
		setScissorRect(0, 0, 0, 0, false)
	end

	paint.beginVGUI = paint.startVGUI
	paint.stopVGUI = paint.endVGUI

	--- Simple helper function which makes bilinear interpolation
	---@private Internal variable. Not meant to use outside
	---@param x number # x is fraction between 0 and 1. 0 - left side, 1 - right side
	---@param y number # y is fraction between 0 and 1. 0 - top side, 1 - bottom side
	---@param leftTop integer
	---@param rightTop integer
	---@param rightBottom integer
	---@param leftBottom integer
	---@return number result # result of bilinear interpolation
	function paint.bilinearInterpolation(x, y, leftTop, rightTop, rightBottom, leftBottom)
		if leftTop == rightTop and leftTop == rightBottom and leftTop == leftBottom then return leftTop end -- Fix (sometimes 255 alpha could get 254, probably double prescision isn't enought or smth like that)
		local top = leftTop == rightTop and leftTop or ((1 - x) * leftTop + x * rightTop)
		local bottom = leftBottom == rightBottom and leftBottom or
			((1 - x) * leftBottom + x * rightBottom) -- more precise checking
		return (1 - y) * top + y * bottom
	end
end

do
	local tab = {}

	-- When designing paint library i forgot that some third party libraries could use colors in pretty the same hacky way as i was
	-- This func will move all color refs to outer table instead of mofifying color itself
	---@param len 2
	---@param color Color
	---@return paint.linearGradientsTable
	---@overload fun(len : 4, color : Color) : paint.gradientsTable
	---@overload fun(len : 5, color : Color) : paint.gradientsTable
	function paint.getColorTable(len, color)
		for i = 1, len do
			tab[i] = color
		end

		return tab
	end
end

do
	if not file.Exists('shaders/fxc/paintlib_shader_ps30.vcs', 'MOD') then -- Shadered white material with dithering, inline gma injection is used.
		---Used to increase perf + disable gamma correction + dithering (to remove gradient banding)
		local gma = [[R01BRAMAAAAAAAAAAGuaJGgAAAAAAHBhaW50bGliIHNoYWRlcgB7CgkiZGVzY3JpcHRpb24iOiAi
		RGVzY3JpcHRpb24iLAoJInR5cGUiOiAic2VydmVyY29udGVudCIsCgkidGFncyI6IFsKCQkiYnVp
		bGQiLAoJCSJmdW4iCgldCn0AQXV0aG9yIE5hbWUAAQAAAAEAAABtYXRlcmlhbHMvcGFpbnRsaWIu
		dm10ABgCAAAAAAAAmVZRJgIAAABzaGFkZXJzL2Z4Yy9wYWludGxpYl9zaGFkZXJfcHMzMC52Y3MA
		cQEAAAAAAAB+v8m+AwAAAHNoYWRlcnMvZnhjL3BhaW50bGliX3NoYWRlcl92czMwLnZjcwClAQAA
		AAAAAGsVTFQAAAAAc2NyZWVuc3BhY2VfZ2VuZXJhbAp7CgkkcGl4c2hhZGVyICJwYWludGxpYl9z
		aGFkZXJfcHMzMCIKICAgICR2ZXJ0ZXhzaGFkZXIgInBhaW50bGliX3NoYWRlcl92czMwIgogICAg
		JGlnbm9yZXogICAgICAgICAgICAxCgoJJGJhc2V0ZXh0dXJlICIiCgkkdGV4dHVyZTEgICAgIiIK
		CSR0ZXh0dXJlMiAgICAiIgoJJHRleHR1cmUzICAgICIiCgogICAgJHZlcnRleGNvbG9yIDEKICAg
		ICR2ZXJ0ZXh0cmFuc2Zvcm0gMQoKICAgICRjMF94IDEuMAogICAgJGMwX3kgMS4wCiAgICAkYzBf
		eiAxLjAKICAgICRjMF93IDEuMAoKCSRjb3B5YWxwaGEgICAgICAgICAgICAgICAgIDAKCSRhbHBo
		YV9ibGVuZF9jb2xvcl9vdmVybGF5IDAKCSRhbHBoYV9ibGVuZCAgICAgICAgICAgICAgIDEKCSRs
		aW5lYXJ3cml0ZSAgICAgICAgICAgICAgIDEKCSRsaW5lYXJyZWFkX2Jhc2V0ZXh0dXJlICAgIDAK
		CSRsaW5lYXJyZWFkX3RleHR1cmUxICAgICAgIDAKCSRsaW5lYXJyZWFkX3RleHR1cmUyICAgICAg
		IDAKCSRsaW5lYXJyZWFkX3RleHR1cmUzICAgICAgIDAKfQoGAAAAAQAAAAEAAAAAAAAAAAAAAAIA
		AABL7ioNAAAAADAAAAD/////cQEAAAAAAAA5AQBATFpNQXgCAAAoAQAAXQAAAAEAAGiaXeCGv+yp
		J8XEIyBnOYzWiWMQpnqHj+igQa0vpL1baF70QH9iOW9HonOew/fDtQ0kPKqJWJbqVX90l4oT5560
		0ucYC+vkzTC+MAXy1dyXh/fDaWhxohmNcgEj6UoQYiP5PlkNWxnnBwvDjJkoe4IlhB14JNr6I2DJ
		fJnrlUAXLK1UVCUTv9yXgEycLLBVpo2f8RCB1k9fwkm3xOaV/r5gZIl8pt/ZRYG94yfIc8zYXJTb
		NYzKkhaX4aHOeA5Wo2bsB6n70OgUIcGXnLC2p8E/9aC+Eq42+5igB8u9fSu/S3hQ/+cgSOJbV/Sy
		WbCBuMvAObVGerLYONnieZ9oUMzgpBVf9Drs+pm89xpKBKb3qyRL9WZVxCXcgSOvGvkeAty1k03x
		AP////8GAAAAAQAAAAEAAAAAAAAAAAAAAAIAAAB3Q0KZAAAAADAAAAD/////pQEAAAAAAABtAQBA
		TFpNQWQEAABcAQAAXQAAAAEAAGiVXjSFv+xjGapeOKoS4OTw07jJnFNIBxQKhv/vJQgnEuk6S8i9
		iIOZ/cNnl7/kpbIBgyPggGrn4SUaCO4wMM2uaBqNFB4WPClr3W2FicbhjyonQ67Q6oYaEEu4Tu17
		xE7pKjTBMD1skFqcZFlmquDhVT5cVKqouodVdly2UrW6k5isS7ZWYZJdaQfqVAWOF8Vq5R385tAH
		sLGH5M+N+ECZpJv5SpYxCk1MLxSB0nv3/3Mz+jlCz3a8CEU/IWSl6lt4AVLtEofUP6eCTvQF2s2F
		XRrtEpQHI9BAuEQBqct+RuetelPCxZdaqLxgeV6qhbshamEvUWNu1lDz4CfLHGsjA5VhQgXVBZdG
		tTWxTpUQEvdF3wqhlSE5ESWuHP/KIIxPwCKCLSuH8E952Pdo4C+DRuaDvGtr1zHfgc1bFSBgKXLv
		DUKxOcxozUD1ymvSW1FbAH+qNahLhAD/////PyQ5WA==]]
		local gmaName = 'eventsui.gma'
		file.Write(gmaName, util.Base64Decode(gma))
		game.MountGMA('data/' .. gmaName)
	end

	paint.defaultMaterial = Material('paintlib')

	local testRT = GetRenderTarget('paintlib_test_rt', 8, 8)

	render.PushRenderTarget(testRT)

	render.Clear(0, 0, 0, 0, true, true)

	cam.Start2D()
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(paint.defaultMaterial)
	surface.DrawTexturedRect(0, 0, 8, 8)
	cam.End2D()

	render.CapturePixels()
	local r, g, b = render.ReadPixel(1, 1)

	render.PopRenderTarget()


	if r == 0 or g == 0 or b == 0 then
		---Fallback for cases if custom shader does not work properly
		paint.defaultMaterial = CreateMaterial('paintlib_no_shader', 'UnlitGeneric', {
			['$basetexture'] = 'color/white',
			['$model'] = 1,
			['$translucent'] = 1,
			['$vertexalpha'] = 1,
			['$vertexcolor'] = 1,
			['$gammacolorread'] = 1,
			['$linearwrite'] = 1
		})

		if not IsValid(paint.defaultMaterial) then
			paint.defaultMaterial = Material('vgui/white')
		end
	end
end

---@diagnostic disable-next-line: undefined-global
if not MINIFIED then
	_G.paint --[[@as paint]] = paint
end
