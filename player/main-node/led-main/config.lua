local json = require "json"

local Config = (function()
    local playlist = {}
    local switch_time = 1
    local synced = false
    local kenburns = false
    local audio = false
    local portrait = false
    local rotation = 0
    local transform = function() end

    local config_file = "data/config.json"

    -- You can put a static-config.json file into the package directory.
    -- That way the config.json provided by info-beamer hosted will be
    -- ignored and static-config.json is used instead.
    --
    -- This allows you to import this package bundled with images/
    -- videos and a custom generated configuration without changing
    -- any of the source code.
    if CONTENTS["vstatic-config.json"] then
        config_file = "static-config.json"
        print "[WARNING]: will use static-config.json, so config.json is ignored"
    end

    util.file_watch(config_file, function(raw)
        print("updated " .. config_file)
        local config = json.decode(raw)

        synced = config.synced
        kenburns = config.kenburns
        audio = config.audio
        progress = config.progress

        rotation = config.rotation
        portrait = rotation == 90 or rotation == 270
        gl.setup(WIDTH, HEIGHT)
        transform = util.screen_transform(rotation)
        print("screen size is " .. WIDTH .. "x" .. HEIGHT)

        function getAssetPath(item)
            local t = {item.file.type, item.creative_id, item.file.timestamp, item.file.asset_name}
            return "data/assets/" .. table.concat(t, "|")
        end

        if #config.playlist == 0 then
            playlist = settings.FALLBACK_PLAYLIST
            switch_time = 0
            kenburns = false
        else
            playlist = {}
            local total_duration = 0
            for idx = 1, #config.playlist do
                local item = config.playlist[idx]
                total_duration = total_duration + item.duration
            end

            local offset = 0
            for idx = 1, #config.playlist do
                local item = config.playlist[idx]
                if item.duration > 0 then
                    playlist[#playlist+1] = {
                        offset = offset,
                        total_duration = total_duration,
                        duration = item.duration,
                        asset_name = getAssetPath(item),
                        type = item.file.type,
                        creative_id = item.creative_id,
                        advertiser_id = item.advertiser_id
                    }
                    offset = offset + item.duration
                end
            end
            switch_time = config.switch_time
        end
    end)

    return {
        get_playlist = function() return playlist end;
        get_switch_time = function() return switch_time end;
        get_synced = function() return synced end;
        get_kenburns = function() return kenburns end;
        get_audio = function() return audio end;
        get_progress = function() return progress end;
        get_rotation = function() return rotation, portrait end;
        apply_transform = function() return transform() end;
    }
end)()

return Config
