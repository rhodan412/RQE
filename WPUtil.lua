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
        local questID = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID

		if not questID then
            RQE.debugLog("No QuestID found. Cannot proceed.")
            return
        end

        -- Check if World Map is open
        local isMapOpen = WorldMapFrame:IsShown()

        if not posX or not posY then
            if not isMapOpen and RQE.superTrackingChanged then
                -- If coordinates are not available, attempt to open the quest log to get them
                OpenQuestLogToQuestDetails(questID)
				if not isMapOpen then
					WorldMapFrame:Hide()
				end
            end
        end

        -- Reset the superTrackingChanged flag
        RQE.superTrackingChanged = false

        -- Call your function to create a waypoint using stored coordinates and mapID
		RQE:CreateUnknownQuestWaypoint(questID, mapID)
    end)
end