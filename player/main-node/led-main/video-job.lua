local Config = require("config")
local shader_repo = require("shader-repo")
local constants = require("constants")

local function ramp(t_s, t_e, t_c, ramp_time)
    if ramp_time == 0 then return 1 end
    local delta_s = t_c - t_s
    local delta_e = t_e - t_c
    return math.min(1, delta_s * 1/ramp_time, delta_e * 1/ramp_time)
end

return function(item, ctx, fn, draw_progress)
    fn.wait_t(ctx.starts - constants.VIDEO_PRELOAD)

    local res = resource.load_video{
        file = ctx.asset,
        audio = Config.get_audio(),
        looped = false,
        paused = true,
        -- raw = true,
    }

    for now in fn.wait_next_frame do
        local state, err = res:state()
        if state == "paused" then
            break
        elseif state == "error" then
            error("preloading failed: " .. err)
        end
    end

    print "waiting for start"
    fn.wait_t(ctx.starts)

    print(">>> VIDEO", res, ctx.starts, ctx.ends)
    res:start()
    local strt = sys.now()
    while true do
        local now = sys.now()
        local rotation, portrait = Config.get_rotation()
        local state, width, height = res:state()
        if state ~= "finished" then
            local layer = -2
            if now > ctx.starts + 0.1 then
                -- after the video started, put it on a more
                -- foregroundy layer. that way two videos
                -- played after one another are sorted in a
                -- predictable way and no flickering occurs.
                layer = -1
            end
            if portrait then
                width, height = height, width
            end
            -- local x1, y1, x2, y2 = util.scale_into(NATIVE_WIDTH, NATIVE_HEIGHT, width, height)
            -- res:layer(layer):place(0, 0, WIDTH, HEIGHT, rotation):alpha(ramp(
            --     ctx.starts, ctx.ends, now, Config.get_switch_time()
            -- ))
            util.draw_correct(res, 0, 0, WIDTH, HEIGHT, ramp(
                ctx.starts, ctx.ends, now, Config.get_switch_time()
            ))
        end
        draw_progress(ctx.starts, ctx.ends, now)
        if now > ctx.ends then
            break
        end
        fn.wait_next_frame()
    end
    local en=sys.now()
    print("<<< VIDEO", res, ctx.starts, ctx.ends)
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
