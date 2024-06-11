---@type Rabbit.Compat
local compat = {
    windows = {
        path = "\\",
        warn = true,
        name = "Windows",
        has = { "win32", "win64" },
    },

    linux = {
        path = "/",
        warn = false,
        name = "Linux",
        has = { "linux" },
    },

    macos = {
        path = "/",
        warn = false,
        name = "macOS",
        has = { "macos" },
    },

    __default__ = {
        path = "/",
        warn = false,
        name = "<nil>",
        has = {},
    },
}

local ret = compat.__default__

for _, v in pairs(compat) do
    for _, o in ipairs(v.has) do
        if vim.fn.has(o) == 1 then
            ret = v
            break
        end
    end
end

local parts = vim.split(debug.getinfo(1).source:sub(2), ret.path)
table.remove(parts, #parts)
table.remove(parts, #parts)
table.remove(parts, #parts)

local path = table.concat(parts, ret.path) .. ret.path .. "memory" .. ret.path
vim.uv.fs_mkdir(path, 493) -- 0x755 = u=rwx; g=r-x; o=r-x
local file = path .. "__compat_warning__"
vim.fn.fnamemodify(file, ":p")

if ret.warn == false then
    --pass
elseif io.open(file, "r") == nil then
    vim.cmd("echohl WarningMsg")
    vim.cmd('echo "WARNING: "')
    vim.cmd("echohl None")
    vim.cmd('echon "Rabbit is not supported on ' .. ret.name .. '."')
    vim.print("If you experience any problems, please open a ticket:")
    vim.print("https://github.com/VoxelPrismatic/rabbit.nvim/issues")
    io.open(file, "w+"):write("1")
else
    vim.cmd("echohl WarningMsg")
    vim.cmd('echo "Reminder: "')
    vim.cmd("echohl None")
    vim.cmd('echon "' ..
        "Report any compatibility issues to " ..
        "http://prz0.github.io/rabbit/issues" ..
    '"')
end

return ret

