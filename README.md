# AE2 Requester GUI


## What I've learnt
- Basalt2 adds methods such as "setText", "setPosition", "setSize", etc. to element classes descending from `VisualElement` - even though you won't see these in the documentation reference, nor intellisense suggestions. You can ignore the yellow squiggly lines on them.
- The documentation guide, on the intro page, has code excerpts which demonstrate the above.
- Due to the reactive-plugin, if you destroy an element which uses dynamic-reactive positioning or sizing (the strings like "{parent.width/2 - 3}" then the program crashes).
  - It really doesn't like when you do that. Idk why.
  - Solution is to not use dynamic strings such as that, and just calculate it manually a la `local centerX = parent.width/2 - 3" then apply it to the element in question.
- Labels do not have a background colour, so you'll have to parent them under a Frame which can have a background colour. 
  - Also Labels by default have a white text colour, so you need to modify its foreground property to contrast against the Frame's background.
- If you want a quick'n'dirty way to bring an element to the front-Z, use `element.prioritize()`.
- Use `inspect.lua` (https://github.com/kikito/inspect.lua) via `inspect.inspect(...)` to get stringified tables - supports stringifying recursive tables!
- Chromy, sanjuuni.
  - Chromy is used for rending BIMG formatted images straight to terminal, and supposedly can be retrofitted to render to smaller space such as in Basalt2 Image elements, but in practice, doesn't work, as BIMG-text formatted files aren't parsed properly.
- My solution to loading BIMG-text files is using the Lua `load` global-function, like: 
  ```lua
  local success, img = pcall(load, "return " .. fileContentsStrippedMinimal, "bimg", "t", {colors=colors, colours=colors})
  ```
  - Wrapped in a protected-call `pcall` so if it errors it won't propagate out and cause the program to crash.
- Playing animations/video via the BIMG format requires the dev to manually cycle through individual image-frames.
  - Example Lua code:
  ```lua
  local frameCount = #img_data
  local currentFrame = 1
  -- print("Frame count: " .. frameCount)
  local frameDelay = img_data.secondsPerFrame or img_data[currentFrame].duration or 0.2

  basalt.schedule(function()
    while true do
      local success, thing = pcall(function()
        frameDelay = img_data.secondsPerFrame 
        if img_data[currentFrame].duration ~= nil then
          frameDelay = img_data[currentFrame].duration
        end
        if frameDelay == nil then
          frameDelay = 0.2
        end
        print("Frame delay set to " .. frameDelay)
      end)
      -- img:updateFrame(currentFrame, img_data[currentFrame])
      img:nextFrame()
      img:render()
      local isFrameDataNil = img_data[currentFrame] == nil
      print("Updated frame to " .. currentFrame .. " with data being nil: " .. tostring(isFrameDataNil))
      currentFrame = currentFrame + 1
      if currentFrame > frameCount then
        print("Wrap around to first frame")
        currentFrame = 1
      end
      print("  sleep")
      os.sleep(frameDelay)
    end
  end)
  ```
- Regular Computers and Advanced Computers have default screen resolution of 51x19.
- Regular Pocket-Computers and Advanced Pocket-Computers have default screen resolution of (?) 26x20. (27?x20?)
- When using either TextBox element or Input element and printing anything on keyup or other events, it won't instantly update the overall render so black lines appear. Usually the re-render would hide this instantly, but again, no re-render, so black lines.
  - Don't use default print function as it interferes with Basalt2's UI, so just use Basalt's input log-to-file functionality.
- Implemented Home, End, Delete, Ctrl+Backspace keyboard functionality.
  - Note, you cannot have multiple listeners for some given event. Eg, I tried to put 2 listeners for the "key" event on the "input_amount" element, it only registered the first callback function. Scratching my head for a lil while.
  - Solution to this, put callback for a single "key" event into a 'broadcast' structure, relay key event to other user-specified callbacks.







End of File