--[[ 
Core.lua
Core file linking all other modules
]]

---------------------------------------------------
-- 1. Global Declarations
---------------------------------------------------

RQE = RQE or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}

-- Table to hold campaigns, quest types and quest lines
RQE.Campaigns = RQE.Campaigns or {}
RQE.QuestTypes = RQE.QuestTypes or {}
RQE.ZoneQuests = RQE.ZoneQuests or {}
RQE.QuestLines = RQE.QuestLines or {}

if not table.unpack then
    table.unpack = unpack
end

---------------------------------------------------
-- 2. Imports
---------------------------------------------------

-- Initialize your RQE addon with AceAddon
RQE = LibStub("AceAddon-3.0"):NewAddon("RQE", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

-- AceConfig and AceConfigDialog references
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- Constants

local floor = math.floor
local fmod = math.fmod
local format = string.format
local gsub = string.gsub
local ipairs = ipairs
local max = math.max
local pairs = pairs
local strfind = string.find
local tonumber = tonumber
local tinsert = table.insert
local tremove = table.remove
local tContains = tContains
local unpack = unpack
local round = function(n) return floor(n + 0.5) end


---------------------------------------------------
-- 3. Debugging Functions
---------------------------------------------------

-- Safe Print Function
function RQE:SafePrint(...)
    local args = {...}
    local output = {}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            output[i] = "Table: Cannot display"
        elseif type(v) == "boolean" then
            output[i] = v and "True" or "False"  -- Convert boolean to "True" or "False"
        else
            output[i] = tostring(v)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(table.concat(output, " "))
end


-- Custom Debug Function
function RQE:CustomDebugLog(index, color, message, ...)
    local output = "|c" .. color .. "[Line " .. tostring(index) .. "] " .. message
    local args = {...}
    for i = 1, select("#", ...) do
        if i == 1 then
            output = output .. " " .. tostring(args[i])
        else
            output = output .. ", " .. tostring(args[i])
        end
    end
    output = output .. "|r"

    -- Add to logTable
    RQE.AddToDebugLog(output)
end


-- Custom Info Message Function
function RQE:CustomLogMsg(color, message, ...)
    local output = "|c" .. color .. message  -- Removed the line number part
    local args = {...}
    for i = 1, select("#", ...) do
        output = output .. " " .. tostring(args[i])
    end
    output = output .. "|r"

    -- Add to logTable
    RQE.AddToDebugLog(output)

    -- Update the log frame to display the new log entry
    if RQE.DebugLogFrameRef and RQE.DebugLogFrameRef:IsShown() then
        RQE.UpdateLogFrame()
    end
end


-- Function to log general info messages
function RQE.infoLog(message, ...)
    if RQE.db and RQE.db.profile.debugMode then
        local debugLevel = RQE.db.profile.debugLevel
		if debugLevel == "INFO" or debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
			RQE:CustomLogMsg("cf9999FF", " RQE Info: " .. message, ...)
        end
    end
end


-- Function to log general debug messages
function RQE.debugLog(message, ...)
    if RQE.db and RQE.db.profile.debugMode then
        local debugLevel = RQE.db.profile.debugLevel
        if debugLevel == "DEBUG" then
            local stack = debugstack(2, 1, 0)
            local _, _, fileName, line = string.find(stack, "([^\\]-):(%d+):")
            fileName = string.gsub(fileName, "@Interface/AddOns/", "@")  -- Simplify file name
            RQE:CustomDebugLog(line, "cfC4C45C", fileName .. " Debug: " .. message, ...)
        end
    end
end


-- Function to log warning messages
function RQE.warningLog(message, ...)
    if RQE.db and RQE.db.profile.debugMode then
        local debugLevel = RQE.db.profile.debugLevel
        if debugLevel == "DEBUG" or debugLevel == "WARNING" then
            local stack = debugstack(2, 1, 0)
            local _, _, fileName, line = string.find(stack, "([^\\]-):(%d+):")
            fileName = string.gsub(fileName, "@Interface/AddOns/", "@")  -- Simplify file name
            RQE:CustomDebugLog(line, "ffFF7F00", fileName .. " Warning: " .. message, ...)
        end
    end
end


-- Function to log critical messages
function RQE.criticalLog(message, ...)
    if RQE.db and RQE.db.profile.debugMode then
        local debugLevel = RQE.db.profile.debugLevel
        if debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
            local stack = debugstack(2, 1, 0)
            local _, _, fileName, line = string.find(stack, "([^\\]-):(%d+):")
            fileName = string.gsub(fileName, "@Interface/AddOns/", "@")  -- Simplify file name
            RQE:CustomDebugLog(line, "ffD63333", fileName .. " Critical: " .. message, ...)
        end
    end
end


-- Verify initialization of DB Profile
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    RQE.warningLog("RQE.db.profile.textSettings is initialized.")
else
    RQE.warningLog("RQE.db.profile.textSettings is NOT initialized.")
end


---------------------------------------------------
-- 4. Default Settings
---------------------------------------------------

local defaults = {
    profile = {
        debugMode = true,
        debugLevel = "INFO",
        enableFrame = true,
		hideRQEFrameWhenEmpty = false,
		enableQuestFrame = true,
		hideRQEQuestFrameWhenEmpty = false,
        showMinimapIcon = false,
        showMapID = true,
        showCoordinates = true,
		autoQuestWatch = true,
		autoQuestProgress = true,
		removeWQatLogin = false,
		autoTrackZoneQuests = false,
		autoClickWaypointButton = false,
		enableQuestAbandonConfirm = false,
		enableTomTomCompatibility = true,
		enableCarboniteCompatibility = true,
		keyBindSetting = nil,
		displayRQEmemUsage = false,
        framePosition = {
            xPos = -40,
            yPos = -270,
            anchorPoint = "TOPRIGHT",
			frameWidth = 435,
			frameHeight = 300,
		},
		MainFrameOpacity = 0.55,
		textSettings = {
		},
        QuestFramePosition = {
            xPos = -40,
            yPos = 150,
			anchorPoint = "BOTTOMRIGHT",
            frameWidth = 325,
            frameHeight = 450
		},
		QuestFrameOpacity = 0.55,
		textSettings = {
		},
        textSettings = {
            headerText = {
                font = "Fonts\\SKURRI.TTF",
                size = 18,
                color = {237/255, 191/255, 89/255}
            },
            QuestIDText = {
                font = "Fonts\\FRIZQT__.TTF",
                size = 15,
                color = {255/255, 255/255, 0/255}  -- RGB for Yellow
            },
            QuestNameText = {
                font = "Fonts\\FRIZQT__.TTF",
                size = 15,
                color = {255/255, 255/255, 0/255}  -- RGB for Yellow
            },
            DirectionTextFrame = {
                font = "Fonts\\FRIZQT__.TTF",
                size = 13,
                color = {255/255, 255/255, 217/255}  -- RGB for Canary
            },
            QuestDescription = {
                font = "Fonts\\FRIZQT__.TTF",
                size = 14,
                color = {0/255, 255/255, 153/255}  -- RGB for Cyan
            },
            QuestObjectives = {
                font = "Fonts\\FRIZQT__.TTF",
                size = 13,
                color = {0/255, 255/255, 153/255}  -- RGB for Cyan
            },
         },
        isFrameMaximized = true,  -- new setting for maximized/minimized state
		isQuestFrameMaximized = true,  -- new setting for maximized/minimized state
        globalSetting = true,  -- This should be inside the 'profile' table
    },
    -- char = {
        -- characterSetting = true,  -- Character-specific settings go here
    -- },
}


---------------------------------------------------
-- 5. Initialization
---------------------------------------------------

-- Initialize original dimensions
RQE.originalWidth = RQE.originalWidth or 0
RQE.originalHeight = RQE.originalHeight or 0
RQE.QToriginalWidth = RQE.QToriginalWidth or 0
RQE.QToriginalHeight = RQE.QToriginalHeight or 0

-- Initialize Waypoint System
RQE.waypoints = {}

-- Initialize the savedAutomaticWorldQuestWatches table within your addon's initialization logic
if not RQE.savedAutomaticWorldQuestWatches then
    RQE.savedAutomaticWorldQuestWatches = {}
end

-- Initialize lastSuperTrackedQuestID variable
RQE.searchedQuestID = nil  -- No quest is being searched/focused initially
RQE.ManualSuperTrack = nil
RQE.LastClickedWaypointButton = nil -- Initialize with nil to indicate no button has been clicked yet
RQE.lastClickedObjectiveIndex = nil
RQE.LastClickedButtonRef = nil
RQE.AddedQuestID = nil
RQE.UpdateInstanceInfoOkay = true
--RQE.OverrideHasProgress = false
--RQE.hasClickedQuestButton = false
RQE.alreadyPrintedSchematics = false
--RQE.AutoWaypointHasBeenClicked = true
--RQE.canUpdateFromCriteria = true
RQE.canSortQuests = false

RQE.dragonMounts = {
    "Cliffside Wylderdrake",
    "Flourishing Whimsydrake",
    "Grotto Netherwing Drake",
    "Highland Drake",
    "Renewed Proto-Drake",
    "Windborne Velocidrake",
    "Winding Slitherdrake"
}


-- Addon Initialization
function RQE:OnInitialize()
	-- Start the timer
	RQE.startTime = debugprofilestop()

    -- Create a new AceDB-3.0 database for your addon
    --self.db = LibStub("AceDB-3.0"):New("RQEDB", defaults, true) -- Set default profile to the character
	self.db = LibStub("AceDB-3.0"):New("RQEDB", defaults, "Default")

	-- Initialize tables for storing StepsText, CoordsText, and WaypointButtons
	RQE.StepsText = RQE.StepsText or {}
	RQE.CoordsText = RQE.CoordsText or {}
	RQE.WaypointButtons = RQE.WaypointButtons or {}

	-- Initialize checkbox state for Coordinates
	if showCoordinates then  -- replace with your actual checkbox frame name
		showCoordinates:SetChecked(RQE.db.profile.showCoordinates)
	end

	-- Initialize checkbox state for Auto Sort Frame
	if autoQuestWatch then  -- replace with your actual checkbox frame name
		autoQuestWatch:SetChecked(RQE.db.profile.autoQuestWatch)
	end

	-- Initialize checkbox state for Auto Progress Update
	if autoQuestProgress then  -- replace with your actual checkbox frame name
		autoQuestProgress:SetChecked(RQE.db.profile.autoQuestProgress)
	end

    -- Initialize checkbox state for MapID
    if MapIDCheckbox then  -- replace with your actual checkbox frame name
        MapIDCheckbox:SetChecked(RQE.db.profile.showMapID)
    end

	-- Register the profile changed callback
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Now call UpdateFrameFromProfile to set the frame's position
	self:UpdateFrameFromProfile()

    -- Initialize character-specific data
    self:GetCharacterInfo()

    -- Register the main options table
    AC:RegisterOptionsTable("RQE_Main", RQE.options.args.general)
    self.optionsFrame = ACD:AddToBlizOptions("RQE_Main", "Rhodan's Quest Explorer")

    -- Register the "Frame" options table as a separate tab
    AC:RegisterOptionsTable("RQE_Frame", RQE.options.args.frame)
    self.optionsFrame.frame = ACD:AddToBlizOptions("RQE_Frame", "Frame Settings", "Rhodan's Quest Explorer")

    -- Register the "Font" options table as a separate tab
    AC:RegisterOptionsTable("RQE_Font", RQE.options.args.font)
    self.optionsFrame.font = ACD:AddToBlizOptions("RQE_Font", "Font Settings", "Rhodan's Quest Explorer")

    -- Register the "Debug" options table as a separate tab
    AC:RegisterOptionsTable("RQE_Debug", RQE.options.args.debug)
    self.optionsFrame.debug = ACD:AddToBlizOptions("RQE_Debug", "Debug Options", "Rhodan's Quest Explorer")

    -- Add profiles (if needed)
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    AC:RegisterOptionsTable("RQE_Profiles", profiles)
    ACD:AddToBlizOptions("RQE_Profiles", "Profiles", "Rhodan's Quest Explorer")

    -- Auto-set profile based on some condition
    local characterName = UnitName("player")
    local characterRealm = GetRealmName()
    if characterName == "SomeSpecificName" and characterRealm == "SomeSpecificRealm" then
        self.db:SetProfile(characterName .. " - " .. characterRealm)
    end

    -- Register chat commands (if needed)
    self:RegisterChatCommand("rqe", "SlashCommand")

    -- Ensure that MAP ID value is set to default values
    local showMapID = RQE.db.profile.showMapID
	if showMapID then
		-- Code to display MapID
		RQEFrame.MapIDText:Show()
	else
		-- Code to hide MapID
		RQEFrame.MapIDText:Hide()
	end

    -- Ensure that frame opacity is set to default values
    local MainOpacity = RQE.db.profile.MainFrameOpacity
	local QuestOpacity = RQE.db.profile.QuestFrameOpacity
    RQEFrame:SetBackdropColor(0, 0, 0, MainOpacity) -- Setting the opacity
    RQEQuestFrame:SetBackdropColor(0, 0, 0, QuestOpacity) -- Same for the quest frame

    -- Override the print function
    local originalPrint = print
    print = function(...)
        local message = table.concat({...}, " ")
        RQE.AddToDebugLog(message)
        originalPrint(...)
    end

	self:UpdateFramePosition()
	RQE.FilterDropDownMenu = CreateFrame("Frame", "RQEDropDownMenuFrame", UIParent, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(RQE.FilterDropDownMenu, RQE.InitializeFilterDropdown)
end


-- Function to initialize dropdown quest filter for Quest Tracker
function RQE.InitializeFilterDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.isNotRadio = true
    info.notCheckable = true

    if level == 1 then
		-- Auto Tracking for Zone Quests
		info.text = "Auto-Track Zone Quests"
		info.keepShownOnClick = true  -- Keeps the dropdown open after clicking
		info.isNotRadio = true
		info.func = function()
			RQE.db.profile.autoTrackZoneQuests = not RQE.db.profile.autoTrackZoneQuests
			-- No need to call RQE.DisplayCurrentZoneQuests() here since it will be called on zone change
		end
		info.checked = RQE.db.profile.autoTrackZoneQuests
		UIDropDownMenu_AddButton(info, level)

        -- First-level menu items
        info.text = "Completed Quests"
        info.func = RQE.filterCompleteQuests  -- Link to your filter function
        UIDropDownMenu_AddButton(info, level)

        info.text = "Daily / Weekly Quests"
        info.func = RQE.filterDailyWeeklyQuests  -- Link to your filter function
        UIDropDownMenu_AddButton(info, level)

        info.text = "Zone Quests"
        info.func = RQE.filterZoneQuests  -- Link to your filter function
        UIDropDownMenu_AddButton(info, level)

        -- ... other first-level items ...

        info.text = "Select Campaign..."
        info.hasArrow = true  -- Important for creating a submenu
        info.value = "campaign_submenu"  -- Used to identify this item in the next level
        UIDropDownMenu_AddButton(info, level)
    elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "campaign_submenu" then
        local campaigns = RQE.GetCampaignsFromQuestLog()
        for campaignID, campaignName in pairs(campaigns) do
            info.text = campaignName
            info.func = function() RQE.filterSpecificCampaign(campaignID) end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end


-- InitializeFrame function
-- @param RQEFrame: The main frame object
function RQE:InitializeFrame()
    --self:Initialize()  -- Call Initialize() within InitializeFrame

    -- Initialize search box (Now calling the function from Buttons.lua)
    RQE.Buttons.CreateSearchBox(RQEFrame)

    -- Initialize search button (Now calling the function from Buttons.lua)
    RQE.Buttons.CreateSearchButton(RQEFrame)

    -- Add logic to update frame with the current super tracked quest
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID then
        local questInfo = RQE.getQuestData(questID)
        if questInfo then
            local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
        end
    end
end


-- Function Check to Initialize RQEFrame sections not yet initialized
function RQE:ConfigurationChanged()
    if RQE.headerText then
        local headerSettings = RQE.db.profile.textSettings.headerText

        RQE.headerText:SetFont(headerSettings.font, headerSettings.size)
        RQE.headerText:SetTextColor(unpack(headerSettings.color))
    end

    if RQE.QuestIDText then
        local QuestIDTextSettings = RQE.db.profile.textSettings.QuestIDText

        RQE.QuestIDText:SetFont(QuestIDTextSettings.font, QuestIDTextSettings.size)
        RQE.QuestIDText:SetTextColor(unpack(QuestIDTextSettings.color))
    end

    if RQE.QuestNameText then
        local QuestNameTextSettings = RQE.db.profile.textSettings.QuestNameText

        RQE.QuestNameText:SetFont(QuestNameTextSettings.font, QuestNameTextSettings.size)
        RQE.QuestNameText:SetTextColor(unpack(QuestNameTextSettings.color))
    end

    if RQE.DirectionTextFrame then
        local DirectionTextFrameSettings = RQE.db.profile.textSettings.DirectionTextFrame

        RQE.DirectionTextFrame:SetFont(DirectionTextFrameSettings.font, DirectionTextFrameSettings.size)
        RQE.DirectionTextFrame:SetTextColor(unpack(DirectionTextFrameSettings.color))
    end

    if RQE.QuestDescription then
        local QuestDescriptionSettings = RQE.db.profile.textSettings.QuestDescription

        RQE.QuestDescription:SetFont(QuestDescriptionSettings.font, QuestDescriptionSettings.size)
        RQE.QuestDescription:SetTextColor(unpack(QuestDescriptionSettings.color))
    end

    if RQE.QuestObjectives then
        local QuestObjectivesSettings = RQE.db.profile.textSettings.QuestObjectives

        RQE.QuestObjectives:SetFont(QuestObjectivesSettings.font, QuestObjectivesSettings.size)
        RQE.QuestObjectives:SetTextColor(unpack(QuestObjectivesSettings.color))
    end
 	    -- You can add more configuration updates here

	-- Notify AceConfig to update UI
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE")
end


---------------------------------------------------
-- 6. Saving/Restoring SuperTrack Data
---------------------------------------------------

-- Function to open the quest log and show specific quest details
function OpenQuestLogToQuestDetails(questID)
	if RQE.searchedQuestID ~= nil then
		return
	end

    local mapID = GetQuestUiMapID(questID, ignoreWaypoints) or C_TaskQuest.GetQuestZoneID(questID)
    if mapID == 0 then mapID = nil end
    OpenQuestLog(mapID)
    QuestMapFrame_ShowQuestDetails(questID)
end


-- Function that saves data of the Super Tracked Quest
function RQE.SaveSuperTrackData()
	-- Extracts Details of Quest if possible
	RQE.ExtractAndSaveQuestCoordinates()

    local questID = C_SuperTrack.GetSuperTrackedQuestID()

    if questID then
        local playerMapID = C_Map.GetBestMapForUnit("player")
        local mapID = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID, ignoreWaypoints)
        local questTitle = C_QuestLog.GetTitleForQuestID(questID)
        local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        local posX, posY

        if isWorldQuest then
            posX, posY = C_TaskQuest.GetQuestLocation(questID, mapID)
        else
			if not posX or not posX and mapID then
				local questID = C_SuperTrack.GetSuperTrackedQuestID()
				local mapID = GetQuestUiMapID(questID, ignoreWaypoints)
				if mapID == 0 then mapID = nil end
			else
				posX, posY = C_QuestLog.GetNextWaypointForMap(questID, mapID)
			end
        end

        RQE.superMapID = mapID
        RQE.superQuestID = questID
        RQE.superQuestTitle = questTitle

		if posX == nil then
			RQE.superX = RQE.x
		else
			RQE.superX = posX
		end

		if posY == nil then
			RQE.superY = RQE.y
		else
			RQE.superY = posY
		end

		C_Timer.After(1, function()
			if RQE.superX == nil or RQE.superY == nil then
				RQE.SaveSuperTrackData()
				return
			end
		end)

        -- Optional: Return the values for immediate use
        return posX, posY, mapID, questID, questTitle
    end
end


function RQE.ExtractAndSaveQuestCoordinates()
	local questID = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID

	if not questID then
		RQE.debugLog("No QuestID found. Cannot proceed.")
		return
	end

	local isMapOpen = WorldMapFrame:IsShown()
	local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
	local mapID, posX, posY, completed, objective

	if isWorldQuest then
		-- It's a world quest, use the TaskQuest APIs
		mapID = C_TaskQuest.GetQuestZoneID(questID)

		-- Ensure mapID is valid before calling GetQuestLocation
		if mapID then
			posX, posY = C_TaskQuest.GetQuestLocation(questID, mapID)
		else
			RQE.debugLog("Invalid mapID for World QuestID:", questID)
			return
		end
	else
		-- Not a world quest, use the existing logic
		mapID = GetQuestUiMapID(questID, ignoreWaypoints)
		completed, posX, posY, objective = QuestPOIGetIconInfo(questID)
	end

	if not mapID then
		return
	end

	-- If POI info is not available, try using GetNextWaypointForMap
	if not posX or not posY then
		if not isMapOpen and RQE.superTrackingChanged and not InCombatLockdown() then
		-- if not isMapOpen and RQE.superTrackingChanged then  --  [commented out for above fix for Frame:SetPassThroughButtons() error]
			-- Call the function to open the quest log with the details of the super tracked quest
			OpenQuestLogToQuestDetails(questID)
        else
            -- Either map is open, or we are in combat, or another secure operation is in progress [fix for Frame:SetPassThroughButtons() error]
            RQE.debugLog("Cannot open quest details due to combat lockdown or other restrictions.")
            return
        end

		completed, posX, posY, objective = QuestPOIGetIconInfo(questID)

		if not posX or not posY then
			local nextPosX, nextPosY, nextMapID, wpType = C_QuestLog.GetNextWaypointForMap(questID, mapID)

			if nextMapID == nil or nextPosX == nil or nextPosY == nil then
				RQE.debugLog("Next Waypoint - MapID:", nextMapID, "X:", nextPosX, "Y:", nextPosY, "Waypoint Type:", wpType)
			else
				RQE.debugLog("Next Waypoint - MapID:", nextMapID, "X:", nextPosX, "Y:", nextPosY, "Waypoint Type:", wpType)
			end

			-- Update the posX and posY variables with the new information
			posX = nextPosX
			posY = nextPosY
		end

		if not isMapOpen then
			WorldMapFrame:Hide()
		end
	end

	-- Reset the superTrackingChanged flag
	RQE.superTrackingChanged = false

	-- Save these to the RQE table
	RQE.x = posX
	RQE.y = posY
	RQE.mapID = mapID
end


-- Function controls the restoration of the quest that is super tracked to the RQEFrame
function RQE:HandleSuperTrackedQuestUpdate()
    -- Save the current super tracked quest ID
    local savedSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

    if savedSuperTrackedQuestID then
		local isWorldQuest = C_QuestLog.IsWorldQuest(savedSuperTrackedQuestID)
		-- Check if the quest was manually tracked
		local manuallyTracked = RQE.ManuallyTrackedQuests and RQE.ManuallyTrackedQuests[savedSuperTrackedQuestID]
		-- Check if the quest is completed
		local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(savedSuperTrackedQuestID)
	end

    -- Determine if the quest is being tracked due to a search and is not completed
    local trackedViaSearchAndNotCompleted = RQE.searchedQuestID == savedSuperTrackedQuestID and not isQuestCompleted

    if isWorldQuest then
        if not (manuallyTracked or trackedViaSearchAndNotCompleted) then
            -- Clear the RQEFrame for this world quest if it's neither manually tracked nor searched and incomplete
            RQE:ClearFrameData()
            return
        end
    end

    -- Clear the current super tracked content for non-world quests or allowed world quests
    C_SuperTrack.ClearSuperTrackedContent()

    -- Restore the super-tracked quest after a delay for non-world quests
    C_Timer.After(0.2, function()
        if savedSuperTrackedQuestID then
            -- Fetch quest info from RQEDatabase if available
            local questInfo = RQE.getQuestData(savedSuperTrackedQuestID)
            if questInfo then
                local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(savedSuperTrackedQuestID)
                UpdateFrame(savedSuperTrackedQuestID, questInfo, StepsText, CoordsText, MapIDs)
                AdjustRQEFrameWidths(newWidth)
            end
        end
    end)
end


-- Function to Reset LFG roles after leaving raid group created through the SearchGroup Button in RQEFrame
function ResetLFGRoles()
    -- Set default roles DAMAGE only: (leader, tank, healer, damage)
    SetLFGRoles(false, false, false, true)
end


-- SlashCommand function
function RQE:SlashCommand(input)
    if input == "config" then
        -- Open the config panel
        InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
    elseif input == "frame" or input == "toggle" then
        -- Toggle the frame visibility
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
        end
        -- Refresh the config panel if it's open
        if YourConfigPanel and YourConfigPanel:IsVisible() then
            YourConfigPanel:UpdateCheckboxState(RQE.Settings.frameVisibility)
        end
    else
        print("Available commands for /rqe:")
        print("config - Opens the configuration panel")
        print("frame, toggle - Toggles the RQE frame")
    end

	-- Check if MagicButton should be visible based on macro body
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- SlashCommand to Reset LFG Role
SLASH_RESETROLE1 = "/rqeresetrole"
SlashCmdList["RESETROLE"] = function()
    local dialog = LFGListApplicationDialog
    if dialog then
        LFGListApplicationDialog_UpdateRoles(dialog)
        LFGListApplicationDialog_UpdateValidState(dialog)
        LFGListApplicationDialog_Show(dialog)
    end
end


-- Register the slash command
RQE:RegisterChatCommand("rqe", "SlashCommand")


-- This function will clear the WQ Tracking for a specific quest
function RQE:ClearSpecificWQTracking(questID)
    if C_QuestLog.IsWorldQuest(questID) and C_QuestLog.GetQuestWatchType(questID) == Enum.QuestWatchType.Automatic then
        C_QuestLog.RemoveWorldQuestWatch(questID)
    end
end


---------------------------------------------------
-- 7. Profile Core Creation
---------------------------------------------------

-- Initialize variable to keep track of whether the profile has been set
RQE.profileHasBeenSet = false

-- Initialize saved variables
RQECharacterDB = RQECharacterDB or {}
RQE.Version = C_AddOns.GetAddOnMetadata("RQE", "Version")
RQE.debugLog("Initialized saved variables.")


-- Initialization
function RQE:SetupDB()
    RQE.options = options  -- if you have options like KT does
    RQE:SetProfileOnce()  -- Now this should work as expected
end


-- Function to set the profile only once
function RQE:SetProfileOnce()
    if not RQE.profileHasBeenSet then
        -- Check if a manual profile choice has been stored.
        local profileToSet = chosenProfile or (UnitName("player") .. " - " .. GetRealmName())

        if type(profileToSet) == "string" then
            RQE.infoLog("Profile set to", profileToSet)
        end
        RQE.profileHasBeenSet = true
    end
end


-- Function to gather character info if addon is set to default to player name instead of account wide
function RQE:GetCharacterInfo()
    local characterName = UnitName("player")
    local characterRealm = GetRealmName()
    local characterKey = characterName .. " - " .. characterRealm

    -- -- Check if character-specific data exists in the database
    -- if not self.db.char.characters then
        -- self.db.char.characters = {}
    -- end

    -- -- Initialize or load character-specific settings
    -- if not self.db.char.characters[characterKey] then
        -- self.db.char.characters[characterKey] = {
		-- -- Initialize character-specific settings here
        -- }
    -- end
end


-- Profile Refresh Function
function RQE:RefreshConfig()
    -- Here, you would reload any saved variables or reset frames, etc.
    -- Basically, apply the settings from the new profile.
	self:UpdateFrameFromProfile()

	-- Refreshes/Reads the Configuration settings for the customized text (in the current/new profile) and calls them when the profile is changed to that from an earlier profile
	RQE:ConfigurationChanged()
end


---------------------------------------------------
-- 8. Toggle Frames
---------------------------------------------------

-- Function to update the state of the frame based on the current profile settings
function RQE:ToggleMainFrame()
    local newValue = not RQE.db.profile.enableFrame
    RQE.db.profile.enableFrame = newValue

    if newValue then
        RQEFrame:Show()
		if RQE.MagicButton then
			RQE.MagicButton:Show()
		end
    else
        RQEFrame:Hide()
		if RQE.MagicButton then
			RQE.MagicButton:Hide()
		end
    end

	-- Check if MagicButton should be visible based on macro body
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- Function to update the state of the minimap based on the current profile settings
function RQE:ToggleMinimapIcon()
    local newValue = not self.db.profile.showMinimapIcon  -- Get the opposite of the current value
    RQE.debugLog("Toggling Minimap Icon. New Value: ", newValue)  -- Debugging line

    self.db.profile.showMinimapIcon = newValue  -- Update the profile value

    if newValue then
        RQE.MinimapButton:Show()
    else
        RQE.MinimapButton:Hide()
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE")
end


-- Function to update the state of the MapID checkbox based on the current profile settings
function RQE:ToggleMapIDCheckbox()
    local newValue = not RQE.db.profile.showMapID
    RQE.db.profile.showMapID = newValue

    -- Add logic here to update your checkbox UI element
    if MapIDCheckbox then
        MapIDCheckbox:SetChecked(newValue)
    end
end


-- Function to Show/Hide RQEFrame when frames are empty
function RQE:UpdateRQEFrameVisibility()
    if InCombatLockdown() then
        return
    end

    local questIDTextContent = self.QuestIDText and self.QuestIDText:GetText() or ""
	local isSuperTracking = C_SuperTrack.GetSuperTrackedQuestID() and C_SuperTrack.GetSuperTrackedQuestID() > 0

    if (self.db.profile.hideRQEFrameWhenEmpty and (questIDTextContent == "" or not isSuperTracking)) or self.isRQEFrameManuallyClosed then
        RQEFrame:Hide()
		if RQE.MagicButton then
			RQE.MagicButton:Hide()
		end
    else
        RQEFrame:Show()
		if RQE.MagicButton then
			RQE.MagicButton:Show()
		end
    end

	-- Check if MagicButton should be visible based on macro body
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- Function to Show/Hide RQEQuestFrame when frames are empty
function RQE:UpdateRQEQuestFrameVisibility()
    if InCombatLockdown() then
        return
    end

    -- Reset counts to 0
    self.campaignQuestCount = 0
    self.regularQuestCount = 0
    self.worldQuestCount = 0

	-- Pull data of number of tracked achievements
	RQE.AchievementsFrame.achieveCount = RQE.GetNumTrackedAchievements()
    self.worldQuestCount = C_QuestLog.GetNumWorldQuestWatches()

    -- Iterate through tracked quests to count them
    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID then
            if C_CampaignInfo.IsCampaignQuest(questID) then
                self.campaignQuestCount = self.campaignQuestCount + 1
            elseif C_QuestLog.IsWorldQuest(questID) then
                self.worldQuestCount = self.worldQuestCount + 1
            else
                self.regularQuestCount = self.regularQuestCount + 1
            end
        end
    end

    -- Check conditions for showing/hiding the frame, including manual closure
    if (self.db.profile.hideRQEQuestFrameWhenEmpty and (self.campaignQuestCount + self.regularQuestCount + self.worldQuestCount + self.AchievementsFrame.achieveCount == 0 and not self.isInScenario)) or self.isRQEQuestFrameManuallyClosed then
        RQEQuestFrame:Hide()
    else
        RQEQuestFrame:Show()
    end

	--RQE.canUpdateFromCriteria = true
end


---------------------------------------------------
-- 9. Update Frames
---------------------------------------------------

-- Function to update MapID display
function RQE:UpdateMapIDDisplay()
	local mapID = C_Map.GetBestMapForUnit("player")
	--UpdateWorldQuestTrackingForMap(mapID)

    if RQE.db.profile.showMapID and mapID then
        RQEFrame.MapIDText:SetText("MapID: " .. mapID)
    else
        RQEFrame.MapIDText:SetText("")
    end
end


-- Function to update Memory Usage display
function RQE:UpdateMemUsageDisplay()
    if RQE.db.profile.showMapID and mapID then
        RQEFrame.MemoryUsageText:SetText("RQE Usage: " .. mapID)
    else
        RQEFrame.MemoryUsageText:SetText("")
    end
end


-- Function to update the frame based on the current profile settings
function RQE:UpdateFramePosition()
    -- When reading from DB
    local anchorPoint = self.db.profile.framePosition.anchorPoint or "TOPRIGHT"
	RQE.debugLog("anchorPoint in RQE:UpdateFramePosition is ", anchorPoint)  -- Debug statement

    -- Validation
    local validAnchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
    if not tContains(validAnchorPoints, anchorPoint) then
        anchorPoint = "TOPRIGHT"  -- Set to default
    end

    local xPos = self.db.profile.framePosition.xPos or -40
    local yPos = self.db.profile.framePosition.yPos or -270

    RQE.infoLog("About to SetPoint xPos: " .. xPos .. " yPos: " .. yPos .. " anchorPoint: " .. anchorPoint .. " IsShown: " .. tostring(RQEFrame:IsShown()))

    -- Error handling
    local success, err = pcall(function()
        RQEFrame:ClearAllPoints()
        RQEFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
    end)

    if not success then
        RQE.debugLog("Error setting frame position: ", err)
    end
end


-- Function to update the RQEQuestFrame based on the current profile settings
function RQE:UpdateQuestFramePosition()
    -- When reading from DB, replace with the appropriate keys for RQEQuestFrame
    local anchorPoint = self.db.profile.QuestFramePosition.anchorPoint or "CENTER"

    -- Validation
    local validAnchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
    if not tContains(validAnchorPoints, anchorPoint) then
        anchorPoint = "BOTTOMRIGHT"  -- Set to default
    end

    local xPos = self.db.profile.QuestFramePosition.xPos or -40
    local yPos = self.db.profile.QuestFramePosition.yPos or 150

    -- Error handling
    local success, err = pcall(function()
        RQEQuestFrame:ClearAllPoints()
        RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
    end)

    if not success then
        RQE.debugLog("Error setting quest frame position: ", err)
    end
end


-- Function to update the RQEFrame size based on the current profile settings
function RQE:UpdateFrameSize()
    -- When reading from DB
    local frameWidth = self.db.profile.framePosition.frameWidth or 400
    local frameHeight = self.db.profile.framePosition.frameHeight or 300

    -- Error handling for main frame
    local success, err = pcall(function()
        RQEFrame:SetSize(frameWidth, frameHeight)
    end)

    if not success then
        RQE.debugLog("Error setting main frame size: ", err)
    end
end


-- Function to update the RQEQuestFrame size based on the current profile settings
function RQE:UpdateQuestFrameSize()
    -- Update the quest frame size similarly, using its respective profile settings
    local questFrameWidth = self.db.profile.QuestFramePosition.frameWidth or 300
    local questFrameHeight = self.db.profile.QuestFramePosition.frameHeight or 450

    -- Error handling for quest frame
    local success, err = pcall(function()
        RQEQuestFrame:SetSize(questFrameWidth, questFrameHeight)
    end)

    if not success then
        RQE.debugLog("Error setting quest frame size: ", err)
    end
end


-- ClearFrameData function
function RQE:ClearFrameData()
	-- Clear the Quest ID and Quest Name
    if RQE.QuestIDText then
        RQE.QuestIDText:SetText("")
    end

    if RQE.QuestNameText then
        RQE.QuestNameText:SetText("")
    end

	if RQE.QuestNameText then
		RQE.debugLog("QuestNameText current text:", RQE.QuestNameText:GetText())
	end

	-- Clear StepsText elements
	if RQE.StepsTexts then
	  for _, text in pairs(RQE.StepsTexts) do
		text:SetText("")  -- Clear the text of each element
	  end
	end

    -- Clear CoordsText elements
    if RQE.CoordsTexts then
        for _, text in pairs(RQE.CoordsTexts) do
            text:SetText("")
        end
    end

	-- Clear QuestDirection Text
	if RQE.DirectionTextFrame then
		RQE.DirectionTextFrame:SetText("")
	end

    -- Clear QuestDescription Text
    if RQE.QuestDescription then
        RQE.QuestDescription:SetText("")
    end

    -- Clear QuestObjectives Text
    if RQE.QuestObjectives then
        RQE.QuestObjectives:SetText("")
    end

	-- Clear Unknown Quests Button
	if RQE.UnknownQuestButton then
		RQE.UnknownQuestButton:Hide()
	end

	-- Clear SearchGroup Button
	if RQE.SearchGroupButton and RQE.SearchGroupButton:IsShown() then
		RQE.SearchGroupButton:Hide()
	end

	RQE:ClearStepsTextInFrame()

	-- Check if MagicButton should be visible based on macro body
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- Clear Waypoint Buttons
function RQE:ClearWaypointButtonData()
    if RQE.WaypointButtons then
        for _, button in pairs(RQE.WaypointButtons) do
            button:Hide()
        end
    end
end


-- Colorization of the RQEFrame
local function colorizeObjectives(questID)
	if not questID then
		return
	end

    local objectivesData = C_QuestLog.GetQuestObjectives(questID)
    local colorizedText = ""

    if objectivesData then  -- Check if the data is not nil
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
    else
        -- Handle the case where objectivesData is nil
        colorizedText = "No objectives data available."
    end

    return colorizedText
end


-- Simulates pressing the "Clear Window" Button
function RQE:PerformClearActions()
    RQE:ClearFrameData()
    RQE.searchedQuestID = nil
    RQE.ManualSuperTrack = nil
    C_SuperTrack.ClearSuperTrackedContent()
    RQE:UpdateRQEFrameVisibility()
    -- Reset manually tracked quests
    if RQE.ManuallyTrackedQuests then
        for questID in pairs(RQE.ManuallyTrackedQuests) do
            RQE.ManuallyTrackedQuests[questID] = nil
        end
    end
end


-- Function check if RQEFrame frame should be cleared
function RQE:ShouldClearFrame()
    -- Attempt to directly extract questID from RQE.QuestIDText if available
    local extractedQuestID
    if RQE.QuestIDText and RQE.QuestIDText:GetText() then
        extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
    end

    -- Early exit if there's still no valid questID
    if not extractedQuestID or extractedQuestID == 0 then
        return
    end

	-- Clears RQEFrame if listed quest is not one that is presently in the player's quest log or is being searched
    local isQuestInLog = C_QuestLog.IsOnQuest(extractedQuestID)
	local isWorldQuest = C_QuestLog.IsWorldQuest(extractedQuestID)
	local isBeingSearched = RQE.searchedQuestID == extractedQuestID
	local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(extractedQuestID)
    local manuallyTracked = RQE.ManuallyTrackedQuests and RQE.ManuallyTrackedQuests[extractedQuestID]

    local watchedQuests = {}
    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local watchedQuestID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if watchedQuestID then
            watchedQuests[watchedQuestID] = true
        end
    end
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local watchedWorldQuestID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if watchedWorldQuestID then
            watchedQuests[watchedWorldQuestID] = true
        end
    end

	-- Clears from RQEFrame searched world quests that have been completed
	if isBeingSearched and isQuestCompleted and isWorldQuest then
        RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQEMacro:ClearMacroContentByName("RQE Macro")
        return -- Exit the function early
	end

	if (isQuestCompleted and not isBeingSearched and not isQuestInLog) or (not isQuestInLog and not manuallyTracked and not isBeingSearched) then
	--if (isQuestCompleted and not isBeingSearched and not isQuestInLog) or (not isQuestInLog and not manuallyTracked) then
        -- Clear the RQEFrame if the quest is not in the log or does not match the searched quest ID
        RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQEMacro:ClearMacroContentByName("RQE Macro")
        return -- Exit the function early
    end

    if isWorldQuest then
		if not (manuallyTracked or (isBeingSearched and not isQuestCompleted) or watchedQuests[extractedQuestID]) then
        --if not (manuallyTracked or (isBeingSearched and not isQuestCompleted)) then
            RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQEMacro:ClearMacroContentByName("RQE Macro")
            return -- Exit the function early
        end
    else
        -- For non-world quests, clear if not in quest log or not being actively searched
		if not (isBeingSearched or manuallyTracked or watchedQuests[extractedQuestID]) then
            RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQEMacro:ClearMacroContentByName("RQE Macro")
            return -- Exit the function early
        end
    end

	-- Call the delayed clear check
	RQE:DelayedClearCheck()
end


-- Function to initiate a delayed re-check and clear operation
function RQE:DelayedClearCheck()
    C_Timer.After(3, function()
		-- Attempt to directly extract questID from RQE.QuestIDText if available
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Early exit if there's still no valid questID
		if not extractedQuestID or extractedQuestID == 0 then
			return
		end

		-- Clears RQEFrame if listed quest is not one that is presently in the player's quest log or is being searched
		local isQuestInLog = C_QuestLog.IsOnQuest(extractedQuestID)
		local isWorldQuest = C_QuestLog.IsWorldQuest(extractedQuestID)
		local isBeingSearched = RQE.searchedQuestID == extractedQuestID
		local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(extractedQuestID)
		local manuallyTracked = RQE.ManuallyTrackedQuests and RQE.ManuallyTrackedQuests[extractedQuestID]

		local watchedQuests = {}
		for i = 1, C_QuestLog.GetNumQuestWatches() do
			local watchedQuestID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if watchedQuestID then
				watchedQuests[watchedQuestID] = true
			end
		end
		for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
			local watchedWorldQuestID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if watchedWorldQuestID then
				watchedQuests[watchedWorldQuestID] = true
			end
		end

		-- Clears from RQEFrame searched world quests that have been completed
		if isBeingSearched and isQuestCompleted and isWorldQuest then
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQEMacro:ClearMacroContentByName("RQE Macro")

			-- Untrack the quest by setting a non-existent quest ID
			C_SuperTrack.SetSuperTrackedQuestID(0)

			return -- Exit the function early
		end

		if isWorldQuest then
			if not (manuallyTracked or (isBeingSearched and not isQuestCompleted) or watchedQuests[extractedQuestID]) then
				RQE:ClearFrameData()
				RQE:ClearWaypointButtonData()
				RQEMacro:ClearMacroContentByName("RQE Macro")

				-- Untrack the quest by setting a non-existent quest ID
				C_SuperTrack.SetSuperTrackedQuestID(0)

				return -- Exit the function early
			end
        end
    end)
end


-- UpdateFrame function
function UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
    -- Retrieve the current super-tracked quest ID for debugging
    local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local extractedQuestID
    if RQE.QuestIDText and RQE.QuestIDText:GetText() then
        extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
    end

    -- Use RQE.searchedQuestID if available; otherwise, fallback to extractedQuestID, then to currentSuperTrackedQuestID
    questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID

    -- Fetch questInfo from RQEDatabase using the determined questID
    questInfo = RQE.getQuestData(questID) or questInfo

	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	AdjustRQEFrameWidths(newWidth)

    -- Debug print the overridden questID and the content of RQE.QuestIDText
    RQE.infoLog("Overridden questID with current super-tracked questID:", questID)
    if RQE.QuestIDText and RQE.QuestIDText:GetText() then
        RQE.infoLog("RQE.QuestIDText content:", RQE.QuestIDText:GetText())
    end

    -- Validate questID before proceeding
    if not questID or type(questID) ~= "number" then
        return
    end

    if not questID then  -- Check if questID is nil
        return  -- Exit the function
    end

    -- Check if the currently super-tracked quest is different from the extractedQuestID and if manual tracking is enabled
    if RQE.ManualSuperTrack ~= true and currentSuperTrackedQuestID ~= extractedQuestID and extractedQuestID then
        -- Re-super-track the extractedQuestID
		RQE.infoLog("Super-tracking incorrectly changed, swapping it back to " .. extractedQuestID)
        C_SuperTrack.SetSuperTrackedQuestID(extractedQuestID)
		UpdateRQEQuestFrame()
    else
		UpdateRQEQuestFrame()
	end

    if not StepsText or not CoordsText or not MapIDs then
        return
    end

    if RQE.QuestIDText then
        RQE.QuestIDText:SetText("Quest ID: " .. (questID or "N/A"))
    end

	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	local questName

	-- Using the centralized data access function to fetch quest data
	local questData = RQE.getQuestData(questID)

	if questData and questData.title then
		questName = questData.title  -- Use title from questData if available
	else
		questName = C_QuestLog.GetTitleForQuestID(questID)  -- Fallback to game's API call if no title is found in your databases
	end

	questName = questName or "N/A"  -- Default to "N/A" if no title found

	if RQE.QuestNameText then
		RQE.QuestNameText:SetText("Quest Name: " .. questName)
	end

	if questInfo then
		RQE.infoLog("questInfo.description is ", questInfo.description)
		RQE.infoLog("questInfo.objectives is ", questInfo.objectives)

		if RQE.CreateStepsText then  -- Check if CreateStepsText is initialized
			RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
		end
	end

    -- For QuestDescription
	if RQE.QuestDescription then  -- Check if QuestDescription is initialized
		local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
		if questLogIndex then
			local _, questObjectives = GetQuestLogQuestText(questLogIndex)
			local QuestDescription = questObjectives
			local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."

			if RQE.QuestDescription then  -- Check if QuestDescription is initialized
				RQE.QuestDescription:SetText(descriptionText)
			end
		end
	end

    -- For QuestObjectives
    local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
    local objectivesText = objectivesTable and "" or "No objectives available."
    if objectivesTable then
        for _, objective in pairs(objectivesTable) do
            objectivesText = objectivesText .. objective.text .. "\n"
        end
    end

    -- Apply colorization to objectivesText
    objectivesText = colorizeObjectives(questID)

    if RQE.QuestObjectives then  -- Check if QuestObjectives is initialized
        RQE.QuestObjectives:SetText(objectivesText)
    else
        RQE.debugLog("RQE.QuestObjectives is not initialized.")
    end

    -- Fetch the next waypoint text for the quest
	local DirectionText = C_QuestLog.GetNextWaypointText(questID)
	RQEFrame.DirectionText = DirectionText  -- Save to addon table
	--RQE.UnknownQuestButton:Click() -- incorrect non-existent function call as it instead needs RQE.UnknownQuestButtonCalcNTrack() to update the waypoint on quest progress changes
	RQE.UnknownQuestButtonCalcNTrack()

	-- Assuming you have a UI element named DirectionTextFrame
	if RQE.DirectionTextFrame then
		RQE.DirectionTextFrame:SetText(DirectionText or "No direction available.")
	end

	-- Always show the UnknownQuestButton
    RQE.UnknownQuestButton:Show()

	-- Runs a check to see if the super tracked quest allows for forming quest group (such as World Boss WQ)
    if questID and C_LFGList.CanCreateQuestGroup(questID) then
        -- If a quest group can be created for this quest, show the button
        RQE.SearchGroupButton:Show()
    else
        -- Otherwise, hide the button
        RQE.SearchGroupButton:Hide()
    end

    -- Adjust description and objectives based on whether RQE.searchedQuestID matches questID
    if RQE.searchedQuestID and RQE.searchedQuestID == questID then
		-- Check if the quest is in the player's quest log
		local isQuestInLog = C_QuestLog.IsOnQuest(questID)
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)

        -- When the RQEFrame is updated for a searched quest that is not in the player's quest log
		if not isQuestInLog and not isWorldQuest then  -- If the quest is not in the log and not a World Quest, update the texts accordingly
			if RQE.QuestDescription then
				RQE.QuestDescription:SetText("")  -- Leave blank
			end

			if RQE.QuestObjectives and not isQuestCompleted then
				RQE.QuestObjectives:SetText("Quest not located in player's Log, please pick up quest")
				RQE.QuestObjectives:SetTextColor(1, 1, 1) -- White color for completed criteria
			end
			if RQE.QuestObjectives and isQuestCompleted then
				RQE.QuestObjectives:SetText("Quest has been marked as completed for player")
				RQE.QuestObjectives:SetTextColor(0, 1, 0) -- Green color for completed criteria
			end
		end
	end

	-- Check to see if the RQEFrame should be cleared
	RQE:ShouldClearFrame()

	-- Visibility Update Check for RQEMagic Button
	C_Timer.After(1, function()
		RQE.Buttons.UpdateMagicButtonVisibility()
	end)
end


-- Function for Tracking World Quests
function UpdateWorldQuestTrackingForMap(uiMapID)
    if not uiMapID then
        RQE.errorLog("Invalid map ID provided to UpdateWorldQuestTrackingForMap")
        return  -- Early exit if uiMapID is invalid
    end

    local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
    local trackedQuests = {}
    local maxTracked = 1
    local currentTrackedCount = 0  -- Initialize the counter for tracked quests

    -- Retrieve the currently tracked quests to avoid duplicates
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local watchedQuestID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if watchedQuestID then
            trackedQuests[watchedQuestID] = true
            currentTrackedCount = currentTrackedCount + 1
        end
    end

    if taskPOIs and currentTrackedCount < maxTracked then
        RQE.infoLog("Found " .. #taskPOIs .. " taskPOIs for map ID: " .. uiMapID)
        for _, taskPOI in ipairs(taskPOIs) do
            local questID = taskPOI.questId
            if questID and C_QuestLog.IsWorldQuest(questID) then
                RQE.debugLog("Checking World QuestID: " .. questID)
                -- Check if the quest is already tracked
				if not trackedQuests[questID] then
					C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
					trackedQuests[questID] = true  -- Mark as tracked
					currentTrackedCount = currentTrackedCount + 1  -- Increment the count
					RQE.infoLog("Manual World QuestID: " .. questID .. " added to watch list.")

					-- Check if we've reached the maximum number of tracked quests
					if currentTrackedCount >= maxTracked then
						RQE.debugLog("Reached the maximum number of tracked World Quests: " .. maxTracked)
						break  -- Exit the loop as we've reached the limit
					end
				else
                    RQE.infoLog("Manual World QuestID: " .. questID .. " added to watch list.")
                end
            end
        end
    end
end


-- Remove Tracking of all World Quests
function RemoveAllTrackedWorldQuests()
    -- Get the number of currently tracked World Quests
    local numWorldQuestWatches = C_QuestLog.GetNumWorldQuestWatches()

    -- Loop backwards through the list of tracked World Quests
    -- Backwards iteration is necessary because removing a quest changes the indices
    for i = numWorldQuestWatches, 1, -1 do
        -- Get the quest ID of the ith tracked World Quest
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            -- Remove the World Quest from being tracked
            C_QuestLog.RemoveWorldQuestWatch(questID)
        end
    end
end


---------------------------------------------------
-- 10. Scenario Functions
---------------------------------------------------

-- Function to fetch/print Scenario Criteria information
function RQE.PrintScenarioCriteriaInfo()
    local numCriteria = select(3, C_Scenario.GetStepInfo())
    if not numCriteria or numCriteria == 0 then
        return
    end
    for criteriaIndex = 1, numCriteria do
        local criteriaString, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, duration, elapsed, criteriaFailed, isWeightedProgress = C_Scenario.GetCriteriaInfo(criteriaIndex)
        RQE.infoLog("Criteria Index:", criteriaIndex)
        RQE.infoLog("Criteria String:", criteriaString or "N/A")
        RQE.infoLog("Criteria Type:", criteriaType or "N/A")
        RQE.infoLog("Completed:", completed)
        RQE.infoLog("Quantity:", quantity or "N/A")
        RQE.infoLog("Total Quantity:", totalQuantity or "N/A")
        RQE.infoLog("Flags:", flags or "N/A")
        RQE.infoLog("Asset ID:", assetID or "N/A")
        RQE.infoLog("Quantity String:", quantityString or "N/A")
        RQE.infoLog("Criteria ID:", criteriaID or "N/A")
        RQE.infoLog("Duration:", duration or "N/A")
        RQE.infoLog("Elapsed:", elapsed or "N/A")
        RQE.infoLog("Criteria Failed:", criteriaFailed)
        RQE.infoLog("Is Weighted Progress:", isWeightedProgress)
    end
end


-- Function to fetch/print Scenario Criteria Step by Step
function RQE.PrintScenarioCriteriaInfoByStep()
    local currentStep, numSteps = C_Scenario.GetInfo()
    for stepID = 1, numSteps do
        local _, _, numCriteria = C_Scenario.GetStepInfo(stepID)
        if not numCriteria or numCriteria == 0 then
            RQE.debugLog("No criteria info available for step", stepID)
        else
            for criteriaIndex = 1, numCriteria do
                local criteriaString, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, duration, elapsed, criteriaFailed, isWeightedProgress = C_Scenario.GetCriteriaInfoByStep(stepID, criteriaIndex)
                RQE.infoLog("Step ID:", stepID)
                RQE.infoLog("Criteria Index:", criteriaIndex)
                RQE.infoLog("Criteria String:", criteriaString or "N/A")
                RQE.infoLog("Criteria Type:", criteriaType or "N/A")
                RQE.infoLog("Completed:", completed)
                RQE.infoLog("Quantity:", quantity or "N/A")
                RQE.infoLog("Total Quantity:", totalQuantity or "N/A")
                RQE.infoLog("Flags:", flags or "N/A")
                RQE.infoLog("Asset ID:", assetID or "N/A")
                RQE.infoLog("Quantity String:", quantityString or "N/A")
                RQE.infoLog("Criteria ID:", criteriaID or "N/A")
                RQE.infoLog("Duration:", duration or "N/A")
                RQE.infoLog("Elapsed:", elapsed or "N/A")
                RQE.infoLog("Criteria Failed:", criteriaFailed)
                RQE.infoLog("Is Weighted Progress:", isWeightedProgress)
            end
        end
    end
end


-- Updates the timer display
function RQE.Timer_OnUpdate(self, elapsed)
    if not self then
        return  -- Exit the function if self is nil
    end

    -- Initialize timeSinceLastUpdate if it's nil
    if not self.timeSinceLastUpdate then
        self.timeSinceLastUpdate = 0
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed

    if self.timeSinceLastUpdate >= 1 then  -- Update the timer every second
        local timeLeft = self.endTime - GetTime()  -- Calculate the remaining time
        if timeLeft > 0 then
            -- Update your timer display here
            RQE.ScenarioChildFrame.timer:SetText(SecondsToTime(timeLeft))
        else
            RQE.Timer_Stop()  -- Stop the timer if the time has elapsed
        end
        self.timeSinceLastUpdate = 0
    end
end


-- Start the timer and shows the UI elements
function RQE.Timer_Start(duration)
    local timerFrame = RQE.ScenarioChildFrame.timerFrame
    if not timerFrame then
        return
    end

    timerFrame.endTime = GetTime() + duration
    timerFrame:SetScript("OnUpdate", RQE.Timer_OnUpdate)
	RQE.TimerFrame = timerFrame
    timerFrame:Show()
end


-- Stops the timer and hides the UI elements
function RQE.Timer_Stop()
    local timerFrame = RQE.ScenarioChildFrame.timerFrame  -- Your custom timer frame

    if not timerFrame then
        return  -- Ensure the frame exists
    end

    -- Stop the OnUpdate script and hide the frame
    timerFrame:SetScript("OnUpdate", nil)
    timerFrame:Hide()
end


--Checks active timers and starts/stops the timer as necessary
function RQE.Timer_CheckTimers()
    -- Retrieve the timer information (example: for the first criteria)
    local duration, elapsed = select(10, C_Scenario.GetCriteriaInfo(1))
	RQE.infoLog("[CheckTimers] Duration is " .. tostring(duration))
	RQE.infoLog("[CheckTimers] Elapsed is " .. tostring(elapsed))

    -- Check if duration and elapsed are valid before proceeding
    if duration and elapsed then
        local timeLeft = duration - elapsed
        RQE.infoLog("Duration is " .. tostring(duration))
        RQE.infoLog("Elapsed is " .. tostring(elapsed))

        if timeLeft > 0 then
            RQE.Timer_Start(timeLeft)
        else
            RQE.Timer_Stop()
        end
    else
        RQE.Timer_Stop()
        if not duration then
            RQE.infoLog("Duration is nil")
        end
        if not elapsed then
            RQE.infoLog("Elapsed is nil")
        end
    end
end


-- Function to map Torghast type enum to a readable string
function RQE.ConvertTorghastTypeToString(eventType)
    local typeMapping = {
        [0] = "Twisting Corridors",
        [1] = "Skoldus Halls",
        [2] = "Fracture Chambers",
        [3] = "Soulforges",
        [4] = "Coldheart",
        [5] = "Mortregar",
        [6] = "Upper Reaches",
        [7] = "Arkoban Hall",
        [8] = "Torment Chamber: Jaina",
        [9] = "Torment Chamber: Thrall",
        [10] = "Torment Chamber: Anduin",
        [11] = "Adamant Vaults",
        [12] = "Forgotten Catacombs",
        [13] = "Ossuary",
        [14] = "Boss Rush",
    }
    return typeMapping[eventType] or "Unknown Type"
end


-- Function to update Torghast details in the RQE table
function RQE.UpdateTorghastDetails(eventLevel, eventType)
    local level = GetJailersTowerLevel()
    local layerNum, floorID

    -- Calculate the Torghast layer number and floor ID based on the level
    if level then
        layerNum = math.ceil(level / 6)
        floorID = level % 6
        floorID = floorID == 0 and 6 or floorID  -- Adjust for floors that are multiples of 6
    else
        return
    end

    -- Assuming the JAILERS_TOWER_LEVEL_UPDATE event provides 'level' and 'type' as parameters
    -- Update only if eventType is provided, indicating the function was called via event
    if eventType then
        RQE.TorghastType = eventType
        RQE.TorghastLayerNum = layerNum
        RQE.TorghastFloorID = floorID

        local typeString = RQE.ConvertTorghastTypeToString(eventType) -- Ensure this function exists
        RQE.infoLog(string.format("You are in Torghast: %s, Layer: %d, Floor: %d",
            typeString or "Unknown Type", layerNum, floorID))
    end
end


---------------------------------------------------
-- 11. Maximize/Minimize/Opacity Change to Frames
---------------------------------------------------

-- Function for Button in Configuration that will reset the anchorPoint, xPos and yPos to what is listed in the DB file
function RQE:ResetFramePositionToDBorDefault()
    local anchorPoint = "TOPRIGHT"  -- Always set to TOPRIGHT
    local xPos = -40  -- Preset xPos
    local yPos = -270  -- Preset yPos

    -- Update the database
    RQE.db.profile.framePosition.anchorPoint = anchorPoint
    RQE.db.profile.framePosition.xPos = xPos
    RQE.db.profile.framePosition.yPos = yPos

    -- Update the frame position
    RQE:UpdateFramePosition()
end


-- Function for Button in Configuration that will reset the size of the RQEFrame and RQEQuestFrame to default values
function RQE:ResetFrameSizeToDBorDefault()
    local RQEWidth = 435
    local RQEHeight = 300
    local RQEQuestWidth = 325
    local RQEQuestHeight = 450

    -- Update the database
    RQE.db.profile.framePosition.frameWidth = RQEWidth
    RQE.db.profile.framePosition.frameHeight = RQEHeight
    RQE.db.profile.QuestFramePosition.frameWidth = RQEQuestWidth
    RQE.db.profile.QuestFramePosition.frameHeight = RQEQuestHeight

    -- Update the frame position
    SaveRQEFrameSize()
	SaveQuestFrameSize()

    -- Directly update the frame sizes
    if RQEFrame then
        RQEFrame:SetSize(RQEWidth, RQEHeight)
    end
    if RQEQuestFrame then
        RQEQuestFrame:SetSize(RQEQuestWidth, RQEQuestHeight)
    end
end


-- When the frame is maximized
function RQE:MaximizeFrame()
    local defaultWidth = RQE.db.profile.frameWidth or 400  -- Replace 400 with the default from Core.lua
    local defaultHeight = RQE.db.profile.frameHeight or 300  -- Replace 300 with the default from Core.lua

    local width = RQE.db.profile.framePosition.originalWidth or defaultWidth
    local height = RQE.db.profile.framePosition.originalHeight or defaultHeight

    RQEFrame:SetSize(width, height)
    RQE.db.profile.isFrameMaximized = true
end


-- When the frame is minimized
function RQE:MinimizeFrame()
    RQEFrame:SetSize(435, 30)  -- If you want to make this configurable, you can use similar logic as above
    RQE.db.profile.isFrameMaximized = false
end


-- Function to Update the Opacity of Main Frame and Quest Tracker
function RQE:UpdateFrameOpacity()
    if RQEFrame then
        RQEFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.MainFrameOpacity)
    end
    if RQE.RQEQuestFrame then
        RQE.RQEQuestFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.QuestFrameOpacity)
    end
end


-- Function for Button in Configuration that will reset the anchorPoint, xPos and yPos to what is listed in the DB file
function RQE:ResetQuestFramePositionToDBorDefault()
    local anchorPoint = "BOTTOMRIGHT"  -- Default anchor point for RQEQuestFrame
    local xPos = -40  -- Preset xPos
    local yPos = 150  -- Preset yPos

    -- Update the database
    RQE.db.profile.QuestFramePosition.anchorPoint = anchorPoint
    RQE.db.profile.QuestFramePosition.xPos = xPos
    RQE.db.profile.QuestFramePosition.yPos = yPos

    -- Update the frame position
    RQE:UpdateQuestFramePosition()
end


-- When the frame is maximized
function RQE:MaximizeQuestFrame()
    local defaultWidth = RQE.db.profile.QuestFrameWidth or 300  -- Replace 300 with the default width
    local defaultHeight = RQE.db.profile.QuestFrameHeight or 450  -- Replace 450 with the default height

    local width = RQE.db.profile.QuestFramePosition.originalWidth or defaultWidth
    local height = RQE.db.profile.QuestFramePosition.originalHeight or defaultHeight

    RQEQuestFrame:SetSize(width, height)
    RQE.db.profile.isQuestFrameMaximized = true
end


-- When the frame is minimized
function RQE:MinimizeQuestFrame()
    RQEQuestFrame:SetSize(300, 30)  -- If you want to make this configurable, you can use similar logic as above
    RQE.db.profile.isQuestFrameMaximized = false
end


---------------------------------------------------
-- 12. Event Handling
---------------------------------------------------

-- Check for TomTom load
local function TomTom_Loaded(self, event, addon)
    if addon == "TomTom" then
        self:UnregisterEvent("ADDON_LOADED")
    end
end


---------------------------------------------------
-- 13. UI Components
---------------------------------------------------

-- Initialize RQEFrame
RQEFrame = RQEFrame or CreateFrame("Frame", "RQEFrame", UIParent)


-- Initialize other UI components like MinimizeButton, MaximizeButton, etc.
RQE.MinimizeButton = RQE.MinimizeButton or {}
RQE.MaximizeButton = RQE.MaximizeButton or {}


-- Initialize SearchEditBox (Make it global if you want to access it from other files)
SearchEditBox = CreateFrame("EditBox", "RQESearchEditBox", RQEFrame, "InputBoxTemplate")


-- Initialize position, size, etc. for SearchEditBox
SearchEditBox:SetAutoFocus(false)
SearchEditBox:SetWidth(100)
SearchEditBox:SetHeight(20)
SearchEditBox:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 10, -10) -- Adjust the position as needed
SearchEditBox:SetFontObject("GameFontNormal")
SearchEditBox:SetText("Edit...")  -- Default text


---------------------------------------------------
-- 14. Search Module
---------------------------------------------------

RQE.SearchModule = {}

-- Function to create the Search Box with an Examine button
function RQE.SearchModule:CreateSearchBox()
    local editBox = AceGUI:Create("EditBox")
    editBox:SetLabel("Enter Quest ID or Title:")
    editBox:SetWidth(200)
    editBox:SetCallback("OnEnterPressed", function(widget, event, text)
        local questID = tonumber(text)
        local foundQuestIDs = {} -- Initialize the table here to store all found quest IDs
        local inputTextLower = string.lower(text) -- Convert input text to lowercase for case-insensitive comparison

        -- Search logic modified to accumulate all matching quest IDs
        if questID then
            -- Direct use of numeric ID
            table.insert(foundQuestIDs, questID)
        else
            -- Search across all databases for matching quest titles
            for dbName, db in pairs(RQEDatabase) do
                for id, questData in pairs(db) do
                    if questData.title and string.find(string.lower(questData.title), inputTextLower) then
                        table.insert(foundQuestIDs, id) -- Add all matching IDs
                    end
                end
            end
        end

        -- Handling multiple found quest IDs
        for _, foundQuestID in ipairs(foundQuestIDs) do
            local questLink = GetQuestLink(foundQuestID)
            local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(foundQuestID)

            if questLink then
                print("Quest ID: " .. foundQuestID .. " - " .. questLink)
            else
                local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
                print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6[" .. questName .. "]|r")
            end

            if isQuestCompleted then
                DEFAULT_CHAT_FRAME:AddMessage("Quest completed by character", 0, 1, 0)  -- Green text
            else
                DEFAULT_CHAT_FRAME:AddMessage("Quest not completed by character", 1, 0, 0)  -- Red text
            end
        end

        -- Additional handling for no matches or multiple matches as needed
        if #foundQuestIDs == 0 then
            print("No matching quests found.")
        elseif #foundQuestIDs > 1 then
            print("Multiple matches found. Listing all.")
        end
    end)

    local examineButton = AceGUI:Create("Button")
    examineButton:SetText("Track")
    examineButton:SetWidth(100)

    examineButton:SetCallback("OnClick", function()
        local inputText = editBox:GetText()
        local questID = tonumber(inputText)
        local foundQuestID = nil
        local inputTextLower = string.lower(inputText) -- Convert input text to lowercase for case-insensitive comparison

		-- Simulates pressing the "Clear Window" Button before proceeding with rest of function
		RQE:PerformClearActions()
		RQE:ClearWaypointButtonData()

        if not questID then
            for id, questData in pairs(RQEDatabase) do
                if questData.title and string.find(string.lower(questData.title), inputTextLower) then
                    foundQuestID = id
                    break
                end
            end
        else
            foundQuestID = questID
        end

        if foundQuestID then
			-- This is where you place the logic for updating location data
			local questData = RQE.getQuestData(foundQuestID)
			if questData and questData.location then
				-- Update the location data for the examined quest
				RQE.DatabaseSuperX = questData.location.x / 100
				RQE.DatabaseSuperY = questData.location.y / 100
				RQE.DatabaseSuperMapID = questData.location.mapID
			end

			-- Local Variables for World Quest/Quest in Log
			local isWorldQuest = C_QuestLog.IsWorldQuest(foundQuestID)
			local isQuestInLog = C_QuestLog.IsOnQuest(foundQuestID)

			-- Found a quest, now set it as the searchedQuestID
			RQE.searchedQuestID = foundQuestID

			-- Super Track the Searched Quest if in the Quest Log
			if isQuestInLog then
				C_SuperTrack.SetSuperTrackedQuestID(foundQuestID)
			end

			-- Add the quest to the tracker		
			if isWorldQuest then
				C_QuestLog.AddWorldQuestWatch(foundQuestID, watchType or Enum.QuestWatchType.Manual)
			else
				C_QuestLog.AddQuestWatch(foundQuestID, Enum.QuestWatchType.Manual)
			end

            -- Print quest link or name
            local questLink = GetQuestLink(foundQuestID)
            if questLink then
                print("Quest ID: " .. foundQuestID .. " - " .. questLink)
            else
                local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
                print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6[" .. questName .. "]|r")
            end

            -- Call UpdateFrame to populate RQEFrame with quest details, if the quest exists in RQEDatabase
            -- This is the new line added to trigger the update based on the foundQuestID
            if questData then
                local questInfo = RQE.getQuestData(foundQuestID)
                UpdateFrame(foundQuestID, questInfo, {}, {}, {}) -- Assuming UpdateFrame handles empty tables gracefully
            end
        else
            print("Invalid Quest ID or Title for Examination")
        end
    end)

    return editBox, examineButton
end


---------------------------------------------------
-- 15. Utility Functions
---------------------------------------------------

-- InitializeAddon function
function RQE:InitializeAddon()
    -- Initializes the Tracked Achievements
	RQE.UpdateTrackedAchievements()
	RQE.UpdateTrackedAchievementList()
end


-- Function to update Coordinates display
function RQE:UpdateCoordinates()
    local mapID = C_Map.GetBestMapForUnit("player")

    -- Check if the mapID is valid before proceeding
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if RQEFrame.CoordinatesText then  -- Check if CoordinatesText is initialized
            if RQE.db.profile.showCoordinates and position then
                local x, y = position:GetXY()
                x = x * 100  -- converting to percentage
                y = y * 100  -- converting to percentage
                RQEFrame.CoordinatesText:SetText(string.format("Coordinates: %.2f, %.2f", x, y))
            else
                RQEFrame.CoordinatesText:SetText("")
            end
        else
            RQE.debugLog("RQEFrame.CoordinatesText is not initialized.")
        end
    else
        -- If mapID is invalid, don't try to update coordinates and clear any existing coordinate text
        if RQEFrame.CoordinatesText then
            RQEFrame.CoordinatesText:SetText("")
        end
    end
end


-- Function to toggle the visibility of the RQE frame
function RQE:ToggleRQEFrame()
    if self.db == nil then
        RQE.debugLog("self.db is nil in ToggleRQEFrame")
        return
    end
    if self.db.profile == nil then
        RQE.debugLog("self.db.profile is nil in ToggleRQEFrame")
        return
    end
    if RQEFrame:IsShown() then
        RQEFrame:Hide()
		if RQE.MagicButton then
			RQE.MagicButton:Hide()
		end
        self.db.profile.enableFrame = false
    else
        RQEFrame:Show()
		if RQE.MagicButton then
			RQE.MagicButton:Show()
		end
        self.db.profile.enableFrame = true
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE")

	-- Check if MagicButton should be visible based on macro body
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- Function to toggle the visibility of the RQEQuestFrame
function RQE:ToggleRQEQuestFrame()
    if self.db.profile.enableQuestFrame then
        -- Code to show the Quest Frame
        RQEQuestFrame:Show()
    else
        -- Code to hide the Quest Frame
        RQEQuestFrame:Hide()
    end
end


-- Clears RQEQuestFrame World Quest Scenario before refreshing Entire Quest Tracker
function RQE:ClearWQTracking()
	RQE:ClearRQEWorldQuestFrame()
	QuestType()
end


function RQE:AbandonQuest(questID)
    if not questID then return end  -- Ensure questID is valid

    local oldSelectedQuest = C_QuestLog.GetSelectedQuest()
    C_QuestLog.SetSelectedQuest(questID)
	local questLink = GetQuestLink(questID)  -- Generate the quest link

	if RQE.db.profile.debugLevel == "INFO" then
		print("Abandoning QuestID:", questID .. " - " .. questLink)
	end
    C_QuestLog.SetAbandonQuest()

    -- Check the addon settings to decide whether to show the confirmation dialogues
    if not RQE.db.profile.enableQuestAbandonConfirm then
        -- Quest name for the confirmation dialog
        local title = QuestUtils_GetQuestName(C_QuestLog.GetAbandonQuest()) or "Unknown Quest"

        -- Determine if there are items to be lost upon abandoning the quest
        local items = C_QuestLog.GetAbandonQuestItems()
        if items and #items > 0 then
            -- If there are items, concatenate their names
            local itemNames = BuildItemNames(items)
            StaticPopup_Hide("ABANDON_QUEST")
            StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", title, itemNames)
        else
            -- No items to be lost, show a simple confirmation
            StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
            StaticPopup_Show("ABANDON_QUEST", title)
        end
    else
        -- If the setting is disabled, abandon the quest directly without confirmation
        C_QuestLog.AbandonQuest()
    end

    -- Restore the previously selected quest
    C_QuestLog.SetSelectedQuest(oldSelectedQuest)
end



function BuildItemNames(itemLinks)
    if not itemLinks or #itemLinks == 0 then return nil end
    local itemNames = {}
    for _, itemLink in ipairs(itemLinks) do
        local itemName = GetItemInfo(itemLink)
        table.insert(itemNames, itemName)
    end
    return table.concat(itemNames, ", ")
end


---------------------------------------------------
-- 16. Quest Info Functions
---------------------------------------------------
-- [Functions related to quest information handling and processing.]

-- Table to store the last known progress of quests
local lastKnownProgress = {}
local isFirstRun = true

-- function AutoWatchQuestsWithProgress()
    -- if isFirstRun then
        -- -- On first run, just populate lastKnownProgress without tracking
        -- for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            -- local questInfo = C_QuestLog.GetInfo(i)
            -- if questInfo and not questInfo.isHeader then
                -- local questID = questInfo.questID
                -- local objectives = C_QuestLog.GetQuestObjectives(questID)
                -- local currentProgress = CalculateCurrentProgress(objectives)
                -- lastKnownProgress[questID] = currentProgress
            -- end
        -- end
        -- isFirstRun = false
    -- else
        -- -- On subsequent runs, track quests with new progress
        -- TrackQuestsWithNewProgress()
    -- end
-- end


function CalculateCurrentProgress(objectives)
    local currentProgress = 0
    for _, objective in ipairs(objectives or {}) do
        if objective and objective.finished then
            currentProgress = currentProgress + 1
        end
    end
    return currentProgress
end


function TrackQuestsWithNewProgress()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local questID = questInfo.questID
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            local currentProgress = CalculateCurrentProgress(objectives)

            if currentProgress > (lastKnownProgress[questID] or 0) then
                C_QuestLog.AddQuestWatch(questID)
            end

            lastKnownProgress[questID] = currentProgress
        end
    end
end


function HasQuestProgress(questID)
    -- Use the WoW API to get quest objectives
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if not objectives then return false end

    for i, objective in ipairs(objectives) do
        if objective and not objective.finished then
            -- If any objective is not finished, consider it as progress
            return true
        end
    end

    return false -- Return false if all objectives are finished or no objectives are found
end


-- Function to retrieve quest data from API
function RQE:LoadQuestData(questID)
    local questData = RQE.getQuestData(questID)

    if questData then
        RQE.debugLog("Quest data for ID " .. questID .. " is already loaded.")
        return questData
    else
        RQE.debugLog("Loading quest data for ID " .. questID)

        -- Fetch quest data from source or API
        questData = RQE:FetchQuestDataFromSource(questID) or RQE:BuildQuestData(questID)

        if questData then
            -- Store the loaded data in the correct database
            RQE.getQuestData[questID] = questData  -- This line is syntactically incorrect, needs fixing
            RQE.debugLog("Quest data loaded for ID " .. questID)
            return questData
        else
            RQE.debugLog("Failed to load quest data for ID " .. questID)
            return nil
        end
    end
end


-- Function to build quest data from WoW API
function RQE:BuildQuestData(questID)
    local questData = {}

    -- Fetch basic quest details from WoW API
    questData.name = C_QuestLog.GetTitleForQuestID(questID)
    questData.questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    questData.directionText = C_QuestLog.GetNextWaypointText(questID)

    -- Fetch quest objectives
    local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
    questData.objectives = objectivesTable

    -- Fetch quest description
    if questData.questLogIndex then
        local _, questDescription = GetQuestLogQuestText(questData.questLogIndex)
        questData.description = questDescription
    end

    return questData
end


-- Function to print quest steps to chat
function PrintQuestStepsToChat(questID)
	local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
    local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}

    if not questInfo then
        -- DEFAULT_CHAT_FRAME:AddMessage("QuestInfo not found for questID: " .. tostring(questID), 0, 1, 0) -- Green color
        return nil, nil, nil
    end

    for i, step in ipairs(questInfo) do
        StepsText[i] = step.description
        CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
        MapIDs[i] = step.coordinates.mapID
        questHeader[i] = step.description:match("^(.-)\n") or step.description

        -- Debug messages
        -- DEFAULT_CHAT_FRAME:AddMessage("Step " .. i .. ": " .. StepsText[i], 0, 1, 0) -- Green color
        -- DEFAULT_CHAT_FRAME:AddMessage("Coordinates " .. i .. ": " .. CoordsText[i], 0, 1, 0) -- Green color
        -- DEFAULT_CHAT_FRAME:AddMessage("MapID " .. i .. ": " .. tostring(MapIDs[i]), 0, 1, 0) -- Green color
        -- DEFAULT_CHAT_FRAME:AddMessage("Header " .. i .. ": " .. questHeader[i], 0, 1, 0) -- Green color
    end

    -- DEFAULT_CHAT_FRAME:AddMessage("Quest Steps Printed for QuestID: " .. tostring(questID), 0, 1, 0) -- Green color
    return StepsText, CoordsText, MapIDs, questHeader
end


function RQE:QuestComplete(questID)
    local questData = RQE.getQuestData(questID)
    if questData then  -- Make sure the quest exists in your database
        questData.description = "Quest Complete - Follow the waypoint for quest turn-in"
        RQE:ConfigurationChanged()
    end
end


-- Function to highlight text for copying
local function HighlightTextForCopy(editBox)
    editBox:SetFocus()
    editBox:HighlightText()
    print("Press Ctrl+C to copy the link.")
end


-- Function to generate frame on menu choice that will display the wowhead link for a given quest
function RQE:ShowWowheadLink(questID)
    local wowheadURL = "https://www.wowhead.com/quest=" .. questID

    -- Create and configure the frame
    local linkFrame = CreateFrame("Frame", "WowheadLinkFrame", UIParent, "BackdropTemplate") --, "DialogBoxFrame")
    linkFrame:SetSize(350, 120)  -- Increased height
    linkFrame:SetPoint("CENTER")
    linkFrame:SetFrameStrata("HIGH")
	RQE.linkFrame = linkFrame

    -- Create and configure the EditBox
    local wowHeadeditBox = CreateFrame("EditBox", nil, linkFrame, "InputBoxTemplate")
    wowHeadeditBox:SetSize(325, 20)
    wowHeadeditBox:SetPoint("TOP", 0, -20)  -- Adjusted position
    wowHeadeditBox:SetAutoFocus(false)
    wowHeadeditBox:SetText(wowheadURL)
    wowHeadeditBox:SetCursorPosition(0)
    wowHeadeditBox:HighlightText()
    wowHeadeditBox:SetHyperlinksEnabled(false)
	RQE.wowHeadeditBox = wowHeadeditBox

    -- Function to copy text to clipboard
	local function CopyTextToClipboard()
		if wowHeadeditBox:IsVisible() then
			wowHeadeditBox:SetFocus()
			wowHeadeditBox:HighlightText()
			-- Copy the text
			if not InCombatLockdown() then
				C_ChatInfo.SendAddonMessage("RQE", "CopyRequest", "WHISPER", UnitName("player"))
			else
				print("Cannot copy while in combat.")
			end
		end
	end

	-- Function to highlight text for copying
	local function HighlightTextForCopy()
		wowHeadeditBox:SetFocus()
		wowHeadeditBox:HighlightText()
		-- Inform the user to press Ctrl+C to copy
		print("Press Ctrl+C to copy the link.")
	end

	-- Configure the Copy button
	local copyButton = CreateFrame("Button", nil, linkFrame, "UIPanelButtonTemplate")
	copyButton:SetSize(100, 20)
    copyButton:ClearAllPoints()
    copyButton:SetPoint("TOP", wowHeadeditBox, "BOTTOM", 0, -10)  -- Adjust the Y-offset as needed
	copyButton:SetText("Copy to Clipboard")
	copyButton:SetScript("OnClick", HighlightTextForCopy)

    -- Create and configure the Close button
    local wowHeadcloseButton = CreateFrame("Button", nil, linkFrame, "UIPanelCloseButton")
	wowHeadeditBox:ClearAllPoints()
    wowHeadeditBox:SetPoint("TOP", 0, -30)
    wowHeadcloseButton:SetScript("OnClick", function() linkFrame:Hide() end)
	RQE.wowHeadcloseButton = wowHeadcloseButton

    -- Make the frame movable
    linkFrame:SetMovable(true)
    linkFrame:EnableMouse(true)
    linkFrame:RegisterForDrag("LeftButton")
    linkFrame:SetScript("OnDragStart", linkFrame.StartMoving)
    linkFrame:SetScript("OnDragStop", linkFrame.StopMovingOrSizing)

    -- Apply the border to the frame
    linkFrame:SetBackdrop(borderBackdrop)

    -- Configure the EditBox font
    wowHeadeditBox:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")

    -- Resize and reposition the close button
    wowHeadcloseButton:SetSize(20, 20)
    wowHeadcloseButton:ClearAllPoints()
    wowHeadcloseButton:SetPoint("TOPRIGHT", linkFrame, "TOPRIGHT", -5, -5)

    -- Apply the font to the copy button text
    copyButton:GetFontString():SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")

	local borderBackdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- path to the background texture
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- path to the border texture
		tile = true,
		tileSize = 32,
		edgeSize = 12, -- this controls the thickness of the border
		insets = { left = 11, right = 11, top = 12, bottom = 11 },
	}
	linkFrame:SetBackdrop(borderBackdrop)

    -- Show the frame
    linkFrame:Show()
end


local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "RQE" and message == "CopyRequest" and sender == UnitName("player") then
        -- Attempt to use the hidden chat frame method to copy text
        local editBox = ChatFrame1EditBox or ChatEdit_ChooseBoxForSend() -- Fallback to an existing chat edit box
        editBox:Show()
        editBox:SetText(wowHeadeditBox:GetText())
        editBox:HighlightText()
        editBox:SetFocus()
        editBox:CopyChatFrame(editBox)
        editBox:Hide()
    end
end)


-- Function to generate frame on menu choice that will display the wowhead link for a given quest
function RQE:ShowWowWikiLink(questID)
    local questTitle = C_QuestLog.GetTitleForQuestID(questID)
    if not questTitle then
        print("Quest title not available for Quest ID: " .. questID)
        return
    end
    -- Replace spaces with '+' for URL encoding
    local searchTitle = questTitle:gsub(" ", "+")
    local wowWikiURL = "https://warcraft.wiki.gg/index.php?search=" .. searchTitle .. "&title=Special%3ASearch&profile=default&fulltext=1"

    -- Create and configure the frame
    local linkFrame = CreateFrame("Frame", "WowWikiLinkFrame", UIParent, "BackdropTemplate")
    linkFrame:SetSize(350, 120)  -- Increased height
    linkFrame:SetPoint("CENTER")
    linkFrame:SetFrameStrata("HIGH")
	RQE.wowWikiLinkFrame = linkFrame

    -- Create and configure the EditBox
    local wowWikieditBox = CreateFrame("EditBox", nil, linkFrame, "InputBoxTemplate")
    wowWikieditBox:SetSize(325, 20)
    wowWikieditBox:SetPoint("TOP", 0, -30)  -- Adjusted position
    wowWikieditBox:SetAutoFocus(false)
    wowWikieditBox:SetText(wowWikiURL)
    wowWikieditBox:SetCursorPosition(0)
    wowWikieditBox:HighlightText()
    wowWikieditBox:SetHyperlinksEnabled(false)
	RQE.wowWikieditBox = wowWikieditBox

    -- Function to copy text to clipboard
	local function CopyTextToClipboard()
		if wowWikieditBox:IsVisible() then
			wowWikieditBox:SetFocus()
			wowWikieditBox:HighlightText()
			-- Copy the text
			if not InCombatLockdown() then
				C_ChatInfo.SendAddonMessage("RQE", "CopyRequest", "WHISPER", UnitName("player"))
			else
				print("Cannot copy while in combat.")
			end
		end
	end

	-- Function to highlight text for copying
	local function HighlightTextForCopy()
		wowWikieditBox:SetFocus()
		wowWikieditBox:HighlightText()
		-- Inform the user to press Ctrl+C to copy
		print("Press Ctrl+C to copy the link.")
	end

	-- Configure the Copy button
	local copyButton = CreateFrame("Button", nil, linkFrame, "UIPanelButtonTemplate")
	copyButton:SetSize(100, 20)
    copyButton:ClearAllPoints()
    copyButton:SetPoint("TOP", wowWikieditBox, "BOTTOM", 0, -15)  -- Adjust the Y-offset as needed
	copyButton:SetText("Copy to Clipboard")
	copyButton:SetScript("OnClick", HighlightTextForCopy)

    -- Create and configure the Close button
    local wowWikicloseButton = CreateFrame("Button", nil, linkFrame, "UIPanelCloseButton")
	wowWikicloseButton:ClearAllPoints()
    wowWikicloseButton:SetPoint("TOP", 0, -30)
    wowWikicloseButton:SetScript("OnClick", function() linkFrame:Hide() end)
	RQE.wowWikicloseButton = wowWikicloseButton

    -- Make the frame movable
    linkFrame:SetMovable(true)
    linkFrame:EnableMouse(true)
    linkFrame:RegisterForDrag("LeftButton")
    linkFrame:SetScript("OnDragStart", linkFrame.StartMoving)
    linkFrame:SetScript("OnDragStop", linkFrame.StopMovingOrSizing)

    -- Apply the border to the frame
    linkFrame:SetBackdrop(borderBackdrop)

    -- Configure the EditBox font
    wowWikieditBox:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")

    -- Resize and reposition the close button
    wowWikicloseButton:SetSize(20, 20)
    wowWikicloseButton:ClearAllPoints()
    wowWikicloseButton:SetPoint("TOPRIGHT", linkFrame, "TOPRIGHT", -5, -5)

    -- Apply the font to the copy button text
    copyButton:GetFontString():SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")

	local borderBackdrop = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- path to the background texture
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- path to the border texture
		tile = true,
		tileSize = 32,
		edgeSize = 12, -- this controls the thickness of the border
		insets = { left = 11, right = 11, top = 12, bottom = 11 },
	}
	linkFrame:SetBackdrop(borderBackdrop)

    -- Show the frame
    linkFrame:Show()
end


-- Variables to track the last known states
RQE.lastKnownQuestID = nil
RQE.lastKnownZoneID = nil
RQE.lastKnownBuffStates = {}
RQE.lastKnownInventory = {}

function RQE.hasStateChanged()
    local currentQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local currentZoneID = C_Map.GetBestMapForUnit("player")
    local currentBuffs = RQE.getCurrentBuffs()
    local currentInventory = RQE.getCurrentInventory()

    -- Check if there's been a change in quest ID, zone ID, buffs, or inventory
    if currentQuestID ~= RQE.lastKnownQuestID or
       currentZoneID ~= RQE.lastKnownZoneID or
       not RQE.compareTables(currentBuffs, RQE.lastKnownBuffStates) or
       not RQE.compareTables(currentInventory, RQE.lastKnownInventory) then

        -- Update last known states
        RQE.lastKnownQuestID = currentQuestID
        RQE.lastKnownZoneID = currentZoneID
        RQE.lastKnownBuffStates = currentBuffs
        RQE.lastKnownInventory = currentInventory

        return true
    end

    return false
end


-- Function will compare the current objectives with the last known objectives stored
function RQE.hasQuestProgressChanged()
    local currentObjectives = RQE.getAllWatchedQuestsObjectives()
    if not RQE.lastKnownObjectives then
        RQE.lastKnownObjectives = currentObjectives
        return true
    end

    -- Compare current objectives with last known objectives for all quests
    for questID, objectives in pairs(currentObjectives) do
        local lastObjectives = RQE.lastKnownObjectives[questID]
        if not lastObjectives or #objectives ~= #lastObjectives then
            RQE.lastKnownObjectives = currentObjectives
            return true
        end

        for index, objective in ipairs(objectives) do
            local lastObjective = lastObjectives[index]
            if not lastObjective or objective.description ~= lastObjective.description or objective.completed ~= lastObjective.completed then
                RQE.lastKnownObjectives = currentObjectives
                return true
            end
        end
    end

    return false
end

function RQE.getAllWatchedQuestsObjectives()
    local objectives = {}
    local watchedQuests = C_QuestLog.GetNumQuestWatches()
    for i = 1, watchedQuests do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID then
            objectives[questID] = RQE.getCurrentQuestObjectives(questID)
        end
    end
    return objectives
end


-- Function to place Current Objectives in table
function RQE.getCurrentQuestObjectives(questID)
    local objectives = {}
    local numObjectives = C_QuestLog.GetNumQuestObjectives(questID)
    for i = 1, numObjectives do
        local description, _, completed, fulfilled, required = GetQuestObjectiveInfo(questID, i, false)
        table.insert(objectives, {
            description = description,
            completed = completed,
            fulfilled = fulfilled,
            required = required
        })
    end
    return objectives
end




-- Function to place Current Buffs in table
function RQE.getCurrentBuffs()
    local buffs = {}
    for i = 1, 40 do  -- Typically there are not more than 40 buffs
        local name = UnitBuff("player", i)
        if not name then break end
        table.insert(buffs, name)
    end
    return buffs
end


-- Function to place Current Inventory in table
function RQE.getCurrentInventory()
    local inventory = {}
    for bag = 1, 5 do  -- Main bags + Reagent Bag (doesn't count items in Bank or Reagent Bank)
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local _, itemCount = C_Container.GetContainerItemInfo(bag, slot)
                if not inventory[itemID] then
                    inventory[itemID] = 0
                end
                inventory[itemID] = inventory[itemID] + (itemCount or 0)  -- Ensure itemCount is not nil before addition
            end
        end
    end
    return inventory
end


-- Compare Function Tables for Buffs and Inventory
function RQE.compareTables(t1, t2)
    if #t1 ~= #t2 then return false end
    for key, value in pairs(t1) do
        if t2[key] ~= value then return false end
    end
    return true
end


-- -- Function to determine the current step based on quest objectives
-- function RQE:DetermineCurrentStepIndex(questID)
    -- local questData = RQE.getQuestData(questID)
    -- if not questData then
        -- RQE.infoLog("No quest data available for quest ID:", questID)
        -- return 1  -- Default to the first step if no data is available
    -- end

    -- for index, step in ipairs(questData) do
        -- if not C_QuestLog.ReadyForTurnIn(questID) then
            -- if not C_QuestLog.IsQuestObjectiveComplete(questID, step.objectiveIndex) then
                -- return index  -- Return the index of the first incomplete objective
            -- end
        -- end
    -- end

    -- return #questData  -- Return the last step if all objectives are complete or ready for turn-in
-- end


-- Periodic check setup
function RQE:StartPeriodicChecks()
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

    if not superTrackedQuestID then
        RQE.debugLog("No super tracked quest ID found, skipping checks.")
        return
    end

    local questData = RQE.getQuestData(superTrackedQuestID)
    local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(superTrackedQuestID)

    if questData then
        local stepIndex = self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex or 1
        local stepData = questData[stepIndex]

        -- Handle turn-in readiness
        if isReadyTurnIn then
            for index, step in ipairs(questData) do
                if step.objectiveIndex == 99 then
                    RQE.infoLog("Quest is ready for turn-in, clicking Waypoint Button for step index:", index)
                    self:ClickWaypointButtonForIndex(index)
                    return
                end
            end
            RQE.infoLog("Quest is ready for turn-in but no appropriate Waypoint Button found.")
        end

        -- -- Check if the specific functions related to the current step need to be triggered    -- KEEPING THIS MEANS THAT IT WONT COUNT THE ITEMS IN THE INVENTORY CORRECTLY AND POSSIBLY OTHER ISSUES SIMILARLY
        -- if not RQE.hasStateChanged(stepData) and not isReadyTurnIn then
            -- RQE.infoLog("No relevant changes detected for the current step, skipping periodic checks.")
            -- return
		-- else
			-- RQE.infoLog("Possible relevant changes detected!")
        -- end

        -- RQE.infoLog("Relevant changes detected or required for the current step.")

        -- Validate stepIndex
        if stepIndex < 1 or stepIndex > #questData then
            RQE.infoLog("Invalid step index:", stepIndex)
            return  -- Exit if stepIndex is invalid
        end

        -- Process the current step
        local funcResult = stepData.funct and RQE[stepData.funct] and RQE[stepData.funct](self, superTrackedQuestID, stepIndex)
        if funcResult then
            RQE.infoLog("Function for current step executed successfully.")
        else
            local failFuncResult = stepData.failedfunc and RQE[stepData.failedfunc] and RQE[stepData.failedfunc](self, superTrackedQuestID, stepIndex, true)
            if failFuncResult then
                local failedIndex = stepData.failedIndex or 1
                RQE.infoLog("Failure condition met, resetting to step:", failedIndex)
                self:ClickWaypointButtonForIndex(failedIndex)
            else
                RQE.infoLog("No conditions met for current step", stepIndex, "of quest ID", superTrackedQuestID)
            end
        end
    end
	--RQE:CheckAndAdvanceStep(questID)
end


-- Function advances the quest step by simulating a click on the corresponding WaypointButton.
function RQE:AdvanceQuestStep(questID, stepIndex)
	-- Clears Macro Data
	RQEMacro:ClearMacroContentByName("RQE Macro")

    RQE.infoLog("Running AdvanceQuestStep for questID:", questID, "at stepIndex:", stepIndex)
    local questData = self.getQuestData(questID)
    local nextIndex = stepIndex + 1
    local nextStep = questData[nextIndex]

    if nextStep then
        local buttonIndex = nextIndex
        local button = self.WaypointButtons[buttonIndex]
        if button then
            button:Click()
            self.LastClickedButtonRef = button
            RQE.infoLog("Advanced to next quest step: " .. buttonIndex)
            -- Update stepIndex globally or within a managed scope
            self.CurrentStepIndex = buttonIndex  -- Assuming CurrentStepIndex is how you track the current step globally
            self:AutoClickQuestLogIndexWaypointButton()  -- Attempt to click using the new reference
        end
    end
end


-- Function that handles if returns Failed stepIndex
function RQE:ClickWaypointButtonForIndex(index)
	-- Clears Macro Data
	--RQEMacro:ClearMacroContentByName("RQE Macro")

    local button = self.WaypointButtons[index]
    if button then
        button:Click()
        self.LastClickedButtonRef = button  -- Update last clicked reference
        self.CurrentStepIndex = index  -- Update current step index
        RQE.infoLog("Clicked waypoint button for index:", index)
    else
        RQE.infoLog("No waypoint button found for index:", index)
    end
end


-- Function will check if the player currently has any of the buffs specified in the quest's check field passed by the RQEDatabase.
function RQE:CheckDBBuff(questID, stepIndex, isFailureCheck)
    local questData = self.getQuestData(questID)
    local stepData = questData[stepIndex]
    local checkData = isFailureCheck and stepData.failedcheck or stepData.check

    for _, buffName in ipairs(checkData) do
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", buffName, "HELPFUL")
        if aura then
            if not isFailureCheck then
                self:AdvanceQuestStep(questID, stepIndex)
                return true  -- Buff is present and it's a regular check
            else
                return false  -- Buff is present but we're doing a failure check
            end
        end
    end
    if isFailureCheck then
        return true  -- Buff is not present and it's a failure check
    end
    return false  -- Buff is not present but it's a regular check
end


-- Function will check if the player currently has any of the debuffs specified in the quest's check field passed by the RQEDatabase.
function RQE:CheckDBDebuff(questID, stepIndex)
    local questData = self.getQuestData(questID)
    local stepData = questData[stepIndex]
    local debuffs = stepData.check -- Renamed from buffs to debuffs for clarity since it checks for debuffs

    for _, debuffName in ipairs(debuffs) do
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", debuffName, "HARMFUL")
        if aura then
            self:AdvanceQuestStep(questID, stepIndex)
            RQE.infoLog("Debuff " .. debuffName .. " is active. Advancing quest step.")
        else
            RQE.infoLog("Debuff " .. debuffName .. " is not active.")
        end
    end
end


-- Function will check the player's inventory for specific items.
function RQE:CheckDBInventory(questID, stepIndex)
    local questData = self.getQuestData(questID)
    local stepData = questData[stepIndex]
    local requiredItems = stepData.check or {}
    local neededAmounts = stepData.neededAmt or {}

    for index, itemID in ipairs(requiredItems) do
        local requiredAmount = tonumber(neededAmounts[index]) or 1  -- Default to 1 if no amount specified
        local itemCount = C_Item.GetItemCount(itemID)

        RQE.infoLog("Item ID:", itemID, "Needed:", requiredAmount, "In Inventory:", itemCount)

        if itemCount >= requiredAmount then
            self:AdvanceQuestStep(questID, stepIndex)
            return  -- Exit function after advancing step to avoid multiple advancements
        end
    end
end


-- Function will check the player's current map ID against the expected map ID stored in the check field in the RQEDatabase
function RQE:CheckDBZoneChange(questID, stepIndex)
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local questData = self.getQuestData(questID)
    local stepData = questData[stepIndex]
    local requiredMapIDs = stepData.check  -- This should be a list of mapIDs

    RQE.infoLog("Checking Map ID:", tostring(currentMapID), "Against Required IDs:", table.concat(requiredMapIDs, ", "))
    -- Check if the current map ID is in the list of required IDs
    if requiredMapIDs and #requiredMapIDs > 0 then
        for _, mapID in ipairs(requiredMapIDs) do
            if tostring(currentMapID) == tostring(mapID) then
                self:AdvanceQuestStep(questID, stepIndex)
                RQE.infoLog("Player is in the correct zone (MapID: " .. currentMapID .. "). Advancing to next quest step.")
                return  -- Exit after advancing to avoid multiple advancements
            end
        end
    end
    RQE.debugLog("Player is not in the correct zone. Current MapID:", currentMapID, "Required MapID(s):", table.concat(requiredMapIDs, ", "))
end


-- Function will check if the quest is ready for turn-in from what is passed by the RQEDatabase.
function RQE:CheckDBComplete(questID, stepIndex)
    if C_QuestLog.ReadyForTurnIn(questID) then
        self:AdvanceQuestStep(questID, stepIndex)
    end
end


-- Function to check if the player's faction is Alliance and advance the quest step if true
function RQE:CheckFactionGroupAlliance(questID, stepIndex)
    local englishFaction = UnitFactionGroup("player")

    RQE.infoLog("Checking if player's faction is Alliance: " .. tostring(englishFaction))

    -- Check if the player's faction is Alliance
    if englishFaction == "Alliance" then
        RQE.infoLog("Player is Alliance, advancing quest step.")
        self:AdvanceQuestStep(questID, stepIndex)
        return true
    else
        RQE.infoLog("Player is not Alliance, not advancing quest step.")
        return false
    end
end


-- Function to check if the player's faction is Horde and advance the quest step if true
function RQE:CheckFactionGroupHorde(questID, stepIndex)
    local englishFaction = UnitFactionGroup("player")

    RQE.infoLog("Checking if player's faction is Horde: " .. tostring(englishFaction))

    -- Check if the player's faction is Horde
    if englishFaction == "Horde" then
        RQE.infoLog("Player is Horde, advancing quest step.")
        self:AdvanceQuestStep(questID, stepIndex)
        return true
    else
        RQE.infoLog("Player is not Horde, not advancing quest step.")
        return false
    end
end


---------------------------------------------------
-- 17. Filtering Functions
---------------------------------------------------

-- Contain filters for the RQEQuestingFrame
RQE.filterCompleteQuests = function()
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader and C_QuestLog.IsComplete(questInfo.questID) then
            C_QuestLog.AddQuestWatch(questInfo.questID)
        else
            C_QuestLog.RemoveQuestWatch(questInfo.questID)
        end
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end


-- Function for Hiding Completed Watched Quests
function RQE:HideCompletedWatchedQuests()
    -- Iterate through all quests currently being watched
    for i = C_QuestLog.GetNumQuestWatches(), 1, -1 do
        local qID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		local isQuestComplete = C_QuestLog.IsComplete(qID)
        if qID then
            -- Check if the quest is completed
            if isQuestComplete then
                -- Remove the quest from the watch list if it is completed
                C_QuestLog.RemoveQuestWatch(qID)

                -- Optional: Update the UI if necessary
                -- If you have a custom UI that depends on the watch list, refresh it here
            end
        end
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end


function RQE.ScanAndCacheQuestFrequencies()
    RQE.DailyQuests = {}
    RQE.WeeklyQuests = {}

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local tagInfo = C_QuestLog.GetQuestTagInfo(questInfo.questID)
            local questTagID = tagInfo and tagInfo.tagID
            local frequency = questInfo.frequency

            -- Categorize as daily or weekly
            if frequency == Enum.QuestFrequency.Daily then
                RQE.DailyQuests[questInfo.questID] = questInfo.title
            elseif frequency == Enum.QuestFrequency.Weekly then
                RQE.WeeklyQuests[questInfo.questID] = questInfo.title
            end
        end
    end
end


RQE.filterDailyWeeklyQuests = function()
    RQE.ScanAndCacheQuestFrequencies()  -- Ensure daily and weekly quests are up-to-date

    -- Loop through the current quest watches and remove all
    local numQuestWatches = C_QuestLog.GetNumQuestWatches()
    for i = numQuestWatches, 1, -1 do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        C_QuestLog.RemoveQuestWatch(questID)
    end

    -- Add daily quests
    for questID, _ in pairs(RQE.DailyQuests) do
        C_QuestLog.AddQuestWatch(questID)
    end

    -- Add weekly quests
    for questID, _ in pairs(RQE.WeeklyQuests) do
        C_QuestLog.AddQuestWatch(questID)
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end


function RQE.ScanAndCacheZoneQuests()
    RQE.ZoneQuests = {}

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            -- Get the primary map ID associated with the quest
            local uiMapID, _, _, _, _ = C_QuestLog.GetQuestAdditionalHighlights(questInfo.questID)
            -- If the primary map ID is not available, fallback to the secondary options
            if not uiMapID or uiMapID == 0 then
                uiMapID = C_TaskQuest.GetQuestZoneID(questInfo.questID)
                -- As a last resort, use the quest's UiMapID if available
                if not uiMapID or uiMapID == 0 then
                    uiMapID = GetQuestUiMapID(questInfo.questID, ignoreWaypoints)
                end
            end
            -- If a valid map ID is found, add the quest to the corresponding zone's quest list
            if uiMapID and uiMapID ~= 0 then
                RQE.ZoneQuests[uiMapID] = RQE.ZoneQuests[uiMapID] or {}
                table.insert(RQE.ZoneQuests[uiMapID], questInfo.questID)
            end
        end
    end
end


function RQE.UpdateTrackedQuestsToCurrentZone()
    -- Determine the player's current zone/mapID
    local currentPlayerMapID = C_Map.GetBestMapForUnit("player")
    if not currentPlayerMapID then
        RQE.debugLog("Unable to determine the player's current map ID.")
        return
    end

    -- Retrieve quests for the current zone using C_QuestLog.GetQuestsOnMap
    local questsOnMap = C_QuestLog.GetQuestsOnMap(currentPlayerMapID)
    if not questsOnMap then
        RQE.debugLog("No quests found for the current zone.")
        return
    end

    -- Convert questsOnMap to a set for quicker lookups
    local questIDSet = {}
    for _, questInfo in ipairs(questsOnMap) do
        questIDSet[questInfo.questID] = true
    end

    -- Iterate through all quests the player is currently watching
    local numQuestWatches = C_QuestLog.GetNumQuestWatches()
    for i = numQuestWatches, 1, -1 do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        -- If a watched quest is not on the current map, untrack it
        if questID and not questIDSet[questID] then
            C_QuestLog.RemoveQuestWatch(questID)
        end
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()
end


-- function RQE.ScanAndCacheZoneQuests()
    -- RQE.ZoneQuests = {}
    -- local numEntries = C_QuestLog.GetNumQuestLogEntries()
	-- local currentPlayerMapID = C_Map.GetBestMapForUnit("player")

    -- for i = 1, numEntries do
        -- local questInfo = C_QuestLog.GetInfo(i)
        -- if questInfo and not questInfo.isHeader then
            -- local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID, ignoreWaypoints)
            -- if zoneID then
                -- RQE.ZoneQuests[zoneID] = RQE.ZoneQuests[zoneID] or {}
                -- table.insert(RQE.ZoneQuests[zoneID], questInfo.questID)
            -- end
        -- end
    -- end

    -- if currentPlayerMapID then
        -- local questsOnMap = C_QuestLog.GetQuestsOnMap(currentPlayerMapID)
        -- RQE.ZoneQuests[currentPlayerMapID] = {} -- Reset or initialize the quests for the current player map ID

        -- for _, questOnMap in ipairs(questsOnMap) do
            -- if questOnMap.questID then
                -- -- Only add quests that are also in the player's quest log to ensure relevance
                -- local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questOnMap.questID)
                -- if questLogIndex then
                    -- table.insert(RQE.ZoneQuests[currentPlayerMapID], questOnMap.questID)
                -- end
            -- end
        -- end
    -- end
-- end


-- Function that when run will print out the Map that is associated with quests in the player's questlog
function RQE.ShowQuestsforMap()
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
		local questInfo = C_QuestLog.GetInfo(i)
		if questInfo and not questInfo.isHeader then
			local uiMapID, worldQuests, worldQuestsElite, dungeons, treasures = C_QuestLog.GetQuestAdditionalHighlights(questInfo.questID)
			if uiMapID ~= 0 then
				print ("QuestID: " .. questInfo.questID .. " belongs with MapID: " .. uiMapID)
			else
				local zoneID = GetQuestUiMapID(questInfo.questID, ignoreWaypoints) or C_TaskQuest.GetQuestZoneID(questInfo.questID)
				print ("QuestID: " .. questInfo.questID .. " belongs with MapID: " .. zoneID)
			end
		end
	end
end


function RQE.BuildZoneQuestMenuList()
    local zoneQuestMenuList = {}
    RQE.ZoneQuests = RQE.ZoneQuests or {}  -- Ensure RQE.ZoneQuests is not nil

    for zoneID, quests in pairs(RQE.ZoneQuests) do
        local mapInfo = C_Map.GetMapInfo(zoneID)
        if mapInfo then
            local zoneName = mapInfo.name
            table.insert(zoneQuestMenuList, {
                zoneID = zoneID,  -- Store zoneID for sorting
                text = zoneID .. ": " .. zoneName,
                func = function() RQE.filterByZone(zoneID) end,
            })
        end
    end

    -- Sort the zoneQuestMenuList by zoneID
    table.sort(zoneQuestMenuList, function(a, b)
        return a.zoneID > b.zoneID
    end)

    -- Remove the zoneID key from the menu items after sorting
    for _, menuItem in ipairs(zoneQuestMenuList) do
        menuItem.zoneID = nil
    end

    if #zoneQuestMenuList == 0 then
        table.insert(zoneQuestMenuList, {
            text = "No zone quests",
            func = function() print("No zone quests to filter.") end,
            disabled = true
        })
    end

    return zoneQuestMenuList
end


function RQE.filterByZone(zoneID)
    local questIDsForZone = RQE.ZoneQuests[zoneID] or {}

    -- Create a set for quick lookup
    local questIDSet = {}
    for _, questID in ipairs(questIDsForZone) do
        questIDSet[questID] = true
    end

    -- Remove quests that are not in the selected zone
    local numQuestWatches = C_QuestLog.GetNumQuestWatches()
    for i = numQuestWatches, 1, -1 do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if not questIDSet[questID] then
            C_QuestLog.RemoveQuestWatch(questID)
        end
    end

	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

    -- Add the quests from the selected zone to the watch list
    for _, questID in ipairs(questIDsForZone) do
        C_QuestLog.AddQuestWatch(questID)
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()

	RQE.CheckAndUpdateForCurrentZone(zoneID)
end


function RQE.CheckAndUpdateForCurrentZone(zoneID)
    local currentPlayerMapID = C_Map.GetBestMapForUnit("player")
    if not currentPlayerMapID then
        RQE.debugLog("Unable to determine the player's current map ID.")
        return
    end

    -- Compare the chosen zone ID with the current player's map ID
    if zoneID == currentPlayerMapID then
        -- If they match, update the tracked quests to reflect the current zone
        RQE.UpdateTrackedQuestsToCurrentZone()
    end
end


-- Function to display quests for the current zone
function RQE.DisplayCurrentZoneQuests()
    -- Step 1: Determine the player's current zone
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        RQE.debugLog("Unable to determine the player's current map ID.")
        return
    end

    -- Ensure we have the latest zone quests data
    RQE.ScanAndCacheZoneQuests()

    -- Step 2: Retrieve quests for the current zone
    local currentZoneQuests = RQE.ZoneQuests[mapID] or {}

    if #currentZoneQuests == 0 then
        return
    end

    -- Step 3: Display or update the quest frame with the current zone's quests
    RQE.filterByZone(mapID)  -- Assuming filterByZone can handle filtering & displaying quests for a given zone
end


function RQE.filterByQuestType(questType)
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            -- Fetch the current quest's type
            local currentQuestType = C_QuestLog.GetQuestType(questInfo.questID)

            -- Determine if the current quest should be watched based on its type
            local shouldWatch = false
            if questType == "Misc" then
                -- For "Misc", include quests of type 0 or 261 or 270 or 282
                shouldWatch = (currentQuestType == 0 or currentQuestType == 261 or currentQuestType == 270 or currentQuestType == 282)
            else
                -- For other quest types, match the quest type directly
                shouldWatch = (currentQuestType == questType)
            end

            -- Add or remove the quest from watch based on the shouldWatch flag
            if shouldWatch then
                C_QuestLog.AddQuestWatch(questInfo.questID)
            else
                C_QuestLog.RemoveQuestWatch(questInfo.questID)
            end
        end
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end


function RQE.GetQuestCampaignInfo(questID)
    local campaignID = C_CampaignInfo.GetCampaignID(questID)
    if campaignID then
        local campaignInfo = C_CampaignInfo.GetCampaignInfo(campaignID)
        if campaignInfo then
            return campaignInfo
        end
    end
    return nil  -- This quest is not part of a campaign
end


function RQE.GetCampaignsFromQuestLog()
    local campaigns = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local campaignInfo = RQE.GetQuestCampaignInfo(questInfo.questID)
            if campaignInfo and campaignInfo.campaignID then  -- Ensure campaignID is not nil
                -- If this campaign is not yet in the table, add it
                if not campaigns[campaignInfo.campaignID] then
                    campaigns[campaignInfo.campaignID] = campaignInfo.name
                end
            end
        end
    end
    return campaigns
end


function RQE.ScanAndCacheCampaigns()
    RQE.Campaigns = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            if C_CampaignInfo.IsCampaignQuest(questInfo.questID) then
                local campaignID = C_CampaignInfo.GetCampaignID(questInfo.questID)
                if campaignID then
                    local campaignInfo = C_CampaignInfo.GetCampaignInfo(campaignID)
                    if campaignInfo and not RQE.Campaigns[campaignID] then
                        RQE.Campaigns[campaignID] = campaignInfo.name
                    end
                end
            end
        end
    end
end


function RQE.BuildCampaignMenuList()
    local campaignMenuList = {}

    for campaignID, campaignName in pairs(RQE.Campaigns) do
        table.insert(campaignMenuList, {
            campaignID = campaignID,  -- Add campaignID key for sorting
            text = campaignID .. ": " .. campaignName,
            func = function() RQE.filterByCampaign(campaignID) end,
        })
    end

    -- Sort the campaignMenuList by campaignID
    table.sort(campaignMenuList, function(a, b)
        return a.campaignID > b.campaignID
    end)

    -- Remove the campaignID key from the menu items after sorting
    for _, menuItem in ipairs(campaignMenuList) do
        menuItem.campaignID = nil
    end

    if #campaignMenuList == 0 then
        -- If there are no campaigns, add a placeholder item
        table.insert(campaignMenuList, {
            text = "No active campaigns",
            func = function() print("No active campaigns to filter.") end,
            disabled = true
        })
    end
    return campaignMenuList
end


function RQE.filterByCampaign(campaignID)
    local numEntries = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local questCampaignID = C_CampaignInfo.GetCampaignID(questInfo.questID)
            if questCampaignID == campaignID then
                C_QuestLog.AddQuestWatch(questInfo.questID)
            else
                C_QuestLog.RemoveQuestWatch(questInfo.questID)
            end
        end
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end

-- -- Function to print out the questline information for a specific quest
-- function RQE.PrintQuestLineInfo(questID, uiMapID)
    -- -- Ensure that the questID and uiMapID are valid numbers
    -- if not questID or not uiMapID then
        -- print("Invalid questID or uiMapID provided.")
        -- return
    -- end

    -- -- Ensure that the questID and uiMapID are numbers
    -- if type(questID) ~= "number" or type(uiMapID) ~= "number" then
        -- print("questID and uiMapID must be numbers.")
        -- return
    -- end

    -- -- Retrieve the quest line information for the given questID and uiMapID
    -- local status, questLineInfo = pcall(C_QuestLine.GetQuestLineInfo, questID, uiMapID)

    -- if status and questLineInfo then
        -- -- Print the quest line information to chat
        -- print("Quest Line Information for Quest ID " .. questID .. ":")
        -- print("Quest Line ID:", questLineInfo.questLineID)
        -- print("Quest Line Name:", questLineInfo.questLineName)
        -- print("Map ID:", uiMapID)
        -- print("Quest Name:", questLineInfo.questName)
        -- print("X Position:", questLineInfo.x)
        -- print("Y Position:", questLineInfo.y)
        -- print("Is Hidden:", questLineInfo.isHidden and "Yes" or "No")
        -- print("Is Legendary:", questLineInfo.isLegendary and "Yes" or "No")
        -- print("Is Daily:", questLineInfo.isDaily and "Yes" or "No")
        -- print("Is Campaign:", questLineInfo.isCampaign and "Yes" or "No")
        -- print("Floor Location:", questLineInfo.floorLocation)
    -- else
        -- -- No quest line info was found for the given questID and uiMapID, or an error occurred
        -- print("No quest line information found for Quest ID " .. questID .. " and Map ID " .. uiMapID .. ", or an error occurred.")
    -- end
-- end

-- -- Example usage:
-- RQE.PrintQuestLineInfo(67100, 2022)


-- Function to Request and Cache all quest lines in player's quest log
function RQE.RequestAndCacheQuestLines()
    RQE.QuestLines = RQE.QuestLines or {}

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            -- Directly use the map ID associated with the quest for more accurate quest line retrieval
            local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID, ignoreWaypoints)
            if zoneID then
                -- Fetch quest line information using the quest ID and its zoneID
                local questLineInfo = C_QuestLine.GetQuestLineInfo(questInfo.questID, zoneID)
                if questLineInfo and questLineInfo.questLineID then
                    if not RQE.QuestLines[questLineInfo.questLineID] then
                        RQE.QuestLines[questLineInfo.questLineID] = {
                            name = questLineInfo.questLineName,
                            quests = {}
                        }
                    end
                    table.insert(RQE.QuestLines[questLineInfo.questLineID].quests, questInfo.questID)
                end
            end
        end
    end
end


-- Function to Build questline list for the menu based on cached questlines
function RQE.BuildQuestLineMenuList()
    local questLineMenuList = {}
    for questLineID, questLineData in pairs(RQE.QuestLines) do
        -- Include the questLineID before the quest line name
        table.insert(questLineMenuList, {
            text = questLineID .. ": " .. questLineData.name,
            func = function() RQE.filterByQuestLine(questLineID) end,
        })
    end

    -- Sort the questLineMenuList by questLineID in descending order
    table.sort(questLineMenuList, function(a, b)
        local aID = tonumber(a.text:match("^(%d+):"))
        local bID = tonumber(b.text:match("^(%d+):"))
        return aID > bID -- Sort from larger to smaller questLineID
    end)

    -- Check if the questLineMenuList is empty and add a placeholder item if it is
    if #questLineMenuList == 0 then
        table.insert(questLineMenuList, {
            text = "No active quest lines to filter.",
            func = function() print("No active quest lines to filter.") end,
            disabled = true  -- Make it non-selectable
        })
    end

    return questLineMenuList
end


-- Menu Filter for Questline-specific
function RQE.filterByQuestLine(questLineID)
    -- Get the quests for the selected questline
    if not RQE.QuestLines[questLineID] then return end -- Early exit if no data for the quest line.

    local questIDsForLine = RQE.QuestLines[questLineID].quests
    local questIDSet = {}

    for _, questID in ipairs(questIDsForLine) do
        questIDSet[questID] = true
    end

    -- Get the total number of quests currently watched
    local numQuestWatches = C_QuestLog.GetNumQuestWatches()

    -- Loop through the current quest watches and remove those not in the selected questline
    for i = numQuestWatches, 1, -1 do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if not questIDSet[questID] then
            C_QuestLog.RemoveQuestWatch(questID)
        end
    end

    -- Add the quests from the selected questline to the watch list
    for _, questID in ipairs(questIDsForLine) do
        C_QuestLog.AddQuestWatch(questID)
    end

	-- Update FrameUI
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()

	-- Sort Quest List by Proximity after populating RQEQuestFrame
	SortQuestsByProximity()
end


-- Function to print quest IDs of a questline along with quest links
function RQE.PrintQuestlineDetails(questLineID)
    local questIDs = C_QuestLine.GetQuestLineQuests(questLineID)
    local questDetails = {}
    local questsToLoad = #questIDs -- Number of quests to load data for

    if questsToLoad > 0 then
        -- Orange color for the questline ID and name message
        print("|cFFFFA500Quests in Questline ID " .. questLineID .. ":|r")
        for i, questID in ipairs(questIDs) do
            -- Attempt to fetch quest title immediately, might not always work due to data loading
            local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Loading..."
            C_Timer.After(0.5, function()
                -- Fetch quest link, retry if not available yet
                local questLink = GetQuestLink(questID)
                if questLink then
                    -- Store quest details in a table
                    -- Light blue color for quest details
                    questDetails[i] = "|cFFADD8E6" .. i .. ". Quest# " .. questID .. " - " .. questLink .. "|r"
                    questsToLoad = questsToLoad - 1
                else
                    -- Fallback if quest link is not available, attempt to use the title
                    -- Light blue color for quest details
                    questDetails[i] = "|cFFADD8E6" .. i .. ". Quest# " .. questID .. " - [" .. questTitle .. "]|r"
                    questsToLoad = questsToLoad - 1
                end

                -- Check if all quests have been processed
                if questsToLoad <= 0 then
                    -- Print all quest details in order
                    for j = 1, #questDetails do
                        print(questDetails[j])
                    end
                end
            end)
        end
    else
        RQE.debugLog("|cFFFFA500No quests found for questline ID: " .. questLineID .. "|r")
    end
end


-- Scans Quest Log for the various Types that each quest is assigned to
function RQE.ScanQuestTypes()
    if type(RQE.QuestTypes) ~= "table" then
        RQE.QuestTypes = {}  -- Initialize as an empty table if it's not already a table
    end
    wipe(RQE.QuestTypes)  -- Clear the table to prevent duplications
    local numEntries = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local questType = C_QuestLog.GetQuestType(questInfo.questID)
            -- Consolidate quest types 0 and 261 or 270 or 282 under a special key "Misc"
            if questType == 0 or questType == 261 or questType == 270 or questType == 282 then
                RQE.QuestTypes["Misc"] = "Misc"  -- Use "Misc" as both key and value for simplicity
            else
                local questTypeName = RQE.GetQuestTypeName(questType)
                if questTypeName then
                    RQE.QuestTypes[questType] = questTypeName
                end
            end
        end
    end
end


function RQE.GetQuestTypeName(questType)
    local questTypeNames = {
		[1] = "Group",
		[21] = "Class",
		[41] = "PvP",
		[62] = "Raid",
		[81] = "Dungeon",
		[82] = "World Event",
		[83] = "Legendary",
		[84] = "Escort",
		[85] = "Heroic",
		[88] = "Raid (10)",
		[89] = "Raid (25)",
		[98] = "Scenario",
		[102] = "Account",
		[104] = "Side Quest",
		[107] = "Artifact",
		[109] = "World Quest",
		[119] = "Herbalism World Quest",
		[128] = "Emissary World Quest",
		[147] = "Warfront - Barrens",
		[148] = "Pickpocketing",
		[254] = "Island Quest",
		[255] = "War Mode PvP",
		[263] = "Public Quest",
		[265] = "Hidden Quest",
		[266] = "Combat Ally Quest",
		[267] = "Professions",
    }
    -- Special handling for 0 and 261 and 270 or 282 to label them as "Misc"
    if questType == 0 or questType == 261 or questType == 270 or questType == 282 then
        return "Misc"
    else
        return questTypeNames[questType] or "Unknown Type"
    end
end


-- Build Menu List for the QuestTypes in your QuestLog
function RQE.BuildQuestTypeMenuList()
    local questTypeMenuList = {}
    RQE.QuestTypes = RQE.QuestTypes or {}

    -- Assign a high numeric value to "Misc" for sorting purposes
    local miscSortValue = 9999

    for questType, questTypeName in pairs(RQE.QuestTypes) do
        local sortKey = (questTypeName == "Misc") and miscSortValue or tonumber(questType)
        table.insert(questTypeMenuList, {
            sortKey = sortKey,
            text = (questTypeName == "Misc" and questTypeName) or (questType .. ": " .. questTypeName),
            func = function() RQE.filterByQuestType(questType) end,
        })
    end

    -- Sort the questTypeMenuList by questType, explicitly handling "Misc"
    table.sort(questTypeMenuList, function(a, b)
        return a.sortKey < b.sortKey
    end)

    -- Remove the temporary sortKey from the menu items
    for _, menuItem in ipairs(questTypeMenuList) do
        menuItem.sortKey = nil
    end

    if #questTypeMenuList == 0 then
        table.insert(questTypeMenuList, {
            text = "No quest types",
            func = function() print("No quest types to filter.") end,
            disabled = true
        })
    end

    return questTypeMenuList
end


---------------------------------------------------
-- 18. Additional Features
---------------------------------------------------

-- Ensure the table exists
RQE.savedWorldQuestWatches = RQE.savedWorldQuestWatches or {}


-- Player Movement that is associated for the creation of current coordinates location text
local isMoving = false


-- OnUpdate function to be triggered while moving
local function OnPlayerMoving(self, elapsed)
    RQE:UpdateCoordinates()
end


-- Function to start the OnUpdate script
function RQE:StartUpdatingCoordinates()
    if not isMoving then
        RQEFrame:SetScript("OnUpdate", OnPlayerMoving)
        isMoving = true
    end
end


-- Function to stop the OnUpdate script
function RQE:StopUpdatingCoordinates()
    if isMoving then
        RQEFrame:SetScript("OnUpdate", nil)
        isMoving = false
    end
end


-- Function to save the currently watched world quests
function RQE:SaveWorldQuestWatches()
    wipe(RQE.savedWorldQuestWatches)
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            if watchType == Enum.QuestWatchType.Manual then  -- Save only if the watch type is Manual
				RQE.savedWorldQuestWatches[questID] = true
				RQE.infoLog("Saved manually tracked World Quest ID:", questID)
			end
        end
    end
    -- Debug: Print the saved world quests
    for questID, _ in pairs(RQE.savedWorldQuestWatches) do
        RQE.infoLog("Saved World Quest ID:", questID)
    end
end


-- Function to save the currently watched world quests with Automatic watch type
function RQE:SaveAutomaticWorldQuestWatches()
    wipe(RQE.savedAutomaticWorldQuestWatches)
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            if watchType == Enum.QuestWatchType.Automatic then  -- Save only if the watch type is Automatic
                RQE.savedAutomaticWorldQuestWatches[questID] = true
                RQE.infoLog("Saved automatically tracked World Quest ID:", questID)
            end
        end
    end
    -- Debug: Print the saved world quests
    for questID, _ in pairs(RQE.savedAutomaticWorldQuestWatches) do
        RQE.infoLog("Saved World Quest ID:", questID)
    end
end


-- Function to restore saved watched world quests
function RQE:RestoreSavedWorldQuestWatches()
    local questsToRestore = {}
    for questID, _ in pairs(RQE.savedWorldQuestWatches) do
        questsToRestore[#questsToRestore + 1] = questID
    end

    local function restoreNext()
        if #questsToRestore == 0 then
            wipe(RQE.savedWorldQuestWatches)
            return
        end
        local questID = table.remove(questsToRestore, 1) -- Get next questID to restore
        if C_QuestLog.IsWorldQuest(questID) and not C_QuestLog.GetQuestWatchType(questID) then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
            RQE.infoLog("Manually tracking World Quest ID " .. questID)
        end
        C_Timer.After(1, restoreNext) -- Call the next restoration after 1 second
    end

    -- Start the restoration process
    restoreNext()
end


-- Function to restore saved automatically watched world quests
function RQE:RestoreSavedAutomaticWorldQuestWatches()
    local questsToRestore = {}
    for questID, _ in pairs(RQE.savedAutomaticWorldQuestWatches) do
        questsToRestore[#questsToRestore + 1] = questID
    end

    local function restoreNext()
        if #questsToRestore == 0 then
            wipe(RQE.savedAutomaticWorldQuestWatches)
            return
        end
        local questID = table.remove(questsToRestore, 1) -- Get next questID to restore
        if C_QuestLog.IsWorldQuest(questID) and not C_QuestLog.GetQuestWatchType(questID) then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
            RQE.infoLog("Automatically tracking World Quest ID " .. questID)
        end
        C_Timer.After(0.5, restoreNext) -- Call the next restoration after 0.5 seconds
    end

    -- Start the restoration process
    restoreNext()
end


-- Function to print the tracking type of all watched world quests
function RQE.PrintTrackedWorldQuestTypes()
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            local trackingType = watchType == Enum.QuestWatchType.Automatic and "Automatic" or "Manual"
            print("Quest ID " .. questID .. " is being tracked " .. trackingType)
        end
    end
end


-- Removes Automatic WQ when leaving area of WQ location
function RQE.UntrackAutomaticWorldQuests()
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)

    -- Convert the questsInArea to a lookup table for quicker access and print them
    local questsInAreaLookup = {}
    for _, taskPOI in ipairs(questsInArea) do
        questsInAreaLookup[taskPOI.questId] = true
        RQE.infoLog(taskPOI.questId)  -- Print each quest ID found in the area
    end

    -- Go through each watched world quest and check conditions
    RQE.infoLog("Checking watched world quests:")
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            RQE.infoLog("WQ " .. i .. ": ID " .. questID .. ", WatchType: " .. (watchType == Enum.QuestWatchType.Automatic and "Automatic" or "Manual"))

            -- If the quest is not in the current area and it was tracked automatically, untrack it
            if watchType == Enum.QuestWatchType.Automatic then
			-- if watchType == Enum.QuestWatchType.Automatic and not questsInAreaLookup[questID] then
                C_QuestLog.RemoveWorldQuestWatch(questID)
            end
        end
    end
end


-- Create Event for the sound of Quest Progress/Completion
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local questObjectiveCompletion = {}
local soundCooldown = false

local function InitializeQuestObjectiveCompletion()
    for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(questIndex)
        if info and not info.isHeader then
            local questID = info.questID
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            for i, objective in ipairs(objectives) do
                local key = questID .. "-" .. i
                questObjectiveCompletion[key] = objective.finished
            end
        end
    end
end

local function CheckQuestObjectivesAndPlaySound()
    if soundCooldown then return end -- Exit if we're in cooldown
    local playSoundForCompletion = false
    local playSoundForObjectives = false

    for questIndex = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(questIndex)
        if info and not info.isHeader then
            local questID = info.questID
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            local allObjectivesComplete = true
            for i, objective in ipairs(objectives) do
                local key = questID .. "-" .. i
                if objective.finished then
                    if not questObjectiveCompletion[key] then
                        -- Objective just completed
                        questObjectiveCompletion[key] = true
                        playSoundForObjectives = true -- Play sound for individual objective completion
                    end
                else
                    allObjectivesComplete = false
                    questObjectiveCompletion[key] = false
                end
            end
            if allObjectivesComplete then
                local key = tostring(questID) .. "-complete"
                if not questObjectiveCompletion[key] then
                    questObjectiveCompletion[key] = true
                    playSoundForCompletion = true -- Play sound for quest completion
                end
            end
        end
    end

    if playSoundForCompletion then
        PlaySound(6199) -- Sound for quest completion
        soundCooldown = true
        C_Timer.After(5, function() soundCooldown = false end)
    elseif playSoundForObjectives then
        PlaySound(6192) -- Sound for individual objective completion
        soundCooldown = true
        C_Timer.After(5, function() soundCooldown = false end)
    end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeQuestObjectiveCompletion()
    elseif event == "QUEST_LOG_UPDATE" then
        C_Timer.After(0.1, CheckQuestObjectivesAndPlaySound)
    end
end)


-- This function will handle the auto clicking of WaypointButton for the super tracked QuestLogIndexButton
function RQE:AutoClickQuestLogIndexWaypointButton()
    if RQE.db.profile.autoClickWaypointButton then
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        if not questID then
            RQE.debugLog("No super tracked quest.")
            return
        end

        -- Use the new LastClickedButtonRef for the operation
        if RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.Click then
            RQE.LastClickedButtonRef:Click()
        else
            RQE.debugLog("Error: No valid WaypointButton found to auto-click, or LastClickedButtonRef is not set correctly.")
        end
    end
end


-- Function to check the memory usage of your addon
function RQE:CheckMemoryUsage()
    if RQE.db and RQE.db.profile.displayRQEmemUsage then
		-- Update the memory usage information
		UpdateAddOnMemoryUsage()

		-- Get the memory usage for the RQE addon
		local memUsage = GetAddOnMemoryUsage("RQE")

        -- Check if memUsage is greater than 1000 KB, then convert to MB
        local memUsageText
        if memUsage > 1000 then
            memUsageText = string.format("RQE Memory usage: %.2f MB", memUsage / 1024)
        else
            memUsageText = string.format("RQE Memory usage: %.2f KB", memUsage)
        end

		-- Update the MemoryUsageText FontString with the new memory usage
		if RQEFrame and RQEFrame.MemoryUsageText then
			RQEFrame.MemoryUsageText:SetText(memUsageText)
		end
    else
        -- User wants to hide memory usage or the setting is not available
        if RQEFrame and RQEFrame.MemoryUsageText then
            -- Hide or clear the text
            RQEFrame.MemoryUsageText:SetText("")
        end
    end
end


function RQE:AdvanceNextStep(questID)
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID

		C_Timer.After(0.5, function()
			RQE:ClickSuperTrackedQuestButton()
			--RQE:CheckAndAdvanceStep(questID)
		end)
	end
end


-- Handles building the macro from the super tracked quest
function RQE:BuildQuestMacroBackup()
	isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

    if isSuperTracking then
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
    end

	-- Allow time for the UI to update and for the super track to register
	C_Timer.After(1, function()
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
end


function RQE:ClickSuperTrackedQuestButton()
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    if not superTrackedQuestID or superTrackedQuestID == 0 then
        RQE.debugLog("No super tracked quest.")
        return
    end

    if not RQE.QuestLogIndexButtons then
        RQE.debugLog("QuestLogIndexButtons table is not initialized.")
        return
    end

    for _, button in pairs(RQE.QuestLogIndexButtons) do
        if button.questID == superTrackedQuestID then
            RQE.debugLog("Clicking button for super tracked quest ID:", superTrackedQuestID)
            button:Click()
            return
        end
    end

    RQE.debugLog("Button for super tracked quest ID not found:", superTrackedQuestID)
end


-- function RQE:HighlightCurrentStepWaypointButton(currentStepIndex)
    -- -- Loop through all WaypointButtons
    -- for i, button in ipairs(RQE.WaypointButtons) do
        -- -- Check if the button's step index matches the current step index
        -- if button.stepIndex == currentStepIndex then
            -- -- This is the button for the current step, so highlight it
            -- button.bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
            -- -- Store this button as the last highlighted button
            -- self.LastHighlightedWaypointButton = button
        -- elseif self.LastHighlightedWaypointButton == button then
            -- -- This button was previously highlighted, but is no longer the current step
            -- -- Reset its appearance to the default texture
            -- button.bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
        -- end
    -- end
-- end


-- Craft Specific Item for Quest
function RQE:CraftSpecificItem(recipeSpellID)
    -- Retrieve recipe information to check if it can be crafted
    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeSpellID)
    if not recipeInfo or not recipeInfo.learned or not recipeInfo.craftable then
        print("Recipe is not learned, not craftable, or doesn't exist.")
        return
    end

	if not (ProfessionsFrame and ProfessionsFrame:IsVisible()) then
        print("Ready to craft:", recipeInfo.name, "x1. Please open the dedicated profession window to craft and press the macro again.")
		return
    end

    -- Check if we've already printed the reagents for this recipe
    if not RQE.alreadyPrintedSchematics then
        -- Print the reagents required for the recipe
        RQE:PrintRecipeSchematic(recipeSpellID, false) -- Assuming isRecraft is false; adjust as needed

        -- Mark this recipe as having its reagents printed so we don't do it again
        RQE.alreadyPrintedSchematics = true
    end
end


-- Display an ItemLink for the required Reagents
function RQE:PrintRecipeSchematic(recipeSpellID, isRecraft, recipeLevel)
    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeSpellID, isRecraft, recipeLevel)
    if not schematic then
        print("Schematic not found for recipeSpellID:", recipeSpellID)
        return
    end

    local reagentsString = "Reagent(s) Required: "
    local firstReagent = true

    -- Print basic recipe information
    RQE.infoLog("Recipe ID:", schematic.recipeID)
    RQE.infoLog("Name:", schematic.name)
    RQE.infoLog("Quantity Min:", schematic.quantityMin, "Quantity Max:", schematic.quantityMax)
    RQE.infoLog("Product Quality:", schematic.productQuality or "N/A")
    RQE.infoLog("Output Item ID:", schematic.outputItemID or "N/A")

    -- Check if there are reagent slot schematics to iterate over
    if schematic.reagentSlotSchematics then
        for i, slotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if slotSchematic.reagents then
                for _, reagent in ipairs(slotSchematic.reagents) do
                    local itemName = "Unknown"
                    if reagent.itemID then
                        itemName = GetItemInfo(reagent.itemID) or itemName
                    end
                    RQE.infoLog("  - Item:", itemName, "Item ID:", reagent.itemID or "N/A", "Quantity Required:", slotSchematic.quantityRequired)
                end
            end
        end
    else
        RQE.infoLog("No reagent slot schematics available.")
    end

	-- Print the required items including item link to chat
    if schematic.reagentSlotSchematics then
        for i, slotSchematic in ipairs(schematic.reagentSlotSchematics) do
            if slotSchematic.reagents then
                for _, reagent in ipairs(slotSchematic.reagents) do
                    local itemLink = select(2, GetItemInfo(reagent.itemID))
                    local quantityRequired = slotSchematic.quantityRequired
                    if itemLink and quantityRequired then
                        if not firstReagent then
                            reagentsString = reagentsString .. ", "
                        else
                            firstReagent = false
                        end
                        reagentsString = reagentsString .. itemLink .. " x" .. quantityRequired
                    end
                end
            end
        end
    else
        reagentsString = reagentsString .. "None."
    end

    print(reagentsString)
end


-- Function to confirm and buy an item from a merchant
function RQE:ConfirmAndBuyMerchantItem(index, quantity)
    local itemName, _, _, _, _, _, _, maxStack = GetMerchantItemInfo(index)
    local itemLink = GetMerchantItemLink(index)
    quantity = tonumber(quantity) or 1  -- Default to buying 1 if no quantity specified, and ensure it's a number
    maxStack = tonumber(maxStack) or 1  -- Ensure maxStack is a number, defaulting to 1 if not available

    StaticPopupDialogs["RQE_CONFIRM_PURCHASE"] = {
        text = "Do you want to buy " .. quantity .. " of " .. (itemLink or itemName) .. "?",
        button1 = "Yes",
        button2 = "No",
        OnShow = function(self)
            local itemFrame = CreateFrame("Frame", nil, self)
            itemFrame:SetAllPoints(self.text)
            itemFrame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(itemFrame, "ANCHOR_TOP")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:Show()
            end)
            itemFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end,
        OnAccept = function()
            if quantity > maxStack then
                local fullStacks = math.floor(quantity / maxStack)
                local remainder = quantity % maxStack
                for i = 1, fullStacks do
                    BuyMerchantItem(index, maxStack)
                end
                if remainder > 0 then
                    BuyMerchantItem(index, remainder)
                end
            else
                BuyMerchantItem(index, quantity)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,  -- Avoid taint from UIParent
    }
    StaticPopup_Show("RQE_CONFIRM_PURCHASE")
end


-- Function that handles a series of functions related to purchasing an item from the AH
function RQE:SearchPreparePurchaseConfirmAH(itemID, quantity)
	-- Check if either TomTom or TradeSkillMaster is loaded
	if IsAddOnLoaded("CraftSim") or IsAddOnLoaded("TradeSkillMaster") then
		RQE:SearchAndPrepareAuctionItem(itemID, quantity)
		--RQE:SearchAndDisplayCommodityResults(itemID, quantity)
	else
		RQE:SearchAndPrepareAuctionItem(itemID, quantity)
		--RQE:SearchAndDisplayCommodityResults(itemID, quantity)
		RQE:ConfirmAndPurchaseCommodity(itemID, quantity)
	end
end


-- Function to search an item in the auction house and prepare for manual review
function RQE:SearchAndPrepareAuctionItem(itemID, quantity)
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        print("Auction House is not open.")
        return
    end

    local itemKey = C_AuctionHouse.MakeItemKey(itemID)
    RQE.debugLog("Created ItemKey for itemID:", itemID, "Item Level:", itemKey.itemLevel, "Item Suffix:", itemKey.itemSuffix)

    -- Array of itemKeys to search
    local itemKeys = {itemKey}

    -- Search for the item using ItemKeys
    C_AuctionHouse.SearchForItemKeys(itemKeys, {sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false})
    RQE.infoLog("Search query sent for ItemID:", itemID, "with quantity:", quantity)

    -- Check and display search results after a short delay to allow data to load
    C_Timer.After(1, function()
        local numResults = C_AuctionHouse.GetNumItemSearchResults(itemKey)

        if numResults > 0 then
            for index = 1, numResults do
                local resultInfo = C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)
                if resultInfo then
                    print("Result", index, ": Price =", resultInfo.buyoutPrice or "No buyout", "Quantity =", resultInfo.quantity)
                end
            end
        else
            print("No results found for itemID:", itemID)
        end
    end)
end


-- Function that searches for and prints out the prices for an item
function RQE:SearchAndDisplayCommodityResults(itemID, quantity)
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        print("Auction House is not open.")
        return
    end

    -- Creating the item key for the commodity
    local itemKey = C_AuctionHouse.MakeItemKey(itemID)
    local searchQuery = {
        itemKey = itemKey,
        sorts = { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false }
    }

    -- Sending the search query
    C_AuctionHouse.SendSearchQuery(itemKey, searchQuery.sorts, false)

    C_Timer.After(1, function()
        if C_AuctionHouse.HasFullCommoditySearchResults(itemID) then
            local numResults = C_AuctionHouse.GetNumCommoditySearchResults(itemID)
            if numResults > 0 then
                -- Iterate through results and display them
                for index = 1, numResults do
                    local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
                    if result then
                        print("Result " .. index .. ": Price per unit: " .. GetCoinTextureString(result.unitPrice) .. ", Quantity: " .. result.quantity)
                    end
                end
            else
                print("No results found for itemID: ", itemID)
            end
        else
            -- Not all results may be loaded immediately; consider requesting more results or retrying
            C_AuctionHouse.RequestMoreCommoditySearchResults(itemID)
        end
    end)
end


-- Function to confirm and purchase a commodity from the auction house
function RQE:ConfirmAndPurchaseCommodity(itemID, quantity)
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        print("Auction House is not open.")
        return
    end

    local itemName = C_Item.GetItemNameByID(itemID)  -- Fetch the item name directly from the item ID
    if not itemName then
        print("Failed to retrieve item name for ID:".. itemID .. ". Please try search again.")
        return
    end

    local itemKey = C_AuctionHouse.MakeItemKey(itemID)
    -- Sending the search query
    C_AuctionHouse.SendSearchQuery(itemKey, {sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false}, false)

    C_Timer.After(1, function()
        local numResults = C_AuctionHouse.GetNumCommoditySearchResults(itemID)
        if numResults > 0 then
            local totalQuantityNeeded = quantity
            local totalCost = 0
            local index = 1
            while totalQuantityNeeded > 0 and index <= numResults do
                local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
                if result then
                    local quantityAvailable = result.quantity
                    local unitPrice = result.unitPrice
                    local quantityToBuy = min(quantityAvailable, totalQuantityNeeded)
                    totalCost = totalCost + (quantityToBuy * unitPrice)
                    totalQuantityNeeded = totalQuantityNeeded - quantityToBuy
                    print("Buying", quantityToBuy, "units at", GetCoinTextureString(unitPrice), "each.")
                end
                index = index + 1
            end
            if totalQuantityNeeded > 0 then
                print("Not enough quantity available to meet the requested purchase.")
            else
                local itemLink = C_AuctionHouse.GetReplicateItemLink(1) or select(2, GetItemInfo(itemID))
                if not itemLink then
                    itemLink = string.format("\124cff0070dd\124Hitem:%d::::::::70:::::\124h[%s]\124h\124r", itemID, C_Item.GetItemNameByID(itemID))
                end
                print("Total cost for " .. itemLink .. " x" .. quantity .. " will be " .. GetCoinTextureString(totalCost))
                -- Here you might want to display the confirmation popup with the total cost
                StaticPopupDialogs["RQE_CONFIRM_PURCHASE_COMMODITY"] = {
                    text = string.format("Confirm your purchase of %d x [%s] for %s.", quantity, C_Item.GetItemNameByID(itemID), GetCoinTextureString(totalCost)),
                    button1 = "Yes",
                    button2 = "No",
                    OnAccept = function()
                        C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity, unitPrice)
                        C_Timer.After(0.5, function()  -- Allow for server response time
                            C_AuctionHouse.ConfirmCommoditiesPurchase(itemID, quantity)
                        end)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,  -- Avoid taint from UIParent
                OnShow = function(self)
                    self.text:SetFormattedText(self.text:GetText(), itemLink, quantity, GetCoinTextureString(totalCost))
                    local itemFrame = CreateFrame("Frame", nil, self)
                    itemFrame:SetAllPoints(self.text)
                    itemFrame:SetScript("OnEnter", function()
                        GameTooltip:SetOwner(itemFrame, "ANCHOR_TOP")
                        GameTooltip:SetHyperlink(itemLink)
                        GameTooltip:Show()
                    end)
                    itemFrame:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                end,
                }
                StaticPopup_Show("RQE_CONFIRM_PURCHASE_COMMODITY")
            end
        end
    end)
end


-- Function that checks to see if player has a DragonRiding Aura/Mount active
function RQE.CheckForDragonMounts()
    for _, dragonName in ipairs(RQE.dragonMounts) do
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", dragonName)
        if aura then
            RQE.infoLog("Dragon riding with:", dragonName)
            return true  -- Dragon mount aura found
        end
    end
    RQE.infoLog("No dragon mount found.")
    return false  -- No dragon mount aura found
end


-- Function that checks if the player has the Dragon Racing Aura up
function RQE.HasDragonraceAura()
    local aura = C_UnitAuras.GetAuraDataBySpellName("player", "Racing", "HELPFUL")  -- Assuming "Racing" is the correct aura name and it's a buff
    if aura then
        return true
    else
        return false
    end
end


---------------------------------------------------
-- 19. Finalization
---------------------------------------------------

-- Converts table to string for debug purposes
function RQE:TableToString(tbl)
    if tbl == nil then
        RQE.debugLog("Table is nil in TableToString")
        return
    end
    local str = "{"
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            v = RQE:TableToString(v)
        end
        str = str .. tostring(k) .. " = " .. tostring(v) .. ", "
    end
    return str .. "}"
end


-- Function to update DB profile frame position
function RQE:UpdateFrameFromProfile()
    local xPos = RQE.db.profile.framePosition.xPos or -40
    local yPos = RQE.db.profile.framePosition.yPos or -270
    RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
end


---------------------------------------------------
-- 20. Experimental Testing Ground
---------------------------------------------------

-- Function to log scenario information, including previously ignored values
function RQE.LogScenarioInfo()
    if not RQE.debugMode then return end  -- Only log if debugging is explicitly enabled
    if C_Scenario.IsInScenario() then
        local scenarioName, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete, completed, xp, money, scenarioType, areaName, textureKit, scenarioID = C_Scenario.GetInfo()

        RQE.infoLog("Scenario Name: " .. tostring(scenarioName))
        RQE.infoLog("Current Stage: " .. tostring(currentStage))
        RQE.infoLog("Number of Stages: " .. tostring(numStages))
        RQE.infoLog("Flags: " .. tostring(flags))
        RQE.infoLog("HasBonusStep: " .. tostring(hasBonusStep))
        RQE.infoLog("isBonusStepComplete: " .. tostring(isBonusStepComplete))
        RQE.infoLog("Completed: " .. tostring(completed))
        RQE.infoLog("XP Reward: " .. tostring(xp))
        RQE.infoLog("Money Reward: " .. tostring(money))
        RQE.infoLog("Scenario Type: " .. tostring(scenarioType))
        RQE.infoLog("areaName: " .. tostring(areaName))
        RQE.infoLog("Texture Kit: " .. tostring(textureKit))
		RQE.infoLog("scenarioID: " .. tostring(scenarioID))
    end
end


function RQE.ScenarioTimer_CheckTimers(...)
	-- only supporting 1 active timer
	for i = 1, select("#", ...) do
		local timerID = select(i, ...);
		local _, elapsedTime, type = GetWorldElapsedTime(timerID);
		if ( type == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE) then
			local mapID = C_ChallengeMode.GetActiveChallengeMapID();
			if ( mapID ) then
				local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID);
				Scenario_ChallengeMode_ShowBlock(timerID, elapsedTime, timeLimit);
				return;
			end
		elseif ( type == LE_WORLD_ELAPSED_TIMER_TYPE_PROVING_GROUND ) then
			local diffID, currWave, maxWave, duration = C_Scenario.GetProvingGroundsInfo()
			if (duration > 0) then
				Scenario_ProvingGrounds_ShowBlock(timerID, elapsedTime, duration, diffID, currWave, maxWave);
				return;
			end
		end
	end
	-- we had an update but didn't find a valid timer, kill the timer if it's running
	ScenarioTimer_Stop();
end
