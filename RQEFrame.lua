--[[ 

RQEFrame.lua
Retail main quest helper layout, interactions, persistence, and separate-focus UI

]]


--------------------------------------------------
-- #1. 🌐 Namespace, Runtime & Menu State
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Addon Namespace & Shared Frame State
	-------------------------------------------------------

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


	-------------------------------------------------------
	-- #1b. Retail Frame Lock State
	-------------------------------------------------------

	-- Initialize to some state (locked or unlocked, based on your preference)
	local isFrameLocked = RQE.db.profile.lockRQEFrame == true


	-------------------------------------------------------
	-- #1c. Static Frame Menu Definition
	-------------------------------------------------------

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


--------------------------------------------------
-- #2. 👥 Group State Cache
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Party & Raid State
	-------------------------------------------------------

	-- Variable to keep track of the last known group size and type
	local lastGroupSize = 0
	local lastGroupType = "none" -- "none", "party", "raid", "instance"


--------------------------------------------------
-- #3. 🖱️ RQEFrame Context Menus
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Menu Frame & Dynamic Labels
	-------------------------------------------------------

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


	-------------------------------------------------------
	-- #3b. Quest-Specific Context Menu
	-------------------------------------------------------

	-------------------------------------------------------
	-- #3c. General Frame Context Menu
	-------------------------------------------------------

	-- Function to Show Right-Click Dropdown Menu
	function ShowQuestDropdownRQEFrame(self, questID)
		MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
			local isPlayerInGroup = IsInGroup()
			local isQuestShareable = C_QuestLog.IsPushableQuest(questID)
			local questLabel = questID and tostring(questID) or RQE.searchedQuestID or RQE.CurrentDisplayedQuestID or "<Nothing Tracked>"

			if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				if RQE_SandboxEditor then
					rootDescription:CreateButton("Open Sandbox", function() RQE_SandboxEditor:Show() end)
				end
				rootDescription:CreateButton("Print Supertracked Quest (Sandbox/DB)", function() RQE.PrintSupertrackedQuest() end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Print coordinateHotspot for [questID stepIndex]", function() RQE.ShowPrintCoordsPopup() end)
				if questLabel ~= "<Nothing Tracked>" then
					rootDescription:CreateButton("Print coordinateHotspot for QuestID " .. questLabel .. " [stepIndex]", function() RQE.ShowPrintCoordsForDisplayedQuestPopup(questLabel) end)
				end
				rootDescription:CreateButton("Print gossipOptions", function() DevTools_Dump(RQE.API.GetGossipOptions()) end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Debug Player Coordinates/TomTom Hotspots", function() RQE:Debug_PlayerCoordinates() end)
			end

			rootDescription:CreateButton("Set Waypoint to Closest Flight Master", function() RQE:SetTomTomWaypointToClosestFlightMaster() end)
			rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)

			if isPlayerInGroup and isQuestShareable then
				rootDescription:CreateButton("Share Quest", function() C_QuestLog.SetSelectedQuest(questID); QuestLogPushQuest(); end)
			end

			if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				if RQE.db.profile.enableStepControls then
					rootDescription:CreateButton("|cff00ff00Disable StepIndex Manual + Enable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickAndStepControls(); end)		-- Green color
					rootDescription:CreateButton("|cffff0000Disable StepIndex Manual Control|r", function() RQE:ToggleStepControls(); end)		-- Red color
				else
					rootDescription:CreateButton("|cffff0000Enable StepIndex Manual + Disable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickAndStepControls(); end)		-- Red color
					rootDescription:CreateButton("|cffffff00Enable StepIndex Manual Control|r", function() RQE:ToggleStepControls(); end)		-- Yellow color
				end

				if RQE.db.profile.autoClickWaypointButton then
					rootDescription:CreateButton("|cffffff00Disable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickWaypointButton(); end)	-- Yellow color
				else
					rootDescription:CreateButton("|cff00ff00Enable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickWaypointButton(); end)		-- Green color
				end
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			end

			rootDescription:CreateButton("Untrack Quest", function() C_QuestLog.RemoveQuestWatch(questID); RQE:ClearFrameData(); end)
			rootDescription:CreateButton("Abandon Quest", function() RQE:AbandonQuest(questID); end)
			rootDescription:CreateButton("View Quest", function() OpenQuestLogToQuestDetails(questID) end)

			-- uiMapID is optional.  Supplying the player's current map makes this
			-- lookup fail when a tracked quest belongs to a questline on another map.
			local questLineInfo = RQE.API.GetQuestLineInfo(questID)
			if questLineInfo and questLineInfo.questLineID then
				rootDescription:CreateButton("Print Questline", function()
					RQE.PrintQuestlineDetails(questLineInfo.questLineID, questID, questLineInfo)
				end)
			end

			rootDescription:CreateButton("Show Wowhead Link", function() RQE:ShowWowheadLink(questID) end)
			rootDescription:CreateButton("Search Warcraft Wiki", function() RQE:ShowWowWikiLink(questID) end)
			rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			rootDescription:CreateButton(isFrameLocked and "Unlock Quest Helper Position & Size" or "Lock Quest Helper Position & Size", function()
				RQE.ToggleFrameLock()
			end)
			rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)

			if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
				rootDescription:CreateButton("Reset frames to Default size & position", function() RQE:ResetFrameAndSizeToDefault() end)
			end
		end)
	end


	-- Function to Show Right-Click Dropdown Menu
	function ShowDropdownRQEFrame(self)
		MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
			local questLabel = questID and tostring(questID) or RQE.searchedQuestID or RQE.CurrentDisplayedQuestID or "<Nothing Tracked>"

			if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				if RQE_SandboxEditor then
					rootDescription:CreateButton("Open Sandbox", function() RQE_SandboxEditor:Show() end)
				end
				rootDescription:CreateButton("Print Supertracked Quest (Sandbox/DB)", function() RQE.PrintSupertrackedQuest() end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Print coordinateHotspot for [questID stepIndex]", function() RQE.ShowPrintCoordsPopup() end)
				if questLabel ~= "<Nothing Tracked>" then
					rootDescription:CreateButton("Print coordinateHotspot for QuestID " .. questLabel .. " [stepIndex]", function() RQE.ShowPrintCoordsForDisplayedQuestPopup(questLabel) end)
				end
				rootDescription:CreateButton("Print gossipOptions", function() DevTools_Dump(RQE.API.GetGossipOptions()) end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				if RQE.db.profile.enableStepControls then
					rootDescription:CreateButton("|cff00ff00Disable StepIndex Manual + Enable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickAndStepControls(); end)		-- Green color
					rootDescription:CreateButton("|cffff0000Disable StepIndex Manual Control|r", function() RQE:ToggleStepControls(); end)		-- Red color
				else
					rootDescription:CreateButton("|cffff0000Enable StepIndex Manual + Disable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickAndStepControls(); end)		-- Red color
					rootDescription:CreateButton("|cffffff00Enable StepIndex Manual Control|r", function() RQE:ToggleStepControls(); end)		-- Yellow color
				end

				if RQE.db.profile.autoClickWaypointButton then
					rootDescription:CreateButton("|cffffff00Disable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickWaypointButton(); end)	-- Yellow color
				else
					rootDescription:CreateButton("|cff00ff00Enable Auto Click Waypoint Control|r", function() RQE:ToggleAutoClickWaypointButton(); end)		-- Green color
				end
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Debug Player Coordinates/TomTom Hotspots", function() RQE:Debug_PlayerCoordinates() end)
			end

			rootDescription:CreateButton("Set Waypoint to Closest Flight Master", function() RQE:SetTomTomWaypointToClosestFlightMaster() end)

			-- Only show RQE buttons if the RQE_Contribution addon is loaded
			if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				rootDescription:CreateButton("Track Quests in DB without Steps", function() RQE.TrackDBQuestsWithoutSteps() end)
				rootDescription:CreateButton("Track Quests in DB with Steps", function() RQE.TrackDBQuestsWithSteps() end)
				rootDescription:CreateButton("Track Quests Not in DB", function() RQE.TrackQuestsNotInDB() end)
			end

			rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			rootDescription:CreateButton(isFrameLocked and "Unlock Quest Helper Position & Size" or "Lock Quest Helper Position & Size", function()
				RQE.ToggleFrameLock()
			end)
			rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)

			if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
				rootDescription:CreateButton("Reset frames to Default size & position", function() RQE:ResetFrameAndSizeToDefault() end)
			end
		end)
	end


--------------------------------------------------
-- #4. 📦 UI Library Imports
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. AceGUI Reference
	-------------------------------------------------------

	local AceGUI = LibStub("AceGUI-3.0")


--------------------------------------------------
-- #5. 🖼️ Main Quest Helper Frame Construction
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Bootstrap Diagnostics & Main Viewport
	-------------------------------------------------------

	-- Debug to check state of main Frame
	RQE.debugLog("Value of RQE.db", RQE.db)
	if RQE and RQE.db and RQE.db.profile then
		RQE.debugLog("RQEFrame.lua loaded. Checking state of isMinimized:", RQE.db.profile.isMinimized)
	else
		RQE.debugLog("RQE, RQE.db, or RQE.db.profile is nil.")
	end


	-- Create the main frame
	RQEFrame = CreateFrame("Frame", "RQE.RQEFrame", UIParent, "BackdropTemplate")
	local anchorPoint, xPos, yPos, frameWidth, frameHeight = RQE:GetFrameGeometry("RQEFrame")
	RQEFrame:SetSize(frameWidth, frameHeight)
	RQEFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	RQEFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 0, right = 0, top = 1, bottom = 0 }
	})
	RQEFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.MainFrameOpacity)
	if RQE.UI then RQE.UI:StylePanel(RQEFrame, RQE.db.profile.MainFrameOpacity, "main") end
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
	content:SetPoint("TOPLEFT", ScrollFrame, "TOPLEFT", 0, 0)
	content:SetSize(math.max(1, ScrollFrame:GetWidth()), 600)
	ScrollFrame:SetScrollChild(content)
	ScrollFrame:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(math.max(1, width or self:GetWidth() or 1))
		if RQE.UpdateContentSize then RQE:UpdateContentSize() end
	end)


	-------------------------------------------------------
	-- #5b. Header & Scrollbar Controls
	-------------------------------------------------------

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
	if RQE.UI then RQE.UI:StyleHeader(header, false) end
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


	-- Keep a trackless slider as the scroll-position controller in both themes.
	-- Azure & Gold exposes only its proportional gold thumb; legacy mode keeps
	-- wheel scrolling but draws no bar, trough, or arrow buttons.
	local slider = CreateFrame("Slider", nil, RQEFrame)
	RQE.slider = slider
	slider:SetOrientation("VERTICAL")
	slider:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -7, -55)
	slider:SetPoint("BOTTOMRIGHT", RQEFrame, "BOTTOMRIGHT", -7, 14)
	slider:SetMinMaxValues(0, 0)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(false)
	slider:EnableMouse(true)
	slider.scrollStep = 1
	slider:SetWidth(10)
	slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
	local thumb = slider:GetThumbTexture()
	thumb:SetColorTexture(255 / 255, 215 / 255, 0 / 255, 1) -- #FFD700
	thumb:SetSize(4, 54)
	slider:Hide()

	slider:SetScript("OnValueChanged", function(self, value)
		ScrollFrame:SetVerticalScroll(value)
	end)
	slider:EnableMouseWheel(true)
	slider:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(self:GetValue() - delta * 40)
	end)
	RQE.API.ConfigureScrollbarDrag(slider)

	function RQE.UpdateQuestHelperScrollbarVisual(contentHeight)
		if not RQE.slider or not RQE.ScrollFrame then return end
		local _, maximum = RQE.slider:GetMinMaxValues()
		local themed = RQE.UI and RQE.UI:IsEnabled()
		local questIDText = RQE.QuestIDText and RQE.QuestIDText:GetText()
		local questNameText = RQE.QuestNameText and RQE.QuestNameText:GetText()
		local displayedQuestID = tonumber(RQE.DisplayedQuestID)
		local searchedQuestID = tonumber(RQE.searchedQuestID)
		local superTrackedQuestID = RQE.API and RQE.API.GetSuperTrackedQuestID
			and tonumber(RQE.API.GetSuperTrackedQuestID())
		local hasDisplayedQuest = (displayedQuestID and displayedQuestID > 0)
			or (searchedQuestID and searchedQuestID > 0)
			or (superTrackedQuestID and superTrackedQuestID > 0)
			or (type(questIDText) == "string" and questIDText:find("%S"))
			or (type(questNameText) == "string" and questNameText:find("%S"))
		if not themed or not hasDisplayedQuest or not RQE.ScrollFrame:IsShown()
			or not maximum or maximum <= 0 then
			RQE.slider:Hide()
			return
		end

		local viewportHeight = math.max(1, RQE.ScrollFrame:GetHeight() or 1)
		local totalHeight = math.max(viewportHeight, tonumber(contentHeight)
			or (viewportHeight + maximum))
		local trackHeight = math.max(1, RQE.slider:GetHeight() or viewportHeight)
		local thumbHeight = math.min(trackHeight, math.max(42,
			math.floor(trackHeight * viewportHeight / totalHeight + 0.5)))
		local sliderThumb = RQE.slider:GetThumbTexture()
		if sliderThumb then
			sliderThumb:SetColorTexture(255 / 255, 215 / 255, 0 / 255, 1) -- #FFD700
			sliderThumb:SetSize(4, thumbHeight)
			sliderThumb:Show()
		end
		RQE.slider:Show()
	end


	-------------------------------------------------------
	-- #5c. Frame Context Click & Scroll Reset
	-------------------------------------------------------

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


	-------------------------------------------------------
	-- #5d. Unknown Quest & Group Search Controls
	-------------------------------------------------------

	-- Create a button for unknown quests in the top-left corner of RQEFrame content
	-- Call the function from WPUtil.lua to create the button
	RQE.UnknownQuestButton = CreateFrame("Button", nil, content)	-- TAINT?: possibly source if run in combat
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
	RQE.UnknownQuestButtonLabel = label


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
	RQE.SearchGroupButtonLabel = sgLabel


	-- Add bg to the global RQE table
	RQE.bg = bg
	RQE.sgbg = sgBg
	if RQE.UI then
		RQE.UI:StyleLegacyActionButton(RQE.UnknownQuestButton, bg, label, "WaypointTarget")
		RQE.UI:StyleLegacyActionButton(RQE.SearchGroupButton, sgBg, sgLabel, "SearchGroup")
	end


	-------------------------------------------------------
	-- #5e. Control Tooltips & Press Feedback
	-------------------------------------------------------

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


	-------------------------------------------------------
	-- #5f. Objective Coloring & Quest Identity Fields
	-------------------------------------------------------

	-- Function to Colorize the RQEFrame Quest Helper Module
	local function colorizeObjectives(questID)
		local objectivesData = RQE.API.GetQuestObjectives(questID)
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


	-- Mirror the active quest's timer/failure status in the Quest Helper. Retail
	-- supplies quest-ID-based state through the normalized modern API wrappers.
	RQE.QuestStatusText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	RQE.QuestStatusText:SetPoint("TOPLEFT", RQE.QuestNameText, "BOTTOMLEFT", -35, -12)
	RQE.QuestStatusText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
	RQE.QuestStatusText:SetJustifyH("LEFT")
	RQE.QuestStatusText:SetJustifyV("TOP")
	RQE.QuestStatusText:SetWidth(RQEFrame:GetWidth() - 35)
	RQE.QuestStatusText:SetHeight(0)
	RQE.QuestStatusText:SetText("")
	RQE.QuestStatusText:Hide()


	-------------------------------------------------------
	-- #5g. Direction, Availability & Quest Timer Status
	-------------------------------------------------------

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

	-- Keep the complete direction value on the FontString for tooltip and routing
	-- consumers, then let the shared layout decide whether it merits a visible row.
	local oldSetDirectionText = RQE.DirectionTextFrame.SetText
	-- Wrap direction updates so every new value also refreshes the shared Quest Helper layout.
	function RQE.DirectionTextFrame:SetText(text)
		local result = oldSetDirectionText(self, text)
		if RQE.RefreshQuestHelperTextLayout then
			RQE:RefreshQuestHelperTextLayout()
		end
		return result
	end


	-- Anchor the direction row beneath the optional quest-status row while accounting for themed search controls.
	local function AnchorDirectionBelowQuestStatus(hasStatus)
		local themed = RQE.UI and RQE.UI:IsEnabled()
		local searchGroupShown = RQE.SearchGroupButton and RQE.SearchGroupButton:IsShown()
		local noGroupTextOffset = themed and -30 or -35
		RQE.QuestStatusText:ClearAllPoints()
		if themed and searchGroupShown then
			-- Keep timer/failure status clear of the two-button W/SG stack without
			-- shifting the shared text column noticeably farther right.
			RQE.QuestStatusText:SetPoint("TOPLEFT", RQE.SearchGroupButton, "BOTTOMLEFT", 5, -8)
		else
			RQE.QuestStatusText:SetPoint("TOPLEFT", RQE.QuestNameText, "BOTTOMLEFT", noGroupTextOffset, -20)
		end
		RQE.DirectionTextFrame:ClearAllPoints()
		if hasStatus then
			RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.QuestStatusText, "BOTTOMLEFT", 0, -10)
		elseif searchGroupShown then
			if themed then
				RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.SearchGroupButton, "BOTTOMLEFT", 5, -12)
			else
				RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.SearchGroupButton, "BOTTOMLEFT", 0, -20)
			end
		else
			RQE.DirectionTextFrame:SetPoint("TOPLEFT", RQE.QuestNameText, "BOTTOMLEFT", noGroupTextOffset, -20)
		end
	end


	-- Identify recurring or world quests whose expiration is availability data rather than a failure countdown.
	local function IsQuestHelperAvailabilityTimer(questID)
		if RQE.API.IsWorldQuest and RQE.API.IsWorldQuest(questID) then
			return true
		end
		local questLogIndex = RQE.API.GetLogIndexForQuestID
			and RQE.API.GetLogIndexForQuestID(questID)
		local questInfo = questLogIndex and RQE.API.GetQuestLogInfo
			and RQE.API.GetQuestLogInfo(questLogIndex)
		local frequency = questInfo and tonumber(questInfo.frequency)
		local frequencyEnum = Enum and Enum.QuestFrequency
		local daily = frequencyEnum and tonumber(frequencyEnum.Daily) or 1
		local weekly = frequencyEnum and tonumber(frequencyEnum.Weekly) or 2
		local scheduled = frequencyEnum and tonumber(frequencyEnum.ResetByScheduler) or 3
		return frequency ~= nil
			and (frequency == daily or frequency == weekly or frequency == scheduled)
	end


	-- Refresh the Retail quest failure or countdown status and reposition the direction row beneath it.
	local function UpdateRetailQuestStatusText()
		local superTrackedQuestID = RQE.API.GetSuperTrackedQuestID
			and RQE.API.GetSuperTrackedQuestID()
		local questID = tonumber(RQE.searchedQuestID)
			or tonumber(RQE.DisplayedQuestID)
			or tonumber(superTrackedQuestID)
		local statusText, isFailed, isUrgent
		local suppressAvailabilityTimer = questID
			and IsQuestHelperAvailabilityTimer(questID)

		if questID and RQE.API.IsQuestFailed and RQE.API.IsQuestFailed(questID) then
			statusText, isFailed = FAILED or "Failed", true
		elseif questID and not suppressAvailabilityTimer
			and RQE.API.GetQuestTimeRemainingSeconds then
			local secondsLeft = RQE.API.GetQuestTimeRemainingSeconds(questID)
			if secondsLeft ~= nil then
				local displaySeconds = math.max(0, math.ceil(secondsLeft))
				local timeText = SecondsToTime and SecondsToTime(displaySeconds)
					or tostring(displaySeconds)
				statusText = (TIME_REMAINING or "Time Remaining:") .. " " .. timeText
				isUrgent = displaySeconds <= 59
			end
		end

		local wasShown = RQE.QuestStatusText:IsShown()
		RQE.QuestStatusText:SetText(statusText or "")
		if isFailed then
			RQE.QuestStatusText:SetTextColor(1, 51/255, 51/255)
		elseif isUrgent then
			RQE.QuestStatusText:SetTextColor(1, 102/255, 51/255)
		else
			RQE.QuestStatusText:SetTextColor(1, 170/255, 119/255)
		end
		RQE.QuestStatusText:SetShown(statusText ~= nil)
		AnchorDirectionBelowQuestStatus(statusText ~= nil)
		if RQE.RefreshQuestHelperTextLayout then
			RQE:RefreshQuestHelperTextLayout()
		end

		if wasShown ~= (statusText ~= nil) and RQE.UpdateContentSize then
			RQE:UpdateContentSize()
		end
	end


	local questStatusUpdater = CreateFrame("Frame", nil, RQEFrame)
	questStatusUpdater.elapsed = 0
	questStatusUpdater:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		if self.elapsed < 0.25 then return end
		self.elapsed = 0
		UpdateRetailQuestStatusText()
	end)


	-------------------------------------------------------
	-- #5h. Description & Objective Adaptive Layout
	-------------------------------------------------------

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
	-- Shorten long quest descriptions before passing them to the compact Quest Helper display.
	function RQE.QuestDescription:SetText(text)
		local displayText = text
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
			displayText = truncated
		end

		local result = oldSetText(self, displayText)
		if RQE.RefreshQuestHelperTextLayout then
			RQE:RefreshQuestHelperTextLayout()
		end
		return result
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


	-- Return whether a Quest Helper FontString currently contains visible, non-whitespace text.
	local function HasQuestHelperText(fontString)
		local text = fontString and fontString:GetText()
		return type(text) == "string" and text:find("%S") ~= nil
	end


	-- Normalize displayed Quest Helper text for reliable duplicate and fallback comparisons.
	local function NormalizeQuestHelperText(text)
		if type(text) ~= "string" then return "" end
		return text:gsub("|c%x%x%x%x%x%x%x%x", "")
			:gsub("|r", "")
			:lower()
			:gsub("^%s+", "")
			:gsub("%s+$", "")
			:gsub("[%.!]+$", "")
	end


	-- Reflow the variable Quest Helper rows onto the nearest visible predecessor.
	-- The fallback strings stay populated for addon logic, but do not consume a row.
	function RQE:RefreshQuestHelperTextLayout()
		if not (RQE.QuestStatusText and RQE.DirectionTextFrame
			and RQE.QuestDescription and RQE.QuestObjectives) then return end

		local hasStatus = RQE.QuestStatusText:IsShown()
		local normalizedDirection = NormalizeQuestHelperText(RQE.DirectionTextFrame:GetText())
		local normalizedDescription = NormalizeQuestHelperText(RQE.QuestDescription:GetText())
		local hasDirection = HasQuestHelperText(RQE.DirectionTextFrame)
			and normalizedDirection ~= "no direction available"
		local hasDescription = HasQuestHelperText(RQE.QuestDescription)
			and normalizedDescription ~= "no description available"
		local hasObjectives = HasQuestHelperText(RQE.QuestObjectives)
		local signature = table.concat({
			hasStatus and "1" or "0",
			hasDirection and "1" or "0",
			hasDescription and "1" or "0",
			hasObjectives and "1" or "0",
			(RQE.UI and RQE.UI:IsEnabled()) and "1" or "0",
			(RQE.SearchGroupButton and RQE.SearchGroupButton:IsShown()) and "1" or "0",
			tostring(RQE.DirectionTextFrame:GetText() or ""),
			tostring(RQE.QuestDescription:GetText() or ""),
			tostring(RQE.QuestObjectives:GetText() or ""),
		}, ":")
		if RQE._questHelperTextLayoutSignature == signature then return end
		RQE._questHelperTextLayoutSignature = signature

		AnchorDirectionBelowQuestStatus(hasStatus)
		RQE.DirectionTextFrame:SetShown(hasDirection)
		RQE.QuestDescription:SetShown(hasDescription)
		RQE.QuestObjectives:SetShown(hasObjectives)

		local firstContent = hasDescription and RQE.QuestDescription or RQE.QuestObjectives
		firstContent:ClearAllPoints()
		if hasDirection then
			firstContent:SetPoint("TOPLEFT", RQE.DirectionTextFrame, "BOTTOMLEFT", 0, -17)
		elseif hasStatus then
			-- Occupy the same first row that DirectionText would have used.
			firstContent:SetPoint("TOPLEFT", RQE.QuestStatusText, "BOTTOMLEFT", 0, -10)
		else
			-- DirectionText retains the theme/button-aware base anchor even while hidden.
			firstContent:SetPoint("TOPLEFT", RQE.DirectionTextFrame, "TOPLEFT", 0, 0)
		end

		if hasDescription then
			RQE.QuestObjectives:ClearAllPoints()
			RQE.QuestObjectives:SetPoint("TOPLEFT", RQE.QuestDescription, "BOTTOMLEFT", 0, -17)
		end

		if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end
		if RQE.UpdateContentSize then RQE:UpdateContentSize() end
	end


	local oldSetObjectivesText = RQE.QuestObjectives.SetText
	RQE.QuestObjectives.RQERawSetText = oldSetObjectivesText
	-- Reflow the dependent Quest Helper rows whenever the displayed objectives change.
	function RQE.QuestObjectives:SetText(text)
		local result = oldSetObjectivesText(self, text)
		local questID = tonumber(RQE.searchedQuestID)
			or tonumber(RQE.DisplayedQuestID)
			or (RQE.API.GetSuperTrackedQuestID
				and tonumber(RQE.API.GetSuperTrackedQuestID()))
		local hasObjectiveText = type(text) == "string" and text:find("%S") ~= nil
		if hasObjectiveText and questID and RQE.ApplyTrackerObjectiveDisplay then
			RQE.ApplyTrackerObjectiveDisplay(
				RQEFrame, questID, self, RQE.content, text)
		elseif RQEFrame.RQEProgressBar then
			RQEFrame.RQEProgressBar:Hide()
		end
		if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end
		RQE:RefreshQuestHelperTextLayout()
		return result
	end


	-- Direction text can change after a map, zone, or minimap-subzone transition
	-- without the supertracked quest changing. Refresh just this value and reflow.
	function RQE:RefreshQuestHelperDirectionForLocation()
		local superTrackedQuestID = RQE.API.GetSuperTrackedQuestID
			and tonumber(RQE.API.GetSuperTrackedQuestID())
		local searchedQuestID = tonumber(RQE.searchedQuestID)
		if searchedQuestID and searchedQuestID ~= superTrackedQuestID then
			RQE:RefreshQuestHelperTextLayout()
			return
		end

		local questID = superTrackedQuestID or tonumber(RQE.DisplayedQuestID)
		if not questID then
			RQE:RefreshQuestHelperTextLayout()
			return
		end

		local directionText = RQE.GetCoordOrderDirection
			and RQE:GetCoordOrderDirection(questID)
		if not directionText or directionText == "" then
			directionText = RQE.API.GetNextWaypointText
				and RQE.API.GetNextWaypointText(questID)
		end
		if directionText == "" then directionText = nil end
		RQEFrame.DirectionText = directionText
		RQE.DirectionTextFrame:SetText(directionText or "No direction available.")
	end


	RQE:RefreshQuestHelperTextLayout()


	-- Compact in-frame location rail shared by MapID, player coordinates, and step distance.
	---@class RQEFrame : Frame
	---@field MapIDText FontString
	RQEFrame = RQEFrame or CreateFrame("Frame", "RQEFrame", UIParent, "BackdropTemplate")

	local LocationInfoBar = CreateFrame("Frame", nil, RQEFrame, "BackdropTemplate")
	LocationInfoBar:SetHeight(24)
	LocationInfoBar:EnableMouse(false)
	LocationInfoBar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	LocationInfoBar:SetBackdropColor(0.04, 0.04, 0.04, 0.86)
	RQE.LocationInfoBar = LocationInfoBar

	local MapIDText = LocationInfoBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	MapIDText:SetPoint("LEFT", LocationInfoBar, "LEFT", 8, 0)
	MapIDText:SetJustifyH("LEFT")
	MapIDText:SetWordWrap(false)
	local initialMapID = C_Map.GetBestMapForUnit("player")
	MapIDText:SetText(initialMapID and ("Map " .. tostring(initialMapID)) or "Map —")
	LocationInfoBar.MapIDText = MapIDText
	RQEFrame.MapIDText = MapIDText


	-------------------------------------------------------
	-- #5i. Coordinates, Distance & Performance Readouts
	-------------------------------------------------------

	-- Create Font String for Coordinates
	local CoordinatesText = LocationInfoBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	CoordinatesText:SetPoint("CENTER", LocationInfoBar, "CENTER", 0, 0)
	CoordinatesText:SetJustifyH("CENTER")
	CoordinatesText:SetWordWrap(false)
	CoordinatesText:SetText("—")
	LocationInfoBar.CoordinatesText = CoordinatesText
	RQEFrame.CoordinatesText = CoordinatesText

	-- Coordinate updates must also run during Retail flight, which does not always
	-- keep PLAYER_STARTED_MOVING active.  The timer uses RQE's Blizzard-map helper.
	RQEFrame:HookScript("OnShow", function()
		if RQE and RQE.StartCoordinateDisplayUpdates then
			RQE:StartCoordinateDisplayUpdates()
		end
	end)

	RQEFrame:HookScript("OnHide", function()
		if RQE and RQE.StopCoordinateDisplayUpdates then
			RQE:StopCoordinateDisplayUpdates()
		end
	end)

	if RQEFrame:IsShown() and RQE and RQE.StartCoordinateDisplayUpdates then
		RQE:StartCoordinateDisplayUpdates()
	end


	-- Create Font String for Step Distance (once)
	local StepDistanceText = LocationInfoBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	StepDistanceText:SetPoint("RIGHT", LocationInfoBar, "RIGHT", -8, 0)
	StepDistanceText:SetJustifyH("RIGHT")
	StepDistanceText:SetWordWrap(false)
	StepDistanceText:SetText("—")
	LocationInfoBar.StepDistanceText = StepDistanceText
	RQEFrame.StepDistanceText = StepDistanceText

	-- Divide the location-information bar evenly among map, coordinate, and distance fields.
	local function LayoutLocationInfoText(_, width)
		local fieldWidth = math.max(1, ((width or LocationInfoBar:GetWidth() or 0) - 24) / 3)
		MapIDText:SetWidth(fieldWidth)
		CoordinatesText:SetWidth(fieldWidth)
		StepDistanceText:SetWidth(fieldWidth)
	end
	LocationInfoBar:SetScript("OnSizeChanged", LayoutLocationInfoText)
	LayoutLocationInfoText(LocationInfoBar, LocationInfoBar:GetWidth())

	if RQE.UI then
		RQE.UI:StyleLocationInfoBar(LocationInfoBar)
		RQE.UI:RefreshLocationInfoBar()
	end


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


	-------------------------------------------------------
	-- #5j. Header Action Buttons
	-------------------------------------------------------

	-- Create buttons using functions from Buttons.lua
	RQE.Buttons.CreateClearButton(RQEFrame)
	RQE.Buttons.CreateRWButton(RQEFrame)
	RQE.Buttons.CreateSearchButton(RQEFrame)
	RQE.Buttons.CreateContributionButton(RQEFrame)
	-- RQE.Buttons.CreateQMButton(RQEFrame) -- Disabled: QF no longer controls the redesigned quest/objective trackers.
	RQE.Buttons.CreateCloseButton(RQEFrame)
	-- RQE.Buttons.CreateMaximizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider)
	-- RQE.Buttons.CreateMinimizeButton(RQEFrame, RQE.originalWidth, RQE.originalHeight, RQE.content, ScrollFrame, slider)
	RQE.Buttons.CreateNextStepButton(RQEFrame)
	RQE.Buttons.CreatePreviousStepButton(RQEFrame)
	RQE.Buttons.CreateHeaderWaypointControls(RQEFrame)
	RQE.Buttons.RefreshContributionButton()
	RQE.Buttons.UpdateHeaderNavigation()


	-- Magic Button
	RQE.Buttons.CreateMagicButton(RQEFrame) --, "TOPRIGHT")


	-- Create the ">" button
	local searchExecuteButton = CreateFrame("Button", nil, RQEFrame.SearchFrame, "UIPanelButtonTemplate")
	searchExecuteButton:SetSize(18, 18)
	searchExecuteButton:SetPoint("LEFT", SearchEditBox, "RIGHT", 5, 0)
	searchExecuteButton:SetText(">")
	if RQE.UI then RQE.UI:StyleIconButton(searchExecuteButton, "Search", { size = 22 }) end


--------------------------------------------------
-- #6. 🖱️ Frame Events, Tooltips & Display Helpers
--------------------------------------------------

	-- UpdateButtonVisibility was used only by the removed RQEFrame +/- controls.


	-------------------------------------------------------
	-- #6a. Resize & Quest Field Activation Events
	-------------------------------------------------------

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
			local questID = RQE.API.GetSuperTrackedQuestID() or RQE.DisplayedQuestID
			OpenQuestLogToQuestDetails(questID)
			return
		end
	end)


	-- Add a click event to open the map for the current QuestName
	if RQE.QuestNameText then  -- Check if QuestNameText is initialized
		RQE.QuestNameText:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not IsShiftKeyDown() then
				local questID = RQE.API.GetSuperTrackedQuestID() or RQE.DisplayedQuestID
				OpenQuestLogToQuestDetails(questID)
				return
			end
		end)
	else
		RQE.debugLog("RQE.QuestNameText is not initialized.")
	end


	-------------------------------------------------------
	-- #6b. Separate Step Text Extraction
	-------------------------------------------------------

	-- Unified helper: works for SimpleHTML, plain FontString, and old segmented text
	function RQE.GetSeparateStepText()
		local sst = RQE.SeparateStepText
		if not sst then
			return ""
		end

		-- 1) New path: SeparateStepText is a SimpleHTML (used when step has {coords:...})
		if sst.GetObjectType and sst:GetObjectType() == "SimpleHTML" then
			-- we stored this when we did: StepText.htmlText = wrappedHTML
			local html = sst.htmlText or ""

			-- strip HTML tags and WoW color codes so the tooltip doesn't look weird
			local text = html
				:gsub("<[^>]+>", "")			   -- remove all HTML tags
				:gsub("|c%x%x%x%x%x%x%x%x", "")	-- remove |cAARRGGBB
				:gsub("|r", "")					-- remove reset
				:gsub("%s+", " ")				  -- collapse whitespace
				:match("^%s*(.-)%s*$") or ""	   -- trim

			return text
		end

		-- 2) Plain FontString path (what you had originally)
		if sst.GetText then
			local txt = sst:GetText()
			if txt and txt ~= "" then
				return txt
			end
		end

		-- 3) Legacy/segmented path (your original word-wrap structure)
		--	sst._rqeSegments is a table of FontStrings we need to stitch together
		if sst._rqeSegments then
			local collected = {}
			for _, seg in ipairs(sst._rqeSegments) do
				if seg and seg.GetText then
					local t = seg:GetText()
					if t and t ~= "" then
						table.insert(collected, t)
					end
				end
			end
			return table.concat(collected, "")
		end

		return ""
	end


	-- -- Safe wrapper function that extracts the text from the new structure
	-- function RQE.GetSeparateStepText()
		-- if not RQE.SeparateStepText then return "" end
		-- if RQE.SeparateStepText.GetText then
			-- return RQE.SeparateStepText:GetText() or ""
		-- elseif RQE.SeparateStepText._rqeSegments then
			-- local collected = {}
			-- for _, seg in ipairs(RQE.SeparateStepText._rqeSegments) do
				-- if seg:IsObjectType("FontString") then
					-- table.insert(collected, seg:GetText() or "")
				-- end
			-- end
			-- return table.concat(collected, "")
		-- end
		-- return ""
	-- end


	-- -- Helper function to determine if text is FontString or SimpleHTML and then normalizes
	-- function RQE.GetSeparateStepText()
		-- if not RQE.SeparateStepText then
			-- return ""
		-- end

		-- -- Handle SimpleHTML type (has no GetText())
		-- if RQE.SeparateStepText:GetObjectType() == "SimpleHTML" then
			-- local html = RQE.SeparateStepText.htmlText or ""
			-- return html:gsub("<[^>]+>", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		-- end

		-- -- Handle FontString type
		-- if RQE.SeparateStepText.GetText then
			-- return RQE.SeparateStepText:GetText() or ""
		-- end

		-- return ""
	-- end


	-------------------------------------------------------
	-- #6c. Quest Details Tooltip Construction
	-------------------------------------------------------

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
		local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()
		extractedQuestID = RQE.DisplayedQuestID

		questID = effectiveQuestID or extractedQuestID or currentSuperTrackedQuestID
		local isWorldQuest = RQE.API.IsWorldQuest(questID)

		local questData = RQE.getQuestData(effectiveQuestID)
		local questTitle = RQE.API.GetTitleForQuestID(questID)
		GameTooltip:SetText(questTitle)

		if RQE.DatabaseSuperX and not RQE.API.IsOnQuest(questID) and not isWorldQuest then
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
		else
			-- Searched quest (not in log): use DB fallback if available
			if questData and questData.descriptionQuestText and questData.descriptionQuestText[1] then
				if RQE.searchedQuestID then
					GameTooltip:AddLine("Status: Quest not in player's log", 1, 0, 1) -- Purple color for not yet picked up
				end
				-- If you store multiple lines, print them all
				for _, line in ipairs(questData.descriptionQuestText) do
					if line and line ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(line, 1, 1, 1, true)
					end
				end
			else
				GameTooltip:AddLine("No description available.", 1, 1, 1, true)
				GameTooltip:AddLine(" ")
			end
		end

		if questID then
			-- Check if the quest is ready to be turned in
			if C_QuestLog.ReadyForTurnIn(questID) then
				GameTooltip:AddLine("Status: Ready for Turn In", 1, 1, 0) -- Yellow color for ready to turn in
			-- Check if the quest is completed
			elseif C_QuestLog.IsQuestFlaggedCompleted(questID) then
				GameTooltip:AddLine("Status: Completed", 0, 1, 0) -- Green color for completed
			else
				if RQE.searchedQuestID then
					GameTooltip:AddLine(" ")
				end
				GameTooltip:AddLine("Status: Not Completed", 1, 0, 0) -- Red color for not completed
				if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
					GameTooltip:AddLine("Status: Completed on Warband", 1, 1, 0) -- Yellow color for completed on warband
				else
					GameTooltip:AddLine("Status: Not Completed on Warband or repeatable", 1, 0, 0) -- Red color for not completed on warband
				end
			end
			GameTooltip:AddLine(" ")
		end

		-- Add objectives
		local objectivesInfo = RQE.API.GetQuestObjectives(questID)
		if objectivesInfo and #objectivesInfo > 0 then
			GameTooltip:AddLine("Objectives:")

			-- Concatenate objectives into a string and colorize
			local objectivesText = ""
			for _, objective in ipairs(objectivesInfo) do
				objectivesText = objectivesText .. objective.text .. "\n"
			end

			local colorizedObjectives = RQE.colorizeObjectives(questID)
			GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)  -- true for wrap
			GameTooltip:AddLine(" ")
		else
			-- Searched quest (or API has no objectives): use DB fallback
			if questData and questData.objectivesQuestText and questData.objectivesQuestText[1] then
				GameTooltip:AddLine("Objectives:")
				for _, obj in ipairs(questData.objectivesQuestText) do
					if obj and obj ~= "" then
						GameTooltip:AddLine(obj, 1, 1, 1, true)
					end
				end
			end
		end

		if RQE.DatabaseSuperX and not RQE.API.IsOnQuest(questID) and not isWorldQuest then
			-- Add code for the Rewards tooltip if this is a searched quest
		else
			-- Add Rewards
			RQE:QuestRewardsTooltip(GameTooltip, questID)
		end

		if RQE.API.IsOnQuest(questID) then
			-- Check if RQE.SeparateStepText exists and has text
			local stepText = RQE.GetSeparateStepText()
			if stepText ~= "" then
				local isWorldQuest = RQE.API.IsWorldQuest(questID)	
				if not isWorldQuest then
					GameTooltip:AddLine(" ")
				end
				GameTooltip:AddLine("|cfffffd9fQuest Help for Current Step:|r", 1, 1, 1, true) -- Canary title
				GameTooltip:AddLine("|cffa9a9ff" .. stepText .. "|r", nil, nil, nil, true)
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("|cffff0000No additional focus data available.|r", 1, 1, 1, true) -- Default message in red
			end

			-- Party Members' Quest Progress
			if IsInGroup() then
				if IsInRaid() then return end
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
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82) -- Aquamarine
		GameTooltip:Show()
	end


	-------------------------------------------------------
	-- #6d. Frame Hover & Quest Field Context Actions
	-------------------------------------------------------

	-- Sets flag to true if player is hovering over RQEFrame
	if RQEFrame then
		RQEFrame:SetScript("OnEnter", function()
			RQE.RQEFrameHover = true
		end)
	end


	-- Hide tooltip for the RQEFrame when moving out of the frame
	if RQEFrame then
		RQEFrame:SetScript("OnLeave", function()
			RQE.RQEFrameHover = false
			GameTooltip:Hide()
		end)
	end


	-- Add mouseover event for QuestIDText
	RQE.QuestIDText:SetScript("OnEnter", function(self)
		local questID = RQE.searchedQuestID or RQE.API.GetSuperTrackedQuestID()
		if questID then
			CreateQuestTooltip(self, questID)
		end
	end)
	RQE.QuestIDText:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	RQE.QuestIDText:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			local questID = RQE.searchedQuestID or RQE.API.GetSuperTrackedQuestID()
			if questID then
				ShowQuestDropdownRQEFrame(self, questID)
			end
		end
	end)

	-- Add mouseover event for QuestNameText
	if RQE.QuestNameText then
		RQE.QuestNameText:SetScript("OnEnter", function(self)
			local questID = RQE.searchedQuestID or RQE.API.GetSuperTrackedQuestID()
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
			local questID = RQE.searchedQuestID or RQE.API.GetSuperTrackedQuestID()
			if questID then
				ShowQuestDropdownRQEFrame(self, questID)
			end
		end
	end)


	-- Event when a dropdown item is clicked
	function RQEFrame:OnSearchResultClicked(_, arg1, _, checked)
		-- Implement what happens when a search result is clicked
	end


	-------------------------------------------------------
	-- #6e. Responsive Main Frame Widths
	-------------------------------------------------------

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
		RQE.QuestStatusText:SetWidth(newWidth - dynamicPadding - 65)
		RQE.DirectionTextFrame:SetWidth(newWidth - dynamicPadding - 55)
		RQE.QuestDescription:SetWidth(newWidth - dynamicPadding - 45)
		RQE.QuestObjectives:SetWidth(newWidth - dynamicPadding - 45)
		if RQEFrame.RQEProgressBar and RQE.LayoutObjectiveProgressBar then
			RQE.LayoutObjectiveProgressBar(RQEFrame.RQEProgressBar)
		end
		if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end

		RQE:UpdateContentSize()
	end


	-------------------------------------------------------
	-- #6f. Main Frame Scrolling & Direct Quest Display
	-------------------------------------------------------

	-- Optional: Update the scrollbar when mouse wheel is used on the ScrollFrame
	ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local value = slider:GetValue()
		if delta > 0 then
			slider:SetValue(value - 40)
		else
			slider:SetValue(value + 40)
		end
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
		local questTitle = RQE.API.GetTitleForQuestID(questID) or "Quest not found"
		self.questText:SetText("Next quest: " .. questTitle)

		-- Optionally, display other quest details here
		print("Displaying quest:", questTitle)
	end


--------------------------------------------------
-- #7. 🧰 Search, Step Controls & Group Tools
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Search Frame Construction
	-------------------------------------------------------

	-- Make this a global variable or part of the RQE table
	RQE.isSearchFrameShown = false


	-- Function to create the search frame
	function CreateSearchFrame(showFrame)
		if not showFrame then
			if RQEFrame.SearchFrame then
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
		if RQE.UI then RQE.UI:StyleAceFrame(SearchFrame) end

		-- Fixing the positioning issue
		SearchFrame.frame:ClearAllPoints()
		SearchFrame.frame:SetPoint("TOPRIGHT", RQEFrame, "TOPLEFT", 0, 0)

		-- Save reference to SearchFrame
		RQEFrame.SearchFrame = SearchFrame
	end


	-------------------------------------------------------
	-- #7b. Search Result Data Loading
	-------------------------------------------------------

	-- DisplayResults function
	function RQE.SearchModule:FetchAndDisplayQuestData(questID)
		C_QuestLog.RequestLoadQuestByID(questID)
		C_Timer.After(1, function()  -- Wait for 1 second for data to load
			local questTitle = RQE.API.GetTitleForQuestID(questID)
			local questDetail, questObjectives = GetQuestLogQuestText(questID)

			if not questTitle or not questDetail or not questObjectives then
				RQE.debugLog("Quest information not available for Quest ID: " .. questID)
				return
			end

			self:DisplayQuestDataInRQEFrame(questTitle, questDetail, questObjectives)
		end)
	end


	-------------------------------------------------------
	-- #7c. Step Text, Coordinates & Waypoint Rows
	-------------------------------------------------------

	-- Function to dynamically create StepsText and CoordsText elements
	--- @class WaypointButton : Button
	--- @field stepIndex number
	--- @field bg Texture
	function RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
		local lastClickedIndex = self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex
		local lastWaypointIndex = self.LastClickedWaypointButton
			and self.WaypointButtonIndices[self.LastClickedWaypointButton]
		self.LastClickedButtonRef, self.LastClickedWaypointButton = nil, nil
		RQE.API.ReleaseRenderGroup(content, "steps")
		self.WaypointButtonHover = false
		-- Initialize an array to store the heights
		local stepTextHeights = {}
		RQE.CurrentQuestSteps = {}
		local yOffset = -20  -- Vertical distance to move everything down by (the smaller the number the bigger the gap - so -35 < -30)
		local baseYOffset = -20

		RQE.StepsText = {}
		RQE.CoordsText = {}
		RQE.WaypointButtons = {}
		RQE.WaypointButtonIndices = {}

		-- 🧹 Create or reuse a dedicated container for hover buttons
		if not RQE.StepsHoverContainer then
			RQE.StepsHoverContainer = CreateFrame("Frame", "RQE_StepsHoverContainer", content)
			RQE.StepsHoverContainer:SetAllPoints(content)
		end

		-- Initialize or reset the MapIDs
		self.MapIDs = MapIDs  -- Save MapIDs in RQEFrame

		-- Previous text used for anchoring
		local prevText = self.QuestObjectives  -- Changed from self.QuestNameText

		-- Create new step texts
		for i = 1, #StepsText do
			local stepTextHeight = 10

			-- Create StepsText
			local raw = StepsText[i] or "No description available."
			local hasCoords = raw:match("{coords:") or raw:match("{coordblock:")
			local hasCoordblock = raw:find("{coordblock:", 1, true) ~= nil
			-- local hasCoords = raw:match("{coords:")
			local hasHoverables = raw:match("{item:") or raw:match("{spell:")
				or raw:match("{npc:") or raw:match("{object:")

			local StepText
			if false and hasCoords then
				-- 🧭 SimpleHTML for coordinate hyperlinks
				StepText = RQE.API.AcquireRenderObject(content, "steps", "SimpleHTML", nil, i)
				table.insert(RQE.StepsText, StepText)
				StepText:SetFontObject("p", GameFontNormal)
				StepText:SetFontObject("h1", GameFontNormal)
				StepText:SetFontObject("h2", GameFontNormal)
				StepText:SetJustifyH("p", "LEFT")
				StepText:SetHyperlinksEnabled(true)
				StepText:SetWidth(RQEFrame:GetWidth() - 80)

				-- Apply color to all HTML text types (paragraph and headings)
				StepText:SetTextColor("p", 1, 1, 0.8)
				StepText:SetTextColor("h1", 1, 1, 0.8)
				StepText:SetTextColor("h2", 1, 1, 0.8)

				-- Format the coords cleanly for display
				local html = raw:gsub("{coords:([^}]+)}", function(data)
					local x, y, mapID, title =
						data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)%s*;%s*waypointTitle:%s*\"([^\"]+)\"")
					if not x then
						x, y, mapID, title =
							data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)%s*;%s*waypointTitle:%s*(.+)")
					end
					if not x then
						x, y, mapID = data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)")
					end
					if not (x and y and mapID) then return data end

					-- Display label
					local label = string.format("coords: %.2f, %.2f map %s", x, y, mapID)

					-- href: use ;title: again (safe when title is quoted)
					local href
					if title then
						href = string.format("coords:%s,%s,%s;title:%s", x, y, mapID, title)
					else
						href = string.format("coords:%s,%s,%s", x, y, mapID)
					end

					-- Colors of coordinate link in StepsText
					-- return string.format('<a href="%s">|cff674ea7[%s]|r</a>', href, label)	-- Blue Marguerite
					-- return string.format('<a href="%s">|cff9933ff[%s]|r</a>', href, label)	-- Blue Violet
					-- return string.format('<a href="%s">|cff00ccff[%s]|r</a>', href, label)	-- Deep Sky Blue
					-- return string.format('<a href="%s">|cffDBA968[%s]|r</a>', href, label)	-- Equator
					-- return string.format('<a href="%s">|cffc080ff[%s]|r</a>', href, label)	-- Heliotrope
					-- return string.format('<a href="%s">|cffFFB2FF[%s]|r</a>', href, label)	-- Lavender Rose
					-- return string.format('<a href="%s">|cff33b3a6[%s]|r</a>', href, label)	-- Light Sea Green
					-- return string.format('<a href="%s">|cffB1ffd7[%s]|r</a>', href, label)	-- Magic Mint
					-- return string.format('<a href="%s">|cff7DBE6E[%s]|r</a>', href, label)	-- Mantis
					-- return string.format('<a href="%s">|cffd7b1ff[%s]|r</a>', href, label)	-- Mauve
					-- return string.format('<a href="%s">|cffb266ff[%s]|r</a>', href, label)	-- Medium Purple
					-- return string.format('<a href="%s">|cffb2ffff[%s]|r</a>', href, label)	-- Pale Turquoise
					-- return string.format('<a href="%s">|cff6c5ddc[%s]|r</a>', href, label)	-- Slate Blue
					return string.format('<a href="%s">|cff40e0d0[%s]|r</a>', href, label)	-- Turquoise
					-- return string.format('<a href="%s">|cff8eccac[%s]|r</a>', href, label)	-- Vista Blue
				end)

				-- html = html:gsub("{item:(%d+):([^}]+)}", function(itemID, name)
					-- return string.format('<a href="item:%s">|cffff66cc[%s]|r</a>', itemID, name)
				-- end)

				-- html = html:gsub("{spell:(%d+):([^}]+)}", function(spellID, name)
					-- return string.format('<a href="spell:%s">|cff66ccff[%s]|r</a>', spellID, name)
				-- end)

				html = html:gsub("\n+", "<br>")

				-- Wrap text with HTML
				local wrappedHTML = string.format('<html><body><p>%s</p></body></html>', html)
				StepText:SetText(wrappedHTML)
				StepText.htmlText = wrappedHTML  -- store HTML string for safe retrieval later

				-- Give it a provisional height so the layout engine reserves space
				StepText:SetHeight(20)
				StepText:Show()

				-- ✅ Re-measure after a tick (this keeps step 5 from collapsing)
				C_Timer.After(0.05, function()
					local h = StepText:GetContentHeight()
					if h and h > 0 then
						StepText:SetHeight(h + 4)
					else
						StepText:SetHeight(20)
					end
				end)

				-- Clickable waypoint handler
				StepText:SetScript("OnHyperlinkClick", function(self, link, text, button)
					local x, y, mapID, title =
						link:match("coords:(%d+%.?%d*),(%d+%.?%d*),(%d+);title:(.+)")
					if not x then
						x, y, mapID = link:match("coords:(%d+%.?%d*),(%d+%.?%d*),(%d+)")
					end
					if x and y and mapID then
						RQE.LastClickedCoords = { tonumber(x), tonumber(y), tonumber(mapID) }
						RQE:CreateWaypoint(
							tonumber(x),
							tonumber(y),
							tonumber(mapID),
							title and title:gsub("\"", "") or "Custom Waypoint"
						)
						if RQE.db.profile.debugLevel == "INFO" then
							print(string.format("|cff00ff00[RQE]|r Created waypoint to (%.2f, %.2f) map %s%s", x, y, mapID, (title and title ~= "") and (" - " .. title:gsub("\"", "")) or "" ))
						end
					end
				end)

				StepText:SetScript("OnHyperlinkEnter", function(_, link)
					if not link then return end

					local linkType, id = link:match("^([^:]+):(.+)$")

					if linkType == "coords" then
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
						GameTooltip:SetText("Click to create a waypoint", 1, 1, 1)
						GameTooltip:Show()
					elseif linkType == "rqeitem" then
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
						GameTooltip:SetItemByID(tonumber(id))
						GameTooltip:Show()
					elseif linkType == "rqespell" then
						GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
						GameTooltip:SetSpellByID(tonumber(id))
						GameTooltip:Show()
					end
				end)

				-- StepText:SetScript("OnHyperlinkEnter", function(_, link)
					-- if type(link) == "string" and link:match("^coords:") then
						-- GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
						-- GameTooltip:SetText("Click to create a waypoint", 1, 1, 1)
						-- GameTooltip:Show()
					-- end
				-- end)

				StepText:SetScript("OnHyperlinkLeave", function()
					GameTooltip:Hide()
				end)

				-- ✅ Make sure SimpleHTML sizes properly and wraps text
				C_Timer.After(0.05, function()
					local h = StepText:GetContentHeight()
					if h and h > 0 then
						StepText:SetHeight(h + 4)
					else
						StepText:SetHeight(20)
					end
					StepText:SetFrameStrata("HIGH")
					StepText:Show()
				end)
			else
				-- 🧾 Normal text (as before)
				StepText = RQE.API.AcquireRenderObject(content, "steps", "FontString", nil, "step:" .. i)
				table.insert(RQE.StepsText, StepText)
				StepText:SetFont("Fonts\\FRIZQT__.TTF", 12)
				StepText:SetJustifyH("LEFT")
				StepText:SetTextColor(1, 1, 0.8)
				StepText:SetSize(RQEFrame:GetWidth() - 80, 0)
				StepText:SetWordWrap(true)
				StepText:SetText("")
				RQE.RenderTextWithItemsSteps(StepText, raw, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 0.8}, RQE.StepsHoverContainer)
				if hasCoordblock then
					-- A zero-height FontString centers multi-line coordblocks across
					-- earlier step rows.  Reserve the rendered height before anchoring.
					local visualText = StepText:GetText() or ""
					local lineBreaks = select(2, visualText:gsub("\n", ""))
					local measuredHeight = StepText:GetStringHeight() or 0
					StepText:SetHeight(math.max(20, measuredHeight + 4, (lineBreaks + 1) * 14))
					StepText:SetJustifyV("TOP")
				end
			end

			StepText:SetWidth(RQEFrame:GetWidth() - 80)

			-- Create CoordsText
			local CoordText = RQE.API.AcquireRenderObject(content, "steps", "FontString", nil, "coord:" .. i)
			table.insert(RQE.CoordsText, CoordText)

			if i == 1 then
				if RQE.SeparateFocusFrame then
					local stepInset = (RQE.UI and RQE.UI:IsEnabled()) and 35 or 50
					StepText:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "BOTTOMLEFT", stepInset, yOffset)
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
			local WaypointButton = RQE.API.AcquireRenderObject(content, "steps", "Button", nil, i)
			if i == lastClickedIndex then self.LastClickedButtonRef = WaypointButton end
			if i == lastWaypointIndex then self.LastClickedWaypointButton = WaypointButton end
			WaypointButton:SetPoint("TOPRIGHT", StepText, "TOPLEFT", -10, 10)
			WaypointButton:SetSize(30, 30)  -- Set size to 30x30

			-- Use the custom texture for the background
			local bg = WaypointButton.bg or WaypointButton:CreateTexture(nil, "BACKGROUND")
			WaypointButton.bg = bg
			bg:SetAlpha(1)
			bg:SetAllPoints()

			if RQE.db.profile.enableStepControls then
				WaypointButton.stepIndex = i
				WaypointButton.bg = bg
			end

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
			if StepText.GetStringHeight then
				stepTextHeight = StepText:GetStringHeight()
			elseif StepText.GetContentHeight then
				stepTextHeight = StepText:GetContentHeight()
			end

			-- Create the number label
			local number = WaypointButton.number or WaypointButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			number:SetPoint("CENTER", WaypointButton, "CENTER")
			number:SetText(i)
			number:SetTextColor(1, 1, 0)
			WaypointButton.number = number
			if RQE.UI then RQE.UI:StyleQuestIndexButton(WaypointButton, RQE.LastClickedIdentifier == i) end

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
				-- if RQE.WaypointButtonHover then
					-- RQE:ClickWaypointButtonForIndex(i)
				-- end

				if RQE.db.profile.enableStepControls then
					if not RQE._autoClickingWaypointButton then
						RQE:SetDisplayedStepFromStepsList(i)
					end
				end

				-- Code for RWButton functionality here
				local extractedQuestID
				if RQE.QuestIDText and RQE.QuestIDText:GetText() then
					extractedQuestID = RQE.DisplayedQuestID
				end
				local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()
				local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

				if questID and not RQE:IsCoordblockWaypointProtected(questID) then
					local waypointText = C_QuestLog.GetNextWaypointText(questID)
					if not waypointText then
						C_Map.ClearUserWaypoint()
					end
				end

				if (RQE.OkayWaypointButtonToMove or RQE.WaypointButtonHover
					or RQE.hoveringOnRQEFrameAndButton)
					and not RQE:IsCoordblockWaypointProtected(questID) then
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
					RQE:OnCoordinateClicked()
					RQE.OkayWaypointButtonToMove = false
				end

				-- This part resets the texture of the last clicked button, but also contains some checks for updating identifiers.
				if RQE.LastClickedWaypointButton and RQE.LastClickedWaypointButton ~= WaypointButton then
					RQE.LastClickedWaypointButton.bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
					if RQE.UI then RQE.UI:StyleQuestIndexButton(RQE.LastClickedWaypointButton, false) end
				end

				-- Update the texture of the currently clicked button
				bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
				if RQE.UI then RQE.UI:StyleQuestIndexButton(WaypointButton, true) end

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
					RQE.questIDFromText = RQE.DisplayedQuestID
					-- RQE.questIDFromText = tonumber(RQE.QuestIDText:GetText():match("%d+"))
					if not RQE.questIDFromText then
						RQE.debugLog("Error: Invalid quest ID extracted from text")
					else
						if RQE.db.profile.debugLevel == "INFO+" then
							RQE.infoLog("Quest ID from text for macro:", RQE.questIDFromText)	-- Debug message for the current operation
						end

						-- Dynamically create/edit macro based on the super tracked quest and the step associated with the clicked waypoint button
						RQE.debugLog("Attempting to create macro")
					end
				end

				if RQE.db.profile.debugLevel == "INFO+" then
					RQE.infoLog("Quest ID from text for macro:", RQE.questIDFromText)  -- Debug message for the current operation
				end

				-- Check if MagicButton should be visible based on macro body
				C_Timer.After(1, function()
					RQE.Buttons.UpdateMagicButtonVisibility()
				end)

				local questData = RQE.getQuestData(RQE.questIDFromText)
				if questData then
					UpdateFrame(RQE.questIDFromText, questData, StepsText, CoordsText, MapIDs)
				end
				RQE.OkayWaypointButtonToMove = false
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
					RQE:OnCoordinateClicked()
				end
			end)
		end

		-- Updates the height of the RQEFrame based on the number of steps a quest has in the RQEDatabase
		if not self._stepsLayoutTimer then
			self._stepsLayoutTimer = C_Timer.NewTimer(0.5, function()
				self._stepsLayoutTimer = nil
				self:UpdateContentSize()
			end)
		end
	end


	-------------------------------------------------------
	-- #7d. Step Advancement & Objective Index State
	-------------------------------------------------------

	-- Check and Advance Steps
	function RQE:CheckAndAdvanceStep(questID)
		local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = RQE.DisplayedQuestID
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
		local objectives = RQE.API.GetQuestObjectives(questID)
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

	-- Function to check if all objectives for a given quest are completed
	function RQE:AreAllObjectivesCompleted(questID)
		-- Check if questID is valid
		if not questID or type(questID) ~= "number" or questID <= 0 then
			return false
		end

		local status, objectives = pcall(RQE.API.GetQuestObjectives, questID)

		if not status or not objectives or #objectives == 0 then
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


	-------------------------------------------------------
	-- #7e. Unknown Quest Button & Waypoint Dispatch
	-------------------------------------------------------

	-- Function that simulates a click of the UnknownQuestButton but streamlined
	function RQE.ClickUnknownQuestButton()
		RQE:QuestType() -- Runs UpdateRQEQuestFrame and UpdateRQEWorldQuestFrame as quest list is generated

		-- Validation check
		if not RQE.QuestIDText or not RQE.QuestIDText:GetText() then
			return
		end

		local extractedQuestID = RQE.DisplayedQuestID
		-- local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()
		local questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

		RQE:SaveSuperTrackedQuestToCharacter()

		-- Call function to create a waypoint using stored coordinates and mapID
		RQE:FindQuestZoneTransition(questID)
	end


	-------------------------------------------------------
	-- #7f. Group Finder Search, Creation & Delisting
	-------------------------------------------------------

	-- Function to handle group search based on the current super-tracked quest with fallback for missing activityID
	function RQE:LFG_Search(questID)
		-- Ensure the Group Finder frame is open
		if not GroupFinderFrame:IsVisible() then
			LFGListUtil_OpenBestWindow() -- Open LFG window if it's not already visible
		end

		-- Retrieve the super-tracked quest ID
		local questID = questID or RQE.currentSuperTrackedQuestID or RQE.API.GetSuperTrackedQuestID()
		if not questID or questID == 0 then
			return
		end

		-- Retrieve the activity ID for the quest
		local activityID = C_LFGList.GetActivityIDForQuestID(questID)
		local questName = C_TaskQuest.GetQuestInfoByQuestID(questID) or RQE.API.GetTitleForQuestID(questID)

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
		local questID = questID or RQE.currentSuperTrackedQuestID or RQE.API.GetSuperTrackedQuestID()
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


	-------------------------------------------------------
	-- #7g. Role Selection & Group State Updates
	-------------------------------------------------------

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
		local questID = RQE.API.GetSuperTrackedQuestID()

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


	-------------------------------------------------------
	-- #7h. Step Clearing, Dropdown & Content Sizing
	-------------------------------------------------------

	-- Function to clear StepsText in RQEFrame.lua
	function RQE:ClearStepsTextInFrame()
		if self._stepsLayoutTimer then
			self._stepsLayoutTimer:Cancel()
			self._stepsLayoutTimer = nil
		end
		RQE.API.ReleaseRenderGroup(content, "steps")
		self.StepsText, self.CoordsText, self.WaypointButtons, self.WaypointButtonIndices = {}, {}, {}, {}
		self.LastClickedButtonRef, self.LastClickedWaypointButton = nil, nil
		self.WaypointButtonHover = false
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


	-- Measure the actual bottom-most rendered element so wrapped quest text,
	-- objective bars, Separate Focus, and every database step share one scrollable
	-- document instead of estimating height from the step count.
	function RQE:UpdateContentSize()
		self.StepsText = self.StepsText or {}	-- Failsafe to ensure that table is loaded following VARIABLES_LOADED event firing
		if not (content and ScrollFrame and slider) then return end

		local viewportHeight = math.max(1, ScrollFrame:GetHeight() or 1)
		local contentTop = content:GetTop()
		local lowestBottom
		local function IncludeRegion(region)
			if not region or region == RQE.StepsHoverContainer
				or not region.IsShown or not region:IsShown() then return end
			local bottom = region.GetBottom and region:GetBottom()
			if bottom and (not lowestBottom or bottom < lowestBottom) then
				lowestBottom = bottom
			end
		end

		for _, child in ipairs({ content:GetChildren() }) do IncludeRegion(child) end
		for _, region in ipairs({ content:GetRegions() }) do
			if region.GetObjectType and region:GetObjectType() == "FontString" then
				IncludeRegion(region)
			end
		end

		local measuredHeight = viewportHeight
		if contentTop and lowestBottom then
			measuredHeight = math.max(viewportHeight, contentTop - lowestBottom + 20)
		end
		content:SetHeight(measuredHeight)

		local maximum = math.max(0, measuredHeight - viewportHeight)
		slider:SetMinMaxValues(0, maximum)
		if slider:GetValue() > maximum then slider:SetValue(maximum) end
		RQE.UpdateQuestHelperScrollbarVisual(measuredHeight)
	end


--------------------------------------------------
-- #8. 🎯 Frame Persistence & Separate Focus UI
--------------------------------------------------

	-------------------------------------------------------
	-- #8a. Search Bootstrap & Core Frame Event Binding
	-------------------------------------------------------

	-- Call to function create the search frame
	CreateSearchFrame()

	-- Event to update text widths when the frame is resized
	RQEFrame:SetScript("OnSizeChanged", function(self, width, height)
		AdjustRQEFrameWidths()
		SaveRQEFrameSize()
	end)


	-------------------------------------------------------
	-- #8b. Main Frame Position & Size Persistence
	-------------------------------------------------------

	-- Calls function to save Quest Frame Position OnDragStop
	RQEFrame:SetScript("OnDragStop", function()
		RQEFrame:StopMovingOrSizing()
		RQE:SaveFramePosition()  -- This will save the current frame position
	end)


	-- Define the function to save frame position
	function RQE:SaveFramePosition()
		-- Ignore provisional geometry and callbacks fired during profile application.
		if not RQE:CanSaveFrameGeometry() then return end
		-- Defensive checks
		if not RQE.db or not RQE.db.profile then return end

		-- Ensure framePosition table exists
		if not RQE.db.profile.framePosition then
			RQE.db.profile.framePosition = {}
		end

		-- Get the current frame position
		local point, _, relativePoint, xOfs, yOfs = RQEFrame:GetPoint()

		-- Keep position data in the same schema used by every geometry caller.
		RQE.db.profile.framePosition.anchorPoint = relativePoint or point
		RQE.db.profile.framePosition.xPos = xOfs
		RQE.db.profile.framePosition.yPos = yOfs
		RQE.db.profile.framePosition.point = nil
		RQE.db.profile.framePosition.relativePoint = nil
		RQE.db.profile.framePosition.xOffset = nil
		RQE.db.profile.framePosition.yOffset = nil
	end


	-- Restores the RQEFrame position based on DB
	function RQE:RestoreFramePosition()
		-- ADDON_LOADED may run before AceDB/world readiness or during combat.
		self:RequestProfileApply()
	end


	-- Define the function to save frame position
	function SaveRQEFrameSize()
		-- Ignore provisional geometry and callbacks fired during profile application.
		if not RQE:CanSaveFrameGeometry() then return end
		if not RQE.db or not RQE.db.profile then return end

		-- Ensure framePosition table exists
		if not RQE.db.profile.framePosition then
			RQE.db.profile.framePosition = {}
		end

		local width, height = RQEFrame:GetSize()
		RQE.db.profile.framePosition.frameWidth = width
		RQE.db.profile.framePosition.frameHeight = height
	end


	-------------------------------------------------------
	-- #8c. Header Dragging, Resize Grip & Frame Lock
	-------------------------------------------------------

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


	function RQE.IsRQEFrameLocked()
		return isFrameLocked
	end

	function RQE.SetRQEFrameLocked(locked, persist)
		isFrameLocked = locked == true
		RQEFrame:EnableMouse(true)  -- Retain right-click access while locked.
		if isFrameLocked then
			RQEFrame:SetMovable(false)
			RQEFrame:SetResizable(false)
			RQEFrame:SetScript("OnDragStart", nil)
			RQEFrame:SetScript("OnDragStop", nil)
			RQE.resizeGrip:Hide()
		else
			RQEFrame:SetMovable(true)
			RQEFrame:SetResizable(true)
			RQEFrame:RegisterForDrag("LeftButton")
			RQEFrame:SetScript("OnDragStart", RQEFrame.StartMoving)
			RQEFrame:SetScript("OnDragStop", function()
				RQEFrame:StopMovingOrSizing()
				RQE:SaveFramePosition()
			end)
			RQE.resizeGrip:Show()
		end
		if persist ~= false and RQE.db and RQE.db.profile then
			RQE.db.profile.lockRQEFrame = isFrameLocked
			local registry = LibStub("AceConfigRegistry-3.0", true)
			if registry then registry:NotifyChange("RQE_Frame") end
		end
		UpdateMenuText()  -- Make sure this function is called here
	end

	function RQE.ToggleFrameLock()
		RQE.SetRQEFrameLocked(not isFrameLocked)
	end


	-- Initialize frame lock state
	RQE.SetRQEFrameLocked(RQE.db.profile.lockRQEFrame == true, false)


	-------------------------------------------------------
	-- #8d. Focus Scroll & Location Layout Helpers
	-------------------------------------------------------

	-- Function to initialize a separate Focused Step Frame with scrolling
	local function HandleSeparateFocusMouseWheel(_, delta)
		-- ALT/CTRL/SHIFT (either left or right key) scrolls the Focus Frame
		-- anywhere inside it. A plain wheel keeps scrolling the main RQEFrame.
		local focusFrame = RQE.SeparateFocusFrame
		local modifierHeld = IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown()
		local target = focusFrame and focusFrame:IsMouseOver() and modifierHeld
			and RQE.SeparateScrollFrame or RQE.ScrollFrame
		if not target then return end
		local current = tonumber(target:GetVerticalScroll()) or 0
		local maximum = tonumber(target:GetVerticalScrollRange()) or 0
		local value = math.max(0, math.min(current - delta * 30, maximum))
		local controller = target == RQE.SeparateScrollFrame
			and RQE.SeparateFocusSlider or RQE.slider
		if controller then controller:SetValue(value)
		else target:SetVerticalScroll(value) end
	end

	-- Capture the current map, zone, and minimap names used to detect Separate Focus location changes.
	local function GetSeparateFocusLocation()
		local mapID = C_Map and C_Map.GetBestMapForUnit
			and C_Map.GetBestMapForUnit("player")
		local mapInfo = mapID and C_Map and C_Map.GetMapInfo
			and C_Map.GetMapInfo(mapID)
		local mapName = mapInfo and mapInfo.name or ""
		local zoneName = GetZoneText and GetZoneText() or ""
		local minimapZone = GetMinimapZoneText and GetMinimapZoneText() or ""
		return mapID, mapName, zoneName, minimapZone
	end

	-- Keep the Focus panel inside the Quest Helper viewport instead of inheriting
	-- the horizontal offset of whichever quest text happens to precede it. Legacy
	-- uses the clipped content width so both backdrop sides remain visible; the
	-- themed calculation retains its approved dimensions.
	function RQE:LayoutSeparateFocusFrame()
		if not (RQE.SeparateFocusFrame and RQE.content and RQE.QuestObjectives) then return end
		local contentTop = RQE.content:GetTop()
		local objectiveBottomRegion = RQEFrame.RQEProgressBar
			and RQEFrame.RQEProgressBar:IsShown()
			and RQEFrame.RQEProgressBar or RQE.QuestObjectives
		local objectivesBottom = objectiveBottomRegion:GetBottom()
		if not contentTop or not objectivesBottom then return end
		local themed = RQE.UI and RQE.UI:IsEnabled()
		local focusWidth = themed and math.max(1, RQEFrame:GetWidth() - 40)
			or math.max(1, RQE.content:GetWidth() - 10)
		local focusTop = objectivesBottom - contentTop - 10
		RQE.SeparateFocusFrame:ClearAllPoints()
		RQE.SeparateFocusFrame:SetPoint("TOPLEFT", RQE.content, "TOPLEFT", 10, focusTop)
		RQE.SeparateFocusFrame:SetWidth(focusWidth)
		if RQE.SeparateContentFrame then
			local contentWidth = math.max(1, focusWidth - 40)
			RQE.SeparateContentFrame:SetWidth(contentWidth)
			for _, child in ipairs({ RQE.SeparateContentFrame:GetChildren() }) do
				if child.GetObjectType and child:GetObjectType() == "SimpleHTML" then
					child:SetWidth(math.max(1, contentWidth - 81))
				end
			end
			for _, region in ipairs({ RQE.SeparateContentFrame:GetRegions() }) do
				if region.GetObjectType and region:GetObjectType() == "FontString" then
					region:SetWidth(math.max(1, contentWidth - 91))
				end
			end
			if RQE.SeparateStepText then
				RQE.SeparateStepText:SetWidth(math.max(1, contentWidth - 81))
			end
		end
	end


	-------------------------------------------------------
	-- #8e. Separate Focus Frame Initialization
	-------------------------------------------------------

	-- Create and configure the independent focus panel used to display the active quest step and controls.
	function RQE.InitializeSeparateFocusFrame()
		-- Create the new independent frame
		if not RQE.SeparateFocusFrame then
			RQE.SeparateFocusFrame = CreateFrame("Frame", "RQE_SeparateFocusFrame", RQE.content, "BackdropTemplate")
			-- Set the size of the frame (width, height)
			RQE.SeparateFocusFrame:SetSize(380, 125)
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
			if RQE.UI then RQE.UI:StylePanel(RQE.SeparateFocusFrame, 0.58, "focus") end
			RQE.SeparateFocusFrame:EnableMouse(true)
			RQE.SeparateFocusFrame:EnableMouseWheel(true)
			RQE.SeparateFocusFrame:SetScript("OnMouseWheel", HandleSeparateFocusMouseWheel)
			RQE.SeparateFocusFrame:Show()
		end

		-- Create the scroll frame
		if not RQE.SeparateScrollFrame then
			RQE.SeparateScrollFrame = CreateFrame("ScrollFrame", "RQE_SeparateScrollFrame", RQE.SeparateFocusFrame)
			RQE.SeparateScrollFrame:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "TOPLEFT", -5, -7)
			RQE.SeparateScrollFrame:SetPoint("BOTTOMRIGHT", RQE.SeparateFocusFrame, "BOTTOMRIGHT", -12, 10)
			RQE.SeparateScrollFrame:EnableMouseWheel(true)
			RQE.SeparateScrollFrame:SetScript("OnMouseWheel", HandleSeparateFocusMouseWheel)
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
			RQE.SeparateContentFrame:SetPoint("TOPLEFT", RQE.SeparateScrollFrame, "TOPLEFT", 0, 0)
			RQE.SeparateContentFrame:SetWidth(RQE.SeparateFocusFrame:GetWidth() - 40)  -- Adjust width for padding
			RQE.SeparateContentFrame:SetHeight(math.max(1, RQE.SeparateScrollFrame:GetHeight()))
			RQE.SeparateScrollFrame:SetScrollChild(RQE.SeparateContentFrame)
			RQE.SeparateContentFrame:EnableMouseWheel(true)
			RQE.SeparateContentFrame:SetScript("OnMouseWheel", HandleSeparateFocusMouseWheel)
			RQE.SeparateContentFrame:Show()
		end

		if not RQE.SeparateFocusSlider then
			local focusSlider = CreateFrame("Slider", nil, RQE.SeparateFocusFrame)
			RQE.SeparateFocusSlider = focusSlider
			focusSlider:SetOrientation("VERTICAL")
			focusSlider:SetPoint("TOPRIGHT", RQE.SeparateFocusFrame, "TOPRIGHT", -6, -9)
			focusSlider:SetPoint("BOTTOMRIGHT", RQE.SeparateFocusFrame, "BOTTOMRIGHT", -6, 10)
			focusSlider:SetWidth(8)
			focusSlider:SetMinMaxValues(0, 0)
			focusSlider:SetValueStep(1)
			focusSlider:SetObeyStepOnDrag(false)
			focusSlider:EnableMouse(true)
			focusSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
			local focusThumb = focusSlider:GetThumbTexture()
			focusThumb:SetColorTexture(0 / 255, 87 / 255, 184 / 255, 1) -- Azure #0057B8
			focusThumb:SetSize(4, 42)
			focusSlider:SetFrameLevel(RQE.SeparateFocusFrame:GetFrameLevel() + 5)
			focusSlider:SetScript("OnValueChanged", function(_, value)
				RQE.SeparateScrollFrame:SetVerticalScroll(value)
			end)
			focusSlider:EnableMouseWheel(true)
			focusSlider:SetScript("OnMouseWheel", function(self, delta)
				self:SetValue(self:GetValue() - delta * 30)
			end)
			RQE.API.ConfigureScrollbarDrag(focusSlider)
			focusSlider:Hide()
		end
		RQE:LayoutSeparateFocusFrame()

		-- Zone events already request a top reset, but map names and minimap
		-- subzones can settle later. Check only while this visible frame updates.
		if not RQE._separateFocusLocationWatcher then
			local watcher = CreateFrame("Frame", nil, RQE.SeparateFocusFrame)
			watcher.elapsed = 0
			watcher:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = self.elapsed + elapsed
				if self.elapsed < 0.4 then return end
				self.elapsed = 0
				if not (RQEFrame and RQEFrame:IsShown()) then return end
				local mapID, mapName, zoneName, minimapZone =
					GetSeparateFocusLocation()
				local changed = self.hasLocation and
					(self.mapID ~= mapID or self.mapName ~= mapName
						or self.zoneName ~= zoneName
						or self.minimapZone ~= minimapZone)
				self.mapID, self.mapName = mapID, mapName
				self.zoneName, self.minimapZone = zoneName, minimapZone
				self.hasLocation = true
				-- Re-evaluate direction immediately. Consume only the scroll reset while
				-- hovered so it is never applied later on mouse leave.
				if changed then
					RQE:RefreshQuestHelperDirectionForLocation()
					if not RQE.SeparateFocusFrame:IsMouseOver() then
						RQE.FocusScrollFrameToTop()
					end
				end
			end)
			watcher:Show()
			RQE._separateFocusLocationWatcher = watcher
		end


	-------------------------------------------------------
	-- #8f. Separate Focus Content Refresh
	-------------------------------------------------------

		-- Function to update the content dynamically
		function RQE:UpdateSeparateFocusFrame()
			if self._focusRefreshTimer then
				self._focusRefreshTimer:Cancel()
				self._focusRefreshTimer = nil
			end
			-- Make sure the SeparateContentFrame exists
			if not RQE.SeparateContentFrame then
				print("Error: SeparateContentFrame not found.")
				return
			end
			RQE:LayoutSeparateFocusFrame()
			-- Keep the approved Azure & Gold spacing intact while returning the
			-- borderless legacy * control and its text to a tighter left column.
			local focusTextInset = (RQE.UI and RQE.UI:IsEnabled()) and 66 or 52
			local focusTextWidth = math.max(1, RQE.SeparateContentFrame:GetWidth() - focusTextInset - 15)
			local focusTextNarrowWidth = math.max(1, RQE.SeparateContentFrame:GetWidth() - focusTextInset - 25)

			-- Coordblock selection belongs only to the current Blizzard supertrack.
			-- Clear it even when the newly selected quest has no coordblocks to render.
			local activeCoordblock = RQE.ActiveCoordblock
			if activeCoordblock
				and activeCoordblock.questID ~= tonumber(RQE.API.GetSuperTrackedQuestID()) then
				RQE.ActiveCoordblock = nil
			end

			-- Prevent re-entrant rebuilds
			if RQE.IsUpdatingSeparateFocusFrame then
				return
			end
			RQE.IsUpdatingSeparateFocusFrame = true

			-- Prevent stale delayed callbacks from older rebuilds from modifying the frame later
			RQE._SeparateFocusBuildToken = (RQE._SeparateFocusBuildToken or 0) + 1
			local buildToken = RQE._SeparateFocusBuildToken

			-- Release the Separate Focus update guard on every completed or aborted refresh path.
			local function finishUpdate()
				RQE.IsUpdatingSeparateFocusFrame = false
				if RQE.UpdateSeparateContentHeight then RQE.UpdateSeparateContentHeight() end
			end

			-- Decide which quest SeparateFocus should display
			-- Only update for REAL quests (quest log or active world quest).
			-- If the RQEFrame is showing a searched quest that's not in the log/WQ, do NOT update SeparateFocus.
			local displayedQuestID

			-- If we're in "searched quest mode" and it's not a real quest, bail out early (freeze SeparateFocus)
			local searchedID = RQE.searchedQuestID
			if searchedID and not RQE.API.IsOnQuest(searchedID) and not RQE.API.IsWorldQuest(searchedID) then
				finishUpdate()
				return
			end

			-- Otherwise, follow Blizzard supertrack, but only if it's valid
			if not RQE.API.IsSuperTrackingQuest() then
				finishUpdate()
				return
			end

			displayedQuestID = RQE.API.GetSuperTrackedQuestID()
			if not displayedQuestID or displayedQuestID <= 0 then
				finishUpdate()
				return
			end

			-- Optional: ensure the supertracked quest is actually real/active
			local isLogQuest = RQE.API.IsOnQuest(displayedQuestID)

			local hasDBQuest = RQE.getQuestData(displayedQuestID) ~= nil
			local displayedObjectives = RQE.API.GetQuestObjectives(displayedQuestID)
			local hasObjectives = type(displayedObjectives) == "table" and #displayedObjectives > 0

			if not (isLogQuest or hasDBQuest or hasObjectives) then
				finishUpdate()
				return
			end

			RQE.API.ReleaseRenderGroup(RQE.SeparateContentFrame, "focus")
			RQE.API.ReleaseRenderGroup(RQE.SeparateContentFrame, "focusRoutes")
			RQE.SeparateStepText = nil

			RQE.CurrentlySuperQuestID = displayedQuestID
			RQE:ClearSeparateFocusFrame()
			RQE.SeparateCoordblockFonts = {}
			RQE.SeparateCoordOrderButtons = {}

			-- ✅ Improved quest data handling (for DB-less quests)
			local stepIndex = tonumber(RQE.AddonSetStepIndex) or 1
			local questID = displayedQuestID
			-- local questID = C_SuperTrack.GetSuperTrackedQuestID()
			local questData = RQE.getQuestData(questID)

			local totalSteps = 0
			local stepData = nil

			-- ✅ Quest handling logic
			if not questData then
				-- Quest not in DB at all
				RQE.SeparateStepText = RQE.API.AcquireRenderObject(RQE.SeparateContentFrame, "focus", "FontString", "GameFontNormal")
				RQE.SeparateStepText:SetJustifyH("LEFT")
				RQE.SeparateStepText:SetTextColor(1, 1, 0.8)
				RQE.SeparateStepText:SetWidth(focusTextWidth)
				RQE.SeparateStepText:SetHeight(0)
				RQE.SeparateStepText:SetWordWrap(true)
				RQE.SeparateStepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", focusTextInset, -7)

				local fallbackText = "No step description available"
				RQE.SeparateStepText:SetText("")
				RQE.RenderTextWithItems(RQE.SeparateStepText, fallbackText, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 1})
				RQE.SeparateStepText:Show()
				finishUpdate()
				return
			else
				totalSteps = #questData
				if totalSteps == 0 then
					-- Quest in DB, but no steps — display "1/0"
					RQE.SeparateStepText = RQE.API.AcquireRenderObject(RQE.SeparateContentFrame, "focus", "FontString", "GameFontNormal")
					RQE.SeparateStepText:SetJustifyH("LEFT")
					RQE.SeparateStepText:SetTextColor(1, 1, 0.8)
					RQE.SeparateStepText:SetWidth(focusTextWidth)
					RQE.SeparateStepText:SetHeight(0)
					RQE.SeparateStepText:SetWordWrap(true)
					RQE.SeparateStepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", focusTextInset, -7)

					local formattedText = string.format("1/0: Quest in DB w/o any available steps.")
					RQE.SeparateStepText:SetText("")
					RQE.RenderTextWithItems(RQE.SeparateStepText, formattedText, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 1})
					RQE.SeparateStepText:Show()
					finishUpdate()
					return
				end

				-- Clamp step index safely
				if stepIndex < 1 then stepIndex = 1 end
				if stepIndex > totalSteps then stepIndex = totalSteps end

				-- Store the exact quest/step currently being displayed by the RQE frame
				RQE.CurrentDisplayedStepIndex = stepIndex
				RQE.CurrentDisplayedQuestID = questID

				stepData = questData[stepIndex]
			end

			-- Update the step text dynamically to include the step index
			local stepDescription = (stepData and stepData.description and stepData.description ~= "")
				and stepData.description or "No step description available."

			if RQE.db.profile.debugLevel == "INFO+" and stepData and stepData.description then
				local s = stepData.description
				local hasSingle = s:find("|c", 1, true) ~= nil	  -- plain find
				local hasDouble = s:find("||c", 1, true) ~= nil	 -- plain find

				-- Replace | with a visible character so you can SEE it in chat
				local visible = s:gsub("|", "¦")

				print(("DBG: has |c=%s, has ||c=%s, text=%s"):format(tostring(hasSingle), tostring(hasDouble), visible))
			end

			local formattedText = string.format("%d/%d: %s", stepIndex, totalSteps, stepDescription)
			formattedText = formattedText:gsub("||c", "|c"):gsub("||r", "|r"):gsub("||H", "|H"):gsub("||h", "|h")
			-- Generate route links only for this supertracked Focus step. StepsText
			-- continues to show exactly the authored description.
			local routeLinks = {}
			local routeQuest, routeStep, _, _, routeData, routePoints = RQE:GetCurrentCoordOrderStep()
			local playerMapID = C_Map and C_Map.GetBestMapForUnit
				and C_Map.GetBestMapForUnit("player")
			if routeQuest == tonumber(questID) and routeStep == stepIndex then
				for index, point in ipairs(routePoints) do
					if point.mapID == playerMapID then
						routeLinks[#routeLinks + 1] = {
							index = index, point = point, route = routeData,
						}
					end
				end
			end
			RQE.StepIndexForCoordMatch = stepIndex
			RQE.totalStepforQuest = totalSteps

			-- Coordblocks use the same native hyperlink path as full coordinate links,
			-- but retain their compact [x, y] display.
			local hasCoords = formattedText:match("{coords:") or formattedText:match("{coordblock:")
			local routeStartOffset

			if hasCoords then
				-- ✅ Always use SimpleHTML for the first paragraph; use FontStrings only for additional lines
				local paragraphs = {}
				local cleaned = formattedText:gsub("\r\n", "\n"):gsub("\r", "\n")
				for p in cleaned:gmatch("([^\n]+)") do
					table.insert(paragraphs, p)
				end
				if #paragraphs == 0 then table.insert(paragraphs, cleaned) end

				-- 🧭 Create SimpleHTML for the first paragraph
				local StepText = RQE.API.AcquireRenderObject(RQE.SeparateContentFrame, "focus", "SimpleHTML")
				RQE.SeparateStepText = StepText
				StepText:EnableMouseWheel(true)
				StepText:SetScript("OnMouseWheel", HandleSeparateFocusMouseWheel)
				StepText:SetFontObject("p", GameFontNormal)
				StepText:SetFontObject("h1", GameFontNormal)
				StepText:SetFontObject("h2", GameFontNormal)
				StepText:SetJustifyH("p", "LEFT")
				StepText:SetHyperlinksEnabled(true)
				StepText:SetWidth(focusTextWidth)
				StepText:SetTextColor("p", 1, 1, 0.8)
				StepText:SetTextColor("h1", 1, 1, 0.8)
				StepText:SetTextColor("h2", 1, 1, 0.8)
				StepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", focusTextInset, -7)

				local html = paragraphs[1]
				StepText._rqeCoordblockLinks = {}
				StepText._rqeCoordblockByPoint = {}

				-- 🔗 Replace {item}, {spell}, {coords}
				html = html:gsub("{item:(%d+):([^}]+)}", function(id, name)
					return string.format('<a href="item:%s">|cffff66cc[%s]|r</a>', id, name)
				end)

				html = html:gsub("{spell:(%d+):([^}]+)}", function(id, name)
					return string.format('<a href="spell:%s">|cff66ccff[%s]|r</a>', id, name)
				end)

				html = html:gsub("{npc:(%d+):([^}]+)}", function(id, name)
					return string.format('<a href="rqenpc:%s">|cff66ff66[%s]|r</a>', id, name)
				end)

				html = html:gsub("{object:([%a%d]+):([^}]+)}", function(id, name)
					return string.format('<a href="rqeobject:%s">|cffffd700[%s]|r</a>', id, name)
				end)

				html = html:gsub("{coordblock:([^}]+)}", function(data)
					local x, y, mapID, title =
						data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)%s*;%s*waypointTitle:%s*\"([^\"]+)\"")
					if not x then
						x, y, mapID = data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)")
					end
					if not (x and y and mapID) then return data end

					local label = RQE:GetCoordblockDisplayLabel(data)
					local href = title and
						string.format("coords:%s,%s,%s;title:%s", x, y, mapID, title) or
						string.format("coords:%s,%s,%s", x, y, mapID)
					-- This suffix identifies compact links without changing {coords:...}.
					href = href .. ";rqeCoordblock"
					StepText._rqeCoordblockLinks[href] = data
					local pointKey = string.format("%.2f,%.2f,%d", tonumber(x), tonumber(y), tonumber(mapID))
					StepText._rqeCoordblockByPoint[pointKey] = data

					return string.format('<a href="%s">|cff40e0d0%s|r</a>', href, label)
				end)

				html = html:gsub("{coords:([^}]+)}", function(data)
					local x, y, mapID, title =
						data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)%s*;%s*waypointTitle:%s*\"([^\"]+)\"")
					if not x then
						x, y, mapID = data:match("(%d+%.?%d*),(%d+%.?%d*),(%d+)")
					end
					if not (x and y and mapID) then return data end

					local label = string.format("coords: %.2f, %.2f map %s", x, y, mapID)
					local href = title and
						string.format("coords:%s,%s,%s;title:%s", x, y, mapID, title)
						or string.format("coords:%s,%s,%s", x, y, mapID)

					-- Colors of coordinate link in SeparateFocusFrame
					-- return string.format('<a href="%s">|cff674ea7[%s]|r</a>', href, label)	-- Blue Marguerite
					-- return string.format('<a href="%s">|cff9933ff[%s]|r</a>', href, label)	-- Blue Violet
					-- return string.format('<a href="%s">|cff00ccff[%s]|r</a>', href, label)	-- Deep Sky Blue
					-- return string.format('<a href="%s">|cffDBA968[%s]|r</a>', href, label)	-- Equator
					-- return string.format('<a href="%s">|cffc080ff[%s]|r</a>', href, label)	-- Heliotrope
					-- return string.format('<a href="%s">|cffFFB2FF[%s]|r</a>', href, label)	-- Lavender Rose
					-- return string.format('<a href="%s">|cff33b3a6[%s]|r</a>', href, label)	-- Light Sea Green
					-- return string.format('<a href="%s">|cffB1ffd7[%s]|r</a>', href, label)	-- Magic Mint
					-- return string.format('<a href="%s">|cff7DBE6E[%s]|r</a>', href, label)	-- Mantis
					-- return string.format('<a href="%s">|cffd7b1ff[%s]|r</a>', href, label)	-- Mauve
					-- return string.format('<a href="%s">|cffb266ff[%s]|r</a>', href, label)	-- Medium Purple
					-- return string.format('<a href="%s">|cffb2ffff[%s]|r</a>', href, label)	-- Pale Turquoise
					-- return string.format('<a href="%s">|cff6c5ddc[%s]|r</a>', href, label)	-- Slate Blue
					return string.format('<a href="%s">|cff40e0d0[%s]|r</a>', href, label)	-- Turquoise
					-- return string.format('<a href="%s">|cff8eccac[%s]|r</a>', href, label)	-- Vista Blue
				end)

				html = html:gsub("\n", "<br>")
				local wrappedHTML = string.format("<html><body><p>%s</p></body></html>", html)
				StepText:SetText(wrappedHTML)
				StepText._rqeCoordblockHTMLBase = wrappedHTML

				-- Hyperlink click handler
				StepText:SetScript("OnHyperlinkClick", function(self, link, text, button)
					local coordblockData = self._rqeCoordblockLinks and self._rqeCoordblockLinks[link]
					local waypointLink = link:gsub(";rqeCoordblock$", "")
					local x, y, mapID, title =
						waypointLink:match("coords:(%d+%.?%d*),(%d+%.?%d*),(%d+);title:(.+)")
					if not x then
						x, y, mapID = waypointLink:match("coords:(%d+%.?%d*),(%d+%.?%d*),(%d+)")
					end
					if x and y and mapID then
						-- Some SimpleHTML clients return a normalized href without our
						-- suffix.  A compact visible label can still identify its point;
						-- the full {coords:...} label contains "coords:" and is excluded.
						if not coordblockData and (not text or not text:find("coords:", 1, true)) then
							local pointKey = string.format("%.2f,%.2f,%d", tonumber(x), tonumber(y), tonumber(mapID))
							coordblockData = self._rqeCoordblockByPoint and self._rqeCoordblockByPoint[pointKey]
						end
						local markedActive = coordblockData and RQE:SetActiveCoordblock(coordblockData)
						RQE.LastClickedCoords = { tonumber(x), tonumber(y), tonumber(mapID) }
						if markedActive and TomTom and TomTom.waydb and TomTom.waydb.ResetProfile then
							TomTom.waydb:ResetProfile()
							RQE._currentTomTomUID = nil
						end
						RQE:CreateWaypoint(
							tonumber(x),
							tonumber(y),
							tonumber(mapID),
							title and title:gsub("\"", "") or "Custom Waypoint"
						)
						print(string.format("|cff00ff00[RQE]|r Created waypoint to (%.2f, %.2f) map %s%s",
							x, y, mapID, (title and title ~= "") and (" - " .. title:gsub("\"", "")) or ""))
						if markedActive then
							C_Timer.After(0, function()
								if RQE.ActiveCoordblock and RQE.ActiveCoordblock.data == coordblockData then
									RQE:RefreshActiveCoordblockLinks()
								end
							end)
						end
					end
				end)

				StepText:SetScript("OnHyperlinkEnter", function(self, link, text)
					if RQE._coordblockTooltipOwner == self then RQE._coordblockTooltipOwner = nil end
					self:SetScript("OnUpdate", nil)
					if type(link) ~= "string" then return end

					local linkType, id = link:match("^(%a+):(.+)$")
					if linkType == "item" then
						local itemID = tonumber(id)
						if itemID then
							GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
							GameTooltip:SetItemByID(itemID)
							local count = C_Item.GetItemCount(itemID) or 0
							GameTooltip:AddLine(("You have: |cffffff00%d|r"):format(count))
							GameTooltip:Show()
						end
					elseif linkType == "spell" then
						local spellID = tonumber(id)
						if spellID then
							GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT")
							GameTooltip:SetSpellByID(spellID)
							GameTooltip:Show()
						end
					elseif linkType == "rqenpc" then
						local name = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%[(.*)%]$")
						if RQE.ShowNPCPreview then RQE.ShowNPCPreview(tonumber(id), name, true) end
					elseif linkType == "rqeobject" then
						local name = tostring(text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%[(.*)%]$")
						if RQE.ShowObjectImagePreview then RQE.ShowObjectImagePreview(id, name, nil, true) end
					elseif linkType == "coords" then
						local compactLink = self._rqeCoordblockLinks and self._rqeCoordblockLinks[link]
						local isCompact = compactLink or link:find(";rqeCoordblock", 1, true)
						if isCompact then
							GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
						else
							GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
						end
						GameTooltip:SetText("Click to create a waypoint", 1, 1, 1)
						GameTooltip:Show()
						if isCompact then
							RQE._coordblockTooltipOwner = self
							RQE:AnchorCoordblockTooltip(self)
							self:SetScript("OnUpdate", function(frame)
								if RQE._coordblockTooltipOwner ~= frame or not GameTooltip:IsShown() then
									frame:SetScript("OnUpdate", nil)
									return
								end
								RQE:AnchorCoordblockTooltip(frame)
							end)
						end
					end
				end)

				StepText:SetScript("OnHyperlinkLeave", function(self)
					if RQE._coordblockTooltipOwner == self then RQE._coordblockTooltipOwner = nil end
					self:SetScript("OnUpdate", nil)
					GameTooltip:Hide()
				end)

				-- Adjust height after rendering
				C_Timer.After(0.05, function()
					-- Ignore stale delayed callbacks from older rebuilds
					if buildToken ~= RQE._SeparateFocusBuildToken then
						return
					end
					if not StepText then
						return
					end

					local h = StepText:GetContentHeight() or 20
					StepText:SetHeight(h + 6)
				end)

				-- ✅ Handle following paragraphs (if \n exists)
				if #paragraphs > 1 then
					C_Timer.After(0.05, function()
						-- Ignore stale delayed callbacks from older rebuilds
						if buildToken ~= RQE._SeparateFocusBuildToken then
							return
						end
						if not StepText then
							return
						end

						local htmlHeight = StepText:GetContentHeight() or StepText:GetHeight() or 20
						local extraPadding = math.max(20, htmlHeight * 0.3) -- at least 20px, scales a bit with height
						local yOffset = -(htmlHeight + extraPadding)

						if RQE.db.profile.debugLevel == "INFO+" then
							print(string.format("RQE DEBUG: SimpleHTML height calculated as %.2f, yOffset set to %.2f", htmlHeight, yOffset))
						end

						for i = 2, #paragraphs do
							if buildToken ~= RQE._SeparateFocusBuildToken then
								return
							end

							local line = paragraphs[i]
							if RQE.db.profile.debugLevel == "INFO+" then
								print(string.format("RQE DEBUG: Rendering paragraph #%d below HTML: %s", i, line))
							end

							local fs = RQE.API.AcquireRenderObject(RQE.SeparateContentFrame, "focus", "FontString", "GameFontNormal")
							fs:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", focusTextInset, yOffset)
							fs:SetWidth(focusTextNarrowWidth)
							fs:SetJustifyH("LEFT")
							fs:SetTextColor(1, 1, 0.8)
							fs:SetWordWrap(true)
							fs:SetText(line)

							-- Render hover-capable markup (items/spells, etc.)
							RQE.RenderTextWithItemsSteps(fs, line, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 0.8}, RQE.SeparateContentFrame)
							if line:find("{coordblock:", 1, true) then
								table.insert(RQE.SeparateCoordblockFonts, fs)
							end

							local h2 = fs.GetStringHeight and fs:GetStringHeight() or 16
							yOffset = yOffset - (h2 + 8)
							if RQE.db.profile.debugLevel == "INFO+" then
								print(string.format("RQE DEBUG: FontString height %.2f, next yOffset %.2f", h2, yOffset))
							end
						end
					end)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					-- 🧾 Standard FontString version (no coords, still supports items/spells + line breaks)
					print("RQE DEBUG: Entered SeparateFocusFrame FontString (no coords) block")
				end

				-- Normalize and split by newline
				local paragraphs = {}
				local cleaned = formattedText:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\\n", "\n")
				for p in cleaned:gmatch("([^\n]+)") do
					table.insert(paragraphs, p)
				end
				if RQE.db.profile.debugLevel == "INFO+" then
					print("RQE DEBUG: FontString paragraph count:", #paragraphs)
				end

				-- Safety: if no paragraphs found, treat whole thing as one
				if #paragraphs == 0 then
					table.insert(paragraphs, cleaned)
				end

				local yOffset = -7
				for i, line in ipairs(paragraphs) do
					if RQE.db.profile.debugLevel == "INFO+" then
						print(string.format("RQE DEBUG: Rendering FontString paragraph #%d: %s", i, line))
					end

					local StepText = RQE.API.AcquireRenderObject(RQE.SeparateContentFrame, "focus", "FontString", "GameFontNormal")
					-- RQE.SeparateStepText = StepText
					if i == 1 then
						RQE.SeparateStepText = StepText
					end
					StepText:SetJustifyH("LEFT")
					StepText:SetTextColor(1, 1, 0.8)
					StepText:SetWidth(focusTextWidth)
					StepText:SetWordWrap(true)
					StepText:SetPoint("TOPLEFT", RQE.SeparateContentFrame, "TOPLEFT", focusTextInset, yOffset)
					StepText:SetText(line)

					-- Handle hover-capable markup for item/spell tags even when no coords exist
					RQE.RenderTextWithItemsSteps(StepText, line, "Fonts\\FRIZQT__.TTF", 12, {1, 1, 0.8}, RQE.SeparateContentFrame)

					-- Measure line height and step down
					local h = StepText.GetStringHeight and StepText:GetStringHeight() or 16
					yOffset = yOffset - (h + 8)
					if RQE.db.profile.debugLevel == "INFO+" then
						print("RQE DEBUG: FontString paragraph height:", h)
					end
				end
				routeStartOffset = yOffset - 8
			end

			-- RQE.SeparateStepText:Show()
			if RQE.SeparateStepText then
				RQE.SeparateStepText:Show()
			end

			RQE.InitializeSeparateFocusWaypoints()

			-- Update content height dynamically
			RQE.UpdateSeparateContentHeight()
			if #routeLinks > 0 then
				C_Timer.After(0.1, function()
					if buildToken ~= RQE._SeparateFocusBuildToken
						or RQE.CurrentDisplayedQuestID ~= questID
						or RQE.CurrentDisplayedStepIndex ~= stepIndex then return end
					RQE:RenderCoordOrderFocusBelowText(routeLinks, questID,
						stepIndex, HandleSeparateFocusMouseWheel, routeStartOffset)
					RQE.UpdateSeparateContentHeight()
				end)
			end
			C_Timer.After(0.12, function()
				if buildToken ~= RQE._SeparateFocusBuildToken then return end
				RQE.UpdateSeparateContentHeight()
			end)

			finishUpdate()
		end


		-------------------------------------------------------
		-- #8f.i. Focus Content Height Finalization
		-------------------------------------------------------

		function RQE.UpdateSeparateFocusScrollbarVisual(contentHeight)
			if not (RQE.SeparateFocusSlider and RQE.SeparateScrollFrame
				and RQE.SeparateFocusFrame) then return end
			local _, maximum = RQE.SeparateFocusSlider:GetMinMaxValues()
			local themed = RQE.UI and RQE.UI:IsEnabled()
			local hasMeaningfulContent = false
			local function CheckText(region)
				if hasMeaningfulContent or not region or not region.IsShown
					or not region:IsShown() or not region.GetText then return end
				local text = region:GetText()
				hasMeaningfulContent = type(text) == "string" and text:find("%S") ~= nil
			end
			if RQE.SeparateContentFrame then
				for _, child in ipairs({ RQE.SeparateContentFrame:GetChildren() }) do CheckText(child) end
				for _, region in ipairs({ RQE.SeparateContentFrame:GetRegions() }) do CheckText(region) end
			end
			if not themed or not RQE.SeparateFocusFrame:IsShown()
				or not hasMeaningfulContent or not maximum or maximum <= 0 then
				RQE.SeparateFocusSlider:Hide()
				return
			end

			local viewportHeight = math.max(1, RQE.SeparateScrollFrame:GetHeight() or 1)
			local totalHeight = math.max(viewportHeight, tonumber(contentHeight)
				or (viewportHeight + maximum))
			local trackHeight = math.max(1, RQE.SeparateFocusSlider:GetHeight() or viewportHeight)
			local thumbHeight = math.min(trackHeight, math.max(26,
				math.floor(trackHeight * viewportHeight / totalHeight + 0.5)))
			local focusThumb = RQE.SeparateFocusSlider:GetThumbTexture()
			if focusThumb then
				focusThumb:SetColorTexture(0 / 255, 87 / 255, 184 / 255, 1) -- Azure #0057B8
				focusThumb:SetSize(4, thumbHeight)
				focusThumb:Show()
			end
			RQE.SeparateFocusSlider:Show()
		end

		-- Measure the actual focused-step regions rather than maintaining the old
		-- permanent 1000-pixel child, which made short steps appear scrollable.
		function RQE.UpdateSeparateContentHeight()
			if not (RQE.SeparateContentFrame and RQE.SeparateScrollFrame) then return end
			local viewportHeight = math.max(1, RQE.SeparateScrollFrame:GetHeight() or 1)
			local contentTop = RQE.SeparateContentFrame:GetTop()
			local lowestBottom
			local function IncludeRegion(region)
				if not region or not region.IsShown or not region:IsShown() then return end
				local bottom = region.GetBottom and region:GetBottom()
				if bottom and (not lowestBottom or bottom < lowestBottom) then
					lowestBottom = bottom
				end
			end

			for _, child in ipairs({ RQE.SeparateContentFrame:GetChildren() }) do
				IncludeRegion(child)
			end
			for _, region in ipairs({ RQE.SeparateContentFrame:GetRegions() }) do
				if region.GetObjectType and region:GetObjectType() == "FontString" then
					IncludeRegion(region)
				end
			end

			local desiredHeight = viewportHeight
			if contentTop and lowestBottom then
				desiredHeight = math.max(viewportHeight, contentTop - lowestBottom + 10)
			end
			RQE.SeparateContentFrame:SetHeight(desiredHeight)

			if RQE.SeparateFocusSlider then
				local maximum = math.max(0, desiredHeight - viewportHeight)
				RQE.SeparateFocusSlider:SetMinMaxValues(0, maximum)
				if RQE.SeparateFocusSlider:GetValue() > maximum then
					RQE.SeparateFocusSlider:SetValue(maximum)
				end
				RQE.UpdateSeparateFocusScrollbarVisual(desiredHeight)
			end
		end

		-- Initial update to content height
		RQE.UpdateSeparateContentHeight()

		-- Call the function to update the frame's content dynamically
		RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when initialized
	end


	-------------------------------------------------------
	-- #8g. Focus Waypoint Control
	-------------------------------------------------------

	-- Initialize the waypoint button for the SeparateFocusFrame
	function RQE.InitializeSeparateFocusWaypoints()
		-- Create or update Waypoint Button
		if not RQE.SeparateWaypointButton then
			RQE.SeparateWaypointButton = CreateFrame("Button", nil, RQE.SeparateFocusFrame)
			-- The artwork remains 30x30, but the native hit rectangle includes
			-- its glow and stays fixed when the Focus Frame content scrolls.
			RQE.SeparateWaypointButton:SetSize(40, 40)
			-- This is the legacy placement. Azure & Gold reapplies its independent
			-- 10/-6 inset through StyleLegacyActionButton below.
			RQE.SeparateWaypointButton:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "TOPLEFT", 2, -4)
			RQE.SeparateWaypointButton:SetFrameLevel(RQE.SeparateScrollFrame:GetFrameLevel() + 3)
			RQE.SeparateWaypointButton:EnableMouseWheel(true)
			RQE.SeparateWaypointButton:SetScript("OnMouseWheel", HandleSeparateFocusMouseWheel)
			local bg = RQE.SeparateWaypointButton:CreateTexture(nil, "BACKGROUND")
			bg:SetSize(30, 30)
			bg:SetPoint("CENTER", RQE.SeparateWaypointButton, "CENTER")
			bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")

			-- Create the number label
			local number = RQE.SeparateWaypointButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			number:SetPoint("CENTER", RQE.SeparateWaypointButton, "CENTER", 0, -1)
			number:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
			number:SetText("*")
			number:SetTextColor(1, 1, 0)
			if RQE.UI then
				RQE.UI:StyleLegacyActionButton(RQE.SeparateWaypointButton, bg, number,
					"Waypoint", { size = 40, iconInset = 3, focusInset = true })
			end

			-- Add the click event for the Waypoint Button
			RQE.SeparateWaypointButton:SetScript("OnClick", function()
				local questID = tonumber(RQE.API.GetSuperTrackedQuestID())
				local stepIndex = tonumber(RQE.AddonSetStepIndex or RQE.CurrentDisplayedStepIndex)
				local questData = questID and RQE.getQuestData(questID)
				if questData and stepIndex and questData[stepIndex] then
					-- Do not delegate to StepsText: its waypoint branch depends on
					-- StepsText hover flags, which hovering this button never sets.
					RQE:EnsureWaypointForSupertracked()
					-- If the RQE.AddonSetStepIndex is "1" then it will build the macro associated with that stepIndex
					if stepIndex == 1 then
						-- Tier Two Importance: 
						if RQE.db.profile.autoClickWaypointButton then
							C_Timer.After(0.1, function()
								RQE.isCheckingMacroContents = true
								local isMacroCorrect = RQE.CheckCurrentMacroContents()

								if isMacroCorrect then
									return
								end

								RQEMacro:CreateMacroForCurrentStep()
								C_Timer.After(0.2, function()
									RQE.isCheckingMacroContents = false
									C_Timer.After(3, function()
										RQE.CreateMacroForUpdateSeparateFocusFrame = false
									end)
								end)
							end)
						end
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("No supertracked quest step found for the Focus Frame waypoint button.")
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

	-------------------------------------------------------
	-- #8h. Focus Tooltip & Scroll Utilities
	-------------------------------------------------------

	-- Function to create a tooltip to display
	function RQE.ShowFocusScrollFrameTooltip(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP", -200, 20) -- Anchor the tooltip at the top of the frame

		-- Set the title of the tooltip
		GameTooltip:SetText("Hold ALT, CTRL, or SHIFT to scroll this frame.", 1, 1, 1, 1, true)

		-- Check if RQE.SeparateStepText exists and has text
		local stepText = RQE.GetSeparateStepText()
		if stepText ~= "" then
		-- if RQE.SeparateStepText and RQE.SeparateStepText:GetText() ~= "" then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("|cfffffd9fQuest Help for Current Step:|r", 1, 1, 1, true) -- Canary title
			GameTooltip:AddLine("|cffa9a9ff" .. stepText .. "|r", nil, nil, nil, true)
		else
			GameTooltip:AddLine(" ")
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
				if RQE.SeparateFocusSlider then RQE.SeparateFocusSlider:SetValue(0) end
				RQE.SeparateScrollFrame:SetVerticalScroll(0)
			end
		end
	end

	-------------------------------------------------------
	-- #8i. Coordinate-Block Tooltip Data
	-------------------------------------------------------

	-- Tooltip and click both follow the current supertracked step's hotspot choice.
	function RQE.GetTooltipDataForCButton()
		local stepIndex = tonumber(RQE.AddonSetStepIndex or RQE.CurrentDisplayedStepIndex) or 1
		local questID = tonumber(RQE.API.GetSuperTrackedQuestID())
		local questData = questID and RQE.getQuestData(questID)

		if questData and questData[stepIndex] then
			local step = questData[stepIndex]

			-- Prefer the selector's current target, but a valid current-map
			-- hotspot outranks a stale cross-map target just as the click does.
			if step.coordinateHotspots then
				local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
				local playerMapID = C_Map and C_Map.GetBestMapForUnit
					and C_Map.GetBestMapForUnit("player")
				if playerMapID and smap ~= playerMapID then
					local localMap, localX, localY = RQE.WPUtil.GetSameMapHotspot(
						questID, stepIndex, playerMapID)
					if localMap then smap, sx, sy = localMap, localX, localY end
				end
				smap, sx, sy = tonumber(smap), tonumber(sx), tonumber(sy)
				if smap and smap > 0 and sx and sx > 0 and sy and sy > 0 then
					local coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", sx * 100, sy * 100, smap)
					RQE.SeparateFocusCoordData = coordsText
					if RQE.db.profile.debugLevel == "INFO+" then
						DEFAULT_CHAT_FRAME:AddMessage("Step " .. stepIndex .. " coords: " .. coordsText, 1, 1, 0)
					end
					return coordsText
				end
			end
			if step.coordinates and type(step.coordinates) == "table" then
				local x, y, mapID = tonumber(step.coordinates.x),
					tonumber(step.coordinates.y), tonumber(step.coordinates.mapID)
				if x and y and x > 0 and y > 0 and mapID and mapID > 0 then
					if x <= 1 and y <= 1 then x, y = x * 100, y * 100 end
					local coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", x, y, mapID)
					RQE.SeparateFocusCoordData = coordsText
					if RQE.db.profile.debugLevel == "INFO+" then
						DEFAULT_CHAT_FRAME:AddMessage("Step " .. stepIndex .. " coords: " .. coordsText, 1, 1, 0)
					end
					return coordsText
				end
			end
		end

		return "No tooltip available."
	end

	-------------------------------------------------------
	-- #8j. Coordinate Button Tooltip Hooks
	-------------------------------------------------------

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

	-------------------------------------------------------
	-- #8k. Periodic Frame Visibility Monitor
	-------------------------------------------------------

	-- Check which visibility state the RQEFrame and RQEQuestFrame should be
	function RQE:CheckFrameVisibility()
		-- Check for the RQEFrame visibility setting
		if RQE.db.profile.enableFrame then
			-- Show the RQEFrame if it should be enabled and is not currently shown
			if not InCombatLockdown() then
				if not RQEFrame:IsShown() then
					if RQEFrame then
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

		if not isMoving or inScenario then
			RQE:CheckFrameVisibility()
		end
	end)
