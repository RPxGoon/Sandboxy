-- Luanti
-- Copyright (C) 2013 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

-- Sandboxy about tab

local function get_formspec()
    local version = core.get_version()
    -- Format version table into a string
    local version_str = version.string or (tostring(version.major) .. "." .. tostring(version.minor) .. "." .. tostring(version.patch))
    
    local text = [[
Sandboxy ]] .. version_str .. [[

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
- Font: Arimo and Cousine (Apache License 2.0)
]]

    local tab = {
        name = "about",
        caption = "About",
        tabsize = {x = 15.5, y = 7},
        content = {
            text = text,
            background = "menu_bg.png",
            textbox = {
                x = 0.5, y = 0.5, w = 14.5, h = 6,
                name = "about_text",
                style = "textbox",
                bgcolor = "#FFFFFF"
            },
            buttons = {
                {
                    x = 12, y = 6.5, w = 3, h = 0.5,
                    name = "btn_credits",
                    label = "View Credits",
                    bgcolor = "#2196F3"
                }
            }
        }
    }

    return tab
end

local function handle_buttons(fields)
    if fields.btn_credits then
        core.show_url("https://github.com/sandboxyorg/sandboxy/graphs/contributors")
        return true
    end
    return false
end

return {
    name = "about",
    caption = "About",
    get_formspec = get_formspec,
    handle_buttons = handle_buttons
}
