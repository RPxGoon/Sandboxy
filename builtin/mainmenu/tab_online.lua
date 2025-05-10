-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

-- Initialize menudata if not already done
if not menudata then menudata = {} end
if not menudata.favorites then
    menudata.favorites = {
        list = {},
        current_index = 0,
        get_list = function(self) return self.list end,
        get_current_index = function(self) return self.current_index end,
        set_current_index = function(self, index) self.current_index = index end
    }
end
if not menudata.public_servers then
    menudata.public_servers = {}
end

local function get_sorted_servers()
	local servers = {
		fav = {},
		public = {},
		incompatible = {}
	}

	local favs = {}
	if serverlistmgr and serverlistmgr.get_favorites then
		favs = serverlistmgr.get_favorites() or {}
	end
	local taken_favs = {}
	local result = {}
	if menudata and menudata.search_result then
		result = menudata.search_result
	elseif serverlistmgr and serverlistmgr.servers then
		result = serverlistmgr.servers
	end
	for _, server in ipairs(result or {}) do
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

	local favs = {}
	if serverlistmgr and serverlistmgr.get_favorites then
		favs = serverlistmgr.get_favorites() or {}
	end
	for _, fav in ipairs(favs) do
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
	if serverlistmgr and serverlistmgr.servers then
		for _, server in ipairs(serverlistmgr.servers) do
			if server.address == address and server.port == port then
				return server
			end
		end
	end
	
	local favs = {}
	if serverlistmgr and serverlistmgr.get_favorites then
		favs = serverlistmgr.get_favorites() or {}
	end
	for _, server in ipairs(favs) do
		if server.address == address and server.port == port then
			return server
		end
	end
end

-- Sandboxy multiplayer tab

local function get_formspec()
    -- Get server list safely
    local servers = get_sorted_servers()
    local selected_server = menudata.favorites:get_current_index() or 0
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
        local selected = menudata.favorites:get_current_index() or 0
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            if not server then return true end
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
        local selected = menudata.favorites:get_current_index() or 0
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            if not server then return true end
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
        -- Initialize required structures if they don't exist
        if not menudata then menudata = {} end
        if not menudata.favorites then
            menudata.favorites = {
                list = {},
                current_index = 0,
                get_list = function(self) return self.list end,
                get_current_index = function(self) return self.current_index end,
                set_current_index = function(self, index) self.current_index = index end
            }
        end
        
        -- Initialize serverlistmgr if not already done
        if not serverlistmgr then
            serverlistmgr = {
                servers = {},
                favorites = {},
                get_favorites = function() return serverlistmgr.favorites end
            }
        end
        
        core.handle_async("get_serverlist", {
            url = core.settings:get("serverlist_url") or 
                  "https://servers.sandboxy.org"
        }, function(result)
            if result and result.list then
                menudata.public_servers = result.list or {}
                -- Initialize serverlistmgr.servers if needed
                if not serverlistmgr.servers then
                    serverlistmgr.servers = {}
                end
                
                -- Update the server list
                for _, server in ipairs(menudata.public_servers) do
                    -- Add to serverlistmgr.servers
                    table.insert(serverlistmgr.servers, server)
                    
                    -- Add public servers to the favorites list if needed
                    if menudata.favorites and menudata.favorites.list then
                        table.insert(menudata.favorites.list, server)
                    end
                end
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
        local selected = menudata.favorites:get_current_index() or 0
        if selected > 0 then
            local server = menudata.favorites:get_list()[selected]
            if not server then return true end
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
