local Config = {}

---@class HeadlineConfig
---@field query? Query
---@field headline_highlights? table<string>
---@field bullet_highlights? table<string>
---@field bullets? table<string>
---@field codeblock_highlight? string
---@field dash_highlight? string
---@field quote_highlight? string
---@field quote_string? string
---@field fat_headlines? boolean
---@field fat_headline_upper_string? string
---@field fat_headline_lower_string? string

---Get headline config defaults
---@return table<string, HeadlineConfig>
function Config.defaults()
    return {
        markdown = {},
        rmd = {},
        norg = {},
        org = {},
    }
end

---Get headline generic config defaults
---@return HeadlineConfig
function Config.generic_defaults()
    return {}
end

---Get filetype specific headline config defaults.
---If one is not found, then it returns a generic config
---@param filetype string
---@return HeadlineConfig
function Config.filetype_defaults(filetype)
    local defaults = Config.defaults()
    return defaults[filetype] or Config.generic_defaults()
end

---Merge user config with default config.
---Uses user config when applicable, otherwise uses default config
---@param user_config HeadlineConfig
---@param default_config HeadlineConfig
---@return HeadlineConfig
function Config.merge(user_config, default_config)
    local merged = {}

    merged = user_config and vim.tbl_deep_extend('force', default_config, user_config) or default_config

    -- tbl_deep_extend does not handle metatables
    if user_config.query then
        merged.query = user_config.query
    end

    return merged
end

return Config
