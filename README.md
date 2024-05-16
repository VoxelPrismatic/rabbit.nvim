# Rabbit.nvim
![logo](/rabbit.png)
Quickly jump between buffers

---

This tool tracks the history of buffers opened in an individual window. With a quick
motion, you can be in any one of your last twenty buffers without remembering any
details.

Unlike other tools, this remembers history *per window*, so you can really jump
quickly.

### Why
1. [theprimeagen/harpoon](https://github.com/theprimeagen/harpoon) requires explicit
adding of files, which is too much effort
2. Telescope:buffers doesn't remember history. You still have to remember what your
last file was
3. Same applies with `:ls` and `:b`


### Install
Lazy:
```lua
return {
    "voxelprismatic/rabbit.nvim",
    config = function()
        require("rabbit").setup("<leader>r")  -- Any keybind you like.
    end,
}
```

### Usage
Just run your keybind!

With Rabbit open, you can hit a number 1-0 (1-10) to jump to that buffer. You can
also move your cursor down to a specific line and hit enter to jump to that buffer.

If you hit `<CR>` immediately after launching Rabbit, it'll open your previous buffer.
You can hop back and forth between buffers very quickly, almost like a rabbit...

If you click away from the Rabbit window, it'll close.

If you try to modify the Rabbit buffer, it'll close.

### Configuration
None. Deal with it.

### Preview
<video src="/video.mp4"></video>
