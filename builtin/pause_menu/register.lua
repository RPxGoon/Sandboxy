local builtin_shared = ...

local make_registration = builtin_shared.make_registration

core.registered_on_formspec_input, core.register_on_formspec_input = make_registration()

-- Sandboxy pause menu registration

local function create_pause_menu()
    local dlg = dialog.create("pause_menu",
        {
            tab_title = "Pause Menu",
            bgimg = "menu_bg.png",
            bgimg_middle = true,
        },
        {
            {
                type = "image",
                name = "logo",
                alignment = "center",
                image = "menu_logo.png",
                padding = 10,
            },
            {
                type = "container",
                name = "buttons",
                orientation = "vertical",
                padding = 10,
                {
                    type = "button",
                    name = "resume",
                    label = "Resume Game",
                    on_click = function()
                        core.close_formspec("pause_menu")
                    end
                },
                {
                    type = "button",
                    name = "settings",
                    label = "Settings",
                    on_click = function()
                        core.show_settings_dialog()
                    end
                },
                {
                    type = "button",
                    name = "topmenu",
                    label = "Exit to Menu",
                    on_click = function()
                        core.disconnect()
                    end
                },
                {
                    type = "button",
                    name = "exit",
                    label = "Exit Game",
                    on_click = function()
                        core.disconnect()
                        core.quit()
                    end
                }
            }
        }
    )
    return dlg
end

core.register_on_connect(function()
    local dlg = create_pause_menu()
    core.register_on_pause_menu(function(is_paused)
        if is_paused then
            dlg:show()
        else 
            dlg:hide()
        end
    end)
end)
