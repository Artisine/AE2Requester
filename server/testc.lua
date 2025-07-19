
local cryptoNet = require("utils.cryptoNet")
local Logger = require("utils.simpleLogging")
local log = Logger.new("/Docs/server.log")
local inspect = require("utils.inspect")

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

	log(prepend .. output)
	return output
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
local function onEvent(event)
	log("Received event: ")
	logTable(event)
	
	return
end

cryptoNet.startEventLoop(onStart, onEvent)

print("[End of Program]")
-- End of File