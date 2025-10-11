--[[ 

RQEFrame.lua
Manages the main frame design

]]


----------------------------
-- 1. Global Declarations
----------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	print("RQE or RQE.debugLog is not initialized.")
end

RQE.Buttons = RQE.Buttons or {}
RQE.WaypointButtonIndices = {}
RQE.Frame = RQE.Frame or {}
RQE.lastKnownObjectiveIndex = RQE.lastKnownObjectiveIndex or {}

RQEDatabase = RQEDatabase or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}
RQE.debugLog("RQE.db and RQE.db.profile loaded in RQEFrame.lua")

-- When setting up the frame size based on isMinimized
if RQE.db and RQE.db.profile.isMinimized then  -- Using AceDB profile storage
	-- Logic to minimize the frame
else
	-- Logic to maximize the frame
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


--------------------------
-- 2. Local Variables
--------------------------

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
	MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
		local isPlayerInGroup = IsInGroup()
		local isQuestShareable = C_QuestLog.IsPushableQuest(questID)

		rootDescription:CreateButton("Set Waypoint to Closest Flight Master", function() RQE:SetTomTomWaypointToClosestFlightMaster() end)
		rootDescription:CreateButton("|cff888888-----------------------------------|r", function() end)

		if isPlayerInGroup and isQuestShareable then
			rootDescription:CreateButton("Share Quest", function() C_QuestLog.SetSelectedQuest(questID); QuestLogPushQuest(); end)
		end

		rootDescription:CreateButton("Untrack Quest", function() C_QuestLog.RemoveQuestWatch(questID); RQE:ClearFrameData(); end)
		rootDescription:CreateButton("Abandon Quest", function() RQE:AbandonQuest(questID); end)
		rootDescription:CreateButton("View Quest", function() OpenQuestLogToQuestDetails(questID) end)

		local uiMapID = C_Map.GetBestMapForUnit("player")
		local questLineInfo = C_QuestLine.GetQuestLineInfo(questID, uiMapID)
		if questLineInfo and questLineInfo.questLineID then
			RQE.PrintQuestDetails = 1
			RQE.RePrintQuestDetailAttempts = 0
			RQE.PrintQuestDetailsSuccess = false
			RQE.PrintQuestLineFailed = false
			rootDescription:CreateButton("Print Questline", function() RQE.PrintQuestlineDetails(questLineInfo.questLineID) end)
		end

		rootDescription:CreateButton("Show Wowhead Link", function() RQE:ShowWowheadLink(questID) end)
		rootDescription:CreateButton("Search Warcraft Wiki", function() RQE:ShowWowWikiLink(questID) end)
		rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)
	end)
end


-- Function to Show Right-Click Dropdown Menu
function ShowDropdownRQEFrame(self)
	MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
		rootDescription:CreateButton("Set Waypoint to Closest Flight Master", function() RQE:SetTomTomWaypointToClosestFlightMaster() end)

		-- Only show RQE buttons if the RQE_Contribution addon is loaded
		if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
			rootDescription:CreateButton("Track Quests in DB without Steps", function() RQE.TrackDBQuestsWithoutSteps() end)
			rootDescription:CreateButton("Track Quests in DB with Steps", function() RQE.TrackDBQuestsWithSteps() end)
			rootDescription:CreateButton("Track Quests Not in DB", function() RQE.TrackQuestsNotInDB() end)
			rootDescription:CreateButton("|cff888888----------------------------------|r", function() end)
		end

		rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)
	end)
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
RQEFrame:SetSize(420, 300)
local xPos, yPos
if RQE and RQE.db and RQE.db.profile and RQE.db.profile.framePosition then
	xPos = RQE.db.profile.framePosition.xPos or 40 --810
	yPos = RQE.db.profile.framePosition.yPos or -285 --165
else
	xPos = 40 --810
	yPos = -285 --165
end
RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
RQEFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 0, right = 0, top = 1, bottom = 0 }
})
RQEFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.MainFrameOpacity)
RQE.OnCoordinateClicked = RQE.OnCoordinateClicked or function() end


-- Create the ScrollFrame
local ScrollFrame = CreateFrame("ScrollFrame", nil, RQEFrame)
ScrollFrame:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 10, -40)  -- Adjusted Y-position
ScrollFrame:SetPoint("BOTTOMRIGHT", RQEFrame, "BOTTOMRIGHT", -30, 10)
ScrollFrame:EnableMouseWheel(true)
ScrollFrame:SetClipsChildren(true)  -- Must remain 'true' as it will otherwise cause the SeparateFocusFrame to overlap into the RQEQuestFrame!!
RQE.ScrollFrame = ScrollFrame


-- Create the content frame
local content = CreateFrame("Frame", nil, ScrollFrame)
RQE.content = content
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
RQE.RQEFrameHeader = header


-- Create header text
local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("CENTER", header, "CENTER")
headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
headerText:SetTextColor(239/255, 191/255, 90/255)
headerText:SetText("RQE Quest Helper")
headerText:SetWordWrap(true)
RQE.headerText = headerText


-- Create the Slider (Scrollbar)
---@class RQESlider : Slider
---@field slider.scrollStep number
-- local slider = CreateFrame("Slider", nil, ScrollFrame, "MinimalScrollBarWithBorderTemplate")
-- RQE.slider = slider
-- slider:SetPoint("TOPLEFT", RQEFrame, "TOPRIGHT", -20, -55)
-- slider:SetPoint("BOTTOMLEFT", RQEFrame, "BOTTOMRIGHT", -20, 45)
-- slider:SetMinMaxValues(0, content:GetHeight())
-- slider:SetValueStep(0.3)
-- slider.scrollStep = 1

-- slider:SetScript("OnValueChanged", function(self, value)
	-- ScrollFrame:SetVerticalScroll(value)
-- end)


-- Create the Slider (Scrollbar)
local slider = CreateFrame("Slider", nil, ScrollFrame)
RQE.slider = slider
slider:SetPoint("TOPLEFT", RQEFrame, "TOPRIGHT", -20, -55)
slider:SetPoint("BOTTOMLEFT", RQEFrame, "BOTTOMRIGHT", -20, 45)
slider:SetMinMaxValues(0, content:GetHeight())
slider:SetValueStep(0.2)
slider.scrollStep = 1
slider:SetWidth(12)  -- Set the width of the scrollbar

-- Set a custom background for the scrollbar
local bg = slider:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(slider)
bg:SetColorTexture(0.15, 0.15, 0.15, 0.65) -- A dark gray, semi-transparent background

-- Set a custom thumb texture for the scrollbar
local thumb = slider:CreateTexture(nil, "OVERLAY")
thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal") -- A custom thumb texture
--thumb:SetTexture("Interface\\AddOns\\RQE\\Textures\\YourCustomThumbTexture")
thumb:SetSize(12, 12)
slider:SetThumbTexture(thumb)

-- Add up and down arrow buttons to the scrollbar (optional)
local upButton = CreateFrame("Button", nil, slider, "UIPanelScrollUpButtonTemplate")
upButton:SetPoint("BOTTOM", slider, "TOP", 0, 0)
upButton:SetScript("OnClick", function()
	slider:SetValue(slider:GetValue() - 20) -- Scroll up by a set amount
end)

local downButton = CreateFrame("Button", nil, slider, "UIPanelScrollDownButtonTemplate")
downButton:SetPoint("TOP", slider, "BOTTOM", 0, 0)
downButton:SetScript("OnClick", function()
	slider:SetValue(slider:GetValue() + 20) -- Scroll down by a set amount
end)


-- Ensure the thumb texture is created correctly
local thumb = slider:CreateTexture(nil, "OVERLAY")
thumb:SetSize(16, 32)  -- Adjust the size as needed
thumb:SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")  -- Use any texture you want
slider:SetThumbTexture(thumb)

-- Create the Animation Group for the thumb
local animGroup = thumb:CreateAnimationGroup()

-- Create an Alpha Animation within the group
local pulse = animGroup:CreateAnimation("Alpha")
pulse:SetFromAlpha(1) -- Start from fully opaque
pulse:SetToAlpha(0.5) -- Fade to 50% opacity
pulse:SetDuration(0.5) -- Duration of the fade
pulse:SetSmoothing("IN_OUT") -- Smooth the animation

-- Set the looping mode on the animation group
animGroup:SetLooping("BOUNCE")

-- Start the animation when the mouse enters the scrollbar
slider:SetScript("OnEnter", function(self)
	RQE:UpdateContentSize()
	animGroup:Play()
end)

-- Stop the animation when the mouse leaves the scrollbar
slider:SetScript("OnLeave", function(self)
	animGroup:Stop()
end)

slider:SetScript("OnValueChanged", function(self, value)
	ScrollFrame:SetVerticalScroll(value)
end)

-- Right-Click Event Logic
RQEFrame:SetScript("OnMouseUp", function(self, button)
	if button == "RightButton" then
		-- EasyMenu(frameMenu, menuFrame, "cursor", 0 , 0, "MENU")
		ShowDropdownRQEFrame()
	end
end)


-- Function that Scrolls the RQEFrame to the top as long as player doesn't have mouse in RQEFrame window
function RQE.ScrollFrameToTop()
	if RQEFrame and not RQEFrame:IsMouseOver() then
		if ScrollFrame and slider then
			ScrollFrame:SetVerticalScroll(0)  -- Set the scroll position to the top
			slider:SetValue(0)  -- Also set the slider to the top position
		end
	end
end


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
	"Shift Lt Click: Delist Group"
})


-- Add a mouse down event to simulate a button press
RQE.UnknownQuestButtonMouseDown()
RQE.SearchGroupButtonMouseDown()


-- Add a mouse up event to reset the texture
RQE.UnknownQuestButtonMouseUp()


-- Function to Colorize the RQEFrame Quest Helper Module
local function colorizeObjectives(questID)
	local objectivesData = C_QuestLog.GetQuestObjectives(questID)
	local colorizedText = ""

	for _, objective in ipairs(objectivesData) do
		local description = objective.text
		if objective.finished then
			-- Objective complete, colorize in green
			colorizedText = colorizedText .. "|cff00ff00" .. description .. "|r\n"
		elseif objective.numFulfilled > 0 then
			-- Objective partially complete, colorize in yellow
			colorizedText = colorizedText .. "|cffffff00" .. description .. "|r\n"
		else
			-- Objective has not started or no progress, leave as white
			colorizedText = colorizedText .. "|cffffffff" .. description .. "|r\n"
		end
	end

	return colorizedText
end


-- Create QuestID Text
RQE.QuestIDText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- Debug: Check if settings are properly initialized
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
	local QuestIDText_settings = RQE.db.profile.textSettings.QuestIDText

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
		RQE.QuestIDText:SetTextColor(table.unpack(RQE.db.profile.textSettings.QuestIDText.color))
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
		RQE.QuestNameText:SetTextColor(table.unpack(QuestNameText_settings.color))
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
		RQE.DirectionTextFrame:SetTextColor(table.unpack(DirectionTextFrame_settings.color or {1, 1, 0.85}))
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


-- Debug: Check if settings are properly initialized
if QuestDescription_settings then
	RQE.QuestDescription:SetFont(QuestDescription_settings.font or "Fonts\\FRIZQT__.TTF", QuestDescription_settings.size or 14)

	if QuestDescription_settings.color then
		RQE.QuestDescription:SetTextColor(table.unpack(QuestDescription_settings.color or {0, 1, 0.6}))
	end
end

-- Hook SetText so we can truncate before displaying
local oldSetText = RQE.QuestDescription.SetText
function RQE.QuestDescription:SetText(text)
	if type(text) == "string" and text ~= "" then
		-- Step 1: Isolate only the first paragraph
		local firstPara, rest = text:match("^(.-)\r?\n\r?\n(.*)")
		if not firstPara then
			firstPara, rest = text:match("^([^\r\n]+)[\r\n]+(.*)")
		end
		if not firstPara then
			firstPara, rest = text, nil
		end

		-- Step 2: Trim trailing spaces/punctuation
		firstPara = firstPara:gsub("[%s%.]+$", "")

		-- Step 3: Enforce 100 character max
		local truncated = firstPara
		local tooLong = false
		if #truncated > 100 then
			truncated = truncated:sub(1, 100):gsub("[%s%.]+$", "")
			tooLong = true
		end

		-- Step 4: Append "..." if more content exists OR if trimmed by char limit
		if (rest and #rest > 0) or tooLong then
			truncated = truncated .. "..."
		end

		return oldSetText(self, truncated)
	end

	return oldSetText(self, text)
end

RQE.QuestDescription:SetJustifyH("LEFT")
RQE.QuestDescription:SetJustifyV("TOP")
RQE.QuestDescription:SetWordWrap(true)
RQE.QuestDescription:SetWidth(RQEFrame:GetWidth() - 35)
RQE.QuestDescription:SetHeight(0)
RQE.QuestDescription:EnableMouse(true)


-- Create QuestObjectives Text
local QuestObjectives = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
RQE.QuestObjectives = QuestObjectives


-- Check if QuestDescription is empty
-- Check if RQE.QuestDescription has text and is shown
-- If QuestDescription is already visible at the time of this code execution,
-- Sets initial position of QuestObjectives.
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
		RQE.QuestObjectives:SetTextColor(table.unpack(QuestObjectives_settings.color or {0, 1, 0.6}))
	end
end

RQE.QuestObjectives:SetJustifyH("LEFT")
RQE.QuestObjectives:SetJustifyV("TOP")
RQE.QuestObjectives:SetWordWrap(true)
RQE.QuestObjectives:SetWidth(RQEFrame:GetWidth() - 35)
RQE.QuestObjectives:SetHeight(0)
RQE.QuestObjectives:EnableMouse(true)


-- Display MapID with Tracker Frame
---@class RQEFrame : Frame
---@field MapIDText FontString
RQEFrame = RQEFrame or CreateFrame("Frame", "RQEFrame", UIParent, "BackdropTemplate")

local MapIDText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
if MapIDText then
	MapIDText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 15, 15)
	MapIDText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
	MapIDText:SetText("Map ID: " .. tostring(C_Map.GetBestMapForUnit("player")))
end
RQEFrame.MapIDText = MapIDText


-- Create Font String for Coordinates
local CoordinatesText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
if CoordinatesText then
	CoordinatesText:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -15, 15)  -- Adjust the offsets as needed
	CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
	CoordinatesText:SetText("")
end
RQEFrame.CoordinatesText = CoordinatesText


-- Create Font String for Addon Memory Usage
local MemoryUsageText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
if MemoryUsageText then
	MemoryUsageText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 15, 35)  -- Position it right above the MapIDText
	MemoryUsageText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
	MemoryUsageText:SetTextColor(231/255, 120/255, 120/255)
end
RQEFrame.MemoryUsageText = MemoryUsageText


-- Create Font String for Addon CPU Usage
local CPUUsageText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
if CPUUsageText then
	CPUUsageText:SetPoint("TOPLEFT", RQEFrame.MemoryUsageText, "BOTTOMLEFT", 0, 35)  -- Position it above MemoryUsageText
	CPUUsageText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
	CPUUsageText:SetTextColor(120/255, 231/255, 120/255) -- Green color
end
RQEFrame.CPUUsageText = CPUUsageText


-- Create buttons using functions from Buttons.lua
RQE.Buttons.CreateClearButton(RQEFrame)
RQE.Buttons.CreateRWButton(RQEFrame)
RQE.Buttons.CreateSearchButton(RQEFrame)
RQE.Buttons.CreateQMButton(RQEFrame)
RQE.Buttons.CreateCloseButton(RQEFrame)
RQE.Buttons.CreateMaximizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider)
RQE.Buttons.CreateMinimizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider)


-- Magic Button
RQE.Buttons.CreateMagicButton(RQEFrame) --, "TOPRIGHT")


-- Create the ">" button
local searchExecuteButton = CreateFrame("Button", nil, RQEFrame.SearchFrame, "UIPanelButtonTemplate")
searchExecuteButton:SetSize(18, 18)
searchExecuteButton:SetPoint("LEFT", SearchEditBox, "RIGHT", 5, 0)
searchExecuteButton:SetText(">")

---------------------------
-- 6. Event Handlers
---------------------------

-- Function for Update Button Visibility
function UpdateButtonVisibility()
	if RQE.db.profile.isMinimized then
		RQE.MinimizeButton:Hide()
		RQE.MaximizeButton:Show()
	else
		RQE.MinimizeButton:Show()
		RQE.MaximizeButton:Hide()
	end

	-- Save the current minimized state to the SavedVariables
	RQEFrame.isMinimized = not RQEFrame.isMinimized
	RQE.db.profile.isMinimized = RQEFrame.isMinimized

	-- Add these lines for debugging
	local point, relativeTo, relativePoint, xOfs, yOfs = RQE.MinimizeButton:GetPoint()
	point, relativeTo, relativePoint, xOfs, yOfs = RQE.MaximizeButton:GetPoint()
end


-- Event to update text widths when the frame is resized
RQEFrame:SetScript("OnSizeChanged", function(self, width, height)
	local baseWidth = 400
	local paddingIncrement = (width - baseWidth) / 20
	local basePadding = 20 -- This is the base padding.
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


-- Add a click event to open the quest details for the current QuestID
RQE.QuestIDText:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" and not IsShiftKeyDown() then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		OpenQuestLogToQuestDetails(questID)
		return
	end
end)


-- Add a click event to open the map for the current QuestName
if RQE.QuestNameText then  -- Check if QuestNameText is initialized
	RQE.QuestNameText:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not IsShiftKeyDown() then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			OpenQuestLogToQuestDetails(questID)
			return
		end
	end)
else
	RQE.debugLog("RQE.QuestNameText is not initialized.")
end


-- Safe wrapper function that extracts the text from the new structure
function RQE.GetSeparateStepText()
	if not RQE.SeparateStepText then return "" end
	if RQE.SeparateStepText.GetText then
		return RQE.SeparateStepText:GetText() or ""
	elseif RQE.SeparateStepText._rqeSegments then
		local collected = {}
		for _, seg in ipairs(RQE.SeparateStepText._rqeSegments) do
			if seg:IsObjectType("FontString") then
				table.insert(collected, seg:GetText() or "")
			end
		end
		return table.concat(collected, "")
	end
	return ""
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

	local questData = RQE.getQuestData(effectiveQuestID)
	local questTitle = C_QuestLog.GetTitleForQuestID(questID)  -- = questData and questData.title or "Unknown Quest"
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
		-- Check if the quest is ready to be turned in
		if C_QuestLog.ReadyForTurnIn(questID) then
			GameTooltip:AddLine("Status: Ready for Turn In", 1, 1, 0) -- Yellow color for ready to turn in
		-- Check if the quest is completed
		elseif C_QuestLog.IsQuestFlaggedCompleted(questID) then
			GameTooltip:AddLine("Status: Completed", 0, 1, 0) -- Green color for completed
		else
			GameTooltip:AddLine("Status: Not Completed", 1, 0, 0) -- Red color for not completed
		end
		GameTooltip:AddLine(" ")
	end

	-- Add objectives
	local objectivesInfo = C_QuestLog.GetQuestObjectives(questID)
	if objectivesInfo and #objectivesInfo > 0 then
		GameTooltip:AddLine("Objectives:")

		-- Concatenate objectives into a string and colorize
		local objectivesText = ""
		for _, objective in ipairs(objectivesInfo) do
			objectivesText = objectivesText .. objective.text .. "\n"
		end

		local colorizedObjectives = RQE.colorizeObjectives(questID)
		--local colorizedObjectives = colorizeObjectives(questID)
		GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)  -- true for wrap
		GameTooltip:AddLine(" ")
	end

	if RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) and not isWorldQuest then
		-- Add code for the Rewards tooltip if this is a searched quest
	else
		-- Add Rewards
		RQE:QuestRewardsTooltip(GameTooltip, questID)
	end

	-- Check if RQE.SeparateStepText exists and has text
	if RQE.SeparateStepText and RQE.SeparateStepText:GetText() ~= "" then
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		if not isWorldQuest then
			GameTooltip:AddLine(" ")
		end
		GameTooltip:AddLine("|cfffffd9fQuest Help for Current Step:|r", 1, 1, 1, true) -- Canary title
		-- GameTooltip:AddLine("|cff00ffffQuest Help for Current Step:|r", 1, 1, 1, true) -- Cyan title
		GameTooltip:AddLine("|cffa9a9ff" .. RQE.GetSeparateStepText() .. "|r", nil, nil, nil, true)
		--GameTooltip:AddLine("|cffa9a9ff" .. RQE.SeparateStepText:GetText() .. "|r", nil, nil, nil, true) -- Light purple text
	else
		GameTooltip:AddLine("|cffff0000No additional focus data available.|r", 1, 1, 1, true) -- Default message in red
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
	RQE.QuestNameText:SetWidth(newWidth - dynamicPadding - 65)
	RQE.DirectionTextFrame:SetWidth(newWidth - dynamicPadding - 55)
	RQE.QuestDescription:SetWidth(newWidth - dynamicPadding - 45)
	RQE.QuestObjectives:SetWidth(newWidth - dynamicPadding - 45)

	RQE:UpdateContentSize()
end


-- Optional: Update the scrollbar when mouse wheel is used on the ScrollFrame
ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
	local value = slider:GetValue()
	if delta > 0 then
		slider:SetValue(value - 25) -- A Change from 20 to 25 on both slider SetValues increases the scroll speed
	else
		slider:SetValue(value + 25)
	end
	RQE:UpdateContentSize()
end)


-- Method to display a quest on RQEFrame
function RQEFrame:DisplayQuest(questID)
	-- Clear previous content if necessary
	if self.questText then
		self.questText:SetText("")
	else
		-- Create a FontString if it doesn't exist yet
		self.questText = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.questText:SetPoint("TOP", self, "TOP", 0, -50)  -- Position it within RQEFrame
		self.questText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		self.questText:SetTextColor(1, 1, 1)
	end

	-- Get quest title for the quest ID
	local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Quest not found"
	self.questText:SetText("Next quest: " .. questTitle)

	-- Optionally, display other quest details here
	print("Displaying quest:", questTitle)
end


---------------------------
-- 7. Utility Functions
---------------------------

-- Make this a global variable or part of the RQE table
RQE.isSearchFrameShown = false


-- Function to create the search frame
function CreateSearchFrame(showFrame)
	if not showFrame then
		if RQEFrame.SearchFrame then
			--RQEFrame.SearchFrame:Hide()  -- COMMENTING OUT DUE TO API ERROR
			RQEFrame.SearchFrame = nil
		end
		return
	end

	local SearchFrame = AceGUI:Create("Frame")
	if not SearchFrame then
		RQE.debugLog("Failed to create a GUI frame via AceGUI")
		return
	end

	SearchFrame:SetTitle("Search Frame")
	SearchFrame:SetWidth(400)
	SearchFrame:SetHeight(200)
	SearchFrame:SetLayout("Flow")
	SearchFrame:SetStatusText("Enter your search query")
	SearchFrame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		RQEFrame.SearchFrame = nil
	end)

	-- Assuming editBox and examineButton are created correctly
	local searchBox, examineButton = RQE.SearchModule:CreateSearchBox()
	SearchFrame:AddChild(searchBox)
	SearchFrame:AddChild(examineButton)

	-- Fixing the positioning issue
	SearchFrame.frame:ClearAllPoints()
	SearchFrame.frame:SetPoint("TOPRIGHT", RQEFrame, "TOPLEFT", 0, 0)

	-- Save reference to SearchFrame
	RQEFrame.SearchFrame = SearchFrame
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
--- @class WaypointButton : Button
--- @field stepIndex number
--- @field bg Texture
function RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
	-- Initialize an array to store the heights
	local stepTextHeights = {}
	RQE.CurrentQuestSteps = {}
	local yOffset = -20  -- Vertical distance to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
	local baseYOffset = -20

	-- 🧹 Create or reuse a dedicated container for hover buttons
	if not RQE.StepsHoverContainer then
		RQE.StepsHoverContainer = CreateFrame("Frame", "RQE_StepsHoverContainer", content)
		RQE.StepsHoverContainer:SetAllPoints(content)
	else
		-- Clean up any old children from the last quest
		for _, child in ipairs({RQE.StepsHoverContainer:GetChildren()}) do
			child:Hide()
			child:SetParent(nil)
		end
	end

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
		local stepTextHeight = 10

		-- Create StepsText
		local StepText = content:CreateFontString(nil, "OVERLAY")
		table.insert(RQE.StepsText, StepText)
		StepText:SetFont("Fonts\\FRIZQT__.TTF", 12)
		StepText:SetJustifyH("LEFT")
		StepText:SetTextColor(1, 1, 0.8) -- Text color for RQE.StepsText in RGB
		StepText:SetSize(350, 0) -- Controls length you have across the frame before it will force a line break
		StepText:SetHeight(0)  -- Auto height
		StepText:SetWordWrap(true)  -- Allow word wrap

		--StepText:SetText(StepsText[i] or "No description available.")

		local raw = StepsText[i] or "No description available."
		StepText:SetText("")  -- Clear main fontstring
		RQE.RenderTextWithItems(StepText, raw, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 0.8}, RQE.StepsHoverContainer)
		-- RQE.RenderTextWithItems(StepText, raw, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 0.8})

		StepText:SetWidth(RQEFrame:GetWidth() - 80)

		-- Create CoordsText
		local CoordText = content:CreateFontString(nil, "OVERLAY")
		table.insert(RQE.CoordsText, CoordText)

		if i == 1 then
			if RQE.SeparateFocusFrame then
				StepText:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "BOTTOMLEFT", 50, yOffset)
			elseif self.QuestObjectives then
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
		---@type WaypointButton
		local WaypointButton = CreateFrame("Button", nil, content)
		WaypointButton:SetPoint("TOPRIGHT", StepText, "TOPLEFT", -10, 10)
		WaypointButton:SetSize(30, 30)  -- Set size to 30x30

		-- Use the custom texture for the background
		local bg = WaypointButton:CreateTexture(nil, "BACKGROUND")  -- changed to WaypointButton from WaypointButtons
		bg:SetAllPoints()

		-- Check if autoClickWaypointButton is enabled and LastClickedIdentifier is nil and set to 1 if so
		if RQE.db.profile.autoClickWaypointButton then
			if not RQE.LastClickedIdentifier then
				RQE.LastClickedIdentifier = 1
			end
		end

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
			RQE.WaypointButtonHover = true
		end)

		-- Insert it into the RQE.WaypointButtons table
		table.insert(RQE.WaypointButtons, WaypointButton)
		RQE.WaypointButtonIndices[WaypointButton] = i	-- Store the index associated with the button

		-- Hide the tooltip when the mouse leaves
		WaypointButton:SetScript("OnLeave", function()
			RQE.WaypointButtonHover = false
			GameTooltip:Hide()
		end)

		-- Add the click event for WaypointButtons
		WaypointButton:SetScript("OnClick", function()
			if RQE.WaypointButtonHover then
				RQE:ClickWaypointButtonForIndex(i)
			end

			-- Code for RWButton functionality here
			local extractedQuestID
			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			end
			local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
			local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

			if questID then
				local waypointText = C_QuestLog.GetNextWaypointText(questID)
				if not waypointText then
					C_Map.ClearUserWaypoint()
				end
			end

			-- Check if TomTom is loaded and compatibility is enabled
			if C_AddOns.IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
				TomTom.waydb:ResetProfile()
				RQE._currentTomTomUID = nil
			end

			local x, y = string.match(CoordsText[i], "([^,]+),%s*([^,]+)")
			x, y = tonumber(x), tonumber(y)
			local mapID = MapIDs[i]		-- Fetch the mapID from the MapIDs array

			-- Call function to handle the coordinate click (IDEALLY IF MOUSE ACTUALLY CLICKS THE "W" BUTTON and may cause some post-combat lag)
			RQE.SaveCoordData()
			RQE:OnCoordinateClicked() --RQE:OnCoordinateClicked(i)

			-- This part resets the texture of the last clicked button, but also contains some checks for updating identifiers.
			if RQE.LastClickedWaypointButton and RQE.LastClickedWaypointButton ~= WaypointButton then
				RQE.LastClickedWaypointButton.bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
			end

			-- Update the texture of the currently clicked button
			bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")

			-- Use AddonSetStepIndex if available
			local effectiveStepIndex = RQE.AddonSetStepIndex or i

			-- Conditionally update LastClickedIdentifier only if the new step index is greater than the current
			if not RQE.LastClickedIdentifier or (RQE.LastClickedIdentifier ~= effectiveStepIndex and effectiveStepIndex > RQE.LastClickedIdentifier) then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Before update: LastClickedIdentifier:", RQE.LastClickedIdentifier)
					RQE.LastClickedIdentifier = effectiveStepIndex
					print("After update: LastClickedIdentifier:", RQE.LastClickedIdentifier)
				else
					RQE.LastClickedIdentifier = effectiveStepIndex
				end
			end

			-- Update WaypointButton stepIndex only if needed
			if WaypointButton.stepIndex and WaypointButton.stepIndex ~= effectiveStepIndex and effectiveStepIndex >= WaypointButton.stepIndex then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Before update: WaypointButton.stepIndex:", WaypointButton.stepIndex)
					WaypointButton.stepIndex = effectiveStepIndex
					print("After update: WaypointButton.stepIndex:", WaypointButton.stepIndex)
				else
					WaypointButton.stepIndex = effectiveStepIndex
				end
			end

			RQE.LastClickedButtonRef = WaypointButton

			-- Update the reference to the last clicked button
			RQE.LastClickedWaypointButton = WaypointButton
			RQE.LastClickedWaypointButton.bg = bg	-- Store the bg texture so it can be modified later

			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				RQE.questIDFromText = tonumber(RQE.QuestIDText:GetText():match("%d+"))
				if not RQE.questIDFromText then
					RQE.debugLog("Error: Invalid quest ID extracted from text")
				else
					RQE.infoLog("Quest ID from text for macro:", RQE.questIDFromText)	-- Debug message for the current operation

					-- Dynamically create/edit macro based on the super tracked quest and the step associated with the clicked waypoint button
					RQE.debugLog("Attempting to create macro")
				end
			end

			RQE.infoLog("Quest ID from text for macro:", RQE.questIDFromText)  -- Debug message for the current operation

			-- Check if MagicButton should be visible based on macro body
			C_Timer.After(1, function()
				RQE.Buttons.UpdateMagicButtonVisibility()
			end)

			local questData = RQE.getQuestData(RQE.questIDFromText)
			if questData then
				UpdateFrame(RQE.questIDFromText, questData, StepsText, CoordsText, MapIDs)
			end
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

		-- Add the mouse down event here
		StepText:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				-- Save the coordinates and mapID when the text is clicked
				RQE.SaveCoordData()

				-- Call function to handle the coordinate click
				RQE:OnCoordinateClicked()	--RQE:OnCoordinateClicked(i) -- Ensure stepIndex is passed here
			end
		end)
	end

	-- Updates the height of the RQEFrame based on the number of steps a quest has in the RQEDatabase
	C_Timer.After(0.5, function()
		RQE:UpdateContentSize()
	end)
end


-- Check and Advance Steps
function RQE:CheckAndAdvanceStep(questID)
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()	 -- TEMPORARILY COMMENTING OUT IN ORDER TO GET RQE:StartPeriodicChecks() OPERATIONAL
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
	local nextObjectiveIndex = highestCompletedObjectiveIndex + 1 -- Default to the next index (will show up as 100 if the quest is completed)

	-- Handle quest completion and specific objectives
	if allObjectivesCompleted or C_QuestLog.ReadyForTurnIn(questID) then
		nextObjectiveIndex = 99 -- Override if all objectives are completed
	end
end


-- Fetch the Objective Index for a particular quest
function RQE:GetCurrentObjectiveIndex(questID)
	local questData = RQEDatabase[questID]
	if not questData then
		RQE.infoLog("No data found for questID:", questID)
		return 0  -- Return 0 or an appropriate default value if no data is found
	end

	local highestIndex = 0
	for _, objectiveData in ipairs(questData) do
		if objectiveData.objectiveIndex and objectiveData.objectiveIndex > highestIndex then
			highestIndex = objectiveData.objectiveIndex
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


-- -- Simulate WaypointButton click for the next step upon completion of a quest objective and print debug statements
-- function RQE:ClickWaypointButtonForNextObjectiveIndex(nextObjectiveIndex, questData)
	-- -- If the quest is completed, prioritize clicking the button for objectiveIndex 99
	-- if nextObjectiveIndex == 99 then
		-- for stepIndex, stepData in ipairs(questData) do
			-- if stepData.objectiveIndex == 99 then
				-- local button = RQE.WaypointButtons[stepIndex]
				-- if button then
					-- RQE.infoLog("Quest is complete. Clicking WaypointButton for quest turn-in (ObjectiveIndex 99).")
					-- button:Click()
					-- RQE.lastClickedObjectiveIndex = 99

					-- -- Call to update the waypoint for the quest completion objective
					-- C_Timer.After(1, function()  -- Delay of 1 second
						-- RQE.ClickUnknownQuestButton()
					-- end)
					-- return
				-- end
			-- end
		-- end
	-- end

	-- -- Check if this is a new objectiveIndex, not the same as the last clicked one.
	-- if RQE.lastClickedObjectiveIndex == nextObjectiveIndex then
		-- RQE.infoLog("ObjectiveIndex " .. nextObjectiveIndex .. " was already clicked. Skipping.")
		-- return
	-- end

	-- for _, stepData in ipairs(questData) do
		-- if stepData.objectiveIndex == nextObjectiveIndex then
			-- local button = RQE.WaypointButtons[_] -- Assuming WaypointButtons are stored in a manner that mirrors questData
			-- if button then
				-- -- Simulate the click
				-- RQE.infoLog("Clicking WaypointButton for objectiveIndex:", nextObjectiveIndex)
				-- button:Click() -- `OnClick` will now use the button's direct data
				-- -- Update the lastClickedObjectiveIndex since we've moved to a new objective.
				-- RQE.lastClickedObjectiveIndex = nextObjectiveIndex

				-- -- Call to update the waypoint for the quest completion objective
				-- C_Timer.After(1, function()  -- Delay of 1 second
					-- RQE.ClickUnknownQuestButton()
				-- end)
				-- return
			-- end
		-- end
	-- end
	-- UpdateRQEQuestFrame()
	-- UpdateRQEWorldQuestFrame()
-- end


-- Function to check if all objectives for a given quest are completed
function RQE:AreAllObjectivesCompleted(questID)
	-- Check if questID is valid
	if not questID or type(questID) ~= "number" or questID <= 0 then
		return false
	end

	local status, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
	if not status or not objectives then
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
	RQE:QuestType() -- Runs UpdateRQEQuestFrame and UpdateRQEWorldQuestFrame as quest list is generated

	-- Validation check
	if not RQE.QuestIDText or not RQE.QuestIDText:GetText() then
		return
	end

	local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

	RQE:SaveSuperTrackedQuestToCharacter()

	-- Call function to create a waypoint using stored coordinates and mapID
	RQE:FindQuestZoneTransition(questID)
end


-- Function to handle group search based on the current super-tracked quest with fallback for missing activityID
function RQE:LFG_Search(questID)
	-- Ensure the Group Finder frame is open
	if not GroupFinderFrame:IsVisible() then
		LFGListUtil_OpenBestWindow() -- Open LFG window if it's not already visible
	end

	-- Retrieve the super-tracked quest ID
	local questID = questID or RQE.currentSuperTrackedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	if not questID or questID == 0 then
		return
	end

	-- Retrieve the activity ID for the quest
	local activityID = C_LFGList.GetActivityIDForQuestID(questID)
	local questName = C_TaskQuest.GetQuestInfoByQuestID(questID) or C_QuestLog.GetTitleForQuestID(questID)

	-- Set the search panel to the appropriate category
	local SearchPanel = LFGListFrame.SearchPanel
	LFGListFrame_SetActivePanel(LFGListFrame, SearchPanel)

	if questID == 81630 then -- 81630 questID is for 'Activation Protocol', which is the world boss at Isle of Dorn, 'Kordac'
		RQE.SearchCategory = 1
	else
		RQE.SearchCategory = 3
	end

	LFGListSearchPanel_SetCategory(SearchPanel, RQE.SearchCategory, 0)

	-- Set search criteria to the questID or fallback to the quest name if activityID is missing
	if activityID then
		C_LFGList.SetSearchToQuestID(questID)
	else
		-- Fallback: Search by quest name if activityID is unavailable or unreliable
		SearchPanel.SearchBox:SetText(questName or "")
		SearchPanel.SearchBox:ClearFocus()
	end

	-- Execute the search
	LFGListSearchPanel_DoSearch(SearchPanel)
end


-- Function to create a group for the current quest
function RQE:LFG_Create(questID)
	-- Determine the questID
	local questID = questID or RQE.currentSuperTrackedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	if not questID or questID == 0 then
		print("LFG_Create: Invalid or missing questID.")
		return
	end

	-- Retrieve the activity ID for the quest
	local activityID = C_LFGList.GetActivityIDForQuestID(questID)
	if not activityID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("LFG_Create: No activity ID found for questID", questID)
		end
		return
	end

	-- Define group listing parameters
	local playerIlvl = GetAverageItemLevel()
	local minIlvlReq = UnitLevel('player') >= 60 and 120 or 50
	local itemLevel = minIlvlReq > playerIlvl and math.floor(playerIlvl) or minIlvlReq
	local honorLevel = 0 -- Honor level requirement
	local autoAccept = true
	local privateGroup = false

	-- Create the `createData` table
	local createData = {
		activityIDs = { activityID }, -- Wrap the activity ID in a table
		questID = questID,
		isAutoAccept = autoAccept,
		isPrivateGroup = privateGroup,
		requiredItemLevel = itemLevel,
		requiredDungeonScore = 0, -- Optional; adjust as needed
		requiredPvpRating = honorLevel, -- Optional; adjust as needed
		playstyle = nil, -- Optional; can be adjusted based on group preferences
		isCrossFactionListing = false, -- Optional; adjust if cross-faction grouping is supported
	}

	-- Debugging output
	if RQE.db.profile.debugLevel == "INFO+" then
		print("LFG_Create Debugging:")
		for key, value in pairs(createData) do
			print("  " .. key .. ": " .. tostring(value) .. " (type: " .. type(value) .. ")")
		end
	end

	-- Attempt to create the group listing
	local success, err = pcall(C_LFGList.CreateListing, createData)

	if RQE.db.profile.debugLevel == "INFO+" then
		if not success then
			print("LFG_Create: Error creating group listing:", err)
		else
			print("LFG_Create: Group listing created successfully!")
		end
	end
end


-- Function to handle button clicks
function RQE:LFG_Delist(questID)
	C_LFGList.RemoveListing();
end


-- Register frame for event handling
local eventFrame = CreateFrame("Frame")


-- Define the function to show the role selection dialog
function RQEShowRoleSelection(activityID)
	ResetLFGRoles()
end


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

	local lastGroupSize = groupSize
end


-- Define the function to handle GROUP_ROSTER_UPDATE event
function RQEOnGroupRosterUpdate()
	local isInGroup = IsInGroup()
	local isInRaid = IsInRaid()
	local isInstanceGroup = IsInInstance()
	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Trigger the role selection only if the player was in an outdoor raid group
	if lastGroupType == "raid" and not isInGroup and not isInRaid and not isInstanceGroup then
		-- Ensure the questID is valid before proceeding
		if questID and questID > 0 then
			local activityID = C_LFGList.GetActivityIDForQuestID(questID)
			if activityID then
				RQEShowRoleSelection(activityID)
			else
				RQE.debugLog("No activity ID found for questID:", questID)
			end
		else
			RQE.debugLog("Invalid or missing questID:", questID)
		end
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
			textElement:SetText("")	-- Clear the text
		end
	end
end


-- Function to initialize dropdown items
function RQEFrame:InitializeDropdown()
	self.searchResults = self.searchResults or {}
	local info = UIDropDownMenu_CreateInfo()
	for i, result in ipairs(self.searchResults or {}) do
		info.text = result
		info.func = self.OnSearchResultClicked
		UIDropDownMenu_AddButton(info)
	end
end


-- Function to update the content size dynamically based on the number of steps
function RQE:UpdateContentSize()
	self.StepsText = self.StepsText or {}	-- Failsafe to ensure that table is loaded following VARIABLES_LOADED event firing

	local n = #self.StepsText	-- The number of steps
	local totalHeight = 110 + (40 * n) + (40 * n) + 40 * (n - 1) + 25
	content:SetHeight(totalHeight)
	slider:SetMinMaxValues(0, content:GetHeight())
end


---------------------------
-- 8. Finalization
---------------------------

-- Call to function create the search frame
CreateSearchFrame()

-- Event to update text widths when the frame is resized
RQEFrame:SetScript("OnSizeChanged", function(self, width, height)
	AdjustRQEFrameWidths()
	SaveRQEFrameSize()
end)


-- Calls function to save Quest Frame Position OnDragStop
RQEFrame:SetScript("OnDragStop", function()
	RQEFrame:StopMovingOrSizing()
	RQE:SaveFramePosition()  -- This will save the current frame position
end)


-- Define the function to save frame position
function RQE:SaveFramePosition()
	-- Defensive checks
	if not RQE.db or not RQE.db.profile then return end

	-- Load from profile
	local yourProfile = RQE.db:GetCurrentProfile()

	-- Ensure framePosition table exists
	if not RQE.db.profile.framePosition then
		RQE.db.profile.framePosition = {}
	end

	-- Get the current frame position
	local point, _, relativePoint, xOfs, yOfs = RQEFrame:GetPoint()

	-- Save the frame position with the anchor points and offsets
	RQE.db.profile.framePosition.point = point
	RQE.db.profile.framePosition.relativePoint = relativePoint
	RQE.db.profile.framePosition.xOffset = xOfs
	RQE.db.profile.framePosition.yOffset = yOfs
end


-- Restores the RQEFrame position based on DB
function RQE:RestoreFramePosition()
	local pos = RQE.db.profile.framePosition
	if pos and pos.point and pos.relativePoint and pos.xOffset and pos.yOffset then
		-- Restore the frame position using saved values
		RQEFrame:ClearAllPoints()
		RQEFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOffset, pos.yOffset)
	else
		-- Default position if saved values are missing or incomplete
		RQEFrame:ClearAllPoints()
		RQEFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end


-- Define the function to save frame position
function SaveRQEFrameSize()
	if not RQE.db or not RQE.db.profile then return end

	-- Ensure framePosition table exists
	if not RQE.db.profile.framePosition then
		RQE.db.profile.framePosition = {
			xPos = -40,
			yPos = -285,
			anchorPoint = "TOPRIGHT",
		}
	end

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


-- Function to initialize a separate Focused Step Frame with scrolling
function RQE.InitializeSeparateFocusFrame()
	-- Create the new independent frame
	if not RQE.SeparateFocusFrame then
		RQE.SeparateFocusFrame = CreateFrame("Frame", "RQE_SeparateFocusFrame", RQE.content, "BackdropTemplate")
		RQE.SeparateFocusFrame:SetSize(375, 100) -- Set the size of the frame
		RQE.SeparateFocusFrame:SetPoint("TOPLEFT", RQE.QuestObjectives, "BOTTOMLEFT", -5, -10)  -- Align closer to the edge
		RQE.SeparateFocusFrame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 0, right = 0, top = 1, bottom = 0 }
		})
		RQE.SeparateFocusFrame:SetBackdropColor(0, 0, 0, 0.4)
		RQE.SeparateFocusFrame:EnableMouse(true)
		RQE.SeparateFocusFrame:Show()
	end

	-- Create the scroll frame
	if not RQE.SeparateScrollFrame then
		RQE.SeparateScrollFrame = CreateFrame("ScrollFrame", "RQE_SeparateScrollFrame", RQE.SeparateFocusFrame, "UIPanelScrollFrameTemplate")
		RQE.SeparateScrollFrame:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "TOPLEFT", -5, -10)
		RQE.SeparateScrollFrame:SetPoint("BOTTOMRIGHT", RQE.SeparateFocusFrame, "BOTTOMRIGHT", -30, 10)
		RQE.SeparateScrollFrame:EnableMouseWheel(true)
		RQE.SeparateScrollFrame:SetClipsChildren(true)
		RQE.SeparateScrollFrame:Show()
	end

	-- Tooltip when hovering over the RQE.SeparateScrollFrame
	RQE.SeparateScrollFrame:SetScript("OnEnter", function(self)
		RQE.ShowFocusScrollFrameTooltip(RQEFrame) -- Call the function to show the tooltip anchored to RQEFrame
	end)

	RQE.SeparateScrollFrame:SetScript("OnLeave", RQE.HideFocusScrollFrameTooltip) -- Hide the tooltip when the mouse leaves the frame

	-- Create the content frame for the scroll frame
	if not RQE.SeparateContentFrame then
		RQE.SeparateContentFrame = CreateFrame("Frame", "RQE_SeparateContentFrame", RQE.SeparateScrollFrame)
		RQE.SeparateContentFrame:SetWidth(RQE.SeparateFocusFrame:GetWidth() - 40)  -- Adjust width for padding
		RQE.SeparateContentFrame:SetHeight(1000)  -- Initial height for content; will adjust dynamically
		RQE.SeparateScrollFrame:SetScrollChild(RQE.SeparateContentFrame)
		RQE.SeparateContentFrame:Show()
	end

	-- Function to update the content dynamically
	function RQE:UpdateSeparateFocusFrame()
		-- Make sure the SeparateContentFrame exists
		if not RQE.SeparateContentFrame then
			print("Error: SeparateContentFrame not found.")
			return
		end

		-- Clear any existing children in the content frame
		for _, child in ipairs({RQE.SeparateContentFrame:GetChildren()}) do
			child:Hide()
		end

		local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
		if not isSuperTracking then
			return
		end

		local stepIndex = tonumber(RQE.AddonSetStepIndex) or 1
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		local questData = RQE.getQuestData(questID) or {}
		-- local questData = RQE.getQuestData(questID)

		-- if not questData then
			-- if RQE.db.profile.debugLevel == "INFO+" then
			-- end

			-- -- Ensure RQE.SeparateStepText is initialized before use
			-- if not RQE.SeparateStepText then
				-- RQE.SeparateStepText = RQE.SeparateContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				-- RQE.SeparateStepText:SetJustifyH("LEFT")
				-- RQE.SeparateStepText:SetTextColor(1, 1, 0.8) -- Text color in RGB
				-- RQE.SeparateStepText:SetWidth(RQE.SeparateContentFrame:GetWidth() - 60) -- Control the width to prevent overflow
				-- RQE.SeparateStepText:SetHeight(0)  -- Auto height
				-- RQE.SeparateStepText:SetWordWrap(true)  -- Allow word wrap
				-- RQE.SeparateStepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", 45, -10)
			-- end

			-- -- Update the step text dynamically
			-- RQE.SeparateStepText:SetText("No step description available for this step.")
			-- RQE.SeparateStepText:Show()
			-- return
		-- end

		-- clamp and normalize
		local totalSteps = #questData
		if totalSteps == 0 then totalSteps = 1 end
		if stepIndex < 1 then stepIndex = 1 end
		if stepIndex > totalSteps then stepIndex = totalSteps end

		local stepData = questData[stepIndex]

		-- Create or update StepText element
		if not RQE.SeparateStepText then
			RQE.SeparateStepText = RQE.SeparateContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			RQE.SeparateStepText:SetJustifyH("LEFT")
			RQE.SeparateStepText:SetTextColor(1, 1, 0.8) -- Text color in RGB
			RQE.SeparateStepText:SetWidth(RQE.SeparateContentFrame:GetWidth() - 60) -- Control the width to prevent overflow
			RQE.SeparateStepText:SetHeight(0)  -- Auto height
			RQE.SeparateStepText:SetWordWrap(true)  -- Allow word wrap
			RQE.SeparateStepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", 45, -10)
		end

		-- Update the step text dynamically to include the step index
		local stepDescription = (stepData and stepData.description and stepData.description ~= "") and stepData.description	or "No step description available for this step."
		-- local stepDescription = (stepData and stepData.description) or "No step description available for this step."
		-- local formattedText = string.format("%d: %s", stepIndex, stepDescription) -- Prepend the stepIndex to the description

		-- Function to update the step text dynamically to include the current and final step index
		local totalSteps = #questData  -- Get the total number of steps from the questData
		local formattedText = string.format("%d/%d: %s", stepIndex, totalSteps, stepDescription) -- Format the text to show the current step index and the total number of steps
		RQE.StepIndexForCoordMatch = stepIndex
		RQE.totalStepforQuest = totalSteps

		--RQE.SeparateStepText:SetText(formattedText)

		-- local itemID = RQE.ParseItemTag(formattedText)
		-- local rendered = RQE.RenderTextWithItemTags(formattedText)
		-- RQE.SeparateStepText:SetText(rendered)
		-- RQE.AttachItemHover(RQE.SeparateStepText, itemID)

		RQE.SeparateStepText:SetText("")  -- clear any previous text
		RQE.RenderTextWithItems(RQE.SeparateStepText, formattedText, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 1})

		RQE.SeparateStepText:Show()

		RQE.InitializeSeparateFocusWaypoints()

		-- Update content height dynamically
		RQE.UpdateSeparateContentHeight()
	end

	-- Attach the mouse wheel scroll script to the scroll frame
	RQE.SeparateScrollFrame:SetScript("OnMouseWheel", function(self, delta)
		-- Check if the mouse is over the SeparateStepText
		if RQE.SeparateStepText and RQE.SeparateStepText:IsMouseOver() then
			-- Check if Alt, Ctrl, or Shift is being held down
			if IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then
				-- Handle scrolling for the SeparateScrollFrame
				local currentScroll = self:GetVerticalScroll()
				local maxScroll = self:GetVerticalScrollRange()

				-- Adjust the scroll speed
				local newScroll = currentScroll - (delta * 20)

				-- Ensure the new scroll position is within valid bounds
				newScroll = math.max(0, math.min(newScroll, maxScroll))

				-- Set the new scroll position
				self:SetVerticalScroll(newScroll)
			end
		else
			-- If not over SeparateStepText or no modifier key is held, pass the scroll event to the main RQEFrame
			if RQE.ScrollFrame then
				local currentScroll = RQE.ScrollFrame:GetVerticalScroll()
				local maxScroll = RQE.ScrollFrame:GetVerticalScrollRange()

				-- Adjust the scroll speed
				local newScroll = currentScroll - (delta * 20)

				-- Ensure the new scroll position is within valid bounds
				newScroll = math.max(0, math.min(newScroll, maxScroll))

				-- Set the new scroll position for the main frame
				RQE.ScrollFrame:SetVerticalScroll(newScroll)
			end
		end
	end)

	-- Function to dynamically update the content height
	function RQE.UpdateSeparateContentHeight()
		local desiredHeight = 0
		for _, child in ipairs({RQE.SeparateContentFrame:GetChildren()}) do
			desiredHeight = desiredHeight + child:GetHeight() + 5 -- Adjust for spacing
		end
		RQE.SeparateContentFrame:SetHeight(math.max(desiredHeight, 1000)) -- Ensure minimum height for visibility
	end

	-- Initial update to content height
	RQE.UpdateSeparateContentHeight()

	-- Call the function to update the frame's content dynamically
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when initialized
end


function RQE.InitializeSeparateFocusWaypoints()
	-- Create or update Waypoint Button
	if not RQE.SeparateWaypointButton then
		RQE.SeparateWaypointButton = CreateFrame("Button", nil, RQE.SeparateContentFrame)
		RQE.SeparateWaypointButton:SetSize(30, 30)
		RQE.SeparateWaypointButton:SetPoint("TOPRIGHT", RQE.SeparateStepText, "TOPLEFT", -10, 0)
		local bg = RQE.SeparateWaypointButton:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")

		-- Create the number label
		local number = RQE.SeparateWaypointButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		number:SetPoint("CENTER", RQE.SeparateWaypointButton, "CENTER", 0, -2)
		number:SetText("*")
		number:SetTextColor(1, 1, 0)

		-- Add the click event for the Waypoint Button
		RQE.SeparateWaypointButton:SetScript("OnClick", function()
			if RQE.WaypointButtons and RQE.WaypointButtons[RQE.AddonSetStepIndex] then
				RQE.WaypointButtons[RQE.AddonSetStepIndex]:Click()
				-- If the RQE.AddonSetStepIndex is "1" then it will build the macro associated with that stepIndex
				if RQE.AddonSetStepIndex == 1 then
					-- Tier Two Importance: 
					if RQE.db.profile.autoClickWaypointButton then
						RQE.CreateMacroForUpdateSeparateFocusFrame = true
						RQEMacro:CreateMacroForCurrentStep()
						C_Timer.After(3, function()
							RQE.CreateMacroForUpdateSeparateFocusFrame = false
						end)
						--RQE.CheckAndBuildMacroIfNeeded()
					end
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("No waypoint button found for the current step.")
				end
			end
		end)

		-- Add the script for the tooltip on mouse enter for the "C" button
		RQE.SeparateWaypointButton:SetScript("OnEnter", function(self)
			-- Use the stepIndex for the current step, always 1 for "C" button
			local stepIndex = RQE.AddonSetStepIndex or 1

			-- Retrieve the correct tooltip data using the function
			local coordsText = RQE.GetTooltipDataForCButton()

			-- Ensure coordsText is valid and set up the tooltip
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:SetText(coordsText)
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 0, 0)
			GameTooltip:Show()
		end)

		-- Hide the tooltip when leaving the "C" button
		RQE.SeparateWaypointButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end

	RQE.SeparateWaypointButton:Show()
end


-- Function to create a tooltip to display
function RQE.ShowFocusScrollFrameTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP", -200, 20) -- Anchor the tooltip at the top of the frame

	-- Set the title of the tooltip
	GameTooltip:SetText("Hold ALT, CTRL, or SHIFT to scroll this frame.", 1, 1, 1, 1, true)

	-- Check if RQE.SeparateStepText exists and has text
	if RQE.SeparateStepText and RQE.SeparateStepText:GetText() ~= "" then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("|cfffffd9fQuest Help for Current Step:|r", 1, 1, 1, true) -- Canary title
		-- GameTooltip:AddLine("|cff00ffffQuest Help for Current Step:|r", 1, 1, 1, true) -- Cyan title
		GameTooltip:AddLine("|cffa9a9ff" .. RQE.GetSeparateStepText() .. "|r", nil, nil, nil, true)
		-- GameTooltip:AddLine("|cffa9a9ff" .. RQE.SeparateStepText:GetText() .. "|r", nil, nil, nil, true) -- Light purple text
	else
		GameTooltip:AddLine("|cffff0000No additional focus data available.|r", 1, 1, 1, true) -- Default message in red
	end

	GameTooltip:Show()
end


-- Function to create a tooltip to hide
function RQE.HideFocusScrollFrameTooltip()
	GameTooltip:Hide()
end


-- Function to scroll the SeparateFocusFrame to the top
function RQE.FocusScrollFrameToTop()
	if RQE.SeparateFocusFrame and not RQE.SeparateFocusFrame:IsMouseOver() then
		if RQE.SeparateScrollFrame then
			-- Set the scroll position of the SeparateScrollFrame to the top
			RQE.SeparateScrollFrame:SetVerticalScroll(10)
		end
	end
end


-- Function to retrieve the tooltip data for the specific stepIndex from the RQEDatabase
function RQE.GetTooltipDataForCButton()
	local stepIndex = RQE.AddonSetStepIndex or 1  -- Default to step index 1 if none is set
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local questData = RQE.getQuestData(questID)

	if questData and questData[stepIndex] then
		local step = questData[stepIndex]

		-- Prefer hotspots if present; else legacy single coordinates
		if step.coordinateHotspots then
			local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
			if smap and sx and sy then
				local coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", sx * 100, sy * 100, smap)
				RQE.SeparateFocusCoordData = coordsText
				if RQE.db.profile.debugLevel == "INFO" then
					DEFAULT_CHAT_FRAME:AddMessage("Step " .. stepIndex .. " coords: " .. coordsText, 1, 1, 0)
				end
				return coordsText
			end
		elseif step.coordinates then
			local x, y, mapID = step.coordinates.x, step.coordinates.y, step.coordinates.mapID
			if x and y and mapID then
				local coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", x, y, mapID)
				RQE.SeparateFocusCoordData = coordsText
				if RQE.db.profile.debugLevel == "INFO" then
					DEFAULT_CHAT_FRAME:AddMessage("Step " .. stepIndex .. " coords: " .. coordsText, 1, 1, 0)
				end
				return coordsText
			end
		end
	end

	return "No tooltip available."
end

-- function RQE.GetTooltipDataForCButton()	-- OLD METHOD RELYING ON THE SINGLE COORDINATE BLOCK METHOD AND NOT THE MULTI ARRAY
	-- local stepIndex = RQE.AddonSetStepIndex or 1  -- Default to step index 1 if none is set
	-- local questID = C_SuperTrack.GetSuperTrackedQuestID()
	-- local questData = RQE.getQuestData(questID)  -- Fetch quest data from RQEDatabase

	-- -- Ensure quest data exists and has the coordinate data
	-- if questData and questData[stepIndex] and questData[stepIndex].coordinates then
		-- -- Extract coordinate information for the current stepIndex
		-- local coordData = questData[stepIndex].coordinates
		-- local x, y, mapID = coordData.x, coordData.y, coordData.mapID

		-- -- Format the coordinate text
		-- local coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", x, y, mapID)
		-- --local coordsText = string.format("Coordinates: %.2f, %.2f (Map ID: %d)", x, y, mapID)
		-- RQE.SeparateFocusCoordData = coordsText

		-- if RQE.db.profile.debugLevel == "INFO" then
			-- DEFAULT_CHAT_FRAME:AddMessage("Step " .. RQE.AddonSetStepIndex .. " coords: " .. coordsText, 1, 1, 0)
		-- end

		-- -- Return the formatted coordinate text
		-- return coordsText
	-- else
		-- return "No tooltip available."  -- Fallback if no data is available
	-- end
-- end


-- Function to attach tooltip to the "C" button
function RQE:AttachTooltipToCButton()
	-- Ensure the "C" button exists
	if not RQE.SeparateWaypointButton then return end

	-- Add the script for the tooltip on mouse enter for the "C" button
	RQE.SeparateWaypointButton:SetScript("OnEnter", function(self)
		-- Retrieve the correct tooltip data
		local coordsText = RQE.GetTooltipDataForCButton()

		-- Set up the tooltip for the "C" button
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetText(coordsText)
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", 0, 0)
		GameTooltip:Show()
	end)

	-- Hide tooltip when leaving the button
	RQE.SeparateWaypointButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end


-- Check which visibility state the RQEFrame and RQEQuestFrame should be
function RQE:CheckFrameVisibility()
-- local checkRQEFrames = CreateFrame("Frame")
-- checkRQEFrames:SetScript("OnUpdate", function()

	-- Check for the RQEFrame visibility setting
	if RQE.db.profile.enableFrame then
		-- Show the RQEFrame if it should be enabled and is not currently shown
		if not InCombatLockdown() then
			if not RQEFrame:IsShown() then
				if RQEFrame then 
					-- print("~~ RQEFrame:Show: 2264 ~~")
					RQEFrame:Show()
				end
			end
		end
	else
		-- Hide the RQEFrame if it should not be shown
		if not InCombatLockdown() then
			if RQEFrame:IsShown() then
				if RQEFrame then
					RQEFrame:Hide()
				end
			end
		end
	end

	-- Check for the RQEQuestFrame visibility setting
	if RQE.db.profile.enableQuestFrame then
		-- Show the RQEQuestFrame if it should be enabled and is not currently shown
		if not RQE.RQEQuestFrame:IsShown() then
			RQE.RQEQuestFrame:Show()
		end
	else
		-- Hide the RQEQuestFrame if it should not be shown
		if RQE.RQEQuestFrame:IsShown() then
			RQE.RQEQuestFrame:Hide()
		end
	end

	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- Frequent checking with OnUpdate to enforce the visibility state of RQE frames
C_Timer.NewTicker(1.5, function()
	if InCombatLockdown() then return end
	local isMoving = IsPlayerMoving()
	local inScenario = C_Scenario.IsInScenario()

	--if RQE.CanCheckFrame or not isMoving then
	if not isMoving or inScenario then
		RQE:CheckFrameVisibility()
	end
end)