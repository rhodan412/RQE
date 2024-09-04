--[[ 
Buttons.lua
Manages button designs for the main frame
]]

----------------------------------------------------
-- 1. Global Declarations
----------------------------------------------------

RQE = RQE or {}

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}

RQE.debugLog("RQE.content initialized: " .. tostring(RQE.content ~= nil))


----------------------------------------------------
-- 2. Utility Functions
----------------------------------------------------

-- Function to show tooltips
local function ShowTooltip(self, text)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 33)
	GameTooltip:SetText(text)
	GameTooltip:Show()
end


-- Function to hide tooltips
local function HideTooltip()
	GameTooltip:Hide()
end


-- Local function to create tooltip using ShowTooltip and HideTooltip
local function CreateTooltip(button, text)
	button:SetScript("OnEnter", function(self) ShowTooltip(self, text) end)
	button:SetScript("OnLeave", HideTooltip)
end


-- Waypoint Buttons for Unlisted Quests (those not in the RQEDatabase)
-- Local function to create border
local function CreateBorder(button)
	local border = button:CreateTexture(nil, "BACKGROUND")
	border:SetColorTexture(1, 1, 1, 1)
	border:SetAlpha(0.25)  -- Set the alpha to 0.5 (50% opacity)
	border:SetPoint("TOPLEFT", button, "TOPLEFT", -0.15, 0.15)
	border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0.15, -0.15)
end


-- Add mouseover tooltip and trigger map opening/closing
RQE.UnknownButtonTooltip = function()
	RQE.UnknownQuestButton:SetScript("OnEnter", function(self)
		C_Timer.After(0.2, function()
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")

			local extractedQuestID
			local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))

			local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

			if questID then  -- Add a check to ensure questID is not nil
				local mapID = GetQuestUiMapID(questID)
				local questData = RQE.getQuestData(questID)
				if mapID == 0 then mapID = nil end
			end

			if RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) then
				-- If coordinates are already available, just show them
				local tooltipText = string.format("Coordinates: (%.1f, %.1f) - MapID: %s", RQE.DatabaseSuperX * 100, RQE.DatabaseSuperY * 100, tostring(RQE.DatabaseSuperMapID))
				GameTooltip:SetText(tooltipText)
				GameTooltip:Show()
			elseif not RQE.DatabaseSuperX and RQE.DatabaseSuperY or not RQE.superX or not RQE.superY and RQE.superMapID then
				-- Open the quest log details for the super tracked quest to fetch the coordinates
				OpenQuestLogToQuestDetails(questID)

				-- Use RQE.GetQuestCoordinates to get the coordinates
				local x, y, mapID = RQE.GetQuestCoordinates(questID)
				if x and y and mapID then
					local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", x * 100, y * 100, tostring(mapID))
					GameTooltip:SetText(tooltipText)
				else
					-- Fallback to using RQE.GetNextWaypoint if coordinates are not available
					local waypointMapID, waypointX, waypointY = C_QuestLog.GetNextWaypoint(questID)
					if waypointX and waypointY and waypointMapID then
						local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", waypointX * 100, waypointY * 100, tostring(waypointMapID))
						GameTooltip:SetText(tooltipText)
					else
						GameTooltip:SetText("Coordinates: Not available.")
					end
				end
				GameTooltip:Show()
			else
				-- If coordinates are already available, just show them
				local tooltipText = string.format("Coordinates: (%.1f, %.1f) - MapID: %s", RQE.superX * 100, RQE.superY * 100, tostring(RQE.superMapID))
				GameTooltip:SetText(tooltipText)
				GameTooltip:Show()
			end
			WorldMapFrame:Hide()
		end)
	end)

	RQE.UnknownQuestButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end


-- Hide the tooltip when the mouse leaves
RQE.HideUnknownButtonTooltip = function()
	RQE.UnknownQuestButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end


-- Add a mouse down event to simulate a button press
RQE.UnknownQuestButtonMouseDown = function()
	RQE.UnknownQuestButton:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			RQE.bg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press
		end
	end)
end


-- Add a mouse up event to reset the texture
RQE.UnknownQuestButtonMouseUp = function()
	RQE.UnknownQuestButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			RQE.bg:SetAlpha(1)  -- Reset the alpha
		end
	end)
end


-- Handles the Raid Message Alert and sound when group is forming/no longer forming in LFG
-- Prevents sound from playing on top of each other if switching between forming group and no longer forming group
RQE.lastSoundTime = RQE.lastSoundTime or 0
RQE.soundThrottle = 2 -- seconds between sounds

function RQE:PlayThrottledSound(soundID)
	local timeNow = GetTime() -- Get the current time in seconds
	if (timeNow - self.lastSoundTime) >= self.soundThrottle then
		PlaySound(soundID)
		self.lastSoundTime = timeNow
	end
end


-- Function that handles the alert/sound when LFG quest group no longer forming
function RQE:StopFormingLFG()
	local leavemessage = "LFG Group has been delisted."
	self:PlayThrottledSound(9244)
	RaidNotice_AddMessage(RaidWarningFrame, leavemessage, ChatTypeInfo["RAID_WARNING"])
end


-- Function that handles the alert/sound when LFG quest group is forming
function RQE:FormLFG()
	local createmessage = "Your quest group is forming."
	RaidNotice_AddMessage(RaidWarningFrame, createmessage, ChatTypeInfo["RAID_WARNING"])
end


-- Add a mouse down event to simulate a button press
RQE.SearchGroupButtonMouseDown = function()
	RQE.SearchGroupButton:SetScript("OnMouseDown", function(self, button)
		RQE.sgbg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press

		if IsShiftKeyDown() and button == "LeftButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			-- Show settings for delisting group
			RQE:LFG_Delist(questID)

		elseif button == "LeftButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			if questID then
				RQE:LFG_Search(questID)
			end

		elseif button == "RightButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			-- Logic for creating a group
			if RQE.LFGActive then
				RQE:LFG_Delist(questID)
				RQE:StopFormingLFG()
			else
				RQE:LFG_Create(questID)
				RQE:FormLFG()
			end
		end
	end)

	RQE.SearchGroupButton:SetScript("OnMouseUp", function(self, button)
		RQE.sgbg:SetAlpha(1)  -- Reset the alpha
	end)
end


----------------------------------------------------
-- 3. Button Initialization (RQEFrame)
----------------------------------------------------

-- Parent function to Create Magic Button for Super Tracked quest (runs the RQE Macro)
function RQE.Buttons.CreateMagicButton(RQEFrame)
	local MagicButton = CreateFrame("Button", "RQEMagicButton", UIParent, "SecureActionButtonTemplate")
	MagicButton:SetSize(32, 32)  -- Set the button size
	MagicButton:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", -50, -30)  -- Positioning the button

	-- Enable mouse input propagation on MagicButton if necessary
	MagicButton:SetPropagateMouseClicks(true)
	MagicButton:SetPropagateMouseMotion(true)

	-- Storing MagicButton within the RQE table
	RQE.MagicButton = MagicButton

	-- Update the Icon of the Magic Button
	RQE.Buttons.UpdateMagicButtonIcon()

	-- Default icon texture ID or path
	local defaultIconID = 134400 -- This is just an example; replace with a valid default icon ID or path
	local iconID = defaultIconID -- Initialize with default icon

	local macroIndex = GetMacroIndexByName("RQE Macro")
	if macroIndex > 0 then
		local _, macroIconID = GetMacroInfo(macroIndex)
		if macroIconID then
			iconID = macroIconID -- Use the macro's icon if available
		end
	end

	-- Set the button to execute the "RQE Macro"
	MagicButton:SetAttribute("type", "macro")
	MagicButton:SetAttribute("macro", "RQE Macro")
	MagicButton:RegisterForClicks("AnyUp", "AnyDown")

	-- Set the button's appearance
	MagicButton:SetNormalTexture(iconID)  -- Example texture ID, replace with actual macro icon or path
	MagicButton:SetHighlightTexture(iconID, "ADD")

	-- Tooltip
	MagicButton:SetScript("OnEnter", function(self)
		local macroIndex = GetMacroIndexByName("RQE Macro")
		if macroIndex and macroIndex > 0 then
			local _, _, body = GetMacroInfo(macroIndex)
			-- Check if the body has content (not nil and not an empty string)
			if body and string.trim(body) ~= "" then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(body, nil, nil, nil, nil, true)
				GameTooltip:Show()
			else
				-- Optionally, clear any existing tooltip since there's no content
				GameTooltip:Hide()
			end
		end
	end)

	-- -- Helper function to trim strings (removes whitespace from the beginning and end of a string)
	-- if not string.trim then
		-- string.trim = function(s)
			-- return s:match("^%s*(.-)%s*$")
		-- end
	-- end

	-- Local helper function to trim strings (removes whitespace from the beginning and end of a string)
	local function trim(s)
		return s:match("^%s*(.-)%s*$")
	end

	MagicButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return MagicButton
end


-- Update MagicButton based on macro content
function RQE.Buttons.UpdateMagicButtonVisibility()
	if InCombatLockdown() then
		return
	end

	local macroIndex = GetMacroIndexByName("RQE Macro")
	local MagicButton = RQE.MagicButton -- Assuming MagicButton stored globally in RQE.MagicButton

	-- Check if the RQEFrame is hidden first
	if not RQEFrame or not RQEFrame:IsShown() then
		if RQE.MagicButton then
			RQE.MagicButton:Hide() -- Ensure MagicButton is hidden if RQEFrame is not shown
		end
		return -- Exit the function early if RQEFrame is hidden
	end

	if macroIndex > 0 then
		local _, _, body = GetMacroInfo(macroIndex)
		if body and body:trim() ~= "" then
			if MagicButton then MagicButton:Show() end
		else
			if MagicButton then MagicButton:Hide() end
		end
	else
		if MagicButton then MagicButton:Hide() end
	end
end


-- Function to set up an override key binding for macro
function RQE:SetupOverrideMacroBinding()
	local ownerFrame = RQE.MagicButton
	local macroName = "RQE Macro"
	local bindingKey = RQE.db.profile.keyBindSetting	-- Use the stored setting or default

	-- Check if bindingKey is valid
	if not bindingKey or bindingKey == "" then
		-- Provide feedback that no valid key binding is set
		print("No key binding is set for the Quest Macro Button.")
		return
	end

	local macroIndex = GetMacroIndexByName(macroName)
	if macroIndex and macroIndex > 0 then
		-- Sets an override binding that runs the specified macro by index
		ClearOverrideBindings(ownerFrame)
		SetOverrideBindingMacro(ownerFrame, true, bindingKey, macroIndex)
		-- Optional: Provide feedback that the binding was set
		RQE.infoLog("Override binding set for " .. bindingKey .. " to run macro: " .. macroName)
	else
		-- Provide feedback if the macro does not exist
		RQE.debugLog("Macro '" .. macroName .. "' not found.")
	end
end


-- Remember to clear the override binding when it's no longer needed or when UI is hidden
local function ClearOverrideMacroBinding()
	local ownerFrame = RQE.MagicButton -- The same frame binding is set to

	-- This will clear all override bindings associated with the ownerFrame
	ClearOverrideBindings(ownerFrame)
end


-- Parent function to Create ClearButton
function RQE.Buttons.CreateClearButton(RQEFrame)
	local ClearButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	ClearButton:SetSize(18, 18)
	ClearButton:SetText("C")
	RQE.ClearButton = ClearButton  -- Store reference for later use

	-- Set the frame strata and level
	ClearButton:SetFrameStrata("MEDIUM")
	ClearButton:SetFrameLevel(3)

	-- Nested functions
	ClearButton:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 6, -6)  -- Anchoring
	ClearButton:SetScript("OnClick", function()

		-- Code for ClearButton functionality here
		RQE:ClearFrameData()  -- changed from RQE.ClearFrameData() - which is nothing
		RQE:ClearWaypointButtonData()
		RQE:ClearSeparateFocusFrame()
		RQE.searchedQuestID = nil
		RQE.ManualSuperTrack = nil
		RQE:RemoveSuperTrackingFromQuest()
		RQE:UpdateRQEFrameVisibility()
		RQEMacro:ClearMacroContentByName("RQE Macro")
		RQE.Buttons.UpdateMagicButtonVisibility()

		C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end

		-- Reset manually tracked quests
		if RQE.ManuallyTrackedQuests then
			for questID in pairs(RQE.ManuallyTrackedQuests) do
				RQE.ManuallyTrackedQuests[questID] = nil
			end
		end
	end)

	CreateTooltip(ClearButton, "Clear Window")  -- Tooltip
	CreateBorder(ClearButton)  -- Border

	return ClearButton
end


-- Parent function to create RWButton
function RQE.Buttons.CreateRWButton(RQEFrame)
	local RWButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	RWButton:SetSize(18, 18)
	RWButton:SetText("RW")
	RQE.RWButton = RWButton

	-- Set the frame strata and level
	RWButton:SetFrameStrata("MEDIUM")
	RWButton:SetFrameLevel(3)

	-- Nested functions
	RWButton:SetPoint("TOPLEFT", RQE.ClearButton, "TOPRIGHT", 3, 0)  -- Anchoring
	RWButton:SetScript("OnClick", function()
		-- Code for RWButton functionality here
		C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end
	end)

	CreateTooltip(RWButton, "Remove Waypoints")
	CreateBorder(RWButton)

	return RWButton
end


-- Parent function to create SearchButton
function RQE.Buttons.CreateSearchButton(RQEFrame)
	local SearchButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	SearchButton:SetSize(18, 18)
	SearchButton:SetText("S")
	RQE.SearchButton = SearchButton  -- Storing the reference in the RQE table

	-- Set the frame strata and level
	SearchButton:SetFrameStrata("MEDIUM")
	SearchButton:SetFrameLevel(3)

	-- Nested functions
	SearchButton:SetPoint("TOPLEFT", RQE.RWButton, "TOPRIGHT", 3, 0)  -- Anchoring
	SearchButton:SetScript("OnClick", function()
		RQE.isSearchFrameShown = not RQE.isSearchFrameShown  -- Toggle the variable
		CreateSearchFrame(RQE.isSearchFrameShown)  -- Pass the updated variable
	end)

	CreateTooltip(SearchButton, "Search by Quest ID")
	CreateBorder(SearchButton)

	return SearchButton
end


-- Parent function to show/hide the QuestingModule frame
function RQE.Buttons.CreateQMButton(RQEFrame)
	local QMButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	QMButton:SetSize(18, 18)
	QMButton:SetText("QF")
	RQE.QMButton = QMButton  -- Storing the reference in the RQE table

	-- Set the frame strata and level
	QMButton:SetFrameStrata("MEDIUM")
	QMButton:SetFrameLevel(3)

	-- Nested functions
	QMButton:SetPoint("TOPLEFT", RQE.SearchButton, "TOPRIGHT", 3, 0)  -- Anchoring
	QMButton:SetScript("OnClick", function()
		if RQE.RQEQuestFrame:IsShown() then
			RQE.RQEQuestFrame:Hide()
		else
			RQE.RQEQuestFrame:Show()
		end
	end)

	CreateTooltip(QMButton, "Show/Hide Quest Tracker")
	CreateBorder(QMButton)

	return QMButton
end


-- Parent function to create CloseButton
function RQE.Buttons.CreateCloseButton(RQEFrame)
	local CloseButton = CreateFrame("Button", nil, RQEFrame, "UIPanelCloseButton")
	CloseButton:SetSize(18, 18)
	RQE.CloseButton = CloseButton  -- Storing the reference in the RQE table

	-- Set the frame strata and level
	CloseButton:SetFrameStrata("MEDIUM") -- Strata makes it appear behind most frames except actionbars, but actionbars remain clickable despite appearance of UIPanelCloseButton icon "in front" of action bar
	CloseButton:SetFrameLevel(3)

	-- Nested functions
	CloseButton:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -6, -6)  -- Anchoring
	CloseButton:SetScript("OnClick", function(self, button)
		RQE.isRQEFrameManuallyClosed = true -- Marking the frame as manually closed
		RQEFrame:Hide()
	end)
	CreateTooltip(CloseButton, "Close/Hide Frame")
	CreateBorder(CloseButton)

	return CloseButton
end


-- Parent function to Create MaximizeButton
function RQE.Buttons.CreateMaximizeButton(RQEFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
	local MaximizeButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	RQE.debugLog("CreateMaximizeButton: Function entered.")
	MaximizeButton:SetSize(18, 18)
	MaximizeButton:SetText("+")
	RQE.MaximizeButton = MaximizeButton  -- Store the reference in the RQE table

	-- Set the frame strata and level
	MaximizeButton:SetFrameStrata("MEDIUM")
	MaximizeButton:SetFrameLevel(3)

	MaximizeButton:SetPoint("TOPRIGHT", RQE.CloseButton, "TOPLEFT", -3, 0)

	MaximizeButton:SetScript("OnClick", function()
		RQE.debugLog("RQE.content after setting up MaximizeButton: " .. tostring(RQE.content ~= nil))
		RQE.debugLog("RQE.content inside button click: " .. tostring(RQE.content ~= nil))
		RQE.debugLog("Maximize button clicked")
	end)

	CreateTooltip(MaximizeButton, "Maximize")
	CreateBorder(MaximizeButton)

	RQE.debugLog("CreateMaximizeButton: Function exited.")
	return MaximizeButton
end


-- Parent function to Create MinimizeButton
function RQE.Buttons.CreateMinimizeButton(RQEFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
	local MinimizeButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	RQE.debugLog("CreateMinimizeButton: Function entered.")
	MinimizeButton:SetSize(18, 18)
	MinimizeButton:SetText("-")
	RQE.MinimizeButton = MinimizeButton  -- Store the reference in the RQE table

	-- Set the frame strata and level
	MinimizeButton:SetFrameStrata("MEDIUM")
	MinimizeButton:SetFrameLevel(3)

	MinimizeButton:SetPoint("TOPRIGHT", RQE.CloseButton, "TOPLEFT", -3, 0)

	MinimizeButton:SetScript("OnClick", function()
		RQE.debugLog("RQE.content inside button click: " .. tostring(RQE.content ~= nil))
		RQE.db.profile.enableFrame = false
		RQE:ToggleRQEFrame()
	end)

	CreateTooltip(MinimizeButton, "Minimize")
	CreateBorder(MinimizeButton)

	RQE.debugLog("CreateMinimizeButton: Function exited.")
	return MinimizeButton
end


----------------------------------------------------
-- 4. Button Initialization (RQEQuestFrame)
----------------------------------------------------

-- Parent function to Create CQButton
function RQE.Buttons.CQButton(RQEQuestFrame)
	local CQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	CQButton:SetSize(18, 18)
	CQButton:SetText("SC")
	RQE.CQButton = CQButton  -- Store reference for later use

	-- Set the frame strata and level
	CQButton:SetFrameStrata("MEDIUM")
	CQButton:SetFrameLevel(3)

	-- Nested functions
	CQButton:SetPoint("TOPLEFT", RQEQuestFrame, "TOPLEFT", 6, -6)  -- Anchoring
	CQButton:SetScript("OnClick", function()
		-- Code for showing completed quests functionality here
		RQE.filterCompleteQuests()
	end)

	CreateTooltip(CQButton, "Show Completed Quests \n in Quest Log")  -- Tooltip
	CreateBorder(CQButton)  -- Border

	return CQButton
end


-- Parent function to Create HQButton
function RQE.Buttons.HQButton(RQEQuestFrame)
	local HQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	HQButton:SetSize(18, 18)
	HQButton:SetText("HC")
	RQE.HQButton = HQButton  -- Store reference for later use

	-- Set the frame strata and level
	HQButton:SetFrameStrata("MEDIUM")
	HQButton:SetFrameLevel(3)

	-- Nested functions
	HQButton:SetPoint("TOPLEFT", RQE.CQButton, "TOPRIGHT", 4, 0)  -- Anchoring
	HQButton:SetScript("OnClick", function()
		-- Code for hiding completed quests functionality here
		RQE:HideCompletedWatchedQuests()
	end)

	CreateTooltip(HQButton, "Hide watched Completed Quests")  -- Tooltip
	CreateBorder(HQButton)  -- Border

	return HQButton
end


-- Parent function to Create ZQButton
function RQE.Buttons.ZQButton(RQEQuestFrame)
	local ZQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	ZQButton:SetSize(18, 18)
	ZQButton:SetText("ZQ")
	RQE.ZQButton = ZQButton  -- Store reference for later use

	-- Set the frame strata and level
	ZQButton:SetFrameStrata("MEDIUM")
	ZQButton:SetFrameLevel(3)

	-- Nested functions
	ZQButton:SetPoint("TOPLEFT", RQE.HQButton, "TOPRIGHT", 4, 0)  -- Anchoring
	ZQButton:SetScript("OnClick", function()
		-- Code for displaying quests in current zone
		RQE.DisplayCurrentZoneQuests()
	end)

	CreateTooltip(ZQButton, "Show zone quests")  -- Tooltip
	CreateBorder(ZQButton)  -- Border

	return ZQButton
end


-- Parent function to create QTCloseButton for RQEQuestFrame
function RQE.Buttons.CreateQuestCloseButton(RQEQuestFrame)
	local QTCloseButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelCloseButton")
	QTCloseButton:SetSize(18, 18)
	RQE.QTQuestCloseButton = QTCloseButton  -- Storing the reference in the RQE table

	-- Set the frame strata and level
	QTCloseButton:SetFrameStrata("MEDIUM")
	QTCloseButton:SetFrameLevel(3)

	QTCloseButton:SetPoint("TOPRIGHT", RQEQuestFrame, "TOPRIGHT", -6, -6)
	QTCloseButton:SetScript("OnClick", function(self, button)
		RQE.isRQEQuestFrameManuallyClosed = true -- Marking the frame as manually closed
		RQEQuestFrame:Hide()
	end)
	CreateTooltip(QTCloseButton, "Close/Hide Quest Tracker")
	CreateBorder(QTCloseButton)

	return QTCloseButton
end


-- Parent function to Create QTMaximizeButton for RQEQuestFrame
function RQE.Buttons.CreateQuestMaximizeButton(RQEQuestFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
	local QTMaximizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	QTMaximizeButton:SetSize(18, 18)
	QTMaximizeButton:SetText("+")
	RQE.QTQuestMaximizeButton = QTMaximizeButton  -- Store the reference in the RQE table

	-- Set the frame strata and level
	QTMaximizeButton:SetFrameStrata("MEDIUM")
	QTMaximizeButton:SetFrameLevel(3)

	QTMaximizeButton:SetPoint("TOPRIGHT", RQE.QTQuestCloseButton, "TOPLEFT", -3, 0)
	QTMaximizeButton:SetScript("OnClick", function()
		RQE.db.profile.enableQuestFrame = false
		RQE.RQEQuestFrame:Show()

		-- Set RQE.QTMinimized to false since we're maximizing the frame
		RQE.QTMinimized = false

		-- Restore the frame to its original size
		RQEQuestFrame:SetSize(RQE.QToriginalWidth, RQE.QToriginalHeight)
		RQE.QTScrollFrame:Show()
		RQE.QMQTResizeButton:Show()
	end)
	CreateTooltip(QTMaximizeButton, "Maximize Quest Tracker")
	CreateBorder(QTMaximizeButton)

	return QTMaximizeButton
end


-- Parent function to Create QTMinimizeButton for RQEQuestFrame
function RQE.Buttons.CreateQuestMinimizeButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
	local QTMinimizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	QTMinimizeButton:SetSize(18, 18)
	QTMinimizeButton:SetText("-")
	RQE.QTQuestMinimizeButton = QTMinimizeButton  -- Store the reference in the RQE table

	-- Set the frame strata and level
	QTMinimizeButton:SetFrameStrata("MEDIUM")
	QTMinimizeButton:SetFrameLevel(3)

	QTMinimizeButton:SetPoint("TOPRIGHT", RQE.QTQuestMaximizeButton, "TOPLEFT", -3, 0)
	QTMinimizeButton:SetScript("OnClick", function()
		RQE.QToriginalWidth, RQE.QToriginalHeight = RQEQuestFrame:GetWidth(), RQEQuestFrame:GetHeight()

		-- Set RQE.QTMinimized to false since we're maximizing the frame
		RQE.QTMinimized = true

		RQEQuestFrame:SetSize(300, 30)

		-- Hide the ScrollFrame if they exist
		if RQE.QTScrollFrame then
			RQE.QTScrollFrame:Hide()
		end

		-- Hide the Slider if they exist
		if RQE.QMQTslider then
			RQE.QMQTslider:Hide()
		end

		-- Hide the resize button
		if RQE.QMQTResizeButton then
			RQE.QMQTResizeButton:Hide()
		end
	end)
	CreateTooltip(QTMinimizeButton, "Minimize Quest Tracker")
	CreateBorder(QTMinimizeButton)

	return QTMinimizeButton
end


-- Custom Mixin for Quest Filter Menu Buttons
RQE_QuestButtonMixin = {}


function RQE_QuestButtonMixin:OnLoad()
	self:SetNormalFontObject("GameFontHighlightSmall")
	self:SetHighlightFontObject("GameFontHighlightSmall")

	local normalTexture = self:CreateTexture(nil, "BACKGROUND")
	normalTexture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
	normalTexture:SetAllPoints(self)
	self:SetNormalTexture(normalTexture)

	local highlightTexture = self:CreateTexture(nil, "BACKGROUND")
	highlightTexture:SetColorTexture(0.2, 0.2, 0.2, 1)
	highlightTexture:SetAllPoints(self)
	self:SetHighlightTexture(highlightTexture)

	local pushedTexture = self:CreateTexture(nil, "BACKGROUND")
	pushedTexture:SetColorTexture(0.05, 0.05, 0.05, 0.8)
	pushedTexture:SetAllPoints(self)
	self:SetPushedTexture(pushedTexture)
end


function RQE_QuestButtonMixin:OnClick()
	-- Placeholder for button click handling
end


-- Custom Mixin for Quest Filter Menu
RQE_QuestMenuMixin = {}


function RQE_QuestMenuMixin:OnLoad()
	self.buttons = {}
	self:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self:SetBackdropColor(0, 0, 0, 0.8)
end


-- Updated AddButton function to return the created button
function RQE_QuestMenuMixin:AddButton(text, onClick, isSubmenu)
	for _, button in ipairs(self.buttons) do
		if button:GetText() == text .. (isSubmenu and " >" or "") then
			return
		end
	end

	local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	Mixin(button, RQE_QuestButtonMixin)
	button:OnLoad()
	button:SetText(text .. (isSubmenu and " >" or ""))
	button:SetSize(self:GetWidth() - 20, 20)
	button:SetScript("OnClick", onClick)

	if #self.buttons == 0 then
		button:SetPoint("TOP", self, "TOP", 0, -10)
	else
		button:SetPoint("TOP", self.buttons[#self.buttons], "BOTTOM", 0, -5)
	end

	table.insert(self.buttons, button)
	self:SetHeight((#self.buttons * (20 + 5)) + 20)
end


-- Show and Position the Menu
function RQE_QuestMenuMixin:ShowMenu(anchorFrame, isSubmenu)
	self:ClearAllPoints()

	local screenWidth = GetScreenWidth()
	local screenHeight = GetScreenHeight()
	local anchorX, anchorY = anchorFrame:GetCenter()

	local isTopHalf = anchorY > (screenHeight / 2)
	local isLeftHalf = anchorX < (screenWidth / 2)

	if not isSubmenu and anchorFrame == RQE.QTQuestFilterButton then
		-- Directly anchor the main menu below the filter button, considering screen side
		if isLeftHalf then
			self:SetPoint("TOPLEFT", RQE.QTQuestFilterButton, "BOTTOMLEFT", 0, -5)
		else
			self:SetPoint("TOPRIGHT", RQE.QTQuestFilterButton, "BOTTOMRIGHT", 0, -5)
		end
	elseif isSubmenu then
		-- Adjust the positioning to anchor the submenu to the specific button (anchorFrame)
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 10, -60)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -10, -60)
		end
	else
		-- Fallback positioning for any other cases
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, -85)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -10, -85)
		end
	end

	self:Show()
end


function RQE_QuestMenuMixin:HideMenu()
	self:Hide()
end


function RQE_QuestMenuMixin:ToggleMenu(anchorFrame)
	if self:IsShown() then
		self:HideMenu()
	else
		self:ShowMenu(anchorFrame)
	end
end


-- Parent function to Create QTFilterButton for RQEQuestFrame
function RQE.Buttons.CreateQuestFilterButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
	local QTFilterButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
	QTFilterButton:SetSize(18, 18)
	QTFilterButton:SetText("F")
	RQE.QTQuestFilterButton = QTFilterButton

	QTFilterButton:SetPoint("TOPRIGHT", RQE.QTQuestMinimizeButton, "TOPLEFT", -3, 0)
	QTFilterButton:SetFrameStrata("MEDIUM")
	QTFilterButton:SetFrameLevel(3)

	-- Attach Dropdown Menu to Filter Button Click
	QTFilterButton:SetScript("OnClick", function(self, button, down)
		RQE.ScanQuestTypes()
		RQE:ShowQuestFilterMenu()
	end)

	CreateTooltip(QTFilterButton, "Filter Quests")
	CreateBorder(QTFilterButton)

	return QTFilterButton
end


-- Create the Dropdown Menu
function RQE:ShowQuestFilterMenu()
	if not self.QuestFilterDropDownMenu then
		self.QuestFilterDropDownMenu = CreateFrame("Frame", "RQEQuestFilterDropDownMenu", UIParent, "BackdropTemplate")
		Mixin(self.QuestFilterDropDownMenu, RQE_QuestMenuMixin)
		self.QuestFilterDropDownMenu:OnLoad()
		self.QuestFilterDropDownMenu:SetSize(150, 200)
		self.QuestFilterDropDownMenu:SetFrameStrata("DIALOG")
		self.QuestFilterDropDownMenu:Hide()

		-- Initialize the buttons table
		self.QuestFilterDropDownMenu.buttons = {}

		self.QuestFilterDropDownMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)
		self.QuestFilterDropDownMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) and not MouseIsOver(RQE.QTQuestFilterButton) then
					self:Hide()
				end
			end)
		end)
	end

	-- Ensure buttons are only added once
	if not self.QuestFilterDropDownMenu.buttons or #self.QuestFilterDropDownMenu.buttons == 0 then
		-- First, ensure all necessary data is up-to-date
		RQE.ScanQuestTypes()
		RQE.ScanAndCacheZoneQuests()
		RQE.ScanAndCacheCampaigns()

		-- Build the sorted menu lists
		local questTypeMenuList = RQE.BuildQuestTypeMenuList()
		local zoneQuestMenuList = RQE.BuildZoneQuestMenuList()
		local campaignMenuList = RQE.BuildCampaignMenuList()
		local questLineMenuList = RQE.BuildQuestLineMenuList()

		-- Add Buttons for Main Menu Items
		self.QuestFilterDropDownMenu:AddButton("Auto-Track Zone Quests", function(button)
			-- Toggle the autoTrackZoneQuests option
			RQE.db.profile.autoTrackZoneQuests = not RQE.db.profile.autoTrackZoneQuests

			-- Update the button text to reflect the new state
			if RQE.db.profile.autoTrackZoneQuests then
				button:SetText("|TInterface\\Buttons\\UI-CheckBox-Check:20|t Auto-Track Zone Quests")
				RQE.DisplayCurrentZoneQuests()
			else
				button:SetText("Auto-Track Zone Quests")
			end
		end)

		-- Initial state setup for the button
		if RQE.db.profile.autoTrackZoneQuests then
			self.QuestFilterDropDownMenu.buttons[#self.QuestFilterDropDownMenu.buttons]:SetText("|TInterface\\Buttons\\UI-CheckBox-Check:20|t Auto-Track Zone Quests")
		end

		self.QuestFilterDropDownMenu:AddButton("Completed Quests", function()
			RQE.filterCompleteQuests()
			if RQE.QTScrollFrame and RQE.QMQTslider then
				RQE.QTScrollFrame:SetVerticalScroll(0)
				RQE.QMQTslider:SetValue(0)
			end
		end)

		self.QuestFilterDropDownMenu:AddButton("Daily / Weekly Quests", function()
			RQE.filterDailyWeeklyQuests()
			if RQE.QTScrollFrame and RQE.QMQTslider then
				RQE.QTScrollFrame:SetVerticalScroll(0)
				RQE.QMQTslider:SetValue(0)
			end
		end)

		-- Add Submenus
		self.QuestFilterDropDownMenu:AddButton("Campaign Quests", function()
			-- Hide any other open submenu
			if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
			if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end
			if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end
			
			self.CampaignSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
		end, true)
		self:CreateCampaignSubMenu()

		self.QuestFilterDropDownMenu:AddButton("Quest Type", function()
			-- Hide any other open submenu
			if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
			if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end
			if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end
			
			self.QuestTypeSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
		end, true)
		self:CreateQuestTypeSubMenu()

		self.QuestFilterDropDownMenu:AddButton("Zone Quests", function()
			-- Hide any other open submenu
			if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
			if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
			if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end
			
			self.ZoneQuestSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
		end, true)
		self:CreateZoneQuestSubMenu()

		self.QuestFilterDropDownMenu:AddButton("Quest Line", function()
			-- Hide any other open submenu
			if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
			if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
			if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end
			
			self.QuestLineSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
		end, true)
		self:CreateQuestLineSubMenu()
	end

	-- Toggle Menu Visibility
	self.QuestFilterDropDownMenu:ToggleMenu(self.QTQuestFilterButton)
end


-- Create the Campaign Quests Submenu
function RQE:CreateCampaignSubMenu()
	if not self.CampaignSubMenu then
		self.CampaignSubMenu = CreateFrame("Frame", "RQECampaignSubMenu", UIParent, "BackdropTemplate")
		Mixin(self.CampaignSubMenu, RQE_QuestMenuMixin)
		self.CampaignSubMenu:OnLoad()
		self.CampaignSubMenu:SetSize(150, 200)
		self.CampaignSubMenu:SetFrameStrata("DIALOG")
		self.CampaignSubMenu:Hide()
		
		-- Keep submenu visible when mouse is over it
		self.CampaignSubMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)

		-- Example for one of the submenus, apply similar logic to others
		self.CampaignSubMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) and not MouseIsOver(self:GetParent()) then
					self:Hide()
					self:GetParent():Hide() -- Hide the main menu if mouse leaves both
				end
			end)
		end)

		-- Add buttons to the submenu
		for _, item in ipairs(RQE.BuildCampaignMenuList()) do
			self.CampaignSubMenu:AddButton(item.text, item.func)
		end
	end
end


-- Create the Quest Type Submenu
function RQE:CreateQuestTypeSubMenu()
	if not self.QuestTypeSubMenu then
		self.QuestTypeSubMenu = CreateFrame("Frame", "RQEQuestTypeSubMenu", UIParent, "BackdropTemplate")
		Mixin(self.QuestTypeSubMenu, RQE_QuestMenuMixin)
		self.QuestTypeSubMenu:OnLoad()
		self.QuestTypeSubMenu:SetSize(150, 200)
		self.QuestTypeSubMenu:SetFrameStrata("DIALOG")
		self.QuestTypeSubMenu:Hide()

		-- Keep submenu visible when mouse is over it
		self.QuestTypeSubMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)
		self.QuestTypeSubMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) then
					self:Hide()
				end
			end)
		end)

		-- Add buttons to the submenu
		for _, item in ipairs(RQE.BuildQuestTypeMenuList()) do
			self.QuestTypeSubMenu:AddButton(item.text, item.func)
		end
	end
end


-- Create the Zone Quests Submenu
function RQE:CreateZoneQuestSubMenu()
	if not self.ZoneQuestSubMenu then
		self.ZoneQuestSubMenu = CreateFrame("Frame", "RQEZoneQuestSubMenu", UIParent, "BackdropTemplate")
		Mixin(self.ZoneQuestSubMenu, RQE_QuestMenuMixin)
		self.ZoneQuestSubMenu:OnLoad()
		self.ZoneQuestSubMenu:SetSize(150, 200)
		self.ZoneQuestSubMenu:SetFrameStrata("DIALOG")
		self.ZoneQuestSubMenu:Hide()

		-- Keep submenu visible when mouse is over it
		self.ZoneQuestSubMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)
		self.ZoneQuestSubMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) then
					self:Hide()
				end
			end)
		end)

		-- Add buttons to the submenu
		for _, item in ipairs(RQE.BuildZoneQuestMenuList()) do
			self.ZoneQuestSubMenu:AddButton(item.text, item.func)
		end
	end
end


-- Create the Quest Line Submenu
function RQE:CreateQuestLineSubMenu()
	if not self.QuestLineSubMenu then
		self.QuestLineSubMenu = CreateFrame("Frame", "RQEQuestLineSubMenu", UIParent, "BackdropTemplate")
		Mixin(self.QuestLineSubMenu, RQE_QuestMenuMixin)
		self.QuestLineSubMenu:OnLoad()
		self.QuestLineSubMenu:SetSize(150, 200)
		self.QuestLineSubMenu:SetFrameStrata("DIALOG")
		self.QuestLineSubMenu:Hide()

		-- Keep submenu visible when mouse is over it
		self.QuestLineSubMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)
		self.QuestLineSubMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) then
					self:Hide()
				end
			end)
		end)

		-- Add buttons to the submenu
		for _, item in ipairs(RQE.BuildQuestLineMenuList()) do
			self.QuestLineSubMenu:AddButton(item.text, item.func)
		end
	end
end


------------------------------------------------------
-- 5. Special Quest Item Buttons
------------------------------------------------------

-- -- Creates or Updates the Special Quest Item to be placed in line with its quest within the RQEQuestFrame
-- local frame = CreateFrame("Frame")
-- frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Fires when player leaves combat
-- frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Fires when player enters combat
-- frame.actionsPending = false

-- frame:SetScript("OnEvent", function(self, event)
	-- if event == "PLAYER_REGEN_ENABLED" then
		-- if self.actionsPending then
			-- -- Perform the pending updates when it is safe to do so
			-- RQE:UpdateQuestItemButtons()
			-- self.actionsPending = false
		-- end
	-- elseif event == "PLAYER_REGEN_DISABLED" then
		-- self.actionsPending = false  -- Reset any pending actions if combat starts
	-- end
-- end)

-- function RQE:CreateOrUpdateQuestItemButton(questID, index)
	-- local buttonName = "RQEQuestItemButton" .. questID
	-- local questButton = _G[buttonName]

	-- if not questButton then
		-- questButton = CreateFrame("Button", buttonName, RQE.RQEQuestFrame, "SecureActionButtonTemplate")
		-- questButton:SetSize(36, 36)  -- Set size only during creation to avoid taint
	-- end

	-- local link, itemID, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(index)

	-- if itemID then
		-- C_Item.RequestLoadItemDataByID(itemID)  -- Ensure the item data is loaded
		-- local itemInfo = C_Item.GetItemInfo(itemID)
		-- questButton:SetNormalTexture(itemInfo and itemInfo.iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark")

		-- -- Ensure cooldown frame exists
		-- if not questButton.cooldown then
			-- questButton.cooldown = CreateFrame("Cooldown", nil, questButton, "CooldownFrameTemplate")
			-- questButton.cooldown:SetAllPoints()
		-- end

		-- -- Cooldown handling
		-- local start, duration, enable = GetQuestLogSpecialItemCooldown(index)
		-- if start and duration > 0 then
			-- questButton.cooldown:SetCooldown(start, duration)
		-- end

		-- -- Tooltip and Click Handling
		-- questButton:SetScript("OnEnter", function(self)
			-- GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			-- if link then GameTooltip:SetHyperlink(link) end
			-- GameTooltip:Show()
		-- end)
		-- questButton:SetScript("OnLeave", GameTooltip_Hide)
		-- questButton:SetScript("OnClick", function() UseQuestLogSpecialItem(index) end)
		-- if not InCombatLockdown() then  -- Only hide if not in combat
			-- questButton:Show()
		-- else
			-- frame.actionsPending = true  -- Mark that actions are pending due to combat
		-- end
	-- else
		-- if not InCombatLockdown() then  -- Only hide if not in combat
			-- questButton:Hide()
		-- else
			-- frame.actionsPending = true  -- Mark that actions are pending due to combat
		-- end
	-- end
-- end


-- -- Call this function whenever quest tracking is updated
-- function RQE:UpdateQuestItemButtons()
	-- if InCombatLockdown() then
		-- frame.actionsPending = true  -- Defer updates if in combat
		-- return
	-- end

	-- local numEntries = C_QuestLog.GetNumQuestLogEntries()
	-- for i = 1, numEntries do
		-- local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		-- if questID then
			-- RQE:CreateOrUpdateQuestItemButton(questID, i)
		-- end
	-- end
-- end



----------------------------------------------------
-- 6. Button Initialization (QuestFrame headers)
----------------------------------------------------

-- Code to be used for any buttons that are placed on the child headers of RQEQuestFrame


----------------------------------------------------
-- 7. Button Initialization (DebugFrame)
----------------------------------------------------

function RQE.Buttons.CreateDebugLogCloseButton(logFrame)
	-- Ensure the frame is valid
	if not logFrame then return end

	local closeButton = CreateFrame("Button", nil, logFrame, "UIPanelCloseButton")
	closeButton:SetSize(18, 18)
	closeButton:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -6, -6)
	closeButton:SetScript("OnClick", function(self, button)
		logFrame:Hide()
	end)
end


----------------------------------------------------
-- 8. Finalization
----------------------------------------------------

-- Function to create and initialize the SearchBox
function RQE.Buttons.CreateSearchBox(RQEFrame)
	--Ace3 SearchBox
end