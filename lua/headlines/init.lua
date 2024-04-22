local M = {}

function M.setup()
    vim.api.nvim_create_augroup('Headlines', {})
    vim.api.nvim_set_hl(0, 'Headline',   { default = true, link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'CodeBlock',  { default = true, link = 'ColorColumn' })
    vim.api.nvim_set_hl(0, 'Dash',       { default = true, link = 'LineNr' })
    vim.api.nvim_set_hl(0, 'DoubleDash', { default = true, link = 'LineNr' })
    vim.api.nvim_set_hl(0, 'Qoute',      { default = true, link = 'LineNr' })
end

---Attach headline to buffer
---@param buffer buffer
---@param config table<string, any>
function M.attach(buffer, config)
    require('headlines.class').new(config):attach(buffer)
end

return M
