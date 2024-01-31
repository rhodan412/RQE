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
RQE = LibStub("AceAddon-3.0"):NewAddon("RQE", "AceConsole-3.0", "AceEvent-3.0")

-- AceConfig and AceConfigDialog references
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

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

    -- Print to chat
    --print(output)
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

    -- Print to chat
    --print(output)
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
        debugMode = false,
        debugLevel = "NONE",
        enableFrame = true,
        showMinimapIcon = false,
        showMapID = true,
        showCoordinates = true,
		autoSortRQEFrame = false,
		autoTrackProgress = true,
        frameWidth = 400,
        frameHeight = 300,
        framePosition = {
            xPos = -40,
            yPos = -300,
            anchorPoint = "TOPRIGHT",
		},
		MainFrameOpacity = 0.55, 
		textSettings = {
		},
        QuestFramePosition = {
            xPos = -40,
            yPos = 135,
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
	if autoSortRQEFrame then  -- replace with your actual checkbox frame name
		autoSortRQEFrame:SetChecked(RQE.db.profile.autoSortRQEFrame)
	end

	-- Initialize checkbox state for Auto Progress Update
	if autoTrackProgress then  -- replace with your actual checkbox frame name
		autoTrackProgress:SetChecked(RQE.db.profile.autoTrackProgress)
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

    AC:RegisterOptionsTable("RQE_Options", self.options)
    self.optionsFrame = ACD:AddToBlizOptions("RQE_Options", "Rhodan's Quest Explorer")

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
    local currentQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    if currentQuestID then
        local currentQuestInfo = RQEDatabase[currentQuestID]
        if currentQuestInfo then
            local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(currentQuestID)
			if RQEFrame:IsShown() and RQEFrame.currentQuestID == questID and RQE.db.profile.autoSortRQEFrame then
				UpdateFrame(currentQuestID, currentQuestInfo, StepsText, CoordsText, MapIDs)
			else
				return
			end			
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
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
    local mapID = GetQuestUiMapID(questID)
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
		
		--RQE.UnknownQuestButtonCalcNTrack()
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
		mapID = GetQuestUiMapID(questID)
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
    local yPos = self.db.profile.framePosition.yPos or -300

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


-- -- Function to update the frame based on the current profile settings
-- function RQE:UpdateFramePosition()
    -- -- When reading from DB
    -- local anchorPoint = self.db.profile.framePosition.anchorPoint or "TOPRIGHT"
	-- RQE.debugLog("anchorPoint in RQE:UpdateFramePosition is ", anchorPoint)  -- Debug statement

    -- -- Validation
    -- local validAnchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
    -- if not tContains(validAnchorPoints, anchorPoint) then
        -- anchorPoint = "TOPRIGHT"  -- Set to default
    -- end

    -- local xPos = self.db.profile.framePosition.xPos or -40
    -- local yPos = self.db.profile.framePosition.yPos or -300

    -- RQE.debugLog("About to SetPoint xPos: " .. xPos .. " yPos: " .. yPos .. " anchorPoint: " .. anchorPoint .. " IsShown: " .. tostring(RQEFrame:IsShown()))

    -- -- Error handling
    -- local success, err = pcall(function()
        -- RQEFrame:ClearAllPoints()
        -- RQEFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
    -- end)

    -- if not success then
        -- RQE.debugLog("Error setting frame position: ", err)
    -- end
-- end


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
    local yPos = self.db.profile.QuestFramePosition.yPos or 135

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
	RQE.UnknownQuestButton:Click()
	
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


-- function UpdateWorldQuestTrackingForMap(uiMapID)
    -- local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
    -- local trackedQuests = {}
    -- local maxTracked = 0
    -- local currentTrackedCount = 0  -- Initialize the counter for tracked quests

    -- -- -- Retrieve the currently tracked quests to avoid duplicates
    -- -- for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        -- -- local watchedQuestID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        -- -- if watchedQuestID then
            -- -- trackedQuests[watchedQuestID] = true
            -- -- currentTrackedCount = currentTrackedCount + 1
        -- -- end
    -- -- end

    -- if taskPOIs then --and currentTrackedCount < maxTracked then
        -- print("Found " .. #taskPOIs .. " taskPOIs for map ID: " .. uiMapID)
        -- for _, taskPOI in ipairs(taskPOIs) do
            -- local questID = taskPOI.questId
            -- if questID and C_QuestLog.IsWorldQuest(questID) then
                -- print("Checking World QuestID: " .. questID)
                -- -- Check if the quest is already tracked
				-- if not trackedQuests[questID] then
					-- print("Attempting to track World QuestID: " .. questID)
					-- C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
					-- trackedQuests[questID] = true  -- Mark as tracked
					-- --currentTrackedCount = currentTrackedCount + 1  -- Increment the count
					-- print("Manual World QuestID: " .. questID .. " added to watch list.")
					
					-- -- Check if we've reached the maximum number of tracked quests
					-- if currentTrackedCount >= maxTracked then
						-- print("Reached the maximum number of tracked World Quests: " .. maxTracked)
						-- break  -- Exit the loop as we've reached the limit
					-- end
				-- else
                    -- print("Manual World QuestID: " .. questID .. " added to watch list.")
                -- end
            -- end
        -- end
    -- end
	-- --RQE:ClearWQTracking()
-- end


-- Function that checks world quests in the player's zone
function UpdateWorldQuestTrackingForMap(uiMapID)
    local taskPOIs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
    local trackedQuests = {}
    local maxTracked = 5
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
                -- Check if the quest is already tracked
				if not trackedQuests[questID] then
					C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
					trackedQuests[questID] = true  -- Mark as tracked
					currentTrackedCount = currentTrackedCount + 1  -- Increment the count
					
					-- Check if we've reached the maximum number of tracked quests
					if currentTrackedCount >= maxTracked then
						break  -- Exit the loop as we've reached the limit
					end
                end
            end
        end
    end
end


-- Function for adding World Quest Watch to Tracker
function UpdateWorldQuestTracking(questID)
    -- Check if questID is actually a quest ID and not a table or nil
    if type(questID) == "table" then
        RQE.debugLog("UpdateWorldQuestTracking was passed a table instead of a questID. Table contents:", questID)
        return
    elseif not questID then
        RQE.debugLog("UpdateWorldQuestTracking was passed a nil value for questID.")
        return
    end

    local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
    local watchType = C_QuestLog.GetQuestWatchType(questID)
    local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)

    if isWorldQuest and not isManuallyTracked then
        C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
        --C_SuperTrack.SetSuperTrackedQuestID(questID)
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


-- Checks active timers and starts/stops the timer as necessary
function RQE.Timer_CheckTimers()
    -- Retrieve the timer information (example: for the first criteria)
    local duration, elapsed = select(10, C_Scenario.GetCriteriaInfo(1))
    ScenarioTimer_CheckTimers(GetWorldElapsedTimers())
	
    if duration and elapsed then
        local timeLeft = duration - elapsed
        if timeLeft > 0 then
            RQE.Timer_Start(timeLeft)
        else
            RQE.Timer_Stop()
        end
    else
        RQE.Timer_Stop()
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
    local yPos = -300  -- Preset yPos
    
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
    local yPos = 135  -- Preset yPos
    
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
    editBox:SetLabel("Enter Quest ID:")
    editBox:SetWidth(200)
    editBox:SetCallback("OnEnterPressed", function(widget, event, text)
        local questID = tonumber(text)
		if questID then
			local questLink = GetQuestLink(questID)
			local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)

			if questLink then
				DEFAULT_CHAT_FRAME:AddMessage(questLink)
			else
				print("Quest link not available for Quest ID: " .. questID)
			end

			if isQuestCompleted then
				DEFAULT_CHAT_FRAME:AddMessage("Quest completed by character", 0, 1, 0)  -- Green text
			else
				DEFAULT_CHAT_FRAME:AddMessage("Quest not completed by character", 1, 0, 0)  -- Red text
			end
		else
			print("Invalid Quest ID")
		end
	end)

    -- Create the Examine button
    local examineButton = AceGUI:Create("Button")
    examineButton:SetText("Examine")
    examineButton:SetWidth(100)
		
	-- "Examine" button callback
	examineButton:SetCallback("OnClick", function()
		local questID = tonumber(editBox:GetText())
		if questID then
			-- Fetch the necessary data
			local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
			local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Replace with your method to get this data

            -- Add the World Quest to the tracker
			C_QuestLog.AddWorldQuestWatch(questID, watchType or Enum.QuestWatchType.Manual)
			RQE.infoLog("adding world quest thru core" .. questID)
			C_QuestLog.AddQuestWatch(questID, watchType or Enum.QuestWatchType.Manual)
			RQE.infoLog("adding regular quest thru core" .. questID)
			
			-- Update the frame based on whether the quest is in the database
			if questInfo then
				RQE:ClearFrameData()
				UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			end
		else
			print("Invalid Quest ID")
		end
	end)
    return editBox, examineButton
end


---------------------------------------------------
-- 15. Utility Functions
---------------------------------------------------

-- InitializeAddon function
function RQE:InitializeAddon()
    -- Your code here
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
    if not questInfo then
        return nil, nil, nil
    end
    for i, step in ipairs(questInfo) do
        StepsText[i] = step.description
        CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
        MapIDs[i] = step.coordinates.mapID
        questHeader[i] = step.description:match("^(.-)\n") or step.description
    end
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
            local zoneID = C_TaskQuest.GetQuestZoneID(questInfo.questID) or GetQuestUiMapID(questInfo.questID)  -- Using fallback
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
        return a.zoneID < b.zoneID
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
            local currentQuestType = C_QuestLog.GetQuestType(questInfo.questID)
            if currentQuestType == questType then
                C_QuestLog.AddQuestWatch(questInfo.questID)
            else
                C_QuestLog.RemoveQuestWatch(questInfo.questID)
            end
        end
    end
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
        return a.campaignID < b.campaignID
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


function RQE.RequestAndCacheQuestLines()
    local uiMapID = C_Map.GetBestMapForUnit("player")
	RQE.QuestLines = RQE.QuestLines or {}
    C_QuestLine.RequestQuestLinesForMap(uiMapID)
    
    -- Assuming this API call populates data that can be retrieved immediately, which may not be the case.
    local questLinesInfo = C_QuestLine.GetAvailableQuestLines(uiMapID)
	if questLinesInfo then
		for _, info in pairs(questLinesInfo) do
			local questLineQuests = C_QuestLine.GetQuestLineQuests(info.questLineID)
			RQE.QuestLines[info.questLineID] = {
				name = info.questLineName,
				quests = questLineQuests
			}
		end
	end
end


function RQE.BuildQuestLineMenuList()
    local questLineMenuList = {}
    for questLineID, questLineData in pairs(RQE.QuestLines) do
        table.insert(questLineMenuList, {
            text = questLineData.name,
            func = function() RQE.filterByQuestLine(questLineID) end,
        })
    end
    
    -- Check if the questLineMenuList is empty and add a placeholder item if it is
    if #questLineMenuList == 0 then
        -- If there are no active quest lines, add a placeholder item
        table.insert(questLineMenuList, {
            text = "No active quest lines to filter.",
            func = function() print("No active quest lines to filter.") end,
            disabled = true  -- Make it non-selectable
        })
    end
    
    return questLineMenuList
end


function RQE.filterByQuestLine(questLineID)
    -- Get the quests for the selected questline
    local questIDsForLine = RQE.QuestLines[questLineID].quests
    local questIDSet = {}

    -- Create a set for quick lookup and print out each questID
    for _, questID in ipairs(questIDsForLine) do
        questIDSet[questID] = true
    end

    -- Get the total number of quests currently watched
    local numQuestWatches = C_QuestLog.GetNumQuestWatches()

    -- Loop through the current quest watches and remove those not in the selected questline
    for i = numQuestWatches, 1, -1 do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if not questIDSet[questID] then
            -- -- --C_QuestLog.RemoveQuestWatch(questID)
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
            if questType then
                local questTypeName = RQE.GetQuestTypeName(questType)
                if questTypeName then
                    RQE.QuestTypes[questType] = questTypeName  -- Store the quest type name
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
    return questTypeNames[questType] or "Unknown Type"
end


function RQE.BuildQuestTypeMenuList()
    local questTypeMenuList = {}
    RQE.QuestTypes = RQE.QuestTypes or {}  -- Ensure RQE.QuestTypes is not nil

    for questType, questTypeName in pairs(RQE.QuestTypes) do
        table.insert(questTypeMenuList, {
            questType = questType,  -- Store questType for sorting
            text = questType .. ": " .. questTypeName,
            func = function() RQE.filterByQuestType(questType) end,
        })
    end

    -- Sort the questTypeMenuList by questType
    table.sort(questTypeMenuList, function(a, b)
        return a.questType < b.questType
    end)

    -- Remove the questType key from the menu items after sorting
    for _, menuItem in ipairs(questTypeMenuList) do
        menuItem.questType = nil
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
    wipe(RQE.savedWorldQuestWatches) -- Clear the existing table
    for i = 1, C_QuestLog.GetNumWorldQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            RQE.savedWorldQuestWatches[questID] = true
            RQE.debugLog("Saving World Quest" .. questID)
        end
    end
    RQE.debugLog("World Quest Saving complete")
end


-- Function to restore saved watched world quests
function RQE:RestoreSavedWorldQuestWatches()
    local delay = 1 -- Delay in seconds
    for questID, _ in pairs(RQE.savedWorldQuestWatches) do
        if C_QuestLog.IsWorldQuest(questID) then
            C_Timer.After(delay, function()
                if not C_QuestLog.GetQuestWatchType(questID) then
                    C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
                end
            end)
            delay = delay + 1 -- Increase delay for the next quest to prevent throttling
        else
        end
    end
    -- Clear the saved world quest watches after a delay
    C_Timer.After(delay, function()
        wipe(RQE.savedWorldQuestWatches)
    end)
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
    local yPos = RQE.db.profile.framePosition.yPos or -300
    RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
end
