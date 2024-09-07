---@diagnostic disable: deprecated
local paint = paint--[[@as paint]]

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
---@field drawLine function
---@field startBatching function
---@field stopbatching function
local lines = {}

--- batch table
local batch = {[0] = 0}

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
	---@deprecated Internal variable. Not meant to use outside
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

	-- Now batched lines

	--[[
		primitiveType is either MATERIAL_LINES, MATERIAL_LINE_STRIP or MATERIAL_LINE_LOOP

		array is a one dimensional one which has this lines
		{
			x, y, color
			x1, y1, color1,
			x2, y2, color2,
			x3, y3, color3,
			x4, y4, color4,
			x5, y5, color5
		}
	--]]

	--- internal function enum, used like switch case
	local counts = {
		[PRIMITIVE_LINES] = function(len) return len / 6 end,
		[PRIMITIVE_LINE_STRIP] = function(len) return len / 6 end,
		[PRIMITIVE_LINE_LOOP] = function(len) return len / 6 - 1 end
	}

	---Draws batched lines
	---@deprecated Internal variable. Not meant to use outside
	---@param array table # array with [startX:number, startY:number, startColor:Color, endColor:Color ...]
	function lines.drawBatchedLines(array)
		---@type number
		local primitiveType = array[-1] or PRIMITIVE_LINES

		renderSetColorMaterialIgnoreZ()

		meshBegin(primitiveType, counts[primitiveType](array[0]))
		if primitiveType == PRIMITIVE_LINES then
			for i = 1, array[0], 6 do
				local startX, startY, endX, endY = array[i], array[i + 1], array[i + 3], array[i + 4]
				local startColor, endColor = array[i + 2], array[i + 5]

				meshColor(startColor.r, startColor.g, startColor.b, startColor.a)
				meshPosition(startX, startY, 0)

				meshAdvanceVertex()

				meshColor(endColor.r, endColor.g, endColor.b, endColor.a)
				meshPosition(endX, endY, 0)

				meshAdvanceVertex()
			end
		elseif primitiveType == PRIMITIVE_LINE_STRIP then
			meshPosition(array[1], array[2], 0)

			local startColor = array[3]

			meshColor(startColor.r, startColor.g, startColor.b, startColor.a)

			meshAdvanceVertex()

			for i = 4, array[0], 6 do
				local x, y, color = array[i], array[i + 1], array[i + 2]

				meshPosition(x, y, 0)
				meshColor(color.r, color.g, color.b, color.a)

				meshAdvanceVertex()
			end
		else -- PRIMITIVE_LINE_LOOP
			meshPosition(array[1], array[2], 0)

			local startColor = array[3]

			meshColor(startColor.r, startColor.g, startColor.b, startColor.a)

			meshAdvanceVertex()

			for i = 4, array[0] - 3, 6 do -- last 3 is basically a start.
				local x, y, color = array[i], array[i + 1], array[i + 2]

				meshPosition(x, y, 0)

				meshColor(color.r, color.g, color.b, color.a)

				meshAdvanceVertex()
			end
		end
		meshEnd()
	end
end

---@type boolean
local batching = false

do -- batching functions

	--- Starts line batching. All lines drawn after this function is called will be batched until stopBatching() is called.
	--- Note: Batching is not shared between different types of shapes.
	function lines.startBatching()
		batching = true

		batch[-1] = PRIMITIVE_LINE_STRIP -- set as default one
		batch[0] = 0
	end

	--- Stops batching and draws final result.
	---@see lines.startBatching
	function lines.stopBatching()
		-- last check if it is a line loop

		local len = batch[0]

		if batch[-1] == PRIMITIVE_LINE_STRIP and batch[1] == batch[len - 2] and batch[2] == batch[len - 1] and batch[3] == batch[len] then
			batch[-1] = PRIMITIVE_LINE_LOOP
		end

		lines.drawBatchedLines(batch)

		batching = false

		batch = { [0] = 0 } -- reseting queued batches
	end

	--- Adds line to batching queue
	---@param startX number
	---@param startY number
	---@param endX number
	---@param endY number
	---@param startColor Color
	---@param endColor? Color
	---@deprecated Internal variable. Not meant to use outside
	function lines.drawBatchedLine(startX, startY, endX, endY, startColor, endColor)
		if endColor == nil then
			endColor = startColor
		end

		---@type integer
		local len = batch[0]

		if batch[-1] == PRIMITIVE_LINE_STRIP and batch[0] ~= 0 then -- check if it is a line strip
			if startX ~= batch[len - 2] or startY ~= batch[len - 1] or startColor ~= batch[len] then
				batch[-1] = PRIMITIVE_LINES
			end
		end

		batch[len + 1] = startX
		batch[len + 2] = startY
---@diagnostic disable-next-line: assign-type-mismatch
		batch[len + 3] = startColor
		batch[len + 4] = endX
		batch[len + 5] = endY
---@diagnostic disable-next-line: assign-type-mismatch
		batch[len + 6] = endColor

		batch[0] = len + 6
	end
end

do -- drawing

	local drawSingleLine = lines.drawSingleLine
	local drawBatchedLine = lines.drawBatchedLine

	--- Draws a line with the specified parameters.
	---@param startX number # The X position of the start of the line
	---@param startY number # The Y position of the start of the line
	---@param endX number # The X position of the end of the line
	---@param endY number # The Y position of the end of the line
	---@param startColor Color # The color of the start of the line
	---@param endColor? Color  # The color of the end of the line.  Default: startColor
	function lines.drawLine(startX, startY, endX, endY, startColor, endColor)
		if batching then
			drawBatchedLine(startX, startY, endX, endY, startColor, endColor)
		else
			drawSingleLine(startX, startY, endX, endY, startColor, endColor)
		end
	end

end

paint.lines = lines