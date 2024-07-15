-- Can't trust the client not to override the default colors
local COLOR_WHITE = Color( 255, 255, 255, 255 )
local COLOR_BLACK = Color( 0, 0, 0, 255 )

paint.examples.addHelpTab( "Rects", "icon16/user.png", function( panel )

	-- Intro
	paint.examples.title( panel, "Rectangles - paint.rects" )
	paint.examples.text( panel,
		[[What makes paint rectangles different from surface and draw rectangles?
		1) Support for linear, per-corner gradients!
		2) Vastly improved performance when drawing multiple rectangles, thanks to batching!]]
	)

	paint.examples.header( panel, "Functions" )

	-- Start batching
	paint.examples.boldText( panel, "paint.rects.startBatching()" )
	paint.examples.text( panel,
		[[Begins batching rectangles together to draw them all at once with greatly improved performance.
		This is primarily useful when drawing a large number of rectangles.
		All rectangles drawn after this function is called will be batched until stopBatching() is called.
		Note: Batching is not shared between different types of shapes.]]
	)

	-- Draw rect
	paint.examples.boldText( panel, "paint.rects.drawRect( startX, startY, w, h, colors, material?, u1?, v1?, u2?, v2 )" )
	paint.examples.text( panel,
		[[Draws a rectangle with the specified parameters.

		Arguments:
		- startX, startY :  number - position of the rectangle
		- w, h :  number - width and height of the rectangle
		- material :  Material - Either a Material, or nil.  Default: vgui/white
		- colors :  Color[ ] or Color - Either a table of Colors, or a single Color.  
		-      If it is a table, it must have 4 elements, one for each corner.
		-      The order of the corners is:
		-            1. Top-Left 
		-            2. Top-Right
		-            3. Bottom-Right 
		-            4. Bottom-Left
		- u1, v1 :  number (0 to 1) - The texture U,V coordinates of the Top-Left corner of the rectangle.
		- u2, v2 :  number (0 to 1) - The texture U,V coordinates of the Bottom-Right corner of the rectangle.]]
	)

	-- Stop batching
	paint.examples.boldText( panel, "paint.rects.stopBatching()" )
	paint.examples.text( panel,
		[[Finishes batching rects and draws all rects created bny paint.rects.drawRect since startBatching() was called.]]
	)

	-- Simple Example
	paint.examples.header( panel, "Simple Example" )
	paint.examples.text( panel,
		[[Drawing an uncolored rectangle with a material, a rectangle with a material and per-corner colors, and a rectangle with just per-color corners.
		]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[
<k>local <v>mat <k>= <f>Material<e>(<s>'icon16/application_xp.png'<e>)
<c>--Draw a rectangle with a material and no colors
<f>paint.rects.drawRect<e>(<n>0<F>, <n>0<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <k>mat<F>, <n>0.5<F>, <n>0<F>, <n>1<F>, <n>0.75<e>)

<c>-- Draw a rectangle with a material and per-corner colors
<f>paint.rects.drawRect<e>(<n>64<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<F>, <v>mat<e>)

<c>-- Draw a rectangle with no material and per-corner colors
<f>paint.rects.drawRect<e>(<n>128<F>, <n>0<F>, <n>64<F>, <n>64<F>, <k>{<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<k>}<e>)
]])

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function(self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self )
			local mat = Material( "icon16/application_xp.png" )
			paint.rects.drawRect( 0, 0, 64, 64, COLOR_WHITE, mat, 0.5, 0, 1, 0.75 )
			paint.rects.drawRect( 64, 0, 64, 64, { Color(255, 0, 0 ), Color( 0, 255, 0 ), Color( 0, 0, 255 ), COLOR_WHITE }, mat )
			paint.rects.drawRect( 128, 0, 64, 64, { Color(255, 0, 0 ), Color( 0, 255, 0 ), Color( 0, 0, 255 ), COLOR_WHITE } )
		paint.endPanel()
	end )

	-- Batched Example
	paint.examples.header( panel, "Batched Example" )
	paint.examples.text( panel,
		[[Drawing 25 rectangles with improved performance by using batching.
		]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[
<c>-- Start batching rects together
<f>paint.rects.startBatching<e>()
<k>for <v>i <k>= <n>1<F>, <n>25 <k>do
   <c>-- This doesn't draw rects, it just adds them to the batch
   <f>paint.rects.drawRect<e>(<v>i <k>* <n>15<F>, <n>0<F>, <n>15<F>, <n>50<F>, <k>{<v>color_white<F>, <v>color_black<F>, <v>color_black<F>, <v>color_white<k>}<e>)
<k>end
<c>-- Now that all our rects are added to the batch, we can draw them all at once
<f>paint.rects.stopBatching<e>()]]
	)

	paint.examples.subheader(panel, "Result")
	paint.examples.result( panel, function( self, width, height  )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self, true, true )
			paint.rects.startBatching()
			for i = 1, 25 do
				paint.rects.drawRect( i * 15, 0, 15, 50, { COLOR_WHITE, COLOR_BLACK, COLOR_BLACK, COLOR_WHITE } )
			end
			paint.rects.stopBatching()
		paint.endPanel( true, true )
	end )
end )