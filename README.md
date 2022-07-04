# Headlines.nvim

This plugin adds horizontal highlights for text filetypes, like `markdown` and `orgmode`.

1. Background highlighting for headlines
2. Background highlighting for code blocks
3. Whole window separator for horizontal line

Treesitter grammar needs to be installed for the languages.

## Install

Use your favourite plugin manager to install.

#### Example with Packer

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- init.lua
require("packer").startup(
    function()
        use {
            'lukas-reineke/headlines.nvim',
            config = function()
                require('headlines').setup()
            end,
        }
    end
)
```

#### Example with Plug

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

```vim
" init.vim
call plug#begin('~/.vim/plugged')
Plug 'lukas-reineke/headlines.nvim'
call plug#end()

lua << EOF
require("headlines").setup()
EOF
```

## Setup

To configure headlines.nvim pass a config table into the setup function.

<br>

Default config:

```lua
require("headlines").setup {
    markdown = {
        query = vim.treesitter.parse_query(
            "markdown",
            [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock
            ]]
        ),
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
    rmd = {
        query = vim.treesitter.parse_query(
            "markdown",
            [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock
            ]]
        ),
        treesitter_language = "markdown",
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
    org = {
        query = vim.treesitter.parse_query(
            "org",
            [[
                (headline (stars) @headline)

                (
                    (expr) @dash
                    (#match? @dash "^---+$")
                )

                (block
                    name: (expr) @_name
                    (#eq? @_name "SRC")
                ) @codeblock
            ]]
        ),
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
}
```

To change any setting, pass a table with that option. Or add a completely new filetype.
You can turn off highlighting by removing that part from the query.

```lua
require("headlines").setup {
    markdown = {
        query = vim.treesitter.parse_query(
            "markdown",
            [[
                (fenced_code_block) @codeblock
            ]]
        ),
    },
    yaml = {
        query = vim.treesitter.parse_query(
            "yaml",
            [[
                (
                    (comment) @dash
                    (#match? @dash "^# ---+$")
                )
            ]]
        ),
        dash_highlight = "Dash",
    }
}
```

Please see `:help headlines.txt` for more details.

## Screenshots

All screenshots use [my custom onedark color scheme](https://github.com/lukas-reineke/onedark.nvim).

### Simple org file

```lua
vim.cmd [[highlight Headline1 guibg=#1e2718]]
vim.cmd [[highlight Headline2 guibg=#21262d]]
vim.cmd [[highlight CodeBlock guibg=#1c1c1c]]
vim.cmd [[highlight Dash guibg=#D19A66 gui=bold]]

require("headlines").setup {
    org = {
        headline_highlights = { "Headline1", "Headline2" },
    },
}
```

<img width="900" src="https://user-images.githubusercontent.com/12900252/152090098-f0fe7ad5-efea-42d9-b3d7-a4bfd6391189.png" alt="Screenshot" />
