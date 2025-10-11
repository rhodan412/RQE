--[[ 

Core.lua
Core file linking all other modules

]]


--------------------------------------------------
-- 1. Global Declarations
--------------------------------------------------

RQEDB = RQEDB or {}
RQEDB.profile = RQEDB.profile or {}
RQEDB.char = RQEDB.char or {}
RQEDB.profileKeys = RQEDB.profileKeys or {}

RQE = RQE or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}
RQEMacro = RQEMacro or {}
RQE.DelayedQuestWatchCheck = RQE.DelayedQuestWatchCheck or {}

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


-- Custom Info Message Function (exact format: " RQE Info (Core.lua @ Line 3640): ...")
function RQE:CustomLogMsg(line, color, filePath, message, ...)
	-- reduce "Interface/AddOns/RQE/Core.lua" to just "Core.lua"
	local shortFile = tostring(filePath):match("([^/\\]+)$") or tostring(filePath)

	local output = "|c" .. color .. " RQE Info (" .. shortFile .. " @ Line " .. tostring(line) .. "): " .. tostring(message)

	-- append any extra args separated by spaces
	local args = { ... }
	for i = 1, #args do
		output = output .. " " .. tostring(args[i])
	end

	output = output .. "|r"

	-- Add to logTable
	RQE.AddToDebugLog(output)

	-- Update the log frame if it’s visible
	if RQE.DebugLogFrameRef and RQE.DebugLogFrameRef:IsShown() then
		RQE.UpdateLogFrame()
	end
end


-- Function to log general info messages (now includes file + line)
function RQE.infoLog(message, ...)
	if RQE.db and RQE.db.profile.debugMode then
		local debugLevel = RQE.db.profile.debugLevel
		if debugLevel == "INFO" or debugLevel == "INFO+" or debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
			-- grab the caller's file and line
			local stack = debugstack(2, 1, 0)
			-- capture "anything up to colon" as filePath, then the line number
			local _, _, filePath, line = string.find(stack, "([^:]-):(%d+):")
			RQE:CustomLogMsg(line, "cf9999FF", filePath or "Unknown.lua", message, ...)
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


--- Prints a message with contextual info (file, provided function name, line number).
--- Works safely even inside C_Timer, hooks, or callbacks.
--- @param funcName string The function name (e.g., "RQE.handleQuestStatusUpdate")
--- @param message string The message to print
--- @param ... any Additional values to append
function RQE.smartPrint(funcName, message, ...)
	if not C_AddOns.IsAddOnLoaded("RQE_Contribution") then return end
	if RQE.db and RQE.db.profile.debugMode then
		local debugLevel = RQE.db.profile.debugLevel
		if debugLevel == "INFO+" then
		-- if debugLevel == "INFO" or debugLevel == "INFO+" or debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
			local stack = debugstack(2, 1, 0)
			local _, _, filePath, line = string.find(stack, "([^:]-):(%d+):")

			local shortFile = (filePath and filePath:match("([^/\\]+)$")) or "Unknown.lua"
			shortFile = shortFile:gsub("%]", "") -- clean any trailing bracket
			line = line or "???"

			-- build message
			local output = string.format("~~ %s ~~\nFile: %s\nFunction: %s\nLine: %s",
				tostring(message),
				shortFile,
				funcName or "Unknown",
				tostring(line)
			)

			-- append extra args if given
			local args = { ... }
			if #args > 0 then
				output = output .. "\nArgs: " .. table.concat(args, ", ")
			end

			-- print to chat
			DEFAULT_CHAT_FRAME:AddMessage(output, 1, 1, 1)

			-- log to debug frame
			if RQE.AddToDebugLog then
				RQE.AddToDebugLog("|cffffffff" .. output .. "|r")
			end

			-- update visible log frame
			if RQE.DebugLogFrameRef and RQE.DebugLogFrameRef:IsShown() then
				RQE.UpdateLogFrame()
			end
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

-- Global color helpers
RQE.ColorGREEN  = "|cff00ff00"
RQE.ColorYELLOW = "|cffffff00"
RQE.ColorWHITE  = "|cffffffff"
RQE.ColorORANGE = "|cffff7f00"
RQE.ColorRESET  = "|r"

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
		debugTimeStampCheckbox = true,
		displayRQEcpuUsage = false,
		displayRQEmemUsage = false,
		enableAutoSuperTrackSwap = false,
		enableCarboniteCompatibility = true,
		enableFrame = true,
		enableGossipModeAutomation = false,
		enableMouseOverMarking = true,
		enableTravelSuggestions = false,
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
		mythicScenarioMode = true,
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


RQE.LastMapChangeTime = 0

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

	RQEDB = RQEDB or {}	-- Ensure the saved var exists

	-- Ensure SavedVariables `profileKeys` exists before AceDB initializes
	if not RQEDB.profileKeys then
		RQEDB.profileKeys = {}
	end

	-- Create AceDB-3.0 database **without forcing a default profile yet**
	self.db = LibStub("AceDB-3.0"):New("RQEDB", defaults)

	-- Ensure AceDB does not overwrite stored profileKeys
	self.db.profileKeys = RQEDB.profileKeys

	-- Debugging: Print all stored profile keys before restoring profile
	print("Checking stored profileKeys before restoration...")
	for key, value in pairs(self.db.profileKeys) do
		print("Found profile key: " .. key .. " -> " .. value)
	end

	-- Restore the correct profile from SavedVariables
	self:RestoreSavedProfile()

	-- Debugging: Confirm the correct profile was restored
	print("Profile after OnInitialize():", self.db:GetCurrentProfile())

	-- Register profile callbacks
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

	-- Initialize UI components
	RQE.StepsText = RQE.StepsText or {}
	RQE.CoordsText = RQE.CoordsText or {}
	RQE.WaypointButtons = RQE.WaypointButtons or {}

	-- Set UI Frame Position
	self:UpdateFrameFromProfile()

	-- Load character-specific data
	self:GetCharacterInfo()

	-- Register UI Options
	AC:RegisterOptionsTable("RQE_Main", RQE.options.args.general)
	self.optionsFrame = ACD:AddToBlizOptions("RQE_Main", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register UI Pages
	AC:RegisterOptionsTable("RQE_Frame", RQE.options.args.frame)
	self.optionsFrame.frame = ACD:AddToBlizOptions("RQE_Frame", "Frame Settings", "|cFFCC99FFRhodan's Quest Explorer|r")

	AC:RegisterOptionsTable("RQE_Font", RQE.options.args.font)
	self.optionsFrame.font = ACD:AddToBlizOptions("RQE_Font", "Font Settings", "|cFFCC99FFRhodan's Quest Explorer|r")

	AC:RegisterOptionsTable("RQE_Debug", RQE.options.args.debug)
	self.optionsFrame.debug = ACD:AddToBlizOptions("RQE_Debug", "Debug Options", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register Profiles Section
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("RQE_Profiles", profiles)
	ACD:AddToBlizOptions("RQE_Profiles", "Profiles", "|cFFCC99FFRhodan's Quest Explorer|r")

	-- Register chat commands
	self:RegisterChatCommand("rqe", "SlashCommand")

	-- Override print function for debug logging
	local originalPrint = print
	print = function(...)
		local args = {...}
		local output = {}

		for i, v in ipairs(args) do
			if v == nil then
				output[i] = "nil"  -- Replace nil values with "nil" string
			elseif type(v) == "table" then
				output[i] = "[Table]"  -- Prevent error from printing tables
			else
				output[i] = tostring(v)  -- Convert all other values to strings
			end
		end

		local message = table.concat(output, " ")

		-- Add to debug log
		RQE.AddToDebugLog(message)

		-- Call original print function
		originalPrint(message)
	end

	-- Final UI Setup
	self:UpdateFramePosition()
	RQE.FilterDropDownMenu = CreateFrame("Frame", "RQEDropDownMenuFrame", UIParent, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(RQE.FilterDropDownMenu, RQE.InitializeFilterDropdown)
end


-- AceAddon calls this after the addon is fully loaded
function RQE:OnEnable()
	-- Restore profile only if not already set
	if not self.db:GetCurrentProfile() or self.db:GetCurrentProfile() == "Default" then
		self:RestoreSavedProfile()
	end

	-- Ensure defaults are in place
	self:EnsureDefaults()

	-- Debugging Output
	print("Currently loaded profile:", self.db:GetCurrentProfile())

	-- Apply UI settings after profile is set
	self:ApplyUISettings()
end


-- Helper function for default frame positions
function RQE:EnsureDefaults()
	self.db.profile.framePosition = self.db.profile.framePosition or CopyTable(defaults.profile.framePosition)
	self.db.profile.QuestFramePosition = self.db.profile.QuestFramePosition or CopyTable(defaults.profile.QuestFramePosition)
	self.db.profile.textSettings = self.db.profile.textSettings or CopyTable(defaults.profile.textSettings)
	self.db.char = self.db.char or CopyTable(defaults.char or {})
end


-- Function to restore the correct profile from SavedVariables
function RQE:RestoreSavedProfile()
	local characterName = UnitName("player")
	local characterRealm = GetRealmName()
	local profileKey = characterName .. " - " .. characterRealm

	-- Ensure the profileKeys table exists
	self.db.profileKeys = self.db.profileKeys or {}

	-- Debugging: Check if profileKey exists
	if not self.db.profileKeys[profileKey] then
		print("No saved profile for " .. profileKey .. ". Assigning Default profile.")
		self.db.profileKeys[profileKey] = "Default"
	end

	local savedProfile = self.db.profileKeys[profileKey]

	-- Debugging: Print loaded profile information
	print("Saved Profile for " .. profileKey .. ": " .. savedProfile)

	-- Ensure profile exists before setting it
	if self.db.profiles and self.db.profiles[savedProfile] then
		self.db:SetProfile(savedProfile)
		print("Successfully restored profile: " .. savedProfile)
	else
		print("Profile " .. savedProfile .. " not found in AceDB. Falling back to Default.")
		self.db:SetProfile("Default")
	end

	-- Final Debug Output
	print("Final profile loaded:", self.db:GetCurrentProfile())
end


-- Function to apply UI settings after restoring profile
function RQE:ApplyUISettings()
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
end


-- Function to print quest info when run with a questID
function RQE:GetQuestInfo(questID)
	if not questID then
		print("Error: No questID provided.")
		return
	end

	-- Get the quest log index for the given quest ID
	local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)

	if not questLogIndex then
		print("Error: Could not find quest log index for Quest ID:", questID)
		return
	end

	-- Retrieve quest information
	local info = C_QuestLog.GetInfo(questLogIndex)

	if not info then
		print("Error: No quest info found for Quest ID:", questID)
		return
	end

	-- Print the retrieved quest information
	print("===== Quest Info for Quest ID:", questID, "=====")
	for key, value in pairs(info) do
		print(key .. ":", tostring(value))
	end
	print("===================================")
end


-- Function that prints the quest data as it relates to a certain quest such as type, numRequired, finished (true/false), text, objectiveType and numFulfilled
function RQE:PrintQuestData(questID)
	-- Ensure the quest data is available
	if not HaveQuestData(questID) then
		print("Quest data is not available for QuestID:", questID)
		return
	end

	-- Get the quest data from the API
	local questData = C_QuestLog.GetQuestObjectives(questID)  -- Replace with the correct function if needed

	-- Print formatted output
	print("Quest Data for QuestID:", questID)
	if type(questData) == "table" then
		for key, value in pairs(questData) do
			if type(value) == "table" then
				print("  " .. key .. " = {")
				for subKey, subValue in pairs(value) do
					print("	" .. subKey .. " = " .. tostring(subValue))
				end
				print("  },")
			else
				print("  " .. key .. " = " .. tostring(value))
			end
		end
	else
		print("  Data is not a table or is empty.")
	end
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
	local functionName = "RQE:InitializeFrame()"

	--self:Initialize()  -- Call Initialize() within InitializeFrame

	-- Call the function to initialize the separate focus frame
	RQE.InitializeSeparateFocusFrame()

	-- Add logic to update frame with the current super tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if questID then
		local questInfo = RQE.getQuestData(questID)
		if questInfo then
			local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
			RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 681 ~~")
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

	-- If this is a completed, auto-completable quest, show the turn-in dialog instead
	if RQE:ShowAutoCompleteDialog(questID) then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(("RQE:ShowAutoCompleteDialog fired for questID %d"):format(questID))
		end
		return
	end

	---@type number|nil
	local mapID = GetQuestUiMapID(questID) or C_TaskQuest.GetQuestZoneID(questID)
	if mapID == 0 then mapID = nil end
	OpenQuestLog(mapID)
	QuestMapFrame_ShowQuestDetails(questID)
end


-- Helper function to see if a given quest is being watched
function RQE:IsQuestWatched(questID)
	if not questID then return false end
	if C_QuestLog.GetQuestWatchType then
		return C_QuestLog.GetQuestWatchType(questID) ~= nil
	end
	local n = C_QuestLog.GetNumQuestWatches and C_QuestLog.GetNumQuestWatches() or 0
	for i = 1, n do
		if C_QuestLog.GetQuestIDForQuestWatchIndex(i) == questID then
			return true
		end
	end
	return false
end


-- Function to auto-watch only auto-completable quests
function RQE:WatchAutoCompletableUnwatchedQuests(verbose)
	local added = 0
	local numEntries = C_QuestLog.GetNumQuestLogEntries()
	for i = 1, numEntries do
		local info = C_QuestLog.GetInfo(i)
		if info and not info.isHeader then
			local qid = info.questID
			if qid and self:IsQuestAutoComplete(qid) and not self:IsQuestWatched(qid) then
				local ok = C_QuestLog.AddQuestWatch(qid)
				if ok then added = added + 1 end
				if verbose and self.db and self.db.profile and self.db.profile.debugLevel == "INFO" then
					print(("RQE: watching auto-completable quest %d (%s)"):format(qid, info.title or ""))
				end
			end
		end
	end
	if verbose and self.db and self.db.profile and self.db.profile.debugLevel == "INFO" then
		print(("RQE: added %d auto-completable quest(s) to watch on login."):format(added))
	end
end


-- Returns true if the given quest is complete and can be auto-turned-in anywhere
function RQE:IsQuestAutoComplete(questID)
	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		print(("IsQuestAutoComplete check start: questID=%s"):format(tostring(questID)))
	end

	if not questID then
		if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
			print("IsQuestAutoComplete: no questID")
		end
		return false
	end

	if C_QuestLog.IsFailed and C_QuestLog.IsFailed(questID) then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(("IsQuestAutoComplete: quest %d is failed"):format(questID))
		end
		return false
	end

	local isComplete = C_QuestLog.IsComplete(questID)
	if RQE.db.profile.debugLevel == "INFO+" then
		print(("IsQuestAutoComplete: C_QuestLog.IsComplete=%s"):format(tostring(isComplete)))
	end
	if not isComplete then return false end

	local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	if RQE.db.profile.debugLevel == "INFO+" then
		print(("IsQuestAutoComplete: logIndex=%s"):format(tostring(logIndex)))
	end
	if not logIndex then return false end

	local info = C_QuestLog.GetInfo(logIndex)
	local isAuto = info and info.isAutoComplete == true
	if RQE.db.profile.debugLevel == "INFO+" then
		print("IsQuestAutoComplete: info=", info and info.questID, info and tostring(info.isAutoComplete))
		print(("IsQuestAutoComplete: isAutoComplete=%s"):format(tostring(isAuto)))
	end
	return isAuto
end


-- Attempts to show the native Blizzard auto-complete dialog; returns true if shown
function RQE:ShowAutoCompleteDialog(questID)
	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		print(("ShowAutoCompleteDialog: questID=%s"):format(tostring(questID)))
	end

	if not questID then return false end

	-- Optional: avoid double opening if the Complete/Reward UI is already up
	if QuestFrame and QuestFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ShowAutoCompleteDialog: QuestFrame already shown; skipping")
		end
		return false
	end

	if RQE:IsQuestAutoComplete(questID) then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(("ShowAutoCompleteDialog: calling ShowQuestComplete(%d)"):format(questID))
		end
		ShowQuestComplete(questID)
		return true
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("ShowAutoCompleteDialog: not auto-completable")
	end
	return false
end


-- Saves x, y, mapID ionformation to the RQE.DatabaseSuperX, RQE.DatabaseSuperY, RQE.DatabaseSuperMapID addon variables when fired
function RQE.SaveCoordData()
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if RQE.db.profile.autoClickWaypointButton and RQE.AreStepsDisplayed(questID) then
		if questID then
			-- Logic for updating location data
			local questData = RQE.getQuestData(questID)
			-- if questData and questData.location and questData.location.x and questData.location.y and questData.location.mapID then
				-- -- Update the location data for the examined quest
				-- RQE.DatabaseSuperX = questData.location.x / 100
				-- RQE.DatabaseSuperY = questData.location.y / 100
				-- RQE.DatabaseSuperMapID = questData.location.mapID
			local x, y, mapID, continentID = RQE.GetPrimaryLocation(questData)
			local finalMapID

			if mapID then
				finalMapID = mapID
			elseif continentID then
				local playerMapID = C_Map.GetBestMapForUnit("player")
				local parent = playerMapID and C_Map.GetMapInfo(playerMapID).parentMapID
				if parent == continentID then
					finalMapID = continentID
				end
			end

			if x and y and finalMapID then
				RQE.DatabaseSuperX = x / 100
				RQE.DatabaseSuperY = y / 100
				RQE.DatabaseSuperMapID = finalMapID
			else
				-- Debug message or fallback to prevent further errors
				if RQE.db.profile.debugLevel == "INFO+" then
					print("SaveCoordData: Invalid location data for questID:", questID)
				end
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
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running RQE:SaveSuperTrackedQuestToCharacter() ~~~")
	end

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


-- Function to save the currently watched/tracked quests to the character-specific table
function RQE:SaveTrackedQuestsToCharacter()
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running RQE:SaveTrackedQuestsToCharacter() ~~~")
	end

	-- Initialize the trackedQuests table for this character
	RQECharacterDB.trackedQuests = {}

	-- Loop through the tracked quests
	for i = 1, C_QuestLog.GetNumQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			-- Save the tracked quest ID
			if RQE.db.profile.debugLevel == "INFO+" then
				print("QuestID: " .. questID .. " saved to RQECharacterDB.trackedQuests")
			end
			table.insert(RQECharacterDB.trackedQuests, questID)
		end
	end

	-- Debug output for tracked quests
	if RQE.db.profile.debugLevel == "INFO+" then
		if #RQECharacterDB.trackedQuests > 0 then
			print("Saved tracked quests for this character:", table.concat(RQECharacterDB.trackedQuests, ", "))
		else
			print("No tracked quests found to save for this character.")
		end
	end
end


-- Function to restore the saved supertracked quest for the current character
function RQE:RestoreSuperTrackedQuestForCharacter()
	local functionName = "RQE:RestoreSuperTrackedQuestForCharacter()"

	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running RQE:RestoreSuperTrackedQuestForCharacter() ~~~")
	end

	if RQECharacterDB and RQECharacterDB.superTrackedQuestID then
		local savedQuestID = RQECharacterDB.superTrackedQuestID
		local isWorldQuest = RQECharacterDB.isWorldQuest

		-- Check if it's a world quest
		if isWorldQuest then
			-- Check if the world quest is still available
			local isWorldQuestStillAvailable = C_QuestLog.IsWorldQuest(savedQuestID) and C_QuestLog.GetQuestObjectives(savedQuestID) ~= nil

			if isWorldQuestStillAvailable then
				-- Restore the world quest as supertracked
				-- print("~~~ SetSuperTrack: 870~~~")
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
				-- print("~~~ SetSuperTrack: 886~~~")
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

	C_Timer.After(0.1, function()
		RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 1085 ~~")
		UpdateFrame()
	end)
end


-- Function to restore the watched/tracked quests for the current character
function RQE:RestoreTrackedQuestsForCharacter()
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running RQE:RestoreTrackedQuestsForCharacter() ~~~")
	end

	if not RQECharacterDB or not RQECharacterDB.trackedQuests then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No tracked quests saved for this character.")
		end
		return
	end

	-- Iterate through saved tracked quests and re-enable tracking
	for _, questID in ipairs(RQECharacterDB.trackedQuests) do
		if C_QuestLog.IsOnQuest(questID) then
			-- Enable tracking for the quest if it's still in the quest log
			C_QuestLog.AddQuestWatch(questID)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Restored tracking for quest:", questID)
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Tracked quest is no longer valid:", questID)
			end
		end
	end
end


-- function RQE:UpdateWaypointForStep(questID, stepIndex)
	-- local questData = RQE.getQuestData(questID)
	-- if questData and questData[stepIndex] then
		-- local stepData = questData[stepIndex]
		-- if stepData and stepData.coordinates then
			-- -- Logic to set the new waypoint
			-- RQE:OnCoordinateClicked()	--RQE:OnCoordinateClicked(stepIndex)
		-- end
	-- end
-- end


-- Obtain addon Contribution Data
function RQE.GetDataForAddon()
	if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
		RQE.db.profile.debugLoggingCheckbox = true
		RQE:ClearDebugLog()
		RQE_Contribution.GetAllContributionInfo()
		RQE.db.profile.debugLoggingCheckbox = false
		RQE.DebugLogFrame()

		C_Timer.After(2, function()
			RQE:ShowDeleteConfirmationDialog()
		end)
	else
		print("RQE Contribution addon is not presently loaded. Please request this from the author")
	end
end


-- Obtain WQ Information for Expansion: The War Within
function RQE.GetTheWarWithinWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()

	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(11)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(11)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(11)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Dragonflight
function RQE.GetDragonflightWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()

	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(10)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(10)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(10)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Shadowlands
function RQE.GetShadowlandsWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()

	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(9)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(9)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(9)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Battle for Azeroth
function RQE.GetBFAWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()

	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(8)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(8)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(8)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Legion
function RQE.GetLegionWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()

	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(7)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(7)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(7)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Misc
function RQE.GetWoDWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()
	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(6)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(6)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(6)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain WQ Information for Expansion: Misc
function RQE.MiscWQ()
	RQE.db.profile.debugLoggingCheckbox = true
	RQE:ClearDebugLog()
	local clicked = GetMouseButtonClicked()

	if IsControlKeyDown() and clicked == "LeftButton" then
		RQE_Contribution.PrintIncorrectMapIDs(5)
	elseif clicked == "LeftButton" then
		RQE_Contribution.GetMissingWQ(5)
	elseif clicked == "RightButton" then
		RQE_Contribution.GetAllWQ(5)
	else
		print("Unknown click type:", tostring(clicked))
	end

	RQE.db.profile.debugLoggingCheckbox = false
	RQE.DebugLogFrame()
end


-- Obtain Quest Objectives and Quest Description Text for quests in player log where an empty set exists for either in the DB (that will contain data and isn't a hidden/emissary quest)
function RQE.GetMissingQuestData()
	if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
		if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
			RQE.db.profile.debugLoggingCheckbox = true
			RQE:ClearDebugLog()

			RQE_Contribution:CheckMissingQuestTextData()

			-- Then also check the last accepted quest for missing NPC info
			local questID = RQE.LastAcceptedQuest
			if questID then
				local questData = RQE.getQuestData(questID)

				if questData then
					local objectives = questData.objectivesQuestText
					local description = questData.descriptionQuestText
					local npc = questData.npc

					local hasObjectives = objectives and type(objectives) == "table" and objectives[1] and objectives[1] ~= ""
					local hasDescription = description and type(description) == "table" and description[1] and description[1] ~= ""
					local missingNPC = not npc or type(npc) ~= "table" or npc[1] == nil or npc[1] == ""

					if hasObjectives and hasDescription and missingNPC then
						RQE_Contribution:CheckMissingNPCOnQuestAccept(questID)
					end
				end
			end

			RQE.db.profile.debugLoggingCheckbox = false
		end
	end
end


-- Function to obtain the quest details and print them on screen
function RQE.ObtainSuperTrackQuestDetails()
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest() or RQE.isSuperTracking
	if not isSuperTracking then return end

	C_Timer.After(0.15, function()
		if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
			if RQEFrame and RQEFrame:IsShown() and RQE.QuestIDText and RQE.QuestIDText:GetText() then
				RQE.TheSuperQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			else
				RQE.TheSuperQuestID = C_SuperTrack.GetSuperTrackedQuestID()
			end

			local questName = "Unknown Quest"
			if RQE.TheSuperQuestID and type(RQE.TheSuperQuestID) == "number" then
				questName = C_QuestLog.GetTitleForQuestID(RQE.TheSuperQuestID) or "Unknown Quest"
			end
			local messagePrefix = "QuestID (supertracked): " .. tostring(RQE.TheSuperQuestID) .. " - " .. questName

			local questData = RQE.getQuestData(RQE.TheSuperQuestID)

			if not questData then
				DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. " |cFFFFFFFF--|r |cFFFF0001[Not in DB]|r", 0.46, 0.82, 0.95)
			else
				local totalSteps = #questData
				if totalSteps == 0 then
					DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. " |cFFFFFFFF--|r |cFFFFFF00[In DB, but has no steps (need to update DB entry)]|r", 0.46, 0.82, 0.95)
				else
					DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. string.format(" |cFFFFFFFF--|r |cFF00FF00[In DB: %d step(s)]|r", totalSteps), 0.46, 0.82, 0.95)
				end
			end
		end
	end)
end


-- Function to Show Confirmation Dialog for Deleting Data
function RQE:ShowDeleteConfirmationDialog()
	-- Define the dialog structure
	StaticPopupDialogs["RQE_DELETE_CONFIRM"] = {
		text = "Are you sure you want to delete all contribution data? This action is irreversible.",
		button1 = "Delete Data",
		button2 = "Cancel",
		OnAccept = function()
			RQE:ExecuteDataDeletion()
		end,
		OnCancel = function()
			print("Data deletion canceled.")
			RQE.DataDeletedfromDBFile = false
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3, -- Avoid conflicts with other popups
	}

	-- Show the confirmation popup
	StaticPopup_Show("RQE_DELETE_CONFIRM")
end


-- Function to Show Confirmation Dialog for Reloading the UI
function RQE:ShowReloadConfirmationDialog()
	-- Define the dialog structure
	StaticPopupDialogs["RQE_RELOAD_CONFIRM"] = {
		text = "Are you sure you want to reload the UI?",
		button1 = "Reload",
		button2 = "Cancel",
		OnAccept = function()
			ReloadUI()
		end,
		OnCancel = function()
			print("Not Reloading the UI")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3, -- Avoid conflicts with other popups
	}

	-- Show the confirmation popup
	StaticPopup_Show("RQE_RELOAD_CONFIRM")
end


-- Function to Run the Data Deletion
function RQE:ExecuteDataDeletion()
	if RQE_Contribution and RQE_Contribution.DeleteAllContributionInfo then
		RQE_Contribution.DeleteAllContributionInfo()
		print("All contribution data has been deleted.")
		C_Timer.After(0.2, function()
			RQE:ShowReloadConfirmationDialog()
		end)
	else
		print("Error: Unable to delete contribution data. Function not found.")
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
	local functionName = "RQE:HandleSuperTrackedQuestUpdate()"

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
				RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 1544 ~~")
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
			-- print("~~ RQEFrame:Show: 1415 ~~")
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
		-- print("~~ RQEFrame:Show: 1546 ~~")
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


-- Helper function to toggle display of the RQEQuestFrame in the mythicScenarioMode
function RQE:UpdateTrackerVisibility()
	local inScenario = C_Scenario.IsInScenario()
	local mythicMode = self.db.profile.mythicScenarioMode
	local configWantsQuestFrame = self.db.profile.enableQuestFrame

	if not mythicMode then return end

	if InCombatLockdown() and inScenario then
		-- print(">> InCombatLockdown() – skipping UpdateTrackerVisibility")
		return
	end

	-- print(">> UpdateTrackerVisibility: inScenario =", inScenario, "| mythicMode =", mythicMode, "| configWantsQuestFrame =", configWantsQuestFrame)

	-- if not C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") then
		-- C_AddOns.LoadAddOn("Blizzard_ObjectiveTracker")
	-- end

	-- if not C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") then
		-- C_AddOns.LoadAddOn("Blizzard_ScenarioObjectiveTracker")
	-- end

	-- if not C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") then
		-- C_AddOns.LoadAddOn("Blizzard_BonusObjectiveTracker")
	-- end

	-- if not C_AddOns.IsAddOnLoaded("Blizzard_ObjectiveTracker") then
		-- C_AddOns.LoadAddOn("Blizzard_CampaignQuestObjectiveTracker")
	-- end

	if not C_AddOns.IsAddOnLoaded("Carbonite Quest") then
		if mythicMode and inScenario then
			if ObjectiveTrackerFrame and ObjectiveTrackerFrame:IsShown() then
				self.RQEQuestFrame:Hide()
			else
				print("Mythic/Scenario mode may not work correctly with current Carbonite Quests settings!\n\nGo to Carbonite addon settings > Quest Module > Watch Options\nCHECK: \"Hide Quest Watch Window\"\nUN-CHECK: \"Hide Blizzards Quest Track Window\"\nThen reload your UI via \"/reload\"")
				return
			end
		end
	end

	if mythicMode and inScenario then
		-- print(">> Scenario + MythicMode active – forcing hide RQEQuestFrame")
		RQE.forceHideRQEQuestFrame = true

		if self.RQEQuestFrame then
			-- Patch Show() so Blizzard layout code can't force show
			if not self.RQEQuestFrame._originalShow then
				self.RQEQuestFrame._originalShow = self.RQEQuestFrame.Show
			end
			self.RQEQuestFrame.Show = function() end

			if self.RQEQuestFrame:IsShown() then
				-- print(">> Hiding RQEQuestFrame")
				self.RQEQuestFrame:Hide()
			end
		end

		if ObjectiveTrackerFrame then
			-- print(">> Showing ObjectiveTrackerFrame")
			ObjectiveTrackerFrame.ignoreFramePositionManager = true
			ObjectiveTrackerFrame:SetParent(UIParent)
			ObjectiveTrackerFrame:ClearAllPoints()
			ObjectiveTrackerFrame:SetPoint("TOPRIGHT", RQEFrame, "BOTTOMRIGHT", 0, -10)	-- TO DO: change the 0, -10 to be variables to be changed in the configuration for player customization
			ObjectiveTrackerFrame:Show()
		end

		return -- Exit early to avoid post-scenario logic
	end

	-- === Post-scenario OR MythicMode disabled ===
	-- print(">> Scenario ended or MythicMode off – restoring visibility from config")
	RQE.forceHideRQEQuestFrame = false

	-- Restore original Show method if it was patched
	if self.RQEQuestFrame and self.RQEQuestFrame._originalShow then
		self.RQEQuestFrame.Show = self.RQEQuestFrame._originalShow
		self.RQEQuestFrame._originalShow = nil
	end

	if ObjectiveTrackerFrame and ObjectiveTrackerFrame:IsShown() then
		-- print(">> Hiding ObjectiveTrackerFrame")
		ObjectiveTrackerFrame:Hide()
	end

	if self.RQEQuestFrame then
		if configWantsQuestFrame then
			-- print(">> Showing RQEQuestFrame (config enabled)")
			self.RQEQuestFrame:Show()
		else
			-- print(">> Hiding RQEQuestFrame (config disabled)")
			self.RQEQuestFrame:Hide()
		end
	end

	RQE.updateScenarioUI()
end


-- Anchor the Objective Tracker to the RQEFrame
function RQE:AnchorObjectiveTracker()
	if not ObjectiveTrackerFrame or not RQEFrame then return end

	-- Tell Blizzard: STOP repositioning it
	ObjectiveTrackerFrame.ignoreFramePositionManager = true

	if ObjectiveTrackerFrame:IsUserPlaced() ~= true then
		ObjectiveTrackerFrame:SetMovable(true)
		ObjectiveTrackerFrame:SetUserPlaced(true)
	end

	-- Clear existing anchors
	ObjectiveTrackerFrame:ClearAllPoints()

	-- Anchor it under RQEFrame
	ObjectiveTrackerFrame:SetPoint("TOPRIGHT", RQEFrame, "BOTTOMRIGHT", 0, -10)

	-- Resize ObjectiveTrackerFrame to fit (optional)
	ObjectiveTrackerFrame:SetWidth(300)
	ObjectiveTrackerFrame:SetHeight(600)  -- Slightly taller for scenarios with many steps

	ObjectiveTrackerFrame.isBeingMoved = true
end


-- Hook the Objective Tracker's OnShow event to enforce the state based on visibility conditions
ObjectiveTrackerFrame:HookScript("OnShow", function()
	if not RQE.db.profile.toggleBlizzObjectiveTracker and not RQE.db.profile.mythicScenarioMode then
		if RQEFrame:IsShown() or (RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown()) then
			ObjectiveTrackerFrame:Hide()
		end
	end
end)


-- Continuous checking with OnUpdate to enforce the visibility state of the Blizzard Objective Tracker
local hideObjectiveTrackerFrame = CreateFrame("Frame")
hideObjectiveTrackerFrame:SetScript("OnUpdate", function()
	if not RQE.db.profile.toggleBlizzObjectiveTracker and not RQE.db.profile.mythicScenarioMode then
		if RQEFrame:IsShown() or (RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown()) then
			ObjectiveTrackerFrame:Hide()
		end
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
		if not RQE.db.profile.enableFrame then
			RQEFrame:Hide()
			if RQE.MagicButton then
				RQE.MagicButton:Hide()
			end
		end
	else
		if RQE.db.profile.enableFrame then
			-- print("~~ RQEFrame:Show: 1757 ~~")
			RQEFrame:Show()
			if RQE.MagicButton then
				RQE.MagicButton:Show()
			end
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
			-- elseif C_QuestLog.IsQuestTask(questID) then
				-- self.worldQuestCount = self.worldQuestCount + 1
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


-- Function to update the frame based on the current profile settings
function RQE:UpdateFramePosition()
	-- Ensure framePosition exists to avoid nil errors
	if not self.db.profile.framePosition then
		self.db.profile.framePosition = {
			xPos = -40,
			yPos = -285,
			anchorPoint = "TOPRIGHT",
			frameWidth = 420,
			frameHeight = 300
		}
	end

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


-- This function checks to see if the quest that was accepted has data in the DB that needs to be unblocked
function RQE.QuestStepsBlocked(questID)
	-- Ensure the questID is valid
	if not questID then
		return
	end

	local stepIndex = RQE.AddonSetStepIndex or 1
	local questData = RQE.getQuestData(questID)

	-- Check if questData is available
	if not questData then
		if RQE.db.profile.debugLevel == "INFO" then
			print("~~ This is a new quest for the DB ~~")
		end
		return
	end

	-- Get the total number of steps, if any
	local totalSteps = #questData
	if stepIndex == 1 and totalSteps == 0 then
		if RQE.db.profile.debugLevel == "INFO" then
			print("~~ Quest " .. questID .. " is in the DB but has no steps to display. ~~")
			PlaySound(1283)
		end
	end
end


-- Function that track quests that are in the DB but have no steps
function RQE.TrackDBQuestsWithoutSteps()
	for i = C_QuestLog.GetNumQuestWatches(), 1, -1 do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			-- print("~~~ Remove Quest Watch: 1889 ~~~")
			C_QuestLog.RemoveQuestWatch(questID)
		end
	end

	C_Timer.After(0.5, function()
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and not info.isHeader then
				local questID = info.questID
				local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
				local messagePrefix = "QuestID (displayed): " .. tostring(questID) .. " - " .. questName
				local questData = RQE.getQuestData(questID)

				if questData and #questData == 0 then
					C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Automatic)
					DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. " |cFFFFFFFF--|r |cFFFFFF00[In DB, but has no steps (need to update DB entry)]|r", 0.46, 0.82, 0.95)
				end
			end
		end
	end)
end


-- Function that track quests that are in the DB and have steps
function RQE.TrackDBQuestsWithSteps()
	for i = C_QuestLog.GetNumQuestWatches(), 1, -1 do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			-- print("~~~ Remove Quest Watch: 1918 ~~~")
			C_QuestLog.RemoveQuestWatch(questID)
		end
	end

	C_Timer.After(0.5, function()
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and not info.isHeader then
				local questID = info.questID
				local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
				local messagePrefix = "QuestID (displayed): " .. tostring(questID) .. " - " .. questName
				local questData = RQE.getQuestData(questID)

				if questData and #questData > 0 then
					C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Automatic)
					DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. string.format(" |cFFFFFFFF--|r |cFF00FF00[In DB: %d step(s)]|r", #questData), 0.46, 0.82, 0.95)
				end
			end
		end
	end)
end


-- Function that track quests that are NOT in the DB at all
function RQE.TrackQuestsNotInDB()
	for i = C_QuestLog.GetNumQuestWatches(), 1, -1 do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			-- print("~~~ Remove Quest Watch: 1947 ~~~")
			C_QuestLog.RemoveQuestWatch(questID)
		end
	end

	C_Timer.After(0.5, function()
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and not info.isHeader then
				local questID = info.questID
				local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
				local messagePrefix = "QuestID (displayed): " .. tostring(questID) .. " - " .. questName
				local questData = RQE.getQuestData(questID)

				if not questData then
					C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Automatic)
					DEFAULT_CHAT_FRAME:AddMessage(messagePrefix .. " |cFFFFFFFF--|r |cFFFF0001[Not in DB]|r", 0.46, 0.82, 0.95)
				end
			end
		end
	end)
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
	end

	if RQE.SeparateStepText then
		RQE.SeparateStepText:SetText("No step description available for this step.")
	end
end


-- Colorization of the RQEFrame
local function colorizeObjectives(questID)
	local objectivesData = C_QuestLog.GetQuestObjectives(questID)
	local colorizedText = ""
	local t = {}

	-- Check if the quest is ready for turn-in
	local isReadyForTurnIn = C_QuestLog.IsComplete(questID) and C_QuestLog.ReadyForTurnIn(questID)
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
			t[#t+1] = RQE.ColorORANGE .. "Click QuestID/QuestName to Complete Quest" .. RQE.ColorRESET .. "\n"
		end
	else
		t[#t+1] = "Objective data unavailable."
	end

	return table.concat(t)

	-- if objectivesData then  -- Check if the data is not nil
		-- for _, objective in ipairs(objectivesData) do
			-- local description = objective.text
			-- if isReadyForTurnIn then
				-- -- Entire quest is ready for turn-in, colorize all objectives in green
				-- colorizedText = colorizedText .. "|cff00ff00" .. description .. "|r |cfffffd9f (Complete)|r\n"	-- Green w/Canary 'Complete'
				-- -- colorizedText = colorizedText .. "|cff00ff00" .. description .. "|r |cffffffff(Complete)|r\n"	-- Green w/White 'Complete'
				-- -- colorizedText = colorizedText .. "|cffffff00" .. description .. " (Complete) |r\n"	-- Yellow
				-- -- colorizedText = colorizedText .. "|cff0000ff" .. description .. " (Complete) |r\n"	-- Blue
			-- else
				-- if objective.finished then
					-- -- Objective complete, colorize in green
					-- colorizedText = colorizedText .. "|cff00ff00" .. description .. "|r |cfffffd9f (Complete)|r\n"	-- Green w/Canary 'Complete'
				-- elseif objective.numFulfilled > 0 then
					-- -- Objective partially complete, colorize in yellow
					-- colorizedText = colorizedText .. "|cffffff00" .. description .. "|r\n"
				-- else
					-- -- Objective has not started or no progress, leave as white
					-- colorizedText = colorizedText .. "|cffffffff" .. description .. "|r\n"
				-- end
			-- end
		-- end
	-- else
		-- colorizedText = "Objective data unavailable."  -- Default text or handle as needed
	-- end

	-- return colorizedText
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
			RQE:ClearSeparateFocusFrame()
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
	if RQE.DontUpdateFrame then return end

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking and not RQE.searchedQuestID then return end

	-- Checks flag to see if the Blacklist underway is presently in process
	if RQE.BlacklistUnderway then return end

	RQE:CheckSuperTrackedQuestAndStep()

	-- Priority: explicit param > search override > current super-tracked
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	questID = tonumber(questID) or RQE.searchedQuestID or currentSuperTrackedQuestID

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

	-- Check if the currently super-tracked quest is different from the extractedQuestID and if manual tracking is enabled
	if RQE.ManualSuperTrack ~= true and currentSuperTrackedQuestID ~= extractedQuestID and extractedQuestID then
		-- Re-super-track the extractedQuestID
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Super-tracking incorrectly changed, swapping it back to " .. extractedQuestID)
		end
		-- print("~~~ SetSuperTrack: 2223~~~")
		C_SuperTrack.SetSuperTrackedQuestID(extractedQuestID)
		RQE:SaveSuperTrackedQuestToCharacter()
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
		questName = C_QuestLog.GetTitleForQuestID(questID)  -- Fallback to game's API call if no title is found in the databases
	end

	questName = questName or "N/A"  -- Default to "N/A" if no title found

	if RQE.QuestNameText then
		RQE.QuestNameText:SetText("Quest Name: " .. questName)
	end

	if questInfo then
		RQE.infoLog("Line 1691: questInfo.description is ", questInfo.description)
		RQE.infoLog("Line 1692: questInfo.objectives is ", questInfo.objectives)

		if RQE.CreateStepsText then  -- Check if CreateStepsText is initialized
			RQE:ClearStepsTextInFrame()
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
	if RQE.searchedQuestID then
		RQEFrame.DirectionText = DirectionText  -- Save to addon table

		if RQE.DirectionTextFrame then
			local dbEntry = RQE.getQuestData(RQE.searchedQuestID)
			local zoneName, continentName = "Unknown", "Unknown"

			if dbEntry then
				local _, _, mapID, continentID = RQE.GetPrimaryLocation(dbEntry)
				local finalMapID

				if mapID then
					finalMapID = mapID
				elseif continentID then
					-- Only fall back to continentID if player is on that continent
					local playerMapID = C_Map.GetBestMapForUnit("player")
					local pInfo = playerMapID and C_Map.GetMapInfo(playerMapID)
					local parent = pInfo and pInfo.parentMapID
					if parent == continentID then
						finalMapID = continentID
					end
				end

				if finalMapID then
					local mapInfo = C_Map.GetMapInfo(finalMapID)
					if mapInfo then
						zoneName = mapInfo.name or "Unknown"
						local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID or 0)
						if parentMapInfo then
							continentName = parentMapInfo.name or "Unknown"
						end
					end
					RQE.DirectionTextFrame:SetText("Travel to " .. zoneName .. ", " .. continentName)
				else
					RQE.DirectionTextFrame:SetText("No direction available.")
				end
			else
				RQE.DirectionTextFrame:SetText("No direction available.")
			end
		end

		RQE.DontUpdateFrame = true
	else
		local DirectionText = C_QuestLog.GetNextWaypointText(questID)
		RQEFrame.DirectionText = DirectionText  -- Save to addon table
		RQE.UnknownQuestButtonCalcNTrack()

		if RQE.DirectionTextFrame then
			RQE.DirectionTextFrame:SetText(DirectionText or "No direction available.")
		end
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


-- Function that will click the "W" button in the RQEFrame
function RQE.ClickWButton()
	RQE.UnknownQuestButton:Click()
end


-- Function that clicks the SeparateWaypointButton
function RQE.CheckAndClickSeparateWaypointButtonButton()
	if RQE.SeparateWaypointButton then
		-- Click the button if it exists
		RQE.SeparateWaypointButton:Click()
	-- else
		-- -- Debugging: Provide feedback if the button doesn't exist
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("|cffff0000Error: SeparateWaypointButton is not initialized or available.|r")
		-- end
	end
end


-- Function to check if the quest has steps or if it's not in the database and player isn't in party/raid instance
function RQE.CheckAndClickWButton()
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking then return end
	
	if InCombatLockdown() then
		RQE.CheckNClickWButtonAfterCombat = true
		return
	end

	-- Adds a check if player is in party or raid instance; if so, will not allow the function to continue further
	local isInInstance, instanceType = IsInInstance()
	if isInInstance and (instanceType == "party" or instanceType == "raid") then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is in a party or raid instance. Exiting function.")
		end
		return
	end

	-- Get the current quest ID displayed in the RQEFrame
	local questID = RQE.currentSuperTrackedQuestID or C_SuperTrack.GetSuperTrackedQuestID()

	-- Check if the quest ID exists
	if not questID or questID == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No valid quest ID found.")
		end
		return
	end

	-- Check if the quest exists in the database
	local questData = nil

	-- Search the database for the quest ID
	for expansion, quests in pairs(RQEDatabase) do
		if quests[questID] then
			questData = quests[questID]
			break
		end
	end

	-- If the quest is not in the database or it has no steps, click the "W" button
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest not found in the database. Clicking the 'W' button.")
		end
		RQE.ClickWButton()
		return
	else
		local waypointText = C_QuestLog.GetNextWaypointText(questID)
		if not waypointText then
			RQE.CheckAndClickSeparateWaypointButtonButton()
			return
		end
		return
	end

	-- If quest exists but has no steps defined, click the "W" button
	local hasSteps = false
	C_Timer.After(1, function()
		for _, step in pairs(questData) do
			if type(step) == "table" and step.description then
				hasSteps = true
				if not RQE.AddonSetStepIndex == 1 then
					return
				end

				if RQE.CheckClickWButtonPossible and RQE.AddonSetStepIndex == 1 then
					if not RQE.GreaterThanOneProgress then
						RQE:ClickWaypointButtonForIndex(1)
						RQE.CheckClickWButtonPossible = false
						RQE.GreaterThanOneProgress = false
					end
				end
				break
			end
		end

		if not hasSteps then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest found but no steps are defined. Clicking the 'W' button.")
			end
			RQE.ClickWButton()
		else
			local waypointText = C_QuestLog.GetNextWaypointText(questID)
			if not waypointText then
				RQE.CheckAndClickSeparateWaypointButtonButton()
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Quest has steps, no need to click the 'W' button.")
				end
			end
		end
	end)
end


-- Function to check for waypoint text and create a waypoint if available
function RQE:CheckAndCreateSuperTrackedQuestWaypoint()
	-- Ensure the frame is shown before proceeding
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden, skipping waypoint check")
		end
		return
	end

	-- Retrieve the currently super-tracked quest ID
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID or questID == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super-tracked quest found.")
		end
		return
	end

	-- Retrieve the Next Waypoint text
	local questData = RQE.getQuestData(questID)
	local waypointText = C_QuestLog.GetNextWaypointText(questID)
	if waypointText and waypointText ~= "" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Waypoint text found:", waypointText, "- Creating a waypoint.")
		end
		-- Call the function to create the waypoint
		if not questData then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest not found in the database. Clicking the 'W' button.")
			end
			RQE:CreateSuperTrackedQuestWaypointFromNextWaypointOnCurrentMap()
			return
		else
			RQE.CheckAndClickSeparateWaypointButtonButton()
			return
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No Next Waypoint text available for questID:", questID)
		end
	end
end


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


-- /run RQE:ShowCustomQuestTooltip(66635)
-- Function that displays a tooltip when mousing over quests in the chat log after doing a 'print questline'
function RQE:ShowCustomQuestTooltip(questID)
	local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
	local logIndex = C_QuestLog.GetLogIndexForQuestID(questID)
	local isOnQuest = C_QuestLog.IsOnQuest(questID)
	local isComplete = C_QuestLog.IsQuestFlaggedCompleted(questID) -- <- more accurate check

	-- Define status color and text
	local statusText, statusR, statusG, statusB
	if isOnQuest then
		statusText, statusR, statusG, statusB = "You are on this quest", 0, 1, 0
	elseif isComplete then
		statusText, statusR, statusG, statusB = "You have completed this quest", 0.95, 0.95, 0.7  -- Faded Yellow Color		--1, 0.65, 0
	else
		statusText, statusR, statusG, statusB = "You are not on this quest", 1, 0, 0
	end

	-- Fetch description and objective text if possible
	local questData = RQE.getQuestData(questID)
	local descriptionText = ""
	local objectivesText = ""
	local objectivesQuestText = ""

	if questData then
		if questData.descriptionQuestText and type(questData.descriptionQuestText) == "table" and questData.descriptionQuestText[1] ~= "" then
			descriptionText = questData.descriptionQuestText[1]
		end

		if questData.objectivesText and type(questData.objectivesText) == "table" and questData.objectivesText[1] ~= "" then
			objectivesText = questData.objectivesText[1]
		end

		if questData.objectivesQuestText and type(questData.objectivesQuestText) == "table" and questData.objectivesQuestText[1] ~= "" then
			objectivesQuestText = questData.objectivesQuestText[1]
		end
	end

	-- Fallback if not found in DB
	if (descriptionText == "" or objectivesText == "") and logIndex then
		local questDesc, questObjectives = GetQuestLogQuestText(logIndex)
		descriptionText = descriptionText ~= "" and descriptionText or (questDesc or "")
		objectivesText = objectivesText ~= "" and objectivesText or (questObjectives or "")
	end

	-- if logIndex then
		-- local questDesc, questObjectives = GetQuestLogQuestText(logIndex)
		-- descriptionText = questDesc or ""
		-- objectivesText = questObjectives or ""
	-- end

	local objText = GetQuestObjectiveInfo(questID, 1, false)
	local showFallbackObjective = (not objectivesText or objectivesText == "") and objText

	C_Timer.After(0.1, function()
		if not GameTooltip:IsShown() then
			GameTooltip:SetOwner(ChatFrame1, "ANCHOR_TOPRIGHT", 30, 30)

			-- 🟨 Quest title (always gold)
			GameTooltip:AddLine(questTitle, 1, 0.82, 0, true)

			-- 🔴🟢🟠 Status message
			GameTooltip:AddLine(statusText, statusR, statusG, statusB, true)

			-- 📜 Description
			if descriptionText ~= "" then
				GameTooltip:AddLine(" ", 1, 1, 1, false)
				GameTooltip:AddLine(descriptionText, 1.0, 0.75, 0.79, true)
			else
				GameTooltip:AddLine(" ", 1, 1, 1, false)
				GameTooltip:AddLine("No quest description available.", 0.8, 0.8, 0.8, true)
			end

			-- 📘 Objectives Comment (if present)
			if objectivesQuestText ~= "" then
				GameTooltip:AddLine(" ", 1, 1, 1, false)
				GameTooltip:AddLine("Objective:", 1, 0.82, 0, true)
				GameTooltip:AddLine(objectivesQuestText, 0.9, 0.95, 1, true)
			end

			-- ✅ Requirements
			if objectivesText ~= "" or showFallbackObjective then
				GameTooltip:AddLine(" ", 1, 1, 1, false)
				GameTooltip:AddLine("Requirements:", 1, 0.82, 0, true)
				if objectivesText ~= "" then
					GameTooltip:AddLine("- " .. objectivesText, 1, 1, 1, true)
				elseif showFallbackObjective then
					GameTooltip:AddLine("- " .. objText, 1, 1, 1, true)
				end
			else
				GameTooltip:AddLine(" ", 1, 1, 1, false)
				GameTooltip:AddLine("Requirements:", 1, 0.82, 0, true)
				GameTooltip:AddLine("Objective requirements unavailable", 0.8, 0.8, 0.8, true)
			end

			-- Add Rewards
			GameTooltip:AddLine(" ")
			RQE:QuestRewardsTooltip(GameTooltip, questID)

			GameTooltip:AddLine(" ", 1, 1, 1, false)
			GameTooltip:AddLine("QuestID: " .. questID, 1, 1, 0.6, true)
			GameTooltip:Show()
		end
	end)
end


-- Function to find the closest quest currently being tracked
function RQE:GetClosestTrackedQuest()
	local closestQuestID, closestDistance = nil, math.huge
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~ No valid playerMapID found. Exiting GetClosestTrackedQuest. ~~")
		end
		return
	end

	local playerPos = C_Map.GetPlayerMapPosition(playerMapID, "player")
	if not playerPos then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~ No valid player position found for mapID:", playerMapID)
		end
		return
	end

	local px, py = playerPos:GetXY()

	-- Use internal DB if distance via Blizzard fails
	local function fallbackDistanceFromDB(questID)
		local questData = RQE.getQuestData(questID)
		if questData then
			-- Loop for coord data using either coordinateHotspots or the legacy coordinates method
			for i = 1, 10 do
				local step = questData[i]
				if step then
					-- Prefer hotspots
					if step.coordinateHotspots then
						local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, i, step)
						if smap and sx and sy then
							mapID, x, y = smap, sx, sy	-- sx/sy are normalized
							break
						end
					-- Legacy single
					elseif step.coordinates
						and step.coordinates.x and step.coordinates.y and step.coordinates.mapID
					then
						mapID = step.coordinates.mapID
						x = step.coordinates.x / 100
						y = step.coordinates.y / 100
						break
					end
				end
			end
			-- for i = 1, 10 do
				-- local step = questData[i]
				-- if step and step.coordinates then
					-- return RQE:GetDistance(playerMapID, px, py, step.coordinates.mapID, step.coordinates.x / 100, step.coordinates.y / 100)
				-- end
			-- end
		end
		return math.huge
	end

	-- Iterate all watched quests
	for i = 1, C_QuestLog.GetNumQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if questID then
			local distance, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
			local finalDist = math.huge

			if distance and onContinent then
				finalDist = math.sqrt(distance)
			else
				finalDist = fallbackDistanceFromDB(questID)
			end

			if finalDist < closestDistance then
				closestDistance = finalDist
				closestQuestID = questID
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Determined closest tracked quest:", closestQuestID, "- Distance:", closestDistance)
	end

	return closestQuestID
end


-- Function to Auto Supertrack the Nearest Watched Quest
function RQE:AutoSuperTrackClosestQuest()
	if not RQE.db.profile.enableAutoSuperTrackSwap or InCombatLockdown() or UnitOnTaxi("player") then return end

	local functionName = "RQE:AutoSuperTrackClosestQuest()"

	-- -- Debounce: prevent multiple zone-change triggers within 2 seconds
	-- local now = GetTime()
	-- if RQE.LastZoneChangeTime and (now - RQE.LastZoneChangeTime) < 2 then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Debounce: Skipping AutoSuperTrackClosestQuest (zone change spam)")
		-- end
		-- return
	-- end
	-- RQE.LastZoneChangeTime = now

	-- -- Continue with delayed AutoSuperTrackClosestQuest
	-- C_Timer.After(1.0, function()
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("From ZONE_CHANGED_NEW_AREA event — tracking nearest quest.")
		-- end
		-- RQE:AutoSuperTrackClosestQuest()
	-- end)

	local closestQuestID = RQE:GetClosestTrackedQuest()
	local supertrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if closestQuestID and closestQuestID ~= 0 then
		if closestQuestID ~= supertrackedQuestID then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Supertracked questID is: " ..  supertrackedQuestID)
				print("This doesn't match with the closest questID: " .. closestQuestID)
			end
			RQE.Buttons.ClearButtonPressed()
			C_SuperTrack.SetSuperTrackedQuestID(0)

			C_Timer.After(0.3, function()
				RQE:ForceSuperTrackQuestProperly(closestQuestID)
				RQE.ClickQuestLogIndexButton(closestQuestID)
				RQE:SaveSuperTrackedQuestToCharacter()

				if RQE.db.profile.debugLevel == "INFO+" then
					print("Supertracking closest quest:", closestQuestID)
				end

				C_Timer.After(0.3, function()
					RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 3219 ~~")
					UpdateFrame()
					UpdateRQEQuestFrame()
				end)

				C_Timer.After(0.4, function()
					RQE.CheckAndClickWButton()
				end)
			end)
		end
	end
end


-- Helper function to RQE:AutoSuperTrackClosestQuest() to force the nearest quest to be supertracked
function RQE:ForceSuperTrackQuestProperly(questID)
	if not questID or questID == 0 then return end

	-- Step 1: Save all currently watched quests BEFORE nuking them
	RQE.SavedQuestWatches = {}
	local numWatches = C_QuestLog.GetNumQuestWatches()
	for i = 1, numWatches do
		local watchedQuestID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		if watchedQuestID then
			table.insert(RQE.SavedQuestWatches, watchedQuestID)
		end
	end

	-- Step 2: Remove all watched quests
	for _, qid in ipairs(RQE.SavedQuestWatches) do
		C_QuestLog.RemoveQuestWatch(qid)
	end

	-- Step 3: Add the target quest back
	C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType.Manual)

	-- Step 4: Force supertrack
	C_SuperTrack.SetSuperTrackedQuestID(questID)
	SetCVar("superTrackedQuestID", questID)

	-- Step 5: After a slight delay, re-add previously watched quests (except the one we supertracked)
	C_Timer.After(0.1, function()
		for _, qid in ipairs(RQE.SavedQuestWatches) do
			if qid ~= questID then
				C_QuestLog.AddQuestWatch(qid, Enum.QuestWatchType.Manual)
			end
		end

		-- Debug
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Restored previous watched quests (excluding supertracked):", questID)
		end
	end)

	-- Step 6: Additional delay to re-force supertracking after Blizzard refreshes
	C_Timer.After(0.1, function()
		C_SuperTrack.SetSuperTrackedQuestID(questID)
		SetCVar("superTrackedQuestID", questID)

		if RQE.db.profile.debugLevel == "INFO+" then
			print("Final forced SuperTracking quest ID after rewatch:", questID)
		end
	end)
end


-- Function to supertrack the first watched quest matching the player's current map ID
function RQE:SuperTrackFirstWatchedQuestInCurrentZone()
	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		return
	end

	local functionName = "RQE:SuperTrackFirstWatchedQuestInCurrentZone()"

	-- Helper function to get watched quest IDs
	local function GetWatchedQuestIDs()
		local watchedQuestIDs = {}

		-- Get world quest watches
		for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
			local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			if questID then
				table.insert(watchedQuestIDs, questID)
			end
		end

		-- Get regular quest watches
		for i = 1, C_QuestLog.GetNumQuestWatches() do
			local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
			if questID then
				table.insert(watchedQuestIDs, questID)
			end
		end

		return watchedQuestIDs
	end

	-- Get the list of watched quest IDs
	local watchedQuestIDs = GetWatchedQuestIDs()
	if #watchedQuestIDs == 0 then
		return
	end

	-- Iterate through the watched quests
	for _, questID in ipairs(watchedQuestIDs) do
		-- Get the map ID associated with the quest
		local questMapID = GetQuestUiMapID(questID)
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		if questMapID then
			-- Check if the quest's map ID matches the player's current map ID
			if questMapID == playerMapID then
				-- Supertrack this quest
				if not isWorldQuest then
					-- print("~~~ SetSuperTrack: 2843~~~")
					C_SuperTrack.SetSuperTrackedQuestID(questID)
					RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 3334 ~~")
					UpdateFrame()
					return
				end
			end
		end
	end

	-- If no quest is supertracked
	if RQE.db.profile.debugLevel == "INFO+" then
		print("No watched quests match the player's current map ID.")
	end
end


-- Function that tracks the closest quest on certain events in the Event Manager
function RQE.TrackClosestQuest()
	if not RQEFrame:IsShown() then return end

	local functionName = "RQE.TrackClosestQuest()"

	-- Ensure supertracking is enabled in the profile
	if RQE.db.profile.enableNearestSuperTrack or RQE.db.profile.enableNearestSuperTrackCampaign or RQE.db.profile.enableNearestSuperTrackCampaignLevelingOnly then
		-- Get the closest tracked quest ID
		local closestQuestID = RQE:GetClosestTrackedQuest()

		if RQE.db.profile.debugLevel == "INFO+" then
			print("Within TrackClosestQuest: The closest quest to your current location is " .. tostring(closestQuestID))
		end

		-- If a closest quest was found, set it as the supertracked quest
		if closestQuestID then
			-- print("~~~ SetSuperTrack: 2874~~~")
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
			RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 3379 ~~")
			UpdateFrame()
		end)

		-- Optionally scroll the frames to the top
		if RQEFrame and not RQEFrame:IsMouseOver() then
			RQE.ScrollFrameToTop()
		end
		RQE.FocusScrollFrameToTop()
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("enableNearestSuperTrack is currently disabled in Config")
		end
	end
end



function UpdateWorldQuestTrackingForMap(uiMapID)
	if not uiMapID then
		print("Invalid map ID provided to UpdateWorldQuestTrackingForMap")
		return
	end

	local taskPOIs = C_TaskQuest.GetQuestsOnMap(uiMapID)		-- The following has been implemented with 11.0.5, the previous version, C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) will be removed in the 12.0 expansion
	local trackedQuests = {}
	local maxTracked = 1
	local currentTrackedCount = 0

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
			local questID = taskPOI.questID

			-- Only proceed if the quest is a world quest (classification 10)
			if questID and RQE:IsWorldQuest(questID) then
				-- Fetch additional info to check if the quest is in the area
				local isInArea, isOnMap, numObjectives = GetTaskInfo(questID)

				if isInArea then
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Checking World QuestID: " .. questID .. " (in area)")
					end

					-- Check if the quest is already tracked
					if not trackedQuests[questID] then
						C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
						trackedQuests[questID] = true
						currentTrackedCount = currentTrackedCount + 1

						if RQE.db.profile.debugLevel == "INFO+" then
							print("Automatic World QuestID: " .. questID .. " added to watch list.")
						end

						if currentTrackedCount >= maxTracked then
							if RQE.db.profile.debugLevel == "INFO+" then
								print("Reached the maximum number of tracked World Quests: " .. maxTracked)
							end
							break
						end
					else
						if RQE.db.profile.debugLevel == "INFO+" then
							print("World QuestID: " .. questID .. " is already being tracked.")
						end
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("World QuestID: " .. questID .. " (not in area)")
					end
					C_QuestLog.RemoveWorldQuestWatch(questID)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Skipping non-World QuestID: " .. questID)
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
	local questsInArea = C_TaskQuest.GetQuestsOnMap(playerMapID)		-- The following has been implemented with 11.0.5, the previous version, C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) will be removed in the 12.0 expansion
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


-- Remove Tracking of all World Quests (called on PLAYER_LOGIN from EventManager if selected in the configuration)
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
		-- RQE:SaveSuperTrackedQuestToCharacter()
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


-- -- Function to print all widget IDs for a given setID
-- function RQE.PrintAllWidgetIDs(setID)
	-- -- Check if setID is provided
	-- if not setID then
		-- print("No setID provided. Please provide a valid setID.")
		-- return
	-- end

	-- -- Fetch all widget IDs for the given setID
	-- local widgetIDs = C_UIWidgetManager.GetAllWidgetsBySetID(setID)

	-- -- Check if widgetIDs are valid
	-- if not widgetIDs or #widgetIDs == 0 then
		-- print("No widgets found for setID:", setID)
		-- return
	-- end

	-- -- Print the widget IDs
	-- print("Widget IDs for setID:", setID)
	-- for _, widgetID in ipairs(widgetIDs) do
		-- print("Widget ID:", widgetID)
	-- end
-- end


-- -- Extracts scenario header widget timer info and prints on screen
-- function RQE.PrintScenarioHeaderInfo(widgetID)
	-- -- Check if widgetID is provided
	-- if not widgetID then
		-- print("No widgetID provided. Please provide a valid widgetID.")
		-- return
	-- end

	-- -- Fetch the widget information using the API
	-- local widgetInfo = C_UIWidgetManager.GetScenarioHeaderTimerWidgetVisualizationInfo(widgetID)

	-- -- Check if the widgetInfo is valid
	-- if not widgetInfo then
		-- print("No widget information found for widgetID:", widgetID)
		-- return
	-- end

	-- -- Print all fields returned by the API
	-- print("Scenario Header Timer Widget Info for widgetID:", widgetID)
	-- print("---------------------------------------------------")
	-- print("shownState:", widgetInfo.shownState)
	-- print("timerMin:", widgetInfo.timerMin)
	-- print("timerMax:", widgetInfo.timerMax)
	-- print("timerValue:", widgetInfo.timerValue)
	-- print("headerText:", widgetInfo.headerText or "N/A")
	-- print("timerTooltip:", widgetInfo.timerTooltip or "N/A")
	-- print("widgetSizeSetting:", widgetInfo.widgetSizeSetting)
	-- print("textureKit:", widgetInfo.textureKit or "N/A")
	-- print("frameTextureKit:", widgetInfo.frameTextureKit or "N/A")
	-- print("hasTimer:", widgetInfo.hasTimer)
	-- print("orderIndex:", widgetInfo.orderIndex)
	-- print("widgetTag:", widgetInfo.widgetTag or "N/A")
	-- print("inAnimType:", widgetInfo.inAnimType)
	-- print("outAnimType:", widgetInfo.outAnimType)
	-- print("widgetScale:", widgetInfo.widgetScale)
	-- print("layoutDirection:", widgetInfo.layoutDirection)
	-- print("modelSceneLayer:", widgetInfo.modelSceneLayer)
	-- print("scriptedAnimationEffectID:", widgetInfo.scriptedAnimationEffectID)
	-- print("---------------------------------------------------")
-- end


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

-- Table to store active events
RQE.activeEvents = {}


-- Check for TomTom load
local function TomTom_Loaded(self, event, addon)
	if addon == "TomTom" then
		self:UnregisterEvent("ADDON_LOADED")
	end
end


-- Function to populate the activeEvents table with today's events
function RQE:UpdateActiveEvents()
	-- Clear the table each time this function runs
	RQE.activeEvents = {}

	-- Get today's date
	local today = C_DateAndTime.GetCurrentCalendarTime()

	-- Loop through events for today and store them in the table
	for i = 1, C_Calendar.GetNumDayEvents(0, today.monthDay) do
		local eventInfo = C_Calendar.GetDayEvent(0, today.monthDay, i)
		if eventInfo then
			RQE.activeEvents[eventInfo.eventID] = eventInfo.title
		end
	end
end


-- Function to check if a specific eventID is active
-- /run RQE:IsEventActive(324)	-- Check to see if Hallow's End event (eventID 324) is active
function RQE:IsEventActive(eventID)
		-- Update active events to ensure we have the latest information
		RQE:UpdateActiveEvents()

	-- Check if the specified eventID is in the table
	if RQE.activeEvents[eventID] then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Event ID", eventID, "is currently active:", RQE.activeEvents[eventID])
		end
		return true
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Event ID", eventID, "is not active.")
		end
		return false
	end
end


function RQE:PopulateNextQuestInEventSeries(eventID)
	local functionName = "RQE:PopulateNextQuestInEventSeries(eventID)"

	-- Check if the eventID matches Hallow's End (324)
	if eventID ~= 324 then
		return -- Exit if it's not the right event
	end

	-- Retrieve the list of questIDs for the event
	local questList = RQE.eventQuests[eventID]
	if not questList then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quests defined for event ID:", eventID)
		end
		return
	end

	-- Iterate through the quest list to find the first incomplete quest
	for _, questID in ipairs(questList) do
		local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)

		if not isCompleted then
			-- Fetch quest information from RQEDatabase, if available
			local questInfo = RQE.getQuestData(questID) or {}

			-- If questInfo is empty, set up minimal info
			questInfo.title = questInfo.title or C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
			questInfo.description = questInfo.description or "No description available."
			questInfo.objectives = questInfo.objectives or "No objectives available."

			-- Display the quest in RQEFrame by calling UpdateFrame
			RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 4111 ~~")
			UpdateFrame(questID, questInfo)

			-- Manual fallback to populate RQEFrame if UpdateFrame does not display it
			if RQE.QuestIDText then
				RQE.QuestIDText:SetText("Quest ID: " .. (questID or "N/A"))
			end
			if RQE.QuestNameText then
				RQE.QuestNameText:SetText("Quest Name: " .. questInfo.title)
			end
			if RQE.QuestDescription then
				RQE.QuestDescription:SetText(questInfo.description)
			end
			if RQE.QuestObjectives then
				RQE.QuestObjectives:SetText(questInfo.objectives)
			end

			-- Get additional step information and display it
			local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
			if RQE.CreateStepsText then
				RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
			end

			-- Display the "W" button with coordinates from location if steps are not available
			if RQE.UnknownQuestButton then
				if questInfo.location then
					local x, y, mapID = questInfo.location.x, questInfo.location.y, questInfo.location.mapID

					-- Set up the "W" button to create a waypoint when clicked
					RQE.UnknownQuestButton:SetScript("OnClick", function()
						RQE:CreateUnknownQuestWaypointForEvent(questID, mapID)
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Waypoint set for", questInfo.title, "at", x, ",", y)
						end
					end)

					-- Set the tooltip for the "W" button to show the coordinates
					RQE.UnknownQuestButton:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText("Coordinates: " .. x .. ", " .. y)
						GameTooltip:Show()
					end)

					-- Hide the tooltip when the mouse leaves the button
					RQE.UnknownQuestButton:SetScript("OnLeave", function()
						GameTooltip:Hide()
					end)
				else
					-- Default behavior if location is unavailable
					RQE.UnknownQuestButton:SetScript("OnClick", function()
						if RQE.db.profile.debugLevel == "INFO+" then
							print("No location data available.")
						end
					end)
					RQE.UnknownQuestButton:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText("Coordinates: Not Available")
						GameTooltip:Show()
					end)
					RQE.UnknownQuestButton:SetScript("OnLeave", function()
						GameTooltip:Hide()
					end)
				end
				RQE.UnknownQuestButton:Show()
			end
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Next quest to complete for event:", questID, "-", questInfo.title)
			end
			return
		end
	end

	-- All quests completed
	if RQE.db.profile.debugLevel == "INFO+" then
		print("All event quests for event ID", eventID, "have been completed.")
	end
end


-- Register the QUEST_TURNED_IN event
local frame = CreateFrame("Frame")
frame:RegisterEvent("QUEST_TURNED_IN")

frame:SetScript("OnEvent", function(self, event, questID)
	if event == "QUEST_TURNED_IN" then
		-- Check and populate the next quest if event 324 is active
		local currentEventID = GetCurrentEventID()
		if currentEventID then
			RQE:PopulateNextQuestInEventSeries(currentEventID)
		end
		-- if currentEventID == 324 then
			-- RQE:PopulateNextQuestInEventSeries(324)
		-- end
	end
end)


-- Define a table for holiday event quest IDs
RQE.eventQuests = {
	--[324] = {12397, 13437} -- Hallow's End Holiday event
}


-- Targeting function defined
function RQE:TargetNearestQuestMob(questID)
	local mobList = RQE.QuestMobTargetData[questID]
	if not mobList then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No mob list defined for quest:", questID)
		end
		return
	end

	for i = 1, 40 do  -- Scan nameplates (you could use a different method if not using nameplates)
		local unitID = "nameplate" .. i
		if UnitExists(unitID) then
			local unitName = UnitName(unitID)
			local isDead = UnitIsDead(unitID)

			for _, mob in ipairs(mobList) do
				if unitName == mob.name then
					if (mob.mustBeAlive and not isDead) or (mob.mustBeAlive == false and isDead) then
						--TargetUnit(unitID)

						if mob.marker then
							SetRaidTarget(unitID, mob.marker)
						end

						if RQE.db.profile.debugLevel == "INFO+" then
							print("Targeted:", unitName)
						end
						return
					end
				end
			end
		end
	end
	if RQE.db.profile.debugLevel == "INFO+" then
		print("No matching mob found nearby for quest:", questID)
	end
end


-- Helper: true if the quest is relevant (supertracked, searched, watched, or in RQE's tracked sets)
function RQE:IsQuestRelevant(questID)
	if not questID then return false end
	if RQE.db.profile.debugLevel == "INFO+" then
		print("QuestID for RQE:IsQuestRelevant is " .. tostring(questID))
	end

	-- Super-tracked
	local isSuperTracking = (C_SuperTrack.IsSuperTrackingQuest and C_SuperTrack.IsSuperTrackingQuest()) or RQE.isSuperTracking
	if isSuperTracking then
		local st = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Supertracked is " .. tostring(st))
		end
		if st and st == questID then
			return true
		end
	end

	-- In quest log & watched (covers world quests too if watched)
	local logIndex = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
	if logIndex then
		if (C_QuestLog.IsQuestWatched and C_QuestLog.IsQuestWatched(questID)) or (C_QuestLog.GetQuestWatchType and C_QuestLog.GetQuestWatchType(questID)) then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest of tracked quest is " .. tostring(questID))
			end
			return true
		end
	end

	-- RQE search / tracking tables
	if RQE.searchedQuestID and RQE.searchedQuestID == questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE.searchedQuestID:")
			if questID then
				print("Searched QuestID is: " .. tostring(questID))
			end
		end
		return true
	end

	if RQE.ManuallyTrackedQuests and RQE.ManuallyTrackedQuests[questID] then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ManuallyTrackedQuests QuestID is: " .. tostring(questID))
		end
		return true
	end

	if RQE.TrackedQuests and RQE.TrackedQuests[questID] then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE.TrackedQuests:")
			if questID then
				print("TrackedQuests QuestID is: " .. tostring(questID))
			end
		end
		return true
	end

	return false
end


-- Helper function to return the texture icon for the marker
local function GetRaidMarkerIcon(marker)
	if not marker then return "" end
	return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker .. ":0|t"
end


-- Local helper: is a specific quest objective complete?
local function _IsObjectiveComplete(questID, objectiveIndex)
	if not questID or not objectiveIndex then return false end
	local objectives = C_QuestLog.GetQuestObjectives(questID)
	if not objectives or not objectives[objectiveIndex] then return false end
	return objectives[objectiveIndex].finished
end


-- Core marking logic for a given unitID (e.g., "mouseover", "target")
local function TryMarkUnit(unitID, mobList)
	if not UnitExists(unitID) then return end

	local unitName = UnitName(unitID)
	local isDead = UnitIsDead(unitID)
	local currentMarker = GetRaidTargetIndex(unitID)
	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	for _, mob in ipairs(mobList) do
		if unitName == mob.name then
			-- If mob.obj is present, skip if that quest objective is already complete
			if mob.obj and _IsObjectiveComplete(questID, mob.obj) then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Skipping marker for " .. unitName .. " (objective " .. tostring(mob.obj) .. " complete).")
				end
			else
				if (mob.mustBeAlive and not isDead) or (mob.mustBeAlive == false and isDead) then
					-- Only change the marker if it's different from what it should be
					if currentMarker ~= mob.marker then
						SetRaidTarget(unitID, mob.marker)
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Re-marked mob on " .. unitID .. ": " .. unitName .. " with " .. GetRaidMarkerIcon(mob.marker))
						end
					else
						-- Marker is already correct → skip re-marking
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Marker on " .. unitID .. " (" .. unitName .. ") is already correct.")
						end
					end
					return
				end
			end
		end
	end
end


-- Cached mob list to avoid rebuilding every mouseover
local _cachedQuestID, _cachedStepIndex, _cachedMobList = nil, nil, nil

local function GetMobListForCurrentStep(questID, stepIndex, questData)
	-- Rebuild only if questID or stepIndex changed
	if questID ~= _cachedQuestID or stepIndex ~= _cachedStepIndex then
		_cachedQuestID, _cachedStepIndex = questID, stepIndex
		_cachedMobList = {}

		if stepIndex and questData[stepIndex] and questData[stepIndex].npcTargets then
			for _, mob in ipairs(questData[stepIndex].npcTargets) do
				if mob.name then
					-- If mob.obj is present, skip if complete
					if mob.obj and _IsObjectiveComplete(questID, mob.obj) then
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Skipping mob " .. mob.name .. " (objective " .. tostring(mob.obj) .. " complete).")
						end
					else
						table.insert(_cachedMobList, mob)
					end
				end
			end
		end
	end

	return _cachedMobList or {}
end


-- Function to mark mob on mouseover or target if it matches quest mob or NPC from DB
function RQE:MarkQuestMobOnMouseover()
	if not RQE.db.profile.enableMouseOverMarking then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local usingSearch = false

	if (not questID or questID == 0) and RQE.searchedQuestID then
		questID = RQE.searchedQuestID
		usingSearch = true
	end
	if not questID or questID == 0 then return end

	local questData = RQE.getQuestData(questID)
	if not questData then return end

	local mobList = {}

	-- If using searchedQuestID (not in log), pull ALL npcTargets + npc (turn-in)
	if usingSearch then
		for _, stepData in pairs(questData) do
			if type(stepData) == "table" and stepData.npcTargets then
				for _, mob in ipairs(stepData.npcTargets) do
					if mob.name then
						table.insert(mobList, mob)
					end
				end
			end
		end

		-- Add DB.npc turn-in marker as marker 3
		if questData.npc and type(questData.npc) == "table" then
			for _, npcName in ipairs(questData.npc) do
				if npcName ~= "" then
					table.insert(mobList, {
						name = npcName,
						marker = 3,
						mustBeAlive = true
					})
				end
			end
		end

	else
		-- Quest is active and supertracked → Only use current step's npcTargets
		local stepIndex = RQE.AddonSetStepIndex or 1
		if stepIndex and questData[stepIndex] and questData[stepIndex].npcTargets then
			for _, mob in ipairs(questData[stepIndex].npcTargets) do
				if mob.name then
					-- If mob.obj is present, skip if that objective is already complete
					if mob.obj and _IsObjectiveComplete(questID, mob.obj) then
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Skipping mob " .. mob.name .. " (objective " .. tostring(mob.obj) .. " complete).")
						end
					else
						-- Extra safeguard: make sure this mob really belongs to npcTargets of this step
						for _, validMob in ipairs(questData[stepIndex].npcTargets) do
							if validMob.name == mob.name then
								table.insert(mobList, mob)
								if RQE.db.profile.debugLevel == "INFO+" then
									print("Inserted mob " .. mob.name .. " for stepIndex " .. stepIndex)
								end
								break
							end
						end
					end
				end
			end
		end
	end

	-- Run the marker logic
	TryMarkUnit("mouseover", mobList)
	TryMarkUnit("target", mobList)
end


-- Safely set a raid marker only if needed.
-- unitID: "target" (default), "mouseover", "nameplateX", etc.
-- desired: 1-8 (⭐=1, ◯=2, ◆=3, △=4, ☾=5, ◼=6, ✖=7, ☠=8)
function RQE:SetMarkerIfNeeded(unitID, desired)
	unitID = unitID or "target"
	local idx = tonumber(desired)
	if not idx or idx < 1 or idx > 8 then return false end
	if not UnitExists(unitID) then return false end

	local current = GetRaidTargetIndex(unitID)
	if current == idx then
		-- Already correct; do nothing.
		if RQE.db.profile.debugLevel == "INFO+" then
			print(("Marker already correct (%d) on %s."):format(idx, unitID))
		end
		return false
	end

	SetRaidTarget(unitID, idx)
	if RQE.db.profile.debugLevel == "INFO" then
		local name = UnitName(unitID) or unitID
		print(("Applied marker %d to %s."):format(idx, name))
	end
	return true
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


-- Parse one {item:id:name} or [item:id:name] tag (returns itemID and display name)
function RQE.ParseItemTag(text)
	if not text or text == "" then return nil end
	local id, name = text:match("{item:(%d+):([^}]+)}")
	if id then return tonumber(id), name end
	id, name = text:match("%[item:(%d+):([^%]]+)%]")
	if id then return tonumber(id), name end
	return nil
end


-- Render text by replacing tags with colored [Name]
function RQE.RenderTextWithItemTags(text)
	if not text then return text end
	text = text:gsub("{item:(%d+):([^}]+)}", "|cffffffff[%2]|r")
	text = text:gsub("%[item:(%d+):([^%]]+)%]", "|cffffffff[%2]|r")
	return text
end


-- Render rich text with multiple {item:id:name} tags and attach separate hover frames
function RQE.RenderTextWithItems(parentFrame, rawText, font, fontSize, textColor, customParent)
	if not rawText or rawText == "" or not parentFrame then return end

	-- Clean up any old hover frames
	if parentFrame._rqeSegments then
		for _, seg in ipairs(parentFrame._rqeSegments) do
			if seg.Hide then seg:Hide() end
			if seg.SetParent then seg:SetParent(nil) end
		end
	end
	parentFrame._rqeSegments = {}

	-- Replace {item:id:name} with [name] visually
	local displayText = rawText:gsub("{item:(%d+):([^}]+)}", "|cffff66cc[%2]|r")	-- The cffff66cc is a light pink color for the tooltip text
	parentFrame:SetText(displayText)

	-- Font metrics
	local fontPath, size, flags = parentFrame:GetFont()
	local measureFS = parentFrame:GetParent():CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	measureFS:SetFont(font or fontPath, fontSize or size, flags)

	local baseParent = customParent or parentFrame:GetParent() or UIParent
	local lineHeight = parentFrame:GetLineHeight()
	local yOffset, rawPos = 0, 1

	-- Helper: resolve the true owning frame name, even if deeply nested
	local function GetTopParentName(frame)
		local limit = 5 -- safety to avoid infinite loops
		local cur = frame
		while cur and limit > 0 do
			if cur.GetName and cur:GetName() then
				return cur:GetName()
			end
			cur = cur:GetParent()
			limit = limit - 1
		end
		return nil
	end

	for line in displayText:gmatch("([^\n]*)\n?") do
		if line and line ~= "" then
			local nl = rawText:find("\n", rawPos, true) or (#rawText + 1)
			local rawLine = rawText:sub(rawPos, nl - 1)
			local patternPos = 1

			while true do
				local startTag, endTag, itemID, itemName = rawLine:find("{item:(%d+):([^}]+)}", patternPos)
				if not startTag then break end
				itemID = tonumber(itemID)

				if itemID and itemName then
					local beforeText = rawLine:sub(1, startTag - 1)
					beforeText = beforeText
						:gsub("{item:%d+:[^}]+}", function(full)
							local _, _, _, nm = full:find("{item:(%d+):([^}]+)}")
							return "[" .. (nm or "?") .. "]"
						end)
						:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

					measureFS:SetText(beforeText)
					local cursorX = measureFS:GetStringWidth()

					measureFS:SetText("[" .. itemName .. "]")
					local tagWidth = measureFS:GetStringWidth()
					local maxWidth = parentFrame:GetWidth() or 400

					-- Wrapping fix: split hover across lines if it exceeds width
					if (cursorX + tagWidth) > maxWidth then
						local overflow = (cursorX + tagWidth) - maxWidth
						local firstWidth = tagWidth - overflow

						-- Part 1: end of current line
						local hover1 = CreateFrame("Button", nil, baseParent)
						hover1:EnableMouse(true)
						hover1:EnableMouseWheel(false)
						hover1:SetPropagateMouseClicks(false)
						hover1:SetPropagateMouseMotion(false)

						hover1:SetFrameStrata("TOOLTIP")
						hover1:SetFrameLevel((baseParent:GetFrameLevel() or 0) + 5 + (#parentFrame._rqeSegments))
						hover1:SetAlpha(0.01)
						hover1:SetSize(firstWidth, lineHeight)
						hover1:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", cursorX, -yOffset)
						hover1:SetScript("OnEnter", function()
							GameTooltip:SetOwner(hover1, "ANCHOR_CURSOR_RIGHT")
							GameTooltip:SetItemByID(itemID)
							local count = GetItemCount(itemID) or 0
							GameTooltip:AddLine(("You have: |cffffff00%d|r"):format(count))
							GameTooltip:Show()
						end)
						hover1:SetScript("OnLeave", function() GameTooltip:Hide() end)
						table.insert(parentFrame._rqeSegments, hover1)

						-- Part 2: start of next wrapped line
						local hover2 = CreateFrame("Button", nil, baseParent)
						hover2:EnableMouse(true)
						hover2:EnableMouseWheel(false)
						hover2:SetPropagateMouseClicks(false)
						hover2:SetPropagateMouseMotion(false)

						hover2:SetFrameStrata("TOOLTIP")
						hover2:SetFrameLevel((baseParent:GetFrameLevel() or 0) + 5 + (#parentFrame._rqeSegments))
						hover2:SetAlpha(0.01)
						hover2:SetSize(overflow, lineHeight)
						hover2:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -(yOffset + lineHeight))
						hover2:SetScript("OnEnter", hover1:GetScript("OnEnter"))
						hover2:SetScript("OnLeave", hover1:GetScript("OnLeave"))
						table.insert(parentFrame._rqeSegments, hover2)
					else
						-- Fits entirely on one line
						local hover = CreateFrame("Button", nil, baseParent)
						hover:EnableMouse(true)
						hover:EnableMouseWheel(false)
						hover:SetPropagateMouseClicks(false)
						hover:SetPropagateMouseMotion(false)

						hover:SetFrameStrata("TOOLTIP")
						hover:SetFrameLevel((baseParent:GetFrameLevel() or 0) + 5 + (#parentFrame._rqeSegments))
						hover:SetAlpha(0.01)
						hover:SetSize(tagWidth + 6, lineHeight)
						local yAdj = yOffset

						-- Use parent chain to identify which frame owns this text (even if nested)
						local parentName = GetTopParentName(parentFrame) or ""
						if parentName:find("RQE_SeparateContentFrame", 1, true) then
							-- Adaptive vertical correction: deeper lines in larger frames get a bit more offset
							local extraAdjust = 0
							if yOffset > lineHeight * 2 then
								extraAdjust = (yOffset / lineHeight) * 0.08  -- small multiplier grows with depth
							end

							-- Separate frame correction (moves tooltip hover slightly down)
							yAdj = yAdj + (lineHeight * (0.15 + extraAdjust))	-- smaller offset of x in the (x + extraAdjust) means move everything higher vertically
						end

						hover:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", cursorX, -yAdj)
						hover:SetScript("OnEnter", function()
							GameTooltip:SetOwner(hover, "ANCHOR_CURSOR_RIGHT")
							GameTooltip:SetItemByID(itemID)
							local count = C_Item.GetItemCount(itemID) or 0
							GameTooltip:AddLine(("You have: |cffffff00%d|r"):format(count))
							GameTooltip:Show()
						end)
						hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
						table.insert(parentFrame._rqeSegments, hover)
					end
				end

				patternPos = endTag + 1
			end
		end

		yOffset = yOffset + lineHeight
		local nextLine = rawText:find("\n", rawPos, true)
		rawPos = nextLine and (nextLine + 1) or (#rawText + 1)
	end

	measureFS:Hide()
end


-- Utility function for showing item tooltips on hover (for quest descriptions, etc.)
function RQE:CreateItemTooltip(frame, itemID)
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")  -- follow the mouse
		GameTooltip:SetItemByID(itemID)

		-- Append the player's current quantity in bags
		local itemName = GetItemInfo(itemID)
		if itemName then
			local count = GetItemCount(itemID, false, false) or 0
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("|cFF00FF00You have:|r " .. count, 1, 1, 1)
		end

		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end


---------------------------------------------------
-- 14. Search Module
---------------------------------------------------

RQE.SearchModule = {}

-- Function to create the Search Box with an Examine button
function RQE.SearchModule:CreateSearchBox()
	local functionName = "RQE.SearchModule:CreateSearchBox()"

	local editBox = AceGUI:Create("EditBox")
	editBox:SetLabel("Enter Quest ID, Title, Description or Objective:")
	editBox:SetWidth(350)
	editBox:SetCallback("OnEnterPressed", function(widget, event, text)
		local questID = tonumber(text)
		local foundQuestIDs = {} -- Initialize the table here to store all found quest IDs
		local inputTextLower = string.lower(text) -- Convert input text to lowercase for case-insensitive comparison

		-- Search logic modified to accumulate all matching quest IDs
		if questID then
			-- Direct use of numeric ID
			table.insert(foundQuestIDs, questID)
		else
			-- Search across all databases for matches in title, description, or objectives
			for dbName, db in pairs(RQEDatabase) do
				for id, questData in pairs(db) do
					local matchFound = false

					-- Title match
					if questData.title and string.find(string.lower(questData.title), inputTextLower) then
						matchFound = true
					end

					-- Description match
					if not matchFound and questData.descriptionQuestText and type(questData.descriptionQuestText) == "table" then
						for _, desc in ipairs(questData.descriptionQuestText) do
							if string.find(string.lower(desc), inputTextLower) then
								matchFound = true
								break
							end
						end
					end

					-- Objectives match
					if not matchFound and questData.objectivesQuestText and type(questData.objectivesQuestText) == "table" then
						for _, obj in ipairs(questData.objectivesQuestText) do
							if string.find(string.lower(obj), inputTextLower) then
								matchFound = true
								break
							end
						end
					end

					-- Step description match (checks numbered keys)
					if not matchFound then
						for k, v in pairs(questData) do
							if type(k) == "number" and type(v) == "table" and v.description then
								if string.find(string.lower(v.description), inputTextLower) then
									matchFound = true
									break
								end
							end
						end
					end

					if matchFound then
						table.insert(foundQuestIDs, id)
					end
				end
			end
		end

		-- Handling multiple found quest IDs
		for _, foundQuestID in ipairs(foundQuestIDs) do
			local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(foundQuestID)

			C_Timer.After(0.2, function()
				local questLink = GetQuestLink(foundQuestID)
				if questLink then
					print("Quest ID: " .. foundQuestID .. " - " .. questLink)
				else
					local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
					local clickableQuestTitle = format("|Hquesttip:%d|h[%s]|h", foundQuestID, questName)
					print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6" .. clickableQuestTitle .. "|r")
				end

				if isQuestCompleted then
					DEFAULT_CHAT_FRAME:AddMessage("Quest completed by character", 0, 1, 0)	-- Green text
				else
					DEFAULT_CHAT_FRAME:AddMessage("Quest not completed by character or is a repeatable quest", 1, 0, 0)	-- Red text
				end
			end)
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
		RQE.DontUpdateFrame = false -- Flag to enable the UpdateFrame to run once in order to populate field (only applicable if player had the RQEFrame populated with a different questID before doing another search)

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
			-- if questData and questData.location then
				-- -- Update the location data for the examined quest
				-- RQE.DatabaseSuperX = questData.location.x / 100
				-- RQE.DatabaseSuperY = questData.location.y / 100
				-- RQE.DatabaseSuperMapID = questData.location.mapID
			local x, y, mapID, continentID = RQE.GetPrimaryLocation(questData)
			local finalMapID

			if mapID then
				finalMapID = mapID
			elseif continentID then
				local playerMapID = C_Map.GetBestMapForUnit("player")
				local parent = playerMapID and C_Map.GetMapInfo(playerMapID).parentMapID
				if parent == continentID then
					finalMapID = continentID
				end
			end

			if x and y and finalMapID then
				RQE.DatabaseSuperX = x / 100
				RQE.DatabaseSuperY = y / 100
				RQE.DatabaseSuperMapID = finalMapID
			end

			-- Local Variables for World Quest/Quest in Log
			local isWorldQuest = C_QuestLog.IsWorldQuest(foundQuestID)
			local isQuestInLog = C_QuestLog.IsOnQuest(foundQuestID)
			local watchType = C_QuestLog.GetQuestWatchType(foundQuestID)

			-- Found a quest, now set it as the searchedQuestID
			RQE.searchedQuestID = foundQuestID
			RQE:GenerateNpcMacroIfNeeded(RQE.searchedQuestID)

			-- Super Track the Searched Quest if in the Quest Log
			if isQuestInLog then
				-- print("~~~ SetSuperTrack: 3854~~~")
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
			C_Timer.After(0.2, function()
				local questLink = GetQuestLink(foundQuestID)
				if questLink then
					print("Quest ID: " .. foundQuestID .. " - " .. questLink)
				else
					local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
					-- ⬇Custom tooltip is created
					local clickableQuestTitle = format("|Hquesttip:%d|h[%s]|h", foundQuestID, C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest")
					print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6" .. clickableQuestTitle .. "|r")
				end
			end)

			-- Call UpdateFrame to populate RQEFrame with quest details, if the quest exists in RQEDatabase
			-- This is the new line added to trigger the update based on the foundQuestID
			if questData then
				local questInfo = RQE.getQuestData(foundQuestID)
				RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 4927 ~~")
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
		-- print("~~ RQEFrame:Show: 4336 ~~")
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
	-- print(">> ToggleRQEQuestFrame called – forceHide =", RQE.forceHideRQEQuestFrame)

	if RQE.forceHideRQEQuestFrame then
		-- print(">> Force-hide is active – hiding RQEQuestFrame")
		self.RQEQuestFrame:Hide()
		return
	end

	if self.db.profile.enableQuestFrame then
		-- print(">> Config enabled – showing RQEQuestFrame")
		RQE.RQEQuestFrame:Show()
	else
		-- print(">> Config disabled – hiding RQEQuestFrame")
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
		if RQE.db.profile.debugLevel == "INFO+"  or RQE.db.profile.debugLevel == "INFO+" then
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

	C_Timer.After(1.5, function()
		RQE.CheckQuestInfoExists()	-- Clears the RQEFrame if nothing is being supertracked (as the focus frame sometimes contains data when it shouldn't)
	end)
end



-- Utility function to convert table of itemLinks to string for debug purposes
function BuildItemNames(itemLinks)
	if not itemLinks or #itemLinks == 0 then return nil end
	local itemNames = {}
	for _, itemLink in ipairs(itemLinks) do
		local itemName = GetItemInfo(itemLink)
		table.insert(itemNames, itemName)
	end
	return table.concat(itemNames, ", ")
end


-- Utility function to convert table to string for debug purposes
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


-- Utility function to check if a value exists in a table
function table.includes(tbl, value)
	for _, v in pairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
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
	-- elseif classification == Enum.QuestClassification.BonusObjective then
		-- return "BonusObjective"
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
		local desc = step and step.description or ""
		StepsText[i] = desc

		-- choose display coords from hotspots (preferred) or legacy single
		local cText, mID
		if step and step.coordinateHotspots then
			local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, i, step)
			if smap and sx and sy then
				cText = string.format("%.1f, %.1f", sx * 100, sy * 100)
				mID = smap
			end
		elseif step and step.coordinates and step.coordinates.x and step.coordinates.y and step.coordinates.mapID then
			cText = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
			mID = step.coordinates.mapID
		end

		CoordsText[i] = cText or "--"
		MapIDs[i] = mID
		questHeader[i] = desc:match("^(.-)\n") or desc

	-- for i, step in ipairs(questInfo) do
		-- StepsText[i] = step.description
		-- CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
		-- MapIDs[i] = step.coordinates.mapID
		-- questHeader[i] = step.description:match("^(.-)\n") or step.description

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


-- Retrieve all of the non-campaign/regular quests in the player's current zone
function RQE:GetAllQuestsInCurrentZone()
	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Debug: Could not determine the player's current map ID.")
		end
		return
	end
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Debug: Player Map ID:", playerMapID)
	end

	-- Get task POIs in the current zone
	local taskPOIs = C_TaskQuest.GetQuestsOnMap(playerMapID)
	if not taskPOIs or #taskPOIs == 0 then
		print("Debug: No tasks or bonus quests found in the current map.")
		return
	end
	print("Debug: Found task POIs:", #taskPOIs)

	-- Iterate through task POIs
	for _, poi in ipairs(taskPOIs) do
		local questID = poi.questID -- Extract quest ID
		if questID then
			-- Fetch quest title
			local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
			print("Task Quest Found - ID:", questID, "Title:", questTitle)
		else
			print("Debug: Task POI does not have a valid questID.")
		end
	end
end


-- Retrieve all of the bonus quests in the player's current zone to be updated to the RQEQuestFrame and placed under the RQE.QuestsFrame child
function RQE:GetBonusQuestsInCurrentZone()
	local bonusQuests = {} -- Ensure we always return a valid table
	RQE.bonusQuestCount = 0

	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Debug: Could not determine the player's current map ID.")
		end
		return bonusQuests -- Return an empty table
	end
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Debug: Player Map ID:", playerMapID)
	end

	-- Get task POIs in the current zone
	local taskPOIs = C_TaskQuest.GetQuestsOnMap(playerMapID)
	if not taskPOIs or #taskPOIs == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Debug: No tasks or bonus quests found in the current map.")
		end
		return bonusQuests -- Return an empty table
	end
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Debug: Found task POIs:", #taskPOIs)
	end

	-- Iterate through task POIs and filter by classification
	for _, poi in ipairs(taskPOIs) do
		local questID = poi.questID -- Extract quest ID
		if questID then
			local classification = C_QuestInfoSystem.GetQuestClassification(questID) or -1 -- Get classification
			if classification == 8 or classification == 9 then -- Check for BonusObjective or Threat
				local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Bonus/Threat Quest Found - ID:", questID, "Title:", questTitle, "Classification:", classification)
				end
				table.insert(bonusQuests, { questID = questID, title = questTitle })
				RQE.bonusQuestCount = RQE.bonusQuestCount + 1
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Debug: Task POI does not have a valid questID.")
			end
		end
	end

	return bonusQuests
end


-- Inspect/Print the TaskPOIs on Player's Current Map
function RQE:InspectTaskPOIs()
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		print("No Map ID Found")
		return
	end

	local taskPOIs =C_TaskQuest.GetQuestsOnMap(playerMapID)
	if not taskPOIs or #taskPOIs == 0 then
		print("No Task POIs Found")
		return
	end

	for index, poi in ipairs(taskPOIs) do
		print("Task POI [" .. index .. "]:")
		for key, value in pairs(poi) do
			print(" - " .. tostring(key) .. ":", tostring(value))
		end
	end
end


-- Function to check if the quest should be flagged as complete
function RQE:QuestComplete(questID)
	local questData = RQE.getQuestData(questID)
	if questData then
		questData.description = "Quest Complete - Follow the waypoint for quest turn-in"
		RQE:ConfigurationChanged()
	end
end


-- Function to generate frame on menu choice that will display the wowhead link for a given quest
function RQE:ShowWowheadLink(questID)
	local wowheadURL = "https://www.wowhead.com/quest=" .. questID

	-- Create and configure the frame
	local linkFrame = CreateFrame("Frame", "WowheadLinkFrame", UIParent, "BackdropTemplate")
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
	copyButton:SetText("Highlight Text")
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
	copyButton:SetText("Highlight Text")
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
		local name = C_UnitAuras.GetBuffDataByIndex("player", i)
		--local name = UnitBuff("player", i)
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
		RQE.highestCompletedObjectiveIndex = highestCompletedObjectiveIndex

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


-- Combine individual check results using `mod`
function RQE:CombineCheckResults(results, stepData)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running CombineCheckResults ~~~")
	end

	local overallResult = nil

	for i, checkData in ipairs(stepData.checks or {}) do
		local mod = checkData.mod or "" -- Modifier relationship
		local currentResult = results[i] ~= nil and results[i] or false -- Ensure `nil` is treated as `false`

		-- Combine based on mod
		if mod == "OR" then
			overallResult = overallResult or currentResult
		elseif mod == "AND" then
			overallResult = overallResult and currentResult
		elseif mod == "NOT" then
			overallResult = not currentResult
		else
			-- No modifier, use the first result as the starting point
			overallResult = currentResult
		end

		-- Ensure `overallResult` is always a boolean before printing
		overallResult = overallResult ~= nil and overallResult or false
		currentResult = currentResult ~= nil and currentResult or false

		-- Print debug information safely
		if RQE.db.profile.debugLevel == "INFO+" then
			if mod == "" then
				print("**** Check index:", i, "Mod: N/A ", "Current Result:", tostring(currentResult), "Overall Result:", tostring(overallResult))
			else
				print("**** Check index:", i, "Mod:", mod, "Current Result:", tostring(currentResult), "Overall Result:", tostring(overallResult))
			end
		end

		-- Short-circuit on AND failure
		if mod == "AND" and not overallResult then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Short-circuited on AND failure at check index:", i)
			end
			return false
		end
	end

	return overallResult
end


-- Function that creates a macro based on the current stepIndex of the current super tracked quest
function RQEMacro:CreateMacroForCurrentStep()
	if not RQE.isCheckingMacroContents then return end

	-- Retrieve the questID that is currently being supertracked
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local isInInstance, instanceType = IsInInstance()
	if not questID then
		return
	end

	if not RQE.NewZoneChange then
		-- Adds a check if player is in party or raid instance, if so, will not allow macro check to run further
		if isInInstance and (instanceType == "raid") then
		-- if isInInstance and (instanceType == "party" or instanceType == "raid") then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("isInInstance is: " .. tostring(isInInstance) .. ". instanceType is: " .. instanceType)
			end
			RQE.isCheckingMacroContents = false
			return
		end
	end

	RQE.NewZoneChange = false
	local isMacroCorrect = RQE.CheckCurrentMacroContents()

	if isMacroCorrect then
		return
	end

	RQE.isCheckingMacroContents = false

	-- -- Clears the RQEMacro before creating a fresh one	-- keeping this in place resulted in the macro being cleared too frequently and sometimes being left empty at those inappropriate times
	-- RQEMacro:ClearMacroContentByName("RQE Macro")

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


-- Helper function to check if the final step contains `funct = "CheckDBComplete"`
function RQE:HasCheckDBComplete(questData)
	local finalStepIndex = #questData
	local finalStep = questData[finalStepIndex]
	if finalStep and finalStep.funct and finalStep.funct == "CheckDBComplete" then
		return true, finalStepIndex
	end
	return false, finalStepIndex
end


-- Periodic check setup comparing with entry in RQEDatabase
function RQE:StartPeriodicChecks()
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running RQE:StartPeriodicChecks() ~~~")
	end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end
	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID() or extractedQuestID

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Current superTrackedQuestID:", superTrackedQuestID)
	end

	if not superTrackedQuestID then return end

	RQE.CheckAndClickSeparateWaypointButtonButton()	-- If this button exists and is valid it will click the button automatically at start, but might need to check that a waypoint doesn't already exist before running this call

	-- Define the function map for parent functions
	local functionMap = {
		CheckDBBuff = "CheckDBBuff",
		CheckDBDebuff = "CheckDBDebuff",
		--CheckDBModel = "CheckDBModel",	-- NYI, but meant to reduce firings from CheckDBBuff and CheckDBDebuff
		CheckDBInventory = "CheckDBInventory",
		CheckDBZoneChange = "CheckDBZoneChange",
		CheckDBObjectiveStatus = "CheckDBObjectiveStatus",
		CheckScenarioStage = "CheckScenarioStage",
		CheckScenarioCriteria = "CheckScenarioCriteria",
		CheckDBComplete = "CheckDBComplete",
	}

	local questData = self.getQuestData(superTrackedQuestID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			RQE:CheckAndCreateSuperTrackedQuestWaypoint()	-- Set the initial waypoint if there is direction text that leads the player to a different zone
			print("No quest data for superTrackedQuestID:", superTrackedQuestID)
		end
		return
	end

	local stepIndex = self.LastClickedButtonRef and self.LastClickedButtonRef.stepIndex or 1
	if RQE.db.profile.debugLevel == "INFO+" then
		print("stepIndex being evaluated:", stepIndex)
	end

	-- Handle turn-in readiness
	if C_QuestLog.ReadyForTurnIn(superTrackedQuestID) then
		local hasCheckDBComplete, finalStepIndex = self:HasCheckDBComplete(questData)
		if hasCheckDBComplete then
			local waypointText = C_QuestLog.GetNextWaypointText(superTrackedQuestID)
			if not waypointText then
				-- No Blizzard waypoint text: advance to final step and stop here.
				self:ClickWaypointButtonForIndex(finalStepIndex)
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Quest ready for turn-in. Advancing to final stepIndex:", finalStepIndex)
				end
				return
			else
				-- Blizzard is already guiding the player.
				-- Keep our logic running, but make the UI reflect the turn-in step.
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Quest ready for turn-in and waypointText present; syncing UI to final step (no auto-advance).")
				end

				-- Make RQE display step 2/2 (final) without forcing our own waypoint.
				stepIndex = finalStepIndex
				RQE.AddonSetStepIndex = finalStepIndex

				-- Refresh frames so Separate Focus shows 2/2
				if UpdateRQEQuestFrame then UpdateRQEQuestFrame() end
				if RQE.UpdateSeparateFocusFrame then RQE:UpdateSeparateFocusFrame() end

				-- Optionally, if you want your transition/portal waypoint to appear too:
				-- RQE:FindQuestZoneTransition(superTrackedQuestID)
				-- (leave commented if you only want Blizzard's arrow)
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest ready for turn-in but final step does not contain `CheckDBComplete`. No action taken.")
			end
			-- keep going
		end
	end

	-- -- Handle turn-in readiness
	-- if C_QuestLog.ReadyForTurnIn(superTrackedQuestID) then
		-- local hasCheckDBComplete, finalStepIndex = self:HasCheckDBComplete(questData)
		-- if hasCheckDBComplete then
			-- self:ClickWaypointButtonForIndex(finalStepIndex)
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Quest ready for turn-in. Advancing to final stepIndex:", finalStepIndex)
			-- end
			-- return
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Quest ready for turn-in but final step does not contain `CheckDBComplete`. No action taken.")
			-- end
		-- end
	-- end

	-- Iterate over all steps to evaluate which one should be active
	for i, stepData in ipairs(questData) do
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Evaluating stepIndex:", i)
		end

		-- Handle `check` for single-condition steps
		if stepData.check and stepData.neededAmt and stepData.funct then
			local parentFunctionName = functionMap[stepData.funct]
			if self[parentFunctionName] then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Calling function:", parentFunctionName, "for stepIndex:", i)
				end
				local funcResult = self[parentFunctionName](self, superTrackedQuestID, i, stepData.check, stepData.neededAmt)
				if funcResult then
					if RQE.db.profile.debugLevel == "INFO+" then
						print(parentFunctionName, "succeeded for stepIndex:", i, ". Advancing to the next step.")
					end
					-- Only advance if result is true
					stepIndex = i + 1
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print(parentFunctionName, "did not succeed for stepIndex:", i, ". Stopping evaluation.")
					end
					break -- Stop advancing further
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Invalid or missing function for funct:", stepData.funct)
				end
				break
			end
		end

		-- Handle `checks` for multi-condition steps
		if stepData.checks then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~~ StepData contains checks. Evaluating each check. ~~~")
			end
			local results = {}
			for j, checkData in ipairs(stepData.checks) do
				local parentFunctionName = checkData.funct
				if self[parentFunctionName] then
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Calling parent function:", parentFunctionName, "for check index:", j)
					end
					local funcResult = self[parentFunctionName](self, superTrackedQuestID, i, checkData.check, checkData.neededAmt)
					results[j] = funcResult
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Invalid or missing function for check index:", j, "funct:", checkData.funct)
					end
					results[j] = false
				end
			end

			-- Combine results using mod logic
			local allChecksPassed = self:CombineCheckResults(results, stepData)

			if allChecksPassed then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("All checks succeeded for stepIndex:", i, ". Advancing to the next step.")
				end
				stepIndex = i + 1
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Not all checks passed for stepIndex:", i)
				end
				break
			end
		end
	end

	-- Early-return if waypoint text exists AND current step is not a zone-change step
	local waypointText = C_QuestLog.GetNextWaypointText(superTrackedQuestID)
	if waypointText then
		local cur = questData[stepIndex]
		local isZoneChangeCheck = false

		if cur then
			if cur.funct == "CheckDBZoneChange" then
				isZoneChangeCheck = true
			elseif cur.checks then
				for _, checkData in ipairs(cur.checks) do
					if checkData.funct == "CheckDBZoneChange" then
						isZoneChangeCheck = true
						break
					end
				end
			end
		end

		-- if not isZoneChangeCheck then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("WaypointText present; current step has no CheckDBZoneChange -> early return.")
			-- end
			-- return
		if not isZoneChangeCheck then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("WaypointText present; suppressing waypoint creation but still updating step index.")
			end

			-- ✅ Update step index / UI without creating a waypoint
			RQE.AddonSetStepIndex = stepIndex
			local playerMapID = C_Map.GetBestMapForUnit("player")
			if UpdateRQEQuestFrame then UpdateRQEQuestFrame() end
			if RQE.UpdateSeparateFocusFrame then RQE:UpdateSeparateFocusFrame() end
			RQE:CreateUnknownQuestWaypointWithDirectionText(superTrackedQuestID, playerMapID)
			return  -- Skip waypoint creation only
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("WaypointText present; current step requires CheckDBZoneChange -> continuing periodic checks.")
			end
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("StartPeriodicChecks continuing (no waypoint text).")
		end
	end

	-- If we advanced to a new stepIndex, click the appropriate waypoint button
	if stepIndex <= #questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Setting stepIndex to:", stepIndex)
		end
		self:ClickWaypointButtonForIndex(stepIndex)
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No further steps to process.")
		end
	end

	C_Timer.After(0.15, function()
		RQE.isCheckingMacroContents = true
		RQEMacro:CreateMacroForCurrentStep()
		C_Timer.After(0.2, function()
			RQE.isCheckingMacroContents = false
		end)
	end)

	-- Final cleanup
	RQE.NewZoneChange = false
	RQE:UpdateSeparateFocusFrame()
end


-- This function will check to see if there is quest info being tracked in the RQEFrame
function RQE.CheckQuestInfoExists()
	local questID = RQE.QuestIDText and RQE.QuestIDText:GetText()

	-- Check if a valid questID was found
	if not questID then
		--print("No valid questID found in RQEFrame.")
		RQE.Buttons.ClearButtonPressed()
	end
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
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Running AdvanceQuestStep for questID:", questID, "at stepIndex:", stepIndex)
	end
	local questData = self.getQuestData(questID)

	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data available for questID:", questID)
		end
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
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Advanced to next quest step: " .. buttonIndex)
			end

			-- Update the current step index
			self.CurrentStepIndex = buttonIndex
			self.AddonSetStepIndex = buttonIndex  -- Ensures the global step index is updated correctly

			-- Call a function to automatically click the waypoint button for the next step
			self:AutoClickQuestLogIndexWaypointButton()
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("No WaypointButton found for index:", buttonIndex)
			end
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No more steps available for quest ID:", questID)
		end
	end

	-- Apply faction logic after ensuring state is consistent
	C_Timer.After(0.7, function()
		RQE:HandleFactionLogicAfterAdvance()
	end)
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
	if not button then
		return
	end

	-- Ensure the button references the correct step
	if button.stepIndex ~= index then
		button.stepIndex = index
	end

	-- Update state references
	self.LastClickedButtonRef = button
	self.CurrentStepIndex = index
	RQE.AddonSetStepIndex = index

	-- Debug log
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Clicking button at index:", index)
	end

	-- Perform button click
	button:Click()

	-- Ensure the macro and UI are refreshed only once
	C_Timer.After(1, function()
		-- Refresh the macro
		RQE.isCheckingMacroContents = true
		RQEMacro:CreateMacroForCurrentStep()
		RQE.isCheckingMacroContents = false

		-- Refresh UI (Waypoint and Focus Frames)
		RQE:OnCoordinateClicked()
		RQE.InitializeSeparateFocusFrame()

		-- Debug log
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Clicked waypoint button for AddonSetStepIndex:", RQE.AddonSetStepIndex)
		end
	end)

	-- Apply faction logic after ensuring state is consistent
	C_Timer.After(0.7, function()
		RQE:HandleFactionLogicAfterAdvance()
	end)
end


-- Function that handles the check to see if the player is Alliance or Horde when needed to be called
function RQE:HandleFactionLogicAfterAdvance()
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:HandleFactionLogicAfterAdvance ~~")
	end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then return end

	local questData = RQE.getQuestData(questID)
	if not questData then return end

	local stepIndex = RQE.AddonSetStepIndex
	local stepData = questData[stepIndex]
	if not stepData then return end

	local description = stepData.description or ""
	local englishFaction = UnitFactionGroup("player")

	-- Check faction-based skipping
	if description:find("^ALLIANCE:") and englishFaction ~= "Alliance" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not Alliance. Skipping stepIndex:", stepIndex)
		end
		RQE.AddonSetStepIndex = stepIndex + 1
		self:ClickWaypointButtonForIndex(RQE.AddonSetStepIndex)
	elseif description:find("^HORDE:") and englishFaction ~= "Horde" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not Horde. Skipping stepIndex:", stepIndex)
		end
		RQE.AddonSetStepIndex = stepIndex + 1
		self:ClickWaypointButtonForIndex(RQE.AddonSetStepIndex)
	end

	-- After faction logic, check failedfunc
	C_Timer.After(0.5, function()
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if superTrackedQuestID then
			RQE:HandleFailedFunction(superTrackedQuestID, RQE.AddonSetStepIndex)
		end
	end)
end


-- Function to handle failedfunc logic for CheckDBZoneChange
function RQE:HandleFailedFunction(questID, stepIndex)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:HandleFailedFunction ~~")
	end

	-- Get the quest data
	local questData = self.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data found for questID:", questID)
		end
		return
	end

	-- Get the current step data
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data found for stepIndex:", stepIndex)
		end
		return
	end

	-- Check for failedfunc and failedcheck
	if stepData.failedfunc and stepData.failedcheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Failed function detected for stepIndex:", stepIndex, "Failed Function:", stepData.failedfunc)
		end

		-- Call the failed function with the necessary parameters
		local failFuncResult = RQE[stepData.failedfunc] and RQE[stepData.failedfunc](self, questID, stepIndex, stepData.failedcheck, stepData.failedIndex)

		if failFuncResult then
			-- If failed function triggers, move to the failedIndex
			local failedIndex = stepData.failedIndex or 1 -- Default to step 1 if not provided
			RQE.AddonFailedSetStepIndex = failedIndex

			if RQE.db.profile.debugLevel == "INFO+" then
				print("Failure condition met. Reverting to failedIndex:", failedIndex)
			end

			self:ClickWaypointButtonForIndex(failedIndex)
			return true -- Indicate failure handling occurred
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Failed function condition not met for stepIndex:", stepIndex)
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("No failed function executed for stepIndex:", stepIndex)
	end

	return false -- No failure conditions triggered
end


-- Function will check if the player currently has a change to their portrait
function RQE.CheckDBModel(questID, stepIndex, check, neededAmt)
	-- Placeholder for the function that will control checks for the UNIT_MODEL_CHANGED event (this will reduce number of unnecessary firings of main functions
end


-- Function will check if the player currently has any of the buffs specified in the quest's check or checks field.
function RQE:CheckDBBuff(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:CheckDBBuff ~~")
	end

	-- Use provided `check` and `neededAmt` if available
	check = check or {}
	neededAmt = neededAmt or {}

	-- Evaluate `check` directly if provided
	if #check > 0 and #neededAmt > 0 then
		for i, buffName in ipairs(check) do
			local aura = C_UnitAuras.GetAuraDataBySpellName("player", buffName, "HELPFUL")
			if not aura then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("CheckDBBuff() - Buff not active:", buffName)
				end
				return false
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("CheckDBBuff() - Buff active:", buffName)
				end
			end
		end
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - All buffs matched for provided `check`.")
		end
		self:ClickWaypointButtonForIndex(stepIndex)
		return true
	end

	-- Fallback to quest data if `check` and `neededAmt` are not directly provided
	local questData = self.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - No quest data found for questID:", questID)
		end
		return false
	end

	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - No step data found for stepIndex:", stepIndex)
		end
		return false
	end

	-- Evaluate `checks` if present
	if stepData.checks then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - Using EvaluateStepChecks for multiple checks.")
		end
		local success = self:EvaluateStepChecks(questID, stepIndex)
		if success then
			self:ClickWaypointButtonForIndex(stepIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBBuff() - Buff checks succeeded. Advancing quest step.")
			end
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBBuff() - Buff checks failed.")
			end
			return false
		end
	end

	-- Evaluate single `check` from step data
	check = stepData.check or {}
	if #check == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBBuff() - No buffs to check.")
		end
		return false
	end

	for _, buffName in ipairs(check) do
		local aura = C_UnitAuras.GetAuraDataBySpellName("player", buffName, "HELPFUL")
		if aura then
			self:ClickWaypointButtonForIndex(stepIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBBuff() - Buff active:", buffName, ". Advancing quest step.")
			end
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBBuff() - Buff not active:", buffName)
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("CheckDBBuff() - No buffs matched.")
	end
	return false
end


-- Function will check if the player currently has any of the debuffs specified in the quest's check or checks field.
function RQE:CheckDBDebuff(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:CheckDBDebuff ~~")
	end

	-- Use provided `check` and `neededAmt` if available
	check = check or {}
	neededAmt = neededAmt or {}

	-- Evaluate `check` directly if provided
	if #check > 0 and #neededAmt > 0 then
		for i, debuffName in ipairs(check) do
			local aura = C_UnitAuras.GetAuraDataBySpellName("player", debuffName, "HARMFUL")
			if not aura then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("CheckDBDebuff() - Debuff not active:", debuffName)
				end
				return false
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("CheckDBDebuff() - Debuff active:", debuffName)
				end
			end
		end
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBDebuff() - All debuffs matched for provided `check`.")
		end
		self:ClickWaypointButtonForIndex(stepIndex)
		return true
	end

	-- Fallback to quest data if `check` and `neededAmt` are not directly provided
	local questData = self.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBDebuff() - No quest data found for questID:", questID)
		end
		return false
	end

	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBDebuff() - No step data found for stepIndex:", stepIndex)
		end
		return false
	end

	-- Evaluate `checks` if present
	if stepData.checks then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBDebuff() - Using EvaluateStepChecks for multiple checks.")
		end
		local success = self:EvaluateStepChecks(questID, stepIndex)
		if success then
			self:ClickWaypointButtonForIndex(stepIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBDebuff() - Debuff checks succeeded. Advancing quest step.")
			end
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBDebuff() - Debuff checks failed.")
			end
			return false
		end
	end

	-- Evaluate single `check` from step data
	check = stepData.check or {}
	if #check == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("CheckDBDebuff() - No debuffs to check.")
		end
		return false
	end

	for _, debuffName in ipairs(check) do
		local aura = C_UnitAuras.GetAuraDataBySpellName("player", debuffName, "HARMFUL")
		if aura then
			self:ClickWaypointButtonForIndex(stepIndex)
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBDebuff() - Debuff active:", debuffName, ". Advancing quest step.")
			end
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("CheckDBDebuff() - Debuff not active:", debuffName)
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("CheckDBDebuff() - No debuffs matched.")
	end
	return false
end


-- Main function to check inventory conditions (Array/Checks or Check compatible)
function RQE:CheckDBInventory(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running CheckDBInventory ~~~")
	end

	-- Ensure `check` and `neededAmt` are valid
	check = check or {}
	neededAmt = neededAmt or {}

	-- Debug print
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Evaluating check:", table.concat(check, ", "), "with neededAmt:", table.concat(neededAmt, ", "))
	end

	-- Evaluate `check` and `neededAmt` directly if provided
	if #check > 0 and #neededAmt > 0 then
		for i, condition in ipairs(check) do
			local amount = tonumber(neededAmt[i]) or 1
			local itemCount = GetItemCount(condition, false) -- Replace with your inventory check logic
			if itemCount < amount then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Inventory check failed for item:", condition, "needed:", amount, "found:", itemCount)
				end
				return false
			end
		end
		if RQE.db.profile.debugLevel == "INFO+" then
			print("All inventory conditions met for check:", table.concat(check, ", "), "neededAmt:", table.concat(neededAmt, ", "))
		end
		return true
	end

	-- Fallback to `EvaluateStepChecks` if `check` and `neededAmt` are not directly provided
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Falling back to EvaluateStepChecks for questID:", questID, "stepIndex:", stepIndex)
	end
	local success = self:EvaluateStepChecks(questID, stepIndex)
	if success then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~ Success ~")
			print("Inventory conditions met for questID:", questID, "stepIndex:", stepIndex)
		end
		return true
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~ Failure ~")
			print("Inventory conditions NOT met for questID:", questID, "stepIndex:", stepIndex)
		end
		return false
	end
end


-- Function to evaluate complex conditions recursively
function RQE:evaluateCondition(check, neededAmt)
	if type(check) == "string" then
		-- Simple case for a single item
		local itemCount = C_Item.GetItemCount(check)
		local requiredAmount = tonumber(neededAmt[1]) or 1
		return itemCount >= requiredAmount
	elseif type(check) == "table" then
		-- Handle complex nested conditions
		local operator = check[1]
		if operator == ";" then
			-- OR logic
			local orItems = { select(2, unpack(check)) }
			return self:evaluateOrCondition(orItems, neededAmt)
		elseif operator == "&" then
			-- AND logic
			local andItems = { select(2, unpack(check)) }
			return self:evaluateAndCondition(andItems, neededAmt)
		elseif operator == "!" then
			-- NOT logic
			local notItem = check[2]
			local requiredAmount = tonumber(neededAmt[1]) or 1
			return self:evaluateNotCondition(notItem, requiredAmount)
		else
			-- Default to AND logic for flat tables (e.g., {"12345", "67890"})
			return self:evaluateAndCondition(check, neededAmt)
		end
	end
end


-- Helper function to evaluate AND conditions for `check`
function RQE:evaluateAndCondition(andItems, neededAmt)
	for index, itemID in ipairs(andItems) do
		local requiredAmount = tonumber(neededAmt[index]) or 1
		local itemCount = C_Item.GetItemCount(itemID)
		if itemCount < requiredAmount then
			return false -- Fail if any condition in AND is not met
		end
	end
	return true -- Pass if all AND conditions are met
end


-- Helper function to evaluate OR conditions for `check`
function RQE:evaluateOrCondition(orItems, neededAmt)
	for index, itemID in ipairs(orItems) do
		local requiredAmount = tonumber(neededAmt[index]) or 1
		local itemCount = C_Item.GetItemCount(itemID)
		if itemCount >= requiredAmount then
			return true -- Pass if any condition in OR is met
		end
	end
	return false -- Fail if no OR conditions are met
end


-- Helper function to evaluate NOT conditions for `check`
function RQE:evaluateNotCondition(itemID, requiredAmount)
	local itemCount = C_Item.GetItemCount(itemID)
	return itemCount < requiredAmount -- Return true if the player does NOT have the required amount
end


-- Evaluate if using 'check' or 'checks' and if it is 'checks' this function will evaluate, otherwise with 'check' it will hand off to another function
function RQE:EvaluateStepChecks(questID, stepIndex)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~~ Running EvaluateStepChecks ~~~")
	end

	local questData = self.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE: No quest data for questID:", questID)
		end
		return false, nil
	end

	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE: No step data for stepIndex:", stepIndex)
		end
		return false, nil
	end

	-- Handle `checks` array for multiple checks
	if stepData.checks then
		for i, checkData in ipairs(stepData.checks) do
			local logic = checkData.logic or "AND"
			local check = checkData.check or {}
			local neededAmt = checkData.neededAmt or {}
			local functName = checkData.funct or ""

			-- Resolve the function
			local checkFunction = self[functName]
			if not checkFunction then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("RQE: Function not found for check index:", i, "logic:", logic, "functName:", functName)
				end
				return false, i
			end

			-- Evaluate the condition
			local success
			if logic == "AND" then
				success = self:EvaluateAndCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
			elseif logic == "OR" then
				success = self:EvaluateOrCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
			elseif logic == "NOT" then
				success = self:EvaluateNotCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("RQE: Unknown logic type for check index:", i, "logic:", logic)
				end
				return false, i
			end

			if not success then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("RQE: Check failed at index:", i, "logic:", logic, "check:", check, "neededAmt:", neededAmt)
				end
				return false, i -- Return the index of the failed check
			end
		end
		if RQE.db.profile.debugLevel == "INFO+" then
			print("RQE: All checks passed for stepIndex:", stepIndex)
		end
		return true, nil -- All conditions satisfied
	end

	-- Handle single `check` + `neededAmt` style
	if stepData.check and stepData.neededAmt then
		local success = self:evaluateCondition(stepData.check, stepData.neededAmt)
		return success, nil
	end

	return false, nil -- No checks to evaluate
end


-- Evaluate AND conditions for `checks`
function RQE:EvaluateAndCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
	for i, condition in ipairs(check) do
		local amount = tonumber(neededAmt[i]) or 1
		if not checkFunction(self, condition, amount, questID, stepIndex, checkData) then
			return false
		end
	end
	return true
end


-- Evaluate OR conditions for `checks`
function RQE:EvaluateOrCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
	for i, condition in ipairs(check) do
		local amount = tonumber(neededAmt[i]) or 1
		if checkFunction(self, condition, amount, questID, stepIndex, checkData) then
			return true
		end
	end
	return false
end


-- Evaluate NOT conditions for `checks`
function RQE:EvaluateNotCondition(checkFunction, check, neededAmt, questID, stepIndex, checkData)
	for i, condition in ipairs(check) do
		local amount = tonumber(neededAmt[i]) or 1
		if checkFunction(self, condition, amount, questID, stepIndex, checkData) then
			return false -- Fail if the condition is true
		end
	end
	return true
end


-- Function will check the player's current map ID against the expected map ID(s) stored in the check and failedcheck fields in the RQEDatabase (Array/Checks or Check compatible)
function RQE:CheckDBZoneChange(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:CheckDBZoneChange ~~")
	end

	-- Ensure `check` and `neededAmt` are valid
	check = check or {}
	neededAmt = neededAmt or {}

	-- Get the player's current map ID and subzone name
	local currentMapID = C_Map.GetBestMapForUnit("player")
	local currentSubZone = GetSubZoneText() or "" -- Subzone name
	local currentZone = GetZoneText() or "" -- Zone name

	-- Fall back to zone name if subzone is blank
	if currentSubZone == "" then
		currentSubZone = currentZone
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Current MapID:", tostring(currentMapID))
		print("Current SubZone:", currentSubZone)
		print("Current Zone:", currentZone)
	end

	-- Determine if `check` contains strings (subzones) or numerals (map IDs)
	local isSubZoneCheck = type(check[1]) == "string" and not tonumber(check[1])

	local questData = self.getQuestData(questID)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Valid quest data found for questID:", questID)
	end

	if not questData then
		return false -- Exit early if no quest data is found
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Valid step data found for stepIndex:", stepIndex)
	end

	local stepData = questData[stepIndex]
	if not stepData then
		return false -- Exit early if no step data is found
	end

	-- Handle subzone checks (string-based)
	if isSubZoneCheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Evaluating subzone check. Required SubZones:", table.concat(check, ", "))
		end

		for _, subZone in ipairs(check) do
			if currentSubZone == subZone then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Player is in the required subzone:", subZone)
				end
				return true -- Subzone matches
			end
		end

		-- If no match in subzone checks
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not in any of the required subzones. Current SubZone:", currentSubZone)
			print("Required SubZones:", table.concat(check, ", "))
		end
		return false
	end

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("Evaluating single check for Current MapID:", tostring(currentMapID))
		-- print("Required MapID(s):", table.concat(check, ", "))
	-- end

	-- Handle single check + neededAmt directly
	if #check > 0 then
		for _, mapID in ipairs(check) do
			if tostring(currentMapID) == tostring(mapID) then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Player is in a required zone (MapID: " .. tostring(currentMapID) .. "). Advancing to the next quest step.")
				end
				return true
			end
		end
		-- If no match is found in the single check, return false
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not in any of the required zones from single check. Current MapID:", tostring(currentMapID))
			print("Required MapID(s):", table.concat(check or {}, ", "))
		end
		return false
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Evaluating multiple checks for stepIndex:", stepIndex)
	end

	-- Handle multiple checks using EvaluateStepChecks
	if stepData.checks then
		local success = self:EvaluateStepChecks(questID, stepIndex)
		if success then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("All zone conditions satisfied for stepIndex:", stepIndex)
			end
			self:ClickWaypointButtonForIndex(stepIndex)
			return true -- Indicate successful advancement
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Zone conditions NOT satisfied for stepIndex:", stepIndex)
			end
			return false -- Indicate failure
		end
	end

	-- Handle failed zones if `failedcheck` is defined
	local failedMapIDs = stepData.failedcheck or {}
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Evaluating failed zones for Current MapID:", tostring(currentMapID))
		print("Failed MapID(s):", table.concat(failedMapIDs, ", "))
	end
	if failedMapIDs and #failedMapIDs > 0 then
		for _, mapID in ipairs(failedMapIDs) do
			if tostring(currentMapID) == tostring(mapID) then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Player is in a failed zone (MapID: " .. tostring(currentMapID) .. "). Returning failure. Current stepIndex:", stepIndex)
				end
				return false
			end
		end
	end

	-- If no match is found
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Player is not in any of the correct or failed zones. Current stepIndex:", stepIndex)
		print("Current MapID:", tostring(currentMapID),
			  "Required MapID(s):", table.concat(stepData.check or {}, ", "),
			  "Failed MapID(s):", table.concat(failedMapIDs or {}, ", "))
	end

	return false -- Default to false if no conditions are met
end


-- Function will check if the quest is ready for turn-in from what is passed by the RQEDatabase.
function RQE:CheckDBComplete(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:CheckDBComplete ~~")
	end

	-- Safeguard: if `check` is a table, extract first element as the questID override
	if type(check) == "table" and tonumber(check[1]) then
		questID = tonumber(check[1])
	end

	local isReady = C_QuestLog.ReadyForTurnIn(questID)

	if RQE.db.profile.debugLevel == "INFO+" then
		print(string.format("CheckDBComplete: Quest %d is %sready for turn-in.", questID, isReady and "" or "NOT "))
	end

	return isReady
end


-- Function to check if the player's faction is Alliance and advance the quest step if true
function RQE:CheckFactionGroupAlliance(questID, stepIndex, check, neededAmt)
	local englishFaction = UnitFactionGroup("player")

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Checking if player's faction is Alliance: " .. tostring(englishFaction))
	end

	-- Validate faction
	if englishFaction ~= "Alliance" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not Alliance, not advancing quest step.")
		end
		return false
	end

	-- Use `check` and `neededAmt` for evaluation
	check = check or {}
	neededAmt = neededAmt or {}

	-- Handle single `check`
	if #check > 0 then
		for _, condition in ipairs(check) do
			if tostring(condition) == "Alliance" then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Alliance-specific check passed. Advancing quest step.")
				end
				self:ClickWaypointButtonForIndex(stepIndex)
				return true
			end
		end
	end

	-- Handle multiple `checks`
	local questData = self.getQuestData(questID)
	local stepData = questData and questData[stepIndex]

	if stepData and stepData.checks then
		local success = self:EvaluateStepChecks(questID, stepIndex)
		if success then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("All Alliance-specific checks passed. Advancing quest step.")
			end
			self:ClickWaypointButtonForIndex(stepIndex)
			return true
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Alliance-specific checks failed or not met.")
	end
	return false
end


-- Function to check if the player's faction is Horde and advance the quest step if true
function RQE:CheckFactionGroupHorde(questID, stepIndex, check, neededAmt)
	local englishFaction = UnitFactionGroup("player")
	local currentStepIndex = RQE.AddonSetStepIndex

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Checking if player's faction is Horde:", tostring(englishFaction))
		print("Current stepIndex in function:", currentStepIndex, "Passed stepIndex:", stepIndex)
	end

	if englishFaction == "Horde" then
		if currentStepIndex == stepIndex then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Horde-specific check passed. Advancing quest step.")
			end
			self:AdvanceQuestStep(questID, stepIndex)
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Player is Horde, but stepIndex does not match. No advancement.")
			end
			return false
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Player is not Horde, not advancing quest step.")
		end
		return false
	end
end


-- Primary function to check the progress of objectives in a quest (Array/Checks or Check compatible)
function RQE:CheckDBObjectiveStatus(questID, stepIndex, check, neededAmt)
	if RQE.db.profile.debugLevel == "INFO+" then
		print("~~ Running RQE:CheckDBObjectiveStatus ~~")
	end

	-- Ensure `check` and `neededAmt` are valid
	check = check or {}
	neededAmt = neededAmt or {}

	-- Retrieve quest objectives and data
	local objectives = C_QuestLog.GetQuestObjectives(questID)
	local questData = RQE.getQuestData(questID)

	-- Early return if no quest is super-tracked or if data is missing
	if not RQE.IsQuestSuperTracked() or not questData or not objectives then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Missing quest data or objectives for questID:", questID)
		end
		return false
	end

	-- Ensure stepIndex is valid
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Invalid stepIndex:", stepIndex, "for questID:", questID)
		end
		return false
	end

	-- Handle `check` and `neededAmt` explicitly
	if #check > 0 and #neededAmt > 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Evaluating check:", table.concat(check, ", "), "with neededAmt:", table.concat(neededAmt, ", "))
		end
		for i, condition in ipairs(check) do
			local amount = tonumber(neededAmt[i]) or 1
			local objectiveIndex = stepData.objectiveIndex or 1 -- Use the objectiveIndex from stepData
			local objective = objectives[objectiveIndex]

			-- Determine the objective type
			local _, objectiveType, _, fulfilled, required = GetQuestObjectiveInfo(questID, objectiveIndex, false)

			-- Check if the objective is a progress bar
			if objectiveType == "progressbar" then
				local progress = GetQuestProgressBarPercent(questID) -- Get the progress percentage

				if RQE.db.profile.debugLevel == "INFO+" then
					print(string.format("Quest %d Objective %d is a progress bar: %d%% complete (Required: %d%%)", questID, objectiveIndex, progress, amount))
				end

				-- Treat 1% as 100% if that's all Blizzard gives us
				if amount == 1 then
					if RQE.db.profile.debugLevel == "INFO+" then
						print("needAmt is exactly 1, likely full — treating as 100%.")
					end
					amount = 100
				elseif amount == 0.01 then
					if RQE.db.profile.debugLevel == "INFO+" then
						print("needAmt is exactly 0.01, — treating as 1%.")
					end
					amount = 1
				end

				-- Return true if progress is equal to or greater than neededAmt (now representing percentage)
				if progress >= amount then
					return true
				else
					return false
				end
			else
				-- Regular check for other objective types (fallback)
				if not objective then
					return false
				end

				-- Enhanced evaluation logic that ensures both fulfillment and status
				if not objective then
					return false
				end

				local fulfilled = objective.numFulfilled or 0
				local required = amount or 1

				-- Only enforce .finished if this step requires full completion
				local enforceFinished = (fulfilled >= objective.numRequired)
				--local needsFinished = true -- Always require .finished for safety

				-- Debug info before deciding
				if RQE.db.profile.debugLevel == "INFO+" then
					print(string.format("Evaluating Objective %d: %s - Fulfilled: %d/%d - Finished: %s",
						objectiveIndex,
						objective.text or "N/A",
						fulfilled,
						required,
						objective.numRequired or -1,
						tostring(objective.finished),
						tostring(enforceFinished)
					))
				end

				if fulfilled < required then
					return false
				end

				if enforceFinished and not objective.finished then
					return false
				end

				return true
			end
		end
		if RQE.db.profile.debugLevel == "INFO+" then
			print("All objective conditions met for check:", table.concat(check, ", "), "neededAmt:", table.concat(neededAmt, ", "))
		end
		return true
	end

	-- Dynamically determine the correct step to advance to
	local correctStepIndex = 1
	for i, step in ipairs(questData) do
		local objectiveIndex = step.objectiveIndex or 1
		local neededAmount = step.neededAmt and tonumber(step.neededAmt[1]) or 1
		local objective = objectives[objectiveIndex]

		if objective then
			if objective.finished or objective.numFulfilled >= neededAmount then
				correctStepIndex = i + 1
			elseif objective.numFulfilled < neededAmount then
				correctStepIndex = i
				break
			end
		else
			correctStepIndex = i -- Handle cases where objectives might be missing
			break
		end
	end

	-- Ensure correctStepIndex does not exceed the number of steps
	correctStepIndex = math.min(correctStepIndex, #questData)

	-- If the stepIndex doesn't match the expected step, click the correct button
	if correctStepIndex ~= stepIndex then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Adjusted to correctStepIndex:", correctStepIndex, "from stepIndex:", stepIndex)
		end
		self:ClickWaypointButtonForIndex(correctStepIndex)
		return true
	end

	-- Handle `checks` if defined for the current step
	if stepData.checks then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Step contains multiple checks. Evaluating each check.")
		end
		local success = self:EvaluateStepChecks(questID, stepIndex)
		if success then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Objective checks met for stepIndex:", stepIndex)
			end
			self:AdvanceQuestStep(questID, stepIndex)
			return true
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Objective checks NOT met for stepIndex:", stepIndex)
			end
			return false
		end
	end

	-- Fallback if no conditions matched
	if RQE.db.profile.debugLevel == "INFO+" then
		print("No conditions met for questID:", questID, "stepIndex:", stepIndex)
	end
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


-- -- Function to check scenario criteria progress (Array/Checks or Check compatible)
-- function RQE:CheckScenarioCriteria(questID, stepIndex, check, neededAmt)
	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("~~ Running RQE:CheckScenarioCriteria ~~")
	-- end

	-- -- Ensure the player is in a scenario
	-- if not C_Scenario.IsInScenario() then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - Player is not in a scenario.")
		-- end
		-- return false
	-- end

	-- -- Fetch general scenario information
	-- local scenarioInfo = C_ScenarioInfo.GetScenarioInfo()
	-- if not scenarioInfo then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - No active scenario information available.")
		-- end
		-- return false
	-- end

	-- -- Use provided `check` and `neededAmt` if available
	-- check = check or {}
	-- neededAmt = neededAmt or {}

	-- -- Evaluate `check` directly if provided
	-- if #check > 0 and #neededAmt > 0 then
		-- for i, criteriaIndex in ipairs(check) do
			-- local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(tonumber(criteriaIndex))
			-- if criteriaInfo then
				-- if criteriaInfo.quantity < tonumber(neededAmt[i] or criteriaInfo.totalQuantity) then
					-- if RQE.db.profile.debugLevel == "INFO+" then
						-- print("CheckScenarioCriteria() - Criteria " .. criteriaIndex .. " not yet met. Progress:", criteriaInfo.quantity, "/", neededAmt[i])
					-- end
					-- return false
				-- end
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("CheckScenarioCriteria() - Invalid criteria index:", criteriaIndex)
				-- end
				-- return false
			-- end
		-- end
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - All criteria checks met.")
		-- end
		-- self:ClickWaypointButtonForIndex(stepIndex)
		-- return true
	-- end

	-- -- Fallback to quest data if `check` and `neededAmt` are not provided
	-- local questData = self.getQuestData(questID)
	-- if not questData then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - No quest data found for quest ID:", questID)
		-- end
		-- return false
	-- end

	-- local stepData = questData[stepIndex]
	-- if not stepData then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - No step data found for quest ID:", questID)
		-- end
		-- return false
	-- end

	-- -- Handle multiple `checks`
	-- if stepData.checks then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("CheckScenarioCriteria() - Using EvaluateStepChecks for multiple checks.")
		-- end
		-- local success = self:EvaluateStepChecks(questID, stepIndex)
		-- if success then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CheckScenarioCriteria() - Scenario criteria checks met for stepIndex:", stepIndex)
			-- end
			-- self:ClickWaypointButtonForIndex(stepIndex)
			-- return true
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CheckScenarioCriteria() - Scenario criteria checks NOT met for stepIndex:", stepIndex)
			-- end
			-- return false
		-- end
	-- end

	-- -- Check single scenario criteria
	-- local numCriteria = select(3, C_Scenario.GetStepInfo())
	-- for criteriaIndex = 1, numCriteria do
		-- local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		-- if criteriaInfo and criteriaInfo.quantity >= criteriaInfo.totalQuantity then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("CheckScenarioCriteria() - Scenario criteria met. Advancing to next step.")
			-- end
			-- self:ClickWaypointButtonForIndex(stepIndex)
			-- return true
		-- end
	-- end

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("CheckScenarioCriteria() - Scenario criteria not yet met.")
	-- end
	-- return false
-- end


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
				-- print("~~~ Remove Quest Watch: 7289 ~~~")
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
				-- print("~~~ Remove Quest Watch: 7314 ~~~")
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
		-- print("~~~ Remove Quest Watch: 7359 ~~~")
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
			-- print("~~~ Remove Quest Watch: 7436 ~~~")
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
			-- print("~~~ Remove Quest Watch: 7517 ~~~")
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
				-- print("~~~ Remove Quest Watch: 7600 ~~~")
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
				-- print("~~~ Remove Quest Watch: 7711 ~~~")
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
		print("Starting MapID:", questLineInfo.startMapID)
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
			-- print("~~~ Remove Quest Watch: 7854 ~~~")
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
	if RQE.PrintQuestDetailsSuccess then return end
	if RQE.RePrintQuestDetailAttempts > 1 then return end

	if not RQE.PrintQuestDetails then
		RQE.PrintQuestDetails = 1 -- Initialize state if not set
	end

	C_Timer.After(0.4, function()
		local questIDs = C_QuestLine.GetQuestLineQuests(questLineID)
		local questDetails = {}
		local questsToLoad = #questIDs -- Number of quests to load data for

		local questLineName = "Unknown Questline"
		if #questIDs > 0 then
			local lineInfo = C_QuestLine.GetQuestLineInfo(questIDs[1])
			if lineInfo and lineInfo.questLineName then
				questLineName = lineInfo.questLineName
			end
		end

		if questsToLoad > 0 then
			if RQE.PrintQuestDetails == 1 then
				RQE.debugLog("|cFFFFA500Questline ID " .. questLineID .. " data is being retrieved...|r")

				-- Delay second run
				C_Timer.After(0.8, function()
					if RQE.PrintQuestDetails == 1 then
						RQE.PrintQuestDetails = 2
						RQE.PrintQuestLineFailed = true
					end
				end)
			end

			if not RQE.PrintQuestLineFailed then
				print("|cFFFFA500Quests in Questline ID " .. questLineID .. ": " .. questLineName .. "|r")
			end

			for i, questID in ipairs(questIDs) do
				local questTitle = C_QuestLog.GetTitleForQuestID(questID) or "Loading..."
				if questTitle == "Loading..." then
					RQE.PrintQuestLineFailed = true
				end

				C_Timer.After(0.7, function()
					local questLink = GetQuestLink(questID)
					if questLink then
						questDetails[i] = "|cFFADD8E6" .. i .. ". Quest# " .. questID .. " - " .. questLink .. "|r"
					else
						local clickableQuestTitle = format("|Hquesttip:%d|h[%s]|h", questID, questTitle)
						questDetails[i] = string.format("|cFFADD8E6%d. Quest# %d - %s|r", i, questID, clickableQuestTitle)
					end

					-- Retry if still loading on first pass
					if RQE.PrintQuestLineFailed then
						RQE.RePrintQuestDetailAttempts = RQE.RePrintQuestDetailAttempts + 1
						if RQE.RePrintQuestDetailAttempts == 1 then
							RQE.PrintQuestlineDetails(questLineID)
							return
						end
					end

					-- Print when all data loaded
					questsToLoad = questsToLoad - 1
					if questsToLoad <= 0 then
						for j = 1, #questDetails do
							print(questDetails[j])
						end
						RQE.PrintQuestDetailsSuccess = true
					end
				end)
			end
		end
	end)
end


-- Custom handler for clickable quest titles
hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
	local linkType, questID = strsplit(":", link)
	if linkType == "questtip" then
		questID = tonumber(questID)
		if questID then
			RQE:ShowCustomQuestTooltip(questID)
		end
	end
end)


-- Returns the available quests at a quest giver when GOSSIP_SHOW is called from EventManager
function RQE.GetAvailableQuests()
	-- Fetch the available quests using the Gossip API
	local availableQuests = C_GossipInfo.GetAvailableQuests()

	-- Check if there are available quests
	if not availableQuests or #availableQuests == 0 then
		return
	end

	-- Iterate through the available quests and print their questID and title
	print("|cFFFFA500Available quests at the quest giver:|r")	-- Printed in orange
	for _, questInfo in ipairs(availableQuests) do
		print("|cffffff00Quest ID: " .. questInfo.questID .. " - |r|cFFADD8E6[" .. questInfo.title .. "]|r")	-- Printed in gold for the questID and light blue for the title
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

-- Movement-driven waypoint refresh (integer % cells)
local updAccum = updAccum or 0
local lastGridMap, lastGridX, lastGridY

-- OnUpdate function to be triggered while moving
local function OnPlayerMoving(self, elapsed)
	RQE:UpdateCoordinates()
	RQE:UpdateMapIDDisplay()
	--RQE:MaybeUpdateWaypointOnSnap(elapsed)

	-- Throttle: ~4x/sec while moving
	updAccum = (updAccum or 0) + (elapsed or 0)
	if updAccum < 0.25 then return end
	updAccum = 0

	-- Only care if something is super-tracked
	if not (C_SuperTrack.IsSuperTrackingQuest and C_SuperTrack.IsSuperTrackingQuest()) then
		return
	end

	-- Player pos in normalized space
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return end
	local px, py = pos:GetXY()
	if not (px and py) then return end

	-- “Integer percent” grid (e.g. 42.72 -> 42)
	local gx = math.floor(px * 100 + 0.0001)
	local gy = math.floor(py * 100 + 0.0001)

	-- Only re-evaluate when the grid cell OR map changed
	if lastGridMap ~= mapID or lastGridX ~= gx or lastGridY ~= gy then
		lastGridMap, lastGridX, lastGridY = mapID, gx, gy

		-- This will only replace the live waypoint if the chosen hotspot changed.
		if RQE.EnsureWaypointForSupertracked then
			RQE:EnsureWaypointForSupertracked()
		end
	end
end


-- Function to start the OnUpdate script
function RQE:StartUpdatingCoordinates()
	if not isMoving then
		updAccum, lastGridMap, lastGridX, lastGridY = 0, nil, nil, nil
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


-- Prints the quests that are on the current player map
function RQE.GetWorldMapQuests()
	-- Get the player's current map ID
	local playerMapID = C_Map.GetBestMapForUnit("player")

	-- Check if playerMapID is valid
	if not playerMapID then
		print("Unable to get player's map ID.")
		return
	end

	-- Fetch quests on the current map
	local quests = C_TaskQuest.GetQuestsOnMap(playerMapID)

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


-- Removes Automatic WQ when leaving area of WQ location
function RQE.UntrackAutomaticWorldQuests()
	local playerMapID = C_Map.GetBestMapForUnit("player")
	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	local questsInArea = C_TaskQuest.GetQuestsOnMap(playerMapID)		-- The following has been implemented with 11.0.5, the previous version, C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) will be removed in the 12.0 expansion
	local questsInAreaLookup = {}

	if questsInArea then
		for _, taskPOI in ipairs(questsInArea) do
			if taskPOI.questID then
				questsInAreaLookup[taskPOI.questID] = true
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Quest found in area: " .. taskPOI.questID)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Invalid task POI with no questID.")
				end
			end
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quests found in the current area.")
		end
	end

	for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
		local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
		if questID then
			local watchType = C_QuestLog.GetQuestWatchType(questID)

			if watchType == Enum.QuestWatchType.Automatic then
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


function RQE.UntrackAutomaticWorldQuestsByMap()
	local playerMapID = C_Map.GetBestMapForUnit("player")

	if not playerMapID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Unable to get player's map ID.")
		end
		return
	end

	local mapQuests = C_QuestLog.GetQuestsOnMap(playerMapID)
	local mapQuestsLookup = {}
	for _, quest in ipairs(mapQuests) do
		mapQuestsLookup[quest.questID] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Map Quest ID: " .. quest.questID .. " at (" .. quest.x .. ", " .. quest.y .. ")")
		end
	end

	local questsInArea = C_TaskQuest.GetQuestsOnMap(playerMapID)		-- The following has been implemented with 11.0.5, the previous version, C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) will be removed in the 12.0 expansion
	local questsInAreaLookup = {}
	for _, taskPOI in ipairs(questsInArea) do
		questsInAreaLookup[taskPOI.questID] = true
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Quest ID in area: " .. taskPOI.questID)
		end
	end

	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	local visibleQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		visibleQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

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

			if watchType == Enum.QuestWatchType.Automatic then
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
	if InCombatLockdown() then return end

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


-- Function to toggle script profiling and prompt for reload
function RQE:ToggleCPUProfiling()
	local currentSetting = GetCVar("scriptProfile") == "1"
	local newSetting = currentSetting and "0" or "1"
	
	-- Set the new profiling value
	SetCVar("scriptProfile", newSetting)

	-- Message for the dialog box
	local message = (newSetting == "1") 
		and "CPU Profiling has been ENABLED. A reload is required for changes to take effect."
		or "CPU Profiling has been DISABLED. A reload is required for changes to take effect."

	-- Show confirmation popup
	StaticPopupDialogs["RQE_CPU_PROFILING_TOGGLE"] = {
		text = message,
		button1 = "Reload UI",
		button2 = "Cancel",
		OnAccept = function()
			ReloadUI()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}

	-- Show the popup
	StaticPopup_Show("RQE_CPU_PROFILING_TOGGLE")
end


-- Function to check the CPU usage of the addon
function RQE:CheckCPUUsage()
	if GetCVar("scriptProfile") == "1" then
		if RQE.db and RQE.db.profile.displayRQEcpuUsage then
			-- Ensure CPU tracking is updated
			UpdateAddOnCPUUsage()

			-- Fetch CPU usage
			local cpuUsage = GetAddOnCPUUsage("RQE")

			-- Ensure CPU usage is calculated as a percentage
			local totalCPU = 0
			for i = 1, C_AddOns.GetNumAddOns() do
				totalCPU = totalCPU + GetAddOnCPUUsage(i)
			end

			-- Calculate percentage usage
			local cpuUsagePercent = (totalCPU > 0) and ((cpuUsage / totalCPU) * 1000) or 0

			-- Create the display string
			if cpuUsagePercent > 0 then
				RQE.cpuUsageText = string.format("CPU Usage: %.2f%%", cpuUsagePercent)
			else
				RQE.cpuUsageText = "CPU Usage: 0.00%"  -- Default display if 0%
			end

			-- Update the display text
			if RQEFrame and RQEFrame.CPUUsageText then
				RQEFrame.CPUUsageText:SetText(RQE.cpuUsageText)
			end
		else
			-- Hide if disabled in settings
			if RQEFrame and RQEFrame.CPUUsageText then
				RQEFrame.CPUUsageText:SetText("")
			end
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
		RQE.memUsageText = memUsageText
		if memUsage > 1000 then
			RQE.memUsageText = string.format("RQE Memory usage: %.2f MB", memUsage / 1024)
		else
			RQE.memUsageText = string.format("RQE Memory usage: %.2f KB", memUsage)
		end

		-- Update the MemoryUsageText FontString with the new memory usage
		if RQEFrame and RQEFrame.MemoryUsageText then
			RQEFrame.MemoryUsageText:SetText(RQE.memUsageText)
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


-- Function to update the recipe tracking frame with the tracked recipe info
function RQE:UpdateRecipeTrackingFrame(recipeID)
	local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
	if not recipeInfo then
		print("Recipe info not found for recipeID:", recipeID)
		return
	end

	-- Get recipe name and output item data
	local recipeName = recipeInfo.name
	local outputData = C_TradeSkillUI.GetRecipeOutputItemData(recipeID)

	-- Get reagents
	local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, recipeInfo.unlockedRecipeLevel)
	local reagents = {}
	local seenReagentNames = {}
		
	if schematic and schematic.reagentSlotSchematics then
		for _, slotSchematic in ipairs(schematic.reagentSlotSchematics) do
			local isBasic = slotSchematic.reagentType == Enum.CraftingReagentType.Basic
			local isSpark = slotSchematic.reagentType == Enum.CraftingReagentType.Modifying
				and slotSchematic.slotInfo
				and slotSchematic.slotInfo.name
				and slotSchematic.slotInfo.name:lower():find("spark")

			if isBasic or isSpark then
				local addedName = false

				for _, reagent in ipairs(slotSchematic.reagents) do
					local itemID = reagent.itemID
					local name = itemID and C_Item.GetItemInfo(itemID)

					if not name then
						name = slotSchematic.slotInfo and slotSchematic.slotInfo.name or "Unknown Reagent"
					end

					if name and not seenReagentNames[name] then
						table.insert(reagents, {
							name = name,
							required = slotSchematic.quantityRequired,
							playerCount = itemID and C_Item.GetItemCount(itemID) or 0
						})
						seenReagentNames[name] = true
						addedName = true
					end
				end

				if not addedName then
					local fallbackName = slotSchematic.slotInfo and slotSchematic.slotInfo.name
					if fallbackName and not seenReagentNames[fallbackName] then
						table.insert(reagents, {
							name = fallbackName,
							required = slotSchematic.quantityRequired,
							playerCount = 0
						})
						seenReagentNames[fallbackName] = true
					end
				end
			end
		end
	end

	-- Display the recipe info on the frame
	if not RQE.recipeTrackingFrame.recipeText then
		RQE.recipeTrackingFrame.recipeText = RQE.recipeTrackingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		RQE.recipeTrackingFrame.recipeText:SetPoint("TOPLEFT", RQE.recipeTrackingFrame, "TOPLEFT", 10, -10)
	end
	RQE.recipeTrackingFrame.recipeText:SetText(recipeName)

	-- Display the reagents info on the frame
	if not RQE.recipeTrackingFrame.reagentsText then
		RQE.recipeTrackingFrame.reagentsText = RQE.recipeTrackingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		RQE.recipeTrackingFrame.reagentsText:SetPoint("TOPLEFT", RQE.recipeTrackingFrame.recipeText, "BOTTOMLEFT", 0, -10)
	end
	local reagentString = ""
	for _, reagent in ipairs(reagents) do
		reagentString = reagentString .. string.format("%s: %d/%d\n", reagent.name, reagent.playerCount, reagent.required)
	end
	RQE.recipeTrackingFrame.reagentsText:SetText(reagentString)

	-- Show the frame
	RQE.recipeTrackingFrame:Show()
end


-- -- Smart crafting function: crafts a specified number, or determines remaining amount via quest objectives if 'x' is passed
-- function RQE:CraftRecipeSmart(spellID, quantity)
	-- if not spellID then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Crafting failed: No spellID provided.")
		-- end
		-- return
	-- end

	-- local amountToCraft

	-- if type(quantity) == "number" and quantity > 0 then
		-- amountToCraft = quantity

	-- elseif quantity == "x" or tostring(quantity or "x") == "x" then
		-- local questID = C_SuperTrack.GetSuperTrackedQuestID()
		-- if not questID or questID == 0 then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("No supertracked quest found for dynamic crafting.")
			-- end
			-- return
		-- end

		-- local text = select(1, GetQuestObjectiveInfo(questID, 1, false)) or ""
		-- local fulfilled, required = string.match(text, "(%d+)%s*/%s*(%d+)")
		-- fulfilled = tonumber(fulfilled)
		-- required = tonumber(required)

		-- if not fulfilled or not required then
			-- if RQE.db.profile.debugLevel == "INFO" then
				-- print("Could not parse crafting requirement from objective text:", text)
			-- end
			-- return
		-- end

		-- amountToCraft = required - fulfilled
		-- if amountToCraft <= 0 then
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Objective already fulfilled or no crafting needed.")
			-- end
			-- return
		-- end

		-- if RQE.db.profile.debugLevel == "INFO" then
			-- print("Crafting quantity resolved from quest: " .. amountToCraft)
		-- end

	-- else
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Invalid quantity value passed to CraftRecipeSmart.")
		-- end
		-- return
	-- end

	-- if amountToCraft and amountToCraft > 0 then
		-- C_TradeSkillUI.CraftRecipe(spellID, amountToCraft)

		-- if RQE.db.profile.debugLevel == "INFO" then
			-- print("Crafting " .. amountToCraft .. " item(s) for spellID: " .. spellID)
		-- end
	-- end
-- end


-- Craft Specific Item for Quest
function RQE:CraftSpecificItem(recipeSpellID)
	if RQE.db.profile.debugLevel ~= "INFO+" then return end

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


-- Function to obtain the index of a given itemID and pass that onto a function used for purchasing that item
function RQE:BuyItemByItemID(itemID, quantity)
	local itemFound = false

	for index = 1, GetMerchantNumItems() do
		local merchantItemID = GetMerchantItemID(index)

		if merchantItemID == itemID then
			itemFound = true

			-- Print debug for confirmation
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Found itemID", itemID, "at merchant index", index)
			end

			-- Call your existing purchase logic
			RQE:ConfirmAndBuyMerchantItem(index, quantity)

			break -- Stop after first match
		end
	end

	if not itemFound then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ItemID", itemID, "not found at this merchant.")
		end
	end
end


-- Function to confirm and buy an item from a merchant
function RQE:ConfirmAndBuyMerchantItem(index, quantity)
	local itemName = C_MerchantFrame.GetItemInfo(index)	-- The following has been implemented with 11.0.5, but will be changing possibly to 'C_MerchantFrame.GetItemInfo' in 12.0 expansion
	--local itemName, _, _, _, _, _, _, _, _, _, _, = C_MerchantFrame.GetItemInfo(index)
	local maxStack = GetMerchantItemMaxStack(index)
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


-- -- Function that handles a series of functions related to purchasing an item from the AH	FIX MADE FOR 'X' RETURNING NIL (2025.09.30)
-- function RQE:SearchPreparePurchaseConfirmAH(itemID, quantity)
	-- local finalQuantity

	-- -- Case 1: If a valid number is passed, use it directly
	-- if type(quantity) == "number" and quantity > 0 then
		-- finalQuantity = quantity

	-- -- Case 2: If "x" is passed, or quantity is not valid, try to resolve from supertracked quest
	-- else
		-- local questID = C_SuperTrack.GetSuperTrackedQuestID()
		-- if questID and questID > 0 then
			-- -- local _, _, _, _fulfilled = GetQuestObjectiveInfo(questID, 1, false)
			-- -- local _, _, _, _, _required = GetQuestObjectiveInfo(questID, 1, false)

			-- -- local fulfilled = tonumber(_fulfilled or 0)
			-- -- local required = tonumber(_required or 0)

			-- local objectives = C_QuestLog.GetQuestObjectives(questID)
			-- if objectives and objectives[1] then
				-- local fulfilled = tonumber(objectives[1].numFulfilled or 0)
				-- local required  = tonumber(objectives[1].numRequired or 0)

				-- if fulfilled and required and required > fulfilled then
					-- finalQuantity = required - fulfilled
					-- if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
						-- print("Required: " .. required .. " & Fulfilled: " .. fulfilled)
						-- print("Resolved Quantity: " .. finalQuantity)
					-- end
				-- else
					-- if RQE.db.profile.debugLevel == "INFO+" then
						-- print("Could not determine required purchase quantity from quest objectives.")
					-- end
					-- return
				-- end
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("Quest has no objectives or objectives[1] missing.")
				-- end
				-- return
			-- end
		-- else
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("No supertracked quest found for dynamic quantity resolution.")
			-- end
			-- return
		-- end
	-- end

	-- -- Final check
	-- if not finalQuantity then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Invalid quantity. Aborting.")
		-- end
		-- return
	-- end

	-- -- Purchase logic
	-- if C_AddOns.IsAddOnLoaded("CraftSim") then
	-- --if C_AddOns.IsAddOnLoaded("CraftSim") or C_AddOns.IsAddOnLoaded("TradeSkillMaster") then
		-- RQE:SearchAndPrepareAuctionItem(itemID, finalQuantity)
	-- else
		-- RQE:SearchAndPrepareAuctionItem(itemID, finalQuantity)
		-- RQE:ConfirmAndPurchaseCommodity(itemID, finalQuantity)
	-- end
-- end


-- Function that handles a series of functions related to purchasing an item from the AH	-- FIX TO MAKE WORK WITH DIFFERENT OBJECTIVE NUMBERS (OTHER THAN JUST OBJECTIVE #1) (2025.09.30)
function RQE:SearchPreparePurchaseConfirmAH(itemID, quantity)
	local finalQuantity

	-- Case 1: If a valid number is passed, use it directly
	if type(quantity) == "number" and quantity > 0 then
		finalQuantity = quantity

	-- Case 2: If "x" is passed, or quantity is not valid, try to resolve from supertracked quest
	else
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID and questID > 0 then
			local objectives = C_QuestLog.GetQuestObjectives(questID)
			if objectives and #objectives > 0 then
				for i, obj in ipairs(objectives) do
					-- Some objectives expose itemID directly, others only in text
					local fulfilled = tonumber(obj.numFulfilled or 0)
					local required  = tonumber(obj.numRequired or 0)

					-- If this looks like an item collection objective
					if required and required > 0 then
						-- Try to match itemID if Blizzard provides it
						if obj.type == "item" and obj.itemID and obj.itemID == itemID then
							finalQuantity = required - fulfilled
						elseif obj.text and string.find(obj.text, C_Item.GetItemNameByID(itemID) or "") then
							finalQuantity = required - fulfilled
						end

						if finalQuantity and finalQuantity > 0 then
							if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
								print("Objective " .. i .. ": Required = " .. required .. " Fulfilled = " .. fulfilled)
								print("Resolved Quantity = " .. finalQuantity)
							end
							break -- stop once we find a match
						end
					end
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Quest has no objectives.")
				end
				return
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" then
				print("No supertracked quest found for dynamic quantity resolution.")
			end
			return
		end
	end

	-- Final check
	if not finalQuantity or finalQuantity <= 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Invalid or zero quantity. Aborting.")
		end
		return
	end

	-- Purchase logic
	if C_AddOns.IsAddOnLoaded("CraftSim") then
		RQE:SearchAndPrepareAuctionItem(itemID, finalQuantity)
	else
		RQE:SearchAndPrepareAuctionItem(itemID, finalQuantity)
		RQE:ConfirmAndPurchaseCommodity(itemID, finalQuantity)
	end
end


-- Function to search an item in the auction house and prepare for manual review
function RQE:SearchAndPrepareAuctionItem(itemID, quantity)
	if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Auction House is not open.")
		end
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
			if RQE.db.profile.debugLevel == "INFO+" then
				print("May not be correct, but no results found for itemID:", itemID)
			end
		end
	end)
end


-- Function that searches for and prints out the prices for an item
function RQE:SearchAndDisplayCommodityResults(itemID, quantity)
	if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Auction House is not open.")
		end
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
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Auction House is not open.")
		end
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
					if self.text then
						self.text:SetFormattedText(self.text:GetText(), itemLink, quantity, GetCoinTextureString(totalCost))
					end
					local itemFrame = CreateFrame("Frame", nil, self)
					itemFrame:SetAllPoints(self.text or self)  -- fallback to whole popup if self.text is nil
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

-- Function to update DB profile frame position
function RQE:UpdateFrameFromProfile()
	local xPos = RQE.db.profile.framePosition.xPos or -40
	local yPos = RQE.db.profile.framePosition.yPos or -285
	RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
end


---------------------------------------------------
-- 20. Experimental Testing Ground
---------------------------------------------------

-- Table to hold the questID and stepIndex conditions (blacklist/exclude/exclusion)
RQE.questConditions = {
	[78640] = 3,  -- Example questID 78640 with stepIndex 3
	[27779] = 1,
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
		-- print("~~~ Remove Quest Watch: 9462 ~~~")
		C_QuestLog.RemoveQuestWatch(superTrackedQuestID)
		RQE.Buttons.ClearButtonPressed()

		-- Supertrack the next closest non-blacklisted quest
		local nextClosestQuestID = RQE:GetClosestNonBlacklistedQuest()
		RQE.ClosestSafeQuestID = nextClosestQuestID

		if nextClosestQuestID then
			-- Set the supertracked quest to the next closest non-blacklisted quest
			-- print("~~~ SetSuperTrack: 9332~~~")
			C_SuperTrack.SetSuperTrackedQuestID(nextClosestQuestID)
			RQE:SaveSuperTrackedQuestToCharacter()

			-- Ensure the blacklisted quest is not re-added prematurely
			RQE.BlacklistUnderway = false

			-- After a delay, re-add the blacklisted quest to the watch list, but do not re-supertrack it
			C_Timer.After(2.5, function()
				C_QuestLog.AddQuestWatch(RQE.BlackListedQuestID)	--C_QuestLog.AddQuestWatch(RQE.BlackListedQuestID, 1)
			end)
		end
	end
end


-- Function to supertrack a random quest
function RQE:SupertrackRandomQuest()
	local functionName = "RQE:SupertrackRandomQuest()"

	local numQuests = C_QuestLog.GetNumQuestLogEntries()
	local randomIndex = math.random(1, numQuests)

	-- Iterate through the player's quest log to find a valid random quest
	for i = 1, numQuests do
		local info = C_QuestLog.GetInfo(i)
		if info and info.questID then
			-- Found a quest, supertrack it
			-- print("~~~ SetSuperTrack: 9358~~~")
			C_SuperTrack.SetSuperTrackedQuestID(info.questID)
			RQE:SaveSuperTrackedQuestToCharacter()

			-- Print debug message
			print("Supertracking random questID: " .. tostring(info.questID))

			-- Call UpdateFrame to refresh the UI
			RQE.smartPrint(functionName, "~~ Firing UpdateFrame(): 10240 ~~")
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
RQEGossipFrame:RegisterEvent("GOSSIP_CLOSED")


-- Table to store multiple gossip selection criteria
local selectedGossipOption = {
	npcName = nil,
	optionIndexes = {}, -- Store multiple option indexes
	currentIndex = 1
}

-- Table to store multiple gossip selection criteria
local selectedGossipMultiple = {
	npcName = nil,
	optionIndexes = {}, -- Store multiple option indexes
	currentIndex = 1
}

-- Table to store **single** gossip selection criteria
local selectedGossipSingle = {
	npcName = nil,
	optionIndex = nil
}


-- Function to process the next gossip selection in queue
local function ProcessNextGossipOption()
	local options = C_GossipInfo.GetOptions()

	-- If no options are available, stop processing
	if not options or #options == 0 then
		return
	end

	-- Ensure we are interacting with the correct NPC
	local currentNPCName = UnitName("npc")
	if not currentNPCName or currentNPCName ~= selectedGossipOption.npcName then
		return
	end

	-- If we have an option left to process
	if selectedGossipOption.currentIndex <= #selectedGossipOption.optionIndexes then
		local targetOption = selectedGossipOption.optionIndexes[selectedGossipOption.currentIndex]

		for _, option in ipairs(options) do
			if option.orderIndex == targetOption then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Selecting gossip option:", option.orderIndex, "for NPC:", selectedGossipOption.npcName)
				end

				-- Select the option
				C_GossipInfo.SelectOptionByIndex(option.orderIndex)

				-- Move to the next option
				selectedGossipOption.currentIndex = selectedGossipOption.currentIndex + 1

				-- Schedule next selection
				C_Timer.After(0.5, ProcessNextGossipOption) -- Add a slight delay to process sequentially
				break
			end
		end
	end
end


-- Function to set a single gossip option
function RQE.SelectGossipOption(npcName, optionIndex)
	-- Ensure gossip automation is enabled
	if not RQE.db.profile.enableGossipModeAutomation then return end

	-- Set the selected gossip option for future use
	if npcName == "target" then
		selectedGossipSingle.npcName = UnitName("target")
	else
		selectedGossipSingle.npcName = npcName
	end
	selectedGossipSingle.optionIndex = optionIndex

	if RQE.db.profile.debugLevel == "INFO+" then
		print("Single gossip selection set for NPC:", npcName, "to select option:", optionIndex)
	end
end


-- Function to set multiple gossip selections
function RQE.SelectMultipleGossipOptions(npcName, ...)
	-- Ensure gossip automation is enabled
	if not RQE.db.profile.enableGossipModeAutomation then return end

	-- Reset previous queue
	selectedGossipOption.npcName = npcName
	selectedGossipOption.optionIndexes = { ... }
	selectedGossipOption.currentIndex = 1

	-- Debug logging
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Gossip selection set for NPC:", npcName, "to select options:", table.concat(selectedGossipOption.optionIndexes, ", "))
	end

	-- If the NPC gossip window is already open, process immediately
	if UnitName("npc") == npcName then
		ProcessNextGossipOption()
	end
end


-- Securely hook event handler to process gossip
RQEGossipFrame:SetScript("OnEvent", function(self, event)
	if event == "GOSSIP_SHOW" then
		-- If selectedGossipOption has active selections, start processing
		if selectedGossipOption.npcName then
			ProcessNextGossipOption()
		end
	elseif event == "GOSSIP_CLOSED" then
		-- Reset queue when gossip window closes
		selectedGossipOption.npcName = nil
		selectedGossipOption.optionIndexes = {}
		selectedGossipOption.currentIndex = 1
	end
end)


-- Securely hook the frame's event handler for single gossip
RQEGossipFrame:HookScript("OnEvent", function(self, event)
	if event == "GOSSIP_SHOW" then
		-- Fetch available gossip options
		local options = C_GossipInfo.GetOptions()

		-- Check if options exist
		if not options or #options == 0 then
			return
		end

		-- Get the current NPC name
		local currentNPCName = UnitName("npc")

		-- Check if the selection criteria match the current NPC
		if selectedGossipSingle.npcName and currentNPCName == selectedGossipSingle.npcName then
			-- Iterate through options and select based on specified index
			for i, option in ipairs(options) do
				if option.orderIndex == selectedGossipSingle.optionIndex then
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Selecting gossip option:", option.orderIndex, "for NPC:", selectedGossipSingle.npcName)
					end
					C_GossipInfo.SelectOptionByIndex(option.orderIndex)
					break
				end
			end
		end
	elseif event == "GOSSIP_CLOSED" then
		-- Reset both queues when gossip window closes
		selectedGossipMultiple.npcName = nil
		selectedGossipMultiple.optionIndexes = {}
		selectedGossipMultiple.currentIndex = 1

		selectedGossipSingle.npcName = nil
		selectedGossipSingle.optionIndex = nil
	end
end)


-- Closes the gossip window to ensure that the options are clean slate
function RQE.ResetGossipWindow()
	if UnitExists("npc") then
		C_GossipInfo.CloseGossip() -- Close the gossip window
		-- C_Timer.After(0.2, function() -- Wait a moment before reopening
			-- C_PlayerInteractionManager.InteractUnit("npc") -- Reopen the gossip window
		-- end)
	-- else
		-- print("No NPC is currently targeted.")
	end
end


-- Prints the closest flight master to the player's current location
function RQE:GetClosestFlightMaster()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		print(">> No valid mapID found.")
		return nil
	end

	local position = C_Map.GetPlayerMapPosition(mapID, "player")
	if not position then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> Unable to get player map position.")
		end
		return nil
	end

	local px, py = position:GetXY()
	if not px or not py then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> Invalid player position.")
		end
		return nil
	end

	local closestNode = nil
	local shortestDistance = math.huge
	local nodes = C_TaxiMap.GetTaxiNodesForMap(mapID)

	local playerFaction = UnitFactionGroup("player")  -- "Alliance", "Horde", or "Neutral"

	for _, node in ipairs(nodes or {}) do
		if not node.isUndiscovered then
			-- Filter by faction (allow Neutral or same-faction only)
			if node.faction == 0 or
				(node.faction == 1 and playerFaction == "Horde") or (node.faction == 2 and playerFaction == "Alliance") or (playerFaction == "Neutral") then	-- Allow all nodes if player is Neutral (e.g. fresh Pandaren)

				local nx, ny = node.position.x, node.position.y
				local dist = math.sqrt((px - nx)^2 + (py - ny)^2)
				if dist < shortestDistance then
					shortestDistance = dist
					closestNode = node
				end
			end
		end
	end

	if closestNode then
		print(string.format(">> Closest flight master: %s (%.2f, %.2f, mapID %d)", closestNode.name, closestNode.position.x * 100, closestNode.position.y * 100, mapID))
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> No discovered flight master found on this map.")
		end
	end

	return closestNode
end


-- Returns { mapID, x, y, xPct, yPct, label, source="waypoint" } or nil.
-- Prints a test line and then calls CreateUnknownQuestWaypointNoDirectionText to place the waypoint.
function RQE:FindQuestZoneTransition(questID)
	if not questID then
		return nil
	end

	local waypointText = C_QuestLog.GetNextWaypointText(questID)
	if not waypointText then return end

	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		return nil
	end

	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local label = C_QuestLog.GetNextWaypointText(questID) or "Quest waypoint"

	-- Preferred: exact waypoint on the player's current map
	local xNorm, yNorm = C_QuestLog.GetNextWaypointForMap(questID, mapID)

	-- Fallback 1: generic waypoint (may be vec or POI id)
	if not (xNorm and yNorm) then
		local wpMapID, wpData = C_QuestLog.GetNextWaypoint(questID)
		if wpMapID then
			if type(wpData) == "table" then
				if wpData.x and wpData.y then
					xNorm, yNorm = wpData.x, wpData.y
					mapID = wpMapID
				elseif wpData.position and wpData.position.x and wpData.position.y then
					xNorm, yNorm = wpData.position.x, wpData.position.y
					mapID = wpMapID
				end
			elseif type(wpData) == "number" then
				local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(wpMapID, wpData)
				if poiInfo and poiInfo.position then
					xNorm, yNorm = poiInfo.position.x, poiInfo.position.y
					mapID = wpMapID
					label = poiInfo.name or label
				end
			end
		end
	end

	-- Fallback 2: our DB (hotspots or legacy coords)
	if not (xNorm and yNorm) then
		local stepIndex = RQE.AddonSetStepIndex or 1
		local questData = RQE.getQuestData and RQE.getQuestData(questID)
		local step = questData and questData[stepIndex]
		if step then
			if step.coordinateHotspots then
				local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
				if smap and sx and sy then
					mapID, xNorm, yNorm = smap, sx, sy
				end
			elseif step.coordinates and step.coordinates.x and step.coordinates.y and step.coordinates.mapID then
				mapID = step.coordinates.mapID
				-- DB coords are 0–100, normalize back to 0–1
				xNorm, yNorm = step.coordinates.x / 100, step.coordinates.y / 100
			end
		end
	end

	-- Still nothing? Bail safely.
	if RQE.db.profile.enableTravelSuggestions then
		if not (xNorm and yNorm) then
			if RQE.db.profile.debugLevel == "INFO+" then
				print(string.format("FindQuestZoneTransition: no waypoint for quest %d on map %d.", questID, mapID))
			end
			return nil
		end
	end

	-- Percent (for display) + rounded for print
	local xPct = xNorm * 100
	local yPct = yNorm * 100

	if RQE.db.profile.enableTravelSuggestions then
		if not RQE.DontPrintTransitionBits then
			print(string.format(
				">> Transition (waypoint): Quest %d \"%s\" — %s (%.2f, %.2f, mapID %d)",
				questID, questName, label, xPct, yPct, mapID
			))
		end
	end

	-- Stash for the creator (fast path in CreateUnknownQuestWaypointWithDirectionText)
	RQE.WPxPos, RQE.WPyPos, RQE.WPmapID = xPct, yPct, mapID
	RQE.x, RQE.y = xPct, yPct  -- legacy helpers you were using before

	-- Create the actual waypoint (this function handles TomTom/Carbonite)
	C_Timer.After(1.2, function()
		if RQE.CreateUnknownQuestWaypointWithDirectionText then
			RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID)
		end
	end)

	return { mapID = mapID, x = xNorm, y = yNorm, xPct = xPct, yPct = yPct, label = label, source = "waypoint" }
end


-- Obtains the closest flight master that is known to a map position
function RQE:GetClosestFlightMasterToCoords(mapID, targetX, targetY)
	if not mapID or not targetX or not targetY then
		print(">> Invalid coordinates or mapID provided.")
		return nil
	end

	local closestNode = nil
	local shortestDistance = math.huge
	local nodes = C_TaxiMap.GetTaxiNodesForMap(mapID)

	for _, node in ipairs(nodes or {}) do
		if not node.isUndiscovered then
			local nx, ny = node.position.x, node.position.y
			local dist = math.sqrt((targetX - nx)^2 + (targetY - ny)^2)
			if dist < shortestDistance then
				shortestDistance = dist
				closestNode = node
			end
		end
	end

	if closestNode then
		print(string.format(">> Closest flight master to (%.2f, %.2f) is %s (%.1f, %.1f, mapID %d)",
			targetX * 100, targetY * 100,
			closestNode.name,
			closestNode.position.x * 100,
			closestNode.position.y * 100,
			mapID
		))
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> No discovered flight master found on that map.")
		end
	end

	return closestNode
end


-- Determines and prints the closest flight master to the questID that is passed to the function
function RQE:GetClosestFlightMasterToQuest(questID)
	if not questID then
		print(">> No quest ID provided.")
		return
	end

	local questData = RQE.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO" then
			print(">> Quest not found in internal database:", questID)
		end
		return
	end

	local mapID, x, y

	-- Try to use coordinates from the current step (first numeric step with coords)
	for i = 1, 10 do
		local step = questData[i]
		if step then
			-- Prefer hotspots
			if step.coordinateHotspots then
				local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, i, step)
				if smap and sx and sy then
					mapID, x, y = smap, sx, sy	-- sx/sy are normalized
					break
				end
			-- Legacy single
			elseif step.coordinates
				and step.coordinates.x and step.coordinates.y and step.coordinates.mapID
			then
				mapID = step.coordinates.mapID
				x = step.coordinates.x / 100
				y = step.coordinates.y / 100
				break
			end
		end
	end

	-- Fallback to quest.location if no step with coordinates was found
	if not mapID then
		-- if questData.location then
			-- mapID = questData.location.mapID
			-- x = questData.location.x / 100
			-- y = questData.location.y / 100
		local xLoc, yLoc, mapID, continentID = RQE.GetPrimaryLocation(questData)
		local finalMapID

		if mapID then
			finalMapID = mapID
		elseif continentID then
			local playerMapID = C_Map.GetBestMapForUnit("player")
			local parent = playerMapID and C_Map.GetMapInfo(playerMapID).parentMapID
			if parent == continentID then
				finalMapID = continentID
			end
		end

		if xLoc and yLoc and finalMapID then
			mapID = finalMapID
			x = xLoc / 100
			y = yLoc / 100
		else
			print(">> No usable coordinates found for quest:", questID)
			return
		end
	end

	-- Call the coord-based function to get closest flight master
	local closest = RQE:GetClosestFlightMasterToCoords(mapID, x, y)

	if not closest then
		print(string.format(">> No known flight master found near %.2f, %.2f on map %d", x * 100, y * 100, mapID))
	end
end


-- Function that determines the fastest travel method to reach a given quest
function RQE:RecommendFastestTravelMethod(questID)
	if not RQE.db.profile.enableTravelSuggestions then return end

	if not questID then
		RQE.SuperTrackedQuestIDForSpeed = C_SuperTrack.GetSuperTrackedQuestID()
	else
		RQE.SuperTrackedQuestIDForSpeed = questID
	end

	RQE:AskSetWaypointToClosestFlightMaster()

	local questData = RQE.getQuestData(RQE.SuperTrackedQuestIDForSpeed)
	if not questData then
		print(">> Quest not found in internal DB:", RQE.SuperTrackedQuestIDForSpeed)
		return
	end

	-- Determine correct coordinates based on active step
	local activeStepIndex = RQE.AddonSetStepIndex or 1
	local activeStep = questData[activeStepIndex]

	if not activeStep or not activeStep.coordinates then
		print(">> No valid coordinates found for step", activeStepIndex, "of questID", RQE.SuperTrackedQuestIDForSpeed)
		return
	end

	local stepCoords = activeStep.coordinates

	local playerMapID = C_Map.GetBestMapForUnit("player")
	local playerPos = C_Map.GetPlayerMapPosition(playerMapID, "player")
	if not playerPos then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> Unable to determine player position.")
		end
		return
	end

	local px, py = playerPos:GetXY()

	-- Distances
	print("QuestID: " .. RQE.SuperTrackedQuestIDForSpeed)
	local directDistance = RQE:GetDistance(playerMapID, px, py, stepCoords.mapID, stepCoords.x / 100, stepCoords.y / 100)

	-- Flight Masters
	local startFM = RQE:GetClosestFlightMaster()
	local endFM = RQE:GetClosestFlightMasterToCoords(stepCoords.mapID, stepCoords.x / 100, stepCoords.y / 100)

	-- Calculate taxi route distance if both FMs are available
	local taxiDistance, walkToFM_Distance, walkFromFM_Distance = math.huge, math.huge, math.huge
	if startFM and endFM then
		walkToFM_Distance = RQE:GetDistance(playerMapID, px, py, playerMapID, startFM.position.x, startFM.position.y)
		taxiDistance = RQE:GetDistance(startFM.mapID or playerMapID, startFM.position.x, startFM.position.y, endFM.mapID or stepCoords.mapID, endFM.position.x, endFM.position.y)
		walkFromFM_Distance = RQE:GetDistance(stepCoords.mapID, endFM.position.x, endFM.position.y, stepCoords.mapID, stepCoords.x / 100, stepCoords.y / 100)
	end

	-- Travel speeds (measured)
	local walkSpeed = 11
	local flySpeed = 50
	local skyridingSpeed = 110
	local taxiSpeed = 85

	-- Time estimates
	local walkTime = directDistance / walkSpeed
	local flyTime = directDistance / flySpeed
	local taxiTime = (walkToFM_Distance / walkSpeed) + (taxiDistance / taxiSpeed) + (walkFromFM_Distance / walkSpeed)

	-- Print time breakdowns
	if type(walkTime) ~= "number" or walkTime == math.huge or
		type(flyTime) ~= "number" or flyTime == math.huge or
		type(taxiTime) ~= "number" or taxiTime == math.huge then
		if RQE.db.profile.debugLevel == "INFO+" then
			print(">> Recommended: Unable to determine route reliably (map mismatch or unknown FMs).")
		end
		return
	end

	-- Print time breakdowns
	print(string.format(">> Estimated times: Walk = %.1fs | Fly = %.1fs | Taxi = %.1fs", walkTime, flyTime, taxiTime))

	-- Decision logic
	if flyTime < walkTime and flyTime < taxiTime then
		print(">> Recommended: Use flying mount (fastest travel method).")
	elseif taxiTime < walkTime then
		print(string.format(">> Recommended: Take taxi from %s to %s", startFM.name, endFM.name))
	else
		print(">> Recommended: Travel directly on foot or ground mount.")
	end
end


-- Returns normalized Euclidean distance for same-map coords
function RQE:GetDistance(mapID1, x1, y1, mapID2, x2, y2)
	if not (x1 and y1 and x2 and y2) then return math.huge end

	-- If different maps, we can't calculate — bail with huge value
	if mapID1 ~= mapID2 then return math.huge end

	-- Convert to actual game space units (normalize to 0–1 range assumed)
	local dx = (x2 - x1)
	local dy = (y2 - y1)
	return math.sqrt(dx * dx + dy * dy) * 10000 -- scale to approx "yards"
end


-- Gather the estimated speed the player is currently traveling
function RQE:EstimatePlayerSpeed(sampleTime)
	sampleTime = sampleTime or 1  -- default to 1 second

	local mapID = C_Map.GetBestMapForUnit("player")
	local startPos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not startPos then
		print(">> Unable to get player position.")
		return
	end

	local x1, y1 = startPos:GetXY()

	C_Timer.After(sampleTime, function()
		local newPos = C_Map.GetPlayerMapPosition(mapID, "player")
		if not newPos then
			print(">> Unable to get player position (after delay).")
			return
		end

		local x2, y2 = newPos:GetXY()

		-- Use the same GetDistance logic
		local distance = RQE:GetDistance(mapID, x1, y1, mapID, x2, y2)
		local speed = distance / sampleTime

		print(string.format(">> Estimated player speed: %.2f yards/sec over %.1f sec", speed, sampleTime))
	end)
end


-- Ask the player if they want a TomTom waypoint to the closest flight master, then set it on Yes.
function RQE:AskSetWaypointToClosestFlightMaster()
	if UnitOnTaxi("player") then return end  -- No popups while flying
	local tomtomLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("TomTom")
	if not (tomtomLoaded and RQE.db and RQE.db.profile and RQE.db.profile.enableTomTomCompatibility) then
		return
	end

	local node = RQE:GetClosestFlightMaster()  -- pure; safe to call
	local nearestName = (node and node.name) or "nearest flight master"

	StaticPopupDialogs["RQE_CONFIRM_WP_CLOSEST_FM"] = {
		text = ("Set a TomTom waypoint to the closest flight master?\n\nNearest: %s"):format(nearestName),
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			RQE:SetTomTomWaypointToClosestFlightMaster()
			RQE.NearestFlightMasterSet = true
		end,
		timeout = 3,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3, -- avoid UIParent taint
	}
	StaticPopup_Show("RQE_CONFIRM_WP_CLOSEST_FM")
end


-- Create a TomTom (or Blizzard) waypoint to the closest discovered flight master on the current map.
function RQE:SetTomTomWaypointToClosestFlightMaster()
	local node = RQE:GetClosestFlightMaster()
	if not node then
		if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
			print(">> No suitable flight master to waypoint.")
		end
		return
	end

	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		print(">> No valid mapID found (cannot set waypoint).")
		return
	end

	local xNorm, yNorm = node.position.x, node.position.y
	if not xNorm or not yNorm then
		print(">> Flight master node has no position (cannot set waypoint).")
		return
	end

	local xPct, yPct = xNorm * 100, yNorm * 100
	local title = string.format('Flight Master: %s', node.name or "Unknown")

	C_Map.ClearUserWaypoint()

	local isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db and RQE.db.profile and RQE.db.profile.enableTomTomCompatibility then
		if TomTom and TomTom.waydb and TomTom.waydb.ResetProfile then
			TomTom.waydb:ResetProfile()
			RQE._currentTomTomUID = nil
		end
		RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, xNorm, yNorm, title)
		--TomTom:AddWaypoint(mapID, xNorm, yNorm, { title = title })

		if RQE.db.profile.debugLevel == "INFO+" then
			print(string.format(">> TomTom waypoint => %s (%.2f, %.2f, mapID %d)", title, xPct, yPct, mapID))
		end
	else
		-- Blizzard fallback
		local wp = { uiMapID = mapID, position = CreateVector2D(xNorm, yNorm), name = title }
		C_Map.SetUserWaypoint(wp)
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)

		if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
			print(string.format(">> Blizzard waypoint => %s (%.2f, %.2f, mapID %d) [TomTom not available/disabled]", title, xPct, yPct, mapID))
		end
	end

	return { name = node.name, mapID = mapID, x = xNorm, y = yNorm, xPct = xPct, yPct = yPct }
end


-- Fetches the player's position in relation to their current continent
function RQE.DebugPrintPlayerContinentPosition(questID)
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		print("Unable to determine current map.")
		return
	end

	if mapID == 407 then
		return
	end

	-- Get normalized x, y for the current map
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then
		print("Unable to get player position on mapID:", mapID)
		return
	end

	local x, y = pos.x, pos.y

	-- Climb to continent
	local continentID, continentName
	local m = mapID
	while m do
		local info = C_Map.GetMapInfo(m)
		if not info then break end
		if info.mapType == 2 then -- 2 = continent
			continentID, continentName = info.mapID, info.name
			break
		end
		m = info.parentMapID
	end

	if not continentID then
		print("Unable to determine continent for mapID:", mapID)
		return
	end

	-- Convert coords to continent-normalized space
	local contPos = C_Map.GetPlayerMapPosition(continentID, "player")
	if not contPos then
		print("Unable to get player position on continentID:", continentID)
		return
	end

	local cx, cy = contPos.x, contPos.y

	-- Print in locations array format (include DB "location" line above it)
	if RQE.MapAndContinentFromQuestAccepted then
		local dbEntry = questID and RQE.getQuestData(questID)
		local hasLocationsArray = dbEntry and dbEntry.locations ~= nil
		local hasSingleLocation = dbEntry and dbEntry.location ~= nil

		if dbEntry and hasSingleLocation and not hasLocationsArray then
			local dbLoc = dbEntry.location
			local dbX, dbY, dbMapID = nil, nil, nil

			if type(dbLoc) == "table" then
				dbX = tonumber(dbLoc.x)
				dbY = tonumber(dbLoc.y)
				dbMapID = tonumber(dbLoc.mapID)
			end

			if questID then
				print(tostring(questID))
			end

			-- Then print the new generated "locations" array block
			print("			locations = {")
			if dbX and dbY and dbMapID then
				print(string.format("				{ x = %.2f, y = %.2f, mapID = %d },", dbX, dbY, dbMapID))
			else
				print(string.format("				{ x = %.2f, y = %.2f, mapID = %d },", x * 100, y * 100, mapID))
			end
			print(string.format("				{ x = %.2f, y = %.2f, continentID = %d },", cx * 100, cy * 100, continentID))
			print("			},")
			PlaySound(265395)	-- VO_110_Alleria_Windrunner_29_F (Alleria: Angry)
		end
	end

	-- Print in coordinateHotspots format
	if not RQE.MapAndContinentFromQuestAccepted then
		local trackedQuestID = questID or C_SuperTrack.GetSuperTrackedQuestID()

		local dbEntry = RQE.getQuestData(trackedQuestID)
		local stepIndex = RQE.AddonSetStepIndex or 1
		local dbX, dbY, dbMapID

		-- Try to pull coordinates for the current step
		if dbEntry and dbEntry[stepIndex] and dbEntry[stepIndex].coordinates then
			dbX = dbEntry[stepIndex].coordinates.x
			dbY = dbEntry[stepIndex].coordinates.y
			dbMapID = dbEntry[stepIndex].coordinates.mapID
		elseif dbEntry and dbEntry.location then
			dbX = dbEntry.location.x
			dbY = dbEntry.location.y
			dbMapID = dbEntry.location.mapID
		end

		if RQE.MapAndContinentFromQuestTurnIn then
			local hasDBCoords = (dbX and dbY and dbMapID)
			local hasHotspots = dbEntry and dbEntry[stepIndex] and dbEntry[stepIndex].coordinateHotspots ~= nil

			if hasDBCoords then
				-- Print DB-based coordinate + player-based continent hotspot
				if trackedQuestID then
					print(tostring(trackedQuestID))
				end
				print(string.format("				coordinates = { x = %.2f, y = %.2f, mapID = %d },", dbX, dbY, dbMapID))
			-- else
				-- -- Don't spam with "No valid DB coordinates..." — just fallback gracefully
				-- print("Using player position fallback (no DB coordinates for this quest step)")
			end

			if not hasHotspots then
				-- ✅ Use DB coords if available, otherwise fallback to player’s current map position
				local hotspotX = hasDBCoords and dbX or (x * 100)
				local hotspotY = hasDBCoords and dbY or (y * 100)
				local hotspotMapID = hasDBCoords and dbMapID or mapID

				print("				coordinateHotspots = {")
				print(string.format("					{ x = %.2f, y = %.2f, mapID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },", hotspotX, hotspotY, hotspotMapID))
				print(string.format("					{ x = %.2f, y = %.2f, continentID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },", cx * 100, cy * 100, continentID))
				print("				},")
				PlaySound(265380)	-- VO_110_Alleria_Windrunner_21_F (Alleria: Greeting)
			else
				print("Turn in step for the quest " .. trackedQuestID .. " already uses a coordinateHotspots array")
			end

		else
			-- Handling for the manually activation of the function
			local hasDBCoords = (dbX and dbY and dbMapID)

			if hasDBCoords then
				if trackedQuestID then
					print(tostring(trackedQuestID))
				end
				print(string.format("				coordinates = { x = %.2f, y = %.2f, mapID = %d },", dbX, dbY, dbMapID))
			-- else
				-- print("Using player position fallback (no DB coordinates for this quest step)")
			end

			print("				coordinateHotspots = {")
			local hotspotX = hasDBCoords and dbX or (x * 100)
			local hotspotY = hasDBCoords and dbY or (y * 100)
			local hotspotMapID = hasDBCoords and dbMapID or mapID

			print(string.format("					{ x = %.2f, y = %.2f, mapID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },", hotspotX, hotspotY, hotspotMapID))
			print(string.format("					{ x = %.2f, y = %.2f, continentID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },", cx * 100, cy * 100, continentID))
			print("				},")
		end
	end

	RQE.MapAndContinentFromQuestAccepted = false
	RQE.MapAndContinentFromQuestTurnIn = false
end