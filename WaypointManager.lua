--[[ 

WaypointManager.lua
This add-on file handles the creation logic of the Waypoint and Map Pin creation

]]


---------------------------
-- 1. Library and AddOn Initialization
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}

---@type any
TomTom = TomTom or {}
---@type any
Nx = Nx or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end


---------------------------
-- 2. Waypoint Logic
---------------------------

-- Function: InitializeWaypointManager
-- Initializes the waypoint management system.
function RQE:InitializeWaypointManager()
    RQEWaypoints = RQEWaypoints or {}
end


-- Function: CreateWaypoint
-- Creates a new waypoint.
-- @param x: X-coordinate
-- @param y: Y-coordinate
-- @param mapID: ID of the map
-- @param title: Title of the waypoint
-- @return: Returns the created waypoint object
function RQE:CreateWaypoint(x, y, mapID, title)

    -- If x and y are nil, use stored values from RQE.x and RQE.y
    x = x or RQE.x
    y = y or RQE.y

    -- Create the waypoint data
    local waypoint = {}
    waypoint.x = x
    waypoint.y = y
    waypoint.mapID = mapID
    waypoint.title = title

    -- Add the waypoint to the RQEWaypoints table
    table.insert(RQEWaypoints, waypoint)

    -- Create a Map Pin to represent the waypoint
    self:CreateMapPin(waypoint.mapID, waypoint.x, waypoint.y)

	RQE.debugLog("Exiting CreateWaypoint Function")
    return waypoint
end


-- Remove the extra functions and keep only this one
function RQE:CreateUnknownQuestWaypoint(questID, mapID)
	if not questID then
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		else
			return
		end
	end

    local questData = RQE.getQuestData(questID)
    local x, y, mapID
    local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
    local waypointTitle

    -- Determine coordinates and title based on quest presence in quest log and database
    if questData and not C_QuestLog.IsOnQuest(questID) and questData.location then
        x = questData.location.x
        y = questData.location.y
        mapID = questData.location.mapID
        waypointTitle = "Quest Start: " .. questData.title
    else
        x = RQE.superX or 0 -- Default to 0 if nil
        y = RQE.superY or 0 -- Default to 0 if nil
        mapID = RQE.superMapID
        waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName

		if x and y then
			x = x * 100
			y = y * 100
		else
			return
		end
    end

    -- Ensure x and y are numbers before attempting arithmetic
    x = tonumber(x) or 0
    y = tonumber(y) or 0

	C_Map.ClearUserWaypoint()

    -- Check if TomTom is loaded and compatibility is enabled
    local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
    if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
        TomTom.waydb:ResetProfile()
    end

	C_Timer.After(0.5, function()
		if RQE.DirectionText and RQE.DirectionText ~= "No direction available." then
			waypointTitle = waypointTitle .. "\n" .. RQE.DirectionText  -- Append DirectionText on a new line if available
		end

		-- Check if TomTom is loaded and compatibility is enabled
        local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
        if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			RQE.debugLog("TomTom is available.")
			if mapID and x and y then  -- Check if x and y are not nil
				TomTom:AddWaypoint(mapID, x/100, y/100, {title = waypointTitle})
			else
				RQE.debugLog("Could not create waypoint for unknown quest.")
			end
		else
			RQE.debugLog("TomTom is not available.")
			-- Code for your own waypoint system or an alternative action
		end

        -- Check if Carbonite is loaded and compatibility is enabled
        local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
        if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
			RQE.debugLog("Carbonite is available.")
			if mapID and x and y then  -- Check if x and y are not nil
				Nx:TTAddWaypoint (mapID, x/100, y/100, {opt = waypointTitle})
			else
				RQE.debugLog("Could not create waypoint for unknown quest.")
			end
		else
			RQE.debugLog("Carbonite is not available.")
			-- Code for your own waypoint system or an alternative action
		end
	end)
end


-- Function: RemoveWaypoint
-- Removes an existing waypoint.
-- @param waypoint: The waypoint object to remove
-- @return: Returns true if the waypoint was successfully removed, false otherwise
function RQE:RemoveWaypoint(waypoint)
    for index, wp in ipairs(RQEWaypoints) do
        if wp == waypoint then
            -- Remove the map pin
            self:RemoveMapPin(wp)

            -- Remove the waypoint from the RQEWaypoints table
            table.remove(RQEWaypoints, index)
            return true
        end
    end

    return false
end


-- Function: CreateMapPin
-- Creates a new map pin at the given coordinates on the specified map.
-- @param mapID: ID of the map
-- @param x: X-coordinate
-- @param y: Y-coordinate
function RQE:CreateMapPin(mapID, x, y)
    -- Logic to create a new map pin
    -- ...
end


-- Function: RemoveMapPin
-- Removes an existing map pin.
-- @param mapPinID: The ID of the map pin to remove
function RQE:RemoveMapPin(mapPinID)
    -- Logic to remove a map pin
    -- ...
end

---------------------------
-- 3. Event Handlers
---------------------------

-- Function: OnCoordinateClicked (Updated)
-- Triggered when a coordinate is clicked on the map.
-- This version also creates waypoints using TomTom if available.
-- @param stepIndex: Index of the quest step
function RQE:OnCoordinateClicked(stepIndex)
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    local x, y, mapID

    if not questID then
        RQE.debugLog("No super-tracked quest.")
        return -- Exit the function if questID is nil
    end

    -- Check conditions and get or reset coordinates
    if RQE.db.profile.autoClickWaypointButton and RQE.AreStepsDisplayed(questID) then
        -- Fetch the coordinates directly from the step data
        local questData = RQE.getQuestData(questID)
        if questData and questData[stepIndex] and questData[stepIndex].coordinates then
            x = questData[stepIndex].coordinates.x
            y = questData[stepIndex].coordinates.y
            mapID = questData[stepIndex].coordinates.mapID
        else
            RQE.debugLog("Coordinates not found for quest step:", stepIndex)
            return -- Exit if coordinates are not found
        end
    else
        -- Reset the coordinates to avoid creating incorrect waypoints
        x, y, mapID = nil, nil, nil
    end

    if not x or not y or not mapID then
        RQE.debugLog("Invalid coordinates. Waypoint creation skipped.")
        return -- Exit if coordinates are invalid
    end

    RQE.debugLog("OnCoordinateClicked called with questID:", questID, "stepIndex:", stepIndex)

    local questData = RQE.getQuestData(questID)
    if not questData then
        RQE.debugLog("Quest data not found for ID:", questID)
        return -- Exit if no data found for the questID
    end

    local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
    local title = "Quest ID: " .. questID .. ", Quest Name: " .. questName

    -- Fetch the description from the specific stepIndex, if available
    local stepData = questData[stepIndex]
    local description = stepData and stepData.description or "No step description available"

    local directionText = RQE.DirectionText
    --local description = RQEDatabase[questID].description

    if directionText then
        title = title .. "\nDirection: " .. directionText
    elseif description then
        title = title .. "\nDescription: " .. description
    end

    -- Check if TomTom is loaded and compatibility is enabled
    local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
    if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
        RQE.debugLog("TomTom is available.")

        -- Add waypoint using TomTom
        local uid = TomTom:AddWaypoint(mapID, x / 100, y / 100, {
            title = title,
            from = "RQE",
            persistent = nil,
            minimap = true,
            world = true
        })

        if uid then
            RQE.debugLog("Waypoint added successfully with UID:", uid)
        else
            RQE.debugLog("Failed to add waypoint.")
        end
    else
        RQE.debugLog("TomTom is not available.")
        -- Code for your own waypoint system or an alternative action
    end
end


---------------------------
-- 4. Finalization
---------------------------

-- Final steps and exporting functions for use in other files
-- e.g., 