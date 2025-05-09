-- Luanti
-- Copyright (C) 2014 sapier
-- Copyright (C) 2018 rubenwardy <rw@rubenwardy.com>
-- SPDX-License-Identifier: LGPL-2.1-or-later

-- Sandboxy content browser tab

local function get_formspec()
    local tab = {
        name = "content",
        caption = "Content",
        tabsize = {x = 15.5, y = 7},
        content = {
            text = "x",
            background = "menu_bg.png",
            buttons = {
                {
                    x = 0, y = 0, w = 15.5, h = 0.5,
                    name = "header",
                    label = "Sandboxy Content Browser",
                    bgcolor = "#1976D2",
                    style = "header"
                },
                {
                    x = 0.2, y = 1, w = 7.5, h = 5.7,
                    name = "content_list",
                    bgcolor = "#FFFFFF",
                    style = "box"
                },
                {
                    x = 8, y = 1, w = 7.3, h = 5.7,
                    name = "content_details",
                    bgcolor = "#FFFFFF", 
                    style = "box"
                },
                {
                    x = 0.3, y = 6.8, w = 2.5, h = 0.5,
                    name = "btn_install",
                    label = "Install",
                    bgcolor = "#4CAF50"
                },
                {
                    x = 3, y = 6.8, w = 2.5, h = 0.5,
                    name = "btn_download",
                    label = "Download",
                    bgcolor = "#2196F3"
                },
                {
                    x = 5.7, y = 6.8, w = 2.5, h = 0.5,
                    name = "btn_uninstall",
                    label = "Uninstall",
                    bgcolor = "#F44336"
                }
            },
            search = {
                x = 8.1, y = 0.2, w = 7.1, h = 0.4,
                name = "search",
                label = "",
                default = "Search...",
                bgcolor = "#FFFFFF"
            }
        }
    }

    return tab
end

local function handle_buttons(fields)
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
    
    if fields.search then
        -- Handle search
        return true
    end
    
    return false
end

local function init()
    -- Initialize content browser
    core.handle_async("get_content_list", {
        url = core.settings:get("contentdb_url") or 
              "https://content.sandboxy.org"
    }, function(result)
        if result and result.list then
            core.event_handler({
                type = "content_list_updated",
                list = result.list
            })
        end
    end)
end

return {
    name = "content",
    caption = "Content",
    get_formspec = get_formspec,
    handle_buttons = handle_buttons,
    init = init
}
