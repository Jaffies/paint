paint.examples.addHelpTab( "Outlines", 'icon16/user.png', function( panel )

	local richText = scroll:Add('paint.markupRichText')
	richText:SetMarkupText([[
<f>paint.outlines.drawOutline<e>(<n>16<F>, <n>10<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>4<e>) <c> -- 4 is for all sides
<f>paint.outlines.drawOutline<e>(<n>8<F>, <n>74<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>8<F>, <n>1<e>) <c>-- 8 is for Y (top, bottom), 1 is for X (left, right)
<f>paint.outlines.drawOutline<e>(<n>22<F>, <n>138<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>1<F>, <n>2<F>, <n>4<F>, <n>8<e>) <c>-- 1, 2, 4, 8 - left, top, right, bottom sides
]])
	richText:Dock(TOP)
	richText:DockMargin(15, 0, 15, 15)
	richText:SetTall(48)

	local panel = scroll:Add('DPanel')
	panel:SetPaintBackground(true)
	panel:Dock(TOP)
	panel:SetTall(64)
	panel:DockMargin(15, 0, 15, 15)

	panel.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self)
			paint.outlines.drawOutline(16, 10, 10, 44, 44, color_white, nil, 4) -- for all sides
			paint.outlines.drawOutline(8, 74, 10, 44, 44, color_white, nil, 8, 1) -- 8 is for Y (top, bottom), 1 is for X (left, right)
			paint.outlines.drawOutline(22, 138, 10, 44, 44, color_white, nil, 1, 2, 4, 8) -- 1, 2, 4, 8 - left, top, right, bottom sides
		paint.endPanel()
	end

	local label2 = scroll:Add('DLabel')
	label2:SetAutoStretchVertical(true)
	label2:Dock(TOP)
	label2:SetColor(color_black)
	label2:SetMouseInputEnabled(false)
	label2:SetText([[Now there is an example on how to use materials and drawOutlineEx function!
Example #2:
]])
	label2:SetWrap(true)
	label2:DockMargin(15, 15, 15, 0)

	local richText2 = scroll:Add('paint.markupRichText')
	richText2:SetMarkupText([[
<f>paint.outlines.drawOutlineEx<e>(<n>17<F>, <n>20<F>, <n>20<F>, <n>44<F>, <n>44<F>, <k>true<F>, <k>false<F>, <k>true<F>, <k>false<F>, <v>color_white<F>, <f>Material<e>(<s>'gui/gradient'<e>)<F>, <n>16<e>) <c>-- note that material musn't have either CLAMPS or CLAMPT (you can try 'noclamp' material parameter in Material function) textureflag set!
]])
	richText2:Dock(TOP)
	richText2:DockMargin(15, 0, 15, 15)
	richText2:SetTall(100)

	local panel2 = scroll:Add('DPanel')
	panel2:SetPaintBackground(true)
	panel2:Dock(TOP)
	panel2:SetTall(96)
	panel2:DockMargin(15, 0, 15, 15)

	panel2.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			paint.outlines.drawOutlineEx(17, 20, 20, 44, 44, true, false, true, false, color_white, Material('gui/gradient'), 16) -- note that material musn't have either CLAMPS or CLAMPT (you can try 'noclamp' material parameter in Material function) textureflag set!
		paint.endPanel(true, true)
	end

	local label3 = scroll:Add('DLabel')
	label3:SetAutoStretchVertical(true)
	label3:Dock(TOP)
	label3:SetColor(color_black)
	label3:SetMouseInputEnabled(false)
	label3:SetText([[I guess it's time to test colors!
Let's try assigning inner and outer bounds to different colors!
Example #3:
]])
	label3:SetWrap(true)
	label3:DockMargin(15, 15, 15, 0)

	local richText3 = scroll:Add('paint.markupRichText')
	richText3:SetMarkupText([[
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>16<F>, <n>10<F>, <n>64<F>, <n>64<F>, <k>{<v>color_white<F>, <v>color_black<k>}<F>, <k>nil<F>, <n>8<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>102<F>, <n>10<F>, <n>64<F>, <n>64<F>, <k>{<v>color_white<F>, <v>color_transparent<k>}<F>, <k>nil<F>, <n>8<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>192<F>, <n>10<e>, <n>64<F>, <n>64<F>, <k>{<v>color_black<F>, <f>ColorAlpha<e>(<v>color_black<F>, <n>0<e>)<k>}<F>, <k>nil<F>, <n>8<e>)
]])
	richText3:Dock(TOP)
	richText3:DockMargin(15, 0, 15, 15)
	richText3:SetTall(72)

	local panel3 = scroll:Add('DPanel')
	panel3:SetPaintBackground(true)
	panel3:Dock(TOP)
	panel3:SetTall(96)
	panel3:DockMargin(15, 0, 15, 15)

	panel3.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			paint.outlines.drawOutline(32, 16, 10, 64, 64, {color_white, color_black}, nil, 8)
			paint.outlines.drawOutline(32, 102, 10, 64, 64, {color_white, color_transparent}, nil, 8)
			paint.outlines.drawOutline(32, 192, 10, 64, 64, {color_black, ColorAlpha(color_black, 0)}, nil, 8)
		paint.endPanel(true, true)
	end

	local label4 = scroll:Add('DLabel')
	label4:SetAutoStretchVertical(true)
	label4:Dock(TOP)
	label4:SetColor(color_black)
	label4:SetMouseInputEnabled(false)
	label4:SetText([[Now let's try making gradients out of it!
Example #4:
]])
	label4:SetWrap(true)
	label4:DockMargin(15, 15, 15, 0)

	local richText4 = scroll:Add('paint.markupRichText')
	richText4:SetMarkupText([[
<k>local <v>color1<F>, <v>color2 <k>= <f>HSVToColor<e>(<f>RealTime<e>() <k>* <n>120<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<f>RealTime<e>() <k>* <n>120 <k>+ <n>30<F>, <n>1<F>, <n>1<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>32<F>, <n>18<F>, <n>64<F>, <n64<F>, <k>{<v>color1<F>, <v>color2<k>}<F>, <k>nil<F>, <n>16<e>)
]])
	richText4:Dock(TOP)
	richText4:DockMargin(15, 0, 15, 15)
	richText4:SetTall(72)

	local panel4 = scroll:Add('DPanel')
	panel4:SetPaintBackground(true)
	panel4:Dock(TOP)
	panel4:SetTall(100)
	panel4:DockMargin(15, 0, 15, 15)

	panel4.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			local color1, color2 = HSVToColor(RealTime() * 120, 1, 1), HSVToColor(RealTime() * 120 + 30, 1, 1)
			paint.outlines.drawOutline(32, 32, 18, 64, 64, {color1, color2}, nil, 16)
		paint.endPanel(true, true)
	end

	return scroll
end,
'icon16/user.png')