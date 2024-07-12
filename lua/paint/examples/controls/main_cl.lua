paint.examples.addControl('Other stuff', function()
	local scroll = vgui.Create('DScrollPanel')
	scroll:Dock(FILL)

	scroll.Paint = function(self)
		paint.startPanel(self, false, true)
	end

	scroll.PaintOver = function(self)
		paint.endPanel(false, true)
	end

	local label = scroll:Add('DLabel')
	label:SetAutoStretchVertical(true)
	label:Dock(TOP)
	label:SetColor(color_black)
	label:SetMouseInputEnabled(false)
	label:SetText([[Not it's time for other stuff
We will dive into VGUI stuff because it is important subject.

Unfortunately, paint library can't work with VGUI natively.
meshes (which are used by paint library) can use only absolute screen coordinates
Also, they can't be clipped with default VGUI clipping. They will be drawed as if DisableCliping was set to true.

To fix this, you can use:
paint.startPanel(panel, position, boundaries)
paint.endPanel(position, boundaries)
-- if position == nil, then it will be set to true. Set false to manually disable position.
-- position sets (or unsets) absolute screen coordinates to relative to panel's (1st argument) position.
-- boundaries sets (or unsets) scissorRect (cliping) for panel's bounds 

you need to have same arguments for position and boundaries between start and end panel functions.

Please, keep in mind that this library is still in development. You can help developing this library in https://github.com/jaffies/paint
]])
	label:SetWrap(true)
	label:DockMargin(15, 15, 15, 0)

	return scroll
end,
'icon16/user.png')