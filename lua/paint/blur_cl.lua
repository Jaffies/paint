---@class blur
local blur = {}
local paint = paint

--[[
	Library that gets blured frame texture.
	It doesn't ocupy smalltex1 now. Use it freely)
]]

local convarBlur = CreateConVar('paint_blur', 10, FCVAR_ARCHIVE, 'Amount of blur that needs to apply', 0, 100)
local convarBlurPasses = CreateConVar('paint_blur_passes', 2, FCVAR_ARCHIVE, 'Amount of blur passes that needs to apply', 0, 30)
local convarBlurFPS = CreateConVar('paint_blur_fps', 20, FCVAR_ARCHIVE, 'How many FPS needed for blur?')

local texture = GetRenderTargetEx('paint_blur_rt', 256, 256, RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_NONE, bit.band(2, 256, 32768), 0, IMAGE_FORMAT_RGB888)

do
	local getInt = FindMetaTable('ConVar').GetInt

	local copyRTToTex = render.CopyRenderTargetToTexture
	local blurRT = render.BlurRenderTarget

	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget
	local overrideColorWriteEnable = render.OverrideColorWriteEnable
	local overrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
	local setColorMaterial = render.SetColorMaterial
	local drawScreenQuad = render.DrawScreenQuad

	function blur.generateBlur() -- used right before drawing 2D shit
		local passes = getInt(convarBlurPasses)
		local blurStrength = getInt(convarBlur)
		copyRTToTex(texture)

		pushRenderTarget(texture)
  			overrideColorWriteEnable(true, false)
			overrideAlphaWriteEnable(true, true)

			setColorMaterial()
			drawScreenQuad()

			overrideAlphaWriteEnable(false)
			overrideColorWriteEnable(false)
		popRenderTarget()
		-- Even if this RT doesn't use alpha channel (IMAGE_FORMAT), it stil somehow uses alpha... BAD!
		-- At least no clearDepth

		blurRT(texture, blurStrength, blurStrength, passes)
	end
end

do
	---@type number?
	local needsBlurWhen = 0

	local clock = os.clock
	local frameTime = 1 / convarBlurFPS:GetInt()

	cvars.AddChangeCallback('paint_blur_fps', function(_, _, new)
		frameTime = 1 / tonumber(new)
	end)

	---utility function to request blur in next blur frame
	function blur.requestBlur()
		if needsBlurWhen == nil then
			needsBlurWhen = clock() + frameTime
		end
	end

	local generateBlur = blur.generateBlur

	hook.Add('RenderScreenspaceEffects', 'paint.blur', function()
		if needsBlurWhen == nil then return end

		if needsBlurWhen < clock() then
			generateBlur()
			needsBlurWhen = nil
		end
	end)
end

do
	local requestBlur = blur.requestBlur

	---Requests next blur update, as well as returns blurred texture
	---@return ITexture
	function blur.getBlurTexture()
		requestBlur()
		return texture
	end

	local mat = CreateMaterial('paint_blur_material', 'UnlitGeneric', {
		['$basetexture'] = texture:GetName(),
		['$model'] = 1,
		['$vertexalpha'] = 1,
		['$vertexcolor'] = 1,
		['$translucent'] = false,
	})

	---Requests next blur update, as well as returns blur material.
	---@return IMaterial
	function blur.getBlurMaterial()
		requestBlur()
		return mat
	end
end

---@class paint
---@field blur blur

paint.blur = blur