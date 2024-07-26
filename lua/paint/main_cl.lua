---@class paint
---@field lines lines
---@field roundedBoxes roundedBoxes
---@field rects rects
---@field outlines outlines
---@field batch batch
---@field examples paint.examples
---@field blur blur
---@field circles circles
local paint = {}

---@alias gradients Color | Color[]
--[[
	Paint library.

	Purpose: drop in replacement to all surface/draw functions. Now there's no need to use them

	Features:
		1) Enchanced lines, with support of linear gradients.
		2) Enchanced rounded boxes. They support stencils, materials and outlines.
		3) Circles. Super fast.
		4) Batching. Everything here can be batched to save draw calls. Saves a lot of performance.
		5) This library is SUPER fast. Some functions here are faster than default ones.
		6) Rectangle support, with support of per-corner gradienting
		7) Coordinates do not end up being rounded. Good for markers and other stuff.


	Coded by @jaffies, aka @mikhail_svetov (formely @michael_svetov) in discord.
	Thanks to A1steaksa, PhoenixF and other people in gmod discord for various help

--]]

do
	-- this fixes rendering issues with batching

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

	--- Calculates Z position, depending of paint.Z value
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

        tab[len] = {x, y, endX, endY}
        setScissorRect(x, y, endX, endY, true)
    end

    --- Pops last scissor rect's boundaries from the stack. Simmilar to Pop ModelMatrix/RenderTarget/Filter(Mag/Min)
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
	-- Helper functions
	-- startPanel - pops model matrix and pushes

	local matrix = Matrix()
	local setField = matrix.SetField

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	---@type Panel
	local panelTab = FindMetaTable('Panel')

	local localToScreen = panelTab.LocalToScreen
	local getSize = panelTab.GetSize

	local pushScissorRect = paint.pushScissorRect
	local popScissorRect = paint.popScissorRect

	--- Helper function, which sets drawing coordinates to panel's relative coordinates, and boundaries if enabled
	---@param panel Panel
	---@param pos? boolean # use panel's relative coordinates in next drawing operations? Default - yes
	---@param boundaries? boolean # use panel's boundaries with scissor rect? Default - no
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

	--- Helper function, which must be used after paint.startPanel
	---@param pos? boolean # remove panel relatvie coordinates? Default - yes
	---@param boundaries? boolean # remove panel boundaries by scissorRect? Default - no
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

	--- Simple helper function which makes bilinear interpolation
	---@param x number # x is fraction between 0 and 1. 0 - left side, 1 - right side
	---@param y number # y is fraction between 0 and 1. 0 - top side, 1 - bottom side
	---@param leftTop integer
	---@param rightTop integer
	---@param rightBottom integer
	---@param leftBottom integer
	---@return number result # result of bilinear interpolation
	function paint.bilinearInterpolation(x, y, leftTop, rightTop, rightBottom, leftBottom)
		if leftTop == rightTop and leftTop == rightBottom and leftTop == leftBottom then return leftTop end -- Fix (sometimes 255 alpha could get 254, probably double prescision isn't enought or smth like that)
		local top = leftTop == rightTop and leftTop or ( (1 - x) * leftTop + x * rightTop)
		local bottom = leftBottom == rightBottom and leftBottom or ((1 - x) * leftBottom + x * rightBottom) -- more precise checking
		return (1 - y) * top + y * bottom
	end
end

---paint library
_G.paint = paint