local Headline = {}
Headline.__index = Headline

--local q = require('vim.treesitter.query')

local use_legacy_query = vim.fn.has "nvim-0.9.0" ~= 1
local parse_query_save = function(language, query)
    -- vim.treesitter.query.parse_query() is deprecated, use vim.treesitter.query.parse() instead
    local ok, parsed_query =
        pcall(use_legacy_query and vim.treesitter.query.parse_query or vim.treesitter.query.parse, language, query)
    if not ok then
        return nil
    end
    return parsed_query
end

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
---@field autocmds table<number>
---@field namespace number

---@type table<string, HeadlineConfig>
Headline.default_config = {
    markdown = {
        query = parse_query_save(
        "markdown",
        [[
        (atx_heading [
        (atx_h1_marker)
        (atx_h2_marker)
        (atx_h3_marker)
        (atx_h4_marker)
        (atx_h5_marker)
        (atx_h6_marker)
        ] @headline)

        (thematic_break) @dash

        (fenced_code_block) @codeblock

        (block_quote_marker) @quote
        (block_quote (paragraph (inline (block_continuation) @quote)))
        (block_quote (paragraph (block_continuation) @quote))
        (block_quote (block_continuation) @quote)
        ]]
        ),
        headline_highlights = { "Headline" },
        bullet_highlights = {
            "@text.title.1.marker.markdown",
            "@text.title.2.marker.markdown",
            "@text.title.3.marker.markdown",
            "@text.title.4.marker.markdown",
            "@text.title.5.marker.markdown",
            "@text.title.6.marker.markdown",
        },
        bullets = { "◉", "○", "✸", "✿" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    rmd = {
        query = parse_query_save(
        "markdown",
        [[
        (atx_heading [
        (atx_h1_marker)
        (atx_h2_marker)
        (atx_h3_marker)
        (atx_h4_marker)
        (atx_h5_marker)
        (atx_h6_marker)
        ] @headline)

        (thematic_break) @dash

        (fenced_code_block) @codeblock

        (block_quote_marker) @quote
        (block_quote (paragraph (inline (block_continuation) @quote)))
        (block_quote (paragraph (block_continuation) @quote))
        (block_quote (block_continuation) @quote)
        ]]
        ),
        treesitter_language = "markdown",
        headline_highlights = { "Headline" },
        bullet_highlights = {
            "@text.title.1.marker.markdown",
            "@text.title.2.marker.markdown",
            "@text.title.3.marker.markdown",
            "@text.title.4.marker.markdown",
            "@text.title.5.marker.markdown",
            "@text.title.6.marker.markdown",
        },
        bullets = { "◉", "○", "✸", "✿" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    norg = {
        query = parse_query_save(
        "norg",
        [[
        [
        (heading1_prefix)
        (heading2_prefix)
        (heading3_prefix)
        (heading4_prefix)
        (heading5_prefix)
        (heading6_prefix)
        ] @headline

        (weak_paragraph_delimiter) @dash
        (strong_paragraph_delimiter) @doubledash

        ([(ranged_tag
        name: (tag_name) @_name
        (#eq? @_name "code")
        )
        (ranged_verbatim_tag
        name: (tag_name) @_name
        (#eq? @_name "code")
        )] @codeblock (#offset! @codeblock 0 0 1 0))

        (quote1_prefix) @quote
        ]]
        ),
        headline_highlights = { "Headline" },
        bullet_highlights = {
            "@neorg.headings.1.prefix",
            "@neorg.headings.2.prefix",
            "@neorg.headings.3.prefix",
            "@neorg.headings.4.prefix",
            "@neorg.headings.5.prefix",
            "@neorg.headings.6.prefix",
        },
        bullets = { "◉", "○", "✸", "✿" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        doubledash_highlight = "DoubleDash",
        doubledash_string = "=",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
    org = {
        query = parse_query_save(
        "org",
        [[
        (headline (stars) @headline)

        (
        (expr) @dash
        (#match? @dash "^-----+$")
        )

        (block
        name: (expr) @_name
        (#match? @_name "(SRC|src)")
        ) @codeblock

        (paragraph . (expr) @quote
        (#eq? @quote ">")
        )
        ]]
        ),
        headline_highlights = { "Headline" },
        bullet_highlights = {
            "@org.headline.level1",
            "@org.headline.level2",
            "@org.headline.level3",
            "@org.headline.level4",
            "@org.headline.level5",
            "@org.headline.level6",
            "@org.headline.level7",
            "@org.headline.level8",
        },
        bullets = { "◉", "○", "✸", "✿" },
        codeblock_highlight = "CodeBlock",
        dash_highlight = "Dash",
        dash_string = "-",
        quote_highlight = "Quote",
        quote_string = "┃",
        fat_headlines = true,
        fat_headline_upper_string = "▃",
        fat_headline_lower_string = "🬂",
    },
}


---Create a new Headline
---@param conf? table
---@return Headline
function Headline.new(conf)
    local config = conf and vim.tbl_deep_extend('force', Headline.default_config[vim.bo.filetype] or {}, conf)
    or (Headline.default_config[vim.bo.filetype] or {})

    local bufnr = vim.api.nvim_get_current_buf()

    local headline = setmetatable({
        config = config,
        namespace = 'headline_namespace_' .. bufnr
    }, Headline)

    local refresh_autocmd = vim.api.nvim_create_autocmd({
        'FileChangedShellPost',
        'Syntax',
        'TextChanged',
        'InsertLeave',
        'WinScrolled',
    }, {
        group = 'Headlines',
        buffer = bufnr,
        desc = 'Refresh buffer local headline',
        callback = function()
            headline:refresh()
        end,
    })
    local delete_autocmd = vim.pi.nvim_create_autocmd({
        'BufDelete',
    }, {
        group = 'Headlines',
        buffer = bufnr,
        desc = 'Delete buffer local headline',
        callback = function()
            headline:delete()
        end,
    })

    headline.autocmds = {
        refresh = refresh_autocmd,
        delete = delete_autocmd
    }

    return headline
end

function Headline:delete()
    vim.api.nvim_del_autocmd(self.autocmds.refresh)
    vim.api.nvim_del_autocmd(self.autocmds.delete)
end

function Headline:refresh()
    vim.print('Headline refresh')
end
