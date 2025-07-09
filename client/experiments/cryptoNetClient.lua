local cryptoNet = require("/Docs/utils/cryptoNet")

function onStart()
	local socket = cryptoNet.connect("LoginDemoServer")
	-- cryptoNet.send(socket, "Hello server!")
	cryptoNet.login(socket, "Bobby", "mypass123")
end

function onEvent(event)
	if event[1] == "login" then
		local username = event[2]
		local socket = event[3]
		print("Logged in as "..username)
		cryptoNet.send(socket, "Hello server!")
	elseif event[1] == "login_failed" then
		print("Did not log in.")
	elseif event[1] == "encrypted_message" then
		print("Server said: " .. event[2])
	end
end

cryptoNet.startEventLoop(onStart, onEvent)
print("[End of Program]")
-- End of File