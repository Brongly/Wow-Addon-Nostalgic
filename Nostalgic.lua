local addonName, addonTable = ...

-- 1. Persistent State
local viewTime = time() 
NostalgicCache = NostalgicCache or {}
local isScanning = false

-- 2. Create the Main Window
local frame = CreateFrame("Frame", "NostalgicFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 320)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetToplevel(true) -- Ensures window comes to front
frame:RegisterForDrag("LeftButton")
frame:Hide()

tinsert(UISpecialFrames, "NostalgicFrame")

-- Position Saving
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    NostalgicPos = { point = point, rel = relativePoint, x = xOfs, y = yOfs }
end)

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)

-- 3. Navigation Buttons
local buttonContainer = CreateFrame("Frame", nil, frame)
buttonContainer:SetSize(380, 24)
buttonContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 8)

local prevBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
prevBtn:SetSize(32, 22)
prevBtn:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
prevBtn:SetText("<")
prevBtn:SetScript("OnClick", function() viewTime = viewTime - 86400; ShowNostalgicUI() end)

local nextBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
nextBtn:SetSize(32, 22)
nextBtn:SetPoint("RIGHT", buttonContainer, "RIGHT", 0, 0)
nextBtn:SetText(">")
nextBtn:SetScript("OnClick", function() viewTime = viewTime + 86400; ShowNostalgicUI() end)

local todayBtn = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
todayBtn:SetSize(60, 22)
todayBtn:SetPoint("CENTER", buttonContainer, "CENTER", 0, 0)
todayBtn:SetText("Today")
todayBtn:SetScript("OnClick", function() viewTime = time(); ShowNostalgicUI() end)

-- Scroll Area
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30) 
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 35) 

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(300, 1) -- Width will be updated dynamically
scrollFrame:SetScrollChild(content)

-- 4. The Optimized Cache Engine
local function RunInitialCache()
    if next(NostalgicCache) or isScanning then return end
    isScanning = true
    
    local categories = GetCategoryList()
    for _, catID in ipairs(categories) do
        local num = GetCategoryNumAchievements(catID)
        for i = 1, num do
            local id, _, _, completed, month, day, year = GetAchievementInfo(catID, i)
            if completed and month and day then
                NostalgicCache[catID] = NostalgicCache[catID] or {}
                table.insert(NostalgicCache[catID], { id = id, m = month, d = day, y = year + 2000 })
            end
        end
    end
    isScanning = false
    print("|cff00ff00Nostalgic: History Indexed. Instant browsing enabled.|r")
end

-- 5. Search & Display (The "Blink" Speed)
local function GetAchievementsForTime(t)
    local results = {}
    local d = date("*t", t)
    for catID, achList in pairs(NostalgicCache) do
        for _, ach in ipairs(achList) do
            if ach.m == d.month and ach.d == d.day then
                -- Pull dynamic info for the UI
                local _, name, _, _, _, _, _, description = GetAchievementInfo(ach.id)
                table.insert(results, { id = ach.id, year = ach.y, name = name, desc = description })
            end
        end
    end
    table.sort(results, function(a, b) return a.year < b.year end)
    return results
end

function ShowNostalgicUI()
    frame.title:SetText("Nostalgic: " .. date("%B %d", viewTime))
    local achievements = GetAchievementsForTime(viewTime)
    
    -- Clear previous rows
    local children = {content:GetChildren()}
    for _, child in ipairs(children) do child:Hide(); child:SetParent(nil) end

    local yOffset = -5
    local maxWidth = 320

    if #achievements > 0 then
        local measurer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        measurer:Hide()

        for _, ach in ipairs(achievements) do
            -- Create row button
            local btn = CreateFrame("Button", nil, content)
            btn:SetHeight(20)
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
            btn:EnableMouse(true)
            btn:RegisterForClicks("LeftButtonUp")

            local link = GetAchievementLink(ach.id)
            local fullText = string.format("|cffffd100[%d]|r %s", ach.year, link or ach.name)
            
            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", btn, "LEFT", 0, 0)
            text:SetText(fullText)

            -- Measure for Autosizing
            measurer:SetText(fullText)
            local w = measurer:GetStringWidth() + 50
            if w > maxWidth then maxWidth = w end
            
            -- *** INTERACTIVITY RESTORED ***
            btn:SetScript("OnClick", function()
                if IsShiftKeyDown() then 
                    ChatEdit_InsertLink(link)
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

            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:SetWidth(maxWidth) -- Initial guess
            yOffset = yOffset - 22
        end

        -- Final Window Scaling
        frame:SetWidth(math.min(maxWidth, 800))
        content:SetWidth(frame:GetWidth() - 20) 
        buttonContainer:SetWidth(frame:GetWidth() - 20)
        
        -- Update all rows to full width
        local finalChildren = {content:GetChildren()}
        for _, child in ipairs(finalChildren) do
            if child:IsObjectType("Button") then
                child:SetWidth(frame:GetWidth() - 30)
            end
        end
    else
        frame:SetWidth(400)
        buttonContainer:SetWidth(380)
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
        text:SetText("No history found for " .. date("%B %d", viewTime))
        yOffset = yOffset - 22
    end

    content:SetHeight(math.abs(yOffset) + 20)
    frame:Show()
end

-- 6. Initialization
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if NostalgicPos then
            frame:ClearAllPoints()
            frame:SetPoint(NostalgicPos.point, UIParent, NostalgicPos.rel, NostalgicPos.x, NostalgicPos.y)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, RunInitialCache)
    end
end)

_G["SLASH_NOS1"] = "/nos"
SlashCmdList["NOS"] = function()
    if frame:IsShown() then frame:Hide() else 
        viewTime = time()
        ShowNostalgicUI() 
    end
end