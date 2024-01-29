-- WPUtil.lua
-- This add-on file may be used to either store, or call coordinate information from the RQEDatabase file for the purposes of modularity/compartmentalization


---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}
RQE.Frame = RQE.Frame or {}


---------------------------
-- 2. Debug Logic
---------------------------

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
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
		
		local unknownQuestID = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID
		
		if not unknownQuestID then
			RQE.debugLog("No QuestID found. Cannot proceed.")
			return
		end

		local isMapOpen = WorldMapFrame:IsShown()
		local isWorldQuest = C_QuestLog.IsWorldQuest(unknownQuestID)
		local mapID, posX, posY, completed, objective

		if isWorldQuest then
			-- It's a world quest, use the TaskQuest APIs
			mapID = C_TaskQuest.GetQuestZoneID(unknownQuestID)
			
			-- Ensure mapID is valid before calling GetQuestLocation
			if mapID then
				posX, posY = C_TaskQuest.GetQuestLocation(unknownQuestID, mapID)
			else
				RQE.debugLog("Invalid mapID for World QuestID:", unknownQuestID)
				return
			end
		else
			-- Not a world quest, use the existing logic
			mapID = GetQuestUiMapID(unknownQuestID)
			completed, posX, posY, objective = QuestPOIGetIconInfo(unknownQuestID)
		end

        if not mapID then
            RQE.debugLog("MapID not found for QuestID:", unknownQuestID)
            return
        end

		-- Convert coordinates to percentage format
		--if posX then posX = posX * 100 end
		--if posY then posY = posY * 100 end
		
		-- If POI info is not available, try using GetNextWaypointForMap
		if not posX or not posY then
			if not isMapOpen and RQE.superTrackingChanged then
				-- Call the function to open the quest log with the details of the super tracked quest
				OpenQuestLogToQuestDetails(unknownQuestID)
			end
			
			completed, posX, posY, objective = QuestPOIGetIconInfo(unknownQuestID)
			
			if not posX or not posY then
				local nextPosX, nextPosY, nextMapID, wpType = C_QuestLog.GetNextWaypointForMap(unknownQuestID, mapID)
				
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
		
		-- Now you can call your function to create a waypoint
		RQE:CreateUnknownQuestWaypoint(unknownQuestID, mapID)
	end)
end