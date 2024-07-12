local paint = paint--[[@as paint]]

---@class batch
local batch = {}

batch.batching = false

---@type table # current batching table
local batchTable = {
	[0] = 0
}

--- Resets batching queue
function batch.reset()
	batchTable = {
		[0] = 0
	}

	---@type table # current batching table
	batch.batchTable = batchTable
end

--- Starts batching queue
function batch.startBatching()
	batch.batching = true
	batch.reset()
end

--[[
	I guess this function will get JIT compiled
]]

--- Internal function
---@param tab table
---@param i integer
---@return number
---@return number
---@return number
---@return Color
---@return number
---@return number
---@return Color
---@return number
---@return number
---@return Color
local function getVariables(tab, i)
	return tab[i], tab[i + 1], tab[i + 2], tab[i + 3], tab[i + 4], tab[i + 5], tab[i + 6], tab[i + 7], tab[i + 8], tab[i + 9]
end

do
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex

	local meshConstructor = Mesh
	local PRIMITIVE_TRIANGLES = MATERIAL_TRIANGLES

	--- Stops batching queue and returns builded mesh.
	---@return IMesh batchedMesh #batched mesh
	---@nodiscard
	function batch.stopBatching()
		local tab = batch.batchTable

		local iMesh = meshConstructor()

		meshBegin(iMesh, PRIMITIVE_TRIANGLES, tab[0] * 0.3)
			for i = 1, tab[0], 10 do
				local x, y, z, color, x1, y1, color1, x2, y2, color2 = getVariables(tab, i)

				meshPosition(x, y, z)
				meshColor(color.r, color.g, color.b, color.a)
				meshAdvanceVertex()

				meshPosition(x1, y1, z)
				meshColor(color1.r, color1.g, color1.b, color1.a)
				meshAdvanceVertex()

				meshPosition(x2, y2, z)
				meshColor(color2.r, color2.g, color2.b, color2.a)
				meshAdvanceVertex()
			end
		meshEnd()

		batch.reset()
		batch.batching = false

		return iMesh
	end
end

---@type table current batching table
batch.batchTable = batchTable

-- used _G because lsp doesn't recognize the table

--- Batch library for paint lib
_G.paint.batch = batch