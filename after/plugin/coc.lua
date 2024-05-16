_G.coc_config_diagnostic_check_current_line = false
vim.cmd.call("coc#config('diagnostic.checkCurrentLine', v:false)")

function ToggleCocConfigDiagnosticCheckCurrentLine()
    if _G.coc_config_diagnostic_check_current_line then
        _G.coc_config_diagnostic_check_current_line = false
        vim.cmd.call("coc#config('diagnostic.checkCurrentLine', v:false)")
        print("Line Diagnostics Off")
    else
        _G.coc_config_diagnostic_check_current_line = true
        vim.cmd.call("coc#config('diagnostic.checkCurrentLine', v:true)")
        print("Line Diagnostics On")
    end
    vim.cmd('norm! j')
end

function CocPumScrollDown()
    if vim.cmd.call("coc#pum#visible()") then
        print("hello")
    else
        print("goodbye")
    end
end

local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }

vim.keymap.set("i", "<C-j>", 'coc#pum#visible() ? coc#pum#next(1) : "<Down>"', opts)

vim.keymap.set("i", "<C-k>", 'coc#pum#visible() ? coc#pum#prev(1) : "<Up>"', opts)

vim.keymap.set("i", "<C-Space>", 'coc#pum#visible() ? coc#pum#confirm() : " "', opts)

vim.keymap.set("n", "<leader>cd", ToggleCocConfigDiagnosticCheckCurrentLine)

vim.keymap.set("n", "<C-n>", function() vim.cmd.call("CocAction('doHover')") end)

vim.keymap.set("n", "gd", function() vim.cmd.call("CocActionAsync('jumpDefinition')") end)
