---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    config = function()
      local treesitter = require 'nvim-treesitter'
      local parsers = {
        'angular',
        'bash',
        'c',
        'c_sharp',
        'css',
        'diff',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'razor',
        'scss',
        'typescript',
        'vim',
        'vimdoc',
        'xml',
      }

      treesitter.setup { install_dir = vim.fn.stdpath 'data' .. '/site' }
      treesitter.install(parsers)

      local function start_treesitter(buf)
        if pcall(vim.treesitter.start, buf) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          start_treesitter(args.buf)
        end,
      })

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          start_treesitter(buf)
        end
      end
    end,
  },
}
