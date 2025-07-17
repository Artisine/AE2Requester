
local scope = {
	["colors.gray"] = colors.gray,
	-- ["image_1"] = loadBimg("/Docs/ui/images/image.bimg"),
	whenPing = function(self)
		-- show a modal alert box like in javascript
		local debouncesForDestroy = {}
		local centerX = math.floor(main.width / 2)
		local centerY = math.floor(main.height / 2)
		local alertBox = main:addFrame()
			:setBackground(colors.black)
			:setForeground(colors.white)
			:setSize(20, 3)
			:setPosition(centerX, centerY)
		
		local alertText = alertBox:addLabel()
			:setText("Ping received!")
			:setBackground(colors.black)
			:setForeground(colors.white)
			:setZ(10)
		alertBox:prioritize()
		alertBox:onClick(function()
			if debouncesForDestroy[alertBox.id] ~= nil then
				print("Alert box already being destroyed, ignoring click.")
				return
			end
			debouncesForDestroy[alertBox.id] = true
			print("Alert box clicked, destroying it.")
			-- alertText:destroy()
			alertBox:destroy()
			print("woah")
		end)
		print("Hello!")
	end,
}
local xmlFile, err = fs.open("/Docs/ui/example.xml", "r")
if not xmlFile then
	print("Error opening XML file: " .. tostring(err))
	return
end
print(xmlFile)
print(err)
main:loadXML(xmlFile.readAll(), scope)
xmlFile.close()
