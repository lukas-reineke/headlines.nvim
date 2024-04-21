local Utils = {}

Utils.use_legacy_query = (vim.fn.has('nvim-0.9.0') ~= 1)
---Parse treesitter query
---@param language string
---@param query string
---@return Query | nil
function Utils.parse_query_save(language, query)
    local ok, parsed_query = pcall(Utils.use_legacy_query and vim.treesitter.query.parse_query or vim.treesitter.query.parse, language, query)

    if not ok then
        return nil
    end

    return parsed_query
end

---Wrapper for nvim_buf_set_extmark with added safety
---@param buffer buffer
---@param ns_id number
---@param line number
---@param col number
---@param opts? table<string, any>
function Utils.set_extmark(buffer, ns_id, line, col, opts)
    pcall(vim.api.nvim_buf_set_extmark, buffer, ns_id, line, col, opts)
end

return Utils
