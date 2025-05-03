---@diagnostic disable: deprecated
---Simple library that provides a way to downsample your shapes.
---In other words: It provides you a way to make SSAA (super sampling anti aliasing) with 2D/3D meshes.
---@class paint.downsampling
local downspampling = {}
local paint = paint

do
	local w, h = ScrW(), ScrH()

	local rt = GetRenderTargetEx('paint.downsampleRT', w * 2, h * 2, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SEPARATE, 2 + 256,
		0, IMAGE_FORMAT_BGRA8888)
	local material = CreateMaterial('paint.downsampleMat', 'UnlitGeneric', {
		['$basetexture'] = rt:GetName(),
		['$translucent'] = '1'
	})

	---@type IMesh?
	local rectMesh

	local function createRectMesh()
		if rectMesh then
			rectMesh:Destroy()
		end

		rectMesh = Mesh(material)

		local color = Color(255, 255, 255)
		---@diagnostic disable-next-line: invisible
		paint.rects.generateRectMesh(rectMesh, 0, 0, w, h, { color, color, color, color }, 0, 0, 1, 1)
	end

	createRectMesh()
	---@cast rectMesh -?

	hook.Add('OnScreenSizeChanged', 'paint.downsampling' .. SysTime(), function(_, _, newW, newH)
		w, h = newW, newH

		rt:Download() -- I vaguely remember it being used to reset rt params. Might not work btw..
		rt = GetRenderTargetEx('paint.downsampleRT', w * 2, h * 2, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SEPARATE, 2 + 256,
			0, IMAGE_FORMAT_BGRA8888)
		createRectMesh()
	end)

	local pushRenderTarget = render.PushRenderTarget
	local popRenderTarget = render.PopRenderTarget
	local setMaterial = render.SetMaterial
	local clear = render.Clear

	local drawMesh = rectMesh.Draw

	local pushModelMatrix = cam.PushModelMatrix
	local popModelMatrix = cam.PopModelMatrix

	local start2D = cam.Start2D
	local end2D = cam.End2D

	local pushFilterMin = render.PushFilterMin
	local popFilterMin = render.PopFilterMin
	local pushFilterMag = render.PushFilterMag
	local popFilterMag = render.PopFilterMag

	local matrix = Matrix()
	matrix:SetScale(Vector(2, 2))

	local nullMatrix = Matrix()

	function downspampling.start(stopMultiply)
		pushRenderTarget(rt)
		clear(0, 0, 0, 0, true, true)
		start2D()
		pushModelMatrix(stopMultiply and nullMatrix or matrix, true)
	end

	function downspampling.stop()
		end2D()
		popModelMatrix()
		popRenderTarget()

		pushFilterMin(2)
		pushFilterMag(2)
		setMaterial(material)
		drawMesh(rectMesh)
		popFilterMin()
		popFilterMag()
	end
end

paint.downsampling = downspampling
