local M = {}

local typst_watch_jobs = {}

function M.start_watch()
  local file = vim.fn.expand('%:p')
  if file == '' or vim.fn.expand('%:e') ~= 'typ' then
    vim.notify('Open a .typ file first', vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.expand('%:p:h')
  local basename = vim.fn.expand('%:t:r')
  local build_dir = dir .. '/typstbuild'
  local pdf = build_dir .. '/' .. basename .. '.pdf'
  vim.fn.mkdir(build_dir, 'p')
  vim.cmd('write')

  if typst_watch_jobs[file] then
    pcall(vim.fn.jobstop, typst_watch_jobs[file])
    typst_watch_jobs[file] = nil
  end

  vim.fn.jobstart({ 'typst', 'compile', file, pdf }, {
    detach = false,
    on_exit = function(_, code, _)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify('typst compile failed', vim.log.levels.ERROR)
        end)
        return
      end

      vim.fn.jobstart({ 'zathura', pdf }, { detach = true })

      local job_id = vim.fn.jobstart({ 'typst', 'watch', file, pdf }, {
        detach = false,
        on_exit = function()
          typst_watch_jobs[file] = nil
        end,
      })

      if job_id <= 0 then
        vim.schedule(function()
          vim.notify('Failed to start typst watch', vim.log.levels.ERROR)
        end)
        return
      end

      typst_watch_jobs[file] = job_id

      vim.schedule(function()
        vim.notify('Watching ' .. vim.fn.fnamemodify(file, ':t'))
      end)
    end,
  })
end

function M.stop_watch()
  local file = vim.fn.expand('%:p')
  if file == '' or vim.fn.expand('%:e') ~= 'typ' then
    vim.notify('Open a .typ file first', vim.log.levels.ERROR)
    return
  end

  local job_id = typst_watch_jobs[file]
  if not job_id then
    vim.notify('No active Typst watcher for this file', vim.log.levels.WARN)
    return
  end

  vim.fn.jobstop(job_id)
  typst_watch_jobs[file] = nil
  vim.notify('Stopped watching ' .. vim.fn.fnamemodify(file, ':t'))
end

function M.setup()
  vim.keymap.set('n', '<leader>tw', M.start_watch, { desc = '[T]ypst [W]atch' })
  vim.keymap.set('n', '<leader>ts', M.stop_watch, { desc = '[T]ypst [S]top' })
end

return M
