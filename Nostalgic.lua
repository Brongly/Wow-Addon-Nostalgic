local addonName, addonTable = ...

-- 1. Create the Main Window (Movable - Golden Build)
local frame = CreateFrame("Frame", "NostalgicFrame", UIParent, "BasicFrameTemplateWithInset")
-- Default base size (We will update this dynamically)
frame:SetSize(400, 300)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()

-- Register for Escape Key to Close
tinsert(UISpecialFrames, "NostalgicFrame")

-- SAVING POSITION LOGIC
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save the position when the user lets go
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    NostalgicPos = { point = point, rel = relativePoint, x = xOfs, y = yOfs }
end)

-- LOADING POSITION LOGIC
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        if NostalgicPos then
            frame:ClearAllPoints()
            frame:SetPoint(NostalgicPos.point, UIParent, NostalgicPos.rel, NostalgicPos.x, NostalgicPos.y)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
frame.title:SetText("Nostalgic")

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1) -- Width will be dynamic
scrollFrame:SetScrollChild(content)

-- 2. Logic to scan achievements
local function GetAchievementsForToday()
    local today = date("*t")
    local results = {}
    local categories = GetCategoryList()
    
    for _, catID in ipairs(categories) do
        local numAchievements = GetCategoryNumAchievements(catID)
        for i = 1, numAchievements do
            local id, name, _, completed, month, day, year = GetAchievementInfo(catID, i)
            if completed and month == today.month and day == today.day then
                local _, _, _, _, _, _, _, description = GetAchievementInfo(id)
                table.insert(results, {id = id, year = year + 2000, name = name, desc = description})
            end
        end
    end
    table.sort(results, function(a, b) return a.year < b.year end)
    return results
end

-- 3. Show the UI with SMART AUTOSIZING
local function ShowNostalgicUI()
    local achievements = GetAchievementsForToday()
    local yOffset = -5
    local children = {content:GetChildren()}
    for _, child in ipairs(children) do child:Hide() end

    if #achievements > 0 then
        -- NEW: Set an absolute MINIMUM width for the window (e.g., 280)
        local maxWidth = 280

        -- Create a temporary FontString using the same font to measure width
        local measurer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        measurer:Hide() -- Keep it hidden

        for _, ach in ipairs(achievements) do
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(350, 20) -- Width will update later
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
            local link = GetAchievementLink(ach.id)
            
            -- Prepare the full display string: "[YYYY] Achievement Name"
            local fullTextString = string.format("|cffffd100[%d]|r %s", ach.year, link or ach.name)
            
            -- Store the text data for the FontString (needed after width measurement)
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", btn, "LEFT", 0, 0)
            text:SetText(fullTextString)
            btn.text = text -- Store reference for dynamic resizing

            -- AUTOSIZING WIDTH CALCULATION
            -- Use the measurement FontString to find the pixel width of this specific achievement line
            measurer:SetText(fullTextString)
            local lineWidth = measurer:GetStringWidth()

            -- We need to add padding for:
            -- 1. Button inset: 5px left
            -- 2. The scrollbar gap: 30px right
            -- Total padding = ~35px. We'll add a little extra safety buffer.
            local totalLineNeeded = lineWidth + 50 

            -- If this line is the longest one so far, update maxWidth
            if totalLineNeeded > maxWidth then
                maxWidth = totalLineNeeded
            end
            
            -- Define Interactivity (Links & Tooltips)
            btn:SetScript("OnClick", function()
                if IsShiftKeyDown() then ChatEdit_InsertLink(link)
                else
                    if not AchievementFrame then AchievementFrame_LoadUI() end
                    ShowUIPanel(AchievementFrame)
                    AchievementFrame_SelectAchievement(ach.id)
                end
            end)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(ach.name, 1, 1, 1)
                GameTooltip:AddLine(ach.desc, 1, 0.82, 0, true)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            yOffset = yOffset - 22
        end

        -- FINALIZE AUTOSIZE WIDTH
        -- 1. Ensure a sane MAXIMUM width (e.g., 800) so it doesn't span across the screen.
        if maxWidth > 800 then maxWidth = 800 end

        -- 2. Now that we know the maxWidth for this entire day, apply it to the main frames
        frame:SetWidth(maxWidth)
        content:SetWidth(maxWidth - 20) -- Account for ScrollFrame margin

        -- 3. Also update the width of all the buttons we just made to match the window
        -- (Iterate through children and find the buttons)
        local finalWidthBuffer = maxWidth - 40 -- Account for scrollbar/padding
        for _, achFrame in ipairs({content:GetChildren()}) do
            if achFrame:GetObjectType() == "Button" then
                achFrame:SetWidth(finalWidthBuffer)
            end
        end

    else
        -- Default width if no achievements are found
        frame:SetWidth(400)
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
        text:SetText("No achievements found for today.")
    end
    
    content:SetHeight(math.abs(yOffset) + 20)
    frame:Show()
end

-- 4. TITAN PANEL / LDB INTEGRATION
local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
if LDB then
    LDB:NewDataObject("Nostalgic", {
        type = "launcher",
        text = "Nostalgic",
        icon = "Interface\\Icons\\INV_Misc_Statue_01",
        OnClick = function(self, button)
            if frame:IsShown() then frame:Hide() else ShowNostalgicUI() end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Nostalgic")
            tooltip:AddLine("|cffffffffClick to see today's history.|r")
        end,
    })
end

-- 5. SLASH COMMANDS
_G["SLASH_NOS1"] = "/nos"
_G["SLASH_NOS2"] = "/nostalgic"
SlashCmdList["NOS"] = function()
    if frame:IsShown() then frame:Hide() else ShowNostalgicUI() end
end

print("|cff00ff00Nostalgic v1.4.0 Loaded!|r Type /nos or check Titan Panel.")