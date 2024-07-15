-- Can't trust the client not to override the default colors
local COLOR_WHITE = Color( 255, 255, 255, 255 )
local COLOR_BLACK = Color( 0, 0, 0, 255 )

paint.examples.addHelpTab( "Lines", "icon16/user.png", function( panel )

	-- Intro
	paint.examples.title( panel, "Lines - paint.lines" )
	paint.examples.text( panel,
[[What makes paint lines better than surface lines?
1) They support linear gradients!
2) They support batching.]]
	)

	paint.examples.header( panel, "Functions" )

	paint.examples.boldText( panel, "paint.lines.startBatching()" )
	paint.examples.text( panel, 
[[Starts line batching. All lines drawn after this function is called will be batched until stopBatching() is called.
Note: Batching is not shared between different types of shapes.]]
	)

	paint.examples.boldText( panel, "paint.lines.drawLine( startX, startY, endX, endY, startColor, endColor? )" )
	paint.examples.text( panel,
[[Draws a line with the specified parameters.

Arguments:
- startX, startY :  number - The position of the start of the line
- endX, endY :  number - The position of the end of the line
- startColor :  Color - The color of the start of the line
- endColor :  Color - The color of the end of the line.  Default: startColor]]
	)

	paint.examples.boldText( panel, "paint.lines.stopBatching()" )
	paint.examples.text( panel, [[Stops batching and draws final result.]] )

	--- Simple Line Example
	paint.examples.header( panel, "Simple Line Example" )
	paint.examples.text( panel,
[[Drawing lines with a gradient of different colors.
]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[
<c>-- Providing two colors to get a gradient line
<f>paint.lines.drawLine<e>(<n>10<F>,<n> 20<F>,<n> 34<F>, <n>55<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>255<F>, <n>0<F>, <n>255<e>))

<c>-- Only providing a single color to get a monochromatic line
<f>paint.lines.drawLine<e>(<n>40<F>,<n> 10<F>,<n> 74<F>, <n>40<F>, <f>Color<e>(<n>255<F>, <n>255<F>, <n>0<e>)<e>)]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect(0, 0, width, height )
		paint.startPanel( self )
			paint.lines.drawLine( 10, 20, 34, 55, Color( 0, 255, 0 ), Color( 255, 0, 255 ) )
			paint.lines.drawLine( 40, 10, 70, 40, Color( 255, 255, 0 ) )
		paint.endPanel()
	end )

	--- Batched Lines Example
	paint.examples.header( panel, "Batched Lines Example" )
	paint.examples.text( panel,
[[Drawing 50 lines with improved performance by using batching.
]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[
<c>-- Start batching lines together
<f>paint.lines.startBatching<e>()
<k>for <v>i <k>= <n>1<F>, <n>50 <k>do
   <c>-- This doesn't draw lines, it just adds them to the batch
   <f>paint.lines.drawLine<e>(<v>i <k>* <n>10<F>, <n>10<F>, <v>i <k>* <n>10 <k>+ <n>5<F>, <n>55<F>, <f>Color<e>(<n>0<F>, <v>i <k>* <n>255 <k>/ <n>50<F>, <n>0<e>)<F>, <f>Color<e>(<n>255<F>, <n>0<F>, <n>255<e>))
<k>end
<c>-- Now that all our lines are added to the batch, we can draw them all at once
<f>paint.lines.stopBatching<e>()
]] )

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor(50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self, true, true )
			paint.lines.startBatching()
			for i = 1, 50 do
				paint.lines.drawLine( i * 10, 10, i * 10 + 5, 55, Color( 0, i * 255 / 50, 0 ), Color( 255, 0, 255 ) )
			end
			paint.lines.stopBatching()
		paint.endPanel( true, true )
	end )
end )