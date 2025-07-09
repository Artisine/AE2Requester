
local cryptoNet = require("/Docs/utils/cryptoNet")
local basalt = require("/Docs/utils/basaltMin")
local inspect = require("/Docs/utils/inspect")



LOG_FILE_PATH = "/Docs/basalt.log"
-- clear log file
local file = fs.open(LOG_FILE_PATH, "w")
if file then
	file.close()
end
if not fs.exists(LOG_FILE_PATH) then
	print("Log file does not exist, creating it.")
	local file = fs.open(LOG_FILE_PATH, "w")
	if file then
		file.close()
	end
end
basalt.LOGGER.setLogToFile(true)
basalt.LOGGER.setEnabled(true)
basalt.LOGGER._logFile = LOG_FILE_PATH
basalt.LOGGER.info("ME Bridge Requester program")

DEFAULT_PRINT = print

Log = basalt.LOGGER
local levelMessages = {
    [Log.LEVEL.DEBUG] = "Debug",
    [Log.LEVEL.INFO] = "Info",
    [Log.LEVEL.WARN] = "Warn",
    [Log.LEVEL.ERROR] = "Error"
}

local levelColors = {
    [Log.LEVEL.DEBUG] = colors.lightGray,
    [Log.LEVEL.INFO] = colors.white,
    [Log.LEVEL.WARN] = colors.yellow,
    [Log.LEVEL.ERROR] = colors.red
}
local function writeToLogFile(message)
    if basalt.LOGGER._logToFile then
        local file = io.open(basalt.LOGGER._logFile, "a")
        if file then
            file:write(message.."\n")
            file:close()
        end
    end
end

local function _log(level, filePathPrepender, ...)
    if not basalt.LOGGER._enabled then return end

    local timeStr = os.date("%H:%M:%S")

    local info = debug.getinfo(3, "Sl")
    local source = info.source:match("@?(.*)")
    local line = info.currentline
    -- local levelStr = string.format("[%s:%d]", source:match("([^/\\]+)%.lua$"), line)

    local levelMsg = "[" .. levelMessages[level] .. "]"

    local message = ""
    for i, v in ipairs(table.pack(...)) do
        if i > 1 then
            message = message .. " "
        end
        message = message .. tostring(v)
    end

    local fullMessage = string.format("%s %s%s %s", timeStr, filePathPrepender, levelMsg, message)

    writeToLogFile(fullMessage)
    table.insert(Log._logs, {
        time = timeStr,
        level = level,
        message = message
    })
end



local log = function(...)
	if basalt.LOGGER._enabled then
		local args = {...}
		local info = debug.getinfo(2, "Sl")
		local line = info and info.currentline or "?"
		local src = info and info.short_src or "?"
		local prepend = "["..src..":"..line.."] "

		if #args == 0 then
			basalt.LOGGER.info(prepend.."")
			return
		end
		for i, obj in ipairs(args) do
			local thing = inspect.inspect(obj)
			_log(Log.LEVEL.INFO, prepend, thing)
			-- basalt.LOGGER.info(prepend .. thing)
		end
	end
end
local warn = function(...)
	if basalt.LOGGER._enabled then
		local args = {...}
		local info = debug.getinfo(2, "Sl")
		local line = info and info.currentline or "?"
		local src = info and info.short_src or "?"
		local prepend = "["..src..":"..line.."] "

		if #args == 0 then
			basalt.LOGGER.warn(prepend.."")
			return
		end
		for i, obj in ipairs(args) do
			local thing = inspect.inspect(obj)
			_log(Log.LEVEL.WARN, prepend, thing)
			-- basalt.LOGGER.warn(prepend .. thing)
		end
	end
end
local basaltError = basalt.LOGGER.error
local basaltDebug = basalt.LOGGER.debug
print = function(...)
	DEFAULT_PRINT(...)
	log(...)
end


local function logTable(t, options)
	local defaultOptions = {
		depth = 2,
		newline = "\n",
		indent = "  ",
		process = nil
	}
	local _options = {}
	if options == nil then
		options = {}
	end
	for k, v in pairs(options) do
		if defaultOptions[k] == nil then
			error("Invalid option: " .. k)
		end
		defaultOptions[k] = v
	end
	options = defaultOptions
	local output = inspect.inspect(t, options)

	local info = debug.getinfo(2, "Sl")
	local line = info and info.currentline or "?"
	local src = info and info.short_src or "?"
	local prepend = "["..src..":"..line.."] "

	_log(Log.LEVEL.INFO, prepend, output)
	return output
end
local function printTable(t, options)
	if t == nil then
		print("Table is nil")
		return
	end
	if type(t) ~= "table" then
		print("Not a table: " .. tostring(t))
		return
	end
	local output = logTable(t, options)
	DEFAULT_PRINT(output)
	return output
end




local function setupGui()
	local main = basalt.getMainFrame():setBackground(colors.gray):setSize(51, 19)
	local label_hello = main:addLabel("label_hello"):setText("Hello, world!"):setPosition(4, 4):setSize(20, 3):setForeground(colors.white)

	local button_stop = main:addButton("button_stop"):setText("Stop Server"):setPosition(4, 8):setSize(20, 3):setBackground(colors.red):setForeground(colors.white)
	button_stop:onClick(function()
		log("Stopping Basalt runtime...")
		basalt.stop()
	end)

	return
end












--- @alias CryptoNetEvent [string, table, table | string]

--- @param event CryptoNetEvent
local function onEvent(event)
	if event[1] == "login" then
		local socket = event[2]
		local username = socket.username
		print("Login event received, user " .. tostring(username) .. " connected.")
	end
	return
end


local function onStart()
	log("Server starting...")
	cryptoNet.setLoggingEnabled(false)

	-- setupGui()

	cryptoNet.host("Cinnamon-AE2-ME-Requester", false)
	return
end


local serverIsRunning = false
local function startCryptoNetServer()
	log("Starting CryptoNet event loop...")	
	cryptoNet.startEventLoop(onStart, onEvent)
	log("CryptoNet Event loop ended.")
	return
end

local function startBasalt()
	log("Starting Basalt runtime...")
	setupGui()
	basalt.run()
	while basalt.isRunning do
		os.sleep(0.25)
	end
	log("Basalt runtime ended.")
	serverIsRunning = false
	cryptoNet.closeAll()
	return
end
basalt.schedule(startCryptoNetServer)
serverIsRunning = true
startBasalt()
print("[End of Server Program]")
-- End of File