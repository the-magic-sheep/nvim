function SortImports()
    if vim.bo.filetype == "python" then
        vim.cmd("CocCommand python.sortImports")
    end
end

function DoAutoFormat()
    if vim.bo.filetype == "markdown" then
        vim.cmd("CocCommand markdownlint.fixAll")
    else
        vim.cmd.call("CocAction('format')")
        SortImports()
    end
end
