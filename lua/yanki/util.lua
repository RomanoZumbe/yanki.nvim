local M = {}
-- Returns a dot repeatable version of a function to be used in keymaps
-- that pressing `.` will repeat the action.
-- Example: `vim.keymap.set('n', 'ct', dot_repeat(function() print(os.clock()) end), { expr = true })`
-- Setting expr = true in the keymap is required for this function to make the keymap repeatable
-- based on gist: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
function M.dot_repeat(callback --[[Function]])
    _G.dot_repeat_callback = callback
    vim.go.operatorfunc = 'v:lua.dot_repeat_callback'
    vim.cmd("normal! g@l")
end

-- swap to table elements
function M.Swap(Table, Pos1, Pos2)
    Table[Pos1], Table[Pos2] = Table[Pos2], Table[Pos1]
    return Table
end

return M
