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
  -- Org mode. Files stay .org in ~/orgfiles (synced by Syncthing). The
  -- org-bullets fork under nvim-orgmode is the maintained one; akinsho's
  -- errors on every org buffer against current nvim-orgmode.
  { "nvim-orgmode/orgmode", ft = { "org" }, lazy = false,
    dependencies = { "nvim-orgmode/org-bullets.nvim" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/orgfiles/*.org", "~/orgfiles/journal/*.org", "~/orgfiles/notes/*.org" },
        org_default_notes_file = "~/orgfiles/refile.org",
        org_todo_keywords = { "TODO", "NEXT", "WAITING", "|", "DONE", "CANCELLED" },
        org_startup_folded = "content",

        -- Capture and the agenda open as a centred float rather than a
        -- 16-line split along the bottom of the screen. Journalling is what
        -- this is mostly used for, and a strip at the foot of a 3440px-wide
        -- monitor is a cramped and oddly-shaped place to write prose.
        win_split_mode = { "float", 0.85 },
        win_border = "rounded",

        -- Stars and emphasis markers are markup, not content. org-bullets
        -- already draws a bullet per level, so showing the stars as well is
        -- noise; hiding the leading ones leaves the bullet sitting at the
        -- indent its level implies. Needs conceallevel, which the plugin does
        -- not set itself — see the FileType autocmd near the bottom.
        org_hide_leading_stars = true,
        org_hide_emphasis_markers = true,
        org_ellipsis = "  ⋯",
        -- The existing journal body text sits flush left, not indented under
        -- the headline; keep new entries matching.
        org_adapt_indentation = false,
        org_capture_templates = {
          -- One file per day under ~/orgfiles/journal (tiller layout). The
          -- target expands %<...> with os.date, so no datetree is needed;
          -- a second capture on the same day appends another "* " entry.
          j = {
            description = "Journal",
            target = "~/orgfiles/journal/%<%Y-%m-%d>.org",
            template = "* %?",
          },
          t = {
            description = "Task",
            target = "~/orgfiles/todo.org",
            template = "* TODO %?\n  %U",
          },
        },
      })
      require("org-bullets").setup()
    end },
  { "folke/which-key.nvim", event = "VeryLazy",
    -- which-key closes its popup five seconds after the terminal loses focus.
    -- With focus following the mouse on Hyprland, letting the pointer drift
    -- off the window is enough, which read as "a timer closes it". There is
    -- no option for that timer, so its autocmds are removed after setup: the
    -- popup now stays until a key completes the mapping or <Esc> cancels.
    config = function(_, opts)
      -- The timer is registered inside which-key.state.setup, which the
      -- plugin runs later on its own schedule. Wrapping that function
      -- removes the two autocmds the moment they are created, whenever that
      -- turns out to be.
      local state = require("which-key.state")
      local state_setup = state.setup
      state.setup = function(...)
        local r = state_setup(...)
        pcall(vim.api.nvim_clear_autocmds, { group = "wk", event = { "FocusLost", "FocusGained" } })
        return r
      end
      require("which-key").setup(opts)
    end,
    opts = {
      -- Show the popup as soon as a prefix is pressed, not after a pause: it
      -- is the menu, so there is nothing to wait for. (timeoutlen stays 400
      -- for jk.)
      delay = 0,
      -- A taller panel at the bottom right, with the group's name as its
      -- title, so you can see where you are in the tree.
      preset = "helix",
      win = { width = { min = 36, max = 80 }, height = { min = 4, max = 0.8 } },
      -- Every group has a title and every leaf a plain sentence. nvim-orgmode
      -- registers its mappings with terse "org ..." descriptions and never
      -- names the groups, so which-key showed "+7 keymaps"; the entries below
      -- only document, they do not remap. Keys are nvim-orgmode's defaults.
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>c", group = "code" },
        { "<leader>r", group = "refactor" },

        -- Neovim's built-in prefixes, which which-key only counted.
        { "g", group = "go to / misc (g)" },
        { "z", group = "folds, spelling, scrolling (z)" },
        { "z=", desc = "Spelling suggestions for this word" },
        { "zg", desc = "Spelling: add word to dictionary" },
        { "zw", desc = "Spelling: mark word as wrong" },
        { "zug", desc = "Spelling: undo add word" },
        { "zuw", desc = "Spelling: undo mark wrong" },
        { "]s", desc = "Next misspelled word" }, { "[s", desc = "Previous misspelled word" },

        -- Neovim's own bracket motions (:help [a and friends), which it
        -- registers without descriptions, so which-key showed "23 keymaps".
        { "[", group = "previous / first" },
        { "]", group = "next / last" },
        { "[a", desc = "Previous argument" }, { "]a", desc = "Next argument" },
        { "[A", desc = "First argument" }, { "]A", desc = "Last argument" },
        { "[b", desc = "Previous buffer" }, { "]b", desc = "Next buffer" },
        { "[B", desc = "First buffer" }, { "]B", desc = "Last buffer" },
        { "[q", desc = "Previous quickfix item" }, { "]q", desc = "Next quickfix item" },
        { "[Q", desc = "First quickfix item" }, { "]Q", desc = "Last quickfix item" },
        { "[<C-Q>", desc = "Previous quickfix file" }, { "]<C-Q>", desc = "Next quickfix file" },
        { "[l", desc = "Previous location-list item" }, { "]l", desc = "Next location-list item" },
        { "[L", desc = "First location-list item" }, { "]L", desc = "Last location-list item" },
        { "[<C-L>", desc = "Previous location-list file" }, { "]<C-L>", desc = "Next location-list file" },
        { "[t", desc = "Previous tag match" }, { "]t", desc = "Next tag match" },
        { "[T", desc = "First tag match" }, { "]T", desc = "Last tag match" },
        { "[<C-T>", desc = "Previous tag in preview" }, { "]<C-T>", desc = "Next tag in preview" },
        { "[d", desc = "Previous diagnostic" }, { "]d", desc = "Next diagnostic" },
        { "[D", desc = "First diagnostic" }, { "]D", desc = "Last diagnostic" },
        { "[<Space>", desc = "Add blank line above" }, { "]<Space>", desc = "Add blank line below" },
        { "[%", desc = "Previous unmatched bracket" }, { "]%", desc = "Next unmatched bracket" },

        { "<leader>o", group = "org" },
        { "<leader>oa", desc = "Agenda" },
        { "<leader>oc", group = "capture" },
        { "<leader>ocj", desc = "Journal entry (today)" },
        { "<leader>oj", desc = "Journal: continue today in a float" },
        { "<leader>oo", desc = "Open link or date under cursor" },
        { "<leader>os", desc = "Spelling: toggle checking in this window" },
        { "<leader>oz", desc = "Tiller: note from this word, stay here" },
        { "<leader>oZ", desc = "Tiller: note from this word, then open it" },
        { "<leader>ot", desc = "Set tags on this heading" },
        { "<leader>or", desc = "Refile this heading elsewhere" },
        { "<leader>oe", desc = "Export" },
        { "<leader>oJ", desc = "Move subtree down" },
        { "<leader>oK", desc = "Move subtree up" },
        { "<leader>o*", desc = "Toggle line <-> heading" },
        { "<leader>o,", desc = "Set priority" },
        { "<leader>o$", desc = "Archive subtree" },
        { "<leader>oA", desc = "Toggle ARCHIVE tag" },
        { "<leader><CR>", desc = "New heading, item or row here" },

        { "<leader>of", group = "open file" },
        { "<leader>ofj", desc = "Journal, today" },
        { "<leader>ofg", desc = "Goals" },
        { "<leader>oft", desc = "Todo" },
        { "<leader>ofr", desc = "Refile" },
        { "<leader>ofs", desc = "Shell in C plan" },
        { "<leader>ofn", desc = "Find a note" },
        { "<leader>ofb", desc = "Find a book file" },

        { "<leader>oi", group = "insert" },
        { "<leader>oi.", desc = "Timestamp, active" },
        { "<leader>oi!", desc = "Timestamp, inactive" },
        { "<leader>oid", desc = "Deadline" },
        { "<leader>ois", desc = "Schedule" },
        { "<leader>oih", desc = "Heading after this block" },
        { "<leader>oit", desc = "TODO heading after this block" },
        { "<leader>oiT", desc = "TODO heading right after this one" },

        { "<leader>ol", group = "links" },
        { "<leader>oli", desc = "Insert a link" },
        { "<leader>ols", desc = "Store a link to here" },

        { "<leader>od", group = "dates" },
        { "<leader>od!", desc = "Toggle active / inactive timestamp" },

        { "<leader>on", group = "notes" },
        { "<leader>ona", desc = "Add a log note to this heading" },

        { "<leader>ox", group = "clock" },
        { "<leader>oxi", desc = "Clock in" },
        { "<leader>oxo", desc = "Clock out" },
        { "<leader>oxq", desc = "Cancel the clock" },
        { "<leader>oxj", desc = "Jump to the running clock" },
        { "<leader>oxe", desc = "Set effort estimate" },

        { "<leader>ob", group = "babel" },
        { "<leader>obt", desc = "Tangle code blocks to files" },
      },
    } },
})

-- theme.lua is generated by theme/apply.sh and now carries the whole palette,
-- not just a name. Tolerant of the old single-string form so a stale file
-- leaves you with a working editor rather than a broken one.
local theme = require("theme")
local palette = type(theme) == "table" and theme or { colorscheme = theme }
vim.cmd.colorscheme(palette.colorscheme)

-- Org headline colours, one per level, from that palette.
--
-- nvim-orgmode links these to Title/Constant/Identifier/Statement/PreProc/
-- Type/Special/String, which borrows whatever the colorscheme chose for code.
-- The result is arbitrary as a hierarchy — in gruvbox levels 2 and 5 come out
-- nearly the same — and it has nothing to do with the palette the rest of the
-- desktop is built from. This is a deliberate cascade instead, warm at the top
-- and cooling as you nest, bold for the three levels you actually navigate by.
--
-- Scheduled rather than called directly: nvim-orgmode re-applies its own links
-- on every ColorScheme event, so this has to run after them. vim.schedule puts
-- it after all synchronous handlers instead of relying on the order autocmds
-- happen to have been registered in.
local org_levels = {
  palette.accent, palette.yellow, palette.green, palette.blue,
  palette.magenta, palette.cyan, palette.red, palette.dim,
}
local function org_headline_colours()
  for i, colour in ipairs(org_levels) do
    if colour then
      vim.api.nvim_set_hl(0, "@org.headline.level" .. i, { fg = colour, bold = i <= 3 })
    end
  end
end
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function() vim.schedule(org_headline_colours) end,
})
vim.schedule(org_headline_colours)

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
  pattern = { "*.go", "*.c", "*.h" },
  callback = function() vim.lsp.buf.format({ async = false }) end,
})

-- Org buffers are prose, so they get prose settings rather than the code
-- defaults. conceallevel is the load-bearing one: org_hide_leading_stars and
-- org_hide_emphasis_markers are both implemented with conceal, and nvim-orgmode
-- does not set it, so without this they are configured and do nothing.
--
-- A function rather than an inline callback because almost all of these are
-- WINDOW-local, not buffer-local. FileType fires once per buffer load, so a
-- second window onto an already-loaded org buffer — which is exactly what the
-- journal float is — gets the global defaults instead: numbers on, conceal
-- off, no spell. Both paths call this.
local function org_window_opts()
  vim.opt_local.conceallevel = 2
  -- Markers reappear on the line the cursor is on, which is what you want
  -- while editing and not while reading.
  vim.opt_local.concealcursor = ""
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true    -- break between words, not mid-word
  vim.opt_local.breakindent = true  -- continuation lines keep the indent

  -- Hard wrap at 79. With "t" in formatoptions, insert mode breaks the line
  -- as you type past the column; gwap reflows a paragraph already written.
  -- gw rather than gq: gq goes through nvim-orgmode's formatexpr, which
  -- only splits long lines and never rejoins short ones. "n" with the list
  -- pattern below keeps "- item" continuation lines indented under the item
  -- instead of being joined into the next one; "1" avoids ending a line on
  -- "a" or "I". No "a" (auto-reflow while typing): it would also reflow
  -- property drawers and tables.
  vim.opt_local.textwidth = 79
  vim.opt_local.formatoptions = "tcqjn1"
  vim.opt_local.formatlistpat = [[^\s*\(\d\+[.)]\|[-+*]\)\s\+]]
  vim.opt_local.number = false      -- line numbers earn nothing in prose
  vim.opt_local.relativenumber = false

  -- en_au rather than plain en, so "color" is flagged and "colour" is not;
  -- both are in the one en.utf-8.spl that ships with nvim, so this needs
  -- nothing downloaded. Not as noisy as it sounds: nvim-orgmode's treesitter
  -- highlights.scm marks headlines, paragraphs and list items @spell, and
  -- TODO/DONE keywords and link URLs @nospell, so only prose is checked.
  vim.opt_local.spell = true
  vim.opt_local.spelllang = "en_au"

  -- The personal dictionary lives with the journal, not in this repo. zg on a
  -- name writes it here, Syncthing carries it to the other machine, and it
  -- stays out of a public repo — the words you add are mostly the names of
  -- people and places you know.
  local dict = vim.fn.expand("~/orgfiles/spell")
  if vim.fn.isdirectory(dict) == 0 then
    vim.fn.mkdir(dict, "p")
  end
  vim.opt_local.spellfile = dict .. "/en.utf-8.add"

  -- See the checktime autocmds below for why this matters here.
  vim.opt_local.autoread = true
end

vim.api.nvim_create_autocmd("FileType", { pattern = "org", callback = org_window_opts })

-- keymaps
local map = function(keys, fn, desc)
  vim.keymap.set("n", keys, fn, { desc = desc })
end
map("<leader>ff", "<cmd>Telescope find_files<cr>", "Files")
map("<leader>fg", "<cmd>Telescope live_grep<cr>", "Grep")
map("<leader>fb", "<cmd>Telescope buffers<cr>", "Buffers")
map("<leader>fr", "<cmd>Telescope oldfiles<cr>", "Recent files")
map("<leader>fh", "<cmd>Telescope help_tags<cr>", "Help")
map("<leader>fm", "<cmd>Telescope man_pages<cr>", "Man pages")
map("<leader>w", "<cmd>w<cr>", "Save")
map("<leader>q", "<cmd>q<cr>", "Quit")
map("<leader>e", "<cmd>Explore<cr>", "File explorer")
-- Search every keymap by what it does, not by key: type "spell" or "link"
-- and press enter to run it. The which-key popup is for browsing a prefix;
-- this is for when you cannot remember which prefix.
map("<leader>?", "<cmd>Telescope keymaps<cr>", "Search keymaps by description")

-- Built-in commands are not keymaps, so that search cannot see them and
-- which-key's labels for them are only labels. Mapping a key to itself with
-- a description makes it a real, searchable entry without changing what it
-- does. Spelling first, because that is the one you reach for and forget.
local function document(mode, keys)
  for lhs, desc in pairs(keys) do
    vim.keymap.set(mode, lhs, lhs, { desc = desc, noremap = true })
  end
end
document("n", {
  ["z="] = "Spelling: suggestions for the word under the cursor",
  ["zg"] = "Spelling: add word to the dictionary",
  ["zw"] = "Spelling: mark word as wrong",
  ["zug"] = "Spelling: undo adding this word",
  ["]s"] = "Spelling: next misspelled word",
  ["[s"] = "Spelling: previous misspelled word",
  ["gqip"] = "Reflow this paragraph",
  ["gw"] = "Reflow (motion), keep cursor",
  ["ga"] = "Show character code under cursor",
  ["g;"] = "Jump to last change",
  ["gi"] = "Insert where you last left insert mode",
  ["gv"] = "Reselect last visual selection",
})
map("<leader>os", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("spell " .. (vim.wo.spell and "on" or "off"))
end, "Spelling: toggle checking in this window")

-- org: capture is <leader>oc and agenda <leader>oa (nvim-orgmode defaults).
-- <leader>ocj goes straight to a journal entry without the template menu.
-- tiller keeps the journal as one file per day under ~/orgfiles/journal, so
-- "the journal" means today's file; it is created with its title line when
-- missing, the same shape tiller writes.
local function journal_today()
  local path = vim.fn.expand("~/orgfiles/journal/") .. os.date("%Y-%m-%d") .. ".org"
  if vim.fn.filereadable(path) == 0 then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile({ "#+TITLE: " .. os.date("%Y-%m-%d %A"), "" }, path)
  end
  return path
end
map("<leader>ofj", function() vim.cmd.edit(vim.fn.fnameescape(journal_today())) end, "Journal, today")
map("<leader>ofg", "<cmd>edit ~/orgfiles/goals.org<cr>", "Goals")
map("<leader>ofn", function() require("telescope.builtin").find_files({ cwd = vim.fn.expand("~/orgfiles/notes"), prompt_title = "notes" }) end, "Find a note")
map("<leader>ofb", function() require("telescope.builtin").find_files({ cwd = vim.fn.expand("~/orgfiles/book"), prompt_title = "books" }) end, "Find a book file")
map("<leader>oft", "<cmd>edit ~/orgfiles/todo.org<cr>", "Todo")
map("<leader>ofs", "<cmd>edit ~/orgfiles/shell-in-c-12-weeks.org<cr>", "Shell in C plan")
map("<leader>ofr", "<cmd>edit ~/orgfiles/refile.org<cr>", "Refile")
map("<leader>ocj", function() require("orgmode").capture:open_template_by_shortcut("j") end, "Journal entry")

-- A note from the word under the cursor (or the visual selection), made by
-- tiller while you keep writing. The new note inherits this note's book tag
-- and links back here, and the word becomes an [[id:...][...]] link, so
-- neither note is an orphan. <leader>oz keeps you here; <leader>oZ opens the
-- new note on its first blank line.
local function tiller_note_from_text(open_it)
  local mode = vim.fn.mode()
  local s_row, s_col, e_row, e_col, text
  if mode == "v" or mode == "V" then
    vim.cmd('normal! "zy')
    text = vim.fn.getreg("z")
    s_row, s_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
    e_row, e_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  else
    text = vim.fn.expand("<cword>")
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local from = vim.fn.matchstrpos(line:sub(1, col + 1), "\\k*$")
    s_row = vim.api.nvim_win_get_cursor(0)[1]
    e_row = s_row
    s_col = from[2]
    e_col = s_col + #text - 1
  end
  text = vim.trim(text)
  if text == "" then return end
  local out = vim.fn.system({ "tiller", "new", "-print", "-from", vim.fn.expand("%:p"), text })
  if vim.v.shell_error ~= 0 then
    vim.notify("tiller: " .. out, vim.log.levels.ERROR)
    return
  end
  local id, path, title = out:match("^(.-)\t(.-)\t(.-)\n?$")
  if not id then return end
  local link = ("[[id:%s][%s]]"):format(id, title)
  vim.api.nvim_buf_set_text(0, s_row - 1, s_col, e_row - 1, e_col + 1, { link })
  vim.cmd("silent write")
  vim.notify("note: " .. title)
  if open_it then
    local n = vim.fn.system({ "sh", "-c", "grep -n -m1 '^$' " .. vim.fn.shellescape(path) .. " | cut -d: -f1" })
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_cursor(0, { tonumber(n) or 1, 0 })
  end
end
_G.tiller_note_from_text = tiller_note_from_text
vim.keymap.set({ "n", "v" }, "<leader>oz", function() tiller_note_from_text(false) end, { desc = "Note from word (stay)" })
vim.keymap.set({ "n", "v" }, "<leader>oZ", function() tiller_note_from_text(true) end, { desc = "Note from word (open)" })

-- Reopen the journal in the same float the capture uses.
--
-- The capture template is append-only by design: it always starts a NEW entry
-- under today's date, so there is no way through it to carry on with one you
-- began earlier. Doing that in the file meant a split at the bottom of the
-- screen, which is a jarring change of context after writing the first half in
-- a centred float.
--
-- This is the real daily file in a float, not a copy: :w writes the actual
-- file and there is nothing to synchronise back, which also means it cannot
-- invent the kind of divergence Syncthing turns into a conflict file.
local function journal_float()
  -- The same arithmetic as orgmode's utils.open_float at the same scale, so
  -- this window and the capture window are the same size in the same place.
  -- The window opens on a throwaway scratch buffer and the file is read into
  -- it afterwards, rather than the other way round.
  local scale = 0.85
  local width = math.floor(vim.o.columns * scale)
  local height = math.floor(vim.o.lines * scale)
  local win = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " journal ",
    title_pos = "center",
  })

  -- :edit, not bufadd + bufload. bufload raises a Lua error when a swap file
  -- exists — the journal open in another nvim, or one that crashed earlier —
  -- so the key failed with a stack traceback instead of vim's own ATTENTION
  -- prompt, which is the thing that actually explains the situation and
  -- offers recovery. :edit keeps that handling, inside this window.
  local today = journal_today()
  if not pcall(vim.cmd.edit, vim.fn.fnameescape(today)) then
    pcall(vim.api.nvim_win_close, win, true)
    vim.notify("journal: could not open " .. today, vim.log.levels.ERROR)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()

  -- Explicit, because almost everything org_window_opts sets is window-local
  -- and FileType does not fire again for a buffer that is already loaded —
  -- which is the normal case here, the journal usually being open already.
  org_window_opts()

  -- The whole file is today, so the end of it is where you left off.
  vim.cmd("normal! G")
  vim.cmd("normal! zz")

  -- <C-c> finishes, the same key that finalises a capture, so the two windows
  -- are driven the same way. Not mapped to q on purpose: q is macro recording,
  -- and this is a real file buffer where losing that would be felt.
  vim.keymap.set("n", "<C-c>", function()
    if vim.bo[bufnr].modified then
      vim.cmd("write")
    end
    pcall(vim.api.nvim_win_close, win, false)
  end, { buffer = bufnr, desc = "Save and close the journal float" })

  -- Buffer-local mappings outlive the window, and the daily file is one you
  -- also open normally, where <C-c> meaning "write and close" would be a
  -- surprise. Drop it when the float goes.
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      pcall(vim.keymap.del, "n", "<C-c>", { buffer = bufnr })
    end,
  })
end
map("<leader>oj", journal_float, "Journal: continue today in a float")
map("<Esc>", "<cmd>nohlsearch<cr>", "Clear search")

-- Syncthing carries ~/orgfiles between the two machines, and it does not merge.
-- When the same file changes in both places it keeps one copy and parks the
-- other as <name>.sync-conflict-<date>.org, which is easy not to notice — one
-- sat here for two days holding an entry that existed nowhere else.
--
-- The usual way to cause that is to leave the journal open in nvim on one
-- machine and write on the other: the buffer here is now stale, and the next
-- :w sends a whole file back that never saw the other machine's entry.
--
-- autoread fixes the harmless half of that — an unmodified buffer quietly
-- takes the newer file — but autoread only acts when nvim looks, and nvim only
-- looks on certain events. checktime is what makes it look. The dangerous half
-- (changed on disk AND unsaved changes here) nvim refuses to resolve on its
-- own and prompts, which is the correct answer: that one needs a human.
--
-- Registered once at top level, not inside the FileType callback, which would
-- add another copy of each autocmd for every org buffer opened.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  pattern = "*.org",
  command = "silent! checktime",
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  pattern = "*.org",
  callback = function(ev)
    vim.notify(
      ("%s changed on disk and was reloaded"):format(vim.fn.fnamemodify(ev.file, ":t")),
      vim.log.levels.WARN
    )
  end,
})

-- jk leaves insert mode, the habit carried over from evil-escape in Doom.
-- Also mapped in terminal mode, where <Esc> is usually swallowed by the shell.
-- timeoutlen is 400 above, which is what keeps the pause after a lone "j"
-- short enough not to notice.
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
