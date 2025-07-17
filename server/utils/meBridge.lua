
local PERIPHERALS = {}

---@class MEBridge_Output_CraftableItems : table
---@field name string The registry name of the item.
---@field fingerprint string? A unique fingerprint which identifies the item to craft.
---@field amount number The amount of the item in the system.
---@field displayName string The display name of the item.
---@field isCraftable boolean Whether the item has a crafting pattern or not.
---@field nbt string? NBT to match the item on.
---@field tags table A list of all the item tags.

---@class MEBridge_Type_ItemFilter : table
---@field name string The registry name of the item to filter for.
---@field type ("item" | "fluid" | "gas" | "energy")? The type of the thing to filter for.
---@field count number? The amount of the item to filter for.
---@field components table? A list of 'components' to filter for, equivalent to usage of NBT-filtering in versions < 1.20.5.

---@class MEBridge : ccTweaked.peripheral.Inventory
---@field isItemCraftable fun(self: MEBridge, item: MEBridge_Type_ItemFilter): boolean
---@field listCraftableItems fun(self: MEBridge): MEBridge_Output_CraftableItems
---@field craftItem fun(self: MEBridge, item: ({name: string, count: number?, nbt: string?} | {fingerprint: string, count: number?})): boolean

function PERIPHERALS.ensureMEBridgeExists()
	PERIPHERALS["meBridge"] = PERIPHERALS["meBridge"] or nil
	local peripheralsWhichExist = peripheral.getNames()
	---@type MEBridge
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
			---@cast temp MEBridge
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