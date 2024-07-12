local examples = {}
local paint = paint

--- NO clean code here
--- Since it's made only for example
function examples.create()
	local frame = vgui.Create('DFrame')

	frame:SetSize(640, 480)
	frame:Center()
	frame:SetTitle('Paint Library Examples')
	frame:SetSizable(true)

	local propertySheet = frame:Add('DPropertySheet')
	propertySheet:Dock(FILL)

	for k, v in pairs(examples.controls) do
		propertySheet:AddSheet(v.name, v.func(), v.icon)
	end
end

examples.controls = {}
function examples.addControl(name, func, icon)
	examples.controls[name] = {name = name, func = func, icon = icon}
end

paint.examples = examples