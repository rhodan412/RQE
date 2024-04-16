--[[ 

RQEFrame.lua
Manages the main frame design

]]


---------------------------
-- 1. Global Declarations
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    print("RQE or RQE.debugLog is not initialized.")
end

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}
RQE.lastKnownObjectiveIndex = RQE.lastKnownObjectiveIndex or {}

RQE.content = content  -- Save it to the global RQE table
RQEDatabase = RQEDatabase or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}
RQE.debugLog("RQE.db and RQE.db.profile loaded in RQEFrame.lua")

-- When setting up the frame size based on isMinimized
if RQE.db and RQE.db.profile.isMinimized then  -- Using AceDB profile storage
    -- your logic to minimize the frame
else
    -- your logic to maximize the frame
end


-- Initialize to some state (locked or unlocked, based on your preference)
local isFrameLocked = true  -- Change this based on your need


-- Menu Definition
local frameMenu = {
    { text = "RQE Frame Options", isTitle = true, notCheckable = true },
    { text = "Lock/Unlock Frames", notCheckable = true, func = function()
        RQE.ToggleFrameLock()
        UpdateMenuText()
    end },
    { text = "Toggle Objective Tracker", func = function()
		RQE:ToggleObjectiveTracker()
        UpdateMenuText()  -- Update menu text after state change
    end },
}


---------------------------
-- 2. Local Variables
---------------------------

-- Variable to keep track of the last known group size and type
local lastGroupSize = 0
local lastGroupType = "none" -- "none", "party", "raid", "instance"




---------------------------------
-- 3. RQEFrame Right-Click Menu
---------------------------------

-- Menu Frame Creation
local menuFrame = CreateFrame("Frame", "RQEFrameMenu", UIParent, "UIDropDownMenuTemplate")


-- Function to update the menu text
function UpdateMenuText()
    if isFrameLocked then
        frameMenu[2].text = "Unlock Frame"
    else
        frameMenu[2].text = "Lock Frame"
    end
	
	frameMenu[3].text = "Toggle Objective Tracker"
end

menuFrame:SetScript("OnShow", function()
    UpdateMenuText()
end)


-- Function to Show Right-Click Dropdown Menu
function ShowQuestDropdownRQEFrame(self, questID)
    local menu = {}

    -- Check if the player is in a group and the quest is shareable
    local isPlayerInGroup = IsInGroup()
    local isQuestShareable = C_QuestLog.IsPushableQuest(questID)
    
    if isPlayerInGroup and isQuestShareable then
        table.insert(menu, { text = "Share Quest", func = function() C_QuestLog.SetSelectedQuest(questID); QuestLogPushQuest(); end })
    end

    -- Always include the other options
    table.insert(menu, { text = "Stop Tracking", func = function() C_QuestLog.RemoveQuestWatch(questID); RQE:ClearFrameData(); end })
	-- Even though no error it can be glitchy with abandoning this from anything other than the world map/official quest log
    table.insert(menu, { text = "Abandon Quest", func = function() RQE:AbandonQuest(questID); end })
	table.insert(menu, { text = "Show Wowhead Link", func = function() RQE:ShowWowheadLink(questID) end })
	table.insert(menu, { text = "Search Warcraft Wiki", func = function() RQE:ShowWowWikiLink(questID) end })
	
    local menuFrame = CreateFrame("Frame", "RQEQuestDropdown", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end


---------------------------
-- 4. Imports
---------------------------

local AceGUI = LibStub("AceGUI-3.0")

---------------------------
-- 5. Frame Initialization
---------------------------

-- Debug to check state of main Frame
RQE.debugLog("Value of RQE.db", RQE.db)
if RQE and RQE.db and RQE.db.profile then
    RQE.debugLog("RQEFrame.lua loaded. Checking state of isMinimized:", RQE.db.profile.isMinimized)
else
    RQE.debugLog("RQE, RQE.db, or RQE.db.profile is nil.")
end


-- Create the main frame
RQEFrame = CreateFrame("Frame", "RQE.RQEFrame", UIParent, "BackdropTemplate")
--_G["RQEFrame"] = CreateFrame("Frame", "RQEFrame", UIParent, "BackdropTemplate")
RQEFrame:SetSize(435, 300)
local xPos, yPos
if RQE and RQE.db and RQE.db.profile and RQE.db.profile.framePosition then
    xPos = RQE.db.profile.framePosition.xPos or 810
    yPos = RQE.db.profile.framePosition.yPos or 165
else
    xPos = 810
    yPos = 165
end
RQEFrame:SetPoint("CENTER", UIParent, "CENTER", xPos, yPos)
RQEFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 0, right = 0, top = 1, bottom = 0 }
})
RQEFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.MainFrameOpacity)
--RQEFrame:SetBackdropColor(0, 0, 0, 0.5)  -- this was before the change to allow the user to make the QuestingFrame opacity change


RQE.OnCoordinateClicked = RQE.OnCoordinateClicked or function() end


-- Create the ScrollFrame
local ScrollFrame = CreateFrame("ScrollFrame", nil, RQEFrame)
ScrollFrame:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 10, -40)  -- Adjusted Y-position
ScrollFrame:SetPoint("BOTTOMRIGHT", RQEFrame, "BOTTOMRIGHT", -30, 10)
ScrollFrame:EnableMouseWheel(true)
ScrollFrame:SetClipsChildren(true)  -- Enable clipping


-- Create the content frame
content = CreateFrame("Frame", nil, ScrollFrame)  -- Made global
content:SetSize(360, 600)  -- Set the content size here
ScrollFrame:SetScrollChild(content)
content:SetAllPoints()


-- Create a header for the frame
local header = CreateFrame("Frame", "RQEFrameHeader", RQEFrame, "BackdropTemplate")
header:SetHeight(30)
header:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
header:SetPoint("TOPLEFT", 0, 0)
header:SetPoint("TOPRIGHT", 0, 0)


-- Create header text
local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("CENTER", header, "CENTER")
headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
headerText:SetTextColor(239/255, 191/255, 90/255)
headerText:SetText("RQE Quest Tracker")
headerText:SetWordWrap(true)
RQE.headerText = headerText


-- Create the Slider (Scrollbar)
slider = CreateFrame("Slider", nil, ScrollFrame, "UIPanelScrollBarTemplate")
slider:SetPoint("TOPLEFT", RQEFrame, "TOPRIGHT", -20, -20)
slider:SetPoint("BOTTOMLEFT", RQEFrame, "BOTTOMRIGHT", -20, 20)
slider:SetMinMaxValues(0, content:GetHeight())
slider:SetValueStep(1)
slider.scrollStep = 1

RQE.slider = slider

slider:SetScript("OnValueChanged", function(self, value)
    ScrollFrame:SetVerticalScroll(value)
end)


-- Right-Click Event Logic
RQEFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        EasyMenu(frameMenu, menuFrame, "cursor", 0 , 0, "MENU")
    end
end)


-- Create a button for unknown quests in the top-left corner of RQEFrame content
-- Call the function from WPUtil.lua to create the button
RQE.UnknownQuestButton = CreateFrame("Button", nil, content)
RQE.UnknownQuestButton:SetSize(25, 25)  -- Set size to 30x30
RQE.UnknownQuestButton:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)  -- Adjusted Y-position
RQE.UnknownQuestButton:Hide()  -- Initially hide the button

-- Use the custom texture for the background
local bg = RQE.UnknownQuestButton:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")

-- Create the text label
local label = RQE.UnknownQuestButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
label:SetPoint("CENTER", RQE.UnknownQuestButton, "CENTER")
label:SetText("W")  -- W for Waypoint
label:SetTextColor(1, 1, 0)


-- Add mouseover tooltip (functions listed in Buttons.lua)
RQE.UnknownButtonTooltip()


-- Hide the tooltip when the mouse leaves
RQE.HideUnknownButtonTooltip()


-- Assume IsWorldMapOpen() returns true if the world map is open, false otherwise
-- Assume CloseWorldMap() closes the world map
--RQE.UnknownQuestButtonCalcNTrack()
RQE.SaveSuperTrackData()


-- Create and position the new Search Group Button
-- Create Search Group button
RQE.SearchGroupButton = CreateFrame("Button", nil, content)
RQE.SearchGroupButton:SetSize(25, 25)  -- Set size to match the UnknownQuestButton
RQE.SearchGroupButton:SetPoint("TOPLEFT", RQE.UnknownQuestButton, "BOTTOMLEFT", 0, -5)  -- Position below UnknownQuestButton
RQE.SearchGroupButton:Hide() -- Hide the button Initially


-- Use a similar texture for the background as UnknownQuestButton
local sgBg = RQE.SearchGroupButton:CreateTexture(nil, "BACKGROUND")
sgBg:SetAllPoints()
sgBg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")  -- Adjust texture as needed


-- Create the text label for Search Group button
local sgLabel = RQE.SearchGroupButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sgLabel:SetPoint("CENTER", RQE.SearchGroupButton, "CENTER")
sgLabel:SetText("SG")  -- SG for Search Group
sgLabel:SetTextColor(1, 1, 0)  -- Adjust color as needed


-- Add bg to the global RQE table
RQE.bg = bg
RQE.sgbg = sgBg


-- Function to set up a tooltip for a given frame and multiple text lines
local function SetUpTooltip(frame, texts)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Concatenate all text lines, separated by line breaks
        local combinedText = table.concat(texts, "\n")
        GameTooltip:SetText(combinedText, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end


-- Setting up the tooltip for RQE.SearchGroupButton with all texts
SetUpTooltip(RQE.SearchGroupButton, {
    "2x Lt Click: Search for Group",
    "Rt Click: Create/Delist Group",
    --"Shift Lt Click: Delist Group"
})


-- Add a mouse down event to simulate a button press
RQE.UnknownQuestButtonMouseDown()
RQE.SearchGroupButtonMouseDown()


-- Add a mouse up event to reset the texture
RQE.UnknownQuestButtonMouseUp()


-- Function to Colorize the RQEFrame Quest Helper Module
local function colorizeObjectives(objectivesText)
    local objectives = { strsplit("\n", objectivesText) }
    local colorizedText = ""

    for _, objective in ipairs(objectives) do
        local current, total = objective:match("(%d+)/(%d+)")  -- Extract current and total progress
        current, total = tonumber(current), tonumber(total)

        if current and total then
            if current >= total then
                -- Objective complete, colorize in green
                colorizedText = colorizedText .. "|cff00ff00" .. objective .. "|r\n"
            elseif current > 0 then
                -- Objective partially complete, colorize in yellow
                colorizedText = colorizedText .. "|cffffff00" .. objective .. "|r\n"
            else
                -- Objective has not started or no progress, leave as white
                colorizedText = colorizedText .. "|cffffffff" .. objective .. "|r\n"
            end
        else
            -- Objective text without progress numbers, leave as is
            colorizedText = colorizedText .. objective .. "\n"
        end
    end

    return colorizedText
end


-- Create QuestID Text
RQE.QuestIDText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Debug: Check if settings are properly initialized
if settings then
    -- Debug: Check individual settings
    if RQE.db.profile.textSettings.QuestIDText.font then
        RQE.debugLog("Font setting exists.")
    else
        RQE.debugLog("Warning - Font setting does NOT exist.")
    end
    
    if RQE.db.profile.textSettings.QuestIDText.size then
        RQE.debugLog("Size setting exists.")
    else
        RQE.debugLog("Warning - Size setting does NOT exist.")
    end
    
    if RQE.db.profile.textSettings.QuestIDText.color then
        RQE.debugLog("Color setting exists.")
    else
        RQE.debugLog("Warning - Color setting does NOT exist.")
    end

    RQE.QuestIDText:SetFont(RQE.db.profile.textSettings.QuestIDText.font or "Fonts\\FRIZQT__.TTF", RQE.db.profile.textSettings.QuestIDText.size or 15)
    
    if RQE.db.profile.textSettings.QuestIDText.color then
        RQE.QuestIDText:SetTextColor(unpack(RQE.db.profile.textSettings.QuestIDText.color))
    end
end

RQE.QuestIDText:SetJustifyH("LEFT")
RQE.QuestIDText:SetJustifyV("TOP")
RQE.QuestIDText:SetWordWrap(true)
RQE.QuestIDText:SetWidth(RQEFrame:GetWidth() - 20)
RQE.QuestIDText:SetHeight(0)
RQE.QuestIDText:EnableMouse(true)
RQE.QuestIDText:SetPoint("TOPLEFT", RQE.UnknownQuestButton, "TOPLEFT", 40, -5)


-- Create QuestName Text
RQE.QuestNameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Set the anchor point relative to QuestIDText
RQE.QuestNameText:SetPoint("TOPLEFT", RQE.QuestIDText, "BOTTOMLEFT", 0, -8)

local QuestNameText_settings
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    QuestNameText_settings = RQE.db.profile.textSettings.QuestNameText
else
    RQE.debugLog("textSettings is not initialized.")
end

-- Debug: Check if settings are properly initialized
if QuestNameText_settings then

    RQE.QuestNameText:SetFont(QuestNameText_settings.font or "Fonts\\FRIZQT__.TTF", QuestNameText_settings.size or 15)
    
    if QuestNameText_settings.color then
        RQE.QuestNameText:SetTextColor(unpack(QuestNameText_settings.color))
    end
end

RQE.QuestNameText:SetJustifyH("LEFT")
RQE.QuestNameText:SetJustifyV("TOP")
RQE.QuestNameText:SetWordWrap(true)
RQE.QuestNameText:SetWidth(RQEFrame:GetWidth() - 35)
RQE.QuestNameText:SetHeight(0)
RQE.QuestNameText:EnableMouse(true)


-- Create DirectionTextFrame
RQE.DirectionTextFrame = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")


-- Set the anchor point relative to SearchGroupButton/QuestIDText
-- Check if RQE.SearchGroupButton exists
if RQE.SearchGroupButton and RQE.SearchGroupButton:IsShown() then
    -- If RQE.SearchGroupButton exists, set the anchor point relative to it
    RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.SearchGroupButton, "BOTTOMLEFT", 0, -20)
else
    -- If RQE.SearchGroupButton does not exist, set the anchor point relative to RQE.QuestIDText
    RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.QuestNameText, "BOTTOMLEFT", -35, -20)
end


local DirectionTextFrame_settings
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    DirectionTextFrame_settings = RQE.db.profile.textSettings.DirectionTextFrame
else
    RQE.debugLog("textSettings is not initialized.")
end


-- Debug: Check if settings are properly initialized
if DirectionTextFrame_settings then

    RQE.DirectionTextFrame:SetFont(DirectionTextFrame_settings.font or "Fonts\\FRIZQT__.TTF", DirectionTextFrame_settings.size or 13)
    
    if DirectionTextFrame_settings.color then
        RQE.DirectionTextFrame:SetTextColor(unpack(DirectionTextFrame_settings.color or {1, 1, 0.85}))
    end
end

RQE.DirectionTextFrame:SetJustifyH("LEFT")
RQE.DirectionTextFrame:SetJustifyV("TOP")
RQE.DirectionTextFrame:SetWordWrap(true)
RQE.DirectionTextFrame:SetWidth(RQEFrame:GetWidth() - 50)
RQE.DirectionTextFrame:SetHeight(0)
RQE.DirectionTextFrame:EnableMouse(true)

-- Create QuestDescription Text
RQE.QuestDescription = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Set the anchor point relative to DirectionTextFrame
RQE.QuestDescription:SetPoint("TOPLEFT", RQE.DirectionTextFrame, "BOTTOMLEFT", 0, -17)

local QuestDescription_settings
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    QuestDescription_settings = RQE.db.profile.textSettings.QuestDescription
else
    RQE.debugLog("textSettings is not initialized.")
end

-- -- Function to Update QuestDescription
-- function RQE:UpdateQuestDescription()
    -- if RQEDatabase and RQEDatabase[currentQuestID] then
        -- local questDescription = RQEDatabase[currentQuestID].description
        -- RQE.QuestDescription:SetText(questDescription)
    -- else
        -- -- Handle the case where the quest ID is not found in the database
        -- RQE.QuestDescription:SetText("Quest information not available.")
    -- end
-- end

-- -- Call this function to initially set the text
-- RQE:UpdateQuestDescription()

-- Debug: Check if settings are properly initialized
if QuestDescription_settings then
    RQE.QuestDescription:SetFont(QuestDescription_settings.font or "Fonts\\FRIZQT__.TTF", QuestDescription_settings.size or 14)
    
    if QuestDescription_settings.color then
        RQE.QuestDescription:SetTextColor(unpack(QuestDescription_settings.color or {0, 1, 0.6}))
    end
end

RQE.QuestDescription:SetJustifyH("LEFT")
RQE.QuestDescription:SetJustifyV("TOP")
RQE.QuestDescription:SetWordWrap(true)
RQE.QuestDescription:SetWidth(RQEFrame:GetWidth() - 35)
RQE.QuestDescription:SetHeight(0)
RQE.QuestDescription:EnableMouse(true)


-- Create QuestObjectives Text
RQEFrame.QuestObjectives = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RQE.QuestObjectives = RQEFrame.QuestObjectives


-- Check if QuestDescription is empty
-- Check if RQE.QuestDescription has text and is shown
-- If QuestDescription is already visible at the time of this code execution,
-- you need to set the initial position of QuestObjectives.
if RQE.QuestDescription and RQE.QuestDescription:IsShown() and RQE.QuestDescription:GetText() ~= "" then
    -- There is a description, so show it and position objectives below it.
    RQE.QuestDescription:Show()
    RQE.QuestObjectives:SetPoint("TOPLEFT", RQE.QuestDescription, "BOTTOMLEFT", 0, -17)
else
    -- There is no description, so hide it and move objectives up.
    RQE.QuestDescription:Hide()
    RQE.QuestObjectives:SetPoint("TOPLEFT", RQE.DirectionTextFrame, "TOPLEFT", 0, -17) -- Adjust the X and Y offsets as needed.
end


local QuestObjectives_settings
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    QuestObjectives_settings = RQE.db.profile.textSettings.QuestObjectives
else
    RQE.debugLog("textSettings is not initialized.")
end

-- Debug: Check if settings are properly initialized
if QuestObjectives_settings then
    RQE.QuestObjectives:SetFont(QuestObjectives_settings.font or "Fonts\\FRIZQT__.TTF", QuestObjectives_settings.size or 13)
    
    if QuestObjectives_settings.color then
        RQE.QuestObjectives:SetTextColor(unpack(QuestObjectives_settings.color or {0, 1, 0.6}))
    end
end

RQE.QuestObjectives:SetJustifyH("LEFT")
RQE.QuestObjectives:SetJustifyV("TOP")
RQE.QuestObjectives:SetWordWrap(true)
RQE.QuestObjectives:SetWidth(RQEFrame:GetWidth() - 35)
RQE.QuestObjectives:SetHeight(0)
RQE.QuestObjectives:EnableMouse(true)


-- Display MapID with Tracker Frame
local MapIDText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MapIDText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 15, 15)  -- Adjust the offsets as needed (-15, 20 was a little too high on the Y)
MapIDText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
MapIDText:SetText("")
RQEFrame.MapIDText = MapIDText


-- Create Font String for Coordinates
local CoordinatesText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CoordinatesText:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -15, 15)  -- Adjust the offsets as needed
CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CoordinatesText:SetText("")
RQEFrame.CoordinatesText = CoordinatesText


-- Create Font String for Addon Memory Usage
local MemoryUsageText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MemoryUsageText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 15, 35)  -- Position it right above the MapIDText
MemoryUsageText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
MemoryUsageText:SetTextColor(231/255, 120/255, 120/255)
RQEFrame.MemoryUsageText = MemoryUsageText


-- Create buttons using functions from Buttons.lua
RQE.Buttons.CreateClearButton(RQEFrame, "TOPLEFT")
RQE.Buttons.CreateRWButton(RQEFrame, "ClearButton")
RQE.Buttons.CreateSearchButton(RQEFrame, "RWButton")
RQE.Buttons.CreateQMButton(RQEFrame, "SearchButton")
RQE.Buttons.CreateCloseButton(RQEFrame, "TOPRIGHT")
RQE.Buttons.CreateMaximizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider, "CloseButton")
RQE.Buttons.CreateMinimizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider, "MaximizeButton")


-- Magic Button
RQE.Buttons.CreateMagicButton(RQEFrame, "TOPRIGHT")


-- Create the ">" button
local searchExecuteButton = CreateFrame("Button", nil, SearchFrame, "UIPanelButtonTemplate")
searchExecuteButton:SetSize(18, 18)
searchExecuteButton:SetPoint("LEFT", searchEditBox, "RIGHT", 5, 0)
searchExecuteButton:SetText(">")

---------------------------
-- 6. Event Handlers
---------------------------

-- Function for Update Button Visibility
function UpdateButtonVisibility()
    if RQEFrame.isMinimized then
        RQE.MinimizeButton:Hide()
        RQE.MaximizeButton:Show()
    else
        RQE.MinimizeButton:Show()
        RQE.MaximizeButton:Hide()
    end
    
    -- Save the current minimized state to the SavedVariables
    RQE.db.profile.isMinimized = RQEFrame.isMinimized

    -- Add these lines for debugging
    local point, relativeTo, relativePoint, xOfs, yOfs = RQE.MinimizeButton:GetPoint()
    point, relativeTo, relativePoint, xOfs, yOfs = RQE.MaximizeButton:GetPoint()
end


-- Event to update text widths when the frame is resized
RQEFrame:SetScript("OnSizeChanged", function(self, width, height)
    local baseWidth = 400
    local paddingIncrement = (width - baseWidth) / 20
    local basePadding = 20 -- This is your base padding. Adjust as necessary.
    local dynamicPadding = math.max(basePadding, paddingIncrement + basePadding)
    
    local newWidth = width - dynamicPadding  -- Use dynamic padding to adjust the width
    RQE.debugLog("OnSizeChanged: New width is " .. newWidth .. ", Padding: " .. dynamicPadding)

    -- Update text widths using newWidth based on dynamic padding
    if RQE.QuestNameText then
        RQE.QuestNameText:SetWidth(newWidth)
    else
        RQE.debugLog("RQE.QuestNameText is not initialized.")
    end
	    
    if self.StepsText then
        for i, stepsTextElement in ipairs(self.StepsText) do
            stepsTextElement:SetWidth(newWidth)
            RQE.debugLog("Setting StepsText " .. i .. " width to " .. newWidth)
        end
    end

    if self.CoordsText then
        for i, coordTextElement in ipairs(self.CoordsText) do
            coordTextElement:SetWidth(newWidth)
            RQE.debugLog("Setting CoordsText " .. i .. " width to " .. newWidth)
        end
    end
end)
-- RQEFrame:SetScript("OnSizeChanged", function(self, width, height)
    -- local newWidth = width - 45  -- Adjust the padding as needed
    -- RQE.debugLog("OnSizeChanged: New width is " .. newWidth)

    -- --RQE.QuestIDText:SetWidth(newWidth)
    -- if RQE.QuestNameText then
        -- RQE.QuestNameText:SetWidth(newWidth)
    -- else
        -- RQE.debugLog("RQE.QuestNameText is not initialized.")
    -- end
	    
    -- if self.StepsText then
        -- for i, stepsTextElement in ipairs(self.StepsText) do
            -- stepsTextElement:SetWidth(newWidth)
            -- RQE.debugLog("Setting StepsText " .. i .. " width to " .. newWidth)
        -- end
    -- end

    -- if self.CoordsText then
        -- for i, coordTextElement in ipairs(self.CoordsText) do
            -- coordTextElement:SetWidth(newWidth)
            -- RQE.debugLog("Setting CoordsText " .. i .. " width to " .. newWidth)
        -- end
    -- end
-- end)


-- Add a click event to open the quest details for the current QuestID
RQE.QuestIDText:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        OpenQuestLogToQuestDetails(questID)
    end
end)


-- Add a click event to open the map for the current QuestName
if RQE.QuestNameText then  -- Check if QuestNameText is initialized
	RQE.QuestNameText:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			OpenQuestLogToQuestDetails(questID)
		end
	end)
else
    RQE.debugLog("RQE.QuestNameText is not initialized.")
end


-- Function to create tooltip for QuestID and QuestName
local function CreateQuestTooltip(frame, questID)
    local effectiveQuestID = RQE.searchedQuestID or questID
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT", -50, -40)
    GameTooltip:SetMinimumWidth(350)
    GameTooltip:SetHeight(0)
    GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")

    if not RQE.QuestIDText or not RQE.QuestIDText:GetText() then
        RQE.debugLog("QuestIDText is nil or empty. Cannot proceed.")
        return
    end
	
	local extractedQuestID
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))

	questID = effectiveQuestID or extractedQuestID or currentSuperTrackedQuestID
	local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
    
	-- local questTitle
    -- if RQEDatabase and RQEDatabase[questID] and RQEDatabase[questID].title then
        -- questTitle = RQEDatabase[questID].title  -- Use title from RQEDatabase if available
    -- else
        -- questTitle = C_QuestLog.GetTitleForQuestID(questID)  -- Fallback to game's API call
    -- end
    -- questTitle = questTitle or "N/A"  -- Default to "N/A" if no title found
    -- GameTooltip:SetText(questTitle)  -- Display quest name

    local questData = RQE.getQuestData(effectiveQuestID)
    local questTitle = questData and questData.title or "Unknown Quest"
    GameTooltip:SetText(questTitle)
	
	if RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) and not isWorldQuest then
		-- Add code for line break if this is a searched quest
	else
		GameTooltip:AddLine(" ")  -- Add line break
	end
	
	-- Add description
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
	if questLogIndex then
		local _, questObjectives = GetQuestLogQuestText(questLogIndex)
		local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
		GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
		GameTooltip:AddLine(" ")
	end

	if questID then
		-- Check if the quest is completed
		if C_QuestLog.IsQuestFlaggedCompleted(questID) then
			GameTooltip:AddLine("Status: Completed", 0, 1, 0) -- Green color for completed
		else
			GameTooltip:AddLine("Status: Not Completed", 1, 0, 0) -- Red color for not completed
		end
	end
	
    -- Add objectives
    local objectivesInfo = C_QuestLog.GetQuestObjectives(questID)
    if objectivesInfo and #objectivesInfo > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Objectives:")

        -- Concatenate objectives into a string and colorize
        local objectivesText = ""
        for _, objective in ipairs(objectivesInfo) do
            objectivesText = objectivesText .. objective.text .. "\n"
        end

        local colorizedObjectives = colorizeObjectives(objectivesText)
        GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)  -- true for wrap
    end

	if RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) and not isWorldQuest then
		-- Add code for the Rewards tooltip if this is a searched quest
	else
		-- Add Rewards
		GameTooltip:AddLine("Rewards: ")
		RQE:QuestRewardsTooltip(GameTooltip, questID)  -- Assuming RQE:QuestRewardsTooltip is defined
		GameTooltip:AddLine(" ")
	end
	
	-- Party Members' Quest Progress
	if IsInGroup() then
		local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
		if tooltipData and tooltipData.lines then
			local player_name = UnitName("player")
			local isFirstPartyMember = true
			local skipPlayerLines = false
			local skipQuestNameLine = false  -- Flag to skip quest name lines

			for _, line in ipairs(tooltipData.lines) do
				if line.type == Enum.TooltipDataLineType.QuestTitle then  -- Assuming quest titles have this type
					skipQuestNameLine = true
				end

				if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText == player_name then
					skipPlayerLines = true
					isFirstPartyMember = false
				end

				if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText ~= player_name then
					skipPlayerLines = false
					skipQuestNameLine = false  -- Reset for the next quest
					if isFirstPartyMember then
						GameTooltip:AddLine(" ")
						isFirstPartyMember = false
					end
				end

				if not skipPlayerLines and not skipQuestNameLine then
					local text = line.leftText
					local r, g, b = line.leftColor:GetRGB()
					GameTooltip:AddLine(text, r, g, b, true)
				end
			end
		end
	end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82) -- Aquamarine
    GameTooltip:Show()
end


-- Hide tooltip for the RQEFrame when moving out of the frame
if RQEFrame then
    RQEFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end


-- Add mouseover event for QuestIDText
RQE.QuestIDText:SetScript("OnEnter", function(self)
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID then
        CreateQuestTooltip(self, questID)
    end
end)
RQE.QuestIDText:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

RQE.QuestIDText:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        if questID then
            ShowQuestDropdownRQEFrame(self, questID)
        end
    end
end)

-- Add mouseover event for QuestNameText
if RQE.QuestNameText then
    RQE.QuestNameText:SetScript("OnEnter", function(self)
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        if questID then
            CreateQuestTooltip(self, questID)
        end
    end)
    RQE.QuestNameText:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
else
    RQE.debugLog("RQE.QuestNameText is not initialized.")
end

RQE.QuestNameText:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        if questID then
            ShowQuestDropdownRQEFrame(self, questID)
        end
    end
end)


-- Event when a dropdown item is clicked
function RQEFrame:OnSearchResultClicked(_, arg1, _, checked)
    -- Implement what happens when a search result is clicked
end


-- Function used to adjust the RQE Frame width
function AdjustRQEFrameWidths(newWidth)
    -- Use the current frame width if newWidth is not provided
    newWidth = newWidth or RQEFrame:GetWidth()
	
    local baseWidth = 400
    local paddingIncrement = (RQEFrame:GetWidth() - baseWidth) / 20
    local basePadding = 20 -- Adjust as needed
    local dynamicPadding = math.max(basePadding, paddingIncrement + basePadding)
	
    -- Adjust width for each element
    RQE.QuestIDText:SetWidth(newWidth - dynamicPadding - 25)	
    RQE.QuestNameText:SetWidth(newWidth - dynamicPadding - 55)
    RQE.DirectionTextFrame:SetWidth(newWidth - dynamicPadding - 55)
    RQE.QuestDescription:SetWidth(newWidth - dynamicPadding - 45)
    RQE.QuestObjectives:SetWidth(newWidth - dynamicPadding - 45)
end


-- Callback function to handle coordinate clicks
function RQEFrame:OnCoordinateClicked(x, y)
    -- Your code to handle the coordinate click event
end


-- Optional: Update the scrollbar when mousewheel is used on the ScrollFrame
ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local value = slider:GetValue()
    if delta > 0 then
        slider:SetValue(value - 25) -- A Change from 20 to 25 on both slider SetValues increases the scroll speed
    else
        slider:SetValue(value + 25)
    end
end)

---------------------------
-- 7. Utility Functions
---------------------------

-- Make this a global variable or part of the RQE table
RQE.isSearchFrameShown = false


-- Function to create the search frame
function CreateSearchFrame(showFrame)
    if not showFrame then
        if RQEFrame.SearchFrame then
            RQEFrame.SearchFrame:Hide()
            RQEFrame.SearchFrame = nil
        end
        return
    end

    -- Use the search box and examine button from Core.lua
    local searchBox, examineButton = RQE.SearchModule:CreateSearchBox()

    local SearchFrame = AceGUI:Create("Frame")
    SearchFrame:SetTitle("Search Frame")
    SearchFrame:SetWidth(400)
    SearchFrame:SetHeight(200)
    SearchFrame:SetLayout("Flow")
    SearchFrame:SetStatusText("Enter your search query")
    SearchFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        RQEFrame.SearchFrame = nil
    end)

    -- Add the edit box and examine button to the SearchFrame
    SearchFrame:AddChild(searchBox)
    SearchFrame:AddChild(examineButton)

    RQEFrame.SearchFrame = SearchFrame
    SearchFrame.frame:ClearAllPoints()
    SearchFrame.frame:SetPoint("TOPRIGHT", RQEFrame, "TOPLEFT", 0, 0)
end


-- DisplayResults function
function RQE.SearchModule:FetchAndDisplayQuestData(questID)
    C_QuestLog.RequestLoadQuestByID(questID)
    C_Timer.After(1, function()  -- Wait for 1 second for data to load
        local questTitle = C_QuestLog.GetTitleForQuestID(questID)
        local questDetail, questObjectives = GetQuestLogQuestText(questID)

        if not questTitle or not questDetail or not questObjectives then
            RQE.debugLog("Quest information not available for Quest ID: " .. questID)
            return
        end

        self:DisplayQuestDataInRQEFrame(questTitle, questDetail, questObjectives)
    end)
end


-- Function to dynamically create StepsText and CoordsText elements
function RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
	-- Initialize an array to store the heights
	local stepTextHeights = {}
	RQE.CurrentQuestSteps = {}
	local yOffset = -20  -- Vertical distance you want to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
	local baseYOffset = -20
	
	if self.CoordsText then
		for i, textElement in ipairs(self.CoordsText) do
			textElement:Hide()
		end
	end

	if self.WaypointButtons then
		for i, buttonElement in ipairs(self.WaypointButtons) do
			buttonElement:Hide()
		end
	end

    -- Initialize or reset the MapIDs
    self.MapIDs = MapIDs  -- Save MapIDs in RQEFrame

    -- Previous text used for anchoring
    local prevText = self.QuestObjectives  -- Changed from self.QuestNameText

	-- Create new step texts
	for i = 1, #StepsText do
		localstepTextHeight = 10
	
		-- Create StepsText
		local StepText = content:CreateFontString(nil, "OVERLAY")
		table.insert(RQE.StepsText, StepText)
		StepText:SetFont("Fonts\\FRIZQT__.TTF", 12)
		StepText:SetJustifyH("LEFT")
		StepText:SetTextColor(1, 1, 0.8) -- Text color for RQE.StepsText in RGB
		StepText:SetSize(350, 0) -- Controls how much length you have across the frame before it will force a line break
		StepText:SetHeight(0)  -- Auto height
		StepText:SetWordWrap(true)  -- Allow word wrap
		StepText:SetText(StepsText[i] or "No description available.")
		StepText:SetWidth(RQEFrame:GetWidth() - 80)
		
		-- Create CoordsText
		local CoordText = content:CreateFontString(nil, "OVERLAY")
		table.insert(RQE.CoordsText, CoordText)
		
		if i == 1 then
			if self.QuestObjectives then
				StepText:SetPoint("TOPLEFT", self.QuestObjectives, "BOTTOMLEFT", 35, yOffset)
			elseif self.QuestDescription then
				StepText:SetPoint("TOPLEFT", self.QuestDescription, "BOTTOMLEFT", 35, yOffset)
			end
		else
			if prevText then  -- Check if StepText[i-1] exists
				StepText:SetPoint("TOPLEFT", prevText, "BOTTOMLEFT", 0, yOffset)
			end
		end
		
        StepText:Show()

        -- Update previous text for anchoring
        prevText = StepText
		
		-- Create the WaypointButton
		local WaypointButton = CreateFrame("Button", nil, content)
		WaypointButton:SetPoint("TOPRIGHT", StepText, "TOPLEFT", -10, 10)
		WaypointButton:SetSize(30, 30)  -- Set size to 30x30
		-- Use the custom texture for the background
		local bg = WaypointButton:CreateTexture(nil, "BACKGROUND")  -- changed to WaypointButton from WaypointButtons
		bg:SetAllPoints()
		--bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
		
		-- Determine if this button was the last clicked
		if RQE.LastClickedIdentifier and RQE.LastClickedIdentifier == i then
			-- This button was the last clicked one; apply the "lit" texture
			bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
		else
			-- For all other buttons, apply the default texture
			bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
		end

		-- Get the height of the StepText element
		local stepTextHeight = StepText:GetStringHeight()
	
		-- Create the number label
		local number = WaypointButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		number:SetPoint("CENTER", WaypointButton, "CENTER")
		number:SetText(i)
		number:SetTextColor(1, 1, 0)

		WaypointButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetText(CoordsText[i])
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 0, 0)  -- Adjust the x, y offsets as needed
			GameTooltip:Show()
		end)
		
		-- Insert it into the RQE.WaypointButtons table
		table.insert(RQE.WaypointButtons, WaypointButton)

		-- Hide the tooltip when the mouse leaves
		WaypointButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Add the click event for WaypointButtons
		WaypointButton:SetScript("OnClick", function()
			-- Your code for RWButton functionality here
			C_Map.ClearUserWaypoint()
			if IsAddOnLoaded("TomTom") then
				TomTom.waydb:ResetProfile()
			end

			local x, y = string.match(CoordsText[i], "([^,]+),%s*([^,]+)")
			x, y = tonumber(x), tonumber(y)
			local mapID = MapIDs[i]  -- Fetch the mapID from the MapIDs array
            
            -- Call your function to handle the coordinate click
            RQE:OnCoordinateClicked(x, y, mapID)

			-- Check if there's a last clicked button and reset its texture
			if RQE.LastClickedWaypointButton and RQE.LastClickedWaypointButton ~= WaypointButton then
				RQE.LastClickedWaypointButton.bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
			end
			
			-- Update the texture of the currently clicked button
			bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")

			-- Save the identifier (could be the questID or any unique property tied to the button)
			RQE.LastClickedIdentifier = i

			-- When creating the WaypointButton
			WaypointButton.stepIndex = i
			RQE.LastClickedButtonRef = WaypointButton
			RQE.infoLog("New LastClickedButton set:", i or "Unnamed")
			
			-- Update the reference to the last clicked button
			RQE.LastClickedWaypointButton = WaypointButton
			RQE.LastClickedWaypointButton.bg = bg -- Store the bg texture so it can be modified later
			
			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				questIDFromText = tonumber(RQE.QuestIDText:GetText():match("%d+"))
				if not questIDFromText then
					RQE.debugLog("Error: Invalid quest ID extracted from text")
				else
					RQE.infoLog("Quest ID from text for macro:", questIDFromText)  -- Debug message for the current operation
				
					-- Dynamically create/edit macro based on the super tracked quest and the step associated with the clicked waypoint button
					RQE.debugLog("Attempting to create macro")
					C_SuperTrack.SetSuperTrackedQuestID(questIDFromText)  -- This call is now inside the else clause
				end
			end
			
			RQE.infoLog("Quest ID from text for macro:", questIDFromText)  -- Debug message for the current operation
	
			-- Dynamically create/edit macro based on the super tracked quest and the step associated with the clicked waypoint button
			RQE.debugLog("Attempting to create macro")
			-- C_SuperTrack.SetSuperTrackedQuestID(questIDFromText)
			
			RQE.debugLog("Super Tracked Quest ID:", questID)  -- Debug message for the super tracked quest ID
			local questData = RQE.getQuestData(questIDFromText)
			local stepDescription = StepsText[i]  -- Holds the description like "This is Step One."
			RQE.infoLog("Step Description:", stepDescription)  -- Debug message for the step description
			if questData then
				local stepData = questData[stepIndex]
				RQE.debugLog("Quest data found for ID:", questIDFromText)
				for index, stepData in ipairs(questData) do
					if stepData.description == stepDescription then
						RQE.infoLog("Matching step data found for description:", stepDescription)
						if stepData and stepData.macro then
							local macroCommands = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro
							RQE.infoLog("Macro commands to set:", macroCommands)
							RQEMacro:SetQuestStepMacro(questIDFromText, index, macroCommands, false)
						else
							RQE.debugLog("No macro data found for this step.")
						end
					end
				end
			else
				RQE.debugLog("Invalid quest ID or step description. Quest data not found.")
			end
						
			-- Check if MagicButton should be visible based on macro body
			C_Timer.After(1, function()
				RQE.Buttons.UpdateMagicButtonVisibility()
			end)
			
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)

		-- Add a mouse down event to simulate a button press
		WaypointButton:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				bg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press
			end
		end)

		-- Add a mouse up event to reset the texture
		WaypointButton:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				bg:SetAlpha(1)  -- Reset the alpha
			end
		end)
		
		-- Show the Elements
		WaypointButton:Show()  -- Make sure to show the button
			
		-- Create CoordsText as a tooltip
		StepText:SetScript("OnEnter", function(self)  -- changed to StepText from RQE.StepText
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetText(CoordsText[i] or "No coordinates available.")
			GameTooltip:Show()
		end)
		StepText:SetScript("OnLeave", function(self)  -- changed to StepText from RQE.StepText
			GameTooltip:Hide()
		end)

		-- Add the mouse down event here
		StepText:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				local x, y = string.match(CoordsText[i], "([^,]+),%s*([^,]+)")
				x, y = tonumber(x), tonumber(y)
				local mapID = MapIDs[i]  -- Fetch the mapID from the MapIDs array
                
                -- Call your function to handle the coordinate click
                RQE:OnCoordinateClicked(x, y, mapID)
            end
        end)
    end
    
    -- Call UpdateContentSize at the end
    RQE:UpdateContentSize()
end


-- Check and Advance Steps
function RQE:CheckAndAdvanceStep(questID)
    local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local extractedQuestID
    if RQE.QuestIDText and RQE.QuestIDText:GetText() then
        extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
    end

    -- Determine questID based on various fallbacks
    questID = RQE.searchedQuestID or extractedQuestID or questID

	-- Validation Check
    if not questID or type(questID) ~= "number" then
        RQE.debugLog("Invalid questID:", questID)
        return
    end

    local currentObjectiveIndex = self:GetCurrentObjectiveIndex(questID)
    
    if RQE.lastKnownObjectiveIndex[questID] ~= currentObjectiveIndex then
        -- Detected a change in objective, indicating progress
        RQE.hasClickedQuestButton = false  -- Reset the flag since there's actual progress
		RQE.infoLog("RQE.hasClickedQuestButton flag is being reset for quest " .. questID)
        RQE.lastKnownObjectiveIndex[questID] = currentObjectiveIndex  -- Update the tracked index
        -- Potentially other logic to handle the change in objective
    end
	
    -- Retrieve objectives for the questID
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if not objectives or #objectives == 0 then
        RQE.debugLog("Quest", questID, "has no objectives or failed to retrieve objectives.")
        return
    end

    -- Handle quest completion and specific objectives
    if allObjectivesCompleted then
        nextObjectiveIndex = 99
        self:ClickWaypointButtonForNextObjectiveIndex(nextObjectiveIndex, questData)
        return
    end
	
    -- Check if all objectives are finished
    local allObjectivesCompleted = true
    for _, objective in ipairs(objectives) do
        if not objective.finished then
            allObjectivesCompleted = false
            break
        end
    end

    -- Calculate highestCompletedObjectiveIndex based on objectives completion
    local highestCompletedObjectiveIndex = allObjectivesCompleted and 99 or 0
    local questData = RQE.getQuestData(questID)
    if not questData then
        RQE.debugLog("Quest data not found for questID:", questID)
        return
    end

    for _, stepData in ipairs(questData) do
        if stepData.objectiveIndex and (stepData.objectiveIndex ~= 99) then
            local objective = objectives[stepData.objectiveIndex]
            if objective and objective.finished and stepData.objectiveIndex > highestCompletedObjectiveIndex then
                highestCompletedObjectiveIndex = stepData.objectiveIndex
            end
        end
    end

    RQE.infoLog("QuestID: " .. tostring(questID) ..
      ", All Objectives Completed: " .. tostring(allObjectivesCompleted) ..
      ", Highest Completed Objective Index: " .. tostring(highestCompletedObjectiveIndex))

    -- Store the previous highestCompletedObjectiveIndex before calculations
    local previousHighestCompletedObjectiveIndex = RQE.lastKnownObjectiveIndex[questID] or 0
	
	-- Before your if-else statement
	local nextObjectiveIndex = highestCompletedObjectiveIndex + 1 -- Default to the next index (will show up as 100 if the quest is completed)

    -- -- After calculations, compare the previous index to the current highestCompletedObjectiveIndex
    -- if highestCompletedObjectiveIndex ~= previousHighestCompletedObjectiveIndex then
        -- -- There has been progress, so call the function to click the super tracked quest button
        -- --RQE:ClickSuperTrackedQuestButton()
        
        -- -- Update the lastKnownObjectiveIndex for this quest
        -- RQE.lastKnownObjectiveIndex[questID] = highestCompletedObjectiveIndex
    -- end
	
    -- Handle quest completion and specific objectives
	if allObjectivesCompleted then
		nextObjectiveIndex = 99 -- Override if all objectives are completed
	end
	
	self:ClickWaypointButtonForNextObjectiveIndex(nextObjectiveIndex, questData)
end


-- Fetch the Objective Index for a particular quest
function RQE:GetCurrentObjectiveIndex(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if not objectives or #objectives == 0 then
        RQE.debugLog("No objectives found for questID:", questID)
        return 0  -- Return 0 or an appropriate default value if no objectives are found
    end
    
    local highestIndex = 0
    for _, objective in ipairs(objectives) do
        if objective.finished and objective.index and objective.index > highestIndex then
            highestIndex = objective.index
        end
    end
    return highestIndex
end


-- Utility function to get the total number of unique objectiveIndexes in the quest
function RQE:GetTotalObjectiveIndexes(questData)
    local indexes = {}
    for _, stepData in ipairs(questData) do
        if stepData.objectiveIndex then
            indexes[stepData.objectiveIndex] = true
        end
    end
    
    local count = 0
    for _ in pairs(indexes) do count = count + 1 end
    
    return count
end


-- Simulate WaypointButton click for the next step upon completion of a quest objective and print debug statements
function RQE:ClickWaypointButtonForNextObjectiveIndex(nextObjectiveIndex, questData)
    -- -- Direct click for the first objective when transitioning from 0 to 1
    -- if nextObjectiveIndex == 1 and RQE.lastClickedObjectiveIndex == 0 then
        -- RQE.infoLog("Quest is incomplete. Clicking WaypointButton(1).")
        -- RQE.WaypointButtons[1]:Click()
        
        -- -- Call to update the waypoint for the first objective
        -- RQE.ClickUnknownQuestButton()
        -- return
    -- end
    
    -- If the quest is completed, prioritize clicking the button for objectiveIndex 99
    if nextObjectiveIndex == 99 then
        for stepIndex, stepData in ipairs(questData) do
            if stepData.objectiveIndex == 99 then
                local button = RQE.WaypointButtons[stepIndex]
                if button then
                    RQE.infoLog("Quest is complete. Clicking WaypointButton for quest turn-in (ObjectiveIndex 99).")
                    button:Click()
                    RQE.lastClickedObjectiveIndex = 99
                    
                    -- Call to update the waypoint for the quest completion objective
					C_Timer.After(1, function()  -- Delay of 1 second
						RQE.ClickUnknownQuestButton()
					end)
                    return
                end
            end
        end
    end
    
    -- Check if this is a new objectiveIndex, not the same as the last clicked one.
    if RQE.lastClickedObjectiveIndex == nextObjectiveIndex then
        RQE.infoLog("ObjectiveIndex " .. nextObjectiveIndex .. " was already clicked. Skipping.")
        return
    end

    for _, stepData in ipairs(questData) do
        if stepData.objectiveIndex == nextObjectiveIndex then
            local button = RQE.WaypointButtons[_] -- Assuming WaypointButtons are stored in a manner that mirrors questData
            if button then
                -- Simulate the click
                RQE.infoLog("objectiveIndex neither 1 or 99, clicking appropriate button")
                RQE.infoLog("Clicking WaypointButton for objectiveIndex:", nextObjectiveIndex)
                button:Click() -- `OnClick` will now use the button's direct data
                RQE.infoLog("WaypointButton clicked for objectiveIndex:", nextObjectiveIndex)
				
                -- Update the lastClickedObjectiveIndex since we've moved to a new objective.
                RQE.lastClickedObjectiveIndex = nextObjectiveIndex
                
				-- Call to update the waypoint for the quest completion objective
				C_Timer.After(1, function()  -- Delay of 1 second
					RQE.ClickUnknownQuestButton()
				end)
                return
            end
        end
    end
    RQE.infoLog("No WaypointButton found for ObjectiveIndex " .. nextObjectiveIndex .. ".")
    UpdateRQEQuestFrame()
end


-- Function to check if all objectives for a given quest are completed
function RQE:AreAllObjectivesCompleted(questID)
    -- Check if questID is valid
    if not questID or type(questID) ~= "number" or questID <= 0 then
        RQE.infoLog("Invalid or missing questID provided to AreAllObjectivesCompleted:", tostring(questID))
        return false
    end

    local status, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not status or not objectives then
        RQE.infoLog("Failed to retrieve objectives for questID:", questID, "Error:", objectives)
        return false
    end

    for _, objective in ipairs(objectives) do
        if not objective.finished then
            RQE.infoLog("Not all objectives completed for questID:", questID)
            return false
        end
    end

    RQE.infoLog("All objectives completed for questID:", questID) -- Debug print for all objectives completed
    return true
end


-- Function that simulates a click of the UnknownQuestButton but streamlined
function RQE.ClickUnknownQuestButton()
	RQE.infoLog("Current state of RQE.hasClickedQuestButton: " .. tostring(RQE.hasClickedQuestButton))

	-- Validation check
	if not RQE.QuestIDText or not RQE.QuestIDText:GetText() then
		RQE.infoLog("QuestIDText is nil or empty. Cannot proceed.")
		return
	end

    local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
    local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

    if not RQE:AreAllObjectivesCompleted(questID) then
        return
    end
	
    if not questID then
        RQE.infoLog("No QuestID found. Cannot proceed.")
        return
    end

    if RQE.hasClickedQuestButton then
		RQE.infoLog("hasClickedQuestButton already clicked, skipping")
        return
    end

    local foundButton = false
    for i, button in ipairs(RQE.QuestLogIndexButtons) do
        if button and button.questID == questID then
			RQE.infoLog("Button successfully clicked")
            button:Click()
            RQE.hasClickedQuestButton = true
            foundButton = true
            break
        end
    end

    if not foundButton then
        RQE.infoLog("Did not find a button for questID:", questID)
    else	
        -- Ensure mapID is defined before calling CreateUnknownQuestWaypoint
		if not mapID then
			local mapID = C_Map.GetBestMapForUnit("player")
		else		
			RQE:CreateUnknownQuestWaypoint(questID, mapID)
		end
    end

    -- If the button wasn't found, print a message
    if not RQE.hasClickedQuestButton then
        RQE.infoLog("Did not find a button for questID:", questID)
    end
	
	-- Re-Track the quest being listed as super tracked
	C_SuperTrack.SetSuperTrackedQuestID(questID)
	
	-- Call your function to create a waypoint using stored coordinates and mapID
	RQE:CreateUnknownQuestWaypoint(questID, mapID)
end


-- Function to handle button clicks
function RQE:LFG_Search(questID)
    -- Open the Group Finder frame if it's not already open
    if not GroupFinderFrame:IsVisible() then
        LFGListUtil_OpenBestWindow()
    end

	-- Logic for searching for groups
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local questName = C_QuestLog.GetTitleForQuestID(questID)
	local activityID = C_LFGList.GetActivityIDForQuestID(questID)

	local categoryID = 3
	
    if not categoryID or categoryID == 0 then
        return
    end

	local languages = C_LFGList.GetLanguageSearchFilter()
	
    -- Set the search to the quest ID
    if questID then
        C_LFGList.SetSearchToQuestID(questID)
    end
	
	local filters = 0
	local preferredFilters = 0

    -- Accessing the search panel directly
    local SearchPanel = LFGListFrame.SearchPanel
	LFGListFrame_SetActivePanel(LFGListFrame, SearchPanel)
    LFGListSearchPanel_SetCategory(SearchPanel, categoryID, filters)
    LFGListSearchPanel_DoSearch(SearchPanel)
end


-- Function to handle button clicks
function RQE:LFG_Create(questID)
	-- Logic for creating a group
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local questName = C_QuestLog.GetTitleForQuestID(questID)
	local activityID = C_LFGList.GetActivityIDForQuestID(questID)
	local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
	local currentAreaActivities = C_LFGList.GetActivityInfoExpensive(activityID)
	local playerIlvl = GetAverageItemLevel()
	local minIlvlReq = UnitLevel('player') >= 60 and 120 or 50
	local itemLevel = minIlvlReq > playerIlvl and math.floor(playerIlvl) or minIlvlReq
	local honorLevel = 0
	local autoAccept = true
	local privateGroup = false

	C_LFGList.CreateListing(activityID, itemLevel, honorLevel, autoAccept, privateGroup, questID)
end


-- Function to handle button clicks
function RQE:LFG_Delist(questID)
	C_LFGList.RemoveListing();
end


-- Set the script for the button
RQE.SearchGroupButton:SetScript("OnClick", SearchGroupButton_OnClick)


-- Register frame for event handling
local eventFrame = CreateFrame("Frame")

-- Define the function to show the role selection dialog
function RQEShowRoleSelection(activityID)
	ResetLFGRoles()
    -- if LFGListApplicationDialog then
        -- LFGListApplicationDialog_Show(LFGListApplicationDialog, activityID)
    -- end
end

-- -- Global variable to keep track of the last known group size and type
-- local lastGroupSize = 0
-- local lastGroupType = "none" -- "none", "party", "raid", "instance"

-- Update lastGroupSize on GROUP_ROSTER_UPDATE
-- Function to update the group size and type
function RQEUpdateGroupSizeAndType()
    local isInRaid = IsInRaid()
    local isInGroup = IsInGroup()
    local isInstanceGroup = IsInInstance()
    local groupSize = GetNumGroupMembers()
	local availTank, availHealer, availDPS = C_LFGList.GetAvailableRoles()

    if isInRaid then
        lastGroupType = "raid"
    elseif isInGroup then
        lastGroupType = "party"
    elseif isInstanceGroup then
        lastGroupType = "instance"
    else
        lastGroupType = "none"
    end

    lastGroupSize = groupSize
end

-- Define the function to handle GROUP_ROSTER_UPDATE event
function RQEOnGroupRosterUpdate()
    local isInGroup = IsInGroup()
    local isInRaid = IsInRaid()
    local isInstanceGroup = IsInInstance()

    -- Trigger the role selection only if the player was in an outdoor raid group
	if lastGroupType == "raid" and not isInGroup and not isInRaid and not isInstanceGroup then
    --if lastGroupType == "raid" and not isInGroup and not isInRaid and not isInstanceGroup and (availTank or availHealer or (availDPS and not (availTank and availHealer))) then
        -- The player has left an outdoor raid group, show the role selection dialog
        -- Ensure 'activityID' is defined appropriately
        RQEShowRoleSelection(activityID)
    end

    -- Update the group size and type for the next check
    RQEUpdateGroupSizeAndType()
end

-- Register the GROUP_ROSTER_UPDATE event
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Set the script handler for the event
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        RQEOnGroupRosterUpdate()
    end
end)


-- Function to clear StepsText in RQEFrame.lua
function RQE:ClearStepsTextInFrame()
	if self.StepsText then
		for i, textElement in ipairs(self.StepsText) do
			textElement:SetText("")  -- Clear the text
		end
	end
end
	
	
-- Function to initialize dropdown items
function RQEFrame:InitializeDropdown()
    local info = UIDropDownMenu_CreateInfo()
    for i, result in ipairs(self.searchResults or {}) do
        info.text = result
        info.func = self.OnSearchResultClicked
        UIDropDownMenu_AddButton(info)
    end
end


-- Function to update the content size dynamically based on the number of steps
function RQE:UpdateContentSize()
    local n = #self.StepsText  -- The number of steps
    local totalHeight = 25 + 25 + (35 * n) + (35 * n) + 30 * (n - 1)
    content:SetHeight(totalHeight)
	slider:SetMinMaxValues(0, content:GetHeight())
end


---------------------------
-- 8. Finalization
---------------------------

-- Call to function create the search frame
CreateSearchFrame()

-- Define the function to save frame position
function RQE:SaveFramePosition()
	local yourProfile = RQE.db:GetCurrentProfile()

	-- Ensure framePosition table exists
	if not RQE.db.profile.framePosition then
		RQE.db.profile.framePosition = {}
	end

	-- Get the current frame position
	local point, _, relativePoint, xOfs, yOfs = RQEFrame:GetPoint()

	-- Save the frame position
	RQE.db.profile.framePosition.xPos = xOfs
	RQE.db.profile.framePosition.yPos = yOfs
end


-- Define the function to save frame position
function SaveRQEFrameSize()
    local width, height = RQEFrame:GetSize()
    RQE.db.profile.framePosition.frameWidth = width
    RQE.db.profile.framePosition.frameHeight = height
end


-- Enable dragging the frame by the header
header:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and RQEFrame:IsMovable() then
        RQEFrame:StartMoving()
    end
end)

header:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        RQEFrame:StopMovingOrSizing()
        RQE:SaveFramePosition()  -- Call the function to save the frame's position
    end
end)


-- Create a resize grip
RQE.resizeGrip = CreateFrame("Button", nil, RQEFrame)
RQE.resizeGrip:SetPoint("BOTTOMRIGHT", -5, 5)
RQE.resizeGrip:SetSize(16, 16)
RQE.resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
RQE.resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
RQE.resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")


-- Add mouse down event for the resize grip
RQE.resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and RQEFrame:IsResizable() then
        RQEFrame:StartSizing("BOTTOMRIGHT")
    end
end)


-- Mouse Event Handler for Resizing
RQE.resizeGrip:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        RQEFrame:StopMovingOrSizing()
		AdjustRQEFrameWidths()
		SaveRQEFrameSize()
    end
end)


-- Toggle function
function RQE.ToggleFrameLock()
    if isFrameLocked then
        RQEFrame:EnableMouse(true)  -- Keep this true to still capture right-clicks
        RQEFrame:SetMovable(true)
        RQEFrame:SetResizable(true)
        RQEFrame:RegisterForDrag("LeftButton")
        RQEFrame:SetScript("OnDragStart", RQEFrame.StartMoving)
        RQEFrame:SetScript("OnDragStop", function()
            RQEFrame:StopMovingOrSizing()
            RQE:SaveFramePosition()
        end)
        RQE.resizeGrip:Show()
    else
        RQEFrame:EnableMouse(true)  -- Keep this true to still capture right-clicks
        RQEFrame:SetMovable(false)
        RQEFrame:SetResizable(false)
        RQEFrame:SetScript("OnDragStart", nil)
        RQEFrame:SetScript("OnDragStop", nil)
        RQE.resizeGrip:Hide()
    end
    isFrameLocked = not isFrameLocked
    UpdateMenuText()  -- Make sure this function is called here
end


-- Initialize frame lock state
RQE.ToggleFrameLock()