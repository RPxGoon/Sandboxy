local scriptpath = core.get_builtin_path()
local commonpath = scriptpath .. "common" .. DIR_DELIM
local gamepath   = scriptpath .. "game".. DIR_DELIM

-- Shared between builtin files, but
-- not exposed to outer context
local builtin_shared = {}

dofile(gamepath .. "constants.lua")
assert(loadfile(commonpath .. "item_s.lua"))(builtin_shared)
assert(loadfile(gamepath .. "item.lua"))(builtin_shared)
assert(loadfile(commonpath .. "register.lua"))(builtin_shared)
assert(loadfile(gamepath .. "register.lua"))(builtin_shared)

if core.settings:get_bool("profiler.load") then
	profiler = dofile(scriptpath .. "profiler" .. DIR_DELIM .. "init.lua")
end

dofile(commonpath .. "after.lua")
dofile(commonpath .. "metatable.lua")
dofile(commonpath .. "mod_storage.lua")
dofile(gamepath .. "item_entity.lua")
dofile(gamepath .. "deprecated.lua")
dofile(gamepath .. "misc_s.lua")
dofile(gamepath .. "misc.lua")
dofile(gamepath .. "privileges.lua")
dofile(gamepath .. "auth.lua")
dofile(commonpath .. "chatcommands.lua")
dofile(gamepath .. "chat.lua")
dofile(commonpath .. "information_formspecs.lua")
dofile(gamepath .. "static_spawn.lua")
dofile(gamepath .. "detached_inventory.lua")
assert(loadfile(gamepath .. "falling.lua"))(builtin_shared)
dofile(gamepath .. "features.lua")
dofile(gamepath .. "voxelarea.lua")
dofile(gamepath .. "forceloading.lua")
dofile(gamepath .. "hud.lua")
dofile(gamepath .. "knockback.lua")
dofile(gamepath .. "async.lua")
dofile(gamepath .. "death_screen.lua")

core.after(0, builtin_shared.cache_content_ids)

profiler = nil

-- Sandboxy core game initialization

-- Default game settings
local default_settings = {
    -- World generation
    mg_name = "v7",
    mg_flags = "trees, caves, dungeons, decorations",
    mg_seed = "",
    water_level = 1,
    mapgen_limit = 31000,
    chunksize = 5,
    
    -- Gameplay
    enable_damage = true,
    creative_mode = false,
    enable_pvp = true,
    enable_tnt = false,
    disable_fire = true,
    
    -- Player
    default_privs = "interact, shout",
    enable_sprint = true,
    movement_acceleration_default = 3,
    movement_acceleration_air = 2,
    movement_acceleration_fast = 10,
    movement_speed_walk = 4,
    movement_speed_crouch = 1.35,
    movement_speed_fast = 6,
    movement_speed_climb = 3,
    movement_speed_jump = 6.5,
    movement_speed_descend = 6,
    movement_liquid_fluidity = 1,
    movement_liquid_fluidity_smooth = 0.5,
    
    -- Environment
    time_speed = 72,
    weather = true,
    cloud_height = 120,
    cloud_radius = 12,
    weather_biome = true,
    weather_heat = true,
    weather_humidity = true,
    
    -- Graphics
    enable_3d_clouds = true,
    enable_particles = true,
    enable_weather_effects = true,
    enable_waving_plants = true,
    enable_waving_leaves = true,
    enable_waving_water = true,
    
    -- Performance
    max_block_send_distance = 10,
    max_simultaneous_block_sends_per_client = 40,
    server_map_save_interval = 5.3,
    max_packets_per_iteration = 1024,
    max_simultaneous_block_sends_server_total = 1000,
    
    -- Server
    server_name = "Sandboxy Server",
    server_description = "A Sandboxy Game Server",
    server_address = "",
    server_url = "",
    server_announce = false,
    server_dedicated = false,
    max_users = 15,
    strict_protocol_version_checking = false,
    
    -- Network
    enable_ipv6 = true,
    ipv6_server = false,
    max_packets_per_iteration = 1024,
    connection_timeout = 30,
    
    -- Advanced
    debug_log_level = 1,
    enable_minimap = true,
    minimap_shape_round = true,
    hud_flags = {
        crosshair = true,
        hotbar = true,
        healthbar = true,
        breathbar = true,
        wielditem = true,
        minimap = true
    }
}

-- Apply settings on world creation
local function apply_default_settings()
    for setting, value in pairs(default_settings) do
        if type(value) == "table" then
            for flag, val in pairs(value) do
                core.settings:set(setting.."_"..flag, tostring(val))
            end
        else
            core.settings:set(setting, tostring(value))
        end
    end
end

-- Initialize new world
local function init_new_world()
    apply_default_settings()
    
    -- Create basic directories
    local worldpath = core.get_worldpath()
    core.mkdir(worldpath)
    core.mkdir(worldpath .. "/players")
    core.mkdir(worldpath .. "/scheduler")
    
    -- Initialize player data
    local auth_db = core.open_auth_file(worldpath .. "/auth.txt")
    if auth_db then
        auth_db:close()
    end
    
    local backend = core.get_auth_handler().get_auth
    if not backend then
        error("Failed to initialize authentication handler")
    end
end

-- Register callbacks
core.register_on_newworld(init_new_world)
core.register_on_prejoinplayer(function(name, ip)
    if not core.is_singleplayer() then
        local privs = minetest.get_player_privs(name)
        if not privs.interact then
            privs.interact = true
            minetest.set_player_privs(name, privs)
        end
    end
    return nil
end)

-- Export API
return {
    get_default_settings = function()
        return table.copy(default_settings)
    end,
    apply_default_settings = apply_default_settings,
    init_new_world = init_new_world
}
