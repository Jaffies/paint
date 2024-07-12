local blur = {}
local paint = paint

--[[
	Library that gets blured frame texture.
	It occupies SmallTex1 by default, keep it in mind when you use it
]]

local convarBlur = CreateConVar('paint_blur', 5, FCVAR_ARCHIVE, 'Amount of blur that needs to apply', 0, 100)
local convarBlurPasses = CreateConVar('paint_blur_passes', 3, FCVAR_ARCHIVE, 'Amount of blur passes that needs to apply', 0, 30)
local convarBlurFPS = CreateConVar('paint_blur_fps', 15, FCVAR_ARCHIVE, 'How many FPS needed for blur?')

do
	local texture = render.GetSmallTex1() -- main texture
	local getInt = FindMetaTable('ConVar').GetInt

	local copyRTToTex = render.CopyRenderTargetToTexture
	local blurRT = render.BlurRenderTarget
	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget
	local overrideColorWriteEnable = render.OverrideColorWriteEnable
	local overrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
	local setColorMaterial = render.SetColorMaterial
	local drawScreenQuad = render.DrawScreenQuad
	local clearDepth = render.ClearDepth

	function blur.generateBlur() -- used right before drawing 2D shit
		local passes = getInt(convarBlurPasses)
		local blur = getInt(convarBlur)
		copyRTToTex(texture)

		pushRenderTarget(texture)
			clearDepth()
			overrideColorWriteEnable(true, false)
			overrideAlphaWriteEnable(true, true)

			setColorMaterial()
			drawScreenQuad()

			overrideAlphaWriteEnable(false, false)
			overrideColorWriteEnable(false)
		popRenderTarget()

		blurRT(texture, blur, blur, passes)
	end
end

do
	---@type number?
	local needsBlurWhen = 0

	local clock = RealTime
	local getInt = FindMetaTable('ConVar').GetInt

	---utility function to request blur in next blur frame
	function blur.requestBlur()
		if needsBlurWhen == nil then
			needsBlurWhen = clock() + 1 / getInt(convarBlurFPS)
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
	local texture = render.GetSmallTex1()

	function blur.getBlurTexture()
		requestBlur()
		return texture
	end

	local mat = CreateMaterial('paintblurmaterial', 'UnlitGeneric', {
		['$basetexture'] = texture:GetName(),
		['$model'] = 1,
		['$vertexalpha'] = 1,
		['$vertexcolor'] = 1,
		['$translucent'] = false,
	})

	function blur.getBlurMaterial()
		requestBlur()
		return mat
	end
end

paint.blur = blur