files = [
    'main',
    'batch',
    'lines',
    'rects',
    'rounded_boxes',
    'outlines',
    'blur',
    'circles',
    'svg',
    'downsampling'
]

wrapper = """
if SERVER then return AddCSLuaFile() end
local paint = {}
local MINIFIED = true
""" # do at the end is because of 'end do'.join()

contents = []
for i in files:
    with open(f'lua/paint/{i}_cl.lua', 'r') as f:
        contents.append(f.read())

version = 1.12
totalText = f'{wrapper} do {" end do ".join(contents)} end return paint'

with open('paint_minified_source.lua', 'w') as f:
    f.write(totalText)
