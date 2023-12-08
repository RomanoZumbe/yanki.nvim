# yanki.nvim


Yanki is a Neovim plugin designed to enhance your yanking experience by creating a yank history. It empowers users to easily insert from this history sequentially, making actions repeatable.

## ✨ Features

- **Yank History:** Yanki maintains a history of your yanks, allowing you to access and reuse them conveniently.

- **Sequential Insertion:** Easily insert text from the yank history in a sequential manner, enhancing your workflow and making repetitive actions a breeze.

- **Repeatable Actions:** Yanki ensures that your put actions are repeatable, providing a consistent and efficient editing experience.

- **Customizable Text Manipulation:** Yanki allows users to define Lua functions to customize the yanked text before it is added to the history.
  This powerful feature enables advanced users to apply transformations, substitutions, or any desired modifications to the yanked content. 
  Users can easily define their own Lua functions and create chains of modifications, allowing for a flexible and extensible text manipulation process.

## 📦 Installation

### [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "RomanoZumbe/yanki.nvim",
    config = function()
        require("yanki").setup()
    end,
    lazy = false
}
```

## ⚙️Configuration

The Yanki plugin offers a flexible configuration to tailor the yanking behavior according to your needs. One key parameter is the `transformer` setup option, 
allowing you to define a list of transformations that will be applied to the yanked text before it is added to the history.

### Example Configuration

```lua
{
    "RomanoZumbe/yanki.nvim",
    config = function()
        require("yanki").setup({
            transformer = {
                {
                    name = "Split by new line",
                    action = function(text)
                        return vim.fn.split(text, '\n')
                    end,
                    active = true
                }, {
                    name = "Surround with register a",
                    action = function(text)
                        local closings = {
                            ['('] = ')',
                            ['['] = ']',
                            ['{'] = '}',
                            ['<'] = '>'
                        }
                        local surroundWith = vim.fn.getreg('a', 1)
                        local surroundEnd =
                            closings[surroundWith] or surroundWith

                        text = surroundWith .. text .. surroundEnd
                        return text
                    end,
                    active = false
                }, {
                    name = "Add to table in register b",
                    action = function(text)
                        local tableName = vim.fn.getreg('b', 1)
                        return "table.insert(" .. tableName .. "," .. text ..
                                   ")"
                    end,
                    active = false
                }, {
                    name = "Replace placeholder(reg c) in template (reg d)",
                    action = function(text)
                        local placeholder = vim.fn.getreg('c', 1)
                        local template = vim.fn.getreg('d', 1)
                        return string.gsub(template, placeholder, text)
                    end,
                    active = false
                }
            }
        })
    end,
    lazy = false
}
```

**Explanation:**

- The `transformer` parameter is an array of objects, each representing a specific transformation.

- Each transformation has a `name` for identification in the configuration, an `action` function defining the transformation logic, and an `active`
  boolean indicating whether the transformation should be applied by default.

- The provided example includes transformations like splitting by a new line, surrounding with a specified register, adding to a table in a specified 
  register, and replacing a placeholder in a template using registers.
  
## Yanki Plugin Commands

The Yanki plugin offers several commands to enhance your yanking experience and manage the yank history effectively.

### 1. PutNextLine Command

```vim
:PutNextLine
```

Description:
Inserts the next text from the yank history on each line in the specified range.
Designed for a range of lines, making it convenient for inserting yanked text sequentially.
Repeatable command, allowing for easy insertion of yanked text on subsequent lines.

### 2. ShowYankHistory Command

```vim
:ShowYankHistory
```

Description:

- Displays the current yank history in a customizable Telescope window.
- The next entry to be inserted is marked with an asterisk (*).
- Use <C-n> to select the next entry for insertion.
- Press <C-c> to clear all entries in the yank history. (this works only in normal mode)
- Use <C-d> to delete the currently highlighted entry.
- Entries can be moved using <C-u>.

### 3. CleanYankHistory Command

```vim
:CleanYankHistory
```

Description:
Clears the current yank history, removing all stored entries.
Useful when you want to start fresh or manage the size of the yank history.

### 4. ShowTransformers Command

```vim
:ShowTransformers
```

Description:

- Shows the available transformations that are applied during yanking.
- Allows for toggling individual transformers on and off using the Enter key.
- Enables rearranging the order of transformers using <C-u> (Ctrl + u).
- Useful for dynamically customizing the sequence and active state of applied text transformations.

### Keybinding examples

```lua
-- PutNextLine
vim.api.nvim_set_keymap('n', '<leader>p', ':PutNextLine<CR>', { noremap = true, silent = true })

-- ShowYankHistory
vim.api.nvim_set_keymap('n', '<leader>yl', ':ShowYankHistory<CR>', { noremap = true, silent = true })

-- CleanYankHistory
vim.api.nvim_set_keymap('n', '<leader>yc', ':CleanYankHistory<CR>', { noremap = true, silent = true })

-- ShowTransformers
vim.api.nvim_set_keymap('n', '<leader>yt', ':ShowTransformers<CR>', { noremap = true, silent = true })
```
