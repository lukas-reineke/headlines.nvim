local Renderer = {}

---Render headlines
---@param headline Headline
function Renderer.render(headline)
    vim.api.nvim_buf_clear_namespace(headline.buffer, headline.namespace, 0, -1)
    vim.api.nvim_buf_set_extmark(headline.buffer, headline.namespace, 0, 0, {
        end_row = 1,
        end_col = 0,
        hl_group = 'Headline',
        hl_eol = true,
    })
end

return Renderer
