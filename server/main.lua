
local basalt = require("utils/basaltMin")
local inspect = require("utils/inspect")
local meBridge = require("utils.meBridge")


LOG_FILE_PATH = "/Docs/server-basalt.log"
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


local bridge = meBridge.ensureMEBridgeExists()
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



local function array_includes(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end








-- Not a full script, but the core recursive idea:
local function getRawMaterials(meBridge, itemName, amount)
	local recipe = meBridge:getPattern({
		name = itemName,
		count = amount
	})
	if not recipe then 
		log("No recipe found for item: " .. itemName)
		return {[itemName] = amount}
	end
	local materials = {}

	local requiredInputs = recipe.inputs

	for _, ingredient in ipairs(requiredInputs) do
		local sub = getRawMaterials(meBridge, ingredient.name, ingredient.count * amount)
		for k, v in pairs(sub) do
			materials[k] = (materials[k] or 0) + v
		end
	end
	return materials
end










local usernames_roles_sockets = {
	["BobTheBuilder"] = {
		["client_pocket"] = {
			["id"] = "some_long_id_1",
			["socket"] = {} -- the socket object
		},
		["client_stock"] = {
			["id"] = "some_long_id_2",
			["socket"] = {} -- the socket object
		}
	}
}
local function getRoleOfSocket(socket)
	for username, roles in pairs(usernames_roles_sockets) do
		for role, info in pairs(roles) do
			if info.socket == socket then
				return role
			end
		end
	end
	return nil
end
local function getSocketByRole(username, role)
	if usernames_roles_sockets[username] and usernames_roles_sockets[username][role] then
		return usernames_roles_sockets[username][role].socket
	end
	return nil
end
local valid_roles = {"client_pocket", "client_stock"}

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
	elseif message.tag == "request_craft_order" then
		local itemName = message.itemName
		local amount = message.amount
		local fingerprint = message.fingerprint
		-- do things here, step "Begin crafting order"

		local stockSocket = getSocketByRole(socket.username, "client_stock")
		if not stockSocket then
			log("No client_stock socket found for user " .. tostring(socket.username))
			return
		end
		cryptoNet.send(stockSocket, {
			tag = "query_materials_can_craft_happen",
			itemName = itemName,
			amount = amount,
			fingerprint = fingerprint
		})
	elseif message.tag == "query_materials_can_craft_happen:response" then
		local canCraft = message.canCraft
		if canCraft then
			log("Crafting is possible for item " .. message.itemName .. " (x" .. message.amount .. ").")
		else
			log("Crafting is NOT possible for item " .. message.itemName .. " (x" .. message.amount .. ").")
		end

	elseif message.tag == "indicate_role" then

		-- log("Message:")
		-- logTable(message)
		-- log("\n")
		-- log("Socket:")
		-- logTable(socket)
		-- log("\n")
		-- log("Server:")
		-- logTable(server)

		local role = message.role
		log("Client indicated role: " .. tostring(role))
		if not role or not array_includes(valid_roles, role) then
			log("Invalid role: " .. tostring(role))
			return
		end

		--[[ Section: Update the usernames_roles_sockets table ]]
		if not usernames_roles_sockets[socket.username] then
			usernames_roles_sockets[socket.username] = {}
		end
		usernames_roles_sockets[socket.username][role] = {
			id = socket.target,
			socket = socket
		}
		log("User " .. tostring(socket.username) .. " set to role: " .. tostring(role))
		logTable(usernames_roles_sockets)

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