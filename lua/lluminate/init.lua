local M = {}


M.options = {
    include_definition = false,
    include_hover = true
}

-- Function to get LSP client
local function get_lsp_client()
    local clients = vim.lsp.buf_get_clients(0)
    for _, client in pairs(clients) do
        if client.server_capabilities.definitionProvider then
            return client
        end
    end
    return nil
end

-- Function to find the definition of a symbol using LSP
local function find_definition(bufnr, line, character, symbol)
    local client = get_lsp_client()
    if not client then
        return "LSP not available for " .. symbol
    end

    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = { line = line, character = character }
    }

    local result = ""

    -- Definition
    if M.options.include_definition then
        local def_result, def_err = client.request_sync("textDocument/definition", params, 30000, bufnr)

        if def_err then
            result = result .. "Error finding definition for " .. symbol .. ": " .. tostring(def_err) .. "\n"
        elseif def_result and def_result.result and not vim.tbl_isempty(def_result.result) then
            local definition = def_result.result[1]
            if definition.uri and definition.range then
                local uri = definition.uri
                local range = definition.range

                -- Read the file content
                local filename = vim.uri_to_fname(uri)
                local lines = vim.fn.readfile(filename)

                if lines and #lines > 0 then
                    local start_line = range.start.line
                    local end_line = range['end'].line
                    local definition_lines = table.concat(lines, "\n", start_line + 1, end_line + 1)
                    result = result .. string.format("Definition of %s:\n%s\n", symbol, definition_lines)
                else
                    result = result .. "Unable to read definition file for " .. symbol .. "\n"
                end
            else
                --result = result .. "Incomplete definition information for " .. symbol .. "\n"
                result = result
            end
        else
                result = result
            --result = result .. "No definition found for " .. symbol .. "\n"
        end
    end

    -- Hover
    if M.options.include_hover then
        local hover, hover_err = client.request_sync("textDocument/hover", params, 30000, bufnr)
        if hover_err then
            result = result .. "Error finding hover for " .. symbol .. ": " .. tostring(hover_err) .. "\n"
        else
            local initial_hover_text = "No hover information available"
            local hover_text = initial_hover_text
            if hover and hover.result and hover.result.contents then
                local contents = hover.result.contents
                if type(contents) == "string" then
                    hover_text = contents
                elseif type(contents) == "table" then
                    if contents.kind == "markdown" then
                        hover_text = contents.value
                    elseif contents.language then
                        hover_text = contents.value
                    else
                        hover_text = table.concat(vim.tbl_filter(function(item)
                            return type(item) == "string"
                        end, contents), "\n")
                    end
                end
            end

            if hover_text == initial_hover_text or hover_text == '' then
                result = result
            else
                result = result .. string.format("Hover of %s:\n%s\n", symbol, hover_text)
            end
        end
    end

    return result ~= "" and result or nil
end

-- Function to get hover information for a symbol
local function get_hover_info(bufnr, line, character, symbol)
    local client = get_lsp_client()
    if not client then
        return nil
    end

    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = { line = line, character = character }
    }

    local result, err = client.request_sync("textDocument/hover", params, 1000, bufnr)

    if err or not result or not result.result or not result.result.contents then
        return nil
    end

    local contents = result.result.contents
    if type(contents) == "string" then
        return contents
    elseif type(contents) == "table" and contents.value then
        return contents.value
    end

    return nil
end


local function get_visual_selection()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local bufnr = vim.api.nvim_get_current_buf()
    local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
    local end_row, end_col = end_pos[2] - 1, end_pos[3]

    if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    if #lines == 0 then return "" end

    lines[1] = string.sub(lines[1], start_col + 1)
    if #lines > 1 then
        lines[#lines] = string.sub(lines[#lines], 1, end_col)
    else
        lines[1] = string.sub(lines[1], 1, end_col - start_col)
    end

    return table.concat(lines, "\n"), start_row, start_col, end_row, end_col
end

-- Function to enrich the context of copied code
local function enrich_context_internal(start_row, start_col, end_row, end_col)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    local selected_text = table.concat(lines, "\n")

    local enriched_context = selected_text .. "\n\nAdditional Context:\n"
    local processed_symbols = {}

    for i = start_row, end_row do
        local line = lines[i - start_row + 1]
        for symbol in string.gmatch(line, "[%w_]+") do
            if not processed_symbols[symbol] then
                local start_symbol_col = string.find(line, symbol, 1, true)
                if start_symbol_col then
                    start_symbol_col = start_symbol_col - 1  -- Convert to 0-based index
                    local definition = find_definition(bufnr, i, start_symbol_col, symbol)
                    if definition then
                        enriched_context = enriched_context .. "\n" .. definition .. "\n"
                        processed_symbols[symbol] = true
                    else
                        local hover_info = get_hover_info(bufnr, i, start_symbol_col, symbol)
                        if hover_info then
                            enriched_context = enriched_context .. "\n" .. symbol .. ":\n" .. hover_info .. "\n"
                            processed_symbols[symbol] = true
                        end
                    end
                end
            end
        end
    end

    -- Copy the enriched context to the clipboard
    vim.fn.setreg('+', enriched_context)
    print("Enriched context copied to clipboard!")
end

function M.enrich_context()
    local mode = vim.api.nvim_get_mode().mode

    if mode == 'v' or mode == 'V' or mode == '' then
        -- Visual mode: get current selection
        local selected_text, start_row, start_col, end_row, end_col = get_visual_selection()
        enrich_context_internal(start_row, start_col, end_row, end_col)
    else
        -- Normal mode: get last selection
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
        local end_row, end_col = end_pos[2] - 1, end_pos[3] - 1
        enrich_context_internal(start_row, start_col, end_row, end_col)
    end
end
-- Set up the plugin
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})

    vim.api.nvim_create_user_command("EnrichContext", function(opts)
        M.enrich_context()
    end, {nargs = 0, range = true })

    -- Optional: Set up a keybinding (e.g., <leader>ec)
    vim.api.nvim_set_keymap('n', '<leader>lm', ':EnrichContext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', '<leader>lm', ':<C-u>EnrichContext<CR>', { noremap = true, silent = true })
end

return M


