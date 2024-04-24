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

-- Hides the Objective Tracker (by default)
function HideObjectiveTracker()
	if ObjectiveTrackerFrame:IsShown() then
		ObjectiveTrackerFrame:Hide()
	end
end


-- Function to Display the Objective Tracker
function RQE:ToggleObjectiveTracker()
    if ObjectiveTrackerFrame:IsShown() then
        ObjectiveTrackerFrame:Hide()
    else
		ObjectiveTrackerFrame:Show()
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
	"BOSS_KILL",
	"CLIENT_SCENE_CLOSED",
	"CLIENT_SCENE_OPENED",
	"CONTENT_TRACKING_UPDATE",
	"CRITERIA_EARNED",
	--"CRITERIA_UPDATE",
	"ITEM_COUNT_CHANGED",
	"JAILERS_TOWER_LEVEL_UPDATE",
	"LEAVE_PARTY_CONFIRMATION",
	"PLAYER_CONTROL_GAINED",
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
	--"QUEST_FINISHED",   -- MAY BE REDUNDANT
	"QUEST_LOG_CRITERIA_UPDATE",
	"QUEST_LOG_UPDATE",  -- Possible High Lag and unnecessary event firing/frequency, but necessary for updating RQEFrame and RQEQuestFrame when partial quest progress is made
	--"QUEST_LOOT_RECEIVED",
	--"QUEST_POI_UPDATE",  -- Possible High Lag and unnecessary event firing/frequency
	"QUEST_REMOVED",
	"QUEST_TURNED_IN",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_WATCH_UPDATE",
	-- "QUESTLINE_UPDATE",  -- Commenting out as this fires too often resulting in some lag
	"SCENARIO_COMPLETED",
	--"SCENARIO_CRITERIA_UPDATE",  -- IT SEEMS TO CAUSE SIGNIFICANT LAG BETWEEN STAGES
	--"SCENARIO_POI_UPDATE",
	"SCENARIO_UPDATE",
	"START_TIMER",
	"SUPER_TRACKING_CHANGED",
	"TASK_PROGRESS_UPDATE",
	"TRACKED_ACHIEVEMENT_UPDATE",
	"UNIT_AURA",
	"UNIT_EXITING_VEHICLE",
	"UNIT_QUEST_LOG_CHANGED",
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
		BOSS_KILL = RQE.handleBossKill,
		CLIENT_SCENE_CLOSED = RQE.HandleClientSceneClosed,
		CLIENT_SCENE_OPENED = function(...) RQE.HandleClientSceneOpened(select(1, ...)) end,  -- MAY NEED TO COMMENT OUT AGAIN
		CONTENT_TRACKING_UPDATE = RQE.handleAchievementTracking,
		CRITERIA_EARNED = RQE.handleCriteriaEarned,
		-- CRITERIA_UPDATE = RQE.handleAchievementTracking,
		ITEM_COUNT_CHANGED = RQE.handleItemCountChanged,
		JAILERS_TOWER_LEVEL_UPDATE = RQE.handleJailersUpdate,
		LEAVE_PARTY_CONFIRMATION = RQE.handleScenarioEvent,
		PLAYER_CONTROL_GAINED = RQE.handlePlayerControlGained,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,
		PLAYER_MOUNT_DISPLAY_CHANGED = RQE.handlePlayerRegenEnabled,
		PLAYER_REGEN_ENABLED = RQE.handlePlayerRegenEnabled,
		PLAYER_STARTED_MOVING = RQE.handlePlayerStartedMoving,
		PLAYER_STOPPED_MOVING = RQE.handlePlayerStoppedMoving, 
		QUEST_ACCEPTED = function(...) RQE.handleQuestAccepted(select(2, ...)) end,
		QUEST_AUTOCOMPLETE = RQE.handleQuestAutoComplete,
		QUEST_COMPLETE = RQE.handleQuestComplete,
		QUEST_CURRENCY_LOOT_RECEIVED = function(...) RQE.handleQuestCurrencyLootReceived(select(1, ...), select(2, ...), select(3, ...)) end,
		--QUEST_DATA_LOAD_RESULT = RQE.handleQuestDataLoad,
		QUEST_FINISHED = RQE.handleQuestFinished,
		QUEST_LOG_CRITERIA_UPDATE = function(...) RQE.handleQuestLogCriteriaUpdate(select(1, ...), select(2, ...), select(3, ...), select(4, ...), select(5, ...)) end,
		QUEST_LOG_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_LOOT_RECEIVED = function(...) RQE.handleQuestLootReceived(select(1, ...), select(2, ...), select(3, ...)) end,
		QUEST_POI_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_REMOVED = function(...) RQE.handleQuestRemoved(select(1, ...), select(2, ...)) end,
		QUEST_TURNED_IN = function(...) RQE.handleQuestTurnIn(select(1, ...), select(2, ...), select(3, ...)) end,
		QUEST_WATCH_LIST_CHANGED = RQE.handleQuestWatchListChanged,
		QUEST_WATCH_UPDATE = function(...) RQE.handleQuestWatchUpdate(select(1, ...)) end,
		QUESTLINE_UPDATE = function(...) RQE.handleQuestlineUpdate(select(1, ...)) end,
		-- SCENARIO_POI_UPDATE = RQE.handleScenarioEvent,,   -- MAY BE SLOWING SUPER BLOOM IN THE MIDDLE SECTION ON THE SOUTH ROUTE
		SCENARIO_COMPLETED = RQE.handleScenarioEvent,
		SCENARIO_CRITERIA_UPDATE = RQE.handleScenarioEvent,
		SCENARIO_UPDATE = RQE.handleScenarioEvent,
		START_TIMER = function(...) RQE.handleStartTimer(select(1, ...), select(2, ...), select(3, ...)) end,
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,  -- ADD MORE DEBUG AND MAKE SURE IT WORKS
		TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,
		TRACKED_ACHIEVEMENT_UPDATE = RQE.handleTrackedAchieveUpdate,
		UNIT_AURA = RQE.handleUnitAura,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		UNIT_QUEST_LOG_CHANGED = RQE.handleUnitQuestLogChange,
		UPDATE_INSTANCE_INFO = RQE.handleInstanceInfoUpdate,
		VARIABLES_LOADED = RQE.handleVariablesLoaded,
		WORLD_STATE_TIMER_START = function(...) RQE.handleWorldStateTimerStart(select(1, ...), select(2, ...), select(3, ...)) end,
		WORLD_STATE_TIMER_STOP = function(...) RQE.handleWorldStateTimerStop(select(1, ...), select(2, ...), select(3, ...)) end,
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
-- Fired when an achievement is gained
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
-- Fired when a timed event for an achievement begins or ends. The achievement does not have to be actively tracked for this to trigger
function RQE.handleTrackedAchieveUpdate(achievementID, criteriaID, elapsed, duration)
    ---- DEFAULT_CHAT_FRAME:AddMessage("Debug: TRACKED_ACHIEVEMENT_UPDATE event triggered for achievementID: " .. tostring(achievementID) .. ", criteriaID: " .. tostring(criteriaID) .. ", elapsed: " .. tostring(elapsed) .. ", duration: " .. tostring(duration), 0xFA, 0x80, 0x72) -- Salmon color		
	RQE.UpdateTrackedAchievementList()
end


-- Handles ITEM_COUNT_CHANGED event
function RQE.handleItemCountChanged(self, event, itemID)
    itemID = tostring(itemID)  -- Ensure the itemID is treated as a string if needed
    RQE.infoLog("Item count changed for itemID:", itemID)
    
	RQE:StartPeriodicChecks()
end


-- Function that runs after leaving combat or PLAYER_REGEN_ENABLED, PLAYER_MOUNT_DISPLAY_CHANGED
-- Fired after ending combat, as regen rates return to normal. Useful for determining when a player has left combat. 
-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
function RQE.handlePlayerRegenEnabled()
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerRegenEnabled function.", 1, 0.65, 0.5)
		
    -- Check for Dragonriding & Capture and print the current states for debugging purposes
	if RQE.CheckForDragonMounts() then
		RQE.isDragonRiding = true
	else
		RQE.isDragonRiding = false
	end
	
    local isFlying = IsFlying("player")
    local onTaxi = UnitOnTaxi("player")
    local dragonRiding = RQE.isDragonRiding
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		local currentSuperTrackedquestID = C_SuperTrack.GetSuperTrackedQuestID()
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.65, 0.5)
		else
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: No quest ID extracted from text.", 1, 0.65, 0.5)
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.65, 0.5)
		
        C_Timer.After(0.5, function()
            RQE:CheckAndAdvanceStep(questID)
            -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.65, 0.5)
        end)
    else
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: autoClickWaypointButton is disabled.", 1, 0.65, 0.5)
    end
end


-- Handling PLAYER_LOGIN Event
-- Triggered immediately before PLAYER_ENTERING_WORLD on login and UI Reload, but NOT when entering/leaving instances
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
-- Fires after an AddOn has been loaded
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
	RQE.updateScenarioUI()

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
		
		C_Timer.After(0.5, function()
			RQE:CheckAndAdvanceStep(questID)
		end)
		
		C_Timer.After(1, function()
			-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
			RQE:StartPeriodicChecks()
		end)
	end
	
	-- Updates frame with data from the super tracked quest (if any)
	RQE:ClearWaypointButtonData()
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
end


-- Function to handle BOSS_KILL event to update Scenario Frame
function RQE.handleBossKill()
	if C_Scenario.IsInScenario() then
		RQE.UpdateScenarioFrame()
	end
end


-- Function to handle SCENARIO_COMPLETED, SCENARIO_UPDATE, LEAVE_PARTY_CONFIRMATION, SCENARIO_POI_UPDATE:
function RQE.handleScenarioEvent(self, event, ...)
    local args = {...}  -- Proper unpacking of additional arguments
    assert(type(args) == "table", "Expected arguments to be passed as a table")
	
    if event == "SCENARIO_COMPLETED" then
		-- startTime = debugprofilestop()  -- Start timer
		-- Extract specific arguments for SCENARIO_COMPLETED
		local questID, xp, money = unpack(args)
		-- DEFAULT_CHAT_FRAME:AddMessage("SC Debug: " .. tostring(event) .. " completed. Quest ID: " .. tostring(questID) .. ", XP: " .. tostring(xp) .. ", Money: " .. tostring(money), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
        RQE.saveScenarioData(self, questID, xp, money)
		
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_COMPLETED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	end
	
    if event == "SCENARIO_UPDATE" then
		-- startTime = debugprofilestop()  -- Start timer
        -- Extract specific argument for SCENARIO_UPDATE
        local newStep = unpack(args)
		-- DEFAULT_CHAT_FRAME:AddMessage("SU Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)
        -- Call another function if necessary, for example:
        RQE.saveScenarioData(self, event, newStep)
		
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	end
	
	if event == "SCENARIO_CRITERIA_UPDATE" then
		-- startTime = debugprofilestop()  -- Start timer
        -- Extract specific argument for SCENARIO_CRITERIA_UPDATE
        local criteriaID = unpack(args)
		-- DEFAULT_CHAT_FRAME:AddMessage("SCU Debug: " .. tostring(event) .. " triggered. Criteria ID: " .. tostring(criteriaID), 0.9, 0.7, 0.9)
        -- Call another function if necessary, for example:
        RQE.saveScenarioData(self, event, criteriaID)
		
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_CRITERIA_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	end

	RQE.updateScenarioUI()
end


-- Function to save different types of scenario data
function RQE.saveScenarioData(self, event, ...)
    local args = {...}

    -- Initialize the storage table if it doesn't already exist
    RQE.ScenarioData = RQE.ScenarioData or {}

    -- Handle data based on event type
    if event == "SCENARIO_COMPLETED" then
        local questID, xp, money = unpack(args)
        if questID and xp and money then  -- Make sure all data is present
            table.insert(RQE.ScenarioData, {type = event, questID = questID, xp = xp, money = money})
			-- DEFAULT_CHAT_FRAME:AddMessage("SC Debug: " .. tostring(event) .. " completed. Quest ID: " .. tostring(questID) .. ", XP: " .. tostring(xp) .. ", Money: " .. tostring(money), 0.9, 0.7, 0.9)
        end
    elseif event == "SCENARIO_UPDATE" then
        local newStep = unpack(args)
        if newStep then  -- Check if the step information is present
            table.insert(RQE.ScenarioData, {type = event, newStep = newStep})
			-- DEFAULT_CHAT_FRAME:AddMessage("SU 01 Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
        end
    elseif event == "SCENARIO_CRITERIA_UPDATE" then
        local criteriaID = unpack(args)
        if criteriaID then
            table.insert(RQE.ScenarioData, {type = event, criteriaID = criteriaID})
            -- DEFAULT_CHAT_FRAME:AddMessage("Saved Criteria Update Data: Criteria ID=" .. tostring(criteriaID), 0.9, 0.7, 0.9)
        end
    end
end


-- Function to handle START_TIMER event, logging the timer details:
function RQE.handleStartTimer(timerType, timeRemaining, totalTime)
    -- Debug message indicating the timer details in a fuchsia color
    -- DEFAULT_CHAT_FRAME:AddMessage("ST 01 Debug: START_TIMER event triggered. Timer Type: " .. tostring(timerType) .. ", Time Remaining: " .. tostring(timeRemaining) .. "s, Total Time: " .. tostring(totalTime) .. "s", 0.85, 0.33, 0.83)  -- Fuchsia Color
    RQE:SaveWorldQuestWatches()
end

-- Function to handle WORLD_STATE_TIMER_START:
function RQE.handleWorldStateTimerStart(self, event, timerID)
    -- DEFAULT_CHAT_FRAME:AddMessage("WSTS 01 Debug: " .. tostring(event) .. " triggered. Timer ID: " .. tostring(timerID), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue

	if not IsFlying("player") and not UnitOnTaxi("player") then
		RQE.LogScenarioInfo()
		RQE.PrintScenarioCriteriaInfoByStep()
	end
	
    if event == "WORLD_STATE_TIMER_START" then
        local timerID = args[1]  -- For WORLD_STATE_TIMER_START, the first argument is timerID
        RQE.StopTimer()
		RQE.StartTimer()
		RQE.HandleTimerStart(timerID)
	end
	
	RQE.updateScenarioUI()
end


-- Function to handle WORLD_STATE_TIMER_STOP:
function RQE.handleWorldStateTimerStop(self, event, ...)
    local args = {...}  -- Capture all arguments in a table
    --local timerID = args[1]  -- For WORLD_STATE_TIMER_STOP, if you need the timerID
	local timerID = ...;
	-- A world timer has stopped; you might want to stop your timer as well
    RQE.StopTimer()
end


-- Handles JAILERS_TOWER_LEVEL_UPDATE event
function RQE.handleJailersUpdate(level, type)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handleJailersUpdate function. Level: " .. tostring(level) .. ", Type: " .. tostring(type), 0.0, 1.0, 1.0)
	
	RQE.UpdateTorghastDetails(level, type)
	
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Scheduled InitializeScenarioFrame after 4 seconds.", 0.0, 1.0, 1.0)
    C_Timer.After(4, function()
        RQE.updateScenarioUI()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Initialized Scenario Frame.", 0.0, 1.0, 1.0)
    end)
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed JAILERS_TOWER_LEVEL_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handles PLAYER_CONTROL_GAINED event
-- Fires after the PLAYER_CONTROL_LOST event, when control has been restored to the player (typically after landing from a taxi)
function RQE.handlePlayerControlGained()
	RQE:AutoClickQuestLogIndexWaypointButton()
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
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if not InCombatLockdown() then
			RQE:CheckMemoryUsage()
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0.93, 0.82, 0.25)
		end
	end
end	


-- Handling VARIABLES_LOADED Event
-- Fired in response to the CVars, Keybindings and other associated "Blizzard" variables being loaded
function RQE.handleVariablesLoaded(...)
	RQE:InitializeFrame()
	isVariablesLoaded = true
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	if C_Scenario.IsInScenario() then
		RQE.ScenarioChildFrame:Show()
	else
		RQE.ScenarioChildFrame:Hide()
	end
	
    -- Handle scenario regardless of the condition
	RQE.updateScenarioUI()
	
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
	
	-- Check if TomTom is loaded and compatibility is enabled
	if IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
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
-- Fires when the player logs in, /reloads the UI or zones between map instances. Basically whenever the loading screen appears
function RQE.handlePlayerEnterWorld(self, event, isLogin, isReload)
	if isLogin then
		-- DEFAULT_CHAT_FRAME:AddMessage("PEW 01 Debug: Loaded the UI from Login.", 0.93, 0.51, 0.93)
		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	elseif isReload then
		-- DEFAULT_CHAT_FRAME:AddMessage("PEW 02 Debug: Loaded the UI after Reload.", 0.93, 0.51, 0.93)
		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	else
        -- DEFAULT_CHAT_FRAME:AddMessage("PEW 03 Debug: Zoned between map instances.", 0.93, 0.51, 0.93)
	end

    -- Check for Dragonriding & Capture and print the current states for debugging purposes
	if RQE.CheckForDragonMounts() then
		RQE.isDragonRiding = true
	else
		RQE.isDragonRiding = false
	end
	
    local isFlying = IsFlying("player")
    local onTaxi = UnitOnTaxi("player")
    local dragonRiding = RQE.isDragonRiding
	
	-- print("Debug: Flying status -", tostring(isFlying))
	-- print("Debug: Taxi status -", tostring(onTaxi))
	-- print("Debug: Dragonriding status -", tostring(dragonRiding))
	
    -- DEFAULT_CHAT_FRAME:AddMessage("PEW 04 Debug: Entering handlePlayerEnterWorld function.", 0.93, 0.51, 0.93)
	
	C_Timer.After(1, function()  -- Delay of 1 second
		wipe(RQE.savedWorldQuestWatches)
		--RQE:HandleSuperTrackedQuestUpdate()
        -- DEFAULT_CHAT_FRAME:AddMessage("PEW 05 Debug: Cleared saved World Quest watches.", 0.93, 0.51, 0.93)
	end)	
	
	local mapID = C_Map.GetBestMapForUnit("player")
    -- DEFAULT_CHAT_FRAME:AddMessage("PEW 06 Debug: Current map ID: " .. tostring(mapID), 0.93, 0.51, 0.93)
	
	RQE.Timer_CheckTimers(GetWorldElapsedTimers())
    -- DEFAULT_CHAT_FRAME:AddMessage("PEW 07 Debug: Checked timers.", 0.93, 0.51, 0.93)
	
    if isReloadingUi then
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
            -- DEFAULT_CHAT_FRAME:AddMessage("PEW 08 Debug: In a scenario, showing ScenarioChildFrame.", 0.93, 0.51, 0.93)
		else
			RQE.ScenarioChildFrame:Hide()
            -- DEFAULT_CHAT_FRAME:AddMessage("PEW 09 Debug: Not in a scenario, hiding ScenarioChildFrame.", 0.93, 0.51, 0.93)
		end
		
		-- Handle scenario regardless of the condition
		RQE.updateScenarioUI()
    end
	
	-- Check if still in a scenario (useful for relogs or loading screens)
	RQE.isInScenario = C_Scenario.IsInScenario()
    -- DEFAULT_CHAT_FRAME:AddMessage("PEW 10 Debug: isInScenario status updated.", 0.93, 0.51, 0.93)
	
	-- Visibility Check for RQEFrame and RQEQuestFrame
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("PEW 11 Debug: Updated frame visibility.", 0.93, 0.51, 0.93)
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
        -- DEFAULT_CHAT_FRAME:AddMessage("PEW 12 Debug: Checked memory usage.", 0.93, 0.51, 0.93)
	end
	
	-- Clicks Waypoint Button if autoClickWaypointButton is true
	RQE:AutoClickQuestLogIndexWaypointButton()
end	
		

-- Handling SUPER_TRACKING_CHANGED Event
-- Fired when the actively tracked location is changed
function RQE.handleSuperTracking(...)
    -- startTime = debugprofilestop()  -- Start timer
	RQEMacro:ClearMacroContentByName("RQE Macro")
	RQE.SaveSuperTrackData()
		
    local extractedQuestID
    local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

    -- Extract questID from RQE's custom UI if available
    if RQE.QuestIDText and RQE.QuestIDText:GetText() then
        extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
    end

    -- Handles situation where tracking changes from another quest tracker addon that deals with Super Tracking
    if ObjectiveTrackerFrame:IsShown() or not RQE.RQEQuestFrame:IsShown() then
        extractedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
        if extractedQuestID then  -- Ensure extractedQuestID is not nil before setting it
            C_SuperTrack.SetSuperTrackedQuestID(extractedQuestID)
            RQE:ClearFrameData()
            UpdateFrame()
        else
            RQE.infoLog("Extracted questID is nil when trying to set super tracked quest.")
        end
    else
        -- Assume that we're using a manually tracked quest ID if available
        questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID
        if not questID then
            RQE.infoLog("All questID references are nil.")
            return
        end
    end
		
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()	
			RQE:CheckAndAdvanceStep(questID)
			RQE:StartPeriodicChecks()
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
		
		-- if RQE.db.profile.debugLevel == "INFO" then
			-- print("Super Tracking: ", questID .. " " .. questLink)
		-- end
		
		RQE.debugLog("Quest Name and Quest Link: ", questName, questLink)

		-- Attempt to fetch quest info from RQEDatabase, use fallback if not present
		local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
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
		UpdateFrame()
	end)
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
        -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 1.0, 0.84, 0)
	end
		
	C_Timer.After(1, function()
		RQE.Buttons.UpdateMagicButtonVisibility()
	end)
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed SUPER_TRACKING_CHANGED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end
		

-- Handling QUEST_ACCEPTED Event
-- Fires whenever the player accepts a quest
function RQE.handleQuestAccepted(questLogIndex, questID)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("QA 01 Debug: QUEST_ACCEPTED event triggered for questID: " .. tostring(questID), 0.46, 0.62, 1)

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

    if questID then
		RQE.LastAcceptedQuest = questID
        local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        local watchType = C_QuestLog.GetQuestWatchType(questID)
        local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)  -- Applies when world quest is manually watched and then accepted when player travels to world quest spot
        local questMapID = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID, ignoreWaypoints)
        local playerMapID = C_Map.GetBestMapForUnit("player")

		-- Debug Messages
		-- DEFAULT_CHAT_FRAME:AddMessage("QA 02 Debug: isWorldQuest: " .. tostring(isWorldQuest) .. " (" .. type(isWorldQuest) .. ")", 0.46, 0.62, 1)
		-- DEFAULT_CHAT_FRAME:AddMessage("QA 03 Debug: watchType: " .. tostring(watchType) .. " (" .. type(watchType) .. ")", 0.46, 0.62, 1)
		-- DEFAULT_CHAT_FRAME:AddMessage("QA 04 Debug: isManuallyTracked: " .. tostring(isManuallyTracked) .. " (" .. type(isManuallyTracked) .. ")", 0.46, 0.62, 1)
		-- DEFAULT_CHAT_FRAME:AddMessage("QA 05 Debug: questMapID: " .. tostring(questMapID) .. " (" .. type(questMapID) .. ")", 0.46, 0.62, 1)
		-- DEFAULT_CHAT_FRAME:AddMessage("QA 06 Debug: playerMapID: " .. tostring(playerMapID) .. " (" .. type(playerMapID) .. ")", 0.46, 0.62, 1)
	
        if isWorldQuest and not isManuallyTracked then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
            -- DEFAULT_CHAT_FRAME:AddMessage("QA 07 Debug: Automatically added World Quest watch for questID: " .. tostring(questID), 0.46, 0.62, 1)
        elseif isWorldQuest and isManuallyTracked then
            C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
            -- DEFAULT_CHAT_FRAME:AddMessage("QA 08 Debug: Manually added World Quest watch for questID: " .. tostring(questID), 0.46, 0.62, 1)
        end

        -- Reapply the manual super-tracked quest ID if it's set and different from the current one
        if RQE.ManualSuperTrack then
            local superTrackIDToApply = RQE.ManualSuperTrackedQuestID
            if superTrackIDToApply and superTrackIDToApply ~= C_SuperTrack.GetSuperTrackedQuestID() then
                C_SuperTrack.SetSuperTrackedQuestID(superTrackIDToApply)
                -- DEFAULT_CHAT_FRAME:AddMessage("QA 09 Debug: Reapplied manual super-tracked QuestID: " .. tostring(superTrackIDToApply), 0.46, 0.62, 1)
			end
        end
        
        if playerMapID and questMapID and playerMapID == questMapID then
            RQE.infoLog("questMapID is " .. questMapID .. " and playerMapID is " .. playerMapID)
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 10 Debug: questMapID is " .. tostring(questMapID) .. " and playerMapID is " .. tostring(playerMapID), 0.46, 0.62, 1)
            UpdateWorldQuestTrackingForMap(playerMapID)
        end
	end
	
    -- Update Frame with the newly accepted quest if nothing is super tracked
	-- DEFAULT_CHAT_FRAME:AddMessage("QA 11 Debug: Updating Frame.", 0.46, 0.62, 1)
	C_Timer.After(1, function()  -- Delay of 1 second
		UpdateFrame()
	end)

	-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	if RQE.db.profile.autoClickWaypointButton then
		RQE:StartPeriodicChecks()
	end
	
	-- Visibility Update Check for RQEFrame & RQEQuestFrame
	-- DEFAULT_CHAT_FRAME:AddMessage("QA 12 Debug: UpdateRQEFrameVisibility.", 0.46, 0.62, 1)
    RQE:UpdateRQEFrameVisibility()
	
	-- DEFAULT_CHAT_FRAME:AddMessage("QA 13 Debug: UpdateRQEQuestFrameVisibility.", 0.46, 0.62, 1)
    RQE:UpdateRQEQuestFrameVisibility()	
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
        -- DEFAULT_CHAT_FRAME:AddMessage("QA 14 Debug: Checked memory usage.", 0.46, 0.62, 1)
	end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_ACCEPTED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end

		
-- Handling of UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS
-- Fired as a unit is about to exit a vehicle, as compared to UNIT_EXITED_VEHICLE which happens afterward or Fires when the player enters a subzone
function RQE.handleZoneChange(self, event, ...)
    -- startTime = debugprofilestop()  -- Start timer
	
    -- Check for Dragonriding & Capture and print the current states for debugging purposes
	if RQE.CheckForDragonMounts() then
		RQE.isDragonRiding = true
	else
		RQE.isDragonRiding = false
	end
	
    local isFlying = IsFlying("player")
    local onTaxi = UnitOnTaxi("player")
    local dragonRiding = RQE.isDragonRiding
	
	if event == "UNIT_EXITING_VEHICLE" then
		-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: UNIT_EXITING_VEHICLE triggered for " .. tostring(...) .. ".", 0, 1, 1)  -- Cyan
	end

	if not IsFlying("player") and not UnitOnTaxi("player") and not self.isDragonRiding then
		-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. SubZone Text: " .. tostring(GetSubZoneText()), 0, 1, 1)  -- Cyan
		C_Timer.After(1.0, function()  -- Delay of 1 second

			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID), 0, 1, 1)  -- Cyan
			
			-- local questInfo = RQE.getQuestData(questID)  -- THIS IS HANDLED IN UPDATEFRAME
			-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values
			
			RQE:UpdateMapIDDisplay()

			-- Call the functions to update the frame
			--UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
						
			-- if C_Scenario.IsInScenario() then
				-- RQE.ScenarioChildFrame:Show()
			-- else
				-- RQE.ScenarioChildFrame:Hide()
			-- end
			
			-- Handle scenario regardless of the condition
			-- RQE.updateScenarioUI()
		end)
	else
		C_Timer.After(0.5, function()
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)
		
		-- SortQuestsByProximity()   -- HANDLED THRU ZONE_CHANGED_NEW_AREA
		-- AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	end
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if not IsFlying("player") or not InCombatLockdown() then
			RQE.debugLog("Player not flying or dragonriding")
			RQE:CheckMemoryUsage()
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0, 1, 1)
		else
			RQE.debugLog("Player is flying or dragonriding")
		end
	end
	
	-- Auto Clicks the QuestLogIndexButton when this event fires
	--RQE:AutoClickQuestLogIndexWaypointButton()
	
	-- -- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	-- if RQE.db.profile.autoClickWaypointButton then
		-- RQE:StartPeriodicChecks()
	-- end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS in: " .. duration .. "ms", 0.25, 0.75, 0.85)

	-- Scrolls frame to top when changing to a new area
	RQE.QuestScrollFrameToTop()
	
	RQE.UntrackAutomaticWorldQuests()
end


-- Handles the event ZONE_CHANGED_NEW_AREA
-- Fires when the player enters a new zone
function RQE.handleZoneNewAreaChange(self, event, ...)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. Zone Text: " .. GetZoneText(), 0, 1, 1)  -- Cyan
	if not UnitOnTaxi("player") and not RQE.isDragonRiding then
		C_Timer.After(1.5, function()

			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
			
			-- local questInfo = RQE.getQuestData(questID)  -- HANDLED IN UPDATEFRAME
			-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values
			
			RQE:UpdateMapIDDisplay()

			-- Call the functions to update the frame
			--UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
					
			-- if C_Scenario.IsInScenario() then  -- SHOULD BE HANDLED THRU SOMETHING LIKE SCENARIO_UPDATE
				-- RQE.ScenarioChildFrame:Show()
				-- RQE.updateScenarioUI()
			-- else
				-- RQE.ScenarioChildFrame:Hide()
				-- RQE.updateScenarioUI()
			-- end
			
			if RQE.db.profile.autoTrackZoneQuests then
				RQE.DisplayCurrentZoneQuests()
				
				C_Timer.After(0.2, function()
					RQE.UpdateTrackedQuestsToCurrentZone()
				end)
			end
			
			SortQuestsByProximity()
			AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		end)
		
		-- Check to advance to next step in quest
		if RQE.db.profile.autoClickWaypointButton then
			C_Timer.After(0.7, function()
				RQE:StartPeriodicChecks()
			end)
		end
	else
		C_Timer.After(0.5, function()
			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan

			-- local questInfo = RQE.getQuestData(questID)  -- HANDLED IN UPDATEFRAME
			-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values

			RQE:UpdateMapIDDisplay()
		end)
	end
	
	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if not IsFlying("player") or not InCombatLockdown() then
			RQE.debugLog("Player not flying or dragonriding")
			RQE:CheckMemoryUsage()
			-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0, 1, 1)
		else
			RQE.debugLog("Player is flying or dragonriding")
		end
	end
	
	-- Scrolls frame to top when changing to a new area
	RQE.QuestScrollFrameToTop()
	
	-- Clears World Quest that are Automatically Tracked when switching to a new area
	RQE.UntrackAutomaticWorldQuests()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed ZONE_CHANGED_NEW_AREA in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handles UNIT_AURA event:
function RQE.handleUnitAura()
    -- Only process the event if it's for the player
    if unitTarget == "player" and not UnitOnTaxi("player") then
        -- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
        if RQE.db.profile.autoClickWaypointButton then
            RQE:StartPeriodicChecks()
        end
    end
end



-- Handles UNIT_QUEST_LOG_CHANGED event:
function RQE.handleUnitQuestLogChange()
    -- Only process the event if it's for the player
    if unitTarget == "player" and not UnitOnTaxi("player") then
		-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
		if RQE.db.profile.autoClickWaypointButton then
			RQE:StartPeriodicChecks()
		end
	end
end


-- Function that handles the Scenario UI Updates
function RQE.updateScenarioUI()
	if not IsFlying("player") and not UnitOnTaxi("player") then
		RQE.LogScenarioInfo()
		RQE.PrintScenarioCriteriaInfoByStep()
	end
	
    if C_Scenario.IsInScenario() then
        RQE.infoLog("Updating because in scenario")
        if not RQE.ScenarioChildFrame:IsVisible() then
            RQE.ScenarioChildFrame:Show()
            RQE.InitializeScenarioFrame()
            --RQE.UpdateScenarioFrame()
        else
			RQE.InitializeScenarioFrame()
            RQE.UpdateScenarioFrame()
        end
        RQE.Timer_CheckTimers()
        RQE.StartTimer()
		RQE.QuestScrollFrameToTop()  -- Moves ScrollFrame of RQEQuestFrame to top
    else
        RQE.ScenarioChildFrame:Hide()
        RQE.StopTimer()
    end
	UpdateRQEQuestFrame()
	RQE.UpdateCampaignFrameAnchor()
	RQE:UpdateRQEQuestFrameVisibility()
end


-- Handles UPDATE_INSTANCE_INFO Event
-- Fired when data from RequestRaidInfo is available and also when player uses portals
function RQE.handleInstanceInfoUpdate()
    -- startTime = debugprofilestop()  -- Start timer
	-- Updates the achievement list for criteria of tracked achievements
	RQE.UpdateTrackedAchievementList()
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE:StartPeriodicChecks()
		end)
	end
	
	-- Updates the RQEFrame with the appropriate super tracked quest
	UpdateFrame()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed UPDATE_INSTANCE_INFO in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handles QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE events
-- Fires when the quest log updates, or whenever Quest POIs change (For example after accepting an quest)
function RQE.handleQuestStatusUpdate(...)
    -- startTime = debugprofilestop()  -- Start timer
    local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
    local currentSuperTrackedquestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- if questID == nil then
		-- questID = currentSuperTrackedquestID
	-- end

    -- -- Check for specific event data
    -- if RQE.latestEventInfo then
        -- local eventInfo = RQE.latestEventInfo
        -- -- Proceed based on the type of event that was triggered
        -- if eventInfo.eventType == "QUEST_CURRENCY_LOOT_RECEIVED" then
            -- -- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_CURRENCY_LOOT_RECEIVED", 0, 1, 0)  -- Bright Green
            -- -- Use eventInfo.questID, eventInfo.currencyId, eventInfo.quantity as needed
		-- elseif eventInfo.eventType == "QUEST_LOG_CRITERIA_UPDATE" then
            -- -- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_LOG_CRITERIA_UPDATE", 0, 1, 0)  -- Bright Green
            -- -- Use eventInfo.questID, eventInfo.specificTreeID, eventInfo.description , eventInfo.numFulfilled, eventInfo.numRequired as needed			
		-- elseif eventInfo.eventType == "QUEST_LOOT_RECEIVED" then
            -- -- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_LOOT_RECEIVED", 0, 1, 0)  -- Bright Green
            -- -- Use eventInfo.questID, eventInfo.itemLink, eventInfo.quantity as needed			
		-- elseif eventInfo.eventType == "QUESTLINE_UPDATE" then
            -- -- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUESTLINE_UPDATE", 0, 1, 0)  -- Bright Green
            -- -- Use eventInfo.requestRequired as needed
        -- end
        -- -- Reset for next event call
        -- RQE.latestEventInfo = nil
    -- else
        -- -- Your existing logic for handling quest status updates without specific event data
    -- end
	
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest Status Update Triggered. SuperTracking: " .. tostring(isSuperTracking) .. ", QuestID: " .. tostring(questID) .. ", Super Tracked QuestID: " .. tostring(currentSuperTrackedquestID), 0, 1, 0)  -- Bright Green

	if not IsFlying("player") and not UnitOnTaxi("player") and not RQE.isDragonRiding then
		C_Timer.After(0.7, function()
			if questID then
				if RQE.ManualSuperTrack and questID ~= RQE.ManualSuperTrackedQuestID then
					C_SuperTrack.SetSuperTrackedQuestID(RQE.ManualSuperTrackedQuestID)
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Manual Super Tracking set for QuestID: " .. tostring(RQE.ManualSuperTrackedQuestID), 0, 1, 0)  -- Bright Green
				end
			
				-- Attempt to fetch other necessary information using the currentQuestID
				local questInfo = RQE.getQuestData(questID)
				local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values

				-- Debug messages for the above variables
				-- DEFAULT_CHAT_FRAME:AddMessage("Debug: QuestInfo: " .. (questInfo and "Found" or "Not Found"), 0, 1, 0)  -- Bright Green
				-- DEFAULT_CHAT_FRAME:AddMessage("Debug: StepsText: " .. tostring(StepsText), 0, 1, 0)  -- Bright Green, assuming StepsText is properly defined
				-- DEFAULT_CHAT_FRAME:AddMessage("Debug: CoordsText: " .. tostring(CoordsText), 0, 1, 0)  -- Bright Green, assuming CoordsText is properly defined
				-- DEFAULT_CHAT_FRAME:AddMessage("Debug: MapIDs: " .. tostring(MapIDs), 0, 1, 0)  -- Bright Green, assuming MapIDs is properly defined
					
				-- Check if the current super-tracked quest is one we're interested in
				if RQE.searchedQuestID and questID == RQE.searchedQuestID then
					-- The super-tracked quest is the one we've set via search; proceed normally
					questInfo = RQE.getQuestData(questID)
					StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Adjust based on actual implementation
				elseif not RQE.searchedQuestID then
					-- No specific searched quest; proceed with default logic
					questInfo = RQE.getQuestData(questID)
					StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Adjust based on actual implementation
				else
					-- The super-tracked quest is not what we set; avoid changing focus
					return  -- Optionally, you could revert the super-tracked quest here
				end
				
				if not RQE.QuestLinesCached then
					RQE.RequestAndCacheQuestLines()
					RQE.QuestLinesCached = true -- Set a flag so we don't re-cache unnecessarily
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest Lines Cached", 0, 1, 0)  -- Bright Green
				end
				
				-- -- Check to advance to next step in quest
				-- if RQE.db.profile.autoClickWaypointButton then
					-- local extractedQuestID
					
					-- if RQE.QuestIDText and RQE.QuestIDText:GetText() then
						-- extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
					-- end

					-- -- Determine questID based on various fallbacks
					-- questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
					
					-- C_Timer.After(0.5, function()
						-- RQE:CheckAndAdvanceStep(questID)
						-- RQE:StartPeriodicChecks()
					-- end)
				-- end
			end
			
			-- RQE:ClearWQTracking()
			-- UpdateRQEQuestFrame()
			-- SortQuestsByProximity()

			-- -- Visibility Update Check for RQEQuestFrame
				-- RQE:UpdateRQEQuestFrameVisibility()
			-- else
				-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Not SuperTracking or QuestID not found", 0, 1, 0)  -- Bright Green
			-- end
			
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			UpdateRQEQuestFrame()
		end)
	end
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end
	

-- Handling QUEST_CURRENCY_LOOT_RECEIVED event
function RQE.handleQuestCurrencyLootReceived(questID, currencyId, quantity)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_CURRENCY_LOOT_RECEIVED for questID: " .. tostring(questID) .. ", CurrencyID: " .. tostring(currencyId) .. ", Quantity: " .. tostring(quantity), 0, 1, 0)  -- Bright Green
	
    -- Saving event specific information before calling the status update function
    RQE.latestEventInfo = {
        eventType = "QUEST_CURRENCY_LOOT_RECEIVED",
        questID = questID,
        currencyId = currencyId,
        quantity = quantity
    }
	
    --RQE.handleQuestStatusUpdate()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_CURRENCY_LOOT_RECEIVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_LOG_CRITERIA_UPDATE event
function RQE.handleQuestLogCriteriaUpdate(questID, specificTreeID, description, numFulfilled, numRequired)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_LOG_CRITERIA_UPDATE for questID: " .. tostring(questID) .. ", SpecificTreeID: " .. tostring(specificTreeID) .. ", Description: " .. description .. ", Fulfilled: " .. tostring(numFulfilled) .. ", Required: " .. tostring(numRequired), 0, 1, 0)  -- Bright Green
	
    -- Saving event specific information before calling the status update function
    RQE.latestEventInfo = {
        eventType = "QUEST_LOG_CRITERIA_UPDATE",
        questID = questID,
        specificTreeID = specificTreeID,
		description = description,
		numFulfilled = numFulfilled,
        numRequired = numRequired
    }
	
    --RQE.handleQuestStatusUpdate()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOG_CRITERIA_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_LOOT_RECEIVED event
-- Fires when player receives loot from quest turn in
function RQE.handleQuestLootReceived(questID, itemLink, quantity)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_LOOT_RECEIVED for questID: " .. tostring(questID) .. ", ItemLink: " .. itemLink .. ", Quantity: " .. tostring(quantity), 0, 1, 0)  -- Bright Green
	
    -- Saving event specific information before calling the status update function
    RQE.latestEventInfo = {
        eventType = "QUEST_LOOT_RECEIVED",
        questID = questID,
        itemLink = itemLink,
        quantity = quantity
    }
	
	--RQE.handleQuestStatusUpdate()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOOT_RECEIVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUESTLINE_UPDATE event
function RQE.handleQuestlineUpdate(requestRequired)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUESTLINE_UPDATE, Request Required: " .. tostring(requestRequired), 0, 1, 0)  -- Bright Green
	
    -- Saving event specific information before calling the status update function
    RQE.latestEventInfo = {
        eventType = "QUESTLINE_UPDATE",
        requestRequired = requestRequired
    }
	
	--RQE.handleQuestStatusUpdate()
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUESTLINE_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_COMPLETE event
-- Fired after the player hits the "Continue" button in the quest-information page, before the "Complete Quest" button. In other words, it fires when you are given the option to complete a quest, but just before you actually complete the quest. 
function RQE.handleQuestComplete()
    -- startTime = debugprofilestop()  -- Start timer
	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	local extractedQuestID
	
	isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	
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
	
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	
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
	--UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())

	-- -- Check to advance to next step in quest
	-- if RQE.db.profile.autoClickWaypointButton then	
		-- RQE:CheckAndAdvanceStep(questID)
	-- end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
	
	-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)
	
	if not RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(2, function()
			RQE.infoLog("Clicking QuestLogIndexButton following QUEST_COMPLETE event")
			RQE.ClickUnknownQuestButton()
			RQE:StartPeriodicChecks()
		end)
	end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_COMPLETE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end
		
-- Handling QUEST_AUTOCOMPLETE events
-- Fires when a quest that can be auto-completed is completed
function RQE.handleQuestAutoComplete(...)
    -- startTime = debugprofilestop()  -- Start timer
	local questID = ...  -- Extract the questID from the event
	local extractedQuestID
	
	isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	
    if isSuperTracking then
        local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    end
	
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		-- DEFAULT_CHAT_FRAME:AddMessage("QAC 01 Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(extractedQuestID), 0, 0.75, 0.75)
		-- DEFAULT_CHAT_FRAME:AddMessage("QAC 02 Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(currentSuperTrackedQuestID), 0, 0.75, 0.75)
	end

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID
	
    -- DEFAULT_CHAT_FRAME:AddMessage("QAC 03 Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	
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
		C_Timer.After(0.5, function()
			RQE:CheckAndAdvanceStep(questID)
		end)
	end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
	
	-- DEFAULT_CHAT_FRAME:AddMessage("QAC 04 Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_AUTOCOMPLETE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end
	
	
-- Handling CLIENT_SCENE_OPENED event (saving of World Quests when event fires):
function RQE.HandleClientSceneOpened(sceneType)
    -- startTime = debugprofilestop()  -- Start timer
    -- Debug message indicating the type of scene opened
    -- DEFAULT_CHAT_FRAME:AddMessage("CSO 01 Debug: CLIENT_SCENE_OPENED event triggered. Scene Type: " .. tostring(sceneType), 0.95, 0.95, 0.7)  -- Faded Yellow Color

    RQE:SaveWorldQuestWatches()  -- Save the watch list when a scene is opened
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed CLIENT_SCENE_OPENED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling CLIENT_SCENE_CLOSED event (restoring of World Quests when event fires):
function RQE.HandleClientSceneClosed()
    -- startTime = debugprofilestop()  -- Start timer
    RQE.isRestoringWorldQuests = true
    C_Timer.After(1, function()
        RQE:RestoreSavedWorldQuestWatches()
        -- Set isRestoringWorldQuests back to false after all quests are restored
        C_Timer.After(2, function() -- adjust the delay as needed
            RQE.isRestoringWorldQuests = false
        end)
    end)
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed CLIENT_SCENE_CLOSED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end

		
-- Handling QUEST_REMOVED event
function RQE.handleQuestRemoved(questID, wasReplayQuest)
    -- startTime = debugprofilestop()  -- Start timer
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

    -- Check if the removed quest is the currently super-tracked quest
    local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    if questID == currentSuperTrackedQuestID then
        -- Clear user waypoint and reset TomTom if loaded
        C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		if IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
            TomTom.waydb:ResetProfile()
        end
		
		-- Update RQEFrame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		
		-- Visibility Check for RQEFrame and RQEQuestFrame
		RQE:UpdateRQEFrameVisibility()
		RQE:UpdateRQEQuestFrameVisibility()
    end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_REMOVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end
	

-- Handling QUEST_WATCH_UPDATE event
-- Fires each time the objectives of the quest with the supplied questID update, i.e. whenever a partial objective has been accomplished: killing a mob, looting a quest item etc
-- UNIT_QUEST_LOG_CHANGED and QUEST_LOG_UPDATE both also seem to fire consistently – in that order – after each QUEST_WATCH_UPDATE.
function RQE.handleQuestWatchUpdate(questID)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Received questID: " .. tostring(questID), 0.56, 0.93, 0.56)
	
	UpdateRQEQuestFrame()
	RQEQuestFrame:ClearAllPoints()
	
	-- Further processing
	QuestType()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()

    if type(questID) ~= "number" then
        -- DEFAULT_CHAT_FRAME:AddMessage("QWU 01 Error: questID is not a number.", 0.56, 0.93, 0.56)
		UpdateFrame()
        return
    end
	
    -- DEFAULT_CHAT_FRAME:AddMessage("QWU 02 Debug: QUEST_WATCH_UPDATE event triggered for questID: " .. tostring(questID), 0.56, 0.93, 0.56) -- Light Green

	-- Adds quest to watch list when progress made
	C_QuestLog.AddQuestWatch(questID)
	
	if questID then
		-- Retrieve the current watched quest ID if needed
		local questName = C_QuestLog.GetTitleForQuestID(questID)
		local questLink = GetQuestLink(questID)
		
		local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
		local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}
	end

	isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	
	-- Check if Super Tracking. If yes, gather info on ID and Name, else super track the progress quest
    if isSuperTracking then
        local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		local superTrackedQuestName = C_QuestLog.GetTitleForQuestID(questID)
	else
		C_SuperTrack.SetSuperTrackedQuestID(questID)
		local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		local superTrackedQuestName = C_QuestLog.GetTitleForQuestID(questID)
    end
	
	-- DEFAULT_CHAT_FRAME:AddMessage("QWU 03 DebugDebug: Current super tracked quest ID/Name: " .. tostring(currentSuperTrackedQuestID) .. " " .. superTrackedQuestName, 0.56, 0.93, 0.56)
	
	if questID then
		local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
		-- DEFAULT_CHAT_FRAME:AddMessage("QWU 04 Debug: Quest info - QuestID: " .. tostring(questInfo.questID) .. ", Name: " .. tostring(questInfo.name) .. questName, 0.56, 0.93, 0.56)
		-- DEFAULT_CHAT_FRAME:AddMessage("QWU 05 Debug: Is quest completed: " .. tostring(isQuestCompleted), 0.56, 0.93, 0.56)
		
		if questInfo then
			-- If you need details about the quest, fetch them here
			for i, step in ipairs(questInfo) do
				StepsText[i] = step.description
				CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
				MapIDs[i] = step.coordinates.mapID
				questHeader[i] = step.description:match("^(.-)\n") or step.description
				
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 06 Debug: Step " .. i .. ": " .. StepsText[i], 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 07 Debug: Coordinates " .. i .. ": " .. CoordsText[i], 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 08 Debug: MapID " .. i .. ": " .. tostring(MapIDs[i]), 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 09 Debug: Header " .. i .. ": " .. questHeader[i], 0.56, 0.93, 0.56)
			end
		end
	end
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
            -- DEFAULT_CHAT_FRAME:AddMessage("QWU 10 Debug: Extracted quest ID from QuestIDText: " .. tostring(extractedQuestID), 0.56, 0.93, 0.56)
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID

		C_Timer.After(1, function()
			RQE:CheckAndAdvanceStep(questID)
		-- DEFAULT_CHAT_FRAME:AddMessage("QWU 11 Debug: Checking and advancing step for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
		end)
	-- else
		-- C_Timer.After(2, function()
			-- RQE.infoLog("Clicking QuestLogIndexButton following QUEST_WATCH_UPDATE event")
			-- RQE.ClickUnknownQuestButton()
		-- end)
	end
	
	C_Timer.After(0.5, function()
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end)
	
	-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	if RQE.db.profile.autoClickWaypointButton then
		RQE:StartPeriodicChecks()
	end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_WATCH_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_WATCH_LIST_CHANGED event
function RQE.handleQuestWatchListChanged(questID, added)
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_WATCH_LIST_CHANGED event triggered for questID: " .. tostring(questID) .. ", added: " .. tostring(added), 0.4, 0.6, 1.0)

	-- Extract QuestID from super track and that which is displayed in RQEFrame
	local extractedQuestID
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or extractedQuestID or questID or currentSuperTrackedQuestID

	UpdateRQEQuestFrame()  -- Ensure this function is defined to refresh the content based on current quest watch list
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	RQE:ClearWQTracking()
    RQE:UpdateRQEQuestFrameVisibility()

    -- This ensures that any change in the watch list is reflected in your addon's UI
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	
	local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
	local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}

	-- if questID then
		-- Debug messages for the above variables
		-- for i, step in ipairs(questInfo) do
			-- StepsText[i] = step.description
			-- CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
			-- MapIDs[i] = step.coordinates.mapID
			-- questHeader[i] = step.description:match("^(.-)\n") or step.description
			
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 01 Debug: Step " .. i .. ": " .. StepsText[i], 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 02 Debug: Coordinates " .. i .. ": " .. CoordsText[i], 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 03 Debug: MapID " .. i .. ": " .. tostring(MapIDs[i]), 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 04 Debug: Header " .. i .. ": " .. questHeader[i], 0.56, 0.93, 0.56)
		-- end
	-- end
		
    -- if questInfo then
        -- DEFAULT_CHAT_FRAME:AddMessage("QWLA 05 Debug: Quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
    -- else
        -- DEFAULT_CHAT_FRAME:AddMessage("QWLA 06 Debug: No quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
    -- end
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then		
		C_Timer.After(0.5, function()
			RQE:CheckAndAdvanceStep(questID)
			RQE:StartPeriodicChecks()
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 07 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
		end)
	-- else
		-- C_Timer.After(2, function()
			-- RQE.infoLog("Clicking QuestLogIndexButton following QUEST_WATCH_LIST_CHANGED event")
			-- RQE.ClickUnknownQuestButton()
		-- end)
	end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_WATCH_LIST_CHANGED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_TURNED_IN event
-- This event fires whenever the player turns in a quest, whether automatically with a Task-type quest (Bonus Objectives/World Quests), or by pressing the Complete button 
-- in a quest dialog window. 
function RQE.handleQuestTurnIn(questID, xpReward, moneyReward)
    -- startTime = debugprofilestop()  -- Start timer
	-- DEFAULT_CHAT_FRAME:AddMessage("QTI 01 Debug: QUEST_TURNED_IN event triggered for questID: " .. tostring(questID) .. ", XP Reward: " .. tostring(xpReward) .. ", Money Reward: " .. tostring(moneyReward) .. " copper", 1.0, 0.08, 0.58)  -- Bright Pink

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false
	
	if not questID then   -- Ensure there's a valid questID from the event
		UpdateFrame()
		return
	end

    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    -- DEFAULT_CHAT_FRAME:AddMessage("QTI 02 Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1.0, 0.08, 0.58)

    -- Check if the removed quest is the currently super-tracked quest
    if questID == superTrackedQuestID then
        -- Clear user waypoint and reset TomTom if loaded
        C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		if IsAddOnLoaded("TomTom") and RQE.db.profile.enableTomTomCompatibility then
            TomTom.waydb:ResetProfile()
        end
    end

	local displayedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		displayedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end
	
	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or displayedQuestID or questID or superTrackedQuestID

    -- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
    -- This might involve checking if there are other quests to display or adjusting UI elements
    RQE:UpdateRQEFrameVisibility()
    RQE:UpdateRQEQuestFrameVisibility()
	
	RQEMacro:ClearMacroContentByName("RQE Macro")

    -- DEFAULT_CHAT_FRAME:AddMessage("QTI 03 Debug: QuestID: " .. tostring(questID), 1.0, 0.08, 0.58)
		
    -- DEFAULT_CHAT_FRAME:AddMessage("QTI 04 Debug: DisplayedQuestID: " .. tostring(displayedQuestID), 1.0, 0.08, 0.58)
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then		
		C_Timer.After(1, function()
			RQE:CheckAndAdvanceStep(questID)
		end)
	else
		-- C_Timer.After(2, function()
			-- RQE.infoLog("Clicking QuestLogIndexButton following QUEST_TURNED_IN event")
			-- RQE.ClickUnknownQuestButton()
		-- end)
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
	
	-- Update RQEFrame
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_TURNED_IN in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end


-- Handling QUEST_FINISHED event
-- Fired whenever the quest frame changes (from Detail to Progress to Reward, etc.) or is closed
function RQE.handleQuestFinished()
    -- startTime = debugprofilestop()  -- Start timer
    -- DEFAULT_CHAT_FRAME:AddMessage("RQE.handleQuestFinished called.", 1, 0.75, 0.79)
		
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- DEFAULT_CHAT_FRAME:AddMessage("QF 01 Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or extractedQuestID or questID or superTrackedQuestID
	
	-- DEFAULT_CHAT_FRAME:AddMessage("QF 02 Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.75, 0.79)
    -- DEFAULT_CHAT_FRAME:AddMessage("QF 03 Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1, 0.75, 0.79)
    -- DEFAULT_CHAT_FRAME:AddMessage("QF 04 Debug: DisplayedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
	
	-- Update RQEFrame
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	
    -- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
    -- This might involve checking if there are other quests to display or adjusting UI elements
    RQE:UpdateRQEFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("QF 05 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	
    RQE:UpdateRQEQuestFrameVisibility()
    -- DEFAULT_CHAT_FRAME:AddMessage("QF 06 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	
	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then	
		C_Timer.After(0.5, function()
			RQE:CheckAndAdvanceStep(questID)
			--RQE:ClickSuperTrackedQuestButton()
			-- DEFAULT_CHAT_FRAME:AddMessage("QF 07 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
			RQE:StartPeriodicChecks()
		end)
	end
	
	-- local duration = debugprofilestop() - startTime
	-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_FINISHED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
end

	
-- Handling PLAYER_LOGOUT event
-- Sent when the player logs out or the UI is reloaded, just before SavedVariables are saved. The event fires after PLAYER_LEAVING_WORLD
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