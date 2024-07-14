---@class paint.examples
---@field title fun(parent:Panel, text:string) : nil
---@field header fun(parent:Panel, text:string) : nil
---@field subheader fun(parent:Panel, text:string) : nil
---@field text fun(parent:Panel, text:string) : nil
---@field boldText fun(parent:Panel, text:string) : nil
---@field footer fun(parent:Panel, height:number) : nil
---@field create fun() : nil
---@field addHelpTab fun( name:string, icon:string, func:fun():Panel ) : nil
local examples = {
	controls = {}
}
paint.examples = examples

local COLOR_BACKGROUND = Color( 148, 152, 156 )

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

--#endregion Example Formatting Functions

function examples.showHelp()

	frame:SetSize(640, 480)
	frame:Center()
	frame:SetTitle('Paint Library Examples')
	frame:SetSizable(true)

	local propertySheet = frame:Add('DPropertySheet')
	propertySheet:Dock(FILL)

	for k, v in pairs(examples.controls) do
		propertySheet:AddSheet(v.name, v.func(), v.icon)
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

load('paint/examples/vgui/markup_richtext_cl.lua')
load('paint/examples/controls/lines_cl.lua')
load('paint/examples/controls/rects_cl.lua')
load('paint/examples/controls/rounded_boxes_cl.lua')
load('paint/examples/controls/outlines_cl.lua')
load('paint/examples/controls/batch_cl.lua')
load('paint/examples/controls/blur_cl.lua')
load('paint/examples/controls/main_cl.lua')

--#endregion Load Examples