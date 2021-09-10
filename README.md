# Headlines.nvim

This plugin adds 3 kind of horizontal highlights for text filetypes, like
`markdown`, `vimwiki` and `orgmode`.

1. Background highlighting for headlines
2. Background highlighting for code blocks
3. Whole window separator for horizontal line

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

````lua
require("headlines").setup {
    markdown = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        headline_pattern = "^#+",
        headline_signs = { "Headline" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
    },
    vimwiki = {
        source_pattern_start = "^{{{%a+",
        source_pattern_end = "^}}}$",
        dash_pattern = "^---+$",
        headline_pattern = "^=+",
        headline_signs = { "Headline" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
    },
    org = {
        source_pattern_start = "#%+[bB][eE][gG][iI][nN]_[sS][rR][cC]",
        source_pattern_end = "#%+[eE][nN][dD]_[sS][rR][cC]",
        dash_pattern = "^-----+$",
        headline_pattern = "^%*+",
        headline_signs = { "Headline" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
    },
}
````

To change any setting, pass a table with that option. Or add a completely new filetype.
You can turn off highlighting by passing `false`

```lua
require("headlines").setup {
    markdown = {
        headline_pattern = false,
    },
    yaml = {
        dash_pattern = "^---+$",
        dash_highlight = "Dash",
    }
}
```

Please see `:help headlines.txt`for more details.

## Screenshots

All screenshots use [my custom onedark color scheme](https://github.com/lukas-reineke/onedark.nvim).

### Simple org file

```lua
vim.cmd [[highlight Headline1 guibg=#1e2718]]
vim.cmd [[highlight Headline2 guibg=#21262d]]
vim.cmd [[highlight CodeBlock guibg=#1c1c1c]]
vim.cmd [[highlight Dash guibg=#D19A66 gui=bold]]
vim.fn.sign_define("Headline1", { linehl = "Headline1" })
vim.fn.sign_define("Headline2"  { linehl = "Headline2" })

require("headlines").setup {
    org = {
        headline_signs = { "Headline1", "Headline2" },
    },
}
```

<img width="900" src="https://i.imgur.com/0tLcXDv.jpg" alt="Screenshot" />
