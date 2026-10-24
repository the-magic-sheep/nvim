-- Autocommands and diagnostic display.

local group = vim.api.nvim_create_augroup("config.general", { clear = true })

-- Diagnostics: signs and underline in the buffer, the message itself in a
-- floating window when the cursor rests (coc.nvim behaved this way too).
vim.diagnostic.config({
    signs = true,
    underline = true,
    virtual_text = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})

-- false: only diagnostics under the cursor. true: anywhere on the line.
-- Toggled with <leader>cd; this was `diagnostic.checkCurrentLine` in coc.
_G.line_diagnostics = false

function ToggleLineDiagnostics()
    _G.line_diagnostics = not _G.line_diagnostics
    print(_G.line_diagnostics and "Line Diagnostics On" or "Line Diagnostics Off")
end

local function diagnostic_scope()
    return _G.line_diagnostics and "line" or "cursor"
end

vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    callback = function()
        -- Don't fight with an already-open floating window.
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then
                return
            end
        end
        vim.diagnostic.open_float(nil, {
            scope = diagnostic_scope(),
            focus = false,
            close_events = {
                "CursorMoved",
                "CursorMovedI",
                "BufHidden",
                "InsertCharPre",
                "WinLeave",
            },
        })
    end,
})

--- Open the diagnostic float and put the cursor inside it, so the message can
--- be scrolled and yanked. The float above cannot be entered: moving into it
--- is a WinLeave in the code window, which is one of its close events. This
--- opens a fresh one that closes on `q` or on leaving it instead.
function FocusDiagnostics()
    -- Drop the auto-opened float first; it would close itself on the way out
    -- of the code window and take its window id with it.
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        for _, scope in ipairs({ "cursor", "line" }) do
            if pcall(vim.api.nvim_win_get_var, win, scope) then
                vim.api.nvim_win_close(win, true)
                break
            end
        end
    end

    local _, win = vim.diagnostic.open_float(nil, {
        scope = diagnostic_scope(),
        focus = false,
        close_events = { "BufHidden" },
    })
    if not win then
        vim.notify("No diagnostic here", vim.log.levels.INFO)
        return
    end

    vim.api.nvim_set_current_win(win)
    vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        buffer = vim.api.nvim_win_get_buf(win),
        once = true,
        callback = function()
            pcall(vim.api.nvim_win_close, win, true)
        end,
    })
end

-- Briefly highlight text after yanking it.
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Reopen a file at the line the cursor was on last time.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
