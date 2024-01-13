--[[ 

Core.lua
Core file linking all other modules

]]


---------------------------
-- 1. Global Declarations
---------------------------

RQE = RQE or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}

-- Initialize your RQE addon with AceAddon
RQE = LibStub("AceAddon-3.0"):NewAddon("RQE", "AceConsole-3.0", "AceEvent-3.0")

-- AceConfig and AceConfigDialog references
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

---------------------------
-- 2. Imports
---------------------------

local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")

---------------------------
-- 3. Debugging Functions
---------------------------

-- Debug Functions
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
    print(output)
end

-- Function to log general info messages
function RQE.infoLog(message, ...)
    if RQE.db and RQE.db.profile.debugMode then
        local debugLevel = RQE.db.profile.debugLevel
		if debugLevel == "INFO" or debugLevel == "DEBUG" or debugLevel == "WARNING" or debugLevel == "CRITICAL" then
			RQE:CustomDebugLog(line, "cf9999FF", " Info: " .. message, ...)
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


-- Core.lua: After initializing RQE.db
if RQE.db and RQE.db.profile and RQE.db.profile.textSettings then
    RQE.warningLog("RQE.db.profile.textSettings is initialized.")
else
    RQE.warningLog("RQE.db.profile.textSettings is NOT initialized.")
end


-- Called when the addon is loaded
local defaults = {
    profile = {
        debugMode = false,
        debugLevel = "NONE",
        enableFrame = true,
        showMinimapIcon = false,
        showMapID = true,
        showCoordinates = true,
		autoSortRQEFrame = false,
        frameWidth = 400,
        frameHeight = 300,
        framePosition = {
            xPos = -40,
            yPos = -300,
            anchorPoint = "TOPRIGHT",
		},
		MainFrameOpacity = 0.45, 
		textSettings = {
		},
        QuestFramePosition = {
            xPos = -40,
            yPos = 125,
			anchorPoint = "BOTTOMRIGHT",
            frameWidth = 325,
            frameHeight = 450
		},
		QuestFrameOpacity = 0.35, 
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

---------------------------
-- 4. Initialization
---------------------------

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
	
    -- Register the options table and add it to the Blizzard options window
	print("self.options before registration:", self.options ~= nil)
	print("First key in self.options:", next(self.options))

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
            end
        end
    end)
end


-- Profile Refresh Function
function RQE:RefreshConfig()
    -- Here, you would reload any saved variables or reset frames, etc.
    -- Basically, apply the settings from the new profile.
	self:UpdateFrameFromProfile()
	
	-- Refreshes/Reads the Configuration settings for the customized text (in the current/new profile) and calls them when the profile is changed to that from an earlier profile
	RQE:ConfigurationChanged()
end


-- Initialize variable to keep track of whether the profile has been set
RQE.profileHasBeenSet = false


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


-- Initialize original dimensions
RQE.originalWidth = RQE.originalWidth or 0
RQE.originalHeight = RQE.originalHeight or 0
RQE.QToriginalWidth = RQE.QToriginalWidth or 0
RQE.QToriginalHeight = RQE.QToriginalHeight or 0


-- Function to initialize the addon's saved variables and properties
function RQE:Initialize()
    -- Initialize saved variables and other properties here
    RQECharacterDB = RQECharacterDB or {}
	RQEWaypoints = RQEWaypoints or {}
	RQE.debugLog("Waypoint and CharacterDB is initialized")
end


-- Initialize saved variables
RQECharacterDB = RQECharacterDB or {}
RQE.Version = C_AddOns.GetAddOnMetadata("RQE", "Version")
RQE.debugLog("Initialized saved variables.")


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


-- Function to update MapID display
function RQE:UpdateMapIDDisplay()
    local mapID = C_Map.GetBestMapForUnit("player")
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
    local yPos = self.db.profile.QuestFramePosition.yPos or 125

    -- Error handling
    local success, err = pcall(function()
        RQEQuestFrame:ClearAllPoints()
        RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
    end)

    if not success then
        RQE.debugLog("Error setting quest frame position: ", err)
    end
end


function RQE:QuestComplete(questID)
    -- Update the RQEDatabase with the new quest description
    if RQEDatabase[questID] then  -- Make sure the quest exists in your database
        RQEDatabase[questID].description = "Quest Complete - Follow the waypoint for quest turn-in"
        -- Notify the system that a change has occurred
        RQE:ConfigurationChanged()
    end
end


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
    local yPos = 125  -- Preset yPos
    
    -- Update the database
    RQE.db.profile.QuestFramePosition.anchorPoint = anchorPoint
    RQE.db.profile.QuestFramePosition.xPos = xPos
    RQE.db.profile.QuestFramePosition.yPos = yPos

    -- Update the frame position
    RQE:UpdateQuestFramePosition()
end


-- When the frame is maximized
function RQE:MaximizeQuestFrame()
    local defaultWidth = RQE.db.profile.QuestFrameWidth or 325  -- Replace 325 with the default width
    local defaultHeight = RQE.db.profile.QuestFrameHeight or 450  -- Replace 450 with the default height
    
    local width = RQE.db.profile.QuestFramePosition.originalWidth or defaultWidth
    local height = RQE.db.profile.QuestFramePosition.originalHeight or defaultHeight

    RQEQuestFrame:SetSize(width, height)
    RQE.db.profile.isQuestFrameMaximized = true
end


-- When the frame is minimized
function RQE:MinimizeQuestFrame()
    RQEQuestFrame:SetSize(325, 30)  -- If you want to make this configurable, you can use similar logic as above
    RQE.db.profile.isQuestFrameMaximized = false
end


-- Initialize lastSuperTrackedQuestID variable
local lastSuperTrackedQuestID = nil


-- Initialize Waypoint System
RQE.waypoints = {}

---------------------------
-- 5. Frame Initialization
---------------------------

RQEFrame = RQEFrame or CreateFrame("Frame", "RQEFrame", UIParent)

---------------------------
-- 6. UI Components
---------------------------

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

---------------------------
-- 7. Search Module
---------------------------

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
            if questLink then
                DEFAULT_CHAT_FRAME:AddMessage(questLink)
            else
                print("Quest link not available for Quest ID: " .. questID)
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
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
			
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


---------------------------
-- 8. Event Handling
---------------------------

-- Check for TomTom load
local function TomTom_Loaded(self, event, addon)
    if addon == "TomTom" then
        self:UnregisterEvent("ADDON_LOADED")
    end
end

---------------------------
-- 9. Quest Info Functions
---------------------------

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


-- Function to update Coordinates display
function RQE:UpdateCoordinates()
    local mapID = C_Map.GetBestMapForUnit("player")
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


-- Define the slash command handler function
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


-- UpdateFrame function
function UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
    RQE.debugLog("UpdateFrame: Received QuestID, QuestInfo, StepsText, CoordsText, MapIDs: ", questID, questInfo, StepsText, CoordsText, MapIDs)

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
	if RQE.SearchGroupButton then
		RQE.SearchGroupButton:Hide()
		RQE.debugLog("Hide SearchGroup Button")
	else
		RQE.debugLog("SearchGroup Button is not initialized.")
	end

	RQE:ClearStepsTextInFrame()
end

---------------------------
-- 10. Utility Functions
---------------------------

-- InitializeAddon function
function RQE:InitializeAddon()
    -- Your code here
end


-- InitializeFrame function
-- @param RQEFrame: The main frame object
function RQE:InitializeFrame()
    RQE.criticalLog("Entered InitializeFrame function")
    self:Initialize()  -- Call Initialize() within InitializeFrame
   
    -- Initialize search box (Now calling the function from Buttons.lua)
    RQE.Buttons.CreateSearchBox(RQEFrame)
    
    -- Initialize search button (Now calling the function from Buttons.lua)
    RQE.Buttons.CreateSearchButton(RQEFrame)
	RQE.criticalLog("Exiting InitializeFrame function")

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


-- Register the slash command
RQE:RegisterChatCommand("rqe", "SlashCommand")

---------------------------
-- 11. Finalization
---------------------------

function RQE:UpdateFrameFromProfile()
    local xPos = RQE.db.profile.framePosition.xPos or -40
    local yPos = RQE.db.profile.framePosition.yPos or -300
    RQEFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", xPos, yPos)
    -- Any other code to update your frame based on the profile
end