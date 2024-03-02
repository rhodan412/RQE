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
        --RQE:ClearFrameData() -- clears frame data of first super tracked quest if super track done right after log in. commenting this out corrects that
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
	"CRITERIA_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"CONTENT_TRACKING_UPDATE",
	"CLIENT_SCENE_CLOSED",
	"CLIENT_SCENE_OPENED",
	"LEAVE_PARTY_CONFIRMATION",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LOGIN",
	"PLAYER_LOGOUT",
	"PLAYER_STARTED_MOVING",
	"PLAYER_STOPPED_MOVING",
	"QUEST_ACCEPTED",
	"QUEST_AUTOCOMPLETE",
	"QUEST_CURRENCY_LOOT_RECEIVED",
	--"QUEST_DATA_LOAD_RESULT",
	"QUEST_LOG_CRITERIA_UPDATE",
	"QUEST_LOG_UPDATE",
	"QUEST_LOOT_RECEIVED",
	"QUEST_POI_UPDATE",
	"QUEST_REMOVED",
	"QUEST_TURNED_IN",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_WATCH_UPDATE",
	"QUESTLINE_UPDATE",
	"SCENARIO_COMPLETED",
	"SCENARIO_CRITERIA_UPDATE",
	"SCENARIO_POI_UPDATE",
	"SCENARIO_UPDATE",
	"START_TIMER",
	"SUPER_TRACKING_CHANGED",
	"TASK_PROGRESS_UPDATE",
	"UNIT_EXITING_VEHICLE",
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

    local handlers = {
		ADDON_LOADED = RQE.handleAddonLoaded,
		ACHIEVEMENT_EARNED = RQE.handleAchievementTracking,
		CONTENT_TRACKING_UPDATE = RQE.handleAchievementTracking,
		CRITERIA_UPDATE = RQE.handleAchievementTracking,
		CLIENT_SCENE_CLOSED = RQE.HandleClientSceneClosed,
		--CLIENT_SCENE_OPENED = RQE.HandleClientSceneOpened,
		LEAVE_PARTY_CONFIRMATION = handleScenario,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,
		PLAYER_STARTED_MOVING = RQE.handlePlayerStartedMoving,
		PLAYER_STOPPED_MOVING = RQE.handlePlayerStoppedMoving,
		QUEST_ACCEPTED = RQE.handleQuestAccepted,
		QUEST_AUTOCOMPLETE = RQE.handleQuestComplete,
		QUEST_COMPLETE = RQE.handleQuestComplete,
		QUEST_CURRENCY_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,
		QUEST_LOG_CRITERIA_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_LOG_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,
		QUEST_POI_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_REMOVED = RQE.handleQuestRemoved,
		QUEST_TURNED_IN = RQE.handleQuestTurnIn,
		QUEST_WATCH_LIST_CHANGED = RQE.handleQuestWatchListChanged,
		QUEST_WATCH_UPDATE = RQE.handleQuestWatchUpdate,
		QUESTLINE_UPDATE = RQE.handleQuestStatusUpdate,
		SCENARIO_COMPLETED = handleScenarioComplete,
		SCENARIO_CRITERIA_UPDATE = handleScenario,
		SCENARIO_POI_UPDATE = RQE.handleScenario,
		SCENARIO_UPDATE = RQE.handleScenario,
		START_TIMER = RQE.HandleClientSceneOpened,
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,
		TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		VARIABLES_LOADED = RQE.handleVariablesLoaded,
		WORLD_STATE_TIMER_START = RQE.handleScenario,
		WORLD_STATE_TIMER_STOP = RQE.handleTimerStop,
		ZONE_CHANGED = RQE.handleZoneChange,
		ZONE_CHANGED_INDOORS = RQE.handleZoneChange,
		ZONE_CHANGED_NEW_AREA = RQE.handleZoneChange
    }
    
    if handlers[event] then
        handlers[event](...)
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
		RQE.UpdateTrackedAchievementList()
		RQE.UpdateTrackedAchievements(contentType, id, tracked)
	end
end


-- Handling PLAYER_LOGIN Event
function RQE.handlePlayerLogin(...)
	
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
	end
	
	-- Make sure the profileKeys table is initialized
	if RQE.db.profileKeys == nil then
		RQE.db.profileKeys = {}
	end

	if RQE.db.profile.removeWQatLogin then
		RemoveAllTrackedWorldQuests()
	end
	
	RQE:ConfigurationChanged()

	local charKey = UnitName("player") .. " - " .. GetRealmName()

	-- Debugging: Print the current charKey
	RQE.debugLog("Current charKey is:", charKey)

	-- This will set the profile to "Default"
	RQE.db:SetProfile("Default")
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
        if RQE.HideObjectiveTracker then
            RQE.HideObjectiveTracker()  -- Assuming you have a function defined to hide the tracker
        end

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
    RQE.UpdateCampaignFrameAnchor()
end


-- Function to handle SCENARIO_COMPLETED:
function RQE.handleScenarioComplete()
	RQE.StopTimer()
	RQE.UpdateCampaignFrameAnchor()
	RQE.HandleTimerStop(timerID)
end


-- Function to handle WORLD_STATE_TIMER_STOP:
function RQE.handleTimerStop(self, event, ...)
    local args = {...}  -- Capture all arguments in a table
    --local timerID = args[1]  -- For WORLD_STATE_TIMER_STOP, if you need the timerID
	local timerID = ...;
	-- A world timer has stopped; you might want to stop your timer as well
    RQE.StopTimer()
end


-- Handling for QUEST_DATA_LOAD_RESULT
function RQE.handleQuestDataLoad(...)  --(_, _, questIndex, questID)
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	local questID, added = ...
	local watchType = C_QuestLog.GetQuestWatchType(questID)

	-- Check if auto-tracking of quest progress is enabled and call the function
	--if questID and added and RQE.db.profile.autoTrackProgress then
		--AutoWatchQuestsWithProgress()
		SortQuestsByProximity()
	--end
end
		

-- Handling PLAYER_STARTED_MOVING Event
function RQE.handlePlayerStartedMoving(...)
	RQE:StartUpdatingCoordinates()
end	


-- Handling PLAYER_STOPPED_MOVING Event
function RQE.handlePlayerStoppedMoving(...)
	RQE:StopUpdatingCoordinates()
	SortQuestsByProximity()
	--AdjustRQEFrameWidths(RQEQuestFrame:GetWidth())
	--AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
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
	else
		RQEFrame:Hide()
	end
		
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
		RQEFrame:SetSize(400, 30)
		
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
function RQE.handlePlayerEnterWorld(...)
	C_Timer.After(1, function()  -- Delay of 1 second
		wipe(RQE.savedWorldQuestWatches)
		RQE:HandleSuperTrackedQuestUpdate()
	end)	
	
	local mapID = C_Map.GetBestMapForUnit("player")
	RQE.Timer_CheckTimers(GetWorldElapsedTimers())
	
    if isReloadingUi then
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			RQE.handleScenario()
		else
			RQE.ScenarioChildFrame:Hide()
			RQE.handleScenario()
		end
    end
end	
		

-- Handling SUPER_TRACKING_CHANGED Event
function RQE.handleSuperTracking(...)
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)
	
	QuestType()
	RQE.superTrackingChanged = true
	RQE:ClearFrameData()
	RQE.SaveSuperTrackData()
	--RQE.UnknownQuestButtonCalcNTrack()
		
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	RQE:CreateUnknownQuestWaypoint(questID, mapID)

	local questName
	if questID then
		questName = C_QuestLog.GetTitleForQuestID(questID)
		if questID ~= lastSuperTrackedQuestID then
			lastSuperTrackedQuestID = questID
			local questLink = GetQuestLink(questID)  -- Generate the quest link
			RQE.debugLog("Quest Name and Quest Link: ", questName, questLink)

			-- Attempt to fetch quest info from RQEDatabase, use fallback if not present
			local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
			local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

			if StepsText and CoordsText and MapIDs then
				UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			end
			AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		end
	else
		RQE.debugLog("questID is nil in SUPER_TRACKING_CHANGED event.")
		SortQuestsByProximity()
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
end
		

-- Handling QUEST_ACCEPTED Event
function RQE.handleQuestAccepted(...)
	local questID = ...  -- Extract the questID from the event
	if questID then
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local watchType = C_QuestLog.GetQuestWatchType(questID)
		local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)

		if isWorldQuest and not isManuallyTracked then
			C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
		elseif isWorldQuest and isManuallyTracked then
			C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
		end
		
		local mapID = C_Map.GetBestMapForUnit("player")
		UpdateWorldQuestTrackingForMap(mapID)
	end
end

		
-- Handling of several events for purpose of updating the DirectionText
function RQE.handleZoneChange(...)
	C_Timer.After(1.0, function()  -- Delay of 1 second

		-- Get the current map ID
		local mapID = C_Map.GetBestMapForUnit("player")			
		local questInfo = RQEDatabase[questID]
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values

		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		
		-- if RQE.db.profile.showMapID and currentMapID then
			-- RQEFrame.MapIDText:SetText("MapID: " .. currentMapID)
		-- else
			-- RQEFrame.MapIDText:SetText("")
		-- end
		RQE:UpdateMapIDDisplay()

		-- Call the functions to update the frame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		--UpdateFrame(currentQuestID, questInfo, StepsText, CoordsText, MapIDs)

		-- -- Check if auto-tracking of quest progress is enabled and call the function
		-- if RQE.db.profile.autoTrackProgress then
			-- AutoWatchQuestsWithProgress()
		-- end
		
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


-- Handling multiple quest related events to update the main frame
function RQE.handleQuestStatusUpdate(...)
	
	-- Attempt to fetch the current super-tracked quest ID
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	--local questInfo, StepsText, CoordsText, MapIDs
	
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
		
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)
	
    RQE:ClearWQTracking()  -- Custom function to clear World Quest tracking if necessary
    -- C_Map.ClearUserWaypoint()  -- Uncomment if you need to clear user waypoints
    UpdateRQEQuestFrame()  -- Custom function to update your frame
    SortQuestsByProximity()  -- Assuming this sorts quests displayed in RQEFrame by proximity
    UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)  -- Update the main frame with quest details
end
	

-- Handling QUEST_COMPLETE event
function RQE.handleQuestComplete(...)
	local questID = ...  -- Extract the questID from the event
	RQE:QuestComplete(questID)
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
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
function RQE.handleQuestRemoved(questID, removedByUser)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()
	RQE:ClearWQTracking()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	
    -- Check if the questID is valid and if it was being tracked automatically
    if questID and RQE.TrackedQuests[questID] == Enum.QuestWatchType.Automatic then
        -- Remove the quest from the tracking list
        C_QuestLog.RemoveWorldQuestWatch(questID)
        -- Clear the saved state for this quest
        RQE.TrackedQuests[questID] = nil
    end
end
	
		
-- Handling QUEST_WATCH_UPDATE event
function RQE.handleQuestWatchUpdate(...)
    -- Retrieve the current watched quest ID if needed
    local questID, added = ...
	local questInfo = RQEDatabase[questID] or { questID = questID, name = questName }
	
    -- If you need details about the quest, fetch them here
    local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if questID then
		RQEQuestFrame:ClearAllPoints()
		UpdateRQEQuestFrame()
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)

		-- Update RQEFrame here if needed
		-- UpdateRQEFrame() -- Pseudo-function, replace with actual function calls needed to update RQEFrame

		-- Further processing
		QuestType()
		SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	end
end
		

-- Handling QUEST_WATCH_LIST_CHANGED event (If questID is nil, the event will be ignored)
function RQE.handleQuestWatchListChanged(...)
	local questID, added = ...
	RQE:ClearWQTracking()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	local watchType
    if questID then
        local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
        local watchType = C_QuestLog.GetQuestWatchType(questID)
        if isWorldQuest then
            if added then
                RQE.TrackedQuests[questID] = watchType -- Track the type of watch added
            else
                RQE.TrackedQuests[questID] = nil -- Remove the tracking if the quest is removed
            end
        end
	end
	
	if questID then
		if C_QuestLog.IsWorldQuest(questID) then
			-- Handle World Quests specifically
			if added then
				-- World Quest is added to the Watch List
				-- Check if auto-tracking of quest progress is enabled and call the function
				-- if RQE.db.profile.autoTrackProgress then
					-- AutoWatchQuestsWithProgress()
				-- end
			else
				-- World Quest is removed from the Watch List
				RQE.savedWorldQuestWatches[questID] = nil
				RQE:ClearWQTracking()
			end
		else
		-- Handle regular quests
		--if RQEFrame:IsShown() and RQEFrame.currentQuestID == questID and RQE.db.profile.autoSortRQEFrame then
			RQE.savedWorldQuestWatches[questID] = nil
			--if RQE.db.profile.autoTrackProgress then
				--AutoWatchQuestsWithProgress()
				SortQuestsByProximity()
			--end					
		end
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearRQEQuestFrame()
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	SortQuestsByProximity()
	UpdateFrameAnchors()
	UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
	end
end
		

-- Handling QUEST_TURNED_IN event
function RQE.handleQuestTurnIn(...)
	RQE:QuestComplete(questID)
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()
	--RQE:ClearWQTracking()
	QuestType()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	
	C_Timer.After(0.5, function() -- This clears the RQEFrame shortly after turning in a quest
		RQE:ClearFrameData()
	end)
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