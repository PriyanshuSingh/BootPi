local ImageJob = require("image-job")
local VideoJob = require("video-job")
local Config = require("config")
local Intermissions = require("intermissions")
local shader_repo = require("shader-repo")
local constants = require("constants")
local json = require "json"

local white = resource.create_colored_texture(1,1,1,1)
local black = resource.create_colored_texture(0,0,0,1)
local font = resource.load_font "roboto.ttf"

local function draw_progress(starts, ends, now)
    local mode = Config.get_progress()
    if mode == "no" then
        return
    end

    if ends - starts < 2 then
        return
    end

    local progress = 1.0 / (ends - starts) * (now - starts)
    if mode == "bar_thin_white" then
        white:draw(0, HEIGHT-10, WIDTH*progress, HEIGHT, 0.5)
    elseif mode == "bar_thick_white" then
        white:draw(0, HEIGHT-20, WIDTH*progress, HEIGHT, 0.5)
    elseif mode == "bar_thin_black" then
        black:draw(0, HEIGHT-10, WIDTH*progress, HEIGHT, 0.5)
    elseif mode == "bar_thick_black" then
        black:draw(0, HEIGHT-20, WIDTH*progress, HEIGHT, 0.5)
    elseif mode == "circle" then
        shader_repo.progress:use{
            progress_angle = math.pi - progress * math.pi * 2
        }
        white:draw(WIDTH-40, HEIGHT-40, WIDTH-10, HEIGHT-10)
        shader_repo.progress:deactivate()
    elseif mode == "countdown" then
        local remaining = math.ceil(ends - now)
        local text
        if remaining >= 60 then
            text = string.format("%d:%02d", remaining / 60, remaining % 60)
        else
            text = remaining
        end
        local size = 32
        local w = font:width(text, size)
        black:draw(WIDTH - w - 4, HEIGHT - size - 4, WIDTH, HEIGHT, 0.6)
        font:write(WIDTH - w - 2, HEIGHT - size - 2, text, size, 1,1,1,0.8)
    end
end
local function cycled(items, offset)
    offset = offset % #items + 1
    return items[offset], offset
end

local Loading = (function()
    local loading = "Loading..."
    local size = 80
    local w = font:width(loading, size)
    local alpha = 0

    local function draw()
        if alpha == 0 then
            return
        end
        font:write((WIDTH-w)/2, (HEIGHT-size)/2, loading, size, 1,1,1,alpha)
    end

    local function fade_in()
        alpha = math.min(1, alpha + 0.01)
    end

    local function fade_out()
        alpha = math.max(0, alpha - 0.01)
    end

    return {
        fade_in = fade_in;
        fade_out = fade_out;
        draw = draw;
    }
end)()

local Scheduler = (function()
    local playlist_offset = 0

    local function get_next()
        local playlist = Intermissions.get_playlist()
        if #playlist == 0 then
            playlist = Config.get_playlist()
        end

        local item
        item, playlist_offset = cycled(playlist, playlist_offset)
        print(string.format("next scheduled item is %s [%f]", item.asset_name, item.duration))
        return item
    end

    return {
        get_next = get_next;
    }
end)()

local Queue = (function()
    local jobs = {}
    local scheduled_until = sys.now()
    local function enqueue(starts, ends, item)
        -- print(json.encode(item) .. "HEre<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        local co = coroutine.create(({
            image = ImageJob,
            video = VideoJob,
        })[item.type])

        local success, asset = pcall(resource.open_file, item.asset_name)
        if not success then
            print("CANNOT GRAB ASSET: ", asset)
            return
        end

        -- an image may overlap another image
        if #jobs > 0 and jobs[#jobs].type == "image" and item.type == "image" then
            starts = starts - Config.get_switch_time()
        end

        local ctx = {
            starts = starts,
            ends = ends,
            asset = asset;
        }

        local success, err = coroutine.resume(co, item, ctx, {
            wait_next_frame = function ()
                return coroutine.yield(false)
            end;
            wait_t = function(t)
                while true do
                    local now = coroutine.yield(false)
                    if now > t then
                        return now
                    end
                end
            end;
        }, draw_progress)

        if not success then
            print("CANNOT START JOB: ", err)
            return
        end

        jobs[#jobs+1] = {
            co = co;
            ctx = ctx;
            type = item.type;
        }

        scheduled_until = ends
        print("added job. scheduled program until ", scheduled_until)
    end

    local function schedule_synced()
        local starts = scheduled_until
        local playlist = Config.get_playlist()

        local now = sys.now()
        local unix = os.time()
        if unix < 100000 then
            return
        end

        local schedule_time = unix + scheduled_until - now + 0.05

        print("unix now", unix)
        print("schedule time:", schedule_time)

        for idx = 1, #playlist do
            local item = playlist[idx]
            print("item", idx)
            local cycle = math.floor(schedule_time / item.total_duration)
            print("cycle", cycle)
            local loop_base = cycle * item.total_duration
            local unix_start = loop_base + item.offset
            print("unix_start", unix_start)
            local start = now + (unix_start - unix)
            print("--> start", start)
            if start > scheduled_until - 0.05 then
                return enqueue(scheduled_until, start + item.duration, item)
            end
        end
        scheduled_until = now
        print "didn't find any schedulable item"
    end

    local function tick()
        gl.clear(0, 0, 0, 0)

        if Config.get_synced() then
            if sys.now() + constants.PRELOAD_TIME > scheduled_until then
                schedule_synced()
            end
        else
            for try = 1,3 do
                if sys.now() + constants.PRELOAD_TIME < scheduled_until then
                    break
                end
                local item = Scheduler.get_next()
                enqueue(scheduled_until, scheduled_until + item.duration, item)
            end
        end

        if #jobs == 0 then
            Loading.fade_in()
        else
            Loading.fade_out()
        end

        local now = sys.now()
        for idx = #jobs,1,-1 do -- iterate backwards so we can remove finished jobs
            local job = jobs[idx]
            local success, is_finished = coroutine.resume(job.co, now)
            if not success then
                print("CANNOT RESUME JOB: ", is_finished)
                table.remove(jobs, idx)
            elseif is_finished then
                table.remove(jobs, idx)
            end
        end

        Loading.draw()
    end

    return {
        tick = tick;
    }
end)()

return Queue
