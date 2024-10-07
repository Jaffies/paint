files = [
    'main',
    'batch',
    'lines',
    'rects',
    'rounded_boxes',
    'outlines',
    'blur',
    'circles'
]

wrapper = """
if SERVER then return AddCSLuaFile() end
""" # do at the end is because of 'end do'.join()

contents = []
for i in files:
    with open(f'lua/paint/{i}_cl.lua', 'r') as f:
        contents.append(f.read())

version = 1.12
totalText = f'{wrapper} do {" end do ".join(contents)} end print("paint library loaded! Version is {version}!")\n print("Copyright @mikhail_svetov aka @jaffies")'

with open('paint_minified_source.lua', 'w') as f:
    f.write(totalText)
