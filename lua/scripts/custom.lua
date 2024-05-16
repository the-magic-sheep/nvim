function SortImports()
    if vim.bo.filetype == "python" then
        vim.cmd("CocCommand python.sortImports")
    end
end

function FormatAll()
    local paths = vim.split(vim.fn.glob(vim.fn.getcwd() .. "/**/*"), '\n')

    print("Formatting...")

    for i, file in pairs(paths) do
        local bn = vim.fn.bufnr(file, true)
        vim.cmd("edit " .. file)
        if vim.bo.filetype == "python" then
            vim.cmd.call("CocAction('runCommand', 'python.sortImports')")
        end

        if pcall(vim.cmd.call, "CocAction('format')") then
            print("formatted ", file)
        end
    end
    vim.cmd('wa')
    vim.cmd.bufdo('bd')
    vim.cmd.Ex()
end
