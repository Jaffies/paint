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
if SERVER then return end

do
if CLIENT and BRANCH ~= 'x86-64' then
print('paint library detoured mesh.Position to support (x, y, z) overload because gmod hasn\\'t updated yet on non x64-86')
local vec = Vector()
local vecSetUnpacked = vec.SetUnpacked
mesh.OldPosition = mesh.OldPosition or mesh.Position
---@param x number|Vector
---@param y? number
---@param z? number
---@overload fun(x: Vector)
function mesh.Position(x, y, z)
if y == nil then
---@cast x Vector
mesh.OldPosition(x)
return
end
---@cast y number
---@cast z number
---@cast x number
vecSetUnpacked(vec, x, y, z)
mesh.OldPosition(vec)
end
end
end

do
""" # do at the end is because of 'end do'.join()

contents = []
for i in files:
    with open(f'lua/paint/{i}_cl.lua', 'r') as f:
        contents.append(f.read())

version = 1.07
totalText = f'{wrapper} {" end do ".join(contents)} end print("paint library loaded! Version is {version}!")'

with open('paint_minified_source.lua', 'w') as f:
    f.write(totalText)
