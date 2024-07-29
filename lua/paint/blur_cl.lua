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

local RT_FLAGS = bit.band(2, 256, 32768)
local TEXTURE_PREFIX = 'paint_library_rt_'
local MATERIAL_PREFIX = 'paint_library_material_'

local textures = {
	default = GetRenderTargetEx(TEXTURE_PREFIX .. 'default', RT_SIZE, RT_SIZE, 1, 2, RT_FLAGS, 0, 2)
}

local textureTimes = {
	default = 0
}

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
	local function blurRTCheap(rt, blur, blur, passes)
		setMaterial(blurMaterial)

		setTexture(blurMaterial, '$basetexture', rt)

		for i = 1, passes do
 			setFloat(blurMaterial, '$blur', (i / passes) * blur)
 			recompute(blurMaterial)

			updateScreenEffectTexture()
			drawScreenQuad()
		end 

		setTexture(blurMaterial, 'basetexture', screenEffectTexture)
	end

	function blur.generateBlur(id, blur, passes, expensive) -- used right before drawing 2D shit
		local texToBlur = textures[id or 'default']

		blur = blur or BLUR
		passes = passes or BLUR_PASSES
		expensive = expensive or BLUR_EXPENSIVE

		copyRTToTex(texToBlur)

 		pushRenderTarget(texToBlur)
 			start2D()
 				local blurRT = expensive and blurRTExpensive or blurRTCheap
 				blurRT(texToBlur, blur, blur, passes)

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
	---@type number?
	local needsBlurWhen = 0

	local clock = os.clock
	local generateBlur = blur.generateBlur

	---utility function to request blur in next blur frame (or current)
	function blur.requestBlur(id, time, blur, passes, expensive)
		id = id or 'default'
		time = time or BLUR_TIME

		if textureTimes[id] == nil then
			textureTimes[id] = clock() + time
			return
		end

		if id ~= 'default' and textureTimes[id] < clock() then
			generateBlur(id, blur, passes, expensive)

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

	---Requests next blur update, as well as returns blurred texture
	---@return ITexture
	function blur.getBlurTexture(id, time, blur, passes, expensive)
		id = id or 'default'
		
		if textures[id] == nil then
			local tex = getRenderTargetEx(TEXTURE_PREFIX .. id, RT_SIZE, RT_SIZE, 1, 2, RT_FLAGS, 0, 2)
			textures[id] = tex
			textureTimes[id] = 0

			pushRenderTarget(tex)	
				clear(0, 0, 0, 255)
			popRenderTarget()
		end

		requestBlur(id, time, blur, passes, expensive)

		return textures[id]
	end

	local getBlurTexture = blur.getBlurTexture

	---Requests next blur update, as well as returns blur material.
	---@return IMaterial
	function blur.getBlurMaterial(id, time, blur, passes, expensive)
		id = id or 'default'
		local mat = textureMaterials[id]

		if mat == nil then
			mat = createMaterial(MATERIAL_PREFIX .. id, 'UnlitGeneric', {
				['$basetexture'] = getBlurTexture(id, time, blur, passes, expensive):GetName(),
				['$vertexalpha'] = 1,
				['$vertexcolor'] = 1,
				['$model'] = 1,
				['$translucent'] = 1,
			})
			textureMaterials[id] = mat

			return mat-- requestBlur is arleady done.
		end

		requestBlur(id, time, blur, passes, expensive)

		return mat
	end
end

paint.blur = blur