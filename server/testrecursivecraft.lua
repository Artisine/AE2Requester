
local Logger = require("utils.simpleLogging")
local log = Logger.new("/Docs/server-test-recursivecraft.log")
---@diagnostic disable-next-line: different-requires
local inspect = require("utils.inspect")
local meBridge = require("utils.meBridge")
local bridge = meBridge.ensureMEBridgeExists()
if not bridge then
	log:error("Failed to ensure ME Bridge exists. Exiting.")
	error("Failed to ensure ME Bridge exists. Exiting.")
	return
end
log:clear()





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




local function main()
	-- local thing = getRawMaterials(bridge, "minecraft:wooden_pickaxe", 1)
	-- log("Raw materials needed for crafting a wooden pickaxe: ", thing)

	local meth = peripheral.getMethods("bottom")
	log("methods: ", meth)

	do
---@diagnostic disable-next-line: undefined-field
		local thing, err = bridge.getPattern({
			name = "minecraft:wooden_pickaxe",
			count = 1
		})
		if not thing then
			log:error("Error getting pattern: " .. err)
			return
		end
	end




	return
end
main()
print("[End of Program]")
-- End of File