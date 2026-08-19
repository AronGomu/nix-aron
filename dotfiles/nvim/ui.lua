---@module 'lazy'
---@type LazySpec
return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      -- delay between pressing a key and opening which-key (milliseconds)
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>g', group = '[G]rep and replace', mode = { 'n', 'v' } },
        { '<leader>l', group = '[L]azy tools', mode = { 'n' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  {
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('onedark').setup {
        transparent = true, -- Tell onedark not to paint the main editor background.
        styles = {
          comments = { italic = false }, -- Keep comments non-italic.
        },
        highlights = {
          -- Keep the editor transparent; only the statusline gets a background.
          Normal = { bg = 'none' }, -- Main editing area background.
          NormalNC = { bg = 'none' }, -- Main editing area in non-current windows.
          EndOfBuffer = { bg = 'none' }, -- Empty lines after the end of a file.
          SignColumn = { bg = 'none' }, -- Left column used for git signs, diagnostics, breakpoints, etc.
          FoldColumn = { bg = 'none' }, -- Left column used for code-folding markers.
          CursorLine = { bg = 'none' }, -- Highlight for the entire line under the cursor.
          CursorColumn = { bg = 'none' }, -- Highlight for the entire column under the cursor.
          ColorColumn = { bg = 'none' }, -- Vertical guide columns, like your 80 and 120 character rulers.
          LineNr = { bg = 'none' }, -- Line number column background.
          CursorLineNr = { bg = 'none' }, -- Current line number background.

          StatusLine = { fg = '$fg', bg = '$bg1' }, -- Active window statusline background.
          StatusLineNC = { fg = '$grey', bg = '$bg1' }, -- Inactive window statusline background.
          MiniStatuslineModeNormal = { fg = '$bg0', bg = '$green', fmt = 'bold' },
          MiniStatuslineModeInsert = { fg = '$bg0', bg = '$blue', fmt = 'bold' },
          MiniStatuslineModeVisual = { fg = '$bg0', bg = '$purple', fmt = 'bold' },
          MiniStatuslineModeReplace = { fg = '$bg0', bg = '$red', fmt = 'bold' },
          MiniStatuslineModeCommand = { fg = '$bg0', bg = '$orange', fmt = 'bold' },
          MiniStatuslineModeOther = { fg = '$bg0', bg = '$cyan', fmt = 'bold' },
          MiniStatuslineGit = { fg = '$bg0', bg = '$yellow', fmt = 'bold' },
          MiniStatuslineModeNormalGitSep = { fg = '$green', bg = '$yellow' },
          MiniStatuslineModeInsertGitSep = { fg = '$blue', bg = '$yellow' },
          MiniStatuslineModeVisualGitSep = { fg = '$purple', bg = '$yellow' },
          MiniStatuslineModeReplaceGitSep = { fg = '$red', bg = '$yellow' },
          MiniStatuslineModeCommandGitSep = { fg = '$orange', bg = '$yellow' },
          MiniStatuslineModeOtherGitSep = { fg = '$cyan', bg = '$yellow' },
          MiniStatuslineGitSep = { fg = '$yellow', bg = '$bg2' },
          MiniStatuslineGitSepFilename = { fg = '$yellow', bg = '$bg1' },
          MiniStatuslineModeNormalSep = { fg = '$green', bg = '$bg2' },
          MiniStatuslineModeInsertSep = { fg = '$blue', bg = '$bg2' },
          MiniStatuslineModeVisualSep = { fg = '$purple', bg = '$bg2' },
          MiniStatuslineModeReplaceSep = { fg = '$red', bg = '$bg2' },
          MiniStatuslineModeCommandSep = { fg = '$orange', bg = '$bg2' },
          MiniStatuslineModeOtherSep = { fg = '$cyan', bg = '$bg2' },
          MiniStatuslineModeNormalSepFilename = { fg = '$green', bg = '$bg1' },
          MiniStatuslineModeInsertSepFilename = { fg = '$blue', bg = '$bg1' },
          MiniStatuslineModeVisualSepFilename = { fg = '$purple', bg = '$bg1' },
          MiniStatuslineModeReplaceSepFilename = { fg = '$red', bg = '$bg1' },
          MiniStatuslineModeCommandSepFilename = { fg = '$orange', bg = '$bg1' },
          MiniStatuslineModeOtherSepFilename = { fg = '$cyan', bg = '$bg1' },
          MiniStatuslineInfoSep = { fg = '$bg2', bg = '$bg1' },
          MiniStatuslineDevinfo = { fg = '$fg', bg = '$bg2' }, -- mini.statusline git/diagnostic/LSP section.
          MiniStatuslineFilename = { fg = '$fg', bg = '$bg1' }, -- mini.statusline filename section.
          MiniStatuslineFileinfo = { fg = '$fg', bg = '$bg2' }, -- mini.statusline filetype/encoding section.
          MiniStatuslineInactive = { fg = '$grey', bg = '$bg1' }, -- mini.statusline when the window is inactive.
        },
      }
      vim.cmd.colorscheme 'onedark'
    end,
  },

  -- Dotfyle top colorschemes. Eager loading exposes every scheme to :Themes.
  { 'catppuccin/nvim', name = 'catppuccin', lazy = false },
  { 'folke/tokyonight.nvim', lazy = false },
  { 'rebelot/kanagawa.nvim', lazy = false },
  { 'rose-pine/neovim', name = 'rose-pine', lazy = false },
  { 'EdenEast/nightfox.nvim', lazy = false },
  { 'sainnhe/gruvbox-material', lazy = false },
  { 'projekt0n/github-nvim-theme', lazy = false },
  { 'sainnhe/everforest', lazy = false },
  { 'scottmckendry/cyberdream.nvim', lazy = false },
  { 'Mofiqul/vscode.nvim', lazy = false },
  { 'olimorris/onedarkpro.nvim', lazy = false },
  { 'Mofiqul/dracula.nvim', lazy = false },
  { 'shaunsingh/nord.nvim', lazy = false },
  { 'nyoom-engineering/oxocarbon.nvim', lazy = false },
  { 'marko-cerovac/material.nvim', lazy = false },
  { 'craftzdog/solarized-osaka.nvim', lazy = false },
  { 'sainnhe/sonokai', lazy = false },
  { 'AlexvZyl/nordic.nvim', lazy = false },
  { 'bluz71/vim-moonfly-colors', lazy = false },
  { 'neanias/everforest-nvim', lazy = false },
  { 'tiagovla/tokyodark.nvim', lazy = false },
  { 'ribru17/bamboo.nvim', lazy = false },
  { 'savq/melange-nvim', lazy = false },
  { 'sainnhe/edge', lazy = false },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  { -- Collection of various small independent plugins/modules
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }

      require('mini.surround').setup()

      local statusline = require 'mini.statusline'

      local separator = vim.g.have_nerd_font and '' or '>'
      local separator_reverse = vim.g.have_nerd_font and '' or '<'

      local function group(hl, content) return '%#' .. hl .. '#' .. content end

      local function join_sections(sections)
        local visible = {}
        for _, section in ipairs(sections) do
          if section ~= '' then table.insert(visible, section) end
        end
        return table.concat(visible, ' ')
      end

      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
            local git = statusline.section_git { trunc_width = 40 }
            local devinfo = join_sections {
              statusline.section_diff { trunc_width = 75 },
              statusline.section_diagnostics { trunc_width = 75 },
              statusline.section_lsp { trunc_width = 75 },
            }
            local filename = statusline.section_filename { trunc_width = 140 }
            local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
            local words = statusline.section_wordcount { trunc_width = 75 }
            local search = statusline.section_searchcount { trunc_width = 75 }
            local location = statusline.section_location { trunc_width = 75 }

            local left = group(mode_hl, ' ' .. mode .. ' ')
            if git ~= '' then
              left = left .. group(mode_hl .. 'GitSep', separator) .. group('MiniStatuslineGit', ' ' .. git .. ' ')

              if devinfo == '' then
                left = left .. group('MiniStatuslineGitSepFilename', separator)
              else
                left = left
                  .. group('MiniStatuslineGitSep', separator)
                  .. group('MiniStatuslineDevinfo', ' ' .. devinfo .. ' ')
                  .. group('MiniStatuslineInfoSep', separator)
              end
            elseif devinfo == '' then
              left = left .. group(mode_hl .. 'SepFilename', separator)
            else
              left = left
                .. group(mode_hl .. 'Sep', separator)
                .. group('MiniStatuslineDevinfo', ' ' .. devinfo .. ' ')
                .. group('MiniStatuslineInfoSep', separator)
            end
            left = left .. '%<' .. group('MiniStatuslineFilename', ' ' .. filename .. ' ')

            local right
            if fileinfo == '' then
              right = group(mode_hl .. 'SepFilename', separator_reverse)
            else
              right = group('MiniStatuslineInfoSep', separator_reverse)
                .. group('MiniStatuslineFileinfo', ' ' .. fileinfo .. ' ')
                .. group(mode_hl .. 'Sep', separator_reverse)
            end
            right = right .. group(mode_hl, ' ' .. join_sections { words, search, location } .. ' ')

            return left .. '%=' .. right
          end,
        },
      }
      ---@diagnostic disable-next-line: duplicate-set-field

      statusline.section_location = function() return '%2l:%-2v' end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_wordcount = function(args)
        if statusline.is_truncated(args.trunc_width) then return '' end
        if vim.bo.buftype ~= '' then return '' end

        local counts = vim.fn.wordcount()
        local n = counts.words or 0
        if vim.fn.mode():find '[vV\22]' and counts.visual_words ~= nil then n = counts.visual_words end

        return n .. ' words'
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function(args)
        if statusline.is_truncated(args.trunc_width) then return '' end

        local branch = vim.b.gitsigns_head
        if branch == nil or branch == '' then return '' end

        local icon = vim.g.have_nerd_font and '' or 'git:'
        return icon .. ' ' .. branch
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        local path = vim.api.nvim_buf_get_name(0)

        if path == '' then return '[No File Selected]' end

        local fname = vim.fn.fnamemodify(path, ':t')

        local win_width = vim.api.nvim_win_get_width(0)

        local max_len = math.floor(win_width * 0.6)

        if vim.fn.strdisplaywidth(fname) <= max_len then return fname end

        local visible_chars = math.max(max_len - 3, 1)
        local start = math.max(vim.fn.strchars(fname) - visible_chars, 0)
        return '...' .. vim.fn.strcharpart(fname, start)
      end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
    end,
  },

  {
    'sphamba/smear-cursor.nvim',
    opts = {},
  },
}
