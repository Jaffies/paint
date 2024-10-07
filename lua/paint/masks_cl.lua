---@diagnostic disable: deprecated
---# Simple masking library
---
---Provides the way to make masks. Really simple
---
---Coded in couple of minutes.
---Bug tested in couple of days
---
---A simplier version of melonmasks which uses ``render.OverrideAlphaWriteEnable``
---
---## Example
---```lua
--- paint.masks.source()
--- 	draw.RoundedBox(32, 0, 0, 128, 128, color_black)
--- 	draw.SimpleText('Test text test text test text', 'DermaDefault', 64, 130, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
--- paint.masks.destination()
--- 	surface.SetDrawColor(255, 0, 0)
--- 	surface.DrawRect(0, 0, 128, 150)
---
--- 	surface.SetDrawColor(255, 255, 255)
--- 	surface.SetMaterial(material)
--- 	surface.DrawTexturedRect(0, 0, 128, 150)
--- paint.masks.stop()
---```
---@class paint.masks
---@field source fun() # starts masking. The things you will draw there will be the alpha mask.
---@field destination fun() # coninues masking. The things you will draw there would be alpha masked.
---@field stop fun() # stops masking session and draws final result.
local masks = {}
do
	local w, h = ScrW(), ScrH()
	local rt = GetRenderTargetEx('paint.masksRT', w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1 + 256, 0, IMAGE_FORMAT_BGRA8888)

	local material = CreateMaterial( "paint.masksMaterial", "UnlitGeneric", {
	  ["$basetexture"] = "paint.masksRT",
	  ["$translucent"] = 1,
	})

	---@type IMesh?
	local rectMesh

	local function createRectMesh()
		if rectMesh then
			rectMesh:Destroy()
		end

		rectMesh = Mesh(material)

		local color = Color(255, 255, 255)
		paint.rects.generateRectMesh(rectMesh, 0, 0, w, h, {color, color, color, color}, 0, 0, 1, 1)
	end

	createRectMesh()
	---@cast rectMesh -?

	hook.Add('OnScreenSizeChanged', 'paint.masks', function(_, _, newW, newH)
		w, h = newW, newH

		rt:Download() -- I vaguely remember it being used to reset rt params. Might not work btw..
		rt = GetRenderTargetEx('paint.masksRT', w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1 + 256, 0, IMAGE_FORMAT_BGRA8888)

		createRectMesh()
	end)

	local renderPushRenderTarget = render.PushRenderTarget
	local renderPopRenderTarget = render.PopRenderTarget
	local renderClear = render.Clear
	local renderOverrideAlphaWriteEnable = render.OverrideAlphaWriteEnable

	local camStart2D
	do
		local camStart = cam.Start
		local data = {type = '2d'}

		function camStart2D()
			camStart(data)
		end
	end
	local camEnd2D = cam.End2D

	---@type fun()
	masks.source = function()
		renderPushRenderTarget(rt)
		renderOverrideAlphaWriteEnable(true, true)
		renderClear(0, 0, 0, 0)

		camStart2D()
	end

	---@type fun()
	masks.destination = function()
		camEnd2D()
		renderOverrideAlphaWriteEnable(true, false)
		camStart2D()
	end

	local setMaterial = render.SetMaterial
	local drawMesh = rectMesh.Draw

	---@type fun()
	masks.stop = function()
		camEnd2D()
		renderPopRenderTarget()

		setMaterial(material)
		drawMesh(rectMesh)
	end
end

paint.masks = masks