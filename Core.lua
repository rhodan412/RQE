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


-- Blizzard Imports
local ScenarioObjectiveTracker = RQE:NewModule("ScenarioObjectiveTracker", "AceEvent-3.0")


---------------------------------------------------
-- 3. Debugging Functions
---------------------------------------------------

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
		enableQuestFrame = true,
        showMinimapIcon = false,
        showMapID = true,
        showCoordinates = true,
		autoQuestWatch = true,
		autoQuestProgress = true,
        frameWidth = 400,
        frameHeight = 300,
        framePosition = {
            xPos = -40,
            yPos = -270,
            anchorPoint = "TOPRIGHT",
		},
		MainFrameOpacity = 0.55, 
		textSettings = {
		},
        QuestFramePosition = {
            xPos = -40,
            yPos = 150,
			anchorPoint = "BOTTOMRIGHT",
            frameWidth = 300,
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

-- Initialize lastSuperTrackedQuestID variable
local lastSuperTrackedQuestID = nil


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
        -- First-level menu items
        info.text = "Complete Quests"
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

    -- Add logic to update frame with the current supertracked quest
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID then
        local questInfo = RQEDatabase[questID]
        if questInfo then
            local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
        end
    end
end


-- Function Check to Initialize RQEFrame sections not yet initialized
function RQE:ConfigurationChanged()
    RQE.debugLog("Entered RQE:ConfigurationChanged")

    if RQE.headerText then
        local headerSettings = RQE.db.profile.textSettings.headerText
		
        RQE.headerText:SetFont(headerSettings.font, headerSettings.size)
        RQE.headerText:SetTextColor(unpack(headerSettings.color))
    else
        RQE.debugLog("RQE.headerText is nil")
    end
	
    if RQE.QuestIDText then
        local QuestIDTextSettings = RQE.db.profile.textSettings.QuestIDText
		
        RQE.QuestIDText:SetFont(QuestIDTextSettings.font, QuestIDTextSettings.size)
        RQE.QuestIDText:SetTextColor(unpack(QuestIDTextSettings.color))
    else
        RQE.debugLog("RQE.QuestIDText is nil")
    end
	
    if RQE.QuestNameText then
        local QuestNameTextSettings = RQE.db.profile.textSettings.QuestNameText
		
        RQE.QuestNameText:SetFont(QuestNameTextSettings.font, QuestNameTextSettings.size)
        RQE.QuestNameText:SetTextColor(unpack(QuestNameTextSettings.color))
    else
        RQE.debugLog("RQE.QuestNameText is nil")
    end
	
    if RQE.DirectionTextFrame then
        local DirectionTextFrameSettings = RQE.db.profile.textSettings.DirectionTextFrame
		
        RQE.DirectionTextFrame:SetFont(DirectionTextFrameSettings.font, DirectionTextFrameSettings.size)
        RQE.DirectionTextFrame:SetTextColor(unpack(DirectionTextFrameSettings.color))
    else
        RQE.debugLog("RQE.DirectionTextFrame is nil")
    end
	
    if RQE.QuestDescription then
        local QuestDescriptionSettings = RQE.db.profile.textSettings.QuestDescription
		
        RQE.QuestDescription:SetFont(QuestDescriptionSettings.font, QuestDescriptionSettings.size)
        RQE.QuestDescription:SetTextColor(unpack(QuestDescriptionSettings.color))
    else
        RQE.debugLog("RQE.QuestDescription is nil")
    end
	
    if RQE.QuestObjectives then
        local QuestObjectivesSettings = RQE.db.profile.textSettings.QuestObjectives
		
        RQE.QuestObjectives:SetFont(QuestObjectivesSettings.font, QuestObjectivesSettings.size)
        RQE.QuestObjectives:SetTextColor(unpack(QuestObjectivesSettings.color))
    else
        RQE.debugLog("RQE.QuestObjectives is nil")
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
    local mapID = GetQuestUiMapID(questID, ignoreWaypoints)
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
				--OpenQuestLog(mapID)
				--QuestMapFrame_ShowQuestDetails(questID)
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
		RQE.debugLog("MapID not found for QuestID:", questID)
		return
	end
	
	-- If POI info is not available, try using GetNextWaypointForMap
	if not posX or not posY then
		if not isMapOpen and RQE.superTrackingChanged then
			-- Call the function to open the quest log with the details of the super tracked quest
			OpenQuestLogToQuestDetails(questID)
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

    -- Clear the current super tracked content
    C_SuperTrack.ClearSuperTrackedContent()

    -- Restore the super tracked quest after a delay
    C_Timer.After(0.2, function()
        if savedSuperTrackedQuestID then
            C_SuperTrack.SetSuperTrackedQuestID(savedSuperTrackedQuestID)
            local questInfo = RQEDatabase[savedSuperTrackedQuestID]
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

    -- Optionally, print a confirmation message to the chat window
    RQE.infoLog("LFG roles have been reset.")
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
        else
			RQEFrame:Show()
        end
        -- Refresh the config panel if it's open
        if YourConfigPanel and YourConfigPanel:IsVisible() then
            YourConfigPanel:UpdateCheckboxState(RQE.Settings.frameVisibility)
        end
    else
        RQE.debugLog("Available commands for /rqe:")
        RQE.debugLog("config - Opens the configuration panel")
        RQE.debugLog("frame, toggle - Toggles the RQE frame")
    end
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
            RQE.debugLog("Profile set to", profileToSet)
        else
            RQE.debugLog("Error: profileToSet is not a string.")
        end
        RQE.profileHasBeenSet = true
    end
end


-- Function to gather character info if addon is set to default to player name instead of accountwide
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
    else
        RQEFrame:Hide()
    end
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

    RQE.debugLog("About to SetPoint xPos: " .. xPos .. " yPos: " .. yPos .. " anchorPoint: " .. anchorPoint .. " IsShown: " .. tostring(RQEFrame:IsShown()))

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


-- ClearFrameData function
function RQE:ClearFrameData()
	-- Clear the Quest ID and Quest Name
    if RQE.QuestIDText then
        RQE.QuestIDText:SetText("")
    else
        RQE.debugLog("QuestIDText is not initialized.")
    end

    if RQE.QuestNameText then
        RQE.QuestNameText:SetText("")
    else
        RQE.debugLog("QuestNameText is not initialized.")
    end

	if RQE.QuestNameText then
		RQE.debugLog("QuestNameText current text:", RQE.QuestNameText:GetText())
	else
		RQE.debugLog("Warning - QuestNameText has NOT been initialized.")
	end
   
	-- Clear StepsText elements
	if RQE.StepsTexts then
	  for _, text in pairs(RQE.StepsTexts) do
		text:SetText("")  -- Clear the text of each element
	  end
	  RQE.debugLog("Cleared StepsTexts")
	else
	  RQE.debugLog("StepsTexts is not initialized.")
	end

    -- Clear CoordsText elements
    if RQE.CoordsTexts then
        for _, text in pairs(RQE.CoordsTexts) do
            text:SetText("")
        end
    else
        RQE.debugLog("CoordsTexts is not initialized.")
    end

	-- Clear QuestDirection Text
	if RQE.DirectionTextFrame then
		RQE.DirectionTextFrame:SetText("")
	else
		RQE.debugLog("DirectionTextFrame is not initialized.")
	end

    -- Clear QuestDescription Text
    if RQE.QuestDescription then
        RQE.QuestDescription:SetText("")
    else
        RQE.debugLog("QuestObjectives is not initialized.")
    end
	
    -- Clear QuestObjectives Text
    if RQE.QuestObjectives then
        RQE.QuestObjectives:SetText("")
    else
        RQE.debugLog("QuestObjectives is not initialized.")
    end
	
    -- Clear Waypoint Buttons
    if RQE.WaypointButtons then
        for _, button in pairs(RQE.WaypointButtons) do
            button:Hide()
        end
        RQE.debugLog("Hide WaypointButtons")
    else
        RQE.debugLog("WaypointButtons is not initialized.")
    end
	
	-- Clear Waypoint Button from "Unknown Quests Button"
	if RQE.UnknownQuestButton then
		RQE.UnknownQuestButton:Hide()
		RQE.debugLog("Hide Special WaypointButton")
	else
		RQE.debugLog("Special WaypointButton is not initialized.")
	end

	-- Clear SearchGroup Button
	if RQE.SearchGroupButton and RQE.SearchGroupButton:IsShown() then
	--if RQE.SearchGroupButton then
		RQE.SearchGroupButton:Hide()
		RQE.debugLog("Hide SearchGroup Button")
	else
		RQE.debugLog("SearchGroup Button is not initialized.")
	end

	RQE:ClearStepsTextInFrame()
end


-- Colorization of the RQEFrame
local function colorizeObjectives(objectivesText)
    local objectives = { strsplit("\n", objectivesText) }
    local colorizedText = ""

    for _, objective in ipairs(objectives) do
        local current, total = objective:match("(%d+)/(%d+)")  -- Extract current and total progress
        current, total = tonumber(current), tonumber(total)

        if current and total and current >= total then
            -- Objective complete, colorize in green
            colorizedText = colorizedText .. "|cff00ff00" .. objective .. "|r\n"
        else
            -- Objective incomplete, colorize in white
            colorizedText = colorizedText .. "|cffffffff" .. objective .. "|r\n"
        end
    end

    return colorizedText
end


-- UpdateFrame function
function UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
    RQE.debugLog("UpdateFrame: Received QuestID, QuestInfo, StepsText, CoordsText, MapIDs: ", questID, questInfo, StepsText, CoordsText, MapIDs)
	AdjustRQEFrameWidths(newWidth)
	
    if not questID then  -- Check if questID is nil
        RQE.debugLog("questID is nil.")
        return  -- Exit the function
    end
	
    if not StepsText or not CoordsText or not MapIDs then
        RQE.debugLog("Exiting UpdateFrame due to missing data.")
        return
    end

    if RQE.QuestIDText then
        RQE.QuestIDText:SetText("Quest ID: " .. (questID or "N/A"))
    else
        RQE.debugLog("RQE.QuestIDText is not initialized.")
    end
	
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    local questName = C_QuestLog.GetTitleForQuestID(questID)

    if RQE.QuestNameText then
        if questName then
            RQE.QuestNameText:SetText("Quest Name: " .. questName)
        else
            RQE.QuestNameText:SetText("Quest Name: N/A")
        end
    else
        RQE.debugLog("RQE.QuestNameText is not initialized.")
    end
    
	if questInfo then
		RQE.debugLog("questInfo.description is ", questInfo.description)
		RQE.debugLog("questInfo.objectives is ", questInfo.objectives)
		
		if RQE.CreateStepsText then  -- Check if CreateStepsText is initialized
			RQE:CreateStepsText(StepsText, CoordsText, MapIDs)
		else
			RQE.debugLog("RQEFrame.CreateStepsText is not initialized.")
		end
	else
		RQE.debugLog("Quest information not found in database for quest ID: " .. questID)
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
		else
			RQE.debugLog("RQE.QuestDescription is not initialized.")
		end
		
	else
		RQE.debugLog("questLogIndex is nil.")
	end
	else
		RQE.debugLog("RQE.QuestDescription is not initialized.")
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
    objectivesText = colorizeObjectives(objectivesText)

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
end


-- Function for Tracking World Quests
function UpdateWorldQuestTrackingForMap(uiMapID)
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


function UpdateWorldQuestTracking(questID)
    -- Check if questID is actually a quest ID and not a table or nil
    if type(questID) == "table" then
        RQE.infoLog("UpdateWorldQuestTracking was passed a table instead of a questID. Table contents:", questID)
        return
    elseif not questID then
        RQE.infoLog("UpdateWorldQuestTracking was passed a nil value for questID.")
        return
    end

    local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
    local watchType = C_QuestLog.GetQuestWatchType(questID)
    local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)

    if isWorldQuest and not isManuallyTracked then
        C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
        C_SuperTrack.SetSuperTrackedQuestID(questID)
    end
end


---------------------------------------------------
-- 10. Scenario Functions
---------------------------------------------------

-- Define the slash command handler function for timer start
local function HandleSlashCommands(msg, editbox)
    local command = string.lower(msg)

    if command == "start" then
        StartTimer() -- Start the timer
        print("Timer started.")
    elseif command == "stop" then
        StopTimer() -- Stop the timer
        print("Timer stopped.")
    else
        print("Invalid command. Use '/rqetimer start' to start the timer or '/rqetimer stop' to stop it.")
    end
end

-- Register the slash command
SLASH_MYTIMER1 = "/rqetimer"
SlashCmdList["MYTIMER"] = HandleSlashCommands


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
        RQE.infoLog("---")
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
                RQE.infoLog("---")
            end
        end
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
    RQEFrame:SetSize(400, 30)  -- If you want to make this configurable, you can use similar logic as above
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
        local foundQuestID = nil
        local inputTextLower = string.lower(text) -- Convert input text to lowercase for case-insensitive comparison

        -- If the input is not a number, search by title
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
            local questLink = GetQuestLink(foundQuestID)
            local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(foundQuestID)

			if questLink then
				print("Quest ID: " .. foundQuestID .. " - " .. questLink)
			else
				-- Fetch quest name using the API
				local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
				-- Format the message to display in light blue text and print it
				print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6[" .. questName .. "]|r")
			end

            if isQuestCompleted then
                DEFAULT_CHAT_FRAME:AddMessage("Quest completed by character", 0, 1, 0)  -- Green text
            else
                DEFAULT_CHAT_FRAME:AddMessage("Quest not completed by character", 1, 0, 0)  -- Red text
            end
        end
    end)

    -- Create the Examine button
    local examineButton = AceGUI:Create("Button")
    examineButton:SetText("Examine")
    examineButton:SetWidth(100)
    
    -- "Examine" button callback
	examineButton:SetCallback("OnClick", function()
		local inputText = editBox:GetText()
		local questID = tonumber(inputText)
		local foundQuestID = nil
		local inputTextLower = string.lower(inputText) -- Convert input text to lowercase for case-insensitive comparison

		-- If the input is not a number, search by title for partial matches
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
			-- Add the quest to the tracker
			C_QuestLog.AddQuestWatch(foundQuestID, Enum.QuestWatchType.Manual)
			
			local questLink = GetQuestLink(foundQuestID)
			if questLink then
				print("Quest ID: " .. foundQuestID .. " - " .. questLink)
			else
				-- Fetch quest name using the API
				local questName = C_QuestLog.GetTitleForQuestID(foundQuestID) or "Unknown Quest"
				-- Format the message to display in light blue text and print it
				print("|cFFFFFFFFQuest ID: " .. foundQuestID .. " - |r|cFFADD8E6[" .. questName .. "]|r")
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
        self.db.profile.enableFrame = false
    else
        RQEFrame:Show()
        self.db.profile.enableFrame = true
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE")
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


-- Function to retrieve questdata from API
function RQE:LoadQuestData(questID)
    -- Check if the quest data already exists
    if RQEDatabase and RQEDatabase[questID] then
        RQE.debugLog("Quest data for ID " .. questID .. " is already loaded.")
        return RQEDatabase[questID]
    else
        RQE.debugLog("Loading quest data for ID " .. questID)

        -- Fetch quest data from source or API
        local questData = RQE:FetchQuestDataFromSource(questID)
        if not questData or not next(questData) then
            -- If data is not in source, build it from WoW API
            questData = RQE:BuildQuestData(questID)
        end

        if questData then
            -- Store the loaded data in RQEDatabase
            RQEDatabase[questID] = questData
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
	local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
    local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}
	
    -- Check if questInfo is valid
    if not questInfo or not next(questInfo) then
        return nil, nil, nil
    end
	
    -- Iterate over questInfo, bypassing non-numeric keys like "title"
    for stepIndex, stepDetails in pairs(questInfo) do
        if type(stepIndex) == "number" then  -- This ensures we're only dealing with steps
            StepsText[stepIndex] = stepDetails.description
            CoordsText[stepIndex] = string.format("%.1f, %.1f", stepDetails.coordinates.x, stepDetails.coordinates.y)
            MapIDs[stepIndex] = stepDetails.coordinates.mapID
            -- Extract the first line of the description as the header, if needed
            questHeader[stepIndex] = stepDetails.description:match("^(.-)\n") or stepDetails.description
        end
    end

    -- Ensure the steps are returned in the correct order
    table.sort(StepsText, function(a, b) return a < b end)
    table.sort(CoordsText, function(a, b) return a < b end)
    table.sort(MapIDs, function(a, b) return a < b end)
    table.sort(questHeader, function(a, b) return a < b end)

    return StepsText, CoordsText, MapIDs, questHeader
end


function RQE:QuestComplete(questID)
    -- Update the RQEDatabase with the new quest description
    if RQEDatabase[questID] then  -- Make sure the quest exists in your database
        RQEDatabase[questID].description = "Quest Complete - Follow the waypoint for quest turn-in"
        -- Notify the system that a change has occurred
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

	-- -- After creating the linkFrame
	-- local dialogButton = _G[linkFrame:GetName().."Button"]
	-- if dialogButton then
		--dialogButton:Hide()
	-- end

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

	-- -- After creating the linkFrame
	-- local dialogButton = _G[linkFrame:GetName().."Button"]
	-- if dialogButton then
		--dialogButton:Hide()
	-- end

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
    
    -- Optionally, update the quest watch frame
    if QuestWatch_Update then
        QuestWatch_Update()
    end
end


function RQE.ScanAndCacheZoneQuests()
    RQE.ZoneQuests = {}

    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        if questInfo and not questInfo.isHeader then
            local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID, ignoreWaypoints)  -- Using fallback
            if zoneID then
                RQE.ZoneQuests[zoneID] = RQE.ZoneQuests[zoneID] or {}
                table.insert(RQE.ZoneQuests[zoneID], questInfo.questID)
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

    -- Add the quests from the selected zone to the watch list
    for _, questID in ipairs(questIDsForZone) do
        C_QuestLog.AddQuestWatch(questID)
    end

    -- Optionally, update the quest watch frame
    if QuestWatch_Update then
        QuestWatch_Update()
    end
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

    -- -- Optionally, update the quest watch frame if necessary
    -- if QuestWatch_Update then
        -- QuestWatch_Update()
    -- end
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
            local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID, ignoreWaypoints) -- Using fallback
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

    -- Optionally, update the quest watch frame
    if QuestWatch_Update then
        QuestWatch_Update()
    end
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
        print("|cFFFFA500No quests found for questline ID: " .. questLineID .. "|r")
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
            RQE.savedWorldQuestWatches[questID] = true
        end
    end
    -- Debug: Print the saved world quests
    for questID, _ in pairs(RQE.savedWorldQuestWatches) do
        RQE.infoLog("Saved World Quest ID:", questID)
    end
    RQE.infoLog("World Quest Saving complete")
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
            RQE.infoLog("Restoration Complete")
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


-- Function to print the tracking type of all watched world quests
function PrintTrackedWorldQuestTypes()
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            local trackingType = watchType == Enum.QuestWatchType.Automatic and "Automatic" or "Manual"
            print("Quest ID " .. questID .. " is being tracked " .. trackingType)
        end
    end
end

function UntrackAutomaticWorldQuests()
    local playerMapID = C_Map.GetBestMapForUnit("player")
    local questsInArea = C_TaskQuest.GetQuestsForPlayerByMapID(playerMapID)

    -- Convert the questsInArea to a lookup table for quicker access
    local questsInAreaLookup = {}
    for _, taskPOI in ipairs(questsInArea) do
        questsInAreaLookup[taskPOI.questId] = true
    end

    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            local watchType = C_QuestLog.GetQuestWatchType(questID)
            -- If the quest is not in the current area and it was tracked automatically, untrack it
            if watchType == Enum.QuestWatchType.Automatic then --and not questsInAreaLookup[questID] then
                C_QuestLog.RemoveWorldQuestWatch(questID)
                RQE.infoLog("Untracked automatic World Quest ID: " .. questID)
            end
        end
    end
end

SLASH_UNTRACKAUTO1 = '/untrackauto'
SlashCmdList["UNTRACKAUTO"] = UntrackAutomaticWorldQuests


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


-- -- Create a frame for the timer
-- local scenarioTimerFrame = CreateFrame("Frame", "ScenarioTimerFrame", RQEScenarioChildFrame)
-- scenarioTimerFrame:SetSize(100, 30) -- Size of the frame
-- scenarioTimerFrame:SetPoint("TOPRIGHT", RQEScenarioChildFrame, "TOPRIGHT") -- Position on the upper right of RQEScenarioChildFrame
-- scenarioTimerFrame:Show()

-- -- Set the frame strata
-- scenarioTimerFrame:SetFrameStrata("HIGH")

-- -- Set the frame level
-- scenarioTimerFrame:SetFrameLevel(5)

-- -- Create a font string for the timer text
-- scenarioTimerFrame.text = scenarioTimerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- scenarioTimerFrame.text:SetPoint("CENTER", scenarioTimerFrame, "CENTER")
-- scenarioTimerFrame.text:SetText("")


-- -- Function to update the timer
-- local function UpdateScenarioTimer()
    -- -- Get the timer information
    -- local duration, elapsed = select(10, C_Scenario.GetCriteriaInfo(1))
    -- if duration and elapsed then
        -- local timeLeft = duration - elapsed
        -- -- Format the time left as MM:SS
        -- local minutes = math.floor(timeLeft / 60)
        -- local seconds = timeLeft % 60
        -- scenarioTimerFrame.text:SetText(string.format("%02d:%02d", minutes, seconds))
    -- else
        -- -- Hide the frame if there's no timer
        -- scenarioTimerFrame:Hide()
    -- end
-- end

-- -- Set up an OnUpdate script to update the timer every second
-- scenarioTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    -- self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    -- if self.timeSinceLastUpdate >= 1 then
        -- UpdateScenarioTimer()
        -- self.timeSinceLastUpdate = 0
    -- end
-- end)

-- -- Function to start the timer when entering a scenario
-- function RQE:StartScenarioTimer()
    -- scenarioTimerFrame:Show()
    -- UpdateScenarioTimer()
-- end

-- -- Function to stop the timer when leaving a scenario
-- function RQE:StopScenarioTimer()
    -- scenarioTimerFrame:Hide()
-- end


---------------------------------------------------
-- 20. Experimental Testing Ground
---------------------------------------------------

-- Function to log scenario information, including previously ignored values
function RQE.LogScenarioInfo()
    if C_Scenario.IsInScenario() then
        local scenarioName, currentStage, numStages, flags, value5, value6, completed, xp, money, scenarioType, value11, textureKit = C_Scenario.GetInfo()
        
        -- print("Scenario Name: " .. tostring(scenarioName))
        -- print("Current Stage: " .. tostring(currentStage))
        -- print("Number of Stages: " .. tostring(numStages))
        -- print("Flags: " .. tostring(flags))
        -- print("Value 5: " .. tostring(value5))
        -- print("Value 6: " .. tostring(value6))
        -- print("Completed: " .. tostring(completed))
        -- print("XP Reward: " .. tostring(xp))
        -- print("Money Reward: " .. tostring(money))
        -- print("Scenario Type: " .. tostring(scenarioType))
        -- print("Value 11: " .. tostring(value11))
        -- print("Texture Kit: " .. tostring(textureKit))
		
        RQE.infoLog("Scenario Name: " .. tostring(scenarioName))
        RQE.infoLog("Current Stage: " .. tostring(currentStage))
        RQE.infoLog("Number of Stages: " .. tostring(numStages))
        RQE.infoLog("Flags: " .. tostring(flags))
        RQE.infoLog("Value 5: " .. tostring(value5))
        RQE.infoLog("Value 6: " .. tostring(value6))
        RQE.infoLog("Completed: " .. tostring(completed))
        RQE.infoLog("XP Reward: " .. tostring(xp))
        RQE.infoLog("Money Reward: " .. tostring(money))
        RQE.infoLog("Scenario Type: " .. tostring(scenarioType))
        RQE.infoLog("Value 11: " .. tostring(value11))
        RQE.infoLog("Texture Kit: " .. tostring(textureKit))
    end
end