---# Simple masking library
---
---Provides the way to make masks. Really simple
---
---Coded in couple of minutes.
---Bug tested in couple of days
---
---A simplier version of melonmasks which uses ``render.OverrideAlphaWriteEnable`` what i used for masking stuff
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

	hook.Add('OnScreenSizeChanged', 'simpleMask', function(_, _, newW, newH)
		w, h = newW, newH

		rt:Download() -- I vaguely remember it being used to reset rt params. Might not work btw..
		rt = GetRenderTargetEx('paint.masksRT', w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1 + 256, 0, IMAGE_FORMAT_BGRA8888)
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

	local surfaceSetMaterial = surface.SetMaterial
	local surfaceSetDrawColor = surface.SetDrawColor
	local surfaceGetDrawColor = surface.GetDrawColor
	local surfaceDrawTexturedRect = surface.DrawTexturedRect
	--- No surface.GetMaterial, so material won't be restored

	---@type fun()
	masks.source = function()
		renderPushRenderTarget(rt)
		renderOverrideAlphaWriteEnable(true, true)
		renderClear(0, 0, 0, 0, true, true)

		camStart2D()
	end

	---@type fun()
	masks.destination = function()
		camEnd2D()
		renderOverrideAlphaWriteEnable(true, false)
		camStart2D()
	end

	---@type fun()
	masks.stop = function()
		camEnd2D()
		renderPopRenderTarget()

		local oldColor = surfaceGetDrawColor()

		surfaceSetMaterial(material)
		surfaceSetDrawColor(255, 255, 255)
		surfaceDrawTexturedRect(0, 0, w, h)
		surfaceSetDrawColor(oldColor)
	end
end

paint.masks = masks