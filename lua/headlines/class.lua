local Headline = {}
Headline.__index = Headline

local renderer = require('headlines.renderer')
local config_manager = require('headlines.config')

---@class Headline
---@field config HeadlineConfig
---@field namespace number
---@field buffer buffer
---@field autocmds table<number>
---@field attach fun(self: Headline, buffer: buffer): Headline
---@field delete fun(self: Headline)
---@field refresh fun(self: Headline)

---Create a new Headline
---@param config? HeadlineConfig
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
---@param buffer buffer
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

    local filetype = vim.api.nvim_buf_get_option(buffer, 'filetype')
    self.config = config_manager.merge(self.config, config_manager.filetype_defaults(filetype))
    self.namespace = vim.api.nvim_create_namespace('headline_namespace_' .. buffer)
    self.buffer = buffer
    self.autocmds = {
        refresh = refresh_autocmd,
        delete = delete_autocmd
    }

    self:refresh()

    return self
end

function Headline:delete()
    vim.api.nvim_del_autocmd(self.autocmds.refresh)
    vim.api.nvim_del_autocmd(self.autocmds.delete)
end

function Headline:refresh()
    renderer.render(self)
end

return Headline
