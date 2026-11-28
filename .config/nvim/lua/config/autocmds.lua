-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Notula (~/Development/rheinardkorf/notula): only when nvim runs in a notes
-- window, which exports NOTULA_DIR. Autosave, and reload when feeders append.
if vim.env.NOTULA_DIR then
  local group = vim.api.nvim_create_augroup("notula", { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost", "BufLeave" }, {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].modified and vim.bo[ev.buf].buftype == "" and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
        vim.api.nvim_buf_call(ev.buf, function() vim.cmd("silent! write") end)
      end
    end,
  })
  -- Poll for changes on disk (CursorHold only fires once per idle spell).
  vim.uv.new_timer():start(1000, 1000, vim.schedule_wrap(function()
    if vim.fn.mode() ~= "c" then vim.cmd("silent! checktime") end
  end))
  -- Keep the preview in step: send the top visible line as ":<line>" Enter.
  local preview, last = "", nil
  local sync = vim.uv.new_timer()
  vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved", "CursorMovedI", "BufWinEnter" }, {
    group = group,
    callback = function()
      sync:stop()
      sync:start(30, 0, vim.schedule_wrap(function()
        if preview == "" then -- the preview pane may start after the editor
          preview = vim.fn.system({ "tmux", "show-options", "-wqv", "-t", vim.env.TMUX_PANE or "", "@notula_preview" }):gsub("%s+$", "")
        end
        local top = vim.fn.line("w0")
        if preview == "" or top == last then return end
        last = top
        vim.system({ "tmux", "send-keys", "-t", preview, ":" .. top, "Enter" })
      end))
    end,
  })
end
