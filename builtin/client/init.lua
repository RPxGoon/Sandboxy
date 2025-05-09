local scriptpath = core.get_builtin_path()
local clientpath = scriptpath.."client"..DIR_DELIM
local commonpath = scriptpath.."common"..DIR_DELIM

local builtin_shared = {}

assert(loadfile(commonpath .. "register.lua"))(builtin_shared)
assert(loadfile(clientpath .. "register.lua"))(builtin_shared)
dofile(commonpath .. "after.lua")
dofile(commonpath .. "mod_storage.lua")
dofile(commonpath .. "chatcommands.lua")
dofile(commonpath .. "information_formspecs.lua")
dofile(clientpath .. "chatcommands.lua")
dofile(clientpath .. "misc.lua")
assert(loadfile(commonpath .. "item_s.lua"))({}) -- Just for push/read node functions

-- Sandboxy client modding system

local csm = {}
csm.registered_on_mods_loaded = {}
csm.registered_on_shutdown = {}
csm.registered_globalsteps = {}
csm.environment = {}
csm.loaded_mods = {}

-- Settings from server
csm.restrictions = {
    chat_messages = false,
    read_itemdefs = false,
    read_nodedefs = false,
    lookup_nodes = false,
    read_playerinfo = false,
    lookup_range = 0
}

function csm.register_on_mods_loaded(callback)
    table.insert(csm.registered_on_mods_loaded, callback)
end

function csm.register_on_shutdown(callback)
    table.insert(csm.registered_on_shutdown, callback)
end

function csm.register_globalstep(callback)
    table.insert(csm.registered_globalsteps, callback)
end

function csm.load_mod(modname)
    if csm.loaded_mods[modname] then
        return false
    end

    local path = core.get_clientmodpath() .. DIR_DELIM .. modname
    local main = path .. DIR_DELIM .. "init.lua"
    local env = table.copy(csm.environment)
    
    local code = core.safe_file_read(main)
    if not code then
        core.log("error", "Failed to load client mod: " .. modname)
        return false
    end

    local chunk, err = loadstring(code)
    if chunk and not err then
        setfenv(chunk, env)
        local ok, err = pcall(chunk)
        if ok then
            csm.loaded_mods[modname] = true
            return true
        else
            core.log("error", "Failed to execute client mod: " .. modname .. " (" .. err .. ")")
        end
    else
        core.log("error", "Failed to load client mod: " .. modname .. " (" .. err .. ")")
    end
    return false
end

function csm.load_mods()
    local clientmods = core.get_clientmods()
    local count = 0
    
    for _, modname in ipairs(clientmods) do
        if csm.load_mod(modname) then
            count = count + 1
        end
    end

    for _, callback in ipairs(csm.registered_on_mods_loaded) do
        callback()
    end

    return count
end

function csm.handle_shutdown()
    for _, callback in ipairs(csm.registered_on_shutdown) do
        callback()
    end
end

function csm.restrict_api(flags, range)
    csm.restrictions.chat_messages = (flags & 0x02) ~= 0
    csm.restrictions.read_itemdefs = (flags & 0x04) ~= 0  
    csm.restrictions.read_nodedefs = (flags & 0x08) ~= 0
    csm.restrictions.lookup_nodes = (flags & 0x10) ~= 0
    csm.restrictions.read_playerinfo = (flags & 0x20) ~= 0
    csm.restrictions.lookup_range = range
end

-- Initialize API environment
csm.environment = {
    -- Core API
    core = {
        log = core.log,
        settings = core.settings,
        get_node = function(pos)
            if csm.restrictions.lookup_nodes then
                -- Check range restriction
                local player = core.localplayer
                if not player then return nil end
                
                local ppos = player:get_pos()
                local dist = vector.distance(pos, ppos)
                
                if dist > csm.restrictions.lookup_range then
                    return nil
                end
            end
            return core.get_node(pos)
        end,
        find_node_near = function(pos, radius, nodenames, search_center)
            if csm.restrictions.lookup_nodes and 
               radius > csm.restrictions.lookup_range then
                return nil
            end
            return core.find_node_near(pos, radius, nodenames, search_center)
        end
    },

    -- Mod API
    sandboxy = {
        register_on_mods_loaded = csm.register_on_mods_loaded,
        register_on_shutdown = csm.register_on_shutdown,
        register_globalstep = csm.register_globalstep,
        get_mod_name = function()
            return debug.getinfo(2, "S").source:match("@.+/(.+)/init.lua$")
        end,
        get_restrictions = function()
            return table.copy(csm.restrictions)
        end
    }
}

-- Start client modding system
core.after(0, csm.load_mods)
core.register_on_shutdown(csm.handle_shutdown)

-- Export API
return csm
