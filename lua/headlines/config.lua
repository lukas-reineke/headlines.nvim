local Config = {}

local utils = require('headlines.utils')

---@class HeadlineConfig
---@field query? Query
---@field headline_highlights? table<string>
---@field bullet_highlights? table<string>
---@field bullets? table<string>
---@field codeblock_highlight? string
---@field dash_highlight? string
---@field dash_string? string
---@field doubledash_highlight? string
---@field doubledash_string? string
---@field quote_highlight? string
---@field quote_string? string
---@field fat_headlines? boolean
---@field fat_headline_upper_string? string
---@field fat_headline_lower_string? string
---@field treesitter_language? string

---Get headline config defaults
---@return table<string, HeadlineConfig>
function Config.defaults()
    return {
        markdown = {
            query = utils.parse_query_save(
                'markdown',
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
            headline_highlights = { 'Headline' },
            bullet_highlights = {
                '@text.title.1.marker.markdown',
                '@text.title.2.marker.markdown',
                '@text.title.3.marker.markdown',
                '@text.title.4.marker.markdown',
                '@text.title.5.marker.markdown',
                '@text.title.6.marker.markdown',
            },
            bullets = { '◉', '○', '✸', '✿' },
            codeblock_highlight = 'CodeBlock',
            dash_highlight = 'Dash',
            dash_string = '-',
            quote_highlight = 'Quote',
            quote_string = '┃',
            fat_headlines = true,
            fat_headline_upper_string = '▃',
            fat_headline_lower_string = '🬂',
        },
        rmd = {
            query = utils.parse_query_save(
                'markdown',
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
            treesitter_language = 'markdown',
            headline_highlights = { 'Headline' },
            bullet_highlights = {
                '@text.title.1.marker.markdown',
                '@text.title.2.marker.markdown',
                '@text.title.3.marker.markdown',
                '@text.title.4.marker.markdown',
                '@text.title.5.marker.markdown',
                '@text.title.6.marker.markdown',
            },
            bullets = { '◉', '○', '✸', '✿' },
            codeblock_highlight = 'CodeBlock',
            dash_highlight = 'Dash',
            dash_string = '-',
            quote_highlight = 'Quote',
            quote_string = '┃',
            fat_headlines = true,
            fat_headline_upper_string = '▃',
            fat_headline_lower_string = '🬂',
        },
        norg = {
            query = utils.parse_query_save(
                'norg',
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
            headline_highlights = { 'Headline' },
            bullet_highlights = {
                '@neorg.headings.1.prefix',
                '@neorg.headings.2.prefix',
                '@neorg.headings.3.prefix',
                '@neorg.headings.4.prefix',
                '@neorg.headings.5.prefix',
                '@neorg.headings.6.prefix',
            },
            bullets = { '◉', '○', '✸', '✿' },
            codeblock_highlight = 'CodeBlock',
            dash_highlight = 'Dash',
            dash_string = '-',
            doubledash_highlight = 'DoubleDash',
            doubledash_string = '=',
            quote_highlight = 'Quote',
            quote_string = '┃',
            fat_headlines = true,
            fat_headline_upper_string = '▃',
            fat_headline_lower_string = '🬂',
            treesitter_language = 'norg',
        },
        org = {
            query = utils.parse_query_save(
                'org',
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
            headline_highlights = { 'Headline' },
            bullet_highlights = {
                '@org.headline.level1',
                '@org.headline.level2',
                '@org.headline.level3',
                '@org.headline.level4',
                '@org.headline.level5',
                '@org.headline.level6',
                '@org.headline.level7',
                '@org.headline.level8',
            },
            bullets = { '◉', '○', '✸', '✿' },
            codeblock_highlight = 'CodeBlock',
            dash_highlight = 'Dash',
            dash_string = '-',
            quote_highlight = 'Quote',
            quote_string = '┃',
            fat_headlines = true,
            fat_headline_upper_string = '▃',
            fat_headline_lower_string = '🬂',
        },
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
    local merged = user_config and vim.tbl_deep_extend('force', default_config, user_config) or default_config

    -- tbl_deep_extend does not handle metatables
    if user_config.query then
        merged.query = user_config.query
    end

    return merged
end

return Config
