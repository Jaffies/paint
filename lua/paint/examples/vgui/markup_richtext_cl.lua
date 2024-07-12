--- Made fast, no clean code as it's not part of library itself.
local PANEL = {}

-- f = Function
-- b = Background
-- F = Foreground
-- c = Comment
-- k = Keyword
-- v = Variable
-- e = Entity
-- s = String
-- n = Number
local colors = {
	f = Color(220, 220, 170),
	b = Color(30,30,30),
	F = Color(212, 212, 212),
	c = Color(106, 153, 85),
	k = Color(197, 134, 192),
	v = Color(156, 220, 254),
	e = Color(86, 156, 214),
	s = Color(206, 145, 120),
	n = Color(181, 206, 168)
}

function PANEL:AddMarkupText(text)
	text:gsub('<([fbFckvesn])>([^<]*)', function(color, text)
		self:InsertColorChange(colors[color]:Unpack())
		self:AppendText(text)
	end)
end

function PANEL:SetMarkupText(text)
	self.markupText = text
end

do
	local charToCol = {
		['('] = '<e>(',
		[')'] = '<e>)',
		['*'] = '<k>*',
		['/'] = '<k>/',
		[','] = '<F>,',
		['='] = '<k>=',
		['-'] = '<k>-',
		['^'] = '<k>^',
		['\''] = '<s>\'',
		['"'] = '<s>"',
		['\n'] = '<F>\n',
		['\t'] = '<F>\t',
		['['] = '<k>[',
		[']'] = '<k>]',
		['>'] = "<k>>",
	}

	local keyWords = {
		'return', 'break', 'continue', 'for', 'in', 'do', 'if', 'then', 'end', 'repeat', 'until', 'function', 'local',
	}
	function PANEL:AutomaticMarkup(text)
		text = text:gsub('[%[%]()*/,=-^\n\'"]', charToCol)
		for k, v in ipairs(keyWords) do
			text = text:Replace(v, '<k>' .. v)
		end

		text = text:gsub('[-/][-/]', function(char)
			return '<c>' .. char
		end)

		self:SetMarkupText(text)
	end
end

local setTall = FindMetaTable('Panel').SetTall
local getTall = FindMetaTable('Panel').GetTall

function PANEL:Init(text)
	self.Paint = function()
		setTall(self, self.tall or getTall(self))
		self:AddMarkupText(self.markupText or '')
		timer.Simple(0, function()
			self:GotoTextStart()
		end)
		self.Paint = nil
	end
end

--- some hacky workaround of bug when richtext is not scrollable
function PANEL:SetTall(px)
	self.tall = px
end

function PANEL:PerformLayout()
	self:SetPaintBackgroundEnabled(true)
	self:SetBGColorEx(colors['b']:Unpack())
	self:SetPaintBorderEnabled(true)
end

vgui.Register('paint.markupRichText', PANEL, 'RichText')