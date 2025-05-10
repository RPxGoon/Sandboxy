--
-- This file contains built-in stuff in Luanti implemented in Lua.
--
-- It is always loaded and executed after registration of the C API,
-- before loading and running any mods.
--

-- Initialize some very basic things
function core.error_handler(err, level)
	return debug.traceback(tostring(err), level)
end
do
	local function concat_args(...)
		local n, t = select("#", ...), {...}
		for i = 1, n do
			t[i] = tostring(t[i])
		end
		return table.concat(t, "\t")
	end
	function core.debug(...) core.log(concat_args(...)) end
	if core.print then
		local core_print = core.print
		-- Override native print and use
		-- terminal if that's turned on
		function print(...) core_print(concat_args(...)) end
		core.print = nil -- don't pollute our namespace
	end
end

do
	-- Note that PUC Lua just calls srand() which is already initialized by C++,
	-- but we don't want to rely on this implementation detail.
	local seed = 1048576 * (os.time() % 1048576)
	seed = seed + core.get_us_time() % 1048576
	math.randomseed(seed)
end

-- Initialize core callbacks system
core.register_on_connect = function(callback)
    core.connect_callbacks = core.connect_callbacks or {}
    table.insert(core.connect_callbacks, callback)
end

core.run_connect_callbacks = function()
    for _, callback in ipairs(core.connect_callbacks or {}) do
        callback()
    end
end

core.register_on_disconnect = function(callback)
    core.disconnect_callbacks = core.disconnect_callbacks or {}
    table.insert(core.disconnect_callbacks, callback)
end

core.run_disconnect_callbacks = function()
    for _, callback in ipairs(core.disconnect_callbacks or {}) do
        callback()
    end
end

-- Set up basic event system
core.callback_origins = {}
core.registered_on_callbacks = {}

core.register_on = function(name, callback)
    core.registered_on_callbacks[name] = core.registered_on_callbacks[name] or {}
    table.insert(core.registered_on_callbacks[name], callback)
end

core.run_callbacks = function(name, ...)
    local callbacks = core.registered_on_callbacks[name]
    if callbacks then
        for _, callback in ipairs(callbacks) do
            callback(...)
        end
    end
end

-- Add pause menu specific callbacks
core.register_on_pause_menu = function(callback)
    core.pause_menu_callbacks = core.pause_menu_callbacks or {}
    table.insert(core.pause_menu_callbacks, callback)
end

core.run_pause_menu_callbacks = function()
    for _, callback in ipairs(core.pause_menu_callbacks or {}) do
        callback()
    end
end

-- Add form field handling callbacks
core.register_on_receive_fields = function(callback)
    core.receive_fields_callbacks = core.receive_fields_callbacks or {}
    table.insert(core.receive_fields_callbacks, callback)
end

core.run_receive_fields_callbacks = function(player, formname, fields)
    for _, callback in ipairs(core.receive_fields_callbacks or {}) do
        if callback(player, formname, fields) then
            return true
        end
    end
    return false
end

minetest = core

-- Load other files
local scriptdir = core.get_builtin_path()
local commonpath = scriptdir .. "common" .. DIR_DELIM
local asyncpath = scriptdir .. "async" .. DIR_DELIM

dofile(commonpath .. "math.lua")
dofile(commonpath .. "vector.lua")
dofile(commonpath .. "strict.lua")
dofile(commonpath .. "serialize.lua")
dofile(commonpath .. "misc_helpers.lua")

if INIT == "game" then
	dofile(scriptdir .. "game" .. DIR_DELIM .. "init.lua")
	assert(not core.get_http_api)
elseif INIT == "mainmenu" then
	local mm_script = core.settings:get("main_menu_script")
	local custom_loaded = false
	if mm_script and mm_script ~= "" then
		local testfile = io.open(mm_script, "r")
		if testfile then
			testfile:close()
			dofile(mm_script)
			custom_loaded = true
			core.log("info", "Loaded custom main menu script: "..mm_script)
		else
			core.log("error", "Failed to load custom main menu script: "..mm_script)
			core.log("info", "Falling back to default main menu script")
		end
	end
	if not custom_loaded then
		dofile(core.get_mainmenu_path() .. DIR_DELIM .. "init.lua")
	end
elseif INIT == "async"  then
	dofile(asyncpath .. "mainmenu.lua")
elseif INIT == "async_game" then
	dofile(commonpath .. "metatable.lua")
	dofile(asyncpath .. "game.lua")
elseif INIT == "client" then
	dofile(scriptdir .. "client" .. DIR_DELIM .. "init.lua")
elseif INIT == "emerge" then
	dofile(scriptdir .. "emerge" .. DIR_DELIM .. "init.lua")
elseif INIT == "pause_menu" then
	dofile(scriptdir .. "pause_menu" .. DIR_DELIM .. "init.lua")
else
	error(("Unrecognized builtin initialization type %s!"):format(tostring(INIT)))
end
