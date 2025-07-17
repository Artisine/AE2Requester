
rednet.open("back")
local hostID = rednet.lookup("chat", "lobby")
if hostID then
	rednet.send(hostID, "Hello lobby!", "chat")
end

print("Sent message to lobby with ID: " .. tostring(hostID))
print("[End of Program]")
-- End of File