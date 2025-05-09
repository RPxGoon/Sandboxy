-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

-- Initialize UI constants
MAIN_TAB_W = 15.5
MAIN_TAB_H = 7.1
TABHEADER_H = 0.85
GAMEBAR_H = 1.25
GAMEBAR_OFFSET_DESKTOP = 0.375
GAMEBAR_OFFSET_TOUCH = 0.15

local menupath = core.get_mainmenu_path()
local basepath = core.get_builtin_path()
defaulttexturedir = core.get_texturepath_share() .. DIR_DELIM .. "base" ..
					DIR_DELIM .. "pack" .. DIR_DELIM

-- Load required modules
dofile(basepath .. "common" .. DIR_DELIM .. "menu.lua")
dofile(basepath .. "common" .. DIR_DELIM .. "filterlist.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "buttonbar.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "dialog.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "tabview.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "ui.lua")
dofile(menupath .. DIR_DELIM .. "async_event.lua")
dofile(menupath .. DIR_DELIM .. "common.lua")
dofile(menupath .. DIR_DELIM .. "serverlistmgr.lua")
dofile(menupath .. DIR_DELIM .. "game_theme.lua")

dofile(menupath .. DIR_DELIM .. "dlg_config_world.lua")
dofile(menupath .. DIR_DELIM .. "content" .. DIR_DELIM .. "init.lua")
dofile(basepath .. "common" .. DIR_DELIM .. "settings" .. DIR_DELIM .. "init.lua")
dofile(menupath .. DIR_DELIM .. "dlg_create_world.lua")
dofile(menupath .. DIR_DELIM .. "dlg_delete_content.lua")
dofile(menupath .. DIR_DELIM .. "dlg_delete_world.lua")
dofile(menupath .. DIR_DELIM .. "dlg_register.lua")
dofile(menupath .. DIR_DELIM .. "dlg_rename_modpack.lua")
dofile(menupath .. DIR_DELIM .. "dlg_version_info.lua")
dofile(menupath .. DIR_DELIM .. "dlg_reinstall_mtg.lua")
dofile(menupath .. DIR_DELIM .. "dlg_clients_list.lua")
dofile(menupath .. DIR_DELIM .. "dlg_server_list_mods.lua")

-- Load tab definitions
local tabs = {
	content  = dofile(menupath .. DIR_DELIM .. "tab_content.lua"),
	about = dofile(menupath .. DIR_DELIM .. "tab_about.lua"),
	local_game = dofile(menupath .. DIR_DELIM .. "tab_local.lua"),
	play_online = dofile(menupath .. DIR_DELIM .. "tab_online.lua")
}

--------------------------------------------------------------------------------
local function main_event_handler(tabview, event)
	if event == "MenuQuit" then
		core.close()
	end
	return true
end

--------------------------------------------------------------------------------
local function init_globals()
	-- Init gamedata
	gamedata.worldindex = 0

	menudata.worldlist = filterlist.create(
		core.get_worlds,
		compare_worlds,
		-- Unique id comparison function
		function(element, uid)
			return element.name == uid
		end,
		-- Filter function
		function(element, gameid)
			return element.gameid == gameid
		end
	)

	menudata.worldlist:add_sort_mechanism("alphabetic", sort_worlds_alphabetic)
	menudata.worldlist:set_sortmode("alphabetic")

	mm_game_theme.init()
	mm_game_theme.set_engine() -- This is just a fallback.

	-- Create main tabview with correct size format
	local tv_main = tabview_create("maintab", {x = MAIN_TAB_W, y = MAIN_TAB_H}, {x = 0, y = 0})

	tv_main:set_autosave_tab(true)
	
	-- Add tabs with correct size format
	for _, tab in pairs(tabs) do
		if tab.size then
			-- Convert from width/height to x/y if needed
			if tab.size.width and tab.size.height then
				tab.size = {x = tab.size.width, y = tab.size.height}
			end
		elseif tab.tabsize then
			-- Use tabsize if defined instead of size
			tab.size = tab.tabsize
		end
		tv_main:add(tab)
	end

	tv_main:set_global_event_handler(main_event_handler)
	tv_main:set_fixed_size(false)

	local last_tab = core.settings:get("maintab_LAST")
	if last_tab and tv_main.current_tab ~= last_tab then
		tv_main:set_tab(last_tab)
	end

	tv_main:set_end_button({
		icon = defaulttexturedir .. "settings_btn.png",
		label = fgettext("Settings"),
		name = "open_settings",
		on_click = function(tabview)
			local dlg = create_settings_dlg()
			dlg:set_parent(tabview)
			tabview:hide()
			dlg:show()
			return true
		end,
	})

	ui.set_default("maintab")
	tv_main:show()
	ui.update()

	check_reinstall_mtg()
	check_new_version()
end

assert(os.execute == nil)

-- Initialize core functions first
core.after = function(time, callback)
    if not callback or type(callback) ~= "function" then
        return
    end
    local job = {
        time = os.clock() + time,
        func = callback
    }
    table.insert(core.delayed_callbacks or {}, job)
end

-- Now load the rest of the menu system
dofile(core.get_mainmenu_path() .. DIR_DELIM .. "async_event.lua")

init_globals()

-- Sandboxy main menu

local menupath = core.get_mainmenu_path()
local modstore = menupath .. "modstore.json"

-- Global menu data
menu = {}
menu.id = "main"
menu.title = "Sandboxy"
menu.version = core.get_version()

function menu.init()
    menu.data = {}
    menu.clouds = true
    menu.node_highlighting = true
    menu.server_list = {}
    menu.selected_server = 0
    menu.favorites = {}
    menu.games = {}
    menu.mods = {}
    menu.world_list = {}
    menu.selected_world = 0
    menu.worldconfig = {}
end

-- Menu pages
menu.pages = {
    "header",
    "play",
    "multiplayer",
    "settings", 
    "mods",
    "texturepacks",
    "worlds",
    "credits"
}

-- Page handlers
menu.handle_play = function(...)
    -- Play button handler
end

menu.handle_multiplayer = function(...)
    -- Multiplayer button handler  
end

menu.handle_settings = function(...)
    -- Settings button handler
end

menu.handle_mods = function(...)
    -- Mods button handler
end

menu.handle_texturepacks = function(...)
    -- Texture packs button handler
end

menu.handle_worlds = function(...)
    -- Worlds button handler
end

menu.handle_credits = function(...)
    -- Credits button handler
end

-- Menu formspec
function menu.get_formspec()
    local formspec = "size[12,7]"
    formspec = formspec .. "background[0,0;12,7;menu_bg.png]"
    formspec = formspec .. "image[5,1;2,2;menu_logo.png]"
    formspec = formspec .. "label[5,3.2;Sandboxy " .. menu.version .. "]"
    
    -- Menu buttons
    local btn_y = 3.8
    for i, page in ipairs(menu.pages) do
        if page ~= "header" then
            formspec = formspec .. "button[4," .. btn_y .. ";4,0.8;" .. 
                      page .. ";" .. core.formspec_escape(page:gsub("^%l", string.upper)) .. "]"
            btn_y = btn_y + 0.9
        end
    end
    
    return formspec
end

-- Initialize menu when game starts
menu.init()

-- Register callbacks
core.register_on_receive_fields(function(player, formname, fields)
    if formname ~= "" then return end
    
    for page, handler in pairs(menu) do
        if fields[page] and type(handler) == "function" then
            handler(player, fields)
            return true
        end
    end
end)
