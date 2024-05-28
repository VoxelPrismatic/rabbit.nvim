### History
Tracks your most recent buffer, and filters by window. That means, in split views, running rabbit will only list the
buffers that the current window has opened.

Why not `:ls` and `:b`? Well, those both require *you* to remember everything. Say you use Lspsaga and jump to the
token or struct definition. Well, which is faster, `<leader>r`, `<CR>`, or typing `:ls` to list ALL buffers available,
then finding the one you need, then `:b #`. Rabbit is simply faster in this scenario.

### Reopen
Tracks your recently closed buffers, and filters by window. If you ever accidentally close a buffer, you can easily
recover with a little `<leader>r`, `o`, `<CR>`. That is, if the window didn't close, of course.

### Oxide
Tracks the files you open from a specific directory, and organizes by a score similar to zoxide. If you work in a
specific directory often, then it'll allow you to reopen your buffers quickly.

Yes, there is Prime's Harpoon, but remember, that still needs explicit adding and deleting of files. This is completely
automatic. Simply use neovim like you always do, and this works in the background.

