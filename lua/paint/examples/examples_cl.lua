---@class paint.examples
---@field title fun( parent:Panel, text:string ) : nil
---@field header fun( parent:Panel, text:string ) : nil
---@field subheader fun( parent:Panel, text:string ) : nil
---@field text fun( parent:Panel, text:string ) : nil
---@field boldText fun( parent:Panel, text:string ) : nil
---@field code fun( parent:Panel, text:string ) : nil
---@field result fun( parent:Panel, height:number|integer|fun( self:Panel, width:number, height:number )?, drawFunc:fun( self:Panel, width:number, height:number )? )
---@field create fun() : nil
---@field controls table<string, { name:string, func:fun( panel:Panel ):nil, icon:string }> # Controls to be added to the examples menu
---@field addHelpTab fun( name:string, icon:string, func:fun( panel:Panel ):nil ):nil
local examples = {
	controls = {}
}
paint.examples = examples

--#region Fonts

local titleFont = "paint_examples_title"
surface.CreateFont( titleFont, {
	font = "Roboto",
	size = 32,
	weight = 500,
	antialias = true
} )

local headerFont = "paint_examples_header"
surface.CreateFont( headerFont, {
	font = "Roboto",
	size = 24,
	weight = 500,
	antialias = true
} )

local subheaderFont = "paint_examples_subheader"
surface.CreateFont( subheaderFont, {
	font = "Roboto",
	size = 20,
	weight = 500,
	antialias = true
} )

local boldTextFont = "paint_examples_bold_text"
surface.CreateFont( boldTextFont, {
	font = "Roboto",
	size = 16,
	weight = 600,
	antialias = true
} )

local textFont = "paint_examples_text"
surface.CreateFont( textFont, {
	font = "Roboto",
	size = 16,
	weight = 500,
	antialias = true
} )

local codeFont = "paint_examples_code"
surface.CreateFont( codeFont, {
	font = "Courier New",
	size = 16,
	weight = 500,
	antialias = true
} )

--#endregion Fonts

--#region Example Formatting Functions

--- Adds a title to the parent panel
---@param parent Panel
---@param text string
function examples.title( parent, text )
	local title = parent:Add( "DLabel" )
	title:SetFont( titleFont )
	title:SetText( text )
	title:SizeToContents()
	title:Dock( TOP )
	title:SetContentAlignment( 4 )
	title:SetColor( color_black )
	title:DockMargin( 15, 15, 15, 0 )
end

--- Adds a header to the parent panel
---@param parent Panel
---@param text string
function examples.header( parent, text )
	local header = parent:Add( "DLabel" )
	header:SetFont( headerFont )
	header:SetText( text )
	header:SizeToContents()
	header:Dock( TOP )
	header:SetContentAlignment( 4 )
	header:SetColor( color_black )
	header:DockMargin( 15, 15, 15, 5 )
end

--- Adds a subheader to the parent panel
---@param parent Panel
---@param text string
function examples.subheader( parent, text )
	local header = parent:Add( "DLabel" )
	header:SetFont( subheaderFont )
	header:SetText( text )
	header:SizeToContents()
	header:Dock( TOP )
	header:SetContentAlignment( 4 )
	header:SetColor( color_black )
	header:DockMargin( 15, 5, 15, 5 )
end

--- Adds a bold text label to the parent panel
---@param parent Panel
---@param text string
function examples.boldText( parent, text )
	local label = parent:Add( "DLabel" )
	label:SetFont( boldTextFont )
	label:SetAutoStretchVertical( true )
	label:Dock( TOP )
	label:SetColor( color_black )
	label:SetText( text )
	label:SetWrap( true )
	label:DockMargin( 15, 5, 15, 0 )
end

--- Adds a text label to the parent panel
---@param parent Panel
---@param text string
function examples.text( parent, text )
	local label = parent:Add( "DLabel" )
	label:SetFont( textFont )
	label:SetAutoStretchVertical( true )
	label:Dock( TOP )
	label:SetColor( color_black )
	label:SetText( text )
	label:SetWrap( true )
	label:DockMargin( 15, 5, 15, 0 )
end

--- Adds a code block to the parent panel
---@param parent Panel
---@param text string
function examples.code( parent, text )
	local lines = string.Explode( "\n", text )
	local linesNeeded = 0
	for _, line in ipairs( lines ) do
		-- Add a line for every 80 characters
		linesNeeded = linesNeeded + math.ceil( #line / 80 )
	end

	local fontHeight = draw.GetFontHeight( codeFont )
	local lineHeight = fontHeight + 2
	local totalHeight = linesNeeded * lineHeight

	local markup = parent:Add( "paint.markupRichText" )
	markup:SetFont( codeFont )
	markup:SetMarkupText( string.Trim( text ) )
	markup:Dock( TOP )
	markup:DockMargin( 15, 0, 15, 15 )
	markup:SetTall( totalHeight )
	markup:InvalidateLayout()
end

--- Adds a result block to the parent panel
---@param parent Panel
---@param height number|integer|fun( self:Panel, width:number, height:number ):nil? Height of the result panel.  Defaults to 80.
---@param drawFunc fun( self:Panel, width:number, height:number )?
function examples.result( parent, height, drawFunc )

	local innerHeight
	local innerDrawFunc
	if isfunction( height ) then
		innerDrawFunc = height
		innerHeight = 80
	else
		innerDrawFunc = drawFunc
		innerHeight = height or 80
	end

	local result = parent:Add( "DPanel" )
	result:SetPaintBackground( true )
	result:SetTall( innerHeight )
	result:Dock( TOP )
	result:DockMargin( 15, 0, 15, 15 )
	result.Paint = innerDrawFunc
end

--#endregion Example Formatting Functions

function examples.showHelp()
	local frame = vgui.Create("DFrame" )

	frame:SetSize(
		math.min( 700, ScrW() ),
		math.min( 500, ScrH() )
	)
	frame:Center()
	frame:SetTitle( "Paint Library Examples" )
	frame:SetSizable( true )

	local propertySheet = frame:Add( "DPropertySheet" )
	propertySheet:Dock( FILL )

	local controls = examples.controls
	for controlIndex = 1, #controls do
		local control = controls[ controlIndex ]

		local scroll = vgui.Create("DScrollPanel" )
		scroll:Dock( FILL )
		scroll:GetCanvas():DockPadding( 5, 15, 5, 15 )

		scroll.Paint = function(self)
			paint.startPanel(self, false, true)
		end

		scroll.PaintOver = function(self)
			paint.endPanel(false, true)
		end

		control.func( scroll )

		propertySheet:AddSheet( control.name, scroll, control.icon )
	end

	frame:MakePopup()
end

function examples.addHelpTab( name, icon, func )
	examples.controls[#examples.controls + 1] = { name = name, func = func, icon = icon }
end

--#region Load Examples

local function load(path)
	AddCSLuaFile(path)
	if CLIENT then
		include(path)
	end
end

