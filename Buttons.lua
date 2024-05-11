--[[ 
Buttons.lua
Manages button designs for the main frame
]]

----------------------------------------------------
-- 1. Global Declarations
----------------------------------------------------

RQE = RQE or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
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

			-- Update tooltip text based on new coordinates
			if RQE.superX and RQE.superY and RQE.superMapID then
				local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", RQE.superX, RQE.superY, tostring(RQE.superMapID))
				GameTooltip:SetText(tooltipText)
			else
				GameTooltip:SetText("Coordinates: Not available.")
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

	-- Helper function to trim strings (removes whitespace from the beginning and end of a string)
	if not string.trim then
		string.trim = function(s)
			return s:match("^%s*(.-)%s*$")
		end
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
    local MagicButton = RQE.MagicButton -- Assuming you've stored MagicButton globally in RQE.MagicButton

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


-- Function to set up an override key binding for your macro
function RQE:SetupOverrideMacroBinding()
    local ownerFrame = RQE.MagicButton
    local macroName = "RQE Macro"
    local bindingKey = RQE.db.profile.keyBindSetting or "CTRL-SHIFT-Y"  -- Use the stored setting or default

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex and macroIndex > 0 then
		-- Sets an override binding that runs the specified macro by index
        ClearOverrideBindings(ownerFrame)
        SetOverrideBindingMacro(ownerFrame, true, bindingKey, macroIndex)
		-- Optional: Provide feedback that the binding was set
        -- print("Override binding set for " .. bindingKey .. " to run macro: " .. macroName)
    else
		-- Provide feedback if the macro does not exist
        RQE.debugLog("Macro '" .. macroName .. "' not found.")
    end
end


-- Remember to clear the override binding when it's no longer needed or when your UI is hidden
local function ClearOverrideMacroBinding()
    local ownerFrame = RQE.MagicButton -- The same frame you set the binding on

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

        -- Your code for ClearButton functionality here
		RQE.ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQE.searchedQuestID = nil
		RQE.ManualSuperTrack = nil
		C_SuperTrack.ClearSuperTrackedContent()
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
        -- Your code for RWButton functionality here
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
        -- Your code for showing completed quests functionality here
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
        -- Your code for hiding completed quests functionality here
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
        -- Your code for displaying quests in current zone
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


-- Parent function to Create QTFilterButton for RQEQuestFrame
function RQE.Buttons.CreateQuestFilterButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
    local QTFilterButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
    QTFilterButton:SetSize(18, 18)  -- Set to your desired size
    QTFilterButton:SetText("F")
    RQE.QTQuestFilterButton = QTFilterButton  -- Store the reference in the RQE table

    -- Define cursorX and cursorY outside the OnClick function
    local cursorX, cursorY

    -- Position the button next to your minimize/maximize buttons
    QTFilterButton:SetPoint("TOPRIGHT", RQE.QTQuestMinimizeButton, "TOPLEFT", -3, 0)

    -- Set the frame strata and level
    QTFilterButton:SetFrameStrata("MEDIUM")
    QTFilterButton:SetFrameLevel(3)

    QTFilterButton:SetScript("OnClick", function(self, button, down)
        RQE.debugLog("RQE.FilterDropDownMenu:", RQE.FilterDropDownMenu)  -- Should not be nil
        RQE.ScanQuestTypes()  -- Ensure quest types are up-to-date

        -- Build the sorted quest type menu list
        local questTypeMenuList = RQE.BuildQuestTypeMenuList()

        RQE.ScanAndCacheZoneQuests()  -- Scan and cache zone quests
        local zoneQuestMenuList = RQE.BuildZoneQuestMenuList()  -- Get the dynamically built zone quest menu list

		RQE.ScanAndCacheCampaigns()

		-- Get the dynamically built campaign menu list
		local campaignMenuList = RQE.BuildCampaignMenuList() --RQE.GetDynamicCampaignMenuList()
		-- Print the campaign menu list for debugging
		RQE.debugLog("Campaign Menu List: ", campaignMenuList)

		-- Fetch the cursor position
		local cursorX, cursorY = GetCursorPosition()
		local uiScale = UIParent:GetScale()
		cursorX, cursorY = cursorX / uiScale, cursorY / uiScale

		-- Define a local function to reset the scroll position
		local function resetScroll()
			if RQE.QTScrollFrame and RQE.QMQTslider then
				RQE.QTScrollFrame:SetVerticalScroll(0)  -- Set the scroll position to the top
				RQE.QMQTslider:SetValue(0)  -- Also set the slider to the top position
			end
		end

		local menuItems = {
			{
				text = "Auto-Track Zone Quests",
				checked = function() return RQE.db.profile.autoTrackZoneQuests end,
				func = function(self, arg1, arg2, checked)
					RQE.db.profile.autoTrackZoneQuests = not RQE.db.profile.autoTrackZoneQuests
					if RQE.db.profile.autoTrackZoneQuests then
						-- If enabling, auto-track the quests for the current zone
						RQE.DisplayCurrentZoneQuests()
					else
						-- If disabling, you may want to untrack all quests or perform another action
					end
				end,
				isNotRadio = true, -- Allows this menu item to be a toggle (checkable) rather than a radio button
				keepShownOnClick = true, -- Keeps the menu open after the item is clicked
			},
			{ text = "Completed Quests", func = function() RQE.filterCompleteQuests(); resetScroll() end },
			{ text = "Daily / Weekly Quests", func = function() RQE.filterDailyWeeklyQuests(); resetScroll() end },
			{
                text = "Camapaign Quests",
                hasArrow = true,
                menuList = campaignMenuList,
			},
            {
                text = "Quest Type",
                hasArrow = true,
                menuList = questTypeMenuList,
            },
            {
                text = "Zone Quests",
                hasArrow = true,
                menuList = zoneQuestMenuList,  -- Add zone quest menu list here
            },
			{
				text = "Quest Line",
				hasArrow = true,
				menuList = RQE.BuildQuestLineMenuList(),
			},

			-- -- Add more filter options here...
			--}
		}

		-- Set up the anchor point for the dropdown menu
		local menuAnchor = {
			point = "TOPLEFT", -- Point on the dropdown
			relativeFrame = RQE.RQEQuestFrameHeader, -- Frame to anchor the dropdown to
			relativePoint = "TOPLEFT", -- Point on RQEQuestFrame
			offsetX = 0, -- X offset from the anchor point
			offsetY = 0, -- Y offset from the anchor point
		}

		-- Open the dropdown menu at the specified position
	    EasyMenu(menuItems, RQE.FilterDropDownMenu, menuAnchor.relativeFrame, menuAnchor.offsetX, menuAnchor.offsetY, "MENU", 2)
	end)

    CreateTooltip(QTFilterButton, "Filter Quests")  -- Tooltip function from your code
    CreateBorder(QTFilterButton)  -- Border function from your code

    return QTFilterButton
end


----------------------------------------------------
-- 5. Button Initialization (QuestFrame headers)
----------------------------------------------------

-- Code to be used for any buttons that are placed on the child headers of RQEQuestFrame


----------------------------------------------------
-- 6. Button Initialization (DebugFrame)
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
-- 7. Finalization
----------------------------------------------------

-- Function to create and initialize the SearchBox
function RQE.Buttons.CreateSearchBox(RQEFrame)
    --Ace3 SearchBox
end