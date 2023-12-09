local util = require("yanki.util")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local state = require("telescope.state")
local sysclip = require("yanki.sysclip")

local M = {}
-- Yank history
M.yanks = {}
-- Current put position in the yank history
M.yankIndex = 1

function M.setup(parm)
	parm = (parm or {})

	-- create autocommand to react to yank actions
	vim.api.nvim_exec(
		[[
      augroup WatchYankRegister
        autocmd!
        autocmd TextYankPost * lua require("yanki").OnTextYank()
      augroup END
    ]],
		false
	)
	M.settings = parm

	if M.settings.observe_system_clipboard then
		sysclip.ObserveSystemClipboard(
			M.settings.system_clipbaord_command,
			M.settings.system_clipboard_wait,
			M.AddToHistory
		)
	end
end

--- Called whenever Text is yanked (yank/delete/replace) in nvim
function M.OnTextYank()
	-- get the contents of the default register
	local yankedText = vim.fn.getreg('"', 1)
	M.AddToHistory(yankedText)
end

function M.AddToHistory(text)
	local lines = {}
	-- Whatever was yanked goes into the temporary history
	table.insert(lines, text)

	-- If transformer functions are defined all active ones will be applied
	-- to the yanked text in the order the appear in the array
	for t, transformer in ipairs(M.settings.transformer or {}) do
		if transformer.active then
			local newLines = {}
			for i = 1, #lines do
				local transformedText = transformer.action(lines[i])

				-- The transformer can return a string or a table of strings
				-- if it is a table, each string will go into the history as
				-- its own entry
				if type(transformedText) == "table" then
					for _, v in ipairs(transformedText) do
						table.insert(newLines, v)
					end
				elseif type(transformedText) == "string" then
					table.insert(newLines, transformedText)
				end
			end
			lines = newLines
		end
	end

	-- Insert all new lines into the actual yank history
	for _, v in ipairs(lines) do
		table.insert(M.yanks, v)
	end
end

-- Select the next entry from the history and put it in the
-- buffer at the current cursor position
function M.PutNext()
	if #M.yanks == 0 then
		return
	end
	local nextPut = M.yanks[M.yankIndex]
	M.Put(nextPut)
end

--- Put text into the active buffer at the current cursor position
---@param text text to put into the buffer
function M.Put(text)
	-- get current cursor position
	local currentLine = vim.fn.line(".")
	local currentCol = vim.fn.col(".")

	-- HACK: if the text ends with a new line or it is explicitly configured
	-- the text will be put in the next line. Mostly to mimic vims
	-- default put behavior
	if M.settings.PutInNewLine or string.sub(text, -1) == "\n" then
		local lines = vim.fn.split(text, "\n")

		vim.api.nvim_buf_set_lines(0, currentLine, currentLine, false, lines)
	else
		-- Otherwise just split the text into seperate lines and start puting
		-- the lines at the current position
		local lines = vim.split(text, "\n")
		vim.api.nvim_buf_set_text(0, currentLine - 1, currentCol - 1, currentLine - 1, currentCol - 1, lines)
	end

	-- raise the index by one and start from the beginning after reaching
	-- the last index
	M.yankIndex = (M.yankIndex % #M.yanks) + 1
end

-- Clear the yank history to start over
function M.ClearYankHistory()
	M.yanks = {}
	M.yankIndex = 1
end

--- Open telescope picker to inspect and manipulate the yank history
---@param opts telescope picker options
function M.ShowYankHistory(opts)
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "Yank History",
			finder = M.GetYankFinder(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				-- the default action (return) is to put the text into the buffer
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					M.Put(selection.ordinal)
				end)
				-- clear the yank history but only in normal mode
				map({ "n" }, "<C-c>", function(_prompt_bufnr)
					M.ClearYankHistory()
					action_state.get_current_picker(_prompt_bufnr):refresh(M.GetYankFinder())
				end)
				-- set next element to put
				map({ "i", "n" }, "<C-n>", function(_prompt_bufnr)
					local selection = action_state.get_selected_entry()
					M.yankIndex = selection.value[3]
					action_state.get_current_picker(_prompt_bufnr):refresh(M.GetYankFinder())
				end)
				-- delete element from history
				map({ "i", "n" }, "<C-d>", function(_prompt_bufnr)
					local selection = action_state.get_selected_entry()
					table.remove(M.yanks, selection.value[3])
					action_state.get_current_picker(_prompt_bufnr):refresh(M.GetYankFinder())
				end)
				-- move element up in the history
				map({ "i", "n" }, "<C-u>", function(_prompt_bufnr)
					local selection = action_state.get_selected_entry()
					M.yanks = util.Swap(M.yanks, selection.value[3], (selection.value[3] % #M.yanks) + 1)
					action_state.get_current_picker(_prompt_bufnr):refresh(M.GetYankFinder())
				end)
				return true
			end,
		})
		:find()
end

--- Open telescope picker to inspect and activate/deactivate transformers
---@param opts telescope picker options
function M.ShowTransformers(opts)
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "Transformer",
			finder = M.GetTransformerFinder(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				-- the default action is to toggle the active state of the transformer
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					-- vim.api.nvim_put({selection[1]}, "", false, true)
					M.settings.transformer[selection.index].active = not M.settings.transformer[selection.index].active
					-- selection.value[1].active = true
					action_state.get_current_picker(prompt_bufnr):refresh(M.GetTransformerFinder())
				end)
				-- move the transformer up in the execution order
				map({ "i", "n" }, "<C-u>", function(_prompt_bufnr)
					local selection = action_state.get_selected_entry()
					M.settings.transformer = util.Swap(
						M.settings.transformer,
						selection.value[2],
						(selection.value[2] % #M.settings.transformer) + 1
					)
					action_state.get_current_picker(_prompt_bufnr):refresh(M.GetTransformerFinder())
				end)
				return true
			end,
		})
		:find()
end

-- Create a finder for the transformer picker
function M.GetTransformerFinder()
	local transformerList = {}

	for i = 1, #M.settings.transformer do
		table.insert(transformerList, { M.settings.transformer[i], i })
	end

	local finder = finders.new_table({
		results = transformerList,
		entry_maker = function(entry)
			return {
				value = entry,
				display = entry[1].active and "*" .. entry[1].name or entry[1].name,
				ordinal = entry[1].name,
			}
		end,
	})

	return finder
end

-- create a finder for the yank history picker
function M.GetYankFinder()
	local yankList = {}

	for i = 1, #M.yanks do
		table.insert(yankList, { M.yanks[i], i == M.yankIndex, i })
	end

	local finder = finders.new_table({
		results = yankList,
		entry_maker = function(entry)
			return {
				value = entry,
				display = entry[2] and "*" .. entry[1] or entry[1],
				ordinal = entry[1],
			}
		end,
	})

	return finder
end

return M
