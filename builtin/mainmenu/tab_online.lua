-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

local function get_sorted_servers()
	local servers = {
		fav = {},
		public = {},
		incompatible = {}
	}

	local favs = serverlistmgr.get_favorites()
	local taken_favs = {}
	local result = menudata.search_result or serverlistmgr.servers
	for _, server in ipairs(result) do
		server.is_favorite = false
		for index, fav in ipairs(favs) do
			if server.address == fav.address and server.port == fav.port then
				taken_favs[index] = true
				server.is_favorite = true
				break
			end
		end
		server.is_compatible = is_server_protocol_compat(server.proto_min, server.proto_max)
		if server.is_favorite then
			table.insert(servers.fav, server)
		elseif server.is_compatible then
			table.insert(servers.public, server)
		else
			table.insert(servers.incompatible, server)
		end
	end

	if not menudata.search_result then
		for index, fav in ipairs(favs) do
			if not taken_favs[index] then
				table.insert(servers.fav, fav)
			end
		end
	end

	return servers
end

local function is_selected_fav(server)
	local address = core.settings:get("address")
	local port = tonumber(core.settings:get("remote_port"))

	for _, fav in ipairs(serverlistmgr.get_favorites()) do
		if address == fav.address and port == fav.port then
			return true
		end
	end
	return false
end

-- Persists the selected server in the "address" and "remote_port" settings

local function set_selected_server(server)
	if server == nil then -- reset selection
		core.settings:remove("address")
		core.settings:remove("remote_port")
		return
	end
	local address = server.address
	local port    = server.port
	gamedata.serverdescription = server.description

	if address and port then
		core.settings:set("address", address)
		core.settings:set("remote_port", port)
	end
end

local function find_selected_server()
	local address = core.settings:get("address")
	local port = tonumber(core.settings:get("remote_port"))
	for _, server in ipairs(serverlistmgr.servers) do
		if server.address == address and server.port == port then
			return server
		end
	end
	for _, server in ipairs(serverlistmgr.get_favorites()) do
		if server.address == address and server.port == port then
			return server
		end
	end
end

-- Sandboxy multiplayer tab

local function get_formspec()
    local selected_server = menudata.favorites:get_current_index()
    local search_string = core.settings:get("serversearch") or ""
    
    local tab = {
        name = "online",
        caption = "Play Online",
        tabsize = {x = 15.5, y = 7},
        content = {
            background = "menu_bg.png",
            containers = {
                {
                    x = 0.2, y = 0.2, w = 15.1, h = 5.8,
                    name = "server_list",
                    bgcolor = "#FFFFFF",
                    style = "container",
                    elements = {
                        {
                            type = "label",
                            x = 0.2, y = 0.2,
                            label = "Multiplayer Servers",
                            style = "label_header"
                        },
                        {
                            type = "field",
                            x = 0.2, y = 0.8, w = 14.7, h = 0.5,
                            name = "search_input",
                            label = "",
                            default = search_string
                        },
                        {
                            type = "list",
                            x = 0.2, y = 1.5, w = 14.7, h = 3.5,
                            name = "srv_list",
                            selected = selected_server,
                            transparent = false,
                            bgcolor = "#E0E0E0"
                        }
                    }
                }
            },
            buttons = {
                {
                    x = 0.2, y = 6.2, w = 3, h = 0.5,
                    name = "btn_join_server",
                    label = "Join Server",
                    bgcolor = "#4CAF50"
                },
                {
                    x = 3.4, y = 6.2, w = 3, h = 0.5,
                    name = "btn_add_favorite",
                    label = "Add Favorite",
                    bgcolor = "#2196F3"
                },
                {
                    x = 6.6, y = 6.2, w = 3, h = 0.5,
                    name = "btn_delete_favorite",
                    label = "Delete",
                    bgcolor = "#F44336"
                },
                {
                    x = 9.8, y = 6.2, w = 3, h = 0.5,
                    name = "btn_mp_connect",
                    label = "Direct Connect",
                    bgcolor = "#FF9800"
                },
                {
                    x = 12.3, y = 6.2, w = 3, h = 0.5,
                    name = "btn_refresh",
                    label = "Refresh",
                    bgcolor = "#607D8B"
                }
            }
        }
    }

    return tab
end

local function handle_buttons(fields)
    if fields.btn_join_server then
        local selected = menudata.favorites:get_current_index()
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            gamedata.address = server.address
            gamedata.port = server.port
            gamedata.selected_world = 0
            core.start()
        end
        return true
    end

    if fields.btn_add_favorite then
        local dlg = create_server_dlg()
        dlg:show()
        return true
    end

    if fields.btn_delete_favorite then
        local selected = menudata.favorites:get_current_index()
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            local dlg = create_delete_favorite_dlg(server)
            dlg:show()
        end
        return true
    end

    if fields.btn_mp_connect then
        local dlg = create_connect_dlg()
        dlg:show()
        return true
    end

    if fields.btn_refresh then
        core.handle_async("get_serverlist", {
            url = core.settings:get("serverlist_url") or 
                  "https://servers.sandboxy.org"
        }, function(result)
            if result and result.list then
                menudata.public_servers = result.list
                core.event_handler({
                    type = "serverlist_updated"
                })
            end
        end)
        return true
    end

    if fields.search_input then
        core.settings:set("serversearch", fields.search_input)
        return true
    end

    return false
end

local function on_change(type, old_index, new_index)
    if type == "ENTER" then
        local selected = menudata.favorites:get_current_index()
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            gamedata.address = server.address
            gamedata.port = server.port
            gamedata.selected_world = 0
            core.start()
        end
        return true
    end
    return false
end

return {
    name = "online",
    caption = "Play Online",
    get_formspec = get_formspec,
    handle_buttons = handle_buttons,
    on_change = on_change
}
