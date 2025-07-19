
local basalt = require("utils.basaltMin")
local Logger = require("utils.simpleLogging")
local log = Logger.new("/Docs/server-test-gui.log")
log:clear()

local main = basalt.getMainFrame()
main:setBackground(colors.white)
main:setSize(51, 19)
main:setPosition(1, 1)

local frame_topLeft = main:addFrame()
	:setPosition(1, 1)
	:setSize(10, 3)
	:setBackground(colors.white)
local label_topLeft = frame_topLeft:addLabel()
	:setText("Requester Server")
	:setPosition(1, 1)
	:setSize(10, 3)
	:setForeground(colors.black)

local frame_program = main:addFrame():setSize(26,19):setPosition(26,1):setBackground(colors.gray)
local element_program = frame_program:addProgram():setSize(26,19):setPosition(1,1)

element_program:execute("testloop.lua")


local exampleTable = {
	foo = "bar",
	baz = 42,
	nested = {
		hello = "world",
		another = {1, 2, 3}
	}
}


log(element_program, 1, 2, "awooga", true, nil, false, "a", exampleTable, Logger.InspectOptions({depth=1, indent="\t"}))
-- Yes, in Lua a function can take both named and variadic arguments.
-- Named arguments are typically passed as a table, and variadic arguments use ...
-- Example:
-- local function example(args, ...)
-- 	log("Named args: ", args)
-- 	local n = select("#", ...)
-- 	for i = 1, n do
-- 		log("Vararg "..i..": ", select(i, ...))
-- 	end
-- end
basalt.run()
print("[End of Program]")
log("[End of Program]")
-- End of File