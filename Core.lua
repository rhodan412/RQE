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
RQEMacro = RQEMacro or {}

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

--- @class AceAddon
local AceAddon = {}

--- @param name string
--- @param ... any
--- @return AceAddon
function AceAddon:NewAddon(name, ...)
	return {}  -- Returning an empty table as a dummy AceAddon instance
end

-- Initialize RQE addon with AceAddon
---@class RQE : AceAddon  -- This line declares that RQE is a subclass of AceAddon
RQE = LibStub("AceAddon-3.0"):NewAddon("RQE", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

-- AceConfig and AceConfigDialog references
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")


---------------------------------------------------
-- 3. Debugging Functions
---------------------------------------------------

--- Safe Print Function
--- Converts the arguments to a string and prints them.
--- @param ... any The arguments to print
function RQE:SafePrint(...)
	local args = {...}
	local output = {}
	for i, v in ipairs(args) do
		if type(v) == "table" then
			output[i] = "Table: Cannot display"
		elseif type(v) == "boolean" then
			output[i] = v and "True" or "False"
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
		if debugLevel == "INFO" or debugLevel == "INFO+" or debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
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
		autoClickWaypointButton = true,
		autoQuestProgress = true,
		autoQuestWatch = true,
		autoTrackZoneQuests = false,
		BossKill = false,
		ClientSceneClosed = false,
		ClientSceneOpened = false,
		debugLevel = "NONE",
		debugLoggingCheckbox = false,
		debugMode = true,
		displayRQEmemUsage = false,
		enableCarboniteCompatibility = true,
		enableFrame = true,
		enableGossipModeAutomation = false,
		enableNearestSuperTrack = true,
		enableNearestSuperTrackCampaign = false,
		enableNearestSuperTrackCampaignOnlyWhileLeveling = false,
		enableQuestAbandonConfirm = false,
		enableQuestFrame = true,
		enableTomTomCompatibility = true,
		EncounterEnd = false,
		framePosition = {
			xPos = -40,
			yPos = -285,
			anchorPoint = "TOPRIGHT",
			frameWidth = 420,
			frameHeight = 300,
		},
		globalSetting = true,
		hideRQEFrameWhenEmpty = false,
		hideRQEQuestFrameWhenEmpty = false,
		JailorsTowerLevelUpdate = false,
		keyBindSetting = nil,
		isFrameMaximized = true,  -- Setting for maximized/minimized state
		isQuestFrameMaximized = true,  -- Setting for maximized/minimized state
		LFGActiveEntryUpdate = false,
		MainFrameOpacity = 0.55,
		minimapButtonAngle = 125,
		PlayerEnteringWorld = false,
		PlayerStartedMoving = false,
		PlayerStoppedMoving = false,
		QuestAccepted = false,
		QuestAutocomplete = false,
		QuestComplete = false,
		QuestCurrencyLootReceived = false,
		QuestFinished = false,
		QuestFramePosition = {
			xPos = -40,
			yPos = 150,
			anchorPoint = "BOTTOMRIGHT",
			frameWidth = 325,
			frameHeight = 450
		},
		QuestFrameOpacity = 0.55,
		QuestlineUpdate = false,
		QuestListWatchListChanged = false,
		QuestLogCriteriaUpdate = false,
		QuestLootReceived = false,
		QuestRemoved = false,
		QuestStatusUpdate = false,
		QuestTurnedIn = false,
		QuestWatchUpdate = false,
		removeWQatLogin = false,
		ScenarioCompleted = false,
		ScenarioCriteriaUpdate = false,
		ScenarioUpdate = false,
		showAddonLoaded = false,
		showArgPayloadInfo = false,
		showCoordinates = true,
		showEventAchievementEarned = false,
		showEventContentTrackingUpdate = false,
		showEventCriteriaEarned = false,
		showEventDebugInfoCheckbox = false,
		showEventSuperTrackingChanged = false,
		showItemCountChanged = false,
		showMapID = true,
		showMinimapIcon = false,
		showPlayerLogin = false,
		showPlayerRegenEnabled = false,
		showPlayerMountDisplayChanged = false,
		showTrackedAchievementUpdate = false,
		StartTimer = false,
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
		toggleBlizzObjectiveTracker = true,
		UpdateInstanceInfo = false,
		WorldStateTimerStart = false,
		WorldStateTimerStop = false,
		ZoneChange = false,
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


-- Initializes Local Variables
local isMacroCreationInProgress = false		-- Declare a variable to track if macro creation is currently in progress
local isPeriodicCheckInProgress = false		-- Declare a variable to track if periodic checks are currently in progress


-- Initialize Waypoint System
RQE.waypoints = {}


RQE.SetInitialFromAccept = false
RQE.SetInitialFromSuperTrack = false

-- Initialize the savedAutomaticWorldQuestWatches table within addon's initialization logic
if not RQE.savedAutomaticWorldQuestWatches then
	RQE.savedAutomaticWorldQuestWatches = {}
end


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

	-- Create AceDB-3.0 database
	--self.db = LibStub("AceDB-3.0"):New("RQEDB", defaults, true) -- Set default profile to the character
	self.db = LibStub("AceDB-3.0"):New("RQEDB", defaults, "Default")

	-- Initialize tables for storing StepsText, CoordsText, and WaypointButtons
	RQE.StepsText = RQE.StepsText or {}
	RQE.CoordsText = RQE.CoordsText or {}
	RQE.WaypointButtons = RQE.WaypointButtons or {}

	-- Register the profile changed callback
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Now call UpdateFrameFromProfile to set the frame's position
	self:UpdateFrameFromProfile()

	-- Initialize character-specific data
	self:GetCharacterInfo()

	-- Register the main options table with a light purple name
	AC:RegisterOptionsTable("RQE_Main", RQE.options.args.general)
	self.optionsFrame = ACD:AddToBlizOptions("RQE_Main", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register the "Frame" options table as a separate tab
	AC:RegisterOptionsTable("RQE_Frame", RQE.options.args.frame)
	self.optionsFrame.frame = ACD:AddToBlizOptions("RQE_Frame", "Frame Settings", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register the "Font" options table as a separate tab
	AC:RegisterOptionsTable("RQE_Font", RQE.options.args.font)
	self.optionsFrame.font = ACD:AddToBlizOptions("RQE_Font", "Font Settings", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register the "Debug" options table as a separate tab
	AC:RegisterOptionsTable("RQE_Debug", RQE.options.args.debug)
	self.optionsFrame.debug = ACD:AddToBlizOptions("RQE_Debug", "Debug Options", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Add profiles (if needed)
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("RQE_Profiles", profiles)
	ACD:AddToBlizOptions("RQE_Profiles", "Profiles", "|cFFCC99FFRhodan's Quest Explorer|r")

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
	RQE.RQEQuestFrame:SetBackdropColor(0, 0, 0, QuestOpacity) -- Same for the quest frame

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
		end
		info.checked = RQE.db.profile.autoTrackZoneQuests
		UIDropDownMenu_AddButton(info, level)

		-- First-level menu items
		info.text = "Completed Quests"
		info.func = RQE.filterCompleteQuests
		UIDropDownMenu_AddButton(info, level)

		info.text = "Daily / Weekly Quests"
		info.func = RQE.filterDailyWeeklyQuests
		UIDropDownMenu_AddButton(info, level)

		info.text = "Zone Quests"
		info.func = RQE.filterZoneQuests
		UIDropDownMenu_AddButton(info, level)

		-- ... other first-level items ...

		info.text = "Select Campaign..."
		info.hasArrow = true  -- Important for creating a submenu
		info.value = "campaign_submenu"  -- Used to identify this item in the next level
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 and _G.UIDROPDOWNMENU_MENU_VALUE == "campaign_submenu" then
		local campaigns = RQE.GetCampaignsFromQuestLog()
		for campaignID, campaignName in pairs(campaigns) do
			info.text = campaignName
			info.func = function() RQE.filterSpecificCampaign(campaignID) end
			UIDropDownMenu_AddButton(info, level)
		end
	end
end


-- InitializeFrame function
function RQE:InitializeFrame()
	--self:Initialize()  -- Call Initialize() within InitializeFrame



	-- Call the function to initialize the separate focus frame
	RQE.InitializeSeparateFocusFrame()

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

	-- Notify AceConfig to update UI
	LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE")
end


---------------------------------------------------
-- 6. Saving/Restoring SuperTrack Data
---------------------------------------------------

-- Function to open the quest log and show specific quest details
--- @param questID number The quest ID.
function OpenQuestLogToQuestDetails(questID)
	if RQE.searchedQuestID ~= nil then
		return
	end

	---@type number|nil
	local mapID = GetQuestUiMapID(questID) or C_TaskQuest.GetQuestZoneID(questID)
	if mapID == 0 then mapID = nil end
	OpenQuestLog(mapID)
	QuestMapFrame_ShowQuestDetails(questID)
end


function RQE.SaveCoordData()
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if RQE.db.profile.autoClickWaypointButton and RQE.AreStepsDisplayed(questID) then
		if questID then
			-- Logic for updating location data
			local questData = RQE.getQuestData(questID)
			if questData and questData.location then
				-- Update the location data for the examined quest
				RQE.DatabaseSuperX = questData.location.x / 100
				RQE.DatabaseSuperY = questData.location.y / 100
				RQE.DatabaseSuperMapID = questData.location.mapID
			end
		end
	end
end


-- Function that saves data of the Super Tracked Quest
function RQE.SaveSuperTrackData()
	-- Extracts Details of Quest if possible
	RQE.ExtractAndSaveQuestCoordinates()

	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	if questID then
		local playerMapID = C_Map.GetBestMapForUnit("player")
		local mapID = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID)
		local questTitle = C_QuestLog.GetTitleForQuestID(questID)
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local posX, posY

		if isWorldQuest then
			posX, posY = C_TaskQuest.GetQuestLocation(questID, mapID)
		else
			if not posX or not posX and mapID then
				local questID = C_SuperTrack.GetSuperTrackedQuestID()
				local mapID = GetQuestUiMapID(questID)
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


-- Function to save the current supertracked quest to the character-specific table
function RQE:SaveSuperTrackedQuestToCharacter()
    -- Get the currently supertracked quest ID
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

    -- Ensure we have a valid quest ID before saving
    if superTrackedQuestID and superTrackedQuestID > 0 then
        -- Check if it is a world quest
        local isWorldQuest = C_QuestLog.IsWorldQuest(superTrackedQuestID)

        -- Save it to the character-specific table with world quest flag
        RQECharacterDB.superTrackedQuestID = superTrackedQuestID
        RQECharacterDB.isWorldQuest = isWorldQuest

        if RQE.db.profile.debugLevel == "INFO+" then
            print("Saved supertracked quest for this character: " .. superTrackedQuestID)
        end
    else
        RQECharacterDB.superTrackedQuestID = nil
        RQECharacterDB.isWorldQuest = nil
    end
end


-- Function to restore the saved supertracked quest for the current character
function RQE:RestoreSuperTrackedQuestForCharacter()
    if RQECharacterDB and RQECharacterDB.superTrackedQuestID then
        local savedQuestID = RQECharacterDB.superTrackedQuestID
        local isWorldQuest = RQECharacterDB.isWorldQuest

        -- Check if it's a world quest
        if isWorldQuest then
            -- Check if the world quest is still available
            local isWorldQuestStillAvailable = C_QuestLog.IsWorldQuest(savedQuestID) and C_QuestLog.GetQuestObjectives(savedQuestID) ~= nil

            if isWorldQuestStillAvailable then
                -- Restore the world quest as supertracked
                C_SuperTrack.SetSuperTrackedQuestID(savedQuestID)
                if RQE.db.profile.debugLevel == "INFO+" then
                    print("Restored supertracked world quest for this character: " .. savedQuestID)
                end
            else
                -- World quest is no longer available, clear supertracked quest
                RQECharacterDB.superTrackedQuestID = nil
                RQECharacterDB.isWorldQuest = nil
                if RQE.db.profile.debugLevel == "INFO+" then
                    print("Saved supertracked world quest is no longer valid.")
                end
            end
        else
            -- Check if the regular quest is still valid and in the quest log
            if C_QuestLog.IsOnQuest(savedQuestID) then
                C_SuperTrack.SetSuperTrackedQuestID(savedQuestID)
                if RQE.db.profile.debugLevel == "INFO+" then
                    print("Restored supertracked quest for this character: " .. savedQuestID)
                end
            else
                -- If the quest is no longer valid, clear the supertracked quest
                RQECharacterDB.superTrackedQuestID = nil
                RQECharacterDB.isWorldQuest = nil
                if RQE.db.profile.debugLevel == "INFO+" then
                    print("Saved supertracked quest is no longer valid.")
                end
            end
        end
    else
        if RQE.db.profile.debugLevel == "INFO+" then
            print("No saved supertracked quest found for this character.")
        end
    end
end


function RQE:UpdateWaypointForStep(questID, stepIndex)
	local questData = RQE.getQuestData(questID)
	if questData and questData[stepIndex] then
		local stepData = questData[stepIndex]
		if stepData and stepData.coordinates then
			-- Logic to set the new waypoint
			RQE:OnCoordinateClicked(stepIndex)
		end
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
		mapID = GetQuestUiMapID(questID)
	end

	if not mapID then
		return
	end

	-- If POI info is not available, try using GetNextWaypointForMap
	if not posX or not posY then
		if not isMapOpen and RQE.superTrackingChanged and not InCombatLockdown() then
			-- Call the function to open the quest log with the details of the super tracked quest
			OpenQuestLogToQuestDetails(questID)
		else
			-- Either map is open, or we are in combat, or another secure operation is in progress [fix for Frame:SetPassThroughButtons() error]
			RQE.debugLog("Cannot open quest details due to combat lockdown or other restrictions.")
			return
		end

		--completed, posX, posY, objective = QuestPOIGetIconInfo(questID)

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
	local isWorldQuest = C_QuestLog.IsWorldQuest(savedSuperTrackedQuestID)

	-- Check if the quest was manually tracked
	local manuallyTracked = RQE.ManuallyTrackedQuests and RQE.ManuallyTrackedQuests[savedSuperTrackedQuestID]

	-- Check if the quest is completed
	local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(savedSuperTrackedQuestID)

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
	RQE:RemoveSuperTrackingFromQuest()

	-- Restore the super-tracked quest after a delay for non-world quests
	C_Timer.After(0.2, function()
		if savedSuperTrackedQuestID then
			-- Fetch quest info from RQEDatabase if available
			local questInfo = RQE.getQuestData(savedSuperTrackedQuestID)
			if questInfo then
				local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(savedSuperTrackedQuestID)
				UpdateFrame(savedSuperTrackedQuestID, questInfo, StepsText, CoordsText, MapIDs)
				AdjustRQEFrameWidths()
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
		if SettingsPanel then
			-- Use the new API to open the correct settings panel
			SettingsPanel:OpenToCategory("|cFFCC99FFRhodan's Quest Explorer|r")
		else
			-- Fallback for older versions, force open Interface Options to the AddOns tab
			InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
			InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer") -- Sometimes needs to be called twice due to Blizzard quirk
		end
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
		local openFrame
		if SettingsPanel then
			openFrame = _G.SettingsPanel:GetCurrentCategory()
		else
			openFrame = _G.InterfaceOptionsFramePanelContainer.displayedPanel
		end

		if openFrame and openFrame.name == "Rhodan's Quest Explorer" then
			if SettingsPanel then
				SettingsPanel:OpenToCategory("|cFFCC99FFRhodan's Quest Explorer|r")
			else
				InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
				InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
			end
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


--- Initializes the addon database with given options.
--- @param options table - Configuration options to set up the addon.
function RQE:SetupDB(options)
	RQE.options = options
	RQE:SetProfileOnce()
end


--- Sets the user profile for the addon, but only once to avoid overwriting.
--- If no profile is specified, defaults to the current player's name and realm.
--- @param chosenProfile string|nil - The manually chosen profile or nil.
function RQE:SetProfileOnce(chosenProfile)
	if not RQE.profileHasBeenSet then
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
	-- Reload any saved variables or reset frames, etc.
	self:UpdateFrameFromProfile()

	-- Refreshes/Reads the Configuration settings for the customized text (in the current/new profile) and calls them when the profile is changed to that from an earlier profile
	RQE:ConfigurationChanged()
end


---------------------------------------------------
-- 8. Toggle Frames
---------------------------------------------------

-- Function to show RQE frames by default on login
function RQE:ShowRQEFramesOnLogin()
	-- Show the frames only if they are not already shown
	if not RQEFrame:IsShown() then
		RQEFrame:Show()
	end
	if not RQE.RQEQuestFrame:IsShown() then
		RQE.RQEQuestFrame:Show()
	end
end


-- Function to initialize the objective tracker state based on the checkbox and frames visibility
function RQE:InitializeObjectiveTracker()
	if not RQE.db.profile.toggleBlizzObjectiveTracker or RQEFrame:IsShown() or RQE.RQEQuestFrame:IsShown() then
		-- If the checkbox is not checked or RQE frames are visible, hide the Blizzard tracker
		ObjectiveTrackerFrame:Hide()
	else
		-- Otherwise, show the Blizzard tracker
		ObjectiveTrackerFrame:Show()
	end
end


-- Hook the Objective Tracker's OnShow event to enforce the state based on visibility conditions
ObjectiveTrackerFrame:HookScript("OnShow", function()
	if not RQE.db.profile.toggleBlizzObjectiveTracker or RQEFrame:IsShown() or RQE.RQEQuestFrame:IsShown() then
		ObjectiveTrackerFrame:Hide()
	end
end)


-- Continuous checking with OnUpdate to enforce the visibility state of the Blizzard Objective Tracker
local hideObjectiveTrackerFrame = CreateFrame("Frame")
hideObjectiveTrackerFrame:SetScript("OnUpdate", function()
	if not RQE.db.profile.toggleBlizzObjectiveTracker or RQEFrame:IsShown() or RQE.RQEQuestFrame:IsShown() then
		-- Hide the Blizzard Objective Tracker if the conditions are met
		ObjectiveTrackerFrame:Hide()
	end
end)


-- Function to update the state of the minimap based on the current profile settings
function RQE:ToggleMinimapIcon()
	local newValue = self.db.profile.showMinimapIcon
	RQE.debugLog("Toggling Minimap Icon. New Value: ", tostring(newValue))  -- Debugging line

	self.db.profile.showMinimapIcon = newValue  -- Update the profile value

	if newValue == true then
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

	-- Logic here to update checkbox UI element
	if RQE.MapIDCheckbox then
		RQE.MapIDCheckbox:SetChecked(newValue)
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
			elseif C_QuestLog.IsQuestTask(questID) then
				self.worldQuestCount = self.worldQuestCount + 1
			else
				self.regularQuestCount = self.regularQuestCount + 1
			end
		end
	end

	-- Check conditions for showing/hiding the frame, including manual closure
	if (self.db.profile.hideRQEQuestFrameWhenEmpty and (self.campaignQuestCount + self.regularQuestCount + self.worldQuestCount + self.AchievementsFrame.achieveCount == 0 and not self.isInScenario)) or self.isRQEQuestFrameManuallyClosed then
		RQE.RQEQuestFrame:Hide()
	else
		RQE.RQEQuestFrame:Show()
	end
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
	local mapID = C_Map.GetBestMapForUnit("player")
	if RQE.db.profile.showMapID and mapID then
		RQEFrame.MemoryUsageText:SetText("RQE Usage: " .. memUsageText)
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
	local yPos = self.db.profile.framePosition.yPos or -285

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
		RQE.RQEQuestFrame:ClearAllPoints()
		RQE.RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	end)

	if not success then
		RQE.debugLog("Error setting quest frame position: ", err)
	end
end


-- Function to update the RQEFrame size based on the current profile settings
function RQE:UpdateFrameSize()
	-- When reading from DB
	local frameWidth = self.db.profile.framePosition.frameWidth or 420
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
	local questFrameWidth = self.db.profile.QuestFramePosition.frameWidth or 325
	local questFrameHeight = self.db.profile.QuestFramePosition.frameHeight or 450

	-- Error handling for quest frame
	local success, err = pcall(function()
		RQE.RQEQuestFrame:SetSize(questFrameWidth, questFrameHeight)
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


-- Function to clear the contents of the SeparateFocusFrame
function RQE:ClearSeparateFocusFrame()
	-- Check if the SeparateFocusFrame exists
	if not RQE.SeparateFocusFrame then
		return
	end

	-- Ensure the frame is initialized	-- WAS CAUSING TEXT TO POSSIBLY BE YELLOW AND NOT HAVE WAYPOINT BUTTON INTIALIZED CORRECTLY IN SEPARATE FOCUS FRAME
	RQE.InitializeSeparateFocusFrame()

	-- Ensure SeparateStepText exists
	if not RQE.SeparateStepText then
		RQE.InitializeSeparateFocusFrame()
		-- RQE.SeparateStepText = RQE.SeparateFocusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		-- RQE.SeparateStepText:SetPoint("TOPLEFT", RQE.SeparateFocusFrame, "TOPLEFT", 10, -10)
		-- RQE.SeparateStepText:SetWidth(280)
		-- RQE.SeparateStepText:SetWordWrap(true)
	end

	if RQE.SeparateStepText then
		RQE.SeparateStepText:SetText("No step description available for this step.")
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
	RQE:RemoveSuperTrackingFromQuest()
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
		RQE:ClearSeparateFocusFrame()	-- Clears progress focus frame if nothing is being tracked
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
		-- Clear the RQEFrame if the quest is not in the log or does not match the searched quest ID
		RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQEMacro:ClearMacroContentByName("RQE Macro")
		return
	end

	if isWorldQuest then
		if not (manuallyTracked or (isBeingSearched and not isQuestCompleted) or watchedQuests[extractedQuestID]) then
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQEMacro:ClearMacroContentByName("RQE Macro")
			return
		end
	else
		-- For non-world quests, clear if not in quest log or not being actively searched
		if not (isBeingSearched or manuallyTracked or watchedQuests[extractedQuestID]) then
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQEMacro:ClearMacroContentByName("RQE Macro")
			return
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
			RQE:RemoveSuperTrackingFromQuest()
			return
		end

		if isWorldQuest then
			if not (manuallyTracked or (isBeingSearched and not isQuestCompleted) or watchedQuests[extractedQuestID]) then
				RQE:ClearFrameData()
				RQE:ClearWaypointButtonData()
				RQEMacro:ClearMacroContentByName("RQE Macro")

				-- Untrack the quest by setting a non-existent quest ID
				RQE:RemoveSuperTrackingFromQuest()
				return
			end
		end
	end)
end


-- Function to check if the quest in RQEFrame is either the searched quest or a tracked/watched quest, and clear if not
function RQE:CheckAndClearUntrackedQuest()
	-- Get the questID currently displayed in the RQEFrame
	local displayedQuestID = RQE.searchedQuestID

	-- If there is no questID in RQE.searchedQuestID, skip the check
	if not displayedQuestID then return end

	-- Flag to determine if the quest is relevant (either searched or tracked)
	local isQuestRelevant = false

	-- Check if the quest is the searched quest
	if RQE.searchedQuestID == displayedQuestID then
		isQuestRelevant = true
	else
		-- Loop through the regular quests tracked in RQEQuestFrame
		for i = 1, C_QuestLog.GetNumQuestWatches() do
			local trackedQuestID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if trackedQuestID == displayedQuestID then
				isQuestRelevant = true
				break
			end
		end

		-- Loop through the world quests tracked in RQEQuestFrame if not already found
		if not isQuestRelevant then
			for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
				local worldQuestID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
				if worldQuestID == displayedQuestID then
					isQuestRelevant = true
					break
				end
			end
		end
	end

	-- If the quest is not relevant, simulate the ClearButton click
	if not isQuestRelevant then
		if RQE.ClearButton and RQE.ClearButton:GetScript("OnClick") then
			RQE.ClearButton:GetScript("OnClick")(RQE.ClearButton)
		end
	end
end


-- UpdateFrame function
function UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking then return end

	-- Checks flag to see if the Blacklist underway is presently in process
	if RQE.BlacklistUnderway then return end

	RQE:CheckSuperTrackedQuestAndStep()

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

	AdjustRQEFrameWidths()

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
		RQE:SaveSuperTrackedQuestToCharacter()
	end

	UpdateRQEQuestFrame()

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
		questName = C_QuestLog.GetTitleForQuestID(questID)  -- Fallback to game's API call if no title is found in the databases
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
	local objectivesText = colorizeObjectives(questID)
	--objectivesText = colorizeObjectives(questID)

	if RQE.QuestObjectives then  -- Check if QuestObjectives is initialized
		RQE.QuestObjectives:SetText(objectivesText)
	else
		RQE.debugLog("RQE.QuestObjectives is not initialized.")
	end

	-- Fetch the next waypoint text for the quest
	local DirectionText = C_QuestLog.GetNextWaypointText(questID)
	RQEFrame.DirectionText = DirectionText  -- Save to addon table
	RQE.UnknownQuestButtonCalcNTrack()

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


-- -- Static Data Update Function
-- function RQE.UpdateFrameStaticData(questID)
	-- -- Retrieve the current super-tracked quest ID for debugging
	-- local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	-- local extractedQuestID
	-- if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		-- extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	-- end

	-- -- Use RQE.searchedQuestID if available; otherwise, fallback to extractedQuestID, then to currentSuperTrackedQuestID
	-- questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID

	-- -- Adjust frame widths for layout
	-- AdjustRQEFrameWidths()

	-- -- Debug print the overridden questID and the content of RQE.QuestIDText
	-- RQE.infoLog("Overridden questID with current super-tracked questID:", questID)

	-- -- Validate questID before proceeding
	-- if not questID or type(questID) ~= "number" then
		-- return
	-- end

	-- -- Update Quest ID Text
	-- if RQE.QuestIDText then
		-- RQE.QuestIDText:SetText("Quest ID: " .. (questID or "N/A"))
	-- end

	-- -- Fetch the quest title from quest data or the game API
	-- local questName = questInfo and questInfo.title or C_QuestLog.GetTitleForQuestID(questID)
	-- questName = questName or "N/A"  -- Default to "N/A" if no title is found

	-- -- Update Quest Name Text
	-- if RQE.QuestNameText then
		-- RQE.QuestNameText:SetText("Quest Name: " .. questName)
	-- end

	-- -- Update Quest Description Text
	-- local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	-- if questLogIndex then
		-- local _, questObjectives = GetQuestLogQuestText(questLogIndex)
		-- local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
		-- if RQE.QuestDescription then
			-- RQE.QuestDescription:SetText(descriptionText)
		-- end
	-- end
-- end


-- -- Dynamic Data Update Function (Objectives and Button States)
-- function RQE.UpdateFrameDynamicData(questID)
	-- -- Ensure the questID is valid
	-- if not questID or type(questID) ~= "number" then
		-- return
	-- end

	-- -- Update Quest Objectives Text
	-- local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
	-- if not objectivesTable then
		-- print("No objectives found for questID:", questID)
		-- return
	-- end

	-- local objectivesText = ""
	-- for _, objective in pairs(objectivesTable) do
		-- objectivesText = objectivesText .. (objective.text or "") .. "\n"
	-- end

	-- -- Apply colorization to objectivesText
	-- objectivesText = colorizeObjectives(questID)

	-- if RQE.QuestObjectives then
		-- RQE.QuestObjectives:SetText(objectivesText)
	-- else
		-- print("RQE.QuestObjectives is not initialized.")
	-- end

	-- -- Fetch and Update the next waypoint text
	-- local DirectionText = C_QuestLog.GetNextWaypointText(questID)
	-- RQEFrame.DirectionText = DirectionText  -- Save to addon table

	-- if RQE.DirectionTextFrame then
		-- RQE.DirectionTextFrame:SetText(DirectionText or "No direction available.")
	-- end

	-- -- Always show the UnknownQuestButton
	-- RQE.UnknownQuestButton:Show()

	-- -- Show or hide the SearchGroupButton based on quest group availability
	-- if questID and C_LFGList.CanCreateQuestGroup(questID) then
		-- RQE.SearchGroupButton:Show()
	-- else
		-- RQE.SearchGroupButton:Hide()
	-- end
-- end


-- function RQE.UpdateFrameSteps(questID)
	-- -- Fetch questInfo from RQEDatabase using the determined questID
	-- local questInfo = RQE.getQuestData(questID)
-- RQE.PauseUpdatesFlag = false
	-- -- PrintQuestStepsToChat provides StepsText, CoordsText, MapIDs
	-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	-- -- Update Steps Text
	-- if RQE.CreateStepsText and StepsText and CoordsText and MapIDs then
		-- RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
	-- end
-- end


-- -- Main UpdateFrame function
-- function UpdateFrame(questID)
	-- -- Fetch and update static data only once when the quest is first tracked
	-- if not RQE.staticDataInitialized or RQE.lastTrackedQuestID ~= questID then
		-- RQE.UpdateFrameStaticData(questID)
		-- RQE.staticDataInitialized = true
		-- RQE.lastTrackedQuestID = questID
	-- end

	-- -- Fetch and update dynamic data on every call
	-- RQE.UpdateFrameDynamicData(questID)

	-- if questID == 78640 then 
		-- RQE.PauseUpdatesFlag = true
		-- return
	-- end

	-- -- Function call that gets updated every time this function is called
	-- RQE.UpdateFrameSteps(questID)

	-- -- Perform any additional final updates here, e.g., clearing the frame
	-- RQE:ShouldClearFrame()

	-- -- Example: Update Button Visibility
	-- C_Timer.After(1, function()
		-- RQE.Buttons.UpdateMagicButtonVisibility()
	-- end)
-- end


-- Create the tooltip when mousing over certain assets
function RQE:CreateQuestTooltip(self, questID, questTitle)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT", -30, 0)  -- Anchor the tooltip to the cursor
	GameTooltip:ClearLines()

	-- Add the quest title
	GameTooltip:AddLine(questTitle)
	GameTooltip:AddLine(" ")  -- Blank line

	-- Add description
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	if questLogIndex then
		local _, questObjectives = GetQuestLogQuestText(questLogIndex)
		local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
		GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
		GameTooltip:AddLine(" ")
	end

	-- Add objectives
	local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
	local objectivesText = objectivesTable and "" or "No objectives available."
	if objectivesTable then
		for _, objective in pairs(objectivesTable) do
			objectivesText = objectivesText .. objective.text .. "\n"
		end
	end

	if objectivesText and objectivesText ~= "" then
		GameTooltip:AddLine("Objectives:")
		GameTooltip:AddLine(objectivesText, 1, 1, 1, true)
		GameTooltip:AddLine(" ")
	end

	-- Add Rewards
	RQE:QuestRewardsTooltip(GameTooltip, questID)

	-- Add the quest ID
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82)  -- Aquamarine color

	GameTooltip:Show()
end


-- Function to find the closest quest currently being tracked
function RQE:GetClosestTrackedQuest()
	local closestQuestID = nil
	local closestDistance = math.huge  -- Initialize with a very large number
	local playerMapID = C_Map.GetBestMapForUnit("player")
	local playerLevel = UnitLevel("player")
	local maxPlayerLevel = GetMaxPlayerLevel()

	if RQE.db.profile.debugLevel == "INFO+" then
		print("playerLevel is " .. playerLevel .. " and maxPlayerLevel is " .. maxPlayerLevel)
	end

	-- Iterate through all quests in the player's quest log
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)

		-- Only consider quests that are being tracked and on the map
		if info and info.isOnMap and C_QuestLog.IsOnQuest(info.questID) then

			-- Case 1: Super track nearest non-campaign quest if campaign tracking is disabled
			if RQE.db.profile.enableNearestSuperTrack and not RQE.db.profile.enableNearestSuperTrackCampaign then
				local questPosition = C_QuestLog.GetQuestObjectives(info.questID)
				if questPosition then
					local distance = C_QuestLog.GetDistanceSqToQuest(info.questID)

					-- Update closest quest if this one is closer
					if distance and distance < closestDistance then
						closestDistance = distance
						closestQuestID = info.questID
					end
				end

			-- Case 2: Super track nearest campaign quest while leveling if "Leveling Only" is enabled
			elseif RQE.db.profile.enableNearestSuperTrackCampaignLevelingOnly and playerLevel < maxPlayerLevel then
				local classification = C_QuestInfoSystem.GetQuestClassification(info.questID)
				if classification == Enum.QuestClassification.Campaign then
					local distance = C_QuestLog.GetDistanceSqToQuest(info.questID)

					-- Update closest campaign quest if this one is closer
					if distance and distance < closestDistance then
						closestDistance = distance
						closestQuestID = info.questID
					end
				end

			-- Case 3: Super track nearest campaign quest even at max level
			elseif RQE.db.profile.enableNearestSuperTrackCampaign then
				local classification = C_QuestInfoSystem.GetQuestClassification(info.questID)
				if classification == Enum.QuestClassification.Campaign then
					local distance = C_QuestLog.GetDistanceSqToQuest(info.questID)

					-- Update closest campaign quest if this one is closer
					if distance and distance < closestDistance then
						closestDistance = distance
						closestQuestID = info.questID
					end
				end
			end
		end
	end

	-- Handle the case where closestQuestID is nil
	if not closestQuestID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No tracked quests found.")
		end
		return nil  -- Return nil if no tracked quest is found
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("The closest quest to your current location is " .. tostring(closestQuestID))
	end

	return closestQuestID
end


-- Function that tracks the closest quest on certain events in the Event Manager
function RQE.TrackClosestQuest()
	-- Ensure supertracking is enabled in the profile
	if RQE.db.profile.enableNearestSuperTrack then
		-- Get the closest tracked quest ID
		local closestQuestID = RQE:GetClosestTrackedQuest()

		if RQE.db.profile.debugLevel == "INFO+" then
			print("Within TrackClosestQuest: The closest quest to your current location is " .. tostring(closestQuestID))
		end

		-- If a closest quest was found, set it as the supertracked quest
		if closestQuestID then
			C_SuperTrack.SetSuperTrackedQuestID(closestQuestID)
			RQE:SaveSuperTrackedQuestToCharacter()

			if RQE.db.profile.debugLevel == "INFO+" then
				print("TrackClosestQuest Debug: Super-tracked quest set to closest quest ID: " .. tostring(closestQuestID))
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("TrackClosestQuest: No closest quest found to super-track.")
			end
		end

		-- Optionally trigger an update to the frame
		C_Timer.After(1.5, function()
			UpdateFrame()
		end)

		-- Optionally scroll the frames to the top
		if RQEFrame and not RQEFrame:IsMouseOver() then
			RQE.ScrollFrameToTop()
		end
		RQE.FocusScrollFrameToTop()
	else
		print("enableNearestSuperTrack is currently disabled in Config")
	end
end



-- Function for Tracking World Quests
function UpdateWorldQuestTrackingForMap(uiMapID)
	if not uiMapID then
		print("Invalid map ID provided to UpdateWorldQuestTrackingForMap")
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
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Found " .. #taskPOIs .. " taskPOIs for map ID: " .. uiMapID)
		end
		for _, taskPOI in ipairs(taskPOIs) do
			local questID = taskPOI.questId

			-- Only proceed if the quest is a world quest (classification 10)
			if questID and RQE:IsWorldQuest(questID) then
				-- Fetch additional info to check if the quest is in the area
				local isInArea, isOnMap, numObjectives = GetTaskInfo(questID)

				if isInArea then  -- Only track if the quest is in the area
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Checking World QuestID: " .. questID .. " (in area)")
					end

					-- Check if the quest is already tracked
					if not trackedQuests[questID] then
						C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
						trackedQuests[questID] = true  -- Mark as tracked
						currentTrackedCount = currentTrackedCount + 1  -- Increment the count

						if RQE.db.profile.debugLevel == "INFO+" then
							print("Automatic World QuestID: " .. questID .. " added to watch list.")
						end

						-- Check if we've reached the maximum number of tracked quests
						if currentTrackedCount >= maxTracked then
							if RQE.db.profile.debugLevel == "INFO+" then
								print("Reached the maximum number of tracked World Quests: " .. maxTracked)
							end
							break  -- Exit the loop as we've reached the limit
						end
					else
						if RQE.db.profile.debugLevel == "INFO+" then
							print("World QuestID: " .. questID .. " is already being tracked.")
						end
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("World QuestID: " .. questID .. " (not in area)")
						C_QuestLog.RemoveWorldQuestWatch(questID)
					end
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Skipping non-World QuestID: " .. questID)
				end
			end
		end
	end
end


-- Function to remove world quests from tracking if the player leaves the area
function RQE:RemoveWorldQuestsIfOutOfArea()
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	-- Fetch quests in the player's current map area
	local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)
	local questsInAreaLookup = {}
	
	-- Store all the quest IDs currently in the player's area
	for _, taskPOI in ipairs(questsInArea or {}) do
		questsInAreaLookup[taskPOI.questId] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest in area: " .. taskPOI.questId)
		end
	end

	-- Check currently tracked world quests
	for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		if questID then
			local watchType = C_QuestLog.GetQuestWatchType(questID)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Checking World QuestID: " .. questID)
			end

			-- If the quest is automatically tracked and not in the player's current area, remove it
			if watchType == Enum.QuestWatchType.Automatic and not questsInAreaLookup[questID] then
				C_QuestLog.RemoveWorldQuestWatch(questID)
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Removed World Quest: " .. questID .. " from tracking because it's out of the current area.")
				end
			end
		end
	end
end


-- Function to remove world quests from tracking if the player leaves the subzone
function RQE:RemoveWorldQuestsIfOutOfSubzone()
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	-- Get the player's current position on the map (subzone level)
	local playerPosition = C_Map.GetPlayerMapPosition(playerMapID, "player")

	if not playerPosition then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player position on the map.")
		end
		return
	end

	local playerX, playerY = playerPosition:GetXY()

	-- Fetch quests in the player's current map area
	local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)
	local questsInAreaLookup = {}

	-- Check currently tracked world quests
	for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		if questID then
			local watchType = C_QuestLog.GetQuestWatchType(questID)
			local isAutomatic = watchType == Enum.QuestWatchType.Automatic
			local isInArea, isOnMap, numObjectives = GetTaskInfo(questID)

			-- Store all the quest IDs currently in the player's area (map and subzone)
			--if watchType == Enum.QuestWatchType.Automatic then
			if isAutomatic then
				if not isInArea then
					C_QuestLog.RemoveWorldQuestWatch(questID)
				end
			end

			if RQE.db.profile.debugLevel == "INFO+" then
				print("Checking World QuestID: " .. questID .. " (WatchType: " .. (isAutomatic and "Automatic" or "Manual") .. ")")
			end

			-- Check if the quest is automatically tracked and is not in the player's current subzone
			if isAutomatic then
				if not questsInAreaLookup[questID] then
					-- Get quest's coordinates
					local questPosition = C_QuestLog.GetQuestObjectives(questID)

					-- Check if player is within the subzone radius of the quest
					local questInSubzone = false

					if questPosition then
						for _, objective in pairs(questPosition) do
							if objective.x and objective.y then
								local distanceSq = (playerX - objective.x) ^ 2 + (playerY - objective.y) ^ 2
								-- Check if within a threshold (adjust the threshold value if needed)
								if distanceSq < 0.0025 then  -- Threshold for being "in the same subzone"
									questInSubzone = true
									break
								end
							end
						end
					end

					if not questInSubzone then
						-- Remove quest from tracking if not in the same subzone
						C_QuestLog.RemoveWorldQuestWatch(questID)
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Removed World Quest: " .. questID .. " from tracking because it's out of the current subzone.")
						end
					else
						if RQE.db.profile.debugLevel == "INFO+" then
							print("World QuestID: " .. questID .. " is still in the current subzone.")
						end
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("World QuestID: " .. questID .. " is still in the current area.")
					end
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("World QuestID: " .. questID .. " is manually tracked, skipping removal.")
				end
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("No world quest found at watch index: " .. i)
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


-- Function that removes a quest from being super tracked but not actually removing the watch
function RQE:RemoveSuperTrackingFromQuest()
	-- Step 1: Get the currently super-tracked quest ID
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Debugging: Print the currently super-tracked quest ID
	RQE.infoLog("Currently Super Tracked Quest ID:", superTrackedQuestID or "None")

	-- Step 2: Remove the super-tracking by setting it to 0
	if superTrackedQuestID and superTrackedQuestID ~= 0 then
		C_SuperTrack.SetSuperTrackedQuestID(0)
		RQE:SaveSuperTrackedQuestToCharacter()
		RQE.infoLog("Removed super-tracking from quest ID:", superTrackedQuestID)
	else
		RQE.infoLog("No quest is currently super-tracked.")
	end

	-- Step 3: Update the RQEQuestFrame to reflect the change
	UpdateRQEQuestFrame()
	UpdateRQEWorldQuestFrame()
	RQE.infoLog("RQEQuestFrame updated to reflect super-tracking changes.")
end


-- Function that checks to see if a player is currently tracking a quest
function RQE.isPlayerSuperTrackingQuest()
	if RQE.currentSuperTrackedQuestID == RQE.previousSuperTrackedQuestID then return end

	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Extracted questID is: " .. tostring(extractedQuestID))
		end
		RQE.isSuperTracking = true
		RQE.CurrentlySuperQuestID = C_SuperTrack.GetSuperTrackedQuestID() or extractedQuestID	-- Added failsafe in case questID isn't yet registered in the RQEFrame, but something is being super tracked and should be considered
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE.isSuperTracking is " .. tostring(RQE.isSuperTracking) .. ". Currently SuperTracked questID: " .. tostring(RQE.CurrentlySuperQuestID) .. " saved to RQE.CurrentlySuperQuestID addon variable")
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE.isSuperTracking is " .. tostring(RQE.isSuperTracking) .. ". There are no quests being supertracked/displayed in the RQEFrame")
		end
		RQE.isSuperTracking = false
	end
end


---------------------------------------------------
-- 10. Scenario Functions
---------------------------------------------------

-- Function to fetch/print Scenario Criteria Step by Step updated for Patch 11.0
function RQE.PrintAllScenarioBits()
	-- Check if the player is currently in a scenario
	if not C_Scenario.IsInScenario() then
		print("Not currently in a scenario.")
		return
	end

	-- Fetch general scenario information
	local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
	if scenarioInfo then
		print("Scenario Name: " .. scenarioInfo.name)
		print("Current Stage: " .. scenarioInfo.currentStage .. " of " .. scenarioInfo.numStages)
		print("Scenario Type: " .. scenarioInfo.type)
		print("Scenario Flags: " .. scenarioInfo.flags)
	else
		print("No active scenario information available.")
		return
	end

	-- Iterate through each step in the current scenario
	local stepID = scenarioInfo.currentStage
	local numCriteria = select(3, C_Scenario.GetStepInfo())
	--local numCriteria = C_Scenario.GetNumCriteria() or 0

	for criteriaIndex = 1, numCriteria do
		-- Fetch criteria information using GetCriteriaInfo
		local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		if criteriaInfo then
			print("Criteria " .. criteriaIndex .. ":")
			print("  Description: " .. (criteriaInfo.description or ""))
			print("  Type: " .. tostring(criteriaInfo.criteriaType))
			print("  Completed: " .. tostring(criteriaInfo.completed))
			print("  Quantity: " .. tostring(criteriaInfo.quantity) .. " / " .. tostring(criteriaInfo.totalQuantity))
			print("  Flags: " .. tostring(criteriaInfo.flags))
			print("  Asset ID: " .. tostring(criteriaInfo.assetID))
			print("  Criteria ID: " .. tostring(criteriaInfo.criteriaID))
			print("  Duration: " .. tostring(criteriaInfo.duration))
			print("  Elapsed: " .. tostring(criteriaInfo.elapsed))
			print("  Failed: " .. tostring(criteriaInfo.failed))
			print("  Is Weighted Progress: " .. tostring(criteriaInfo.isWeightedProgress))
			print("  Is Formatted: " .. tostring(criteriaInfo.isFormatted))
			print("  Quality String: " .. tostring(criteriaInfo.quantityString))
		end

		-- Fetch criteria information using GetCriteriaInfoByStep
		local criteriaInfoByStep = C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
		if criteriaInfoByStep then
			print("Criteria By Step " .. criteriaIndex .. ":")
			print("  Description: " .. (criteriaInfoByStep.description or ""))
			print("  Type: " .. tostring(criteriaInfoByStep.criteriaType))
			print("  Completed: " .. tostring(criteriaInfoByStep.completed))
			print("  Quantity: " .. tostring(criteriaInfoByStep.quantity) .. " / " .. tostring(criteriaInfoByStep.totalQuantity))
			print("  Flags: " .. tostring(criteriaInfoByStep.flags))
			print("  Asset ID: " .. tostring(criteriaInfoByStep.assetID))
			print("  Criteria ID: " .. tostring(criteriaInfoByStep.criteriaID))
			print("  Duration: " .. tostring(criteriaInfoByStep.duration))
			print("  Elapsed: " .. tostring(criteriaInfoByStep.elapsed))
			print("  Failed: " .. tostring(criteriaInfoByStep.failed))
			print("  Is Weighted Progress: " .. tostring(criteriaInfoByStep.isWeightedProgress))
			print("  Is Formatted: " .. tostring(criteriaInfoByStep.isFormatted))
			print("  Quality String: " .. tostring(criteriaInfo.quantityString))
		end
	end
end


-- Updates the timer display
--- @param self TimerFrame The timer frame
--- @param elapsed number The time elapsed since the last update
function RQE.Timer_OnUpdate(self, elapsed)
	if not self then
		return  -- Exit the function if self is nil
	end

	-- Initialize timeSinceLastUpdate if it's nil
	if not self.timeSinceLastUpdate then
		self.timeSinceLastUpdate = 0
	end

	self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed

	if self.timeSinceLastUpdate >= 1 then
		local timeLeft = self.endTime - GetTime()  -- Calculate the remaining time
		if timeLeft > 0 then
			-- Scenario Timer display
			RQE.ScenarioChildFrame.timer:SetText(SecondsToTime(timeLeft))
		else
			RQE.Timer_Stop()  -- Stop the timer if the time has elapsed
		end
		self.timeSinceLastUpdate = 0
	end
end


-- Start the timer and shows the UI elements
--- @class TimerFrame : Frame
--- @field timeSinceLastUpdate number
--- @field endTime number
--- @param timerFrame TimerFrame
function RQE.Timer_Start(timerFrame, duration)
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
	local timerFrame = RQE.ScenarioChildFrame.timerFrame
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
	local duration, elapsed = select(10, C_ScenarioInfo.GetCriteriaInfo(1))
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
	local yPos = -285  -- Preset yPos

	-- Update the database
	RQE.db.profile.framePosition.anchorPoint = anchorPoint
	RQE.db.profile.framePosition.xPos = xPos
	RQE.db.profile.framePosition.yPos = yPos

	-- Update the frame position
	RQE:UpdateFramePosition()
end


-- Function for Button in Configuration that will reset the size of the RQEFrame and RQEQuestFrame to default values
function RQE:ResetFrameSizeToDBorDefault()
	local RQEWidth = 420
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
	if RQE.RQEQuestFrame then
		RQE.RQEQuestFrame:SetSize(RQEQuestWidth, RQEQuestHeight)
	end
end


-- When the frame is maximized
function RQE:MaximizeFrame()
	local defaultWidth = RQE.db.profile.frameWidth or 420  -- Replace 400 with the default from Core.lua
	local defaultHeight = RQE.db.profile.frameHeight or 300  -- Replace 300 with the default from Core.lua

	local width = RQE.db.profile.framePosition.originalWidth or defaultWidth
	local height = RQE.db.profile.framePosition.originalHeight or defaultHeight

	RQEFrame:SetSize(width, height)
	RQE.db.profile.isFrameMaximized = true
end


-- When the frame is minimized
function RQE:MinimizeFrame()
	RQEFrame:SetSize(420, 30)
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
	local defaultWidth = RQE.db.profile.QuestFrameWidth or 325  -- Replace 300 with the default width
	local defaultHeight = RQE.db.profile.QuestFrameHeight or 450  -- Replace 450 with the default height

	local width = RQE.db.profile.QuestFramePosition.originalWidth or defaultWidth
	local height = RQE.db.profile.QuestFramePosition.originalHeight or defaultHeight

	RQE.RQEQuestFrame:SetSize(width, height)
	RQE.db.profile.isQuestFrameMaximized = true
end


-- When the frame is minimized
function RQE:MinimizeQuestFrame()
	RQE.RQEQuestFrame:SetSize(325, 30)
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


-- Initialize SearchEditBox (Make it global to access it from other files)
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
			-- Logic for updating location data
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
			local watchType = C_QuestLog.GetQuestWatchType(foundQuestID)

			-- Found a quest, now set it as the searchedQuestID
			RQE.searchedQuestID = foundQuestID

			-- Super Track the Searched Quest if in the Quest Log
			if isQuestInLog then
				C_SuperTrack.SetSuperTrackedQuestID(foundQuestID)
				RQE:SaveSuperTrackedQuestToCharacter()
			end

			-- Add the quest to the tracker
			if isWorldQuest then
				C_QuestLog.AddWorldQuestWatch(foundQuestID)
			else
				C_QuestLog.AddQuestWatch(foundQuestID)
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


-- Utility function to check if a quest is super-tracked
function RQE.IsQuestSuperTracked()
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	return superTrackedQuestID ~= nil
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
		RQE.RQEQuestFrame:Show()
	else
		-- Code to hide the Quest Frame
		RQE.RQEQuestFrame:Hide()
	end
end


---Abandons a quest with the given questID. Optionally shows a confirmation dialog if items will be lost.
---@param questID number The ID of the quest to abandon.
function RQE:AbandonQuest(questID)
	if not questID then return end  -- Ensure questID is valid

	local oldSelectedQuest = C_QuestLog.GetSelectedQuest()
	C_QuestLog.SetSelectedQuest(questID)
	local questLink = GetQuestLink(oldSelectedQuest)  -- Generate the quest link

	if questLink then
		if RQE.db.profile.debugLevel == "INFO"  or RQE.db.profile.debugLevel == "INFO+" then
			print("Abandoning QuestID:", questID .. " - " .. questLink)
		end
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


-- Utility function to convert a table to a string
function RQE:TableToString(tbl)
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end

	local result = "{"
	for k, v in pairs(tbl) do
		result = result .. tostring(k) .. "=" .. RQE:TableToString(v) .. ", "
	end
	return result .. "}"
end


-- Utility function to convert a table of elements
function countTableElements(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end


---------------------------------------------------
-- 16. Quest Info Functions
---------------------------------------------------
-- [Functions related to quest information handling and processing.]

-- Table to store the last known progress of quests
local lastKnownProgress = {}
local isFirstRun = true


-- Enhanced function to check the correct classification of the quest
local function GetCorrectQuestType(questID)
	local classification = C_QuestInfoSystem.GetQuestClassification(questID)
	
	-- World quests should have classification 10
	if classification == Enum.QuestClassification.WorldQuest then
		return "WorldQuest"
	elseif classification == Enum.QuestClassification.BonusObjective then
		return "BonusObjective"
	else
		return "Other"
	end
end


function AutoWatchQuestsWithProgress()
	if isFirstRun then
		-- On first run, just populate lastKnownProgress without tracking
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local questInfo = C_QuestLog.GetInfo(i)
			if questInfo and not questInfo.isHeader then
				local questID = questInfo.questID
				local objectives = C_QuestLog.GetQuestObjectives(questID)
				local currentProgress = CalculateCurrentProgress(objectives)
				lastKnownProgress[questID] = currentProgress
			end
		end
		isFirstRun = false
	else
		-- On subsequent runs, track quests with new progress
		TrackQuestsWithNewProgress()
	end
end


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
				local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
				if isWorldQuest then
					C_QuestLog.AddWorldQuestWatch(questID)
				else
					C_QuestLog.AddQuestWatch(questID)
				end
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
	if not questID or type(questID) ~= "number" then
		-- Handle the case where questID is invalid
		RQE.debugLog("Invalid or missing questID provided.")
		return nil, nil, nil
	end

	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
	local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
	local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}

	for i, step in ipairs(questInfo) do
		StepsText[i] = step.description
		CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
		MapIDs[i] = step.coordinates.mapID
		questHeader[i] = step.description:match("^(.-)\n") or step.description

		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- -- Debug messages
			-- DEFAULT_CHAT_FRAME:AddMessage("Step " .. i .. ": " .. StepsText[i], 0, 1, 0) -- Green color
			-- DEFAULT_CHAT_FRAME:AddMessage("Coordinates " .. i .. ": " .. CoordsText[i], 0, 1, 0) -- Green color
			-- DEFAULT_CHAT_FRAME:AddMessage("MapID " .. i .. ": " .. tostring(MapIDs[i]), 0, 1, 0) -- Green color
			-- DEFAULT_CHAT_FRAME:AddMessage("Header " .. i .. ": " .. questHeader[i], 0, 1, 0) -- Green color
		-- end
	end

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- DEFAULT_CHAT_FRAME:AddMessage("Quest Steps Printed for QuestID: " .. tostring(questID), 0, 1, 0) -- Green color
	-- end
	return StepsText, CoordsText, MapIDs, questHeader
end


function RQE:QuestComplete(questID)
	local questData = RQE.getQuestData(questID)
	if questData then
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
		editBox:SetText(RQE.wowHeadeditBox:GetText())
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


-- Function to check if a quest is a World Quest by its classification
function RQE:IsWorldQuest(questID)
	local classification = C_QuestInfoSystem.GetQuestClassification(questID)
	return classification == 10  -- 10 corresponds to World Quest
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


-- Function to determine the current step based on quest objectives
function RQE:DetermineCurrentStepIndex(questID)
	local questData = RQE.getQuestData(questID)
	if not questData then
		RQE.infoLog("No quest data available for quest ID:", questID)
		return 1  -- Default to the first step if no data is available
	end

	for index, step in ipairs(questData) do
		if not C_QuestLog.ReadyForTurnIn(questID) then
			if not C_QuestLog.IsQuestObjectiveComplete(questID, step.objectiveIndex) then
				return index  -- Return the index of the first incomplete objective
			end
		end
	end

	return #questData  -- Return the last step if all objectives are complete or ready for turn-in
end


-- Function to find and set the final step for the super-tracked quest
function RQE:FindAndSetFinalStep()
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if not superTrackedQuestID then
		RQE.debugLog("No super-tracked quest ID found.")
		return
	end

	local questData = self.getQuestData(superTrackedQuestID)

	if not questData then
		return
	end

	for index, stepData in ipairs(questData) do
		if stepData.objectiveIndex == 99 then
			self.FinalStep = index
			RQE.infoLog("Final step for quest ID", superTrackedQuestID, "is step index:", self.FinalStep)
			return
		end
	end

	RQE.infoLog("No final step found for quest ID:", superTrackedQuestID)
	self.FinalStep = nil
end


-- Set initial waypoint button to 1
function RQE.SetInitialWaypointToOne()
	if not RQE.db.profile.autoClickWaypointButton then
		return
	end

	if not RQE.SetInitialFromAccept or not RQE.RQEQuestFrame:IsMouseOver() then
		return
	end

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if isSuperTracking then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		local stepIndex = RQE.AddonSetStepIndex or 1

		-- Tier Four Importance: RQE.SETINITIALWAYPOINTTOONE Function
		RQE.CreateMacroForSetInitialWaypoint = true
		RQEMacro:CreateMacroForCurrentStep()
		C_Timer.After(3, function()
			RQE.CreateMacroForSetInitialWaypoint = false
		end)
		--RQE.SetMacroForFinalStep(questID, stepIndex)
	end

	RQE.SetInitialFromAccept = false

	C_Timer.After(1, function()
		if RQE.LastClickedIdentifier == 1 then
			RQE.WaypointButtons[1]:Click()
		else
			if RQE.WaypointButtons[RQE.LastClickedIdentifier] then
				RQE.WaypointButtons[RQE.LastClickedIdentifier]:Click()
			else
				RQE.infoLog("Waypoint button with identifier " .. tostring(RQE.LastClickedIdentifier) .. " does not exist.")
			end
		end
	end)
end


-- Function to check and set the final step
function RQE.CheckAndSetFinalStep()
	C_Timer.After(1, function()
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

		if not superTrackedQuestID then
			RQE.debugLog("No super tracked quest ID found, skipping check.")
			RQE.shouldCheckFinalStep = false
			return
		end

		local questData = RQE.getQuestData(superTrackedQuestID)
		if not questData then
			RQE.shouldCheckFinalStep = false
			return
		end

		local objectives = C_QuestLog.GetQuestObjectives(superTrackedQuestID)
		if not objectives or #objectives == 0 then
			RQE.debugLog("Quest", tostring(superTrackedQuestID), "has no objectives or failed to retrieve objectives.")
			RQE.shouldCheckFinalStep = false
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
		local highestCompletedObjectiveIndex = allObjectivesCompleted and 99 or RQE.AddonSetStepIndex or 1 --(RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex) or 1

		for _, stepData in ipairs(questData) do
			if stepData.objectiveIndex and (stepData.objectiveIndex ~= 99) then
				local objective = objectives[stepData.objectiveIndex]
				if objective and objective.finished and stepData.objectiveIndex > highestCompletedObjectiveIndex then
					highestCompletedObjectiveIndex = stepData.objectiveIndex
				end
			end
		end

		RQE.infoLog("QuestID:", tostring(superTrackedQuestID), ", All Objectives Completed:", tostring(allObjectivesCompleted),", Highest Completed Objective Index:", tostring(highestCompletedObjectiveIndex))

		local finalStepIndex = nil
		for index, step in ipairs(questData) do
			if step.objectiveIndex == 99 then
				finalStepIndex = index
				break
			end
		end

		if not finalStepIndex then
			RQE.debugLog("No final step (objectiveIndex 99) found for quest ID:", superTrackedQuestID)
			RQE.shouldCheckFinalStep = false
			return
		end

		C_Timer.After(1.5, function()
			if highestCompletedObjectiveIndex == 99 then
				RQE.infoLog("Highest Completed Objective is: " .. highestCompletedObjectiveIndex)
				RQE.infoLog("Final Index is: " .. finalStepIndex)
				-- Tier Four Importance: RQE.CHECKANDSETFINALSTEP Function
				RQE.CreateMacroForCheckAndSetFinalStep = true
				RQEMacro:CreateMacroForCurrentStep()
				C_Timer.After(3, function()
					RQE.CreateMacroForCheckAndSetFinalStep = false
				end)
				-- RQE.SetMacroForFinalStep(superTrackedQuestID, finalStepIndex)
			else
				RQE.infoLog("Highest Completed Objective is: " .. highestCompletedObjectiveIndex)
				RQE.infoLog("Final Index is: " .. finalStepIndex)
			end
		end)
	end)

	RQE.shouldCheckFinalStep = false
end


-- Function that creates a macro based on the current stepIndex of the current super tracked quest
function RQE.SetMacroForFinalStep(questID, finalStepIndex)
	local questData = RQE.getQuestData(questID)
	if not questData then
		return
	end

	local stepData = questData[finalStepIndex]
	if stepData and stepData.macro then
		local macroCommands = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro
		RQE.infoLog("Setting macro commands for final step:", macroCommands)
		RQEMacro:SetQuestStepMacro(questID, finalStepIndex, macroCommands, false)
	else
		RQE.debugLog("No macro data found for the final step.")
	end
end


-- -- Function that creates a macro based on the current stepIndex of the current super tracked quest
-- function RQEMacro:CreateMacroForCurrentStep()
	-- -- If a macro creation is already in progress, return immediately
	-- if isMacroCreationInProgress then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CreateMacroForCurrentStep() - Macro creation already in progress, skipping...")
		-- end
		-- return
	-- end

	-- -- Set the flag to indicate macro creation is in progress
	-- isMacroCreationInProgress = true

	-- -- Priority Flag Check: Determine which flag is allowed to run the function
	-- if RQE.CreateMacroForPeriodicChecks then
		-- -- Tier 1 priority, always allowed to run immediately
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CreateMacroForCurrentStep() - Tier 1 flag set: RQE.CreateMacroForPeriodicChecks")
		-- end
		-- -- Proceed with creating the macro
	-- elseif RQE.CreateMacroForUpdateSeparateFocusFrame then
		-- -- Tier 2 priority, run only if no Tier 1 flag is set
		-- if not RQE.CreateMacroForPeriodicChecks then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Tier 2 flag set: RQE.CreateMacroForUpdateSeparateFocusFrame")
			-- end
			-- -- Proceed with creating the macro
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Delaying due to Tier 1 flag")
			-- end
			-- return
		-- end
	-- elseif RQE.CreateMacroForSuperTracking or RQE.CreateMacroForQuestLogIndexButton then
		-- -- Tier 3 priority, run only if no Tier 1 or Tier 2 flags are set
		-- if not (RQE.CreateMacroForPeriodicChecks or RQE.CreateMacroForUpdateSeparateFocusFrame) then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Tier 3 flag set: RQE.CreateMacroForSuperTracking or RQE.CreateMacroForQuestLogIndexButton")
			-- end
			-- -- Proceed with creating the macro
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Delaying due to Tier 1 or Tier 2 flag")
			-- end
			-- return
		-- end
	-- elseif RQE.CreateMacroForSetInitialWaypoint or RQE.CreateMacroForCheckAndSetFinalStep or RQE.CreateMacroForCheckAndBuildMacroIfNeeded then
		-- -- Tier 4 priority, run only if no Tier 1, Tier 2, or Tier 3 flags are set
		-- if not (RQE.CreateMacroForPeriodicChecks or RQE.CreateMacroForUpdateSeparateFocusFrame or 
				-- RQE.CreateMacroForSuperTracking or RQE.CreateMacroForQuestLogIndexButton) then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Tier 4 flag set")
			-- end
			-- -- Proceed with creating the macro
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Delaying due to higher tier flags")
			-- end
			-- return
		-- end
	-- elseif RQE.CreateMacroForUnitQuestLogChange or RQE.CreateMacroForQuestWatchUpdate or RQE.CreateMacroForQuestWatchListChanged then
		-- -- Tier 5 priority, run only if no Tier 1, Tier 2, Tier 3, or Tier 4 flags are set
		-- if not (RQE.CreateMacroForPeriodicChecks or RQE.CreateMacroForUpdateSeparateFocusFrame or
				-- RQE.CreateMacroForSuperTracking or RQE.CreateMacroForQuestLogIndexButton or
				-- RQE.CreateMacroForSetInitialWaypoint or RQE.CreateMacroForCheckAndSetFinalStep or
				-- RQE.CreateMacroForCheckAndBuildMacroIfNeeded) then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Tier 5 flag set")
			-- end
			-- -- Proceed with creating the macro
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CreateMacroForCurrentStep() - Delaying due to higher tier flags")
			-- end
			-- return
		-- end
	-- else
		-- -- No flag set, nothing to do
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CreateMacroForCurrentStep() ceased because no flag detected")
		-- end
		-- return
	-- end

	-- -- Clears the RQEMacro before creating a fresh one
	-- RQEMacro:ClearMacroContentByName("RQE Macro")

	-- -- Actual macro creation logic
	-- local questID = C_SuperTrack.GetSuperTrackedQuestID()
	-- if not questID then
		-- isMacroCreationInProgress = false -- Reset flag
		-- return
	-- end

	-- -- Ensure only one macro creation is processed
	-- local isMacroCorrect = RQE.CheckCurrentMacroContents()
	-- if isMacroCorrect then
		-- isMacroCreationInProgress = false -- Reset flag
		-- return
	-- end

	-- -- Retrieve the quest data from the database
	-- local questData = RQE.getQuestData(questID)
	-- if not questData then
		-- isMacroCreationInProgress = false -- Reset flag
		-- return
	-- end

	-- -- Fetch the current step index that the player is on
	-- local stepIndex = RQE.AddonSetStepIndex
	-- if not stepIndex then
		-- isMacroCreationInProgress = false -- Reset flag
		-- return
	-- end

	-- -- Fetch the macro data for the current step
	-- local stepData = questData[stepIndex]
	-- if not stepData or not stepData.macro then
		-- isMacroCreationInProgress = false -- Reset flag
		-- return
	-- end

	-- -- Combine the macro data into a single string
	-- local macroContent = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro

	-- -- Print the macro content for debugging
	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("Creating or updating 'RQE Macro' with content:", macroContent)
	-- end

	-- -- Set or update the macro using the provided content
	-- RQEMacro:SetMacro("RQE Macro", "INV_MISC_QUESTIONMARK", macroContent, false)
	-- RQE.Buttons.UpdateMagicButtonVisibility()

	-- -- Set a timer to reset the flag after 3 seconds
	-- C_Timer.After(3, function()
		-- isMacroCreationInProgress = false
	-- end)
-- end


-- Function that creates a macro based on the current stepIndex of the current super tracked quest
function RQEMacro:CreateMacroForCurrentStep()
	if not RQE.isCheckingMacroContents then return end

	-- Retrieve the questID that is currently being supertracked
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local isInInstance, instanceType = IsInInstance()
	if not questID then
		return
	end

	-- Adds a check if player is in party or raid instance, if so, will not allow macro check to run further
	if isInInstance and (instanceType == "party" or instanceType == "raid") then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("isInInstance is: " .. tostring(isInInstance) .. ". instanceType is: " .. instanceType)
		end
		RQE.isCheckingMacroContents = false
		return
	end

	local isMacroCorrect = RQE.CheckCurrentMacroContents()

	if isMacroCorrect then
		return
	end

	RQE.isCheckingMacroContents = false

	-- Clears the RQEMacro before creating a fresh one
	RQEMacro:ClearMacroContentByName("RQE Macro")

	-- Retrieve the quest data from the database
	local questData = RQE.getQuestData(questID)
	if not questData then
		return
	end

	-- Fetch the current step index that the player is on
	local stepIndex = RQE.AddonSetStepIndex
	if not stepIndex then
		return
	end

	-- Fetch the macro data for the current step
	local stepData = questData[stepIndex]
	if not stepData or not stepData.macro then
		return
	end

	-- Combine the macro data into a single string
	local macroContent = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro

	-- Print the macro content for debugging
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Creating or updating 'RQE Macro' with content:", macroContent)
	end

	-- Set or update the macro using the provided content
	RQEMacro:SetMacro("RQE Macro", "INV_MISC_QUESTIONMARK", macroContent, false)
	RQE.Buttons.UpdateMagicButtonVisibility()
end


-- -- Periodic check setup (updated to include CheckDBObjectiveStatus)
-- function RQE:StartPeriodicChecks()
	-- -- Priority Flag Check: Determine which flag is allowed to run the function
	-- if RQE.StartPerioFromQuestWatchUpdate then
		-- -- Tier 1 priority, always allowed to run immediately
		-- RQE.StartPerioFromQuestWatchUpdate = false
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("RQE:StartPeriodicChecks() ceased because " .. tostring(RQE.StartPerioFromQuestWatchUpdate))
		-- end
	-- elseif RQE.StartPerioFromSuperTrackChange then
		-- -- Tier 2 priority, run only if no Tier 1 flag is set
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("Status of SUPER_TRACKING_CHANGED RQE.StartPerioFromSuperTrackChange is " .. tostring(RQE.StartPerioFromSuperTrackChange))
		-- end
		-- if not (RQE.StartPerioFromQuestWatchUpdate) then
			-- RQE.StartPerioFromSuperTrackChange = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() ceased because " .. tostring(RQE.StartPerioFromSuperTrackChange))
			-- end
		-- else
			-- return
		-- end
	-- elseif RQE.StartPerioFromPlayerEnteringWorld or RQE.StartPerioFromInstanceInfoUpdate or RQE.StartPerioFromPlayerControlGained then
		-- -- Tier 3 priority, run only if no Tier 1 or Tier 2 flags are set
		-- if not (RQE.StartPerioFromQuestWatchUpdate or RQE.StartPerioFromSuperTrackChange) then
			-- RQE.StartPerioFromPlayerEnteringWorld = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of PLAYER_ENTERING_WORLD RQE.StartPerioFromPlayerEnteringWorld is " .. tostring(RQE.StartPerioFromPlayerEnteringWorld))
			-- end
			-- RQE.StartPerioFromInstanceInfoUpdate = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of UPDATE_INSTANCE_INFO RQE.StartPerioFromInstanceInfoUpdate is " .. tostring(RQE.StartPerioFromInstanceInfoUpdate))
			-- end
			-- RQE.StartPerioFromPlayerControlGained = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of PLAYER_CONTROL_GAINED RQE.StartPerioFromPlayerControlGained is " .. tostring(RQE.StartPerioFromPlayerControlGained))
			-- end
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() ceased because either RQE.StartPerioFromQuestWatchUpdate is " .. tostring(RQE.StartPerioFromQuestWatchUpdate) .. " or RQE.StartPerioFromSuperTrackChange is " .. tostring(RQE.StartPerioFromSuperTrackChange))
			-- end
			-- return
		-- end
	-- elseif RQE.StartPerioFromQuestAccepted or RQE.StartPerioFromQuestComplete or RQE.StartPerioFromQuestTurnedIn or RQE.StartPerioFromItemCountChanged then
		-- -- Tier 4 priority, run only if no Tier 1, Tier 2, or Tier 3 flags are set
		-- if not (RQE.StartPerioFromQuestWatchUpdate or RQE.StartPerioFromSuperTrackChange or
				-- RQE.StartPerioFromPlayerEnteringWorld or RQE.StartPerioFromInstanceInfoUpdate or
				-- RQE.StartPerioFromPlayerControlGained) then
			-- RQE.StartPerioFromQuestAccepted = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of QUEST_ACCEPTED RQE.StartPerioFromQuestAccepted is " .. tostring(RQE.StartPerioFromQuestAccepted))
			-- end
			-- RQE.StartPerioFromQuestComplete = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of QUEST_COMPLETE RQE.StartPerioFromQuestComplete is " .. tostring(RQE.StartPerioFromQuestComplete))
			-- end
			-- RQE.StartPerioFromQuestTurnedIn = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of QUEST_TURNED_IN RQE.StartPerioFromQuestTurnedIn is " .. tostring(RQE.StartPerioFromQuestTurnedIn))
			-- end
			-- RQE.StartPerioFromItemCountChanged = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of ITEM_COUNT_CHANGED RQE.StartPerioFromItemCountChanged is " .. tostring(RQE.StartPerioFromItemCountChanged))
			-- end
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() ceased because one of the Tier 4 flags was true: RQE.StartPerioFromQuestAccepted is " .. tostring(RQE.StartPerioFromQuestAccepted) .. ", RQE.StartPerioFromQuestComplete is " .. tostring(RQE.StartPerioFromQuestComplete) .. ", RQE.StartPerioFromQuestTurnedIn is " .. tostring(RQE.StartPerioFromQuestTurnedIn) .. ", or RQE.StartPerioFromItemCountChanged is " .. tostring(RQE.StartPerioFromItemCountChanged))
			-- end
			-- return
		-- end
	-- elseif RQE.StartPerioFromUnitQuestLogChanged then
		-- -- Tier 5 priority, run only if no Tier 1, Tier 2, Tier 3, or Tier 4 flags are set
		-- if not (RQE.StartPerioFromQuestWatchUpdate or RQE.StartPerioFromSuperTrackChange or
				-- RQE.StartPerioFromPlayerEnteringWorld or RQE.StartPerioFromInstanceInfoUpdate or
				-- RQE.StartPerioFromPlayerControlGained or RQE.StartPerioFromQuestAccepted or
				-- RQE.StartPerioFromQuestComplete or RQE.StartPerioFromQuestTurnedIn or
				-- RQE.StartPerioFromItemCountChanged) then
			-- RQE.StartPerioFromUnitQuestLogChanged = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Status of UNIT_QUEST_LOG_CHANGED RQE.StartPerioFromUnitQuestLogChanged is " .. tostring(RQE.StartPerioFromUnitQuestLogChanged))
			-- end
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() ceased because one of the Tier 5 flags was true: RQE.StartPerioFromUnitQuestLogChanged is " .. tostring(RQE.StartPerioFromUnitQuestLogChanged))
			-- end
			-- return
		-- end
	-- else
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("RQE:StartPeriodicChecks() ceased because no flag detected")
		-- end
		-- return
	-- end

	-- -- Early return if no quest is super-tracked
	-- if not RQE.IsQuestSuperTracked() then
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("RQE:StartPeriodicChecks() ceased because nothing being Super Tracked")
		-- end
		-- return
	-- end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
		-- print("~~ Entering RQE:StartPeriodicChecks() ~~")
	-- end

	-- local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- if not superTrackedQuestID then
		-- RQE.debugLog("No super tracked quest ID found, skipping checks.")
		-- return
	-- end

	-- self:FindAndSetFinalStep()  -- Find and set the final step

	-- local questData = RQE.getQuestData(superTrackedQuestID)
	-- local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(superTrackedQuestID)

	-- if questData then
		-- local stepIndex = RQE.AddonSetStepIndex --self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex or 1
		-- local stepData = questData[stepIndex]

		-- -- Handle turn-in readiness
		-- if isReadyTurnIn and self.FinalStep then
			-- RQE.debugLog("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			-- end
			-- self:ClickWaypointButtonForIndex(self.FinalStep)
			-- return
		-- end

		-- -- Additional check if the highest completed objective is 99
		-- if self.shouldCheckFinalStep then
			-- local finalStepIndex = #questData  -- Assuming the last step is the final one
			-- for index, step in ipairs(questData) do
				-- if step.objectiveIndex == 99 then
					-- finalStepIndex = index
					-- break
				-- end
			-- end

			-- -- Calculate highestCompletedObjectiveIndex based on objectives completion
			-- --highestCompletedObjectiveIndex = allObjectivesCompleted and 99 or (RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex) or 1
			-- local highestCompletedObjectiveIndex = RQE:AreAllObjectivesCompleted(superTrackedQuestID) or RQE.AddonSetStepIndex or 1

			-- -- If the highest completed objective is 99, click the waypoint button for the final step
			-- if highestCompletedObjectiveIndex == 99 and finalStepIndex then
				-- RQE.infoLog("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
					-- print("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				-- end
				-- self:ClickWaypointButtonForIndex(finalStepIndex)
				-- return
			-- end
		-- end

		-- -- Validate stepIndex
		-- if stepIndex < 1 or stepIndex > #questData then
			-- RQE.infoLog("Invalid step index:", stepIndex)
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Invalid step index:", stepIndex)
			-- end
			-- return
		-- end

		-- -- Check if the current step requires objective progress check
		-- if stepData.funct and string.find(stepData.funct, "CheckDBObjectiveStatus") then
			-- local objProgressResult = RQE:CheckObjectiveProgress(superTrackedQuestID, stepIndex)
			-- if objProgressResult then
				-- RQE.debugLog("Objective progress check completed and step advanced.")
				-- return
			-- else
				-- RQE.debugLog("Objective progress check did not result in advancement.")
			-- end
		-- end

		-- -- Process the current step
		-- local funcResult = stepData.funct and RQE[stepData.funct] and RQE[stepData.funct](self, superTrackedQuestID, stepIndex)
		-- if funcResult then
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("Function for current step executed successfully.")
			-- end
		-- else
			-- local failFuncResult = stepData.failedfunc and RQE[stepData.failedfunc] and RQE[stepData.failedfunc](self, superTrackedQuestID, stepIndex, true)
			-- if failFuncResult then
				-- local failedIndex = stepData.failedIndex or 1
				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
					-- print("Failure condition met, resetting to step:", failedIndex)
				-- end
				-- self:ClickWaypointButtonForIndex(failedIndex)
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
					-- RQE.infoLog("No conditions met for current step", stepIndex, "of quest ID", superTrackedQuestID)
				-- end
			-- end
		-- end

		-- -- Check and build macro if needed
		-- RQE.CreateMacroForPeriodicChecks = true
		-- RQEMacro:CreateMacroForCurrentStep()

		-- -- Reset the flag after creating the macro
		-- RQE.CreateMacroForPeriodicChecks = false

		-- -- Reset the in-progress flag after 3 seconds
		-- C_Timer.After(3, function()
			-- RQE.isPeriodicCheckInProgress = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() is ready for the next call.")
			-- end
		-- end)
	-- else
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("RQE:StartPeriodicChecks() ceased because no flag detected")
		-- end
		-- return
	-- end
-- end


-- -- Periodic check setup (updated to include CheckDBObjectiveStatus)
-- function RQE:StartPeriodicChecks()
	-- -- Early return if no quest is super-tracked
	-- if not RQE.IsQuestSuperTracked() then
		-- return
	-- end

	-- local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- if not superTrackedQuestID then
		-- RQE.debugLog("No super tracked quest ID found, skipping checks.")
		-- return
	-- end

	-- self:FindAndSetFinalStep()  -- Find and set the final step

	-- local questData = RQE.getQuestData(superTrackedQuestID)
	-- local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(superTrackedQuestID)

	-- if questData then
		-- local stepIndex = self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex or 1
		-- local stepData = questData[stepIndex]

		-- -- Handle turn-in readiness
		-- if isReadyTurnIn and self.FinalStep then
			-- RQE.debugLog("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			-- -- if RQE.db.profile.debugLevel == "INFO+" then
				-- -- print("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			-- -- end
			-- self:ClickWaypointButtonForIndex(self.FinalStep)
			-- return
		-- end

		-- -- Additional check if the highest completed objective is 99
		-- if self.shouldCheckFinalStep then
			-- local finalStepIndex = #questData  -- Assuming the last step is the final one
			-- for index, step in ipairs(questData) do
				-- if step.objectiveIndex == 99 then
					-- finalStepIndex = index
					-- break
				-- end
			-- end

			-- -- If the highest completed objective is 99, click the waypoint button for the final step
			-- if highestCompletedObjectiveIndex == 99 and finalStepIndex then
				-- RQE.infoLog("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				-- end
				-- self:ClickWaypointButtonForIndex(finalStepIndex)
				-- return
			-- end
		-- end

		-- -- Validate stepIndex
		-- if stepIndex < 1 or stepIndex > #questData then
			-- RQE.infoLog("Invalid step index:", stepIndex)
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Invalid step index:", stepIndex)
			-- end
			-- return  -- Exit if stepIndex is invalid
		-- end

		-- -- Check if the current step requires objective progress check
		-- if stepData.funct and string.find(stepData.funct, "CheckDBObjectiveStatus") then
			-- local objProgressResult = RQE:CheckObjectiveProgress(superTrackedQuestID, stepIndex)
			-- if objProgressResult then
				-- RQE.debugLog("Objective progress check completed and step advanced.")
				-- return
			-- else
				-- RQE.debugLog("Objective progress check did not result in advancement.")
			-- end
		-- end

		-- -- Process the current step
		-- local funcResult = stepData.funct and RQE[stepData.funct] and RQE[stepData.funct](self, superTrackedQuestID, stepIndex)
		-- if funcResult then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Function for current step executed successfully.")
			-- end
		-- else
			-- local failFuncResult = stepData.failedfunc and RQE[stepData.failedfunc] and RQE[stepData.failedfunc](self, superTrackedQuestID, stepIndex, true)
			-- if failFuncResult then
				-- local failedIndex = stepData.failedIndex or 1
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("Failure condition met, resetting to step:", failedIndex)
				-- end
				-- self:ClickWaypointButtonForIndex(failedIndex)
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- RQE.infoLog("No conditions met for current step", stepIndex, "of quest ID", superTrackedQuestID)
				-- end
			-- end
		-- end

		-- -- Check and build macro if needed
		-- --RQE.CheckAndBuildMacroIfNeeded()
		-- RQEMacro:CreateMacroForCurrentStep()
	-- end
-- end


-- Periodic check setup comparing with entry in RQEDatabase
function RQE:StartPeriodicChecks()
	if RQE.db.profile.debugLevel == "INFO+" then
		print("StartPeriodicChecks() called.")
	end

	-- Stops the function if autoClickWaypointButton is unchecked by user
	if not RQE.db.profile.autoClickWaypointButton then
		return
	end

	-- Early return if no quest is super-tracked
	if not RQE.IsQuestSuperTracked() then
		return
	end

	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if not superTrackedQuestID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super tracked quest ID found, skipping checks.")
		end
		return
	end

	RQE.isCheckingMacroContents = true
	self:FindAndSetFinalStep()  -- Find and set the final step

	local questData = RQE.getQuestData(superTrackedQuestID)
	local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(superTrackedQuestID)

	if questData then
		local stepIndex = self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex or 1
		local stepData = questData[stepIndex]

		-- Handle turn-in readiness
		if isReadyTurnIn and self.FinalStep then
			RQE.debugLog("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest is ready for turn-in, clicking Waypoint Button for step index:", self.FinalStep)
			end
			self:ClickWaypointButtonForIndex(self.FinalStep)
			RQE:UpdateSeparateFocusFrame()
			return
		end

		-- Additional check if the highest completed objective is 99
		if self.shouldCheckFinalStep then
			local finalStepIndex = #questData  -- Assuming the last step is the final one
			for index, step in ipairs(questData) do
				if step.objectiveIndex == 99 then
					finalStepIndex = index
					RQE:UpdateSeparateFocusFrame()
					break
				end
			end

			-- If the highest completed objective is 99, click the waypoint button for the final step
			if highestCompletedObjectiveIndex == 99 and finalStepIndex then
				RQE.infoLog("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				if RQE.db.profile.debugLevel == "INFO+" then
					print("All objectives completed. Advancing to final stepIndex:", finalStepIndex)
				end
				self:ClickWaypointButtonForIndex(finalStepIndex)
				RQE:UpdateSeparateFocusFrame()
				return
			end
		end

		-- Validate stepIndex
		if stepIndex < 1 or stepIndex > #questData then
			RQE.infoLog("Invalid step index:", stepIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Invalid step index:", stepIndex)
			end
			return  -- Exit if stepIndex is invalid
		end

		-- Check if the current step requires objective progress check
		if stepData.funct and string.find(stepData.funct, "CheckDBObjectiveStatus") then
			local objProgressResult = RQE:CheckObjectiveProgress(superTrackedQuestID, stepIndex)
			if objProgressResult then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Objective progress check completed and step advanced.")
				end
				RQE.isCheckingMacroContents = false
				return
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Objective progress check did not result in advancement.")
				end
			end

		-- Check if the current step requires scenario stage checks
		elseif stepData.funct and string.find(stepData.funct, "CheckScenarioStage") then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Running CheckScenarioStage for stepIndex:", stepIndex)
			end
			local stageResult = RQE:CheckScenarioStage(superTrackedQuestID, stepIndex)
			if stageResult then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Scenario stage check completed and step advanced.")
				end
				RQE:UpdateSeparateFocusFrame()
				return
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Scenario stage check did not result in advancement.")
				end
			end

		-- Check if the current step requires scenario objective progress
		elseif stepData.funct and string.find(stepData.funct, "CheckScenarioCriteria") then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Running CheckScenarioCriteria for stepIndex:", stepIndex)
			end
			local criteriaResult = RQE:CheckScenarioCriteria(superTrackedQuestID, stepIndex)
			if criteriaResult then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Scenario criteria check completed and step advanced.")
				end
				RQE:UpdateSeparateFocusFrame()
				return
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Scenario criteria check did not result in advancement.")
				end
			end
		end

		-- Process the current step
		local funcResult = stepData.funct and RQE[stepData.funct] and RQE[stepData.funct](self, superTrackedQuestID, stepIndex)
		if funcResult then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Function for current step executed successfully.")
			end
		else
			local failFuncResult = stepData.failedfunc and RQE[stepData.failedfunc] and RQE[stepData.failedfunc](self, superTrackedQuestID, stepIndex, true)
			if failFuncResult then
				local failedIndex = stepData.failedIndex or 1
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Failure condition met, resetting to step:", failedIndex)
				end
				self:ClickWaypointButtonForIndex(failedIndex)
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("No conditions met for current step", stepIndex, "of quest ID", superTrackedQuestID)
				end
			end
		end

		-- Check and build macro if needed
		-- RQE.CreateMacroForPeriodicChecks = true
		RQEMacro:CreateMacroForCurrentStep()

		-- -- Reset the flag after creating the macro
		-- RQE.CreateMacroForPeriodicChecks = false

		-- -- Reset the in-progress flag after 3 seconds
		-- C_Timer.After(3, function()
			-- RQE.isPeriodicCheckInProgress = false
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
				-- print("RQE:StartPeriodicChecks() is ready for the next call.")
			-- end
		-- end)
	-- else
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showStartPeriodicCheckInfo then
			-- print("RQE:StartPeriodicChecks() ceased because no flag detected")
		-- end
		-- return
	end

	RQE:UpdateSeparateFocusFrame()
end


-- Function to check the current quest step and perform actions accordingly
function RQE.CheckThatQuestStep()
	-- Retrieve the questID from the RQEFrame
	local questID = RQE.searchedQuestID or (RQE.QuestIDText and tonumber(RQE.QuestIDText:GetText():match("%d+"))) or C_SuperTrack.GetSuperTrackedQuestID()

	-- Check if a valid questID was found
	if not questID then
		print("No valid questID found in RQEFrame.")
		return
	end

	-- Get quest objectives
	local objectives = C_QuestLog.GetQuestObjectives(questID)
	local questData = RQE.getQuestData(questID)

	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest data not found for questID:", questID)
		end
		return
	end

	if not objectives then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No objectives found for questID:", questID)
		end
		return
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Debug [Core.lua: Line 3156]: " .. tostring(RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or "nil"))
	end

	local currentStepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
	local stepData = questData[currentStepIndex]

	-- Determine the current step the player should be on
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Current stepIndex:", currentStepIndex)
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Debug [Core.lua: Line 3162]: " .. tostring(RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or "nil"))
	end

	-- Print initial debug information
	if RQE.db.profile.debugLevel == "INFO+" then
		if stepData then
			print("neededAmt:", stepData.neededAmt and stepData.neededAmt[1] or "nil", "objectiveIndex:", stepData.objectiveIndex)
		else
			print("Invalid stepData for stepIndex:", currentStepIndex)
			return
		end
	end

	-- Print objective details
	if RQE.db.profile.debugLevel == "INFO+" then
		for i, o in ipairs(objectives) do
			print(i .. ".", o.text, o.numFulfilled .. "/" .. o.numRequired, "Finished:", tostring(o.finished))
		end
	end

	-- Check if the quest is ready for turn-in first
	local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(questID)
	if isReadyTurnIn then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest is ready for turn-in. Clicking final step associated with objectiveIndex 99.")
		end
		RQE:ClickWaypointButtonForIndex(#questData) -- Clicks the last step which should be the turn-in step
		return
	end

	-- Refined step advancement logic with additional debug prints
	local correctStepIndex = 1
	local foundStep = false

	for i, step in ipairs(questData) do
		local objectiveIndex = step.objectiveIndex or 1
		local neededAmt = step.neededAmt and tonumber(step.neededAmt[1]) or 1
		local objective = objectives[objectiveIndex]

		if objective then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Analyzing Step:", i)
				print("Objective Index:", objectiveIndex, "Needed Amount:", neededAmt, "Objective Fulfilled:", objective.numFulfilled, "Objective Finished:", tostring(objective.finished))
			end

			-- If the objective is completed, skip steps with this objectiveIndex
			if objective.finished then
				correctStepIndex = i + 1
				-- Continue to find the next step with the next objectiveIndex
			elseif objective.numFulfilled == neededAmt then
				correctStepIndex = i
				foundStep = true
				break
			elseif objective.numFulfilled < neededAmt then
				correctStepIndex = i
				foundStep = true
				break
			end
		else
			print("Objective data missing or mismatched for questID:", questID, "at step:", i)
			correctStepIndex = i
			break
		end
	end

	-- Ensure correctStepIndex does not exceed the number of steps
	correctStepIndex = math.min(correctStepIndex, #questData)

	-- Print information about the quest and objectives
	if RQE.db.profile.debugLevel == "INFO+" then
		print("QuestID:", tostring(questID), ", All Objectives Completed:", tostring(isReadyTurnIn), ", Highest Completed Objective Index:", tostring(objectives[#objectives].finished and 99 or correctStepIndex))
	end

	-- If the stepIndex does not match the expected, click the correct button
	if correctStepIndex ~= currentStepIndex then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Mismatch detected. Expected stepIndex:", correctStepIndex, "but currently on:", currentStepIndex)
			print("Clicking the correct step button.")
		end
		RQE:ClickWaypointButtonForIndex(correctStepIndex)
	else
		print("Current stepIndex matches expected stepIndex. No action needed.")
	end

	-- Print additional debug information
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Final stepIndex:", correctStepIndex)
		print("RQE.LastClickedIdentifier:", tostring(RQE.LastClickedIdentifier))
		print("RQE.LastClickedButtonRef.stepIndex:", tostring(RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex))
		print("RQE.LastClickedButtonRef:", tostring(RQE.LastClickedButtonRef))
	end

	-- Check and build macro if needed
	RQE.CheckAndBuildMacroIfNeeded()
end


-- Function advances the quest step by simulating a click on the corresponding WaypointButton
function RQE:AdvanceQuestStep(questID, stepIndex)
	RQE.infoLog("Running AdvanceQuestStep for questID:", questID, "at stepIndex:", stepIndex)
	local questData = self.getQuestData(questID)

	if not questData then
		RQE.debugLog("No quest data available for questID:", questID)
		return
	end

	local nextIndex

	-- Check if the ObjectiveFlag is set and adjust nextIndex accordingly
	if self.ObjectiveFlag then
		nextIndex = stepIndex  -- Use the current stepIndex directly
		self.ObjectiveFlag = nil  -- Clear the flag after using it
	else
		nextIndex = stepIndex + 1
	end

	local nextStep = questData[nextIndex]

	if nextStep then
		local buttonIndex = nextIndex
		local button = self.WaypointButtons[buttonIndex]
		if button then
			button:Click()
			self.LastClickedButtonRef = button
			RQE.infoLog("Advanced to next quest step: " .. buttonIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Advanced to next quest step: " .. buttonIndex)
			end

			-- Update the current step index
			self.CurrentStepIndex = buttonIndex
			self.AddonSetStepIndex = buttonIndex  -- Ensures the global step index is updated correctly

			-- Call a function to automatically click the waypoint button for the next step
			self:AutoClickQuestLogIndexWaypointButton()
		else
			RQE.debugLog("No WaypointButton found for index:", buttonIndex)
		end
	else
		RQE.infoLog("No more steps available for quest ID:", questID)
	end
end


-- Function to check if steps are displayed in the RQEFrame for a given questID
function RQE.AreStepsDisplayed(questID)
	local questInfo = RQE.getQuestData(questID)
	if not questInfo then return false end

	for stepIndex, stepData in ipairs(questInfo) do
		if stepData and stepData.description then
			return true
		end
	end

	return false
end


-- Function that handles button clicks based on changes to the stepText
function RQE:ClickWaypointButtonForIndex(index)
	local button = self.WaypointButtons[index]
	if button then
		if button.stepIndex ~= index then
			button.stepIndex = index
		end

		-- Update last clicked reference and step index
		self.LastClickedButtonRef = button
		self.CurrentStepIndex = index
		RQE.AddonSetStepIndex = index

		-- Log the state changes for debugging
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Clicking button at index:", index)
		end

		-- Perform the button click
		button:Click()

		-- Schedule a check to click the button associated with AddonSetStepIndex
		C_Timer.After(0.2, function()
			local addonButton = RQE.WaypointButtons[RQE.AddonSetStepIndex]
			if addonButton then
				-- Ensure the button is clickable and perform the click
				RQE:OnCoordinateClicked()
				-- RQE:OnCoordinateClicked(stepIndex)	-- NEEDS to be stepIndex and NOT index to work properly!
				RQE.InitializeSeparateFocusFrame()	-- Refreshes the Focus Step Frame
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Clicked waypoint button for AddonSetStepIndex:", RQE.AddonSetStepIndex)
				end
			else
				RQE.debugLog("No waypoint button found for AddonSetStepIndex:", RQE.AddonSetStepIndex)
			end
		end)
	else
		RQE.debugLog("No waypoint button found for index:", index)
	end

	-- Check to ensure that the macro is properly set
	C_Timer.After(0.6, function()
		RQE.isCheckingMacroContents = true
		RQEMacro:CreateMacroForCurrentStep()
		C_Timer.After(0.4, function()
			RQE.isCheckingMacroContents = false
		end)
	end)
end


-- Function will check if the player currently has any of the buffs specified in the quest's check field passed by the RQEDatabase.
function RQE:CheckDBBuff(questID, stepIndex, isFailureCheck)
	local questData = self.getQuestData(questID)

	if not questData then
		return
	end

	local stepData = questData[stepIndex]
	local checkData = isFailureCheck and stepData.failedcheck or stepData.check

	-- Ensure checkData is a table before proceeding
	if not checkData or type(checkData) ~= "table" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - Invalid or missing check data for quest ID:", questID, "at step index:", stepIndex)
		end
		return false
	end

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

	if not questData then
		return
	end

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

	if not questData then
		return
	end

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

	if not questData then
		return
	end

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


-- Primary function to check the progress of objectives in a quest
function RQE:CheckObjectiveProgress(questID, stepIndex)
	-- Retrieve quest objectives and data
	local objectives = C_QuestLog.GetQuestObjectives(questID)
	local questData = self.getQuestData(questID)

	-- Early return if no quest is super-tracked
	if not RQE.IsQuestSuperTracked() then
		return
	end

	-- Validate quest and objective data
	if not questData then
		return false
	end

	if not objectives then
		return false
	end

	-- Ensure stepIndex is valid
	if not questData[stepIndex] then
		return false
	end

	-- Determine the current step and its data
	local currentStepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
	local stepData = questData[currentStepIndex]

	-- Check if the quest is ready for turn-in first
	local isReadyTurnIn = C_QuestLog.ReadyForTurnIn(questID)
	if isReadyTurnIn then
		self:ClickWaypointButtonForIndex(#questData) -- Clicks the last step which should be the turn-in step
		return true
	end

	-- Refined step advancement logic
	local correctStepIndex = 1
	local foundStep = false

	-- Iterate through the questData to find the correct step based on objective completion
	for i, step in ipairs(questData) do
		local objectiveIndex = step.objectiveIndex or 1
		local neededAmt = step.neededAmt and tonumber(step.neededAmt[1]) or 1
		local objective = objectives[objectiveIndex]

		if objective then
			-- Objective is completed; move to the next objective index
			if objective.finished then
				correctStepIndex = i + 1
			-- Exact match of numFulfilled with neededAmt found for current step
			elseif objective.numFulfilled == neededAmt then
				correctStepIndex = i
				foundStep = true
				break
			-- Objective numFulfilled is less than neededAmt; this is the correct step
			elseif objective.numFulfilled < neededAmt then
				correctStepIndex = i
				foundStep = true
				break
			end
		else
			-- Handle missing or mismatched objective data
			correctStepIndex = i
			break
		end
	end

	-- Ensure correctStepIndex does not exceed the number of steps
	correctStepIndex = math.min(correctStepIndex, #questData)

	-- If the stepIndex does not match the expected, click the correct button
	if correctStepIndex ~= currentStepIndex then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("StepIndex before running self:ClickWaypointButtonForIndex is: " .. correctStepIndex)
		end
		self:ClickWaypointButtonForIndex(correctStepIndex)
		if RQE.db.profile.debugLevel == "INFO+" then
			print("StepIndex after running self:ClickWaypointButtonForIndex is: " .. correctStepIndex)
		end
		return true
	end

	-- No action needed if current stepIndex matches expected stepIndex
	return false
end


-- Function to check the current scenario stage
function RQE:CheckScenarioStage(questID, stepIndex)
	-- Ensure the player is in a scenario
	if not C_Scenario.IsInScenario() then
		return false
	end

	-- Fetch general scenario information
	local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
	if not scenarioInfo then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No active scenario information available.")
		end
		return false
	end

	local currentStage = scenarioInfo.currentStage

	-- Fetch quest data and step information
	local questData = self.getQuestData(questID)
	local stepData = questData and questData[stepIndex]

	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data found in RQEDatabase for quest ID:", questID)
		end
		return false
	end

	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data found for quest ID:", questID)
		end
		return false
	end

	-- Compare current scenario stage with needed stage
	local neededStage = tonumber(stepData.neededAmt[1]) or 1
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Current scenario stage:", currentStage, "Needed stage:", neededStage)
	end

	-- Check if the current stage meets or exceeds the needed stage
	if currentStage >= neededStage then
		-- Correctly identify the next step index based on scenario progression
		local nextStepIndex = stepIndex

		-- Only advance if we have reached or surpassed the needed stage for the next step
		for i = stepIndex + 1, #questData do
			local step = questData[i]
			local stepNeededStage = tonumber(step.neededAmt[1]) or 1

			-- Only advance if the current scenario stage is equal to the stepNeededStage
			if currentStage == stepNeededStage then
				nextStepIndex = i
				break
			elseif currentStage < stepNeededStage then
				break
			end
		end

		-- Advance to the next correct step only if it differs from the current step index
		if nextStepIndex > stepIndex then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Scenario stage requirement met. Advancing to next step index:", nextStepIndex)
			end
			self:ClickWaypointButtonForIndex(nextStepIndex)
			return true
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Current scenario stage (" .. currentStage .. ") does not meet required stage (" .. neededStage .. ").")
		end
	end

	return false
end



-- Function to check scenario criteria progress
function RQE:CheckScenarioCriteria(questID, stepIndex)
	-- Ensure the player is in a scenario
	if not C_Scenario.IsInScenario() then
		return false
	end

	-- Fetch general scenario information
	local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
	if not scenarioInfo then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No active scenario information available.")
		end
		return false
	end

	-- Iterate through scenario criteria
	local stepID = scenarioInfo.currentStage
	local numCriteria = select(3, C_Scenario.GetStepInfo())

	for criteriaIndex = 1, numCriteria do
		local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)

		if criteriaInfo and criteriaInfo.quantity >= criteriaInfo.totalQuantity then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Scenario criteria met. Advancing to next step.")
			end
			self:AdvanceQuestStep(questID, stepIndex)
			return true
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Scenario criteria not yet met.")
	end
	return false
end


---------------------------------------------------
-- 17. Filtering Functions
---------------------------------------------------

-- Contain filters for the RQEQuestingFrame
RQE.filterCompleteQuests = function()
	local numEntries = C_QuestLog.GetNumQuestLogEntries()

	for i = 1, numEntries do
		local questInfo = C_QuestLog.GetInfo(i)
		if questInfo and not questInfo.isHeader then
			if C_QuestLog.IsComplete(questInfo.questID) then
				C_QuestLog.AddQuestWatch(questInfo.questID)
			elseif questInfo.questID then
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
			---@type number|nil
			local uiMapID, _, _, _, _ = C_QuestLog.GetQuestAdditionalHighlights(questInfo.questID)
			-- If the primary map ID is not available, fallback to the secondary options
			if not uiMapID or uiMapID == 0 then
				uiMapID = C_TaskQuest.GetQuestZoneID(questInfo.questID)
				-- As a last resort, use the quest's UiMapID if available
				if not uiMapID or uiMapID == 0 then
					uiMapID = GetQuestUiMapID(questInfo.questID)
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
				local zoneID = GetQuestUiMapID(questInfo.questID) or C_TaskQuest.GetQuestZoneID(questInfo.questID)
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


-- Function to print out the questline information for a specific quest
function RQE.PrintQuestLineInfo(questID, uiMapID)
	-- Ensure that the questID and uiMapID are valid numbers
	if not questID or not uiMapID then
		print("Invalid questID or uiMapID provided.")
		return
	end

	-- Ensure that the questID and uiMapID are numbers
	if type(questID) ~= "number" or type(uiMapID) ~= "number" then
		print("questID and uiMapID must be numbers.")
		return
	end

	-- Retrieve the quest line information for the given questID and uiMapID
	local status, questLineInfo = pcall(C_QuestLine.GetQuestLineInfo, questID, uiMapID)

	if status and questLineInfo then
		-- Print the quest line information to chat
		print("Quest Line Information for Quest ID " .. questID .. ":")
		print("Quest Line ID:", questLineInfo.questLineID)
		print("Quest Line Name:", questLineInfo.questLineName)
		print("Map ID:", uiMapID)
		print("Quest Name:", questLineInfo.questName)
		print("X Position:", questLineInfo.x)
		print("Y Position:", questLineInfo.y)
		print("Is Hidden:", questLineInfo.isHidden and "Yes" or "No")
		print("Is Legendary:", questLineInfo.isLegendary and "Yes" or "No")
		print("Is Daily:", questLineInfo.isDaily and "Yes" or "No")
		print("Is Campaign:", questLineInfo.isCampaign and "Yes" or "No")
		print("Floor Location:", questLineInfo.floorLocation)
	else
		-- No quest line info was found for the given questID and uiMapID, or an error occurred
		print("No quest line information found for Quest ID " .. questID .. " and Map ID " .. uiMapID .. ", or an error occurred.")
	end
end


-- Get the X, Y, and MapID of a particular quest
function RQE.GetQuestUiMapID(questID)
	local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	local mapID = GetQuestUiMapID(questID)
	local x, y = C_QuestLog.GetNextWaypointForMap(questID, mapID)

	print("Map is: " .. mapID)
	print("X:", tostring(x), "Y:", tostring(y))
end


-- Function to Request and Cache all quest lines in player's quest log
function RQE.RequestAndCacheQuestLines()
	RQE.QuestLines = RQE.QuestLines or {}

	local numEntries = C_QuestLog.GetNumQuestLogEntries()
	for i = 1, numEntries do
		local questInfo = C_QuestLog.GetInfo(i)
		if questInfo and not questInfo.isHeader then
			-- Directly use the map ID associated with the quest for more accurate quest line retrieval
			local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID)
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
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		if isWorldQuest then
			C_QuestLog.AddWorldQuestWatch(questID)
		else
			C_QuestLog.AddQuestWatch(questID)
		end
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
			-- Check if questType is a valid number
			if questType and type(questType) == "number" then
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


-- Build Menu List for the QuestTypes in QuestLog
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
	RQE:UpdateMapIDDisplay()
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


-- Function to remove a manually tracked world quest
function RQE:RemoveManuallyTrackedWorldQuest(questID)
	if not questID then
		RQE.debugLog("Invalid questID for RemoveManuallyTrackedWorldQuest")
		return
	end

	-- Remove the world quest from tracking
	C_QuestLog.RemoveWorldQuestWatch(questID)

	-- Update the saved list
	RQE.savedWorldQuestWatches[questID] = nil
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Manually removed World Quest ID: " .. questID .. " from saved list")
	end

	-- Refresh the UI
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if questID == extractedQuestID then
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
		end
	end
	UpdateRQEWorldQuestFrame()
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


-- Function to remove an automatically tracked world quest
function RQE:RemoveAutomaticallyTrackedWorldQuest(questID)
	if not questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Invalid questID for RemoveAutomaticallyTrackedWorldQuest")
		end
		return
	end

	-- Remove the world quest from tracking
	C_QuestLog.RemoveWorldQuestWatch(questID)

	-- Update the saved list
	RQE.savedAutomaticWorldQuestWatches[questID] = nil
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Automatically removed World Quest ID: " .. questID .. " from saved list")
	end

	-- Optionally clear RQEFrame if necessary
	C_Timer.After(1, function()
		RQE.CheckAndClearRQEFrame()
	end)
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
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Manually tracking World Quest ID " .. questID)
			end
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
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Automatically tracking World Quest ID " .. questID)
			end
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
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest ID " .. questID .. " is being tracked " .. trackingType)
			end
		end
	end
end


-- Prints the quests that are on the current player map
function RQE.GetMapQuests()
	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		print("Unable to get player's map ID.")
		return
	end

	-- Fetch quests on the current map
	local quests = C_QuestLog.GetQuestsOnMap(playerMapID)

	-- Check if there are any quests on the map
	if not quests or #quests == 0 then
		print("No quests found on the current map.")
		return
	end

	-- Print out the details of each quest on the map
	for _, quest in ipairs(quests) do
		print("Quest ID: " .. quest.questID)
		print("Coordinates: (" .. quest.x .. ", " .. quest.y .. ")")
		print("Type: " .. quest.type)
		print("Is Map Indicator Quest: " .. tostring(quest.isMapIndicatorQuest))
		print("-------")
	end
end


-- Pulls map information for quests in the present zone and saves them
function RQE.PullDataFromMapQuests()
	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		RQE.debugLog("Unable to get player's map ID.")
		return {}
	end

	-- Fetch quests on the current map
	local quests = C_QuestLog.GetQuestsOnMap(playerMapID)

	-- Check if there are any quests on the map
	if not quests or #quests == 0 then
		RQE.debugLog("No quests found on the current map.")
		return {}
	end

	-- Create a table to store quest data
	local questData = {}

	-- Store the details of each quest on the map in the table
	for _, quest in ipairs(quests) do
		questData[quest.questID] = {
			x = quest.x,
			y = quest.y,
			type = quest.type,
			isMapIndicatorQuest = quest.isMapIndicatorQuest,
			mapID = playerMapID
		}
	end

	return questData
end


-- Function to get coordinates for a specific quest
function RQE.GetQuestCoordinates(questID)
	-- Get the quests on the current map
	local questsOnMap = RQE.PullDataFromMapQuests()

	-- Check if the questID is in the questsOnMap table
	if questsOnMap[questID] then
		return questsOnMap[questID].x, questsOnMap[questID].y, questsOnMap[questID].mapID
	else
		return nil, nil, nil
	end
end


-- -- Removes Automatic WQ when leaving area of WQ location
-- function RQE.UntrackAutomaticWorldQuests()
	-- local playerMapID = C_Map.GetBestMapForUnit("player")

	-- -- Check if playerMapID is valid
	-- if not playerMapID then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Unable to get player's map ID.")
		-- end
		-- return
	-- end

	-- local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)

	-- -- Convert the questsInArea to a lookup table for quicker access and print them
	-- local questsInAreaLookup = {}
	-- for _, taskPOI in ipairs(questsInArea) do
		-- questsInAreaLookup[taskPOI.questId] = true
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print(taskPOI.questId)  -- Print each quest ID found in the area
		-- end
	-- end

	-- -- Go through each watched world quest and check conditions
	-- RQE.infoLog("Checking watched world quests:")
	-- for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		-- local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		-- if questID then
			-- local watchType = C_QuestLog.GetQuestWatchType(questID)
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("WQ " .. i .. ": ID " .. questID .. ", WatchType: " .. (watchType == Enum.QuestWatchType.Automatic and "Automatic" or "Manual"))
			-- end

			-- -- Only untrack if the quest is tracked automatically and is not in the current area
			-- if watchType == Enum.QuestWatchType.Automatic and not questsInAreaLookup[questID] then
				-- -- Additional check: ensure the player is not close to the quest location
				-- local questMapID = C_TaskQuest.GetQuestZoneID(questID)
				-- if questMapID and questMapID ~= playerMapID then
					-- C_QuestLog.RemoveWorldQuestWatch(questID)
					-- if RQE.db.profile.debugLevel == "INFO+" then
						-- print("Removing world quest watch for quest: " .. questID)
					-- end
				-- end
			-- end
		-- end
	-- end
-- end


-- Function to untrack automatically tracked world quests
function RQE.UntrackAutomaticWorldQuests()
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	-- Check for quests in the current map area
	local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)
	local questsInAreaLookup = {}

	for _, taskPOI in ipairs(questsInArea) do
		questsInAreaLookup[taskPOI.questId] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest found in area: " .. taskPOI.questId)
		end
	end

	-- Iterate over tracked world quests
	for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		if questID then
			local watchType = C_QuestLog.GetQuestWatchType(questID)

			-- Ensure it is tracked automatically
			if watchType == Enum.QuestWatchType.Automatic then
				-- Remove it if the quest is no longer in the current area
				if not questsInAreaLookup[questID] then
					C_QuestLog.RemoveWorldQuestWatch(questID)
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Removed automatic world quest tracking: " .. questID)
					end
				end
			end
		end
	end
end


-- Removes Automatic WQ when leaving area of WQ location
function RQE.UntrackAutomaticWorldQuestsByMap()
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	-- Get quests on the current map
	local mapQuests = C_QuestLog.GetQuestsOnMap(playerMapID)

	-- Convert the mapQuests to a lookup table for quicker access
	local mapQuestsLookup = {}
	for _, quest in ipairs(mapQuests) do
		mapQuestsLookup[quest.questID] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Map Quest ID: " .. quest.questID .. " at (" .. quest.x .. ", " .. quest.y .. ")")  -- Print each quest ID found on the map
		end
	end

	-- Convert the questsInArea to a lookup table for quicker access and print them
	local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)
	local questsInAreaLookup = {}
	for _, taskPOI in ipairs(questsInArea) do
		questsInAreaLookup[taskPOI.questId] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print(taskPOI.questId)  -- Print each quest ID found in the area
		end
	end

	-- Get the currently super tracked quest ID
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Attempt to directly extract questID from RQE.QuestIDText if available
	local visibleQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		visibleQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Go through each watched world quest and check conditions
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Checking watched world quests:")
	end
	for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		if questID then
			local watchType = C_QuestLog.GetQuestWatchType(questID)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("WQ " .. i .. ": ID " .. questID .. ", WatchType: " .. (watchType == Enum.QuestWatchType.Automatic and "Automatic" or "Manual"))
			end

			-- If the quest is not in the current area and it was tracked automatically, untrack it
			if watchType == Enum.QuestWatchType.Automatic then
				-- Check if the quest is not in the area and not on the map
				if not questsInAreaLookup[questID] and not mapQuestsLookup[questID] then
					C_QuestLog.RemoveWorldQuestWatch(questID)
					RQE.infoLog("Removed WQ " .. questID .. " from watch list.")
				end
			end
		end
	end
end


-- Checks and Clears RQEFrame of any quest data that is not being tracked
function RQE.CheckAndClearRQEFrame()
	-- Attempt to directly extract questID from RQE.QuestIDText if available
	local visibleQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		visibleQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	if RQE.searchedQuestID == visibleQuestID then
		return
	end

	-- Get the currently super tracked quest ID
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	local isOnQuest = C_QuestLog.IsOnQuest(visibleQuestID)

	-- Check if the visible quest is not a regular quest
	if visibleQuestID and not isOnQuest then
		local isWorldQuestTracked = false
		for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
			local qID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if qID == visibleQuestID then
				isWorldQuestTracked = true
				break
			end
		end

		-- Clear the frame data if the quest is neither a regular quest nor a tracked world quest
		if not isWorldQuestTracked then
			RQE:RemoveSuperTrackingFromQuest() -- Remove super-tracking if the quest is not being tracked
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
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

	RQE.isCheckingMacroContents = true

	if playSoundForCompletion then
		PlaySound(6199) -- Sound for quest completion
		soundCooldown = true
		C_Timer.After(5, function() soundCooldown = false end)
		RQEMacro:CreateMacroForCurrentStep()
	elseif playSoundForObjectives then
		PlaySound(6192) -- Sound for individual objective completion
		soundCooldown = true
		C_Timer.After(5, function() soundCooldown = false end)
		RQEMacro:CreateMacroForCurrentStep()
	end

	-- Failsafe to set the flag back to false if is true
	if RQE.isCheckingMacroContents then
		RQE.isCheckingMacroContents = false
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


-- Function to check the memory usage of addon
function RQE:CheckMemoryUsage()
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		-- Update the memory usage information via the following Blizzard API
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


-- Function to check macro contents and build a new macro if needed
function RQE.CheckAndBuildMacroIfNeeded()
	if not RQE.db.profile.autoClickWaypointButton then
		return
	end

	local isMacroCorrect = RQE.CheckCurrentMacroContents()

	if not isMacroCorrect then
		--RQE:BuildQuestMacroBackup()
		-- Tier Four Importance: RQE.CheckAndBuildMacroIfNeeded function
		RQE.CreateMacroForCheckAndBuildMacroIfNeed = true
		RQEMacro:CreateMacroForCurrentStep()
		C_Timer.After(3, function()
			RQE.CreateMacroForCheckAndBuildMacroIfNeed = false
		end)
	end

	if RQE.shouldCheckFinalStep then
		C_Timer.After(1, function()
			RQE.CheckAndSetFinalStep()
		end)
	end
end


-- Handles building the macro from the super tracked quest
function RQE:BuildQuestMacroBackup()
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if isSuperTracking then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()

		-- Allow time for the UI to update and for the super track to register
		C_Timer.After(1, function()
			-- Fetch the quest data here
			local questData = RQE.getQuestData(questID)
			if not questData then
				return
			end

			-- Validate waypointButton before proceeding
			local waypointButton = (type(RQE.LastClickedWaypointButton) == "table" and RQE.LastClickedWaypointButton) or { stepIndex = 1 }

			-- Check if the last clicked waypoint button's macro should be set
			if waypointButton and waypointButton.stepIndex then
				local stepData = questData[waypointButton.stepIndex]
				if stepData and stepData.macro then
					-- Get macro commands from the step data
					local macroCommands = type(stepData.macro) == "table" and table.concat(stepData.macro, "\n") or stepData.macro
					RQE.infoLog("Setting macro commands for final step:", macroCommands)
					RQEMacro:SetQuestStepMacro(questID, waypointButton.stepIndex, macroCommands, false)
				end
			end
		end)
	end
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


function RQE:ClickSuperTrackedNonBlacklistQuestButton()
	for _, button in pairs(RQE.QuestLogIndexButtons) do
		if button.questID == RQE.NonBlacklistSuperID then
			button:Click()
			return
		end
	end
end


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

	if not itemName then
		RQE.debugLog("Error: Unable to retrieve item name for merchant index " .. tostring(index))
		return
	end

	if not itemLink then
		RQE.debugLog("Warning: Unable to retrieve item link for merchant index " .. tostring(index) .. ", using item name instead.")
	end

	local itemDisplay = itemLink or itemName

	StaticPopupDialogs["RQE_CONFIRM_PURCHASE"] = {
		text = "Do you want to buy " .. quantity .. " of " .. itemDisplay .. "?",
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
	if C_AddOns.IsAddOnLoaded("CraftSim") or C_AddOns.IsAddOnLoaded("TradeSkillMaster") then
		RQE:SearchAndPrepareAuctionItem(itemID, quantity)
	else
		RQE:SearchAndPrepareAuctionItem(itemID, quantity)
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
				-- Display the confirmation popup with the total cost
				StaticPopupDialogs["RQE_CONFIRM_PURCHASE_COMMODITY"] = {
					text = string.format("Confirm your purchase of %d x [%s] for %s.", quantity, C_Item.GetItemNameByID(itemID), GetCoinTextureString(totalCost)),
					button1 = "Yes",
					button2 = "No",
					OnAccept = function()
						C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)
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
	local yPos = RQE.db.profile.framePosition.yPos or -285
	RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
end


---------------------------------------------------
-- 20. Experimental Testing Ground
---------------------------------------------------

-- Table to hold the questID and stepIndex conditions (blacklist)
RQE.questConditions = {
	[78640] = 3,  -- Example questID 78640 with stepIndex 3
}


-- Function to get the closest quest that isn't blacklisted
function RQE:GetClosestNonBlacklistedQuest()
	local nextClosestQuestID = nil
	local closestDistance = math.huge  -- Initialize with a large number

	-- Get the current map of the player (for quest location purposes)
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Iterate through all quests in the player's quest log
	for i = 1, C_QuestLog.GetNumQuestLogEntries() do
		local info = C_QuestLog.GetInfo(i)

		-- Only consider quests that are on the map, are being tracked, and are not blacklisted
		if info and info.isOnMap and C_QuestLog.IsOnQuest(info.questID) and not RQE.questConditions[info.questID] then
			-- Get the quest's objectives to find position/distance
			local questPosition = C_QuestLog.GetQuestObjectives(info.questID)

			-- Ensure the quest position is valid
			if questPosition then
				local distance = C_QuestLog.GetDistanceSqToQuest(info.questID)

				-- Check if this quest is closer than the current closest one
				if distance and distance < closestDistance then
					closestDistance = distance
					nextClosestQuestID = info.questID
				end
			end
		end
	end

	return nextClosestQuestID
end


-- Function to check if the supertracked quest matches the array and stepIndex
function RQE:CheckSuperTrackedQuestAndStep()
	-- Get the currently super-tracked quest ID
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	RQE.BlackListedQuestID = superTrackedQuestID

	-- Get the current step index from the addon
	local currentStepIndex = RQE.AddonSetStepIndex or 1  -- Default to 1 if AddonSetStepIndex is nil

	-- Check if the super-tracked quest is in the questConditions array and matches the stepIndex
	if RQE.questConditions[superTrackedQuestID] and RQE.questConditions[superTrackedQuestID] == currentStepIndex then
		-- If the condition matches, clear the RQEFrame and blacklist the quest
		RQE.BlacklistUnderway = true
		
		-- Temporarily remove the quest from the watch list
		C_QuestLog.RemoveQuestWatch(superTrackedQuestID)
		RQE.Buttons.ClearButtonPressed()

		-- Supertrack the next closest non-blacklisted quest
		local nextClosestQuestID = RQE:GetClosestNonBlacklistedQuest()
		RQE.ClosestSafeQuestID = nextClosestQuestID

		if nextClosestQuestID then
			-- Set the supertracked quest to the next closest non-blacklisted quest
			C_SuperTrack.SetSuperTrackedQuestID(nextClosestQuestID)
			RQE:SaveSuperTrackedQuestToCharacter()

			-- Ensure the blacklisted quest is not re-added prematurely
			RQE.BlacklistUnderway = false

			-- After a delay, re-add the blacklisted quest to the watch list, but do not re-supertrack it
			C_Timer.After(2.5, function()
				C_QuestLog.AddQuestWatch(RQE.BlackListedQuestID, 1)
			end)
		end
	end
end


-- Function to supertrack a random quest
function RQE:SupertrackRandomQuest()
	local numQuests = C_QuestLog.GetNumQuestLogEntries()
	local randomIndex = math.random(1, numQuests)

	-- Iterate through the player's quest log to find a valid random quest
	for i = 1, numQuests do
		local info = C_QuestLog.GetInfo(i)
		if info and info.questID then
			-- Found a quest, supertrack it
			C_SuperTrack.SetSuperTrackedQuestID(info.questID)
			RQE:SaveSuperTrackedQuestToCharacter()

			-- Print debug message
			print("Supertracking random questID: " .. tostring(info.questID))

			-- Call UpdateFrame to refresh the UI
			UpdateFrame(info.questID)
			return  -- Exit after setting one random quest
		end
	end

	-- Fallback: No quests found
	print("No quests found to supertrack.")
end


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


-- Frame to handle the gossip event securely
local RQEGossipFrame = CreateFrame("Frame", "RQEGossipFrame", UIParent)
RQEGossipFrame:RegisterEvent("GOSSIP_SHOW")

-- Function to store the selected gossip option criteria
local selectedGossipOption = {
	npcName = nil,
	optionIndex = nil
}


-- Securely hook the frame's event handler
RQEGossipFrame:HookScript("OnEvent", function(self, event)
	-- Fetch available gossip options
	local options = C_GossipInfo.GetOptions()

	-- Check if options exist
	if not options or #options == 0 then
		return
	end

	-- Get the current NPC name
	local currentNPCName = UnitName("npc")

	-- Check if the selection criteria match the current NPC
	if selectedGossipOption.npcName and currentNPCName == selectedGossipOption.npcName then
		-- Iterate through options and select based on specified index
		for i, option in ipairs(options) do
			if option.orderIndex == selectedGossipOption.optionIndex then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Selecting gossip option:", option.orderIndex, "for NPC Name:", selectedGossipOption.npcName)
				end
				C_GossipInfo.SelectOptionByIndex(option.orderIndex)
				break
			end
		end
	end
end)


-- Function to set the gossip selection criteria for the current NPC
function RQE.SelectGossipOption(npcName, optionIndex)
	-- Adding check to make sure that Gossip Mode is enabled
	if not RQE.db.profile.enableGossipModeAutomation then return end

	-- Set the selected gossip option for future use
	selectedGossipOption.npcName = npcName
	selectedGossipOption.optionIndex = optionIndex

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Gossip selection set for NPC Name:", npcName, "to select option:", optionIndex)
	end
end