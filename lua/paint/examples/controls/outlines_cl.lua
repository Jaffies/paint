-- Can't trust the client not to override the default colors
local COLOR_WHITE = Color( 255, 255, 255, 255 )
local COLOR_BLACK = Color( 0, 0, 0, 255 )

paint.examples.addHelpTab( "Outlines", 'icon16/user.png', function( panel )

	--- Intro
	paint.examples.title( panel, "Outlines - paint.outlines" )
	paint.examples.text( panel,
		[[What makes paint outlines better than stencils?
		1) Support for materials!
		2) Support for gradients within the outline!]]
	)

	paint.examples.header( panel, "Functions" )

	--- Draw Outline
	paint.examples.boldText( panel, "paint.outlines.drawOutline( radius, x, y, w, h, colors, material?, left, top?, right?, bottom? )" )
	paint.examples.text( panel,
		[[Draws an outline with the specified parameters.

		Arguments:
		- radius :  number - radius of the outline
		- x, y :  number - position of the outline
		- w, h :  number - width and height of the outline
		- material :  Material - Either a Material, or nil.  Default: vgui/white
		- colors :  Color[ ] or Color - Either a table of Colors, or a single Color.  
		-      If it is a table, it must have 2 elements, one for the inner bound and one for the outer bound.
		-      If it is a single color, it will be used for both bounds.
		- left, top, right, bottom :  number - The thickness of the outline on each side.
		-      If only the left side is specified, it will be used as the tickness of all sides.
		-      If the left and top sides are specified, the left value will be used as the thickness of the x-axis and top value will be used as the thickness of the y-axis.
		-      If all sides are specified, the order is left, top, right, bottom.]]
	)

	--- Draw Outline Extended
	paint.examples.boldText( panel, "paint.outlines.outlines.drawOutlineEx( radius, x, y, w, h, leftTop, rightTop, rightBottom, leftBottom, colors, material, left, top?, right?, bottom? )" )
	paint.examples.text( panel,
		[[Identical to drawOutline other than that it allows you to specify specific corners to be rounded.
		For brevity, arguments duplicated from drawOutline are not repeated here.

		Arguments:
		- topLeft, topRight, bottomRight, bottomLeft :  boolean - Whether to round the specified corner.]]
	)

	--- Draw Outline Example
	paint.examples.header( panel, "Draw Outline Example" )
	paint.examples.text( panel,
		[[Drawing outlines with different thicknesses on each side.]]
	)

	paint.examples.subheader( panel, "Code" )

	paint.examples.code( panel,
[[<f>paint.outlines.drawOutline<e>(<n>16<F>, <n>10<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>4<e>) <c> -- 4 is for all sides
<f>paint.outlines.drawOutline<e>(<n>8<F>, <n>74<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>8<F>, <n>1<e>) <c>-- 8 is for Y (top, bottom), 1 is for X (left, right)
<f>paint.outlines.drawOutline<e>(<n>22<F>, <n>138<F>, <n>10<F>, <n>44<F>, <n>44<F>, <v>color_white<F>, <k>nil<F>, <n>1<F>, <n>2<F>, <n>4<F>, <n>8<e>) <c>-- 1, 2, 4, 8 - left, top, right, bottom sides]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel(self)
			paint.outlines.drawOutline( 16, 10, 10, 44, 44, COLOR_WHITE, nil, 4 ) -- for all sides
			paint.outlines.drawOutline( 8, 74, 10, 44, 44, COLOR_WHITE, nil, 8, 1 ) -- 8 is for Y (top, bottom), 1 is for X (left, right)
			paint.outlines.drawOutline( 22, 138, 10, 44, 44, COLOR_WHITE, nil, 1, 2, 4, 8 ) -- 1, 2, 4, 8 - left, top, right, bottom sides
		paint.endPanel()
	end )

	--- Draw Outline Extended Example
	paint.examples.header( panel, "Draw Outline Extended Example" )
	paint.examples.text( panel, [[Drawing outlines with a material and different corners rounded.]] )

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[<c>-- note that material musn't have either CLAMPS or CLAMPT (you can try 'noclamp' material parameter in Material function) textureflag set!
<f>paint.outlines.drawOutlineEx<e>(<n>16<F>, <n>10<F>, <n>10<F>, <n>44<F>, <n>44<F>, <k>true<F>, <k>false<F>, <k>true<F>, <k>false<F>, <v>color_white<F>, <f>Material<e>(<s>'gui/gradient'<e>)<F>, <n>16<e>)]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, width, height )
		paint.startPanel(self, true, true)
			paint.outlines.drawOutlineEx(17, 20, 20, 44, 44, true, false, true, false, COLOR_WHITE, Material('gui/gradient'), 16) -- note that material musn't have either CLAMPS or CLAMPT (you can try 'noclamp' material parameter in Material function) textureflag set!
		paint.endPanel(true, true)
	end )

	--- Draw Outline Gradient Example
	paint.examples.header( panel, "Draw Outline Gradient Example" )
	paint.examples.text( panel,
		[[Drawing outlines with a different inner and outer color.]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>16<F>, <n>10<F>, <n>64<F>, <n>64<F>, <k>{<v>color_white<F>, <v>color_black<k>}<F>, <k>nil<F>, <n>8<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>102<F>, <n>10<F>, <n>64<F>, <n>64<F>, <k>{<v>color_white<F>, <v>color_transparent<k>}<F>, <k>nil<F>, <n>8<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>192<F>, <n>10<e>, <n>64<F>, <n>64<F>, <k>{<v>color_black<F>, <f>ColorAlpha<e>(<v>color_black<F>, <n>0<e>)<k>}<F>, <k>nil<F>, <n>8<e>)]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self, true, true )
			paint.outlines.drawOutline( 32, 16, 10, 64, 64, { COLOR_WHITE, COLOR_BLACK }, nil, 8 )
			paint.outlines.drawOutline( 32, 102, 10, 64, 64, { COLOR_WHITE, color_transparent }, nil, 8 )
			paint.outlines.drawOutline( 32, 192, 10, 64, 64, { COLOR_BLACK, ColorAlpha( COLOR_BLACK, 0 ) }, nil, 8 )
		paint.endPanel(true, true)
	end )

	--- Draw Outline Fun Gradient Example

	paint.examples.header( panel, "Draw Outline Animated Gradient Example" )
	paint.examples.text( panel,
		[[Drawing an animated, colorful outline with a gradient.]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[<k>local <v>color1<F>, <v>color2 <k>= <f>HSVToColor<e>(<f>RealTime<e>() <k>* <n>120<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<f>RealTime<e>() <k>* <n>120 <k>+ <n>30<F>, <n>1<F>, <n>1<e>)
<f>paint.outlines.drawOutline<e>(<n>32<F>, <n>32<F>, <n>18<F>, <n>64<F>, <n64<F>, <k>{<v>color1<F>, <v>color2<k>}<F>, <k>nil<F>, <n>16<e>)]]
	)

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, 100, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self, true, true )
			local color1, color2 = HSVToColor( RealTime() * 120, 1, 1 ), HSVToColor( RealTime() * 120 + 30, 1, 1 )
			paint.outlines.drawOutline( 32, 32, 18, 64, 64, { color1, color2 }, nil, 16 )
		paint.endPanel(true, true)
	end )
end )