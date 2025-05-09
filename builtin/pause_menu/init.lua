local scriptpath = core.get_builtin_path()
local pausepath = scriptpath.."pause_menu"..DIR_DELIM
local commonpath = scriptpath.."common"..DIR_DELIM

-- we're in-game, so no absolute paths are needed
defaulttexturedir = ""

local builtin_shared = {}

assert(loadfile(commonpath .. "register.lua"))(builtin_shared)
assert(loadfile(commonpath .. "menu.lua"))(builtin_shared)
assert(loadfile(pausepath .. "register.lua"))(builtin_shared)
dofile(commonpath .. "settings" .. DIR_DELIM .. "init.lua")

-- Sandboxy pause menu

local menu = {}

function menu.get_formspec()
    local formspec = "size[12,7]"
    formspec = formspec .. "background[0,0;12,7;menu_bg.png;true]"
    formspec = formspec .. "label[5,0.5;Game Paused]"
    
    -- Menu buttons
    formspec = formspec .. "button[4,2;4,0.8;btn_resume;Resume Game]"
    formspec = formspec .. "button[4,3;4,0.8;btn_settings;Settings]"
    formspec = formspec .. "button[4,4;4,0.8;btn_topmenu;Main Menu]"
    formspec = formspec .. "button[4,5;4,0.8;btn_exit;Exit Game]"
    
    return formspec
end

function menu.handle_buttons(player, fields)
    if fields.btn_resume then
        return false -- Close menu
    end
    
    if fields.btn_settings then
        -- Show settings dialog
        core.show_settings_dialog()
        return true
    end
    
    if fields.btn_topmenu then
        core.disconnect()
        return false
    end
    
    if fields.btn_exit then
        core.disconnect()
        core.quit()
        return false
    end
    
    return true
end

core.register_on_pause_menu(function(isMenuVisible)
    if isMenuVisible then
        core.show_formspec("pause_menu", menu.get_formspec())
    end
end)

core.register_on_receive_fields(function(player, formname, fields)
    if formname ~= "pause_menu" then return end
    return menu.handle_buttons(player, fields)
end)
