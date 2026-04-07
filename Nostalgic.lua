local addonName, addonTable = ...

-- 1. State
local viewTime = time()
NostalgicCache = {} 

-- 2. The Window
local frame = CreateFrame("Frame", "NostalgicFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 320)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetFrameStrata("MEDIUM")
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    NostalgicPos = { point = p, rel = rp, x = x, y = y }
end)
frame:Hide()
tinsert(UISpecialFrames, "NostalgicFrame")

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)

-- Mouse Wheel
frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel", function(self, delta)
    viewTime = viewTime + (delta > 0 and 86400 or -86400)
    ShowNostalgicUI()
end)

-- Scroll Area
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 45)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(300, 500)
scrollFrame:SetScrollChild(content)

-- 3. Navigation Buttons
local prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
prevBtn:SetSize(32, 22); prevBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 12); prevBtn:SetText("<")
prevBtn:SetScript("OnClick", function() viewTime = viewTime - 86400; ShowNostalgicUI() end)

local nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
nextBtn:SetSize(32, 22); nextBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 12); nextBtn:SetText(">")
nextBtn:SetScript("OnClick", function() viewTime = viewTime + 86400; ShowNostalgicUI() end)

local todayBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
todayBtn:SetSize(70, 22); todayBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12); todayBtn:SetText("Today")
todayBtn:SetScript("OnClick", function() viewTime = time(); ShowNostalgicUI() end)

-- 4. Search Logic
local function BuildCache()
    NostalgicCache = {}
    local cats = GetCategoryList()
    for _, cat in ipairs(cats) do
        local num = GetCategoryNumAchievements(cat)
        for i = 1, num do
            local id, name, _, completed, m, d, y = GetAchievementInfo(cat, i)
            if completed and m and d then
                table.insert(NostalgicCache, {id=id, m=m, d=d, y=y+2000, name=name})
            end
        end
    end
    print("|cff00ff00Nostalgic: Memories Loaded.|r")
end

-- 5. Show Function
function ShowNostalgicUI()
    frame.title:SetText("Nostalgic: " .. date("%B %d", viewTime))
    local targetDate = date("*t", viewTime)
    
    local children = {content:GetChildren()}
    for _, child in ipairs(children) do child:Hide(); child:SetParent(nil) end
    local regions = {content:GetRegions()}
    for _, region in ipairs(regions) do if region:IsObjectType("FontString") then region:SetText(""); region:Hide() end end
    
    local yOffset = -5
    local count = 0
    local maxWidth = 300
    local measurer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    measurer:Hide()

    for _, ach in ipairs(NostalgicCache) do
        if ach.m == targetDate.month and ach.d == targetDate.day then
            count = count + 1
            local btn = CreateFrame("Button", nil, content)
            btn:SetHeight(20)
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
            btn:SetPoint("RIGHT", content, "RIGHT", -5, 0)
            btn:EnableMouse(true)
            
            local link = GetAchievementLink(ach.id)
            local display = string.format("|cffffd100[%d]|r %s", ach.y, link or ach.name)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            txt:SetPoint("LEFT", btn, "LEFT", 0, 0)
            txt:SetText(display)

            measurer:SetText(display)
            local w = measurer:GetStringWidth() + 60
            if w > maxWidth then maxWidth = w end
            
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
                GameTooltip:SetHyperlink(link or GetAchievementLink(ach.id))
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            
            yOffset = yOffset - 22
        end
    end
    
    if count == 0 then
        frame:SetWidth(400)
        local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        empty:SetPoint("TOPLEFT", 10, -10); empty:SetText("No history found for this day.")
    else
        frame:SetWidth(math.min(maxWidth, 800))
    end
    
    content:SetHeight(math.abs(yOffset) + 50)
    frame:Show()
end

-- 6. Initialization
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function()
    if NostalgicPos then
        frame:ClearAllPoints()
        frame:SetPoint(NostalgicPos.point, UIParent, NostalgicPos.rel, NostalgicPos.x, NostalgicPos.y)
    end
    C_Timer.After(4, BuildCache)
end)

-- *** TITANPANEL / LDB REGISTRATION ***
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

-- Slash Commands
_G["SLASH_NOS1"] = "/nos"
_G["SLASH_NOS2"] = "/nostalgic"
SlashCmdList["NOS"] = function()
    if frame:IsShown() then frame:Hide() else ShowNostalgicUI() end
end