--[[ 

WaypointManager.lua
This add-on file handles the creation logic of the Waypoint and Map Pin creation

]]


---------------------------
-- 1. Library and AddOn Initialization
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}
--RQEFrame = RQEFrame or {}

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
function RQE:CreateUnknownQuestWaypoint(unknownQuestID, mapID)
    local posX = RQE.x
    local posY = RQE.y
    local mapID = RQE.mapID
    local DirectionText = RQEFrame.DirectionText  -- Assuming DirectionText is stored in RQE table
    local questName = C_QuestLog.GetTitleForQuestID(unknownQuestID) or "Unknown"
    
    local x, y  -- Declare x and y here so they are accessible throughout the function
    
    if posX and posY then
        x = posX * 100
        y = posY * 100
    else
        return
    end

    -- Construct the waypoint title
    local waypointTitle = "Quest ID: " .. unknownQuestID .. ", Quest Name: " .. questName  -- Default title with Quest ID and Name
    
    if DirectionText and DirectionText ~= "No direction available." then
        waypointTitle = waypointTitle .. "\n" .. DirectionText  -- Append DirectionText on a new line if available
    end

    if mapID and x and y then  -- Check if x and y are not nil
        TomTom:AddWaypoint(mapID, x/100, y/100, {title = waypointTitle})
    else
        RQE.debugLog("Could not create waypoint for unknown quest.")
    end
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
    local title = description and description:match("^(.-)\n") or "No description"
    if TomTom then
        RQE.debugLog("TomTom is available.")
        
        --Use the questHeader for the stepIndex if available
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        if questID and RQEDatabase[questID] then
			local _, _, _, questHeader = PrintQuestStepsToChat(questID)
			RQE.debugLog("questHeader received in OnCoordinateClicked: ", questHeader)
			if questHeader and questHeader[stepIndex] then
				title = questHeader[stepIndex]
			end
        end

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
        -- Use your own waypoint system
    end
end

---------------------------
-- 4. Finalization
---------------------------

-- Final steps and exporting functions for use in other files
-- e.g., 
-- RQE.WaypointManager = {}
-- RQE.WaypointManager.CreateWaypoint = createWaypointm