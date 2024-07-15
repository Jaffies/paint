-- Can't trust the client not to override the default colors
local COLOR_WHITE = Color( 255, 255, 255, 255 )

paint.examples.addHelpTab( "Blur", "icon16/user.png", function( panel )

	-- Intro
	paint.examples.title( panel, "Blur - paint.blur" )

	paint.examples.text( panel,
[[The paint library has a built-in blur effect!
This works by taking a copy of the screen, lowering its resolution, blurring it, then returning that as a material.
You can then use that material with any of the paint functions to draw a blurred shape.
It's a simple, cheap, and cool effect!

The blur effect is configurable clientside with the following ConVars:
paint_blur - integer - Controls blur strength
paint_blur_passes - integer - Controls blur passes
paint_blur_fps - integer - Controls how many fps will bloored image have]]
	)

	paint.examples.header( panel, "Functions" )

	paint.examples.boldText( panel, "paint.blur.getBlurMaterial()" )
	paint.examples.text( panel,
[[Returns a Material with the blurred image from the screen.]]
	)

	-- Example
	paint.examples.header( panel, "Example" )

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[<k>local <v>x<F>, <v>y <k>= <f>panel:LocalToScreen<e>(<n>0<F>, <n>0<e>) <c>-- getting absolute position
<k>local <v>scrW<F>, <v>scrH <k>= <f>ScrW<e>()<F>, <f>ScrH<e>() <c>-- it will be used to get UV coordinates
<k>local <v>mat <k>= <f>paint.blur.getBlurMaterial<e>()
<f>paint.rects.drawRect<e>(<n<0<F>, <n>0<F>, <n>100<F>, <n>64<F>, <v>color_white<F>, <v>mat<F>, <v>x <k>/ <v>scrW<F>, <v>y <k>/ <v>scrH<F>, <e>(<v>x <k>+ <n<100<e>) <k>/ <v>scrW<F>, <e>(<v>y <k>+ <n>64<e>) <k>/ <v>scrH<e>)

<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>120<F>, <n>0<F>, <n>120<F>, <n>64<F>, <v>color_white<F>, <v>mat<F>, <e>(<v>x <k>+ <n>120<e>) <k>/ <v>scrW<F>, <v>y <k>/ <v>scrH<F>, <e>(<v>x <k>+ <n>240<e>) <k>/ <v>scrW<F>, <e>(<v>y <k>+ <n>64<e>) <k>/ <v>scrH<e>) ]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )

		local panel = self
		paint.startPanel(self)
			local x, y = panel:LocalToScreen( 0, 0 ) -- getting absolute position
			local scrW, scrH = ScrW(), ScrH() -- it will be used to get UV coordinates
			local mat = paint.blur.getBlurMaterial()
			paint.rects.drawRect( 0, 0, 100, 64, COLOR_WHITE, mat, x / scrW, y / scrH, (x + 100) / scrW, (y + 64) / scrH )

			paint.roundedBoxes.roundedBox( 32, 120, 0, 120, 64, COLOR_WHITE, mat, (x + 120) / scrW, y / scrH, (x + 240) / scrW, (y + 64) / scrH )
		paint.endPanel()
	end)
end )