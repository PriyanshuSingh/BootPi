local json = require "json"
local Intermissions = (function()
    local intermissions = {}
    local intermissions_serial = {}

    util.file_watch("intermission.json", function(raw)
        intermissions = json.decode(raw)
    end)

    local serial = sys.get_env "SERIAL"
    if serial then
        util.file_watch("intermission-" .. serial .. ".json", function(raw)
            intermissions_serial = json.decode(raw)
        end)
    end

    local function get_playlist()
        local now = os.time()
        local playlist = {}

        local function add_from_intermission(intermissions)
            for idx = 1, #intermissions do
                local intermission = intermissions[idx]
                if intermission.starts <= now and now <= intermission.ends then
                    playlist[#playlist+1] = {
                        duration = intermission.duration,
                        asset_name = intermission.asset_name,
                        type = intermission.type,
                    }
                end
            end
        end

        add_from_intermission(intermissions)
        add_from_intermission(intermissions_serial)

        return playlist
    end

    return {
        get_playlist = get_playlist;
    }
end)()
return Intermissions
