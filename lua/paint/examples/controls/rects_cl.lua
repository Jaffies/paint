paint.examples.addControl('Rects', function()
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
	label:SetText([[paint.rects!
Rects. Why they are better than default ones?
1) They support linear gradients per corner!
2) They support batching. (same as lines!)

Syntax:
1) paint.lines.drawRect(startX, startY, w, h, colors, material?, u1?, v1?, u2?, v2)
-material can be nil. vgui/white will be used instead
-colors is either the table of colors (i.e {color_white, color_white, color_black, color_black}) or color (i.e. color_white)
-[1] - leftTop, [2] - rightTop, [3] - rightBottom, [4] - leftBottom
u1, v1 - start U, V coordinates (from 0 to 1)
u2, v2 - end U, V coordinates (from 0 to 1)
2) paint.rects.startBatching() - starts rects specific batching
3) lines.rects.stopBatching() - ends rects specific batching and draws final result.
Example #1:
]])
	label:SetWrap(true)
	label:DockMargin(15, 15, 15, 0)

	local richText = scroll:Add('paint.markupRichText')
	richText:SetMarkupText([[
<k>local <v>mat <k>= <f>Material<e>(<s>'icon16/application_xp.png'<e>)
<f>paint.rects.drawRect<e>(<n>0<F>, <n>0<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <k>mat<F>, <n>0.5<F>, <n>0<F>, <n>1<F>, <n>0.75<e>)
<f>paint.rects.drawRect<e>(<n>64<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<F>, <v>mat<e>)
<f>paint.rects.drawRect<e>(<n>128<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<e>)
<c>--if material is nil, then vgui/white will be used
]])
	richText:Dock(TOP)
	richText:DockMargin(15, 0, 15, 15)
	richText:SetTall(80)

	local panel = scroll:Add('DPanel')
	panel:SetPaintBackground(true)
	panel:Dock(TOP)
	panel:SetTall(64)
	panel:DockMargin(15, 0, 15, 15)

	panel.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self)
			local mat = Material('icon16/application_xp.png')
			paint.rects.drawRect(0, 0, 64, 64, color_white, mat, 0.5, 0, 1, 0.75)
			paint.rects.drawRect(64, 0, 64, 64, {Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), color_white}, mat)
			paint.rects.drawRect(128, 0, 64, 64, {Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), color_white})
		paint.endPanel()
	end

	local label2 = scroll:Add('DLabel')
	label2:SetAutoStretchVertical(true)
	label2:Dock(TOP)
	label2:SetColor(color_black)
	label2:SetText([[It was the simpliest example! Let's dive into rect batching!
When you should use it? You should use it when you draw a lot of rects, and therefore you need
to save draw calls to make it faster

Example #2:
]])
	label2:SetWrap(true)
	label2:DockMargin(15, 15, 15, 0)

	local richText2 = scroll:Add('paint.markupRichText')
	richText2:SetMarkupText([[
<f>paint.rects.startBatching<e>() <c>--start batching, next draws will be batched untill stopBatching() will be called
<k>for <v>i <k>= <n>1<F>, <n>25 <k>do
	<f>paint.rects.drawRect<e>(<v>i <k>* <n>15<F>, <n>0<F>, <n>15<F>, <n>50<F>, <k>{<v>color_white<F>, <v>color_black<F>, <v>color_black<F>, <v>color_white<k>}<e>) <c>--It doesn't actually draw anything, just stores it to the mesh
<k>end
<f>paint.rects.stopBatching<e>() <c>--it draws all rects as one whole mesh
]])
	richText2:Dock(TOP)
	richText2:DockMargin(15, 0, 15, 15)
	richText2:SetTall(100)

	local panel2 = scroll:Add('DPanel')
	panel2:SetPaintBackground(true)
	panel2:Dock(TOP)
	panel2:SetTall(64)
	panel2:DockMargin(15, 0, 15, 15)

	panel2.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			paint.rects.startBatching()
			for i = 1, 25 do
				paint.rects.drawRect(i * 15, 0, 15, 50, {color_white, color_black, color_black, color_white})
			end
			paint.rects.stopBatching()
		paint.endPanel(true, true)
	end

	return scroll
end,
'icon16/user.png')