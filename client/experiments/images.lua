
local function loadBimg(path)
	local file, err = fs.open(path, "r")
	local fileContents = file.readAll()
	file.close()

	-- print("[loadBimg] File contents: ")
	-- print(fileContents)
	local fileContentsStrippedMinimal = fileContents

-- 	-- Remove Lua comments, then whitespace like newlines or spaces which appear to be indentation
-- 	local fileContentsStrippedMinimal = fileContents:gsub("%-%-.-\n", "") -- remove comments
-- 	  -- Remove any group of exactly 4 whitespace characters
-- 	fileContentsStrippedMinimal = fileContentsStrippedMinimal:gsub("%s%s%s%s", "")
--   -- Remove any group of exactly 2 whitespace characters
-- 	fileContentsStrippedMinimal = fileContentsStrippedMinimal:gsub("%s%s", "")
-- 	-- Remove instances of "\n" newline
-- 	fileContentsStrippedMinimal = fileContentsStrippedMinimal:gsub("\n", "")

-- 	print("[loadBimg] Stripped file contents: ")
-- 	print(fileContentsStrippedMinimal)

	if file then
		-- local img = textutils.unserialize(fileContentsStrippedMinimal)
		local success, img = pcall(load, "return " .. fileContentsStrippedMinimal, "bimg", "t", {colors=colors, colours=colors})
		if success then
			img = img()
			if type(img) ~= "table" then
				error("Loaded image is not a table: " .. tostring(img))
			end
			-- Check if the image has the required fields
			if not img[1] or false then -- not img.version or not img.palette or not img.title or not (img.author and img.creator) or not img.date then
				error("Loaded image is missing required fields")
			end
			print("[loadBimg] Image loaded successfully from path: " .. path)
		else
			error("Failed to load image from path: " .. path .. " with error: " .. tostring(img))
		end
		return img
	end
	error("Failed to load image from path: " .. path)
end
assert(img, "Image not found in frame")
local img_data = loadBimg("/Docs/ui/images/felix.bimg")
-- local img_data = chromy.loadBimgFile("/Docs/ui/images/image2.bmg")
-- printTable(img_data)
assert(img_data, "Image data not loaded")



img:setBimg(img_data)

basalt.schedule(function()

	
	local monitor = peripheral.find("monitor")
	local mon_width, mon_height = monitor.getSize()
	
	if img_data.palette then
		for i=0, #img_data.palette do
			local col = img_data.palette[i]
			if col then
				term.setPaletteColor(2^i, table.unpack(col))
				monitor.setPaletteColor(2^i, table.unpack(col))
			end
		end
	end
	for i=1, #img_data do
		for y, r in ipairs(img_data[i]) do
			-- print(y)
			-- print(r)
			monitor.setCursorPos(1, y)
			monitor.blit(table.unpack(r))
		end
		
	end

	for i = 0, 15 do
		term.setPaletteColor(2^i, term.nativePaletteColor(2^i))
		monitor.setPaletteColor(2^i, term.nativePaletteColor(2^i))
	end

end)

-- local monitor = peripheral.find("monitor")
-- local mon_width, mon_height = monitor.getSize()
-- local monitorFrame = basalt.createFrame():setTerm(monitor):setSize(mon_width, mon_height)
-- local mon_img = monitorFrame:addImage():setSize(mon_width, mon_height)
-- if not mon_img then
-- 	print("Failed to add image to monitor frame")
-- 	return
-- else
-- 	print("Added image to monitor frame")
-- end

-- -- mon_img:setBimg(img_data)

-- if img_data.palette then
-- 	for i=0, #img_data.palette do
-- 		local col = img_data.palette[i]
-- 		if col then
-- 			term.setPaletteColor(2^i, table.unpack(col))
-- 			monitor.setPaletteColor(2^i, table.unpack(col))
-- 		end
-- 	end
-- end
-- for i=1, #img_data do
-- 	for y, r in ipairs(img_data[i]) do
-- 		-- print(y)
-- 		-- print(r)
-- 		monitor.setCursorPos(1, y)
-- 		monitor.blit(table.unpack(r))
-- 	end
	
-- end

-- for i = 0, 15 do
-- 	term.setPaletteColor(2^i, term.nativePaletteColor(2^i))
--     monitor.setPaletteColor(2^i, term.nativePaletteColor(2^i))
-- end


-- local frameCount = #img_data
-- local currentFrame = 1
-- -- print("Frame count: " .. frameCount)
-- local frameDelay = img_data.secondsPerFrame or img_data[currentFrame].duration or 0.2

-- basalt.schedule(function()
-- 	while true do
-- 		local success, thing = pcall(function()
-- 			frameDelay = img_data.secondsPerFrame 
-- 			if img_data[currentFrame].duration ~= nil then
-- 				frameDelay = img_data[currentFrame].duration
-- 			end
-- 			if frameDelay == nil then
-- 				frameDelay = 0.2
-- 			end
-- 			-- print("Frame delay set to " .. frameDelay)
-- 		end)
-- 		-- img:updateFrame(currentFrame, img_data[currentFrame])
-- 		img:nextFrame()
-- 		img:render()
-- 		local isFrameDataNil = img_data[currentFrame] == nil
-- 		-- print("Updated frame to " .. currentFrame .. " with data being nil: " .. tostring(isFrameDataNil))
-- 		currentFrame = currentFrame + 1
-- 		if currentFrame > frameCount then
-- 			-- print("Wrap around to first frame")
-- 			currentFrame = 1
-- 		end
-- 		-- print("  sleep")
-- 		os.sleep(frameDelay)
-- 	end
-- end)