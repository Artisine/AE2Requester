
local basalt = require("utils/basaltMin")
local inspect = require("utils/inspect")
local peripherals = require("utils.meBridge")


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
	-- DEFAULT_PRINT(...)
	log(...)
end
_G.print = function(...)
	-- Intentionally do nothing, because
	--   do not want to print to terminal
	-- Use log functions instead!
	return nil
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


local bridge = peripherals.ensureMEBridgeExists()
if not bridge then
	log("No ME Bridge found, cannot proceed.")
	basaltError("No ME Bridge found, cannot proceed.")
	return nil
end

-- Modify the cryptoNet Lua script to replace its log and print functions
-- with this file's log and print functions.
-- Requires editing the Lua script dynamically.
-- Dynamically patch cryptoNet's source to replace its local log/print functions with this file's versions

local cryptoNet = require("utils/cryptoNet")




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













---comment
---@param message_table table
local function handle_meBridge_messages(message_table, socket, server)
	local message = message_table
	if message.tag == "materials_bill" then
		---@type {tag: string, itemName: string, amount: number}
		message = message
		local itemFilter = {
			name = message.itemName,
			count = message.amount
		}
		---@type boolean
		local isItemCraftable = bridge:isItemCraftable(itemFilter)
		if isItemCraftable then
			log("Item " .. message.itemName .. " with amount " .. message.amount .. " is craftable.")
		else
			log("Item " .. message.itemName .. " with amount " .. message.amount .. " is NOT craftable.")
		end

	elseif message.tag == "all_craftable_items" then
		local craftableItems = bridge:listCraftableItems()
		log("Received all craftable items from ME Bridge.")
		log("Craftable items total: " .. tostring(#craftableItems))
		cryptoNet.send(socket, {
			tag = "all_craftable_items:response",
			craftableItems = craftableItems
		})
		log("Sent list to socket " .. tostring(socket.username or "??") .. ".")
	else
		log("Unknown message tag: " .. tostring(message.tag))
	end
end

















local function process_message_string(message_string, socket, server)

	return
end

local function process_message_table(message_table, socket, server)
	handle_meBridge_messages(message_table, socket, server)
		
	return
end





--- @alias CryptoNetEvent [string, table, table | string]

--- @param event CryptoNetEvent
local function onEvent(event)
	if event[1] == "login" then
		local username = event[2]
		local socket = event[3]
		log("Login event received, user " .. tostring(username) .. " connected.")
	end

	if event[1] == "encrypted_message" then
		local message = event[2]
		local socket = event[3]
		local server = event[4]
		if type(message) == "string" then
			process_message_string(message, socket, server)
		elseif type(message) == "table" then
			process_message_table(message, socket, server)
		else
			log("Unknown message type: " .. type(message))
			return
		end
	end

	return
end


local function onStart()
	log("Server starting...")
	cryptoNet.setLoggingEnabled(true)

	-- setupGui()

	local server = cryptoNet.host(
		"Cinnamon-AE2-ME-Requester",
		false,
		false,
		"top",
		"Cinnamon-AE2-ME-Requester.crt",
		"Cinnamon-AE2-ME-Requester_private.key",
		"Cinnamon-AE2-ME-Requester_users.tbl"
	)

	log("CryptoNet server started on port " .. tostring(server.channel) .. ".")
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