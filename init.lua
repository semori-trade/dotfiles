local module_vim_setup;
local module_plugins;
local module_keymaps;
local module_cmp;
local module_lsp;
local module_mason_lspconfig;
local module_telescope;
local module_treesitter;
local module_autopairs;
local module_comment;
local module_gitsigns;
local module_nvimtree;
local module_bufferline;
local module_lualine;
local module_toggleterm;
local module_project;
local module_impatient;
local module_whichkey;
local module_autocomands;
local module_colorscheme;


-- TODO: Mastery in Quicfix
-- TODO: Matery in macros
-- TODO: Matery in Telescope
-- TODO: Matery in LSP (renaming and other stuff)
-- TODO: Install and Matery in Harpoon
-- TODO: Install library for show white-spaces


module_vim_setup = (function()
  vim.g["netrw_fastbrowse"] = 0

  -- Copilot settings
  vim.g.copilot_filetypes = {
    ["*"] = false,
    ["javascript"] = true,
    ["typescript"] = true,
    ["lua"] = false,
    ["c"] = true,
    ["c#"] = true,
    ["c++"] = true,
    ["go"] = true,
    ["python"] = true,
  }
  vim.g.copilot_no_tab_map = true
  vim.g.copilot_assume_mapped = true
  vim.g.copilot_tab_fallback = ""
  vim.g.did_load_netrw = 1

  local options = {
    backup = false,                          -- creates a backup file
    clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
    cmdheight = 2,                           -- more space in the neovim command line for displaying messages
    completeopt = { "menuone", "noselect" }, -- mostly just for cmp
    conceallevel = 0,                        -- so that `` is visible in markdown files
    fileencoding = "utf-8",                  -- the encoding written to a file
    hlsearch = true,                         -- highlight all matches on previous search pattern
    ignorecase = true,                       -- ignore case in search patterns
    mouse = "a",                             -- allow the mouse to be used in neovim
    pumheight = 10,                          -- pop up menu height
    showmode = false,                        -- we don't need to see things like -- INSERT -- anymore
    showtabline = 2,                         -- always show tabs
    smartcase = true,                        -- smart case
    smartindent = true,                      -- make indenting smarter again
    splitbelow = true,                       -- force all horizontal splits to go below current window
    splitright = true,                       -- force all vertical splits to go to the right of current window
    swapfile = false,                        -- creates a swapfile
    termguicolors = true,                    -- set term gui colors (most terminals support this)
    timeoutlen = 100,                        -- time to wait for a mapped sequence to complete (in milliseconds)
    undofile = true,                         -- enable persistent undo
    updatetime = 300,                        -- faster completion (4000ms default)
    writebackup = false,                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
    expandtab = true,                        -- convert tabs to spaces
    shiftwidth = 2,                          -- the number of spaces inserted for each indentation
    tabstop = 4,                             -- insert 2 spaces for a tab
    -- tabstop = 2,                             -- insert 2 spaces for a tab
    cursorline = true,                       -- highlight the current line
    number = true,                           -- set numbered lines
    relativenumber = true,                   -- set relative numbered lines
    numberwidth = 4,                         -- set number column width to 2 {default 4}
    signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
    wrap = false,                            -- display lines as one long line
    scrolloff = 8,                           -- is one of my fav
    sidescrolloff = 8,
    guifont = "monospace:h17",               -- the font used in graphical neovim applications
  }

  vim.opt.shortmess:append "c"

  for k, v in pairs(options) do
    vim.opt[k] = v
  end

  vim.cmd "set whichwrap+=<,>,[,],h,l"
  vim.cmd [[set iskeyword+=-]]
  vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work
  vim.cmd [[set laststatus=3]]
  vim.cmd [[set foldmethod=indent]]
  vim.cmd [[set foldlevel=20]]

  local function zoom()
    if vim.fn.winnr('$') > 1 then
      local lst = vim.fn.win_findbuf(vim.fn.bufnr(''))
      local found = false
      for _, win_id in ipairs(lst) do
        local tabwin = vim.fn.win_id2tabwin(win_id)
        if vim.fn.tabpagewinnr(tabwin[1], '$') == 1 then
          vim.fn.win_gotoid(win_id)
          found = true
          break
        end
      end
      if not found then
        vim.cmd('tab split')
      end
    else
      local lst = vim.fn.win_findbuf(vim.fn.bufnr(''))
      for i, win_id in ipairs(lst) do
        if win_id ~= vim.fn.win_getid() then
          vim.cmd('wincmd c')
          vim.fn.win_gotoid(win_id)
          break
        end
      end
    end
  end

  local function goto_definition(split_cmd)
    local util = vim.lsp.util
    local log = require("vim.lsp.log")
    local api = vim.api

    -- note, this handler style is for neovim 0.5.1/0.6, if on 0.5, call with function(_, method, result)
    local handler = function(_, result, ctx)
      if result == nil or vim.tbl_isempty(result) then
        local _ = log.info() and log.info(ctx.method, "No location found")
        return nil
      end

      -- targetUri for ts-lsp and uri for go-lsp
      local targetUri = result[1]["targetUri"] or result[1]["uri"]
      local ctxUri = ctx["params"]["textDocument"]["uri"]
      local isSameFile = targetUri == ctxUri or not targetUri

      if split_cmd and not isSameFile then
        vim.cmd(split_cmd)
      end

      if vim.tbl_islist(result) then
        util.jump_to_location(result[1])

        if #result > 1 then
          util.set_qflist(util.locations_to_items(result))
          api.nvim_command("copen")
          api.nvim_command("wincmd p")
        end
      else
        util.jump_to_location(result)
      end
    end

    return handler
  end
  -- There we can switch betwen horizontal('split') and vertical ('vsplit') page changer
  vim.lsp.handlers["textDocument/definition"] = goto_definition('vsplit')

  M = {}
  M.zoom = zoom
  return M
end)()

module_plugins = (function()
  local fn = vim.fn

  -- Automatically install packer
  local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system {
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/wbthomason/packer.nvim",
      install_path,
    }
    print "Installing packer close and reopen Neovim..."
    vim.cmd [[packadd packer.nvim]]
  end

  -- Autocommand that reloads neovim whenever you save the plugins.lua file
  vim.cmd [[
    augroup packer_user_config
      autocmd!
      autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup end
  ]]

  -- Use a protected call so we don't error out on first use
  local status_ok, packer = pcall(require, "packer")
  if not status_ok then
    return
  end

  -- Have packer use a popup window
  packer.init {
    display = {
      open_fn = function()
        return require("packer.util").float { border = "rounded" }
      end,
    },
  }

  -- Install your plugins here
  return packer.startup(function(use)
    -- My plugins here
    use "wbthomason/packer.nvim" -- Have packer manage itself
    use "nvim-lua/popup.nvim"    -- An implementation of the Popup API from vim in Neovim
    use "nvim-lua/plenary.nvim"  -- Useful lua functions used by lots of plugins
    use "windwp/nvim-autopairs"  -- Autopairs, integrates with both cmp and treesitter
    -- use "numToStr/Comment.nvim" -- Easily comment stuff
    use {
      'kyazdani42/nvim-tree.lua',
      auto_close = false,
      tag = 'nightly' -- optional, updated every week. (see issue #1193)
    }

    use { "akinsho/bufferline.nvim", branch = 'main' }
    use "moll/vim-bbye"
    use "nvim-lualine/lualine.nvim"
    use { "akinsho/toggleterm.nvim", branch = 'main' }
    use "ahmedkhalf/project.nvim"
    use "lewis6991/impatient.nvim"
    use "antoinemadec/FixCursorHold.nvim" -- This is needed to fix lsp doc highlight
    use "folke/which-key.nvim"

    -- Colorschemes
    use 'morhetz/gruvbox'

    -- cmp plugins
    use "hrsh7th/nvim-cmp"    -- The completion plugin
    use "hrsh7th/cmp-buffer"  -- buffer completions
    use "hrsh7th/cmp-path"    -- path completions
    use "hrsh7th/cmp-cmdline" -- cmdline completions
    use "hrsh7th/cmp-nvim-lsp"

    -- snippets
    use "L3MON4D3/LuaSnip"             --snippet engine
    use "rafamadriz/friendly-snippets" -- a bunch of snippets to use
    use "saadparwaiz1/cmp_luasnip"     -- snippet completions

    -- LSP
    -- use "williamboman/nvim-lsp-installer" -- simple to use language server installer
    use "tamago324/nlsp-settings.nvim"    -- language server settings defined in json for
    use "jose-elias-alvarez/null-ls.nvim" -- for formatters and linters

    -- Telescope
    use "nvim-telescope/telescope.nvim"
    -- File manipulating via Telescope
    -- use "nvim-telescope/telescope-file-browser.nvim"
    -- Treesitter
    use {
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
    }
    use 'nvim-treesitter/nvim-treesitter-refactor'
    use "JoosepAlviste/nvim-ts-context-commentstring"
    use "p00f/nvim-ts-rainbow"

    -- Git
    use {
      "lewis6991/gitsigns.nvim", branch = 'main'
    }
    use 'ray-x/lsp_signature.nvim'

    -- TypeScript
    use 'jose-elias-alvarez/nvim-lsp-ts-utils'


    use {
      "nvim-telescope/telescope-file-browser.nvim",
      requires = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
    }

    use "VidocqH/lsp-lens.nvim"

    use {
      'stevearc/overseer.nvim',
      config = function() require('overseer').setup() end
    }

    -- Debugger for C
    use { 'mfussenegger/nvim-dap' }

    -- Lsp-installer alternative mason
    use {
      "williamboman/mason.nvim",
      config = function() require('mason').setup() end
    }
    use { "williamboman/mason-lspconfig.nvim" }
    use { "neovim/nvim-lspconfig" }
    use { "ThePrimeagen/harpoon" }
    use {
      'j-hui/fidget.nvim',
      tag = 'legacy',
      config = function()
        require("fidget").setup {
          -- options
        }
      end,
    }


    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
      require("packer").sync()
    end
  end)
end)()

module_keymaps = (function()
  local opts = { noremap = true, silent = true }

  -- Shorten function name
  local keymap = vim.api.nvim_set_keymap

  --Remap space as leader key
  keymap("", "<Space>", "<Nop>", opts)
  vim.g.mapleader = "m"
  -- vim.g.maplocalleader = ","

  -- Normal --
  -- Better window navigation
  keymap("n", "<C-h>", "<C-w>h", opts)
  keymap("n", "<C-l>", "<C-w>l", opts)

  -- Move text up and down
  keymap("n", "<S-k>", "<Esc>:m .-2<CR>", opts)
  keymap("n", "<S-j>", "<Esc>:m .+1<CR>", opts)

  -- Insert --
  -- Press jk fast to enter
  -- keymap("i", "jk", "<ESC>", opts)

  -- Visual --
  -- Stay in indent mode
  keymap("v", "<", "<gv", opts)
  keymap("v", ">", ">gv", opts)

  -- Paste in visual mode
  keymap("v", "p", '"_dP', opts)

  -- Visual Block --
  -- Move text up and down
  keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
  keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
  keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
  keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

  -- Fast saving
  keymap("n", "<leader>w", ":w!<cr>", opts)

  -- Disable highlight when <leader><cr> is pressed
  keymap("n", "<leader><cr>", ":noh<cr>", opts)

  -- Switch CWD to the directory of the open buffer
  -- Useful command but need to find a good place for use it
  keymap("n", "<leader>cd", ":cd %:p:h<cr>:pwd<cr>", opts)

  -- Disable suspend
  keymap("n", "<C-z>", "<Nop>", opts)

  -- Fast switch to buffers
  keymap("n", "<C-n>", ":enew<cr>", opts)
  keymap("n", "<C-k>", ":bnext<cr>", opts)
  keymap("n", "<C-j>", ":bprevious<cr>", opts)
  keymap("n", "<C-q>", ":bdelete<cr>", opts)

  -- Show floating lsp window
  -- No local leader + should be in lsp part of keymaps
  -- keymap("n", "<localleader>d", "<cmd>lua vim.lsp.diagnostic.get_line_diagnostics()<cr>", opts)

  -- Find Telescope recent files
  -- Cool stuff but should be in telescope part of keymaps
  -- keymap("n", "\\", ":Telescope grep_string <CR><CW><CR>", opts);
  -- keymap("n", ";", ":Telescope live_grep <CR>", opts);

  -- Replace standart "close all other windows" to Zoom to this window
  keymap("n", "<C-w>o", ":lua M.zoom()<cr>", opts)
end)()

module_cmp = (function()
  local cmp_status_ok, cmp = pcall(require, "cmp")
  if not cmp_status_ok then
    return
  end

  local snip_status_ok, luasnip = pcall(require, "luasnip")
  if not snip_status_ok then
    return
  end

  require("luasnip/loaders/from_vscode").lazy_load()

  local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
  end

  --   פּ ﯟ   some other good icons
  local kind_icons = {
    Text = "",
    Method = "m",
    Function = "",
    Constructor = "",
    Field = "",
    Variable = "",
    Class = "",
    Interface = "",
    Module = "",
    Property = "",
    Unit = "",
    Value = "",
    Enum = "",
    Keyword = "",
    Snippet = "",
    Color = "",
    File = "",
    Reference = "",
    Folder = "",
    EnumMember = "",
    Constant = "",
    Struct = "",
    Event = "",
    Operator = "",
    TypeParameter = "",
  }
  -- find more here: https://www.nerdfonts.com/cheat-sheet

  cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body) -- For `luasnip` users.
      end,
    },
    mapping = {
      ["<C-k>"] = cmp.mapping.select_prev_item(),
      ["<C-j>"] = cmp.mapping.select_next_item(),
      ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
      ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
      ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
      ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ["<C-e>"] = cmp.mapping {
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      },
      -- Accept currently selected item. If none selected, `select` first item.
      --Set `select` to `false` to only confirm explicitly selected items.
      ["<CR>"] = cmp.mapping.confirm { select = true },
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expandable() then
          luasnip.expand()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif check_backspace() then
          fallback()
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
      ['<C-c>'] = cmp.mapping(function(fallback)
        local copilot_keys = vim.fn['copilot#Accept']()
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif copilot_keys ~= '' and type(copilot_keys) == 'string' then
          vim.api.nvim_feedkeys(copilot_keys, 'i', true)
        else
          fallback()
        end
      end, {
        'i',
        's',
      }),
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        -- Kind icons
        vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
        -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
        vim_item.menu = ({
          nvim_lsp = "[LSP]",
          luasnip = "[Snippet]",
          buffer = "[Buffer]",
          path = "[Path]",
        })[entry.source.name]
        return vim_item
      end,
    },
    sources = {
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    },
    confirm_opts = {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    --documentation = {
    --  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    --},
    experimental = {
      ghost_text = false,
      native_menu = false,
    },
  }
end)()

module_mason_lspconfig = (function()
  local ensure_installed = {
    'tsserver',
    'eslint',
    'lua_ls',
    'lua_language_server',
    'gopls'
  }
end)()

module_lsp = (function()
  local null_ls_status_ok, null_ls = pcall(require, "null-ls")
  if not null_ls_status_ok then
    return
  end

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics
  local code_actions = null_ls.builtins.code_actions

  null_ls.setup({
    debug = false,
    sources = {
      formatting.prettierd,
      formatting.black.with({ extra_args = { "--fast" } }),
      formatting.stylua,
      diagnostics.cppcheck,
      diagnostics.eslint_d,
      code_actions.eslint_d
      -- diagnostics.flake8
    },
  })

  local M = {}

  -- TODO: backfill this to template
  M.setup = function()
    local signs = {
      { name = "DiagnosticSignError", text = "X" },
      { name = "DiagnosticSignWarn",  text = "!" },
      { name = "DiagnosticSignHint",  text = "?" },
      { name = "DiagnosticSignInfo",  text = "-" },
    }

    for _, sign in ipairs(signs) do
      vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
    end

    local config = {
      -- disable virtual text
      virtual_text = true,
      -- show signs
      signs = {
        active = signs,
      },
      update_in_insert = true,
      underline = true,
      severity_sort = true,
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      }
    }

    vim.diagnostic.config(config)

    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = "rounded",
    })

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = "rounded",
    })
  end

  local function lsp_highlight_document(client)
    -- Set autocommands conditional on server_capabilities
    if client.server_capabilities.document_highlight then
      vim.api.nvim_exec(
        [[
        augroup lsp_document_highlight
          autocmd! * <buffer>
          autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
          autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
      ]],
        false
      )
    end
  end

  local function lsp_keymaps(bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "-d", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-h>", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
    vim.api.nvim_buf_set_keymap(
      bufnr,
      "n",
      "gl",
      '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ border = "rounded" })<CR>',
      opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
    vim.cmd [[ command! Format execute 'lua vim.lsp.buf.format()' ]]
  end

  M.on_attach = function(client, bufnr)
    if client.name == "tsserver" then
      client.server_capabilities.document_formatting = false
    end
    lsp_keymaps(bufnr)
    lsp_highlight_document(client)
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if not status_ok then
    return
  end

  M.capabilities = cmp_nvim_lsp.default_capabilities(capabilities)

  local function on_attach(client, bufnr)
    -- Find the clients capabilities
    local cap = client.server_capabilities

    -- Only highlight if compatible with the language
    if cap.document_highlight then
      vim.cmd('augroup LspHighlight')
      vim.cmd('autocmd!')
      vim.cmd('autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()')
      vim.cmd('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')
      vim.cmd('augroup END')
    end
  end

  require 'lspconfig'.tsserver.setup({ on_attach = on_attach })

  local status_ok, _ = pcall(require, "lspconfig")
  if not status_ok then
    return
  end

  require 'lspconfig'.tsserver.setup {
    settings = {
      implicitProjectConfiguration = {
        checkJs = true
      }
    }
  }

  cfg = {
    debug = false,                                              -- set to true to enable debug logging
    log_path = vim.fn.stdpath("cache") .. "/lsp_signature.log", -- log dir when debug is on
    -- default is  ~/.cache/nvim/lsp_signature.log
    verbose = false,                                            -- show debug line number

    bind = true,                                                -- This is mandatory, otherwise border config won't get registered.
    -- If you want to hook lspsaga or other signature handler, pls set to false
    doc_lines = 10,                                             -- will show two lines of comment/doc(if there are more than two lines in doc, will be truncated);
    -- set to 0 if you DO NOT want any API comments be shown
    -- This setting only take effect in insert mode, it does not affect signature help in normal
    -- mode, 10 by default

    max_height = 12,                       -- max height of signature floating_window
    max_width = 80,                        -- max_width of signature floating_window
    noice = false,                         -- set to true if you using noice to render markdown
    wrap = true,                           -- allow doc/signature text wrap inside floating_window, useful if your lsp return doc/sig is too long

    floating_window = true,                -- show hint in a floating window, set to false for virtual text only mode

    floating_window_above_cur_line = true, -- try to place the floating above the current line when possible Note:
    -- will set to true when fully tested, set to false will use whichever side has more space
    -- this setting will be helpful if you do not want the PUM and floating win overlap

    floating_window_off_x = 1, -- adjust float windows x position.
    -- can be either a number or function
    floating_window_off_y = 0, -- adjust float windows y position. e.g -2 move window up 2 lines; 2 move down 2 lines
    -- can be either number or function, see examples

    close_timeout = 4000, -- close floating window after ms when laster parameter is entered
    fix_pos = false, -- set to true, the floating window will not auto-close until finish all parameters
    hint_enable = true, -- virtual hint enable
    hint_prefix = "🐼 ", -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
    hint_scheme = "String",
    hint_inline = function() return false end, -- should the hint be inline(nvim 0.10 only)?  default false
    hi_parameter = "LspSignatureActiveParameter", -- how your parameter will be highlight
    handler_opts = {
      border = "rounded" -- double, rounded, single, shadow, none, or a table of borders
    },

    always_trigger = false,                   -- sometime show signature on new line or in middle of parameter can be confusing, set it to false for #58

    auto_close_after = nil,                   -- autoclose signature float win after x sec, disabled if nil.
    extra_trigger_chars = {},                 -- Array of extra characters that will trigger signature completion, e.g., {"(", ","}
    zindex = 200,                             -- by default it will be on top of all floating windows, set to <= 50 send it to bottom

    padding = '',                             -- character to pad on left and right of signature can be ' ', or '|'  etc

    transparency = nil,                       -- disabled by default, allow floating win transparent value 1~100
    shadow_blend = 36,                        -- if you using shadow as border use this set the opacity
    shadow_guibg = 'Black',                   -- if you using shadow as border use this set the color e.g. 'Green' or '#121315'
    timer_interval = 200,                     -- default timer check interval set to lower value if you want to reduce latency
    toggle_key = nil,                         -- toggle signature on and off in insert mode,  e.g. toggle_key = '<M-x>'
    toggle_key_flip_floatwin_setting = false, -- true: toggle float setting after toggle key pressed

    select_signature_key = nil,               -- cycle to next signature, e.g. '<M-n>' function overloading
    move_cursor_key = nil,                    -- imap, use nvim_set_current_win to move cursor between current win and floating
  }
  require "lsp_signature".setup(cfg)
  require 'lspconfig'.clangd.setup {}

  require 'lspconfig'.gopls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = require 'lspconfig/util'.root_pattern("go.work", "go.mod", ".git"),
    settings = {
      gopls = {
        completeUnimported = true,
        usePlaceholders = true,
        analyses = {
          unusedparams = true,
        }
      },
    },
  }

  require 'lspconfig'.lua_ls.setup {}
end)()

module_telescope = (function()
  local status_ok, telescope = pcall(require, "telescope")
  if not status_ok then
    return
  end

  local actions = require "telescope.actions"

  telescope.setup {
    defaults = {
      prompt_prefix = " ",
      selection_caret = " ",
      path_display = { "smart" },
      file_ignore_patterns = { "node_modules" },

      mappings = {
        i = {
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,

          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,

          ["<C-c>"] = actions.close,

          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,

          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,

          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,

          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,

          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          ["<C-l>"] = actions.complete_tag,
          ["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
        },

        n = {
          ["<esc>"] = actions.close,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-v>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,

          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,
          ["H"] = actions.move_to_top,
          ["M"] = actions.move_to_middle,
          ["L"] = actions.move_to_bottom,

          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,
          ["gg"] = actions.move_to_top,
          ["G"] = actions.move_to_bottom,

          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,

          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,

          ["?"] = actions.which_key,
        },
      },
    },
    pickers = {
      -- Default configuration for builtin pickers goes here:
      -- picker_name = {
      --   picker_config_key = value,
      --   ...
      -- }
      -- Now the picker_config_key will be applied every time you call this
      -- builtin picker
    },
    extensions = {
      -- Your extension configuration goes here:
      -- extension_name = {
      --   extension_config_key = value,
      -- }
      -- please take a look at the readme of the extension you want to configure
      file_browser = {
        theme = "ivy",
        mappings = {
          ["i"] = {
            -- your custom insert mode mappings
          },
          ["n"] = {
            -- your custom normal mode mappings
          },
        },
      },
    },
  }

  require("telescope").load_extension "file_browser"
end)()

module_treesitter = (function()
  local status_ok, configs = pcall(require, "nvim-esitter.configs")
  if not status_ok then
    return
  end

  configs.setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    sync_install = false,     -- install languages synchronously (only applied to `ensure_installed`)
    ignore_install = { "" },  -- List of parsers to ignore installing
    autopairs = {
      enable = true,
    },
    highlight = {
      enabled = true,   -- false will disable the whole extension
      disable = { "" }, -- list of language that will be disabled
      additional_vim_regex_highlighting = true,
    },
    indent = { enable = true, disable = { "yaml" } },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
    rainbow = {
      enable = true,
      -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
      extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
      -- colors = {}, -- table of hex strings
      -- termcolors = {} -- table of colour name strings
    },
    refactor = {
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = "lnd",
          list_definitions = "lnD",
          list_definitions_toc = "lO",
          goto_next_usage = "<a-*>",
          goto_previous_usage = "<a-#>",
        },
      },
    },
  }
end)()

module_autopairs = (function()
  -- Setup nvim-cmp.
  local status_ok, npairs = pcall(require, "nvim-autopairs")
  if not status_ok then
    return
  end

  npairs.setup {
    check_ts = true,
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
      java = false,
    },
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    fast_wrap = {
      map = "<M-e>",
      chars = { "{", "[", "(", '"', "'" },
      pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
      offset = 0, -- Offset from pattern match
      end_key = "$",
      keys = "qwertyuiopzxcvbnmasdfghjkl",
      check_comma = true,
      highlight = "PmenuSel",
      highlight_grey = "LineNr",
    },
  }

  local cmp_autopairs = require "nvim-autopairs.completion.cmp"
  local cmp_status_ok, cmp = pcall(require, "cmp")
  if not cmp_status_ok then
    return
  end
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })
end)()

module_comment = (function()
  --local status_ok, comment = pcall(require, "Comment")
  --if not status_ok then
  --  return
  --end
  --
  --comment.setup {
  --  pre_hook = function(ctx)
  --    local U = require "Comment.utils"
  --
  --    local location = nil
  --    if ctx.ctype == U.ctype.block then
  --      location = require("ts_context_commentstring.utils").get_cursor_location()
  --    elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
  --      location = require("ts_context_commentstring.utils").get_visual_start_location()
  --    end
  --
  --    return require("ts_context_commentstring.internal").calculate_commentstring {
  --      key = ctx.ctype == U.ctype.line and "__default" or "__multiline",
  --      location = location,
  --    }
  --  end,
  --}
end)()

module_gitsigns = (function()
  local status_ok, gitsigns = pcall(require, "gitsigns")
  if not status_ok then
    return
  end

  gitsigns.setup {
    signs = {
      add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
      change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
      delete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
      topdelete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
      changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    },
    signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
    numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
    linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
    word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
    watch_gitdir = {
      interval = 1000,
      follow_files = true,
    },
    attach_to_untracked = true,
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      delay = 1000,
      ignore_whitespace = false,
    },
    current_line_blame_formatter_opts = {
      relative_time = false,
    },
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil, -- Use default
    max_file_length = 40000,
    preview_config = {
      -- Options passed to nvim_open_win
      border = "single",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    yadm = {
      enable = false,
    },
  }
end)()

module_nvimtree = (function()
  -- following options are the default
  -- each of these are documented in `:help nvim-tree.OPTION_NAME`
  vim.g.nvim_tree_icons = {
    default = "",
    symlink = "",
    git = {
      unstaged = "",
      staged = "S",
      unmerged = "",
      renamed = "➜",
      deleted = "",
      untracked = "U",
      ignored = "◌",
    },
    folder = {
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
    },
  }

  local status_ok, nvim_tree = pcall(require, "nvim-tree")
  if not status_ok then
    return
  end

  local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
  if not config_status_ok then
    return
  end

  local tree_cb = nvim_tree_config.nvim_tree_callback

  -- TODO: See what I really need to enable, now all is disabled
  -- [NvimTree] unknown option: quit_on_open | unknown option: git_hl | unknown option: disable_window_picker | unknown option: view.auto_resize | unknown option: update_to_buf_dir | unknown
  -- option: show_icons | unknown option: root_folder_modifier

  nvim_tree.setup {

    disable_netrw = true,
    hijack_netrw = true,
    open_on_setup = false,
    ignore_ft_on_setup = {
      "startify",
      "dashboard",
      -- "alpha",
    },
    auto_close = true,
    open_on_tab = false,
    hijack_cursor = false,
    update_cwd = true,
    -- update_to_buf_dir = {
    --   enable = true,
    --   auto_open = true,
    -- },
    diagnostics = {
      enable = true,
      icons = {
        hint = "",
        info = "",
        warning = "",
        error = "",
      },
    },
    update_focused_file = {
      enable = true,
      update_cwd = true,
      ignore_list = {},
    },
    system_open = {
      cmd = nil,
      args = {},
    },
    filters = {
      dotfiles = false,
      custom = {},
    },
    -- git = {
    --   enable = true,
    --   ignore = true,
    --   timeout = 500,
    -- },
    view = {
      width = 30,
      height = 30,
      hide_root_folder = false,
      side = "left",
      -- auto_resize = true,
      mappings = {
        custom_only = false,
        list = {
          { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
          { key = "h",                  cb = tree_cb "close_node" },
          { key = "v",                  cb = tree_cb "vsplit" },
        },
      },
      number = false,
      relativenumber = true,
    },
    trash = {
      cmd = "trash",
      require_confirm = true,
    },
    -- quit_on_open = 0,
    -- git_hl = 1,
    -- disable_window_picker = 0,
    -- root_folder_modifier = ":t",
    -- show_icons = {
    --   git = 1,
    --   folders = 1,
    --   files = 1,
    --   folder_arrows = 1,
    --   tree_width = 30,
    -- },
  }
end)()

module_bufferline = (function()
  local status_ok, bufferline = pcall(require, "bufferline")
  if not status_ok then
    return
  end

  bufferline.setup {
    options = {
      numbers = "none",                    -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
      close_command = "Bdelete! %d",       -- can be a string | function, see "Mouse actions"
      right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      left_mouse_command = "buffer %d",    -- can be a string | function, see "Mouse actions"
      middle_mouse_command = nil,          -- can be a string | function, see "Mouse actions"
      -- NOTE: this plugin is designed with this icon in mind,
      -- and so changing this is NOT recommended, this is intended
      -- as an escape hatch for people who cannot bear it for whatever reason
      -- indicator_icon = "▎",
      buffer_close_icon = "",
      -- buffer_close_icon = "",
      -- buffer_close_icon = '',
      modified_icon = "●",
      close_icon = "",
      -- close_icon = "",
      -- close_icon = '',
      left_trunc_marker = "",
      right_trunc_marker = "",
      --- name_formatter can be used to change the buffer's label in the bufferline.
      --- Please note some names can/will break the
      --- bufferline so use this at your discretion knowing that it has
      --- some limitations that will *NOT* be fixed.
      -- name_formatter = function(buf)  -- buf contains a "name", "path" and "bufnr"
      --   -- remove extension from markdown files for example
      --   if buf.name:match('%.md') then
      --     return vim.fn.fnamemodify(buf.name, ':t:r')
      --   end
      -- end,
      max_name_length = 30,
      max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
      tab_size = 21,
      diagnostics = "nvim_lsp",
      diagnostics_update_in_insert = false,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      -- NOTE: this will be called a lot so don't do any heavy processing here
      -- custom_filter = function(buf_number)
      --   -- filter out filetypes you don't want to see
      --   if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
      --     return true
      --   end
      --   -- filter out by buffer name
      --   if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
      --     return true
      --   end
      --   -- filter out based on arbitrary rules
      --   -- e.g. filter out vim wiki buffer from tabline in your work repo
      --   if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
      --     return true
      --   end
      -- end,
      offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
      show_buffer_icons = false,
      show_buffer_close_icons = false,
      show_close_icon = false,
      show_tab_indicators = true,
      persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
      -- can also be a table containing 2 custom separators
      -- [focused and unfocused]. eg: { '|', '|' }
      separator_style = "thin", -- | "thick" | "thin" | { 'any', 'any' },
      enforce_regular_tabs = true,
      always_show_bufferline = true,
      -- sort_by = 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
      --   -- add custom logic
      --   return buffer_a.modified > buffer_b.modified
      -- end
    },
    highlights = {
      -- fill = {
      --   guifg = { attribute = "fg", highlight = "#ff0000" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },
      -- background = {
      --   guifg = { attribute = "fg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },

      -- buffer_selected = {
      --   guifg = {attribute='fg',highlight='#ff0000'},
      --   guibg = {attribute='bg',highlight='#0000ff'},
      --   gui = 'none'
      --   },
      -- buffer_visible = {
      --   guifg = { attribute = "fg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },

      -- close_button = {
      --   guifg = { attribute = "fg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },
      -- close_button_visible = {
      --   guifg = { attribute = "fg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },
      -- close_button_selected = {
      --   guifg = {attribute='fg',highlight='TabLineSel'},
      --   guibg ={attribute='bg',highlight='TabLineSel'}
      --   },

      -- tab_selected = {
      --   guifg = { attribute = "fg", highlight = "Normal" },
      --   guibg = { attribute = "bg", highlight = "Normal" },
      -- },
      -- tab = {
      --   guifg = { attribute = "fg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },
      --tab_close = {
      --  -- guifg = {attribute='fg',highlight='LspDiagnosticsDefaultError'},
      --  guifg = { attribute = "fg", highlight = "TabLineSel" },
      --  guibg = { attribute = "bg", highlight = "Normal" },
      --},

      --duplicate_selected = {
      --  guifg = { attribute = "fg", highlight = "TabLineSel" },
      --  guibg = { attribute = "bg", highlight = "TabLineSel" },
      --  gui = "italic",
      --},
      --duplicate_visible = {
      --  guifg = { attribute = "fg", highlight = "TabLine" },
      --  guibg = { attribute = "bg", highlight = "TabLine" },
      --  gui = "italic",
      --},
      --duplicate = {
      --  guifg = { attribute = "fg", highlight = "TabLine" },
      --  guibg = { attribute = "bg", highlight = "TabLine" },
      --  gui = "italic",
      --},

      --modified = {
      --  guifg = { attribute = "fg", highlight = "TabLine" },
      --  guibg = { attribute = "bg", highlight = "TabLine" },
      --},
      --modified_selected = {
      --  guifg = { attribute = "fg", highlight = "Normal" },
      --  guibg = { attribute = "bg", highlight = "Normal" },
      --},
      --modified_visible = {
      --  guifg = { attribute = "fg", highlight = "TabLine" },
      --  guibg = { attribute = "bg", highlight = "TabLine" },
      --},

      -- separator = {
      --   guifg = { attribute = "bg", highlight = "TabLine" },
      --   guibg = { attribute = "bg", highlight = "TabLine" },
      -- },
      -- separator_selected = {
      --   guifg = { attribute = "bg", highlight = "Normal" },
      --   guibg = { attribute = "bg", highlight = "Normal" },
      -- },
      -- separator_visible = {
      --   guifg = {attribute='bg',highlight='TabLine'},
      --   guibg = {attribute='bg',highlight='TabLine'}
      --   },
      -- indicator_selected = {
      --   guifg = { attribute = "fg", highlight = "LspDiagnosticsDefaultHint" },
      --   guibg = { attribute = "bg", highlight = "Normal" },
      -- },
    },
  }
end)()

module_lualine = (function()
  -- Eviline config for lualine
  -- Author: shadmansaleh
  -- Credit: glepnir
  local lualine = require('lualine')

  -- Color table for highlights
  -- stylua: ignore
  local colors = {
    bg       = '#202328',
    fg       = '#bbc2cf',
    yellow   = '#ECBE7B',
    cyan     = '#008080',
    darkblue = '#081633',
    green    = '#98be65',
    orange   = '#FF8800',
    violet   = '#a9a1e1',
    magenta  = '#c678dd',
    blue     = '#51afef',
    red      = '#ec5f67',
  }

  local conditions = {
    buffer_not_empty = function()
      return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
    end,
    hide_in_width = function()
      return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
      local filepath = vim.fn.expand('%:p:h')
      local gitdir = vim.fn.finddir('.git', filepath .. ';')
      return gitdir and #gitdir > 0 and #gitdir < #filepath
    end,
  }

  -- Config
  local config = {
    options = {
      -- Disable sections and component separators
      component_separators = '',
      section_separators = '',
      theme = {
        -- We are going to use lualine_c an lualine_x as left and
        -- right section. Both are highlighted by c theme .  So we
        -- are just setting default looks o statusline
        normal = { c = { fg = colors.fg, bg = colors.bg } },
        inactive = { c = { fg = colors.fg, bg = colors.bg } },
      },
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x at right section
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ins_left {
    function()
      return '▊'
    end,
    color = { fg = colors.blue },      -- Sets highlighting of component
    padding = { left = 0, right = 1 }, -- We don't need space before this
  }

  ins_left {
    -- mode component
    function()
      return ''
    end,
    color = function()
      -- auto change color according to neovims mode
      local mode_color = {
        n = colors.red,
        i = colors.green,
        v = colors.blue,
        [''] = colors.blue,
        V = colors.blue,
        c = colors.magenta,
        no = colors.red,
        s = colors.orange,
        S = colors.orange,
        [''] = colors.orange,
        ic = colors.yellow,
        R = colors.violet,
        Rv = colors.violet,
        cv = colors.red,
        ce = colors.red,
        r = colors.cyan,
        rm = colors.cyan,
        ['r?'] = colors.cyan,
        ['!'] = colors.red,
        t = colors.red,
      }
      return { fg = mode_color[vim.fn.mode()] }
    end,
    padding = { right = 1 },
  }

  ins_left {
    -- filesize component
    'filesize',
    cond = conditions.buffer_not_empty,
  }

  ins_left {
    'filename',
    cond = conditions.buffer_not_empty,
    color = { fg = colors.magenta, gui = 'bold' },
  }

  ins_left { 'location' }

  ins_left { 'progress', color = { fg = colors.fg, gui = 'bold' } }

  ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
    diagnostics_color = {
      color_error = { fg = colors.red },
      color_warn = { fg = colors.yellow },
      color_info = { fg = colors.cyan },
    },
  }

  -- Insert mid section. You can make any number of sections in neovim :)
  -- for lualine it's any number greater then 2
  ins_left {
    function()
      return '%='
    end,
  }

  ins_left {
    -- Lsp server name .
    function()
      local msg = 'No Active Lsp'
      local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
      local clients = vim.lsp.get_active_clients()
      if next(clients) == nil then
        return msg
      end
      for _, client in ipairs(clients) do
        local filetypes = client.config.filetypes
        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          return client.name
        end
      end
      return msg
    end,
    icon = ' LSP:',
    color = { fg = '#ffffff', gui = 'bold' },
  }

  -- Add components to right sections
  ins_right {
    'o:encoding',       -- option component same as &encoding in viml
    fmt = string.upper, -- I'm not sure why it's upper case either ;)
    cond = conditions.hide_in_width,
    color = { fg = colors.green, gui = 'bold' },
  }

  ins_right {
    'fileformat',
    fmt = string.upper,
    icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
    color = { fg = colors.green, gui = 'bold' },
  }

  ins_right {
    'branch',
    icon = '',
    color = { fg = colors.violet, gui = 'bold' },
  }

  ins_right {
    'diff',
    -- Is it me or the symbol for modified us really weird
    symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
    diff_color = {
      added = { fg = colors.green },
      modified = { fg = colors.orange },
      removed = { fg = colors.red },
    },
    cond = conditions.hide_in_width,
  }

  ins_right {
    function()
      return '▊'
    end,
    color = { fg = colors.blue },
    padding = { left = 1 },
  }

  -- Now don't forget to initialize lualine
  lualine.setup(config)
  --   local status_ok, lualine = pcall(require, "lualine")
  --   if not status_ok then
  --   	return
  --   end
  --
  --   local hide_in_width = function()
  --   	return vim.fn.winwidth(0) > 80
  --   end
  --
  --   local diagnostics = {
  --   	"diagnostics",
  --   	sources = { "nvim_diagnostic" },
  --   	sections = { "error", "warn" },
  --   	symbols = { error = " ", warn = " " },
  --   	colored = false,
  --   	update_in_insert = false,
  --   	always_visible = true,
  --   }
  --
  --   local diff = {
  --   	"diff",
  --   	colored = false,
  --   	symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
  --     cond = hide_in_width
  --   }
  --
  --   local mode = {
  --   	"mode",
  --   	fmt = function(str)
  --   		return "-- " .. str .. " --"
  --   	end,
  --   }
  --
  --   local filetype = {
  --   	"filetype",
  --   	icons_enabled = false,
  --   	icon = nil,
  --   }
  --
  --   local branch = {
  --   	"branch",
  --   	icons_enabled = true,
  --   	icon = "",
  --   }
  --
  --   local location = {
  --   	"location",
  --   	padding = 0,
  --   }
  --
  --   -- cool function for progress
  --   local progress = function()
  --   	local current_line = vim.fn.line(".")
  --   	local total_lines = vim.fn.line("$")
  --   	local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
  --   	local line_ratio = current_line / total_lines
  --   	local index = math.ceil(line_ratio * #chars)
  --   	return chars[index]
  --   end
  --
  --   local spaces = function()
  --   	return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
  --   end
  --
  --   lualine.setup({
  --   	options = {
  --   		icons_enabled = true,
  --   		theme = "auto",
  --   		component_separators = { left = "", right = "" },
  --   		section_separators = { left = "", right = "" },
  --   		disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
  --   		always_divide_middle = true,
  --   	},
  --   	sections = {
  --   		lualine_a = { branch, diagnostics },
  --   		lualine_b = { mode },
  --   		lualine_c = { { "filename", path = 1 } },
  --   		-- lualine_x = { "encoding", "fileformat", "filetype" },
  --   		lualine_x = { diff, "encoding", filetype },
  --   		lualine_y = { location },
  --   		lualine_z = { progress },
  --   	},
  --   	inactive_sections = {
  --   		lualine_a = {},
  --   		lualine_b = {},
  --   		lualine_c = { "filename" },
  --   		lualine_x = { "location" },
  --   		lualine_y = {},
  --   		lualine_z = {},
  --   	},
  --   	tabline = {},
  --   	extensions = {},
  --   })
end)()

module_toggleterm = (function()
  local status_ok, toggleterm = pcall(require, "toggleterm")
  if not status_ok then
    return
  end

  toggleterm.setup({
    size = 20,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = true,
    direction = "float",
    close_on_exit = true,
    shell = vim.o.shell,
    float_opts = {
      border = "curved",
      winblend = 0,
      highlights = {
        border = "Normal",
        background = "Normal",
      },
    },
  })

  function _G.set_terminal_keymaps()
    local opts = { noremap = true }
    vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
  end

  vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })

  function _LAZYGIT_TOGGLE()
    lazygit:toggle()
  end

  local node = Terminal:new({ cmd = "node", hidden = true })

  function _NODE_TOGGLE()
    node:toggle()
  end

  local ncdu = Terminal:new({ cmd = "ncdu", hidden = true })

  function _NCDU_TOGGLE()
    ncdu:toggle()
  end

  local htop = Terminal:new({ cmd = "htop", hidden = true })

  function _HTOP_TOGGLE()
    htop:toggle()
  end

  local python = Terminal:new({ cmd = "python", hidden = true })

  function _PYTHON_TOGGLE()
    python:toggle()
  end
end)()

module_project = (function()
  local status_ok, project = pcall(require, "project_nvim")
  if not status_ok then
    return
  end
  project.setup({
    ---@usage set to false to disable project.nvim.
    --- This is on by default since it's currently the expected behavior.
    active = true,

    on_config_done = nil,

    ---@usage set to true to disable setting the current-woriking directory
    --- Manual mode doesn't automatically change your root directory, so you have
    --- the option to manually do so using `:ProjectRoot` command.
    manual_mode = false,

    ---@usage Methods of detecting the root directory
    --- Allowed values: **"lsp"** uses the native neovim lsp
    --- **"pattern"** uses vim-rooter like glob pattern matching. Here
    --- order matters: if one is not detected, the other is used as fallback. You
    --- can also delete or rearangne the detection methods.
    -- detection_methods = { "lsp", "pattern" }, -- NOTE: lsp detection will get annoying with multiple langs in one project
    detection_methods = { "pattern" },

    ---@usage patterns used to detect root dir, when **"pattern"** is in detection_methods
    patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },

    ---@ Show hidden files in telescope when searching for files in a project
    show_hidden = false,

    ---@usage When set to false, you will get a message when project.nvim changes your directory.
    -- When set to false, you will get a message when project.nvim changes your directory.
    silent_chdir = true,

    ---@usage list of lsp client names to ignore when using **lsp** detection. eg: { "efm", ... }
    ignore_lsp = {},

    ---@type string
    ---@usage path to store the project history for use in telescope
    datapath = vim.fn.stdpath("data"),
  })

  local tele_status_ok, telescope = pcall(require, "telescope")
  if not tele_status_ok then
    return
  end

  telescope.load_extension('projects')
end)()

module_impatient = (function()
  local status_ok, impatient = pcall(require, "impatient")
  if not status_ok then
    return
  end

  impatient.enable_profile()
end)()

module_whichkey = (function()
  local status_ok, which_key = pcall(require, "which-key")
  if not status_ok then
    return
  end

  local setup = {
    plugins = {
      marks = true,     -- shows a list of your marks on ' and `
      registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
      -- spelling = {
      --   enabled = true,   -- enabling this will show WhichKey when pressing z= to select spelling suggestions
      --   suggestions = 20, -- how many suggestions should be shown in the list?
      -- },
      -- the presets plugin, adds help for a bunch of default keybindings in Neovim
      -- No actual key bindings are created
      presets = {
        operators = false,   -- adds help for operators like d, y, ... and registers them for motion / text object completion
        motions = true,      -- adds help for motions
        text_objects = true, -- help for text objects triggered after entering an operator
        windows = true,      -- default bindings on <c-w>
        nav = true,          -- misc bindings to work with windows
        z = true,            -- bindings for folds, spelling and others prefixed with z
        g = true,            -- bindings for prefixed with g
      },
    },
    -- add operators that will trigger motion and text object completion
    -- to enable all native operators, set the preset / operators plugin above
    -- operators = { gc = "Comments" },
    key_labels = {
      -- override the label used to display some keys. It doesn't effect WK in any other way.
      -- For example:
      -- ["<space>"] = "SPC",
      -- ["<cr>"] = "RET",
      -- ["<tab>"] = "TAB",
    },
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's label
      group = "+", -- symbol prepended to a group
    },
    popup_mappings = {
      scroll_down = "<c-d>", -- binding to scroll down inside the popup
      scroll_up = "<c-u>",   -- binding to scroll up inside the popup
    },
    window = {
      border = "rounded",       -- none, single, double, shadow
      position = "bottom",      -- bottom, top
      margin = { 1, 0, 1, 0 },  -- extra window margin [top, right, bottom, left]
      padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
      winblend = 0,
    },
    layout = {
      height = { min = 4, max = 25 },                                             -- min and max height of the columns
      width = { min = 20, max = 50 },                                             -- min and max width of the columns
      spacing = 3,                                                                -- spacing between columns
      align = "left",                                                             -- align columns left, center or right
    },
    ignore_missing = true,                                                        -- enable this to hide mappings for which you didn't specify a label
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
    show_help = true,                                                             -- show help message on the command line when the popup is visible
    triggers = "auto",                                                            -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specify a list manually
    triggers_blacklist = {
      -- list of mode / prefixes that should never be hooked by WhichKey
      -- this is mostly relevant for key maps that start with a native binding
      -- most people should not need to change this
      i = { "j", "k" },
      v = { "j", "k" },
    },
  }

  local opts = {
    mode = "n",     -- NORMAL mode
    prefix = "<leader>",
    buffer = nil,   -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true,  -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true,  -- use `nowait` when creating keymaps
  }

  local mappings = {
    -- ["a"] = { "<cmd>Alpha<cr>", "Alpha" },
    ["b"] = {
      "<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "Buffers",
    },
    ["e"] = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
    -- ["e"] = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
    d = {
      name = "Debugger",
      c = { "<cmd>DapContinue<cr>", "Continue" },
      o = { "<cmd>DapStepOver<cr>", "Step over" },
      i = { "<cmd>DapStepInto<cr>", "Step into" },
      u = { "<cmd>DapStepOut<cr>", "Step out" },
      b = { "<cmd>DapToggleBreakpoint<cr>", "Toggle breakpoint" },
      r = { "<cmd>DapToggleReppl<cr>", "Toggle REPL" },
    },
    ["w"] = { "<cmd>w!<CR>", "Save" },
    ["q"] = { "<cmd>q!<CR>", "Quit" },
    ["c"] = { "<cmd>Bdelete!<CR>", "Close Buffer" },
    ["h"] = { "<cmd>nohlsearch<CR>", "No Highlight" },
    ["f"] = {
      "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false})<cr>",
      "Find files",
    },
    ["F"] = { "<cmd>Telescope live_grep theme=ivy<cr>", "Find Text" },
    ["P"] = { "<cmd>lua require('telescope').extensions.projects.projects()<cr>", "Projects" },
    -- ["m"] = { "<cmd>lua require('telescope').extensions.file_browser.file_browser()<cr>", "File manipulation" },

    p = {
      name = "Packer",
      c = { "<cmd>PackerCompile<cr>", "Compile" },
      i = { "<cmd>PackerInstall<cr>", "Install" },
      s = { "<cmd>PackerSync<cr>", "Sync" },
      S = { "<cmd>PackerStatus<cr>", "Status" },
      u = { "<cmd>PackerUpdate<cr>", "Update" },
    },

    g = {
      name = "Git",
      -- g = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
      j = { "<cmd>lua require 'gitsigns'.next_hunk()<cr>", "Next Hunk" },
      k = { "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", "Prev Hunk" },
      l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "Blame" },
      p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
      r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
      R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
      s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
      u = {
        "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>",
        "Undo Stage Hunk",
      },
      o = { "<cmd>Telescope git_status<cr>", "Open changed file" },
      b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
      c = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
      d = {
        "<cmd>Gitsigns diffthis HEAD<cr>",
        "Diff",
      },
    },

    l = {
      name = "LSP",
      a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
      d = {
        -- "<cmd>Telescope lsp_document_diagnostics<cr>",
        -- "<cmd> lua vim.lsp.buf.diagnostic()<cr>",
        -- "Document Diagnostics",
        "<cmd>lua vim.lsp.buf.definition()<CR>",
        "Go to definition"
      },
      w = {
        "<cmd>Telescope lsp_workspace_diagnostics<cr>",
        "Workspace Diagnostics",
      },
      h = {
        "<cmd>lua vim.lsp.buf.hover()<CR>", "Help"
      },
      f = { "<cmd>lua vim.lsp.buf.format()<cr>", "Format" },
      i = { "<cmd>LspInfo<cr>", "Info" },
      I = { "<cmd>LspInstallInfo<cr>", "Installer Info" },
      j = {
        "<cmd>lua vim.diagnostic.goto_next()<CR>",
        "Next Diagnostic",
      },
      k = {
        "<cmd>lua vim.diagnostic.goto_prev()<cr>",
        "Prev Diagnostic",
      },
      l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
      q = { "<cmd>lua vim.diagnostic.set_loclist()<cr>", "Quickfix" },
      r = { "<cmd>Telescope lsp_references<cr>", "References" },
      s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
      S = {
        "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
        "Workspace Symbols",
      },
    },
    s = {
      name = "Search",
      b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
      c = { "<cmd>Telescope colorscheme<cr>", "Colorscheme" },
      h = { "<cmd>Telescope help_tags<cr>", "Find Help" },
      M = { "<cmd>Telescope man_pages<cr>", "Man Pages" },
      r = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
      R = { "<cmd>Telescope registers<cr>", "Registers" },
      k = { "<cmd>Telescope keymaps<cr>", "Keymaps" },
      C = { "<cmd>Telescope commands<cr>", "Commands" },
      d = { "<cmd>lua vim.diagnostic.definition<cr>", "Definition" },
    },

    t = {
      name = "Terminal",
      n = { "<cmd>lua _NODE_TOGGLE()<cr>", "Node" },
      u = { "<cmd>lua _NCDU_TOGGLE()<cr>", "NCDU" },
      t = { "<cmd>lua _HTOP_TOGGLE()<cr>", "Htop" },
      p = { "<cmd>lua _PYTHON_TOGGLE()<cr>", "Python" },
      f = { "<cmd>ToggleTerm direction=float<cr>", "Float" },
      h = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", "Horizontal" },
      v = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", "Vertical" },
    },
  }

  which_key.setup(setup)
  which_key.register(mappings, opts)
end)()

module_autocomands = (function()
  vim.cmd [[
    augroup _general_settings
      autocmd!
      autocmd FileType qf,help,man,lspinfo nnoremap <silent> <buffer> q :close<CR>
      autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
      autocmd BufWinEnter * :set formatoptions-=cro
      autocmd FileType qf set nobuflisted
    augroup end

    augroup _git
      autocmd!
      autocmd FileType gitcommit setlocal wrap
      autocmd FileType gitcommit setlocal spell
    augroup end

    augroup _markdown
      autocmd!
      autocmd FileType markdown setlocal wrap
      autocmd FileType markdown setlocal spell
    augroup end

    augroup _auto_resize
      autocmd!
      autocmd VimResized * tabdo wincmd =
    augroup end

    augroup _alpha
      autocmd!
      autocmd User AlphaReady set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
    augroup end

    autocmd FocusLost * :wa
  ]]
  -- Avoid nerw but broke which key
  -- autocmd! VimEnter * if isdirectory(expand('%:p')) | exe 'cd %:p:h' | exe 'bd!'| exe 'Telescope file_browser' | endif

  -- Autoformat
  vim.cmd [[
    augroup _lsp
      autocmd!
      autocmd BufWritePre * lua vim.lsp.buf.format()
    augroup end
  ]]
end)()

module_colorscheme = (function()
  vim.cmd [[ colorscheme gruvbox ]]
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.o.termguicolors = true
end)()


-- helper for rendering table contet
-- should uncoment for debug
-- function dump(o)
--   if type(o) == 'table' then
--     local s = '{ '
--     for k, v in pairs(o) do
--       if type(k) ~= 'number' then k = '"' .. k .. '"' end
--       s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
--     end
--     return s .. '} '
--   else
--     return tostring(o)
--   end
-- end
