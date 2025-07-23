function SortImports()
    if vim.bo.filetype == "python" then
        vim.cmd("CocCommand python.sortImports")
    end
end

function FormatAll()
    local paths = vim.split(vim.fn.glob(vim.fn.getcwd() .. "/**/*"), '\n')

    print("Visiting...")

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


function ClearTerm(reset)
  vim.opt_local.scrollback = 1

  vim.api.nvim_command("startinsert")
  if reset == 1 then
    vim.api.nvim_feedkeys("reset", 't', false)
  else
    vim.api.nvim_feedkeys("clear", 't', false)
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<cr>', true, false, true), 't', true)

  vim.opt_local.scrollback = 10000
end
