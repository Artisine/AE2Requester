
-- local basalt = require("basalt.init")
local basalt = require("basaltMin")
local printing = require("utils.printing")
local inspect     = require("utils.inspect")
---@diagnostic disable-next-line: different-requires
local cryptoNet = require("utils.cryptoNet")

-- local capacityRoot = fs.getCapacity("/")
-- local freeSpaceRoot = fs.getFreeSpace("/")
-- print("Root has capacity (bytes): " .. tostring(capacityRoot) .. " - free space (bytes): " .. tostring(freeSpaceRoot))



local null = {
	isNull = true,
	_type = "null"
}
local undefined = nil




LOG_FILE_PATH = "/Docs/basalt.log"
-- clear log file
local file = fs.open(LOG_FILE_PATH, "w")
if file then
	file.close()
end
if not fs.exists(LOG_FILE_PATH) then
	print("Log file does not exist, creating it.")
	local file = fs.open(LOG_FILE_PATH, "w")
	if file then
		file.close()
	end
end
basalt.LOGGER.setLogToFile(true)
basalt.LOGGER.setEnabled(true)
basalt.LOGGER._logFile = LOG_FILE_PATH
basalt.LOGGER.info("ME Bridge Requester program")

DEFAULT_PRINT = print

Log = basalt.LOGGER
local levelMessages = {
    [Log.LEVEL.DEBUG] = "Debug",
    [Log.LEVEL.INFO] = "Info",
    [Log.LEVEL.WARN] = "Warn",
    [Log.LEVEL.ERROR] = "Error"
}

local levelColors = {
    [Log.LEVEL.DEBUG] = colors.lightGray,
    [Log.LEVEL.INFO] = colors.white,
    [Log.LEVEL.WARN] = colors.yellow,
    [Log.LEVEL.ERROR] = colors.red
}
local function writeToLogFile(message)
    if basalt.LOGGER._logToFile then
        local file = io.open(basalt.LOGGER._logFile, "a")
        if file then
            file:write(message.."\n")
            file:close()
        end
    end
end

local function _log(level, filePathPrepender, ...)
    if not basalt.LOGGER._enabled then return end

    local timeStr = os.date("%H:%M:%S")

    local info = debug.getinfo(3, "Sl")
    local source = info.source:match("@?(.*)")
    local line = info.currentline
    -- local levelStr = string.format("[%s:%d]", source:match("([^/\\]+)%.lua$"), line)

    local levelMsg = "[" .. levelMessages[level] .. "]"

    local message = ""
    for i, v in ipairs(table.pack(...)) do
        if i > 1 then
            message = message .. " "
        end
        message = message .. tostring(v)
    end

    local fullMessage = string.format("%s %s%s %s", timeStr, filePathPrepender, levelMsg, message)

    writeToLogFile(fullMessage)
    table.insert(Log._logs, {
        time = timeStr,
        level = level,
        message = message
    })
end



local log = function(...)
	if basalt.LOGGER._enabled then
		local args = {...}
		local info = debug.getinfo(2, "Sl")
		local line = info and info.currentline or "?"
		local src = info and info.short_src or "?"
		local prepend = "["..src..":"..line.."] "

		if #args == 0 then
			basalt.LOGGER.info(prepend.."")
			return
		end
		for i, obj in ipairs(args) do
			local thing = inspect.inspect(obj)
			_log(Log.LEVEL.INFO, prepend, thing)
			-- basalt.LOGGER.info(prepend .. thing)
		end
	end
end
local warn = function(...)
	if basalt.LOGGER._enabled then
		local args = {...}
		local info = debug.getinfo(2, "Sl")
		local line = info and info.currentline or "?"
		local src = info and info.short_src or "?"
		local prepend = "["..src..":"..line.."] "

		if #args == 0 then
			basalt.LOGGER.warn(prepend.."")
			return
		end
		for i, obj in ipairs(args) do
			local thing = inspect.inspect(obj)
			_log(Log.LEVEL.WARN, prepend, thing)
			-- basalt.LOGGER.warn(prepend .. thing)
		end
	end
end
local basaltError = basalt.LOGGER.error
local basaltDebug = basalt.LOGGER.debug
print = function(...)
	DEFAULT_PRINT(...)
	log(...)
end


local function logTable(t, options)
	local defaultOptions = {
		depth = 2,
		newline = "\n",
		indent = "  ",
		process = nil
	}
	local _options = {}
	if options == nil then
		options = {}
	end
	for k, v in pairs(options) do
		if defaultOptions[k] == nil then
			error("Invalid option: " .. k)
		end
		defaultOptions[k] = v
	end
	options = defaultOptions
	local output = inspect.inspect(t, options)

	local info = debug.getinfo(2, "Sl")
	local line = info and info.currentline or "?"
	local src = info and info.short_src or "?"
	local prepend = "["..src..":"..line.."] "

	_log(Log.LEVEL.INFO, prepend, output)
	return output
end
local function printTable(t, options)
	if t == nil then
		print("Table is nil")
		return
	end
	if type(t) ~= "table" then
		print("Not a table: " .. tostring(t))
		return
	end
	local output = logTable(t, options)
	DEFAULT_PRINT(output)
	return output
end



-- capacityRoot = fs.getCapacity("/")
-- freeSpaceRoot = fs.getFreeSpace("/")
-- print("Root has capacity (bytes): " .. tostring(capacityRoot) .. " - free space (bytes): " .. tostring(freeSpaceRoot))


Enum = {
	Mouse = {
		LEFT = 1,
		RIGHT = 2,
		MIDDLE = 3
	}
}

local thisUserSocket = nil

local main = basalt.getMainFrame()

---@type table<number, boolean>
---@description A table to keep track of keys pressed down, mapping KeyCode to pressed-down state.
local keysPressedDown = {}
---@type table<string, boolean>
---@description A table to keep track of meta-keys pressed down, distinct from regular map.
local metaKeysPressedDown = {
	SHIFT = false,
	CTRL = false,
	ALT = false
}

-- main:onChar(function(self, char)
-- 	-- logTable(self, {depth=1})
-- 	log("Char pressed: " .. tostring(char))
	
-- 	return
-- end)

local function processMetaKeysStates(keyCode, isDown)
	local keyName = keys.getName(keyCode)
	if keyName == "leftShift" or keyName == "rightShift" then
		metaKeysPressedDown.SHIFT = isDown
		-- log("Shift key " .. (isDown and "pressed down" or "released"))
	elseif keyName == "leftCtrl" or keyName == "rightCtrl" then
		metaKeysPressedDown.CTRL = isDown
		-- log("Ctrl key " .. (isDown and "pressed down" or "released"))
	elseif keyName == "leftAlt" or keyName == "rightAlt" then
		metaKeysPressedDown.ALT = isDown
		-- log("Alt key " .. (isDown and "pressed down" or "released"))
	elseif keyName == "leftCommand" or keyName == "rightCommand" then
		-- Command key is often used for special actions, but not always tracked in metaKeysPressedDown.
		-- log("Command key " .. (isDown and "pressed down" or "released"))
		metaKeysPressedDown.CTRL = isDown
	else
		
		-- Not a meta key, do nothing.
		return
	end
end

main:onKey(function(self, keyCode)
	local keyIsDown = (keysPressedDown[keyCode] ~= nil) and (keysPressedDown[keyCode] == true)
	if not keyIsDown then
		-- From currently Up, to now Down.
		keysPressedDown[keyCode] = true
	end
	processMetaKeysStates(keyCode, true)
end)
main:onKeyUp(function(self, keyCode)
	local keyIsDown = (keysPressedDown[keyCode] ~= nil) and (keysPressedDown[keyCode] == true)
	if keyIsDown then
		-- From currently down, to now Up.
		keysPressedDown[keyCode] = false
	end
	processMetaKeysStates(keyCode, false)
end)




local scope = {
	["colors.gray"] = colors.gray,
	
}
local xmlFile, err = fs.open("/Docs/ui/pocket.xml", "r")
if not xmlFile then
	print("Error opening XML file: " .. tostring(err))
	return
end
-- print(xmlFile)
-- print(err)
main:loadXML(xmlFile.readAll(), scope)
xmlFile.close()

local mainWidth = main.width
local mainHeight = main.height
log("Main frame size: " .. mainWidth .. "x" .. mainHeight)
log("Main frame position: " .. main.x .. "," .. main.y)

local pocketWindow = main:getChild("pocket_window")

local frame_main = pocketWindow:getChild("frame_main")
assert(frame_main, "Frame 'frame_main' not found in pocket window.")

local frame_request = pocketWindow:getChild("frame_request")
assert(frame_request, "Frame 'frame_request' not found in pocket window.")

--- @type table<string, table<string, table>>
--- @description A table to hold event listeners for elements. Mapped with element-id against map of event-types mapped to list of callback functions.
local MAP_PER_ELEMENT_EVENT_LISTENERS = {}

--- @type table<string, table<string, function>>
--- @description A table to hold the "master event listeners" for elements, these will convey a given event to all listeners registered for that event on that element.
local SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS = {}

---@param eventName ("Click" | "ClickUp"|"Drag"|"Scroll"|"Enter"|"Leave"|"Focus"|"Blur"|"Key"|"KeyUp"|"Char")
local function registerEventListenerOnElement(eventName, element, callbackFunction)
	assert(eventName, "Event name is nil")
	assert(element, "Element is nil")


	-- This section: registering one-time overall 'master listener' if it doesn't exist yet.
	-- This will ensure that the event is conveyed to all listeners registered for that event on that element.
	if not SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS[element.id] then
		SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS[element.id] = {}
	end
	if not SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS[element.id][eventName] then
		SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS[element.id][eventName] = function(self, ...)
			local listeners = MAP_PER_ELEMENT_EVENT_LISTENERS[element.id][eventName]
			if listeners then
				for _, listener in ipairs(listeners) do
					listener(self, ...)
				end
			end
		end
		-- binding the master-event-listener to the element on this event name.
		element["on" .. eventName]( element, SET_PER_ELEMENT_OVERALL_EVENT_LISTENERS[element.id][eventName] )
		log("Registered overall event listener for event '" .. eventName .. "' on element '" .. element.name .. "' (" .. element.id .. ")")
	end


	-- This section: registering potentially multiple callbacks on the same event-types for an element.
	if not MAP_PER_ELEMENT_EVENT_LISTENERS[element.id] then
		MAP_PER_ELEMENT_EVENT_LISTENERS[element.id] = {}
	end
	if not MAP_PER_ELEMENT_EVENT_LISTENERS[element.id][eventName] then
		MAP_PER_ELEMENT_EVENT_LISTENERS[element.id][eventName] = {}
	end
	table.insert(MAP_PER_ELEMENT_EVENT_LISTENERS[element.id][eventName], callbackFunction)
	log("Registered event listener for event '" .. eventName .. "' on element '" .. element.name .. "' (" .. element.id .. ")")


	return
end




local SET_ELEMENTS_WITH_OVERFLOWING_TEXT = {}
local function apply_overflowScrollingEffectOnElement(textualElement)
	-- This will apply a scrolling effect to the element if the text overflows its bounds.
	-- Scrolling goes horizontal, and the text will scroll left and right, forever.
	-- This function is applied part-by-part, called via a coroutine (basalt.schedule).
	local todo = "todo something"
	return
end
local function apply_rightClickToClearTextOnInput(inputElement)
	assert(inputElement, "Input element is nil")
	registerEventListenerOnElement("Click", inputElement, function(self, button, x, y)
		if button == Enum.Mouse.RIGHT then
			self:setText("")
		end
	end)
	return
end
local function apply_wordLevelBackspaceOnInput(inputElement)
	-- Ctrl+Backspace removes entire words.
	-- That is, blocks of text separated by spaces.
	-- TODO: Stop deletion before comma or underscore, if present.
	registerEventListenerOnElement("Key", inputElement, function(self, keyCode)
		if keyCode == keys.backspace and metaKeysPressedDown.CTRL then
			local text = self:getText()
			local cursorPos = self.cursorPos or 1
			local beforeCursor = text:sub(1, cursorPos - 1)
			local afterCursor = text:sub(cursorPos)
			-- Find the last space before the cursor position
			local lastSpacePos = beforeCursor:match(".*() ")
			if lastSpacePos then
				-- Remove the word before the last space
				beforeCursor = beforeCursor:sub(1, lastSpacePos - 1)
			else
				-- No space found, remove everything before the cursor
				beforeCursor = ""
			end
			-- Set the new text and cursor position
			self:setText(beforeCursor .. afterCursor)
			self:setCursor(#beforeCursor + 1, 1, true, colors.white)
			self.cursorPos = #beforeCursor + 1
		end
	end)
	return
end
local function apply_homeAndEndKeysOnInput(inputElement)
	registerEventListenerOnElement("KeyUp", inputElement, function(self, keyCode)
		-- local keyName = keys.getName(keyCode)
		-- log("Input amount box: Key up: " .. tostring(keyName))
		if keyCode == keys.home then
			-- log("Input amount box: Home key pressed")
			self:setCursor(1,1, true, colors.white)
			self.cursorPos = 1
		elseif keyCode == keys["end"] then
			-- log("Input amount box: End key pressed")
			local indexOfEndOfString = self:getText():len() + 1
			self:setCursor(indexOfEndOfString, 1, true, colors.white)
			self.cursorPos = indexOfEndOfString
		end
	end)
	return
end
local function apply_deleteKeyOnInput(inputElement)
	-- The Delete key removes the character in front of the cursor.
	registerEventListenerOnElement("Key", inputElement, function(self, keyCode)
		if keyCode == keys.delete then
			local text = self:getText()
			local cursorPos = self.cursorPos or 1

			-- If Ctrl key is down, then remove entire words at-and-in front of cursor.
			local ctrlIsDown = metaKeysPressedDown.CTRL
			if ctrlIsDown then
				-- Find the next space after the cursor position
				local nextSpacePos = text:sub(cursorPos):find(" ")
				if nextSpacePos then
					-- Remove the word from the cursor position to the next space
					local beforeCursor = text:sub(1, cursorPos - 1)
					local afterCursor = text:sub(cursorPos + nextSpacePos)
					self:setText(beforeCursor .. afterCursor)
					-- Move the cursor to the same position
					self:setCursor(cursorPos, 1, true, colors.white)
					self.cursorPos = cursorPos
				else
					-- No space found, remove everything from the cursor position to the end of the string
					self:setText(text:sub(1, cursorPos - 1))
					self:setCursor(cursorPos, 1, true, colors.white)
					self.cursorPos = cursorPos
				end
				-- log("Delete key pressed with Ctrl, word removed at position: " .. tostring(cursorPos))
				return
			end

			-- If not Ctrl, then just remove the character in front of the cursor.
			-- Check if the cursor position is valid
			if cursorPos < 1 or cursorPos > #text then
				-- log("Delete key pressed, but cursor position is invalid: " .. tostring(cursorPos))
				return
			end
			if cursorPos <= #text then
				-- Remove the character at the cursor position
				local beforeCursor = text:sub(1, cursorPos - 1)
				local afterCursor = text:sub(cursorPos + 1)
				self:setText(beforeCursor .. afterCursor)
				-- Move the cursor to the same position
				self:setCursor(cursorPos, 1, true, colors.white)
				self.cursorPos = cursorPos
			end
			-- log("Delete key pressed, character removed at position: " .. tostring(cursorPos))
		end
	end)
	return
end
local function apply_ctrlWordSkipping(inputElement)
	-- Holding Ctrl and pressing arrow keys left or right will skip entire words separated by spaces.
	registerEventListenerOnElement("Key", inputElement, function(self, keyCode)
		if keyCode == keys.left and metaKeysPressedDown.CTRL then
			local text = self:getText()
			local cursorPos = self.cursorPos or 1
			-- Find the last space before the cursor position
			local lastSpacePos = text:sub(1, cursorPos - 1):match(".*() ")
			if lastSpacePos then
				-- Move the cursor to the last space position
				self:setCursor(lastSpacePos, 1, true, colors.white)
				self.cursorPos = lastSpacePos
			else
				-- No space found, move to the start of the text
				self:setCursor(1, 1, true, colors.white)
				self.cursorPos = 1
			end
		elseif keyCode == keys.right and metaKeysPressedDown.CTRL then
			local text = self:getText()
			local cursorPos = self.cursorPos or 1
			-- Find the next space after the cursor position
			local nextSpacePos = text:sub(cursorPos):find(" ")
			if nextSpacePos then
				-- Move the cursor to the next space position
				self:setCursor(cursorPos + nextSpacePos - 1, 1, true, colors.white)
				self.cursorPos = cursorPos + nextSpacePos - 1
			else
				-- No space found, move to the end of the text
				self:setCursor(#text + 1, 1, true, colors.white)
				self.cursorPos = #text + 1
			end
		end
		return
	end)
	return
end

local textInput_itemSearch = frame_main:getChild("input")
assert(textInput_itemSearch, "Text input box 'input' not found in frame_main.")

local function searchInput_whenKeyUp(self, key)
	if key == keys.enter then
		log("Search input box: Enter key pressed")
	elseif key == keys.backspace then
		log("Search input box: Backspace key pressed")
	end
	return
end


do
	apply_wordLevelBackspaceOnInput(textInput_itemSearch)
	apply_homeAndEndKeysOnInput(textInput_itemSearch)
	apply_deleteKeyOnInput(textInput_itemSearch)
	apply_rightClickToClearTextOnInput(textInput_itemSearch)
	apply_ctrlWordSkipping(textInput_itemSearch)

	registerEventListenerOnElement("KeyUp", textInput_itemSearch, searchInput_whenKeyUp)

	textInput_itemSearch:setForeground(colors.white)
end


local list = frame_main:getChild("list")
assert(list, "List 'list' not found in frame_main.")
local itemToMake = ""

local function searchList_whenItemSelect(self, index, item)
	-- logTable(self, {depth=1})
	-- log(index)
	-- log(item)

	local isShiftDown = metaKeysPressedDown.SHIFT
	local itemIsSelected = (not not item.selected)
	-- logTable(self.items)
	-- log("Shift is down: " .. tostring(isShiftDown))
	if isShiftDown and not itemIsSelected then
		-- This means they selected it, and it deselected - but we want to selected again!
		log("Shift is down, and item is not selected, selecting it again.")
		item.selected = true
		-- self:updateRender()
		log(item)
	end

	local thing = self:getSelectedItem()
	logTable(thing, {depth=2})

	itemToMake = thing["text"]
	log("Selected item: " .. tostring(itemToMake))

	return
end
do
	list:addItem({
		text = "Nothing here yet...",
		selected = true,
		itemName = "minecraft:air",
		doNotSelectThis = true
	})

	list:setMultiSelection(false)
	list:setSelectedBackground(colors.cyan)
	list:onSelect(searchList_whenItemSelect)
end


local section_amount = frame_request:getChild("section_amount")
assert(section_amount, "Section 'section_amount' not found in frame_request.")
local section_confirm = frame_request:getChild("section_confirm")
assert(section_confirm, "Section 'section_confirm' not found in frame_request.")


local btnRequest = frame_main:getChild("btn-request")
assert(btnRequest, "Button 'btn-request' not found in frame.")


local btnCancel = section_amount:getChild("btn-cancel")
assert(btnCancel, "Button 'btn-cancel' not found in frame_request.")
btnCancel:onClick(function(self, button, x, y)
	frame_request:setVisible(false)
	frame_main:setVisible(true)
end)

local btnNext = section_amount:getChild("btn-next")
assert(btnNext, "Button 'btn-confirm' not found in frame_request.")

local label_itemName = frame_request:getChild("div_display"):getChild("label_item")
assert(label_itemName, "Label 'label_item' not found in frame_request.")
label_itemName:setText("Item Name: Example Itemabcd")

local div_amount = section_amount:getChild("div_amount"); assert(div_amount, "Div 'div_amount' not found in frame_request.")
local div_picker_positives = div_amount:getChild("div_picker_positives"); assert(div_picker_positives, "Div 'div_picker_positives' not found in frame_request.")
local div_picker_negatives = div_amount:getChild("div_picker_negatives"); assert(div_picker_negatives, "Div 'div_picker_negatives' not found in frame_request.")
do
	local output_label_names_pos = {}
	local output_label_names_neg = {}
	local label_names_prepend_pos = "label_positive_"
	local label_names_prepend_neg = "label_negative_"

	for i=0,3 do
		table.insert(output_label_names_pos, label_names_prepend_pos .. tostring(10^(i)))
		table.insert(output_label_names_neg, label_names_prepend_neg .. tostring(10^(i)))
	end

	-- log("Positive label names: " .. table.concat(output_label_names, ", "))
	for i, labelName in ipairs(output_label_names_pos) do
		local button = div_picker_positives:getChild(labelName)
		assert(button, "Button '" .. labelName .. "' not found in div_picker_positives.")
		button:setText("+" .. tostring(10^(i-1)))
	end
	for i, labelName in ipairs(output_label_names_neg) do
		local button = div_picker_negatives:getChild(labelName)
		assert(button, "Button '" .. labelName .. "' not found in div_picker_negatives.")
		button:setText("-" .. tostring(10^(i-1)))
	end
end

local input_amount = div_amount:getChild("input_amount"); assert(input_amount, "Input 'input_amount' not found in frame_request.")
local label_status = section_amount:getChild("label_status"); assert(label_status, "Label 'label_status' not found in frame_request.")
local itemAmountIsValid = false
local amountToMake = 0
local function whenNextButtonClicked(self, button, x, y)
	if itemAmountIsValid then
		section_amount:setVisible(false)
		section_confirm:setVisible(true)

		if not thisUserSocket then
			error("No user socket found, cannot proceed to confirmation.")
			return
		end

		log("Item to make: " .. itemToMake)
		log("Amount to make: " .. tostring(amountToMake))

		cryptoNet.send(thisUserSocket, {
			tag = "materials_bill",
			itemName = itemToMake,
			amount = amountToMake
		})
	else
		label_status:setVisible(true)
		label_status:setText("Must be a number > 0.")
		log("Invalid item count, cannot proceed to confirmation.")
	end
	return
end
local function whenConfirmButtonClicked(self, button, x, y)
	if itemAmountIsValid then
		-- do things here
		log("valid item count, do things here.")
		log("User wants to make ".. itemToMake .. " x".. tostring(amountToMake) .. " ...")
	else
		log("Do nothing, because invalid item count.")
	end
	return
end
local function whenBackButtonClicked(self, button, x, y)
	section_confirm:setVisible(false)
	section_amount:setVisible(true)
	return
end
do
	local form = div_amount
	main:initializeState("amount_string", "", false)
	-- logTable(main._values.states, {depth=2})

	local function setStatusText(text)
		label_status:setVisible(true)
		label_status:setText(text)
	end

	form:computed("isValid", function(self)
		local amountString = self:getState("amount_string")
		amountString = string.gsub(amountString, "%s+", "")
		if amountString == nil or amountString == "" then
			itemAmountIsValid = false
			return false
		end

		-- Ensure only digits, but
		-- allow single "e" character for scientific notation
		-- allow single decimal point for floating point numbers
		-- allow commas and underscores for readability
		local validChars = "0123456789.e,_"
		for i = 1, #amountString do
			local char = amountString:sub(i, i)
			if not validChars:find(char, 1, true) then
				itemAmountIsValid = false
				return false
			end
		end

		-- Ensure only 1 decimal point is present
		local decimalCount = 0
		for i = 1, #amountString do
			local char = amountString:sub(i, i)
			if char == "." then
				decimalCount = decimalCount + 1
			end
			if decimalCount >= 2 then break end
		end
		if decimalCount >= 2 then
			itemAmountIsValid = false
			return false
		end

		-- Ensure only 1 "e" character is present
		local eCount = 0
		for i = 1, #amountString do
			local char = amountString:sub(i, i)
			if char == "e" then
				eCount = eCount + 1
			end
			if eCount >= 2 then break end
		end
		if eCount >= 2 then
			itemAmountIsValid = false
			return false
		end

		-- Ensure that an integer or decimal number comes before the single "e" character
		local eIndex = amountString:find("e")
		if eIndex then
			-- Check if there is a digit before "e"
			local hasDigitBeforeE = false
			for i = 1, eIndex - 1 do
				if amountString:sub(i, i):find("%d") then
					hasDigitBeforeE = true
					break
				end
			end
			if not hasDigitBeforeE then
				itemAmountIsValid = false
				return false
			end

			-- Check if there is a digit after "e"
			local hasDigitAfterE = false
			for i = eIndex + 1, #amountString do
				if amountString:sub(i, i):find("%d") then
					hasDigitAfterE = true
					break
				end
			end
			if not hasDigitAfterE then
				itemAmountIsValid = false
				return false
			end
		end


		-- Commas may not proceed another comma
		-- Underscores may not proceed another underscore
		-- Commas may not proceed an underscore
		-- Underscores may not proceed a comma
		-- Commas and underscores may not be at the start or end of the string
		if amountString:sub(1, 1) == "," or amountString:sub(1, 1) == "_" or
		   amountString:sub(-1) == "," or amountString:sub(-1) == "_" then
			itemAmountIsValid = false
			return false
		end
		for i = 1, #amountString - 1 do
			local char1 = amountString:sub(i, i)
			local char2 = amountString:sub(i + 1, i + 1)
			if (char1 == "," and char2 == ",") or (char1 == "_" and char2 == "_") or
			   (char1 == "," and char2 == "_") or (char1 == "_" and char2 == ",") then
				itemAmountIsValid = false
				return false
			end
		end




		-- If we reach here, the amount string is valid.
		-- Time to convert to a number.

		-- Remove underscores and commas for conversion
		local sanitizedAmountString = amountString:gsub("[_,]", "")
		local amountNumber = tonumber(sanitizedAmountString)
		if amountNumber == nil then
			itemAmountIsValid = false
			return false
		end
		if amountNumber <= 0 then
			-- setStatusText("Must be greater than 0.")
			itemAmountIsValid = false
			return false
		end

		-- Ensure number is an integer once coerced.
		if amountNumber % 1 ~= 0 then
			-- setStatusText("Must be an integer.")
			itemAmountIsValid = false
			return false
		end


		-- If we reach here, the amount string is valid and a number.
		itemAmountIsValid = true
		amountToMake = amountNumber

		-- temporary
		return true
	end)

	input_amount:bind("text", "amount_string")

	form:onStateChange("isValid", function(self, isValid)
		if isValid then
			label_status:setVisible(false)
			btnNext:setBackground(colors.green)
			btnNext:setForeground(colors.white)
		else
			setStatusText("Must be whole number > 0")
			btnNext:setBackground(colors.lightGray)
			btnNext:setForeground(colors.gray)
		end
	end)
	btnNext:onClick(whenNextButtonClicked)
	btnNext:setText(" Next > ")

	input_amount:setText("1")
	-- log("Set text to 0.")

	-- input_amount:onKey(function(self, keyCode)
	-- 	local keyName = keys.getName(keyCode)
	-- 	log("Input amount box: Key pressed: " .. tostring(keyName))
	-- end)

	apply_rightClickToClearTextOnInput(input_amount)
	apply_wordLevelBackspaceOnInput(input_amount)
	apply_homeAndEndKeysOnInput(input_amount)
	apply_deleteKeyOnInput(input_amount)
	apply_ctrlWordSkipping(input_amount)
end



local btnConfirm = section_confirm:getChild("btn-confirm"); assert(btnConfirm, "Button 'btn-confirm' not found in frame_request.")
local btnBack = section_confirm:getChild("btn-back"); assert(btnBack, "Button 'btn-back' not found in frame_request.")
btnBack:onClick(whenBackButtonClicked)
btnConfirm:onClick(whenConfirmButtonClicked)
do
	btnBack:setText(" < Back ")
end

btnRequest:onClick(function(self, button, x, y)
	frame_main:setVisible(false)
	frame_request:setVisible(true)
	input_amount:setText("1")
end)


-- capacityRoot = fs.getCapacity("/")
-- freeSpaceRoot = fs.getFreeSpace("/")
-- print("Root has capacity (bytes): " .. tostring(capacityRoot) .. " - free space (bytes): " .. tostring(freeSpaceRoot))




local function onStart()
	basalt.run()
	local socket = cryptoNet.connect("Cinnamon-AE2-ME-Requester")
	if not socket then
		print("Failed to connect to server.")
		return
	end

	print("Username: ")
	local username = read()
	print("Password: ")
	local password = read("*")

	cryptoNet.login(socket, username, password)

	thisUserSocket = socket
	return
end
local function onEvent(event)

	if event[1] == "login" then
		-- Successful login event.
		local username = event[2]
		local socket = event[3]
		log("Logged in as: " .. username)
		cryptoNet.send(socket, "Hello server! I am " .. username .. ".")

		cryptoNet.send(socket, {
			tag = "all_craftable_items"
		})

		-- basalt.run()
	elseif event[1] == "login_failed" then
		-- Failed login event.
		local reason = event[2]
		log("Login failed: " .. reason)
		print("Login failed: " .. reason)

		cryptoNet.closeAll()
		return
	elseif event[1] == "connection_closed" then
		-- Connection closed event.
		cryptoNet.closeAll()
		log("Connection closed.")
		print("Connection closed.")
		basalt.stop()
		print("Hold Ctrl+T to terminate the program.")
		return
	elseif event[1] == "encrypted_message" then
		local message = event[2]
		local socket = event[3]
		local server = event[4]
		
		if message.tag == "all_craftable_items:response" then
			log("Received all craftable items response from server.")
			
			local craftableItems = message["craftableItems"]
			logTable(craftableItems, {depth=2})

			-- Clear the list and add the items.
			list:clearItems()
			for _, item in ipairs(craftableItems) do
				list:addItem({
					text = item.displayName,
					itemName = item.name,
					selected = false
				})
			end
			list:updateRender()
			log("Added " .. tostring(#craftableItems) .. " items to the list.")
		end

	end

	return
end
cryptoNet.startEventLoop(onStart, onEvent)








print("[Program Executed Successfully]")
-- basalt.run()
print("[End of Program]")
-- End of File