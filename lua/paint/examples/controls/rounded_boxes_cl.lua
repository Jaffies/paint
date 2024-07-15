-- Can't trust the client not to override the default colors
local COLOR_WHITE = Color( 255, 255, 255, 255 )
local COLOR_BLACK = Color( 0, 0, 0, 255 )
local COLOR_RED = Color( 255, 0, 0, 255 )

paint.examples.addHelpTab('Rounded boxes', "icon16/user.png", function( panel )

	paint.examples.title( panel, "Rounded boxes - paint.roundedBoxes" )
	paint.examples.text( panel,
[[What makes paint rounded boxes better than the draw library's rounded boxes?
1) Support for per-corner gradients!
2) Improved performance when drawing multiple rounded boxes, thanks to batching!
3) Stencil support!
4) Material support!]]
	)

	paint.examples.header( panel, "Functions" )

	paint.examples.boldText( panel, "paint.roundedBoxes.roundedBox( radius, x, y, w, h, colors, material?, u1?, v1?, u2?, v2? )" )
	paint.examples.text( panel,
[[Draws a rounded box with the specified parameters.

Arguments:
- radius :  number - radius of the rounded corners
- x, y :  number - position of the rounded box
- w, h :  number - width and height of the rounded box
- colors :  Color[ ] or Color - Either a table of Colors, or a single Color.
- material :  Material - Either a Material, or nil.  Default: vgui/white
- u1, v1 :  number (0 to 1) - The texture U,V coordinates of the Top-Left corner of the rounded box.
- u2, v2 :  number (0 to 1) - The texture U,V coordinates of the Bottom-Right corner of the rounded box.]]
	)

	paint.examples.boldText( panel, "paint.roundedBoxes.roundedBoxEx( radius, x, y, w, h, colors, topLeft, topRight, bottomRight, bottomLeft, material?, u1?, v1?, u2?, v2? )" )
	paint.examples.text( panel,
[[Identical to roundedBox other than that it allows you to specify specific corners to be rounded.
For brevity, arguments duplicated from roundedBox are not repeated here.

Arguments:
- topLeft, topRight, bottomRight, bottomLeft :  boolean - Whether to round the specified corner.]]
	)

	--- Simple Example
	paint.examples.header( panel, "Simple Example" )
	paint.examples.text( panel, [[Drawing rounded boxes with different corner radii and colors.]] )

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[<f>paint.roundedBoxes.roundedBox<e>(<n>20<F>, <n>5<F>, <n>5<F>, <n>64<F>, <n>64<F>, <k>{
<f>Color<e>(<n>255<F>, <n>0<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>255<F>, <n>0<e>)<F>, <f>Color<e>(<n>0<F>, <n>0<F>, <n>255<e>)<F>, <v>color_white<F>, <v>color_black<k>
}<e>)
<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>72<F>, <n>5<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <e>(<f>Material<e>(<s>'icon16/application_xp.png'<e>)))
]]
	)

	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self )
			-- A colorful rounded box
			paint.roundedBoxes.roundedBox( 20, 5, 5, 64, 64, {
				Color( 255, 0, 0 ), -- Top Left
				Color( 0, 255, 0 ), -- Top Right
				Color( 0, 0, 255 ), -- Bottom Right
				COLOR_WHITE,	-- Bottom Left
				COLOR_BLACK	-- Center
			} )

			-- An icon with rounded corners
			paint.roundedBoxes.roundedBox( 32, 72, 5, 64, 64, COLOR_WHITE, ( Material( "icon16/application_xp.png" ) ) )
		paint.endPanel()
	end )

	-- Asymmetrical Example
	paint.examples.header( panel, "Asymmetrical Example" )
	paint.examples.text( panel, [[Drawing a rounded box with only the top-right and bottom-left corners rounded.]] )

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[<f>paint.roundedBoxes.roundedBoxEx<e>(<n>16<F>, <n>10<F>, <n>10<F>, <n>64<F>, <n>64<F>, <v>color_white<F>, <k>false<F>, <k>true<F>, <k>false<F>, <k>true<e>)]] )

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, function( self, width, height )
		surface.SetDrawColor( 50, 50, 50, 200 )
		surface.DrawRect( 0, 0, width, height )
		paint.startPanel( self )
			paint.roundedBoxes.roundedBoxEx( 16, 10, 10, 64, 64, COLOR_WHITE, false, true, false, true )
		paint.endPanel()
	end )

	--- Stencil Masked Example
	paint.examples.header( panel, "Stencil Masked Example" )
	paint.examples.text( panel, 
[[Creating a button with a circular ripple effect when clicked.
This example uses stencils to create a mask for the ripple effect.]]
	)

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel,
[[
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
end]]
	)

	paint.examples.subheader( panel, "Result" )

	local button = panel:Add('DButton')
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

	local RIPPLE_DIE_TIME = 1
	local RIPPLE_START_ALPHA = 50

	function button:Paint(w, h)
		paint.startPanel(self)
			mask(function()
				paint.roundedBoxes.roundedBox( 32, 0, 0, w, h, COLOR_RED )
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

					paint.roundedBoxes.roundedBox(radius, rippleX - radius, rippleY - radius, radius * 2, radius * 2, ColorAlpha(COLOR_WHITE, alpha))
				end
			end)
		paint.endPanel()
	end

	function button:DoClick()
		local posX, posY = self:LocalCursorPos()
		self.rippleEffect = {posX, posY, RealTime()}
	end

	-- Animated Rainbow Colors Example
	paint.examples.header( panel, "Animated Rainbow Colors Example" )
	paint.examples.text( panel, [[Drawing a rounded box with a rainbow gradient.]] )

	paint.examples.subheader( panel, "Code" )
	paint.examples.code( panel, [[
<k>local <v>time1<F>, <v>time2 <k>= <f>RealTime<e>() <k>* <n>100<F>, <f>RealTime<e>() <k>* <n>100 <k>+ <n>30
<k>local <v>time3 <k>= <e>(<v>time1 <k>+ <v>time2<e>) <k>/ <n>2

<k>local <v>color1<F>, <v>color2<F>, <v>color3 <k>= <f>HSVToColor<e>(<v>time1<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<v>time2<F>, <n>1<F>, <n>1<e>)<F>, <f>HSVToColor<e>(<v>time3<F>, <n>1<F>, <n>1<e>)

<f>paint.roundedBoxes.roundedBox<e>(<n>32<F>, <n>10<F>, <n>10<F>, <n>300<F>, <n>128<F>, <k>{<v>color1<F>, <v>color3<F>, <v>color2<F>, <v>color3<k>}<e>)
<c>-- Center is color3 not nil because interpolating between colors and between HSV is different
]] )

	paint.examples.subheader( panel, "Result" )
	paint.examples.result( panel, 162, function( self, width, height )
		surface.SetDrawColor(50, 50, 50, 200)
		surface.DrawRect(0, 0, width, height)
		paint.startPanel(self, true, true)
			local time1, time2 = RealTime() * 100, RealTime() * 100 + 30
			local time3 = (time1 + time2) / 2

			local color1, color2, color3 = HSVToColor(time1, 1, 1), HSVToColor(time2, 1, 1), HSVToColor(time3, 1, 1)

			paint.roundedBoxes.roundedBox(32, 10, 10, 300, 128, {color1, color3, color2, color3})
			-- Center is color3 not nil because interpolating between colors and between HSV is different
		paint.endPanel( true, true )
	end )


end )