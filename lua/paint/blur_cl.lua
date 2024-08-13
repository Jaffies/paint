---@diagnostic disable: deprecated
---The paint library has a built-in blur effect!
---
---This works by taking a copy of the screen, lowering its resolution, blurring it, then returning that as a material.
---
---You can then use that material with any of the paint functions to draw a blurred shape.
---
---It's a simple, cheap, and cool effect!
---
---Simple example:
---```lua
---local x, y = panel:LocalToScreen( 0, 0 ) -- getting absolute position
---local scrW, scrH = ScrW(), ScrH() -- it will be used to get UV coordinates
---local mat = paint.blur.getBlurMaterial()
---paint.rects.drawRect( 0, 0, 100, 64, color_white, mat, x / scrW, y / scrH, (x + 100) / scrW, (y + 64) / scrH )
---paint.roundedBoxes.roundedBox( 32, 120, 0, 120, 64, color_white, mat, (x + 120) / scrW, y / scrH, (x + 240) / scrW, (y + 64) / scrH )
---``` 

---@class blur
local blur = {}
local paint = paint

--[[
	Library that gets blured frame texture.
	It doesn't ocupy smalltex1 now. Use it freely)
]]

local RT_SIZE = 256

local BLUR = 20
local BLUR_PASSES = 3
local BLUR_TIME = 1 / 30

local BLUR_EXPENSIVE = false

local RT_FLAGS = 2 + 256 + 32768
local TEXTURE_PREFIX = 'paint_library_rt_'
local MATERIAL_PREFIX = 'paint_library_material_'

---@type {[string] : ITexture}
local textures = {
	default = GetRenderTargetEx(TEXTURE_PREFIX .. 'default', RT_SIZE, RT_SIZE, 1, 2, RT_FLAGS, 0, 2)
}

---@type {[string] : number}
local textureTimes = {
	default = 0
}

---@type {[string] : IMaterial}
local textureMaterials = {
	default = CreateMaterial(MATERIAL_PREFIX .. 'default', 'UnlitGeneric', {
		['$basetexture'] = TEXTURE_PREFIX .. 'default',
		['$vertexalpha'] = 1,
		['$vertexcolor'] = 1,
	})
}


do
	local copyRTToTex = render.CopyRenderTargetToTexture

	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget

	local start2D = cam.Start2D
	local end2D = cam.End2D

	local overrideColorWriteEnable = render.OverrideColorWriteEnable
	local overrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
	local drawScreenQuad = render.DrawScreenQuad
	local updateScreenEffectTexture = render.UpdateScreenEffectTexture
	local setMaterial = render.SetMaterial

	local blurMaterial = Material('pp/blurscreen')

	local setTexture = blurMaterial.SetTexture
	local setFloat = blurMaterial.SetFloat
	local recompute = blurMaterial.Recompute

	local screenEffectTexture = render.GetScreenEffectTexture()
	local whiteMaterial = Material('vgui/white')

	local blurRTExpensive = render.BlurRenderTarget

	---@param rt ITexture
	---@param _ number
	---@param blurStrength number
	---@param passes number
	local function blurRTCheap(rt, _, blurStrength, passes)
		setMaterial(blurMaterial)
		setTexture(blurMaterial, '$basetexture', rt)

		for i = 1, passes do
 			setFloat(blurMaterial, '$blur', (i / passes) * blurStrength)
 			recompute(blurMaterial)

 			-- if you don't update screenEffect texture
 			-- Then for whatever reason gmodscreenspace
 			-- shader won't update it's $basetexture
 			-- resulting in broken passes
 			-- and picture like it was only single pass instead of multiple.

 			--ScreenEffect texutre is not used by blur at all.
 			--Like literally, i have to update it only for gmodscreenspace shader to work.
 			--That's tottally retarded.
			updateScreenEffectTexture()
			drawScreenQuad()
		end

		--Reseting it's basetexture to default one
		setTexture(blurMaterial, '$basetexture', screenEffectTexture)
	end


	---Blurs texture with specified parameters
	---@param blurStrength number? How much blur strength the result texture will have. Overrides BLUR
	---@param passes number? How much bluring passes texture will have. More passes will result in better bluring quality, but worse performace. Affects performance a lot.
	---@param expensive boolean? If set to true, it will try to blur texture with defualt Source Engine shaders called BlurX, BlurY. They are expensive. If unset or false, it will try to blur stuff with gmodscreenspace shader.
	function blur.generateBlur(id, blurStrength, passes, expensive) -- used right before drawing 2D shit
		local texToBlur = textures[id or 'default']

		blurStrength = blurStrength or BLUR
		passes = passes or BLUR_PASSES
		expensive = expensive or BLUR_EXPENSIVE

		copyRTToTex(texToBlur)

 		pushRenderTarget(texToBlur)
 			start2D()
 				---@type fun(texture: ITexture, blurX: number, blurY: number, passes: number)
 				local blurRT = expensive and blurRTExpensive or blurRTCheap
 				blurRT(texToBlur, blurStrength, blurStrength, passes)

	 			overrideAlphaWriteEnable(true, true)
	 			overrideColorWriteEnable(true, false)

	 			setMaterial(whiteMaterial)
	 			drawScreenQuad()

	 			overrideAlphaWriteEnable(false, true)
	 			overrideColorWriteEnable(false, true)
	  		end2D()
		popRenderTarget()

		-- Even if this RT doesn't use alpha channel (IMAGE_FORMAT), it stil somehow uses alpha... BAD!
		-- At least no clearDepth

	end
end

do
	local clock = os.clock
	local generateBlur = blur.generateBlur

	---Tries to blur texture with specified id and parameters according to it's last time being blurred
	---@param id string Identifier of blur texture. If set to nil or 'default', then default blur texture will be asked to be blurred with legacy logic
	---If it is set, and not set to 'default', then it tries to blur texture if needs to and enables other arguments as well. Use with caution!
	---@param time number? How much time needs to be passed for next texture's bluring? You usually want it to set to ``1 / blurFPS``. Overrides BLUR_FPS. Affects performance a lot.
	---@param blurStrength number? How much blur strength the result texture will have. Overrides BLUR
	---@param passes number? How much bluring passes texture will have. More passes will result in better bluring quality, but worse performace. Affects performance a lot.
	---@param expensive boolean? If set to true, it will try to blur texture with defualt Source Engine shaders called BlurX, BlurY. They are expensive. If unset or false, it will try to blur stuff with gmodscreenspace shader.
	---@overload fun(id : 'default'?): IMaterial
	function blur.requestBlur(id, time, blurStrength, passes, expensive)
		id = id or 'default'
		time = time or BLUR_TIME

		if textureTimes[id] == nil then
			textureTimes[id] = clock() + time
			return
		end

		if id ~= 'default' and textureTimes[id] < clock() then
			generateBlur(id, blurStrength, passes, expensive)

			if time > 0 then
				textureTimes[id] = nil
			else
				textureTimes[id] = 0
			end
		end
	end

	hook.Add('RenderScreenspaceEffects', 'paint.blur', function()
		local time = textureTimes['default']
		if time == nil then return end

		if time < clock() then
			generateBlur()
			textureTimes['default'] = nil
		end
	end)
end

do
	local requestBlur = blur.requestBlur
	local getRenderTargetEx = GetRenderTargetEx

	local createMaterial = CreateMaterial

	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget
	local clear = render.Clear

	---Returns a Texture with the blurred image from the screen.
	---@param id string Identifier of blur texture. If set to nil or 'default', then default blur texture will be returned with legacy logic
	---If it is set, and not set to 'default', then it tries to blur texture if needs to and enables other arguments as well. Use with caution!
	---@param time number? How much time needs to be passed for next texture's bluring? You usually want it to set to ``1 / blurFPS``. Overrides BLUR_FPS. Affects performance a lot.
	---@param blurStrength number? How much blur strength the result texture will have. Overrides BLUR
	---@param passes number? How much bluring passes texture will have. More passes will result in better bluring quality, but worse performace. Affects performance a lot.
	---@param expensive boolean? If set to true, it will try to blur texture with defualt Source Engine shaders called BlurX, BlurY. They are expensive. If unset or false, it will try to blur stuff with gmodscreenspace shader.
	---@nodiscard
	---@overload fun(id : 'default'?): ITexture
	---@return ITexture
	function blur.getBlurTexture(id, time, blurStrength, passes, expensive)
		id = id or 'default'

		if textures[id] == nil then
			local tex = getRenderTargetEx(TEXTURE_PREFIX .. id, RT_SIZE, RT_SIZE, 1, 2, RT_FLAGS, 0, 2)
			textures[id] = tex
			textureTimes[id] = 0

			pushRenderTarget(tex)
				clear(0, 0, 0, 255)
			popRenderTarget()
		end

		requestBlur(id, time, blurStrength, passes, expensive)

		return textures[id]
	end

	local getBlurTexture = blur.getBlurTexture

	---Returns a Material with the blurred image from the screen.
	---@param id string Identifier of blur material. If set to nil or 'default', then default blur material will be returned with legacy logic
	---If it is set, and not set to 'default', then it tries to blur material if needs to and enables other arguments as well. Use with caution!
	---@param time number? How much time needs to be passed for next material's bluring? You usually want it to set to ``1 / blurFPS``. Overrides BLUR_FPS. Affects performance a lot.
	---@param blurStrength number? How much blur strength the result material will have. Overrides BLUR
	---@param passes number? How much bluring passes material will have. More passes will result in better bluring quality, but worse performace. Affects performance a lot.
	---@param expensive boolean? If set to true, it will try to blur material with defualt Source Engine shaders called BlurX, BlurY. They are expensive. If unset or false, it will try to blur stuff with gmodscreenspace shader.
	---@nodiscard
	---@overload fun(id : 'default'?): IMaterial
	---@return IMaterial # Blurred screen image
	function blur.getBlurMaterial(id, time, blurStrength, passes, expensive)
		id = id or 'default'
		local mat = textureMaterials[id]

		if mat == nil then
			mat = createMaterial(MATERIAL_PREFIX .. id, 'UnlitGeneric', {
				['$basetexture'] = getBlurTexture(id, time, blurStrength, passes, expensive):GetName(),
				['$vertexalpha'] = 1,
				['$vertexcolor'] = 1,
				['$model'] = 1,
				['$translucent'] = 1,
			})
			textureMaterials[id] = mat

			return mat-- requestBlur is arleady done.
		end

		requestBlur(id, time, blurStrength, passes, expensive)

		return mat
	end
end

paint.blur = blur