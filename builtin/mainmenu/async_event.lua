core.async_jobs = {}

local function handle_job(jobid, serialized_retval)
	local retval = core.deserialize(serialized_retval)
	assert(type(core.async_jobs[jobid]) == "function")
	core.async_jobs[jobid](retval)
	core.async_jobs[jobid] = nil
end

core.async_event_handler = handle_job

function core.handle_async(func, parameter, callback)
	-- Serialize parameters
	local serialized_param = core.serialize(parameter)

	if serialized_param == nil then
		return false
	end

	local jobid = core.do_async_callback(func, serialized_param)

	core.async_jobs[jobid] = callback

	return true
end

-- Sandboxy async event handler

async_event = {
    connected = false,
    current_async_job = nil,
    initialized = false
}

function async_event.init()
    if async_event.initialized then
        return
    end

    async_event.initialized = true

    core.after(0.5, function()  
        async_event.wait_for_jobs()
    end)
end

function async_event.wait_for_jobs()
    -- Process queued tasks
    if not async_event.connected then
        async_event.current_async_job = nil
        core.after(1.0, async_event.wait_for_jobs)
        return
    end

    if async_event.current_async_job == nil then
        -- No current job, try to get one
        async_event.current_async_job = core.get_async_event()
        core.after(0.1, async_event.wait_for_jobs)
        return
    end

    -- Handle the event
    local retval = nil
    local job = async_event.current_async_job

    if job.type == "content_update" then
        if job.action == "download" then
            retval = handle_async_download(job.param)
        elseif job.action == "install" then  
            retval = handle_async_install(job.param)
        end
    elseif job.type == "serverlist" then
        retval = handle_async_serverlist(job.param)
    elseif job.type == "modstore" then
        retval = handle_async_modstore(job.param)        
    end

    -- Reset current job and continue checking
    async_event.current_async_job = nil

    if retval then
        core.event_handler(retval)
    end

    core.after(0.1, async_event.wait_for_jobs)
end

function handle_async_download(param)
    if not param then return end

    local result = {
        type = "download",
        successful = param.status == "success"
    }

    if param.status == "success" then
        result.name = param.name
        result.path = param.path
    else
        result.error = param.error or "Unknown error"
    end

    return result
end

function handle_async_install(param)
    if not param then return end

    local result = {
        type = "install",
        successful = param.status == "success" 
    }

    if param.status == "success" then
        result.path = param.path
    else
        result.error = param.error or "Unknown error"
    end

    return result
end

function handle_async_serverlist(param)
    if not param then return end
    
    local result = {
        type = "serverlist",
        list = param.list or {}
    }

    return result
end

function handle_async_modstore(param)
    if not param then return end

    local result = {
        type = "modstore",
        list = param.list or {}
    }

    return result
end

async_event.init()

