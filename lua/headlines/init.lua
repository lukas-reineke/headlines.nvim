local M = {}

function M.setup()
    vim.api.nvim_create_augroup('Headlines', {})
    vim.api.nvim_set_hl(0, 'Headline',   { default = true, link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'CodeBlock',  { default = true, link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'Dash',       { default = true, link = 'LineNr' })
    vim.api.nvim_set_hl(0, 'DoubleDash', { default = true, link = 'LineNr' })
    vim.api.nvim_set_hl(0, 'Qoute',      { default = true, link = 'LineNr' })
end

return M
