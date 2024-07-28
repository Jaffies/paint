---@class blur
local blur = {}
local paint = paint

--[[
	Library that gets blured frame texture.
	It doesn't ocupy smalltex1 now. Use it freely)
]]

local CONST_BLUR = 5
local CONST_BLUR_PASSES = 2
local CONST_BLUR_TIME = 1 / 30

local RT_FLAGS = bit.band(2, 256, 32768)
local TEXTURE_PREFIX = 'paint_library_rt_'
local MATERIAL_PREFIX = 'paint_library_material_'

local textures = {
	default = GetRenderTargetEx(TEXTURE_PREFIX .. 'default', 256, 256, 1, 2, RT_FLAGS, 0, IMAGE_FORMAT_RGBA8888)
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
	local blurRT = render.BlurRenderTarget

	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget

	local start2D = cam.Start2D
	local end2D = cam.End2D

	local overrideColorWriteEnable = render.OverrideColorWriteEnable
	local overrideAlphaWriteEnable = render.OverrideAlphaWriteEnable

	local setColorMaterial = render.SetColorMaterial
	local drawScreenQuad = render.DrawScreenQuad

	function blur.generateBlur(id) -- used right before drawing 2D shit
		local texToBlur = textures[id or 'default']

		copyRTToTex(texToBlur)

 		pushRenderTarget(texToBlur)
 			start2D()
	 			blurRT(texToBlur, CONST_BLUR, CONST_BLUR, CONST_BLUR_PASSES)
	 			overrideAlphaWriteEnable(true, true)
	 			overrideColorWriteEnable(true, false)

	 			setColorMaterial()
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
	function blur.requestBlur(id)
		id = id or 'default'
		if textureTimes[id] == nil then
			textureTimes[id] = clock() + CONST_BLUR_TIME
			return
		end


		if id ~= 'default' and textureTimes[id] < clock() then
			generateBlur(id)
			textureTimes[id] = nil
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
	function blur.getBlurTexture(id)
		id = id or 'default'
		
		if textures[id] == nil then
			local tex = getRenderTargetEx(TEXTURE_PREFIX .. id, 256, 256, 1, 2, RT_FLAGS, 0, IMAGE_FORMAT_RGBA8888)
			textures[id] = tex
			textureTimes[id] = 0

			pushRenderTarget(tex)	
				clear(0, 0, 0, 255)
			popRenderTarget()
		end

		requestBlur(id)

		return textures[id]
	end

	local getBlurTexture = blur.getBlurTexture

	---Requests next blur update, as well as returns blur material.
	---@return IMaterial
	function blur.getBlurMaterial(id)
		id = id or 'default'
		local mat = textureMaterials[id]

		if mat == nil then
			mat = createMaterial(MATERIAL_PREFIX .. id, 'UnlitGeneric', {
				['$basetexture'] = getBlurTexture(id):GetName(),
				['$vertexalpha'] = 1,
				['$vertexcolor'] = 1,
				['$model'] = 1,
				['$translucent'] = 1,
			})
			textureMaterials[id] = mat

			return mat-- requestBlur is arleady done.
		end

		requestBlur(id)

		return mat
	end
end

paint.blur = blur