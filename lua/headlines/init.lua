local M = {}

M.namespace = vim.api.nvim_create_namespace "headlines_namespace"

M.config = {
    markdown = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        headline_pattern = "^#+",
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
    rmd = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        headline_pattern = "^#+",
        headline_signs = { "Headline" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
    vimwiki = {
        source_pattern_start = "^{{{%a+",
        source_pattern_end = "^}}}$",
        dash_pattern = "^---+$",
        headline_pattern = "^=+",
        headline_highlights = { "Headline" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        fat_headlines = true,
    },
    org = {
        source_pattern_start = "#%+[bB][eE][gG][iI][nN]_[sS][rR][cC]",
        source_pattern_end = "#%+[eE][nN][dD]_[sS][rR][cC]",
        dash_pattern = "^-----+$",
        headline_pattern = "^%*+",
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

M.refresh = function()
    local c = M.config[vim.bo.filetype]
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)

    if not c then
        return
    end

    local offset = math.max(vim.fn.line "w0" - 1, 0)
    local range = math.min(vim.fn.line "w$", vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)
    local width = vim.api.nvim_win_get_width(0)

    local source = false

    for i = 1, #lines do
        if c.source_pattern_start and c.source_pattern_end and c.codeblock_highlight then
            local _, source_start = lines[i]:find(c.source_pattern_start)
            if source_start then
                source = true
            end

            if source then
                vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1 + offset, 0, {
                    end_col = 0,
                    end_row = i + offset,
                    hl_group = c.codeblock_highlight,
                    hl_eol = true,
                })
            end

            local _, source_end = lines[i]:find(c.source_pattern_end)

            if source_end then
                source = false
            end
        end

        if c.headline_pattern and c.headline_highlights and #c.headline_highlights > 0 then
            local _, headline = lines[i]:find(c.headline_pattern)

            if headline then
                local hl_group = c.headline_highlights[math.min(headline, #c.headline_highlights)]
                vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1 + offset, 0, {
                    end_col = 0,
                    end_row = i + offset,
                    hl_group = hl_group,
                    hl_eol = true,
                })

                if c.fat_headlines then
                    local reverse_hl_group = M.make_reverse_highlight(hl_group)

                    local padding_above = { { ("▂"):rep(width), reverse_hl_group } }
                    local line_above = lines[i - 1]
                    if line_above == "" then
                        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 2 + offset, 0, {
                            virt_text = padding_above,
                            virt_text_pos = "overlay",
                            hl_mode = "combine",
                        })
                    else
                        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1 + offset, 0, {
                            virt_lines_above = true,
                            virt_lines = { padding_above },
                        })
                    end

                    local padding_below = { { ("▔"):rep(width), reverse_hl_group } }
                    local line_below = lines[i + 1]
                    if line_below == "" then
                        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i + offset, 0, {
                            virt_text = padding_below,
                            virt_text_pos = "overlay",
                            hl_mode = "combine",
                        })
                    else
                        vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1 + offset, 0, {
                            virt_lines = { padding_below },
                        })
                    end
                end
            end
        end

        if c.dash_pattern and c.dash_highlight then
            local _, dashes = lines[i]:find(c.dash_pattern)
            if dashes then
                vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1 + offset, 0, {
                    virt_text = { { (c.dash_string):rep(width), c.dash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end
        end
    end
end

return M
