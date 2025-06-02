--- Currently WIP.
--- Planned features are (strong means completed):
--- 2. ** Support for rect **
--- 3. ** Support for circle **
--- 1. Support for defs and g
--- 4. Support for path
--- 5. Support for fill
--- 6. Support for fill='linear-gradient'
--- 7. Support for ellipses in path
---@class paint.svg
local svg = {}
local paint = paint

paint.svg = svg

do -- CSS Colors
	local sub = string.sub
	local color = Color

	---An olde function of mine from simple UI library. Could GAMMA un-correct color too.
	---@param hex string
	---@return Color
	local function fromHex(hex)
		local ind = sub(hex, 1, 1) == '#' and 1 or 0
		local r, g, b, a = hex:sub(1 + ind, 2 + ind), hex:sub(3 + ind, 4 + ind), hex:sub(5 + ind, 6 + ind),
			hex:sub(7 + ind, 8 + ind)

		---@diagnostic disable-next-line: cast-local-type
		r, g, b, a = tonumber(r, 16) or 255, tonumber(g, 16) or 255, tonumber(b, 16) or 255,
			a ~= '' and tonumber(a, 16) or 255

		return color(r, g, b, a)
	end

	---https://developer.mozilla.org/en-US/docs/Web/CSS/named-color
	---@enum paint.svg.colors
	local colors = {
		['black'] = color(0, 0, 0),
		['silver'] = fromHex('#c0c0c0'),
		['gray'] = fromHex('#808080'),
		['white'] = color(255, 255, 255),
		['maroon'] = fromHex('#800000'),
		['red'] = color(255, 0, 0),
		['purple'] = fromHex('#800080'),
		['fuchsia'] = fromHex('#ff00ff'),
		['green'] = color(0, 255, 0),
		['lime'] = fromHex('#00ff00'),
		['olive'] = fromHex('#808000'),
		['yellow'] = fromHex('#ffff00'),
		['navy'] = fromHex('#000080'),
		['blue'] = color(0, 0, 255),
		['teal'] = fromHex('#008080'),
		['aqua'] = fromHex('#00ffff'),
		--- Below are additional colors. They will be added here when i wont be lazy...
		['aliceblue'] = fromHex('#F0F8FF'),
		['pink'] = fromHex('#FFC0CB'),
	}

	---@diagnostic disable-next-line: inject-field
	colors.fromHex = fromHex
	svg.colors = colors
end

---Parsing
do
	---@class paint.svg.parserObj
	---@field [0] string type

	---@type {[string] : fun(tag : string) : paint.svg.parserObj}
	local parsers = {}

	---@param tag string
	---@param parser fun(tag : string) : paint.svg.parserObj
	local function addParser(tag, parser)
		parsers[tag] = parser
	end

	local match = string.match
	local sub = string.sub

	local parseColor
	do
		local colors = svg.colors
		local black = Color(0, 0, 0)

		---@param color string
		---@return gradients
		local function parseColorValue(color)
			if colors[color:lower()] then
				return colors[color:lower()]
			elseif sub(color, 1, 1) == '#' then
				return colors.fromHex(color)
			else
				return black
			end
		end

		function parseColor(tag, name)
			return parseColorValue(match(tag, name .. ' ?=["\']([%w%d#().]+)["\']') or '')
		end
	end

	local parseSize
	do
		local tonumber = tonumber
		---@return fun(height : number) : number
		local function createPercentFunc(val)
			local percent = tonumber(sub(val, 1, -2)) / 100
			return function(height)
				return height * percent
			end
		end

		---@param val integer?
		---@return fun() : number
		local function createAbsoluteFunc(val)
			val = tonumber(val) or 0
			return function()
				return val
			end
		end

		local patternSafe = string.PatternSafe

		---@param tag string
		---@param name string
		---@param name2 string
		---@return fun(w : number, h : number) : number, number
		---@overload fun(tag: string, name : string) : fun(w : number, h: number) : number
		function parseSize(tag, name, name2)
			name = patternSafe(name)

			if name2 then
				name2 = patternSafe(name2)
			end

			do -- Positioning
				local x = match(tag, name .. ' ?=["\'](.-)["\']')
				local y = match(tag, (name2 or name) .. ' ?=["\'](.-)["\']')

				local xFunc, yFunc
				if x and sub(x, -1, -1) == '%' then
					xFunc = createPercentFunc(x)
				else
					xFunc = createAbsoluteFunc(x)
				end

				if y and sub(y, -1, -1) == '%' then
					yFunc = createPercentFunc(y)
				else
					yFunc = createAbsoluteFunc(y)
				end

				if name2 then
					return function(w, h)
						return xFunc(w), yFunc(h)
					end
				end

				return function(w, h)
					---@diagnostic disable-next-line: missing-return-value
					return xFunc((w + h) / 2)
				end
			end
		end
	end

	---@class paint.svg.parserObj.rect : paint.svg.parserObj
	---@field pos fun(w, h) : number, number # This function returns position of rect
	---@field size fun(w, h) : number, number # This function returns size of rect.
	---@field fill gradients # returns colors of filling
	---@field stroke Color? # return stroke color. Can be nil if stroke is unset.
	---@field radius number # returns (rx+ry) / 2 - average radius of horizontal/vertical radiuses of roundings.
	---@field strokeWidth fun(w, h) : number #


	---@param tag string
	---@return paint.svg.parserObj.rect
	addParser('rect', function(tag)
		local tab = {}

		tab.pos = parseSize(tag, 'x', 'y')
		tab.size = parseSize(tag, 'width', 'height')

		local radiusSize = parseSize(tag, 'rx', 'ry')

		---@type fun(w : number, h : number) : number
		tab.radius = function(w, h)
			local rx, ry = radiusSize(w, h)

			return (rx + ry) / 2
		end

		tab.strokeWidth = parseSize(tag, 'stroke-width')

		do
			tab.fill = parseColor(tag, 'fill')
			tab.stroke = parseColor(tag, 'stroke')
		end

		---@cast tab paint.svg.parserObj.rect
		return tab
	end)

	---@class paint.svg.parserObj.circle : paint.svg.parserObj
	---@field pos fun(w, h) : number, number # This function returns position of rect
	---@field radius fun(w, h) : number
	---@field fill Color # returns colors of filling
	---@field strokeWidth number
	---@field stroke Color

	---@param tag string
	---@return paint.svg.parserObj.circle
	addParser('circle', function(tag)
		local tab = {}

		tab.pos = parseSize(tag, 'cx', 'cy')
		tab.radius = parseSize(tag, 'r')

		do
			tab.fill = parseColor(tag, 'fill')
			tab.stroke = parseColor(tag, 'stroke')
		end

		tab.strokeWidth = parseSize(tag, 'stroke-width')

		return tab
	end)

	---@class paint.svg.parserObj.svg : paint.svg.parserObj
	---@field width number?
	---@field height number?
	---@field x number?
	---@field y number?

	---@param tag string
	---@return paint.svg.parserObj.svg
	addParser('svg', function(tag)
		local tab = {}

		local x, y, w, h = match(tag, 'viewBox ?=["\'] ?(%d+) (%d+) (%d+) (%d+) ?["\']')

		w = w or match(tag, 'width ?=["\'](%d+)["\']')
		h = h or match(tag, 'height ?=["\'](%d+)["\']')

		x = x or match(tag, 'x ?=["\'](%d+)["\']')
		y = y or match(tag, 'y ?=["\'](%d+)["\']')

		tab.x = tonumber(x)
		tab.y = tonumber(y)
		tab.width = tonumber(w)
		tab.height = tonumber(h)

		---@cast tab paint.svg.parserObj.svg
		return tab
	end)

	svg.parsers = parsers
end

---Construction
do
	---@class paint.svg.settings
	---@field w number
	---@field h number
	---@field x number
	---@field y number
	---@field circleVertexCount number?

	---@type {[string] : fun(obj : paint.svg.parserObj, settings : paint.svg.settings)}
	local constructors = {}

	---@param tag string
	---@param constructor fun(obj : paint.svg.parserObj, settings : paint.svg.settings)
	local function addConstructor(tag, constructor)
		constructors[tag] = constructor
	end

	do
		local min = math.min
		local roundedBox = paint.roundedBoxes.roundedBox
		local drawOutline = paint.outlines.drawOutline
		---@param obj paint.svg.parserObj.rect
		---@param settings paint.svg.settings
		addConstructor('rect', function(obj, settings)
			local x, y = obj.pos(settings.w, settings.h)
			local w, h = obj.size(settings.w, settings.h)

			local strokeWidth = obj.strokeWidth(settings.w, settings.h)

			local radiusVal = min(w, h) / 2
			local radius = obj.radius(radiusVal, radiusVal)

			local fill = obj.fill
			local stroke = obj.stroke

			roundedBox(radius, x + settings.x, y + settings.y, w, h, fill)

			if strokeWidth > 0 then
				---@cast stroke -?
				drawOutline(radius, x + settings.x, y + settings.y, w, h, stroke, nil, strokeWidth)
			end
		end)
	end

	do
		local drawCircle = paint.circles.drawCircle
		local drawOutlinedCircle = paint.circles.drawOutline
		---@param obj paint.svg.parserObj.circle
		---@param settings paint.svg.settings
		addConstructor('circle', function(obj, settings)
			local x, y = obj.pos(settings.w, settings.h)
			local radius = obj.radius(settings.w, settings.h)

			local fill = obj.fill
			local stroke = obj.stroke

			drawCircle(x + settings.x, y + settings.y, radius, radius, fill, settings.circleVertexCount)

			local strokeWidth = obj.strokeWidth(radius, radius)

			if strokeWidth > 0 then
				drawOutlinedCircle(x + settings.x, y + settings.y, radius, radius, stroke, strokeWidth,
					settings.circleVertexCount)
			end
		end)
	end

	---@param obj paint.svg.parserObj.svg
	---@param settings paint.svg.settings
	addConstructor('svg', function(obj, settings)
		settings.w = obj.width or settings.w
		settings.h = obj.height or settings.h

		settings.x = obj.x or settings.x
		settings.y = obj.y or settings.y
	end)

	svg.constructors = constructors
end

---API
do
	local gmatch = string.gmatch
	local match = string.match

	local parsers = svg.parsers

	---@param svgText string
	---@return {[integer] : paint.svg.parserObj}
	function svg.parseSVG(svgText)
		local parsingTab = {}
		local index = 0

		for tag in gmatch(svgText, '<(.-)>') do
			---@type string
			local nameOfTag = match(tag, '^(%w+)') or 'undefined'
			if parsers[nameOfTag] then
				local tab = parsers[nameOfTag](tag)
				tab[0] = nameOfTag

				index = index + 1
				parsingTab[index] = tab
			elseif nameOfTag ~= 'undefined' then
				print('[paint] Cant parse <' .. nameOfTag .. '> tag. Not implemented yet')
			end
		end

		return parsingTab
	end

	local startBatching = paint.batch.startBatching
	local stopBatching = paint.batch.stopBatching

	local constructors = svg.constructors

	---@param tab {[integer] : paint.svg.parserObj}
	---@param settings paint.svg.settings?
	---@return IMesh
	function svg.generateIMesh(tab, settings)
		settings = settings or { w = 0, h = 0, x = 0, y = 0 }
		---@cast settings -?

		startBatching()

		for k, v in ipairs(tab) do
			local type = v[0]

			if constructors[type] then
				constructors[type](v, settings)
			else
				print('[paint] Cant construct IMesh from ' .. type .. ' type. Not implemented yet.')
			end
		end

		return stopBatching()
	end
end
