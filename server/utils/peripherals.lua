
local PERIPHERALS = {}

function PERIPHERALS.ensureMEBridgeExists()
	PERIPHERALS["meBridge"] = PERIPHERALS["meBridge"] or nil
	local peripheralsWhichExist = peripheral.getNames()
	---@type ccTweaked.peripherals.wrappedPeripheral
	local bridge = nil
	if peripheralsWhichExist == nil or #peripheralsWhichExist == 0 then
		print("No peripherals found.")
		return
	end
	for _, directionName in ipairs(peripheralsWhichExist) do
		local temp = peripheral.wrap(directionName)
		local success, result = pcall((function()
			return (temp ~= nil and temp["isConnected"] ~= nil)
		end))
		if success and result == true then
			bridge = temp
			print("Found ME Bridge at " .. directionName .. " direction.")
			break
		end
	end
	PERIPHERALS["meBridge"] = bridge
	if bridge == nil then
		print("No ME Bridge found in any direction.")
		print("Available peripherals:")
		for _, name in ipairs(peripheralsWhichExist) do
			print(" - " .. name)
		end
		print()
		print("Please ensure the ME Bridge is connected and try again.")
		return nil
	end
	return bridge
end

return PERIPHERALS
-- End of File