-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later


local current_game, singleplayer_refresh_gamebar

-- Import dialog modules with error handling
local create_create_world_dlg, create_delete_world_dlg, create_configure_world_dlg

-- Import directly from the global scope where these functions were defined
if _G.create_create_world_dlg then
    create_create_world_dlg = _G.create_create_world_dlg
    core.log("info", "Using global create_create_world_dlg")
else
    -- Safely load dialog module functions
    local function safe_load_dialog(path)
        local status, result = pcall(dofile, path)
        if not status then
            core.log("error", "Failed to load dialog module: " .. path .. " - " .. tostring(result))
            return nil
        end
        if type(result) == "function" then
            return result
        else
            -- Module was loaded, but we need to extract the function
            return _G.create_create_world_dlg
        end
    end
    
    -- Load dialog modules with error handling and force direct path
    local mainmenu_path = core.get_mainmenu_path()
    create_create_world_dlg = safe_load_dialog(mainmenu_path .. DIR_DELIM .. "dlg_create_world.lua") or 
                             dofile(mainmenu_path .. DIR_DELIM .. "dlg_create_world.lua")
    create_delete_world_dlg = safe_load_dialog(mainmenu_path .. DIR_DELIM .. "dlg_delete_world.lua")
    create_configure_world_dlg = safe_load_dialog(mainmenu_path .. DIR_DELIM .. "dlg_config_world.lua")
end

-- Add debugging function to track world list issues
local function debug_log(msg, ...)
    core.log("action", "[tab_local] " .. string.format(msg, ...))
end


-- Fallback if filterlist methods are missing
local selected_world_index = 1

-- World list comparison and filtering functions
local function compare_worlds(a, b)
    return a.name:lower() < b.name:lower()
end

local function sort_worlds_alphabetic(worldlist)
    table.sort(worldlist, compare_worlds)
end

-- World filtering based on game ID
local function filter_worlds(world, gameid)
    -- If no game is selected, show all worlds
    if not gameid then
        return true
    end
    -- Show worlds that match the selected game
    -- Note: Some worlds might have slightly different game IDs but still be compatible
    return world.gameid == gameid or world.gameid:match("^" .. gameid .. ".*$")
end

-- Function to refresh world list and maintain selection
local function refresh_worldlist()
    if not menudata.worldlist then
        debug_log("Creating new world list")
        -- Create world list with proper error handling
        local worlds = core.get_worlds()
        if type(worlds) ~= "table" then
            debug_log("Error: core.get_worlds() returned invalid type: %s", type(worlds))
            worlds = {}
        end
        
        debug_log("Found %d worlds in filesystem", #worlds)
        
        -- Create filterlist directly
        local new_list = filterlist.create(
            function() return worlds end,
            compare_worlds,
            function(element, uid) return element.name == uid end,
            filter_worlds
        )
        
        -- Always add our own set_current_index method to ensure it works
        new_list.set_current_index = function(self, index)
            -- Store in local variable
            selected_world_index = index
            debug_log("Set world index to: %d", index)
            
            -- Store in settings
            core.settings:set("mainmenu_last_selected_world", index)
            
            -- Store in the object itself
            if type(self) == "table" then
                self.m_current_index = index
            end
            
            return true
        end
        
        -- Add get_current_index if not present
        if not new_list.get_current_index then
            new_list.get_current_index = function(self)
                if self.m_current_index then 
                    return self.m_current_index
                end
                return selected_world_index
            end
        end
        
        -- Setup sorting
        new_list:add_sort_mechanism("alphabetic", sort_worlds_alphabetic)
        new_list:set_sortmode("alphabetic")
        
        menudata.worldlist = new_list
    end

    debug_log("Refreshing world list")
    
    -- Refresh the list with error handling
    local success, err = pcall(function()
        menudata.worldlist:refresh()
    end)
    
    if not success then
        debug_log("Error refreshing world list: %s", tostring(err))
        -- Create a new list if refresh fails
        menudata.worldlist = nil
        return refresh_worldlist()
    end
    
    local list = menudata.worldlist:get_list()
    debug_log("Found %d worlds", #list)
    
    -- Reapply game filtering
    local game = current_game()
    if game then
        debug_log("Filtering for game: %s", game.id)
        menudata.worldlist:set_filtercriteria(game.id)
    end
    
    -- Log filtered results
    list = menudata.worldlist:get_list()
    debug_log("After filtering: %d worlds", #list)
    
    -- Get saved selection from settings
    local saved_index = tonumber(core.settings:get("mainmenu_last_selected_world"))
    local current = selected_world_index
    
    -- Use saved index or current if valid, otherwise default to 1
    if saved_index and saved_index > 0 and saved_index <= #list then
        current = saved_index
    elseif not (current > 0 and current <= #list) and #list > 0 then
        current = 1
    end
    
    -- Set the index directly
    if current > 0 and current <= #list then
        debug_log("Setting selection to index %d", current)
        menudata.worldlist:set_current_index(current)
    end
    
    return true
}
        
        -- Now safely proceed with selection
        local list_size = menudata.worldlist:size()
        local last_selected = menudata.worldlist:get_current_index()
        
        if last_selected and last_selected > 0 and last_selected <= list_size then
            menudata.worldlist:set_current_index(last_selected)
            debug_log("Restored selection to index %d", last_selected)
        elseif list_size > 0 then
            menudata.worldlist:set_current_index(1)
            debug_log("Set selection to first world")
        end
    end
    
    -- Try to set selection and handle any errors
    local status, err = pcall(safe_set_selection)
    if not status then
        debug_log("Error setting world selection: %s", tostring(err))
        
        -- Fallback to direct index selection for UI
        selected_world_index = 1
    end
    
    return true
end

-- Helper function for creating and showing dialogs
local function create_and_show_dialog(dialog_func, parent, ...)
    if type(dialog_func) ~= "function" then
        core.log("error", "Dialog creation function not found")
        gamedata.errormessage = "Dialog creation function not available"
        return false
    end
    
    -- Use pcall to catch any errors during dialog creation
    local success, dlg = pcall(dialog_func, ...)
    if not success then
        core.log("error", "Error creating dialog: " .. tostring(dlg))
        gamedata.errormessage = "Failed to create dialog: " .. tostring(dlg)
        return false
    end
    
    if dlg and type(dlg) == "table" and type(dlg.set_parent) == "function" then
        dlg:set_parent(parent)
        parent:hide()
        dlg:show()
        return true
    else
        core.log("error", "Invalid dialog object returned")
        gamedata.errormessage = "Dialog creation failed - invalid dialog object"
        return false
    end
end
local valid_disabled_settings = {
	["enable_damage"]=true,
	["creative_mode"]=true,
	["enable_server"]=true,
}

-- Name and port stored to persist when updating the formspec
local current_name = core.settings:get("name")
local current_port = core.settings:get("port")

-- Currently chosen game in gamebar for theming and filtering
function current_game()
	local gameid = core.settings:get("menu_last_game")
	local game = gameid and pkgmgr.find_by_gameid(gameid)
	-- Fall back to first game installed if one exists.
	if not game and #pkgmgr.games > 0 then

		-- If devtest is the first game in the list and there is another
		-- game available, pick the other game instead.
		local picked_game
		if pkgmgr.games[1].id == "devtest" and #pkgmgr.games > 1 then
			picked_game = 2
		else
			picked_game = 1
		end

		game = pkgmgr.games[picked_game]
		gameid = game.id
		core.settings:set("menu_last_game", gameid)
	end

    -- Ensure world list is filtered for the current game if it exists
    if game and menudata.worldlist then
        menudata.worldlist:set_filtercriteria(game.id)
    end

	return game
end

-- Apply menu changes from given game
function apply_game(game)
    core.settings:set("menu_last_game", game.id)
    
    -- Ensure world list exists before trying to filter
    if not menudata.worldlist then
        menudata.worldlist = filterlist.create(
            function()
                local worlds = core.get_worlds()
                if type(worlds) ~= "table" then
                    core.log("error", "core.get_worlds() returned invalid type")
                    return {}
                end
                return worlds
            end,
            compare_worlds,
            function(element, uid) 
                return element.name == uid 
            end,
            filter_worlds
        )
        menudata.worldlist:add_sort_mechanism("alphabetic", sort_worlds_alphabetic)
        menudata.worldlist:set_sortmode("alphabetic")
    end
    
    -- Apply filtering and refresh
    menudata.worldlist:set_filtercriteria(game.id)
    menudata.worldlist:refresh()  -- Add explicit refresh
    refresh_worldlist()           -- Keep existing refresh for selection handling
    
    -- Update theme
    mm_game_theme.set_game(game)
    
    -- Maintain selection if possible
    local index = filterlist.get_current_index(menudata.worldlist,
        tonumber(core.settings:get("mainmenu_last_selected_world")))
    if not index or index < 1 then
        local selected = core.get_textlist_index("sp_worlds")
        if selected and selected <= menudata.worldlist:size() then
            index = selected
        else
            index = menudata.worldlist:size() > 0 and 1 or nil
        end
    end
    
    if index then
        menudata.worldlist:set_current_index(index)
        menu_worldmt_legacy(index)
    end
end

function singleplayer_refresh_gamebar()

	local old_bar = ui.find_by_name("game_button_bar")
	if old_bar ~= nil then
		old_bar:delete()
	end

	-- Hide gamebar if no games are installed
	if #pkgmgr.games == 0 then
		return false
	end

	local function game_buttonbar_button_handler(fields)
		for _, game in ipairs(pkgmgr.games) do
			if fields["game_btnbar_" .. game.id] then
				apply_game(game)
				return true
			end
		end
	end

	local TOUCH_GUI = core.settings:get_bool("touch_gui")

	local gamebar_pos_y = MAIN_TAB_H
		+ TABHEADER_H -- tabheader included in formspec size
		+ (TOUCH_GUI and GAMEBAR_OFFSET_TOUCH or GAMEBAR_OFFSET_DESKTOP)

	local btnbar = buttonbar_create(
			"game_button_bar",
			{x = 0, y = gamebar_pos_y},
			{x = MAIN_TAB_W, y = GAMEBAR_H},
			"#000000",
			game_buttonbar_button_handler)

	for _, game in ipairs(pkgmgr.games) do
		local btn_name = "game_btnbar_" .. game.id

		local image = nil
		local text = nil
		local tooltip = core.formspec_escape(game.title)

		if (game.menuicon_path or "") ~= "" then
			image = core.formspec_escape(game.menuicon_path)
		else
			local part1 = game.id:sub(1,5)
			local part2 = game.id:sub(6,10)
			local part3 = game.id:sub(11)

			text = part1 .. "\n" .. part2
			if part3 ~= "" then
				text = text .. "\n" .. part3
			end
		end
		btnbar:add_button(btn_name, text, image, tooltip)
	end

	local plus_image = core.formspec_escape(defaulttexturedir .. "plus.png")
	btnbar:add_button("game_open_cdb", "", plus_image, fgettext("Install games from ContentDB"))
	return true
end

local function get_disabled_settings(game)
	if not game then
		return {}
	end

	local gameconfig = Settings(game.path .. "/game.conf")
	local disabled_settings = {}
	if gameconfig then
		local disabled_settings_str = (gameconfig:get("disabled_settings") or ""):split()
		for _, value in pairs(disabled_settings_str) do
			local state = false
			value = value:trim()
			if string.sub(value, 1, 1) == "!" then
				state = true
				value = string.sub(value, 2)
			end
			if valid_disabled_settings[value] then
				disabled_settings[value] = state
			else
				core.log("error", "Invalid disabled setting in game.conf: "..tostring(value))
			end
		end
	end
	return disabled_settings
end

-- Sandboxy local game tab

-- Define global texture directory
defaulttexturedir = core.get_texturepath_share() .. DIR_DELIM .. "base" .. DIR_DELIM .. "pack" .. DIR_DELIM

local function get_formspec()
    -- Ensure texture directory is set only once
    if not defaulttexturedir or defaulttexturedir == "" then
        defaulttexturedir = core.get_texturepath_share() .. DIR_DELIM .. "base" .. DIR_DELIM .. "pack" .. DIR_DELIM
        core.log("info", "Setting texture directory: " .. defaulttexturedir)
    end
    
    -- Ensure world list is initialized
    debug_log("Refreshing formspec, checking world list initialization")
    if not menudata.worldlist then
        menudata.worldlist = filterlist.create(
            function()
                local worlds = core.get_worlds()
                if type(worlds) ~= "table" then
                    core.log("error", "core.get_worlds() returned " .. type(worlds))
                    return {}
                end
                return worlds
            end,
            compare_worlds,
            function(element, uid) 
                return element.name == uid 
            end,
            filter_worlds  -- Use our filter function
        )
        menudata.worldlist:add_sort_mechanism("alphabetic", sort_worlds_alphabetic)
        menudata.worldlist:set_sortmode("alphabetic")
        
        -- Set initial filter based on current game
        local game = current_game()
        if game then
            menudata.worldlist:set_filtercriteria(game.id)
        end
    end

    -- Get current world list
    local world_list = menudata.worldlist:get_list()
    local selected = menudata.worldlist:get_current_index()
    
    -- Debug world list state
    debug_log("World list status:")
    debug_log("- Number of worlds: %d", #world_list)
    for i, world in ipairs(world_list) do
        debug_log("- World %d: %s (game: %s)", i, world.name, world.gameid)
    end
    
    -- Debug game selection state
    local game = current_game()
    if game then
        debug_log("Current game: %s", game.id)
    else
        debug_log("No game selected")
    end
    
    -- Create basic formspec layout
    local formspec = "size[12,6.5]" ..
                     "bgcolor[#333333;true]" ..  -- Use solid background
                     "box[0,0;12,6.5;#222222]" ..  -- Main background
                     
                     -- World list with proper formspec syntax
                     "label[0.25,0.1;Select World]" ..
                     "textlist[0.25,0.5;5.5,5;world_list;"
    
    -- Build world list with proper format
    if #world_list > 0 then
        local items = {}
        for i, world in ipairs(world_list) do
            items[i] = world.name  -- Don't escape names in the array
        end
        -- Escape the entire string at once
        formspec = formspec .. core.formspec_escape(table.concat(items, ","))
    else
        formspec = formspec .. "No worlds available"
    end
    
    -- Add selection and transparency
    formspec = formspec .. ";" .. 
        tostring(selected or 1) .. ";" ..  -- Current selection
        "false" ..                         -- Not transparent
        "]"                               -- Close textlist
    
    -- Add world info and controls on the right
    if selected and selected > 0 and selected <= #world_list then
        local world = world_list[selected]
        local game = pkgmgr.find_by_gameid(world.gameid)
        local game_name = game and (game.title or game.id) or world.gameid
        
        formspec = formspec ..
            -- World info
            "label[6,0.5;World Info:]" ..
            "label[6,1;Name: " .. core.formspec_escape(world.name) .. "]" ..
            "label[6,1.5;Game: " .. core.formspec_escape(game_name) .. "]" ..
            
            -- Game settings
            "label[6,2.5;Game Settings:]" ..
            "checkbox[6,3;cb_creative;Creative Mode;" .. 
                (core.settings:get_bool("creative_mode") and "true" or "false") .. "]" ..
            "checkbox[6,3.5;cb_damage;Enable Damage;" .. 
                (core.settings:get_bool("enable_damage") and "true" or "false") .. "]" ..
            -- Action buttons
            "button[6,4.5;5.5,0.8;btn_play;Play Game]" ..
            "button[6,5.5;2.5,0.8;btn_configure_world;Configure]" ..
            "button[9,5.5;2.5,0.8;btn_delete_world;Delete]"
    else
        -- No world selected or empty list
        formspec = formspec ..
            "label[6,0.5;Select a world to play or create a new one]" ..
            "button[6,5.5;5.5,0.8;btn_new_world;Create New World]"
    end
    
    return formspec
end

-- Store reference to this tab for proper dialog parent/child relationship
local tab_local

-- Direct world launching function - simplified robust version
local function launch_world(world_index, gui_settings)
    debug_log("LAUNCH: Starting world launch process for index %d", world_index)
    
    -- Verify world list exists or try to create it
    if not menudata.worldlist then
        if not refresh_worldlist() then
            gamedata.errormessage = "Failed to initialize world list"
            return false
        end
    end
    
    local list = menudata.worldlist:get_list()
    
    -- Validate world index
    if not list or world_index <= 0 or world_index > #list then
        debug_log("LAUNCH ERROR: Invalid world index: %d (max: %d)", 
                 world_index, list and #list or 0)
        gamedata.errormessage = "Invalid world selection"
        return false
    end
    
    -- Get world data
    local world = list[world_index]
    debug_log("LAUNCH: Selected world '%s' (game: %s, path: %s)", 
              world.name, world.gameid, world.path)
    
    -- Get the game information
    local game = pkgmgr.find_by_gameid(world.gameid)
    if not game then
        debug_log("Cannot find game: %s", world.gameid)
        gamedata.errormessage = "Cannot find game '" .. world.gameid .. "'"
        return false
    end
    
    -- Set up environment for launch
    debug_log("Launching world: %s (game: %s)", world.name, world.gameid)
    
    -- Ensure world settings are properly synchronized
    local worldconfig = pkgmgr.get_worldconfig(world.path)
    if worldconfig then
        debug_log("LAUNCH: World config loaded from %s", world.path)
        if worldconfig.creative_mode then
            core.settings:set("creative_mode", worldconfig.creative_mode)
            debug_log("LAUNCH: Setting creative_mode from world.mt: %s", worldconfig.creative_mode)
        else
            -- Set default values for devtest game
            if world.gameid == "devtest" then
                core.settings:set("creative_mode", "true")
                debug_log("LAUNCH: Setting default creative_mode=true for devtest")
            end
        end
        if worldconfig.enable_damage then
            core.settings:set("enable_damage", worldconfig.enable_damage)
            debug_log("LAUNCH: Setting enable_damage from world.mt: %s", worldconfig.enable_damage)
        else
            -- Set default values for devtest game
            if world.gameid == "devtest" then
                core.settings:set("enable_damage", "false") 
                debug_log("LAUNCH: Setting default enable_damage=false for devtest")
            end
        end
    else
        debug_log("LAUNCH: No world config found at %s", world.path)
        -- Create minimal world.mt file if it doesn't exist
        local filename = world.path .. DIR_DELIM .. "world.mt"
        if not core.file_exists(filename) then
            debug_log("LAUNCH: Creating minimal world.mt file")
            local worldfile = Settings(filename)
            worldfile:set("backend", "sqlite3")
            worldfile:set("player_backend", "files")
            worldfile:set("auth_backend", "files")
            worldfile:set("gameid", world.gameid)
            if world.gameid == "devtest" then
                worldfile:set("creative_mode", "true")
                worldfile:set("enable_damage", "false")
            end
            worldfile:write()
            debug_log("LAUNCH: Created default world.mt file")
        end
    end
    
    -- Ensure world path is absolute and exists
    if not world.path:find("^/") then
        -- Convert to absolute path if needed
        world.path = core.get_user_path() .. DIR_DELIM .. "worlds" .. DIR_DELIM .. world.name
        debug_log("LAUNCH: Converted to absolute path: %s", world.path)
    end
    
    -- Verify world directory exists
    if not core.file_exists(world.path) then
        debug_log("LAUNCH ERROR: World path doesn't exist: %s", world.path)
        gamedata.errormessage = "World directory not found: " .. world.name
        return false
    end
    
    -- Apply GUI settings if provided (from checkboxes)
    if gui_settings then
        if gui_settings.creative_mode ~= nil then
            core.settings:set_bool("creative_mode", gui_settings.creative_mode)
            debug_log("LAUNCH: Applied creative_mode from UI: %s", 
                      tostring(gui_settings.creative_mode))
        end
        
        if gui_settings.enable_damage ~= nil then
            core.settings:set_bool("enable_damage", gui_settings.enable_damage)
            debug_log("LAUNCH: Applied enable_damage from UI: %s", 
                      tostring(gui_settings.enable_damage))
        end
    end
    
    -- Set world and game context
    core.settings:set("menu_last_game", game.id)
    debug_log("LAUNCH: Set menu_last_game to %s", game.id)
    
    core.settings:set("mainmenu_last_selected_world", world_index)
    debug_log("LAUNCH: Set mainmenu_last_selected_world to %d", world_index)
    
    -- Set player name if not already set
    if core.settings:get("name") == "" then
        core.settings:set("name", "singleplayer")
        debug_log("LAUNCH: Set default player name to 'singleplayer'")
    end
    
    -- Configure world parameters
    if type(menu_worldmt_legacy) == "function" then
        pcall(menu_worldmt_legacy, world_index)
        debug_log("LAUNCH: Applied legacy world settings")
    end
    
    -- Force save any settings we've changed
    core.settings:write()
    debug_log("LAUNCH: Saved settings")
    
    -- Set game data for the engine
end

local function handle_buttons(fields)
    -- Ensure world list exists
    if not menudata.worldlist then
        if not refresh_worldlist() then
            gamedata.errormessage = "Failed to initialize world list"
            return true
        end
    end

    -- Handle game selection changes
    if fields.game_dropdown then
        local selected_idx = tonumber(fields.game_dropdown)
        if selected_idx and selected_idx > 0 and selected_idx <= #pkgmgr.games then
            local game = pkgmgr.games[selected_idx]
            if game then
                -- Update game selection and refresh world filtering
                core.settings:set("menu_last_game", game.id)
                menudata.worldlist:set_filtercriteria(game.id)
                
                -- Apply game settings and update the menu
                apply_game(game)
                return true
            end
        end
    end

    -- Handle world list selection change
    if fields.world_list then
        local event = core.explode_table_event(fields.world_list)
        debug_log("World list event: type=%s, row=%s", event.type, event.row)
        
        local world_index = tonumber(event.row)
        if world_index then
            debug_log("World selection event: type=%s index=%d", event.type, world_index)
        end
        
        if event.type == "CHG" then
            local world_index = tonumber(event.row)
            if world_index and world_index > 0 then
                debug_log("Setting world selection to index: %d", world_index)
                
                -- Store the selected index both in our variable and try the method
                selected_world_index = world_index
                
                -- Safely try to set current index if the method exists
                if type(menudata.worldlist.set_current_index) == "function" then
                    local status, err = pcall(function()
                        menudata.worldlist:set_current_index(world_index)
                    end)
                    
                    if not status then
                        debug_log("Error setting world index: %s", tostring(err))
                    end
                end
                
                -- Always store in settings
                core.settings:set("mainmenu_last_selected_world", world_index)
                
                -- Call legacy function if available
                if type(menu_worldmt_legacy) == "function" then
                    menu_worldmt_legacy(world_index)
                end
                
                return true
            end
        elseif event.type == "DCL" then
            local world_index = tonumber(event.row)
            if world_index and world_index > 0 then
                local world_list = menudata.worldlist:get_list()
                if world_index <= #world_list then
                    local world = world_list[world_index]
                    debug_log("Double-click on world: %s", world.name)
                    
                    -- Set game context
                    local game = pkgmgr.find_by_gameid(world.gameid)
                    if game then
                        debug_log("Starting game with index %d, game %s", world_index, game.id)
                        menudata.worldlist:set_current_index(world_index)
                        gamedata.selected_world = world_index
                        gamedata.selected_game = game.id
                        core.start()
                    else
                        gamedata.errormessage = "Cannot find game '" .. world.gameid .. "'"
                    end
                end
            end
            return true
        end
    end
    
    -- Handle play button (and ignore disabled button clicks)
    if fields.btn_play and not fields.btn_play_disabled then
        debug_log("BUTTON CLICK: Play button clicked")
        
        -- Get the selected world index from either the method or our backup variable
        local selected
        
        if type(menudata.worldlist.get_current_index) == "function" then
            local status, result = pcall(function()
                local idx = menudata.worldlist:get_current_index()
                debug_log("Got current index from filterlist: %s", tostring(idx))
                return idx
            end)
            
            if status and result and result > 0 then
                selected = result
                debug_log("Using filterlist index: %d", selected)
            else
                selected = selected_world_index
                debug_log("Using fallback index: %d", selected)
            end
        else
            selected = selected_world_index
            debug_log("Using direct index: %d", selected)
        end
        
        debug_log("BUTTON CLICK: Selected world index for launch: %d", selected)
        
        if selected > 0 then
            local world_list = menudata.worldlist:get_list()
            if selected <= #world_list then
                debug_log("BUTTON CLICK: Using direct launch function for world index %d", selected)
                
                -- Get the GUI settings from checkboxes if they exist
                local gui_settings = {}
                if fields.cb_creative ~= nil then
                    gui_settings.creative_mode = fields.cb_creative == "true"
                end
                if fields.cb_damage ~= nil then
                    gui_settings.enable_damage = fields.cb_damage == "true"
                end
                
                -- Use our direct launching function
                local success = launch_world(selected, gui_settings)
                
                if not success then
                    debug_log("BUTTON CLICK ERROR: Failed to launch world %d", selected)
                    -- Error message already set by launch_world
                else
                    debug_log("BUTTON CLICK: Successfully launched world %d", selected)
                end
                
                -- Always return true to indicate we've handled the button press
                return true
            else
                debug_log("BUTTON CLICK ERROR: Selected index %d out of bounds (max: %d)", 
                          selected, #world_list)
                gamedata.errormessage = "Invalid world selection"
                return true
            end
        else
            debug_log("BUTTON CLICK ERROR: No world selected (index=%d)", selected)
            gamedata.errormessage = "Please select a world first"
            return true
        end
                
                -- Ensure world settings are properly synchronized
                local worldconfig = pkgmgr.get_worldconfig(world.path)
                if worldconfig then
                    if worldconfig.creative_mode then
                        core.settings:set("creative_mode", worldconfig.creative_mode)
                        debug_log("Setting creative_mode from world.mt: %s", worldconfig.creative_mode)
                    end
                    if worldconfig.enable_damage then
                        core.settings:set("enable_damage", worldconfig.enable_damage)
                        debug_log("Setting enable_damage from world.mt: %s", worldconfig.enable_damage)
                    end
                end
                
                -- Apply game settings
                core.settings:set("menu_last_game", game.id)  -- Use game.id instead of world.gameid
                
        return true
    end

    -- Handle world management buttons
    if fields.btn_new_world then
        core.log("info", "Creating new world dialog")
        
        -- Ensure the create_world_dlg module is loaded
        if not create_create_world_dlg then
            core.log("warning", "Loading create world dialog module")
            local mainmenu_path = core.get_mainmenu_path()
            local dlg_path = mainmenu_path .. DIR_DELIM .. "dlg_create_world.lua"
            
            -- Load the module directly with explicit error handling
            -- Also refresh the world list after dialog operations
            refresh_worldlist()
            
            local status, loaded_module = pcall(dofile, dlg_path)
            if status then
                if type(loaded_module) == "function" then
                    create_create_world_dlg = loaded_module
                    core.log("info", "Successfully loaded create_world_dlg as function")
                elseif _G.create_create_world_dlg then
                    create_create_world_dlg = _G.create_create_world_dlg
                    core.log("info", "Successfully loaded create_world_dlg from global scope")
                end
            else
                core.log("error", "Failed to load dialog: " .. tostring(loaded_module))
            end
        end
        
        if not create_create_world_dlg then
            core.log("error", "Create world dialog module not available")
            gamedata.errormessage = "Failed to load world creation dialog"
            return true
        end
        
        -- Create dialog with exception handling
        local status, dlg = pcall(create_create_world_dlg)
        if not status then
            core.log("error", "Exception while creating dialog: " .. tostring(dlg))
            gamedata.errormessage = "Error creating world dialog: " .. tostring(dlg)
            return true
        end
        
        -- Create and show the dialog with proper parent-child relationship
        if dlg then
            -- Make sure parent is properly set
            if type(dlg.set_parent) == "function" then
                dlg:set_parent(tab_local)
                tab_local:hide()
                dlg:show()
                return true
            else
                core.log("error", "Invalid dialog object - missing set_parent method")
                gamedata.errormessage = "Invalid dialog object returned"
                return true
            end
        else
            core.log("error", "Failed to create world dialog instance")
            gamedata.errormessage = "Failed to create world dialog"
            return true
        end
    end
    -- Refresh world list after any dialog operations
    if menudata.worldlist then
        refresh_worldlist()
    else
        debug_log("Creating world list since it doesn't exist")
        refresh_worldlist()
    end
    
    if fields.btn_delete_world then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world = menudata.worldlist:get_list()[selected]
            if world then
                if not create_delete_world_dlg then
                    core.log("error", "Delete world dialog module not loaded properly")
                    gamedata.errormessage = "Delete world dialog not available"
                    return true
                end
                core.log("info", "Creating delete world dialog for: " .. world.name)
                -- Pass the world name and index to the delete world dialog
                return create_and_show_dialog(create_delete_world_dlg, tab_local, world.name, selected) or true
            end
        end
        return true
    end
    
    if fields.btn_configure_world then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world = menudata.worldlist:get_list()[selected]
            if world then
                if not create_configure_world_dlg then
                    core.log("error", "Configure world dialog module not loaded properly")
                    gamedata.errormessage = "Configure world dialog not available"
                    return true
                end
                core.log("info", "Creating configure world dialog for: " .. world.name)
                return create_and_show_dialog(create_configure_world_dlg, tab_local, world) or true
            end
        end
        return true
    end
    
    -- Handle checkboxes
    if fields.cb_creative ~= nil then
        -- Convert string "true"/"false" to boolean for settings
        core.settings:set_bool("creative_mode", fields.cb_creative == "true")
        -- Also update the world.mt file for the selected world
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world_list = menudata.worldlist:get_list()
            if selected <= #world_list then
                local world = world_list[selected]
                local filename = world.path .. DIR_DELIM .. "world.mt"
                local worldfile = Settings(filename)
                if worldfile then
                    worldfile:set("creative_mode", fields.cb_creative == "true" and "true" or "false")
                    worldfile:write()
                    debug_log("Updated world.mt creative_mode setting to %s", 
                             fields.cb_creative == "true" and "true" or "false")
                end
            end
        end
        return true
    end
    
    if fields.cb_damage ~= nil then
        -- Convert string "true"/"false" to boolean for settings
        core.settings:set_bool("enable_damage", fields.cb_damage == "true")
        -- Also update the world.mt file for the selected world
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world_list = menudata.worldlist:get_list()
            if selected <= #world_list then
                local world = world_list[selected]
                local filename = world.path .. DIR_DELIM .. "world.mt"
                local worldfile = Settings(filename)
                if worldfile then
                    worldfile:set("enable_damage", fields.cb_damage == "true" and "true" or "false")
                    worldfile:write()
                    debug_log("Updated world.mt enable_damage setting to %s", 
                             fields.cb_damage == "true" and "true" or "false")
                end
            end
        end
        return true
    end
    
    return false
end

local function on_change(type, old_index, new_index)
    -- Ensure world list exists
    if not menudata.worldlist then
        refresh_worldlist()
    end

    if type == "ENTER" then
        -- Get the selected world index from either the method or our backup variable
        local selected
        
        if type(menudata.worldlist.get_current_index) == "function" then
            local status, result = pcall(function()
                return menudata.worldlist:get_current_index()
            end)
            
            if status and result and result > 0 then
                selected = result
            else
                selected = selected_world_index
            end
        else
            selected = selected_world_index
        end
        
        if selected > 0 then
            -- Use our direct launching function instead of repeating code
            launch_world(selected)
            return true
        end
    end
    return false
end

-- Create tab object and store in local variable for proper dialog handling
tab_local = {
    name = "local",
    caption = "Play Game",
    get_formspec = get_formspec,
    handle_buttons = handle_buttons,
    on_change = on_change,
    type = "toplevel"
}

return tab_local
