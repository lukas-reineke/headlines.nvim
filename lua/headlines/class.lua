local Headline = {}
Headline.__index = Headline

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

---@class Headline
---@field config HeadlineConfig
---@field namespace number
---@field buffer number
---@field autocmds table<number>

---Create a new Headline
---@param config? table
---@return Headline
function Headline.new(config)
    return setmetatable({
        config = config,
        namespace = '',
        buffer = 0,
        autocmds = {}
    }, Headline)
end

---Attach headline to buffer
---@param buffer number
---@return Headline
function Headline:attach(buffer)
    local refresh_autocmd = vim.api.nvim_create_autocmd({
        'FileChangedShellPost',
        'Syntax',
        'TextChanged',
        'InsertLeave',
        'WinScrolled',
    }, {
        group = 'Headlines',
        buffer = buffer,
        desc = 'Refresh buffer local headline',
        callback = function()
            self:refresh()
        end,
    })
    local delete_autocmd = vim.api.nvim_create_autocmd({
        'BufDelete',
    }, {
        group = 'Headlines',
        buffer = buffer,
        desc = 'Delete buffer local headline',
        callback = function()
            self:delete()
        end,
    })
    self.namespace = 'headline_namespace_' .. buffer
    self.buffer = buffer
    self.autocmds = {
        refresh = refresh_autocmd,
        delete = delete_autocmd
    }

    return self
end

function Headline:delete()
    vim.api.nvim_del_autocmd(self.autocmds.refresh)
    vim.api.nvim_del_autocmd(self.autocmds.delete)
end

function Headline:refresh()
    vim.print('Headline refresh: ' .. self.buffer)
end

return Headline
