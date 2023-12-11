---@diagnostic disable: param-type-mismatch
local uv = vim.loop
local M = {}
M.lastsysClip = ""
M.timer = vim.loop.new_timer()
M.lastHandle = nil

function M.ObserveSystemClipboard(sysclipCommand, args, wait, AddToHistory)
	M.timer:start(0, wait, function()
		M.GetClipboardText(
			sysclipCommand,
			args,
			vim.schedule_wrap(function(data)
				if data and data ~= M.lastsysClip then
					M.lastsysClip = data
					AddToHistory(data)
				end
			end)
		)
	end)
end

function M.GetClipboardText(command, args, action)
	local stdout = uv.new_pipe()
	local handle, pid = uv.spawn(command, { stdio = { nil, stdout }, args = args }, function()
		stdout:read_stop()
		stdout:close()
--		handle:close()
	end)
	M.lastHandle = handle
	uv.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			action(data)
		else
			-- if handle then
			--     -- uv.shutdown(stdin, function() uv.close(handle) end)
			--     if not uv.is_closing(handle) then uv.close(handle) end
			-- end
		end
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

	-- if handle then uv.shutdown(stdin, function() uv.close(handle) end) end
	-- if not uv.is_active(handle) then uv.close(handle) end
end

return M
