-- local fs = require("fs")
-- local colors = require("colors")
local strings = require("cc.strings")

local basalt = require "basalt.init"
local BaseFrame = require "basalt.elements.BaseFrame"
local TextBox = require "basalt.elements.TextBox"


---@class BaseFrame
---@field addTextBox fun(self: BaseFrame): TextBox
---@field addButton fun(self: BaseFrame): Button

---@type BaseFrame
local main = basalt.getMainFrame()


-- Terminal-like output area
---@type TextBox
local outputBox = main:addTextBox()
	:setSize("{parent.width-2}", "{parent.height-2}")
	:setPosition(1, 2)
	:setBackground(colors.black)
	:setForeground(colors.white)


-- Pastel yellow button in top-right
local helloButton = main:addButton()
	:setText("Hello")
	:setSize(10, 1)
	:setPosition("{parent.width - 9}", 1)
	:setBackground(colors.yellow)
	:setForeground(colors.black)


-- Button click: append "hello" to output
helloButton:onClick(function()
    local currentText = outputBox:getText()
	local amendedText = currentText .. "\nHello World!"
	outputBox:setText(amendedText)

	-- set cursor to end of that text
	local lines = strings.split(amendedText, "\n")
	local numberLines = #lines
	local lastLine = lines[numberLines]
	local cursorX = #lastLine + 1
	local cursorY = numberLines
	outputBox.cursorX = cursorX
	outputBox.cursorY = cursorY
	outputBox:updateViewport()

	basalt.update()
end)


-- local scope = {
-- 	["colors.gray"] = colors.gray,
-- 	whenPing = function(self)
-- 		-- show a modal alert box like in javascript
-- 		local alertBox = main:addLabel()
-- 			:setText("Ping received!")
-- 			:setSize(20, 3)
-- 			:setPosition("{parent.width/2 - 10}", "{parent.height/2 - 1}")
-- 			:setBackground(colors.gray)
-- 			:setForeground(colors.white)
-- 		alertBox:prioritize()
-- 		alertBox:onClick(function()
-- 			alertBox:destroy()
-- 		end)
-- 	end
-- }
-- local xmlFile, err = fs.open("/Docs/ui/example.xml", "r")
-- print(xmlFile)
-- print(err)
-- main:loadXML(xmlFile.readAll(), scope)
-- xmlFile.close()


-- start Basalt
basalt.run()

-- End of File