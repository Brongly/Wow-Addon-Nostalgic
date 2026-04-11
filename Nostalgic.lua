local addonName = ...

-- ============================================================
-- 1. STATE & CACHE (Localized & Live-Updating)
-- ============================================================
local viewTime = time()
local seenAchievements = {}
local isLoaded = false
local frame

local MIN_FRAME_WIDTH = 280
local MAX_FRAME_WIDTH = 700
local MIN_FRAME_HEIGHT = 120
local MAX_FRAME_HEIGHT = 600

local FRAME_SIDE_PADDING = 60

local TOP_SECTION_HEIGHT = 42
local BOTTOM_SECTION_HEIGHT = 42
local EXTRA_CONTENT_PADDING = 12
local ROW_HEIGHT = 22

local function DedupeSavedCache()
    NostalgicCache = NostalgicCache or {}

    local cleaned = {}
    local seen = {}

    for _, ach in ipairs(NostalgicCache) do
        if ach and ach.id and not seen[ach.id] then
            cleaned[#cleaned + 1] = ach
            seen[ach.id] = true
        end
    end

    NostalgicCache = cleaned
end

local function PrimeSeenAchievements()
    wipe(seenAchievements)

    NostalgicCache = NostalgicCache or {}

    for _, ach in ipairs(NostalgicCache) do
        if ach and ach.id then
            seenAchievements[ach.id] = true
        end
    end
end

local function AddToCache(id)
    if not id or seenAchievements[id] then return end

    local name, _, _, completed, m, d, y = GetAchievementInfo(id)
    if completed and m and d and y then
        local y_final = (y < 100) and (y + 2000) or y

        NostalgicCache = NostalgicCache or {}
        table.insert(NostalgicCache, {
            id = id,
            m = m,
            d = d,
            y = y_final,
            name = name,
        })

        seenAchievements[id] = true
    end
end

local function BuildCache()
    PrimeSeenAchievements()

    local cats = GetCategoryList()
    if not cats then return end

    for _, cat in ipairs(cats) do
        local num = GetCategoryNumAchievements(cat)
        for i = 1, num do
            local id = GetAchievementInfo(cat, i)
            if id then
                AddToCache(id)
            end
        end
    end
end

local function ShiftViewDate(dayOffset)
    local t = date("*t", viewTime)
    t.hour = 12
    t.min = 0
    t.sec = 0
    t.day = t.day + dayOffset
    viewTime = time(t)
end

local function ShowNostalgicUI()
    frame.title:SetText("Nostalgic: " .. date("%B %d", viewTime))
    local targetDate = date("*t", viewTime)

    frame:ReleaseRows()

    local yOffset = -5
    local count = 0
    local filtered = {}
    local maxWidth = 0

    NostalgicCache = NostalgicCache or {}

    for _, ach in ipairs(NostalgicCache) do
        if ach.m == targetDate.month and ach.d == targetDate.day then
            table.insert(filtered, ach)
        end
    end

    table.sort(filtered, function(a, b)
        if a.y ~= b.y then
            return a.y < b.y
        end
        return a.id < b.id
    end)

    for _, ach in ipairs(filtered) do
        local link = GetAchievementLink(ach.id)
        local visibleText = string.format("|cffffd100[%d]|r %s", ach.y, link or ach.name or "")
        local w = frame:GetMeasuredWidth(visibleText)

        if w > maxWidth then
            maxWidth = w
        end
    end

    local desiredWidth
    if #filtered > 0 then
        desiredWidth = math.min(
            math.max(maxWidth + FRAME_SIDE_PADDING, MIN_FRAME_WIDTH),
            MAX_FRAME_WIDTH
        )
    else
        desiredWidth = MIN_FRAME_WIDTH
    end

    local contentHeight
    if #filtered > 0 then
        contentHeight = (#filtered * ROW_HEIGHT) + EXTRA_CONTENT_PADDING
    else
        contentHeight = 28
    end

    local desiredHeight = TOP_SECTION_HEIGHT + BOTTOM_SECTION_HEIGHT + contentHeight
    desiredHeight = math.min(math.max(desiredHeight, MIN_FRAME_HEIGHT), MAX_FRAME_HEIGHT)

    frame:SetSize(desiredWidth, desiredHeight)
    frame.content:SetWidth(frame:GetWidth() - 44)

    for _, ach in ipairs(filtered) do
        count = count + 1

        local id = ach.id
        local name = ach.name
        local link = GetAchievementLink(id)
        local display = string.format("|cffffd100[%d]|r %s", ach.y, link or name)

        local btn = frame:AcquireRow()
        btn:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 5, yOffset)
        btn:SetPoint("RIGHT", frame.content, "RIGHT", -5, 0)
        btn.txt:SetText(display)

        btn:SetScript("OnEnter", function(self)
            local safeLink = link or GetAchievementLink(id)
            if safeLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(safeLink)
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", GameTooltip_Hide)

        btn:SetScript("OnClick", function()
            if not AchievementFrame then
                AchievementFrame_LoadUI()
            end
            ShowUIPanel(AchievementFrame)
            AchievementFrame_SelectAchievement(id)
        end)

        table.insert(frame.activeRows, btn)
        yOffset = yOffset - ROW_HEIGHT
    end

    if count == 0 then
        if not frame.emptyText then
            frame.emptyText = frame.content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            frame.emptyText:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -10)
            frame.emptyText:SetPoint("RIGHT", frame.content, "RIGHT", -10, 0)
            frame.emptyText:SetJustifyH("LEFT")
            frame.emptyText:SetWordWrap(false)
            frame.emptyText:SetText("No history found for this day.")
        end
        frame.emptyText:Show()
    end

    frame.content:SetHeight(contentHeight)
    frame.scrollFrame:SetVerticalScroll(0)
    frame:Show()
end

local function ToggleNostalgicUI(resetToToday)
    if frame:IsShown() then
        frame:Hide()
    else
        if resetToToday then
            viewTime = time()
        end
        ShowNostalgicUI()
    end
end

-- ============================================================
-- 2. THE WINDOW & FRAME POOLING
-- ============================================================
frame = CreateFrame("Frame", "NostalgicFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(MIN_FRAME_WIDTH, 160)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetToplevel(true)
frame:SetFrameStrata("MEDIUM")
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    NostalgicPos = NostalgicPos or {}
    NostalgicPos.point = p
    NostalgicPos.rel = rp
    NostalgicPos.x = x
    NostalgicPos.y = y
end)
frame:Hide()

if UISpecialFrames then
    table.insert(UISpecialFrames, "NostalgicFrame")
end

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)

frame.measurer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.measurer:Hide()

frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 45)

frame.content = CreateFrame("Frame", nil, frame.scrollFrame)
frame.content:SetSize(260, 1)
frame.scrollFrame:SetScrollChild(frame.content)

frame.rowPool = {}
frame.activeRows = {}
frame.emptyText = nil

function frame:AcquireRow()
    local row = table.remove(self.rowPool)
    if not row then
        row = CreateFrame("Button", nil, self.content)
        row:SetHeight(20)

        row.txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.txt:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.txt:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        row.txt:SetJustifyH("LEFT")
        row.txt:SetWordWrap(false)
    end

    row:Show()
    return row
end

function frame:ReleaseRows()
    for _, row in ipairs(self.activeRows) do
        row:Hide()
        row:ClearAllPoints()
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row:SetScript("OnClick", nil)
        table.insert(self.rowPool, row)
    end
    wipe(self.activeRows)

    if self.emptyText then
        self.emptyText:Hide()
    end
end

function frame:GetMeasuredWidth(text)
    self.measurer:SetText(text or "")

    if self.measurer.GetUnboundedStringWidth then
        local width = self.measurer:GetUnboundedStringWidth()
        if width and width > 0 then
            return width
        end
    end

    return self.measurer:GetStringWidth() or 0
end

-- ============================================================
-- 3. BUTTON & INITIALIZATION
-- ============================================================
local function AttachToAchievementFrame()
    if _G["NostalgicAchievementBtn"] or not AchievementFrame then return end

    local btn = CreateFrame("Button", "NostalgicAchievementBtn", AchievementFrame, "UIPanelButtonTemplate")
    btn:SetSize(110, 22)
    btn:SetPoint("BOTTOM", AchievementFrame, "BOTTOM", 0, 5)
    btn:SetText("|cffffd100On This Day|r")

    btn:SetScript("OnClick", function()
        ToggleNostalgicUI(true)
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("ACHIEVEMENT_EARNED")

loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            NostalgicCache = NostalgicCache or {}
            NostalgicPos = NostalgicPos or {}

            DedupeSavedCache()
            PrimeSeenAchievements()

            if NostalgicPos.point then
                frame:ClearAllPoints()
                frame:SetPoint(NostalgicPos.point, UIParent, NostalgicPos.rel, NostalgicPos.x, NostalgicPos.y)
            end

            if AchievementFrame then
                AttachToAchievementFrame()
            end
        elseif arg1 == "Blizzard_AchievementUI" then
            AttachToAchievementFrame()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not isLoaded then
            C_Timer.After(4, function()
                BuildCache()
                print("|cff00ff00Nostalgic: Memories Loaded! /nos to toggle.|r")

                if AchievementFrame then
                    AttachToAchievementFrame()
                end

                local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
                if LDB then
                    LDB:NewDataObject("Nostalgic", {
                        type = "launcher",
                        text = "Nostalgic",
                        icon = "Interface\\Icons\\INV_Misc_Statue_01",
                        OnClick = function()
                            ToggleNostalgicUI(true)
                        end,
                    })
                end
            end)
            isLoaded = true
        end

    elseif event == "ACHIEVEMENT_EARNED" then
        C_Timer.After(1, function()
            AddToCache(arg1)
        end)
    end
end)

-- ============================================================
-- 4. NAVIGATION & SLASH COMMANDS
-- ============================================================
local prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
prevBtn:SetSize(32, 22)
prevBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 12)
prevBtn:SetText("<")
prevBtn:SetScript("OnClick", function()
    ShiftViewDate(-1)
    ShowNostalgicUI()
end)

local nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
nextBtn:SetSize(32, 22)
nextBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 12)
nextBtn:SetText(">")
nextBtn:SetScript("OnClick", function()
    ShiftViewDate(1)
    ShowNostalgicUI()
end)

local todayBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
todayBtn:SetSize(70, 22)
todayBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
todayBtn:SetText("Today")
todayBtn:SetScript("OnClick", function()
    viewTime = time()
    ShowNostalgicUI()
end)

SLASH_NOS1 = "/nos"
SLASH_NOS2 = "/nostalgic"
SlashCmdList["NOS"] = function()
    ToggleNostalgicUI(false)
end
