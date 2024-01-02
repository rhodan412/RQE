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
    -- Add more options here if needed
}


-- Function to update the menu text
function UpdateMenuText()
    if isFrameLocked then
        frameMenu[2].text = "Unlock Frame"
    else
        frameMenu[2].text = "Lock Frame"
    end
end


-- Menu Frame Creation
local menuFrame = CreateFrame("Frame", "RQEFrameMenu", UIParent, "UIDropDownMenuTemplate")


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
    table.insert(menu, { text = "Abandon Quest", func = function() C_QuestLog.SetAbandonQuest(); C_QuestLog.AbandonQuest(); end })

    local menuFrame = CreateFrame("Frame", "RQEQuestDropdown", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end



---------------------------
-- 2. Imports
---------------------------

local AceGUI = LibStub("AceGUI-3.0")

---------------------------
-- 3. Frame Initialization
---------------------------

-- Debug to check state of main Frame
RQE.debugLog("Value of RQE.db", RQE.db)
if RQE and RQE.db and RQE.db.profile then
    RQE.debugLog("RQEFrame.lua loaded. Checking state of isMinimized:", RQE.db.profile.isMinimized)
else
    RQE.debugLog("RQE, RQE.db, or RQE.db.profile is nil.")
end


-- Create the main frame
_G["RQEFrame"] = CreateFrame("Frame", "RQEFrame", UIParent, "BackdropTemplate")
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
RQEFrame:SetBackdropColor(0, 0, 0, 0.5)


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
RQE.UnknownQuestButton:SetSize(30, 30)  -- Set size to 30x30
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

-- Add bg to the global RQE table
RQE.bg = bg

-- Add mouseover tooltip (functions listed in WPUtil.lua)
RQE.UnknownButtonTooltip()

-- Hide the tooltip when the mouse leaves
RQE.HideUnknownButtonTooltip()

-- Add a mouse down event to simulate a button press
RQE.UnknownQuestButtonMouseDown()

-- Add a mouse up event to reset the texture
RQE.UnknownQuestButtonMouseUp()

-- Assume IsWorldMapOpen() returns true if the world map is open, false otherwise
-- Assume CloseWorldMap() closes the world map
RQE.UnknownQuestButtonCalcNTrack()


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
RQE.QuestNameText:SetWidth(RQEFrame:GetWidth() - 20)
RQE.QuestNameText:SetHeight(0)
RQE.QuestNameText:EnableMouse(true)


-- Create DirectionTextFrame
RQE.DirectionTextFrame = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Set the anchor point relative to QuestIDText
RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.QuestIDText, "BOTTOMLEFT", -35, -13)

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
RQE.DirectionTextFrame:SetWidth(RQEFrame:GetWidth() - 20)
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

-- Function to Update QuestDescription
function RQE:UpdateQuestDescription()
    if RQEDatabase and RQEDatabase[currentQuestID] then
        local questDescription = RQEDatabase[currentQuestID].description
        RQE.QuestDescription:SetText(questDescription)
    else
        -- Handle the case where the quest ID is not found in the database
        RQE.QuestDescription:SetText("Quest information not available.")
    end
end

-- Call this function to initially set the text
RQE:UpdateQuestDescription()

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
RQE.QuestDescription:SetWidth(RQEFrame:GetWidth() - 20)
RQE.QuestDescription:SetHeight(0)
RQE.QuestDescription:EnableMouse(true)


-- Create QuestObjectives Text
RQEFrame.QuestObjectives = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RQE.QuestObjectives = RQEFrame.QuestObjectives

-- Check if QuestDescription is empty
if RQE.QuestDescription:GetText() == "" then
    -- If QuestDescription is empty, anchor QuestObjectives to DirectionTextFrame
    RQE.QuestObjectives:SetPoint("TOPLEFT", RQE.DirectionTextFrame, "BOTTOMLEFT", 0, 5)
else
    -- If QuestDescription has content, anchor QuestObjectives to QuestDescription
    RQE.QuestObjectives:SetPoint("TOPLEFT", RQE.QuestDescription, "BOTTOMLEFT", 0, -12)
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
RQE.QuestObjectives:SetWidth(RQEFrame:GetWidth() - 20)
RQE.QuestObjectives:SetHeight(0)
RQE.QuestObjectives:EnableMouse(true)


-- Display MapID with Tracker Frame
local MapIDText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
MapIDText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 15, 15)  -- Adjust the offsets as needed (-15, 20 was a little too high on the Y)
MapIDText:SetText("")
RQEFrame.MapIDText = MapIDText


-- Create Font String for Coordinates
local CoordinatesText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CoordinatesText:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -15, 15)  -- Adjust the offsets as needed
CoordinatesText:SetText("")
RQEFrame.CoordinatesText = CoordinatesText


-- Create buttons using functions from Buttons.lua
RQE.Buttons.CreateClearButton(RQEFrame, "TOPLEFT")
RQE.Buttons.CreateRWButton(RQEFrame, "ClearButton")
RQE.Buttons.CreateSearchButton(RQEFrame, "RWButton")
RQE.Buttons.CreateQMButton(RQEFrame, "SearchButton")
RQE.Buttons.CreateCloseButton(RQEFrame, "TOPRIGHT")
RQE.Buttons.CreateMaximizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider, "CloseButton")
RQE.Buttons.CreateMinimizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider, "MaximizeButton")


-- Create the ">" button
local searchExecuteButton = CreateFrame("Button", nil, SearchFrame, "UIPanelButtonTemplate")
searchExecuteButton:SetSize(18, 18)
searchExecuteButton:SetPoint("LEFT", searchEditBox, "RIGHT", 5, 0)
searchExecuteButton:SetText(">")

---------------------------
-- 5. Event Handlers
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
    local newWidth = width - 45  -- Adjust the padding as needed
    RQE.debugLog("OnSizeChanged: New width is " .. newWidth)

    RQE.QuestIDText:SetWidth(newWidth)
    if RQE.QuestNameText then
        RQE.QuestNameText:SetWidth(newWidth)
    else
        RQE.debugLog("RQE.QuestNameText is not initialized.")
    end
	
    -- Update widths
    RQE.QuestNameText:SetWidth(newWidth)
    RQE.DirectionTextFrame:SetWidth(newWidth)
    RQE.QuestDescription:SetWidth(newWidth)
    RQE.QuestObjectives:SetWidth(newWidth)
    
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


-- Function to open the quest log and show specific quest details
function OpenQuestLogToQuestDetails(questID)
    local mapID = GetQuestUiMapID(questID)
    if mapID == 0 then mapID = nil end
    OpenQuestLog(mapID)
    QuestMapFrame_ShowQuestDetails(questID)
end



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
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT", -50, -40)
    GameTooltip:SetMinimumWidth(350)
    GameTooltip:SetHeight(0)
    GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")
    GameTooltip:SetText(C_QuestLog.GetTitleForQuestID(questID))  -- Display quest name

    GameTooltip:AddLine(" ")  -- Add line break
	
	-- Add description
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
	if questLogIndex then
		local _, questObjectives = GetQuestLogQuestText(questLogIndex)
		local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
		GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
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

    -- Add Rewards
    AddQuestRewardsToTooltip(GameTooltip, questID)  -- Assuming AddQuestRewardsToTooltip is defined
    GameTooltip:AddLine(" ")

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


-- Function to reposition text elements upon frame resizing
local function OnFrameResized(self)
    local newWidth, newHeight = self:GetSize()
    
    -- Update the width for word wrapping
    if self.StepsText then  -- Add this check
        for i, textElement in ipairs(self.StepsText) do
            textElement:SetWidth(newWidth - 30)  -- Adjust the width based on your preference
        end
    end
end


-- Callback function to handle coordinate clicks
function RQEFrame:OnCoordinateClicked(x, y)
    -- Your code to handle the coordinate click event
end


-- Optional: Update the scrollbar when mousewheel is used on the ScrollFrame
ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local value = slider:GetValue()
    if delta > 0 then
        slider:SetValue(value - 20)
    else
        slider:SetValue(value + 20)
    end
end)

---------------------------
-- 6. Utility Functions
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
            print("Quest information not available for Quest ID: " .. questID)
            return
        end

        self:DisplayQuestDataInRQEFrame(questTitle, questDetail, questObjectives)
    end)
end



-- Function to dynamically create StepsText and CoordsText elements
function RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
	-- Initialize an array to store the heights
	local stepTextHeights = {}
	local yOffset = -20  -- Vertical distance you want to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
	local baseYOffset = -20  -- Vertical distance you want to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
	
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
		stepTextHeight = 0
		local yOffset = -20  -- Vertical distance you want to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
		local baseYOffset = -20  -- Vertical distance you want to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
	
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
		bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")

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
			local x, y = string.match(CoordsText[i], "([^,]+),%s*([^,]+)")
			x, y = tonumber(x), tonumber(y)
			local mapID = MapIDs[i]  -- Fetch the mapID from the MapIDs array
            
            -- Call your function to handle the coordinate click
            RQE:OnCoordinateClicked(x, y, mapID)
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
			GameTooltip:SetText(CoordText[i] or "No coordinates available.")
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
    local totalHeight = 20 + 20 + (20 * n) + (20 * n) + 10 * (n - 1)
    content:SetHeight(totalHeight)
end


-- Dummy function for adding quest steps, to be populated later
function AddQuestStepsToFrame(questSteps)
    -- Add quest steps to RQEFrame
end

---------------------------
-- 7. Finalization
---------------------------

-- Call to function create the search frame
CreateSearchFrame()

-- Define the function to save frame position
function SaveFramePosition()
    
    local yourProfile = RQE.db:GetCurrentProfile()
  
    -- Get the current frame position
    local point, _, relativePoint, xOfs, yOfs = RQEFrame:GetPoint()

    -- Save the frame position
    RQE.db.profile.framePosition.xPos = xOfs
    RQE.db.profile.framePosition.yPos = yOfs

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
        SaveFramePosition()  -- Call the function to save the frame's position
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
            SaveFramePosition()
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