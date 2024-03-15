local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui")
local config = lazy.require("flutter-tools.config")

local api = vim.api
local fmt = string.format

local M = {}

local namespace = api.nvim_create_namespace("flutter_tools_closing_labels")

local function render_labels(labels, opts)
    api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    opts = opts or {}
    local highlight = opts and opts.highlight or "Comment"
    local prefix = opts and opts.prefix or "// "

    local previous_line = -1
    for _, item in ipairs(labels) do
        local line = item.range["end"].line
        -- Check if the label will overlap with the previous one
        if line ~= previous_line then
            local ok, err = pcall(api.nvim_buf_set_extmark, 0, namespace, tonumber(line), -1, {
                virt_text = {{
                    prefix .. item.label,
                    highlight,
                }},
                virt_text_pos = "eol",
                hl_mode = "combine",
            })
            if not ok then
                local name = api.nvim_buf_get_name(0)
                ui.notify(fmt("error drawing label for %s on line %d.\nbecause: ", name, line, err), ui.ERROR)
            end
            previous_line = line
        end
    end
end

function M.closing_tags(err, response, _)
    local opts = config.closing_tags
    if err or not opts.enabled then return end
    local uri = response.uri
    if uri ~= vim.uri_from_bufnr(0) then return end
    render_labels(response.labels, opts)
end

return M
