-- RQEMinimap.lua
-- Creates minimap button that will toggle the RQEFrame

---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}
RQE.hoverTimers = {}

---@class RQEMinimapButton : Frame
---@field hoverTimer any
local RQEMinimapButton = {}

---------------------------
-- 2. Debug Logic
---------------------------

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

---------------------------
-- 3. Function/Utilities
---------------------------

-- Toggle Debug Log window function
function RQE:ToggleDebugLog()
    if not RQE.DebugLogFrameRef then
        -- Initialize the debug log frame here if it doesn't exist yet
    end
    RQE.DebugLogFrame()
end

-- Open Settings function
function RQE:OpenSettings()
    Settings.OpenToCategory("Rhodan's Quest Explorer")
end

---------------------------
-- 4. Data Broker Handling
---------------------------

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

RQE.dataBroker = ldb:NewDataObject("RQE", {
    type = "launcher",
    icon = "Interface\\Addons\\RQE\\Textures\\rhodan.tga",
    OnClick = function(_, button)
        if button == "RightButton" then
            RQE:ShowLDBDropdownMenu()
        elseif IsShiftKeyDown() and button == "LeftButton" then
            RQE:ToggleDebugLog()
        elseif button == "LeftButton" then
            if RQEFrame:IsShown() then
                RQEFrame:Hide()
                if RQE.MagicButton then
                    RQE.MagicButton:Hide()
                end
                RQE.RQEQuestFrame:Hide()
                RQE.isRQEFrameManuallyClosed = true
                RQE.isRQEQuestFrameManuallyClosed = true
                RQE.Buttons.UpdateMagicButtonVisibility()
            else
                RQE:ClearFrameData()
                RQE:ClearWaypointButtonData()
                RQEFrame:Show()
                UpdateFrame()
                if RQE.MagicButton then
                    RQE.MagicButton:Show()
                end
                if RQE.db.profile.enableQuestFrame then
                    RQE.RQEQuestFrame:Show()
                end
                RQE.isRQEFrameManuallyClosed = false
                RQE.isRQEQuestFrameManuallyClosed = false
                RQE.Buttons.UpdateMagicButtonVisibility()
            end
        end
    end,

    OnEnter = function(display)
        if RQE.hoverTimers[display] then
            RQE:CancelTimer(RQE.hoverTimers[display])
        end
        RQE.hoverTimers[display] = RQE:ScheduleTimer(function()
            RQE:ShowLDBDropdownMenu()
        end, 1.5)
        
        GameTooltip:SetOwner(display, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOMLEFT", display, "TOPRIGHT")
        RQE.dataBroker.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end,

    OnLeave = function(display)
        if RQE.hoverTimers[display] then
            RQE:CancelTimer(RQE.hoverTimers[display])
            RQE.hoverTimers[display] = nil
        end
        GameTooltip:Hide()
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Rhodan's Quest Explorer")
        tooltip:AddLine("Left-click to toggle frame.")
        tooltip:AddLine("Right-click to Settings.")
        tooltip:AddLine("Shift+Left-click to toggle Debug Log.")
    end,
})

function RQE.ToggleBothFramesfromLDB()
    if RQEFrame:IsShown() then
        RQEFrame:Hide()
        if RQE.MagicButton then
            RQE.MagicButton:Hide()
        end
        RQE.RQEQuestFrame:Hide()
        RQE.isRQEFrameManuallyClosed = true
        RQE.isRQEQuestFrameManuallyClosed = true
    else
        RQE:ClearFrameData()
        RQE:ClearWaypointButtonData()
        if RQE.db.profile.enableFrame then
            RQEFrame:Show()
            if RQE.MagicButton then
                RQE.MagicButton:Show()
            end
        end
        if RQE.db.profile.enableQuestFrame then
            RQE.RQEQuestFrame:Show()
        end
        RQE.isRQEFrameManuallyClosed = false
        RQE.isRQEQuestFrameManuallyClosed = false
        RQE.Buttons.UpdateMagicButtonVisibility()
    end
end

---------------------------
-- 5. Minimap Button
---------------------------

RQE.MinimapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
RQE.MinimapButton:SetSize(25, 25)
RQE.MinimapButton:SetNormalTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetHighlightTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPushedTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)

---------------------------
-- 6. Event Handler
---------------------------

RQE.MinimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        RQE:ShowLDBDropdownMenu()
    elseif button == "LeftButton" then
        if RQEFrame:IsShown() then
            RQEFrame:Hide()
            if RQE.MagicButton then
                RQE.MagicButton:Hide()
            end
        else
            RQEFrame:Show()
            if RQE.MagicButton then
                RQE.MagicButton:Show()
            end
            RQE.RQEQuestFrame:Show()
        end
        RQE.Buttons.UpdateMagicButtonVisibility()
    end
end)

RQE.MinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Rhodan's Quest Explorer", 1, 1, 1)
    GameTooltip:AddLine("Left-click to toggle frame.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)

RQE.MinimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

---------------------------
-- 7. Menu Creation Functions
---------------------------

function RQE:ShowLDBDropdownMenu()
    local menuFrame = CreateFrame("Frame", "RQEDropDownMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menuFrame, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        if level == 1 then
            info.text, info.isTitle, info.notCheckable = "Menu", true, true
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text, info.notCheckable = "Toggle Frame(s)", true
            info.func = function() RQE.ToggleBothFramesfromLDB() end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text, info.notCheckable = "AddOn Settings", true
            info.func = function() RQE:OpenSettings() end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text, info.notCheckable = "Debug Log", true
            info.func = function() RQE:ToggleDebugLog() end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text, info.hasArrow, info.notCheckable = "More Options", true, true
            info.menuList = "MoreOptionsMenu"
            UIDropDownMenu_AddButton(info, level)
        elseif menuList == "MoreOptionsMenu" then
            info = UIDropDownMenu_CreateInfo()
            info.text, info.isTitle, info.notCheckable = "More Options Menu", true, true
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text, info.notCheckable = "AddOn Settings", true
            info.func = function() RQE:OpenSettings() end
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, "cursor", 3, -3)
end

---------------------------
-- 8. Drag n Drop Functions
---------------------------

RQE.MinimapButton:SetMovable(true)
RQE.MinimapButton:EnableMouse(true)

RQE.MinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

RQE.MinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

RQE.MinimapButton:RegisterForDrag("LeftButton")
