gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
local hh = sys.get_env "HEIGHT"
local ww = sys.get_env "WIDTH"
print("this is height: ", tonumber(hh))
print("this is width: ", tonumber(ww))
function node.render()
    -- gl.clear(0, 0, 0, 1) -- green
    resource.render_child("led-main"):draw(0, 0, tonumber(ww or "90"), tonumber(hh or "90"))
    -- resource.render_child("test"):draw(0,0,100,100)
end
