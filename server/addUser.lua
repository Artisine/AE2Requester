---@diagnostic disable-next-line: different-requires
local cryptoNet = require("utils.cryptoNet")

cryptoNet.host("Cinnamon-AE2-ME-Requester")

term.write("Username: ")
local username = read()
print()

local pass_val = ""
while pass_val == "" do
	term.write("Password: ")
	local password = read("*")
	print()
	term.write("Confirm Password: ")
	local confirm = read("*")
	if password == confirm then
		---@cast password string
		pass_val = password
	else
		print("Passwords do not match. Please try again.")
	end
end

cryptoNet.addUser(username, pass_val)
cryptoNet.closeAll()

print("[End of Server Program]")
-- End of File