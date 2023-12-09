local M = {}
M.lastsysClip = ""
M.timer = vim.loop.new_timer()

function M.ObserveSystemClipboard(sysclipCommand, wait, AddToHistory)
	M.timer:start(
		0,
		wait,
		vim.schedule_wrap(function()
			local handle = io.popen(sysclipCommand)
			local sysClip = handle:read("*a")
			handle:close()
			if sysClip ~= M.lastsysClip then
				M.lastsysClip = sysClip
				AddToHistory(sysClip)
			end
		end)
	)
end

return M
