-- Sandboxy game theme manager

mm_game_theme = {}
local theme = {}

function mm_game_theme.init()
    theme = {
        id = "sandboxy",
        type = "generic",
        name = "Sandboxy",
        author = "Sandboxy Team",
        title_color = "#2196F3",
        title_bgcolor = "#1976D2",
        
        bg_topleft = {
            type = "image",
            pos = {x=0, y=0},
            image = "menu_bg_header.png"
        },
        
        bg_tile = {
            type = "image",
            pos = {x=128, y=0},
            image = "menu_bg_tile.png"
        },
        
        bg_header = {
            type = "image",
            pos = {x=0, y=0},
            image = "menu_bg_header.png"
        },
        
        logo = {
            type = "image",
            pos = {x=20, y=20},
            image = "menu_logo.png"
        },
        
        footer = {
            type = "box",
            pos = {x=0, y=-60},
            size = {w=0, h=60},
            color = "#1976D2"
        },
        
        buttons = {
            type = "container",
            pos = {x=40, y=100},
            size = {w=240, h=300},
            color = "#FFFFFF",
            items = {}
        }
    }
end

function mm_game_theme.set_game(game)
    if not game then return end

    if game.menuicon_path then
        theme.logo.image = game.menuicon_path
    end

    if game.name then
        theme.game_id = game.name
    end

    mm_game_theme.set(theme)
end

function mm_game_theme.set(custom_theme)
    if not custom_theme then return end
    theme = custom_theme
    
    core.set_background("menu",
        theme.bg_topleft.image,
        theme.bg_tile.image,
        theme.bg_header.image,
        true)
end

function mm_game_theme.get()
    return theme
end

function mm_game_theme.set_engine()
    local engine_theme = {
        id = "engine",
        type = "engine",
        name = "Sandboxy Engine",
        author = "Sandboxy Team",
        title_color = "#2196F3",
        title_bgcolor = "#1976D2",
        
        bg_topleft = {
            type = "image",
            pos = {x=0, y=0}, 
            image = "menu_bg_header.png"
        },
        
        bg_tile = {
            type = "image",
            pos = {x=0, y=0},
            image = "menu_bg_tile.png" 
        },
        
        bg_header = {
            type = "image",
            pos = {x=0, y=0},
            image = "menu_bg_header.png"
        }
    }
    
    mm_game_theme.set(engine_theme)
end

-- Initialize theme system
mm_game_theme.init()
