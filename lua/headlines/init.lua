local M = {}

M.namespace = vim.api.nvim_create_namespace "headlines_namespace"
local q = require "vim.treesitter.query"

local use_legacy_query = vim.fn.has "nvim-0.9.0" ~= 1

local parse_query_save = function(language, query)
    -- vim.treesitter.query.parse_query() is deprecated, use vim.treesitter.query.parse() instead
    local ok, parsed_query =
        pcall(use_legacy_query and vim.treesitter.query.parse_query or vim.treesitter.query.parse, language, query)
    if not ok then
        return nil
    end
    return parsed_query
end

M.config = {
    markdown = {
        query = parse_query_save(
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

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
            ]]
        ),
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    rmd = {
        query = parse_query_save(
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

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
            ]]
        ),
        treesitter_language = "markdown",
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    norg = {
        query = parse_query_save(
            "norg",
            [[
                [
                    (heading1_prefix)
                    (heading2_prefix)
                    (heading3_prefix)
                    (heading4_prefix)
                    (heading5_prefix)
                    (heading6_prefix)
                ] @headline

                (weak_paragraph_delimiter) @dash
                (strong_paragraph_delimiter) @doubledash

                ([(ranged_tag
                    name: (tag_name) @_name
                    (#eq? @_name "code")
                )
                (ranged_verbatim_tag
                    name: (tag_name) @_name
                    (#eq? @_name "code")
                )] @codeblock (#offset! @codeblock 0 0 1 0))

                (quote1_prefix) @quote
            ]]
        ),
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        doubledash_highlight = "DoubleDash",
        doubledash_string = "=",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    org = {
        query = parse_query_save(
            "org",
            [[
                (headline (stars) @headline)

                (
                    (expr) @dash
                    (#match? @dash "^-----+$")
                )

                (block
                    name: (expr) @_name
                    (#match? @_name "(SRC|src)")
                ) @codeblock

                (paragraph . (expr) @quote
                    (#eq? @quote ">")
                )
            ]]
        ),
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
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
    config = config or {}
    M.config = vim.tbl_deep_extend("force", M.config, config)

    -- tbl_deep_extend does not handle metatables
    for filetype, conf in pairs(config) do
        if conf.query then
            M.config[filetype].query = conf.query
        end
    end

    vim.cmd [[
        highlight default link Headline ColorColumn
        highlight default link CodeBlock ColorColumn
        highlight default link Dash LineNr
        highlight default link DoubleDash LineNr
        highlight default link Quote LineNr
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
    local last_fat_headline = -1

    for _, match, metadata in c.query:iter_matches(root, bufnr) do
        for id, node in pairs(match) do
            local capture = c.query.captures[id]
            local start_row, start_column, end_row, _ =
                unpack(vim.tbl_extend("force", { node:range() }, (metadata[id] or {}).range or {}))

            if capture == "headline" and c.headline_highlights then
                -- vim.treesitter.query.get_node_text() is deprecated, use vim.treesitter.get_node_text() instead.
                local get_text_function = use_legacy_query and q.get_node_text(node, bufnr)
                    or vim.treesitter.get_node_text(node, bufnr)
                local level = #vim.trim(get_text_function)
                local hl_group = c.headline_highlights[math.min(level, #c.headline_highlights)]
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    end_col = 0,
                    end_row = start_row + 1,
                    hl_group = hl_group,
                    hl_eol = true,
                })

                if c.fat_headlines then
                    local reverse_hl_group = M.make_reverse_highlight(hl_group)

                    local padding_above = { { c.fat_headline_upper_string:rep(width), reverse_hl_group } }
                    if start_row > 0 then
                        local line_above = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, start_row, false)[1]
                        if line_above == "" and start_row - 1 ~= last_fat_headline then
                            nvim_buf_set_extmark(bufnr, M.namespace, start_row - 1, 0, {
                                virt_text = padding_above,
                                virt_text_pos = "overlay",
                                hl_mode = "combine",
                            })
                        else
                            nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                                virt_lines_above = true,
                                virt_lines = { padding_above },
                            })
                        end
                    end

                    local padding_below = { { c.fat_headline_lower_string:rep(width), reverse_hl_group } }
                    local line_below = vim.api.nvim_buf_get_lines(bufnr, start_row + 1, start_row + 2, false)[1]
                    if line_below == "" then
                        nvim_buf_set_extmark(bufnr, M.namespace, start_row + 1, 0, {
                            virt_text = padding_below,
                            virt_text_pos = "overlay",
                            hl_mode = "combine",
                        })
                        last_fat_headline = start_row + 1
                    else
                        nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                            virt_lines = { padding_below },
                        })
                    end
                end
            end

            if capture == "dash" and c.dash_highlight and c.dash_string then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    virt_text = { { c.dash_string:rep(width), c.dash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end

            if capture == "doubledash" and c.doubledash_highlight and c.doubledash_string then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    virt_text = { { c.doubledash_string:rep(width), c.doubledash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end

            if capture == "codeblock" and c.codeblock_highlight then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
                    end_col = 0,
                    end_row = end_row,
                    hl_group = c.codeblock_highlight,
                    hl_eol = true,
                })

                local start_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
                local _, padding = start_line:find "^ +"
                local codeblock_padding = math.max((padding or 0) - left_offset, 0)

                if codeblock_padding > 0 then
                    for i = start_row, end_row do
                        nvim_buf_set_extmark(bufnr, M.namespace, i, 0, {
                            virt_text = { { string.rep(" ", codeblock_padding), "Normal" } },
                            virt_text_win_col = 0,
                            priority = 1,
                        })
                    end
                end
            end

            if capture == "quote" and c.quote_highlight and c.quote_string then
                nvim_buf_set_extmark(bufnr, M.namespace, start_row, start_column, {
                    virt_text = { { c.quote_string, c.quote_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end
        end
    end
end

return M
