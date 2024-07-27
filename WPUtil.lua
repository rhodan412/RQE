-- WPUtil.lua
-- This add-on file may be used to either store, or call coordinate information from the RQEDatabase file for the purposes of modularity/compartmentalization


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
        local superQuest = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID
        local extractedQuestID
        if RQE.QuestIDText and RQE.QuestIDText:GetText() then
            extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
        end

        -- Determine questID based on various fallbacks
        local questID = RQE.searchedQuestID or extractedQuestID or superQuest
        local questData = RQE.getQuestData(questID)

        if not questID then
            print("No QuestID found. Cannot proceed.")
            return
        end

        -- Check if World Map is open
        local isMapOpen = WorldMapFrame:IsShown()

        if not RQE.posX or not RQE.posY then
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
        RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
    end)
end