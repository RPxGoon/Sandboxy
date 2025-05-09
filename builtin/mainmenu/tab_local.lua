-- Luanti
-- Copyright (C) 2014 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later


local current_game, singleplayer_refresh_gamebar
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

	return game
end

-- Apply menu changes from given game
function apply_game(game)
	core.settings:set("menu_last_game", game.id)
	menudata.worldlist:set_filtercriteria(game.id)

	mm_game_theme.set_game(game)

	local index = filterlist.get_current_index(menudata.worldlist,
		tonumber(core.settings:get("mainmenu_last_selected_world")))
	if not index or index < 1 then
		local selected = core.get_textlist_index("sp_worlds")
		if selected ~= nil and selected < #menudata.worldlist:get_list() then
			index = selected
		else
			index = #menudata.worldlist:get_list()
		end
	end
	menu_worldmt_legacy(index)
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

local function get_formspec()
    local selected_world = menudata.worldlist:get_current_index()
    local selected_game = core.settings:get("menu_last_game")
    
    local tab = {
        name = "local",
        caption = "Play Game",
        tabsize = {x = 15.5, y = 7},
        content = {
            background = "menu_bg.png",
            containers = {
                {
                    x = 0.2, y = 0.2, w = 7.5, h = 6.3,
                    name = "worlds_container",
                    bgcolor = "#FFFFFF",
                    style = "container",
                    elements = {
                        {
                            type = "label",
                            x = 0.2, y = 0.2,
                            label = "Select World",
                            style = "label_header"
                        },
                        {
                            type = "list",
                            x = 0.2, y = 0.7, w = 7.1, h = 4.8,
                            name = "world_list",
                            selected = selected_world,
                            transparent = false,
                            bgcolor = "#E0E0E0"
                        },
                        {
                            type = "button",
                            x = 0.2, y = 5.7, w = 2.3, h = 0.5,
                            name = "btn_new_world",
                            label = "New World",
                            bgcolor = "#4CAF50"
                        },
                        {
                            type = "button",
                            x = 2.7, y = 5.7, w = 2.3, h = 0.5,
                            name = "btn_delete_world",
                            label = "Delete",
                            bgcolor = "#F44336"
                        },
                        {
                            type = "button",
                            x = 5.1, y = 5.7, w = 2.3, h = 0.5,
                            name = "btn_configure_world",
                            label = "Configure",
                            bgcolor = "#2196F3"
                        }
                    }
                },
                {
                    x = 8, y = 0.2, w = 7.3, h = 6.3,
                    name = "game_info",
                    bgcolor = "#FFFFFF",
                    style = "container",
                    elements = {
                        {
                            type = "label",
                            x = 0.2, y = 0.2,
                            label = "Game",
                            style = "label_header"
                        },
                        {
                            type = "box",
                            x = 0.2, y = 0.7, w = 6.9, h = 4.8,
                            name = "game_info_box",
                            bgcolor = "#E0E0E0"
                        }
                    }
                }
            },
            buttons = {
                {
                    x = 12.8, y = 6.7, w = 2.5, h = 0.5,
                    name = "btn_play",
                    label = "Play",
                    bgcolor = "#4CAF50"
                }
            }
        }
    }

    return tab
end

local function handle_buttons(fields)
    if fields.btn_play then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            gamedata.selected_world = selected
            core.start()
        end
        return true
    end

    if fields.btn_new_world then
        local dlg = create_create_world_dlg()
        dlg:set_parent(this)
        this:hide()
        dlg:show()
        return true
    end

    if fields.btn_delete_world then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world = menudata.worldlist:get_list()[selected]
            local dlg = create_delete_world_dlg(world.name, function()
                menudata.worldlist:remove_index(selected)
            end)
            dlg:show()
        end
        return true
    end

    if fields.btn_configure_world then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            local world = menudata.worldlist:get_list()[selected]
            local dlg = create_configure_world_dlg(world)
            dlg:show()
        end
        return true
    end

    return false
end

local function on_change(type, old_index, new_index)
    if type == "ENTER" then
        local selected = menudata.worldlist:get_current_index()
        if selected > 0 then
            gamedata.selected_world = selected
            core.start()
        end
        return true
    end
    return false
end

return {
    name = "local",
    caption = "Play Game",
    get_formspec = get_formspec,
    handle_buttons = handle_buttons,
    on_change = on_change
}
