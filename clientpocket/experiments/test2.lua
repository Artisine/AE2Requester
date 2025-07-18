local basalt = require("basalt")

local main = basalt.getMainFrame()
main:addButton("open")
	:setSize(10, 1)
    :setPosition("{parent.width-10}", 1)
    :setText("Show Popup")
    :onClick(function()
        local popup = main:addContainer("popup")
            :setSize(30, 17)
        popup:addLabel("msg")
            :setPosition(2, 2)
            :setText("Hello from Basalt2!")
        popup:addButton("close")
            :setPosition(popup.width - 1, 1)
			:setSize(1,1)
			:setBackground(colors.red)
            :setText("X")
            :onClick(function()
				popup:getChild("msg"):destroy()
				sleep(2)
                main:getChild(popup.name):destroy()
            end)
    end)

basalt.run()