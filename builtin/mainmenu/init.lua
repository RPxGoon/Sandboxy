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

-- Initialize core globals with explicit declarations
_G.menudata = {}  -- Properly declare menudata as a global
_G.gamedata = {}  -- Properly declare gamedata as a global
_G.serverlistmgr = {}  -- Properly declare serverlistmgr as a global

-- Initialize core data structures
menudata.worldlist = nil  -- Will be initialized later
gamedata.worldindex = 0
serverlistmgr.servers = {}
serverlistmgr.favorites = {}
serverlistmgr.get_favorites = function() return serverlistmgr.favorites end
serverlistmgr.init_done = false

local menupath = core.get_mainmenu_path()
local basepath = core.get_builtin_path()
defaulttexturedir = core.get_texturepath_share() .. DIR_DELIM .. "base" ..
					DIR_DELIM .. "pack" .. DIR_DELIM
-- Ensure global texture directory is consistent throughout the application
_G.defaulttexturedir = defaulttexturedir

-- Load required modules
dofile(basepath .. "common" .. DIR_DELIM .. "menu.lua")
dofile(basepath .. "common" .. DIR_DELIM .. "filterlist.lua")

-- Load UI framework in the correct order (ui.lua must be before dialog.lua)
dofile(basepath .. "fstk" .. DIR_DELIM .. "ui.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "buttonbar.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "dialog.lua")
dofile(basepath .. "fstk" .. DIR_DELIM .. "tabview.lua")
dofile(menupath .. DIR_DELIM .. "async_event.lua")
dofile(menupath .. DIR_DELIM .. "common.lua")

-- Serverlistmgr is already initialized at the top of the file
-- No need to reinitialize it here

-- Now load the serverlistmgr after initializing required variables
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
    local_game = dofile(menupath .. DIR_DELIM .. "tab_local.lua"),
    multiplayer = {
        name = "multiplayer",
        caption = "Multiplayer",
        get_formspec = function()
            return {
                name = "multiplayer",
                caption = "Multiplayer",
                tabsize = {x = 15.5, y = 7},
                content = {
                    background = "menu_bg.png",
                    containers = {
                        {
                            x = 0.2, y = 0.2, w = 15.1, h = 6.3,
                            name = "multiplayer_info",
                            bgcolor = "#FFFFFF",
                            style = "container",
                            elements = {
                                {
                                    type = "label",
                                    x = 0.2, y = 0.2,
                                    label = "Multiplayer Not Configured",
                                    style = "label_header"
                                },
                                {
                                    type = "textarea",
                                    x = 0.2, y = 1.0, w = 14.7, h = 4.0,
                                    name = "multiplayer_message",
                                    label = "",
                                    default = "Multiplayer features are currently disabled.\n\nServer configuration needs to be set up before multiplayer features can be enabled.",
                                    bgcolor = "#F5F5F5"
                                }
                            }
                        }
                    }
                }
            }
        end,
        handle_buttons = function() return false end
    },
    content = {
        name = "content",
        caption = "Content",
        get_formspec = function()
            return {
                name = "content",
                caption = "Content",
                tabsize = {x = 15.5, y = 7},
                content = {
                    background = "menu_bg.png",
                    buttons = {
                        {
                            bgcolor = "#1976D2",
                            h = 0.5,
                            label = "Sandboxy Content Browser",
                            name = "header",
                            style = "header",
                            w = 15.5,
                            x = 0,
                            y = 0
                        },
                        {
                            x = 0.3, y = 6.8,
                            w = 2.5, h = 0.5,
                            name = "btn_install",
                            label = "Install",
                            bgcolor = "#4CAF50"
                        },
                        {
                            x = 3.0, y = 6.8,
                            w = 2.5, h = 0.5,
                            name = "btn_download",
                            label = "Download",
                            bgcolor = "#2196F3"
                        },
                        {
                            x = 5.7, y = 6.8,
                            w = 2.5, h = 0.5,
                            name = "btn_uninstall",
                            label = "Uninstall",
                            bgcolor = "#F44336"
                        }
                    },
                    containers = {
                        {
                            x = 0.2, y = 1.0, w = 7.5, h = 5.7,
                            bgcolor = "#FFFFFF",
                            style = "box",
                            name = "content_list",
                            elements = {
                                {
                                    type = "list",
                                    x = 0.2, y = 0.2,
                                    w = 7.1, h = 5.3,
                                    name = "pkg_list",
                                    bgcolor = "#F5F5F5"
                                }
                            }
                        },
                        {
                            x = 8.0, y = 1.0, w = 7.3, h = 5.7,
                            bgcolor = "#FFFFFF",
                            style = "box",
                            name = "content_details",
                            elements = {
                                {
                                    type = "textarea",
                                    x = 0.2, y = 0.2,
                                    w = 6.9, h = 5.3,
                                    name = "pkg_details",
                                    label = "",
                                    default = "Select a content package to view details",
                                    bgcolor = "#F5F5F5"
                                }
                            }
                        }
                    },
                    search = {
                        bgcolor = "#FFFFFF",
                        default = "Search...",
                        h = 0.4,
                        label = "",
                        name = "search",
                        w = 7.1,
                        x = 8.1,
                        y = 0.2
                    }
                }
            }
        end,
        handle_buttons = function(fields)
            if fields.search then
                -- Handle search
                return true
            end
            
            if fields.pkg_list then
                -- Handle package selection
                return true
            end
            
            if fields.btn_install then
                -- Handle install
                return true
            end
            
            if fields.btn_download then
                -- Handle download
                return true
            end
            
            if fields.btn_uninstall then
                -- Handle uninstall
                return true
            end
            
            return false
        end
    },
    about = {
        name = "about",
        caption = "About",
        get_formspec = function()
            return {
                name = "about",
                caption = "About",
                tabsize = {x = 15.5, y = 7},
                content = {
                    background = "menu_bg.png",
                    containers = {
                        {
                            x = 0.2, y = 0.2, w = 15.1, h = 6.3,
                            name = "about_container",
                            bgcolor = "#FFFFFF",
                            style = "container",
                            elements = {
                                {
                                    type = "label",
                                    x = 0.2, y = 0.2,
                                    label = "Sandboxy",
                                    style = "label_header"
                                },
                                {
                                    type = "textarea",
                                    x = 0.2, y = 0.8, w = 14.7, h = 4.5,
                                    name = "about_text",
                                    label = "",
                                    default = 
[[Sandboxy 5.12.0-dev

A free open-source voxel game engine with powerful modding capabilities.

Website: https://www.sandboxy.org
Source code: https://github.com/sandboxyorg/sandboxy
Forums: https://forum.sandboxy.org

Contributors
---------------
See our GitHub repository for a full list of contributors.

License
---------
Licensed under GNU LGPL v2.1 or later.
See LICENSE.txt and COPYING.LESSER for more details.

Credits
---------
- Original game engine based on Minetest
- Textures: CC BY-SA 3.0
- Sounds: CC BY 3.0
- Font: Arimo and Cousine (Apache License 2.0)]],
                                    bgcolor = "#F5F5F5"
                                },
                                {
                                    type = "button",
                                    x = 12, y = 5.5, w = 3, h = 0.5,
                                    name = "btn_credits",
                                    label = "View Credits",
                                    bgcolor = "#2196F3"
                                }
                            }
                        }
                    }
                }
            }
        end,
        handle_buttons = function(fields)
            if fields.btn_credits then
                -- Could implement a more detailed credits dialog here
                return true
            end
            return false
        end
    }
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
-- gamedata and menudata are already initialized at the top of the file
-- Just update any properties that might have changed
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
		local tab_copy = {
			name = tab.name,
			caption = tab.caption,
			cbf_formspec = tab.get_formspec,
			cbf_button_handler = tab.handle_buttons,
			cbf_events = tab.handle_events,
			size = tab.tabsize -- Map tabsize to size as expected by tabview
		}
		tv_main:add(tab_copy)
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

-- Initialize event handling functions
core.receive_fields_callbacks = {}
core.register_on_receive_fields = function(callback)
    if callback and type(callback) == "function" then
        table.insert(core.receive_fields_callbacks, callback)
    end
end

-- Function to process form field events
core.handle_received_fields = function(player, formname, fields)
    for _, callback in ipairs(core.receive_fields_callbacks) do
        if callback(player, formname, fields) then
            return true
        end
    end
    return false
end

-- Now load the rest of the menu system
dofile(core.get_mainmenu_path() .. DIR_DELIM .. "async_event.lua")

init_globals()
