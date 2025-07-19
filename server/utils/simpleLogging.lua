local inspect = require("utils.inspect")
local arrayMethods = require("utils.arrayMethods")

local SimpleLogger = {}
SimpleLogger.__index = SimpleLogger

function SimpleLogger.new(logfile)
    local self = setmetatable({}, SimpleLogger)
    self.logfile = logfile or "log.txt"
    return setmetatable(self, {
        __index = SimpleLogger,
        __call = function(logger, ...)
            return logger:info(...)
        end
    })
end

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias T_InspectOptions {depth?: number, newline?: string, indent?: string, process?: fun(value: any): any}

local defaultTableInspectOptions = {
    depth = 2,
    newline = "\n",
    indent = "  ",
    process = nil
}

--- Creates a new set of inspect options based on the default options and the provided ones.
---@param options T_InspectOptions
---@return T_InspectOptions
function SimpleLogger.InspectOptions(options)
    local opts = arrayMethods.copyAssociative(defaultTableInspectOptions)
    for k, v in pairs(options) do
        opts[k] = options[k]
    end
    return setmetatable(opts, {
        __type = "T_InspectOptions",
    })
end




function SimpleLogger:_write(level, ...)
    local args = {...}
    -- print(inspect.inspect(args))

    local hasTablesInArgs = arrayMethods.some(args, function(arg)
        return type(arg) == "table"
    end)
    local lastArgIsTable = type(args[#args]) == "table"

    -- print("hasTablesInArgs:", hasTablesInArgs, "lastArgIsTable:", lastArgIsTable)

    ---@type T_InspectOptions
    local tableInspectOptions = defaultTableInspectOptions
    if hasTablesInArgs and lastArgIsTable then
        -- Check whether last arg is a table formatted like the defaultTableInspectOptions
        -- This means it must have at least 1 of the keys in defaultTableInspectOptions
        local lastArg = args[#args]
        -- check meta key "__type" to see if it is T_InspectOptions
        -- getmetatable(lastArg)  -- This will throw an error if lastArg is not a table
        if getmetatable(lastArg) ~= nil and getmetatable(lastArg).__type == "T_InspectOptions" then
            tableInspectOptions = lastArg
            -- remove lastArg from args because we don't want to log the actual options table
            table.remove(args, #args)
            print("Removed an item from end")
        end
        -- else case implicitly handled
    end
    -- else case implicitly handled

    local outputBuffer = ""
    for i=1, #args do
        local arg = args[i]
        -- print("Processing argument %d: %s", i, tostring(arg))
        if type(arg) == "table" then
            outputBuffer = outputBuffer .. inspect.inspect(arg, tableInspectOptions)
        -- elseif arg == nil then
        --     outputBuffer = outputBuffer .. "nil"
        else
            outputBuffer = outputBuffer .. tostring(arg)
        end
        if i < #args then
            outputBuffer = outputBuffer .. " "  -- add a space between arguments, but not at end of arguments
        end
    end
    if outputBuffer == "" then
        outputBuffer = "\n"  -- Ensure there's at least a newline if no output
    end

    local f, err = io.open(self.logfile, "a")
    if f then
        local line = string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, outputBuffer)
        f:write(line)
        f:close()
    else
        print("Error opening log file: " .. tostring(err))
    end
end

function SimpleLogger:info(...) self:_write("INFO", ...) end
function SimpleLogger:warn(...) self:_write("WARN", ...) end
function SimpleLogger:error(...) self:_write("ERROR", ...) end
function SimpleLogger:debug(...) self:_write("DEBUG", ...) end
function SimpleLogger:clear()
    local f, err = io.open(self.logfile, "w")
    if f then
        f:close()
    else
        print("Error clearing log file: " .. tostring(err))
    end
end

return SimpleLogger
-- End of File