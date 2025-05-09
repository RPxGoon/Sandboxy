-- Sandboxy Server List Manager

serverlistmgr = {}

local public_servers = {}
local favorites = {}

function serverlistmgr.init()
    -- Load favorites from file
    local file = io.open(core.get_user_path()..DIR_DELIM.."client"..
        DIR_DELIM.."favorites.json", "r")
    if file then
        local data = file:read("*all")
        favorites = core.parse_json(data) or {}
        file:close()
    end
end

function serverlistmgr.save_favorites()
    -- Save favorites to file
    local file = io.open(core.get_user_path()..DIR_DELIM.."client"..
        DIR_DELIM.."favorites.json", "w")
    if file then
        local data = core.write_json(favorites)
        file:write(data)
        file:close()
    end
end

function serverlistmgr.get_favorites()
    return favorites
end

function serverlistmgr.get_public_servers()
    return public_servers
end

function serverlistmgr.add_favorite(server)
    if not server or not server.address then return end
    
    -- Check if already exists
    for i, fav in ipairs(favorites) do
        if fav.address == server.address then
            return
        end
    end

    -- Add new favorite
    table.insert(favorites, {
        name = server.name or "",
        address = server.address,
        port = server.port or 30000,
        description = server.description or "",
        favicon = server.favicon or "",
        players = server.players or 0,
        max_players = server.max_players or 0
    })

    serverlistmgr.save_favorites()
end

function serverlistmgr.remove_favorite(address)
    for i, server in ipairs(favorites) do
        if server.address == address then
            table.remove(favorites, i)
            serverlistmgr.save_favorites()
            return true
        end
    end
    return false
end

function serverlistmgr.sync_public_servers()
    -- Request server list from master server
    local url = core.settings:get("serverlist_url") or 
                "https://servers.sandboxy.org"

    core.handle_async("get_serverlist", {url = url}, function(result)
        if result and result.list then
            public_servers = result.list
            core.event_handler({
                type = "serverlist_updated",
                list = public_servers
            })
        end
    end)
end

-- Initialize on load
serverlistmgr.init()
