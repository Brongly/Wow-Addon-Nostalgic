--[[
    Nostalgic: A World of Warcraft Achievement History Addon
    Target Date: April 4th (Today)
    
    Current Issue: The 12.0.1 (Midnight) client has changed frame templates. 
    This build reverts to 'BasicFrameTemplateWithInset' for stability.
]]

local addonName, addonTable = ...

-- 1. THE MAIN UI WINDOW
local frame = CreateFrame("Frame", "NostalgicFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(450, 480)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:Hide()

-- Header Text
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Nostalgic: This Day in History")

-- Close Button
frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -1)

-- Scrollable Container
local scroll = CreateFrame("ScrollFrame", "NostalgicScrollFrame", frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -30)
scroll:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(380, 1)
scroll:SetScrollChild(content)
content.lines = {}

-- 2. DATA SCANNER (The "April 4th" Filter)
local function GetAchievementData()
    local today = date("*t") -- Get system date
    local list = {}
    
    local categories = GetCategoryList()
    for _, catID in ipairs(categories) do
        local num = GetCategoryNumAchievements(catID)
        for i = 1, num do
            -- NOTE: m (month) is often 0-indexed (0=Jan, 3=Apr) in older API versions
            local id, name, _, completed, m, d, y = GetAchievementInfo(catID, i)
            
            if completed then
                -- Check for April 4th (handles both 0 and 1 indexing for safety)
                local isApril = (m == 3 or m == 4)
                local isFourth = (d == 3 or d == 4)
                
                if isApril and isFourth then
                    local link = GetAchievementLink(id)
                    local displayYear = y or 0
                    if displayYear > 0 and displayYear < 100 then displayYear = displayYear + 2000 end
                    
                    local yearsAgo = today.year - displayYear
                    table.insert(list, {year = displayYear, ago = yearsAgo, link = link, id = id})
                end
            end
        end
    end
    
    table.sort(list, function(a, b) return a.year < b.year end)
    return list
end

-- 3. UI RENDERING
local function RefreshDisplay()
    -- Reset content rows
    for _, l in ipairs(content.lines) do l:Hide() end
    content.lines = {}
    
    local achievements = GetAchievementData()
    local yOffset = -10
    
    for _, data in ipairs(achievements) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetSize(380, 24)
        btn:SetPoint("TOPLEFT", 5, yOffset)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 5, 0)
        
        local agoText = data.ago > 0 and string.format("|cffaaaaaa(%d yrs ago)|r", data.ago) or "|cff00ff00(Today!)|r"
        text:SetText(string.format("|cffffd100[%d]|r %s %s", data.year, data.link, agoText))
        
        -- Click to view in Journal / Shift-click to Link
        btn:SetScript("OnClick", function()
            if IsShiftKeyDown() then
                ChatEdit_InsertLink(data.link)
            else
                if not AchievementFrame then AchievementFrame_LoadUI() end
                ShowUIPanel(AchievementFrame)
                AchievementFrame_SelectAchievement(data.id)
            end
        end)
        
        -- Tooltip support
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetAchievementByID(data.id)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", GameTooltip_Hide)

        btn:Show()
        table.insert(content.lines, btn)
        yOffset = yOffset - 26
    end
    
    if #achievements == 0 then
        print("|cff00ff00Nostalgic:|r No memories for today (4/4) found.")
    else
        content:SetHeight(math.abs(yOffset) + 20)
        frame:Show()
    end
end

-- 4. INTERFACE CONTROLS
_G["SLASH_NOSTALGIC1"] = "/nos"
SlashCmdList["NOSTALGIC"] = function()
    if frame:IsShown() then frame:Hide() else RefreshDisplay() end
end

print("|cff00ff00Nostalgic:|r v8.1 (Clean GitHub Export) Loaded. Type /nos")