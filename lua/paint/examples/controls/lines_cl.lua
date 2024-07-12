paint.examples.addControl('Lines', function()
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
	label:SetText([[paint.lines!
Lines. Why they are better than default ones?
1) They support linear gradients!
2) They support batching.

Syntax:
1) paint.lines.drawLine(startX, startY, endX, endY, startColor, endColor?)
-if endColor == nil, then endColor = startColor
2) lines.lines.startBatching() - starts line specific batching
3) lines.lines.stopBatching() - ends batching and draws final result.

Example #1:
]])
	label:SetWrap(true)
	label:DockMargin(15, 15, 15, 0)

	local richText = scroll:Add('paint.markupRichText')
	richText:SetMarkupText([[
<f>paint.lines.drawLine<e>(<n>10<F>,<n> 20<F>,<n> 34<F>, <n>55<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>255<F>, <n>0<F>, <n>255<e>))
<f>paint.lines.drawLine<e>(<n>40<F>,<n> 10<F>,<n> 74<F>, <n>40<F>, <f>Color<e>(<n>255<F>, <n>255<F>, <n>0<e>)<e>) <c>--If endColor == nil, then endColor = startColor
]])
	richText:Dock(TOP)
	richText:DockMargin(15, 0, 15, 15)
	richText:SetTall(40)

	local panel = scroll:Add('DPanel')
	panel:SetPaintBackground(true)
	panel:Dock(TOP)
	panel:SetTall(64)
	panel:DockMargin(15, 0, 15, 15)

	panel.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self)
			paint.lines.drawLine(10, 20, 34, 55, Color(0, 255, 0), Color(255, 0, 255))
			paint.lines.drawLine(40, 10, 70, 40, Color(255, 255, 0))
		paint.endPanel()
	end

	local label2 = scroll:Add('DLabel')
	label2:SetAutoStretchVertical(true)
	label2:Dock(TOP)
	label2:SetColor(color_black)
	label2:SetMouseInputEnabled(false)
	label2:SetText([[It was the simpliest example! Let's dive into line batching!
When you should use it? You should use it when you draw a lot of lines, and therefore you need
to save draw calls to make it faster

Example #2:
]])
	label2:SetWrap(true)
	label2:DockMargin(15, 15, 15, 0)

	local richText2 = scroll:Add('paint.markupRichText')
	richText2:SetMarkupText([[
<f>paint.lines.startBatching<e>() <c>--start batching, next draws will be batched untill stopBatching() will be called
<k>for <v>i <k>= <n>1<F>, <n>50 <k>do
	<f>paint.lines.drawLine<e>(<v>i <k>* <n>10<F>, <n>10<F>, <v>i <k>* <n>10 <k>+ <n>5<F>, <n>55<F>, <f>Color<e>(<n>0<F>, <v>i <k>* <n>255 <k>/ <n>50<F>, <n>0<e>)<F>, <f>Color<e>(<n>255<F>, <n>0<F>, <n>255<e>)) <c>--It doesn't actually draw anything, just stores it to the mesh
<k>end
<f>paint.lines.stopBatching<e>() <c>--it draws all rects as one whole mesh
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
			paint.lines.startBatching()
			for i = 1, 50 do
				paint.lines.drawLine(i * 10, 10, i * 10 + 5, 55, Color(0, i * 255 / 50, 0), Color(255, 0, 255))
			end
			paint.lines.stopBatching()
		paint.endPanel(true, true)
	end

	return scroll
end,
'icon16/user.png')