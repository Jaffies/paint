paint.examples.addControl( 'Rects', function()
	local scroll = vgui.Create('DScrollPanel')
	scroll:Dock( FILL )

	scroll.Paint = function(self)
		paint.startPanel(self, false, true)
	end

	scroll.PaintOver = function(self)
		paint.endPanel(false, true)
	end

	-- Intro
	paint.examples.title( scroll, "Rectangles - paint.rects" )
	paint.examples.text( scroll,
		[[What makes paint rectangles different from surface and draw rectangles?
		1) Support for linear, per-corner gradients!
		2) Vastly improved performance when drawing multiple rectangles, thanks to batching!]]
	)

	paint.examples.header( scroll, "Functions" )

	-- Start batching
	paint.examples.boldText( scroll, "paint.rects.startBatching()" )
	paint.examples.text( scroll,
		[[Begins batching rectangles together to draw them all at once with greatly improved performance.
		This is primarily useful when drawing a large number of rectangles.
		Note: All rectangles drawn after this function is called will be batched until stopBatching() is called.]]
	)

	-- Draw rect
	paint.examples.boldText( scroll, "paint.rects.drawRect( startX, startY, w, h, colors, material?, u1?, v1?, u2?, v2 ) " )
	paint.examples.text( scroll,
		[[Draws a rectangle with the specified parameters.

		Arguments:
		- startX, startY :  number - position of the rectangle
		- w, h :  number - width and height of the rectangle
		- material :  Material - Either a Material, or nil.  Default: vgui/white
		- colors :  Color[ ] or Color - Either a table of Colors, or a single Color.  
		-      If it is a table, it must have 4 elements, one for each corner.
		-      The order of the corners is:
		-      1. Top-Left 
		-      2. Top-Right
		-      3. Bottom-Right 
		-      4. Bottom-Left
		- u1, v1 :  number (0 to 1) - The texture U,V coordinates of the Top-Left corner of the rectangle.
		- u2, v2 :  number (0 to 1) - The texture U,V coordinates of the Bottom-Right corner of the rectangle.]]
	)

	-- Stop batching
	paint.examples.boldText( scroll, "paint.rects.stopBatching()" )
	paint.examples.text( scroll,
		[[Finishes batching rects and draws all rects created bny paint.rects.drawRect since startBatching() was called.]]
	)

	-- Example 1
	paint.examples.header( scroll, "Example 1" )
	paint.examples.text( scroll,
		[[Drawing colored rectangles with a material.
		]]
	)

	paint.examples.subheader( scroll, "Code" )

	local example1Code = scroll:Add( "paint.markupRichText" )
	example1Code:SetMarkupText([[
<k>local <v>mat <k>= <f>Material<e>(<s>'icon16/application_xp.png'<e>)
<f>paint.rects.drawRect<e>(<n>0<F>, <n>0<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <k>mat<F>, <n>0.5<F>, <n>0<F>, <n>1<F>, <n>0.75<e>)
<f>paint.rects.drawRect<e>(<n>64<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<F>, <v>mat<e>)
<f>paint.rects.drawRect<e>(<n>128<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<e>)
<c>--if material is nil, then vgui/white will be used
]])
	example1Code:Dock( TOP )
	example1Code:DockMargin( 15, 0, 15, 15 )
	example1Code:SetTall( 80 )

	paint.examples.subheader( scroll, "Result" )

	local example1Result = scroll:Add('DPanel')
	example1Result:SetPaintBackground(true)
	example1Result:Dock(TOP)
	example1Result:SetTall(64)
	example1Result:DockMargin(15, 0, 15, 15)

	example1Result.Paint = function(self, w, h)
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, w, h)
		paint.startPanel(self)
			local mat = Material('icon16/application_xp.png')
			paint.rects.drawRect(0, 0, 64, 64, color_white, mat, 0.5, 0, 1, 0.75)
			paint.rects.drawRect(64, 0, 64, 64, {Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), color_white}, mat)
			paint.rects.drawRect(128, 0, 64, 64, {Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255), color_white})
		paint.endPanel()
	end

	-- Example 2
	paint.examples.header( scroll, "Example 2" )

	paint.examples.text( scroll,
		[[Drawing 25 rectangles with improved performance by using batching.
		]]
	)

	paint.examples.subheader( scroll, "Code" )

	local example2Code = scroll:Add('paint.markupRichText')
	example2Code:SetMarkupText([[
<f>paint.rects.startBatching<e>() <c>--start batching, next draws will be batched untill stopBatching() will be called
<k>for <v>i <k>= <n>1<F>, <n>25 <k>do
	<f>paint.rects.drawRect<e>(<v>i <k>* <n>15<F>, <n>0<F>, <n>15<F>, <n>50<F>, <k>{<v>color_white<F>, <v>color_black<F>, <v>color_black<F>, <v>color_white<k>}<e>) <c>--It doesn't actually draw anything, just stores it to the mesh
<k>end
<f>paint.rects.stopBatching<e>() <c>--it draws all rects as one whole mesh
]])
	example2Code:Dock(TOP)
	example2Code:DockMargin(15, 0, 15, 15)
	example2Code:SetTall(100)

	paint.examples.subheader(scroll, "Result")

	local example2Result = scroll:Add('DPanel')
	example2Result:SetPaintBackground(true)
	example2Result:Dock(TOP)
	example2Result:SetTall(64)
	example2Result:DockMargin(15, 0, 15, 15)

	example2Result.Paint = function(self, w, h)
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