--[[ 

QuestingModule.lua
Retail quest tracker construction, sorting, search, rendering, and interaction

]]


--------------------------------------------------
-- #1. 🌐 Module Namespace & Shared Tracking State
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Addon Namespace & Tracking Tables
	-------------------------------------------------------

	-- Initialize RQE global table
	RQE = RQE or {}
	RQE.modules = RQE.modules or {}
	RQE.WorldQuestsInfo = RQE.WorldQuestsInfo or {}
	RQE.TrackedQuests = RQE.TrackedQuests or {}
	RQE.TrackedAchievementIDs = RQE.TrackedAchievementIDs or {}
	RQE.DelayedQuestWatchCheck = RQE.DelayedQuestWatchCheck or {}

	-- Initialization of RQE.ManuallyTrackedQuests
	if not RQE.ManuallyTrackedQuests then
		RQE.ManuallyTrackedQuests = {}
	end


	-------------------------------------------------------
	-- #1b. Bootstrap Diagnostics & AceGUI
	-------------------------------------------------------

	if RQE and RQE.debugLog then
		RQE.debugLog("Message here")
	else
		print("RQE or RQE.debugLog is not initialized.")
	end

	-- Assuming AceGUI is already loaded and RQE is initialized
	local AceGUI = LibStub("AceGUI-3.0")


--------------------------------------------------
-- #2. 🖼️ Quest Tracker Frame, Search & Scrolling
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Primary Frame & Scroll View
	-------------------------------------------------------

	-- Create the frame
	--- @class RQE.RQEQuestFrame : Frame
	--- @field questTitles table<number, FontString>
	--- @field questCount number
	RQE.RQEQuestFrame = CreateFrame("Frame", "RQEQuestFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	local frame = RQE.RQEQuestFrame
	local isQuestFrameLocked = RQE.db.profile.lockRQEQuestFrame == true

	-- Frame properties come from the active profile, falling back to the shared coded defaults.
	local anchorPoint, xPos, yPos, frameWidth, frameHeight = RQE:GetFrameGeometry("RQEQuestFrame")
	RQE.RQEQuestFrame:SetSize(frameWidth, frameHeight)
	RQE.RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	RQE.RQEQuestFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 5,
		insets = { left = 0, right = 0, top = 1, bottom = 0 }
	})
	RQE.RQEQuestFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.QuestFrameOpacity)
	if RQE.UI then RQE.UI:StylePanel(RQE.RQEQuestFrame, RQE.db.profile.QuestFrameOpacity, "tracker") end

	-- Create the ScrollFrame
	local ScrollFrame = CreateFrame("ScrollFrame", nil, RQE.RQEQuestFrame)
	ScrollFrame:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 10, -72)  -- Leave room for the tracker search controls.
	ScrollFrame:SetPoint("BOTTOMRIGHT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -30, 10)
	ScrollFrame:EnableMouseWheel(true)
	ScrollFrame:SetClipsChildren(true)  -- Enable clipping
	RQE.QTScrollFrame = ScrollFrame


	-- Create the content frame
	local content = CreateFrame("Frame", nil, ScrollFrame)
	content:SetPoint("TOPLEFT", ScrollFrame, "TOPLEFT", 0, 0)
	content:SetSize(math.max(1, ScrollFrame:GetWidth()), 600)
	ScrollFrame:SetScrollChild(content)
	ScrollFrame:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(math.max(1, width))
	end)
	RQE.QTcontent = content


	-------------------------------------------------------
	-- #2b. Quest Button Alignment Helpers
	-------------------------------------------------------

	local TRACKER_QUEST_BUTTON_SIZE = 35
	local TRACKER_QUEST_LABEL_GAP = 5
	local TRACKER_THEMED_BUTTON_TOP_OFFSET = 2

	local function GetTrackerQuestLabelInset()
		return (RQE.UI and RQE.UI:IsEnabled()) and 46 or 40
	end

	local function AnchorTrackerQuestButton(button, label)
		button:ClearAllPoints()
		if RQE.UI and RQE.UI:IsEnabled() then
			-- Themed quest names may wrap to multiple lines. Top-align the button to
			-- the title instead of centering it on the full FontString height so every
			-- badge begins on the same visual row regardless of title wrapping.
			button:SetPoint("TOPRIGHT", label, "TOPLEFT", -TRACKER_QUEST_LABEL_GAP, TRACKER_THEMED_BUTTON_TOP_OFFSET)
		else
			button:SetPoint("RIGHT", label, "LEFT", -TRACKER_QUEST_LABEL_GAP, 0)
		end
	end


	-------------------------------------------------------
	-- #2c. Quest-Log Search Controls
	-------------------------------------------------------

	-- Quest-log search controls remain fixed below the tracker header while the
	-- category frames continue to scroll in the content area beneath them.
	local questTrackerSearchRow = CreateFrame("Frame", nil, RQE.RQEQuestFrame)
	questTrackerSearchRow:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 10, -40)
	questTrackerSearchRow:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -30, -40)
	questTrackerSearchRow:SetHeight(30)
	RQE.QuestTrackerSearchRow = questTrackerSearchRow

	local questTrackerRestoreButton = CreateFrame("Button", nil, questTrackerSearchRow, "UIPanelButtonTemplate")
	questTrackerRestoreButton:SetSize(90, 28)
	questTrackerRestoreButton:SetPoint("RIGHT", questTrackerSearchRow, "RIGHT", 0, 0)
	questTrackerRestoreButton:SetText("Restore")
	questTrackerRestoreButton:Disable()
	RQE.QuestTrackerRestoreButton = questTrackerRestoreButton

	local questTrackerSearchButton = CreateFrame("Button", nil, questTrackerSearchRow, "UIPanelButtonTemplate")
	questTrackerSearchButton:SetSize(82, 28)
	questTrackerSearchButton:SetPoint("RIGHT", questTrackerRestoreButton, "LEFT", -4, 0)
	questTrackerSearchButton:SetText("Search")
	RQE.QuestTrackerSearchButton = questTrackerSearchButton

	local questTrackerSearchInput = CreateFrame("EditBox", nil, questTrackerSearchRow, "InputBoxTemplate")
	questTrackerSearchInput:SetHeight(24)
	questTrackerSearchInput:SetPoint("LEFT", questTrackerSearchRow, "LEFT", 3, 0)
	questTrackerSearchInput:SetPoint("RIGHT", questTrackerSearchButton, "LEFT", -6, 0)
	questTrackerSearchInput:SetAutoFocus(false)
	questTrackerSearchInput:SetFontObject("GameFontHighlight")
	questTrackerSearchInput:SetTextInsets(6, 6, 0, 0)
	RQE.QuestTrackerSearchInput = questTrackerSearchInput
	if RQE.UI then
		RQE.UI:StyleTextButton(questTrackerSearchButton, { trackerAction = true })
		RQE.UI:StyleTextButton(questTrackerRestoreButton, { trackerAction = true })
		RQE.UI:StyleSearchBox(questTrackerSearchInput)
	end

	local function ShowQuestTrackerSearchTooltip(self, text)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(text, 1, 1, 1, true)
		GameTooltip:Show()
	end

	questTrackerSearchInput:SetScript("OnEnter", function(self)
		ShowQuestTrackerSearchTooltip(self, "Type in questID, name, description, or objective")
	end)
	questTrackerSearchInput:SetScript("OnLeave", GameTooltip_Hide)

	-- Previous longer Search tooltip retained for reference:
	-- questTrackerSearchButton:SetScript("OnEnter", function(self)
	-- 	ShowQuestTrackerSearchTooltip(self,
	-- 		"Search the active quest log by quest ID, quest title, objectives, or description.\n\n" ..
	-- 		"Matches may also come from the same title, objectives, or description fields in RQEDatabase. " ..
	-- 		"Searching removes other player-log quests from the RQE Quest Tracker and keeps only the matching quests. World, bonus, and other non-log tracker entries are unchanged.")
	-- end)
	questTrackerSearchButton:SetScript("OnEnter", function(self)
		ShowQuestTrackerSearchTooltip(self, "Search for and populate quest tracker with results")
	end)
	questTrackerSearchButton:SetScript("OnLeave", GameTooltip_Hide)

	-- Previous Restore tooltip retained for reference:
	-- questTrackerRestoreButton:SetScript("OnEnter", function(self)
	-- 	ShowQuestTrackerSearchTooltip(self, "Restore the player-log quests that were tracked before the latest quest-tracker search.")
	-- end)
	questTrackerRestoreButton:SetScript("OnEnter", function(self)
		ShowQuestTrackerSearchTooltip(self, "Restore your watch list before Search")
	end)
	questTrackerRestoreButton:SetScript("OnLeave", GameTooltip_Hide)

	local function RunQuestTrackerSearch()
		if RQE.SearchQuestTracker then
			RQE:SearchQuestTracker(questTrackerSearchInput:GetText())
		end
		RQE.QuestScrollFrameToTop(true)
		questTrackerSearchInput:ClearFocus()
	end

	questTrackerSearchInput:SetScript("OnEnterPressed", RunQuestTrackerSearch)
	questTrackerSearchButton:SetScript("OnClick", RunQuestTrackerSearch)

	questTrackerRestoreButton:SetScript("OnClick", function()
		if RQE.RestoreQuestTrackerSearch then
			RQE:RestoreQuestTrackerSearch()
		end
		RQE.QuestScrollFrameToTop(true)
	end)

	-- The stock minimize button reduces the tracker to its header. Keep the search
	-- controls from extending below that compact frame and restore them on expand.
	RQE.RQEQuestFrame:HookScript("OnSizeChanged", function(_, _, height)
		if RQE.QuestTrackerSearchRow then
			local collapsedHeight = (RQE.UI and RQE.UI:IsEnabled()) and 48 or 30
			if height <= collapsedHeight then
				RQE.QuestTrackerSearchRow:Hide()
			else
				RQE.QuestTrackerSearchRow:Show()
			end
		end
	end)


	-------------------------------------------------------
	-- #2d. Dragging, Hover Detection & Resizing
	-------------------------------------------------------

	-- Make it draggable
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)


	-- Recursive function to attach hover handlers to a frame and its children
	local function AttachHoverHandlers(frame)
		if not frame then return end

		-- Attach hover handlers to the frame itself
		frame:SetScript("OnEnter", function()
			if not RQE.hoveringOnFrame then
				RQE.hoveringOnFrame = true
			end
		end)

		frame:SetScript("OnLeave", function()
			-- Delay to recheck mouse position to ensure accurate detection
			-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.1, function()
			RQE.API.Client.C_Timer.After(0.1, function()
				-- Check if mouse is still over the frame or any of its children
				-- if not MouseIsOver(frame) then
				if not frame:IsMouseOver() then
					GameTooltip:Hide()
					RQE.hoveringOnFrame = false
				end
			end)
		end)

		-- Recursively attach handlers to all children of the frame
		local children = { frame:GetChildren() }
		for _, child in ipairs(children) do
			AttachHoverHandlers(child)
		end
	end


	-- Attach hover handlers to RQEQuestFrame and its children
	if RQE.RQEQuestFrame then
		AttachHoverHandlers(RQE.RQEQuestFrame)
	end


	-- Make it resizable
	frame:SetResizable(true)

	-- Create a resize button
	local resizeBtn = CreateFrame("Button", nil, frame)
	resizeBtn:SetSize(16, 16)
	resizeBtn:SetPoint("BOTTOMRIGHT")
	resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeBtn:SetScript("OnMouseDown", function(self, button)
	  if button == "LeftButton" then
		frame:StartSizing()
	  end
	end)
	resizeBtn:SetScript("OnMouseUp", function(self, button)
	  frame:StopMovingOrSizing()
	  AdjustQuestItemWidths()
	end)
	RQE.QMQTResizeButton = resizeBtn

	function RQE.IsRQEQuestFrameLocked()
		return isQuestFrameLocked
	end

	function RQE.SetRQEQuestFrameLocked(locked, persist)
		isQuestFrameLocked = locked == true
		frame:EnableMouse(true) -- Retain right-click access while locked.
		if isQuestFrameLocked then
			frame:SetMovable(false)
			frame:SetResizable(false)
			frame:SetScript("OnDragStart", nil)
			resizeBtn:Hide()
		else
			frame:SetMovable(true)
			frame:SetResizable(true)
			frame:RegisterForDrag("LeftButton")
			frame:SetScript("OnDragStart", frame.StartMoving)
			frame:SetScript("OnDragStop", function()
				frame:StopMovingOrSizing()
				if SaveQuestFramePosition then SaveQuestFramePosition() end
			end)
			resizeBtn:Show()
		end
		if persist ~= false and RQE.db and RQE.db.profile then
			RQE.db.profile.lockRQEQuestFrame = isQuestFrameLocked
			local registry = LibStub("AceConfigRegistry-3.0", true)
			if registry then registry:NotifyChange("RQE_Frame") end
		end
	end

	function RQE.ToggleRQEQuestFrameLock()
		RQE.SetRQEQuestFrameLocked(not isQuestFrameLocked)
	end

	RQE.SetRQEQuestFrameLocked(RQE.db.profile.lockRQEQuestFrame == true, false)


	-------------------------------------------------------
	-- #2e. Tracker Header & Scrollbar
	-------------------------------------------------------

	-- Title text in a custom header
	local header = CreateFrame("Frame", "RQEQuestFrameHeader", RQE.RQEQuestFrame, "BackdropTemplate")
	RQE.RQEQuestFrameHeader = header
	header:SetHeight(30)
	header:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 8,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
	if RQE.UI then RQE.UI:StyleHeader(header, false) end
	header:SetPoint("TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", 0, 0)

	-- Create header text
	local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerText:SetPoint("CENTER", header, "CENTER")
	headerText:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
	headerText:SetTextColor(239/255, 191/255, 90/255)
	headerText:SetText("RQE Quest Tracker")
	headerText:SetWordWrap(true)
	RQE.QuestTrackerHeaderText = headerText

	RQE.debugLog("Frame size: Width = " .. frame:GetWidth() .. ", Height = " .. frame:GetHeight())

	-- Create a trackless Slider.  It remains the scroll-position controller in
	-- both presentations, but only Azure & Gold exposes its draggable gold thumb.
	-- Keeping this independent from UIPanelScrollBarTemplate avoids stock arrow
	-- buttons and the dark Blizzard trough around the indicator.
	---@class RQE.QMQTslider : Slider
	---@field QMQTslider.scrollStep number
	local QMQTslider = CreateFrame("Slider", nil, RQE.RQEQuestFrame)
	QMQTslider:SetOrientation("VERTICAL")
	QMQTslider:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -7, -90)
	QMQTslider:SetPoint("BOTTOMRIGHT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -7, 14)
	QMQTslider:SetWidth(10)
	QMQTslider:SetMinMaxValues(0, content:GetHeight())
	QMQTslider:SetValueStep(1)
	QMQTslider:SetObeyStepOnDrag(false)
	QMQTslider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
	local QMQTthumb = QMQTslider:GetThumbTexture()
	QMQTthumb:SetColorTexture(255 / 255, 215 / 255, 0 / 255, 1) -- #FFD700
	QMQTthumb:SetSize(4, 54)
	QMQTslider.scrollStep = 1
	QMQTslider:Hide()

	RQE.QMQTslider = QMQTslider

	QMQTslider:SetScript("OnValueChanged", function(self, value)
		RQE.QTScrollFrame:SetVerticalScroll(value)
	end)

	-- Synchronize range, thumb size, and visibility after category layout settles.
	-- Legacy mode intentionally retains mouse-wheel scrolling without drawing a
	-- scrollbar; the themed thumb length reflects the visible share of content.
	function RQE.UpdateQuestTrackerScrollbarVisual(contentHeight)
		if not RQE.QMQTslider or not RQE.QTScrollFrame then return end

		local _, maximum = RQE.QMQTslider:GetMinMaxValues()
		local themed = RQE.UI and RQE.UI:IsEnabled()
		if not themed or RQE.QTMinimized or not RQE.QTScrollFrame:IsShown()
			or not maximum or maximum <= 0 then
			RQE.QMQTslider:Hide()
			return
		end

		local viewportHeight = math.max(1, RQE.QTScrollFrame:GetHeight() or 1)
		local totalHeight = math.max(viewportHeight, tonumber(contentHeight)
			or (viewportHeight + maximum))
		local trackHeight = math.max(1, RQE.QMQTslider:GetHeight() or viewportHeight)
		local thumbHeight = math.min(trackHeight, math.max(42,
			math.floor(trackHeight * viewportHeight / totalHeight + 0.5)))
		local thumb = RQE.QMQTslider:GetThumbTexture()
		if thumb then
			thumb:SetColorTexture(255 / 255, 215 / 255, 0 / 255, 1) -- #FFD700
			thumb:SetSize(4, thumbHeight)
			thumb:Show()
		end
		RQE.QMQTslider:Show()
	end

	function RQE.RefreshQuestTrackerScrollRange()
		if not RQE.QTcontent or not RQE.QTScrollFrame or not RQE.QMQTslider then return end
		if RQE.RefreshTrackerProgressBarLayouts then
			RQE.RefreshTrackerProgressBarLayouts()
		end

		local contentTop = RQE.QTcontent:GetTop()
		local lowestBottom
		for _, section in ipairs({
			RQE.ScenarioChildFrame, RQE.CampaignFrame, RQE.QuestsFrame,
			RQE.WorldQuestsFrame, RQE.BonusQuestsFrame, RQE.TaskQuestsFrame,
			RQE.AchievementsFrame, RQE.recipeTrackingFrame,
		}) do
			if section and section:IsShown() then
				local bottom = section:GetBottom()
				if bottom and (not lowestBottom or bottom < lowestBottom) then
					lowestBottom = bottom
				end
			end
		end

		local viewportHeight = math.max(1, RQE.QTScrollFrame:GetHeight() or 1)
		local measuredHeight = viewportHeight
		if contentTop and lowestBottom then
			measuredHeight = math.max(viewportHeight, contentTop - lowestBottom + 10)
		end
		RQE.QTcontent:SetHeight(measuredHeight)

		local maximum = math.max(0, measuredHeight - viewportHeight)
		RQE.QMQTslider:SetMinMaxValues(0, maximum)
		if RQE.QMQTslider:GetValue() > maximum then
			RQE.QMQTslider:SetValue(maximum)
		end
		RQE.UpdateQuestTrackerScrollbarVisual(measuredHeight)
	end

	ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
		local value = QMQTslider:GetValue()
		if delta > 0 then
			QMQTslider:SetValue(value - 50) -- A Change from 20 to 40 on both slider SetValues increases the scroll speed
		else
			QMQTslider:SetValue(value + 50)
		end
	end)


	-------------------------------------------------------
	-- #2f. Scroll Position Reset
	-------------------------------------------------------
	RQE.API.ConfigureScrollbarDrag(QMQTslider, function(_, delta)
		local handler = ScrollFrame:GetScript("OnMouseWheel")
		if handler then handler(ScrollFrame, delta) end
	end)

	-- Automatic updates preserve the player's position while the mouse is over the
	-- tracker, its scroll region, or its content. Explicit button actions pass
	-- forceScroll = true to intentionally return the newly populated list to top.
	function RQE.QuestScrollFrameToTop(forceScroll)
		if not forceScroll then
			local mouseOverTracker = RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsMouseOver()
			local mouseOverScrollFrame = RQE.QTScrollFrame and RQE.QTScrollFrame:IsMouseOver()
			local mouseOverContent = RQE.QTcontent and RQE.QTcontent:IsMouseOver()
			if mouseOverTracker or mouseOverScrollFrame or mouseOverContent then
				return
			end
		end

		if RQE.QTScrollFrame and RQE.QMQTslider then
			RQE.QMQTslider:SetValue(0)  -- Also set the slider to the top position
			RQE.QTScrollFrame:SetVerticalScroll(0)  -- Set the scroll position to the top
		end
	end


--------------------------------------------------
-- #3. 🧱 Child Frames & Objective Tracker Integration
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Child Frame Factory
	-------------------------------------------------------

	---@class RQEChildFrame : Frame
	---@field questCount number
	local function CreateChildFrame(name, parent, offsetX, offsetY, width, height)
		local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
		frame:SetSize(width, height)
		frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, offsetY)
		if RQE.UI then RQE.UI:StylePanel(frame, 0.10, "section") end
		return frame
	end


	-------------------------------------------------------
	-- #3b. Objective Tracker Visibility & Hooks
	-------------------------------------------------------

	-- Check every frame so Blizzard's tracker cannot linger after quest/movement updates.
	local objectiveTrackerWatchdog = CreateFrame("Frame")
	objectiveTrackerWatchdog:SetScript("OnUpdate", function()
		-- Previous Blizzard call changed 2026.09.25: if RQE.db.profile.mythicScenarioMode and not InCombatLockdown() then
		if RQE.db.profile.mythicScenarioMode and not RQE.API.Client.InCombatLockdown() then
			-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario() then
			if not RQE.API.Client.C_Scenario.IsInScenario() then
				RQE:UpdateTrackerVisibility()
			end
		end
	end)


	function RQE:EnforceObjectiveTrackerVisibility()
		if RQE.db.profile.toggleBlizzObjectiveTracker or RQE.db.profile.mythicScenarioMode then
			return
		end
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			RQE.UpdateTrackerVisibilityAfterCombat = true
			return
		end

		local isRQEQuestTrackerVisible = RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown()
		if isRQEQuestTrackerVisible then
			if ObjectiveTrackerFrame:IsShown() then
				ObjectiveTrackerFrame:Hide()
			end
		else
			if not ObjectiveTrackerFrame:IsShown() then
				ObjectiveTrackerFrame:Show()
			end
		end
	end


	function RQE:InitializeObjectiveTrackerHooks()
		if self._objectiveTrackerHooksInitialized then
			return
		end

		if not ObjectiveTrackerFrame or not RQEFrame then
			return
		end

		ObjectiveTrackerFrame:HookScript("OnShow", function()
			RQE:EnforceObjectiveTrackerVisibility()
		end)

		RQEFrame:HookScript("OnShow", function()
			RQE:EnforceObjectiveTrackerVisibility()
		end)

		RQEFrame:HookScript("OnHide", function()
			RQE:EnforceObjectiveTrackerVisibility()
		end)

		if RQE.RQEQuestFrame then
			RQE.RQEQuestFrame:HookScript("OnShow", function()
				RQE:EnforceObjectiveTrackerVisibility()
			end)

			RQE.RQEQuestFrame:HookScript("OnHide", function()
				RQE:EnforceObjectiveTrackerVisibility()
			end)
		end

		self._objectiveTrackerHooksInitialized = true
	end


	-------------------------------------------------------
	-- #3c. Quest Category Frame Instances
	-------------------------------------------------------

	-- Create the ScenarioChildFrame, anchored to the content frame
	RQE.ScenarioChildFrame = CreateChildFrame("RQEScenarioChildFrame", content, 0, 0, content:GetWidth(), 110)

	-- Create the Campaign Child frame, anchored to the content frame/Scenario Frame if available
	RQE.CampaignFrame = CreateChildFrame("RQECampaignFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.CampaignFrame.questCount = RQE.CampaignFrame.questCount or 0

	-- Create the second child frame, anchored below the CampaignFrame
	RQE.QuestsFrame = CreateChildFrame("RQEQuestsFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.QuestsFrame.questCount = RQE.QuestsFrame.questCount or 0

	-- Create the third child frame, anchored below the QuestsFrame
	RQE.WorldQuestsFrame = CreateChildFrame("RQEWorldQuestsFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.WorldQuestsFrame.questCount = RQE.WorldQuestsFrame.questCount or 0

	-- Bonus Objectives use their own section and retain the existing BQ row behavior.
	RQE.BonusQuestsFrame = CreateChildFrame("RQEBonusQuestsFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.BonusQuestsFrame.questCount = RQE.BonusQuestsFrame.questCount or 0

	-- Task Quests are intentionally separate from Bonus Objectives and World Quests.
	RQE.TaskQuestsFrame = CreateChildFrame("RQETaskQuestsFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.TaskQuestsFrame.questCount = RQE.TaskQuestsFrame.questCount or 0


	-- Create the third child frame, anchored below the QuestsFrame
	RQE.AchievementsFrame = CreateChildFrame("RQEAchievementsFrame", content, 0, 0, content:GetWidth(), 120)
	RQE.AchievementsFrame.achieveCount = RQE.AchievementsFrame.achieveCount or 0


	-------------------------------------------------------
	-- #3d. Standard Headers & Recipe Tracking Frame
	-------------------------------------------------------

	-- Function to create a header for a child frame
	local function CreateChildFrameHeader(childFrame, title)
		local header = CreateFrame("Frame", nil, childFrame, "BackdropTemplate")
		header:SetHeight(30)
		header:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
		if RQE.UI then RQE.UI:StyleHeader(header, true) end
		header:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
		header:SetPoint("TOPRIGHT", childFrame, "TOPRIGHT", 0, 0)

		-- Create header text
		local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		headerText:SetPoint("CENTER", header, "CENTER")
		headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
		headerText:SetTextColor(239/255, 191/255, 90/255)
		headerText:SetText(title)
		headerText:SetWordWrap(true)
		childFrame.headerFrame = header

		return headerText  -- Return the FontString instead of the frame
	end


	-- Profession is a normal scrollable child section, immediately before Achievements.
	function RQE:CreateRecipeTrackingFrame()
		if RQE.recipeTrackingFrame then return end
		local recipeFrame = CreateChildFrame("RQERecipeTrackingFrame", content, 0, 0, content:GetWidth(), 60)
		recipeFrame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 8,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		recipeFrame:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
		if RQE.UI then RQE.UI:StylePanel(recipeFrame, 0.72, "section") end
		RQE.recipeTrackingFrame = recipeFrame
		recipeFrame.header = CreateChildFrameHeader(recipeFrame, "Profession")
		recipeFrame.rows = {}
		recipeFrame:Hide()
	end

	local function CreateRecipeRow(recipeFrame)
		local row = CreateFrame("Button", nil, recipeFrame)
		row:SetHeight(19)
		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
		row.text:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetWordWrap(false)
		row:RegisterForClicks("LeftButtonUp")
		row:SetScript("OnClick", function(self)
			if RQE.API.Client.IsShiftKeyDown() then
				RQE.API.SetTrackedRecipe(self.recipeID, false, self.isRecraft)
				return
			end
			RQE.API.OpenTrackedRecipe(self.recipeID)
		end)
		row:SetScript("OnEnter", function(self)
			RQE.API.ShowTrackedRecipeTooltip(self)
		end)
		row:SetScript("OnLeave", RQE.API.HideTrackedTooltip)
		return row
	end

	function RQE:RenderRecipeTrackingFrame(recipes)
		local recipeFrame = self.recipeTrackingFrame
		if not recipeFrame then return end
		local rowIndex, offset = 0, -35
		for _, recipe in ipairs(recipes) do
			rowIndex = rowIndex + 1
			local row = recipeFrame.rows[rowIndex] or CreateRecipeRow(recipeFrame)
			recipeFrame.rows[rowIndex] = row
			row.recipeID, row.isRecraft = recipe.id, recipe.isRecraft
			row.recipeName, row.itemID, row.currencyID = recipe.name, nil, nil
			local craftCount
			for _, reagent in ipairs(recipe.reagents) do
				if reagent.required > 0 then
					local possible = math.floor(reagent.count / reagent.required)
					craftCount = craftCount and math.min(craftCount, possible) or possible
				end
			end
			row.text:SetText(craftCount and string.format("%s [x%d]", recipe.name, craftCount) or recipe.name)
			row.text:SetTextColor(1, 0.82, 0)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", recipeFrame, "TOPLEFT", 12, offset)
			row:SetPoint("TOPRIGHT", recipeFrame, "TOPRIGHT", -12, offset)
			row:Show()
			offset = offset - 21
			for _, reagent in ipairs(recipe.reagents) do
				rowIndex = rowIndex + 1
				row = recipeFrame.rows[rowIndex] or CreateRecipeRow(recipeFrame)
				recipeFrame.rows[rowIndex] = row
				row.recipeID, row.isRecraft = recipe.id, recipe.isRecraft
				row.recipeName, row.itemID, row.currencyID = recipe.name, reagent.itemID, reagent.currencyID
				row.text:SetText(string.format("%s: %d/%d", reagent.name, reagent.count, reagent.required))
				if reagent.required > 0 and reagent.count >= reagent.required then
					row.text:SetTextColor(0.25, 1, 0.25)
				else
					row.text:SetTextColor(1, 1, 1)
				end
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", recipeFrame, "TOPLEFT", 26, offset)
				row:SetPoint("TOPRIGHT", recipeFrame, "TOPRIGHT", -12, offset)
				row:Show()
				offset = offset - 19
			end
			offset = offset - 7
		end
		for i = rowIndex + 1, #recipeFrame.rows do recipeFrame.rows[i]:Hide() end
		recipeFrame.trackedRecipeCount = #recipes
		recipeFrame._rqeRenderedHeight = math.max(60, -offset + 9)
		recipeFrame:SetHeight(recipeFrame._rqeRenderedHeight)
		recipeFrame:SetShown(#recipes > 0)
		if self.UpdateRecipeTrackingAnchor then self.UpdateRecipeTrackingAnchor() end
		self.RefreshQuestTrackerScrollRange()
		self:UpdateRQEQuestFrameVisibility()
	end

	-- Create headers for each child frame
	RQE.CampaignFrame.header = CreateChildFrameHeader(RQE.CampaignFrame, "Campaign")
	RQE.QuestsFrame.header = CreateChildFrameHeader(RQE.QuestsFrame, "Normal Quests")
	RQE.WorldQuestsFrame.header = CreateChildFrameHeader(RQE.WorldQuestsFrame, "World Quests")
	RQE.BonusQuestsFrame.header = CreateChildFrameHeader(RQE.BonusQuestsFrame, "Bonus Quests")
	RQE.TaskQuestsFrame.header = CreateChildFrameHeader(RQE.TaskQuestsFrame, "Task Quests")
	RQE.AchievementsFrame.header = CreateChildFrameHeader(RQE.AchievementsFrame, "Achievements")

	-------------------------------------------------------
	-- #3e. Scenario Header & Dynamic Height
	-------------------------------------------------------

	-- ScenarioChildFrame header
	-- Function to create a unique header for the ScenarioChildFrame
	local function CreateUniqueScenarioHeader(scenarioFrame, title)
		local header = CreateFrame("Frame", nil, scenarioFrame, "BackdropTemplate")
		header:SetFrameStrata("LOW")
		header:SetHeight(115)  -- Setting a custom height for the scenario header
		header:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 8,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
		if RQE.UI then RQE.UI:StyleHeader(header, true) end
		header:SetPoint("TOPLEFT", scenarioFrame, "TOPLEFT", 0, 0)
		header:SetPoint("TOPRIGHT", scenarioFrame, "TOPRIGHT", 0, 0)

		-- Create header text
		local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		headerText:SetPoint("CENTER", header, "CENTER", 0, -10)  -- Adjust Y offset to vertically center the text in the taller header
		headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
		headerText:SetTextColor(239/255, 191/255, 90/255)
		headerText:SetText(title)
		headerText:SetWordWrap(true)

		scenarioFrame.header = header  -- Assign the header to the scenario frame
		return header  -- Return the new header frame
	end


	-- Function to dynamically set ScenarioChildFrame height based on the number of criteria
	function RQE.SetScenarioChildFrameHeight()
		-- Check if the player is currently in a scenario
		-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario() then
		if not RQE.API.Client.C_Scenario.IsInScenario() then
			return
		end

		-- Fetch scenario information
		-- Previous Blizzard call changed 2026.09.25: local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
		local scenarioInfo = RQE.API.Client.C_ScenarioInfo.GetScenarioInfo()
		if not scenarioInfo then
			return
		end

		-- Fetch the number of criteria for the current scenario step
		-- Previous Blizzard call changed 2026.09.25: local numCriteria = select(3, C_Scenario.GetStepInfo()) or 0
		local numCriteria = select(3, RQE.API.Client.C_Scenario.GetStepInfo()) or 0

		-- Base height for the frame
		local baseHeight = 120

		-- Height per criteria (adjust as needed for proper spacing)
		local heightPerCriteria = 45

		-- Calculate the total height
		local totalHeight = baseHeight + (numCriteria * heightPerCriteria)

		-- Set the height of the ScenarioChildFrame dynamically
		RQE.ScenarioChildFrame:SetHeight(totalHeight)
	end


	-- Use the function to create a unique header for the ScenarioChildFrame
	RQE.ScenarioChildFrame = RQE.ScenarioChildFrame or CreateFrame("Frame", "RQEScenarioChildFrame", UIParent)
	CreateUniqueScenarioHeader(RQE.ScenarioChildFrame, "")


	-------------------------------------------------------
	-- #3f. Dynamic Category Header Counts
	-------------------------------------------------------

	local function UpdateHeader(frame, baseTitle, questCount)
		-- Previous Blizzard call changed 2026.09.25: local maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()
		local maxQuests = RQE.API.Client.C_QuestLog.GetMaxNumQuestsCanAccept()
		local numShownEntries, numQuestsInLog = RQE.API.GetNumQuestLogEntries()
		local titleText = baseTitle
		if frame == RQE.QuestsFrame then
			titleText = titleText .. " (" .. questCount .. "/" .. numQuestsInLog .. "/" .. maxQuests .. ")"
		else
			titleText = titleText .. " (" .. questCount .. ")"
		end
		if RQE.RefreshTrackerSectionHeaderText then
			RQE:RefreshTrackerSectionHeaderText(frame, titleText)
		else
			frame.header:SetText(titleText)
		end
	end


--------------------------------------------------
-- #4. 📐 Child Frame Anchoring & Dynamic Layout
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Default Category Anchors
	-------------------------------------------------------
	function RQE.UpdateRecipeTrackingAnchor()
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder()
			return
		end
		local recipeFrame = RQE.recipeTrackingFrame
		if not recipeFrame then return end
		local previous
		for _, section in ipairs({ RQE.TaskQuestsFrame, RQE.BonusQuestsFrame,
			RQE.WorldQuestsFrame, RQE.QuestsFrame, RQE.CampaignFrame, RQE.ScenarioChildFrame }) do
			if section and section:IsShown() then
				previous = section
				break
			end
		end
		recipeFrame:ClearAllPoints()
		if previous then
			recipeFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5)
		else
			recipeFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
		RQE.AchievementsFrame:ClearAllPoints()
		if recipeFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", recipeFrame, "BOTTOMLEFT", 0, -5)
		elseif previous then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -5)
		else
			RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
	end

	function UpdateFrameAnchors()
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder()
			return
		end
		-- Clear all points to prevent any previous anchoring affecting the new setup
		RQE.CampaignFrame:ClearAllPoints()
		RQE.QuestsFrame:ClearAllPoints()
		RQE.WorldQuestsFrame:ClearAllPoints()
		RQE.BonusQuestsFrame:ClearAllPoints()
		RQE.TaskQuestsFrame:ClearAllPoints()
		RQE.AchievementsFrame:ClearAllPoints()
		if RQE.recipeTrackingFrame then
			RQE.recipeTrackingFrame:ClearAllPoints()
		end

		-- Anchor CampaignFrame
		if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Anchor QuestsFrame
		if RQE.CampaignFrame:IsShown() then
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Anchor WorldQuestsFrame
		if RQE.QuestsFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Anchor Bonus Quests below World Quests, or the next visible section above it.
		if RQE.WorldQuestsFrame:IsShown() then
			RQE.BonusQuestsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.QuestsFrame:IsShown() then
			RQE.BonusQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.BonusQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.BonusQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.BonusQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Task Quests follow Bonus Quests, then fall back through the existing sections.
		if RQE.BonusQuestsFrame:IsShown() then
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", RQE.BonusQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.WorldQuestsFrame:IsShown() then
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.QuestsFrame:IsShown() then
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.TaskQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Anchor AchievementsFrame based on visibility of other frames
		if RQE.TaskQuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.TaskQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.BonusQuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.BonusQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.WorldQuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.QuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		RQE.UpdateRecipeTrackingAnchor()
	end


	-------------------------------------------------------
	-- #4b. Default Anchor Restoration
	-------------------------------------------------------

	-- Make the function global or move it outside where it is defined so it can be accessed by UpdateFrameAnchors
	function ResetChildFramesToDefault()
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder()
			return
		end
		-- CampaignFrame positioning
		if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- QuestsFrame positioning
		if RQE.CampaignFrame:IsShown() then
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- WorldQuestsFrame positioning
		if RQE.QuestsFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- AchievementsFrame positioning
		if RQE.WorldQuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.QuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
		elseif RQE.CampaignFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
		RQE.UpdateRecipeTrackingAnchor()
	end


	-------------------------------------------------------
	-- #4c. Content-Aware Category Positioning
	-------------------------------------------------------

	-- The themed child-frame border needs enough room below wrapped objectives to
	-- remain visually distinct from both the text and the following section header.
	local function GetQuestSectionBottomPadding()
		return (RQE.UI and RQE.UI:IsEnabled()) and 18 or 10
	end


	-- Adjust Set Point Anchor of Child Frames based on LastElements
	function UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
			return
		end
		-- Reset positions to default first
		ResetChildFramesToDefault()
		local elementStackGap = GetQuestSectionBottomPadding() + 5

		-- Adjusting Quests child frame position based on last campaign element
		if lastCampaignElement then
			RQE.QuestsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif not RQE.CampaignFrame:IsShown() and RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If there are no campaign quests but ScenarioChildFrame is shown
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		elseif not RQE.CampaignFrame:IsShown() then
			-- If there are no campaign quests, anchor QuestsFrame to content
			RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Adjusting World Quests child frame position based on last campaign element
		if lastQuestElement then
			-- If there's a last element in the regular quests frame, anchor to it
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", lastQuestElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif lastCampaignElement then
			-- If there's no last regular quest element but a last campaign element, anchor to it
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif RQE.CampaignFrame:IsShown() and not lastCampaignElement then
			-- If the Campaign frame is shown but there's no last campaign element, anchor to the Campaign frame
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.QuestsFrame:IsShown() and not lastQuestElement then
			-- If the Quests frame is shown but there's no last quest element, anchor to the Quests frame
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If the ScenarioChildFrame is shown, anchor to it
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			-- If neither Campaign nor Regular Quests frames have elements, anchor to the content
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Adjust AchievementsFrame position based on the presence of WorldQuest elements
		if RQE.WorldQuestsFrame:IsShown() and lastWorldQuestElement then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", lastWorldQuestElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif not RQE.WorldQuestsFrame:IsShown() and lastQuestElement then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", lastQuestElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif not RQE.WorldQuestsFrame:IsShown() and lastCampaignElement then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -GetTrackerQuestLabelInset(), -elementStackGap)
		elseif RQE.WorldQuestsFrame:IsShown() or RQE.QuestsFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame or RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame:IsShown() then
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -15)
		else
			RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
		RQE.UpdateRecipeTrackingAnchor()
	end


	-------------------------------------------------------
	-- #4d. Scenario-Aware Campaign Anchor
	-------------------------------------------------------

	-- Update the Campaign frame anchor dynamically based on the state of the ScenarioChild being is present or not
	function RQE.UpdateCampaignFrameAnchor()
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder()
			return
		end
		if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If ScenarioChildFrame is present and shown, anchor CampaignFrame to ScenarioChildFrame
			RQE.CampaignFrame:ClearAllPoints()  -- Clear existing points
			RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -35)
		else
			-- If ScenarioChildFrame is not present or not shown, anchor CampaignFrame to content
			RQE.CampaignFrame:ClearAllPoints()  -- Clear existing points
			RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
	end


--------------------------------------------------
-- #5. 🔘 Quest Tracker Header Controls
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Header Button Construction
	-------------------------------------------------------

	-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Right Side)
	RQE.Buttons.CreateQuestCloseButton(RQE.RQEQuestFrame)
	RQE.Buttons.CreateQuestMaximizeButton(RQE.RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)
	RQE.Buttons.CreateQuestMinimizeButton(RQE.RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)
	RQE.Buttons.CreateQuestFilterButton(RQE.RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)

	-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Left Side)
	RQE.Buttons.CQButton(RQE.RQEQuestFrame)

	-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Left Side)
	RQE.Buttons.SCButton(RQE.RQEQuestFrame)

	-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Left Side)
	RQE.Buttons.HQButton(RQE.RQEQuestFrame)

	-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Left Side)
	RQE.Buttons.ZQButton(RQE.RQEQuestFrame)
	RQE.Buttons.UpdateQuestTrackerHeaderTitle()


--------------------------------------------------
-- #6. 🖱️ Frame Events, Geometry & Responsive Sizing
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Resize, Drag & Context-Menu Events
	-------------------------------------------------------

	-- Event to update text widths when the frame is resized
	RQE.RQEQuestFrame:SetScript("OnSizeChanged", function(self, width, height)
		AdjustQuestItemWidths(width)
		SaveQuestFrameSize()
	end)


	-- Calls function to save Quest Frame Position OnDragStop
	RQE.RQEQuestFrame:SetScript("OnDragStop", function()
		RQE.RQEQuestFrame:StopMovingOrSizing()
		SaveQuestFramePosition()  -- This will save the current frame position
	end)


	-- Right-Click Event Logic
	RQE.RQEQuestFrame:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			ShowDropdownRQEQuestFrame()
		end
	end)


	-------------------------------------------------------
	-- #6b. Frame Geometry Persistence
	-------------------------------------------------------

	-- Define the function to save frame position
	function SaveQuestFramePosition()
		-- Do not write old-profile or startup geometry into the selected profile.
		if not RQE:CanSaveFrameGeometry() then return end
		local point, relativeTo, relativePoint, xOfs, yOfs = RQE.RQEQuestFrame:GetPoint()
		RQE.db.profile.QuestFramePosition.xPos = xOfs
		RQE.db.profile.QuestFramePosition.yPos = yOfs
		RQE.db.profile.QuestFramePosition.anchorPoint = relativePoint
	end


	-- Define the function to save frame position
	function SaveQuestFrameSize()
		-- Do not write old-profile or startup geometry into the selected profile.
		if not RQE:CanSaveFrameGeometry() then return end
		if RQE.QTMinimized then return end
		local width, height = RQE.RQEQuestFrame:GetSize()
		RQE.db.profile.QuestFramePosition.frameWidth = width
		RQE.db.profile.QuestFramePosition.frameHeight = height
	end


	-------------------------------------------------------
	-- #6c. Responsive Element Widths
	-------------------------------------------------------

	-- Function used to adjust the Questing Frame width
	function AdjustQuestItemWidths(frameWidth)
		-- Fallback: If frameWidth is not provided, use the width of a specific frame, e.g., RQEQuestFrame
		if not frameWidth then
			frameWidth = RQE.RQEQuestFrame:GetWidth() -- Adjust RQEQuestFrame to specific frame
		end

		-- Quest row margins must match the fixed 100/110 in the rendering paths.
		-- Movement also calls this function; scaling those margins made unchanged
		-- objectives wrap differently and changed the width of attached progress bars.
		-- Other responsive elements retain their existing proportional padding.
		local baseWidth = 400
		local paddingMultiplier = (frameWidth - baseWidth) / 400

		-- Define fixed quest row margins and base padding for other elements
		local basePadding = {
			-- Quest Base Padding
			QuestLevelAndName = 100,
			QuestObjectives = 110,
			QuestObjectivesOrDescription = 110,
			QuestTypeLabel = 130,

			-- World Quest Base Padding
			WQuestLevelAndName = 100,  -- Specific to WQuestLevelAndName
			WQuestObjectives = 110,  -- Specific to WQuestObjectives
			WQuestObjectivesOrDescription = 110,  -- Specific to WQuestObjectivesOrDescription
			WorldQuestTimeLeft = 45,
			WorldQuestDistance = 65,

			-- Scenario Base Padding
			ScenarioChildFrameBody = 75,  -- Added base padding for RQE.ScenarioChildFrame.body
			ScenarioChildFrameScenarioTitle = 55,  -- Added base padding for RQE.ScenarioChildFrame.scenarioTitle
			ScenarioChildFrameTitle = 75,  -- Added base padding for RQE.ScenarioChildFrame.title
			ScenarioTimerFrame = 15,

			TextPadding = 90,
			TimerFramePadding = 10, -- Additional padding for the timer frame if needed
		}

		-- Adjust widths for elements in RQE.QuestLogIndexButtons
		for i, button in ipairs(RQE.QuestLogIndexButtons or {}) do
			if button.QuestLevelAndName then
				button.QuestLevelAndName:SetWidth(frameWidth - basePadding.QuestLevelAndName)
			end

			if button.QuestObjectives then
				-- Match the objective width assigned when the quest row is rendered
				local dynamicPadding = basePadding.QuestObjectives
				button.QuestObjectives:SetWidth(frameWidth - dynamicPadding)
			end

			if button.QuestObjectivesOrDescription then
				-- Match the description width assigned when the quest row is rendered
				local dynamicPadding = basePadding.QuestObjectivesOrDescription
				button.QuestObjectivesOrDescription:SetWidth(frameWidth - dynamicPadding)
			end
		end

		-- Dynamic padding calculation for newly added elements
		local textPadding = basePadding.TextPadding * (1 + paddingMultiplier)
		local timerFramePadding = basePadding.TimerFramePadding * (1 + paddingMultiplier)

		-- Adjust widths for child frames and their headers
		local childFrames = {
			RQE.ScenarioChildFrame,
			RQE.CampaignFrame,
			RQE.QuestsFrame,
			RQE.WorldQuestsFrame,
			RQE.BonusQuestsFrame,
			RQE.TaskQuestsFrame,
			RQE.AchievementsFrame,
			RQE.recipeTrackingFrame,
		}

		-- Adjust width for each element
		for _, WQuestLogIndexButton in pairs(RQE.WQuestLogIndexButtons or {}) do
			-- Adjust WQuestLevelAndName width for each WQuestLogIndexButton
			if WQuestLogIndexButton.WQuestLevelAndName then
				local dynamicPadding = basePadding.WQuestLevelAndName
				WQuestLogIndexButton.WQuestLevelAndName:SetWidth(frameWidth - dynamicPadding)
			end

			-- Adjust WQuestObjectives width for each WQuestLogIndexButton
			if WQuestLogIndexButton.QuestObjectives then
				local dynamicPadding = basePadding.WQuestObjectives
				WQuestLogIndexButton.QuestObjectives:SetWidth(frameWidth - dynamicPadding)
			end

			-- Adjust WQuestObjectivesOrDescription width for each WQuestLogIndexButton
			if WQuestLogIndexButton.QuestObjectivesOrDescription then
				local dynamicPadding = basePadding.WQuestObjectivesOrDescription
				WQuestLogIndexButton.QuestObjectivesOrDescription:SetWidth(frameWidth - dynamicPadding)
			end

			-- Adjust WorldQuestTimeLeft width for each WQuestLogIndexButton
			if WQuestLogIndexButton.WQuestTimeLeft then
				local dynamicPadding = basePadding.WorldQuestTimeLeft * (1 + paddingMultiplier)
				WQuestLogIndexButton.WQuestTimeLeft:SetWidth(frameWidth - dynamicPadding)
			end

			-- Adjust WorldQuestDistance width for each WQuestLogIndexButton
			if WQuestLogIndexButton.WQuestDistance then
				local dynamicPadding = basePadding.WorldQuestDistance * (1 + paddingMultiplier)
				WQuestLogIndexButton.WQuestDistance:SetWidth(frameWidth - dynamicPadding)
			end
		end

		-- Adjust widths for elements in RQE.QuestLogIndexButtons
		for i, button in pairs(RQE.QuestLogIndexButtons or {}) do
			if button.QuestLevelAndName then
				button.QuestLevelAndName:SetWidth(frameWidth - basePadding.QuestLevelAndName)
			end

			if button.QuestObjectivesOrDescription then
				button.QuestObjectivesOrDescription:SetWidth(frameWidth - basePadding.QuestObjectivesOrDescription)
			end

			if button.QuestTypeLabel then
				button.QuestTypeLabel:SetWidth(frameWidth - (basePadding.QuestTypeLabel * (1 + paddingMultiplier)))
			end
		end

		-- Adjust width for RQE.ScenarioChildFrame.body using dynamic padding if not nil
		if RQE.ScenarioChildFrame.body then
			RQE.ScenarioChildFrame.body:SetWidth(frameWidth - (basePadding.ScenarioChildFrameBody * (1 + paddingMultiplier)))
		end

		-- Adjust width for RQE.ScenarioChildFrame.scenarioTitle using dynamic padding if not nil
		if RQE.ScenarioChildFrame.scenarioTitle then
			RQE.ScenarioChildFrame.scenarioTitle:SetWidth(frameWidth - (basePadding.ScenarioChildFrameScenarioTitle * (1 + paddingMultiplier)))
		end

		-- Adjust width for RQE.ScenarioChildFrame.title using dynamic padding if not nil
		if RQE.ScenarioChildFrame.title then
			RQE.ScenarioChildFrame.title:SetWidth(frameWidth - (basePadding.ScenarioChildFrameTitle * (1 + paddingMultiplier)))
		end

		-- Adjust width for RQE.ScenarioChildFrame.timerFrame using dynamic padding if not nil
		if RQE.ScenarioChildFrame.timerFrame then
			RQE.ScenarioChildFrame.timerFrame:SetWidth(frameWidth - (basePadding.ScenarioTimerFrame * (1 + paddingMultiplier)))
		end

		for _, childFrame in ipairs(childFrames) do
			if childFrame then
				-- Both presentations live inside the same viewport gutters. Keeping the
				-- child at viewport width gives legacy headers a visible right edge too.
				local childWidth = math.max(1, frameWidth - 40)
				childFrame:SetWidth(childWidth)

				-- Ordinary section .header values are their title FontStrings; the
				-- scenario stores a header frame whose two anchors already follow the
				-- corrected child width.
				if childFrame.header then
					local objectType = childFrame.header.GetObjectType and childFrame.header:GetObjectType()
					if objectType == "FontString" and childFrame._rqeCollapseButton
						and RQE.RefreshTrackerSectionHeaderText then
						RQE:RefreshTrackerSectionHeaderText(childFrame)
					elseif objectType == "FontString" then
						childFrame.header:SetWidth(math.max(1, childWidth - textPadding))
					end
				end

				-- Percentage bars are section children rather than FontStrings. Re-size
				-- them after the section and objective widths settle.
				if RQE.LayoutObjectiveProgressBar then
					for _, child in ipairs({ childFrame:GetChildren() }) do
						if child.RQEObjectiveText then
							RQE.LayoutObjectiveProgressBar(child)
						end
					end
				end
			end
		end

		-- Adjustment for RQE.AchievementsFrame specific elements
		-- criteriaText and achievementHeader are directly accessible here
		if RQE.AchievementsFrame.criteriaText then
			RQE.AchievementsFrame.criteriaText:SetWidth(frameWidth - textPadding)
		end
		if RQE.AchievementsFrame.achievementHeader then
			RQE.AchievementsFrame.achievementHeader:SetWidth(frameWidth - textPadding)
		end
	end


	-- Apply the viewport width once at creation; OnSizeChanged keeps it current
	-- after this when the player resizes or a saved frame width is restored.
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())


--------------------------------------------------
-- #7. 🧭 Quest Sorting, Distance & Context Actions
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Movement-Based Sorting Thresholds
	-------------------------------------------------------

	-- [Utility functions like AdjustQuestItemWidths, SaveQuestFramePosition, colorizeObjectives, RQE:QuestRewardsTooltip, etc.]

	-- Function to create and position the ScrollFrame's child frames
	local function shouldSortQuests()
		-- Previous Blizzard call changed 2026.09.25: local mapID = C_Map.GetBestMapForUnit("player")
		local mapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		if not mapID then
			return false  -- If no valid mapID, return false to prevent sorting
		end

		-- Previous Blizzard call changed 2026.09.25: local position = C_Map.GetPlayerMapPosition(mapID, "player")
		local position = RQE.API.Client.C_Map.GetPlayerMapPosition(mapID, "player")
		if not position then return false end

		local x, y = position:GetXY()
		if not RQE.lastX or not RQE.lastY or (abs(x - RQE.lastX) > 0.08 or abs(y - RQE.lastY) > 0.08) then
			RQE.lastX, RQE.lastY = x, y
			--print("X:" .. x .. ", Y:" .. y)
			return true
		end
		return false
	end


	local function shouldSortQuestsWhileDragonRiding()
		-- Previous Blizzard call changed 2026.09.25: local mapID = C_Map.GetBestMapForUnit("player")
		local mapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		if not mapID then
			return false  -- If no valid mapID, return false to prevent sorting
		end

		-- Previous Blizzard call changed 2026.09.25: local position = C_Map.GetPlayerMapPosition(mapID, "player")
		local position = RQE.API.Client.C_Map.GetPlayerMapPosition(mapID, "player")
		if not position then return false end

		local x, y = position:GetXY()
		if not RQE.lastX or not RQE.lastY or (abs(x - RQE.lastX) > 0.05 or abs(y - RQE.lastY) > 0.05) then
			RQE.lastX, RQE.lastY = x, y
			--print("X:" .. x .. ", Y:" .. y)
			return true
		end
		return false
	end


	-------------------------------------------------------
	-- #7b. Empty World Quest Watch Population
	-------------------------------------------------------

	-- Function that adds world quests with no steps to the watch list
	--[[ 
	/run RQE:AddEmptyWorldQuestsToWatch(2248)
	/run RQE:AddEmptyWorldQuestsToWatch(2339, { [10] = true, [9] = true })
	/run RQE:AddEmptyWorldQuestsToWatch()
	]]
	function RQE:AddEmptyWorldQuestsToWatch(mapID, allowedClassifications)
		-- Default to current zone if none passed
		-- Previous Blizzard call changed 2026.09.25: mapID = mapID or C_Map.GetBestMapForUnit("player")
		mapID = mapID or RQE.API.Client.C_Map.GetBestMapForUnit("player")
		if not mapID then
			print("Could not determine map ID.")
			return
		end

		-- Default to classification 10 (World Quest) only if no override
		allowedClassifications = allowedClassifications or { [10] = true }

		-- Fetch world quests on the map
		-- Previous Blizzard call changed 2026.09.25: local taskPOIs = C_TaskQuest.GetQuestsOnMap(mapID)
		local taskPOIs = RQE.API.Client.C_TaskQuest.GetQuestsOnMap(mapID)
		if not taskPOIs or #taskPOIs == 0 then
			print("No world quests found on this map.")
			return
		end

		for _, poi in ipairs(taskPOIs) do
			local questID = poi.questID
			if questID then
				-- Check classification
				-- Previous Blizzard call changed 2026.09.25: local classification = C_QuestInfoSystem.GetQuestClassification(questID)
				local classification = RQE.API.Client.C_QuestInfoSystem.GetQuestClassification(questID)
				if allowedClassifications[classification] then
					local questData = RQE.getQuestData(questID)
					local stepIndex = RQE.AddonSetStepIndex or 1
					local totalSteps = questData and #questData or 0

					if questData and stepIndex == 1 and totalSteps == 0 then
						-- Add to world quest watch
						-- Previous Blizzard call changed 2026.09.25: C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
						RQE.API.Client.C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)

						if RQE.db.profile.debugLevel == "INFO" then
							print(string.format("Watching empty WQ: %d - '%s'", questID, RQE.API.GetTitleForQuestID(questID) or "Unknown"))
						end
					end
				end
			end
		end
	end


	-------------------------------------------------------
	-- #7c. Database Zero-Step Watch List
	-------------------------------------------------------

	-- Function to clear all watched quests and add only those in DB with zero steps
	function RQE:WatchQuestsInDBWithNoSteps()
		-- Clear all currently watched quests
		-- Previous Blizzard call changed 2026.09.25: for i = 1, C_QuestLog.GetNumQuestWatches() do
		for i = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local watchedID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local watchedID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if watchedID then
				-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(watchedID)
				RQE.API.Client.C_QuestLog.RemoveQuestWatch(watchedID)
			end
		end

		if RQE.db.profile.debugLevel == "INFO" then
			print("Cleared all quest watches. Scanning for empty quests in DB...")
		end

		-- Loop through all quest log entries
		for i = 1, RQE.API.GetNumQuestLogEntries() do
			local info = RQE.API.GetQuestLogInfo(i)
			if info and not info.isHeader then
				local questID = info.questID
				local questData = RQE.getQuestData(questID)

				if questData then
					local totalSteps = #questData
					if totalSteps == 0 then
						-- Add to quest watch
						-- Previous Blizzard call changed 2026.09.25: C_QuestLog.AddQuestWatch(questID)
						RQE.API.Client.C_QuestLog.AddQuestWatch(questID)
						if RQE.db.profile.debugLevel == "INFO" then
							local title = RQE.API.GetTitleForQuestID(questID) or "Unknown"
							print(string.format("Watching quest with no steps: %d - '%s'", questID, title))
						end
					end
				end
			end
		end
	end


	-------------------------------------------------------
	-- #7d. Basic Proximity Sorting & Diagnostics
	-------------------------------------------------------

	-- Function that iterates through the watched quests and sorts them by proximity
	function SortQuestsByProximity()
		if RQE.PlayerMountStatus == "Dragonriding" then
			if shouldSortQuestsWhileDragonRiding() or RQE.canSortQuests then
				-- Logic to sort quests based on proximity
				-- Previous Blizzard call changed 2026.09.25: C_QuestLog.SortQuestWatches()
				RQE.API.Client.C_QuestLog.SortQuestWatches()
				GatherAndSortWorldQuestsByProximity()
				RQE.canSortQuests = false
			end
		else
			if shouldSortQuests() or RQE.canSortQuests then
				-- Logic to sort quests based on proximity
				-- Previous Blizzard call changed 2026.09.25: C_QuestLog.SortQuestWatches()
				RQE.API.Client.C_QuestLog.SortQuestWatches()
				GatherAndSortWorldQuestsByProximity()
				RQE.canSortQuests = false
			end
		end
	end


	-- Function that prints the currently watched quest along with a listing of distance
	function RQE:PrintSortedWatchedQuests()
		-- Previous Blizzard call changed 2026.09.25: local playerMapID = C_Map.GetBestMapForUnit("player")
		local playerMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		-- Previous Blizzard call changed 2026.09.25: local pos = C_Map.GetPlayerMapPosition(playerMapID, "player")
		local pos = RQE.API.Client.C_Map.GetPlayerMapPosition(playerMapID, "player")

		if not pos then
			print("Error: Unable to determine player position.")
			return
		end

		local playerX, playerY = pos:GetXY()
		print("Player Position:", playerX, playerY, "on Map ID:", playerMapID)

		local questDistances = {}

		-- Iterate over watched quests
		-- Previous Blizzard call changed 2026.09.25: for i = 1, C_QuestLog.GetNumQuestWatches() do
		for i = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)

			-- Get the squared distance to the quest
			-- Previous Blizzard call changed 2026.09.25: local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
			local distanceSq, onContinent = RQE.API.Client.C_QuestLog.GetDistanceSqToQuest(questID)

			-- Only include quests that are on the same continent
			if distanceSq and onContinent then
				table.insert(questDistances, { questID = questID, distanceSq = distanceSq })
			end
		end

		-- Sort quests by proximity (smallest distance first)
		table.sort(questDistances, function(a, b)
			return a.distanceSq < b.distanceSq
		end)

		-- Print sorted quest list
		print("Sorted Quest List by Proximity:")
		for _, data in ipairs(questDistances) do
			local questName = RQE.API.GetTitleForQuestID(data.questID) or "Unknown Quest"
			print(questName, "- QuestID:", data.questID, "- Distance:", math.sqrt(data.distanceSq))
		end
	end


	-------------------------------------------------------
	-- #7e. Retail Watch Sorting & Step-Distance Resolution
	-------------------------------------------------------

	-- Sort watched Retail quests within their tracker section. The distance key is
	-- deliberately produced by GetTrackerQuestStepDistance so the displayed yard
	-- value and the ordering can never come from different destinations.
	function RQE:SortWatchedQuestsByProximity()
		RQE.SortedWatchedQuests = {}

		-- Previous Blizzard call changed 2026.09.25: local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
		local numTrackedQuests = RQE.API.Client.C_QuestLog.GetNumQuestWatches()
		if numTrackedQuests == 0 then return end

		for sourceOrder = 1, numTrackedQuests do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(sourceOrder)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(sourceOrder)
			if questID and not RQE.API.IsWorldQuest(questID) then
				-- Previous Blizzard call changed 2026.09.25: local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
				local questLogIndex = RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)
				local questInfo = questLogIndex and RQE.API.GetQuestLogInfo(questLogIndex)
				local questTitle = (questInfo and questInfo.title)
					or (RQE.API.GetTitleForQuestID and RQE.API.GetTitleForQuestID(questID))
					or "Unknown Quest"
				local questLevel = tonumber(questInfo and questInfo.level) or -math.huge
				-- Previous Blizzard call changed 2026.09.25: local isCampaignQuest = C_CampaignInfo.IsCampaignQuest(questID) or C_QuestLog.IsMetaQuest(questID)
				local isCampaignQuest = RQE.API.Client.C_CampaignInfo.IsCampaignQuest(questID) or RQE.API.Client.C_QuestLog.IsMetaQuest(questID)
				local distanceYards, stepIndex = RQE:GetTrackerQuestStepDistance(questID)

				table.insert(RQE.SortedWatchedQuests, {
					questID = questID,
					distanceYards = distanceYards,
					distanceSq = distanceYards and distanceYards * distanceYards or math.huge,
					stepIndex = stepIndex,
					sectionRank = isCampaignQuest and 1 or 2,
					sectionName = isCampaignQuest and "Campaign/Meta" or "Normal Quests",
					questLevel = questLevel,
					questTitle = questTitle,
					questTitleSort = string.lower(tostring(questTitle)),
					sourceOrder = sourceOrder,
				})
			end
		end

		-- Within each header: measured distances ascend. N/A entries follow, with
		-- higher-level quests first and same-level quests ordered alphabetically.
		table.sort(RQE.SortedWatchedQuests, function(a, b)
			if a.sectionRank ~= b.sectionRank then
				return a.sectionRank < b.sectionRank
			end

			local aHasDistance = a.distanceYards ~= nil
			local bHasDistance = b.distanceYards ~= nil
			if aHasDistance ~= bHasDistance then
				return aHasDistance
			end

			if aHasDistance and a.distanceYards ~= b.distanceYards then
				return a.distanceYards < b.distanceYards
			end

			if not aHasDistance and a.questLevel ~= b.questLevel then
				return a.questLevel > b.questLevel
			end

			if a.questTitleSort ~= b.questTitleSort then
				return a.questTitleSort < b.questTitleSort
			end
			if a.questID ~= b.questID then
				return a.questID < b.questID
			end
			return a.sourceOrder < b.sourceOrder
		end)

		-- Debug Print
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Sorted watched quests by section and proximity:")
			for i, questData in ipairs(RQE.SortedWatchedQuests) do
				local displayDistance = questData.distanceYards
					and string.format("%.0f yds", questData.distanceYards)
					or "N/A"
				print(i .. ". QuestID:", questData.questID, "- Section:", questData.sectionName,
					"- Level:", questData.questLevel, "- Distance:", displayDistance)
			end
		end
	end


	-- Keep tracker step indexes in character SavedVariables without changing the
	-- legacy trackedQuests array. WoW writes this table to disk on logout/reload;
	-- during play RQE and RQECharacterDB share this same in-memory table.
	RQECharacterDB = RQECharacterDB or {}
	RQECharacterDB.trackedQuestStepIndexes = RQECharacterDB.trackedQuestStepIndexes or {}
	RQE.trackerQuestStepCache = RQECharacterDB.trackedQuestStepIndexes


	local function IsValidTrackerDBStep(questData, stepIndex)
		stepIndex = tonumber(stepIndex)
		return stepIndex and stepIndex >= 1 and stepIndex % 1 == 0
			and type(questData and questData[stepIndex]) == "table"
	end


	local function GetLiveTrackerQuestOwnerID()
		local displayedQuestID = tonumber(RQE.DisplayedQuestID)
		local superTrackedQuestID = RQE.API.GetSuperTrackedQuestID and tonumber(RQE.API.GetSuperTrackedQuestID())
		if superTrackedQuestID == 0 then superTrackedQuestID = nil end

		if displayedQuestID and superTrackedQuestID then
			if displayedQuestID == superTrackedQuestID then
				return displayedQuestID
			end
			return nil
		end
		return displayedQuestID or superTrackedQuestID
	end


	-- AddonSetStepIndex belongs to one quest only. Never copy it to another row in
	-- the tracker merely because that row is watched.
	local function GetLiveTrackerQuestStepIndex(questID, questData)
		local ownerQuestID = GetLiveTrackerQuestOwnerID()

		local stepIndex = tonumber(RQE.AddonSetStepIndex)
		if ownerQuestID == tonumber(questID) and IsValidTrackerDBStep(questData, stepIndex) then
			return stepIndex
		end
	end


	local function GetLiveTrackerQuestStep()
		local ownerQuestID = GetLiveTrackerQuestOwnerID()
		if not ownerQuestID then return nil end
		local questData = RQE.getQuestData and RQE.getQuestData(ownerQuestID)
		local stepIndex = GetLiveTrackerQuestStepIndex(ownerQuestID, questData)
		if stepIndex then return ownerQuestID, stepIndex end
	end


	local function ParseTrackerRequiredAmount(rawAmount)
		if type(rawAmount) == "string" then
			local combinedAmount = rawAmount:match("^%s*(%d+)%s*%+%s*objective%s*$")
			if combinedAmount then
				return tonumber(combinedAmount) or 1, true
			end
		end
		return tonumber(rawAmount) or 1, false
	end


	local function GetTrackerObjectiveProgress(objectives, stepData)
		local objectiveIndex = tonumber(stepData and stepData.objectiveIndex) or 1
		local objective = objectives and objectives[objectiveIndex]
		return objective and (tonumber(objective.numFulfilled) or 0) or 0, objectiveIndex, objective
	end


	local function GetTrackerItemCount(itemID)
		-- Previous Blizzard call changed 2026.09.25: if C_Item and C_Item.GetItemCount then
		if C_Item and RQE.API.ResolveClientAPI("C_Item.GetItemCount") then
			-- Previous Blizzard call changed 2026.09.25: return tonumber(C_Item.GetItemCount(itemID)) or 0
			return tonumber(RQE.API.Client.C_Item.GetItemCount(itemID)) or 0
		end
		-- Previous Blizzard call changed 2026.09.25: if GetItemCount then
		if RQE.API.ResolveClientAPI("GetItemCount") then
			-- Previous Blizzard call changed 2026.09.25: return tonumber(GetItemCount(itemID, false)) or 0
			return tonumber(RQE.API.Client.GetItemCount(itemID, false)) or 0
		end
		return 0
	end


	local function GetTrackerAuraStacks(auraName, filter)
		-- Previous Blizzard call changed 2026.09.25: if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName) then return 0 end
		if not (C_UnitAuras and RQE.API.ResolveClientAPI("C_UnitAuras.GetAuraDataBySpellName")) then return 0 end
		-- Previous Blizzard call changed 2026.09.25: local aura = C_UnitAuras.GetAuraDataBySpellName("player", auraName, filter)
		local aura = RQE.API.Client.C_UnitAuras.GetAuraDataBySpellName("player", auraName, filter)
		if not aura then return 0 end
		return aura.applications and aura.applications > 0 and aura.applications or 1
	end


	-- Conditionals are deliberately allowlisted. The normal progression engine can
	-- execute arbitrary RQE functions; doing that for every watched quest would be
	-- unsafe because some of those functions click buttons or change waypoints.
	local trackerConditionalAllowlist = {
		CheckCoordinateDistance = true,
		CheckKnownSpell = true,
		CheckMap = true,
		CheckQuestState = true,
	}


	local function EvaluateTrackerConditional(condition)
		if type(condition) ~= "string" then return false end
		local functionName, rawParameters = condition:match("RQE%.([%w_]+)%((.-)%)")
		if not (functionName and trackerConditionalAllowlist[functionName] and type(RQE[functionName]) == "function") then
			return false
		end

		local parameters = {}
		for rawParameter in string.gmatch(rawParameters or "", "[^,]+") do
			rawParameter = rawParameter:gsub("^%s+", ""):gsub("%s+$", "")
			local numericParameter = tonumber(rawParameter)
			if numericParameter then
				table.insert(parameters, numericParameter)
			else
				table.insert(parameters, rawParameter:gsub("^['\"]", ""):gsub("['\"]$", ""))
			end
		end

		local succeeded, result = pcall(RQE[functionName], RQE, unpack(parameters))
		return succeeded and result == true
	end


	-- Read-only counterpart to the progression checks used by StartPeriodicChecks.
	-- It queries state but never clicks a waypoint button, changes a macro, mutates
	-- AddonSetStepIndex, or schedules another evaluation.
	local function EvaluateTrackerDBCheck(questID, stepIndex, stepData, checkData, objectives)
		local functionName = checkData.funct
		local check = checkData.check or {}
		local neededAmount = checkData.neededAmt or {}

		if functionName == "CheckDBInventory" then
			local objectiveProgress = GetTrackerObjectiveProgress(objectives, stepData)
			for index, itemID in ipairs(check) do
				local required, includeObjective = ParseTrackerRequiredAmount(neededAmount[index])
				local current = GetTrackerItemCount(itemID) + (includeObjective and objectiveProgress or 0)
				if current < required then return false end
			end
			return #check > 0

		elseif functionName == "CheckDBBuff" or functionName == "CheckDBDebuff" then
			local objectiveProgress = GetTrackerObjectiveProgress(objectives, stepData)
			local auraFilter = functionName == "CheckDBBuff" and "HELPFUL" or "HARMFUL"
			for index, auraName in ipairs(check) do
				local required, includeObjective = ParseTrackerRequiredAmount(neededAmount[index])
				local current = GetTrackerAuraStacks(auraName, auraFilter) + (includeObjective and objectiveProgress or 0)
				if current < required then return false end
			end
			return #check > 0

		elseif functionName == "CheckDBZoneChange" then
			-- Previous Blizzard call changed 2026.09.25: local currentMapID = C_Map.GetBestMapForUnit("player")
			local currentMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
			-- Previous Blizzard call changed 2026.09.25: local currentSubZone = tostring(GetSubZoneText and GetSubZoneText() or ""):lower()
			local currentSubZone = tostring(RQE.API.ResolveClientAPI("GetSubZoneText") and RQE.API.Client.GetSubZoneText() or ""):lower()
			-- Previous Blizzard call changed 2026.09.25: local currentZone = tostring(GetZoneText and GetZoneText() or ""):lower()
			local currentZone = tostring(RQE.API.ResolveClientAPI("GetZoneText") and RQE.API.Client.GetZoneText() or ""):lower()
			-- Previous Blizzard call changed 2026.09.25: local currentRealZone = tostring(GetRealZoneText and GetRealZoneText() or ""):lower()
			local currentRealZone = tostring(RQE.API.ResolveClientAPI("GetRealZoneText") and RQE.API.Client.GetRealZoneText() or ""):lower()
			for _, mapOrZone in ipairs(check) do
				local requiredMapID = tonumber(mapOrZone)
				if (requiredMapID and requiredMapID == currentMapID)
					or (not requiredMapID and (
						currentSubZone == tostring(mapOrZone):lower()
						or currentZone == tostring(mapOrZone):lower()
						or currentRealZone == tostring(mapOrZone):lower()
					))
				then
					return true
				end
			end
			return false

		elseif functionName == "CheckDBObjectiveStatus" then
			local _, objectiveIndex, objective = GetTrackerObjectiveProgress(objectives, stepData)
			if not objective then return false end

			local objectiveType
			-- Previous Blizzard call changed 2026.09.25: if GetQuestObjectiveInfo then
			if RQE.API.ResolveClientAPI("GetQuestObjectiveInfo") then
				-- Previous Blizzard call changed 2026.09.25: objectiveType = select(2, GetQuestObjectiveInfo(questID, objectiveIndex, false))
				objectiveType = select(2, RQE.API.Client.GetQuestObjectiveInfo(questID, objectiveIndex, false))
			end

			for index = 1, math.max(1, #neededAmount) do
				local required = tonumber(neededAmount[index]) or 1
				-- Previous Blizzard call changed 2026.09.25: if objectiveType == "progressbar" and GetQuestProgressBarPercent then
				if objectiveType == "progressbar" and RQE.API.ResolveClientAPI("GetQuestProgressBarPercent") then
					if required == 1 then required = 100 elseif required == 0.01 then required = 1 end
					-- Previous Blizzard call changed 2026.09.25: if (tonumber(GetQuestProgressBarPercent(questID)) or 0) < required then return false end
					if (tonumber(RQE.API.Client.GetQuestProgressBarPercent(questID)) or 0) < required then return false end
				else
					local fulfilled = tonumber(objective.numFulfilled) or 0
					if fulfilled < required then return false end
					local totalRequired = tonumber(objective.numRequired)
					if totalRequired and fulfilled >= totalRequired and objective.finished ~= true then return false end
				end
			end
			return true

		elseif functionName == "CheckDBComplete" then
			local checkedQuestID = tonumber(check[1]) or questID
			-- Previous Blizzard call changed 2026.09.25: return C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(checkedQuestID) == true
			return RQE.API.ResolveClientAPI("C_QuestLog.ReadyForTurnIn") and RQE.API.Client.C_QuestLog.ReadyForTurnIn(checkedQuestID) == true

		elseif functionName == "CheckScenarioStage" then
			-- Previous Blizzard call changed 2026.09.25: if not (C_Scenario and C_Scenario.IsInScenario and C_Scenario.IsInScenario()) then return false end
			if not (C_Scenario and RQE.API.ResolveClientAPI("C_Scenario.IsInScenario") and RQE.API.Client.C_Scenario.IsInScenario()) then return false end
			-- Previous Blizzard call changed 2026.09.25: local scenarioInfo = C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo and C_ScenarioInfo.GetScenarioInfo()
			local scenarioInfo = C_ScenarioInfo and RQE.API.ResolveClientAPI("C_ScenarioInfo.GetScenarioInfo") and RQE.API.Client.C_ScenarioInfo.GetScenarioInfo()
			return scenarioInfo and tonumber(scenarioInfo.currentStage)
				and scenarioInfo.currentStage >= (tonumber(neededAmount[1]) or 1) or false

		elseif functionName == "CheckScenarioCriteria" then
			-- Previous Blizzard call changed 2026.09.25: if not (C_Scenario and C_Scenario.IsInScenario and C_Scenario.IsInScenario()) then return false end
			if not (C_Scenario and RQE.API.ResolveClientAPI("C_Scenario.IsInScenario") and RQE.API.Client.C_Scenario.IsInScenario()) then return false end
			local results = {}
			for index, criteriaIndex in ipairs(check) do
				-- Previous Blizzard call changed 2026.09.25: local criteriaInfo = C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo
				local criteriaInfo = C_ScenarioInfo and RQE.API.ResolveClientAPI("C_ScenarioInfo.GetCriteriaInfo")
					-- Previous Blizzard call changed 2026.09.25: and C_ScenarioInfo.GetCriteriaInfo(tonumber(criteriaIndex))
					and RQE.API.Client.C_ScenarioInfo.GetCriteriaInfo(tonumber(criteriaIndex))
				results[index] = criteriaInfo
					and (tonumber(criteriaInfo.quantity) or 0) >= (tonumber(neededAmount[index]) or tonumber(criteriaInfo.totalQuantity) or 1)
					or false
			end

			local logic = checkData.logic or "AND"
			if logic == "OR" then
				for _, result in ipairs(results) do if result then return true end end
				return false
			elseif logic == "NOT" then
				for _, result in ipairs(results) do if result then return false end end
				return true
			end
			for _, result in ipairs(results) do if not result then return false end end
			return #results > 0

		elseif functionName == "CheckDBConditionalsOnly" then
			return EvaluateTrackerConditional(checkData.cond)
		end

		-- Unknown functions fail closed at this step instead of being called.
		return false
	end


	local function EvaluateTrackerDBStep(questID, stepIndex, stepData, objectives)
		if stepData.checks then
			local overallResult
			for _, checkData in ipairs(stepData.checks) do
				-- This mirrors the progression engine's conditional short-circuit.
				if checkData.cond and EvaluateTrackerConditional(checkData.cond) then
					return true
				end

				local currentResult = EvaluateTrackerDBCheck(questID, stepIndex, stepData, checkData, objectives) == true
				local modifier = checkData.mod or ""
				if modifier == "OR" then
					overallResult = (overallResult or false) or currentResult
				elseif modifier == "AND" then
					overallResult = (overallResult or false) and currentResult
				elseif modifier == "NOT" then
					overallResult = not currentResult
				else
					overallResult = currentResult
				end
			end
			return overallResult == true
		end

		if stepData.funct then
			return EvaluateTrackerDBCheck(questID, stepIndex, stepData, stepData, objectives)
		end

		local objectiveIndex = tonumber(stepData.objectiveIndex)
		if objectiveIndex == 99 then
			-- Previous Blizzard call changed 2026.09.25: return C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID) == true
			return RQE.API.ResolveClientAPI("C_QuestLog.ReadyForTurnIn") and RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID) == true
		elseif objectiveIndex and objectives[objectiveIndex] then
			return objectives[objectiveIndex].finished == true
		end

		-- A navigation-only step with no completion check is the active step.
		return false
	end


	local function ShouldSkipTrackerStepForFaction(stepData)
		local description = tostring(stepData and stepData.description or "")
		local requiredFaction = description:match("^%s*(ALLIANCE):") or description:match("^%s*(HORDE):")
		if not requiredFaction then return false end
		-- Previous Blizzard call changed 2026.09.25: local playerFaction = UnitFactionGroup and UnitFactionGroup("player")
		local playerFaction = RQE.API.ResolveClientAPI("UnitFactionGroup") and RQE.API.Client.UnitFactionGroup("player")
		return playerFaction and requiredFaction ~= string.upper(playerFaction)
	end


	local function ResolveTrackerQuestStepIndex(questID, questData)
		-- Previous Blizzard call changed 2026.09.25: if (C_QuestLog.IsComplete and C_QuestLog.IsComplete(questID))
		if (RQE.API.ResolveClientAPI("C_QuestLog.IsComplete") and RQE.API.Client.C_QuestLog.IsComplete(questID))
			-- Previous Blizzard call changed 2026.09.25: or (C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questID))
			or (RQE.API.ResolveClientAPI("C_QuestLog.ReadyForTurnIn") and RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID))
		then
			for stepIndex, stepData in ipairs(questData) do
				if tonumber(stepData.objectiveIndex) == 99 or stepData.funct == "CheckDBComplete" then
					return stepIndex
				end
			end
		end

		local objectives = RQE.API.GetQuestObjectives(questID) or {}
		for stepIndex, stepData in ipairs(questData) do
			if not ShouldSkipTrackerStepForFaction(stepData)
				and not EvaluateTrackerDBStep(questID, stepIndex, stepData, objectives)
			then
				return stepIndex
			end
		end

		return #questData > 0 and #questData or nil
	end


	function RQE:ClearTrackedQuestStepIndex(questID)
		-- The cache aliases SavedVariables; leave it intact until tracking is restored.
		if self.PendingTrackerStateRestore then return end
		questID = tonumber(questID)
		if questID and RQE.trackerQuestStepCache then
			RQE.trackerQuestStepCache[questID] = nil
		end
	end


	-- Write the single authoritative live step through to the cache entry owned by
	-- that same watched quest. This is a constant-time state copy apart from the
	-- small watch-list membership check; it does not evaluate DB checks.
	function RQE:SyncLiveTrackedQuestStepIndex()
		-- The cache aliases SavedVariables; leave it intact until tracking is restored.
		if self.PendingTrackerStateRestore then return end
		local ownerQuestID, liveStepIndex = GetLiveTrackerQuestStep()
		if not (ownerQuestID and liveStepIndex) then return end

		local isWatched = false
		-- Previous Blizzard call changed 2026.09.25: for watchIndex = 1, C_QuestLog.GetNumQuestWatches() do
		for watchIndex = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex) == ownerQuestID then
			if RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex) == ownerQuestID then
				isWatched = true
				break
			end
		end
		if not isWatched or RQE.API.IsWorldQuest(ownerQuestID) then return end

		RQE.trackerQuestStepCache[ownerQuestID] = liveStepIndex
		return ownerQuestID, liveStepIndex
	end


	-- Returns the step cached specifically for this quest. A full DB scan happens
	-- only for a missing/new entry or when forceResolve is requested by a real map
	-- transition. The active quest's authoritative live step is always accepted.
	function RQE:GetNextIncompleteTrackerStepIndex(questID, forceResolve)
		-- Display the saved step during startup without recalculating/persisting it.
		if self.PendingTrackerStateRestore then
			return self.trackerQuestStepCache[tonumber(questID)]
		end
		questID = tonumber(questID)
		if not questID then return nil end

		local questData = RQE.getQuestData and RQE.getQuestData(questID)
		if type(questData) ~= "table" then
			self:ClearTrackedQuestStepIndex(questID)
			return nil
		end

		local liveStepIndex = GetLiveTrackerQuestStepIndex(questID, questData)
		if liveStepIndex then
			RQE.trackerQuestStepCache[questID] = liveStepIndex
			return liveStepIndex
		end

		local cachedStepIndex = RQE.trackerQuestStepCache[questID]
		if not forceResolve and IsValidTrackerDBStep(questData, cachedStepIndex) then
			return tonumber(cachedStepIndex)
		end

		local resolvedStepIndex = ResolveTrackerQuestStepIndex(questID, questData)
		if IsValidTrackerDBStep(questData, resolvedStepIndex) then
			RQE.trackerQuestStepCache[questID] = resolvedStepIndex
			return resolvedStepIndex
		end

		self:ClearTrackedQuestStepIndex(questID)
	end


	-- Re-resolve all watched Retail non-world quests after an actual map change.
	-- This function is intentionally never called by the movement refresh path.
	function RQE:RefreshTrackedQuestStepIndexes()
		-- The cache aliases SavedVariables; leave it intact until tracking is restored.
		if self.PendingTrackerStateRestore then return end
		local watchedQuestIDs = {}
		-- Previous Blizzard call changed 2026.09.25: for watchIndex = 1, C_QuestLog.GetNumQuestWatches() do
		for watchIndex = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
			if questID and not RQE.API.IsWorldQuest(questID) then
				watchedQuestIDs[questID] = true
				self:GetNextIncompleteTrackerStepIndex(questID, true)
			end
		end

		for questID in pairs(RQE.trackerQuestStepCache) do
			if not watchedQuestIDs[tonumber(questID) or questID] then
				RQE.trackerQuestStepCache[questID] = nil
			end
		end
	end


	-- Returns an exact yard distance to the coordinate selected for the next
	-- incomplete RQE step. If that step has no RQE coordinate, fall back to
	-- Blizzard's quest POI and then its next-waypoint destination.
	local function GetPlayerDistanceToMapPositionYards(mapID, x, y)
		mapID, x, y = tonumber(mapID), tonumber(x), tonumber(y)
		if not (mapID and x and y) then return nil end

		-- RQE database coordinates may be stored as percentages, while Blizzard's
		-- quest POI APIs return normalized coordinates.
		if x > 1 or y > 1 then
			x, y = x / 100, y / 100
		end

		local targetPosition = CreateVector2D and CreateVector2D(x, y)
		local function GetWorldDistance(playerMapID, playerPosition)
			-- Previous Blizzard call changed 2026.09.25: if not (targetPosition and C_Map.GetWorldPosFromMapPos and playerMapID and playerPosition) then
			if not (targetPosition and RQE.API.ResolveClientAPI("C_Map.GetWorldPosFromMapPos") and playerMapID and playerPosition) then
				return nil
			end

			-- Previous Blizzard call changed 2026.09.25: local playerContinent, playerWorldPosition = C_Map.GetWorldPosFromMapPos(playerMapID, playerPosition)
			local playerContinent, playerWorldPosition = RQE.API.Client.C_Map.GetWorldPosFromMapPos(playerMapID, playerPosition)
			-- Previous Blizzard call changed 2026.09.25: local targetContinent, targetWorldPosition = C_Map.GetWorldPosFromMapPos(mapID, targetPosition)
			local targetContinent, targetWorldPosition = RQE.API.Client.C_Map.GetWorldPosFromMapPos(mapID, targetPosition)
			if not (playerWorldPosition and targetWorldPosition and playerContinent == targetContinent) then
				return nil
			end

			local playerWorldX, playerWorldY = playerWorldPosition:GetXY()
			local targetWorldX, targetWorldY = targetWorldPosition:GetXY()
			if not (playerWorldX and playerWorldY and targetWorldX and targetWorldY) then
				return nil
			end

			local deltaX = targetWorldX - playerWorldX
			local deltaY = targetWorldY - playerWorldY
			return math.sqrt(deltaX * deltaX + deltaY * deltaY)
		end

		-- Ask for the player's position on the destination map first. This avoids
		-- child/parent map mismatches and works for maps whose world origin is absent.
		-- Previous Blizzard call changed 2026.09.25: local playerOnTargetMap = C_Map.GetPlayerMapPosition(mapID, "player")
		local playerOnTargetMap = RQE.API.Client.C_Map.GetPlayerMapPosition(mapID, "player")
		if playerOnTargetMap then
			local distance = GetWorldDistance(mapID, playerOnTargetMap)
			if distance then return distance end

			-- Retail documents these dimensions in yards, so this is still an exact
			-- same-map distance when GetWorldPosFromMapPos is unavailable.
			-- Previous Blizzard call changed 2026.09.25: if C_Map.GetMapWorldSize then
			if RQE.API.ResolveClientAPI("C_Map.GetMapWorldSize") then
				-- Previous Blizzard call changed 2026.09.25: local mapWidth, mapHeight = C_Map.GetMapWorldSize(mapID)
				local mapWidth, mapHeight = RQE.API.Client.C_Map.GetMapWorldSize(mapID)
				local playerX, playerY = playerOnTargetMap:GetXY()
				if mapWidth and mapHeight and mapWidth > 0 and mapHeight > 0 and playerX and playerY then
					local deltaX = (x - playerX) * mapWidth
					local deltaY = (y - playerY) * mapHeight
					return math.sqrt(deltaX * deltaX + deltaY * deltaY)
				end
			end
		end

		-- Cross-map native world-space attempt, followed by the addon's existing HBD
		-- translator for maps that require its parent/child map transforms.
		-- Previous Blizzard call changed 2026.09.25: local playerMapID = C_Map.GetBestMapForUnit("player")
		local playerMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		-- Previous Blizzard call changed 2026.09.25: local playerPosition = playerMapID and C_Map.GetPlayerMapPosition(playerMapID, "player")
		local playerPosition = playerMapID and RQE.API.Client.C_Map.GetPlayerMapPosition(playerMapID, "player")
		local distance = GetWorldDistance(playerMapID, playerPosition)
		if distance then return distance end

		if RQE.WPUtil and RQE.WPUtil.PlayerDistanceTo then
			local hbdDistance, unit = RQE.WPUtil.PlayerDistanceTo(mapID, x, y)
			if hbdDistance and unit == "yards" then
				return hbdDistance
			end
		end
	end


	-- The visible no-database W-button tooltip obtains its coordinates from
	-- RQE.PullDataFromMapQuests/C_QuestLog.GetQuestsOnMap. Cache that same snapshot
	-- briefly so refreshing a full tracker only scans Blizzard's POIs once.
	local function GetTrackerBlizzardPOICoordinates(questID)
		-- Previous Blizzard call changed 2026.09.25: local playerMapID = C_Map.GetBestMapForUnit("player")
		local playerMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		if not playerMapID then return nil end

		-- Previous Blizzard call changed 2026.09.25: local now = GetTime()
		local now = RQE.API.Client.GetTime()
		local cache = RQE.trackerBlizzardPOICache
		if not cache or cache.mapID ~= playerMapID or now - cache.updatedAt >= 1 then
			local quests = RQE.PullDataFromMapQuests and RQE.PullDataFromMapQuests() or {}
			cache = {
				mapID = playerMapID,
				updatedAt = now,
				quests = quests,
			}
			RQE.trackerBlizzardPOICache = cache
		end

		local questPOI = cache.quests and cache.quests[questID]
		if questPOI and questPOI.x and questPOI.y then
			return questPOI.x, questPOI.y, questPOI.mapID or playerMapID
		end
	end


	function RQE:GetTrackerQuestStepDistance(questID, stepIndex, useProvidedStepIndex)
		if not useProvidedStepIndex then
			stepIndex = RQE:GetNextIncompleteTrackerStepIndex(questID)
		end
		if stepIndex and RQE.GetDBStepCoordinates then
			local x, y, mapID = RQE:GetDBStepCoordinates(questID, stepIndex)
			if x and y and mapID then
				local distance = GetPlayerDistanceToMapPositionYards(mapID, x, y)
				if distance then
					return distance, stepIndex
				end

				-- A usable RQE step coordinate always takes precedence over Blizzard's
				-- quest waypoint, even if its yard distance is temporarily unavailable.
				return nil, stepIndex
			end
		end

		-- Use the exact Blizzard quest-POI source shown by the W-button tooltip before
		-- trying route/transition waypoints. This covers quests such as 29513 that
		-- have a map objective POI but no RQE database entry or direction waypoint.
		local poiX, poiY, poiMapID = GetTrackerBlizzardPOICoordinates(questID)
		if poiX and poiY and poiMapID then
			local distance = GetPlayerDistanceToMapPositionYards(poiMapID, poiX, poiY)
			if distance then
				return distance
			end
		end

		-- Next ask Blizzard for a route waypoint on the quest's UI map, rather than
		-- assuming the player's best map is the same.
		-- Previous Blizzard call changed 2026.09.25: local questMapID = GetQuestUiMapID and GetQuestUiMapID(questID)
		local questMapID = RQE.API.ResolveClientAPI("GetQuestUiMapID") and RQE.API.Client.GetQuestUiMapID(questID)
		-- Previous Blizzard call changed 2026.09.25: if questMapID and C_QuestLog.GetNextWaypointForMap then
		if questMapID and RQE.API.ResolveClientAPI("C_QuestLog.GetNextWaypointForMap") then
			-- Previous Blizzard call changed 2026.09.25: local x, y = C_QuestLog.GetNextWaypointForMap(questID, questMapID)
			local x, y = RQE.API.Client.C_QuestLog.GetNextWaypointForMap(questID, questMapID)
			if x and y then
				local distance = GetPlayerDistanceToMapPositionYards(questMapID, x, y)
				if distance then
					return distance
				end
			end
		end

		-- Generic route/transition waypoint fallback.
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.GetNextWaypoint then
		if RQE.API.ResolveClientAPI("C_QuestLog.GetNextWaypoint") then
			-- Previous Blizzard call changed 2026.09.25: local mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
			local mapID, x, y = RQE.API.Client.C_QuestLog.GetNextWaypoint(questID)
			if mapID and x and y then
				local distance = GetPlayerDistanceToMapPositionYards(mapID, x, y)
				if distance then
					return distance
				end
			end
		end

		-- Last resort: look for a waypoint on the player's current map.
		-- Previous Blizzard call changed 2026.09.25: local playerMapID = C_Map.GetBestMapForUnit("player")
		local playerMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		-- Previous Blizzard call changed 2026.09.25: if playerMapID and C_QuestLog.GetNextWaypointForMap then
		if playerMapID and RQE.API.ResolveClientAPI("C_QuestLog.GetNextWaypointForMap") then
			-- Previous Blizzard call changed 2026.09.25: local x, y = C_QuestLog.GetNextWaypointForMap(questID, playerMapID)
			local x, y = RQE.API.Client.C_QuestLog.GetNextWaypointForMap(questID, playerMapID)
			if x and y then
				local distance = GetPlayerDistanceToMapPositionYards(playerMapID, x, y)
				if distance then
					return distance
				end
			end
		end

		-- Blizzard's quest-distance API uses the same active objective destination and
		-- is a final fallback if a POI exists but no coordinate conversion is exposed.
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.GetDistanceSqToQuest then
		if RQE.API.ResolveClientAPI("C_QuestLog.GetDistanceSqToQuest") then
			-- Previous Blizzard call changed 2026.09.25: local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
			local distanceSq, onContinent = RQE.API.Client.C_QuestLog.GetDistanceSqToQuest(questID)
			if distanceSq and onContinent then
				return math.sqrt(distanceSq)
			end
		end

		return nil, stepIndex
	end


	-------------------------------------------------------
	-- #7f. Live Distance Refresh & Movement Reordering
	-------------------------------------------------------

	-- Match the precision used by the visible Quest Helper coordinate header. Raw
	-- C_Map coordinates can drift by tiny fractions while the player is standing
	-- still, which otherwise makes rounded yard labels oscillate by a few yards.
	local function GetTrackedDistancePositionCell()
		-- Previous Blizzard call changed 2026.09.25: local mapID = C_Map.GetBestMapForUnit("player")
		local mapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		-- Previous Blizzard call changed 2026.09.25: local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
		local position = mapID and RQE.API.Client.C_Map.GetPlayerMapPosition(mapID, "player")
		if not position then return nil end

		local x, y = position:GetXY()
		if not x or not y then return nil end
		return mapID, math.floor(x * 10000 + 0.5), math.floor(y * 10000 + 0.5)
	end


	local function GetUnresolvedTrackedDistanceQuestIDs()
		local questIDs = {}
		local found = false
		for _, questButton in pairs(RQE.QuestLogIndexButtons or {}) do
			local distanceText = questButton and questButton.QuestDistanceInfo
			local text = distanceText and distanceText:GetText()
			if questButton and questButton:IsShown() and type(text) == "string" and text:find("N/A", 1, true) then
				local questID = tonumber(questButton.questID)
				if questID then questIDs[questID] = true end
				found = true
			end
		end
		return questIDs, found
	end


	-- Update the visible tracker distance labels without rebuilding the quest frame.
	-- The 0.2-second throttle keeps this inexpensive for long lists, while the
	-- coordinate cell prevents stationary C_Map jitter from changing the display.
	function RQE:RefreshTrackedQuestDistances(force)
		if not (RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown()) then return end

		-- Previous Blizzard call changed 2026.09.25: local now = GetTime()
		local now = RQE.API.Client.GetTime()
		if not force and RQE.lastTrackedQuestDistanceRefresh
			and now - RQE.lastTrackedQuestDistanceRefresh < 0.2
		then
			return
		end
		RQE.lastTrackedQuestDistanceRefresh = now

		local unresolvedQuestIDs, hasUnresolvedDistance = GetUnresolvedTrackedDistanceQuestIDs()
		local unresolvedOnly = false
		local mapID, gridX, gridY = GetTrackedDistancePositionCell()
		if mapID then
			local samePosition = RQE.lastTrackedQuestDistanceMapID == mapID
				and RQE.lastTrackedQuestDistanceGridX == gridX
				and RQE.lastTrackedQuestDistanceGridY == gridY
			if not force and samePosition and not hasUnresolvedDistance then
				return
			end
			unresolvedOnly = not force and samePosition
			RQE.lastTrackedQuestDistanceMapID = mapID
			RQE.lastTrackedQuestDistanceGridX = gridX
			RQE.lastTrackedQuestDistanceGridY = gridY
		end

		local liveQuestID, liveStepIndex = GetLiveTrackerQuestStep()
		if not RQE.PendingTrackerStateRestore and liveQuestID and liveStepIndex then
			RQE.trackerQuestStepCache[liveQuestID] = liveStepIndex
		end

		for _, questButton in pairs(RQE.QuestLogIndexButtons or {}) do
			if questButton and questButton:IsShown() and questButton.questID and questButton.QuestDistanceInfo then
				local questID = tonumber(questButton.questID)
				if not unresolvedOnly or unresolvedQuestIDs[questID] then
					local stepIndex = tonumber(questButton.rqeTrackerDistanceStepIndex)

					-- Reading the already-resolved live step is O(1), and it is accepted
					-- only for the quest that owns AddonSetStepIndex. Other rows retain
					-- their own cached values (for example, step 1 is never changed to
					-- quest 29509's step 9).
					if liveQuestID == questID and liveStepIndex then
						stepIndex = liveStepIndex
					elseif not stepIndex then
						local savedStepIndex = questID and RQE.trackerQuestStepCache[questID]
						stepIndex = tonumber(savedStepIndex)
					end

					local distance = RQE:GetTrackerQuestStepDistance(questID, stepIndex, true)
					questButton.rqeTrackerDistanceStepIndex = stepIndex
					questButton.QuestDistanceInfo:SetText(
						distance and string.format("Distance: %.0f yds", distance) or "Distance: N/A"
					)
				end
			end
		end
	end


	-------------------------------------------------------
	-- #7g. World Quest Proximity Collection
	-------------------------------------------------------

	-- Function to gather and sort World Quests by proximity
	function GatherAndSortWorldQuestsByProximity()
		local worldQuests = {}
		-- Previous Blizzard call changed 2026.09.25: local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
		local numTrackedWorldQuests = RQE.API.Client.C_QuestLog.GetNumWorldQuestWatches()

		-- Gather World Quests
		for i = 1, numTrackedWorldQuests do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if questID and RQE.API.IsWorldQuest(questID) then
				-- Previous Blizzard call changed 2026.09.25: local distanceSq = C_QuestLog.GetDistanceSqToQuest(questID)
				local distanceSq = RQE.API.Client.C_QuestLog.GetDistanceSqToQuest(questID)
				table.insert(worldQuests, { questID = questID, distanceSq = distanceSq or math.huge, type = "WQ" })
			end
		end

		-- Get the player's current map ID
		-- Previous Blizzard call changed 2026.09.25: local currentMapID = C_Map.GetBestMapForUnit("player")
		local currentMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player")
		if not currentMapID then
			-- If currentMapID is nil, print an error message and return the current worldQuests table
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Error: Could not determine player's current map ID.")
			end
			return worldQuests
		end

		-- Sort the combined list of quests by proximity
		table.sort(worldQuests, function(a, b) return a.distanceSq < b.distanceSq end)

		return worldQuests
	end


	-------------------------------------------------------
	-- #7h. Rapid Quest Watch Verification
	-------------------------------------------------------

	-- Helper function to watch quests that are rapidly chosen from a single NPC
	function RQE:VerifyWatchedQuests()
		if not RQE.DelayedQuestWatchCheck then return end

		-- Build a lookup of currently watched quests
		local watched = {}
		-- Previous Blizzard call changed 2026.09.25: for i = 1, C_QuestLog.GetNumQuestWatches() do
		for i = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local id = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local id = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if id then
				watched[id] = true
			end
		end

		-- Compare against accepted list and add missing
		for _, questID in ipairs(RQE.DelayedQuestWatchCheck) do
			if RQE.API.IsOnQuest(questID) and not watched[questID] then
				-- Previous Blizzard call changed 2026.09.25: C_QuestLog.AddQuestWatch(questID)
				RQE.API.Client.C_QuestLog.AddQuestWatch(questID)
				if RQE.db.profile.debugLevel == "INFO+" then
					DEFAULT_CHAT_FRAME:AddMessage("Repair Watch: Added questID " .. questID, 0.46, 0.96, 0.46)
				end
			end
		end
	end


	-------------------------------------------------------
	-- #7i. Quest Tracker Context Menus
	-------------------------------------------------------

	-- Function to Show Right-Click Dropdown Menu
	function ShowQuestDropdown(self, questID)
		MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
			-- Previous Blizzard call changed 2026.09.25: local isPlayerInGroup = IsInGroup()
			local isPlayerInGroup = RQE.API.Client.IsInGroup()
			-- Previous Blizzard call changed 2026.09.25: local isQuestShareable = C_QuestLog.IsPushableQuest(questID)
			local isQuestShareable = RQE.API.Client.C_QuestLog.IsPushableQuest(questID)

			if isPlayerInGroup and isQuestShareable then
				-- Previous Blizzard call changed 2026.09.25: rootDescription:CreateButton("Share Quest", function() C_QuestLog.SetSelectedQuest(questID); QuestLogPushQuest(); end)
				rootDescription:CreateButton("Share Quest", function() RQE.API.Client.C_QuestLog.SetSelectedQuest(questID); RQE.API.Client.QuestLogPushQuest(); end)
			end

			-- Previous Blizzard call changed 2026.09.25: if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
			if RQE.API.Client.C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				if RQE_SandboxEditor then
					rootDescription:CreateButton("Open Sandbox", function() RQE_SandboxEditor:Show() end)
				end
				rootDescription:CreateButton("Print Supertracked Quest (Sandbox/DB)", function() RQE.PrintSupertrackedQuest() end)
				rootDescription:CreateButton("Check Coordinate Status for Quest", function() RQE:CheckCoordHotspotsInSteps(questID) end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			end

			rootDescription:CreateButton("Set Waypoint to Closest Flight Master", function() RQE:SetTomTomWaypointToClosestFlightMaster() end)
			-- Previous Blizzard call changed 2026.09.25: rootDescription:CreateButton("Untrack Quest", function() C_QuestLog.RemoveQuestWatch(questID); RQE:ClearRQEQuestFrame(); UpdateRQEQuestFrame() end)
			rootDescription:CreateButton("Untrack Quest", function() RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID); RQE:ClearRQEQuestFrame(); UpdateRQEQuestFrame() end)
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

			-- Only show RQE buttons if the RQE_Contribution addon is loaded
			-- Previous Blizzard call changed 2026.09.25: if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
			if RQE.API.Client.C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Track Quests in DB without Steps", function() RQE.TrackDBQuestsWithoutSteps() end)
				rootDescription:CreateButton("Track Quests in DB with Steps", function() RQE.TrackDBQuestsWithSteps() end)
				rootDescription:CreateButton("Track Quests Not in DB", function() RQE.TrackQuestsNotInDB() end)
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			else
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
			end

			rootDescription:CreateButton("Show Wowhead Link", function() RQE:ShowWowheadLink(questID) end)
			rootDescription:CreateButton("Search Warcraft Wiki", function() RQE:ShowWowWikiLink(questID) end)
			rootDescription:CreateButton("|cff888888----------------------------------|r", function() end)
			rootDescription:CreateButton(isQuestFrameLocked and "Unlock Quest Tracker Position & Size" or "Lock Quest Tracker Position & Size", function()
				RQE.ToggleRQEQuestFrameLock()
			end)
			rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)

			if RQE.db.profile.debugLevel ~= "NONE" then
				rootDescription:CreateButton("|cff888888-----------------------------------------------|r", function() end)
				rootDescription:CreateButton("Reset frames to Default size & position", function() RQE:ResetFrameAndSizeToDefault() end)
			end
		end)
	end


	-- Function to Show Right-Click Dropdown Menu
	function ShowDropdownRQEQuestFrame(self)
		MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
			-- Only show RQE buttons if the RQE_Contribution addon is loaded
			-- Previous Blizzard call changed 2026.09.25: if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
			if RQE.API.Client.C_AddOns.IsAddOnLoaded("RQE_Contribution") then
				rootDescription:CreateButton("Track Quests in DB without Steps", function() RQE.TrackDBQuestsWithoutSteps() end)
				rootDescription:CreateButton("Track Quests in DB with Steps", function() RQE.TrackDBQuestsWithSteps() end)
				rootDescription:CreateButton("Track Quests Not in DB", function() RQE.TrackQuestsNotInDB() end)
				rootDescription:CreateButton("|cff888888----------------------------------|r", function() end)
			end
			rootDescription:CreateButton(isQuestFrameLocked and "Unlock Quest Tracker Position & Size" or "Lock Quest Tracker Position & Size", function()
				RQE.ToggleRQEQuestFrameLock()
			end)
			rootDescription:CreateButton("Hide Frames ~10 seconds", function() RQE:TempBlizzObjectiveTracker() end)
		end)
	end


--------------------------------------------------
-- #8. 🎭 Scenario Frame Lifecycle
--------------------------------------------------

	-------------------------------------------------------
	-- #8a. Scenario Frame Initialization
	-------------------------------------------------------

	-- [Functions related to the scenario frame, such as RQE.InitializeScenarioFrame, RQE.UpdateScenarioFrame]

	-- Function to initiate the Scenario Frame
	---@class RQE.ScenarioChildFrame : Frame
	---@field scenarioTitle FontString
	---@field stage FontString
	---@field title FontString
	---@field timerFrame Frame
	---@field timer FontString
	---@field body FontString
	function RQE.InitializeScenarioFrame()
		-- Create the ScenarioChildFrame if not already done
		-- Only create the ScenarioChildFrame if it does not already exist
		if not RQE.ScenarioChildFrame then
			---@type RQE.ScenarioChildFrame
			-- Create the ScenarioChildFrame if it does not already exist
			RQE.ScenarioChildFrame = CreateFrame("Frame", "RQEScenarioChildFrame", UIParent)
			RQE.ScenarioChildFrame:SetSize(400, 200) -- Set the size as needed
			RQE.ScenarioChildFrame:SetPoint("CENTER") -- Position it at the center, or change as needed
		end

		if not RQE.ScenarioChildFrame.scenarioTitle then
			-- Create the scenarioTitle as a FontString within the ScenarioChildFrame
			RQE.ScenarioChildFrame.scenarioTitle = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			RQE.ScenarioChildFrame.scenarioTitle:ClearAllPoints()
			RQE.ScenarioChildFrame.scenarioTitle:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.header, "TOPLEFT", 10, -10)
			RQE.ScenarioChildFrame.scenarioTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
			-- Ensure the text fits nicely and is readable
			RQE.ScenarioChildFrame.scenarioTitle:SetJustifyH("LEFT")
			RQE.ScenarioChildFrame.scenarioTitle:SetJustifyV("TOP")
			RQE.ScenarioChildFrame.scenarioTitle:SetWordWrap(true)  -- Ensure word wrap
			RQE.ScenarioChildFrame.scenarioTitle:SetHeight(0)

		end

		if not RQE.ScenarioChildFrame.stage then
			-- Create the stage as a FontString within the ScenarioChildFrame
			RQE.ScenarioChildFrame.stage = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			RQE.ScenarioChildFrame.stage:ClearAllPoints()
			RQE.ScenarioChildFrame.stage:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.scenarioTitle, "TOPLEFT", 0, -40)
			RQE.ScenarioChildFrame.stage:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
			-- Ensure the text fits nicely and is readable
			RQE.ScenarioChildFrame.stage:SetJustifyH("LEFT")
			RQE.ScenarioChildFrame.stage:SetJustifyV("TOP")
			RQE.ScenarioChildFrame.stage:SetWordWrap(true)  -- Ensure word wrap
			RQE.ScenarioChildFrame.stage:SetHeight(0)
		end

		-- Ensure that scenarioTitle is a valid FontString object before creating title
		if not RQE.ScenarioChildFrame.title then
			-- Create the title as a FontString below the scenarioTitle
			RQE.ScenarioChildFrame.title = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			RQE.ScenarioChildFrame.title:ClearAllPoints()
			RQE.ScenarioChildFrame.title:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.stage, "TOPLEFT", 0, -25)
			RQE.ScenarioChildFrame.title:SetFont("Fonts\\SKURRI.TTF", 17, "OUTLINE")
			RQE.ScenarioChildFrame.title:SetJustifyH("LEFT")
			RQE.ScenarioChildFrame.title:SetJustifyV("TOP")
			RQE.ScenarioChildFrame.title:SetWordWrap(true)  -- Ensure word wrap
			RQE.ScenarioChildFrame.title:SetHeight(0)
		end

		-- Create a new frame for the timer
		---@type TimerFrame
		RQE.ScenarioChildFrame.timerFrame = CreateFrame("Frame", nil, RQE.ScenarioChildFrame, "BackdropTemplate")
		RQE.ScenarioChildFrame.timerFrame:SetSize(100, 50)
		RQE.ScenarioChildFrame.timerFrame:SetPoint("BOTTOMRIGHT", RQE.ScenarioChildFrame.header, "BOTTOMRIGHT", -10, 10)
		RQE.ScenarioChildFrame.timerFrame:SetFrameStrata("MEDIUM")
		RQE.ScenarioChildFrame.timerFrame:SetFrameLevel(RQE.ScenarioChildFrame:GetFrameLevel() + 2)
		RQE.ScenarioChildFrame.timerFrame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 8, edgeSize = 0.1,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		RQE.ScenarioChildFrame.timerFrame:SetBackdropColor(0, 0, 0, 0)

		-- Ensure the timer frame is on top of other elements
		RQE.ScenarioChildFrame.timerFrame:SetFrameLevel(RQE.ScenarioChildFrame:GetFrameLevel() + 1)

		-- Create the FontString for the timer within the timer frame
		RQE.ScenarioChildFrame.timer = RQE.ScenarioChildFrame.timer or RQE.ScenarioChildFrame.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		RQE.ScenarioChildFrame.timer:SetAllPoints()
		RQE.ScenarioChildFrame.timer:SetJustifyH("CENTER")
		RQE.ScenarioChildFrame.timer:SetJustifyV("MIDDLE")
		RQE.ScenarioChildFrame.timer:SetText("Initial Timer")
		RQE.ScenarioChildFrame.timer:SetHeight(0)
		RQE.ScenarioChildFrame.timer:SetWordWrap(true)
		RQE.ScenarioChildFrame.timer:SetTextColor(1, 1, 0, 1)

		-- Show the timer frame and its text
		RQE.ScenarioChildFrame.timerFrame:Show()
		RQE.ScenarioChildFrame.timer:Show()

		if not RQE.ScenarioChildFrame.body then
			-- Create the body as a FontString below the header
			RQE.ScenarioChildFrame.body = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			RQE.ScenarioChildFrame.body:ClearAllPoints()
			RQE.ScenarioChildFrame.body:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.header, "BOTTOMLEFT", 10, -15)  -- Assuming the header is around 60px in height plus a 30px gap
			RQE.ScenarioChildFrame.body:SetFont("Fonts\\FRIZQT__.TTF", 14, "MONOCHROME")
			RQE.ScenarioChildFrame.body:SetText("Initial Body Text")
			RQE.ScenarioChildFrame.body:SetJustifyH("LEFT")
			RQE.ScenarioChildFrame.body:SetJustifyV("TOP")
			RQE.ScenarioChildFrame.body:SetWordWrap(true)  -- Ensure word wrap
			RQE.ScenarioChildFrame.body:SetHeight(0)
			-- Set the color of the body FontString to white (r, g, b, alpha)
			RQE.ScenarioChildFrame.body:SetTextColor(1, 1, 1, 0.9) -- White color
		end

		-- Update scenarioTitle and stage based on Torghast information
		-- Previous Blizzard call changed 2026.09.25: if IsInJailersTower() and RQE.TorghastType and RQE.TorghastLayerNum and RQE.TorghastFloorID then
		if RQE.API.Client.IsInJailersTower() and RQE.TorghastType and RQE.TorghastLayerNum and RQE.TorghastFloorID then
			local torghastTypeString = RQE.ConvertTorghastTypeToString(RQE.TorghastType)
			RQE.ScenarioChildFrame.scenarioTitle:SetText("Torghast, Tower of the Damned\n" .. torghastTypeString)
			RQE.ScenarioChildFrame.stage:SetText("Layer " .. RQE.TorghastLayerNum .. " - Floor " .. RQE.TorghastFloorID)
		end
	end


	-------------------------------------------------------
	-- #8b. Scenario Start-Time Diagnostics
	-------------------------------------------------------

	-- /run RQE.PrintScenarioTimer()
	-- Check and set the scenario start time
	function RQE.CheckScenarioStartTime()
		-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario() then
		if not RQE.API.Client.C_Scenario.IsInScenario() then
			return
		end

		-- If we already have a start time, skip
		if RQE.db.char.scenarioStartTime then
			return
		end

		-- Record the current time (in seconds since epoch)
		RQE.db.char.scenarioStartTime = time()

		-- print("Scenario started at:", date("%Y-%m-%d %H:%M:%S", RQE.db.char.scenarioStartTime))
	end


	-- Print elapsed time since the scenario started
	function RQE.PrintScenarioElapsedTime()
		-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario() then
		if not RQE.API.Client.C_Scenario.IsInScenario() then
			return
		end

		if not RQE.db.char.scenarioStartTime then
			return
		end

		-- Calculate the elapsed time
		local elapsedTime = time() - RQE.db.char.scenarioStartTime
		local hours = math.floor(elapsedTime / 3600)
		local minutes = math.floor(elapsedTime / 60) % 60
		local seconds = math.floor(elapsedTime % 60)

		-- Return formatted elapsed time (if needed elsewhere)
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end


	-------------------------------------------------------
	-- #8c. Scenario Content Rendering
	-------------------------------------------------------

	-- Function to update the scenario frame with the latest information
	function RQE.UpdateScenarioFrame()
		-- Fast exit if we are not in a scenario (most reliable first check)
		-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario or not C_Scenario.IsInScenario() then
		if not RQE.API.ResolveClientAPI("C_Scenario.IsInScenario") or not RQE.API.Client.C_Scenario.IsInScenario() then
			if RQE.ScenarioChildFrame then RQE.ScenarioChildFrame:Hide() end
			return
		end

		-- Get the full scenario information once at the beginning of the function
		-- Previous Blizzard call changed 2026.09.25: local scenarioName, currentStage, numStages, flags, _, _, completed, xp, money, scenarioType, _, textureKit = C_Scenario.GetInfo()
		local scenarioName, currentStage, numStages, flags, _, _, completed, xp, money, scenarioType, _, textureKit = RQE.API.Client.C_Scenario.GetInfo()
		-- Previous Blizzard call changed 2026.09.25: local scenarioStepInfo = C_ScenarioInfo.GetScenarioInfo()
		local scenarioStepInfo = RQE.API.Client.C_ScenarioInfo.GetScenarioInfo()
		-- Previous Blizzard call changed 2026.09.25: local numCriteria = select(3, C_Scenario.GetStepInfo())
		local numCriteria = select(3, RQE.API.Client.C_Scenario.GetStepInfo())

		-- Only set stepID if scenarioStepInfo exists
		local stepID = scenarioStepInfo and scenarioStepInfo.currentStage
		local criteriaIndex = 1
		-- Previous Blizzard call changed 2026.09.25: local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		local criteriaInfo = RQE.API.Client.C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)

		-- Check if we have valid scenario information
		if scenarioStepInfo and type(scenarioStepInfo) == "table" and RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.title then
			if scenarioStepInfo.title then
				RQE.ScenarioChildFrame.title:SetText(scenarioStepInfo.title)
			else
				RQE.ScenarioChildFrame.title:SetText("Title is not available")
			end
		end

		-- Check if we have valid scenario information
		if scenarioName and scenarioStepInfo then
			-- Update the scenarioTitle with the scenario name
			if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.scenarioTitle then
				RQE.ScenarioChildFrame.scenarioTitle:SetText(scenarioName)
			end

			-- Update the stage with the current stage and total stages
			if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.stage then
				RQE.ScenarioChildFrame.stage:SetText("Stage " .. currentStage .. " of " .. numStages)
			end

			-- Update the title with the scenario step title
			if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.title then
				RQE.ScenarioChildFrame.title:SetText(scenarioStepInfo.title or "Title is not available")
			end

			-- Update the main frame with criteria
			local criteriaText = ""
			-- Iterate through each criteria and collect information
			for criteriaIndex = 1, numCriteria do
				-- Previous Blizzard call changed 2026.09.25: local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
				local criteriaInfo = RQE.API.Client.C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)

				if criteriaInfo then
					local description = criteriaInfo.description or "No description available"
					local quantity = criteriaInfo.quantity or 0
					local totalQuantity = criteriaInfo.totalQuantity or 0
					local completed = criteriaInfo.completed or false

					-- Format the criteria text
					if completed then
						criteriaText = criteriaText .. "|cff00ff00" .. quantity .. " / " .. totalQuantity .. " " .. description .. "|r\n" -- Green color for completed
					else
						criteriaText = criteriaText .. quantity .. " / " .. totalQuantity .. " " .. description .. "\n" -- Default color for not completed
					end
				end
			end

			if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.body then
				RQE.ScenarioChildFrame.body:SetText(criteriaText)
			end

			-- Update the timer, if applicable
			local duration = criteriaInfo and criteriaInfo.duration
			local elapsed = criteriaInfo and criteriaInfo.elapsed

			if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame.timer then
				if duration and elapsed then
					local timeLeft = duration - elapsed
					RQE.ScenarioChildFrame.timer:SetText(SecondsToTime(timeLeft))
				else
					RQE.ScenarioChildFrame.timer:SetText("")
				end
			end

			-- Display the frame if it's not already shown
			RQE.ScenarioChildFrame:Show()
		else
			RQE.debugLog("No active scenario or scenario information is not available.")
			-- Hide the scenario frame since we're not in a scenario
			RQE.ScenarioChildFrame:Hide()
		end

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.35, function()
		RQE.API.Client.C_Timer.After(0.35, function()
			UpdateRQEQuestFrame()
		end)
	end


--------------------------------------------------
-- #9. ⭐ Bonus Quest Rendering
--------------------------------------------------

	-------------------------------------------------------
	-- #9a. Bonus Quest Clearing & Display Dispatch
	-------------------------------------------------------

	-- Clears the Bonus Quest Elements in order to refresh them when changes occur to tracking or objectives completed
	function RQE.ClearBonusQuestElements()
		-- Ensure RQE.bonusQuestElements exists and iterate through it to clear all elements
		if not RQE.bonusQuestElements then
			RQE.bonusQuestElements = {}
			return
		end

		for _, element in ipairs(RQE.bonusQuestElements) do
			if element then
				element:Hide() -- Hide the element
				element:ClearAllPoints() -- Clear its anchor points
				element:SetParent(nil) -- Remove it from the parent frame
			end
		end

		-- Reset the bonus quest elements table
		RQE.bonusQuestElements = {}
	end


	-- Helper for Bonus Quests Frame
	function RQE:DisplayBonusQuestInRQEFrame(questID, questTitle)
		local questInfo = RQE.getQuestData(questID)
		if not questInfo then return end

		RQE.AddonSetStepIndex = RQE.AddonSetStepIndex or 1
		RQE.DisplayedQuestID = questID
		RQE.ManualSuperTrack = "BQ"
		RQE.ManualSuperTrackedQuestID = questID
		RQE.searchedQuestID = nil

		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)

		if RQE.CreateStepsText then
			RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
		end

		if RQE.UnknownQuestButton then
			RQE.UnknownQuestButton:Show()
		end

		if RQE.UnknownQuestButtonCalcNTrack then
			RQE.UnknownQuestButtonCalcNTrack()
		end

		if RQE.QuestIDText then
			RQE.QuestIDText:SetText("Quest ID: " .. questID)
		end

		if RQE.QuestNameText then
			RQE.QuestNameText:SetText("Quest Name: " .. (questInfo.title or questTitle or "Unknown Quest"))
		end

		if RQE.QuestDescription then
			RQE.QuestDescription:SetText((questInfo.descriptionQuestText and questInfo.descriptionQuestText[1]) or "")
		end

		if RQE.QuestObjectives then
			RQE.QuestObjectives:SetText(RQE.colorizeObjectives(questID) or "")
		end

		if RQE.UpdateSeparateFocusFrame then
			RQE:UpdateSeparateFocusFrame()
		end

		if RQE.StartPeriodicChecks then
			RQE:StartPeriodicChecks()
		end
	end


	-------------------------------------------------------
	-- #9b. Bonus Quest Row Construction
	-------------------------------------------------------

	-- Function that adds the Bonus Quests to the RQE.QuestsFrame below the last tracked normal quest
	function RQE.AddBonusQuestToFrame(parentFrame, lastElement, questID, questTitle)
		-- Validate the questID
		if not questID or type(questID) ~= "number" or questID <= 0 then
			print("Error: Invalid questID for AddBonusQuestToFrame:", questID)
			return lastElement
		end

		-- Create the BQ supertrack button
		local bonusQuestButton = CreateFrame("Button", nil, parentFrame)
		bonusQuestButton:SetSize(TRACKER_QUEST_BUTTON_SIZE, TRACKER_QUEST_BUTTON_SIZE)

		local buttonText = bonusQuestButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		buttonText:SetPoint("CENTER", bonusQuestButton, "CENTER", 0, 0)
		buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		buttonText:SetTextColor(1, 0.82, 0)
		buttonText:SetText("BQ")

		local buttonTexture = bonusQuestButton:CreateTexture(nil, "BACKGROUND")
		buttonTexture:SetAllPoints(bonusQuestButton)
		if RQE.API.GetSuperTrackedQuestID() == questID then
			buttonTexture:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
		else
			buttonTexture:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
		end
		bonusQuestButton.bg = buttonTexture
		bonusQuestButton.number = buttonText
		if RQE.UI then
			RQE.UI:StyleQuestIndexButton(bonusQuestButton,
				RQE.API.GetSuperTrackedQuestID() == questID, "Bonus")
		end

		-- Create a FontString for the quest title
		local bonusQuestLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		bonusQuestLabel:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		bonusQuestLabel:SetTextColor(137/255, 95/255, 221/255)
		bonusQuestLabel:SetText(questTitle)
		RQE.bonusQuestLabel = bonusQuestLabel

		-- Position the label first, then attach the BQ button to it
		if lastElement then
			bonusQuestLabel:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -20)
		else
			bonusQuestLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", GetTrackerQuestLabelInset(), -40)
		end

		AnchorTrackerQuestButton(bonusQuestButton, bonusQuestLabel)

		-- Button click: supertrack this bonus quest
		bonusQuestButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
		bonusQuestButton:SetScript("OnMouseDown", function(self, button)
			-- Previous Blizzard call changed 2026.09.25: if button == "LeftButton" and not IsShiftKeyDown() then
			if button == "LeftButton" and not RQE.API.Client.IsShiftKeyDown() then
				RQE.ManualSuperTrack = "BQ"
				RQE.ManualSuperTrackedQuestID = questID
				RQE.searchedQuestID = nil

				if RQEMacro and RQEMacro.ClearMacroContentByName then
					RQEMacro:ClearMacroContentByName("RQE Macro")
				end

				RQE.ManuallyTrackedQuests = RQE.ManuallyTrackedQuests or {}
				RQE.ManuallyTrackedQuests[questID] = true
				RQE.DisplayedQuestID = questID

				-- Previous Blizzard call changed 2026.09.25: C_SuperTrack.SetSuperTrackedQuestID(questID)
				RQE.API.Client.C_SuperTrack.SetSuperTrackedQuestID(questID)

				if UpdateRQEQuestFrame then
					UpdateRQEQuestFrame()
				end

				if RQE.SaveSuperTrackedQuestToCharacter then
					RQE:SaveSuperTrackedQuestToCharacter()
				end

				-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.15, function()
				RQE.API.Client.C_Timer.After(0.15, function()
					RQE:DisplayBonusQuestInRQEFrame(questID, questTitle)
				end)

				-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.50, function()
				RQE.API.Client.C_Timer.After(0.50, function()
					if RQE.API.GetSuperTrackedQuestID() == questID then
						RQE:DisplayBonusQuestInRQEFrame(questID, questTitle)
					end
				end)

				-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1.00, function()
				RQE.API.Client.C_Timer.After(1.00, function()
					if RQE.API.GetSuperTrackedQuestID() == questID then
						RQE:DisplayBonusQuestInRQEFrame(questID, questTitle)
					end

					if UpdateRQEQuestFrame then
						UpdateRQEQuestFrame()
					end
				end)

				return
			end

			if button == "RightButton" and ShowQuestDropdown then
				ShowQuestDropdown(self, questID)
			end
		end)

		table.insert(RQE.bonusQuestElements, bonusQuestButton)
		table.insert(RQE.bonusQuestElements, bonusQuestLabel)

		-- Fetch and set the objectives text from the quest log
		local objectivesTable = RQE.API.GetQuestObjectives(questID)
		local objectivesText = objectivesTable and "" or "No objectives available."

		if objectivesTable then
			for _, objective in pairs(objectivesTable) do
				objectivesText = objectivesText .. (objective.text or "Unknown Objective") .. "\n"
			end
		end

		objectivesText = RQE.colorizeObjectives(questID)

		-- Create a FontString for the objectives
		local bonusQuestObjectives = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		bonusQuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
		bonusQuestObjectives:SetTextColor(1, 1, 1)
		bonusQuestObjectives:SetWordWrap(true)
		bonusQuestObjectives:SetJustifyH("LEFT")
		bonusQuestObjectives:SetJustifyV("TOP")
		bonusQuestObjectives:SetWidth(parentFrame:GetWidth() - 110)
		bonusQuestObjectives:SetHeight(0)
		bonusQuestObjectives:SetText(objectivesText)

		bonusQuestObjectives:SetPoint("TOPLEFT", bonusQuestLabel, "BOTTOMLEFT", 0, -5)
		local bonusObjectiveLastElement = RQE.ApplyTrackerObjectiveDisplay(
			bonusQuestButton, questID, bonusQuestObjectives, parentFrame, objectivesText)

		table.insert(RQE.bonusQuestElements, bonusQuestObjectives)
		if bonusObjectiveLastElement ~= bonusQuestObjectives then
			table.insert(RQE.bonusQuestElements, bonusObjectiveLastElement)
		end

		-- Tooltip
		bonusQuestLabel:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT", -50, -40)
			GameTooltip:SetMinimumWidth(350)
			GameTooltip:SetHeight(0)
			GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
			GameTooltip:SetText(questTitle)

			GameTooltip:AddLine(" ")

			if objectivesText and objectivesText ~= "" then
				GameTooltip:AddLine("Objectives:")
				GameTooltip:AddLine(objectivesText, 1, 1, 1, true)
				GameTooltip:AddLine(" ")
			end

			RQE:QuestRewardsTooltip(GameTooltip, questID)

			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82)
			GameTooltip:Show()
		end)

		bonusQuestLabel:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		return bonusObjectiveLastElement
	end


--------------------------------------------------
-- #10. ⏱️ Scenario Timer Lifecycle
--------------------------------------------------

	-------------------------------------------------------
	-- #10a. Timer Text & Elapsed-Time Updates
	-------------------------------------------------------

	-- Create a FontString for the timer text inside RQE.ScenarioChildFrame
	local timerFrame = CreateFrame("Frame", nil, RQE.ScenarioChildFrame)
	timerFrame:SetSize(100, 10) -- Adjust size as needed
	timerFrame:SetPoint("TOP", RQE.ScenarioChildFrame.header, "TOP", 75, -45)

	local timerText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	timerText:SetAllPoints(timerFrame)
	timerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")  -- Increase font size to 16, adjust as needed
	timerText:SetTextColor(1, 1, 1, 1) -- Set timerText color to white

	-- Function to update the timer display based on elapsed time from the DB
	local function UpdateScenarioTimer(self, elapsed)
		if not RQE.db or not RQE.db.char.scenarioStartTime then
			timerText:SetText("00:00:00")  -- Reset if no time is found
			return
		end

		-- Calculate the elapsed time from the stored start time
		local elapsedTime = time() - RQE.db.char.scenarioStartTime
		local hours = math.floor(elapsedTime / 3600)
		local minutes = math.floor(elapsedTime / 60) % 60
		local seconds = math.floor(elapsedTime % 60)

		-- Update the timer text display
		timerText:SetText(string.format("%02d:%02d:%02d", hours, minutes, seconds))
	end


	-------------------------------------------------------
	-- #10b. Timer Start & Stop Controls
	-------------------------------------------------------

	-- Function to start showing the elapsed time in the RQEQuestFrame
	function RQE.StartScenarioTimer()
		-- Only proceed if the player is in a scenario
		-- Previous Blizzard call changed 2026.09.25: if not C_Scenario.IsInScenario() then
		if not RQE.API.Client.C_Scenario.IsInScenario() then
			return
		end

		-- Ensure the timer keeps updating based on the saved start time
		timerFrame:SetScript("OnUpdate", UpdateScenarioTimer)
		timerFrame:Show() -- Show the frame displaying the timer
	end

	-- Function to stop the timer and clear the saved time from the DB
	function RQE.StopScenarioTimer()
		RQE.db.char.scenarioStartTime = nil  -- Clear the start time from the DB
		timerFrame:SetScript("OnUpdate", nil)  -- Stop updating the timer
		timerText:SetText("00:00:00")  -- Reset the displayed text
		timerFrame:Hide()
	end


--------------------------------------------------
-- #11. 🔄 Quest Tracker Rendering, Search & Interaction
--------------------------------------------------

	-------------------------------------------------------
	-- #11a. Quest Frame Clearing & Status Indicators
	-------------------------------------------------------

	-- [Functions for updating the quest frames, such as UpdateRQEQuestFrame, UpdateRQEWorldQuestFrame, RQE:ClearRQEQuestFrame, etc.]

	-- Function used to clear the Questing Frame
	function RQE:ClearRQEQuestFrame()
		-- Clearing regular quest buttons
		for i, QuestLogIndexButton in pairs(RQE.QuestLogIndexButtons or {}) do
			if QuestLogIndexButton then
				QuestLogIndexButton:Hide()
				if QuestLogIndexButton.QuestLevelAndName then
					QuestLogIndexButton.QuestLevelAndName:Hide()
				end
				if QuestLogIndexButton.QuestObjectivesOrDescription then
					QuestLogIndexButton.QuestObjectivesOrDescription:Hide()
				end
				if QuestLogIndexButton.QuestStatusInfo then
					QuestLogIndexButton.QuestStatusInfo:Hide()
				end
				if QuestLogIndexButton.RQEProgressBar then
					QuestLogIndexButton.RQEProgressBar:Hide()
				end
			end
		end
	end


	-- Returns the player-facing line inserted between a tracked quest's name and
	-- distance. Failure takes precedence over a timer, including at zero seconds.
	local function GetTrackedQuestStatusText(questID)
		if RQE.API.IsQuestFailed and RQE.API.IsQuestFailed(questID) then
			return FAILED or "Failed", true
		end

		local secondsLeft = RQE.API.GetQuestTimeRemainingSeconds
			and RQE.API.GetQuestTimeRemainingSeconds(questID)
		if secondsLeft ~= nil then
			local displaySeconds = math.max(0, math.ceil(secondsLeft))
			local timeText = SecondsToTime and SecondsToTime(displaySeconds)
				or tostring(displaySeconds)
			return (TIME_REMAINING or "Time Remaining:") .. " " .. timeText, false, displaySeconds <= 59
		end

		return nil, false, false
	end


	local function UpdateTrackedQuestStatusLine(questButton, questID, questNameLine, followingLine)
		local statusLine = questButton and questButton.QuestStatusInfo
		if not statusLine or not questNameLine or not followingLine then return end

		local statusText, isFailed, isUrgent = GetTrackedQuestStatusText(questID)
		statusLine:SetText(statusText or "")
		if isFailed then
			statusLine:SetTextColor(1, 51/255, 51/255)
		elseif isUrgent then
			statusLine:SetTextColor(1, 102/255, 51/255)
		else
			statusLine:SetTextColor(1, 209/255, 0)
		end
		statusLine:SetShown(statusText ~= nil)

		followingLine:ClearAllPoints()
		followingLine:SetPoint("TOPLEFT", statusText and statusLine or questNameLine, "BOTTOMLEFT", 0, -3)
		return statusText ~= nil, isFailed
	end


	local function StartTrackedQuestStatusUpdates(questButton, questID, questNameLine, followingLine)
		local hasStatus, isFailed = UpdateTrackedQuestStatusLine(questButton, questID, questNameLine, followingLine)
		if not hasStatus or isFailed then
			questButton:SetScript("OnUpdate", nil)
			return
		end
		questButton.rqeQuestStatusElapsed = 0
		questButton:SetScript("OnUpdate", function(self, elapsed)
			self.rqeQuestStatusElapsed = (self.rqeQuestStatusElapsed or 0) + elapsed
			if self.rqeQuestStatusElapsed < 0.25 then return end
			self.rqeQuestStatusElapsed = 0
			local stillHasStatus, nowFailed = UpdateTrackedQuestStatusLine(self, questID, questNameLine, followingLine)
			if not stillHasStatus or nowFailed then
				self:SetScript("OnUpdate", nil)
			end
		end)
	end


	-------------------------------------------------------
	-- #11b. Retail Search Matching & Watch Capture
	-------------------------------------------------------

	-- Quest Tracker search -------------------------------------------------------
	-- Search only regular player-log quests. World, bonus, task, and other
	-- externally managed tracker entries deliberately remain outside this filter.
	local function IsQuestTrackerSearchableLogQuest(questID, info)
		questID = tonumber(questID)
		if not questID or not info or info.isHeader then return false end
		if RQE.API.IsWorldQuest and RQE.API.IsWorldQuest(questID) then return false end
		if info.isTask then return false end
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog and C_QuestLog.IsQuestTask and C_QuestLog.IsQuestTask(questID) then return false end
		if C_QuestLog and RQE.API.ResolveClientAPI("C_QuestLog.IsQuestTask") and RQE.API.Client.C_QuestLog.IsQuestTask(questID) then return false end
		return true
	end

	local function AddQuestTrackerSearchText(searchText, value)
		if type(value) == "string" and value ~= "" then
			searchText[#searchText + 1] = value
		end
	end

	local function AddQuestTrackerSearchTextList(searchText, values)
		if type(values) ~= "table" then return end
		for _, value in ipairs(values) do
			AddQuestTrackerSearchText(searchText, value)
		end
	end

	local function FindQuestTrackerSearchMatches(searchTerm)
		local matches = {}
		local normalizedSearchTerm = string.lower(searchTerm)
		local numEntries = select(1, RQE.API.GetNumQuestLogEntries()) or 0

		for questLogIndex = 1, numEntries do
			local info = RQE.API.GetQuestLogInfo(questLogIndex)
			local questID = info and tonumber(info.questID)
			if IsQuestTrackerSearchableLogQuest(questID, info) then
				local searchableText = { tostring(questID) }
				AddQuestTrackerSearchText(searchableText, info.title)

				-- Previous Blizzard call changed 2026.09.25: if type(GetQuestLogQuestText) == "function" then
				if type(RQE.API.ResolveClientAPI("GetQuestLogQuestText")) == "function" then
					-- Previous Blizzard call changed 2026.09.25: local descriptionText, objectivesText = GetQuestLogQuestText(questLogIndex)
					local descriptionText, objectivesText = RQE.API.Client.GetQuestLogQuestText(questLogIndex)
					AddQuestTrackerSearchText(searchableText, descriptionText)
					AddQuestTrackerSearchText(searchableText, objectivesText)
				end

				for _, objective in ipairs(RQE.API.GetQuestObjectives(questID) or {}) do
					AddQuestTrackerSearchText(searchableText, objective and objective.text)
				end

				local dbQuestData = RQE.getQuestData and RQE.getQuestData(questID)
				if type(dbQuestData) == "table" then
					AddQuestTrackerSearchText(searchableText, dbQuestData.title)
					AddQuestTrackerSearchTextList(searchableText, dbQuestData.objectivesQuestText)
					AddQuestTrackerSearchTextList(searchableText, dbQuestData.descriptionQuestText)
					AddQuestTrackerSearchText(searchableText, dbQuestData.npc)
					AddQuestTrackerSearchTextList(searchableText, dbQuestData.npc)
					for stepIndex, stepData in pairs(dbQuestData) do
						if type(stepIndex) == "number" and type(stepData) == "table" then
							AddQuestTrackerSearchText(searchableText, stepData.description)
						end
					end
				end

				for _, value in ipairs(searchableText) do
					if string.find(string.lower(value), normalizedSearchTerm, 1, true) then
						table.insert(matches, questID)
						break
					end
				end
			end
		end

		return matches
	end

	-- Some Retail installs can load without RQE_API's GetLogIndexForQuestID
	-- wrapper even though Blizzard's native Retail API is available. Prefer the
	-- native API, then use the wrapper only when it exists.
	local function GetRetailQuestTrackerLogIndex(questID)
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
		if C_QuestLog and RQE.API.ResolveClientAPI("C_QuestLog.GetLogIndexForQuestID") then
			-- Previous Blizzard call changed 2026.09.25: return C_QuestLog.GetLogIndexForQuestID(questID)
			return RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)
		end
		if RQE.API.GetLogIndexForQuestID then
			return RQE.API.GetLogIndexForQuestID(questID)
		end

		-- Last-resort fallback for an incomplete API table: find the live-log row
		-- from the information which is already available to RQE's tracker.
		local numEntries = select(1, RQE.API.GetNumQuestLogEntries()) or 0
		for questLogIndex = 1, numEntries do
			local info = RQE.API.GetQuestLogInfo(questLogIndex)
			if info and tonumber(info.questID) == tonumber(questID) then
				return questLogIndex
			end
		end
	end

	local function CollectRetailQuestTrackerSearchWatches()
		local watchedQuestIDs = {}
		-- Previous Blizzard call changed 2026.09.25: local numWatches = C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches() or 0
		local numWatches = RQE.API.ResolveClientAPI("C_QuestLog.GetNumQuestWatches") and RQE.API.Client.C_QuestLog.GetNumQuestWatches() or 0
		for watchIndex = 1, numWatches do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex)
			local questLogIndex = questID and GetRetailQuestTrackerLogIndex(questID)
			local info = questLogIndex and RQE.API.GetQuestLogInfo(questLogIndex)
			if IsQuestTrackerSearchableLogQuest(questID, info) then
				table.insert(watchedQuestIDs, questID)
			end
		end
		return watchedQuestIDs
	end

	-- The search must use Retail's live watch API. Some installs do not populate
	-- the corresponding RQE_API wrappers, so native calls are deliberately first.
	local function RemoveRetailQuestTrackerSearchWatch(questID)
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog and C_QuestLog.RemoveQuestWatch then
		if C_QuestLog and RQE.API.ResolveClientAPI("C_QuestLog.RemoveQuestWatch") then
			-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(questID)
			RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID)
		elseif RQE.API.RemoveQuestWatch then
			RQE.API.RemoveQuestWatch(questID)
		end
	end

	local function AddRetailQuestTrackerSearchWatch(questID)
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog and C_QuestLog.AddQuestWatch then
		if C_QuestLog and RQE.API.ResolveClientAPI("C_QuestLog.AddQuestWatch") then
			-- Previous Blizzard call changed 2026.09.25: return C_QuestLog.AddQuestWatch(questID)
			return RQE.API.Client.C_QuestLog.AddQuestWatch(questID)
		elseif RQE.API.AddQuestWatch then
			return RQE.API.AddQuestWatch(questID)
		end
	end


	-------------------------------------------------------
	-- #11c. Search State, Filtering & Restoration
	-------------------------------------------------------

	function RQE:UpdateQuestTrackerSearchRestoreButton()
		if not self.QuestTrackerRestoreButton then return end
		if self.QuestTrackerSearchRestoreState then
			self.QuestTrackerRestoreButton:Enable()
		else
			self.QuestTrackerRestoreButton:Disable()
		end
	end

	function RQE:RefreshQuestTrackerAfterSearch()
		if UpdateRQEQuestFrame then
			UpdateRQEQuestFrame()
		end
		if self.UpdateRQEQuestFrameVisibility then
			self:UpdateRQEQuestFrameVisibility()
		end
		if self.SaveTrackedQuestsToCharacter then
			self:SaveTrackedQuestsToCharacter()
		end
	end

	function RQE:SearchQuestTracker(searchText)
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown and InCombatLockdown() then
		if RQE.API.ResolveClientAPI("InCombatLockdown") and RQE.API.Client.InCombatLockdown() then
			print("RQE Quest Tracker search is unavailable during combat.")
			return
		end

		searchText = tostring(searchText or ""):match("^%s*(.-)%s*$")
		if searchText == "" then
			print("No data returned for Search.")
			return
		end

		local matchingQuestIDs = FindQuestTrackerSearchMatches(searchText)
		if #matchingQuestIDs == 0 then
			print("No data returned for Search.")
			return
		end

		if not self.QuestTrackerSearchRestoreState then
			self.QuestTrackerSearchRestoreState = {
				watchedQuestIDs = CollectRetailQuestTrackerSearchWatches(),
			}
		end

		-- Collect first, then remove. Removing while traversing Blizzard's watch list
		-- would shift the remaining watch indexes and skip quests.
		for _, questID in ipairs(CollectRetailQuestTrackerSearchWatches()) do
			RemoveRetailQuestTrackerSearchWatch(questID)
		end

		self.QuestTrackerSearchResults = {}
		for _, questID in ipairs(matchingQuestIDs) do
			self.QuestTrackerSearchResults[questID] = true
			AddRetailQuestTrackerSearchWatch(questID)
		end

		self:UpdateQuestTrackerSearchRestoreButton()
		self:RefreshQuestTrackerAfterSearch()
	end

	function RQE:RestoreQuestTrackerSearch()
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown and InCombatLockdown() then
		if RQE.API.ResolveClientAPI("InCombatLockdown") and RQE.API.Client.InCombatLockdown() then
			print("RQE Quest Tracker restore is unavailable during combat.")
			return
		end

		local restoreState = self.QuestTrackerSearchRestoreState
		if not restoreState then
			print("No quest-tracker search is currently active.")
			return
		end

		for _, questID in ipairs(CollectRetailQuestTrackerSearchWatches()) do
			RemoveRetailQuestTrackerSearchWatch(questID)
		end

		for _, questID in ipairs(restoreState.watchedQuestIDs or {}) do
			if GetRetailQuestTrackerLogIndex(questID) then
				AddRetailQuestTrackerSearchWatch(questID)
			end
		end

		self.QuestTrackerSearchResults = nil
		self.QuestTrackerSearchRestoreState = nil
		self:UpdateQuestTrackerSearchRestoreButton()
		self:RefreshQuestTrackerAfterSearch()
	end


	-------------------------------------------------------
	-- #11d. World Quest & Achievement Frame Clearing
	-------------------------------------------------------

	-- Function used to clear the World Quest Frame
	function RQE:ClearRQEWorldQuestFrame()
		-- Ensure that RQE.WorldQuestsFrame exists and is a table
		if RQE.WorldQuestsFrame and type(RQE.WorldQuestsFrame) == "table" then
			-- Iterate over all elements in RQE.WorldQuestsFrame
			for i, WQuestLogIndexButton in pairs(RQE.WorldQuestsFrame) do
				-- Check if each element is a valid table
				if WQuestLogIndexButton and type(WQuestLogIndexButton) == "table" then
					-- Check if the element has a GetName method and a name that matches the pattern
					if WQuestLogIndexButton.GetName and WQuestLogIndexButton:GetName() and WQuestLogIndexButton:GetName():find("WQButton") then
						WQuestLogIndexButton:Hide()
						-- Hide sub-elements of the World Quest Button
						if WQuestLogIndexButton.WQuestLevelAndName then
							WQuestLogIndexButton.WQuestLevelAndName:Hide()
						end
						if WQuestLogIndexButton.QuestObjectivesOrDescription then
							WQuestLogIndexButton.QuestObjectivesOrDescription:Hide()
						end
					end
				end
			end
		end
	end


	-- Function to clear the Achievement Frame but preserve the header
	function RQE:ClearAchievementFrame()
		-- Check if the achievements frame exists
		if RQE.AchievementsFrame then
			local headerFrame = RQE.AchievementsFrame.headerFrame

			-- Iterate through all child frames and hide them
			local children = {RQE.AchievementsFrame:GetChildren()}
			for _, child in ipairs(children) do
				if child ~= headerFrame then
					child:Hide()
					child:SetParent(nil)
				end
			end

			-- Clear all font strings in the frame
			local regions = {RQE.AchievementsFrame:GetRegions()}
			for _, region in ipairs(regions) do
				if region:GetObjectType() == "FontString" then
					region:Hide()
				end
			end
		end
		-- Keep the original header and its collapse button across achievement
		-- redraws; recreating it would orphan the persistent section control.
		if RQE.AchievementsFrame and not RQE.AchievementsFrame.headerFrame then
			RQE.AchievementsFrame.header = CreateChildFrameHeader(RQE.AchievementsFrame, "Achievements")
		end
	end


	-------------------------------------------------------
	-- #11e. Objective Progress Colorization
	-------------------------------------------------------

	-- Function to Colorize the Quest Tracker Module based on objective progress using the API
	local function colorizeObjectives(questID)
		local objectivesData = RQE.API.GetQuestObjectives(questID)
		local colorizedText = ""
		local t = {}

		-- Check if the quest is ready for turn-in
		-- Previous Blizzard call changed 2026.09.25: local isReadyForTurnIn = C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID)
		local isReadyForTurnIn = RQE.API.Client.C_QuestLog.IsComplete(questID) or RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID)
		local isAuto = RQE and RQE.IsQuestAutoComplete and RQE:IsQuestAutoComplete(questID)

		if objectivesData then
			for _, objective in ipairs(objectivesData) do
				local desc = objective.text
				if isReadyForTurnIn then
					t[#t+1] = RQE.ColorGREEN .. desc .. RQE.ColorRESET .. "\n"
				else
					if objective.finished then
						t[#t+1] = RQE.ColorGREEN  .. desc .. RQE.ColorRESET .. "\n"
					elseif (objective.numFulfilled or 0) > 0 then
						t[#t+1] = RQE.ColorYELLOW .. desc .. RQE.ColorRESET .. "\n"
					else
						t[#t+1] = RQE.ColorWHITE  .. desc .. RQE.ColorRESET .. "\n"
					end
				end
			end
			if isAuto then
				t[#t+1] = RQE.ColorORANGE .. "Click to Complete Quest" .. RQE.ColorRESET .. "\n"
			end
		else
			t[#t+1] = "Objective data unavailable."
		end

		return table.concat(t)
	end


	-- Function to Colorize the Quest Tracker Module based on objective progress using the API (currently applies to tooltip within RQEFrame only)
	function RQE.colorizeObjectives(questID)
		local objectivesData = RQE.API.GetQuestObjectives(questID)
		local colorizedText = ""
		local t = {}

		-- Check if the quest is ready for turn-in
		-- Previous Blizzard call changed 2026.09.25: local isReadyForTurnIn = C_QuestLog.IsComplete(questID) or C_QuestLog.ReadyForTurnIn(questID)
		local isReadyForTurnIn = RQE.API.Client.C_QuestLog.IsComplete(questID) or RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID)
		local isAuto = RQE and RQE.IsQuestAutoComplete and RQE:IsQuestAutoComplete(questID)

		if objectivesData then
			for _, objective in ipairs(objectivesData) do
				local desc = objective.text
				if isReadyForTurnIn then
					t[#t+1] = RQE.ColorGREEN .. desc .. RQE.ColorRESET .. "\n"
				else
					if objective.finished then
						t[#t+1] = RQE.ColorGREEN  .. desc .. RQE.ColorRESET .. "\n"
					elseif (objective.numFulfilled or 0) > 0 then
						t[#t+1] = RQE.ColorYELLOW .. desc .. RQE.ColorRESET .. "\n"
					else
						t[#t+1] = RQE.ColorWHITE  .. desc .. RQE.ColorRESET .. "\n"
					end
				end
			end
			-- if isAuto then
				-- t[#t+1] = RQE.ColorORANGE .. "Click QuestID/QuestName to Complete Quest" .. RQE.ColorRESET .. "\n"
			-- end
		else
			t[#t+1] = "Objective data unavailable."
		end

		return table.concat(t)
	end


	-- Builds Retail tracker objective text and, when Blizzard explicitly reports a
	-- progressbar objective, separates its label from the numeric percentage.  A
	-- missing type or percentage deliberately falls back to the original one-line
	-- objective text so unusual quests never lose information.
	local function BuildTrackerObjectiveDisplay(questID)
		local objectivesData = RQE.API.GetQuestObjectives(questID)
		if type(objectivesData) ~= "table" or #objectivesData == 0 then
			return nil, nil
		end

		-- Previous Blizzard call changed 2026.09.25: local isReadyForTurnIn = C_QuestLog.IsComplete(questID)
		local isReadyForTurnIn = RQE.API.Client.C_QuestLog.IsComplete(questID)
			-- Previous Blizzard call changed 2026.09.25: or C_QuestLog.ReadyForTurnIn(questID)
			or RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID)
		local lines = {}
		local progressInfo

		for objectiveIndex, objective in ipairs(objectivesData) do
			local description = tostring(objective.text or "")
			local objectiveType = objective.type or objective.objectiveType
			if not objectiveType and RQE.API.GetQuestObjectiveInfo then
				local ok, info = pcall(RQE.API.GetQuestObjectiveInfo,
					questID, objectiveIndex, false)
				if ok and type(info) == "table" then
					objectiveType = info.objectiveType or info.type
				end
			end

			local percentage
			if not progressInfo and objectiveType == "progressbar"
				-- Previous Blizzard call changed 2026.09.25: and type(GetQuestProgressBarPercent) == "function" then
				and type(RQE.API.ResolveClientAPI("GetQuestProgressBarPercent")) == "function" then
				-- Previous Blizzard call changed 2026.09.25: local ok, value = pcall(GetQuestProgressBarPercent, questID)
				local ok, value = pcall(RQE.API.ResolveClientAPI("GetQuestProgressBarPercent"), questID)
				if ok then percentage = tonumber(value) end
			end

			if percentage then
				percentage = math.max(0, math.min(100, percentage))
				local label = description
				label = label:gsub("%s*%(%s*%d+%.?%d*%%%s*%)%s*$", "")
				label = label:gsub("%s*[:%-]?%s*%d+%.?%d*%%%s*$", "")
				if label == "" then label = PROGRESS or "Progress" end
				progressInfo = { label = label, percentage = percentage }
				description = label
			end

			local color
			if isReadyForTurnIn or objective.finished then
				color = RQE.ColorGREEN
			elseif (objective.numFulfilled or 0) > 0 then
				color = RQE.ColorYELLOW
			else
				color = RQE.ColorWHITE
			end
			lines[#lines + 1] = (color or "") .. description .. (RQE.ColorRESET or "")
		end

		return table.concat(lines, "\n"), progressInfo
	end


	-- Sizes a percentage bar from its objective column. Tracker bars compensate
	-- for child-frame horizontal offsets so all categories share one right edge;
	-- the Quest Helper uses a deliberately shorter responsive width.
	function RQE.LayoutObjectiveProgressBar(progressBar)
		if not progressBar or not progressBar.RQEObjectiveText then return end
		local objectiveText = progressBar.RQEObjectiveText
		local parentFrame = progressBar.RQEObjectiveParent
		local textWidth = math.max(1, objectiveText:GetWidth() or 1)
		local width

		if RQE.content and parentFrame == RQE.content then
			width = textWidth * 0.78
		else
			local sectionOffset = 0
			if parentFrame and RQE.QTcontent then
				local sectionLeft = parentFrame:GetLeft()
				local contentLeft = RQE.QTcontent:GetLeft()
				if sectionLeft and contentLeft then
					sectionOffset = math.max(0, sectionLeft - contentLeft)
				end
			end
			width = textWidth - 28 - sectionOffset
		end

		progressBar:ClearAllPoints()
		progressBar:SetPoint("TOPLEFT", objectiveText, "BOTTOMLEFT", 0, -5)
		progressBar:SetWidth(math.max(80, width))
	end


	function RQE.RefreshTrackerProgressBarLayouts()
		for _, section in ipairs({
			RQE.CampaignFrame, RQE.QuestsFrame, RQE.WorldQuestsFrame,
			RQE.BonusQuestsFrame, RQE.TaskQuestsFrame,
		}) do
			if section then
				for _, child in ipairs({ section:GetChildren() }) do
					if child.RQEObjectiveText then
						RQE.LayoutObjectiveProgressBar(child)
					end
				end
			end
		end
	end


	-- Applies the shared objective presentation to Campaign/Meta, Normal, World,
	-- Bonus, and Task rows.  The returned region is the true bottom-most element
	-- and is therefore safe to use for the following row and child-frame anchors.
	function RQE.ApplyTrackerObjectiveDisplay(owner, questID, objectiveText, parentFrame, fallbackText)
		if not owner or not objectiveText or not parentFrame then return objectiveText end

		local displayText, progressInfo = BuildTrackerObjectiveDisplay(questID)
		if displayText == nil or displayText == "" then
			displayText = fallbackText or RQE.colorizeObjectives(questID) or ""
		end
		if type(objectiveText.RQERawSetText) == "function" then
			objectiveText.RQERawSetText(objectiveText, displayText)
		else
			objectiveText:SetText(displayText)
		end

		local progressBar = owner.RQEProgressBar
		if not progressInfo then
			if progressBar then progressBar:Hide() end
			return objectiveText
		end

		if not progressBar then
			-- Keep the border on an outer frame and inset the StatusBar fill. A
			-- StatusBar's own fill can otherwise cover its backdrop edge at 100%.
			progressBar = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
			progressBar:SetHeight(16)
			progressBar:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Buttons\\WHITE8X8",
				edgeSize = 1,
				insets = { left = 1, right = 1, top = 1, bottom = 1 },
			})
			progressBar.RQEFill = CreateFrame("StatusBar", nil, progressBar)
			progressBar.RQEFill:SetPoint("TOPLEFT", progressBar, "TOPLEFT", 3, -3)
			progressBar.RQEFill:SetPoint("BOTTOMRIGHT", progressBar, "BOTTOMRIGHT", -3, 3)
			progressBar.RQEFill:SetMinMaxValues(0, 100)
			progressBar.RQEFill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
			progressBar.RQEFillBackground = progressBar.RQEFill:CreateTexture(nil, "BACKGROUND")
			progressBar.RQEFillBackground:SetAllPoints()
			progressBar.RQEFillBackground:SetColorTexture(5 / 255, 10 / 255, 22 / 255, 1)
			progressBar.RQEPercentText = progressBar.RQEFill:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			progressBar.RQEPercentText:SetPoint("CENTER")
			progressBar.RQEPercentText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			progressBar.RQEPercentText:SetTextColor(1, 1, 1)
			owner.RQEProgressBar = progressBar
		end

		progressBar:SetParent(parentFrame)
		progressBar.RQEObjectiveText = objectiveText
		progressBar.RQEObjectiveParent = parentFrame
		RQE.LayoutObjectiveProgressBar(progressBar)
		progressBar:SetFrameLevel(parentFrame:GetFrameLevel() + 2)
		progressBar.RQEFill:SetFrameLevel(progressBar:GetFrameLevel())
		progressBar.RQEFill:SetStatusBarColor(0 / 255, 87 / 255, 184 / 255, 1)
		if RQE.UI and RQE.UI:IsEnabled() then
			progressBar:SetBackdropColor(9 / 255, 14 / 255, 23 / 255, 0.98)
			progressBar:SetBackdropBorderColor(1, 215 / 255, 0, 1)
		else
			progressBar:SetBackdropColor(0.03, 0.03, 0.06, 0.95)
			progressBar:SetBackdropBorderColor(0.55, 0.55, 0.62, 1)
		end
		progressBar.RQEFill:SetValue(progressInfo.percentage)
		progressBar.RQEPercentText:SetText(string.format("%d%%",
			math.floor(progressInfo.percentage + 0.5)))
		progressBar:Show()
		return progressBar
	end


	-------------------------------------------------------
	-- #11f. Quest Rewards Tooltip
	-------------------------------------------------------

	-- Populates the Game Tooltip with Quest Reward information when hovering over a quest
	function RQE:QuestRewardsTooltip(tooltip, questID)
		-- Reward Qualities
		local customItemQualityColors = {
			[0] = { r = 0.62, g = 0.62, b = 0.62 },  -- Poor (grey)
			[1] = { r = 1.00, g = 1.00, b = 1.00 },  -- Common (white)
			[2] = { r = 0.12, g = 1.00, b = 0.00 },  -- Uncommon (green)
			[3] = { r = 0.00, g = 0.44, b = 0.87 },  -- Rare (blue)
			[4] = { r = 0.64, g = 0.21, b = 0.93 },  -- Epic (purple)
			[5] = { r = 1.00, g = 0.50, b = 0.00 },  -- Legendary (orange)
		}

		-- Stores the current selected quest, then select the one we’re building tooltip for
		-- Previous Blizzard call changed 2026.09.25: local prevSelectedQuest = C_QuestLog.GetSelectedQuest()
		local prevSelectedQuest = RQE.API.Client.C_QuestLog.GetSelectedQuest()
		-- Previous Blizzard call changed 2026.09.25: C_QuestLog.SetSelectedQuest(questID)
		RQE.API.Client.C_QuestLog.SetSelectedQuest(questID)

		-- Retrieve rewards
		-- Previous Blizzard call changed 2026.09.25: local rewardXP = GetQuestLogRewardXP(questID)
		local rewardXP = RQE.API.Client.GetQuestLogRewardXP(questID)
		-- Previous Blizzard call changed 2026.09.25: local rewardMoney = GetQuestLogRewardMoney(questID)
		local rewardMoney = RQE.API.Client.GetQuestLogRewardMoney(questID)
		-- Previous Blizzard call changed 2026.09.25: local rewardArtifactXP = GetQuestLogRewardArtifactXP(questID)
		local rewardArtifactXP = RQE.API.Client.GetQuestLogRewardArtifactXP(questID)
		-- Previous Blizzard call changed 2026.09.25: local rewardHonor = GetQuestLogRewardHonor(questID)
		local rewardHonor = RQE.API.Client.GetQuestLogRewardHonor(questID)
		-- Previous Blizzard call changed 2026.09.25: local playerTitle = GetQuestLogRewardTitle(questID)
		local playerTitle = RQE.API.Client.GetQuestLogRewardTitle(questID)
		-- Previous Blizzard call changed 2026.09.25: local numQuestCurrencies = #C_QuestLog.GetQuestRewardCurrencies(questID)
		local numQuestCurrencies = #RQE.API.Client.C_QuestLog.GetQuestRewardCurrencies(questID)
		-- Previous Blizzard call changed 2026.09.25: local rewardItemsCount = GetNumQuestLogRewards(questID)
		local rewardItemsCount = RQE.API.Client.GetNumQuestLogRewards(questID)
		-- Previous Blizzard call changed 2026.09.25: local choiceItemsCount = GetNumQuestLogChoices(questID, true)
		local choiceItemsCount = RQE.API.Client.GetNumQuestLogChoices(questID, true)
		-- Previous Blizzard call changed 2026.09.25: local reputationRewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
		local reputationRewards = RQE.API.Client.C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
		-- Previous Blizzard call changed 2026.09.25: local spellIDs = C_QuestInfoSystem.GetQuestRewardSpells(questID) or {}
		local spellIDs = RQE.API.Client.C_QuestInfoSystem.GetQuestRewardSpells(questID) or {}

		-- Previous Blizzard call changed 2026.09.25: local skillName, skillIcon, rawSkillPoints = GetQuestLogRewardSkillPoints()
		local skillName, skillIcon, rawSkillPoints = RQE.API.Client.GetQuestLogRewardSkillPoints()
		local rewardSkillPoints = tonumber(rawSkillPoints) or 0

		-- If it's a World Quest or Task Quest, handle differently
		-- Previous Blizzard call changed 2026.09.25: if RQE.API.IsWorldQuest(questID) or C_TaskQuest.IsActive(questID) then
		if RQE.API.IsWorldQuest(questID) or RQE.API.Client.C_TaskQuest.IsActive(questID) then
			tooltip:AddLine("Rewards:", 1, 1, 1)

			-- XP and money
			-- Previous Blizzard call changed 2026.09.25: local xp = GetQuestLogRewardXP(questID)
			local xp = RQE.API.Client.GetQuestLogRewardXP(questID)
			if xp and xp > 0 then
				tooltip:AddLine("XP: " .. FormatLargeNumber(xp), 1, 1, 1)
				tooltip:AddLine(" ")
			end

			-- Previous Blizzard call changed 2026.09.25: local money = GetQuestLogRewardMoney(questID)
			local money = RQE.API.Client.GetQuestLogRewardMoney(questID)
			if money and money > 0 then
				-- Previous Blizzard call changed 2026.09.25: tooltip:AddLine("Gold: " .. GetCoinTextureString(money), 1, 1, 1)
				tooltip:AddLine("Gold: " .. RQE.API.Client.GetCoinTextureString(money), 1, 1, 1)
				tooltip:AddLine(" ")
			end

			-- Currencies
			-- Previous Blizzard call changed 2026.09.25: local currencies = C_QuestLog.GetQuestRewardCurrencies(questID) or {}
			local currencies = RQE.API.Client.C_QuestLog.GetQuestRewardCurrencies(questID) or {}
			for i, currencyInfo in ipairs(currencies) do
				if currencyInfo and currencyInfo.name and currencyInfo.texture then
					local amount = FormatLargeNumber(currencyInfo.totalRewardAmount or 0)
					local text = "|T" .. currencyInfo.texture .. ":16|t " .. amount .. " " .. currencyInfo.name
					local color = ITEM_QUALITY_COLORS[currencyInfo.quality] or { r = 1, g = 1, b = 1 }
					tooltip:AddLine(text, color.r, color.g, color.b)
					tooltip:AddLine(" ")
				end
			end

			-- Items
			-- Previous Blizzard call changed 2026.09.25: local numQuestRewards = GetNumQuestLogRewards(questID) or 0
			local numQuestRewards = RQE.API.Client.GetNumQuestLogRewards(questID) or 0
			for i = 1, numQuestRewards do
				-- Previous Blizzard call changed 2026.09.25: local name, texture, numItems, quality = GetQuestLogRewardInfo(i, questID)
				local name, texture, numItems, quality = RQE.API.Client.GetQuestLogRewardInfo(i, questID)
				if name then
					local countText = (numItems > 1) and (numItems .. "x ") or ""
					local text = (texture and "|T" .. texture .. ":16|t " or "") .. countText .. name
					local color = ITEM_QUALITY_COLORS[quality] or { r = 1, g = 1, b = 1 }
					tooltip:AddLine(text, color.r, color.g, color.b)
					tooltip:AddLine(" ")
				end
			end

			tooltip:Show()
			-- Restore selected quest if needed
			if prevSelectedQuest then
				-- Previous Blizzard call changed 2026.09.25: C_QuestLog.SetSelectedQuest(prevSelectedQuest)
				RQE.API.Client.C_QuestLog.SetSelectedQuest(prevSelectedQuest)
			end
			return
		end

		-- Choice rewards
		if choiceItemsCount > 0 then
			tooltip:AddLine(choiceItemsCount == 1 and "You will receive:" or "Choose one of the following rewards:")
			for i = 1, choiceItemsCount do
				-- Previous Blizzard call changed 2026.09.25: local lootType = GetQuestLogChoiceInfoLootType(i)
				local lootType = RQE.API.Client.GetQuestLogChoiceInfoLootType(i)
				if lootType == 0 then
					-- Item choice
					-- Previous Blizzard call changed 2026.09.25: local itemName, _, numItems, quality = GetQuestLogChoiceInfo(i)
					local itemName, _, numItems, quality = RQE.API.Client.GetQuestLogChoiceInfo(i)
					if itemName then
						local text = (numItems > 1) and (numItems .. "x " .. itemName) or itemName
						local color = customItemQualityColors[quality] or { r = 1, g = 1, b = 1 }
						tooltip:AddLine(text, color.r, color.g, color.b)
					end
				elseif lootType == 1 then
					-- Currency choice
					-- Previous Blizzard call changed 2026.09.25: local currencyInfo = C_QuestLog.GetQuestRewardCurrencyInfo(questID, i, true)
					local currencyInfo = RQE.API.Client.C_QuestLog.GetQuestRewardCurrencyInfo(questID, i, true)
					if currencyInfo and currencyInfo.name and currencyInfo.texture then
						local amount = FormatLargeNumber(currencyInfo.totalRewardAmount or 0)
						local text = "|T" .. currencyInfo.texture .. ":16|t " .. amount .. " " .. currencyInfo.name
						local color = customItemQualityColors[currencyInfo.quality] or { r = 1, g = 1, b = 1 }
						tooltip:AddLine(text, color.r, color.g, color.b)
					end
				end
			end
		end

		-- Any static rewards?
		local hasOtherRewards = rewardXP > 0 or rewardMoney > 0 or rewardArtifactXP > 0 or rewardItemsCount > 0 or reputationRewards and #reputationRewards > 0 or rewardHonor > 0 or playerTitle or rewardSkillPoints > 0 or #spellIDs > 0
		if hasOtherRewards then
			if choiceItemsCount > 0 then tooltip:AddLine("\nAdditional rewards:") else tooltip:AddLine("Rewards:") end

			if rewardXP > 0 then tooltip:AddLine("XP: " .. FormatLargeNumber(rewardXP), 1, 1, 1) end
			-- Previous Blizzard call changed 2026.09.25: if rewardMoney > 0 then tooltip:AddLine("Gold: " .. C_CurrencyInfo.GetCoinTextureString(rewardMoney), 1, 1, 1) end
			if rewardMoney > 0 then tooltip:AddLine("Gold: " .. RQE.API.Client.C_CurrencyInfo.GetCoinTextureString(rewardMoney), 1, 1, 1) end
			if rewardArtifactXP > 0 then tooltip:AddLine("Artifact Power: " .. FormatLargeNumber(rewardArtifactXP), 1, 1, 1) end
			if rewardHonor > 0 then tooltip:AddLine("Honor: " .. rewardHonor, 1, 1, 1) end
			if playerTitle then tooltip:AddLine("Title: " .. playerTitle, 1, 1, 1) end

			if rewardSkillPoints > 0 and skillName then
				tooltip:AddLine("Profession: +" .. rewardSkillPoints .. " to " .. skillName, 1, 1, 1)
			end

			if numQuestCurrencies > 0 then
				QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip)
			end

			for i = 1, rewardItemsCount do
				-- Previous Blizzard call changed 2026.09.25: local itemName, _, numItems, quality = GetQuestLogRewardInfo(i, questID)
				local itemName, _, numItems, quality = RQE.API.Client.GetQuestLogRewardInfo(i, questID)
				if itemName then
					local text = (numItems > 1) and (numItems .. "x " .. itemName) or itemName
					local color = customItemQualityColors[quality] or { r = 1, g = 1, b = 1 }
					tooltip:AddLine(text, color.r, color.g, color.b)
				end
			end

			if #spellIDs > 0 then
				tooltip:AddLine("\nReward Spells:")
				for _, spellID in ipairs(spellIDs) do
					-- Previous Blizzard call changed 2026.09.25: local info = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
					local info = RQE.API.Client.C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
					-- Previous Blizzard call changed 2026.09.25: if info and info.name and not IsSpellKnownOrOverridesKnown(spellID) and (not info.isBoostSpell or IsCharacterNewlyBoosted()) and (not info.garrFollowerID or not C_Garrison.IsFollowerCollected(info.garrFollowerID)) then
					if info and info.name and not RQE.API.Client.IsSpellKnownOrOverridesKnown(spellID) and (not info.isBoostSpell or RQE.API.Client.IsCharacterNewlyBoosted()) and (not info.garrFollowerID or not RQE.API.Client.C_Garrison.IsFollowerCollected(info.garrFollowerID)) then
						local icon = info.texture or 134400
						tooltip:AddLine("|T" .. icon .. ":16|t " .. info.name, 1, 1, 1)
					end
				end
			end

			if reputationRewards and #reputationRewards > 0 then
				tooltip:AddLine("\nReputation:")
				for _, reward in ipairs(reputationRewards) do
					-- Previous Blizzard call changed 2026.09.25: local data = C_MajorFactions.GetMajorFactionData(reward.factionID)
					local data = RQE.API.Client.C_MajorFactions.GetMajorFactionData(reward.factionID)
					tooltip:AddLine((data and data.name or ("Faction ID " .. reward.factionID)) .. ": " .. reward.rewardAmount, 0, 1, 0)
				end
			end
		end

		-- Restore previously selected quest
		if prevSelectedQuest then
			-- Previous Blizzard call changed 2026.09.25: C_QuestLog.SetSelectedQuest(prevSelectedQuest)
			RQE.API.Client.C_QuestLog.SetSelectedQuest(prevSelectedQuest)
		end

		tooltip:Show()
	end


	-------------------------------------------------------
	-- #11g. Quest Type & Zone Classification
	-------------------------------------------------------

	-- Enhanced Determine QuestType Function
	function GetQuestType(questID)
		-- Previous Blizzard call changed 2026.09.25: local questClassification = C_QuestInfoSystem.GetQuestClassification(questID)
		local questClassification = RQE.API.Client.C_QuestInfoSystem.GetQuestClassification(questID)

		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.ReadyForTurnIn(questID) then
		if RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID) then
			return "|cFF00FF00QUEST COMPLETE|r"  -- Green color for completed quests

		elseif questClassification == 1 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Important Quest"  -- Important Quests

		elseif questClassification == 0 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Normal Quest"  -- Normal Quests

		elseif questClassification == 2 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Legendary Quest"  -- Legendary Quests

		elseif questClassification == 3 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Campaign Quest"  -- Campaign Quests

		elseif questClassification == 4 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Calling Quest"  -- Calling Quests

		elseif questClassification == 5 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Meta Quest"  -- Meta Quests

		elseif questClassification == 6 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Recurring Quest"  -- Recurring Quests

		elseif questClassification == 7 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Normal Quest"  -- Normal Quest fallback (non-important)

		elseif questClassification == 8 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Bonus Objective"  -- Bonus Objective Quests

		elseif questClassification == 9 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Threat Quest"  -- Threat Quests

		elseif questClassification == 10 then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "World Quest"  -- World Quests

		else
			-- Handle fallback cases when the classification isn't defined or known
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " is: " .. tostring(questClassification))
			end
			return "Unknown Quest Type"
		end
	end


	-- Function to get the zone name for a given quest
	function GetQuestZone(questID)
		-- Previous Blizzard call changed 2026.09.25: local mapID = GetQuestUiMapID(questID)
		local mapID = RQE.API.Client.GetQuestUiMapID(questID)
		if mapID then
			-- Previous Blizzard call changed 2026.09.25: local mapInfo = C_Map.GetMapInfo(mapID)
			local mapInfo = RQE.API.Client.C_Map.GetMapInfo(mapID)
			if mapInfo and mapInfo.name then
				return mapInfo.name
			end
		end
		-- Do not mutate QuestMapFrame/WorldMapFrame to resolve a display label.
		-- Retail's map refresh can reach protected pin setup during combat.
		-- Previous Blizzard call changed 2026.09.25: local uiMapID, worldQuests, worldQuestsElite, dungeons, treasures = C_QuestLog.GetQuestAdditionalHighlights(questID)
		local uiMapID, worldQuests, worldQuestsElite, dungeons, treasures = RQE.API.Client.C_QuestLog.GetQuestAdditionalHighlights(questID)
		if uiMapID then
			-- Previous Blizzard call changed 2026.09.25: local mapInfo = C_Map.GetMapInfo(uiMapID)
			local mapInfo = RQE.API.Client.C_Map.GetMapInfo(uiMapID)
			if mapInfo and mapInfo.name then
				return mapInfo.name
			end
		end

		-- Previous Blizzard call changed 2026.09.25: local fallbackZoneID = C_TaskQuest.GetQuestZoneID(questID)
		local fallbackZoneID = RQE.API.Client.C_TaskQuest.GetQuestZoneID(questID)
		if fallbackZoneID then
			-- Previous Blizzard call changed 2026.09.25: local fallbackMapInfo = C_Map.GetMapInfo(fallbackZoneID)
			local fallbackMapInfo = RQE.API.Client.C_Map.GetMapInfo(fallbackZoneID)
			if fallbackMapInfo and fallbackMapInfo.name then
				return fallbackMapInfo.name
			end
		end

		-- Previous Blizzard call changed 2026.09.25: local waypointZoneID = C_QuestLog.GetNextWaypoint(questID)
		local waypointZoneID = RQE.API.Client.C_QuestLog.GetNextWaypoint(questID)
		if waypointZoneID then
			-- Previous Blizzard call changed 2026.09.25: local waypointMapInfo = C_Map.GetMapInfo(waypointZoneID)
			local waypointMapInfo = RQE.API.Client.C_Map.GetMapInfo(waypointZoneID)
			if waypointMapInfo and waypointMapInfo.name then
				return waypointMapInfo.name
			end
		end

		-- Fallback to a pre-compiled quest-zone list
		if RQE.ZoneQuests and RQE.ZoneQuests[questID] then
			return RQE.ZoneQuests[questID]
		end

		return "Unknown Zone"
	end


	-- Function to determine if each quest belongs to World Quest or Non-World Quest
	function RQE:QuestType()
		-- Previous Blizzard call changed 2026.09.25: local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
		local numTrackedQuests = RQE.API.Client.C_QuestLog.GetNumQuestWatches()
		-- Previous Blizzard call changed 2026.09.25: local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
		local numTrackedWorldQuests = RQE.API.Client.C_QuestLog.GetNumWorldQuestWatches()
		local regularQuestUpdated = false
		local worldQuestUpdated = false

		-- Loop through all tracked quests for regular and campaign quests
		for i = 1, numTrackedQuests do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if questID and not RQE.API.IsWorldQuest(questID) then
				regularQuestUpdated = true
			end
		end

		-- Loop through all tracked World Quests
		for i = 1, numTrackedWorldQuests do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if questID then
				worldQuestUpdated = true
			end
		end

		-- Update frames if needed
		if regularQuestUpdated then
			UpdateRQEQuestFrame()
		end
		if worldQuestUpdated then
			UpdateRQEWorldQuestFrame()
		end
	end


	-------------------------------------------------------
	-- #11h. Main Tracked Quest Rendering
	-------------------------------------------------------

	-- Updates the RQEQuestFrame
	function UpdateRQEQuestFrame()
		RQE.LastTrackerStepCacheMapID = RQE.LastTrackerStepCacheMapID
			-- Previous Blizzard call changed 2026.09.25: or C_Map.GetBestMapForUnit("player")
			or RQE.API.Client.C_Map.GetBestMapForUnit("player")
		RQE:SortWatchedQuestsByProximity()
		RQE:ClearRQEQuestFrame() -- Clears the Quest Frame in preparation for refreshing it

		local campaignQuestCount, regularQuestCount, worldQuestCount, bonusQuestCount = 0, 0, 0, 0
		local campaignStatusLineCount, regularStatusLineCount = 0, 0
		RQE.campaignQuestCount = campaignQuestCount
		RQE.bonusQuestCount = bonusQuestCount
		RQE.regularQuestCount = regularQuestCount + RQE.bonusQuestCount -- Include bonus quests in the count
		RQE.worldQuestCount = worldQuestCount

		RQE.AchievementsFrame.achieveCount = 0
		local baseHeight = 175 -- Base height when no quests are present
		local questHeight = 65 -- Height per quest
		local spacingBetweenElements = 5
		local extraHeightForScenario = 50

		-- Check if ScenarioChildFrame is present and visible
		if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			local numCriteria = RQE.ScenarioChildFrame.numCriteria or 0
			extraHeightForScenario = numCriteria * questHeight
		end

		-- Loop through all tracked quests to count campaign and world quests
		-- Previous Blizzard call changed 2026.09.25: local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
		local numTrackedQuests = RQE.API.Client.C_QuestLog.GetNumQuestWatches()
		RQE.worldQuestCount = 0  -- Reset before counting
		-- Previous Blizzard call changed 2026.09.25: RQE.worldQuestCount = C_QuestLog.GetNumWorldQuestWatches()
		RQE.worldQuestCount = RQE.API.Client.C_QuestLog.GetNumWorldQuestWatches()

		for i = 1, numTrackedQuests do
			-- Previous Blizzard call changed 2026.09.25: local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local questID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			-- Previous Blizzard call changed 2026.09.25: local isCampaignQuest = C_CampaignInfo.IsCampaignQuest(questID) or C_QuestLog.IsMetaQuest(questID)
			local isCampaignQuest = RQE.API.Client.C_CampaignInfo.IsCampaignQuest(questID) or RQE.API.Client.C_QuestLog.IsMetaQuest(questID)
			if isCampaignQuest then
				RQE.campaignQuestCount = RQE.campaignQuestCount + 1
			elseif RQE.API.IsWorldQuest(questID) then
				RQE.worldQuestCount = RQE.worldQuestCount + 1
			end
			if not RQE.API.IsWorldQuest(questID) and GetTrackedQuestStatusText(questID) then
				if isCampaignQuest then
					campaignStatusLineCount = campaignStatusLineCount + 1
				else
					regularStatusLineCount = regularStatusLineCount + 1
				end
			end
		end

		-- Calculate the number of regular quests
		RQE.regularQuestCount = numTrackedQuests - RQE.campaignQuestCount

		-- Calculate frame heights
		local campaignHeight = baseHeight + (RQE.campaignQuestCount * questHeight) + (campaignStatusLineCount * 14)
		local regularHeight = baseHeight + (RQE.regularQuestCount * questHeight) + (regularStatusLineCount * 14) + extraHeightForScenario
		local worldQuestHeight = baseHeight + (RQE.worldQuestCount * questHeight)
		local achievementHeight = RQE.AchievementsFrame.lastMeasuredHeight or baseHeight

		-- World Quest rows are deliberately not rebuilt during combat because that
		-- renderer can create and reconfigure buttons.  Keep its last measured
		-- height instead of replacing it with this coarse count-based estimate;
		-- otherwise the Bonus Quests header is pushed well below the visible row.
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			worldQuestHeight = RQE.WorldQuestsFrame.lastMeasuredHeight or RQE.WorldQuestsFrame:GetHeight()
		end

		-- Update frame heights
		RQE.CampaignFrame:SetHeight(campaignHeight)
		RQE.QuestsFrame:SetHeight(regularHeight)
		RQE.WorldQuestsFrame:SetHeight(worldQuestHeight)
		RQE.AchievementsFrame:SetHeight(achievementHeight)

		-- Update total content height
		local totalHeight = campaignHeight + regularHeight + worldQuestHeight + achievementHeight
		RQE.QTcontent:SetHeight(totalHeight)

		-- Store quest count in each frame for reference
		RQE.CampaignFrame.questCount = RQE.campaignQuestCount
		RQE.QuestsFrame.questCount = RQE.regularQuestCount
		RQE.WorldQuestsFrame.questCount = RQE.worldQuestCount

		for _, fontString in pairs(RQE.RQEQuestFrame.questTitles or {}) do
			fontString:Hide()
		end

		RQE.RQEQuestFrame.questTitles = RQE.RQEQuestFrame.questTitles or {}

		-- Initialize the table to hold the QuestLogIndexButtons if it doesn't exist
		RQE.QuestLogIndexButtons = RQE.QuestLogIndexButtons or {}

		-- Create a variable to hold the last QuestObjectivesOrDescription
		local lastQuestObjectivesOrDescription = nil

		-- Custom orders must be laid out as a whole. The legacy Campaign -> Normal
		-- -> World chain can point back into a reordered section and form a cycle.
		if RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout() then
			RQE:ApplyTrackerSectionOrder()
		else
		-- Create the Set Point for the Regular Quests Child Frame
		if RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
			-- If CampaignFrame is present and shown, anchor QuestsFrame to CampaignFrame
			RQE.QuestsFrame:ClearAllPoints()
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If CampaignFrame is not shown but ScenarioChildFrame is, anchor QuestsFrame to ScenarioChildFrame
			RQE.QuestsFrame:ClearAllPoints()
			RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			-- If neither is present or shown, anchor QuestsFrame to content
			RQE.QuestsFrame:ClearAllPoints()
			RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Create the Set Point for the World Quests Child Frame
		if RQE.QuestsFrame and RQE.QuestsFrame:IsShown() then
			-- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
			RQE.WorldQuestsFrame:ClearAllPoints()
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
			-- If QuestsFrame is not shown but CampaignFrame is, anchor WorldQuestsFrame to CampaignFrame
			RQE.WorldQuestsFrame:ClearAllPoints()
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If none of the quest frames are shown but ScenarioChildFrame is, anchor WorldQuestsFrame to ScenarioChildFrame
			RQE.WorldQuestsFrame:ClearAllPoints()
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			-- If no other frames are present or shown, anchor WorldQuestsFrame to content
			RQE.WorldQuestsFrame:ClearAllPoints()
			RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end

		-- Create the Set Point for the World Quests Child Frame
		if RQE.WorldQuestsFrame and RQE.WorldQuestsFrame:IsShown() then
			-- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.QuestsFrame and RQE.QuestsFrame:IsShown() then
			-- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
			-- If QuestsFrame is not shown but CampaignFrame is, anchor WorldQuestsFrame to CampaignFrame
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			-- If none of the quest frames are shown but ScenarioChildFrame is, anchor WorldQuestsFrame to ScenarioChildFrame
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			-- If no other frames are present or shown, anchor WorldQuestsFrame to content
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
		end

		-- Separate variables to track the last element in each child frame
		local lastCampaignElement, lastQuestElement, lastWorldQuestElement = nil, nil, nil
		RQE.lastCampaignElement = lastCampaignElement
		RQE.lastQuestElement = lastQuestElement
		RQE.lastWorldQuestElement = lastWorldQuestElement

		-- Get the bonus quests in the current zone
		local bonusQuests = RQE:GetBonusQuestsInCurrentZone()

		-- Loop through sorted watched quests by proximity
		for i, questData in ipairs(RQE.SortedWatchedQuests) do
			local questID = questData.questID
			-- Previous Blizzard call changed 2026.09.25: local directionText = C_QuestLog.GetNextWaypointText(questID)
			local directionText = RQE.API.Client.C_QuestLog.GetNextWaypointText(questID)
			RQE.QuestDirectionText = directionText
			-- Previous Blizzard call changed 2026.09.25: local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
			local questIndex = RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)
			-- Previous Blizzard call changed 2026.09.25: local isQuestComplete = C_QuestLog.IsComplete(questID)
			local isQuestComplete = RQE.API.Client.C_QuestLog.IsComplete(questID)
			local isSuperTracked = RQE.API.GetSuperTrackedQuestID() == questID

			if questIndex and not RQE.API.IsWorldQuest(questID) then
				local info = RQE.API.GetQuestLogInfo(questIndex)

				if info and not info.isHeader then
					-- Determine the type of the quest (Campaign, World Quest, or Regular)
					-- Previous Blizzard call changed 2026.09.25: local isCampaignQuest = C_CampaignInfo.IsCampaignQuest(questID) or C_QuestLog.IsMetaQuest(questID)
					local isCampaignQuest = RQE.API.Client.C_CampaignInfo.IsCampaignQuest(questID) or RQE.API.Client.C_QuestLog.IsMetaQuest(questID)
					local isWorldQuest = RQE.API.IsWorldQuest(questID)
					-- Previous Blizzard call changed 2026.09.25: local isBonusQuest = C_QuestLog.IsQuestTask(questID) or C_QuestLog.IsThreatQuest(questID)
					local isBonusQuest = RQE.API.Client.C_QuestLog.IsQuestTask(questID) or RQE.API.Client.C_QuestLog.IsThreatQuest(questID)
					local dailyFrequency = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily or 1
					local isDailyQuest = info.frequency == dailyFrequency

					local parentFrame
					local lastElement
					if isCampaignQuest then
						parentFrame = RQE.CampaignFrame
						lastElement = lastCampaignElement
					elseif isWorldQuest then --or isBonusQuest then
						parentFrame = RQE.WorldQuestsFrame
						lastElement = lastWorldQuestElement
					else
						parentFrame = RQE.QuestsFrame
						lastElement = lastQuestElement
					end

					-- Create or reuse the QuestLogIndexButton
					---@class QuestLogIndexButton : Button
					---@field bg Texture
					---@field number FontString
					local QuestLogIndexButton = RQE.QuestLogIndexButtons[i] or CreateFrame("Button", nil, parentFrame)	-- TAINT?: possibly source if run in combat
					-- Rows must belong to their section so collapsing or hiding that
					-- section also hides its quest text and interactive button.
					if QuestLogIndexButton:GetParent() ~= parentFrame then
						QuestLogIndexButton:SetParent(parentFrame)
					end
					QuestLogIndexButton:SetSize(TRACKER_QUEST_BUTTON_SIZE, TRACKER_QUEST_BUTTON_SIZE)

					-- Create or update the background texture
					local bg = QuestLogIndexButton.bg or QuestLogIndexButton:CreateTexture(nil, "BACKGROUND")
					bg:SetAllPoints()
					if isSuperTracked then
						bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
					else
						bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
					end
					QuestLogIndexButton.bg = bg  -- Save for future reference

					-- Create or update the number label
					local number = QuestLogIndexButton.number or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
					number:SetPoint("CENTER", QuestLogIndexButton, "CENTER")
					number:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
					number:SetTextColor(1, 0.7, 0.2)
					number:SetText(questIndex)
					QuestLogIndexButton.number = number  -- Save for future reference
					local questKind = isCampaignQuest and "Campaign"
						or isBonusQuest and "Bonus"
						or isDailyQuest and "Daily" or "Normal"
					if RQE.UI then RQE.UI:StyleQuestIndexButton(QuestLogIndexButton, isSuperTracked, questKind) end

					-- Quest Watch List
					QuestLogIndexButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
					QuestLogIndexButton:SetScript("OnMouseDown", function(self, button, confirmed)
						-- Previous Blizzard call changed 2026.09.25: local shiftLeftClick = not confirmed and IsShiftKeyDown()
						local shiftLeftClick = not confirmed and RQE.API.Client.IsShiftKeyDown()
							and button == "LeftButton"
						if not confirmed and not self:IsMouseOver() then return end
						if not confirmed and not shiftLeftClick
							and RQE:RequestCoordOrderTrackingConfirmation("switch", questID,
								function()
									if self.questID ~= questID then return end
									local handler = self:GetScript("OnMouseDown")
									if handler then handler(self, button, true) end
								end) then return end
					RQE.QuestLogIndexButtonPressed = true
						RQE.OkaytoUpdateCreateSteps = true
						RQE.AllFramesShouldUpdate = true

						-- Make sure player is actually hovering over the button
						if not confirmed and not self:IsMouseOver() then return end
						-- A physical quest-row press explicitly returns waypoint ownership
						-- to the normal DB/Blizzard selector, even for the same quest.
						RQE:ReleaseActiveCoordblockWaypoint()
						RQE.ManualFlightMasterWaypointMapID = nil
						RQE.ManualFlightMasterWaypointQuestID = nil
						RQE.ManualFlightMasterWaypointStepIndex = nil
						RQE.NearestFlightMasterSet = false

						RQE:ClearSeparateFocusFrame()

						-- Check if the player is in combat and return if an automatic click
						-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
						if RQE.API.Client.InCombatLockdown() then
							if RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsMouseOver() then
								return
							end
						end

						if RQE.db.profile.debugLevel == "INFO" then
							RQE:CheckCoordHotspotsInSteps(questID)
						end

						if shiftLeftClick then
							if RQE.db.profile.debugLevel == "INFO+" then
								if RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsMouseOver() then
									print("Not hovering over RQEQuestFrame!")
									return
								end
							end

							-- Explicitly double-check mouseover on *this* button
							if not self:IsMouseOver() then
								if RQE.db.profile.debugLevel == "INFO+" then
									print("Not hovering over this button, aborting RemoveQuestWatch.")
								end
								return
							end

							-- Untrack the quest
							if not RQE.hoveringOnFrame then return end
							-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(questID)
							RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID)

							local extractedQuestID
							if RQE.QuestIDText and RQE.QuestIDText:GetText() then
								extractedQuestID = RQE.DisplayedQuestID
							end

							if questID == extractedQuestID then
								RQE:ClearFrameData()  -- changed from RQE.ClearFrameData() - which is nothing
								RQE:ClearWaypointButtonData()
							end

							-- Refresh the UI here to update the button state
							UpdateRQEQuestFrame()

							-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.25, function()
							RQE.API.Client.C_Timer.After(0.25, function()
								RQE:SaveTrackedQuestsToCharacter()
								RQE:SaveSuperTrackedQuestToCharacter()
							end)
						else
							-- Re-selecting a quest is deliberate: once its actual step is
							-- restored, start an ordered route at the nearest same-map point.
							local sameQuestReselect = tonumber(RQE.API.GetSuperTrackedQuestID())
								== tonumber(questID)
							local previousStep = tonumber(RQE.AddonSetStepIndex
								or RQE.CurrentDisplayedStepIndex)
							RQE._coordOrderReselect = {
								-- Previous Blizzard call changed 2026.09.25: questID = questID, expiresAt = GetTime() + 5,
								questID = questID, expiresAt = RQE.API.Client.GetTime() + 5,
								-- Previous Blizzard call changed 2026.09.25: readyAt = GetTime() + (sameQuestReselect and 0 or 0.75),
								readyAt = RQE.API.Client.GetTime() + (sameQuestReselect and 0 or 0.75),
								sameQuest = sameQuestReselect, previousStep = previousStep,
								armed = false,
							}
							if RQE.hoveringOnFrame or confirmed then
								RQE.DontUpdateFrame = false

								-- Leaving manual step preview mode and returning control to automatic quest progression.
								if RQE.db.profile.enableStepControls then
									RQE:ClearManualStepPreview(false)
									RQE.ManualStepOverrideQLIB = true
								end

								RQE.shouldCheckFinalStep = true
								RQE.CheckAndSetFinalStep()
								-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.1, function()
								RQE.API.Client.C_Timer.After(0.1, function()
									RQE.ClickUnknownQuestButton()
									RQE.NearestFlightMasterSet = false

									if RQE.db.profile.enableTravelSuggestions then
										-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.8, function()
										RQE.API.Client.C_Timer.After(0.8, function()
											RQE:RecommendFastestTravelMethod()
										end)
									end

									-- Check if autoClickWaypointButton is selected in the configuration
									if RQE.db.profile.autoClickWaypointButton then
										-- Click the "W" Button is autoclick is selected and no steps or questData exist
										RQE.CheckAndClickWButton()
									end

									RQE.ObtainSuperTrackQuestDetails()

									if RQE.db.profile.autoClickWaypointButton then
										-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.1, function()
										RQE.API.Client.C_Timer.After(0.1, function()
											if not sameQuestReselect then RQE.AddonSetStepIndex = 1 end
											RQE:StartPeriodicChecks()
										end)
									end

									-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.2, function()
									RQE.API.Client.C_Timer.After(0.2, function()
										RQE:SaveSuperTrackedQuestToCharacter()
									end)
								end)
							end

							-- Previous Blizzard call changed 2026.09.25: C_Map.ClearUserWaypoint()
							RQE.API.Client.C_Map.ClearUserWaypoint()
							-- Check if TomTom is loaded and compatibility is enabled
							-- Previous Blizzard call changed 2026.09.25: if C_AddOns.IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
							if RQE.API.Client.C_AddOns.IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
								TomTom.waydb:ResetProfile()
								RQE._currentTomTomUID = nil
							end

							-- New quests start at button 1; reselecting the same quest keeps
							-- its current step for the nearest ordered-point re-anchor.
							if not sameQuestReselect then RQE.SetInitialWaypointToOne() end

							-- Scrolls the RQEFrame to top on super track
							RQE.ScrollFrameToTop()

							-- Reset the "Clicked" WaypointButton to nil
							if not sameQuestReselect then RQE.LastClickedIdentifier = nil end

							-- Preserve the active button on a same-quest reselect; otherwise
							-- StartPeriodicChecks would briefly evaluate step 1 again.
							RQE.LastClickedButtonRef = (sameQuestReselect and previousStep
								and RQE.WaypointButtons[previousStep]) or RQE.WaypointButtons[1]

							-- Get the currently super tracked quest ID
							local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()

							-- Simulates pressing the "Clear Window" Button before proceeding with rest of function
							RQE:PerformClearActions()

							-- Clears Macro Data
							RQEMacro:ClearMacroContentByName("RQE Macro")

							-- Super track the new quest
							-- This will re-super track the quest even if it's the same as the currently super tracked quest
							RQE.ManualSuperTrack = true
							RQE.ManualSuperTrackedQuestID = questID
							-- Previous Blizzard call changed 2026.09.25: C_SuperTrack.SetSuperTrackedQuestID(questID)
							RQE.API.Client.C_SuperTrack.SetSuperTrackedQuestID(questID)
							if RQE._coordOrderReselect and RQE._coordOrderReselect.questID == questID then
								RQE._coordOrderReselect.armed = true
							end
							RQE:SaveSuperTrackedQuestToCharacter()

							-- Allow time for the UI to update and for the super track to register
							-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1, function()
							RQE.API.Client.C_Timer.After(1, function()
								-- Fetch the quest data here
								local questData = RQE.getQuestData(questID)
								if not questData then
									RQE.debugLog("Quest data not found for questID:", questID)
									return
								end

								-- Check if the last clicked waypoint button's macro should be set
								local waypointButton = RQE.LastClickedWaypointButton
								if waypointButton and waypointButton.stepIndex then
									local stepData = questData[waypointButton.stepIndex]
									if stepData and stepData.macro then
										-- Get macro commands from the step data
										local macroCommands = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro
										RQEMacro:SetQuestStepMacro(questID, waypointButton.stepIndex, macroCommands, false)
									end
								end
							end)

							-- Refresh the UI here to update the button state
							UpdateRQEQuestFrame()

							-- Check if MagicButton should be visible based on macro body
							-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1, function()
							RQE.API.Client.C_Timer.After(1, function()
								RQE.Buttons.UpdateMagicButtonVisibility()
							end)
						end
					end)

					-- Save the button in the table for future reference
					RQE.QuestLogIndexButtons[i] = QuestLogIndexButton
					QuestLogIndexButton.questID = questID  -- Store the questID with its respective button

					-- Fetch Quest Description
					-- Previous Blizzard call changed 2026.09.25: local _, questObjectivesText = GetQuestLogQuestText(questIndex)
					local _, questObjectivesText = RQE.API.Client.GetQuestLogQuestText(questIndex)

					-- Fetch Quest Objectives
					local objectivesTable = RQE.API.GetQuestObjectives(questID)
					local objectivesText = objectivesTable and "" or "No objectives available."

					if objectivesTable then
						for _, objective in pairs(objectivesTable) do
							-- Simply append the objective text without any additional progress information
							objectivesText = objectivesText .. objective.text .. "\n"
						end
					end

					local questTitle, questLevel, suggestedSize

					-- Use the regular quest title, level, and suggestedSize of party
					questTitle = info.title
					questLevel = info.level
					-- Previous Blizzard call changed 2026.09.25: suggestedSize = C_QuestLog.GetSuggestedGroupSize(questID)
					suggestedSize = RQE.API.Client.C_QuestLog.GetSuggestedGroupSize(questID)

					-- Create or reuse the QuestLevelAndName label
					local QuestLevelAndName = RQE.QuestLogIndexButtons[i].QuestLevelAndName or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")--, content)
					QuestLogIndexButton.QuestLevelAndName = QuestLevelAndName
					QuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
					QuestLevelAndName:SetTextColor(137/255, 95/255, 221/255)  -- Medium Purple

					local levelText
					if suggestedSize and suggestedSize > 1 then
						levelText = string.format("[%s - Suggested: %s+]", questLevel, suggestedSize)
					else
						levelText = string.format("[%s]", questLevel)
					end

					QuestLevelAndName:SetText(levelText .. " " .. questTitle)

					local QuestStatusInfo = RQE.QuestLogIndexButtons[i].QuestStatusInfo or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					QuestStatusInfo:ClearAllPoints()
					QuestStatusInfo:SetPoint("TOPLEFT", QuestLevelAndName, "BOTTOMLEFT", 0, -3)
					QuestStatusInfo:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
					QuestStatusInfo:SetJustifyH("LEFT")
					QuestStatusInfo:SetJustifyV("TOP")
					QuestStatusInfo:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
					QuestStatusInfo:SetHeight(0)
					QuestLogIndexButton.QuestStatusInfo = QuestStatusInfo

					-- Display the current distance to this quest's next incomplete RQE step
					-- between its title and objective text, matching the Classic trackers.
					local distance, stepIndex = questData.distanceYards, questData.stepIndex
					local QuestDistanceInfo = RQE.QuestLogIndexButtons[i].QuestDistanceInfo or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					QuestDistanceInfo:ClearAllPoints()
					QuestDistanceInfo:SetPoint("TOPLEFT", QuestLevelAndName, "BOTTOMLEFT", 0, -3)
					QuestDistanceInfo:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
					QuestDistanceInfo:SetTextColor(0, 212/255, 212/255) -- Bright teal: #00D4D4
					QuestDistanceInfo:SetJustifyH("LEFT")
					QuestDistanceInfo:SetJustifyV("TOP")
					QuestDistanceInfo:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
					QuestDistanceInfo:SetHeight(0)
					QuestDistanceInfo:SetText(distance and string.format("Distance: %.0f yds", distance) or "Distance: N/A")
					QuestDistanceInfo:Show()
					QuestLogIndexButton.QuestDistanceInfo = QuestDistanceInfo
					QuestLogIndexButton.rqeTrackerDistanceStepIndex = stepIndex
					StartTrackedQuestStatusUpdates(QuestLogIndexButton, questID, QuestLevelAndName, QuestDistanceInfo)

					-- Create or reuse the QuestObjectives label
					local QuestObjectives = RQE.QuestLogIndexButtons[i].QuestObjectives or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					QuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
					QuestObjectives:SetWordWrap(true)
					QuestObjectives:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
					QuestObjectives:SetHeight(0)  -- Auto height
					QuestObjectives:SetText(objectivesText)

					RQE.QuestLogIndexButtons[i].QuestObjectives = QuestObjectives

					-- Anchor logic based on the quest type and index of lastelement/first
					QuestLevelAndName:ClearAllPoints()
					if lastElement then
						QuestLevelAndName:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -15)
					else
						QuestLevelAndName:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", GetTrackerQuestLabelInset(), -40)
					end
					AnchorTrackerQuestButton(QuestLogIndexButton, QuestLevelAndName)

					-- Set Justification and Word Wrap
					QuestLevelAndName:SetJustifyH("LEFT")
					QuestLevelAndName:SetJustifyV("TOP")
					QuestLevelAndName:SetWordWrap(true)
					QuestLevelAndName:SetWidth(RQE.RQEQuestFrame:GetWidth() - 100)
					QuestLevelAndName:SetHeight(0)  -- Auto height
					QuestLevelAndName:EnableMouse(true)

					QuestLevelAndName:SetScript("OnLeave", function()
						GameTooltip:Hide()
					end)

					-- Quest Type
					if RQE.db.profile.enableQuestTypeDisplay then
						local questTypeText = GetQuestType(questID)
						local questZoneText = GetQuestZone(questID)
						local QuestTypeLabel = QuestLogIndexButton.QuestTypeLabel or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						RQE.QuestTypeLabel = QuestTypeLabel
						QuestTypeLabel:ClearAllPoints()
						QuestTypeLabel:SetPoint("TOPLEFT", QuestDistanceInfo, "BOTTOMLEFT", 0, -3)
						QuestTypeLabel:SetWordWrap(true)
						QuestTypeLabel:SetJustifyH("LEFT")
						QuestTypeLabel:SetJustifyV("TOP")
						QuestTypeLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
						QuestTypeLabel:SetTextColor(250/255, 128/255, 115/255)  -- Salmon

						-- Update the quest type label text
						QuestTypeLabel:SetText(questTypeText .. " @ " .. questZoneText)
						QuestLogIndexButton.QuestTypeLabel = QuestTypeLabel
					end

					-- Create or reuse the QuestObjectivesOrDescription label
					local QuestObjectivesOrDescription = RQE.QuestLogIndexButtons[i].QuestObjectivesOrDescription or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					QuestObjectivesOrDescription:ClearAllPoints()
					if RQE.db.profile.enableQuestTypeDisplay then
						QuestObjectivesOrDescription:SetPoint("TOPLEFT", RQE.QuestTypeLabel, "BOTTOMLEFT", 0, -5)  -- 10 units of vertical spacing
					else
						QuestObjectivesOrDescription:SetPoint("TOPLEFT", QuestDistanceInfo, "BOTTOMLEFT", 0, -3)
					end
					QuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
					QuestObjectivesOrDescription:SetJustifyH("LEFT")
					QuestObjectivesOrDescription:SetJustifyV("TOP")
					QuestObjectivesOrDescription:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
					QuestObjectivesOrDescription:SetHeight(0)  -- Auto height
					QuestObjectivesOrDescription:SetWordWrap(true)
					QuestObjectivesOrDescription:EnableMouse(true)

					QuestObjectivesOrDescription:SetScript("OnMouseDown", function(self, button)
						if button == "RightButton" then
							ShowQuestDropdown(self, questID)
							return
						-- Previous Blizzard call changed 2026.09.25: elseif button == "LeftButton" and not IsShiftKeyDown() then
						elseif button == "LeftButton" and not RQE.API.Client.IsShiftKeyDown() then
							OpenQuestLogToQuestDetails(questID)
							return
						else
							if RQE.searchedQuestID ~= nil then
								RQE.Buttons.ClearButtonPressed()
								return
							end
						end
					end)

					QuestLevelAndName:SetScript("OnMouseDown", function(self, button)
						if RQE.searchedQuestID ~= nil then
							RQE.Buttons.ClearButtonPressed()
						else
							-- Quest Details and Menu
							-- Previous Blizzard call changed 2026.09.25: if IsShiftKeyDown() and button == "LeftButton" then
							if RQE.API.Client.IsShiftKeyDown() and button == "LeftButton" then
								if RQE.db.profile.debugLevel == "INFO+" then
									if RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsMouseOver() then
										print("Not hovering over RQEQuestFrame!")
										return
									end
								end

								-- Untrack the quest
								-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(questID)
								RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID)
								RQE:ClearRQEQuestFrame()
							elseif button == "RightButton" then
								ShowQuestDropdown(self, questID)
								return
							-- Previous Blizzard call changed 2026.09.25: elseif button == "LeftButton" and not IsShiftKeyDown() then
							elseif button == "LeftButton" and not RQE.API.Client.IsShiftKeyDown() then
								OpenQuestLogToQuestDetails(questID)
								return
							end
						end
					end)

					-- Tooltip on mouseover
					QuestLevelAndName:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT", -50, -40)
						GameTooltip:SetMinimumWidth(350)
						GameTooltip:SetHeight(0)
						GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
						GameTooltip:SetText(info.title)

						GameTooltip:AddLine(" ")

						-- Add description
						-- Previous Blizzard call changed 2026.09.25: local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
						local questLogIndex = RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
						if questLogIndex then
							-- Previous Blizzard call changed 2026.09.25: local _, questObjectives = GetQuestLogQuestText(questLogIndex)
							local _, questObjectives = RQE.API.Client.GetQuestLogQuestText(questLogIndex)
							local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
							GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
						end

						-- Add Direction Text
						-- Previous Blizzard call changed 2026.09.25: local directionText = C_QuestLog.GetNextWaypointText(questID)
						local directionText = RQE.API.Client.C_QuestLog.GetNextWaypointText(questID)
						if RQE.db.profile.debugLevel == "INFO+" then
							RQE.infoLog("Debug - QuestID:", questID, "Direction Text:", directionText)
						end
						if directionText and directionText ~= "" then
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine("Next Step: " .. directionText, 0.81, 0.5, 1, true)
							GameTooltip:AddLine(" ")
						else
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine("Next Step: [No additional information]", 0.81, 0.5, 1, true)
							GameTooltip:AddLine(" ")
						end

						if questID then
							-- Check if the quest is ready to be turned in
							-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.ReadyForTurnIn(questID) then
							if RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID) then
								GameTooltip:AddLine("Status: Ready for Turn In", 1, 1, 0) -- Yellow color for ready to turn in
							-- Check if the quest is completed
							-- Previous Blizzard call changed 2026.09.25: elseif C_QuestLog.IsQuestFlaggedCompleted(questID) then
							elseif RQE.API.Client.C_QuestLog.IsQuestFlaggedCompleted(questID) then
								GameTooltip:AddLine("Status: Completed", 0, 1, 0) -- Green color for completed
								-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
								if RQE.API.Client.C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
									GameTooltip:AddLine("Status: Completed on Warband", 0, 1, 0) -- Green color for completed on warband & character
								else
									GameTooltip:AddLine("Status: Not Completed on Warband or repeatable", 1, 0, 0) -- Red color for not completed on warband
								end
							else
								GameTooltip:AddLine("Status: Not Completed", 1, 0, 0) -- Red color for not completed
								-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
								if RQE.API.Client.C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
									GameTooltip:AddLine("Status: Completed on Warband", 1, 1, 0) -- Yellow color for completed on warband
								else
									GameTooltip:AddLine("Status: Not Completed on Warband or repeatable", 1, 0, 0) -- Red color for not completed on warband
								end
							end
							GameTooltip:AddLine(" ")
						end

						-- Add objectives
						if objectivesText and objectivesText ~= "" then
							GameTooltip:AddLine("Objectives:")

							local colorizedObjectives = colorizeObjectives(questID)
							GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
							GameTooltip:AddLine(" ")
						end

						-- Add Rewards
						RQE:QuestRewardsTooltip(GameTooltip, questID)

						-- Party Members' Quest Progress
						-- Previous Blizzard call changed 2026.09.25: if IsInGroup() then
						if RQE.API.Client.IsInGroup() then
							-- Previous Blizzard call changed 2026.09.25: if IsInRaid() then return end
							if RQE.API.Client.IsInRaid() then return end
							-- Previous Blizzard call changed 2026.09.25: local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
							local tooltipData = RQE.API.Client.C_TooltipInfo.GetQuestPartyProgress(questID)
							if tooltipData and tooltipData.lines then
								-- Previous Blizzard call changed 2026.09.25: local player_name = UnitName("player")
								local player_name = RQE.API.Client.UnitName("player")
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
					end)

					QuestObjectivesOrDescription:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT", -50, -40)
						GameTooltip:SetMinimumWidth(350)
						GameTooltip:SetHeight(0)
						GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
						GameTooltip:SetText(info.title)

						GameTooltip:AddLine(" ")

						-- Add description
						-- Previous Blizzard call changed 2026.09.25: local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
						local questLogIndex = RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
						if questLogIndex then
							-- Previous Blizzard call changed 2026.09.25: local _, questObjectives = GetQuestLogQuestText(questLogIndex)
							local _, questObjectives = RQE.API.Client.GetQuestLogQuestText(questLogIndex)
							local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
							GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
						end

						-- Add Direction Text
						-- Previous Blizzard call changed 2026.09.25: local directionText = C_QuestLog.GetNextWaypointText(questID)
						local directionText = RQE.API.Client.C_QuestLog.GetNextWaypointText(questID)
						if RQE.db.profile.debugLevel == "INFO+" then
							RQE.infoLog("Debug - QuestID:", questID, "Direction Text:", directionText)  -- Debug print
						end
						if directionText and directionText ~= "" then
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine("Next Step: " .. directionText, 0.81, 0.5, 1, true)
							GameTooltip:AddLine(" ")
						else
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine("Next Step: [No additional information]", 0.81, 0.5, 1, true)
							GameTooltip:AddLine(" ")
						end

						if questID then
							-- Check if the quest is ready to be turned in
							-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.ReadyForTurnIn(questID) then
							if RQE.API.Client.C_QuestLog.ReadyForTurnIn(questID) then
								GameTooltip:AddLine("Status: Ready for Turn In", 1, 1, 0) -- Yellow color for ready to turn in
							-- Check if the quest is completed
							-- Previous Blizzard call changed 2026.09.25: elseif C_QuestLog.IsQuestFlaggedCompleted(questID) then
							elseif RQE.API.Client.C_QuestLog.IsQuestFlaggedCompleted(questID) then
								GameTooltip:AddLine("Status: Completed", 0, 1, 0) -- Green color for completed
								-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
								if RQE.API.Client.C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
									GameTooltip:AddLine("Status: Completed on Warband", 0, 1, 0) -- Green color for completed on warband & character
								else
									GameTooltip:AddLine("Status: Not Completed on Warband or repeatable", 1, 0, 0) -- Red color for not completed on warband
								end
							else
								GameTooltip:AddLine("Status: Not Completed", 1, 0, 0) -- Red color for not completed
								-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
								if RQE.API.Client.C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
									GameTooltip:AddLine("Status: Completed on Warband", 1, 1, 0) -- Yellow color for completed on warband
								else
									GameTooltip:AddLine("Status: Not Completed on Warband or repeatable", 1, 0, 0) -- Red color for not completed on warband
								end
							end
							GameTooltip:AddLine(" ")
						end

						-- Add objectives
						if objectivesText and objectivesText ~= "" then
							GameTooltip:AddLine("Objectives:")

							local colorizedObjectives = colorizeObjectives(questID)
							GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
							GameTooltip:AddLine(" ")
						end

						-- Add Rewards
						RQE:QuestRewardsTooltip(GameTooltip, questID)

						-- Party Members' Quest Progress
						-- Previous Blizzard call changed 2026.09.25: if IsInGroup() then
						if RQE.API.Client.IsInGroup() then
							-- Previous Blizzard call changed 2026.09.25: if IsInRaid() then return end
							if RQE.API.Client.IsInRaid() then return end
							GameTooltip:AddLine(" ")
							-- Previous Blizzard call changed 2026.09.25: local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
							local tooltipData = RQE.API.Client.C_TooltipInfo.GetQuestPartyProgress(questID)
							if tooltipData and tooltipData.lines then
								-- Previous Blizzard call changed 2026.09.25: local player_name = UnitName("player")
								local player_name = RQE.API.Client.UnitName("player")
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
					end)

					-- Moved this block of code after the creation of QuestLevelAndName and QuestObjectivesOrDescription
					if QuestLevelAndName and QuestObjectivesOrDescription then
						local questLevelAndNameHeight = QuestLevelAndName:GetStringHeight()
						local questObjectivesOrDescriptionHeight = QuestObjectivesOrDescription:GetStringHeight()
					end

					local objectiveFallback = objectivesText and objectivesText ~= ""
						and colorizeObjectives(questID) or questObjectivesText
					local objectiveLastElement = RQE.ApplyTrackerObjectiveDisplay(
						QuestLogIndexButton, questID, QuestObjectivesOrDescription,
						parentFrame, objectiveFallback)

					-- A progress bar, when present, becomes the row bottom so the next
					-- quest and the following category header reserve its full height.
					if isCampaignQuest then
						lastCampaignElement = objectiveLastElement
					else
						lastQuestElement = objectiveLastElement
					end

					-- Save the FontString in a table for future reference
					RQE.QuestLogIndexButtons[i].QuestObjectivesOrDescription = QuestObjectivesOrDescription

					-- Show the label
					QuestObjectivesOrDescription:Show()

					-- Save the FontString in a table for future reference
					RQE.QuestLogIndexButtons[i].QuestLevelAndName = QuestLevelAndName

					-- Show the labels
					QuestLevelAndName:Show()

					-- Save the button in the table for future reference
					QuestLogIndexButton:Show()

					-- Update lastQuestObjectivesOrDescription for the next iteration
					lastQuestObjectivesOrDescription = objectiveLastElement

					local elementHeight = QuestLogIndexButton:GetHeight()
					totalHeight = totalHeight + elementHeight + spacingBetweenElements
				end
			end
		end

		-- Normal and Campaign frames used fixed estimated heights. Resize them to
		-- their final rendered rows so the next visible section does not inherit
		-- unused vertical space.
		local function ResizeQuestSectionToContent(sectionFrame, lastElement)
			if not lastElement then
				return
			end

			local frameTop = sectionFrame:GetTop()
			local elementBottom = lastElement:GetBottom()
			if frameTop and elementBottom then
				sectionFrame._rqeRenderedHeight = math.max(80, frameTop - elementBottom + GetQuestSectionBottomPadding())
				sectionFrame:SetHeight(sectionFrame._rqeRenderedHeight)
			elseif sectionFrame._rqeRenderedHeight then
				sectionFrame:SetHeight(sectionFrame._rqeRenderedHeight)
			end
		end

		ResizeQuestSectionToContent(RQE.CampaignFrame, lastCampaignElement)
		ResizeQuestSectionToContent(RQE.QuestsFrame, lastQuestElement)

		-- Add Bonus Quests to their dedicated frame. The existing BQ renderer is unchanged.
		RQE.ClearBonusQuestElements() -- Clear existing bonus quest elements
		local lastBonusQuestElement = nil
		if type(bonusQuests) == "table" then
			for _, bonusQuest in ipairs(bonusQuests) do
				lastBonusQuestElement = RQE.AddBonusQuestToFrame(RQE.BonusQuestsFrame, lastBonusQuestElement, bonusQuest.questID, bonusQuest.title)
				RQE.OkayCheckBonusQuests = false
			end
		end
		RQE.BonusQuestsFrame.questCount = RQE.bonusQuestCount

		-- Size the section to the final rendered objective instead of reserving a
		-- fixed amount of unused space below short Bonus Quest rows.
		local bonusFrameHeight = 80
		if lastBonusQuestElement then
			local frameTop = RQE.BonusQuestsFrame:GetTop()
			local objectiveBottom = lastBonusQuestElement:GetBottom()
			if frameTop and objectiveBottom then
				bonusFrameHeight = math.max(80, frameTop - objectiveBottom + GetQuestSectionBottomPadding())
			end
		end
		RQE.BonusQuestsFrame:SetHeight(bonusFrameHeight)

		-- Check if any of the child frames should have their visibility removed as no quests being tracked
		RQE.CampaignFrame:SetShown(RQE.campaignQuestCount > 0)
		RQE.QuestsFrame:SetShown(RQE.regularQuestCount > 0)
		RQE.WorldQuestsFrame:SetShown(RQE.worldQuestCount > 0)
		RQE.BonusQuestsFrame:SetShown(RQE.bonusQuestCount > 0)

		-- After adding all quest items, update the total height of the content frame
		content:SetHeight(totalHeight)

		-- Call the function to reposition child frames again at the end
		UpdateFrameAnchors()
		UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
		UpdateHeader(RQE.CampaignFrame, "Campaign/Meta", RQE.campaignQuestCount)
		UpdateHeader(RQE.QuestsFrame, "Normal Quests", RQE.regularQuestCount)
		UpdateHeader(RQE.WorldQuestsFrame, "World Quests", RQE.worldQuestCount)
		UpdateHeader(RQE.BonusQuestsFrame, "Bonus Quests", RQE.bonusQuestCount)

		-- Visibility Update Check for RQEQuestFrame
		UpdateRQEWorldQuestFrame()
		UpdateRQETaskQuestFrame()
		RQE.RefreshQuestTrackerScrollRange()
		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0, RQE.RefreshQuestTrackerScrollRange)
		RQE.API.Client.C_Timer.After(0, RQE.RefreshQuestTrackerScrollRange)
	end


	-------------------------------------------------------
	-- #11i. World Quest Rendering
	-------------------------------------------------------

	-- Function to update the RQE.WorldQuestFrame with tracked World Quests
	function UpdateRQEWorldQuestFrame()
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			RQE.RunUpdateRQEWorldQuestFrame = true
			return
		end

		-- Define padding value
		local padding = GetQuestSectionBottomPadding()
		local yOffset = -45 -- Y offset for the first element

		-- Get the player's current map ID
		-- Previous Blizzard call changed 2026.09.25: local currentMapID = C_Map.GetBestMapForUnit("player") -- Get the player's current map ID
		local currentMapID = RQE.API.Client.C_Map.GetBestMapForUnit("player") -- Get the player's current map ID

		-- Gather and sort World Quests by proximity
		local sortedWorldQuests = GatherAndSortWorldQuestsByProximity()

		-- Hide all existing World Quest buttons first
		for i = 1, 50 do -- Assuming player won't have more than 50 World Quests tracked at once
			local button = RQE.WorldQuestsFrame["WQButton" .. i]
			if button then
				button:Hide()
				button.WQuestLevelAndName:Hide()
				button.QuestObjectivesOrDescription:Hide()
				if button.RQEProgressBar then button.RQEProgressBar:Hide() end
			end
		end

		-- Get the number of tracked World Quests
		-- Previous Blizzard call changed 2026.09.25: local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
		local numTrackedWorldQuests = RQE.API.Client.C_QuestLog.GetNumWorldQuestWatches()
		local numTrackedBonusQuests = 0
		local lastWorldQuestElement = nil
		local usedQuestIDs = {}  -- Table to keep track of used quest IDs

		-- Loop through sorted quests to count bonus quests
		for _, questInfo in ipairs(sortedWorldQuests) do
			if questInfo.type == "BQ" then
				numTrackedBonusQuests = numTrackedBonusQuests + 1
			end
		end

		-- Total quests to be tracked
		local totalTrackedQuests = numTrackedWorldQuests --+ numTrackedBonusQuests
		RQE.numTrackedBonusQuests = numTrackedBonusQuests

		-- Ensure the frame is visible if there are any tracked quests
		if totalTrackedQuests > 0 then
			RQE.WorldQuestsFrame:Show()
		else
			RQE.WorldQuestsFrame:Hide()
			RQE.RefreshQuestTrackerScrollRange()
			return -- Exit early if no quests to display
		end

		-- Loop through each tracked World Quest or Bonus Objective
		for i, questInfo in ipairs(sortedWorldQuests) do
			local questID = questInfo.questID
			local button = RQE.WorldQuestsFrame["WQButton" .. questID]
			local isSuperTracked = RQE.API.GetSuperTrackedQuestID() == questID

			-- Ensure questID is valid
			if questID then
				-- Retrieve or initialize the WQuestLogIndexButton for the current questID
				local WQuestLogIndexButton = RQE.WorldQuestsFrame["WQButton" .. questID] or CreateFrame("Button", "WQButton" .. questID, RQE.WorldQuestsFrame)	-- TAINT?: possibly source if run in combat
				RQE.WorldQuestsFrame["WQButton" .. questID] = WQuestLogIndexButton
				WQuestLogIndexButton:SetSize(TRACKER_QUEST_BUTTON_SIZE, TRACKER_QUEST_BUTTON_SIZE)

				-- Ensure the button always has the correct background texture based on its tracking state
				local bg = WQuestLogIndexButton.bg or WQuestLogIndexButton:CreateTexture(nil, "BACKGROUND")
				WQuestLogIndexButton.bg = bg
				bg:SetAllPoints()
				if isSuperTracked then
					bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
				else
					bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
				end

				WQuestLogIndexButton:Show()

				-- Create or update the number label
				local WQnumber = WQuestLogIndexButton.number or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
				WQnumber:SetPoint("CENTER", WQuestLogIndexButton, "CENTER")
				WQnumber:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				WQnumber:SetTextColor(1, 0.7, 0.2)

				local isWorldQuest = RQE.API.IsWorldQuest(questID)
				-- Previous Blizzard call changed 2026.09.25: local isBonusQuest = C_QuestLog.IsQuestTask(questID) or C_QuestLog.IsThreatQuest(questID)
				local isBonusQuest = RQE.API.Client.C_QuestLog.IsQuestTask(questID) or RQE.API.Client.C_QuestLog.IsThreatQuest(questID)

				if isWorldQuest then
					WQnumber:SetText("WQ")
				end

				WQuestLogIndexButton.number = WQnumber
				if RQE.UI then RQE.UI:StyleQuestIndexButton(WQuestLogIndexButton, isSuperTracked, "World") end

				-- Set flag to check if correct macro
				if RQE.RQEQuestFrame then
					WQuestLogIndexButton:SetScript("OnEnter", function()
						RQE.hoveringOnFrame = true
					end)
				end

				-- Hide tooltip for the RQEQuestFrame when moving out of the frame
				if RQE.RQEQuestFrame then
					WQuestLogIndexButton:SetScript("OnLeave", function()
						GameTooltip:Hide()
						RQE.hoveringOnFrame = false
					end)
				end

				-- Modify the OnClick event
				WQuestLogIndexButton:SetScript("OnClick", function(self, button)
					RQE.OkaytoUpdateCreateSteps = true
					RQE.AllFramesShouldUpdate = true
					-- Previous Blizzard call changed 2026.09.25: if IsShiftKeyDown() and button == "LeftButton" then
					if RQE.API.Client.IsShiftKeyDown() and button == "LeftButton" then
						-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveWorldQuestWatch(questID)
						RQE.API.Client.C_QuestLog.RemoveWorldQuestWatch(questID)
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Removing world quest watch for quest: " .. questID)
						end

						local extractedQuestID
						if RQE.QuestIDText and RQE.QuestIDText:GetText() then
							extractedQuestID = RQE.DisplayedQuestID
						end

						if questID == extractedQuestID then
							RQE:ClearFrameData()
							RQE:ClearWaypointButtonData()
						end

						RQE.TrackedQuests[questID] = nil
						UpdateRQEWorldQuestFrame()
					else
						if RQE.hoveringOnFrame then
							RQE.shouldCheckFinalStep = true
							RQE.CheckAndSetFinalStep()
						end

						RQE.ObtainSuperTrackQuestDetails()

						local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()
						RQE:PerformClearActions()
						RQEMacro:ClearMacroContentByName("RQE Macro")
						RQE.LastClickedIdentifier = nil
						RQE.ScrollFrameToTop()
						RQE.LastClickedButtonRef = RQE.WaypointButtons[1]
						RQE.ManualSuperTrack = true
						-- Previous Blizzard call changed 2026.09.25: C_SuperTrack.SetSuperTrackedQuestID(questID)
						RQE.API.Client.C_SuperTrack.SetSuperTrackedQuestID(questID)
						RQE:SaveSuperTrackedQuestToCharacter()
						RQE.ManualSuperTrackedQuestID = questID
						RQE.ManuallyTrackedQuests[questID] = true

						-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1, function()
						RQE.API.Client.C_Timer.After(1, function()
							local questData = RQE.getQuestData(questID)
							if not questData then
								RQE.debugLog("Quest data not found for questID:", questID)
								return
							end

							local waypointButton = RQE.LastClickedWaypointButton
							if waypointButton and waypointButton.stepIndex then
								local stepData = questData[waypointButton.stepIndex]
								if stepData and stepData.macro then
									local macroCommands = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro
									RQEMacro:SetQuestStepMacro(questID, waypointButton.stepIndex, macroCommands, false)
								end
							end
						end)

						RQE:ClearRQEQuestFrame()
						UpdateRQEQuestFrame()

						-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1, function()
						RQE.API.Client.C_Timer.After(1, function()
							RQE.Buttons.UpdateMagicButtonVisibility()
						end)
					end
				end)

				-- Fetch Quest Title with error handling
				local questTitle = RQE.API.GetTitleForQuestID(questID)
				if not questTitle or questTitle == "" then
					questTitle = "Unknown Quest"
				end

				local WQuestLevelAndName = WQuestLogIndexButton.WQuestLevelAndName or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				WQuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
				WQuestLevelAndName:SetHeight(0)
				WQuestLevelAndName:SetJustifyH("LEFT")
				WQuestLevelAndName:SetJustifyV("TOP")
				WQuestLevelAndName:SetWidth(RQE.RQEQuestFrame:GetWidth() - 100)

				if RQE.API.IsWorldQuest(questID) then
					WQuestLevelAndName:SetText("|cFFFFD700[WQ] " .. questTitle .. "|r") -- Gold color for World Quests
				else
					WQuestLevelAndName:SetText("|cFFFFA500[UQ] Unknown Quest|r") -- Orange or any other color for Unknown Quests
				end

				WQuestLogIndexButton.WQuestLevelAndName = WQuestLevelAndName

				-- Create QuestObjectives label
				local WQuestObjectives = WQuestLogIndexButton.QuestObjectives or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				WQuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				WQuestObjectives:SetWordWrap(true)
				WQuestObjectives:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
				WQuestObjectives:SetHeight(0)
				WQuestObjectives:SetJustifyH("LEFT")
				WQuestObjectives:SetJustifyV("TOP")
				RQE.WQuestObjectives = WQuestObjectives
				WQuestLogIndexButton.QuestObjectives = WQuestObjectives

				-- Fetch and set the objectives text from the quest log
				local objectivesTable = RQE.API.GetQuestObjectives(questID)
				local objectivesText = objectivesTable and "" or "No objectives available."
				if objectivesTable then
					for _, objective in pairs(objectivesTable) do
						objectivesText = objectivesText .. objective.text .. "\n"
					end
				end

				-- Apply colorization to objectivesText. Progress-bar objectives are
				-- converted after this label receives its final anchor below distance.
				objectivesText = RQE.colorizeObjectives(questID)
				WQuestObjectives:SetText(objectivesText)

				-- Untrack World Quest
				WQuestLevelAndName:SetScript("OnMouseDown", function(self, button)
					-- Previous Blizzard call changed 2026.09.25: if IsShiftKeyDown() and button == "LeftButton" then
					if RQE.API.Client.IsShiftKeyDown() and button == "LeftButton" then
						-- Untrack the quest
						-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(questID)
						RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID)
						RQE:ClearRQEQuestFrame()
					elseif button == "RightButton" then
						ShowQuestDropdown(self, questID)
					end
				end)

				-- Position WQuestLogIndexButton relative to WQuestLevelAndName
				AnchorTrackerQuestButton(WQuestLogIndexButton, WQuestLevelAndName)

				-- Function to format time left based on seconds
				local function FormatTimeLeft(secondsLeft)
					if not secondsLeft then return "No time left info" end
					local days = math.floor(secondsLeft / (24 * 60 * 60))
					local hours = math.floor((secondsLeft % (24 * 60 * 60)) / (60 * 60))
					local minutes = math.floor((secondsLeft % (60 * 60)) / 60)
					local seconds = secondsLeft % 60

					local timeStrings = {}
					if days > 0 then table.insert(timeStrings, days .. " days") end
					if hours > 0 then table.insert(timeStrings, hours .. " hours") end
					if minutes > 0 or (days == 0 and hours == 0) then
						table.insert(timeStrings, minutes .. " min")
					end
					if secondsLeft < 60 then
						table.insert(timeStrings, seconds .. " sec")
					end

					return table.concat(timeStrings, ", ")
				end

				local WQuestTimeLeft = WQuestLogIndexButton.WQuestTimeLeft or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				WQuestTimeLeft:SetPoint("TOPLEFT", WQuestLevelAndName, "BOTTOMLEFT", 0, -5)
				WQuestTimeLeft:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				WQuestTimeLeft:SetTextColor(0.98, 0.5, 0.45)  -- Set the text color to Salmon
				WQuestTimeLeft:SetJustifyH("LEFT")
				WQuestLogIndexButton.WQuestTimeLeft = WQuestTimeLeft

				-- Get the time left for the World Quest
				-- Previous Blizzard call changed 2026.09.25: local secondsLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
				local secondsLeft = RQE.API.Client.C_TaskQuest.GetQuestTimeLeftSeconds(questID)
				local timeLeftString = FormatTimeLeft(secondsLeft)  -- Ensure it always returns a string
				WQuestTimeLeft:SetText(timeLeftString)
				WQuestTimeLeft:Show()

				-- Previous Blizzard call changed 2026.09.25: local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
				local distanceSq, onContinent = RQE.API.Client.C_QuestLog.GetDistanceSqToQuest(questID)
				RQE.debugLog("DEBUG: Processing QuestID:", questID, "OnContinent:", onContinent, "DistanceSq:", distanceSq)
				local questDistanceText = "Distance: N/A"  -- Default text if distance is not available

				if distanceSq then  -- This condition now checks only for a valid distanceSq value
					local distance = math.sqrt(distanceSq)
					questDistanceText = string.format("Distance: %.2f", distance)
					RQE.debugLog("DEBUG: questDistance is " .. questDistanceText .. " for questID " .. questID)
				end

				-- Create or update the distance label
				local WQuestDistance = WQuestLogIndexButton.WQuestDistance or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				WQuestDistance:SetPoint("TOPLEFT", WQuestTimeLeft, "BOTTOMLEFT", 0, -5)
				WQuestDistance:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				WQuestDistance:SetJustifyH("LEFT")
				WQuestDistance:SetText(questDistanceText)
				WQuestLogIndexButton.WQuestDistance = WQuestDistance
				WQuestDistance:Show()

				-- Create QuestObjectivesOrDescription label
				local WQuestObjectivesOrDescription = WQuestLogIndexButton.QuestObjectivesOrDescription or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				WQuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				WQuestObjectivesOrDescription:SetJustifyH("LEFT")
				WQuestObjectivesOrDescription:SetJustifyV("TOP")
				WQuestObjectivesOrDescription:SetHeight(0)
				WQuestObjectivesOrDescription:SetWordWrap(true)
				WQuestObjectivesOrDescription:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
				WQuestLogIndexButton.QuestObjectivesOrDescription = WQuestObjectivesOrDescription

				WQuestObjectivesOrDescription:SetScript("OnMouseDown", function(self, button)
					if button == "RightButton" then
						ShowQuestDropdown(self, questID)
					end
				end)

				-- Set position of the WQuestObjectives based on TimeLeft
				WQuestObjectives:SetPoint("TOPLEFT", WQuestDistance, "BOTTOMLEFT", 0, -5)
				local worldObjectiveLastElement = RQE.ApplyTrackerObjectiveDisplay(
					WQuestLogIndexButton, questID, WQuestObjectives,
					RQE.WorldQuestsFrame, objectivesText)

				-- Untrack World Quest
				WQuestLogIndexButton:SetScript("OnMouseDown", function(self, button)
					RQE.OkaytoUpdateCreateSteps = true
					RQE.AllFramesShouldUpdate = true
					-- Previous Blizzard call changed 2026.09.25: if IsShiftKeyDown() and button == "LeftButton" then
					if RQE.API.Client.IsShiftKeyDown() and button == "LeftButton" then
						-- Previous Blizzard call changed 2026.09.25: C_QuestLog.RemoveQuestWatch(questID)
						RQE.API.Client.C_QuestLog.RemoveQuestWatch(questID)
					end
				end)

				-- Positioning logic for WQuestLevelAndName
				WQuestLevelAndName:ClearAllPoints()
				if i == 1 then
					-- If this is the first world quest, position it at the top left of the frame
					WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", GetTrackerQuestLabelInset(), yOffset)
				else
					-- For the second and subsequent world quests, position them relative to the last world quest element
					if lastWorldQuestElement then
						WQuestLevelAndName:SetPoint("TOPLEFT", lastWorldQuestElement, "BOTTOMLEFT", 0, -padding)
					else
						-- Fallback to the top left position if for some reason the last element doesn't exist
						-- This should not happen if player's world quest elements are handled correctly
						WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", GetTrackerQuestLabelInset(), yOffset - (i * padding))
					end
				end

				-- Show the elements
				WQuestLevelAndName:Show()
				WQuestObjectivesOrDescription:Show()
				WQuestLogIndexButton:Show()
				WQuestObjectives:Show()

				lastWorldQuestElement = worldObjectiveLastElement

				-- Set the mouseover tooltip for the World Quest button
				WQuestLevelAndName:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR")  -- Anchor the tooltip to the cursor
					GameTooltip:ClearLines()

					-- Add the quest title
					GameTooltip:AddLine(questTitle)
					GameTooltip:AddLine(" ")  -- Blank line

					-- Add description
					-- Previous Blizzard call changed 2026.09.25: local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
					local questLogIndex = RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
					if questLogIndex then
						-- Previous Blizzard call changed 2026.09.25: local _, questObjectives = GetQuestLogQuestText(questLogIndex)
						local _, questObjectives = RQE.API.Client.GetQuestLogQuestText(questLogIndex)
						local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
						GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
						GameTooltip:AddLine(" ")
					end

					-- Add objectives
					-- Previous Blizzard call changed 2026.09.25: local objectivesText = GetQuestLogQuestText(C_QuestLog.GetLogIndexForQuestID(questID))
					local objectivesText = RQE.API.Client.GetQuestLogQuestText(RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID))
					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(questID)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
						GameTooltip:AddLine(" ")
					end

					-- Add Rewards
					RQE:QuestRewardsTooltip(GameTooltip, questID)

					-- Add time left
					-- Previous Blizzard call changed 2026.09.25: local timeLeftString = FormatTimeLeft(C_TaskQuest.GetQuestTimeLeftSeconds(questID))  -- Make sure FormatTimeLeft function is defined as previously described
					local timeLeftString = FormatTimeLeft(RQE.API.Client.C_TaskQuest.GetQuestTimeLeftSeconds(questID))  -- Make sure FormatTimeLeft function is defined as previously described
					if timeLeftString and timeLeftString ~= "" then
						GameTooltip:AddLine("Time Left: " .. timeLeftString, 1, 0.08, 0.58) -- Pink color
						GameTooltip:AddLine(" ")  -- Blank line
					end

					-- Add the quest ID
					GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82)  -- Aquamarine color

					GameTooltip:Show()
				end)

				-- Party Members' Quest Progress
				-- Previous Blizzard call changed 2026.09.25: if IsInGroup() then
				if RQE.API.Client.IsInGroup() then
					-- Previous Blizzard call changed 2026.09.25: if IsInRaid() then return end
					if RQE.API.Client.IsInRaid() then return end
					GameTooltip:AddLine(" ")
					-- Previous Blizzard call changed 2026.09.25: local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
					local tooltipData = RQE.API.Client.C_TooltipInfo.GetQuestPartyProgress(questID)
					if tooltipData and tooltipData.lines then
						-- Previous Blizzard call changed 2026.09.25: local player_name = UnitName("player")
						local player_name = RQE.API.Client.UnitName("player")
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

				WQuestLevelAndName:SetScript("OnLeave", function(self)
					GameTooltip:Hide()  -- Hide the tooltip when the mouse leaves the button
				end)

				-- Save the button in a table for future reference
				RQE.WorldQuestsFrame["WQButton" .. i] = WQuestLogIndexButton

			end
		end

		-- Size the section once every row has been laid out.  Resizing inside the
		-- loop can measure a stale row position and leave the next section anchored
		-- below the old estimated World Quests height.
		local function ResizeWorldQuestSection()
			if not lastWorldQuestElement or not lastWorldQuestElement:IsShown() then
				return
			end

			local frameTop = RQE.WorldQuestsFrame:GetTop()
			local rowBottom = lastWorldQuestElement:GetBottom()
			if not frameTop or not rowBottom then
				return
			end

			local measuredHeight = math.max(80, frameTop - rowBottom + padding)
			RQE.WorldQuestsFrame.lastMeasuredHeight = measuredHeight
			RQE.WorldQuestsFrame:SetHeight(measuredHeight)
			UpdateFrameAnchors()
		end

		ResizeWorldQuestSection()
		-- Font-string bounds can settle on the following frame after a quest title
		-- or objective wraps.  Recheck then so the Bonus Quests header always
		-- follows the real bottom of the World Quests row.
		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0, ResizeWorldQuestSection)
		RQE.API.Client.C_Timer.After(0, ResizeWorldQuestSection)
		RQE.RefreshQuestTrackerScrollRange()
	end


	-------------------------------------------------------
	-- #11j. Task Quest Rendering
	-------------------------------------------------------

	-- Clears only rows created for the Task Quests section.
	function RQE:ClearTaskQuestElements()
		for _, element in ipairs(RQE.TaskQuestElements or {}) do
			if element then
				element:Hide()
				element:ClearAllPoints()
				element:SetParent(nil)
			end
		end
		RQE.TaskQuestElements = {}
	end

	-- Shows a dedicated Task Quests section without reusing Bonus Quest or World Quest UI.
	function UpdateRQETaskQuestFrame()
		local taskFrame = RQE.TaskQuestsFrame
		if not taskFrame then return end
		local managedLayout = RQE.UsesManagedTrackerSectionLayout and RQE:UsesManagedTrackerSectionLayout()

		local taskQuests = RQE:GetActiveTrackedTaskQuests()
		RQE:ClearTaskQuestElements()
		taskFrame.questCount = #taskQuests
		local taskTitle = "Task Quests (" .. taskFrame.questCount .. ")"
		if RQE.RefreshTrackerSectionHeaderText then
			RQE:RefreshTrackerSectionHeaderText(taskFrame, taskTitle)
		else
			taskFrame.header:SetText(taskTitle)
		end

		if taskFrame.questCount == 0 then
			taskFrame:Hide()
			if not managedLayout and RQE.AchievementsFrame and RQE.BonusQuestsFrame and RQE.BonusQuestsFrame:IsShown() then
				RQE.AchievementsFrame:ClearAllPoints()
				RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.BonusQuestsFrame, "BOTTOMLEFT", 0, -15)
			end
			RQE.UpdateRecipeTrackingAnchor()
			RQE.RefreshQuestTrackerScrollRange()
			return
		end

		taskFrame:Show()
		if managedLayout then
			RQE:ApplyTrackerSectionOrder()
		else
		taskFrame:ClearAllPoints()
		if RQE.BonusQuestsFrame and RQE.BonusQuestsFrame:IsShown() then
			taskFrame:SetPoint("TOPLEFT", RQE.BonusQuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.WorldQuestsFrame:IsShown() then
			taskFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.QuestsFrame:IsShown() then
			taskFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.CampaignFrame:IsShown() then
			taskFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
		elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
			taskFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
		else
			taskFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		end
		end

		local lastElement
		for _, taskQuest in ipairs(taskQuests) do
			local questID = taskQuest.questID
			local button = CreateFrame("Button", nil, taskFrame)
			button:SetSize(TRACKER_QUEST_BUTTON_SIZE, TRACKER_QUEST_BUTTON_SIZE)

			local background = button:CreateTexture(nil, "BACKGROUND")
			background:SetAllPoints()
			background:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")

			local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			buttonText:SetPoint("CENTER")
			buttonText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			buttonText:SetTextColor(1, 0.82, 0)
			buttonText:SetText("TQ")

			local title = taskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			title:SetTextColor(137 / 255, 95 / 255, 221 / 255)
			title:SetWidth(RQE.RQEQuestFrame:GetWidth() - 100)
			title:SetJustifyH("LEFT")
			title:SetWordWrap(true)
			title:SetText("|cFF00CCFF[TQ] " .. taskQuest.title .. "|r")

			if lastElement then
				title:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -15)
			else
				title:SetPoint("TOPLEFT", taskFrame, "TOPLEFT", GetTrackerQuestLabelInset(), -40)
			end
			AnchorTrackerQuestButton(button, title)

			local objectives = taskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			objectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			objectives:SetWidth(RQE.RQEQuestFrame:GetWidth() - 110)
			objectives:SetJustifyH("LEFT")
			objectives:SetWordWrap(true)
			objectives:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
			local taskObjectivesText = RQE.colorizeObjectives(questID) or ""
			objectives:SetText(taskObjectivesText)
			local taskObjectiveLastElement = RQE.ApplyTrackerObjectiveDisplay(
				button, questID, objectives, taskFrame, taskObjectivesText)

			button:RegisterForClicks("LeftButtonUp")
			button:SetScript("OnClick", function()
				RQE.ManualSuperTrack = "TQ"
				RQE.ManualSuperTrackedQuestID = questID
				RQE.DisplayedQuestID = questID
				RQE.ManuallyTrackedQuests = RQE.ManuallyTrackedQuests or {}
				RQE.ManuallyTrackedQuests[questID] = true
				-- Previous Blizzard call changed 2026.09.25: C_SuperTrack.SetSuperTrackedQuestID(questID)
				RQE.API.Client.C_SuperTrack.SetSuperTrackedQuestID(questID)

				local questData = RQE.getQuestData(questID)
				if questData then
					local stepsText, coordsText, mapIDs = PrintQuestStepsToChat(questID)
					UpdateFrame(questID, questData, stepsText, coordsText, mapIDs)
				end
			end)

			table.insert(RQE.TaskQuestElements, button)
			table.insert(RQE.TaskQuestElements, title)
			table.insert(RQE.TaskQuestElements, objectives)
			if taskObjectiveLastElement ~= objectives then
				table.insert(RQE.TaskQuestElements, taskObjectiveLastElement)
			end
			lastElement = taskObjectiveLastElement
		end

		-- Size the Task Quests section to its final rendered objective so the
		-- Achievements section does not inherit unused vertical space.
		local taskFrameHeight = 80
		if lastElement then
			local frameTop = taskFrame:GetTop()
			local objectiveBottom = lastElement:GetBottom()
			if frameTop and objectiveBottom then
				taskFrameHeight = math.max(80, frameTop - objectiveBottom + GetQuestSectionBottomPadding())
			end
		end
		taskFrame:SetHeight(taskFrameHeight)

		-- Keep Achievements below the new section whenever it is visible.
		if not managedLayout and RQE.AchievementsFrame then
			RQE.AchievementsFrame:ClearAllPoints()
			RQE.AchievementsFrame:SetPoint("TOPLEFT", taskFrame, "BOTTOMLEFT", 0, -15)
		end
		RQE.UpdateRecipeTrackingAnchor()
		RQE.RefreshQuestTrackerScrollRange()
	end


	-------------------------------------------------------
	-- #11k. Quest Selection Automation
	-------------------------------------------------------

	-- Function that simulates a click of the QuestLogIndexButton
	function RQE.ClickQuestLogIndexButton(questID)
		-- Check if the player is in combat
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			RQE.QuestButtonToReClickAfterCombat = questID
			RQE.ReClickQuestLogIndexButtonAfterCombat = true
		end

		-- Ensure the table is initialized
		if not RQE.QuestLogIndexButtons then
			RQE.QuestLogIndexButtons = {}
		end

		local found = false
		for i, button in ipairs(RQE.QuestLogIndexButtons) do
			if button and button.questID == questID then
				if button:IsVisible() and button:IsEnabled() then
					button:Click()
					found = true
					break
				end
			end
		end

		if not found then
			RQE.debugLog("No button found for questID: " .. tostring(questID))
		end

		-- Tier Three Importance: CLICKQUESTLOGINDEXBUTTON function
		if RQE.db.profile.autoClickWaypointButton then
			-- Previous Blizzard call changed 2026.09.25: C_Timer.After(3, function()
			RQE.API.Client.C_Timer.After(3, function()
				RQE.isCheckingMacroContents = true
				local isMacroCorrect = RQE.CheckCurrentMacroContents()

				if isMacroCorrect then
					return
				end

				RQEMacro:CreateMacroForCurrentStep()
				-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.2, function()
				RQE.API.Client.C_Timer.After(0.2, function()
					RQE.isCheckingMacroContents = false
				end)
			end)
		end
	end


	-- Function that simulates a click of the UnknownQuestButton but streamlined
	function RQE.ClickRandomQuestLogIndexButton(bigQuestID)
		local randomQuestID = 81930
		-- Previous Blizzard call changed 2026.09.25: C_SuperTrack.SetSuperTrackedQuestID(randomQuestID)
		RQE.API.Client.C_SuperTrack.SetSuperTrackedQuestID(randomQuestID)

		RQE.ClickQuestLogIndexButton(randomQuestID)

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.2, function()
		RQE.API.Client.C_Timer.After(0.2, function()
			RQE.CheckAndClickWButton()
		end)

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.3, function()
		RQE.API.Client.C_Timer.After(0.3, function()
			RQE.ClickQuestLogIndexButton(bigQuestID)

			-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.2, function()
			RQE.API.Client.C_Timer.After(0.2, function()
				RQE.CheckAndClickWButton()
			end)
		end)
	end


	-------------------------------------------------------
	-- #11l. Secure Quest Item Buttons
	-------------------------------------------------------

	-- Create Special Quest Button for item/spell associated with tracked quest -- BUTTON IS CREATED BUT IS SECURECMD AND IMPROPERLY ANCHORED
	function RQE:CreateOrUpdateQuestItemButton(questID, questLogIndex, parent)
		-- Debug: print the inputs to the function
		print("Creating/updating quest item button for questID:", questID, "questLogIndex:", questLogIndex)

		-- Fetch the special quest item info using the correct quest log index
		-- Previous Blizzard call changed 2026.09.25: local itemLink, itemIcon, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
		local itemLink, itemIcon, charges, showItemWhenComplete = RQE.API.Client.GetQuestLogSpecialItemInfo(questLogIndex)
		if not itemLink then
			print("No item link found for questID:", questID, "questLogIndex:", questLogIndex)
			return
		end

		-- Debug: print the retrieved item link and icon
		print("Retrieved item link:", itemLink, "itemIcon:", itemIcon)

		-- Fetch detailed item info
		-- Previous Blizzard call changed 2026.09.25: local itemName, itemID = C_Item.GetItemInfo(itemLink)
		local itemName, itemID = RQE.API.Client.C_Item.GetItemInfo(itemLink)
		if not itemIcon then
			print("Item icon not found for questID:", questID, "questLogIndex:", questLogIndex)
			return
		end

		local buttonName = "RQEQuestItemButton" .. questID
		local itemButton = _G[buttonName]
		if not itemButton then
			print("Creating new item button:", buttonName)
			itemButton = CreateFrame("Button", buttonName, parent, "SecureActionButtonTemplate, ActionButtonTemplate")
			itemButton:SetSize(40, 40)
			itemButton:SetPoint("CENTER", parent, "CENTER", 0, 0)
			itemButton.icon = itemButton:CreateTexture(buttonName .. "Icon", "BACKGROUND")
			itemButton.icon:SetAllPoints()
			itemButton.icon:SetTexture(itemIcon)
			-- Set up the secure attributes for item usage
			itemButton:SetAttribute("type", "item")
			itemButton:SetAttribute("item", itemLink)
			-- Register the button for clicks
			itemButton:RegisterForClicks("AnyUp")
			itemButton:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(itemLink)
				GameTooltip:Show()
			end)
			itemButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)
			itemButton:SetScript("PreClick", function(self)
				-- Use the quest log special item function to ensure the correct usage
				-- Previous Blizzard call changed 2026.09.25: UseQuestLogSpecialItem(self:GetAttribute("questLogIndex"))
				RQE.API.Client.UseQuestLogSpecialItem(self:GetAttribute("questLogIndex"))
			end)
		else
			print("Updating existing item button:", buttonName)
			itemButton.icon:SetTexture(itemIcon)
			-- Update the secure attributes for item usage
			itemButton:SetAttribute("item", itemLink)
		end

		itemButton:SetAttribute("questLogIndex", questLogIndex)
		itemButton:Show()
		print("Button created or updated for questID:", questID, "questLogIndex:", questLogIndex, "with item:", itemName, itemLink)
	end


	-------------------------------------------------------
	-- #11m. World Quest Button Automation
	-------------------------------------------------------

	-- Functions to Force a Button Click
	function RQE:ClickWorldQuestButton(questID)
		local button = self.WorldQuestsFrame["WQButton" .. questID]
		if button then
			button:Click()
		end
	end


	function RQE:ForceRefreshAndClickWorldQuestButton(questID)
		UpdateRQEWorldQuestFrame()  -- Force a refresh of all buttons
		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(1, function()  -- Delay to ensure UI updates
		RQE.API.Client.C_Timer.After(1, function()  -- Delay to ensure UI updates
			self:ClickWorldQuestButton(questID)
		end)
	end


	-------------------------------------------------------
	-- #11n. Achievement Tracking & Rendering
	-------------------------------------------------------

	-- Function to add/remove tracked achievements into table
	function RQE.UpdateTrackedAchievements(contentType, id, tracked)
		if contentType == 2 then -- Assuming "2" signifies an achievement
			if tracked then
				if not tContains(RQE.TrackedAchievementIDs, id) then
					table.insert(RQE.TrackedAchievementIDs, id)
				end
			else
				for i, trackedID in ipairs(RQE.TrackedAchievementIDs) do
					if trackedID == id then
						table.remove(RQE.TrackedAchievementIDs, i)
						break
					end
				end
			end
		end
		-- Call the update function to refresh the UI
		RQE.UpdateTrackedAchievementList()
	end


	-- Function to fetch and update the list of tracked achievements
	function RQE.UpdateTrackedAchievementList()
		-- Previous Blizzard call changed 2026.09.25: local achievementIDs = C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
		local achievementIDs = RQE.API.Client.C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
		RQE.TrackedAchievementIDs = achievementIDs -- Assuming RQE.TrackedAchievementIDs is initialized as a table somewhere
		-- Optionally, call a function to update UI with the new list
		UpdateRQEAchievementsFrame()
	end


	-- Function to count the number of tracked achievements
	function RQE.GetNumTrackedAchievements()
		-- Assuming RQE.TrackedAchievementIDs is a table that contains the achievement IDs that are being tracked
		local count = 0
		if RQE and RQE.TrackedAchievementIDs then
			for _ in pairs(RQE.TrackedAchievementIDs) do
				count = count + 1
			end
		end
		return count
	end

	-- Keep the full criteria list, but supply the text omitted by numeric and
	-- description-only achievements in the standard criteria label.
	local function GetTrackedAchievementCriteriaText(achievementID, criteriaIndex, description)
		local label, criteriaType, complete, quantity, totalQuantity, _, _, assetID, progressText =
			RQE.API.Client.GetAchievementCriteriaInfo(achievementID, criteriaIndex)
		if CRITERIA_TYPE_ACHIEVEMENT and criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID then
			local _, linkedName = RQE.API.Client.GetAchievementInfo(assetID)
			label = linkedName or label
		end
		if type(label) ~= "string" or label:match("^%s*%-?%s*$") then
			label = description or ""
		end
		local hasRatio = type(progressText) == "string"
			and progressText:match("^%s*[%d,]+%s*/%s*[%d,]+")
		if (type(totalQuantity) == "number" and totalQuantity > 1) or hasRatio then
			local progress = progressText
			if not hasRatio then
				progress = string.format("%d/%d", quantity or 0, totalQuantity)
			end
			progress = progress:gsub("%s*/%s*", "/")
			if not label:find("^%d[%d,]*/%d") then
				label = progress .. (label ~= "" and (" " .. label) or "")
			end
		end
		return label, complete
	end


	-- Function to Update Achievements Frame
	function UpdateRQEAchievementsFrame()
		RQE.AchievementsFrame.achieveCount = RQE.GetNumTrackedAchievements()

		-- Print the IDs of tracked achievements for debugging
		if RQE.AchievementsFrame.achieveCount > 0 then
			RQE.infoLog("Currently Tracked Achievements:")
		end

		-- Clear the achievement ID list before updating
		RQE:ClearAchievementFrame()

		-- Initialize or clear the table that keeps track of achievement ID widgets
		RQE.AchievementsIDWidgets = RQE.AchievementsIDWidgets or {}

		-- Sets initial y-offset slightly below top of frame
		local offsetY = -45 -- Starting offset for the first achievement
		local spacing = 7 -- Space between achievements
		local textPadding = 55 -- Adjust this value to control word wrap width
		local availableWidth = RQE.AchievementsFrame:GetWidth() - textPadding

		-- Loop through each tracked achievement ID and display it along with the description
		for _, achievementID in ipairs(RQE.TrackedAchievementIDs) do
			-- Previous Blizzard call changed 2026.09.25: local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(achievementID)
			local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = RQE.API.Client.GetAchievementInfo(achievementID)
			RQE.infoLog("- Achievement ID:", achievementID)

			if id then
				-- Create the header for each achievement
				local achievementHeader = RQE.AchievementsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				achievementHeader:SetWidth(math.max(1, availableWidth))
				achievementHeader:SetWordWrap(true)
				achievementHeader:SetPoint("TOPLEFT", RQE.AchievementsFrame, "TOPLEFT", 10, offsetY)
				achievementHeader:SetText("[" .. id .. "] " .. name)
				achievementHeader:SetTextColor(1, 0.5, 0.3) -- Tan color for the achievement ID and name
				achievementHeader:SetJustifyH("LEFT")
				RQE.AchievementHeader = achievementHeader  -- Save for future reference

				-- Set up the tooltip for the achievement header
				achievementHeader:SetScript("OnEnter", function(self)
					RQE.API.ShowTrackedAchievementTooltip(self, id, name, description)
				end)
				achievementHeader:SetScript("OnLeave", function(self)
					RQE.API.HideTrackedTooltip()
				end)

				-- Set up the clickable action for the achievement header
				achievementHeader:EnableMouse(true)

				achievementHeader:SetScript("OnMouseUp", function(self, button)
					if button == "LeftButton" then
						if RQE.API.Client.IsShiftKeyDown() then
							RQE.API.HideTrackedTooltip()
							RQE.API.StopTrackingAchievement(id)
							return
						end
						-- Previous Blizzard call changed 2026.09.25: local _, isBlizzAchieveLoaded = C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI")
						local _, isBlizzAchieveLoaded = RQE.API.Client.C_AddOns.IsAddOnLoaded("Blizzard_AchievementUI")
						if not isBlizzAchieveLoaded then
							-- Previous Blizzard call changed 2026.09.25: C_AddOns.LoadAddOn("Blizzard_AchievementUI")
							RQE.API.Client.C_AddOns.LoadAddOn("Blizzard_AchievementUI")
						end
						if AchievementFrame then
							if not AchievementFrame:IsShown() then
								AchievementFrame_ToggleAchievementFrame()
							end
							AchievementFrame_SelectAchievement(id)
						end
					end
				end)

				offsetY = offsetY - achievementHeader:GetStringHeight() - spacing -- Adjust offsetY for the header and additional spacing

				-- Loop through criteria
				-- Previous Blizzard call changed 2026.09.25: local numCriteria = GetAchievementNumCriteria(id)
				local numCriteria = RQE.API.Client.GetAchievementNumCriteria(id)
				if numCriteria == 0 and description and description ~= "" then
					local criteriaText = RQE.AchievementsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					criteriaText:SetWidth(math.max(1, availableWidth))
					criteriaText:SetJustifyH("LEFT")
					criteriaText:SetPoint("TOPLEFT", RQE.AchievementsFrame, "TOPLEFT", 10, offsetY)
					criteriaText:SetWordWrap(true)
					criteriaText:SetTextColor(1, 1, 1)
					criteriaText:SetText("- " .. description)
					offsetY = offsetY - criteriaText:GetStringHeight() - spacing
				end
				for criteriaIndex = 1, numCriteria do
					local criteriaString, criteriaCompleted = GetTrackedAchievementCriteriaText(id, criteriaIndex, description)

					-- Create a FontString for each criteria
					local criteriaText = RQE.AchievementsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					criteriaText:SetWidth(math.max(1, availableWidth))
					criteriaText:SetJustifyH("LEFT")
					criteriaText:SetPoint("TOPLEFT", RQE.AchievementsFrame, "TOPLEFT", 10, offsetY)
					criteriaText:SetWordWrap(true)

					-- Set color based on completion status
					if criteriaCompleted then
						criteriaText:SetTextColor(0, 1, 0) -- Green color for completed criteria
					else
						criteriaText:SetTextColor(1, 1, 1) -- White color for incomplete criteria
					end

					criteriaText:SetText("- " .. criteriaString)
					offsetY = offsetY - criteriaText:GetStringHeight() - spacing -- Adjust offsetY for each criteria line and additional spacing
				end

				-- Add extra spacing between different achievements
				offsetY = offsetY - spacing
			end
		end

		-- Include every rendered criteria line in the section and scroll range.
		-- A fixed height per achievement cannot contain long or wrapped criteria.
		RQE.AchievementsFrame.lastMeasuredHeight = math.max(80,
			-offsetY + GetQuestSectionBottomPadding())
		RQE.AchievementsFrame:SetHeight(RQE.AchievementsFrame.lastMeasuredHeight)

		-- After creating each new FontString, insert it into RQE.AchievementsIDWidgets:
		table.insert(RQE.AchievementsIDWidgets, RQE.AchievementHeader)

		-- Check if any achievements in the Achievement Frame are being tracked/watched
		RQE.AchievementsFrame:SetShown(RQE.AchievementsFrame.achieveCount > 0)
		RQE.UpdateRecipeTrackingAnchor()

		-- Update the scroll frame range if necessary
		if RQE.AchievementsFrame.scrollFrame then
			RQE.AchievementsFrame.scrollFrame:SetVerticalScrollRange(math.abs(offsetY))
		end

		RQE.RefreshQuestTrackerScrollRange()
		-- Let wrapped FontStrings settle before measuring the final scroll extent.
		RQE.API.Client.C_Timer.After(0, function()
			if RQE.AchievementsFrame and RQE.AchievementsFrame:IsShown() then
				RQE.AchievementsFrame.lastMeasuredHeight = math.max(80,
					-offsetY + GetQuestSectionBottomPadding())
				RQE.AchievementsFrame:SetHeight(RQE.AchievementsFrame.lastMeasuredHeight)
			end
			RQE.RefreshQuestTrackerScrollRange()
		end)

		-- Visibility Update Check for RQEQuestFrame
		RQE:UpdateRQEQuestFrameVisibility()
	end


	-------------------------------------------------------
	-- #11o. Watch-List Synchronization
	-------------------------------------------------------

	-- Function that checks the watch list and compares that with the quests displayed in the RQEQuestFrame
	function RQE:CheckWatchedQuestsSync()
		local watchedQuests = {}
		local displayedQuests = {}

		-- Build list of all watched normal quests
		-- Previous Blizzard call changed 2026.09.25: for i = 1, C_QuestLog.GetNumQuestWatches() do
		for i = 1, RQE.API.Client.C_QuestLog.GetNumQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local qID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			local qID = RQE.API.Client.C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if qID then
				watchedQuests[qID] = true
			end
		end

		-- Build list of all watched world quests
		-- Previous Blizzard call changed 2026.09.25: for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		for i = 1, RQE.API.Client.C_QuestLog.GetNumWorldQuestWatches() do
			-- Previous Blizzard call changed 2026.09.25: local qID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			local qID = RQE.API.Client.C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if qID then
				watchedQuests[qID] = true
			end
		end

		-- Populate displayedQuests from your RQEQuestFrame (update as per your actual tracking structure)
		if RQE.RQEQuestFrame and RQE.RQEQuestFrame.QuestBlocks then
			for questID in pairs(RQE.RQEQuestFrame.QuestBlocks) do
				displayedQuests[questID] = true
			end
		end

		-- Compare sets
		for qID in pairs(watchedQuests) do
			if not displayedQuests[qID] then
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					DEFAULT_CHAT_FRAME:AddMessage("WatchListSync: Missing questID " .. qID .. " from RQEQuestFrame. Refreshing...", 1, 0.75, 0.79)
				end
				RQE:QuestType() -- Refresh layout
				return
			end
		end
	end


	-- Frequent checking to enforce the visibility of quests being tracked to be displayed in RQEQuestFrame
	-- Previous Blizzard call changed 2026.09.25: C_Timer.NewTicker(1, function()
	RQE.API.Client.C_Timer.NewTicker(1, function()
		-- Retry Blizzard-backed labels even while stationary. Quest POI data may not
		-- be populated during the first tracker build immediately after a reload.
		if RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown() and RQE.RefreshTrackedQuestDistances then
			RQE:RefreshTrackedQuestDistances()
		end

		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then return end
		if RQE.API.Client.InCombatLockdown() then return end

		local isMapOpen = WorldMapFrame:IsShown()
		local isClassicQuestLogOpen = ClassicQuestLog and ClassicQuestLog:IsShown()
		-- Previous Blizzard call changed 2026.09.25: local isPlayerStationary = not UnitCastingInfo("player") and not UnitChannelInfo("player") and not IsPlayerMoving()
		local isPlayerStationary = not RQE.API.Client.UnitCastingInfo("player") and not RQE.API.Client.UnitChannelInfo("player") and not RQE.API.Client.IsPlayerMoving()
		local isMouseOverRelevantFrames = WorldMapFrame:IsMouseOver() or (RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsMouseOver())

		if isPlayerStationary and (isMapOpen or isClassicQuestLogOpen or isMouseOverRelevantFrames) then
			RQE:CheckWatchedQuestsSync()
		end
	end)
