local Renderer = {}

local utils = require('headlines.utils')
local treesitter_query = require('vim.treesitter.query')

---Render headlines
---@param headline Headline
function Renderer.render(headline)
    local conf = headline.config
    vim.print(conf.headline_highlights)
    vim.api.nvim_buf_clear_namespace(headline.buffer, headline.namespace, 0, -1)

    if not conf or not conf.query then
        return
    end

    local language = conf.treesitter_language or vim.api.nvim_buf_get_option(headline.buffer, 'filetype')
    local language_tree = vim.treesitter.get_parser(headline.buffer, language)
    local syntax_tree = language_tree:parse()
    local root = syntax_tree[1]:root()
    local win_view = vim.fn.winsaveview()
    local left_offset = win_view.leftcol
    local width = vim.api.nvim_win_get_width(0)
    local last_fat_headline = -1

    -- INFO: ignore warning. last two args can be nil
    for _, match, metadata in conf.query:iter_matches(root, headline.buffer) do
        for id, node in pairs(match) do
            local capture = conf.query.captures[id]
            local start_row, start_column, end_row, end_column = unpack(vim.tbl_extend('force', { node:range() }, (metadata[id] or {}).range or {}))

            if capture == 'headline' and conf.headline_highlights then
                local get_text_function = utils.use_legacy_query and treesitter_query.get_node_text(node, headline.buffer)
                                          or vim.treesitter.get_node_text(node, headline.buffer)

                local level = #vim.trim(get_text_function)
                local hl_group = conf.headline_highlights[math.min(level, #conf.headline_highlights)]
                local bullet_hl_group = conf.bullet_highlights[math.min(level, #conf.bullet_highlights)]

                local virt_text = {}
                if conf.bullets and #conf.bullets > 0 then
                    local bullet = conf.bullets[((level - 1) % #conf.bullets) + 1]
                    virt_text[1] = { string.rep(" ", level - 1) .. bullet, { hl_group, bullet_hl_group }}
                end

                utils.set_extmark(headline.buffer, headline.namespace, start_row, 0, {
                    end_col = 0,
                    end_row = start_row + 1,
                    hl_group = hl_group,
                    virt_text = virt_text,
                    virt_text_pos = 'overlay',
                    hl_eol = true
                })
            end

            if capture == 'dash' and conf.dash_highlight and conf.dash_string then
                utils.set_extmark(headline.buffer, headline.namespace, start_row, 0, {
                    virt_text = { { conf.dash_string:rep(width), conf.dash_highlight } },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                })
            end

            if capture == 'doubledash' and conf.doubledash_highlight and conf.doubledash_string then
                utils.set_extmark(headline.buffer, headline.namespace, start_row, 0, {
                    virt_text = { { conf.doubledash_string:rep(width), conf.doubledash_highlight } },
                    virt_text_pos = 'overlay',
                    hl_mode = 'combine',
                })
            end

            if capture == 'codeblock' and conf.codeblock_highlight then
                utils.set_extmark(headline.buffer, headline.namespace, start_row, 0, {
                    end_col = 0,
                    end_row = end_row,
                    hl_group = conf.codeblock_highlight,
                    hl_eol = true,
                })

                local start_line = vim.api.nvim_buf_get_lines(headline.buffer, start_row, start_row + 1, false)[1]
                local _, padding = start_line:find '^ +'
                local codeblock_padding = math.max((padding or 0) - left_offset, 0)

                if codeblock_padding > 0 then
                    for i = start_row, end_row - 1 do
                        utils.set_extmark(headline.buffer, headline.namespace, i, 0, {
                            virt_text = { { string.rep(' ', codeblock_padding), 'Normal' } },
                            virt_text_win_col = 0,
                            priority = 1,
                        })
                    end
                end
            end

            if capture == 'quote' and conf.quote_highlight and conf.quote_string then
                if vim.api.nvim_buf_get_option(headline.buffer, 'filetype') == 'markdown' then
                    local text = vim.api.nvim_buf_get_text(headline.buffer, start_row, start_column, end_row, end_column, {})[1]
                    utils.set_extmark(headline.buffer, headline.namespace, start_row, start_column, {
                        virt_text = { { text:gsub('>', conf.quote_string), conf.quote_highlight } },
                        virt_text_pos = 'overlay',
                        hl_mode = 'combine',
                    })
                else
                    utils.set_extmark(headline.buffer, headline.namespace, start_row, start_column, {
                        virt_text = { { conf.quote_string, conf.quote_highlight } },
                        virt_text_pos = 'overlay',
                        hl_mode = 'combine',
                    })
                end
            end
        end
    end
end

return Renderer
