local M = {}

M.dash_namespace = vim.api.nvim_create_namespace "headlines_dash_namespace"
M.sign_namespace = "headlines_sign_namespace"

M.config = {
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

M.reset_highlights = function()
    for highlight_name, highlight in pairs {
        Headline = "highlight link Headline ColorColumn",
        CodeBlock = "highlight link CodeBlock ColorColumn",
        Dash = "highlight link Dash LineNr",
    } do
        local current_highlight = vim.fn.synIDtrans(vim.fn.hlID(highlight_name))
        if vim.fn.synIDattr(current_highlight, "fg") == "" and vim.fn.synIDattr(current_highlight, "bg") == "" then
            vim.cmd(highlight)
        end
    end
end

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.fn.sign_define("CodeBlock", { linehl = "CodeBlock" })
    vim.fn.sign_define("Headline", { linehl = "Headline" })

    vim.cmd [[augroup Headlines]]
    vim.cmd [[autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua require('headlines').refresh()]]
    vim.cmd [[augroup END]]
end

M.refresh = function()
    local c = M.config[vim.bo.filetype]
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.sign_unplace(M.sign_namespace, { buffer = bufnr })
    vim.api.nvim_buf_clear_namespace(0, M.dash_namespace, 1, -1)

    if not c then
        return
    end

    M.reset_highlights()

    local offset = math.max(vim.fn.line "w0" - 1, 0)
    local range = math.min(vim.fn.line "w$", vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)

    local source = false

    for i = 1, #lines do
        if c.source_pattern_start and c.source_pattern_end and c.codeblock_sign then
            local _, source_start = lines[i]:find(c.source_pattern_start)
            if source_start then
                source = true
            end

            if source then
                vim.fn.sign_place(0, M.sign_namespace, c.codeblock_sign, bufnr, { lnum = i + offset })
            end

            local _, source_end = lines[i]:find(c.source_pattern_end)

            if source_end then
                source = false
            end
        end

        if c.headline_pattern and c.headline_signs and #c.headline_signs > 0 then
            local _, headline = lines[i]:find(c.headline_pattern)

            if headline then
                vim.fn.sign_place(
                    0,
                    M.sign_namespace,
                    c.headline_signs[math.min(headline, #c.headline_signs)],
                    bufnr,
                    { lnum = i + offset }
                )
            end
        end

        if c.dash_pattern and c.dash_highlight then
            local _, dashes = lines[i]:find(c.dash_pattern)
            if dashes then
                vim.api.nvim_buf_set_extmark(bufnr, M.dash_namespace, i - 1 + offset, 0, {
                    virt_text = { { ("-"):rep(vim.api.nvim_win_get_width(0)), c.dash_highlight } },
                    virt_text_pos = "overlay",
                    hl_mode = "combine",
                })
            end
        end
    end
end

return M
