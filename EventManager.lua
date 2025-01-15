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
RQEMacro = RQEMacro or {}


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


-- Function to Hide the RQE Tracker and display the Blizzard Objective Tracker for quests that require Blizzard's Tracker to complete or accept quest
function RQE:BlizzObjectiveTracker()
	RQE.ToggleBothFramesfromLDB()

	C_Timer.After(0.5, function()
		RQE:ToggleObjectiveTracker()
	end)

	RQE.ReEnableRQEFrames = true
end


-- Function to Hide the RQE Tracker and display the Blizzard Objective Tracker for quests that require Blizzard's Tracker to complete or accept quest
function RQE:TempBlizzObjectiveTracker()
	RQE.ToggleBothFramesfromLDB()

	C_Timer.After(0.5, function()
		RQE:ToggleObjectiveTracker()
	end)

	C_Timer.After(10, function()
		RQE.ToggleBothFramesfromLDB()
	end)
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
		if RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown() then
			RQE.RQEQuestFrame:Hide()
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
		if RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsShown() then
			RQE.RQEQuestFrame:Show()
		end
		-- Ensure the Blizzard Objective Tracker is hidden
		HideObjectiveTracker()
	end
end


-- Function to Toggle RQE Frames and Blizzard Objective Tracker
function RQE:ToggleFramesAndTracker()
	if InCombatLockdown() then
		-- If in combat, queue the toggle for after combat and return early
		RQE:RegisterEvent("PLAYER_REGEN_ENABLED", function()
			RQE:ToggleFramesAndTracker() -- Try to toggle again once combat ends
			RQE:UnregisterEvent("PLAYER_REGEN_ENABLED") -- Unregister the event to avoid repeated triggers
		end)
		return
	end

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
	"BAG_NEW_ITEMS_UPDATED",
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
	"MAIL_SUCCESS",
	"MERCHANT_UPDATE",
	"PLAYER_CONTROL_GAINED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LOGIN",
	"PLAYER_LOGOUT",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	--"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_STARTED_MOVING",
	"PLAYER_STOPPED_MOVING",
	"QUEST_ACCEPTED",
	"QUEST_AUTOCOMPLETE",
	"QUEST_COMPLETE",
	-- "QUEST_CURRENCY_LOOT_RECEIVED",
	"QUEST_FINISHED",
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
	"TRACKED_RECIPE_UPDATE",
	"UI_INFO_MESSAGE",
	"UNIT_AURA",
	"UNIT_ENTERING_VEHICLE",
	"UNIT_EXITING_VEHICLE",
	"UNIT_INVENTORY_CHANGED",
	"UNIT_QUEST_LOG_CHANGED",
	"UPDATE_INSTANCE_INFO",
	--"UPDATE_SHAPESHIFT_COOLDOWN",
	--"UPDATE_SHAPESHIFT_FORM",
	-- "UPDATE_UI_WIDGET",
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
	if (RQE.db.profile.debugLevel == "INFO") and (RQE.db.profile.showEventDebugInfo) then
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
		BAG_NEW_ITEMS_UPDATED = RQE.BagNewItemsAdded,
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
		MAIL_SUCCESS = RQE.handleMailSuccess,
		MERCHANT_UPDATE = RQE.handleMerchantUpdate,
		PLAYER_CONTROL_GAINED = RQE.handlePlayerControlGained,
		PLAYER_ENTERING_WORLD = RQE.handlePlayerEnterWorld,
		PLAYER_LOGIN = RQE.handlePlayerLogin,
		PLAYER_LOGOUT = RQE.handlePlayerLogout,
		PLAYER_MOUNT_DISPLAY_CHANGED = RQE.handlePlayerMountDisplayChanged,
		--PLAYER_REGEN_DISABLED = RQE.handlePlayerRegenDisabled,
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
		SUPER_TRACKING_CHANGED = RQE.handleSuperTracking,
		TASK_PROGRESS_UPDATE = RQE.handleQuestStatusUpdate,
		TRACKED_ACHIEVEMENT_UPDATE = RQE.handleTrackedAchieveUpdate,
		TRACKED_RECIPE_UPDATE = RQE.handleTrackedRecipeUpdate,
		UI_INFO_MESSAGE = RQE.handleUIInfoMessage,
		UNIT_AURA = RQE.handleUnitAura,
		UNIT_ENTERING_VEHICLE = RQE.handleUnitEnterVehicle,
		UNIT_EXITING_VEHICLE = RQE.handleZoneChange,
		UNIT_INVENTORY_CHANGED = RQE.handleUnitInventoryChange,
		UNIT_QUEST_LOG_CHANGED = RQE.handleUnitQuestLogChange,
		UPDATE_INSTANCE_INFO = RQE.handleInstanceInfoUpdate,
		UPDATE_SHAPESHIFT_COOLDOWN = RQE.handleUpdateShapeShiftCD,
		UPDATE_SHAPESHIFT_FORM = RQE.handleUpdateShapeShiftForm,
		-- UPDATE_UI_WIDGET = RQE.handleUpdateWidgetID,
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
		local args = {...}
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
	local isTracked = select(5, ...)

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
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when GOSSIP_CLOSED event fires acting as a fail safe for some "gossip' quests that may not trigger what is necessary to update this frame otherwise

	-- Clear the raid marker from the current target
	if UnitExists("target") then
		SetRaidTarget("target", 0)
	end

	RQE.SelectGossipOption(nil, nil)
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
			RQE.infoLog("Line 565: Current super tracked questID:", questID)
			local questData = RQE.getQuestData(questID)
			if questData then
				if RQE.LastClickedButtonRef == nil then return end
				local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1

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
		-- Tier Four Importance: ITEM_COUNT_CHANGED event
		if RQE.db.profile.autoClickWaypointButton then
			local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
			local questID = C_SuperTrack.GetSuperTrackedQuestID() or RQE.CurrentlySuperQuestID

			C_Timer.After(0.4, function()
				--if RQE.LastAcceptedQuest then
					--if RQE.LastAcceptedQuest == questID then
						RQE.StartPerioFromItemCountChanged = true
						RQE.ItemCountRanStartPeriodicChecks = true
						RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after ITEM_COUNT_CHANGED fires
						C_Timer.After(3, function()
							RQE.StartPerioFromItemCountChanged = false
						end)
					--end
				--end
			end)
		end
	end
end


-- Handles BAG_NEW_ITEMS_UPDATED event
function RQE.BagNewItemsAdded()
	if InCombatLockdown() then return end

	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("|cffffff00BAG_NEW_ITEMS_UPDATED triggered.|r")
	-- end

	-- C_Timer.After(1.5, function()
		-- RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after BAG_NEW_ITEMS_UPDATED fires
	-- end)

	-- Get the currently super-tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super-tracked quest ID found, skipping inventory checks.")
		end
		return
	end

	local questData = RQE.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data available for quest ID:", questID)
		end
		return
	end

	-- Determine the current stepIndex
	local stepIndex = RQE.AddonSetStepIndex or 1
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data available for quest ID:", questID, "stepIndex:", stepIndex)
		end
		return
	end

	-- Check if the current step relies on inventory checks
	local isInventoryCheck = false
	if stepData.funct and stepData.funct == "CheckDBInventory" then
		isInventoryCheck = true
	elseif stepData.checks then
		-- Also evaluate `checks` for CheckDBInventory
		for _, checkData in ipairs(stepData.checks) do
			if checkData.funct and checkData.funct == "CheckDBInventory" then
				isInventoryCheck = true
				break
			end
		end
	end

	-- If the current step is tied to inventory checks, re-run periodic checks
	if isInventoryCheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("BAG_NEW_ITEMS_UPDATED related to current stepIndex:", stepIndex, "for questID:", questID)
			RQE.BagNewItemsRunning = false
		end
		C_Timer.After(1.5, function()
			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~ Running RQE:StartPeriodicChecks() from BAG_NEW_ITEMS_UPDATED ~~")
			end
			RQE.BagNewItemsRunning = true
			RQE:StartPeriodicChecks()
		end)
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("BAG_NEW_ITEMS_UPDATED not related to current stepIndex:", stepIndex, "for questID:", questID)
			RQE.BagNewItemsRunning = false
		end
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
		--RQE.infoLog("Line 677: Current super tracked questID:", questID)	-- Potentially Fires a lot and visible only when Debug Logging is active
		local questData = RQE.getQuestData(questID)
		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			if stepData then
				local requiredItems = stepData.failedcheck or {}
				local neededAmounts = stepData.neededAmt or {}
				local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided
				if stepData.failedfunc and string.find(stepData.failedfunc, "CheckDBInventory") then
					local previousStepData = questData[stepIndex - 1]
					if previousStepData and previousStepData.funct and string.find(previousStepData.funct, "CheckDBZoneChange") then
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
	-- C_Timer.After(1.5, function()
		-- RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after BAG_UPDATE fires
	-- end)
end


-- Function that handles the MAIL_SUCCESS event
function RQE.handleMailSuccess(...)
	local event = select(2, ...)
	local itemID = select(3, ...)

	C_Timer.After(3, function()
		RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after MAIL_SUCCESS fires
	end)
end


-- Handles MERCHANT_UPDATE event:
-- Fires when an item is bought
function RQE.handleMerchantUpdate()
	if not RQE.db.profile.autoClickWaypointButton then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if questID then
		RQE.infoLog("Line 734: Current super tracked questID:", questID)
		local questData = RQE.getQuestData(questID)
		if questData then
			if RQE.LastClickedButtonRef == nil then return end
			local stepIndex = RQE.LastClickedButtonRef.stepIndex or 1
			local stepData = questData[stepIndex]

			-- Validate that stepData exists before continuing
			if not stepData then
				RQE.infoLog("No step data found for step index:", stepIndex, "in quest ID:", questID)
				return
			end

			local requiredItems = stepData.failedcheck or {}
			local neededAmounts = stepData.neededAmt or {}
			local failedIndex = stepData.failedIndex or stepIndex  -- Default to current step if no failedIndex is provided
			if stepData.failedfunc and string.find(stepData.failedfunc, "CheckDBInventory") then
				local previousStepData = questData[stepIndex - 1]
				if previousStepData and previousStepData.funct and string.find(previousStepData.funct, "CheckDBZoneChange") then
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
		C_Timer.After(1.3, function()
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after MERCHANT_UPDATE fires
		end)
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
		--RQE.infoLog("Line 806: Current super tracked questID:", questID)	-- Potentially Fires a lot and visible only when Debug Logging is active
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
			if stepData.failedfunc and string.find(stepData.failedfunc, "CheckDBInventory") then
				local previousStepData = questData[stepIndex - 1]
				if previousStepData and previousStepData.funct and string.find(previousStepData.funct, "CheckDBZoneChange") then
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
		-- C_Timer.After(1.7, function()
			-- RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after UNIT_INVENTORY_CHANGED fires
		-- end)
	end
end


-- Function that handles PLAYER_REGEN_DISABLED event
-- Fired whenever you enter combat, as normal regen rates are disabled during combat. This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim). 
function RQE.handlePlayerRegenDisabled()
	-- Bits of code for handling code during combat
end


-- Function that runs after leaving combat or PLAYER_REGEN_ENABLED
-- Fired after ending combat, as regen rates return to normal. Useful for determining when a player has left combat. 
-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
function RQE.handlePlayerRegenEnabled()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerRegenEnabled function.", 1, 0.65, 0.5)
	end

	if RQE.CheckNClickWButtonAfterCombat then
		C_Timer.After(1.5, function()
			RQE.CheckAndClickWButton()
		end)
		RQE.CheckNClickWButtonAfterCombat = false
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

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.65, 0.5)
		end
	else
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: autoClickWaypointButton is disabled.", 1, 0.65, 0.5)
		end
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerRegenEnabled then
			DEFAULT_CHAT_FRAME:AddMessage("PLAYER_REGEN_ENABLED Debug: Checked memory usage.", 0.46, 0.62, 1)
		end
	end

	-- if RQE.db.profile.autoClickWaypointButton then
		-- C_Timer.After(1.3, function()
			-- RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after PLAYER_REGEN_ENABLED fires
		-- end)
	-- end
end


-- Function that runs after leaving combat or PLAYER_MOUNT_DISPLAY_CHANGED
function RQE.handlePlayerMountDisplayChanged()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerMountDisplayChanged then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Entering handlePlayerRegenEnabled function.", 1, 0.65, 0.5)
	end

	RQE:UpdateCoordinates()

	-- Tier Five Importance: PLAYER_MOUNT_DISPLAY_CHANGED event
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			RQE.isCheckingMacroContents = true
			RQEMacro:CreateMacroForCurrentStep()		-- Checks for macro status if PLAYER_MOUNT_DISPLAY_CHANGED event fires
			C_Timer.After(3, function()
				RQE.isCheckingMacroContents = false
			end)
		end)
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerMountDisplayChanged then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.65, 0.5)
			end
		else
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerMountDisplayChanged then
				DEFAULT_CHAT_FRAME:AddMessage("Debug: No quest ID extracted from text.", 1, 0.65, 0.5)
			end
		end

		-- Determine questID based on various fallbacks
		local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerMountDisplayChanged then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.65, 0.5)
		end
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showPlayerMountDisplayChanged then
			DEFAULT_CHAT_FRAME:AddMessage("PLAYER_REGEN_ENABLED Debug: Checked memory usage.", 0.46, 0.62, 1)
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

	RQE:RestoreSuperTrackedQuestForCharacter()

	-- Add this line to update coordinates when player logs in
	RQE:UpdateCoordinates()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Fetch current MapID to have option of appearing with Frame
	RQE:UpdateMapIDDisplay()

	-- Make sure RQE.db is initialized
	if RQE.db == nil then
		RQE.db = RQE.db or {}
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

	RQE:SetupOverrideMacroBinding()  -- Set the key binding using the created MagicButton
	RQE:ReapplyMacroBinding()
	RQE:RemoveWorldQuestsIfOutOfSubzone()	-- Removes WQ that are auto watched that are not in the current player's area
	RQE.UntrackAutomaticWorldQuests()

	-- Check if autoClickWaypointButton is selected in the configuration
	C_Timer.After(2.5, function()
		if RQE.db.profile.autoClickWaypointButton then
			local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
			-- Click the "W" Button is autoclick is selected and no steps or questData exist
			--RQE.CheckAndClickWButton()
			-- C_Timer.After(2.5, function()
				-- RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after PLAYER_LOGIN fires
			-- end)
			RQE.ClickQuestLogIndexButton(currentSuperTrackedQuestID)
		end
	end)
end


-- Function to handle ADDON_LOADED
-- Fires after an AddOn has been loaded and is typically the first event to fire (running after all .lua files have been run and SavedVariables have loaded)
function RQE.handleAddonLoaded(self, event, addonName, containsBindings)
	-- Only proceed if RQE is the addon being loaded
	if addonName == "RQE" then
		RQE.infoLog("ADDON_LOADED for Rhodan's Quest Explorer")
	else
		return
	end

	RQE:RestoreFramePosition()

	-- Initialize Flags
	RQE.BagNewItemsRunning = false
	RQE.BlacklistUnderway = false
	RQE.CheckClickWButtonPossible = false
	RQE.CheckNClickWButtonAfterCombat = false
	RQE.ClearButtonPressed = false
	RQE.CreateMacroForCheckAndSetFinalStep = false
	RQE.CreateMacroForQuestLogIndexButton = false
	RQE.CreateMacroForSetInitialWaypoint = false
	RQE.CreateMacroForUpdateSeparateFocusFrame = false
	RQE.GreaterThanOneProgress = false
	RQE.hoveringOnRQEFrameAndButton = false
	RQE.isCheckingMacroContents = false
	RQE.OkayCheckBonusQuests = false
	RQE.QuestAddedForWatchListChanged = false
	RQE.QuestRemoved = false
	RQE.QuestWatchFiringNoUnitQuestLogUpdateNeeded = false
	RQE.QuestWatchUpdateFired = false
	RQE.ReEnableRQEFrames = false
	RQE.ShapeshiftUpdated = false
	RQE.StartPerioFromInstanceInfoUpdate = false
	RQE.StartPerioFromItemCountChanged = false
	RQE.StartPerioFromPlayerControlGained = false
	RQE.StartPerioFromPlayerEnteringWorld = false
	RQE.StartPerioFromQuestAccepted = false
	RQE.StartPerioFromQuestComplete = false
	RQE.StartPerioFromQuestTurnedIn = false
	RQE.StartPerioFromQuestWatchUpdate = false
	RQE.StartPerioFromSuperTrackChange = false
	RQE.StartPerioFromUnitQuestLogChanged = false
	RQE.StartPerioFromUQLC = false
	RQE.SuperTrackChangeRanStartPeriodicChecks = false
	RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded = false
	RQE.UIInfoUpdateFired = false
	RQE.WaypointButtonHover = false

	-- Making sure that the variables are cleared
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking then
		RQE.CurrentlySuperQuestID = nil
		RQE.isSuperTracking = false
		RQE.SuperTrackChangeToDifferentQuestOccurred = false
		RQE.SuperTrackUpdatingFrameWithStepTextInfo = false
	else
		RQE.CurrentlySuperQuestID = C_SuperTrack.GetSuperTrackedQuestID()
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
	if RQE.CurrentlySuperQuestID == nil then
		RQE:ClearWaypointButtonData()
		RQE:ClearSeparateFocusFrame()
	end
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

	RQE.updateScenarioUI()
end

-- Function to handle SCENARIO_UPDATE event
function RQE.handleScenarioUpdate(...)
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

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("SU Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)
	end

	if not C_Scenario.IsInScenario() then
		if not RQE.ScenarioChildFrame:IsVisible() then
			-- print("Not in scenario... Ending")
			return
		-- else
			-- print("In scenario... Continuing")
		end
	-- else
		-- print("In scenario... Continuing")
	end

	if RQE.db.profile.autoClickWaypointButton then
		RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after SCENARIO_UPDATE fires
	end

	--RQE.saveScenarioData(RQE, event, newStep)
	RQE.updateScenarioUI()

	RQE.SetScenarioChildFrameHeight()	-- Updates the height of the scenario child frame based on the number of criteria called
end


-- Function to handle SCENARIO_CRITERIA_UPDATE event
function RQE.handleScenarioCriteriaUpdate(...)
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

	RQE.scenarioCriteriaUpdate = true
	RQE.updateScenarioCriteriaUI()

	RQE.SetScenarioChildFrameHeight()	-- Updates the height of the scenario child frame based on the number of criteria called
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
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCompleted then
				DEFAULT_CHAT_FRAME:AddMessage("SC Debug: " .. tostring(event) .. " completed. Quest ID: " .. tostring(questID) .. ", XP: " .. tostring(xp) .. ", Money: " .. tostring(money), 0.9, 0.7, 0.9)
			end
		end

	elseif event == "SCENARIO_UPDATE" then
		local newStep = unpack(args)
		if newStep then  -- Check if the step information is present
			table.insert(RQE.ScenarioData, {type = event, newStep = newStep})
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioUpdate then
				DEFAULT_CHAT_FRAME:AddMessage("SU 01 Debug: " .. tostring(event) .. " triggered. New Step: " .. tostring(newStep), 0.9, 0.7, 0.9)  -- Light purple with a slightly greater reddish hue
			end
		end

	elseif event == "SCENARIO_CRITERIA_UPDATE" then
		local criteriaID = unpack(args)
		if criteriaID then
			table.insert(RQE.ScenarioData, {type = event, criteriaID = criteriaID})
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ScenarioCriteriaUpdate then
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

	RQE.StopScenarioTimer()
	RQE.StartScenarioTimer()
	RQE.CheckScenarioStartTime()	--RQE.StartScenarioTimer() --RQE.StartTimer()
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
end


-- Handles PLAYER_CONTROL_GAINED event
-- Fires after the PLAYER_CONTROL_LOST event, when control has been restored to the player (typically after landing from a taxi)
function RQE.handlePlayerControlGained()
	C_Timer.After(1.5, function()
		RQE:UpdateMapIDDisplay()
		RQE:UpdateCoordinates()
	end)

	RQE.canSortQuests = true
	SortQuestsByProximity()
	RQE:AutoClickQuestLogIndexWaypointButton()

	-- Tier Three Importance: PLAYER_CONTROL_GAINED event
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE.StartPerioFromPlayerControlGained = true
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after PLAYER_CONTROL_GAINED fires
			C_Timer.After(3, function()
				RQE.StartPerioFromPlayerControlGained = false
			end)
		end)
	end
end


-- Handling PLAYER_STARTED_MOVING Event
function RQE.handlePlayerStartedMoving()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerStartedMoving then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Player started moving.", 0.56, 0.93, 0.56)
	end

	-- Checks to see if showCoordinates is selected as true for an option before calling the applicable function
	if RQE.db.profile.showCoordinates then
		C_Timer.After(0.3, function()
			RQE:StartUpdatingCoordinates()
		end)
	end

	-- When player starts moving if not super tracking it will clear the RQEFrame of bad/outdated display info as long as player not in a scenario
	if C_Scenario.IsInScenario() then return end
	if not RQE.db.profile.autoClickWaypointButton then return end

 	if InCombatLockdown() then
		return
	end

	-- local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	-- if RQEFrame:IsShown() and not isSuperTracking then
		-- RQE.Buttons.ClearButtonPressed()
	-- end

	local isFlying = IsFlying("player")
	local isMounted = IsMounted()
	local onTaxi = UnitOnTaxi("player")

	if not IsFlying and not isMounted and not onTaxi then
		C_Timer.After(0.3, function()
			-- Get the macro index for 'RQE Macro'
			local macroIndex = GetMacroIndexByName("RQE Macro")

			-- If the macro exists, retrieve its content
			if macroIndex > 0 then
				local _, _, macroBody = GetMacroInfo(macroIndex)

				-- Check if the macro body has content
				if macroBody and macroBody == "" then
					RQE.isCheckingMacroContents = true
					RQEMacro:CreateMacroForCurrentStep()	-- Checks for macro status if PLAYER_STARTED_MOVING event fires
					C_Timer.After(0.2, function()
						RQE.isCheckingMacroContents = false
					end)
				end
			end
		end)
	end
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


-- Handling UPDATE_SHAPESHIFT_COOLDOWN event
function RQE.handleUpdateShapeShiftCD()
	-- local isBearFormSpellKnown = IsPlayerSpell(5487)
	-- if not isBearFormSpellKnown then
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("SpellID 5487 is not known by player")
		-- end
		-- return
	-- end

 	-- if InCombatLockdown() then
		-- return
	-- end

	-- if not RQE.ShapeshiftUpdated then return end
	-- local isInInstance, instanceType = IsInInstance()

	-- -- Adds a check if player is in party or raid instance, if so, will not allow macro check to run further
	-- if isInInstance and (instanceType == "party" or instanceType == "raid") then
		-- return
	-- end

	-- local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	-- if not RQE.isSuperTracking or not isSuperTracking then return end

	-- RQE.isCheckingMacroContents = true
	-- RQEMacro:CreateMacroForCurrentStep()	-- Checks for macro status if UPDATE_SHAPESHIFT_COOLDOWN event fires
	-- RQE.isCheckingMacroContents = false
end


-- Handling UPDATE_SHAPESHIFT_FORM event
-- Fired when the current form changes
function RQE.handleUpdateShapeShiftForm()
	local isBearFormSpellKnown = IsPlayerSpell(5487)
	if not isBearFormSpellKnown then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("SpellID 5487 is not known by player")
		end
		return
	end

 	if InCombatLockdown() then
		return
	end

	-- Get the macro index for 'RQE Macro'
	local macroIndex = GetMacroIndexByName("RQE Macro")

	-- If the macro exists, retrieve its content
	if macroIndex > 0 then
		local _, _, macroBody = GetMacroInfo(macroIndex)

		-- Check if the macro body has content
		if macroBody and macroBody ~= "" then
			RQE.ShapeshiftUpdated = false  -- Macro has content, so set flag to true
		else
			RQE.ShapeshiftUpdated = true -- Macro is empty, so set flag to false
		end
	else
		-- If macro doesn't exist, consider it empty
		RQE.ShapeshiftUpdated = true
	end

	-- Optional: Debugging messages to see the status
	if RQE.db.profile.debugLevel == "INFO+" then
		if RQE.ShapeshiftUpdated then
			print("RQE Macro has content. ShapeshiftUpdated is set to true.")
		else
			print("RQE Macro is empty or doesn't exist. ShapeshiftUpdated is set to false.")
		end
	end
end


-- -- Function to handle the UPDATE_UI_WIDGET event
-- function RQE.handleUpdateWidgetID(...)
	-- if RQE.db.profile.debugLevel ~= "INFO+" then return end

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
-- end


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
		RQEFrame:SetSize(420, 30)

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

	-- If no quest is currently super-tracked and enableNearestSuperTrack is activated, find and set the closest tracked quest
	C_Timer.After(3, function()
		local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
		if not RQE.isSuperTracking or not isSuperTracking then	--if RQE.db.profile.enableNearestSuperTrack then
			if not RQEFrame:IsShown() then return end
			if not isSuperTracking then
				local closestQuestID = RQE:GetClosestTrackedQuest()  -- Get the closest tracked quest
				if closestQuestID then
					C_SuperTrack.SetSuperTrackedQuestID(closestQuestID)
					RQE:SaveSuperTrackedQuestToCharacter()
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
						DEFAULT_CHAT_FRAME:AddMessage("PEW 01 Debug: Super-tracked quest set to closest quest ID: " .. tostring(closestQuestID), 1, 0.75, 0.79)
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
						DEFAULT_CHAT_FRAME:AddMessage("PEW 02 Debug: No closest quest found to super-track.", 1, 0.75, 0.79)
					end
				end
				RQE.TrackClosestQuest()
				if RQE.db.profile.autoClickWaypointButton then
					C_Timer.After(4, function()
						RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after PLAYER_ENTERING_WORLD fires
					end)
				end
			end

			C_Timer.After(1, function()
				UpdateFrame()
			end)

			-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when PLAYER_ENTERING_WORLD event fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
			if RQEFrame and not RQEFrame:IsMouseOver() then
				RQE.ScrollFrameToTop()
			end
			RQE.FocusScrollFrameToTop()
		else
			RQE:UpdateContentSize()
		end
	end)

	if isLogin then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 03 Debug: Loaded the UI from Login.", 0.93, 0.51, 0.93)
		end
		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	elseif isReload then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 04 Debug: Loaded the UI after Reload.", 0.93, 0.51, 0.93)
		end

		RQE.RequestAndCacheQuestLines()
		RQE:ClickSuperTrackedQuestButton()
	else
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 05 Debug: Zoned between map instances.", 0.93, 0.51, 0.93)
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
		DEFAULT_CHAT_FRAME:AddMessage("PEW 06 Debug: Entering handlePlayerEnterWorld function.", 0.93, 0.51, 0.93)
	end

	C_Timer.After(1, function()  -- Delay of 1 second
		wipe(RQE.savedWorldQuestWatches)
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 07 Debug: Cleared saved World Quest watches.", 0.93, 0.51, 0.93)
		end
	end)

	local mapID = C_Map.GetBestMapForUnit("player")
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 08 Debug: Current map ID: " .. tostring(mapID), 0.93, 0.51, 0.93)
	end

	-- RQE.Timer_CheckTimers(GetWorldElapsedTimers())	-- Fires needlessly as the data is nil
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 09 Debug: Checked timers.", 0.93, 0.51, 0.93)
	end

	if isReload or isLogin then
		if C_Scenario.IsInScenario() then
			RQE.ScenarioChildFrame:Show()
			RQE.SetScenarioChildFrameHeight()	-- Updates the height of the scenario child frame based on the number of criteria called
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
				DEFAULT_CHAT_FRAME:AddMessage("PEW 10 Debug: In a scenario, showing ScenarioChildFrame.", 0.93, 0.51, 0.93)
			end
		else
			RQE.ScenarioChildFrame:Hide()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
				DEFAULT_CHAT_FRAME:AddMessage("PEW 11 Debug: Not in a scenario, hiding ScenarioChildFrame.", 0.93, 0.51, 0.93)
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
				-- Tier Three Importance: PLAYER_ENTERING_WORLD event
				C_Timer.After(1, function()
					RQE.StartPerioFromPlayerEnteringWorld = true
					RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after PLAYER_ENTERING_WORLD fires
					C_Timer.After(3, function()
						RQE.StartPerioFromPlayerEnteringWorld = false
					end)
				end)
			end

			UpdateFrame()
		end

		-- Checks to see if in scenario and if no, will reset the scenario timer
		if not C_Scenario.IsInScenario() then
			C_Timer.After(0.7, function()
				RQE.StopScenarioTimer()
			end)
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
		DEFAULT_CHAT_FRAME:AddMessage("PEW 12 Debug: isInScenario status updated.", 0.93, 0.51, 0.93)
	end

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 13 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
		DEFAULT_CHAT_FRAME:AddMessage("PEW 14 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.PlayerEnteringWorld then
			DEFAULT_CHAT_FRAME:AddMessage("PEW 15 Debug: Checked memory usage.", 0.93, 0.51, 0.93)
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

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 1.0, 0.84, 0)
		end
	end

	RQE.OkayCheckBonusQuests = true

	C_Timer.After(1.5, function()
		RQE:UpdateContentSize()
	end)

	RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded = true

	-- Making sure that the variables are cleared
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking then
		RQE.currentSuperTrackedQuestID = nil
	else
		RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
	end

	if RQE.currentSuperTrackedQuestID == nil then
		RQE:ClearWaypointButtonData()
	else
		RQE.SaveSuperTrackData()
	end

	-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when SUPER_TRACKING_CHANGED event fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
	if RQEFrame and not RQEFrame:IsMouseOver() then
		RQE.ScrollFrameToTop()
	end
	RQE.FocusScrollFrameToTop()

	-- Optimize by updating the separate frame only if needed
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when SUPER_TRACKING_CHANGED event fires
	RQE.FocusScrollFrameToTop()

	local extractedQuestID
	RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Extract questID from RQE's custom UI if available
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Check if the super-tracked quest ID has changed
	if RQE.currentSuperTrackedQuestID ~= RQE.previousSuperTrackedQuestID then
		RQE.CheckClickWButtonPossible = true
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
			print("Super-tracked quest changed from", tostring(RQE.previousSuperTrackedQuestID), "to", tostring(RQE.currentSuperTrackedQuestID))
		end

		RQE.SuperTrackChangeToDifferentQuestOccurred = true

		-- If autoClickWaypointButton is enabled, then clear the macro, create a new macro and click the appropriate waypoint button
		if RQE.db.profile.autoClickWaypointButton then

			-- Ensure that the quest ID is valid and that the necessary data is available
			C_Timer.After(0.2, function()
				-- Ensure that WaypointButtons and LastClickedButtonRef are valid before using them
				if RQE.WaypointButtons and RQE.WaypointButtons[RQE.AddonSetStepIndex] then
					if RQE.LastClickedButtonRef and RQE.LastClickedButtonRef.stepIndex and RQE.WaypointButtons[RQE.LastClickedButtonRef.stepIndex] then
						RQE.WaypointButtons[RQE.LastClickedButtonRef.stepIndex]:Click()
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("Error: Waypoint button or AddonSetStepIndex is nil during SUPER_TRACKING_CHANGED for quest ID:", RQE.currentSuperTrackedQuestID)
					end
				end
			end)
		end

		-- Reset relevant variables
		RQE.LastClickedIdentifier = nil
		RQE.CurrentStepIndex = 1
		RQE.AddonSetStepIndex = 1
		RQE.LastClickedButtonRef = nil

		-- Store the current quest ID for future reference
		RQE.previousSuperTrackedQuestID = RQE.currentSuperTrackedQuestID
	else
		RQE.CheckClickWButtonPossible = false
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
			print("Super-tracked quest is the same between", tostring(RQE.previousSuperTrackedQuestID), "and", tostring(RQE.currentSuperTrackedQuestID))
		end
	end

	-- If player is no longer super tracking, they will instead super-track the nearest quest. If there continues to be no quest super tracked it will clear the Separate Focus Frame
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if not RQE.ClearButtonPressed then
		if not isSuperTracking then
			if not RQE.isSuperTracking or not isSuperTracking then	--if RQE.db.profile.enableNearestSuperTrack then
				if not RQEFrame:IsShown() then return end
				local closestQuestID = RQE:GetClosestTrackedQuest()  -- Get the closest tracked quest
				if closestQuestID then
					C_SuperTrack.SetSuperTrackedQuestID(closestQuestID)
					RQE:SaveSuperTrackedQuestToCharacter()
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
						DEFAULT_CHAT_FRAME:AddMessage("SUPER_TRACKING_CHANGED Debug: Super-tracked quest set to closest quest ID: " .. tostring(closestQuestID), 1, 0.75, 0.79)
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
						DEFAULT_CHAT_FRAME:AddMessage("SUPER_TRACKING_CHANGED Debug: No closest quest found to super-track.", 1, 0.75, 0.79)
					end
				end
			end
			RQE.TrackClosestQuest()
		end
	elseif RQE.ClearButtonPressed then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showEventSuperTrackingChanged then
			print("Clear Button has been pressed, no changes made to Super Track")
		end
		RQE.ClearButtonPressed = false
	end

	C_Timer.After(0.3, function()
		if not isSuperTracking then
			RQE:ClearSeparateFocusFrame()
		end
	end)

	-- Tier Two Importance: SUPER_TRACKING_CHANGED event
	if RQE.db.profile.autoClickWaypointButton then
		RQE.StartPerioFromSuperTrackChange = true
		RQE.SuperTrackChangeRanStartPeriodicChecks = true
		if RQE.LastAcceptedQuest == RQE.currentSuperTrackedQuestID then
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after SUPER_TRACKING_CHANGED fires
		end
		C_Timer.After(3, function()
			RQE.StartPerioFromSuperTrackChange = false
		end)
	end

	-- Early return if manual super tracking wasn't performed
	if not RQE.ManualSuperTrack then
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

	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	local mapID = C_Map.GetBestMapForUnit("player")

	-- Runs check to make sure still super tracking as this doesn't need to run if SUPER_TRACKING_CHANGED fires as it goes from a supertracked quest to nil
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if isSuperTracking then
		if questID then
			local questName
			questName = C_QuestLog.GetTitleForQuestID(questID)
			local questLink = GetQuestLink(questID)  -- Generate the quest link

			RQE.debugLog("Quest Name and Quest Link: ", questName, questLink)

			-- Attempt to fetch quest info from RQEDatabase, use fallback if not present
			local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown Quest"
			local questInfo = RQE.getQuestData(questID) or { questID = questID, name = questName }
			if questInfo then
				local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

				if StepsText and CoordsText and MapIDs then
					RQE.SuperTrackUpdatingFrameWithStepTextInfo = true
					UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
				end
			end
		else
			RQE.debugLog("questID is nil in SUPER_TRACKING_CHANGED event.")
		end

		-- Handles width adjustment of RQEFrame if Super Track Change occurred following actual change from one quest to another or from nil to a quest
		if RQE.SuperTrackChangeToDifferentQuestOccurred then
			AdjustRQEFrameWidths()
		end
	end

	-- Simulate clicking the RWButton
	if RQE.RWButton and RQE.RWButton:GetScript("OnClick") then
		RQE.RWButton:GetScript("OnClick")()
	end

	-- Checks to make sure if UpdateFrame occurred as a result of more information in the code above with StepsText, CoordsText and MapIDs. If so, this doesn't need to also run
	if not RQE.SuperTrackUpdatingFrameWithStepTextInfo then
		C_Timer.After(0.5, function()
			UpdateFrame()
		end)
	end

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

	RQE.OkayCheckBonusQuests = false
	RQE.LastSuperTrackedQuestID = questID
end


-- Handling QUEST_ACCEPTED Event
-- Fires whenever the player accepts a quest
function RQE.handleQuestAccepted(...)
	local event = select(2, ...)
	local questID = select(3, ...)

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	RQE.QuestStepsBlocked(questID)	-- Function call that checks to see if quest is in the DB already, but nothing is printed unless debug mode is set to 'Info'
	RQE.QuestAcceptedToSuperTrackOkay = true
	RQE.SetInitialFromAccept = true

	-- -- Check if the quest is a bonus objective
	-- if questID and C_QuestInfoSystem.GetQuestClassification(questID) == 8 then  -- 8 = Bonus Quest
		-- UpdateRQEBonusQuestFrame(questID)
	-- end

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

	C_Timer.After(1, function()
		UpdateRQEQuestFrame()	-- Fail safe to run function to check for new WQ/Bonus Quests when event fires to accept a quest
	end)

	-- Clear the raid marker from the current target
	if UnitExists("target") then
		SetRaidTarget("target", 0)
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 01 Debug: QUEST_ACCEPTED event triggered for questID: " .. tostring(questID), 0.46, 0.62, 1)
	end

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	if questID then
		RQE.LastAcceptedQuest = questID
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
		local isTaskQuest = C_QuestLog.IsQuestTask(questID)
		local isMetaQuest = C_QuestLog.IsMetaQuest(questID)
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
		-- elseif isTaskQuest then
			-- local isTaskQuest = C_QuestLog.IsQuestTask(questID)
			-- C_QuestLog.AddQuestWatch(questID)
		else
			C_QuestLog.AddQuestWatch(questID)	-- Designed to be called in the event that the quest accepted is something like a meta quest
		end

		-- Reapply the manual super-tracked quest ID if it's set and different from the current one
		if RQE.ManualSuperTrack then
			local superTrackIDToApply = RQE.ManualSuperTrackedQuestID
			if superTrackIDToApply and superTrackIDToApply ~= C_SuperTrack.GetSuperTrackedQuestID() then
				C_SuperTrack.SetSuperTrackedQuestID(superTrackIDToApply)
				RQE:SaveSuperTrackedQuestToCharacter()
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

	RQE.CheckClickWButtonPossible = true

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

	-- Only runs an update of the RQEFrame if the QUEST_ACCEPTED questID matches the quest that is currently supertracked
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if isSuperTracking then
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if questID == superTrackedQuestID then
			C_Timer.After(1, function()  -- Delay of 1 second
				UpdateFrame()
			end)
			RQE.SetInitialWaypointToOne()
			RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when QUEST_ACCEPTED event fires
		end
		RQE:UpdateRQEFrameVisibility()
	end

	-- Tier Four Importance: QUEST_ACCEPTED event
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE.StartPerioFromQuestAccepted = true
			if not RQE.StartPerioFromUQLC then
				if not RQE.SuperTrackChangeRanStartPeriodicChecks then
					local currentSuperQuestID = C_SuperTrack.GetSuperTrackedQuestID()
					if RQE.LastAcceptedQuest == currentSuperQuestID then
						RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after QUEST_ACCEPTED fires
					end
					C_Timer.After(3, function()
						RQE.StartPerioFromQuestAccepted = false
					end)
				end
				RQE.SuperTrackChangeRanStartPeriodicChecks = false
			end
			RQE.StartPerioFromUQLC = false
		end)
	end

	-- Visibility Update Check for RQEFrame & RQEQuestFrame
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 12 Debug: UpdateRQEFrameVisibility.", 0.46, 0.62, 1)
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
		DEFAULT_CHAT_FRAME:AddMessage("QA 13 Debug: UpdateRQEQuestFrameVisibility.", 0.46, 0.62, 1)
	end

	UpdateRQEQuestFrame()
	RQE:UpdateRQEQuestFrameVisibility()

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAccepted then
			DEFAULT_CHAT_FRAME:AddMessage("QA 14 Debug: Checked memory usage.", 0.46, 0.62, 1)
		end
	end
end


-- Handles UNIT_ENTERING_VEHICLE vent
function RQE.handleUnitEnterVehicle(...)
	local event = select(2, ...)
	local unitTarget = select(3, ...)
	local showVehicleFrame = select(4, ...)
	local isControlSeat = select(5, ...)
	local vehicleUIIndicatorID = select(6, ...)
	local vehicleGUID = select(7, ...)
	local mayChooseExit = select(8, ...)
	local hasPitch = select(9, ...)

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

	-- Flag to make sure that it is only handling for circumstances when the player goes into vehicle/multi-person mount
	if unitTarget ~= "player" then
		return
	end

	-- Performs check of step and macro
	if RQE.db.profile.autoClickWaypointButton then
		RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after UNIT_ENTERING_VEHICLE fires
	end
end


-- Handling of UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS
-- Fired as a unit is about to exit a vehicle, as compared to UNIT_EXITED_VEHICLE which happens afterward
-- Fires when the player enters an outdoors/indoors subzone
function RQE.handleZoneChange(...)
	local event = select(2, ...)

	if C_Scenario.IsInScenario() then
		RQE.updateScenarioUI()
	end

	-- RQE:UpdateMapIDDisplay()
	-- RQE:UpdateCoordinates()
	-- RQE:RemoveWorldQuestsIfOutOfSubzone()	-- Removes WQ that are auto watched that are not in the current player's area
	-- RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when UNIT_EXITING_VEHICLE, ZONE_CHANGED and ZONE_CHANGED_INDOORS events fire

	C_Timer.After(0.5, function()
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then  -- Check if QuestIDText exists and has text
			local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			if not extractedQuestID or extractedQuestID == 0 then
				RQEMacro:ClearMacroContentByName("RQE Macro")
				RQE:ClearSeparateFocusFrame()
			end
		-- else
			-- -- If QuestIDText is nil or has no text, ensure the macro and frame are cleared
			-- RQEMacro:ClearMacroContentByName("RQE Macro")
			-- RQE:ClearSeparateFocusFrame()
		end
	end)

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

	if RQE.PlayerMountStatus == "None" or RQE.PlayerMountStatus == "Mounted" then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: " .. tostring(event) .. " triggered. SubZone Text: " .. tostring(GetSubZoneText()), 0, 1, 1)  -- Cyan
		end

		-- Get the current map ID
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
			C_Timer.After(1.0, function()  -- Delay of 1 second
				local mapID = C_Map.GetBestMapForUnit("player")
				DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID), 0, 1, 1)  -- Cyan
			end)
		end
	-- else
		-- C_Timer.After(0.5, function()
			-- local extractedQuestID
			-- if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				-- extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			-- end

			-- -- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
			-- local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
			-- local questInfo = RQE.getQuestData(questID)
			-- local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

			-- UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		-- end)
	end

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		if RQE.PlayerMountStatus ~= "Flying" and not InCombatLockdown() then
		-- if not IsFlying("player") or not InCombatLockdown() then
			RQE.debugLog("Player not flying or dragonriding")
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				RQE:CheckMemoryUsage()
				DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 0, 1, 1)
			end
		else
			RQE.debugLog("Player is flying or dragonriding")
		end
	end

	-- Get the currently super-tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super-tracked quest ID found, skipping zone checks.")
		end
		return
	end

	-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when UNIT_EXITING_VEHICLE, ZONE_CHANGED or ZONE_CHANGED_INDOORS events fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
	if RQEFrame and not RQEFrame:IsMouseOver() then
		RQE.ScrollFrameToTop()
	end
	RQE.FocusScrollFrameToTop()

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	RQE.canSortQuests = true

	-- -- Check if autoClickWaypointButton is selected in the configuration
	-- if RQE.db.profile.autoClickWaypointButton then
		-- -- Click the "W" Button is autoclick is selected and no steps or questData exist
		-- RQE.CheckAndClickWButton()
	-- end

	if event == "UNIT_EXITING_VEHICLE" then
		local unitTarget = select(3, ...)
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: UNIT_EXITING_VEHICLE triggered for " .. tostring(...) .. ".", 0, 1, 1)  -- Cyan
		end
	end

	-- Scrolls frame to top when changing to a new area
	RQE.QuestScrollFrameToTop()

	-- -- Clears World Quest that are Automatically Tracked when switching to a new area
	-- local isFlying = IsFlying("player")
	-- local isMounted = IsMounted()
	-- local onTaxi = UnitOnTaxi("player")

	local questData = RQE.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data available for quest ID:", questID)
		end
		return
	end

	-- Determine the current stepIndex
	local stepIndex = RQE.AddonSetStepIndex or 1
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data available for quest ID:", questID, "stepIndex:", stepIndex)
		end
		return
	end

	-- Check if the current step relies on CheckDBZoneChange
	local isZoneChangeCheck = false
	if stepData.funct and stepData.funct == "CheckDBZoneChange" then
		isZoneChangeCheck = true
	elseif stepData.checks then
		-- Evaluate `checks` for CheckDBZoneChange
		for _, checkData in ipairs(stepData.checks) do
			if checkData.funct and checkData.funct == "CheckDBZoneChange" then
				isZoneChangeCheck = true
				break
			end
		end
	end

	-- If the current step relies on CheckDBZoneChange, re-run periodic checks
	if isZoneChangeCheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ZONE_CHANGED_NEW_AREA related to current stepIndex:", stepIndex, "for questID:", questID)
		end
		C_Timer.After(1.3, function()
			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~ Running RQE:StartPeriodicChecks() from ZONE_CHANGED ~~")
			end
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after ZONE_CHANGED or ZONE_CHANGED_INDOORS fires
		end)
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ZONE_CHANGED_NEW_AREA not related to current stepIndex:", stepIndex, "for questID:", questID)
		end
	end

	if not IsFlying and not isMounted and not onTaxi then
		RQE.UntrackAutomaticWorldQuests()
	end
end


-- Handles the event ZONE_CHANGED_NEW_AREA
-- Fires when the player enters a new zone
function RQE.handleZoneNewAreaChange()
	RQE.OkayCheckBonusQuests = true

	RQE:UpdateMapIDDisplay()
	RQE:UpdateCoordinates()
	RQE:RemoveWorldQuestsIfOutOfSubzone()	-- Removes WQ that are auto watched that are not in the current player's area
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when ZONE_CHANGED_NEW_AREA event fires

	-- Get the currently super-tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super-tracked quest ID found, skipping zone checks.")
		end
		return
	end

	-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when ZONE_CHANGED_NEW_AREA event fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
	if RQEFrame and not RQEFrame:IsMouseOver() then
		RQE.ScrollFrameToTop()
	end
	RQE.FocusScrollFrameToTop()

	-- -- Checks to see if in scenario and if no, will reset the scenario timer
	-- if not C_Scenario.IsInScenario() then
		-- C_Timer.After(0.7, function()
			RQE.StopScenarioTimer()
			RQE.StartScenarioTimer()
			RQE.CheckScenarioStartTime()
		-- end)
	-- end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		local playerMapID = C_Map.GetBestMapForUnit("player")
		local questData = RQE.getQuestData(questID)

		-- Click the "W" Button is autoclick is selected and no steps or questData exist
		RQE.CheckAndClickWButton()

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

	--if RQE.PlayerMountStatus == "Flying" then
	-- if not UnitOnTaxi("player") and not RQE.isDragonRiding then
		C_Timer.After(1.5, function()

			-- Get the current map ID
			local mapID = C_Map.GetBestMapForUnit("player")
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
			end

			if RQE.db.profile.autoTrackZoneQuests then
				RQE.DisplayCurrentZoneQuests()
			end

			SortQuestsByProximity()

			AdjustRQEFrameWidths()
			AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())
		end)

	-- elseif RQE.PlayerMountStatus == "Dragonriding" then
	-- --elseif not UnitOnTaxi("player") and RQE.isDragonRiding then
		-- RQE.canSortQuests = true
		-- C_Timer.After(0.5, function()
			-- -- Get the current map ID
			-- local mapID = C_Map.GetBestMapForUnit("player")
			-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.ZoneChange then
				-- DEFAULT_CHAT_FRAME:AddMessage("|cff00FFFFDebug: Current Map ID: " .. tostring(mapID) .. " - " .. tostring(C_Map.GetMapInfo(mapID).name), 0, 1, 1)  -- Cyan
			-- end
			-- RQE:UpdateMapIDDisplay()
		-- end)
	-- end

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

	local questData = RQE.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data available for quest ID:", questID)
		end
		return
	end

	-- Determine the current stepIndex
	local stepIndex = RQE.AddonSetStepIndex or 1
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data available for quest ID:", questID, "stepIndex:", stepIndex)
		end
		return
	end

	-- Check if the current step relies on CheckDBZoneChange
	local isZoneChangeCheck = false
	if stepData.funct and stepData.funct == "CheckDBZoneChange" then
		isZoneChangeCheck = true
	elseif stepData.checks then
		-- Evaluate `checks` for CheckDBZoneChange
		for _, checkData in ipairs(stepData.checks) do
			if checkData.funct and checkData.funct == "CheckDBZoneChange" then
				isZoneChangeCheck = true
				break
			end
		end
	end

	-- If the current step relies on CheckDBZoneChange, re-run periodic checks
	if isZoneChangeCheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ZONE_CHANGED_NEW_AREA related to current stepIndex:", stepIndex, "for questID:", questID)
		end
		C_Timer.After(0.8, function()
			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~ Running RQE:StartPeriodicChecks() from ZONE_CHANGED_NEW_AREA ~~")
			end
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after ZONE_CHANGED_NEW_AREA fires
		end)
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("ZONE_CHANGED_NEW_AREA not related to current stepIndex:", stepIndex, "for questID:", questID)
		end
	end

	-- Clears World Quest that are Automatically Tracked when switching to a new area
	RQE.UntrackAutomaticWorldQuests()
end


-- Handles TRACKED_RECIPE_UPDATE event
function RQE.handleTrackedRecipeUpdate(...)
	local event = select(2, ...)
	local recipeID = select(3, ...)
	local tracked = select(4, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
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

	if tracked then
		-- Recipe is being tracked, update the recipe frame
		RQE:CreateRecipeTrackingFrame()
		RQE:UpdateRecipeTrackingFrame(recipeID)
	else
		-- Recipe is untracked, clear the frame
		if RQE.recipeTrackingFrame then
			RQE.recipeTrackingFrame:Hide()
		end
	end
end


-- Handles UI_INFO_MESSAGE event
function RQE.handleUIInfoMessage(...)
	local event = select(2, ...)
	local messageType = select(3, ...)
	local message = select(4, ...)

	if not RQE.BlacklistUnderway then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	-- -- Check if the message is Exploration objective complete (messageType 308)
	-- if messageType == 308 then
		-- if RQE.db.profile.autoClickWaypointButton then
			-- C_Timer.After(1.5, function()
				-- RQE.UIInfoUpdateFired = true
				-- RQE:StartPeriodicChecks()
				-- C_Timer.After(0.2, function()
					-- RQE.UIInfoUpdateFired = false
				-- end)
				-- -- RQE.ClickQuestLogIndexButton(questID)
			-- end)
		-- end
	-- end

	if messageType == 311 or messageType == 312 then
		if RQE.BagNewItemsRunning then
			C_Timer.After(0.1, function()
				RQE:StartPeriodicChecks()
				RQE.BagNewItemsRunning = false
			end)
		end
	end

	-- Check if the message is Travel to a specific location such as for exploration objective (messageType 308)
	if messageType == 309 then
	--if messageType == 309 and message == "Objective Complete." then
		RQE.BlacklistUnderway = false
		RQE.Buttons.ClearButtonPressed()
		C_Timer.After(2.5, function()
			C_SuperTrack.SetSuperTrackedQuestID(RQE.BlackListedQuestID)
			RQE:SaveSuperTrackedQuestToCharacter()
			C_Timer.After(1.5, function()
				if RQE.db.profile.autoClickWaypointButton then
					RQE.UIInfoUpdateFired = true
					RQE:StartPeriodicChecks()
					C_Timer.After(0.2, function()
						RQE.UIInfoUpdateFired = false
					end)
					-- RQE.ClickQuestLogIndexButton(questID)
				end
				UpdateFrame()
			end)
		end)
	end

	-- -- Check if the message is Monster Kill (messageType 310)
	-- if messageType == 310 then
		-- if RQE.db.profile.autoClickWaypointButton then
			-- C_Timer.After(1.5, function()
				-- RQE.UIInfoUpdateFired = true
				-- RQE:StartPeriodicChecks()
				-- C_Timer.After(0.2, function()
					-- RQE.UIInfoUpdateFired = false
				-- end)
				-- -- RQE.ClickQuestLogIndexButton(questID)
			-- end)
		-- end
	-- end

	-- -- Check if the message is Collecting an object from ground or speaking to NPC (messageType 311)
	-- if messageType == 311 then
		-- if RQE.db.profile.autoClickWaypointButton then
			-- C_Timer.After(1.5, function()
				-- RQE.UIInfoUpdateFired = true
				-- RQE:StartPeriodicChecks()
				-- C_Timer.After(0.2, function()
					-- RQE.UIInfoUpdateFired = false
				-- end)
				-- -- RQE.ClickQuestLogIndexButton(questID)
			-- end)
		-- end
	-- end

	-- -- Check if the message is Collecting an object from ground or quest loot from mob (messageType 312)
	-- if messageType == 312 then
		-- if RQE.db.profile.autoClickWaypointButton then
			-- C_Timer.After(1.5, function()
				-- RQE.UIInfoUpdateFired = true
				-- RQE:StartPeriodicChecks()
				-- C_Timer.After(0.2, function()
					-- RQE.UIInfoUpdateFired = false
				-- end)
				-- -- RQE.ClickQuestLogIndexButton(questID)
			-- end)
		-- end
	-- end
end


-- Handles UNIT_AURA event
function RQE.handleUnitAura(...)
	local event = select(2, ...)
	local unitToken = select(3, ...)
	local spellName = select(4, ...)
	local filter = select(5, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
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

	if unitToken ~= "player" then  -- Only process changes for the player
		return
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("|cffffff00EventHandler triggered with event:|r", event)	-- Print the event name in yellow
	end

	-- Get the currently super-tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super tracked quest ID found, skipping aura checks.")
		end
		return
	end

	local questData = RQE.getQuestData(questID)
	if not questData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No quest data available for quest ID:", questID)
		end
		return
	end

	-- Determine the current stepIndex
	local stepIndex = RQE.AddonSetStepIndex or 1
	local stepData = questData[stepIndex]
	if not stepData then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No step data available for quest ID:", questID, "stepIndex:", stepIndex)
		end
		return
	end

	-- Check if the current step relies on buffs or debuffs
	local isBuffOrDebuffCheck = false
	if stepData.funct and (stepData.funct == "CheckDBBuff" or stepData.funct == "CheckDBDebuff") then
		isBuffOrDebuffCheck = true
	elseif stepData.checks then
		-- Also evaluate `checks` for the same
		for _, checkData in ipairs(stepData.checks) do
			if checkData.funct and (checkData.funct == "CheckDBBuff" or checkData.funct == "CheckDBDebuff") then
				isBuffOrDebuffCheck = true
				break
			end
		end
	end

	-- If the current step is tied to buff or debuff checks, re-run periodic checks
	if isBuffOrDebuffCheck then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("UNIT_AURA related to current stepIndex:", stepIndex, "for questID:", questID)
		end
		C_Timer.After(0.5, function()
			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~ Running RQE:StartPeriodicChecks() from UNIT_AURA ~~")
			end
			RQE:StartPeriodicChecks()
		end)
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("UNIT_AURA not related to current stepIndex:", stepIndex, "for questID:", questID)
		end
	end
end


-- Handles UNIT_QUEST_LOG_CHANGED event	-- POSSIBLY FIRED WHILE IN COMBAT CAUSING PASSTHRU ERROR
-- Fired whenever the quest log changes. (Frequently, but not as frequently as QUEST_LOG_UPDATE) 
function RQE.handleUnitQuestLogChange(...)
	local event = select(2, ...)
	local unitTarget = select(3, ...)

	-- Print Event-specific Args
	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.showArgPayloadInfo then
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

	-- Flag check to see if QUEST_WATCH_UPDATE has fired already and this is redundant
	if RQE.QuestWatchFiringNoUnitQuestLogUpdateNeeded then return end

	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	-- Only process the event if it's for the player
	if unitTarget == "player" and not UnitOnTaxi("player") then
		-- Ensure the event fires only for quests that are super-tracked
		if questID and RQE.db.profile.autoClickWaypointButton then
			C_Timer.After(1, function()
				RQE.CheckAndClickWButton()
				-- Flag check to see if SUPER_TRACKING_CHANGED has fired already and this is redundant
				if RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded then return end

				if not RQE.QuestRemoved then
					RQE.StartPerioFromUnitQuestLogChanged = true
					if RQE.LastAcceptedQuest ~= RQE.currentSuperTrackedQuestID then
						RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after SUPER_TRACKING_CHANGED fires
					end
					RQE.QuestRemoved = false

					-- Perform similar actions as in QUEST_WATCH_UPDATE to ensure waypoints and steps are updated
					RQE.currentSuperTrackedQuestID = questID
					local superTrackedQuestName = C_QuestLog.GetTitleForQuestID(RQE.currentSuperTrackedQuestID) or "Unknown Quest"

					-- Ensure that the quest ID is valid and that the necessary data is available
					if RQE.currentSuperTrackedQuestID then
						C_Timer.After(0.2, function()
							if RQE.WaypointButtons and RQE.WaypointButtons[RQE.AddonSetStepIndex] then
								RQE.WaypointButtons[RQE.AddonSetStepIndex]:Click()
							else
								if RQE.db.profile.debugLevel == "INFO+" then
									print("Error: Waypoint button or AddonSetStepIndex is nil during SUPER_TRACKING_CHANGED for quest ID:", RQE.currentSuperTrackedQuestID)
								end
							end
						end)

						if RQE.db.profile.debugLevel == "INFO+" then
							print("Updating waypoint for UNIT_QUEST_LOG_CHANGED questID: " .. tostring(RQE.currentSuperTrackedQuestID))
						end
					end

					-- Reset the flag after 3 seconds
					C_Timer.After(3, function()
						RQE.StartPerioFromUnitQuestLogChanged = false
					end)
				end
			end)
		end
	end

	-- Only process the event if the achievements frame is shown
	if RQE.AchievementsFrame:IsShown() then
		C_Timer.After(2, function()
			-- Flag check to see if SUPER_TRACKING_CHANGED has fired already and this is redundant
			if RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded then return end

			-- Ensure that the RQEQuestFrame updates when the quest is accepted (including World Quests)
			RQE:QuestType()
		end)
	end

	-- Flag check to see if SUPER_TRACKING_CHANGED has fired already and this is redundant
	if RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded then
		return
	else
		if not RQE.QuestRemoved then
			RQE.StartPerioFromUQLC = true
			if RQE.LastAcceptedQuest ~= RQE.currentSuperTrackedQuestID then
				RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after SUPER_TRACKING_CHANGED fires
			end
			RQE.QuestRemoved = false
		end
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
		return
	end

	if C_Scenario.IsInScenario() then
		if not RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Show()
		end
		RQE.InitializeScenarioFrame()
		RQE.UpdateScenarioFrame()
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

	RQE.scenarioCriteriaUpdate = false	-- Flag that denotes if the event that was run prior to this was SCENARIO_CRITERIA_UPDATE
end


-- Function that handles the Scenario UI Updates
function RQE.updateScenarioUI()
	-- If we're in combat, defer the update
	if InCombatLockdown() then
		RQE.deferredScenarioUpdate = true  -- Set a flag to update after combat
		return
	end

	-- RQE.SetScenarioChildFrameHeight()	-- Updates the height of the scenario child frame based on the number of criteria called (called separately but might localize here)

	-- Check to see if player in scenario, if not it will end
	if not C_Scenario.IsInScenario() then
		if RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()
		UpdateRQEQuestFrame()
		if RQE.db.profile.debugLevel == "INFO+" or (RQE.db.profile.ScenarioCriteriaUpdate or RQE.db.profile.ScenarioCompleted or RQE.db.profile.ScenarioUpdate) then
			DEFAULT_CHAT_FRAME:AddMessage("updateScenarioUI: Called UpdateRQEQuestFrame (1470).", 1, 0.75, 0.79)
		end
		return
	end

	-- Get the current scenario information
	local scenarioName, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete, completed = C_Scenario.GetInfo()

	-- Check if the scenario has been marked as completed
	if completed then
		-- If the scenario is complete, avoid further updates or handle differently
		if RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Hide()
		end

		if RQE.ScenarioChildFrame.timerFrame and RQE.ScenarioChildFrame.timerFrame:IsVisible() then
			--print("Hiding Timer that is visible")
			RQE.StopTimer()
		end

		RQE.UpdateCampaignFrameAnchor()
		return
	end

	if C_Scenario.IsInScenario() then
		if not RQE.ScenarioChildFrame:IsVisible() then
			RQE.ScenarioChildFrame:Show()
		end
		RQE.InitializeScenarioFrame()
		RQE.UpdateScenarioFrame()
		RQE.StartScenarioTimer()
		RQE.CheckScenarioStartTime()	--RQE.StartScenarioTimer() --RQE.StartTimer()
		RQE.QuestScrollFrameToTop()  -- Moves ScrollFrame of RQEQuestFrame to top
	else
		RQE.ScenarioChildFrame:Hide()
		RQE.StopTimer()
	end

	UpdateRQEQuestFrame()

	if RQE.db.profile.debugLevel == "INFO+" or (RQE.db.profile.ScenarioCriteriaUpdate or RQE.db.profile.ScenarioCompleted or RQE.db.profile.ScenarioUpdate) then
		DEFAULT_CHAT_FRAME:AddMessage("updateScenarioUI: Called UpdateRQEQuestFrame (1521).", 1, 0.75, 0.79)
	end

	RQE.UpdateCampaignFrameAnchor()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()
	RQE:UpdateRQEQuestFrameVisibility()
end


-- Handles UPDATE_INSTANCE_INFO Event
-- Fired when data from RequestRaidInfo is available and also when player uses portals
function RQE.handleInstanceInfoUpdate()
	C_Timer.After(1.5, function()
		RQE.CheckQuestInfoExists()	-- Clears the RQEFrame if nothing is being supertracked (as the focus frame sometimes contains data when it shouldn't)
	end)

	RQE:UpdateMapIDDisplay()
	RQE:UpdateCoordinates()

	if not RQE.UpdateInstanceInfoOkay then
		return
	end

	-- Updates the achievement list for criteria of tracked achievements
	RQE.UpdateTrackedAchievementList()

	-- Tier Three Importance: UPDATE_INSTANCE_INFO event
	if RQE.db.profile.autoClickWaypointButton then
		RQE.StartPerioFromInstanceInfoUpdate = true
		RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after UPDATE_INSTANCE_INFO fires
		C_Timer.After(3, function()
			RQE.StartPerioFromInstanceInfoUpdate = false
		end)
	end

	-- Update RQEFrame and Refresh Quest Tracker
	UpdateFrame()
	RQE:QuestType()

	RQE.UpdateInstanceInfoOkay = false
end


-- Handles QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE events
-- Fires when the quest log updates, or whenever Quest POIs change (For example after accepting an quest)
function RQE.handleQuestStatusUpdate()
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when QUEST_LOG_UPDATE, QUEST_POI_UPDATE or TASK_PROGRESS_UPDATE events fire

	-- Resets the flag that prevents UNIT_QUEST_LOG_CHANGED from firing immediately following QUEST_WATCH_UPDATE
	if RQE.QuestWatchFiringNoUnitQuestLogUpdateNeeded then
		RQE.QuestWatchFiringNoUnitQuestLogUpdateNeeded = false
	end

	-- Resets the flag that prevents UNIT_QUEST_LOG_CHANGED from firing immediately following SUPER_TRACKING_CHANGED
	if RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded then
		RQE.SuperTrackingHandlingUnitQuestLogUpdateNotNeeded = false
	end

	-- Restore Automatic World Quests that have been saved to their table
	if RQE.ReadyToRestoreAutoWorldQuests then
		RQE:RestoreSavedAutomaticWorldQuestWatches()
		RQE.ReadyToRestoreAutoWorldQuests = false
	end

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest Status Update Triggered. SuperTracking: " .. tostring(isSuperTracking) .. ", Super Tracked QuestID: " .. tostring(RQE.currentSuperTrackedQuestID), 0, 1, 0)  -- Bright Green
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
		C_Timer.After(0.7, function()
			if questID then
				if RQE.ManualSuperTrack and questID ~= RQE.ManualSuperTrackedQuestID then
					C_SuperTrack.SetSuperTrackedQuestID(RQE.ManualSuperTrackedQuestID)
					RQE:SaveSuperTrackedQuestToCharacter()
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
			end

			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)
	end

	UpdateRQEQuestFrame()
	UpdateRQEWorldQuestFrame()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestStatusUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("handleQuestStatusUpdate: Called UpdateRQEQuestFrame (1686).", 1, 0.75, 0.79)
	end
end


-- Handling QUEST_CURRENCY_LOOT_RECEIVED event
function RQE.handleQuestCurrencyLootReceived(...)

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

	RQE.QuestScrollFrameToTop()
end


-- Handling QUEST_LOG_CRITERIA_UPDATE event
function RQE.handleQuestLogCriteriaUpdate(...)
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

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if isSuperTracking or RQE.isSuperTracking then
		local superQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if superQuestID == questID then
			if numFulfilled ~= 0 or 1 then
				print("RQE.GreaterThanOneProgress is true")
				RQE.GreaterThanOneProgress = true
			else
				print("RQE.GreaterThanOneProgress is false")
				RQE.GreaterThanOneProgress = false
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
end


-- Handling QUEST_LOOT_RECEIVED event
-- Fires when player receives loot from quest turn in (Runs once per quest loot received)
function RQE.handleQuestLootReceived(...)
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

	-- Saving event specific information before calling the status update function
	RQE.latestEventInfo = {
		eventType = "QUEST_LOOT_RECEIVED",
		questID = questID,
		itemLink = itemLink,
		quantity = quantity
	}

	--RQE.handleQuestStatusUpdate()
end


-- Handling QUESTLINE_UPDATE event
function RQE.handleQuestlineUpdate(...)
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
end


-- Handling QUEST_COMPLETE event
-- Fired after the player hits the "Continue" button in the quest-information page, before the "Complete Quest" button. In other words, it fires when you are given the option to complete a quest, but just before you actually complete the quest. 
function RQE.handleQuestComplete()
	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	if RQE.ReEnableRQEFrames then
		C_Timer.After(2.5, function()
			RQE.ToggleBothFramesfromLDB()
		end)
		RQE.ReEnableRQEFrames = false
	end

	local extractedQuestID

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for Extracted QuestID: " .. tostring(extractedQuestID), 0, 0.75, 0.75)
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process concluded for SuperTracked QuestID: " .. tostring(RQE.currentSuperTrackedQuestID), 0, 0.75, 0.75)
		end
	end

	-- Determine questID based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestComplete then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	end

	RQE.searchedQuestID = nil	-- THIS MIGHT NEED TO BE COMMENTED OUT IF THE SEARCHED QUEST GETS REMOVED ANYTIME A QUEST IS COMPLETED
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
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

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

	-- Tier Four Importance: QUEST_COMPLETE event
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE.StartPerioFromQuestComplete = true
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after QUEST_COMPLETE fires
			C_Timer.After(3, function()
				RQE.StartPerioFromQuestComplete = false
			end)
		end)
	end
end


-- Handling QUEST_AUTOCOMPLETE events
-- Fires when a quest that can be auto-completed is completed
function RQE.handleQuestAutoComplete(...)
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

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local questID = RQE.searchedQuestID or questID --or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestAutocomplete then
		DEFAULT_CHAT_FRAME:AddMessage("QAC 03 Debug: Quest completion process started for questID: " .. tostring(questID), 0, 0.75, 0.75)  -- Blue-green color
	end

	RQE.searchedQuestID = nil	-- THIS MIGHT NEED TO BE COMMENTED OUT IF THE SEARCHED QUEST GETS REMOVED ANYTIME A QUEST IS COMPLETED
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
	SortQuestsByProximity()

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
	end
end


-- Handling CLIENT_SCENE_OPENED event (saving of World Quests when event fires):
function RQE.HandleClientSceneOpened(...)
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
end


-- Handling CLIENT_SCENE_CLOSED event (restoring of World Quests when event fires):
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
function RQE.handleQuestRemoved(...)
	-- Extract questID and wasReplayQuest from the correct argument positions
	local event = select(2, ...)
	local questID = select(3, ...)
	local wasReplayQuest = select(4, ...)

	RQE:SaveAutomaticWorldQuestWatches()
	RQE.ReadyToRestoreAutoWorldQuests = true
	RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when QUEST_REMOVED event fires

	RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

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

	C_Timer.After(1, function()
		UpdateRQEQuestFrame()	-- Fail safe to run function to check for new WQ/Bonus Quests when event fires to remove quest
	end)

	if not RQE.currentSuperTrackedQuestID then
		RQE.currentSuperTrackedQuestID = RQE.LastSuperTrackedQuestID  -- Use the last known super-tracked questID if current is nil
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_REMOVED event triggered for questID: " .. tostring(questID) .. ", wasReplayQuest: " .. tostring(wasReplayQuest), 0.82, 0.70, 0.55) -- Light brown color
	end

	RQEFrame:ClearAllPoints()
	RQE.RQEQuestFrame:ClearAllPoints()
	RQE:QuestType()
	SortQuestsByProximity()

	AdjustRQEFrameWidths()
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())

	RQE:RemoveWorldQuestsIfOutOfSubzone()	-- Removes WQ that are auto watched that are not in the current player's area
	RQE:ShouldClearFrame()

	-- Check if the questID is valid and if it was being tracked automatically
	if questID and RQE.TrackedQuests[questID] == Enum.QuestWatchType.Automatic then

		-- Remove the quest from the tracking list
		local isWorldQuest = C_QuestLog.IsWorldQuest(questID)

		if isWorldQuest then
			C_QuestLog.RemoveWorldQuestWatch(questID)
		end

		-- Clear the saved state for this quest
		RQE.TrackedQuests[questID] = nil
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestRemoved  then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Removed automatic World Quest watch for questID: " .. tostring(questID), 0.82, 0.70, 0.55) -- Light brown color
		end
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
	RQE.QuestRemoved = true
end


-- Handling QUEST_WATCH_UPDATE event
-- Fires each time the objectives of the quest with the supplied questID update, i.e. whenever a partial objective has been accomplished: killing a mob, looting a quest item etc
-- UNIT_QUEST_LOG_CHANGED and QUEST_LOG_UPDATE both also seem to fire consistently – in that order – after each QUEST_WATCH_UPDATE.
function RQE.handleQuestWatchUpdate(...)
	local event = select(2, ...)
	local questID = select(3, ...)

	-- Store the questID for tracking
	RQE.LastQuestWatchQuestID = questID
	RQE.QuestWatchUpdateFired = true

	-- Update Display of Memory Usage of Addon
	if RQE.db and RQE.db.profile.displayRQEmemUsage then
		RQE:CheckMemoryUsage()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("Debug: Checked memory usage.", 1.0, 0.84, 0)
		end
	end

	-- Check if autoClickWaypointButton is selected in the configuration
	if RQE.db.profile.autoClickWaypointButton then
		-- Click the "W" Button is autoclick is selected and no steps or questData exist
		RQE.CheckAndClickWButton()
	end

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

	-- Checks to see if the quest and stepIndex are blacklisted from RQEFrame updates due to heavy load on the add-on and lag
	RQE:CheckSuperTrackedQuestAndStep()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("Received questID: " .. tostring(questID), 0.56, 0.93, 0.56) -- Light Green
	end

	if type(questID) ~= "number" then
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("QWU 01 Error: questID is not a number.", 0.56, 0.93, 0.56)
		end
		return
	end

	RQE.QuestWatchFiringNoUnitQuestLogUpdateNeeded = true

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		DEFAULT_CHAT_FRAME:AddMessage("QWU 02 Debug: QUEST_WATCH_UPDATE event triggered for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
	end

	-- Initialize variables
	-- RQE:UpdateSeparateFocusFrame()	-- Updates the Focus Frame within the RQE when QUEST_WATCH_UPDATE event fires	-- ADDED to RQE:StartPeriodicChecks()
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

	if isSuperTracking and RQE.currentSuperTrackedQuestID == questID then

		RQE.currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		local superTrackedQuestName = "Unknown Quest" -- Default if ID is nil or no title found

		if RQE.currentSuperTrackedQuestID then
			superTrackedQuestName = C_QuestLog.GetTitleForQuestID(RQE.currentSuperTrackedQuestID) or "Unknown Quest"
		end

		if RQE.currentSuperTrackedQuestID == questID then
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
				DEFAULT_CHAT_FRAME:AddMessage("Quest is already super tracked: " .. superTrackedQuestName, 0.56, 0.93, 0.56)
			end
		end

		if RQE.currentSuperTrackedQuestID then
			-- Ensure that RQE.WaypointButtons and the index are valid before attempting to click
			if RQE.WaypointButtons and RQE.AddonSetStepIndex and RQE.WaypointButtons[RQE.AddonSetStepIndex] then
				RQE.WaypointButtons[RQE.AddonSetStepIndex]:Click()
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Error: RQE.WaypointButtons or RQE.AddonSetStepIndex is nil or invalid.")
				end
			end
		end

	elseif not isSuperTracking then
		C_SuperTrack.SetSuperTrackedQuestID(questID) -- Supertracks quest with progress if nothing is being supertracked
		RQE:SaveSuperTrackedQuestToCharacter()

		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			local superTrackedQuestName = C_QuestLog.GetTitleForQuestID(RQE.currentSuperTrackedQuestID) or "Unknown Quest"
			DEFAULT_CHAT_FRAME:AddMessage("Now super tracking quest: " .. superTrackedQuestName, 0.56, 0.93, 0.56)
		end
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
		local superTrackedQuestName = C_QuestLog.GetTitleForQuestID(RQE.currentSuperTrackedQuestID) or "Unknown Quest"
		DEFAULT_CHAT_FRAME:AddMessage("QWU 03 Debug: Current super tracked quest ID/Name: " .. tostring(RQE.currentSuperTrackedQuestID) .. " / " .. tostring(superTrackedQuestName), 0.56, 0.93, 0.56)
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
	local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
	local isTaskQuest = C_QuestLog.IsQuestTask(questID) or C_QuestLog.IsThreatQuest(questID)

	if isWorldQuest then
		C_QuestLog.AddWorldQuestWatch(questID)
	elseif isTaskQuest then
		C_QuestLog.AddQuestWatch(questID)
	else
		C_QuestLog.AddQuestWatch(questID)
	end

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

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
			DEFAULT_CHAT_FRAME:AddMessage("QWU 12 Debug: Extracted quest ID from QuestIDText: " .. tostring(extractedQuestID), 0.56, 0.93, 0.56)
		end
	end

	-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
	local advanceQuestID = RQE.searchedQuestID or extractedQuestID or questID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(advanceQuestID)
	if questInfo then
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(advanceQuestID)

		-- Tier One Importance: QUEST_WATCH_UPDATE event
		if RQE.db.profile.autoClickWaypointButton then
			C_Timer.After(1, function()
				-- Click the "W" Button is autoclick is selected and no steps or questData exist
				RQE.CheckAndClickWButton()

				RQE.StartPerioFromQuestWatchUpdate = true
				RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after QUEST_WATCH_UPDATE fires

				-- Immediately reset flag after running StartPeriodicChecks
				RQE.StartPerioFromQuestWatchUpdate = false

				--RQE:CheckAndAdvanceStep(advanceQuestID)
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestWatchUpdate then
					DEFAULT_CHAT_FRAME:AddMessage("QWU 13 Debug: Checking and advancing step for questID: " .. tostring(questID), 0.56, 0.93, 0.56)
				end
			end)
		end

		C_Timer.After(0.5, function()
			if RQE.QuestWatchUpdateFired then
				RQE.QuestWatchUpdateFired = false	-- Reset the flag to false if it is currently marked as true
			end
			UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
		end)
	end
end


-- Handling QUEST_WATCH_LIST_CHANGED event
function RQE.handleQuestWatchListChanged(...)
	local event = select(2, ...)
	local questID = select(3, ...)
	local added = select(4, ...)

	if not questID then
		return
	end

	-- Checks to see if a quest was added or removed (true/false) in order to call this event
	if added == true then
		RQE.QuestAddedForWatchListChanged = true
	else
		RQE.QuestAddedForWatchListChanged = false
	end

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

	-- Local variables for the event
	local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	-- Check to see if actively doing a Dragonriding Race and if so will skip rest of this event function
	if RQE.HasDragonraceAura() then
		return
	end

	RQE.UpdateInstanceInfoOkay = true	-- Flag to allow UPDATE_INSTANCE_INFO to run next time it is called

	RQE:QuestType()	-- Determines if UpdateRQEQuestFrame or UpdateRQEWorldQuestFrame gets updated and useful for clearing frame

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

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
		DEFAULT_CHAT_FRAME:AddMessage("Debug: QUEST_WATCH_LIST_CHANGED event triggered for questID: " .. tostring(questID) .. ", added: " .. tostring(added), 0.4, 0.6, 1.0)
	end

	if isSuperTracking then
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if superTrackedQuestID == questID then
			-- Determine questID, questInfo, StepsText, CoordsText and MapIDs based on various fallbacks
			local questInfo = RQE.getQuestData(superTrackedQuestID)
			if questInfo then
				local StepsText, CoordsText, MapIDs, questHeader = {}, {}, {}, {}	-- Initialize variables StepsText, CoordsText, MapIds and questHeader
				local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)	-- Populates recently initialized variables

				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					DEFAULT_CHAT_FRAME:AddMessage("QWLC 01 Debug: Quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
				end
				UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
			else
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					DEFAULT_CHAT_FRAME:AddMessage("QWLC 02 Debug: No quest info found for questID: " .. tostring(questID), 0.4, 0.6, 1.0)
				end
			end

			AdjustRQEFrameWidths()

			-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
			RQE:UpdateRQEFrameVisibility()

			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QWLC 03 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
			end

			RQE:UpdateRQEQuestFrameVisibility()

			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
				DEFAULT_CHAT_FRAME:AddMessage("QWLC 04 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
			end

			-- -- Debug messages for the above variables
			-- for i, step in ipairs(questInfo) do
				-- StepsText[i] = step.description
				-- CoordsText[i] = string.format("%.1f, %.1f", step.coordinates.x, step.coordinates.y)
				-- MapIDs[i] = step.coordinates.mapID
				-- questHeader[i] = step.description:match("^(.-)\n") or step.description

				-- if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					-- DEFAULT_CHAT_FRAME:AddMessage("QWLC 05 Debug: Step " .. i .. ": " .. StepsText[i], 0.56, 0.93, 0.56)
					-- DEFAULT_CHAT_FRAME:AddMessage("QWLC 06 Debug: Coordinates " .. i .. ": " .. CoordsText[i], 0.56, 0.93, 0.56)
					-- DEFAULT_CHAT_FRAME:AddMessage("QWLC 07 Debug: MapID " .. i .. ": " .. tostring(MapIDs[i]), 0.56, 0.93, 0.56)
					-- DEFAULT_CHAT_FRAME:AddMessage("QWLC 08 Debug: Header " .. i .. ": " .. questHeader[i], 0.56, 0.93, 0.56)
				-- end
			-- end

			-- Check to advance to next step in quest
			if RQE.db.profile.autoClickWaypointButton then
				C_Timer.After(0.5, function()
					--RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after QUEST_WATCH_LIST_CHANGED fires
					if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
						DEFAULT_CHAT_FRAME:AddMessage("QWLC 09 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
					end
				end)
			end
		end
	end

	-- If no quest is currently super-tracked and enableNearestSuperTrack is activated, find and set the closest tracked quest
	if RQE.db.profile.enableNearestSuperTrack then
		if not RQE.isSuperTracking or not isSuperTracking then	--if not isSuperTracking then
			if not RQEFrame:IsShown() then return end
			local closestQuestID = RQE:GetClosestTrackedQuest()  -- Get the closest tracked quest
			if closestQuestID then
				C_SuperTrack.SetSuperTrackedQuestID(closestQuestID)
				RQE:SaveSuperTrackedQuestToCharacter()
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					DEFAULT_CHAT_FRAME:AddMessage("QF 01 Debug: Super-tracked quest set to closest quest ID: " .. tostring(closestQuestID), 1, 0.75, 0.79)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestListWatchListChanged then
					DEFAULT_CHAT_FRAME:AddMessage("QF 02 Debug: No closest quest found to super-track.", 1, 0.75, 0.79)
				end
			end
			RQE.TrackClosestQuest()
		end

		-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when QUEST_WATCH_LIST_CHANGED event fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
		if RQEFrame and not RQEFrame:IsMouseOver() then
			RQE.ScrollFrameToTop()
		end
		RQE.FocusScrollFrameToTop()
	end

	-- If nothing is still being supertracked, a quest will be super tracked if it is added to the RQEQuestFrame
	if RQE.QuestAddedForWatchListChanged and not (isSuperTracking and isWorldQuest) then
		C_SuperTrack.SetSuperTrackedQuestID(questID)	-- If still nothing is being supertracked the addon will opt to super track the quest that fired the event
		RQE:SaveSuperTrackedQuestToCharacter()
		UpdateFrame()
	end

	UpdateRQEQuestFrame()

	C_Timer.After(0.5, function()
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then  -- Check if QuestIDText exists and has text
			local extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			if not extractedQuestID or extractedQuestID == 0 then
				RQEMacro:ClearMacroContentByName("RQE Macro")
				RQE:ClearSeparateFocusFrame()
			end
		else
			-- If QuestIDText is nil or has no text, ensure the macro and frame are cleared
			RQEMacro:ClearMacroContentByName("RQE Macro")
			RQE:ClearSeparateFocusFrame()
		end
	end)

	-- Updates RQEQuestFrame widths when progress is made whether progress quest is super tracked or not
	AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())
end


-- Handling QUEST_TURNED_IN event
-- This event fires whenever the player turns in a quest, whether automatically with a Task-type quest (Bonus Objectives/World Quests), or by pressing the Complete button 
-- in a quest dialog window. 
function RQE.handleQuestTurnIn(...)
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
		if not RQE.previousSuperTrackedQuestID then
			RQE.previousSuperTrackedQuestID = nil
		end

		if not isSuperTracking or (questID == RQE.previousSuperTrackedQuestID) then
			RQE.Buttons.ClearButtonPressed()	-- Simulate pressing the "C" ClearButton
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

			RQE:ClearSeparateFocusFrame()
			UpdateFrame()

			-- Update the visibility or content of RQEFrame as needed
			RQE:UpdateRQEFrameVisibility()
		end
		RQE:QuestType()
	end)

	C_Timer.After(1.5, function()
		RQEMacro:ClearMacroContentByName("RQE Macro")
	end)

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 01 Debug: QUEST_TURNED_IN event triggered for questID: " .. tostring(questID) .. ", XP Reward: " .. tostring(xpReward) .. ", Money Reward: " .. tostring(moneyReward) .. " copper", 1.0, 0.08, 0.58)  -- Bright Pink
	end

	-- Reset Flag for printing schematics when quest accepted
	RQE.alreadyPrintedSchematics = false

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 02 Debug: SuperTrackedQuestID: " .. tostring(C_SuperTrack.GetSuperTrackedQuestID()), 1.0, 0.08, 0.58)
	end

	-- Update the visibility or content of RQEQuestFrame as needed
	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 03 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 04 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestTurnedIn then
		DEFAULT_CHAT_FRAME:AddMessage("QTI 05 Debug: QuestID: " .. tostring(questID), 1.0, 0.08, 0.58)
	end

	-- Tier Four Importance: QUEST_TURNED_IN event
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(1, function()
			RQE.StartPerioFromQuestTurnedIn = true
			RQE:StartPeriodicChecks()	-- Checks 'funct' for current quest in DB after QUEST_TURNED_IN fires
			C_Timer.After(3, function()
				RQE.StartPerioFromQuestTurnedIn = false
			end)
		end)
	end

	local questInfo = RQE.getQuestData(questID)

	if questInfo then
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
		-- Update RQEFrame
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	end
end


-- Handling QUEST_FINISHED event
-- Fired whenever the quest frame changes (from Detail to Progress to Reward, etc.) or is closed
function RQE.handleQuestFinished()
	-- Clear the raid marker from the current target
	if UnitExists("target") then
		SetRaidTarget("target", 0)
	end

	-- If no quest is currently super-tracked and enableNearestSuperTrack is activated, find and set the closest tracked quest
	if RQE.db.profile.enableNearestSuperTrack then
		local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
		if not RQE.isSuperTracking or not isSuperTracking then	--if not isSuperTracking then
			if not RQEFrame:IsShown() then return end
			local closestQuestID = RQE:GetClosestTrackedQuest()  -- Get the closest tracked quest
			if closestQuestID then
				C_SuperTrack.SetSuperTrackedQuestID(closestQuestID)
				RQE:SaveSuperTrackedQuestToCharacter()
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
					DEFAULT_CHAT_FRAME:AddMessage("QF 01 Debug: Super-tracked quest set to closest quest ID: " .. tostring(closestQuestID), 1, 0.75, 0.79)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
					DEFAULT_CHAT_FRAME:AddMessage("QF 02 Debug: No closest quest found to super-track.", 1, 0.75, 0.79)
				end
			end
			RQE.TrackClosestQuest()
		end

		-- Sets the scroll frames of the RQEFrame and the FocusFrame within RQEFrame to top when QUEST_FINISHED event fires and player doesn't have mouse over the RQEFrame ("Super Track Frame")
		if RQEFrame and not RQEFrame:IsMouseOver() then
			RQE.ScrollFrameToTop()
		end
		RQE.FocusScrollFrameToTop()
	end

	local extractedQuestID
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 01 Debug: ExtractedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
	end

	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if isSuperTracking then
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
			DEFAULT_CHAT_FRAME:AddMessage("QF 03 Debug: SuperTrackedQuestID: " .. tostring(superTrackedQuestID), 1, 0.75, 0.79)
		end
	end

	-- Determine questID based on various fallbacks
	local questID = RQE.searchedQuestID or extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()
	local questInfo = RQE.getQuestData(questID)
	if questInfo then
		local StepsText, CoordsText, MapIDs = PrintQuestStepsToChat(questID)
		UpdateFrame(questID, questInfo, StepsText, CoordsText, MapIDs)
	else
		UpdateFrame()
	end

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 02 Debug: Final QuestID for advancing step: " .. tostring(questID), 1, 0.75, 0.79)
		DEFAULT_CHAT_FRAME:AddMessage("QF 04 Debug: DisplayedQuestID: " .. tostring(extractedQuestID), 1, 0.75, 0.79)
	end

	-- Refresh Quest Tracker
	RQE:QuestType()

	-- Update the visibility or content of RQEFrame and RQEQuestFrame as needed
	RQE:UpdateRQEFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 05 Debug: Updated RQEFrame Visibility.", 1, 0.75, 0.79)
	end

	RQE:UpdateRQEQuestFrameVisibility()

	if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
		DEFAULT_CHAT_FRAME:AddMessage("QF 06 Debug: Updated RQEQuestFrame Visibility.", 1, 0.75, 0.79)
	end

	-- Check to advance to next step in quest
	if RQE.db.profile.autoClickWaypointButton then
		C_Timer.After(0.5, function()
			if RQE.db.profile.debugLevel == "INFO+" and RQE.db.profile.QuestFinished then
				DEFAULT_CHAT_FRAME:AddMessage("QF 07 Debug: Called CheckAndAdvanceStep for QuestID: " .. tostring(questID), 1, 0.75, 0.79)
			end
		end)
	end
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