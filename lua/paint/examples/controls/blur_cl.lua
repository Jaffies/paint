paint.examples.addControl('Blur', function()
	local scroll = vgui.Create('DScrollPanel')
	scroll:Dock(FILL)

	scroll.Paint = function(self)
		paint.startPanel(self, false, true)
	end

	scroll.PaintOver = function(self)
		paint.endPanel(false, true)
	end

	local label = scroll:Add('DLabel')
	label:SetAutoStretchVertical(true)
	label:Dock(TOP)
	label:SetColor(color_black)
	label:SetMouseInputEnabled(false)
	label:SetText([[paint.blur!
Paint library also adds some additional functional, for an example - paint's blur.
paint.blur gets image from RenderScreenEffects hook, blurs it and then throws you with a material which has that blur.
Simple and cool.

It has 3 convars!
paint_blur<int> - controls blur strength
paint_blur_passes<int> - controls blur passes
paint_blur_fps<int> - controls how many fps will bloored image have
Syntax:
paint.blur.getBlurMaterial() : material
-- returns material with blured screen

Let's try to use it!
Example #1:
]])
	label:SetWrap(true)
	label:DockMargin(15, 15, 15, 0)

	local richText = scroll:Add('paint.markupRichText')
	richText:SetMarkupText([[
<k>local <v>x<F>, <v>y <k>= <f>panel:LocalToScreen<e>(<n>0<F>, <n>0<e>) <c>-- getting absolute position
<k>local <v>scrW<F>, <v>scrH <k>= <f>ScrW<e>()<F>, <f>ScrH<e>() <c>-- it will be used to get UV coordinates
<k>local <v>mat <k>= <f>paint.blur.getBlurMaterial<e>()
<f>paint.rects.drawRect<e>(<n<0<F>, <n>0<F>, <n>100<F>, <n>64<F>, <v>color_white<F>, <v>mat<F>, <v>x <k>/ <v>scrW<F>, <v>y <k>/ <v>scrH<F>, <e>(<v>x <k>+ <n<100<e>) <k>/ <v>scrW<F>, <e>(<v>y <k>+ <n>64<e>) <k>/ <v>scrH<e>)

<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>120<F>, <n>0<F>, <n>120<F>, <n>64<F>, <v>color_white<F>, <v>mat<F>, <e>(<v>x <k>+ <n>120<e>) <k>/ <v>scrW<F>, <v>y <k>/ <v>scrH<F>, <e>(<v>x <k>+ <n>240<e>) <k>/ <v>scrW<F>, <e>(<v>y <k>+ <n>64<e>) <k>/ <v>scrH<e>)
]])
	richText:Dock(TOP)
	richText:DockMargin(15, 0, 15, 15)
	richText:SetTall(128)

	local panel = scroll:Add('DPanel')
	panel:SetPaintBackground(true)
	panel:Dock(TOP)
	panel:SetTall(64)
	panel:DockMargin(15, 0, 15, 15)

	panel.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)

		local panel = self
		paint.startPanel(self)
			local x, y = panel:LocalToScreen(0, 0) -- getting absolute position
			local scrW, scrH = ScrW(), ScrH() -- it will be used to get UV coordinates
			local mat = paint.blur.getBlurMaterial()
			paint.rects.drawRect(0, 0, 100, 64, color_white, mat, x / scrW, y / scrH, (x + 100) / scrW, (y + 64) / scrH)

			paint.roundedBoxes.roundedBox(32, 120, 0, 120, 64, color_white, mat, (x + 120) / scrW, y / scrH, (x + 240) / scrW, (y + 64) / scrH)
		paint.endPanel()
	end

	return scroll
end,
'icon16/user.png')