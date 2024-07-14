paint.examples.addHelpTab('Rounded boxes', "icon16/user.png", function( panel )
	label:SetAutoStretchVertical(true)
	label:Dock(TOP)
	label:SetColor(color_black)
	label:SetText([[paint.roundedBoxes!
Rounded boxes. The top 2 of coolest things paint library has!
1) They support gradients per corner and center (like rects)
2) They support batching. (only universal)
3) They support stencils! (Check example #3)
4) They support materials (Check example #1)
5) They are faster than default ones!

Syntax:
1) paint.roundedBoxes.roundedBox(radius, x, y, w, h, colors, material?, u1?, v1?, u2?, v2?)
2) paint.roundedBoxes.roundedBoxEx(radius, x, y, w, h, colors, topLeft, topRight, bottomRight, bottomLeft, material? u1?, v1?, u2?, v2?)
-- colors is either a table of colors {topLeft, topRight, bottomRight, bottomLeft, centre?} (centre can be nil), or color
-- material can be nil, vgui/white will be used instead
-- u1, v1, u2, v2 - is UV coordinates. They can be nil, meaning that (0, 0, 1, 1) will be used instead
-- topLeft, topRight, bottomRight, bottomLeft - are a booleans, representing if you want to round that corner. false means don't round it, true - round it.
Example #1:
]])
	label:SetWrap(true)
	label:DockMargin(15, 15, 15, 0)

	local richText = scroll:Add('paint.markupRichText')
	richText:SetMarkupText([[
<f>paint.roundedBoxes.roundedBox<e>(<n>20<F>, <n>5<F>, <n>5<F>, <n>64<F>, <n>64<F>, <k>{
	<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<F>, <v>color_black<k>
}<e>)
<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>72<F>, <n>5<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <e>(<f>Material<e>(<s>'icon16/application_xp.png'<e>)))
]])
	richText:Dock(TOP)
	richText:DockMargin(15, 0, 15, 15)
	richText:SetTall(80)

	local panel = scroll:Add('DPanel')
	panel:SetPaintBackground(true)
	panel:Dock(TOP)
	panel:SetTall(80)
	panel:DockMargin(15, 0, 15, 15)

	panel.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self)
			paint.roundedBoxes.roundedBox(20, 5, 5, 64, 64, {Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), color_white, color_black})
			paint.roundedBoxes.roundedBox(32, 72, 5, 64, 64, color_white, (Material('icon16/application_xp.png')) )
		paint.endPanel()
	end

	local label2 = scroll:Add('DLabel')
	label2:SetAutoStretchVertical(true)
	label2:Dock(TOP)
	label2:SetColor(color_black)
	label2:SetText([[Now for complex results!
Let's try to make rounding only for 2 corners!
Example #2:
]])
	label2:SetWrap(true)
	label2:DockMargin(15, 15, 15, 0)

	local richText2 = scroll:Add('paint.markupRichText')
	richText2:SetMarkupText([[
<f>paint.roundedBoxes.roundedBoxEx<e>(<n>16<F>, <n>10<F>, <n>10<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <k>false<F>, <k>true<F>, <k>false<F>, <k>true<e>)
]])
	richText2:Dock(TOP)
	richText2:DockMargin(15, 0, 15, 15)
	richText2:SetTall(32)

	local panel2 = scroll:Add('DPanel')
	panel2:SetPaintBackground(true)
	panel2:Dock(TOP)
	panel2:SetTall(80)
	panel2:DockMargin(15, 0, 15, 15)

	panel2.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			paint.roundedBoxes.roundedBoxEx(16, 10, 10, 64, 64, color_white, false, true, false, true)
		paint.endPanel(true, true)
	end

	local label3 = scroll:Add('DLabel')
	label3:SetAutoStretchVertical(true)
	label3:Dock(TOP)
	label3:SetColor(color_black)
	label3:SetText([[Let's try using stencils!
In next example, we will try to make ripple effect from Google's Material Design.
Stencils will be used to make a mask
Example #3:
]])
	label3:SetWrap(true)
	label3:DockMargin(15, 15, 15, 0)

	local richText3 = scroll:Add('paint.markupRichText')
	richText3:SetTall(300)
	richText3:Dock(TOP)
	richText3:DockMargin(15, 0, 15, 15)
	richText3:SetMarkupText([[
<k>local function <f>mask<e>(<v>drawMask<F>, <v>draw<e>)
	<f>render.ClearStencil<e>()
	<f>render.SetStencilEnable<e>(<k>true<e>)

	<f>render.SetStencilWriteMask<e>(<n>1<e>)
	<f>render.SetStencilTestMask<e>(<n>1<e>)

	<f>render.SetStencilFailOperation<e>(<v>STENCIL_REPLACE<e>)
	<f>render.SetStencilPassOperation<e>(<v>STENCIL_REPLACE<e>)
	<f>render.SetStencilZFailOperation<e>(<v>STENCIL_KEEP<e>)
	<f>render.SetStencilCompareFunction<e>(<v>STENCIL_ALWAYS<e>)
	<f>render.SetStencilReferenceValue<e>(<v>1<e>)

	<f>drawMask<e>()

	<f>render.SetStencilFailOperation<e>(<v>STENCIL_KEEP<e>)
	<f>render.SetStencilPassOperation<e>(<v>STENCIL_REPLACE<e>)
	<f>render.SetStencilZFailOperation<e>(<v>STENCIL_KEEP<e>)
	<f>render.SetStencilCompareFunction<e>(<v>STENCIL_EQUAL<e>)
	<f>render.SetStencilReferenceValue<e>(<n>1<e>)

	<f>draw<e>()

	<f>render.SetStencilEnable<e>(<k>false<e>)
	<f>render.ClearStencil<e>()
<k>end

local <v>colorGreen <k>= <f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)

<k>local <v>RIPPLE_DIE_TIME <k>= <n>1
<k>local <v>RIPPLE_START_ALPHA <k>= <n>50

<k>function <f>button:Paint<e>(<v>w<F>, <v>h<e>)
	<f>paint.startPanel<e>(<v>self<e>)
		<f>mask<e>(<k>function<e>()
			<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>0<F>, <n>0<F>, <v>w<F>, <v>h<F>, <v>colorGreen<e>)
		<k>end<F>,
		<k>function<e>()
			<k>local <v>ripple <k>= <v>self.rippleEffect

			<k>if <v>ripple <k>== nil then return end

			<k>local <v>rippleX<F>, <v>rippleY<F>, <v>rippleStartTime <k>= <v>ripple<k>[<n>1<k>]<F>, <v>ripple<k>[<n>2<k>]<F>, <v>ripple<k>[<n>3<k>]

			local <v>percent <k>= <e>(<f>RealTime<e>() <k>- <v>rippleStartTime<e>) <k>/ <v>RIPPLE_DIE_TIME

			<k>if <v>percent <k>>= <n>1 <k>then
				<v>self.rippleEffect <k>= nil
			else
				local <v>alpha <k>= <v>RIPPLE_START_ALPHA <k>* <e>(<n>1 <k>- <v>percent<e>)
				<k>local <v>radius <k>= <f>math.max<e>(<v>w<F>, <v>h<e>) <k>* <v>percent <k>* <f>math.sqrt<e>(<n>2<e>)

				<f>paint.roundedBoxes.roundedBox<e>(<v>radius<F>, <v>rippleX <k>- <v>radius<F>, <v>rippleY <k>- <v>radius<F>, <v>radius <k>* <n>2<F>, <v>radius <k>* <n>2<F>, <f>ColorAlpha<e>(<v>color_white<F>, <v>alpha<e>))
			<k>end
		end<e>)
	<f>paint.endPanel<e>()
<k>end

function <f>button:DoClick<e>()
	<k>local <v>posX<F>, <v>posY <k>= <f>self:LocalCursorPos<e>()
	<v>self.rippleEffect <k>= {<v>posX<F>, <v>posY<F>, <f>RealTime<e>()<k>}
end
]])
	richText3:InvalidateLayout()

	do
		local button = scroll:Add('DButton')
		button:Dock(TOP)
		button:SetColor(color_white)
		button:SetText('Button ripple effect')
		button:SetTall(32)

		local function mask(drawMask, draw)
			render.ClearStencil()
			render.SetStencilEnable(true)

			render.SetStencilWriteMask(1)
			render.SetStencilTestMask(1)

			render.SetStencilFailOperation(STENCIL_REPLACE)
			render.SetStencilPassOperation( STENCIL_REPLACE)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			render.SetStencilCompareFunction(STENCIL_ALWAYS)
			render.SetStencilReferenceValue(1)

			drawMask()

			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilPassOperation(STENCIL_REPLACE)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			render.SetStencilCompareFunction(STENCIL_EQUAL)
			render.SetStencilReferenceValue(1)

			draw()

			render.SetStencilEnable(false)
			render.ClearStencil()
		end

		local colorGreen = Color(255, 0, 0)

		local RIPPLE_DIE_TIME = 1
		local RIPPLE_START_ALPHA = 50

		function button:Paint(w, h)
			paint.startPanel(self)
				mask(function()
					paint.roundedBoxes.roundedBox(32, 0, 0, w, h, colorGreen)
				end,
				function()
					local ripple = self.rippleEffect

					if ripple == nil then return end

					local rippleX, rippleY, rippleStartTime = ripple[1], ripple[2], ripple[3]

					local percent = (RealTime() - rippleStartTime)  / RIPPLE_DIE_TIME

					if percent >= 1 then
						self.rippleEffect = nil
					else
						local alpha = RIPPLE_START_ALPHA * (1 - percent)
						local radius = math.max(w, h) * percent * math.sqrt(2)

						paint.roundedBoxes.roundedBox(radius, rippleX - radius, rippleY - radius, radius * 2, radius * 2, ColorAlpha(color_white, alpha))
					end
				end)
			paint.endPanel()
		end

		function button:DoClick()
			local posX, posY = self:LocalCursorPos()
			self.rippleEffect = {posX, posY, RealTime()}
		end
	end

	local label4 = scroll:Add('DLabel')
	label4:SetAutoStretchVertical(true)
	label4:Dock(TOP)
	label4:SetColor(color_black)
	label4:SetText([[Looks nice!
Let's try making some gradient of it so it would look fantastic?
Example #4:
]])
	label4:SetWrap(true)
	label4:DockMargin(15, 15, 15, 0)

	local richText4 = scroll:Add('paint.markupRichText')
	richText4:SetMarkupText([[
<k>local <v>time1<F>, <v>time2 <k>= <f>RealTime<e>() <k>* <n>100<F>, <f>RealTime<e>() <k>* <n>100 <k>+ <n>30
<k>local <v>time3 <k>= <e>(<v>time1 <k>+ <v>time2<e>) <k>/ <n>2

<k>local <v>color1<F>, <v>color2<F>, <v>color3 <k>= <f>HSVToColor<e>(<v>time1<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<v>time2<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<v>time3<F>, <n>1<F>, <n>1<e>)

<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>10<F>, <n>10<F>, <n>300<F>, <n>128<F>, <k>{<v>color1<F>, <v>color3<F>, <v>color2<F>, <v>color3<k>}<e>)
<c>-- center is color3 not nil because interpolating between colors and between HSV is different
]])
	richText4:Dock(TOP)
	richText4:DockMargin(15, 0, 15, 15)
	richText4:SetTall(128)

	local panel4 = scroll:Add('DPanel')
	panel4:SetPaintBackground(true)
	panel4:Dock(TOP)
	panel4:SetTall(162)
	panel4:DockMargin(15, 0, 15, 15)

	panel4.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self, true, true)
			local time1, time2 = RealTime() * 100, RealTime() * 100 + 30
			local time3 = (time1 + time2) / 2

			local color1, color2, color3 = HSVToColor(time1, 1, 1), HSVToColor(time2, 1, 1), HSVToColor(time3, 1, 1)

			paint.roundedBoxes.roundedBox(32, 10, 10, 300, 128, {color1, color3, color2, color3})
			-- center is color3 not nil because interpolating between colors and between HSV is different
		paint.endPanel(true, true)
	end


	return scroll
end,
'icon16/user.png')