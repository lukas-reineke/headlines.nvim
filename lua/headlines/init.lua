local M = {}

function M.setup()
    vim.api.nvim_create_augroup('Headlines', {})
    vim.api.nvim_set_hl(0, 'Headline', { link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'CodeBlock', { link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'Dash', { link = 'LineNr' })
end

return M
