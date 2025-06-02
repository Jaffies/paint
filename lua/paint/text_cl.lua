---@class paint.text
local text = {}

---@class paint.text.fonts
---@field [string] paint.text.font
local fonts = {}

do
	---@class paint.text.font
	---@field name string
	---@field atlasName string
	---@field glyphs {[string] : string} # table containing glyph (utf8 character) as a key and cell id as a value
	---@field texts {[string] : IMesh} # table containing text unique id, and a IMesh
end

do
	---surface.DrawText generation
	local function generateEngineGlyphs(characterList, fontName)
	end
end
