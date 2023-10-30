vim.g.mapleader = " "

vim.keymap.set("n", "<leader>is2", function()
  vim.opt.expandtab = true
  vim.opt.tabstop = 2
  vim.opt.softtabstop = 2
  vim.opt.shiftwidth = 2
end, { desc = "[I]ndent [S]paces <2>" })
vim.keymap.set("n", "<leader>is4", function()
  vim.opt.expandtab = true
  vim.opt.tabstop = 4
  vim.opt.softtabstop = 4
  vim.opt.shiftwidth = 4
end, { desc = "[I]ndent [S]paces <4>" })
vim.keymap.set("n", "<leader>it", function()
  vim.opt.noexpandtab = true
  vim.opt.tabstop = 4
  vim.opt.softtabstop = 4
  vim.opt.shiftwidth = 4
end, { desc = "[I]ndent [T]abs" })

vim.keymap.set("n", "<Up>", "<nop>", {})
vim.keymap.set("n", "<Down>", "<nop>", {})
vim.keymap.set("n", "<Left>", "<nop>", {})
vim.keymap.set("n", "<Right>", "<nop>", {})

vim.keymap.set("n", "<Tab>", "<cmd>bn<CR>", { desc = "Next Buffer" })
vim.keymap.set("n", "<C-Tab>", "<cmd>bp<CR>", { desc = "Previous Buffer" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- paste over visual selection while keeping existing clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])
-- delete selection while keeping existing clipboard
vim.keymap.set("v", "<leader>d", [["_d]], { desc = "[D]elete (Keep Clipboard)" })

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>bf", vim.lsp.buf.format, { desc = "[B]uffer [F]ormat" })

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "[K] List Next Warning" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "[J] List Previous Warning" })

vim.keymap.set("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "[R]eplace Word Under Cur[S]or" })
vim.keymap.set("n", "<leader>fx", "<cmd>!chmod +x %<CR>", { silent = true, desc = "[F]ile e[X]ecutable" })

vim.keymap.set({ "n", "v", "t" }, "<C-q>", "<cmd>confirm qa<cr>", {})
vim.keymap.set("n", "<leader>bc", function()
  vim.cmd("set bufhidden=delete")
  local bufid = vim.api.nvim_get_current_buf()
  vim.cmd("confirm bp")
  if bufid == vim.api.nvim_get_current_buf() then
    vim.cmd("confirm enew")
  end
end, { desc = "[B]uffer [C]lose" })
