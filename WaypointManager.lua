--[[ 

WaypointManager.lua
This add-on file handles the creation logic of the Waypoint and Map Pin creation

]]


---------------------------
-- 1. Library and AddOn Initialization
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}

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
--function RQE:CreateUnknownQuestWaypoint(unknownQuestID, mapID)
    local posX = RQE.superX
    local posY = RQE.superY
    local mapID = RQE.superMapID
    local DirectionText = RQEFrame.DirectionText  -- Assuming DirectionText is stored in RQE table

	if not questID then
		RQE.debugLog("Quest ID is nil. Cannot retrieve quest title.")
		return -- Early return to prevent the rest of the function from executing
	end

	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
    --local questName = C_QuestLog.GetTitleForQuestID(unknownQuestID) or "Unknown"
    
    local x, y  -- Declare x and y here so they are accessible throughout the function
    
    if posX and posY then
        x = posX * 100
        y = posY * 100
    else
        return
    end

	C_Map.ClearUserWaypoint()
	
	if IsAddOnLoaded("TomTom") then
		TomTom.waydb:ResetProfile()
	end

	C_Timer.After(0.5, function()
		-- Construct the waypoint title
		local waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName  -- Default title with Quest ID and Name
		--local waypointTitle = "Quest ID: " .. unknownQuestID .. ", Quest Name: " .. questName  -- Default title with Quest ID and Name
		
		if DirectionText and DirectionText ~= "No direction available." then
			waypointTitle = waypointTitle .. "\n" .. DirectionText  -- Append DirectionText on a new line if available
		end

		-- Check if TomTom is loaded and enabled
		if IsAddOnLoaded("TomTom") then
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
		
		-- Check if Carbonite is loaded and enabled
		if IsAddOnLoaded("Carbonite") then
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
-- @param x: X-coordinate
-- @param y: Y-coordinate
-- @param mapID: ID of the map where the coordinate was clicked
-- @param stepIndex: Index of the quest step
function RQE:OnCoordinateClicked(x, y, mapID, stepIndex)
    local questID = C_SuperTrack.GetSuperTrackedQuestID()
    RQE.debugLog("OnCoordinateClicked called with questID:", questID, "stepIndex:", stepIndex)

    local questData = RQEDatabase[questID]
    if not questData then
        RQE.debugLog("Quest data not found for ID:", questID)
        return -- Exit if no data found for the questID
    end
	
    local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
    local title = "Quest ID: " .. questID .. ", Quest Name: " .. questName

    -- Fetch the description from the specific stepIndex, if available
    local stepData = questData[stepIndex]
    local description = stepData and stepData.description or "No step description available"
	
    local directionText = RQEFrame.DirectionText
    --local description = RQEDatabase[questID].description

    if directionText then
        title = title .. "\nDirection: " .. directionText
    elseif description then
        title = title .. "\nDescription: " .. description
    end

    -- Check if TomTom is loaded and enabled
    if IsAddOnLoaded("TomTom") then
        RQE.debugLog("TomTom is available.")

        -- Add waypoint using TomTom
        local uid = TomTom:AddWaypoint(mapID, x/100, y/100, {
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