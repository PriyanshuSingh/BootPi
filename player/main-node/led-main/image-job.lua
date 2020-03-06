
local Config = require("config")
local shader_repo = require("shader-repo")
local constants = require("constants")
local logManager = require("log-manager")
local function ramp(t_s, t_e, t_c, ramp_time)
    if ramp_time == 0 then return 1 end
    local delta_s = t_c - t_s
    local delta_e = t_e - t_c
    return math.min(1, delta_s * 1/ramp_time, delta_e * 1/ramp_time)
end


return function(item, ctx, fn, draw_progress)
    fn.wait_t(ctx.starts - constants.IMAGE_PRELOAD)

    local res = resource.load_image(ctx.asset)

    for now in fn.wait_next_frame do
        local state, err = res:state()
        if state == "loaded" then
            break
        elseif state == "error" then
            error("preloading failed: " .. err)
        end
    end

    print "waiting for start"
    local starts = fn.wait_t(ctx.starts)
    local duration = ctx.ends - starts

    print(">>> IMAGE", res, ctx.starts, ctx.ends)
    -- logManager.log(item, "renderlog")
    local strt = sys.now()
    if Config.get_kenburns() then
        local function lerp(s, e, t)
            return s + t * (e-s)
        end

        local paths = {
            {from = {x=0.0,  y=0.0,  s=1.0 }, to = {x=0.08, y=0.08, s=0.9 }},
            {from = {x=0.05, y=0.0,  s=0.93}, to = {x=0.03, y=0.03, s=0.97}},
            {from = {x=0.02, y=0.05, s=0.91}, to = {x=0.01, y=0.05, s=0.95}},
            {from = {x=0.07, y=0.05, s=0.91}, to = {x=0.04, y=0.03, s=0.95}},
        }

        local path = paths[math.random(1, #paths)]

        local to, from = path.to, path.from
        if math.random() >= 0.5 then
            to, from = from, to
        end

        local w, h = res:size()
        local multisample = w / WIDTH > 0.8 or h / HEIGHT > 0.8
        local shader = multisample and shader_repo.multisample or shader_repo.simple

        while true do
            local now = sys.now()
            local t = (now - starts) / duration
            shader:use{
                x = lerp(from.x, to.x, t);
                y = lerp(from.y, to.y, t);
                s = lerp(from.s, to.s, t);
            }
            util.draw_correct(res, 0, 0, WIDTH, HEIGHT, ramp(
                ctx.starts, ctx.ends, now, Config.get_switch_time()
            ))
            draw_progress(ctx.starts, ctx.ends, now)
            if now > ctx.ends then
                break
            end
            fn.wait_next_frame()
        end
    else
        while true do
            local now = sys.now()
            util.draw_correct(res, 0, 0, WIDTH, HEIGHT, ramp(
                ctx.starts, ctx.ends, now, Config.get_switch_time()
            ))
            -- res:draw(0, 0, WIDTH, HEIGHT, ramp(
            --     ctx.starts, ctx.ends, now, Config.get_switch_time()
            -- ))
            draw_progress(ctx.starts, ctx.ends, now)
            if now > ctx.ends then
                break
            end
            fn.wait_next_frame()
        end
    end
    local en = sys.now()
    print("<<< IMAGE", res, ctx.starts, ctx.ends)
    logManager.log({
        type=item.type,
        logType="renderlog",
        asset_name=item.asset_name,
        creative_id=item.creative_id,
        duration=en-strt,
        startTime=os.time() - (en - strt),
        endTime=os.time(),
        advertiser_id=item.advertiser_id
    })
    res:dispose()

    return true
end
