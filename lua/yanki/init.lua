local util = require "yanki.util"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local state = require "telescope.state"

local M = {}

function M.setup(parm)
    parm = (parm or {})
    vim.api.nvim_exec([[
      augroup WatchYankRegister
        autocmd!
        autocmd TextYankPost * lua require("yanki").OnTextYank()
      augroup END
    ]], false)
    M.settings = parm
end

M.yanks = {}
M.yankIndex = 1

function M.OnTextYank()
    local yankedText = vim.fn.getreg('"', 1)

    print(vim.inspect(M.settings.transformer))
    for k, transformer in ipairs(M.settings.transformer) do
        if transformer.active then
            yankedText = transformer.action(yankedText)
        end
    end

    if M.settings.SplitLines then
        local lines = vim.fn.split(yankedText, '\n')

        for _, line in ipairs(lines) do table.insert(M.yanks, line) end
    else
        table.insert(M.yanks, yankedText)
    end
end

function M.PutNext()
    if #M.yanks == 0 then return end
    local nextPut = M.yanks[M.yankIndex]
    M.Put(nextPut)
end

function M.Put(text)
    local currentLine = vim.fn.line('.')
    local currentCol = vim.fn.col('.')

    if M.settings.PutInNewLine or string.sub(text, -1) == "\n" then
        local lines = vim.fn.split(text, '\n')

        vim.api.nvim_buf_set_lines(0, currentLine, currentLine, false, lines)
    else
        local lines = vim.split(text, '\n')
        vim.api.nvim_buf_set_text(0, currentLine - 1, currentCol - 1,
                                  currentLine - 1, currentCol - 1, lines)
    end
    M.yankIndex = (M.yankIndex % #M.yanks) + 1
end

function M.ClearYankHistory()
    M.yanks = {}
    M.yankIndex = 1
end

function M.ShowYankHistory(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "Yank History",
        finder = M.GetYankFinder(),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                -- print(vim.inspect(selection))
                -- vim.api.nvim_put({selection[1]}, "", false, true)
                M.Put(selection.ordinal)
            end)
            map({"i", "n"}, "<C-c>", function(_prompt_bufnr)
                M.ClearYankHistory()
                action_state.get_current_picker(_prompt_bufnr):refresh(
                    M.GetYankFinder())
            end)
            map({"i", "n"}, "<C-n>", function(_prompt_bufnr)
                local selection = action_state.get_selected_entry()
                M.yankIndex = selection.value[3]
                action_state.get_current_picker(_prompt_bufnr):refresh(
                    M.GetYankFinder())
            end)
            map({"i", "n"}, "<C-d>", function(_prompt_bufnr)
                local selection = action_state.get_selected_entry()
                table.remove(M.yanks, selection.value[3])
                action_state.get_current_picker(_prompt_bufnr):refresh(
                    M.GetYankFinder())
            end)
            map({"i", "n"}, "<C-u>", function(_prompt_bufnr)
                local selection = action_state.get_selected_entry()
                M.yanks = util.Swap(M.yanks, selection.value[3],
                                    (selection.value[3] % #M.yanks) + 1)
                action_state.get_current_picker(_prompt_bufnr):refresh(
                    M.GetYankFinder())
            end)
            return true
        end
    }):find()
end

function M.ShowTransformers(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "Yank History",
        finder = M.GetTransformerFinder(),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                print("enter pressed")
                print(vim.inspect(selection.value[1].active))
                -- vim.api.nvim_put({selection[1]}, "", false, true)
                M.settings.transformer[selection.index].active = not M.settings
                                                                     .transformer[selection.index]
                                                                     .active
                -- selection.value[1].active = true
                action_state.get_current_picker(prompt_bufnr):refresh(
                    M.GetTransformerFinder())
            end)
            return true
        end
    }):find()
end

function M.GetTransformerFinder()
    local transformerList = {}

    for i = 1, #M.settings.transformer do
        print(vim.inspect(M.settings.transformer[i]))
        table.insert(transformerList, {M.settings.transformer[i], i})
    end

    print(vim.inspect(transformerList))

    local finder = finders.new_table {
        results = transformerList,
        entry_maker = function(entry)
            return {
                value = entry,
                display = entry[1].active and "*" .. entry[1].name or
                    entry[1].name,
                ordinal = entry[1].name
            }
        end
    }

    return finder
end

function M.GetYankFinder()
    local yankList = {}

    for i = 1, #M.yanks do
        table.insert(yankList, {M.yanks[i], i == M.yankIndex, i})
    end

    local finder = finders.new_table {
        results = yankList,
        entry_maker = function(entry)
            return {
                value = entry,
                display = entry[2] and "*" .. entry[1] or entry[1],
                ordinal = entry[1]
            }
        end
    }

    return finder
end

return M
