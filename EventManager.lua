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
	"ADDON_LOADED",
	"BAG_UPDATE_COOLDOWN",
	"SUPER_TRACKING_CHANGED",
	"QUEST_CURRENCY_LOOT_RECEIVED",
	"QUEST_LOOT_RECEIVED",
	"QUEST_LOG_CRITERIA_UPDATE",
	"QUEST_AUTOCOMPLETE",
	"QUESTLINE_UPDATE",
	"QUEST_POI_UPDATE",
	"QUEST_LOG_UPDATE",
	"TASK_PROGRESS_UPDATE",
	"UNIT_EXITING_VEHICLE",
	"ZONE_CHANGED",
	"ZONE_CHANGED_INDOORS",
	"ZONE_CHANGED_NEW_AREA",
	"PLAYER_LOGIN",
	"QUEST_ACCEPTED",
	"PLAYER_LOGOUT",
	"QUEST_DATA_LOAD_RESULT",
	"VARIABLES_LOADED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_STARTED_MOVING",
	"PLAYER_STOPPED_MOVING",
	"QUEST_WATCH_UPDATE",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_REMOVED",
	"QUEST_TURNED_IN"
}



---------------------------
-- 4. Event Handling
---------------------------

-- On Event Handler
local function HandleEvents(frame, event, ...)
	--RQE.criticalLog("EventHandler triggered with event:", event)  -- Debug print here

    local handlers = {
		ADDON_LOADED = RQE.handleAddonLoaded,
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,
		QUEST_CURRENCY_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,
		QUEST_LOOT_RECEIVED = RQE.handleQuestStatusUpdate,
		QUEST_LOG_CRITERIA_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_AUTOCOMPLETE = RQE.handleQuestComplete,
		QUEST_COMPLETE = RQE.handleQuestComplete,
		QUESTLINE_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_POI_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_LOG_UPDATE = RQE.handleQuestStatusUpdate,
		TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		ZONE_CHANGED = RQE.handleZoneChange,
		ZONE_CHANGED_INDOORS = RQE.handleZoneChange,
		ZONE_CHANGED_NEW_AREA = RQE.handleZoneChange,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		QUEST_ACCEPTED = RQE.handleQuestAccepted,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,
		QUEST_DATA_LOAD_RESULT = RQE.handleQuestDataLoad,
		VARIABLES_LOADED = RQE.handleVariablesLoaded,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_STARTED_MOVING = RQE.handlePlayerStartedMoving,
		PLAYER_STOPPED_MOVING = RQE.handlePlayerStoppedMoving,
		QUEST_WATCH_UPDATE = RQE.handleQuestWatchUpdate,
		QUEST_WATCH_LIST_CHANGED = RQE.handleQuestWatchListChanged,
		QUEST_REMOVED = RQE.handleQuestRemoved,
		QUEST_TURNED_IN = RQE.handleQuestTurnIn
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


-- Handling PLAYER_LOGIN Event
function RQE.handlePlayerLogin(...)
	
	-- Initialize other components of your AddOn
	RQE:InitializeAddon()
	RQE:InitializeFrame()

	-- Add this line to update coordinates when player logs in
	RQE:UpdateCoordinates()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	
	-- Fetch current MapID to have option of appearing with Frame
	local mapID = C_Map.GetBestMapForUnit("player")
	if RQEFrame.MapIDText then  -- Check if MapIDText is initialized
		if RQE.db.profile.showMapID and mapID then
			RQEFrame.MapIDText:SetText("MapID: " .. mapID)
		else
			RQEFrame.MapIDText:SetText("")
		end
	else
		RQE.debugLog("RQEFrame.MapIDText is not initialized.")
	end

	-- Make sure RQE.db is initialized
	if RQE.db == nil then
		RQE.db = {}
	end
	
	-- Make sure the profileKeys table is initialized
	if RQE.db.profileKeys == nil then
		RQE.db.profileKeys = {}
	end
	
	RQE:ConfigurationChanged()

	local charKey = UnitName("player") .. " - " .. GetRealmName()

	-- Debugging: Print the current charKey
	RQE.debugLog("Current charKey is:", charKey)

	-- This will set the profile to "Default"
	RQE.db:SetProfile("Default")
end
		

function RQE.handleAddonLoaded(...)
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		RQE:UpdateFrameOpacity()
	end)
end

		
-- Handling for QUEST_DATA_LOAD_RESULT
function RQE.handleQuestDataLoad(...)
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	local questID, added = ...
	local watchType = C_QuestLog.GetQuestWatchType(questID)

	-- Check if auto-tracking of quest progress is enabled and call the function
	if questID and added and RQE.db.profile.autoTrackProgress then
		AutoWatchQuestsWithProgress()
		SortQuestsByProximity()
	end
end
		

-- Handling PLAYER_STARTED_MOVING Event
function RQE.handlePlayerStartedMoving(...)
	RQE:StopUpdatingCoordinates()
	SortQuestsByProximity()
end	
		

-- Handling VARIABLES_LOADED Event
function RQE.handleVariablesLoaded(...)
	RQE:InitializeFrame()
	isVariablesLoaded = true
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)
	
	RQE:ClearWQTracking()
	--QuestType()
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
		RQE:HandleSuperTrackedQuestUpdate()
	end)	
	
	local mapID = C_Map.GetBestMapForUnit("player")
end	
		

-- Handling SUPER_TRACKING_CHANGED Event
function RQE.handleSuperTracking(...)
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	QuestType()
	RQE.superTrackingChanged = true
	RQE:ClearFrameData()

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
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
		--RQE:ClearWQTracking()
		--QuestType()
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
		

function RQE.handleQuestAccepted(...)
	local questID = arg1
	if questID then
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local watchType = C_QuestLog.GetQuestWatchType(questID)
		local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)

		if isWorldQuest and not isManuallyTracked then
			C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
			C_SuperTrack.SetSuperTrackedQuestID(questID)
		end
		
		local mapID = C_Map.GetBestMapForUnit("player")
		UpdateWorldQuestTrackingForMap(mapID)
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end
end

		
-- Handling of several events for purpose of updating the DirectionText
function RQE.handleZoneChange(...)
	C_Timer.After(1.0, function()  -- Delay of 1 second

		-- Get the current map ID
		local currentMapID = C_Map.GetBestMapForUnit("player")			
		local questInfo = RQEDatabase[currentQuestID]
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(currentQuestID)  -- Assuming PrintQuestStepsToChat exists and returns these values

		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		
		if RQE.db.profile.showMapID and mapID then
			RQEFrame.MapIDText:SetText("MapID: " .. mapID)
		else
			RQEFrame.MapIDText:SetText("")
		end
			
		-- Call the functions to update the frame
		UpdateFrame(currentQuestID, questInfo, StepsText, CoordsText, MapIDs)

		-- Check if auto-tracking of quest progress is enabled and call the function
		if RQE.db.profile.autoTrackProgress then
			AutoWatchQuestsWithProgress()
		end
		
		SortQuestsByProximity()
		AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	end)
end


-- Handling multiple quest related events to update the main frame
function RQE.handleQuestStatusUpdate(...)
	
	-- Attempt to fetch the current super-tracked quest ID
	local currentQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Attempt to fetch other necessary information using the currentQuestID
	local currentQuestInfo = RQEDatabase[currentQuestID]
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(currentQuestID)  -- Assuming PrintQuestStepsToChat exists and returns these values

	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)
	
	RQE:ClearWQTracking()
	UpdateRQEQuestFrame()
	SortQuestsByProximity()
	UpdateFrame(currentQuestID, currentQuestInfo, StepsText, CoordsText, MapIDs)
end
	

-- Handling QUEST_COMPLETE event
function RQE.handleQuestComplete(...)
	local questID = ...  -- Extract the questID from the event
	RQE:QuestComplete(questID)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearWQTracking()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
end
		
		
-- Handling QUEST_REMOVED event
function RQE.handleQuestRemoved(...)
	RQEQuestFrame:ClearAllPoints()
	RQE:ClearRQEQuestFrame()
	UpdateRQEQuestFrame()
	RQE:ClearWQTracking()
	SortQuestsByProximity()
	AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
end
	
		
-- Handling QUEST_WATCH_UPDATE event
function RQE.handleQuestWatchUpdate(...)
	RQEQuestFrame:ClearAllPoints()
	UpdateRQEQuestFrame()
	QuestType()
	SortQuestsByProximity()
end
		

-- Handling QUEST_WATCH_LIST_CHANGED event (If questID is nil, the event will be ignored)
function RQE.handleQuestWatchListChanged(...)
	local questID, added = ...
	RQE:ClearWQTracking()
	local watchType
	if currentQuestID then
		watchType = C_QuestLog.GetQuestWatchType(questID)
	end
	
	if questID then
		if C_QuestLog.IsWorldQuest(questID) then
			-- Handle World Quests specifically
			if added then
				-- World Quest is added to the Watch List
				-- Check if auto-tracking of quest progress is enabled and call the function
				if RQE.db.profile.autoTrackProgress then
					AutoWatchQuestsWithProgress()
				end
			else
				-- World Quest is removed from the Watch List
				RQE:ClearWQTracking()
			end
		else
			-- Handle regular quests
			--if RQEFrame:IsShown() and RQEFrame.currentQuestID == questID and RQE.db.profile.autoSortRQEFrame then
				if RQE.db.profile.autoTrackProgress then
					AutoWatchQuestsWithProgress()
					SortQuestsByProximity()
				end					
			--else
				--return
			--end
			RQEQuestFrame:ClearAllPoints()
			RQE:ClearRQEQuestFrame()
			RQE:ClearWQTracking()
			UpdateRQEQuestFrame()
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
		end
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
--end


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