
local Logger = require("utils.simpleLogging")
local log = Logger.new("/Docs/clientstock.log")
local cryptoNet = require("utils.cryptoNet")
local meBridge = require("utils.meBridge")
local bridge = meBridge.ensureMEBridgeExists()
if not bridge then
	log:error("Failed to ensure ME Bridge exists. Exiting.")
	error("Failed to ensure ME Bridge exists. Exiting.")
	return
end

-- DEFAULT_PRINT = print
-- print = function(...)
-- 	local output = table.concat({...}, " ")
-- 	log:info(output)
-- 	DEFAULT_PRINT(...)
-- end

log:info("Starting the server...")
log:warn("awooga")

local function handle_meBridge_messages_clientstock(message_table, socket, server)
	local message = message_table

	if message.tag == "query_materials_can_craft_happen" then
		local canCraft = bridge:isItemCraftable({
			name = message.itemName,
			count = message.amount
		})
		local response = {
			tag = "query_materials_can_craft_happen:response",
			canCraft = canCraft,
			itemName = message.itemName,
			amount = message.amount
		}
		cryptoNet.send(socket, response)
	end


	return
end
local function process_message_table(message_table, socket, server)
	handle_meBridge_messages_clientstock(message_table, socket, server)
	return
end


local thisUserSocket = nil
local function onStart()
	local socket = cryptoNet.connect("Cinnamon-AE2-ME-Requester")
	if not socket then
		log:error("Failed to connect to the server.")
		error("Failed to connect to the server.")
		return
	end
	print("Username: ")
	local username = read()
	print("Password: ")
	local password = read("*")
	cryptoNet.login(socket, username, password)
	thisUserSocket = socket
end

local function onEvent(event)
	if event[1] == "login" then
		local username = event[2]
		local socket = event[3]
		log:info("User logged in as " .. username .. " successfully.")
		cryptoNet.send(socket, "Hello from clientstock!")

		cryptoNet.send(socket, {
			tag = "indicate_role",
			role = "client_stock"
		})

	elseif event[1] == "login_failed" then
		local reason = event[2]
		log:error("Login failed: " .. reason)
		print("Login failed: " .. reason)
	elseif event[1] == "connection_closed" then
		local reason = event[2]
		log:warn("Connection closed: " .. textutils.serialise(reason))
		print("Connection closed: " .. textutils.serialise(reason))
	elseif event[1] == "encrypted_message" then
		local message = event[2]
		local socket = event[3]
		local server = event[4]

		if type(message) == "table" then
			process_message_table(message, socket, server)
		end

		print(message)
	end
end

cryptoNet.startEventLoop(onStart, onEvent)



print("[End of Program]")
-- End of File