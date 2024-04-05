--[[ 

EventManager.lua
Specifically for the event-driven notifications. Handles alerts for quest completion or progress.

]]


---------------------------
-- 1. Global Declarations
---------------------------

-- Initialize RQE namespace and Buttons sub-table
RQE = RQE or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}
RQE.WorldQuestsInfo = RQE.WorldQuestsInfo or {}
RQEDatabase = RQEDatabase or {}

---------------------------
-- 2. Constants and Settings
---------------------------

-- Create an event frame
local Frame = CreateFrame("Frame")

local function HideObjectiveTracker()
    if ObjectiveTrackerFrame:IsShown() then
        ObjectiveTrackerFrame:Hide()
    end
end

---------------------------
-- 3. Event Registration
---------------------------

-- Register events to the frame
-- Define a list of events to register
local eventsToRegister = {
	"ACHIEVEMENT_EARNED",
	"ADDON_LOADED",
	--"BAG_UPDATE_COOLDOWN",
	"CLIENT_SCENE_CLOSED",
	--"CLIENT_SCENE_OPENED",
	"CONTENT_TRACKING_UPDATE",
	"CRITERIA_EARNED",
	--"CRITERIA_UPDATE",
	"JAILERS_TOWER_LEVEL_UPDATE",
	--"LEAVE_PARTY_CONFIRMATION",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LOGIN",
	"PLAYER_LOGOUT",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_STARTED_MOVING",
	"PLAYER_STOPPED_MOVING",
	"QUEST_ACCEPTED",
	"QUEST_AUTOCOMPLETE",
	"QUEST_CURRENCY_LOOT_RECEIVED",
	--"QUEST_DATA_LOAD_RESULT",
	"QUEST_FINISHED",
	"QUEST_LOG_CRITERIA_UPDATE",
	"QUEST_LOG_UPDATE",
	"QUEST_LOOT_RECEIVED",
	"QUEST_POI_UPDATE",
	"QUEST_REMOVED",
	"QUEST_TURNED_IN",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_WATCH_UPDATE",
	"QUESTLINE_UPDATE",
	--"SCENARIO_COMPLETED",
	--"SCENARIO_CRITERIA_UPDATE",
	"SCENARIO_POI_UPDATE",
	"SCENARIO_UPDATE",
	"START_TIMER",
	"SUPER_TRACKING_CHANGED",
	"TASK_PROGRESS_UPDATE",
	"TRACKED_ACHIEVEMENT_UPDATE",
	"UNIT_EXITING_VEHICLE",
	"UPDATE_INSTANCE_INFO",
	"VARIABLES_LOADED",
	"WORLD_STATE_TIMER_START",
	"WORLD_STATE_TIMER_STOP",
	"ZONE_CHANGED",
	"ZONE_CHANGED_INDOORS",
	"ZONE_CHANGED_NEW_AREA"

}


---------------------------
-- 4. Event Handling
---------------------------

-- On Event Handler
local function HandleEvents(frame, event, ...)
	--RQE.criticalLog("EventHandler triggered with event:", event)  -- Debug print here
	--print("EventHandler triggered with event:", event)  -- Debug print here

    local handlers = {
		ACHIEVEMENT_EARNED = RQE.handleAchievementTracking,
		ADDON_LOADED = RQE.handleAddonLoaded,
		CLIENT_SCENE_CLOSED = RQE.HandleClientSceneClosed,
		--CLIENT_SCENE_OPENED = RQE.HandleClientSceneOpened,
		CONTENT_TRACKING_UPDATE = RQE.handleAchievementTracking,
		CRITERIA_EARNED = RQE.handleCriteriaEarned,
		CRITERIA_UPDATE = RQE.handleAchievementTracking,
		JAILERS_TOWER_LEVEL_UPDATE = RQE.handleJailersUpdate,
		--LEAVE_PARTY_CONFIRMATION = handleScenario,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,  -- CHECK IF OKAY
		PLAYER_MOUNT_DISPLAY_CHANGED = RQE.handlePlayerRegenEnabled,
		PLAYER_REGEN_ENABLED = RQE.handlePlayerRegenEnabled,
		PLAYER_STARTED_MOVING = RQE.handlePlayerStartedMoving,
		PLAYER_STOPPED_MOVING = RQE.handlePlayerStoppedMoving, 
		QUEST_ACCEPTED = function(...) RQE.handleQuestAccepted(select(2, ...)) end,
		QUEST_AUTOCOMPLETE = RQE.handleQuestAutoComplete,
		QUEST_COMPLETE = RQE.handleQuestComplete,
		--QUEST_CURRENCY_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		--QUEST_DATA_LOAD_RESULT = RQE.handleQuestDataLoad,
		QUEST_FINISHED = RQE.handleQuestFinished,
		-- QUEST_LOG_CRITERIA_UPDATE = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		-- QUEST_LOG_UPDATE = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		-- QUEST_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		-- QUEST_POI_UPDATE = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		QUEST_REMOVED = function(...) RQE.handleQuestRemoved(select(1, ...), select(2, ...)) end, -- GOOD FUNCTION BUT DEBUG MSGS RETURN TABLES AND NOT QUESTID -- MAY BE BEST USING QUEST_WATCH_LIST_CHANGED
		QUEST_TURNED_IN = RQE.handleQuestTurnIn,
		QUEST_WATCH_LIST_CHANGED = RQE.handleQuestWatchListChanged, -- GOOD FUNCTION BUT DEBUG MSGS RETURN TABLES AND NOT QUESTID -- MAY BE BEST USING QUEST_WATCH_LIST_CHANGED
		QUEST_WATCH_UPDATE = RQE.handleQuestWatchUpdate, -- GOOD FUNCTION. HAS QUESTID when progress made but rest in tables
		--QUESTLINE_UPDATE = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		--SCENARIO_COMPLETED = handleScenarioComplete,
		--SCENARIO_CRITERIA_UPDATE = handleScenario,
		SCENARIO_POI_UPDATE = RQE.handleScenario,  -- CHECK IF OKAY
		SCENARIO_UPDATE = RQE.handleScenario,  -- CHECK IF OKAY
		START_TIMER = RQE.HandleClientSceneOpened,  -- CHECK IF OKAY
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,
		--TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,   --PENDING MORE WORK
		TRACKED_ACHIEVEMENT_UPDATE = RQE.handleTrackedAchieveUpdate,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		UPDATE_INSTANCE_INFO = RQE.handleInstanceInfoUpdate,
		VARIABLES_LOADED = RQE.handleVariablesLoaded,
		WORLD_STATE_TIMER_START = RQE.handleScenario,  -- CHECK IF OKAY
		WORLD_STATE_TIMER_STOP = RQE.handleTimerStop,  -- CHECK IF OKAY
		ZONE_CHANGED = RQE.handleZoneChange,
		ZONE_CHANGED_INDOORS = RQE.handleZoneChange,
		ZONE_CHANGED_NEW_AREA = RQE.handleZoneNewAreaChange
    }
    
    if handlers[event] then
        -- handlers[event](...)
        -- Use unpack to pass all received arguments including isLogin and isReload for PLAYER_ENTERING_WORLD
        handlers[event](frame, event, unpack({...}))
    else
        RQE.debugLog("Unhandled event:", event)
    end
end


function RQE.UnregisterUnusedEvents()
    -- Example: Unregister events that are no longer needed
    Frame:UnregisterEvent("EVENT_NAME")
end


-- Handles ACHIEVEMENT_EARNED and CONTENT_TRACKING_UPDATE Events
function RQE.handleAchievementTracking(...)
    local contentType, id, tracked = ...
	if contentType == 2 then -- Assuming 2 indicates an achievement
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: CONTENT_TRACKING_UPDATE event triggered for type: " .. tostring(type) .. ", id: " .. tostring(id) .. ", isTracked: " .. tostring(isTracked), 0xFA, 0x80, 0x72) -- Salmon color
			
		RQE.UpdateTrackedAchievementList()
		RQE.UpdateTrackedAchievements(contentType, id, tracked)
	else
		RQE.UpdateTrackedAchievementList()
	end
end


-- Handles CRITERIA_EARNED event
function RQE.handleCriteriaEarned(achievementID, description)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: CRITERIA_EARNED event triggered for achievementID: " .. tostring(achievementID) .. ", description: " .. description, 0xFA, 0x80, 0x72) -- Salmon color
	RQE.UpdateTrackedAchievementList()
end


-- Handles TRACKED_ACHIEVEMENT_UPDATE event
function RQE.handleTrackedAchieveUpdate(achievementID, criteriaID, elapsed, duration)
    --DEFAULT_CHAT_FRAME:AddMessage("Debug: TRACKED_ACHIEVEMENT_UPDATE event triggered for achievementID: " .. tostring(achievementID) .. ", criteriaID: " .. tostring(criteriaID) .. ", elapsed: " .. tostring(elapsed) .. ", duration: " .. tostring(duration), 0xFA, 0x80, 0x72) -- Salmon color		
	RQE.UpdateTrackedAchievementList()
end


-- Function that runs after leaving combat or PLAYER_REGEN_ENABLED, PLAYER_MOUNT_DISPLAY_CHANGED
function RQE.handlePlayerRegenEnabled()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerRegenEnabled function.", 1, 0.65, 0.5)
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.65, 0.5)
		else
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: No quest ID extracted from text.", 1, 0.65, 0.5)
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.65, 0.5)
		
        C_Timer.After(1, function()
            RQE:CheckAndAdvanceStep(questID)
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.65, 0.5)
        end)
    else
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: autoClickWaypointButton is disabled.", 1, 0.65, 0.5)
    end
end


-- Handling PLAYER_LOGIN Event
function RQE.handlePlayerLogin()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerLogin function.", 0.68, 0.85, 0.9)
	
	-- Initialize other components of your AddOn
	RQE:InitializeAddon()
	RQE:InitializeFrame()
	
	-- Add this line to update coordinates when player logs in
	RQE:UpdateCoordinates()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	
	-- Fetch current MapID to have option of appearing with Frame
	RQE:UpdateMapIDDisplay()

	-- Make sure RQE.db is initialized
	if RQE.db == nil then
		RQE.db = {}
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: RQE.db initialized.", 0.68, 0.85, 0.9)
	end
	
	-- Make sure the profileKeys table is initialized
	if RQE.db.profileKeys == nil then
		RQE.db.profileKeys = {}
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: RQE.db.profileKeys initialized.", 0.68, 0.85, 0.9)
	end

	if RQE.db.profile.removeWQatLogin then
		RemoveAllTrackedWorldQuests()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Removed all tracked World Quests.", 0.68, 0.85, 0.9)
	end
	
	RQE:ConfigurationChanged()

	local charKey = UnitName("player") .. " - " .. GetRealmName()
	-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Current charKey is: " .. tostring(charKey), 0.68, 0.85, 0.9)
	
	-- Debugging: Print the current charKey
	RQE.debugLog("Current charKey is:", charKey)
	
	-- This will set the profile to "Default"
	RQE.db:SetProfile("Default")
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Profile set to Default.", 0.68, 0.85, 0.9)
	
	if RQE.db.profile.autoTrackZoneQuests then
		RQE.DisplayCurrentZoneQuests()
		
		C_Timer.After(0.1, function()
			RQE.UpdateTrackedQuestsToCurrentZone()
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Updated tracked quests to current zone.", 0.68, 0.85, 0.9)
		end)
	end
end
		

-- Function to handle ADDON_LOADED
function RQE.handleAddonLoaded(addonName)
    -- Only proceed if RQE is the addon being loaded
    if addonName ~= "Rhodan's Quest Explorer" then return end
	
    -- Initialize the saved variable if it doesn't exist
    RQE_TrackedAchievements = RQE_TrackedAchievements or {}
    -- Ensure your addon uses this saved variable for tracking
    RQE.TrackedAchievementIDs = RQE_TrackedAchievements

    -- Add this line to update tracked achievements as soon as the addon is loaded
    RQE.UpdateTrackedAchievements()

    -- Hide the default objective tracker and make other UI adjustments after a short delay
    C_Timer.After(0.5, function()
		HideObjectiveTracker()

        if RQE.AdjustQuestItemWidths then
            RQE.AdjustQuestItemWidths(RQEQuestFrame:GetWidth())  -- Adjust quest item widths based on frame width
        end

        if RQE.UpdateFrameOpacity then
            RQE.UpdateFrameOpacity()  -- Update the frame opacity
        end
    end)
    
    -- Handle scenarios
    if C_Scenario.IsInScenario() then
        if RQE.PrintScenarioCriteriaInfoByStep then
            RQE.PrintScenarioCriteriaInfoByStep()  -- Print scenario information
        end
        RQE.ScenarioChildFrame:Show()
    else
        RQE.ScenarioChildFrame:Hide()
    end

    -- Handle scenario regardless of the condition
    if RQE.handleScenario then
        RQE.handleScenario()
    end

	if RQE.db.profile.autoTrackZoneQuests then
		RQE.DisplayCurrentZoneQuests()
		
		C_Timer.After(0.1, function()
			RQE.UpdateTrackedQuestsToCurrentZone()
		end)
	end
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
		
		RQE:CheckAndAdvanceStep(questID)
	end
	
	-- Updates frame with data from the super tracked quest (if any)
	RQE:ClearWaypointButtonData()
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
end


-- Function to handle LEAVE_PARTY_CONFIRMATION, SCENARIO_CRITERIA_UPDATE, SCENARIO_UPDATE, WORLD_STATE_TIMER_START
function RQE.handleScenario(self, event, ...)
    local args = {...}  -- Capture all arguments in a table
	--RQE.Timer_CheckTimers(timerID)
	RQE.LogScenarioInfo()
	RQE.PrintScenarioCriteriaInfoByStep()
	
    if event == "WORLD_STATE_TIMER_START" then
        local timerID = args[1]  -- For WORLD_STATE_TIMER_START, the first argument is timerID
        RQE.StopTimer()
		RQE.StartTimer()
		RQE.HandleTimerStart(timerID)
	end

    -- Handle other events
    if C_Scenario.IsInScenario() then
        RQE.ScenarioChildFrame:Show()
        RQE.InitializeScenarioFrame()
        RQE.UpdateScenarioFrame()
        RQE.StopTimer()
		RQE.StartTimer()
		RQE.Timer_CheckTimers()
    else
		RQE.StopTimer()
        RQE.ScenarioChildFrame:Hide()
    end

	-- -- Handles situation of being in Torghast
    -- RQE.UpdateTorghastDetails(level, type)
    -- C_Timer.After(4, RQE.InitializeScenarioFrame) -- Wait 4 seconds before re-initializing the scenario frame
	
	UpdateRQEQuestFrame()
    RQE.UpdateCampaignFrameAnchor()
	
	-- Check if still in a scenario (useful for relogs or loading screens)
	RQE.isInScenario = C_Scenario.IsInScenario()
	RQE:UpdateRQEQuestFrameVisibility()
end


-- Function to handle SCENARIO_COMPLETED:
function RQE.handleScenarioComplete()
	RQE.StopTimer()
	RQE.UpdateCampaignFrameAnchor()
	RQE.HandleTimerStop(timerID)
	
	UpdateRQEQuestFrame()
	
	-- Check if still in a scenario (useful for relogs or loading screens)
	RQE.isInScenario = C_Scenario.IsInScenario()
	RQE:UpdateRQEQuestFrameVisibility()
end


-- Function to handle WORLD_STATE_TIMER_STOP:
function RQE.handleTimerStop(self, event, ...)
    local args = {...}  -- Capture all arguments in a table
    --local timerID = args[1]  -- For WORLD_STATE_TIMER_STOP, if you need the timerID
	local timerID = ...;
	-- A world timer has stopped; you might want to stop your timer as well
    RQE.StopTimer()
end


-- Handles JAILERS_TOWER_LEVEL_UPDATE event
function RQE.handleJailersUpdate(level, type)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handleJailersUpdate function. Level: " .. tostring(level) .. ", Type: " .. tostring(type), 0.0, 1.0, 1.0)
	
	RQE.UpdateTorghastDetails(level, type)
	
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Scheduled InitializeScenarioFrame after 4 seconds.", 0.0, 1.0, 1.0)
    C_Timer.After(4, function()
        RQE.InitializeScenarioFrame()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Initialized Scenario Frame.", 0.0, 1.0, 1.0)
    end)
end
	

-- Handling PLAYER_STARTED_MOVING Event
function RQE.handlePlayerStartedMoving()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Player started moving.", 0.56, 0.93, 0.56)
	RQE:StartUpdatingCoordinates()
end	


-- Handling PLAYER_STOPPED_MOVING Event
function RQE.handlePlayerStoppedMoving()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Player stopped moving.", 0.93, 0.82, 0.25)
	RQE:StopUpdatingCoordinates()
	--SortQuestsByProximity()
	AdjustRQEFrameWidths()
	AdjustQuestItemWidths()
end	


-- Handling VARIABLES_LOADED Event
function RQE.handleVariablesLoaded(...)
	RQE:InitializeFrame()
	isVariablesLoaded = true
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	if C_Scenario.IsInScenario() then
		RQE.ScenarioChildFrame:Show()
		RQE.handleScenario()
	else
		RQE.ScenarioChildFrame:Hide()
		RQE.handleScenario()
	end
	
	RQE:ClearWQTracking()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())

	-- Load time End timer
	RQE.endTime = debugprofilestop()
	RQE.loadTime = RQE.endTime - RQE.startTime
	local loadTimeSeconds = RQE.loadTime / 1000
	RQE.infoLog("Rhodan's Quest Explorer (RQE) loaded in " .. RQE.loadTime .. " ms. (" .. loadTimeSeconds .. " seconds)")

	-- Initialize the frame based on saved settings
	if RQE.db.profile.enableFrame then
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
		
	-- Initialize the questing frame based on saved settings
	if RQE.db.profile.enableQuestFrame then
		RQEQuestFrame:Show()
	else
		RQEQuestFrame:Hide()
	end
	
	-- Initialize QuestNameText (or other fields that need early initialization)
	if not RQE.QuestNameText then
		-- Create/Initialize QuestNameText on PLAYER_LOGIN
		RQE.QuestNameText = RQEFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		RQE.QuestNameText:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 10, -10)
	end

	-- Initialize StepsText (or other fields that need early initialization)
	if not RQE.StepsText then
		RQE.StepsText = {}  -- Code to initialize StepsText
	end

	-- Initialize the minimap icon based on saved settings
	if RQE.db.profile.showMinimapIcon then
		RQE.MinimapButton:Show()
	else
		RQE.MinimapButton:Hide()
	end

	-- Initialize frame position based on saved variables
	RQE.debugLog("RQE.db after initialization:", RQE.db)

	local xPos = RQE.db.profile.framePosition.xPos
	local yPos = RQE.db.profile.framePosition.yPos
	local anchorPoint = RQE.db.profile.framePosition.anchorPoint

	local validAnchorPoints = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

	if xPos and yPos and anchorPoint and tContains(validAnchorPoints, anchorPoint) then
		RQEFrame:ClearAllPoints()  -- Clear any existing anchoring
		RQEFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	else
		RQE.debugLog("Invalid frame position or anchor point.")
	end

	-- Initialize frame maximized/minimized state
	if RQE.db.profile.isFrameMaximized then
		-- Code to maximize the frame
		RQEFrame:ClearAllPoints()
		RQEFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
		RQE:MaximizeFrame()
		if ScrollFrame then
			ScrollFrame:Show()
		else
			RQE.debugLog("ScrollFrame is not initialized.")
		end
		
		if slider then
			slider:Show()
		else
			RQE.debugLog("slider is not initialized.")
		end

		RQE.MinimizeButton:Show()
		RQE.MaximizeButton:Hide()

	else
		-- Code to minimize the frame
		RQEFrame:SetSize(435, 30)
		
		if ScrollFrame then
			ScrollFrame:Hide()
		end
		
		if slider then
			slider:Hide()
		end

		RQE.MaximizeButton:Show()
		RQE.MinimizeButton:Hide()
	end

	-- Clear frame data and waypoints
	C_Map.ClearUserWaypoint()
	
	if IsAddOnLoaded("TomTom") then
		TomTom.waydb:ResetProfile()
	end
		
	-- Initialize RQEQuestFrame position based on saved variables
	local xPos = RQE.db.profile.QuestFramePosition.xPos
	local yPos = RQE.db.profile.QuestFramePosition.yPos
	local anchorPoint = RQE.db.profile.QuestFramePosition.anchorPoint

	local validAnchorPoints = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

	if xPos and yPos and anchorPoint and tContains(validAnchorPoints, anchorPoint) then
		RQEQuestFrame:ClearAllPoints()  -- Clear any existing anchoring
		RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	else
		RQE.debugLog("Invalid quest frame position or anchor point.")
	end
end
		

-- Handling PLAYER_ENTERING_WORLD Event
function RQE.handlePlayerEnterWorld(self, event, isLogin, isReload)
	if isLogin then
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Loaded the UI from Login.", 0.93, 0.51, 0.93)
		RQE.RequestAndCacheQuestLines()
	elseif isReload then
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Loaded the UI after Reload.", 0.93, 0.51, 0.93)
		RQE.RequestAndCacheQuestLines()
	else
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Zoned between map instances.", 0.93, 0.51, 0.93)
	end

    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerEnterWorld function.", 0.93, 0.51, 0.93)
	
	C_Timer.After(1, function()  -- Delay of 1 second
		wipe(RQE.savedWorldQuestWatches)
		--RQE:HandleSuperTrackedQuestUpdate()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Cleared saved World Quest watches.", 0.93, 0.51, 0.93)
	end)	
	
	local mapID = C_Map.GetBestMapForUnit("player")
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Current map ID: " .. tostring(mapID), 0.93, 0.51, 0.93)
	
	RQE.Timer_CheckTimers(GetWorldElapsedTimers())
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked timers.", 0.93, 0.51, 0.93)
	
    if isReloadingUi then
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			RQE.handleScenario()
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: In a scenario, showing ScenarioChildFrame.", 0.93, 0.51, 0.93)
		else
			RQE.ScenarioChildFrame:Hide()
			RQE.handleScenario()
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Not in a scenario, hiding ScenarioChildFrame.", 0.93, 0.51, 0.93)
		end
    end
	
	-- Check if still in a scenario (useful for relogs or loading screens)
	RQE.isInScenario = C_Scenario.IsInScenario()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: isInScenario status updated.", 0.93, 0.51, 0.93)
	
	-- Visibility Check for RQEFrame and RQEQuestFrame
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Updated frame visibility.", 0.93, 0.51, 0.93)
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0.93, 0.51, 0.93)
	end
end	
		

-- Handling SUPER_TRACKING_CHANGED Event
function RQE.handleSuperTracking(...)
	RQEMacro:ClearMacroContentByName("RQE Macro")

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
		
		C_Timer.After(1, function()
			RQE:CheckAndAdvanceStep(questID)
		end)
	end
	
    -- Early return if manual super tracking wasn't performed
	if not RQE.ManualSuperTrack then
		--RQE:ShouldClearFrame()
        return
    end

    -- Early return if manual super tracking wasn't performed
	if RQE.ManualSuperTrack then
		RQE:ClearFrameData()
		RQE.lastClickedObjectiveIndex = 0
    end
	
    -- Reset the manual super tracking flag now that we're handling it
    RQE.ManualSuperTrack = nil
	
	QuestType()
	RQE.superTrackingChanged = true
	
	RQE.SaveSuperTrackData()
	--RQE.UnknownQuestButtonCalcNTrack()
	
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local mapID = C_Map.GetBestMapForUnit("player")
	
	-- Resets RQE.LastClickedWaypointButton to nil after Manual Super Track occurred
	if RQE.ManualSuperTrack == false and questID == extractedQuestID and extractedQuestID then
		RQE.LastClickedWaypointButton = nil
	end
	
	RQE:CreateUnknownQuestWaypoint(questID, mapID)

	local questName
	if questID then
		questName = C_QuestLog.GetTitleForQuestID(questID)
		local questLink = GetQuestLink(questID)  -- Generate the quest link
		RQE.debugLog("Quest Name and Quest Link: ", questName, questLink)

		-- Attempt to fetch quest info from RQEDatabase, use fallback if not present
		local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

		if StepsText and CoordsText and MapIDs then
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	else
		RQE.debugLog("questID is nil in SUPER_TRACKING_CHANGED event.")
		--SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	end

	-- Simulate clicking the RWButton
	if RQE.RWButton and RQE.RWButton:GetScript("OnClick") then
		RQE.RWButton:GetScript("OnClick")()
	end

	-- Simulate clicking the RWButton
	if RQE.RWButton and RQE.RWButton:GetScript("OnClick") then
		RQE.RWButton:GetScript("OnClick")()
	end
	
	C_Timer.After(0.5, function()
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end)
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
	end
	
	C_Timer.After(1, function()
		RQE.Buttons.UpdateMagicButtonVisibility()
	end)
end
		

-- Handling QUEST_ACCEPTED Event
function RQE.handleQuestAccepted(questLogIndex, questID)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_ACCEPTED event triggered for questID: " .. tostring(questID), 0.26, 0.42, 0.88) -- Sapphire color
	
    if questID then
        local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        local watchType = C_QuestLog.GetQuestWatchType(questID)
        local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)  -- Applies when world quest is manually watched and then accepted when player travels to world quest spot
        local questMapID = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID, ignoreWaypoints)
        local playerMapID = C_Map.GetBestMapForUnit("player")
        
        if isWorldQuest and not isManuallyTracked then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Automatically added World Quest watch for questID: " .. tostring(questID), 0.26, 0.42, 0.88)
        elseif isWorldQuest and isManuallyTracked then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Manually added World Quest watch for questID: " .. tostring(questID), 0.26, 0.42, 0.88)
        end

        -- Reapply the manual super-tracked quest ID if it's set and different from the current one
        if RQE.ManualSuperTrack then
            local superTrackIDToApply = RQE.ManualSuperTrackedQuestID --or RQE.lastSuperTrackedQuestID
            if superTrackIDToApply and superTrackIDToApply ~= C_SuperTrack.GetSuperTrackedQuestID() then
                C_SuperTrack.SetSuperTrackedQuestID(superTrackIDToApply)
                -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Reapplied manual super-tracked QuestID: " .. tostring(superTrackIDToApply), 0.26, 0.42, 0.88)
			end
        end
        
        if playerMapID and questMapID and playerMapID == questMapID then
            RQE.infoLog("questMapID is " .. questMapID .. " and playerMapID is " .. playerMapID)
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: questMapID is " .. tostring(questMapID) .. " and playerMapID is " .. tostring(playerMapID), 0.26, 0.42, 0.88) -- Sapphire color
            UpdateWorldQuestTrackingForMap(playerMapID)
        end
    end
	
    -- Visibility Update Check for RQEFrame & RQEQuestFrame
    RQE:UpdateRQEFrameVisibility()
    RQE:UpdateRQEQuestFrameVisibility()
end


		
-- Handling of UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS
function RQE.handleZoneChange(self, event, ...)
	if event == "UNIT_EXITING_VEHICLE" then
		-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: UNIT_EXITING_VEHICLE triggered for " .. tostring(...) .. ".", 0, 1, 1)  -- Cyan
	end

    -- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. SubZone Text: " .. tostring(GetSubZoneText()), 0, 1, 1)  -- Cyan
	C_Timer.After(1.0, function()  -- Delay of 1 second

		-- Get the current map ID
		local mapID = C_Map.GetBestMapForUnit("player")
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID), 0, 1, 1)  -- Cyan
		local questInfo = RQEDatabase[questID]
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values
		
		--RQE:UpdateMapIDDisplay()

		-- Call the functions to update the frame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		
		SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			RQE.handleScenario()
		else
			RQE.ScenarioChildFrame:Hide()
			RQE.handleScenario()
		end
	end)
end


-- Handles the event ZONE_CHANGED_NEW_AREA
function RQE.handleZoneNewAreaChange(self, event, ...)
    -- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. Zone Text: " .. GetZoneText(), 0, 1, 1)  -- Cyan
	C_Timer.After(0.5, function()

		-- Get the current map ID
		local mapID = C_Map.GetBestMapForUnit("player")
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
		local questInfo = RQEDatabase[questID]
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values
		
		RQE:UpdateMapIDDisplay()

		-- Call the functions to update the frame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		
		SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			RQE.handleScenario()
		else
			RQE.ScenarioChildFrame:Hide()
			RQE.handleScenario()
		end
		
		if RQE.db.profile.autoTrackZoneQuests then
			RQE.DisplayCurrentZoneQuests()
			
			C_Timer.After(0.1, function()
				RQE.UpdateTrackedQuestsToCurrentZone()
			end)
		end
	end)
end


-- Handles UPDATE_INSTANCE_INFO Event
function RQE.handleInstanceInfoUpdate()
	-- Updates the achievement list for criteria of tracked achievements
	RQE.UpdateTrackedAchievementList()
end


-- Handling multiple quest related events to update the main frame
function RQE.handleQuestStatusUpdate(...)
	isSuperTracking = C_SuperTrack.IsSuperTrackingContent()
	
    if isSuperTracking then
        local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
        if RQE.ManualSuperTrack and currentSuperTrackedQuestID ~= RQE.ManualSuperTrackedQuestID then
            -- The addon has a different quest set for manual super-tracking
            C_SuperTrack.SetSuperTrackedQuestID(RQE.ManualSuperTrackedQuestID)
        end
    end
	
	-- Attempt to fetch other necessary information using the currentQuestID
	local questInfo = RQEDatabase[questID]
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values

    -- Check if the current super-tracked quest is one we're interested in
    if RQE.searchedQuestID and questID == RQE.searchedQuestID then
        -- The super-tracked quest is the one we've set via search; proceed normally
        questInfo = RQEDatabase[questID]
        StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Adjust based on actual implementation
    elseif not RQE.searchedQuestID then
        -- No specific searched quest; proceed with default logic
        questInfo = RQEDatabase[questID]
        StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Adjust based on actual implementation
    else
        -- The super-tracked quest is not what we set; avoid changing focus
        return  -- Optionally, you could revert the super-tracked quest here
    end
	
	if not RQE.QuestLinesCached then
		RQE.RequestAndCacheQuestLines()
		RQE.QuestLinesCached = true -- Set a flag so we don't re-cache unnecessarily
	end
			
    RQE:ClearWQTracking()  -- Custom function to clear World Quest tracking if necessary
    UpdateRQEQuestFrame()  -- Custom function to update your frame
    SortQuestsByProximity()  -- Assuming this sorts quests displayed in RQEFrame by proximity
	
	C_Timer.After(0.5, function()
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end)

	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
end
	

-- Handling QUEST_COMPLETE event
function RQE.handleQuestComplete()
	local extractedQuestID
	
	isSuperTracking = C_SuperTrack.IsSuperTrackingContent()
	
    if isSuperTracking then
        local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    end
	
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(extractedQuestID), 0, 0.75, 0.75)
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for SuperTracked QuestID: " .. tostring(currentSuperTrackedQuestID), 0, 0.75, 0.75)
	end

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
	
    DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	
	-- Clears the RQEFrame when a quest is completed so that it stops reappearing in this frame (now handled through RQE:ShouldClearFrame)
	--RQE:ClearFrameData()
	RQE.searchedQuestID = nil -- THIS MIGHT NEED TO BE COMMENTED OUT IF THE SEARCHED QUEST GETS REMOVED ANYTIME A QUEST IS COMPLETED
	-- Reset manually tracked quests
	if RQE.ManuallyTrackedQuests then
		for questID in pairs(RQE.ManuallyTrackedQuests) do
			RQE.ManuallyTrackedQuests[questID] = nil
		end
	end
		
	RQE:QuestComplete(questID)
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then	
		RQE:CheckAndAdvanceStep(questID)
	end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
	
	-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)
end
		
-- Handling QUEST_AUTOCOMPLETE events
function RQE.handleQuestAutoComplete(...)
	local questID = ...  -- Extract the questID from the event
	local extractedQuestID
	
	isSuperTracking = C_SuperTrack.IsSuperTrackingContent()
	
    if isSuperTracking then
        local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    end
	
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(extractedQuestID), 0, 0.75, 0.75)
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(currentSuperTrackedQuestID), 0, 0.75, 0.75)
	end

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
	
    DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	
	-- Clears the RQEFrame when a quest is completed so that it stops reappearing in this frame (now handled through RQE:ShouldClearFrame)
	--RQE:ClearFrameData()
	RQE.searchedQuestID = nil -- THIS MIGHT NEED TO BE COMMENTED OUT IF THE SEARCHED QUEST GETS REMOVED ANYTIME A QUEST IS COMPLETED
	-- Reset manually tracked quests
	if RQE.ManuallyTrackedQuests then
		for questID in pairs(RQE.ManuallyTrackedQuests) do
			RQE.ManuallyTrackedQuests[questID] = nil
		end
	end
		
	RQE:QuestComplete(questID)
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then	
		RQE:CheckAndAdvanceStep(questID)
	end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
	
	DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)
end
		
-- Handles the Saving of World Quests
function RQE.HandleClientSceneOpened()
    RQE:SaveWorldQuestWatches()  -- Save the watch list when a scene is opened
end


-- Handles the Restoration of World Quests after event CLIENT_SCENE_CLOSED
function RQE.HandleClientSceneClosed()
    RQE.isRestoringWorldQuests = true
    C_Timer.After(1, function()
        RQE:RestoreSavedWorldQuestWatches()
        -- Set isRestoringWorldQuests back to false after all quests are restored
        C_Timer.After(2, function() -- adjust the delay as needed
            RQE.isRestoringWorldQuests = false
        end)
    end)
end

		
-- Handling QUEST_REMOVED event
function RQE.handleQuestRemoved(questID, wasReplayQuest)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_REMOVED event triggered for questID: " .. tostring(questID) .. ", wasReplayQuest: " .. tostring(wasReplayQuest), 0.82, 0.70, 0.55) -- Light brown color
	
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()
	RQE:ClearWQTracking()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	
	RQE.UntrackAutomaticWorldQuests()
	
    -- Check if the questID is valid and if it was being tracked automatically
    if questID and RQE.TrackedQuests[questID] == Enum.QuestWatchType.Automatic then
        -- Remove the quest from the tracking list
        C_QuestLog.RemoveWorldQuestWatch(questID)
        -- Clear the saved state for this quest
        RQE.TrackedQuests[questID] = nil
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Removed automatic World Quest watch for questID: " .. tostring(questID), 0.82, 0.70, 0.55) -- Light brown color
    end
	
	-- Visibility Check for RQEFrame and RQEQuestFrame
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()
end
	
		
-- Handling QUEST_WATCH_UPDATE event
function RQE.handleQuestWatchUpdate(questID)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_WATCH_UPDATE event triggered for questID: " .. tostring(questID), 0.56, 0.93, 0.56) -- Light Green
	
    -- Retrieve the current watched quest ID if needed
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Current super tracked quest ID: " .. tostring(currentSuperTrackedQuestID), 0.56, 0.93, 0.56)
	local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest info - QuestID: " .. tostring(questInfo.questID) .. ", Name: " .. tostring(questInfo.name), 0.56, 0.93, 0.56)
    local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Is quest completed: " .. tostring(isQuestCompleted), 0.56, 0.93, 0.56)
	
    -- If you need details about the quest, fetch them here
    local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: StepsText: " .. tostring(StepsText), 0.56, 0.93, 0.56)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: CoordsText: " .. tostring(CoordsText), 0.56, 0.93, 0.56)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: MapIDs: " .. tostring(MapIDs), 0.56, 0.93, 0.56)
	
	-- if isQuestCompleted or RQE.searchedQuestID == nil then
		-- RQE:ClearFrameData()
		-- print("Frame data cleared")
	-- end

	if questID then
		RQEQuestFrame:ClearAllPoints()
		
		-- Adds quest to watch list when progress made
		C_QuestLog.AddQuestWatch(questID)
		
		UpdateRQEQuestFrame()

		-- Update RQEFrame here if needed
		-- UpdateRQEFrame() -- Pseudo-function, replace with actual function calls needed to update RQEFrame

		-- Further processing
		QuestType()
		SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		
		C_Timer.After(0.5, function()
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)
			
		-- Visibility Update Check for RQEQuestFrame
		RQE:UpdateRQEQuestFrameVisibility()
		
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Added quest to watch list and updated frames.", 0.56, 0.93, 0.56)
	end
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Extracted quest ID from QuestIDText: " .. tostring(extractedQuestID), 0.56, 0.93, 0.56)
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
		
		RQE:CheckAndAdvanceStep(questID)
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checking and advancing step for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
	end
end


-- Handling QUEST_WATCH_LIST_CHANGED event
function RQE.handleQuestWatchListChanged(questID, added)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_WATCH_LIST_CHANGED event triggered for questID: " .. tostring(questID) .. ", added: " .. tostring(added), 0.4, 0.6, 1.0)   -- Light Blue
	
    -- Optionally log the event for debugging
    -- print("QUEST_WATCH_LIST_CHANGED event received", questID, added)
	local questInfo = RQEDatabase[questID] -- Example lookup, replace with actual implementation
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

    -- Debug messages for the above variables
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: StepsText: " .. tostring(StepsText), 0.4, 0.6, 1.0)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: CoordsText: " .. tostring(CoordsText), 0.4, 0.6, 1.0)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: MapIDs: " .. tostring(MapIDs, ", "), 0.4, 0.6, 1.0)
	
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
    -- Immediate update to the visibility and content of the quest frames
    -- This ensures that any change in the watch list is reflected in your addon's UI
    
    UpdateRQEQuestFrame()  -- Ensure this function is defined to refresh the content based on current quest watch list
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQE:ClearWQTracking()
    RQE:UpdateRQEQuestFrameVisibility()
    -- If you need to refresh or update specific quest information based on questID,
    -- consider implementing that logic here or in the called functions.
	
    if questInfo then
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
    else
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: No quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
    end
end


-- Handling QUEST_TURNED_IN event
function RQE.handleQuestTurnIn()
	print("RQE.handleQuestTurnIn called")
    if not questID then return end  -- Ensure there's a valid questID from the event

	RQEMacro:ClearMacroContentByName("RQE Macro")

    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local displayedQuestID = RQE.QuestIDText and tonumber(strmatch(RQE.QuestIDText:GetText() or "", "%d+"))

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or superTrackedQuestID
		
		C_Timer.After(1, function()
			RQE:CheckAndAdvanceStep(questID)
		end)
	end
	
    -- Verify if the turned-in quest matches the currently displayed or super tracked quest
    if superTrackedQuestID == questID or displayedQuestID == questID then
        -- Clear data and update frame after a brief delay to ensure quest log updates
        C_Timer.After(0.5, function()
            --RQE:ClearFrameData()  -- This method should clear the content from the RQEFrame
			RQE:ShouldClearFrame()
            -- Optionally, you might want to update the frame to show the next priority quest or clear visibility
        end)
    end

    -- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
    -- This might involve checking if there are other quests to display or adjusting UI elements
    RQE:UpdateRQEFrameVisibility()
    RQE:UpdateRQEQuestFrameVisibility()
end


-- Handling QUEST_FINISHED event
function RQE.handleQuestFinished()
    -- DEFAULT_CHAT_FRAME:AddMessage("RQE.handleQuestFinished called.", 1, 0.75, 0.79)
	
	RQEMacro:ClearMacroContentByName("RQE Macro")
	-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Cleared RQE Macro.", 1, 0.75, 0.79)
	
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    local displayedQuestID = RQE.QuestIDText and tonumber(strmatch(RQE.QuestIDText:GetText() or "", "%d+"))

    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1, 0.75, 0.79)
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: DisplayedQuestID: " .. tostring(displayedQuestID), 1, 0.75, 0.79)
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
		
		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or superTrackedQuestID
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.75, 0.79)
		
		C_Timer.After(1, function()
			RQE:CheckAndAdvanceStep(questID)
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
		end)
	end

    -- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
    -- This might involve checking if there are other quests to display or adjusting UI elements
    RQE:UpdateRQEFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	
    RQE:UpdateRQEQuestFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
end

	
-- Handling PLAYER_LOGOUT event
function RQE.handlePlayerLogout(...)
	RQE:SaveFramePosition()  -- Custom function that saves frame's position
end


-- Set the event handler
Frame:SetScript("OnEvent", HandleEvents)


-- Loop through the list and register each event
for _, eventName in ipairs(eventsToRegister) do
    Frame:RegisterEvent(eventName)
end


---------------------------
-- 5. Event Callbacks
---------------------------

-- Add a click event to SearchButton
if RQE.SearchButton then
    RQE.SearchButton:SetScript("OnClick", function(self, button)
        RQE.isSearchFrameShown = not RQE.isSearchFrameShown  -- Toggle the variable
        CreateSearchFrame(RQE.isSearchFrameShown)  -- Pass the updated variable
    end)
else
	RQE.debugLog("RQE.SearchButton is not initialized.")  -- Debug statement
end


-- Register "Enter" key event for SearchEditBox
SearchEditBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()  -- remove focus from the edit box
    -- Implement your search logic here, likely the same as the click event
end)