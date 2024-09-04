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

---@class RQEDatabase
---@field public profileKeys table
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

-- Function to Hide the Objective Tracker (only if the toggle is enabled)
function HideObjectiveTracker()
	if not RQE.db.profile.toggleBlizzObjectiveTracker then
		-- Hide the tracker only if the toggle is disabled
		if ObjectiveTrackerFrame:IsShown() then
			ObjectiveTrackerFrame:Hide()
		end
		-- Recheck after a delay to ensure it remains hidden
		C_Timer.After(0.1, function()
			if ObjectiveTrackerFrame:IsShown() then
				ObjectiveTrackerFrame:Hide()
			end
		end)
	end
end



-- Function to Display or Hide the Objective Tracker
function RQE:ToggleObjectiveTracker()
	if RQE.db.profile.toggleBlizzObjectiveTracker then
		-- Hide RQE frames and show Blizzard Tracker
		if RQEFrame and RQEFrame:IsShown() then
			RQEFrame:Hide()
			C_Timer.After(0.5, function()
				RQE:ToggleObjectiveTracker()
			end)
		end
		if RQEQuestFrame and RQEQuestFrame:IsShown() then
			RQEQuestFrame:Hide()
			C_Timer.After(0.5, function()
				RQE:ToggleObjectiveTracker()
			end)
		end
		-- Ensure the Blizzard Objective Tracker is shown
		ObjectiveTrackerFrame:Show()
	else
		print("Showing RQE frames and hiding Blizzard Tracker")
		-- Show RQE frames and hide Blizzard Tracker
		if RQEFrame and not RQEFrame:IsShown() then
			RQEFrame:Show()
		end
		if RQEQuestFrame and not RQEQuestFrame:IsShown() then
			RQEQuestFrame:Show()
		end
		-- Ensure the Blizzard Objective Tracker is hidden
		HideObjectiveTracker()
	end
end


-- Function to Toggle RQE Frames and Blizzard Objective Tracker
function RQE:ToggleFramesAndTracker()
	if RQEFrame:IsShown() then
		-- Hide RQE frames
		RQEFrame:Hide()

		C_Map.ClearUserWaypoint()

		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end

		if RQE.MagicButton then
			RQE.MagicButton:Hide()
		end
		RQE.RQEQuestFrame:Hide()
		RQE.isRQEFrameManuallyClosed = true
		RQE.isRQEQuestFrameManuallyClosed = true

		-- Show Blizzard Tracker if the toggle is enabled
		if RQE.db.profile.toggleBlizzObjectiveTracker then
			ObjectiveTrackerFrame:Show()
		else
			ObjectiveTrackerFrame:Hide() -- Ensure it stays hidden if the toggle is disabled
		end
	else
		-- Show RQE frames
		RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQE:ClearSeparateFocusFrame()
		RQEFrame:Show()
		UpdateFrame()

		if RQE.MagicButton then
			RQE.MagicButton:Show()
		end

		if RQE.db.profile.enableQuestFrame then
			RQE.RQEQuestFrame:Show()
		end

		RQE.isRQEFrameManuallyClosed = false
		RQE.isRQEQuestFrameManuallyClosed = false

		-- Hide Blizzard Tracker if the toggle is disabled or if RQE frames are shown
		ObjectiveTrackerFrame:Hide()

		-- Check if MagicButton should be visible based on macro body
		RQE.Buttons.UpdateMagicButtonVisibility()
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
	"BAG_UPDATE",
	"BOSS_KILL",
	"CLIENT_SCENE_CLOSED",
	"CLIENT_SCENE_OPENED",
	"CONTENT_TRACKING_UPDATE",
	"CRITERIA_EARNED",
	"ENCOUNTER_END",
	"GOSSIP_CLOSED",
	--"GOSSIP_CONFIRM",
	"GOSSIP_CONFIRM_CANCEL",
	--"GOSSIP_SHOW",
	"ITEM_COUNT_CHANGED",
	"JAILERS_TOWER_LEVEL_UPDATE",
	--"LEAVE_PARTY_CONFIRMATION",
	"LFG_LIST_ACTIVE_ENTRY_UPDATE",
	"MERCHANT_UPDATE",
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
	"QUEST_COMPLETE",
	-- "QUEST_CURRENCY_LOOT_RECEIVED",
	"QUEST_FINISHED",				-- MAY BE REDUNDANT
	"QUEST_LOG_CRITERIA_UPDATE",
	"QUEST_LOG_UPDATE",				-- Necessary for updating RQEFrame and RQEQuestFrame when partial quest progress is made
	"QUEST_LOOT_RECEIVED",
	--"QUEST_POI_UPDATE",			-- Possible High Lag and unnecessary event firing/frequency
	"QUEST_REMOVED",
	"QUEST_TURNED_IN",
	"QUEST_WATCH_LIST_CHANGED",
	"QUEST_WATCH_UPDATE",
	--"QUESTLINE_UPDATE",			-- Commenting out as this fires too often resulting in some lag
	"SCENARIO_COMPLETED",
	"SCENARIO_CRITERIA_UPDATE",
	"SCENARIO_UPDATE",
	"START_TIMER",
	"SUPER_TRACKING_CHANGED",
	"TASK_PROGRESS_UPDATE",
	"TRACKED_ACHIEVEMENT_UPDATE",
	"UNIT_AURA",
	"UNIT_EXITING_VEHICLE",
	"UNIT_INVENTORY_CHANGED",
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
	-- List of events to exclude from printing
	if (RQE.db.profile.debugLevel == "INFO+") and (RQE.db.profile.showEventDebugInfo) then
		local excludeEvents = {
			["ADDON_LOADED"] = true,
			["BAG_UPDATE"] = true,
			["CHAT_MSG_CHANNEL"] = true,
			["CHAT_MSG_LOOT"] = true,
			["UNIT_INVENTORY_CHANGED"] = true,
			["NAME_PLATE_CREATED"] = true,
			["NAME_PLATE_UNIT_ADDED"] = true,
			["NAME_PLATE_UNIT_REMOVED"] = true,
			["PLAYER_STARTED_MOVING"] = true,
			["PLAYER_STOPPED_MOVING"] = true,
			["QUEST_LOG_UPDATE"] = true,
			["UNIT_AURA"] = true,
			["UNIT_INVENTORY_CHANGED"] = true,
			["UNIT_SPELLCAST_RETICLE_CLEAR"] = true,
			["UNIT_SPELLCAST_RETICLE_TARGET"] = true,
			["UNIT_SPELLCAST_START"] = true,
			["UNIT_SPELLCAST_STOP"] = true,
			["UNIT_SPELLCAST_SUCCEEDED"] = true,
			["UPDATE_INVENTORY_DURABILITY"] = true,
		}

		-- Check if the event is not in the exclude list before printing
		if not excludeEvents[event] then
			print("|cffffff00EventHandler triggered with event:|r", event)	-- Print the event name in yellow

			-- Get the current memory usage of the addon
			local addonName = "RQE"
			RQE:CheckMemoryUsage()
			local memoryUsage = GetAddOnMemoryUsage(addonName)
			local memUsageText = string.format("|cffffc0cbRQE Usage: %.2f KB|r", memoryUsage)	-- Print the current memory usage with the event in pink
			print(memUsageText)
		end
	end

	local handlers = {
		ACHIEVEMENT_EARNED = RQE.handleAchievementTracking,
		ADDON_LOADED = RQE.handleAddonLoaded,
		BAG_UPDATE = RQE.ReagentBagUpdate,
		BOSS_KILL = RQE.handleBossKill,
		CLIENT_SCENE_CLOSED = RQE.HandleClientSceneClosed,
		CLIENT_SCENE_OPENED = RQE.HandleClientSceneOpened,  -- MAY NEED TO COMMENT OUT AGAIN
		CONTENT_TRACKING_UPDATE = RQE.handleContentUpdate,
		CRITERIA_EARNED = RQE.handleCriteriaEarned,
		ENCOUNTER_END = RQE.handleBossKill,
		GOSSIP_CLOSED = RQE.handleGossipClosed,
		--GOSSIP_CONFIRM = RQE.handleGossipConfirm,
		GOSSIP_CONFIRM_CANCEL = RQE.handleGossipConfirmCancel,
		--GOSSIP_SHOW = RQE.handleGossipShow,
		ITEM_COUNT_CHANGED = RQE.handleItemCountChanged,
		JAILERS_TOWER_LEVEL_UPDATE = RQE.handleJailersUpdate,
		--LEAVE_PARTY_CONFIRMATION = RQE.handleScenarioEvent,
		LFG_LIST_ACTIVE_ENTRY_UPDATE = RQE.handleLFGActive,
		MERCHANT_UPDATE = RQE.handleMerchantUpdate,
		PLAYER_CONTROL_GAINED = RQE.handlePlayerControlGained,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,
		PLAYER_MOUNT_DISPLAY_CHANGED = RQE.handlePlayerRegenEnabled,
		PLAYER_REGEN_ENABLED = RQE.handlePlayerRegenEnabled,
		PLAYER_STARTED_MOVING = RQE.handlePlayerStartedMoving,
		PLAYER_STOPPED_MOVING = RQE.handlePlayerStoppedMoving,
		QUEST_ACCEPTED = RQE.handleQuestAccepted,
		QUEST_AUTOCOMPLETE = RQE.handleQuestAutoComplete,
		QUEST_COMPLETE = RQE.handleQuestComplete,
		QUEST_CURRENCY_LOOT_RECEIVED = RQE.handleQuestCurrencyLootReceived,
		QUEST_FINISHED = RQE.handleQuestFinished,
		QUEST_LOG_CRITERIA_UPDATE = RQE.handleQuestLogCriteriaUpdate,
		QUEST_LOG_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_LOOT_RECEIVED = RQE.handleQuestLootReceived,
		-- QUEST_POI_UPDATE = RQE.handleQuestStatusUpdate,
		QUEST_REMOVED = RQE.handleQuestRemoved,
		QUEST_TURNED_IN = RQE.handleQuestTurnIn,
		QUEST_WATCH_LIST_CHANGED = RQE.handleQuestWatchListChanged,
		QUEST_WATCH_UPDATE = RQE.handleQuestWatchUpdate,
		QUESTLINE_UPDATE = RQE.handleQuestlineUpdate,
		SCENARIO_COMPLETED = RQE.handleScenarioComplete,
		SCENARIO_CRITERIA_UPDATE = RQE.handleScenarioCriteriaUpdate,
		SCENARIO_UPDATE = RQE.handleScenarioUpdate,
		START_TIMER = RQE.handleStartTimer,
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,  -- ADD MORE DEBUG AND MAKE SURE IT WORKS
		TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,
		TRACKED_ACHIEVEMENT_UPDATE = RQE.handleTrackedAchieveUpdate,
		UNIT_AURA = RQE.handleUnitAura,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		UNIT_INVENTORY_CHANGED = RQE.handleUnitInventoryChange,
		UNIT_QUEST_LOG_CHANGED = RQE.handleUnitQuestLogChange,
		UPDATE_INSTANCE_INFO = RQE.handleInstanceInfoUpdate,
		VARIABLES_LOADED = RQE.handleVariablesLoaded,
		WORLD_STATE_TIMER_START = RQE.handleWorldStateTimerStart,
		WORLD_STATE_TIMER_STOP = RQE.handleWorldStateTimerStop,
		ZONE_CHANGED = RQE.handleZoneChange,
		ZONE_CHANGED_INDOORS = RQE.handleZoneChange,
		ZONE_CHANGED_NEW_AREA = RQE.handleZoneNewAreaChange
	}

	if handlers[event] then
		handlers[event](frame, event, unpack({...}))
	else
		RQE.debugLog("Unhandled event:", event)
	end
end


-- Example: Unregister events that are no longer needed
function RQE.UnregisterUnusedEvents()
	Frame:UnregisterEvent("EVENT_NAME")
end


-- Handles ACHIEVEMENT_EARNED events
-- Fired when an achievement is gained
function RQE.handleAchievementTracking(...)
	local event = select(2, ...)
	local achievementID = select(3, ...)
	local alreadyEarned = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventAchievementEarned and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventAchievementEarned then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: ACHIEVEMENT_EARNED event triggered for achivementID: " .. achievementID .. ", Already Earned Check: " .. tostring(alreadyEarned), 0xFA, 0x80, 0x72) -- Salmon color
	end

	RQE.UpdateTrackedAchievementList()
end


-- Handles CONTENT_TRACKING_UPDATE Events
function RQE.handleContentUpdate(...)
	local event = select(2, ...)
	local type = select(3, ...)
	local id = select(4, ...)
	local isTracked = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventContentTrackingUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if type == 2 then -- Assuming 2 indicates an achievement
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventContentTrackingUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: CONTENT_TRACKING_UPDATE event triggered for type: " .. tostring(type) .. ", id: " .. tostring(id) .. ", isTracked: " .. tostring(isTracked), 0xFA, 0x80, 0x72) -- Salmon color
		end

		RQE.UpdateTrackedAchievementList()
		RQE.UpdateTrackedAchievements(type, id, isTracked)
	end
end


-- Handles CRITERIA_EARNED event
function RQE.handleCriteriaEarned(achievementID, description)
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventCriteriaEarned then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: CRITERIA_EARNED event triggered for achievementID: " .. tostring(achievementID) .. ", description: " .. description, 0xFA, 0x80, 0x72) -- Salmon color
	end
	RQE.UpdateTrackedAchievementList()
end


-- Handles TRACKED_ACHIEVEMENT_UPDATE event
-- Fired when a timed event for an achievement begins or ends. The achievement does not have to be actively tracked for this to trigger
function RQE.handleTrackedAchieveUpdate(achievementID, criteriaID, elapsed, duration)
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showTrackedAchievementUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: TRACKED_ACHIEVEMENT_UPDATE event triggered for achievementID: " .. tostring(achievementID) .. ", criteriaID: " .. tostring(criteriaID) .. ", elapsed: " .. tostring(elapsed) .. ", duration: " .. tostring(duration), 0xFA, 0x80, 0x72) -- Salmon color		
	end
	RQE.UpdateTrackedAchievementList()
end


-- Function that handles the GOSSIP_CLOSED event
-- Fired when you close the talk window for an npc. (Seems to be called twice) 
function RQE.handleGossipClosed()
	-- Clear the raid marker from the current target
	if UnitExists("target") then
		SetRaidTarget("target", 0)
	end
end


-- Function that handles the GOSSIP_CONFIRM event
function RQE.handleGossipConfirm(...)
	local event = select(2, ...)
	local gossipID = select(3, ...)
	local text = select(4, ...)
	local cost = select(5, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end
end


-- Function that handles the GOSSIP_CONFIRM_CANCEL event
function RQE.handleGossipConfirmCancel()
	-- Nils out the npcName and Gossip optionIndex so that the same selection won't be run over and over again
	RQE.SelectGossipOption(nil, nil)
end


-- Function that handles the GOSSIP_SHOW event
-- Fires when you talk to an npc. 
-- This event typicaly fires when you are given several choices, including choosing to sell item, select available and active quests, just talk about something, or bind to a location. Even when the the only available choices are quests, this event is often used instead of QUEST_GREETING.
function RQE.handleGossipShow(...)
	local event = select(2, ...)
	local uiTextureKit = select(3, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end
end


-- Handles ITEM_COUNT_CHANGED event
function RQE.handleItemCountChanged(...)
	local event = select(2, ...)
	local itemID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showItemCountChanged and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showItemCountChanged then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: ITEM_COUNT_CHANGED event triggered for event: " .. tostring(event) .. ", ItemID: " .. tostring(itemID), 1, 0.65, 0.5)
	end

	if RQE.db.profile.autoClickWaypointButton then
		itemID = tostring(itemID)  -- Ensure the itemID is treated as a string if needed
		local itemCount = C_Item.GetItemCount(itemID)
		RQE.infoLog("Item count changed for itemID:", itemID, " to ", itemCount)

		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID then
			RQE.infoLog("Current super tracked questID:", questID)
			local questData = RQE.getQuestData(questID)
			if questData then
				if RQE.LastClickedButtonRef == nil then return end
				local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
				--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1

				-- Ensure stepIndex is within the bounds of questData
				if stepIndex >= 1 and stepIndex <= #questData then
					local stepData = questData[stepIndex]
					if stepData then
						local requiredItems = stepData.failedcheck or {}
						local neededAmounts = stepData.neededAmt or {}
						local failedAmounts = stepData.failedAmt or {}
						local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided

						for index, reqItemID in ipairs(requiredItems) do
							if tostring(reqItemID) == itemID then
								local requiredAmount = tonumber(neededAmounts[index]) or 1
								if itemCount < requiredAmount and stepData.failedfunc == "CheckDBInventory" then
									C_Timer.After(0.5, function()
										if RQE.WaypointButtons and RQE.WaypointButtons[failedIndex] then

											local previousStepData = questData[stepIndex - 1]
											if previousStepData and previousStepData.funct == "CheckDBZoneChange" then
												local currentMapID = C_Map.GetBestMapForUnit("player")
												local requiredMapIDs = previousStepData.check  -- This should be a list of mapIDs

												RQE.infoLog("Checking Map ID:", tostring(currentMapID), "Against Required IDs:", table.concat(requiredMapIDs, ", "))
												-- Check if the current map ID is in the list of required IDs
												if requiredMapIDs and #requiredMapIDs > 0 then
													for _, mapID in ipairs(requiredMapIDs) do
														if tostring(currentMapID) == tostring(mapID) then
															return
														end
													end
												end
											else
												RQE.WaypointButtons[failedIndex]:Click()
												RQE.infoLog("Inventory check failed, moving to step:", failedIndex)
											end
										else
											RQE.debugLog("No WaypointButton found for failed index:", failedIndex)
										end
									end)
									return
								end
							end
						end
					else
						RQE.debugLog("No stepData found for stepIndex:", stepIndex)
					end
				else
					RQE.debugLog("Invalid stepIndex:", stepIndex)
				end
			end
		end

		C_Timer.After(1, function()
			RQE:StartPeriodicChecks()
		end)
	end
end


-- Handles BAG_UPDATE event:
function RQE.ReagentBagUpdate(...)
	local event = select(2, ...)
	local bagID = select(3, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end

	if not RQE.db.profile.autoClickWaypointButton then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if questID then
		RQE.infoLog("Current super tracked questID:", questID)
		local questData = RQE.getQuestData(questID)
		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			if stepData then
				local requiredItems = stepData.failedcheck or {}
				local neededAmounts = stepData.neededAmt or {}
				local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided
				if stepData.failedfunc == "CheckDBInventory" then
					local previousStepData = questData[stepIndex - 1]
					if previousStepData.funct == "CheckDBZoneChange" then
						local currentMapID = C_Map.GetBestMapForUnit("player")
						local requiredMapIDs = previousStepData.check  -- This should be a list of mapIDs

						RQE.infoLog("Checking Map ID:", tostring(currentMapID), "Against Required IDs:", table.concat(requiredMapIDs, ", "))
						-- Check if the current map ID is in the list of required IDs
						if requiredMapIDs and #requiredMapIDs > 0 then
							for _, mapID in ipairs(requiredMapIDs) do
								if tostring(currentMapID) == tostring(mapID) then
									return
								end
							end
						end
					else
						RQE.ClickQuestLogIndexButton(questID)
					end
				end
			end
		end
	end
end


-- Handles MERCHANT_UPDATE event:
-- Fires when an item is bought
function RQE.handleMerchantUpdate()
	if not RQE.db.profile.autoClickWaypointButton then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if questID then
		RQE.infoLog("Current super tracked questID:", questID)
		local questData = RQE.getQuestData(questID)
		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]
			
			-- Validate that stepData exists before continuing
			if not stepData then
				RQE.infoLog("No step data found for step index:", stepIndex, "in quest ID:", questID)
				return
			end

			local requiredItems = stepData.failedcheck or {}
			local neededAmounts = stepData.neededAmt or {}
			local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided
			if stepData.failedfunc == "CheckDBInventory" then
				local previousStepData = questData[stepIndex - 1]
				if previousStepData.funct == "CheckDBZoneChange" then
					local currentMapID = C_Map.GetBestMapForUnit("player")
					local requiredMapIDs = previousStepData.check  -- This should be a list of mapIDs

					RQE.infoLog("Checking Map ID:", tostring(currentMapID), "Against Required IDs:", table.concat(requiredMapIDs, ", "))
					-- Check if the current map ID is in the list of required IDs
					if requiredMapIDs and #requiredMapIDs > 0 then
						for _, mapID in ipairs(requiredMapIDs) do
							if tostring(currentMapID) == tostring(mapID) then
								return
							end
						end
					end
				else
					RQE.ClickQuestLogIndexButton(questID)
				end
			end
		end
	end
end


-- Handles UNIT_INVENTORY_CHANGED event:
-- Fires when an item is destroyed
function RQE.handleUnitInventoryChange(...)
	local event = select(2, ...)
	local unitTarget = select(3, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end

	if unitTarget ~= "player" then  -- Only process changes for the player
		return
	end

	if not RQE.db.profile.autoClickWaypointButton then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if questID then
		RQE.infoLog("Current super tracked questID:", questID)
		local questData = RQE.getQuestData(questID)
		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			if not stepData then
				RQE.debugLog("No step data available for quest ID:", questID)
				return
			end

			local requiredItems = stepData.failedcheck or {}
			local neededAmounts = stepData.neededAmt or {}
			local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided
			if stepData.failedfunc == "CheckDBInventory" then
				local previousStepData = questData[stepIndex - 1]
				if previousStepData.funct == "CheckDBZoneChange" then
					local currentMapID = C_Map.GetBestMapForUnit("player")
					local requiredMapIDs = previousStepData.check  -- This should be a list of mapIDs

					RQE.infoLog("Checking Map ID:", tostring(currentMapID), "Against Required IDs:", table.concat(requiredMapIDs, ", "))
					-- Check if the current map ID is in the list of required IDs
					if requiredMapIDs and #requiredMapIDs > 0 then
						for _, mapID in ipairs(requiredMapIDs) do
							if tostring(currentMapID) == tostring(mapID) then
								return
							end
						end
					end
				else
					RQE.ClickQuestLogIndexButton(questID)
				end
			end
		end
	end
end


-- Function that runs after leaving combat or PLAYER_REGEN_ENABLED, PLAYER_MOUNT_DISPLAY_CHANGED
-- Fired after ending combat, as regen rates return to normal. Useful for determining when a player has left combat. 
-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
function RQE.handlePlayerRegenEnabled()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerRegenEnabled function.", 1, 0.65, 0.5)
	end

	-- Check and execute any deferred scenario updates
	if RQE.deferredScenarioCriteriaUpdate then
		--RQE.canUpdateFromCriteria = true
		RQE.updateScenarioCriteriaUI()
		RQE.deferredScenarioCriteriaUpdate = false
	end

	-- Check and execute any deferred scenario updates
	if RQE.deferredScenarioUpdate then
		RQE.updateScenarioUI()
		RQE.deferredScenarioUpdate = false
	end

	C_Timer.After(2, function()
		-- Check for Dragonriding & Capture and print the current states for debugging purposes
		if RQE.CheckForDragonMounts() then
			RQE.isDragonRiding = true
		else
			RQE.isDragonRiding = false
		end

		local isFlying = IsFlying("player")
		local isMounted = IsMounted()
		local onTaxi = UnitOnTaxi("player")

		-- Update RQE.PlayerMountStatus based on conditions
		if not RQE.isDragonRiding and isFlying and isMounted then
			RQE.PlayerMountStatus = "Flying"
		elseif RQE.isDragonRiding then
			RQE.PlayerMountStatus = "Dragonriding"
		elseif onTaxi then
			RQE.PlayerMountStatus = "Taxi"
		elseif isMounted then
			RQE.PlayerMountStatus = "Mounted"
		else
			RQE.PlayerMountStatus = "None"
		end
	end)

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.65, 0.5)
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: No quest ID extracted from text.", 1, 0.65, 0.5)
			end
		end

		-- Determine questID based on various fallbacks
		local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.65, 0.5)
		end

		C_Timer.After(0.5, function()
			RQE:StartPeriodicChecks() -- might need to comment section out if too much lag after combat (mount changes seem good)
			--RQE:CheckAndAdvanceStep(questID)
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.65, 0.5)
			end
		end)
	else
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: autoClickWaypointButton is disabled.", 1, 0.65, 0.5)
		end
	end
end


-- Handling PLAYER_LOGIN Event
-- Triggered immediately before PLAYER_ENTERING_WORLD on login and UI Reload, but NOT when entering/leaving instances
function RQE.handlePlayerLogin()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerLogin then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerLogin function.", 0.68, 0.85, 0.9)
	end

	-- Initialize other components of your AddOn
	RQE:InitializeAddon()
	RQE:InitializeFrame()

	-- Add this line to update coordinates when player logs in
	RQE:UpdateCoordinates()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Fetch current MapID to have option of appearing with Frame
	RQE:UpdateMapIDDisplay()

	-- Make sure RQE.db is initialized
	if RQE.db == nil then
		RQE.db = {}
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerLogin then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: RQE.db initialized.", 0.68, 0.85, 0.9)
		end
	end

	-- Make sure the profileKeys table is initialized
	if not RQE.db.profileKeys then
		RQE.db.profileKeys = {}
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerLogin then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: RQE.db.profileKeys initialized.", 0.68, 0.85, 0.9)
		end
	end

	if RQE.db.profile.removeWQatLogin then
		RemoveAllTrackedWorldQuests()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerLogin then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Removed all tracked World Quests.", 0.68, 0.85, 0.9)
		end
	end

	RQE:ConfigurationChanged()

	local charKey = UnitName("player") .. " - " .. GetRealmName()
	if RQE.db.profile.debugLevel == "INFO+" then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Current charKey is: " .. tostring(charKey), 0.68, 0.85, 0.9)
	end

	-- Debugging: Print the current charKey
	RQE.debugLog("Current charKey is:", charKey)

	-- This will set the profile to "Default"
	RQE.db:SetProfile("Default")
	if RQE.db.profile.debugLevel == "INFO+" then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Profile set to Default.", 0.68, 0.85, 0.9)
	end

	if RQE.db.profile.autoTrackZoneQuests then
		RQE.DisplayCurrentZoneQuests()
		if RQE.db.profile.debugLevel == "INFO+" then
			DEFAULT_CHAT_FRAME:AddMessage("Debug (From PLAYER_LOGIN): Updated tracked quests to current zone.", 0.68, 0.85, 0.9)
		end
	end
	
	if RQE.MagicButton then
		RQE:SetupOverrideMacroBinding()  -- Set the key binding using the created MagicButton
	end
	
	RQE.UntrackAutomaticWorldQuests()
end


-- Function to handle ADDON_LOADED
-- Fires after an AddOn has been loaded and is typically the first event to fire (running after all .lua files have been run and SavedVariables have loaded)
function RQE.handleAddonLoaded(self, event, addonName, containsBindings)
	-- Only proceed if RQE is the addon being loaded
	if addonName == "RQE" then
		-- RQE.infoLog("ADDON_LOADED for Rhodan's Quest Explorer")
	else
		return
	end

	-- Initialize the saved variable if it doesn't exist
	RQE_TrackedAchievements = RQE_TrackedAchievements or {}

	-- Ensure your addon uses this saved variable for tracking
	RQE.TrackedAchievementIDs = RQE_TrackedAchievements

	-- Add this line to update tracked achievements as soon as the addon is loaded
	RQE.UpdateTrackedAchievements()
	RQE.UpdateTrackedAchievementList()

	-- Hide the default objective tracker and make other UI adjustments after a short delay
	C_Timer.After(0.5, function()
		HideObjectiveTracker()

		if AdjustQuestItemWidths then
			AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())  -- Adjust quest item widths based on frame width
		end

		if RQE.UpdateFrameOpacity then
			RQE:UpdateFrameOpacity()  -- Update the frame opacity
		end
	end)

	-- Updates frame with data from the super tracked quest (if any)
	RQE:ClearWaypointButtonData()
	RQE:ClearSeparateFocusFrame()
end


-- Function to handle BOSS_KILL or ENCOUNTER_END events to update Scenario Frame
function RQE.handleBossKill(...)
	local event = select(2, ...)

	-- Print messages based on the event
	if event == "BOSS_KILL" then
		local encounterID = select(3, ...)
		local encounterName = select(4, ...)

		-- Print Event-specific Args
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.BossKill and RQE.db.profile.showArgPayloadInfo then
			local args = {...}  -- Capture all arguments into a table
			for i, arg in ipairs(args) do
				if type(arg) == "table" then
					print("Arg " .. i .. ": (table)")
					for k, v in pairs(arg) do
						print("  " .. tostring(k) .. ": " .. tostring(v))
					end
				else
					print("Arg " .. i .. ": " .. tostring(arg))
				end
			end
		end

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.BossKill then
			DEFAULT_CHAT_FRAME:AddMessage("BOSS_KILL event triggered. EncounterID: " .. tostring(encounterID) .. ", Encounter Name: " .. tostring(encounterName), 0.85, 0.33, 0.83)  -- Fuchsia Color
		end

	elseif event == "ENCOUNTER_END" then
		local encounterID = select(3, ...)
		local encounterName = select(4, ...)
		local difficultyID = select(5, ...)
		local groupSize = select(6, ...)
		local success = select(7, ...)

		-- Print Event-specific Args
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.EncounterEnd and RQE.db.profile.showArgPayloadInfo then
			local args = {...}  -- Capture all arguments into a table
			for i, arg in ipairs(args) do
				if type(arg) == "table" then
					print("Arg " .. i .. ": (table)")
					for k, v in pairs(arg) do
						print("  " .. tostring(k) .. ": " .. tostring(v))
					end
				else
					print("Arg " .. i .. ": " .. tostring(arg))
				end
			end
		end

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.EncounterEnd then
			DEFAULT_CHAT_FRAME:AddMessage("ENCOUNTER_END event triggered: EncounterID: " .. tostring(encounterID) .. ", Encounter Name: " .. tostring(encounterName) .. ", DifficultyID: " .. difficultyID .. ", Group Size: " .. tostring(groupSize) .. ", Success Check: " .. tostring(success), 0, 1, 0)  -- Bright Green
		end
	end

	--RQE.canUpdateFromCriteria = true
end



-- Function to handle LFG_LIST_ACTIVE_ENTRY_UPDATE event
function RQE.handleLFGActive(...)
	local event = select(2, ...)
	local created = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.LFGActiveEntryUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if created == true then
		RQE.LFGActive = true
	else
		RQE.LFGActive = false
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.LFGActiveEntryUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("LFG-A Debug: " .. tostring(event) .. ". Created: " .. tostring(created), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
	end
end


-- Function to handle SCENARIO_COMPLETED event
function RQE.handleScenarioComplete(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCompleted
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local xp = select(4, ...)
	local money = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCompleted and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		DEFAULT_CHAT_FRAME:AddMessage("SC Debug: " .. tostring(event) .. " completed. Quest ID: " .. tostring(questID) .. ", XP: " .. tostring(xp) .. ", Money: " .. tostring(money), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
	end
	RQE.saveScenarioData(RQE, event, questID, xp, money)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCompleted
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_COMPLETED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	RQE.updateScenarioUI()
end

-- Function to handle SCENARIO_UPDATE event
function RQE.handleScenarioUpdate(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local newStep = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		DEFAULT_CHAT_FRAME:AddMessage("SU Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)
	end

	--RQE.canUpdateFromCriteria = true
	-- Call another function if necessary, for example:
	RQE.saveScenarioData(RQE, event, newStep)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	RQE.updateScenarioUI()
end

-- Function to handle SCENARIO_CRITERIA_UPDATE event
function RQE.handleScenarioCriteriaUpdate(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local criteriaID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("SCU Debug: " .. tostring(event) .. " triggered. Criteria ID: " .. tostring(criteriaID), 0.9, 0.7, 0.9)
	end

	-- Call another function if necessary, for example:
	RQE.saveScenarioData(RQE, event, criteriaID)
	RQE.scenarioCriteriaUpdate = true

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SCENARIO_CRITERIA_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	RQE.updateScenarioCriteriaUI()
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
			if RQE.db.profile.debugLevel == "INFO+" then
				DEFAULT_CHAT_FRAME:AddMessage("SC Debug: " .. tostring(event) .. " completed. Quest ID: " .. tostring(questID) .. ", XP: " .. tostring(xp) .. ", Money: " .. tostring(money), 0.9, 0.7, 0.9)
			end
		end

	elseif event == "SCENARIO_UPDATE" then
		local newStep = unpack(args)
		if newStep then  -- Check if the step information is present
			table.insert(RQE.ScenarioData, {type = event, newStep = newStep})
			if RQE.db.profile.debugLevel == "INFO+" then
				DEFAULT_CHAT_FRAME:AddMessage("SU 01 Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
			end
		end

	elseif event == "SCENARIO_CRITERIA_UPDATE" then
		local criteriaID = unpack(args)
		if criteriaID then
			table.insert(RQE.ScenarioData, {type = event, criteriaID = criteriaID})
			if RQE.db.profile.debugLevel == "INFO+" then
				DEFAULT_CHAT_FRAME:AddMessage("Saved Criteria Update Data: Criteria ID=" .. tostring(criteriaID), 0.9, 0.7, 0.9)
			end
		end
	end
end


-- Function to handle START_TIMER event, logging the timer details:
function RQE.handleStartTimer(...)
	local event = select(2, ...)
	local timerType = select(3, ...)
	local timeRemaining = select(4, ...)
	local totalTime = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.StartTimer and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.StartTimer then
		DEFAULT_CHAT_FRAME:AddMessage("ST 01 Debug: START_TIMER event triggered. Timer Type: " .. tostring(timerType) .. ", Time Remaining: " .. tostring(timeRemaining) .. "s, Total Time: " .. tostring(totalTime) .. "s", 0.85, 0.33, 0.83)  -- Fuchsia Color
	end
	RQE:SaveWorldQuestWatches()
end

-- Function to handle WORLD_STATE_TIMER_START:
function RQE.handleWorldStateTimerStart(...)
	local event = select(2, ...)
	local timerID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.WorldStateTimerStart and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.WorldStateTimerStart then
		DEFAULT_CHAT_FRAME:AddMessage("WSTS 01 Debug: " .. tostring(event) .. " triggered. Timer ID: " .. tostring(timerID), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
	end

	RQE.StopTimer()
	RQE.StartTimer()
	RQE.HandleTimerStart(timerID)

	RQE.updateScenarioUI()
end


-- Function to handle WORLD_STATE_TIMER_STOP:
function RQE.handleWorldStateTimerStop(...)
	local event = select(2, ...)
	local timerID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.WorldStateTimerStop and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.WorldStateTimerStop then
		DEFAULT_CHAT_FRAME:AddMessage("WSTST 01 Debug: " .. tostring(event) .. " triggered. Timer ID: " .. tostring(timerID), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
	end

	-- A world timer has stopped; you might want to stop your timer as well
	RQE.StopTimer()
end


-- Handles JAILERS_TOWER_LEVEL_UPDATE event
function RQE.handleJailersUpdate(...)
	if RQE.db.profile.debugLevel == "INFO+" then
		startTime = debugprofilestop()  -- Start timer
	end

	local event = select(2, ...)
	local level = select(3, ...)
	local type = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.JailorsTowerLevelUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.JailorsTowerLevelUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handleJailersUpdate function. Level: " .. tostring(level) .. ", Type: " .. tostring(type), 0.0, 1.0, 1.0)
	end

	RQE.UpdateTorghastDetails(level, type)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.JailorsTowerLevelUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Scheduled InitializeScenarioFrame after 4 seconds.", 0.0, 1.0, 1.0)
	end
	C_Timer.After(4, function()
		RQE.updateScenarioUI()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.JailorsTowerLevelUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Initialized Scenario Frame.", 0.0, 1.0, 1.0)
		end
	end)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.JailorsTowerLevelUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed JAILERS_TOWER_LEVEL_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handles PLAYER_CONTROL_GAINED event
-- Fires after the PLAYER_CONTROL_LOST event, when control has been restored to the player (typically after landing from a taxi)
function RQE.handlePlayerControlGained()
	RQE.canSortQuests = true
	SortQuestsByProximity()
	RQE:AutoClickQuestLogIndexWaypointButton()
	RQE:StartPeriodicChecks() -- Needed for updating WaypointButton presses when getting off taxi
end


-- Handling PLAYER_STARTED_MOVING Event
function RQE.handlePlayerStartedMoving()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerStartedMoving then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Player started moving.", 0.56, 0.93, 0.56)
	end
	RQE:StartUpdatingCoordinates()
end


-- Handling PLAYER_STOPPED_MOVING Event
function RQE.handlePlayerStoppedMoving()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerStoppedMoving then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Player stopped moving.", 0.93, 0.82, 0.25)
	end
	RQE:StopUpdatingCoordinates()
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths()

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if not InCombatLockdown() then
			RQE:CheckMemoryUsage()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerStoppedMoving then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0.93, 0.82, 0.25)
			end
		end
	end
end


-- Handling VARIABLES_LOADED Event
-- Fired in response to the CVars, Keybindings and other associated "Blizzard" variables being loaded
function RQE.handleVariablesLoaded()
	RQE:InitializeFrame()
	--isVariablesLoaded = true
	C_Timer.After(0.5, function()
		HideObjectiveTracker()
	end)

	if C_Scenario.IsInScenario() then
		RQE.ScenarioChildFrame:Show()
	else
		RQE.ScenarioChildFrame:Hide()
	end

	RQE:QuestType() -- Runs UpdateRQEQuestFrame and UpdateRQEWorldQuestFrame as quest list is generated
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

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
		RQE.RQEQuestFrame:Show()
	else
		RQE.RQEQuestFrame:Hide()
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
		if RQE.ScrollFrame then
			RQE.ScrollFrame:Show()
		else
			RQE.debugLog("RQE.ScrollFrame is not initialized.")
		end

		if RQE.slider then
			RQE.slider:Show()
		else
			RQE.debugLog("RQE.slider is not initialized.")
		end

		RQE.MinimizeButton:Show()
		RQE.MaximizeButton:Hide()

	else
		-- Code to minimize the frame
		RQEFrame:SetSize(435, 30)

		if RQE.ScrollFrame then
			RQE.ScrollFrame:Hide()
		end

		if RQE.slider then
			RQE.slider:Hide()
		end

		RQE.MaximizeButton:Show()
		RQE.MinimizeButton:Hide()
	end

	-- Clear frame data and waypoints
	C_Map.ClearUserWaypoint()

	-- Check if TomTom is loaded and compatibility is enabled
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom.waydb:ResetProfile()
	end

	-- Initialize RQEQuestFrame position based on saved variables
	local xPos = RQE.db.profile.QuestFramePosition.xPos or -40
	local yPos = RQE.db.profile.QuestFramePosition.yPos or 150
	local anchorPoint = RQE.db.profile.QuestFramePosition.anchorPoint

	local validAnchorPoints = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

	if xPos and yPos and anchorPoint and tContains(validAnchorPoints, anchorPoint) then
		RQE.RQEQuestFrame:ClearAllPoints()  -- Clear any existing anchoring
		RQE.RQEQuestFrame:SetPoint(anchorPoint, UIParent, anchorPoint, xPos, yPos)
	else
		RQE.debugLog("Invalid quest frame position or anchor point.")
	end
end


-- Handling PLAYER_ENTERING_WORLD Event
-- Fires when the player logs in, /reloads the UI or zones between map instances. Basically whenever the loading screen appears
function RQE.handlePlayerEnterWorld(...)
	local event = select(2, ...)
	local isLogin = select(3, ...)
	local isReload = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if isLogin then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 01 Debug: Loaded the UI from Login.", 0.93, 0.51, 0.93)
		end
		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	elseif isReload then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 02 Debug: Loaded the UI after Reload.", 0.93, 0.51, 0.93)
		end

		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	else
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 03 Debug: Zoned between map instances.", 0.93, 0.51, 0.93)
		end
	end

	C_Timer.After(2, function()
		-- Check for Dragonriding & Capture and print the current states for debugging purposes
		if RQE.CheckForDragonMounts() then
			RQE.isDragonRiding = true
		else
			RQE.isDragonRiding = false
		end

		local isFlying = IsFlying("player")
		local isMounted = IsMounted()
		local onTaxi = UnitOnTaxi("player")

		-- Update RQE.PlayerMountStatus based on conditions
		if not RQE.isDragonRiding and isFlying and isMounted then
			RQE.PlayerMountStatus = "Flying"
		elseif RQE.isDragonRiding then
			RQE.PlayerMountStatus = "Dragonriding"
		elseif onTaxi then
			RQE.PlayerMountStatus = "Taxi"
		elseif isMounted then
			RQE.PlayerMountStatus = "Mounted"
		else
			RQE.PlayerMountStatus = "None"
		end
	end)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 04 Debug: Entering handlePlayerEnterWorld function.", 0.93, 0.51, 0.93)
	end

	C_Timer.After(1, function()  -- Delay of 1 second
		wipe(RQE.savedWorldQuestWatches)
		--RQE:HandleSuperTrackedQuestUpdate()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 05 Debug: Cleared saved World Quest watches.", 0.93, 0.51, 0.93)
		end
	end)

	local mapID = C_Map.GetBestMapForUnit("player")
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 06 Debug: Current map ID: " .. tostring(mapID), 0.93, 0.51, 0.93)
	end

	RQE.Timer_CheckTimers(GetWorldElapsedTimers())
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 07 Debug: Checked timers.", 0.93, 0.51, 0.93)
	end

	if isReload or isLogin then
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
				DEFAULT_CHAT_FRAME:AddMessage("PEW 08 Debug: In a scenario, showing ScenarioChildFrame.", 0.93, 0.51, 0.93)
			end
		else
			RQE.ScenarioChildFrame:Hide()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
				DEFAULT_CHAT_FRAME:AddMessage("PEW 09 Debug: Not in a scenario, hiding ScenarioChildFrame.", 0.93, 0.51, 0.93)
			end
		end

		UpdateRQEQuestFrame()

		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
		local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
		local questInfo = RQE.getQuestData(questID)
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

		if questID then
			-- Check to advance to next step in quest
			if RQE.db.profile.autoClickWaypointButton then

				-- C_Timer.After(0.5, function()
					-- RQE:CheckAndAdvanceStep(questID)
				-- end)

				C_Timer.After(1, function()
					-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
					RQE:StartPeriodicChecks()
				end)
			end

			UpdateFrame()
		end

		-- Handle scenario regardless of the condition
		RQE.updateScenarioUI()
	end

	C_Timer.After(2, function()
		RQE:QuestType()

		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID then
			if C_QuestLog.IsWorldQuest(questID) then
				-- This is a World Quest that is currently super tracked
				RQE.infoLog("Super tracked quest is a World Quest:", questID)
				RQE:ClickWorldQuestButton(questID)
			else
				-- This is a regular quest or other content that is super tracked
				RQE.infoLog("Super tracked content is not a World Quest:", questID)
				-- Handle regular quest or other actions if necessary
			end
		end
	end)

	-- Check if still in a scenario (useful for relogs or loading screens)
	RQE.isInScenario = C_Scenario.IsInScenario()
	RQE.UpdateCampaignFrameAnchor()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 10 Debug: isInScenario status updated.", 0.93, 0.51, 0.93)
	end

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 11 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 12 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 13 Debug: Checked memory usage.", 0.93, 0.51, 0.93)
		end
	end

	-- Clicks Waypoint Button if autoClickWaypointButton is true
	RQE:AutoClickQuestLogIndexWaypointButton()
end


-- Handling SUPER_TRACKING_CHANGED Event
-- Fired when the actively tracked location is changed
function RQE.handleSuperTracking()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	--RQEMacro:ClearMacroContentByName("RQE Macro")
	RQE.SaveSuperTrackData()
	RQE:ClearWaypointButtonData()

	-- Reset the "Clicked" WaypointButton to nil
	RQE.LastClickedIdentifier = nil
	RQE.AddonSetStepIndex = 1

	RQE.SetInitialWaypointToOne()
	UpdateFrame()

	local extractedQuestID
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Extract questID from RQE's custom UI if available
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- -- Handles situation where tracking changes from another quest tracker addon that deals with Super Tracking
	-- if ObjectiveTrackerFrame:IsShown() or not RQE.RQEQuestFrame:IsShown() then
		-- extractedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		-- if extractedQuestID then  -- Ensure extractedQuestID is not nil before setting it
			-- C_SuperTrack.SetSuperTrackedQuestID(extractedQuestID)
			-- --RQE:ClearFrameData()
			-- UpdateFrame()
		-- else
			-- RQE.infoLog("Extracted questID is nil when trying to set super tracked quest.")
		-- end
	-- else
		-- -- Assume that we're using a manually tracked quest ID if available
		-- questID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID
		-- if not questID then
			-- RQE.infoLog("All questID references are nil.")
			-- return
		-- end
	-- end

	-- if not RQE.AutoWaypointHasBeenClicked then
		-- -- Initially clicks the WaypointButton[1] after super tracking a quest via pressing QuestLogIndexButton
		-- C_Timer.After(2, function()
			-- if RQE.WaypointButtons[1] then
				-- RQE.WaypointButtons[1]:Click()
			-- end
		-- end)

		-- -- Reset the Last Clicked WaypointButton to be "1"
		-- RQE.LastClickedButtonRef = RQE.WaypointButtons[1]
	-- end

	-- RQE.AutoWaypointHasBeenClicked = true

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			--RQE:CheckAndAdvanceStep(questID)
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
		RQE:ClearFrameData()  -- changed from RQE.ClearFrameData() - which is nothing
		RQE.lastClickedObjectiveIndex = 0
	end

	-- Reset the manual super tracking flag now that we're handling it
	RQE.ManualSuperTrack = nil

	RQE:QuestType()
	RQE.superTrackingChanged = true
	RQE:UpdateSeparateFocusFrame()

	--RQE.UnknownQuestButtonCalcNTrack()

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local mapID = C_Map.GetBestMapForUnit("player")

	-- Resets RQE.LastClickedWaypointButton to nil after Manual Super Track occurred
	--if RQE.ManualSuperTrack == false and questID == extractedQuestID and extractedQuestID then
		--RQE.LastClickedWaypointButton = nil
	--end

	RQE:CreateUnknownQuestWaypoint(questID, mapID)

	if questID then
		local questName
		questName = C_QuestLog.GetTitleForQuestID(questID)
		local questLink = GetQuestLink(questID)  -- Generate the quest link

		-- if RQE.db.profile.debugLevel == "INFO" then
			-- print("Super Tracking: ", questID .. " " .. questLink)
		-- end

		RQE.debugLog("Quest Name and Quest Link: ", questName, questLink)

		-- Attempt to fetch quest info from RQEDatabase, use fallback if not present
		local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
		local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

		if StepsText and CoordsText and MapIDs then
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end
	else
		RQE.debugLog("questID is nil in SUPER_TRACKING_CHANGED event.")
		--SortQuestsByProximity()
	end

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

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
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 1.0, 0.84, 0)
		end
	end

	C_Timer.After(1, function()
		RQE.Buttons.UpdateMagicButtonVisibility()
	end)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed SUPER_TRACKING_CHANGED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	RQE.LastSuperTrackedQuestID = questID
end


-- Handling QUEST_ACCEPTED Event
-- Fires whenever the player accepts a quest
function RQE.handleQuestAccepted(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local superTrackQuest = C_SuperTrack.GetSuperTrackedQuestID()

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 01 Debug: QUEST_ACCEPTED event triggered for questID: " .. tostring(questID), 0.46, 0.62, 1)
	end

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	if questID then
		RQE.LastAcceptedQuest = questID
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local watchType = C_QuestLog.GetQuestWatchType(questID)
		local isManuallyTracked = (watchType == Enum.QuestWatchType.Manual)  -- Applies when world quest is manually watched and then accepted when player travels to world quest spot
		local questMapID = C_TaskQuest.GetQuestZoneID(questID) or GetQuestUiMapID(questID)
		local playerMapID = C_Map.GetBestMapForUnit("player")

		-- Debug Messages
		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 02 Debug: isWorldQuest: " .. tostring(isWorldQuest) .. " (" .. type(isWorldQuest) .. ")", 0.46, 0.62, 1)
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 03 Debug: watchType: " .. tostring(watchType) .. " (" .. type(watchType) .. ")", 0.46, 0.62, 1)
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 04 Debug: isManuallyTracked: " .. tostring(isManuallyTracked) .. " (" .. type(isManuallyTracked) .. ")", 0.46, 0.62, 1)
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 05 Debug: questMapID: " .. tostring(questMapID) .. " (" .. type(questMapID) .. ")", 0.46, 0.62, 1)
			-- DEFAULT_CHAT_FRAME:AddMessage("QA 06 Debug: playerMapID: " .. tostring(playerMapID) .. " (" .. type(playerMapID) .. ")", 0.46, 0.62, 1)
		-- end

		if isWorldQuest and not isManuallyTracked then
			C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Automatic)
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
				DEFAULT_CHAT_FRAME:AddMessage("QA 07 Debug: Automatically added World Quest watch for questID: " .. tostring(questID), 0.46, 0.62, 1)
			end
		elseif isWorldQuest and isManuallyTracked then
			C_QuestLog.AddWorldQuestWatch(questID, Enum.QuestWatchType.Manual)
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
				DEFAULT_CHAT_FRAME:AddMessage("QA 08 Debug: Manually added World Quest watch for questID: " .. tostring(questID), 0.46, 0.62, 1)
			end
		end

		-- Reapply the manual super-tracked quest ID if it's set and different from the current one
		if RQE.ManualSuperTrack then
			local superTrackIDToApply = RQE.ManualSuperTrackedQuestID
			if superTrackIDToApply and superTrackIDToApply ~= C_SuperTrack.GetSuperTrackedQuestID() then
				C_SuperTrack.SetSuperTrackedQuestID(superTrackIDToApply)
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
					DEFAULT_CHAT_FRAME:AddMessage("QA 09 Debug: Reapplied manual super-tracked QuestID: " .. tostring(superTrackIDToApply), 0.46, 0.62, 1)
				end
			end
		end

		if playerMapID and questMapID and playerMapID == questMapID then
			RQE.infoLog("questMapID is " .. questMapID .. " and playerMapID is " .. playerMapID)
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
				DEFAULT_CHAT_FRAME:AddMessage("QA 10 Debug: questMapID is " .. tostring(questMapID) .. " and playerMapID is " .. tostring(playerMapID), 0.46, 0.62, 1)
			end
			UpdateWorldQuestTrackingForMap(playerMapID)
		end
	end

	RQE:UpdateSeparateFocusFrame()

	-- Delay to check for a blank RQEFrame and attempt to click the QuestLogIndexButton if necessary
	if not RQE.QuestIDText or not RQE.QuestIDText:GetText() or RQE.QuestIDText:GetText() == "" then
		C_Timer.After(2, function()
			RQE.infoLog("RQEFrame appears blank, attempting to click QuestLogIndexButton for questID:", questID)
			RQE.ClickQuestLogIndexButton(questID)
		end)
	else
		RQE.infoLog("RQEFrame is not blank, skipping QuestLogIndexButton click.")
	end

	-- Update Frame with the newly accepted quest if nothing is super tracked
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 11 Debug: Updating Frame.", 0.46, 0.62, 1)
	end

	C_Timer.After(1, function()  -- Delay of 1 second
		UpdateFrame()
	end)

	-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	if RQE.db.profile.autoClickWaypointButton then
		RQE:StartPeriodicChecks()
	end

	-- Visibility Update Check for RQEFrame & RQEQuestFrame
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 12 Debug: UpdateRQEFrameVisibility.", 0.46, 0.62, 1)
	end

	RQE:UpdateRQEFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 13 Debug: UpdateRQEQuestFrameVisibility.", 0.46, 0.62, 1)
	end

	RQE:UpdateRQEQuestFrameVisibility()

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
			DEFAULT_CHAT_FRAME:AddMessage("QA 14 Debug: Checked memory usage.", 0.46, 0.62, 1)
		end
	end

	-- Calls for an update to the special Quest Item Buttons
	--RQE:UpdateQuestItemButtons()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_ACCEPTED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling of UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS
-- Fired as a unit is about to exit a vehicle, as compared to UNIT_EXITED_VEHICLE which happens afterward or Fires when the player enters a subzone
function RQE.handleZoneChange(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)

	if C_Scenario.IsInScenario() then
		RQE.updateScenarioUI()
	end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	RQE.canSortQuests = true

	C_Timer.After(2, function()
		-- Check for Dragonriding & Capture and print the current states for debugging purposes
		if RQE.CheckForDragonMounts() then
			RQE.isDragonRiding = true
		else
			RQE.isDragonRiding = false
		end

		local isFlying = IsFlying("player")
		local isMounted = IsMounted()
		local onTaxi = UnitOnTaxi("player")

		-- Update RQE.PlayerMountStatus based on conditions
		if not RQE.isDragonRiding and isFlying and isMounted then
			RQE.PlayerMountStatus = "Flying"
		elseif RQE.isDragonRiding then
			RQE.PlayerMountStatus = "Dragonriding"
		elseif onTaxi then
			RQE.PlayerMountStatus = "Taxi"
		elseif isMounted then
			RQE.PlayerMountStatus = "Mounted"
		else
			RQE.PlayerMountStatus = "None"
		end
	end)

	if event == "UNIT_EXITING_VEHICLE" then
		local unitTarget = select(3, ...)
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: UNIT_EXITING_VEHICLE triggered for " .. tostring(...) .. ".", 0, 1, 1)  -- Cyan
		end
	end

	if RQE.PlayerMountStatus == "None" or RQE.PlayerMountStatus == "Mounted" then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. SubZone Text: " .. tostring(GetSubZoneText()), 0, 1, 1)  -- Cyan
		end

		C_Timer.After(1.0, function()  -- Delay of 1 second

			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID), 0, 1, 1)  -- Cyan
			end

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
			local extractedQuestID
			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			end

			-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
			local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
			local questInfo = RQE.getQuestData(questID)
			local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)

		-- SortQuestsByProximity()	-- HANDLED THRU ZONE_CHANGED_NEW_AREA
		-- AdjustQuestItemWidths(RQEQuestFrame:GetWidth())
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if RQE.PlayerMountStatus ~= "Flying" and not InCombatLockdown() then
		-- if not IsFlying("player") or not InCombatLockdown() then
			RQE.debugLog("Player not flying or dragonriding")
			RQE:CheckMemoryUsage()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0, 1, 1)
			end
		else
			RQE.debugLog("Player is flying or dragonriding")
		end
	end

	-- -- Fail safe that will hide Scenario Frame on ZONE_CHANGE 
	-- if RQE.ScenarioChildFrame:IsShown then
		-- if C_Scenario.IsInScenario() then
			-- RQE.ScenarioChildFrame:Show()
			-- RQE.updateScenarioUI()
		-- else
			-- RQE.ScenarioChildFrame:Hide()
			-- RQE.updateScenarioUI()
		-- end
	-- end

	-- Auto Clicks the QuestLogIndexButton when this event fires
	--RQE:AutoClickQuestLogIndexWaypointButton()

	-- -- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	-- if RQE.db.profile.autoClickWaypointButton then
		-- RQE:StartPeriodicChecks()
	-- end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	-- Scrolls frame to top when changing to a new area
	RQE.QuestScrollFrameToTop()

	-- Clears World Quest that are Automatically Tracked when switching to a new area
	RQE.UntrackAutomaticWorldQuests()
end


-- Handles the event ZONE_CHANGED_NEW_AREA
-- Fires when the player enters a new zone
function RQE.handleZoneNewAreaChange()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
		-- startTime = debugprofilestop()  -- Start timer
		DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. Zone Text: " .. GetZoneText(), 0, 1, 1)  -- Cyan
	end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		local playerMapID = C_Map.GetBestMapForUnit("player")
		local questData = RQE.getQuestData(questID)

		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			if stepData then
				local failedIndex = stepData.failedIndex or stepIndex -- Default to current step if no failedIndex is provided

				-- Log the failed check details if available
				if stepData.failedfunc then
					RQE.infoLog(tostring(stepData.failedfunc) .. " " .. table.concat(stepData.failedcheck or {}, ", "))
				end

				if stepData.failedfunc == "CheckDBZoneChange" and not table.includes(stepData.failedcheck, tostring(playerMapID)) then
					C_Timer.After(0.5, function()
						if RQE.WaypointButtons and RQE.WaypointButtons[failedIndex] then
							RQE.WaypointButtons[failedIndex]:Click()
						else
							RQE.debugLog("Failed to find WaypointButton for index:", failedIndex)
						end
					end)
				end
			end
		end
	end

	if RQE.PlayerMountStatus == "Flying" then
	-- if not UnitOnTaxi("player") and not RQE.isDragonRiding then
		C_Timer.After(1.5, function()

			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
			end

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
			end

			SortQuestsByProximity()

			AdjustRQEFrameWidths()
			AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())
		end)

		-- -- Check to advance to next step in quest  -- HANDLED THRU QUEST_WATCH_LIST_CHANGED
		-- if RQE.db.profile.autoClickWaypointButton then
			-- C_Timer.After(0.7, function()
				-- RQE:StartPeriodicChecks()
			-- end)
		-- end
	elseif RQE.PlayerMountStatus == "Dragonriding" then
	--elseif not UnitOnTaxi("player") and RQE.isDragonRiding then
		RQE.canSortQuests = true
		C_Timer.After(0.5, function()
			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
			end

			-- local questInfo = RQE.getQuestData(questID)  -- HANDLED IN UPDATEFRAME
			-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)  -- Assuming PrintQuestStepsToChat exists and returns these values

			RQE:UpdateMapIDDisplay()
		end)
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if not RQE.PlayerMountStatus == "Flying" and not InCombatLockdown() then
		--if not IsFlying("player") or not InCombatLockdown() then
			RQE.debugLog("Player not flying or dragonriding")
			RQE:CheckMemoryUsage()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0, 1, 1)
			end
		else
			RQE.debugLog("Player is flying or dragonriding")
		end
	end

	if RQE.db and RQE.db.profile.autoTrackZoneQuests then
		local mapID = C_Map.GetBestMapForUnit("player")
		RQE.filterByZone(mapID)
	end

	-- Scrolls frame to top when changing to a new area
	RQE.QuestScrollFrameToTop()

	-- Clears World Quest that are Automatically Tracked when switching to a new area
	RQE.UntrackAutomaticWorldQuests()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed ZONE_CHANGED_NEW_AREA in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handles UNIT_AURA event
function RQE.handleUnitAura(...)
	local event = select(2, ...)
	local unitToken = select(3, ...)
	local spellName = select(4, ...)
	local filter = select(4, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end

	if unitToken ~= "player" then  -- Only process changes for the player
		return
	end

	if RQE.db.profile.autoClickWaypointButton then
		-- Only process the event if it's for the player and not in a taxi
		if RQE.HasDragonraceAura() or RQE.PlayerMountStatus ~= "Taxi" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			if not questID then
				RQE.debugLog("No super tracked quest ID found, skipping aura checks.")
				return
			end

			local questData = RQE.getQuestData(questID)
			if not questData then
				RQE.debugLog("No quest data available for quest ID:", questID)
				return
			end

			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			--local stepIndex = RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			if not stepData then
				RQE.debugLog("No step data available for quest ID:", questID)
				return
			end

			-- Process 'funct' for buffs or debuffs if specified
			if stepData and stepData.funct then
				if string.find(stepData.funct, "CheckDBBuff") or string.find(stepData.funct, "CheckDBDebuff") then
					RQE[stepData.funct](questID, stepIndex)
				end
			end

			-- Handle failed functions based on losing a buff or debuff
			if stepData.failedfunc and (string.find(stepData.failedfunc, "CheckDBBuff") or string.find(stepData.failedfunc, "CheckDBDebuff")) then
				local hasAura = false
				for _, auraName in ipairs(stepData.failedcheck or {}) do
					if C_UnitAuras.GetAuraDataBySpellName("player", auraName) then
						hasAura = true
						break
					end
				end

				-- If the aura is not present and it's a condition for failure, trigger the failure response
				if not hasAura then
					local failedIndex = stepData.failedIndex or stepIndex
					C_Timer.After(0.5, function()
						if RQE.WaypointButtons and RQE.WaypointButtons[failedIndex] then
							RQE.WaypointButtons[failedIndex]:Click()
							RQE.debugLog("Aura check failed, moving to step:", failedIndex)
						else
							RQE.debugLog("No WaypointButton found for failed index:", failedIndex)
						end
					end)
				end
			end
		end
	end
end


-- Handles UNIT_QUEST_LOG_CHANGED event:
function RQE.handleUnitQuestLogChange(...)
	local event = select(2, ...)
	local unitTarget = select(3, ...)

	-- -- Print Event-specific Args
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
		-- local args = {...}  -- Capture all arguments into a table
		-- for i, arg in ipairs(args) do
			-- if type(arg) == "table" then
				-- print("Arg " .. i .. ": (table)")
				-- for k, v in pairs(arg) do
					-- print("  " .. tostring(k) .. ": " .. tostring(v))
				-- end
			-- else
				-- print("Arg " .. i .. ": " .. tostring(arg))
			-- end
		-- end
	-- end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Only process the event if it's for the player
	if unitTarget == "player" and not RQE.PlayerMountStatus == "Taxi" then
	--if unitTarget == "player" and not UnitOnTaxi("player") then	
		-- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
		if RQE.db.profile.autoClickWaypointButton then
			RQE:StartPeriodicChecks()
		end
	end

	-- Only process the event if the achievements frame is shown
	if RQE.AchievementsFrame:IsShown() then
		C_Timer.After(2, function()
			-- Ensure that the RQEQuestFrame updates when the quest is accepted (including World Quests)
			RQE:QuestType()
		end)
	end
end


-- Function that handles the Scenario UI Updates coming from SCENARIO_CRITERA_UPDATE
function RQE.updateScenarioCriteriaUI()
	-- If we're in combat, defer the update
	if InCombatLockdown() then
		RQE.deferredScenarioCriteriaUpdate = true
		return
	end

	-- Check to see if player in scenario, if not it will end
	if not C_Scenario.IsInScenario() then
		if RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()
		return
	end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	-- Get the current scenario information
	local scenarioName, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete, completed = C_Scenario.GetInfo()

	-- Check if the scenario has been marked as completed
	if completed then
		-- If the scenario is complete, avoid further updates or handle differently
		if RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()

		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
			-- local duration = debugprofilestop() - startTime
			-- DEFAULT_CHAT_FRAME:AddMessage("Processed updateScenarioCriteriaUI completed in: " .. duration .. "ms", 0.25, 0.75, 0.85)
		-- end
		return
	end

	-- if not RQE.canUpdateFromCriteria then
		-- return  -- Skip processing if the flag is false
	-- end

	-- If not completed, proceed with regular updates
	-- if not IsFlying("player") and not UnitOnTaxi("player") then
		-- RQE.LogScenarioInfo()
		-- RQE.PrintScenarioCriteriaInfoByStep()
	-- end

	if C_Scenario.IsInScenario() then
		if not RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Show()
		end
		RQE.InitializeScenarioFrame()
		RQE.UpdateScenarioFrame()
		--RQE.Timer_CheckTimers()
		RQE.StartTimer()
		RQE.QuestScrollFrameToTop()  -- Moves ScrollFrame of RQEQuestFrame to top
	else
		RQE.ScenarioChildFrame:Hide()
		RQE.StopTimer()
	end

	UpdateRQEQuestFrame()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("updateScenarioCriteriaUI: Called UpdateRQEQuestFrame (1431).", 1, 0.75, 0.79)
	end
	RQE.UpdateCampaignFrameAnchor()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()

	--RQE.canUpdateFromCriteria = false
	RQE.scenarioCriteriaUpdate = false	-- Flag that denotes if the event that was run prior to this was SCENARIO_CRITERIA_UPDATE

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed full updateScenarioUI in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end

-- Function that handles the Scenario UI Updates
function RQE.updateScenarioUI()
	-- If we're in combat, defer the update
	if InCombatLockdown() then
		RQE.deferredScenarioUpdate = true  -- Set a flag to update after combat
		return
	end

	-- Check to see if player in scenario, if not it will end
	if not C_Scenario.IsInScenario() then
		if RQE.ScenarioChildFrame:IsVisible() then
			--print("Hiding Scenario Frame that is visible")
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			--print("Hiding Timer that is visible")
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()
		UpdateRQEQuestFrame()
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- DEFAULT_CHAT_FRAME:AddMessage("updateScenarioUI: Called UpdateRQEQuestFrame (1470).", 1, 0.75, 0.79)
		-- end
		return
	end

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	-- Get the current scenario information
	local scenarioName, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete, completed = C_Scenario.GetInfo()

	-- Check if the scenario has been marked as completed
	if completed then
		--print("Scenario is completed. Skipping updates.")
		-- If the scenario is complete, avoid further updates or handle differently
		if RQE.ScenarioChildFrame:IsVisible() then
			--print("Hiding Scenario Frame that is visible")
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			--print("Hiding Timer that is visible")
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()

		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- local duration = debugprofilestop() - startTime
			-- DEFAULT_CHAT_FRAME:AddMessage("Processed updateScenarioUI completed in: " .. duration .. "ms", 0.25, 0.75, 0.85)
		-- end
		return
	end

	-- If not completed, proceed with regular updates
	-- if not IsFlying("player") and not UnitOnTaxi("player") then
		-- RQE.LogScenarioInfo()
		-- RQE.PrintScenarioCriteriaInfoByStep()
	-- end

	if C_Scenario.IsInScenario() then
		if not RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Show()
		end
		RQE.InitializeScenarioFrame()
		RQE.UpdateScenarioFrame()
		--RQE.Timer_CheckTimers()
		RQE.StartTimer()
		RQE.QuestScrollFrameToTop()  -- Moves ScrollFrame of RQEQuestFrame to top
	else
		RQE.ScenarioChildFrame:Hide()
		RQE.StopTimer()
	end

	UpdateRQEQuestFrame()
	if RQE.db.profile.debugLevel == "INFO+" then
		DEFAULT_CHAT_FRAME:AddMessage("updateScenarioUI: Called UpdateRQEQuestFrame (1521).", 1, 0.75, 0.79)
	end

	RQE.UpdateCampaignFrameAnchor()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed full updateScenarioCriteriaUI in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handles UPDATE_INSTANCE_INFO Event
-- Fired when data from RequestRaidInfo is available and also when player uses portals
function RQE.handleInstanceInfoUpdate()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.UpdateInstanceInfo then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	if not RQE.UpdateInstanceInfoOkay then
		return
	end

	-- Updates the achievement list for criteria of tracked achievements
	RQE.UpdateTrackedAchievementList()

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE:StartPeriodicChecks()
		end)
	end

	-- Update RQEFrame and Refresh Quest Tracker
	UpdateFrame()
	RQE:QuestType()

	RQE.UpdateInstanceInfoOkay = false
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.UpdateInstanceInfo then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed UPDATE_INSTANCE_INFO in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handles QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE events
-- Fires when the quest log updates, or whenever Quest POIs change (For example after accepting an quest)
function RQE.handleQuestStatusUpdate()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	RQE:UpdateSeparateFocusFrame()

	-- Restore Automatic World Quests that have been saved to their table
	if RQE.ReadyToRestoreAutoWorldQuests then
		RQE:RestoreSavedAutomaticWorldQuestWatches()
		RQE.ReadyToRestoreAutoWorldQuests = false
	end

	-- -- Check for actual progress in the quest objectives of all watched quests ***
	-- if not RQE.hasQuestProgressChanged() then
		-- RQE.debugLog("No quest progress made across watched quests. Skipping update.")
		-- return
	-- else
		-- -- Process updates only if there's actual progress detected
		-- RQE.debugLog("Quest progress detected across watched quests. Processing update.")
	-- end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

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
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
				-- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_CURRENCY_LOOT_RECEIVED", 0, 1, 0)  -- Bright Green
			-- end
			-- -- Use eventInfo.questID, eventInfo.currencyId, eventInfo.quantity as needed
		-- elseif eventInfo.eventType == "QUEST_LOG_CRITERIA_UPDATE" then
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
				-- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_LOG_CRITERIA_UPDATE", 0, 1, 0)  -- Bright Green
			-- end
			-- -- Use eventInfo.questID, eventInfo.specificTreeID, eventInfo.description , eventInfo.numFulfilled, eventInfo.numRequired as needed			
		-- elseif eventInfo.eventType == "QUEST_LOOT_RECEIVED" then
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
				-- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUEST_LOOT_RECEIVED", 0, 1, 0)  -- Bright Green
			-- end
			-- -- Use eventInfo.questID, eventInfo.itemLink, eventInfo.quantity as needed			
		-- elseif eventInfo.eventType == "QUESTLINE_UPDATE" then
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
				-- DEFAULT_CHAT_FRAME:AddMessage("Processing event data for QUESTLINE_UPDATE", 0, 1, 0)  -- Bright Green
			-- end
			-- -- Use eventInfo.requestRequired as needed
		-- end
		-- -- Reset for next event call
		-- RQE.latestEventInfo = nil
	-- else
		-- -- Your existing logic for handling quest status updates without specific event data
	-- end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest Status Update Triggered. SuperTracking: " .. tostring(isSuperTracking) .. ", QuestID: " .. tostring(questID) .. ", Super Tracked QuestID: " .. tostring(currentSuperTrackedquestID), 0, 1, 0)  -- Bright Green
	end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.PlayerMountStatus == "Flying" or RQE.PlayerMountStatus ~= "Taxi" or RQE.PlayerMountStatus ~= "Dragonriding" then
	--if not IsFlying("player") and not UnitOnTaxi("player") and not RQE.isDragonRiding then
		C_Timer.After(0.7, function()
			if questID then
				if RQE.ManualSuperTrack and questID ~= RQE.ManualSuperTrackedQuestID then
					C_SuperTrack.SetSuperTrackedQuestID(RQE.ManualSuperTrackedQuestID)
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
						DEFAULT_CHAT_FRAME:AddMessage("Debug: Manual Super Tracking set for QuestID: " .. tostring(RQE.ManualSuperTrackedQuestID), 0, 1, 0)  -- Bright Green
					end
				end

				-- -- Debug messages for the above variables
				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: QuestInfo: " .. (questInfo and "Found" or "Not Found"), 0, 1, 0)  -- Bright Green
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: StepsText: " .. tostring(StepsText), 0, 1, 0)  -- Bright Green, assuming StepsText is properly defined
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: CoordsText: " .. tostring(CoordsText), 0, 1, 0)  -- Bright Green, assuming CoordsText is properly defined
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: MapIDs: " .. tostring(MapIDs), 0, 1, 0)  -- Bright Green, assuming MapIDs is properly defined
				-- end

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
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
						DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest Lines Cached", 0, 1, 0)  -- Bright Green
					end
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

			-- RQE:QuestType()
			-- UpdateRQEQuestFrame()
			-- SortQuestsByProximity()

			-- -- Visibility Update Check for RQEQuestFrame
				-- RQE:UpdateRQEQuestFrameVisibility()
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
					-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Not SuperTracking or QuestID not found", 0, 1, 0)  -- Bright Green
				-- end
			-- end

			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			UpdateRQEQuestFrame()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
				DEFAULT_CHAT_FRAME:AddMessage("handleQuestStatusUpdate: Called UpdateRQEQuestFrame (1686).", 1, 0.75, 0.79)
			end
		end)
	end
	
	UpdateRQEQuestFrame()
	UpdateRQEWorldQuestFrame()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_CURRENCY_LOOT_RECEIVED event
function RQE.handleQuestCurrencyLootReceived(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestCurrencyLootReceived then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local currencyId = select(4, ...)
	local quantity = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestCurrencyLootReceived and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestCurrencyLootReceived then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_CURRENCY_LOOT_RECEIVED for questID: " .. tostring(questID) .. ", CurrencyID: " .. tostring(currencyId) .. ", Quantity: " .. tostring(quantity), 0, 1, 0)  -- Bright Green
	end

	-- Saving event specific information before calling the status update function
	RQE.latestEventInfo = {
		eventType = "QUEST_CURRENCY_LOOT_RECEIVED",
		questID = questID,
		currencyId = currencyId,
		quantity = quantity
	}

	--RQE.handleQuestStatusUpdate()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestCurrencyLootReceived then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_CURRENCY_LOOT_RECEIVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end

	RQE.QuestScrollFrameToTop()
end


-- Handling QUEST_LOG_CRITERIA_UPDATE event
function RQE.handleQuestLogCriteriaUpdate(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLogCriteriaUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local questID = select(4, ...)
	local specificTreeID = select(5, ...)
	local description = select(6, ...)
	local numFulfilled = select(7, ...)
	local numRequired = select(8, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLogCriteriaUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLogCriteriaUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_LOG_CRITERIA_UPDATE for questID: " .. tostring(questID) .. ", SpecificTreeID: " .. tostring(specificTreeID) .. ", Description: " .. description .. ", Fulfilled: " .. tostring(numFulfilled) .. ", Required: " .. tostring(numRequired), 0, 1, 0)  -- Bright Green
	end

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

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLogCriteriaUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOG_CRITERIA_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_LOOT_RECEIVED event
-- Fires when player receives loot from quest turn in (Runs once per quest loot received)
function RQE.handleQuestLootReceived(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLootReceived then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local itemLink = select(4, ...)
	local quantity = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLootReceived and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLootReceived then
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_LOOT_RECEIVED for questID: " .. tostring(questID) .. ", ItemLink: " .. itemLink .. ", Quantity: " .. tostring(quantity), 0, 1, 0)  -- Bright Green
	-- end

	-- Saving event specific information before calling the status update function
	RQE.latestEventInfo = {
		eventType = "QUEST_LOOT_RECEIVED",
		questID = questID,
		itemLink = itemLink,
		quantity = quantity
	}

	--RQE.handleQuestStatusUpdate()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestLootReceived then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_LOOT_RECEIVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUESTLINE_UPDATE event
function RQE.handleQuestlineUpdate(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestlineUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	-- Extracting the third argument as 'requestRequired'
	local event = select(2, ...)
	local requestRequired = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestlineUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestlineUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUESTLINE_UPDATE, Request Required: " .. tostring(requestRequired), 0, 1, 0)  -- Bright Green
	end

	-- Saving event specific information before calling the status update function
	RQE.latestEventInfo = {
		eventType = "QUESTLINE_UPDATE",
		requestRequired = requestRequired
	}

	--RQE.handleQuestStatusUpdate()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestlineUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUESTLINE_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_COMPLETE event
-- Fired after the player hits the "Continue" button in the quest-information page, before the "Complete Quest" button. In other words, it fires when you are given the option to complete a quest, but just before you actually complete the quest. 
function RQE.handleQuestComplete()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	local extractedQuestID

	isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(extractedQuestID), 0, 0.75, 0.75)
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for SuperTracked QuestID: " .. tostring(currentSuperTrackedQuestID), 0, 0.75, 0.75)
		end
	end

	-- Determine questID based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	end

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

	-- Update RQEFrame and Refresh Quest Tracker
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs) -- was commented out for unknown reason
	RQE:QuestType()

	RQEFrame:ClearAllPoints()
	RQE.RQEQuestFrame:ClearAllPoints()
	--UpdateRQEQuestFrame()
	--UpdateRQEWorldQuestFrame()
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- -- Check to advance to next step in quest
	-- if RQE.db.profile.autoClickWaypointButton then	
		-- RQE:CheckAndAdvanceStep(questID)
	-- end

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 04 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 05 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)
	end

	if not RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(2, function()
			--RQE.ClickUnknownQuestButton()
			RQE:StartPeriodicChecks()
		end)
	end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_COMPLETE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end

-- Handling QUEST_AUTOCOMPLETE events
-- Fires when a quest that can be auto-completed is completed
function RQE.handleQuestAutoComplete(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

		-- Extracting elements
	local event = select(2, ...)
	local questID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	-- local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	-- if isSuperTracking then
		-- local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	-- end

	-- local extractedQuestID
	-- if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		-- extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	-- end

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local questID = RQE.searchedQuestID or questID --or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 03 Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	end

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

	-- Update RQEFrame and Refresh Quest Tracker
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQE:QuestType()

	RQEFrame:ClearAllPoints()
	RQE.RQEQuestFrame:ClearAllPoints()
	--RQE:QuestType()
	--UpdateRQEQuestFrame()
	--UpdateRQEWorldQuestFrame()
	SortQuestsByProximity()

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			--RQE:CheckAndAdvanceStep(questID)
		end)
	end

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 04 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()
	
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 05 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
		DEFAULT_CHAT_FRAME:AddMessage("QAC 06 Debug: Quest completion process concluded for questID: " .. tostring(questID), 0, 0.75, 0.75)

		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_AUTOCOMPLETE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	end
end


-- Handling CLIENT_SCENE_OPENED event (saving of World Quests when event fires):
function RQE.HandleClientSceneOpened(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local sceneType = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	-- Debug message indicating the type of scene opened
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened then
		DEFAULT_CHAT_FRAME:AddMessage("CSO 01 Debug: CLIENT_SCENE_OPENED event triggered. Scene Type: " .. tostring(sceneType), 0.95, 0.95, 0.7)  -- Faded Yellow Color
	end

	RQE:SaveWorldQuestWatches()  -- Save the watch list when a scene is opened

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed CLIENT_SCENE_OPENED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling CLIENT_SCENE_CLOSED event (restoring of World Quests when event fires):
function RQE.HandleClientSceneClosed()
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	RQE.isRestoringWorldQuests = true
	C_Timer.After(1, function()
		RQE:RestoreSavedWorldQuestWatches()
		-- Set isRestoringWorldQuests back to false after all quests are restored
		C_Timer.After(2, function() -- adjust the delay as needed
			RQE.isRestoringWorldQuests = false
		end)
	end)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ClientSceneOpened then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed CLIENT_SCENE_CLOSED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_REMOVED event
function RQE.handleQuestRemoved(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	RQE:SaveAutomaticWorldQuestWatches()
	RQE.ReadyToRestoreAutoWorldQuests = true
	RQE:UpdateSeparateFocusFrame()

	-- Extract questID and wasReplayQuest from the correct argument positions
	local event = select(2, ...)
	local questID = select(3, ...)
	local wasReplayQuest = select(4, ...)
	local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if not currentSuperTrackedQuestID then
		currentSuperTrackedQuestID = RQE.LastSuperTrackedQuestID  -- Use the last known super-tracked questID if current is nil
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_REMOVED event triggered for questID: " .. tostring(questID) .. ", wasReplayQuest: " .. tostring(wasReplayQuest), 0.82, 0.70, 0.55) -- Light brown color
	end

	RQEFrame:ClearAllPoints()
	RQE.RQEQuestFrame:ClearAllPoints()
	--RQE:ClearRQEQuestFrame() -- HANDLED AT START OF UpdateRQEQuestFrame() FUNCTION
	RQE:QuestType()
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	RQE:ShouldClearFrame() -- Clears RQEFrame of WQ that is no longer being tracked
	--RQE.UntrackAutomaticWorldQuests()

	-- Check if the questID is valid and if it was being tracked automatically
	if questID and RQE.TrackedQuests[questID] == Enum.QuestWatchType.Automatic then
		-- Remove the quest from the tracking list
		C_QuestLog.RemoveWorldQuestWatch(questID)
		-- Clear the saved state for this quest
		RQE.TrackedQuests[questID] = nil
		-- DEFAULT_CHAT_FRAME:AddMessage("Debug: Removed automatic World Quest watch for questID: " .. tostring(questID), 0.82, 0.70, 0.55) -- Light brown color
	end

	-- FLAG: Is the below necessary? Or redundant code that results in slowing
	-- Check if the removed quest is the currently super-tracked quest
	if questID == RQE.LastSuperTrackedQuestID then
		-- Clear user waypoint and reset TomTom if loaded
		C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end

		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
		local questID = RQE.searchedQuestID or extractedQuestID or questID or C_SuperTrack.GetSuperTrackedQuestID()
		local questInfo = RQE.getQuestData(questID)
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

		-- Update RQEFrame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)

		-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
		RQE:UpdateRQEFrameVisibility()

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
			DEFAULT_CHAT_FRAME:AddMessage("QR 01 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
		end

		RQE:UpdateRQEQuestFrameVisibility()

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
			DEFAULT_CHAT_FRAME:AddMessage("QR 02 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
		end
	end

	-- -- Resets Quest Progress ***
	-- RQE.hasStateChanged()
	-- RQE.hasQuestProgressChanged()

	-- if questID == RQE.LastSuperTrackedQuestID then
		-- RQE.AutoWaypointHasBeenClicked = false
	-- end

	-- Calls for an update to the special Quest Item Buttons
	--RQE:UpdateQuestItemButtons()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_REMOVED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_WATCH_UPDATE event
-- Fires each time the objectives of the quest with the supplied questID update, i.e. whenever a partial objective has been accomplished: killing a mob, looting a quest item etc
-- UNIT_QUEST_LOG_CHANGED and QUEST_LOG_UPDATE both also seem to fire consistently – in that order – after each QUEST_WATCH_UPDATE.
function RQE.handleQuestWatchUpdate(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Received questID: " .. tostring(questID), 0.56, 0.93, 0.56) -- Light Green
	end

	if type(questID) ~= "number" then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("QWU 01 Error: questID is not a number.", 0.56, 0.93, 0.56)
		end
		-- UpdateFrame()
		return
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 02 Debug: QUEST_WATCH_UPDATE event triggered for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
	end

	-- Initialize variables
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	RQE:UpdateSeparateFocusFrame()

	if isSuperTracking then
		RQEMacro:ClearMacroContentByName("RQE Macro")

		local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		local superTrackedQuestName = "Unknown Quest"  -- Default if ID is nil or no title found

		if currentSuperTrackedQuestID then
			superTrackedQuestName = C_QuestLog.GetTitleForQuestID(currentSuperTrackedQuestID) or "Unknown Quest"
		end

		if currentSuperTrackedQuestID == questID then
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
				DEFAULT_CHAT_FRAME:AddMessage("Quest is already super tracked: " .. superTrackedQuestName, 0.56, 0.93, 0.56)
			end
			questID = currentSuperTrackedQuestID
		end
	else
		C_SuperTrack.SetSuperTrackedQuestID(questID)

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("Now super tracking quest: " .. superTrackedQuestName, 0.56, 0.93, 0.56)
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 03 Debug: Current super tracked quest ID/Name: " .. tostring(currentSuperTrackedQuestID) .. " / " .. superTrackedQuestName, 0.56, 0.93, 0.56)
	end

	RQEFrame:ClearAllPoints()
	RQE.RQEQuestFrame:ClearAllPoints()

	-- Further processing
	RQE:QuestType()
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 04 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 05 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- Adds quest to watch list when progress made
	C_QuestLog.AddQuestWatch(questID)

	--if questID then
	-- Retrieve the current watched quest ID if needed
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
	local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
	local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID) or false
	local questLink = GetQuestLink(questID)
	local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 06 Debug: Quest info - QuestID: " .. tostring(questID) .. ", Name: " .. questName, 0.56, 0.93, 0.56)
		DEFAULT_CHAT_FRAME:AddMessage("QWU 07 Debug: Is quest completed: " .. tostring(isQuestCompleted), 0.56, 0.93, 0.56)
	end

	if questInfo then
		-- If you need details about the quest, fetch them here
		for i, step in ipairs(questInfo) do
			StepsText[i] = step.description
			CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
			MapIDs[i] = step.coordinates.mapID
			questHeader[i] = step.description:match("^(.-)\n") or step.description

			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 08 Debug: Step " .. i .. ": " .. StepsText[i], 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 09 Debug: Coordinates " .. i .. ": " .. CoordsText[i], 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 10 Debug: MapID " .. i .. ": " .. tostring(MapIDs[i]), 0.56, 0.93, 0.56)
				-- DEFAULT_CHAT_FRAME:AddMessage("QWU 11 Debug: Header " .. i .. ": " .. questHeader[i], 0.56, 0.93, 0.56)
			-- end
		end
	end
	--end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("QWU 12 Debug: Extracted quest ID from QuestIDText: " .. tostring(extractedQuestID), 0.56, 0.93, 0.56)
		end
	end

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local advanceQuestID = RQE.searchedQuestID or extractedQuestID or questID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		if questID == advanceQuestID then
			C_Timer.After(1, function()
				RQE:StartPeriodicChecks()
				--RQE:CheckAndAdvanceStep(advanceQuestID)
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
					DEFAULT_CHAT_FRAME:AddMessage("QWU 13 Debug: Checking and advancing step for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
				end
			end)
		end
	-- else
		-- C_Timer.After(2, function()
			-- RQE.ClickUnknownQuestButton()
		-- end)
	end

	C_Timer.After(0.5, function()
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end)

	-- -- Runs periodic checks for quest progress (aura/debuff/inventory item, etc) to see if it should advance steps
	-- if RQE.db.profile.autoClickWaypointButton then
		-- RQE:StartPeriodicChecks()
	-- end

	-- Calls for an update to the special Quest Item Buttons
	--RQE:UpdateQuestItemButtons()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_WATCH_UPDATE in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_WATCH_LIST_CHANGED event
function RQE.handleQuestWatchListChanged(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local added = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	RQE.UpdateInstanceInfoOkay = true -- Flag to allow UPDATE_INSTANCE_INFO to run next time it is called

	RQE:QuestType() -- Determines if UpdateRQEQuestFrame or UpdateRQEWorldQuestFrame gets updated

	if questID then
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)

		if isWorldQuest then
			UpdateRQEWorldQuestFrame()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QUEST_WATCH_LIST_CHANGED: Called UpdateRQEWorldQuestFrame (2206).", 1, 0.75, 0.79)
			end
		else
			UpdateRQEQuestFrame()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QUEST_WATCH_LIST_CHANGED: Called UpdateRQEQuestFrame (2209).", 1, 0.75, 0.79)
			end
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_WATCH_LIST_CHANGED event triggered for questID: " .. tostring(questID) .. ", added: " .. tostring(added), 0.4, 0.6, 1.0)
	end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or questID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
	local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}

	if questID then
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)

		if isWorldQuest then
			UpdateRQEWorldQuestFrame()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QUEST_WATCH_LIST_CHANGED: Called UpdateRQEWorldQuestFrame (2369).", 1, 0.75, 0.79)
			end
		else
			UpdateRQEQuestFrame()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QUEST_WATCH_LIST_CHANGED: Called UpdateRQEQuestFrame (2372).", 1, 0.75, 0.79)
			end
		end
	end

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		DEFAULT_CHAT_FRAME:AddMessage("QWLA 01 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		DEFAULT_CHAT_FRAME:AddMessage("QWLA 02 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- This ensures that any change in the watch list is reflected in your addon's UI
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)

	-- Debug messages for the above variables
	-- for i, step in ipairs(questInfo) do
		-- StepsText[i] = step.description
		-- CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
		-- MapIDs[i] = step.coordinates.mapID
		-- questHeader[i] = step.description:match("^(.-)\n") or step.description

		-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 03 Debug: Step " .. i .. ": " .. StepsText[i], 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 04 Debug: Coordinates " .. i .. ": " .. CoordsText[i], 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 05 Debug: MapID " .. i .. ": " .. tostring(MapIDs[i]), 0.56, 0.93, 0.56)
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 06 Debug: Header " .. i .. ": " .. questHeader[i], 0.56, 0.93, 0.56)
		-- end
	-- end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		-- if questInfo then
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 07 Debug: Quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
		-- else
			-- DEFAULT_CHAT_FRAME:AddMessage("QWLA 08 Debug: No quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
		-- end
	-- end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			RQE:StartPeriodicChecks()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QWLA 09 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
			end
		end)
	end

	-- -- Only process the event if the achievements frame is shown
	-- if RQE.AchievementsFrame:IsShown() then
		-- C_Timer.After(0.1, function()
			-- -- Ensure that the RQEQuestFrame updates when the quest is accepted (including World Quests)
			-- UpdateRQEQuestFrame()

			-- C_Timer.After(0.5, function()
				-- UpdateRQEWorldQuestFrame()
			-- end)
		-- end)
	-- end

	-- Calls for an update to the special Quest Item Buttons
	--RQE:UpdateQuestItemButtons()

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_WATCH_LIST_CHANGED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_TURNED_IN event
-- This event fires whenever the player turns in a quest, whether automatically with a Task-type quest (Bonus Objectives/World Quests), or by pressing the Complete button 
-- in a quest dialog window. 
function RQE.handleQuestTurnIn(...)
	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		-- startTime = debugprofilestop()  -- Start timer
	-- end

	local event = select(2, ...)
	local questID = select(3, ...)
	local xpReward = select(4, ...)
	local moneyReward = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn and RQE.db.profile.showArgPayloadInfo then
		local args = {...}  -- Capture all arguments into a table
		for i, arg in ipairs(args) do
			if type(arg) == "table" then
				print("Arg " .. i .. ": (table)")
				for k, v in pairs(arg) do
					print("  " .. tostring(k) .. ": " .. tostring(v))
				end
			else
				print("Arg " .. i .. ": " .. tostring(arg))
			end
		end
	end

	C_Timer.After(0.5, function()
		local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
		if not isSuperTracking then
			RQE:ClearSeparateFocusFrame()
		end
	end)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 01 Debug: QUEST_TURNED_IN event triggered for questID: " .. tostring(questID) .. ", XP Reward: " .. tostring(xpReward) .. ", Money Reward: " .. tostring(moneyReward) .. " copper", 1.0, 0.08, 0.58)  -- Bright Pink
	end

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	if not questID then	-- Ensure there's a valid questID from the event
		UpdateFrame()
		RQE:QuestType()
		return
	end

	local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 02 Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1.0, 0.08, 0.58)
	end

	-- Check if the removed quest is the currently super-tracked quest
	if questID == superTrackedQuestID then
		-- Clear user waypoint and reset TomTom if loaded
		C_Map.ClearUserWaypoint()
		
		-- Reset the "Clicked" WaypointButton to nil
		RQE.LastClickedIdentifier = nil

		-- Reset the Last Clicked WaypointButton to be "1"
		RQE.LastClickedButtonRef = RQE.WaypointButtons[1]
		
		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end
	end

	local displayedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		displayedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Determine questID based on various fallbacks
	questID = RQE.searchedQuestID or displayedQuestID or questID or superTrackedQuestID

	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 03 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 04 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	RQEMacro:ClearMacroContentByName("RQE Macro")

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 05 Debug: QuestID: " .. tostring(questID), 1.0, 0.08, 0.58)
		DEFAULT_CHAT_FRAME:AddMessage("QTI 06 Debug: DisplayedQuestID: " .. tostring(displayedQuestID), 1.0, 0.08, 0.58)
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			--RQE:CheckAndAdvanceStep(questID)
			RQE:StartPeriodicChecks()
		end)
	end

	-- -- Verify if the turned-in quest matches the currently displayed or super tracked quest	-- RQE:SHOULDCLEARFRAME() RUNS AT END OF UPDATEFRAME FUNCTION BELOW
	-- if superTrackedQuestID == questID or displayedQuestID == questID then
		-- -- Clear data and update frame after a brief delay to ensure quest log updates
		-- C_Timer.After(0.5, function()
			-- --RQE:ClearFrameData()  -- This method should clear the content from the RQEFrame
			-- RQE:ShouldClearFrame()
			-- -- Optionally, you might want to update the frame to show the next priority quest or clear visibility
		-- end)
	-- end

	-- Update RQEFrame
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_TURNED_IN in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling QUEST_FINISHED event
-- Fired whenever the quest frame changes (from Detail to Progress to Reward, etc.) or is closed
function RQE.handleQuestFinished()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		-- startTime = debugprofilestop()  -- Start timer
		DEFAULT_CHAT_FRAME:AddMessage("RQE.handleQuestFinished called.", 1, 0.75, 0.79)
	end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 01 Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
	end

	-- Determine questID based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 02 Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.75, 0.79)
		DEFAULT_CHAT_FRAME:AddMessage("QF 03 Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1, 0.75, 0.79)
		DEFAULT_CHAT_FRAME:AddMessage("QF 04 Debug: DisplayedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
	end

	-- Update RQEFrame and Refresh Quest Tracker
	UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	RQE:QuestType()

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	-- DEFAULT_CHAT_FRAME:AddMessage("QF 05 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)

	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 06 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			--RQE:CheckAndAdvanceStep(questID)
			--RQE:ClickSuperTrackedQuestButton()

			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
				DEFAULT_CHAT_FRAME:AddMessage("QF 07 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
			end
			RQE:StartPeriodicChecks()
		end)
	end

	-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		-- local duration = debugprofilestop() - startTime
		-- DEFAULT_CHAT_FRAME:AddMessage("Processed QUEST_FINISHED in: " .. duration .. "ms", 0.25, 0.75, 0.85)
	-- end
end


-- Handling PLAYER_LOGOUT event
-- Sent when the player logs out or the UI is reloaded, just before SavedVariables are saved. The event fires after PLAYER_LEAVING_WORLD
function RQE.handlePlayerLogout()
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
	-- Implement search logic here, likely the same as the click event
end)

-- Hooking the Objective Tracker's OnShow and OnHide events
ObjectiveTrackerFrame:HookScript("OnShow", HideObjectiveTracker)

-- Optionally, use OnUpdate for continuous checking
local hideObjectiveTrackerFrame = CreateFrame("Frame")
hideObjectiveTrackerFrame:SetScript("OnUpdate", HideObjectiveTracker)