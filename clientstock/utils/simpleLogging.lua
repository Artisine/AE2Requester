local SimpleLogger = {}
SimpleLogger.__index = SimpleLogger

function SimpleLogger.new(logfile)
    local self = setmetatable({}, SimpleLogger)
    self.logfile = logfile or "log.txt"
    return self
end

function SimpleLogger:_write(level, msg)
    local f, err = io.open(self.logfile, "a")
    if f then
        local line = string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, msg)
        f:write(line)
        f:close()
    else
        print("Error opening log file: " .. tostring(err))
    end
end

function SimpleLogger:info(msg) self:_write("INFO", msg) end
function SimpleLogger:warn(msg) self:_write("WARN", msg) end
function SimpleLogger:error(msg) self:_write("ERROR", msg) end
function SimpleLogger:debug(msg) self:_write("DEBUG", msg) end

return SimpleLogger
-- End of File