vim.g.mapleader = " "

local o = vim.opt
o.number = true
o.relativenumber = true
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.ignorecase = true
o.smartcase = true
o.termguicolors = true
o.signcolumn = "yes"
o.clipboard = "unnamedplus"
o.undofile = true
o.scrolloff = 8
o.splitright = true
o.splitbelow = true
o.completeopt = { "menu", "menuone", "noselect" }
o.timeoutlen = 400

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

local langs = { "lua", "go", "gomod", "bash", "dart", "markdown", "json", "yaml" }

require("lazy").setup({
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "ellisonleao/gruvbox.nvim", priority = 1000 },
  { "shaunsingh/nord.nvim", priority = 1000 },
  { "folke/tokyonight.nvim", priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install(langs)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = langs,
        callback = function() vim.treesitter.start() end,
      })
    end },
  { "neovim/nvim-lspconfig" },
  { "folke/which-key.nvim", event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>c", group = "code" },
        { "<leader>r", group = "refactor" },
      },
    } },
})

vim.cmd.colorscheme(require("theme"))

-- LSP
vim.lsp.enable({ "gopls", "lua_ls", "clangd" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
  end,
})

-- format Go on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function() vim.lsp.buf.format({ async = false }) end,
})

-- keymaps
local map = function(keys, fn, desc)
  vim.keymap.set("n", keys, fn, { desc = desc })
end
map("<leader>ff", "<cmd>Telescope find_files<cr>", "Files")
map("<leader>fg", "<cmd>Telescope live_grep<cr>", "Grep")
map("<leader>fb", "<cmd>Telescope buffers<cr>", "Buffers")
map("<leader>fr", "<cmd>Telescope oldfiles<cr>", "Recent files")
map("<leader>fh", "<cmd>Telescope help_tags<cr>", "Help")
map("<leader>w", "<cmd>w<cr>", "Save")
map("<leader>q", "<cmd>q<cr>", "Quit")
map("<leader>e", "<cmd>Explore<cr>", "File explorer")
map("<leader>?", "<cmd>WhichKey<cr>", "All keymaps")
map("<Esc>", "<cmd>nohlsearch<cr>", "Clear search")
