local Utils = {}

local use_legacy_query = (vim.fn.has('nvim-0.9.0') ~= 1)
---Parse treesitter query
---@param language string
---@param query string
---@return Query | nil
function Utils.parse_query_save(language, query)
    local ok, parsed_query = pcall(use_legacy_query and vim.treesitter.query.parse_query or vim.treesitter.query.parse, language, query)

    if not ok then
        return nil
    end

    return parsed_query
end

return Utils
