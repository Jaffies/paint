---@diagnostic disable: deprecated
local paint = paint --[[@as paint]]
---# Batching library of paint lib
---This is a really hard to explain thing, and made for experienced lua coders
---
---This library allows you to generate IMeshes on the fly, by using default
---paint library draw functions
---
---In order to cache resulted IMesh of course!
---
---That allows you to batch your multiple shape in 1 single mesh in order to save draw calls
---@class paint.batch
local batch = {}

do
	---@class paint.batch.atlasData
	---@field size integer
	---@field cellSize integer
	---@field cells { [string] : integer, [0] : integer } table containing string id of cells and it's int position

	local getRenderTarget = GetRenderTarget

	---@type {[string] : paint.batch.atlasData}
	local atlasData = {}
	---@rtoe {[string] : ITexture}
	local atlasTextures = {}

	---@param name string
	---@param atlasSize integer
	---@param cellSize integer # max value is ``atlasSize / 2``
	function batch.createAtlas(name, atlasSize, cellSize)
		---@type paint.batch.atlasData
		local data = { size = atlasSize, cellSize = cellSize, cells = { [0] = 0 } }

		atlasData[name] = data
		atlasTextures[name] = getRenderTarget('paintlib.' .. name, atlasSize, atlasSize)

		return atlasData[name], atlasTextures[name]
	end

	---@param name string
	function batch.getAtlas(name)
		return atlasData[name], atlasTextures[name]
	end

	---@param name string
	---@param id string
	function batch.createAtlasCell(name, id)
		local cells = atlasData[name].cells
		local position = cells[0] + 1

		cells[id] = position
		cells[0] = position
	end

	local floor = math.floor

	---@param name string
	---@return number uStart
	---@return number vStart
	---@return number uEnd
	---@return number vEnd
	function batch.getAtlasCellPosition(name, id)
		local data = atlasData[name]

		if not data then
			return 0, 0, 1, 1
		end

		local position = data.cells[id] - 1

		local atlasSize = data.size
		local cellSize = data.cellSize
		local cellsPerRow = atlasSize / data.cellSize

		local x = position % cellsPerRow
		local y = floor(position / cellsPerRow)

		local xUV, yUV = (cellSize * x) / atlasSize, cellSize * y / atlasSize
		return xUV, yUV, xUV + cellSize / atlasSize, yUV + cellSize / atlasSize
	end

	---@type string|nil
	local currentAtlas
	---@type string?
	local currentCell

	---@param name string? # can be nil to unset atlas
	function batch.setDrawAtlas(name)
		currentAtlas = name
	end

	---@return string|nil returns nil if no atlas was set
	function batch.getDrawAtlas()
		return currentAtlas
	end

	---@param id string?
	function batch.setDrawCell(id)
		currentCell = id
	end

	function batch.getDrawCell()
		return currentCell
	end

	---@param atlasName string
	---@param cellId string
	---@param material IMaterial
	function batch.copyMaterialToAtlas(atlasName, cellId, material)
		local data, texture = batch.getAtlas(atlasName)

		local uStart, vStart, uEnd, vEnd = batch.getAtlasCellPosition(atlasName, cellId)
		local size, cellSize = data.size, data.cellSize

		render.PushRenderTarget(texture)
		cam.Start2D()
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(material)
		surface.DrawTexturedRect(uStart * size, vStart * size, cellSize, cellSize)
		cam.End2D()
		render.PopRenderTarget()
	end

	batch.offsetX = 0
	batch.offsetY = 0

	---@offsets x, y positions for batching.
	---@param x number
	---@param y number
	function batch.setRelativePosition(x, y)
		batch.offsetX = x
		batch.offsetY = y
	end
end

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
---@param i integer offset
---@return number x
---@return number y
---@return number z
---@return Color color
---@return number x1
---@return number y1
---@return Color color1
---@return number x2
---@return number y2
---@return Color color2
---@return number u1
---@return number v1
---@return number u2
---@return number v2
---@return number u3
---@return number v3
---@return integer cellPosition
local function getVariables(tab, i)
	return tab[i], tab[i + 1], tab[i + 2], tab[i + 3], tab[i + 4], tab[i + 5], tab[i + 6], tab[i + 7], tab[i + 8],
		tab[i + 9], tab[i + 10], tab[i + 11], tab[i + 12], tab[i + 13], tab[i + 14], tab[i + 15], tab[i + 16]
end

do
	local meshBegin = mesh.Begin
	local meshEnd = mesh.End
	local meshPosition = mesh.Position
	local meshTexCoord = mesh.TexCoord
	local meshColor = mesh.Color
	local meshAdvanceVertex = mesh.AdvanceVertex

	local meshConstructor = Mesh
	local PRIMITIVE_TRIANGLES = MATERIAL_TRIANGLES

	local remap = math.Remap

	--- Stops batching queue and returns builded mesh.
	---@return IMesh batchedMesh #batched mesh
	---@nodiscard
	function batch.stopBatching()
		local tab = batch.batchTable

		local iMesh = meshConstructor()

		meshBegin(iMesh, PRIMITIVE_TRIANGLES, tab[0] * 0.3)
		local res, reason = pcall(function()
			local atlas = batch.getDrawAtlas()

			local offsetX, offsetY = batch.offsetX, batch.offsetY
			for i = 1, tab[0], 17 do
				local x, y, z, color, x1, y1, color1, x2, y2, color2, u1, v1, u2, v2, u3, v3, cell = getVariables(
					tab, i)

				local cellu1, cellv1, cellu2, cellv2 = 0, 0, 1, 1
				if atlas and cell then
					cellu1, cellv1, cellu2, cellv2 = batch.getAtlasCellPosition(atlas, cell)
				end

				u1, v1, u2, v2, u3, v3 = u1 or 0, v1 or 1, u2 or 1, v2 or 0, u3 or 1, v3 or 1

				x = x + offsetX
				y = y + offsetY

				meshPosition(x, y, z)
				meshColor(color.r, color.g, color.b, color.a)
				meshTexCoord(0, remap(u1, 0, 1, cellu1, cellu2), remap(v1, 0, 1, cellv1, cellv2))
				meshAdvanceVertex()

				meshPosition(x1, y1, z)
				meshColor(color1.r, color1.g, color1.b, color1.a)
				meshTexCoord(0, remap(u2, 0, 1, cellu1, cellu2), remap(v2, 0, 1, cellv1, cellv2))
				meshAdvanceVertex()

				meshPosition(x2, y2, z)
				meshColor(color2.r, color2.g, color2.b, color2.a)
				meshTexCoord(0, remap(u3, 0, 1, cellu1, cellu2), remap(v3, 0, 1, cellv1, cellv2))
				meshAdvanceVertex()
			end
		end)
		meshEnd()

		if not res then
			print('[paint] batching error', reason)
		end

		batch.reset()
		batch.batching = false

		return iMesh
	end
end

do
	local meshDraw = FindMetaTable('IMesh') --[[@as IMesh]].Draw
	local meshDestroy = FindMetaTable('IMesh') --[[@as IMesh]].Destroy
	local resetZ = paint.resetZ

	local setMaterial = render.SetMaterial

	local startBatching = batch.startBatching
	local stopBatching = batch.stopBatching

	local startVGUI, endVGUI = paint.startVGUI, paint.endVGUI

	---@param self paint.injectedPanel
	---@param x number
	---@param y number
	local panelPaint = function(self, x, y)
		do
			local beforePaint = self.BeforePaint
			if beforePaint then
				beforePaint(self, x, y)
			end
		end

		local iMesh = self.iMesh
		if not iMesh then return end
		setMaterial(paint.defaultMaterial)

		startVGUI()
		meshDraw(iMesh)
		endVGUI()
	end

	---@param self paint.injectedPanel
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

	---@param self paint.injectedPanel
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

	---@param self paint.injectedPanel
	local panelRemove = function(self)
		if IsValid(self.iMesh) then
			self.iMesh:Destroy()
		end
	end

	---@class paint.injectedPanel : Panel # The injected panel is a supporting class that actually behaves as a wrapped pannel. Made for people who like
	---type checking, and lsp things. Used internally only.
	---@field Paint function
	---@field OnSizeChanged function
	---@field OnOldRemove function?
	---@field OldOnSizeChanged function?
	---@field RebuildMesh function
	---@field BeforePaint function?
	---@field PaintMesh function?
	---@field OnRemove function
	---@field iMesh IMesh?

	---Wraps panel with some hacky functions that overrides paint function and OnChangeSize
	---That is made for panel to use Panel:PaintMesh() when panel is updated (size updated/etc)
	---@param panel Panel
	function batch.wrapPanel(panel)
		---@cast panel paint.injectedPanel
		panel.Paint = panelPaint
		panel.OldOnSizeChanged = panel.OnSizeChanged
		panel.OnSizeChanged = panelOnSizeChanged
		panel.RebuildMesh = panelRebuildMesh
		panel.OnOldRemove = panel.OnRemove
		panel.OnRemove = panelRemove
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

--- Batch library for paint lib
paint.batch = batch
