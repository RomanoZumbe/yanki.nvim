---@diagnostic disable: param-type-mismatch
local uv = vim.loop
local M = {}
local lastsysClip = ""
local timer = vim.loop.new_timer()

--- Starts the global timer to check for system clipboard changes
---@param sysclipCommand string the application to check for system clipboard changes
---@param args string arguments to the application
---@param wait number how long to wait before rechecking
---@param AddToHistory function the function to call when there is something new
function M.ObserveSystemClipboard(sysclipCommand, args, wait, AddToHistory)
    timer:start(0, wait, function()
        M.GetStdoutFromAsync(sysclipCommand, args,
        -- the function call needs to be wrapped to call vim.fn functions from the vim.loop
                             vim.schedule_wrap(function(data)
            if data and data ~= lastsysClip then
                lastsysClip = data
                AddToHistory(data)
            end
        end))
    end)
end

--- Calls an external command and runs a callback with the data returned on stdout
---@param command string command to execute
---@param args table arguments to the command
---@param callback function callback function that will be executed with the data from stdout as parameter
function M.GetStdoutFromAsync(command, args, callback)
    local stdout = uv.new_pipe()
    -- TODO: Checkout if the handle needs to get closed
    local handle, _ = uv.spawn(command, {stdio = {nil, stdout}, args = args},
    -- close the pipes after executing the command
                               function()
        if stdout then
            stdout:read_stop()
            stdout:close()
        end
    end)

    uv.read_start(stdout, function(err, data)
        assert(not err, err)
        if data then callback(data) end
    end)
    -- HACK: This throws a lot of errors, no idea what to do about it
    -- uv.read_start(stderr, function(err, data)
    --     assert(not err, err)
    --     if data then
    --         print("stderr chunk", stderr, data)
    --     else
    --         print("stderr end", stderr)
    --     end
    -- end)
end

return M
