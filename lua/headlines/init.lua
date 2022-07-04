local M = {}

M.namespace = vim.api.nvim_create_namespace "headlines_namespace"
local q = require "vim.treesitter.query"

M.config = {
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

M.make_reverse_highlight = function(name)
    local reverse_name = name .. "Reverse"

    if vim.fn.synIDattr(reverse_name, "fg") ~= "" then
        return reverse_name
    end

    local highlight = vim.fn.synIDtrans(vim.fn.hlID(name))
    local gui_bg = vim.fn.synIDattr(highlight, "bg", "gui")
    local cterm_bg = vim.fn.synIDattr(highlight, "bg", "cterm")

    if gui_bg == "" then
        gui_bg = "None"
    end
    if cterm_bg == "" then
        cterm_bg = "None"
    end

    vim.cmd(string.format("highlight %s guifg=%s ctermfg=%s", reverse_name, gui_bg or "None", cterm_bg or "None"))
    return reverse_name
end

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.cmd [[
        highlight default link Headline ColorColumn
        highlight default link CodeBlock ColorColumn
        highlight default link Dash LineNr
    ]]

    vim.cmd [[
        augroup Headlines
        autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua require('headlines').refresh()
        augroup END
    ]]
end

local nvim_buf_set_extmark = function(...)
    pcall(vim.api.nvim_buf_set_extmark, ...)
end

M.refresh = function()
    local c = M.config[vim.bo.filetype]
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)

    if not c or not c.query then
        return
    end

    local language = c.treesitter_language or vim.bo.filetype
    local language_tree = vim.treesitter.get_parser(bufnr, language)
    local syntax_tree = language_tree:parse()
    local root = syntax_tree[1]:root()
    local win_view = vim.fn.winsaveview()
    local left_offset = win_view.leftcol
    local width = vim.api.nvim_win_get_width(0)

    for _, match, _ in c.query:iter_matches(root, bufnr) do
        for id, node in pairs(match) do
            local capture = c.query.captures[id]

            if capture == "headline" then
                local level = #q.get_node_text(node, bufnr)
                local hl_group = c.headline_highlights[math.min(level, #c.headline_highlights)]
                local start = node:start()
                nvim_buf_set_extmark(bufnr, M.namespace, start, 0, {
                    end_col = 0,
                    end_row = start + 1,
                    hl_group = hl_group,
                    hl_eol = true,
                })

                if c.fat_headlines then
                    local reverse_hl_group = M.make_reverse_highlight(hl_group)

                    local padding_above = { { ("▂"):rep(width), reverse_hl_group } }
                    if start > 0 then
                        local line_above = vim.api.nvim_buf_get_lines(bufnr, start - 1, start, false)[1]
                        if line_above == "" then
                            nvim_buf_set_extmark(bufnr, M.namespace, start - 1, 0, {
                                virt_text = padding_above,
                                virt_text_pos = "overlay",
                                hl_mode = "combine",
                            })
                        else
                            nvim_buf_set_extmark(bufnr, M.namespace, start - 1, 0, {
                                virt_lines_above = true,
                                virt_lines = { padding_above },
                            })
                        end
                    end

                    local padding_below = { { ("▔"):rep(width), reverse_hl_group } }
                    local line_below = vim.api.nvim_buf_get_lines(bufnr, start + 1, start + 2, false)[1]
                    if line_below == "" then
                        nvim_buf_set_extmark(bufnr, M.namespace, start + 1, 0, {
                            virt_text = padding_below,
                            virt_text_pos = "overlay",
                            hl_mode = "combine",
                        })
                    else
                        nvim_buf_set_extmark(bufnr, M.namespace, start, 0, {
                            virt_lines = { padding_below },
                        })
                    end
                end
            end

            if capture == "dash" then
                local start = node:start()
                nvim_buf_set_extmark(bufnr, M.namespace, start, 0, {
                    virt_text = { { c.dash_string:rep(width), c.dash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end

            if capture == "codeblock" then
                local start = node:start()
                local end_ = node:end_()
                nvim_buf_set_extmark(bufnr, M.namespace, start, 0, {
                    end_col = 0,
                    end_row = end_,
                    hl_group = c.codeblock_highlight,
                    hl_eol = true,
                })

                local start_line = vim.api.nvim_buf_get_lines(bufnr, start, start + 1, false)[1]
                local _, padding = start_line:find "^ +"
                local codeblock_padding = math.max((padding or 0) - left_offset, 0)

                if codeblock_padding > 0 then
                    for i = start, end_ do
                        nvim_buf_set_extmark(bufnr, M.namespace, i, 0, {
                            virt_text = { { string.rep(" ", codeblock_padding), "Normal" } },
                            virt_text_win_col = 0,
                            priority = 1,
                        })
                    end
                end
            end
        end
    end
end

return M
