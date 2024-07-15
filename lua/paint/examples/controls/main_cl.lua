paint.examples.addHelpTab( "VGUI Info", "icon16/user.png", function( panel )

	-- Intro
	paint.examples.title( panel, "VGUI Usage Information" )
	paint.examples.text( panel,
[[Unfortunately, the paint library cannot integrate seamlessly with VGUI and Derma in the way that the surface and draw libraries do.
This is because Meshes, which are used by the paint library, can only use absolute screen coordinates whereas the surface and draw libraries are automatically provided with panel-relative coordinates by the VGUI system.

In addition, meshes cannot be clipped with the default VGUI clipping system and will behave as though it is disabled.

To work around these limitations, you can use: 
]] )

	-- Start panel
	paint.examples.boldText( panel, "paint.startPanel( panel, position?, boundaries? )" )
	paint.examples.text( panel,
[[
Arguments:
- panel : Panel - The panel to draw on.
- position : boolean? - Set to true to autoamtically adjust all future paint operations to be relative to the panel.  Default: true
- boundaries : boolean? - Set to true to enable ScissorRect to the size of the panel. Default: false
]] )

	-- End panel
	paint.examples.boldText( panel, "paint.endPanel( position?, boundaries? )" )
	paint.examples.text( panel,
[[
Arguments:
- position : boolean? - Set to true to autoamtically adjust all future paint operations to be relative to the panel.  Default: true
- boundaries : boolean? - Set to true to enable ScissorRect to the size of the panel. Default: false

Note: You need to have same arguments for position and boundaries between start and end panel functions.

Please, keep in mind that this library is still in development. 
You can help the project by contributing to it at: https://github.com/jaffies/paint
]] )

end )