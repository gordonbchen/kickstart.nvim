local M = {}

local typst_watch_jobs = {}
local opened_pdfs = {}

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO)
  end)
end

local function clear_qf()
  vim.schedule(function()
    vim.fn.setqflist({}, 'r', { title = 'Typst', items = {} })
    vim.cmd('cclose')
  end)
end

local function parse_typst_diagnostics(lines)
  local items = {}
  local pending_message = nil
  local pending_kind = nil

  local i = 1
  while i <= #lines do
    local line = lines[i]

    if line and line ~= '' then
      local kind, msg = line:match('^(error):%s*(.*)$')
      if not kind then
        kind, msg = line:match('^(warning):%s*(.*)$')
      end
      if kind then
        pending_kind = kind
        pending_message = msg ~= '' and msg or kind
        i = i + 1
        goto continue
      end

      local filename, lnum, col = line:match('^%s*%-%->%s*(.-):(%d+):(%d+)%s*$')
      if filename then
        local text_parts = {}

        if pending_kind and pending_message then
          table.insert(text_parts, pending_kind .. ': ' .. pending_message)
        elseif pending_message then
          table.insert(text_parts, pending_message)
        end

        local j = i + 1
        while j <= #lines do
          local next_line = lines[j]

          if not next_line or next_line == '' then
            j = j + 1
            goto continue_inner
          end

          if next_line:match('^%s*%-%->%s*') then
            break
          end
          if next_line:match('^(error):') or next_line:match('^(warning):') then
            break
          end

          if not next_line:match('^%s*|')
            and not next_line:match('^%s*[%d]+%s*|')
            and not next_line:match('^%s*=') then
            table.insert(text_parts, next_line)
          end

          j = j + 1
          ::continue_inner::
        end

        table.insert(items, {
          filename = filename,
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = table.concat(text_parts, ' '),
          type = (pending_kind == 'warning') and 'W' or 'E',
        })

        i = j
        goto continue
      end
    end

    ::continue::
    i = i + 1
  end

  if #items == 0 then
    for _, line in ipairs(lines) do
      if line and line ~= '' then
        table.insert(items, {
          text = line,
          type = 'E',
        })
      end
    end
  end

  return items
end

local function set_qf_from_typst(lines, title)
  local items = parse_typst_diagnostics(lines)

  vim.schedule(function()
    vim.fn.setqflist({}, 'r', {
      title = title,
      items = items,
    })

    if #items > 0 then
      vim.cmd('copen')
    else
      vim.cmd('cclose')
    end
  end)
end

local function maybe_open_zathura(pdf)
  if opened_pdfs[pdf] then
    return
  end

  local job_id = vim.fn.jobstart({ 'zathura', pdf }, { detach = true })
  if job_id > 0 then
    opened_pdfs[pdf] = true
  else
    notify('Failed to open zathura', vim.log.levels.ERROR)
  end
end

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

  local compile_output = {}

  vim.fn.jobstart({ 'typst', 'compile', file, pdf }, {
    detach = false,
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      if data then
        vim.list_extend(compile_output, data)
      end
    end,

    on_stderr = function(_, data)
      if data then
        vim.list_extend(compile_output, data)
      end
    end,

    on_exit = function(_, code)
      if code ~= 0 then
        set_qf_from_typst(compile_output, 'Typst Compile Errors')
        notify('Typst compile failed', vim.log.levels.ERROR)
        return
      end

      clear_qf()
      maybe_open_zathura(pdf)

      local watch_chunk = {}

      local function flush_watch_errors()
        if #watch_chunk > 0 then
          set_qf_from_typst(watch_chunk, 'Typst Watch Errors')
        end
      end

      local function handle_watch_data(data)
        if not data then
          return
        end

        for _, line in ipairs(data) do
          if line and line ~= '' then
            if line:match('compiled successfully') or line:match('writing to') then
              watch_chunk = {}
              clear_qf()
            else
              watch_chunk[#watch_chunk + 1] = line
            end
          end
        end

        flush_watch_errors()
      end

      local job_id = vim.fn.jobstart({ 'typst', 'watch', file, pdf }, {
        detach = false,
        stdout_buffered = false,
        stderr_buffered = false,

        on_stdout = function(_, data)
          handle_watch_data(data)
        end,

        on_stderr = function(_, data)
          handle_watch_data(data)
        end,

        on_exit = function()
          typst_watch_jobs[file] = nil
        end,
      })

      if job_id <= 0 then
        notify('Failed to start typst watch', vim.log.levels.ERROR)
        return
      end

      typst_watch_jobs[file] = job_id
      notify('Watching ' .. vim.fn.fnamemodify(file, ':t'))
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
