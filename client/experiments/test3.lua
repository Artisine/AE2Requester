
local basalt = require("basalt.init")
local printing = require("utils.printing")

local a = peripheral.getNames()
print(a)
for k,v in pairs(a) do
	print(k, v)
end


local meBridges = {
	peripheral.find("meBridge", function (name, wrapped)
		print("Found ME Bridge: " .. name)
		return wrapped ~= nil and wrapped.isConnected() and wrapped
	end)
}

---@type ccTweaked.peripherals.wrappedPeripheral
local bridge = meBridges[1]
print(bridge)

local meths = peripheral.getMethods("right")
if meths == nil then
	print("No methods found for the ME Bridge. (probably wrong bridge name)")
	return
end
print("Available methods:")
for _, meth in ipairs(meths) do
	print(" - " .. meth)
end

print()
print()

local thing = bridge.listItems()
if thing == nil then
	print("No items found in the ME Bridge.")
	return
end
print("Items in the ME Bridge:")
print(thing)
for k, item in ipairs(thing) do
	-- print(" - " .. item.name .. " (Count: " .. item.count .. ")")
	print(k)
	print(item.name)
end

print(string.rep("\n", 3))

local itemStack_oakLog = bridge.getItem({
	name = "minecraft:oak_log"
})
if itemStack_oakLog == nil then
	print("No oak logs found in the ME Bridge.")
	return
end
print("Oak Logs in the ME Bridge:")
print(" - " .. itemStack_oakLog.name .. " (Count: " .. itemStack_oakLog.amount .. ")")


local itemFilter_woodenPickaxe = {
	name = "minecraft:wooden_pickaxe",
	count = 1
}
local canBeCrafted_woodenPickaxe = bridge.isItemCraftable(itemFilter_woodenPickaxe)
if canBeCrafted_woodenPickaxe then
	print("Wooden Pickaxe can be crafted.")
else
	print("uh oh , Wooden Pickaxe cannot be crafted.")
end

printing.verticalSpace(3)

local craftableItems = bridge.listCraftableItems()
if craftableItems == nil or #craftableItems == 0 then
	print("No craftable items found in the ME Bridge.")
	return
end
for i, itemObj in ipairs(craftableItems) do
	print("Craftable Item " .. i .. ":")
	print(" - Name: " .. itemObj.name)
	print(" - Count: " .. itemObj.amount)
	print(" - Craftable: " .. tostring(itemObj.isCraftable))
	printing.verticalSpace(1)
end

print("[End of Program]")
-- End of File