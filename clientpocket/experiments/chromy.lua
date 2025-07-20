--[[
    Chromy | A small Bimg API | v.1.6
    =================================
    Available under the MIT Licence
    Copyright (c) 2022 Sammy L. Koch 
    ---------------------------------
    Load images or animations in the
    unofficial official bimg (blit -
    image) format!
    
]]


local chromy = {}
--[[ Get methods ]]
function chromy.getVersion(tBimg) return tBimg.version or "nil" end

function chromy.getTitle(tBimg) return tBimg.title or "nil" end

function chromy.getDescription(tBimg) return tBimg.description or "nil" end

function chromy.getAuthor(tBimg) return tBimg.author or "nil" end

function chromy.getCreator(tBimg) return tBimg.creator or "nil" end

function chromy.getDate(tBimg) return tBimg.date or"2001-01-01T01:01:01+0000" end

function chromy.isAnimation(tBimg) return tBimg.animation or false end

function chromy.getRootSPF(tBimg) return tBimg.secondsPerFrame or 0.0 end

function chromy.getFrameSPF(tBimg, nFrame) return tBimg[nFrame or 1].secondsPerFrame or tBimg.secondsPerFrame or 0.0 end


---Returns the current color palette of the used term.
---@return table palette
function chromy.getCurrPalette()
    local palette = {}

    for pos,name in pairs(
        {
        "white","orange","magenta","lightBlue","yellow","green","pink","gray","lightGray","cyan","purple","blue","brown","green","red","black"}) do
        palette[pos-1] = {term.getPaletteColor(colors[name])}
    end

    return palette
end

---Swaps the given color palette with the one by the current term.
---@param tPalette table E.g. tBimg.palette for root palette or tBimg[2].palette for palette of second frame
---@return boolean result Did work or not.
function chromy.setPalette(tPalette)
    local tmp = {}
    if type(tPalette) ~= "table" then return false end

    for color, tbl in pairs(tPalette) do
        term.setPaletteColor(2^color, table.unpack(tbl))
    end

    return true
end

---Renders a given bimg (from the given frame).
---@param tBimg table
---@param nFrame? number
---@return boolean result Did work or not.
function chromy.render(tBimg, nFrame)
    local nX,nY = term.getCursorPos()
    local frame = tBimg[nFrame or 1]

    if type(frame) ~= "table" then return false end

    if term.getLine then
        -- WITH transparency
        for _,line in pairs(frame) do
            term.setCursorPos(nX,nY)
            if line[2]:find(' ') or line[3]:find(' ') then
                local _,fg,bg = term.getLine(nY)
                line[2] = line[2]:gsub("() ",function(...)
                    return fg:sub(..., ...)
                end)
                line[3] = line[3]:gsub("() ",function(...)
                    return bg:sub(..., ...)
                end)
            end

            term.blit(line[1],line[2],line[3])
            nY = nY+1
        end
    else
        -- WITHOUT transparency
        for i=1,#frame do
            term.setCursorPos(nX,nY)
            term.blit(frame[i][1],frame[i][2],frame[i][3])
            nY = nY+1
        end
    end

    return true
end

---Loads bimg string.
---@param str string Content of bimg file as string.
---@return table bimg Str converted to a table.
---@return boolean result Did work or not.
function chromy.loadBimgStr(str)
    local col = {white=0x1,orange=0x2,magenta=0x4,lightBlue=0x8,yellow=0x10,lime=0x20,pink=0x40,grey=0x80,lightGrey=0x100,cyan=0x200,purple=0x400,blue=0x800,brown=0x1000,green=0x2000,red=0x4000,black=0x8000}
    local inferiorcol=col; inferiorcol.gray=col.grey; inferiorcol.lightGray=col.lightGrey
    local b,tBimg = pcall( load("return "..str,"bimg","t",{colours=col,colors=inferiorcol}) )
    return tBimg, type(tBimg) == "table"
end

---Loads a bimg file
---@param sPath string Path to bimg file.
---@return table bimg converted to a table.
---@return boolean result Did work or not.
function chromy.loadBimgFile(sPath)
    if sPath and fs.exists(sPath) then
        local file = fs.open(sPath, 'rb')
        local tBimg,bResult = chromy.loadBimgStr(file.readAll())
        file.close()
        
        return tBimg, bResult
    end
    return {}, false
end


return chromy
--[[Example:
--local chromy = require("chromy")
local image = chromy.loadBimgFile("animation.bimg") -- https://github.com/SkyTheCodeMaster/bimg/blob/master/examples/animation.bimg
local rootPalette = chromy.getCurrPalette()

-- For image
chromy.setPalette(image.palette)
term.setCursorPos(1,1)
term.clear()
chromy.render(image)
chromy.setPalette(rootPalette)

-- For animation 
for i=1,#image do
    chromy.setPalette(image[i].palette or image.palette)
    term.setCursorPos(1,1)
    term.clear()
    chromy.render(image,i)
    sleep(chromy.getFrameSPF(image,i))
end]]