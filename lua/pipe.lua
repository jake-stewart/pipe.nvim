local SAFE_COMMANDS = {
    "grep", "egrep", "sed", "awk", "seq", "tac",
    "cat", "rg", "fd", "find", "sh", "bash",
    "zsh", "cut", "sort", "tr", "xargs", "ls",
    "python3", "perl", "echo", "printf"
}
local UNSAFE = false

-- this is not fool proof
-- it should be enough to stop accidents
local function isSafeCommand(command)
    for _, pipe in pairs(vim.split(command, "|", {trimempty=true})) do
        local cmd = vim.split(pipe, " ", {trimempty=true})[1]
        if not cmd then
            break
        end
        local safe = false
        for _, safeCommand in pairs(SAFE_COMMANDS) do
            if cmd == safeCommand then
                safe = true
                break
            end
        end
        if not safe then
            return false
        end
    end
    return true
end

local function pipePreview(opts, preview_ns)
    local cmd = vim.fn.split(opts.args)[1]
    local buf = vim.api.nvim_get_current_buf()
    local input = vim.api.nvim_buf_get_lines(
        buf, opts.line1 - 1, opts.line2, false)
    local lines = input
    if UNSAFE or isSafeCommand(cmd) then
        local output = vim.fn.systemlist(opts.args, input)
        if vim.v.shell_error == 0 then
            lines = output
        end
    end
    vim.api.nvim_buf_set_lines(buf, opts.line1 - 1, opts.line2, false, lines)
    for i, _ in ipairs(lines) do
        vim.api.nvim_buf_add_highlight(buf, preview_ns, "Visual",
            opts.line1 + i - 2, 0, -1)
    end
    return 1
end

local function pipe(opts)
    vim.cmd(opts.line1 .. "," .. opts.line2 .. "!" .. opts.args)
end

return {
    setup = function(opts)
        opts = opts or {}
        if opts.safeCommands then
            for _, command in pairs(opts.safeCommands) do
                table.insert(SAFE_COMMANDS, command)
            end
        end
        if opts.unsafe then
            UNSAFE = true
        end
        vim.api.nvim_create_user_command("Pipe", pipe, {
            nargs = "?", range = true, addr = "lines", preview = pipePreview
        })
    end,
}
