local json = require "json"
return (function()
    local c = nil
    node.event("connect", function (client, prefix)
        print("Connected event: ", prefix, client)
        c = client
    end)

    node.event("disconnect", function (client)
        print("Disconnected event: ", prefix, client)
        if (client == c) then
            c = nil
        end
    end)

    node.event("input", function (line, client)
        print("Received input: [", line, "] from :", client)
        node.client_write(client, "Hey There!")
    end)

    node.event("rlog", function (json)
        if (c == nil) then
            print("Error: client is not connected yet!")
            return
        end
        node.client_write(c, json)
    end)

    return {
        log = function (data)
            data.logType = data.logType or "log"
            node.dispatch("rlog", json.encode(data))
        end
    }
end)()
