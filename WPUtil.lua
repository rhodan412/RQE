--[[ 

WPUtil.lua
This add-on file may be used to either store, or call coordinate information from the RQEDatabase file for the purposes of modularity/compartmentalization

]]


---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}
RQE.Frame = RQE.Frame or {}

RQE.posX = nil
RQE.posY = nil

---------------------------
-- 2. Debug Logic
---------------------------

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end


---------------------------
-- 3. Waypoint Logic
---------------------------

-- Assume IsWorldMapOpen() returns true if the world map is open, false otherwise
-- Assume CloseWorldMap() closes the world map
RQE.UnknownQuestButtonCalcNTrack = function()
	RQE.UnknownQuestButton:SetScript("OnClick", function()
		if RQE.hoveringOnRQEFrameAndButton then
			RQE:StartPeriodicChecks()
			C_Timer.After(0.2, function()
				RQE.hoveringOnRQEFrameAndButton = false
			end)
		end

		local superQuest = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID
		local extractedQuestID
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		end

		-- Determine questID based on various fallbacks
		local questID = RQE.searchedQuestID or extractedQuestID or superQuest
		local questData = RQE.getQuestData(questID)

		if not questID then
			RQE.debugLog("No QuestID found. Cannot proceed.")
			return
		end

		-- Update the macro if the WaypointButton is physically clicked by the player
		RQE.isCheckingMacroContents = true
		RQEMacro:CreateMacroForCurrentStep()
		RQE.isCheckingMacroContents = false

		-- Check if World Map is open
		local isMapOpen = WorldMapFrame:IsShown()

		if not RQE.posX or not RQE.posY then
			if not isMapOpen and RQE.superTrackingChanged then
				-- If coordinates are not available, attempt to open the quest log to get them
				--OpenQuestLogToQuestDetails(questID)
				-- if not isMapOpen then
					-- WorldMapFrame:Hide()
				-- end
			end
		end

		-- Reset the superTrackingChanged flag
		RQE.superTrackingChanged = false

		-- Call function to create a waypoint using stored coordinates and mapID
		RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
	end)
end


-- Function to get coordinates for the current stepIndex
function RQE:GetStepCoordinates(stepIndex)
	local stepIndex = RQE.AddonSetStepIndex or 1
	local x, y, mapID
	local questID = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID

	-- Fetch the coordinates directly from the step data
	local questData = RQE.getQuestData(questID)
	if questData and questData[stepIndex] and questData[stepIndex].coordinates then
		x = questData[stepIndex].coordinates.x / 100
		y = questData[stepIndex].coordinates.y / 100
		mapID = questData[stepIndex].coordinates.mapID
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Using coordinates from RQEDatabase for stepIndex:", stepIndex)
		end
	else
		if RQE.WPxPos and C_QuestLog.IsOnQuest(questID) then
			-- If coordinates are available from DatabaseSuper, use them
			x = RQE.WPxPos
			y = RQE.WPyPos
			mapID = RQE.WPmapID
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Using coordinates from RQE.WPxyPos for questID:", questID)
			end
		elseif RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) then
			-- If coordinates are available from DatabaseSuper, use them
			x = RQE.DatabaseSuperX
			y = RQE.DatabaseSuperY
			mapID = RQE.DatabaseSuperMapID
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Using coordinates from DatabaseSuper for questID:", questID)
			end
		elseif (not RQE.DatabaseSuperX and RQE.DatabaseSuperY) or (not RQE.superX or not RQE.superY and RQE.superMapID) then
			-- Open the quest log details for the super tracked quest to fetch the coordinates
			--OpenQuestLogToQuestDetails(questID)

			-- Use RQE.GetQuestCoordinates to get the coordinates
			x, y, mapID = RQE.GetQuestCoordinates(questID)
			if not (x and y and mapID) then
				-- Fallback to using C_QuestLog.GetNextWaypoint if coordinates are not available
				mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Fallback to GetNextWaypoint for coordinates for questID:", questID)
				end
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Using coordinates from GetQuestCoordinates for questID:", questID)
				end
			end
		else
			-- If coordinates are available from super tracking, use them
			x = RQE.superX
			y = RQE.superY
			mapID = RQE.superMapID
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Using coordinates from super tracking for questID:", questID)
			end
		end
	end

	-- Save the final coordinates to be used for the waypoint
	RQE.WPxPos = x
	RQE.WPyPos = y
	RQE.WPmapID = mapID

	-- Debug print the final coordinates and the method used
	if RQE.db.profile.debugLevel == "INFO+" then
		print("Final waypoint coordinates - X:", RQE.WPxPos, "Y:", RQE.WPyPos, "MapID:", RQE.WPmapID)
	end

	return x, y, mapID
end