---@diagnostic disable: deprecated
local paint = paint--[[@as paint]]
---# Batching library of paint lib 
---This is a really hard to explain thing, and made for experienced lua coders
---
---This library allows you to generate IMeshes on the fly, by using default
---paint library draw functions
---
---In order to cache resulted IMesh of course!
---
---That allows you to batch your multiple shape in 1 single mesh in order to save draw calls
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

do
	local startPanel, endPanel = paint.startPanel, paint.endPanel
	local meshDraw = FindMetaTable('IMesh')--[[@as IMesh]].Draw
	local meshDestroy = FindMetaTable('IMesh')--[[@as IMesh]].Destroy
	local resetZ = paint.resetZ

	local whiteMat = Material('vgui/white')
	local setMaterial = render.SetMaterial

	local startBatching = batch.startBatching
	local stopBatching = batch.stopBatching

	---@param self InjectedPanel
	---@param x number
	---@param y number
	local panelPaint = function(self, x, y)
		local iMesh = self.iMesh
		if not iMesh then return end

		do
			local beforePaint = self.BeforePaint
			if beforePaint then
				beforePaint(self, x, y)
			end
		end

		local disableBoundaries = self.DisableBoundaries

		setMaterial(whiteMat)

		startPanel(self, true, disableBoundaries ~= true)
			meshDraw(iMesh)
		endPanel(true, disableBoundaries ~= true)

		do
			local afterPaint = self.AfterPaint
			if afterPaint then
				afterPaint(self, x, y)
			end
		end
	end

	---@param self InjectedPanel
	---@param x number
	---@param y number
	local panelRebuildMesh = function(self, x, y)
		resetZ()
			local iMesh = self.iMesh
			if iMesh then
				meshDestroy(iMesh)
			end

			local drawFunc = self.PaintMesh

			if drawFunc then
				startBatching()
					drawFunc(self, x, y)
				self.iMesh = stopBatching()
			end
		resetZ()
	end

	---@param self InjectedPanel
	---@param x number
	---@param y number
	local panelOnSizeChanged = function(self, x, y)
		local rebuildMesh = self.RebuildMesh

		if rebuildMesh then
			rebuildMesh(self, x, y)
		end

		local oldOnSizeChanged = self.OldOnSizeChanged

		if oldOnSizeChanged then
			oldOnSizeChanged(self, x, y)
		end
	end

	---@class InjectedPanel : Panel # The injected panel is a supporting class that actually behaves as a wrapped pannel. Made for people who like
	---type checking, and lsp things. Used internally only.
	---@field Paint function
	---@field OnSizeChanged function
	---@field OldOnSizeChanged function?
	---@field RebuildMesh function
	---@field DisableBoundaries boolean?
	---@field BeforePaint function?
	---@field AfterPaint function?
	---@field PaintMesh function?
	---@field iMesh IMesh?

	---Wraps panel with some hacky functions that overrides paint function and OnChangeSize
	---That is made for panel to use Panel:PaintMesh() when panel is updated (size updated/etc)
	---@param panel Panel
	function batch.wrapPanel(panel)
		---@cast panel InjectedPanel
		panel.Paint = panelPaint
		panel.OldOnSizeChanged = panel.OnSizeChanged
		panel.OnSizeChanged = panelOnSizeChanged
		panel.RebuildMesh = panelRebuildMesh
	end
end

do
	---Adds triangle to batching queue. If you want to manually add some figures to paint batching, then you can use this.
	---@param z number Z position of next triangle. You want to use paint.incrementZ for that
	---@param x1 number
	---@param y1 number
	---@param color1 Color color of first vertex
	---@param x2 number
	---@param y2 number
	---@param color2 Color color of second vertex
	---@param x3 number
	---@param y3 number
	---@param color3 Color color of third vertex
	function batch.addTriangle(z, x1, y1, color1, x2, y2, color2, x3, y3, color3)
		local len = batchTable[0]

		batchTable[len + 1] = x1
		batchTable[len + 2] = y1
		batchTable[len + 3] = z
---@diagnostic disable-next-line: assign-type-mismatch
		batchTable[len + 4] = color1

		batchTable[len + 5] = x2
		batchTable[len + 6] = y2
---@diagnostic disable-next-line: assign-type-mismatch
		batchTable[len + 7] = color2

		batchTable[len + 8] = x3
		batchTable[len + 9] = y3
---@diagnostic disable-next-line: assign-type-mismatch
		batchTable[len + 10] = color3

		batchTable[0] = len + 10
	end
end

---@type table current batching table
batch.batchTable = batchTable

-- used _G because lsp doesn't recognize the table

--- Batch library for paint lib
_G.paint.batch = batch