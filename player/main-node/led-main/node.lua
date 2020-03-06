gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

node.make_nested() -- New API call!
local Config = require("config")

local Queue = require("render-queue")

-- local logManager = require("log-manager")
util.set_interval(1, node.gc)

-- util.set_interval(1, function ()
--     local data = {l=1, p=2}
--     -- print("sending log" .. data)
--     logManager.log(data, "renderlog")
-- end)

function node.render()
    -- print("--- frame", sys.now())
    gl.clear(0, 0, 0, 1)
    Config.apply_transform()
    Queue.tick()
end
