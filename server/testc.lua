
local cryptoNet = require("/Docs/utils/cryptoNet")
local Logger = require("utils.simpleLogging")
local log = Logger.new("/Docs/server.log")
local inspect = require("utils.inspect")


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
	log("Received event: ", inspect.inspect(event))

	return
end

cryptoNet.startEventLoop(onStart, onEvent)

print("[End of Program]")
-- End of File