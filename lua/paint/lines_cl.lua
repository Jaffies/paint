---@diagnostic disable: deprecated
local paint = paint --[[@as paint]]

---	Lines. Why they are good?
---	1) They support gradients. It means that you do not need to make a lot of lines to make
---	color grading smooth between start of segment and the end of it.
---
---	2) They support batching. It means that you can make a lot of lines without any performance costs
--- Examples of paint.lines
---
--- Simple line example:
---
--- Drawing lines with a gradient of different colors.
---```lua
---	paint.lines.drawLine( 10, 20, 34, 55, Color( 0, 255, 0 ), Color( 255, 0, 255 ) )
---	paint.lines.drawLine( 40, 10, 70, 40, Color( 255, 255, 0 ) )
---```
---Batched Lines Example:
---
---Drawing 50 lines with improved performance by using batching.
---```lua
---paint.lines.startBatching()
---	for i = 1, 50 do
---		paint.lines.drawLine( i * 10, 10, i * 10 + 5, 55, Color( 0, i * 255 / 50, 0 ), Color( 255, 0, 255 ) )
---	end
---paint.lines.stopBatching()
---```
---@class paint.lines
local lines = {}

--- batch table
local batch = { [0] = 0 }

local PRIMITIVE_LINES = MATERIAL_LINES
local PRIMITIVE_LINE_STRIP = MATERIAL_LINE_STRIP
local PRIMITIVE_LINE_LOOP = MATERIAL_LINE_LOOP

do
	-- define drawing functions
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex

	local renderSetColorMaterialIgnoreZ = render.SetColorMaterialIgnoreZ

	-- single line
	-- It is used when there is no any batching.

	---Draws single unbatched line. Used internally
	---@param startX number
	---@param startY number
	---@param endX number
	---@param endY number
	---@param startColor Color
	---@param endColor? Color
	---@private Internal variable. Not meant to use outside
	function lines.drawSingleLine(startX, startY, endX, endY, startColor, endColor)
		if endColor == nil then
			endColor = startColor
		end

		renderSetColorMaterialIgnoreZ()

		meshBegin(PRIMITIVE_LINES, 1)
		meshColor(startColor.r, startColor.g, startColor.b, startColor.a)

		meshPosition(startX, startY, 0)

		meshAdvanceVertex()

		meshColor(endColor.r, endColor.g, endColor.b, endColor.a)

		meshPosition(endX, endY, 0)

		meshAdvanceVertex()
		meshEnd()
	end
end

do -- drawing
	local drawSingleLine = lines.drawSingleLine

	--- Draws a line with the specified parameters.
	---@param startX number # The X position of the start of the line
	---@param startY number # The Y position of the start of the line
	---@param endX number # The X position of the end of the line
	---@param endY number # The Y position of the end of the line
	---@param startColor Color # The color of the start of the line
	---@param endColor? Color  # The color of the end of the line.  Default: startColor
	function lines.drawLine(startX, startY, endX, endY, startColor, endColor)
		drawSingleLine(startX, startY, endX, endY, startColor, endColor)
	end
end

paint.lines = lines
