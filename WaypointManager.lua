--[[ 

WaypointManager.lua
This add-on file handles the creation logic of the Waypoint and Map Pin creation

]]


---------------------------------------
-- 1. Library and AddOn Initialization
---------------------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}

---@type any
TomTom = TomTom or {}
---@type any
Nx = Nx or {}

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
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

	if mapID and x and y then -- Check if x and y are not nil
		print("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", title)
		TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = title })
		-- print("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
		-- TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
	end

	-- Add the waypoint to the RQEWaypoints table
	--table.insert(RQEWaypoints, waypoint)

	-- Create a Map Pin to represent the waypoint
	self:CreateMapPin(waypoint.mapID, waypoint.x, waypoint.y)

	RQE.debugLog("Exiting CreateWaypoint Function")
	return waypoint
end


-- Main function to determine which method to use based on waypoint text
function RQE:CreateUnknownQuestWaypoint(questID, mapID)
	-- Reset coordinates at the start
	RQE.x = nil
	RQE.y = nil
	RQE.MapID = nil
	RQE.DatabaseSuperX = nil
	RQE.DatabaseSuperY = nil
	RQE.DatabaseSuperMapID = nil
	RQE.superX = nil
	RQE.superY = nil
	RQE.superMapID = nil

	C_Timer.After(0.5, function()
		if not questID then
			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			else
				return
			end
		end

		local waypointText = C_QuestLog.GetNextWaypointText(questID)

		if waypointText then
			RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID)
		else
			RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID)
		end
	end)
end


-- Create a Waypoint when there is Direction Text available
function RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID)
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden and won't display waypoint information WithDirectionText")
		end
		return
	end

	if not questID then
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		else
			return
		end
	end

	local questData = RQE.getQuestData(questID)
	local x, y
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local waypointTitle

	if questData and questID and not C_QuestLog.IsOnQuest(questID) and questData.location then
		x = questData.location.x
		y = questData.location.y
		mapID = questData.location.mapID
		waypointTitle = "Quest Start: " .. questData.title
	else
		-- Directly fetch the super tracked quest data
		local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
		if superTrackedQuestID then
			mapID = C_TaskQuest.GetQuestZoneID(superTrackedQuestID) or GetQuestUiMapID(superTrackedQuestID)
			local isWorldQuest = C_QuestLog.IsWorldQuest(superTrackedQuestID)
			if isWorldQuest then
				x, y = C_TaskQuest.GetQuestLocation(superTrackedQuestID, mapID)
			else
				x, y = C_QuestLog.GetNextWaypointForMap(superTrackedQuestID, mapID)
			end
		end

		waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName

		if x and y then
			x = x * 100
			y = y * 100
		else
			RQE.debugLog("Could not fetch coordinates for the quest")
			return
		end
	end

	-- Ensure x and y are numbers before attempting arithmetic
	x = tonumber(x) or 0
	y = tonumber(y) or 0

	RQE.infoLog("Old method coordinates: x =", x, "y =", y, "mapID =", mapID)

	C_Map.ClearUserWaypoint()

	-- Check if TomTom is loaded and compatibility is enabled
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom.waydb:ResetProfile()
	end

	C_Timer.After(0.5, function()
		if RQE.DirectionText and RQE.DirectionText ~= "No direction available." then
			waypointTitle = waypointTitle .. "\n" .. RQE.DirectionText -- Append DirectionText on a new line if available
		end

		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			if mapID and x and y then -- Check if x and y are not nil
				RQE.infoLog("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
			else
				RQE.debugLog("Could not create waypoint for unknown quest.")
			end
		else
			RQE.debugLog("TomTom is not available.")
		end

		-- Check if Carbonite is loaded and compatibility is enabled
		local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
		if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
			if mapID and x and y then -- Check if x and y are not nil
				RQE.infoLog("Adding waypoint to Carbonite: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointTitle })
			else
				RQE.debugLog("Could not create waypoint for unknown quest.")
			end
		else
			RQE.debugLog("Carbonite is not available.")
		end
	end)
end


-- Create a Waypoint when there is No Direction Text available
function RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID)
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden and won't display waypoint information for NoDirectionText")
		end
		return
	end

	if not questID then
		-- Check if RQE.QuestIDText exists and has text
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		else
			return -- Exit if questID and QuestIDText are both unavailable
		end
	end

	local questData = RQE.getQuestData(questID)
	local x, y
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local waypointTitle

	-- Determine coordinates and title based on quest presence in quest log and database
	if questData and not C_QuestLog.IsOnQuest(questID) and questData.location then
		x = questData.location.x
		y = questData.location.y
		mapID = questData.location.mapID
		waypointTitle = "Quest Start: " .. questData.title
	else
		-- Fetch coordinates using super tracking data
		C_Timer.After(0.1, function()
			local extractedQuestID = nil

			-- Ensure QuestIDText exists and is valid before extracting the quest ID
			if RQE.QuestIDText and RQE.QuestIDText:GetText() then
				extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
			end

			-- Use either extractedQuestID or current super-tracked quest ID
			local questID = extractedQuestID or C_SuperTrack.GetSuperTrackedQuestID()

			if questID then
				mapID = GetQuestUiMapID(questID)
				questData = RQE.getQuestData(questID)
				if mapID == 0 then mapID = nil end
			end

			if RQE.DatabaseSuperX and questID and not C_QuestLog.IsOnQuest(questID) then
				RQE.x = RQE.DatabaseSuperX
				RQE.y = RQE.DatabaseSuperY
				RQE.MapID = RQE.DatabaseSuperMapID
			elseif not RQE.DatabaseSuperX and RQE.DatabaseSuperY or not RQE.superX or not RQE.superY and RQE.superMapID then
				RQE.x = RQE.superX
				RQE.y = RQE.superY
				RQE.MapID = RQE.superMapID

				local x, y, mapID = RQE.GetQuestCoordinates(questID)
				if x and y and mapID then
					RQE.x = x
					RQE.y = y
					RQE.MapID = mapID
				else
					-- Add a check here to ensure GetNextWaypoint only runs if waypoints are available
					if questID then
						local waypointMapID, waypointX, waypointY = C_QuestLog.GetNextWaypoint(questID)
						if waypointX and waypointY and waypointMapID then
							RQE.x = waypointX
							RQE.y = waypointY
							RQE.MapID = waypointMapID
						else
							-- Handle cases where no waypoint is available
							RQE.x = 0
							RQE.y = 0
							RQE.MapID = nil
							RQE.debugLog("No waypoint data available for quest ID:", questID)
						end
					end
				end
			end

			RQE.infoLog("After timer: x =", RQE.x, "y =", RQE.y, "mapID =", RQE.MapID)

			if RQE.x and RQE.y then
				x = RQE.x * 100
				y = RQE.y * 100
			else
				x = 0
				y = 0
			end

			mapID = RQE.MapID or mapID
			
			-- Ensure questID is not nil before using it
			if not questID then
				questID = C_SuperTrack.GetSuperTrackedQuestID() or 0  -- Fallback to super-tracked quest or set to 0
			end

			-- Set a default title if questID is still nil or 0
			local waypointTitle = questID > 0 and ("Quest ID: " .. questID .. ", Quest Name: " .. (questName or "Unknown")) or "Unknown Quest"

			--waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName

			x = tonumber(x) or 0
			y = tonumber(y) or 0

			RQE.infoLog("Before clearing user waypoint: x =", x, "y =", y, "mapID =", mapID)

			C_Map.ClearUserWaypoint()

			local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
			if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
				TomTom.waydb:ResetProfile()
			end

			C_Timer.After(0.5, function()
				if RQE.DirectionText and RQE.DirectionText ~= "No direction available." then
					waypointTitle = waypointTitle .. "\n" .. RQE.DirectionText
				end

				local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
				if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
					if mapID and x and y then
						RQE.infoLog("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
						TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
					else
						RQE.debugLog("Could not create waypoint for unknown quest.")
					end
				else
					RQE.debugLog("TomTom is not available.")
				end

				local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
				if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
					if mapID and x and y then
						RQE.infoLog("Adding waypoint to Carbonite: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
						Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointTitle })
					else
						RQE.debugLog("Could not create waypoint for unknown quest.")
					end
				else
					RQE.debugLog("Carbonite is not available.")
				end
			end)
		end)
	end
end


-- Create a Waypoint when there is No Direction Text available
function RQE:CreateUnknownQuestWaypointForEvent(questID, mapID)
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden and won't display waypoint information for ForEvent")
		end
		return
	end

	if not questID then
		-- Check if RQE.QuestIDText exists and has text
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		else
			return -- Exit if questID and QuestIDText are both unavailable
		end
	end

	local questData = RQE.getQuestData(questID)
	local x, y
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local waypointTitle

	-- Determine coordinates and title based on quest presence in quest log and database
	if questData and questID and not C_QuestLog.IsOnQuest(questID) and questData.location then
		x = questData.location.x
		y = questData.location.y
		mapID = questData.location.mapID
		waypointTitle = "Quest Start: " .. questData.title
	else
		-- Log error if location data isn't available
		RQE.debugLog("No valid coordinates available for quest:", questID)
		return
	end

	-- Ensure x and y are numbers before setting the waypoint
	x = tonumber(x) or 0
	y = tonumber(y) or 0
	waypointTitle = waypointTitle or ("Quest ID: " .. questID .. ", Quest Name: " .. questName)

	RQE.infoLog("Attempting to set waypoint for:", questName, "at coordinates:", x, ",", y, "on mapID:", mapID)

	-- Clear any existing waypoint
	C_Map.ClearUserWaypoint()

	-- Check if TomTom is loaded and compatibility is enabled
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom.waydb:ResetProfile()
		C_Timer.After(0.5, function()
			if mapID and x and y then
				RQE.infoLog("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
			else
				RQE.debugLog("Could not create TomTom waypoint for:", questID)
			end
		end)
	else
		RQE.debugLog("TomTom is not available or compatibility disabled.")
	end

	-- Check if Carbonite is loaded and compatibility is enabled
	local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
	if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
		C_Timer.After(0.5, function()
			if mapID and x and y then
				RQE.infoLog("Adding waypoint to Carbonite: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointTitle })
			else
				RQE.debugLog("Could not create Carbonite waypoint for:", questID)
			end
		end)
	else
		RQE.debugLog("Carbonite is not available or compatibility disabled.")
	end

	-- Fallback to default waypoint if neither TomTom nor Carbonite are used
	if not isTomTomLoaded and not isCarboniteLoaded then
		RQE.debugLog("Setting default waypoint with C_Map.SetUserWaypoint")
		C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
	end
end


-- Create a Waypoint for a specific quest step using questID and stepIndex
function RQE:CreateWaypointForStep(questID, stepIndex)
	-- Ensure questID and stepIndex are valid
	if not questID or not stepIndex then
		print("Invalid questID or stepIndex provided for waypoint creation.")
		return
	end

	-- Fetch quest data for the given questID
	local questData = RQE.getQuestData(questID)
	if not questData or not questData[stepIndex] then
		print("No quest data found for questID:", questID, "or stepIndex:", stepIndex)
		return
	end

	-- Retrieve step data and coordinates
	local stepData = questData[stepIndex]
	local x, y, mapID = stepData.coordinates.x, stepData.coordinates.y, stepData.coordinates.mapID
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName

	-- Fetch the description from the specific stepIndex, if available
	local stepData = questData[stepIndex]
	RQE.DescriptionText = stepData and stepData.description or "No step description available"

	if not x or not y or not mapID then
		print("Invalid coordinates for questID:", questID, "stepIndex:", stepIndex)
		return
	end

	-- Ensure x and y are numbers before attempting arithmetic
	x = tonumber(x) or 0
	y = tonumber(y) or 0

	-- Clear any existing user waypoint
	C_Map.ClearUserWaypoint()

	-- Check if TomTom is loaded and compatibility is enabled
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom.waydb:ResetProfile()
	end

	-- Set a timer to handle waypoint setting (with delay for compatibility reasons)
	C_Timer.After(0.5, function()
		if RQE.DescriptionText and RQE.DescriptionText ~= "No direction available." then
			waypointTitle = waypointTitle .. "\n" .. RQE.DescriptionText -- Append DirectionText on a new line if available
		end

		-- Add waypoint for TomTom if available and enabled
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			if mapID and x and y then -- Check if x and y are not nil
				print("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
			else
				print("Could not create waypoint for unknown quest.")
			end
		else
			print("TomTom is not available.")
		end

		-- Check if Carbonite is loaded and compatibility is enabled
		local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
		if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
			if mapID and x and y then -- Check if x and y are not nil
				print("Adding waypoint to Carbonite: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointTitle })
			else
				print("Could not create waypoint for unknown quest.")
			end
		else
			print("Carbonite is not available.")
		end
	end)
end


-- Create a Waypoint Using C_QuestLog.GetNextWaypoint
function RQE:CreateQuestWaypointFromNextWaypoint(questID)
	-- Ensure the frame is shown before proceeding
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden, skipping waypoint creation for NextWaypoint")
		end
		return
	end

	-- Ensure a valid questID is available
	if not questID then
		questID = C_SuperTrack.GetSuperTrackedQuestID()
		if not questID or questID == 0 then
			print("No valid questID found for waypoint creation.")
			return
		end
	end

	-- Retrieve the Next Waypoint text
	local waypointText = C_QuestLog.GetNextWaypointText(questID)
	if not waypointText or waypointText == "" then
		print("No Next Waypoint text available for questID:", questID)
		return
	end

	-- Retrieve the next waypoint coordinates
	local mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
	if not mapID or not x or not y then
		print("No waypoint data available for questID:", questID)
		return
	end

	-- Convert to percentage format
	x = x * 100
	y = y * 100

	-- Debug info
	if RQE.db.profile.debugLevel == "INFO+" then
		print(string.format("Setting Waypoint: QuestID: %d, MapID: %d, X: %.2f, Y: %.2f", questID, mapID, x, y))
	end

	-- Clear existing waypoint
	C_Map.ClearUserWaypoint()

	-- Create a new user waypoint
	local waypointData = {
		uiMapID = mapID,
		position = CreateVector2D(x / 100, y / 100),
		name = waypointText
	}
	C_Map.SetUserWaypoint(waypointData)
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	-- TomTom Integration (if enabled)
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointText })
		print("Waypoint added to TomTom for questID:", questID)
	end

	-- Carbonite Integration (if enabled)
	local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
	if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
		Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointText })
		print("Waypoint added to Carbonite for questID:", questID)
	end
end


-- Create a Waypoint Using C_QuestLog.GetNextWaypointForMap with Exclusion List
function RQE:CreateSuperTrackedQuestWaypointFromNextWaypointOnCurrentMap()
	-- Ensure the frame is shown before proceeding
	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden, skipping waypoint creation for NextWaypoint")
		end
		return
	end

	-- Define a list of excluded quest IDs
	local excludedQuestIDs = {
		-- 74359,  -- Example Quest ID 1 (Replace with actual IDs)
		-- 76000   -- Example Quest ID 2
	}

	-- Extract Quest ID from UI if applicable
	local extractedQuestID = nil
	if RQE.QuestIDText and RQE.QuestIDText:GetText() then
		extractedQuestID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
	end

	-- Retrieve the currently super-tracked quest ID
	local questID = C_SuperTrack.GetSuperTrackedQuestID() or extractedQuestID
	if not questID or questID == 0 then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No super-tracked quest found.")
		end
		return
	end

	-- Check if the quest is in the exclusion list
	for _, excludedID in ipairs(excludedQuestIDs) do
		if questID == excludedID then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Quest ID", questID, "is in the exclusion list. Skipping waypoint creation.")
			end
			return
		end
	end

	-- Retrieve the Next Waypoint text
	local waypointText = C_QuestLog.GetNextWaypointText(questID)
	if not waypointText or waypointText == "" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No Next Waypoint text available for questID:", questID)
		end
		return
	end

	-- Retrieve the next waypoint coordinates
	local mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
	if not mapID or not x or not y then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("No waypoint data available for questID:", questID)
		end
		return
	end

	-- Convert to percentage format
	x = x * 100
	y = y * 100

	-- Debug info
	if RQE.db.profile.debugLevel == "INFO+" then
		print(string.format("Setting Waypoint: QuestID: %d, MapID: %d, X: %.2f, Y: %.2f", questID, mapID, x, y))
	end

	-- Clear existing waypoint
	C_Map.ClearUserWaypoint()

	-- Create a new user waypoint
	local waypointData = {
		uiMapID = mapID,
		position = CreateVector2D(x / 100, y / 100),
		name = waypointText
	}
	C_Map.SetUserWaypoint(waypointData)
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	-- TomTom Integration (if enabled)
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointText })
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Waypoint added to TomTom for questID:", questID)
		end
	end

	-- Carbonite Integration (if enabled)
	local _, isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
	if isCarboniteLoaded and RQE.db.profile.enableCarboniteCompatibility then
		Nx:TTAddWaypoint(mapID, x / 100, y / 100, { opt = waypointText })
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Waypoint added to Carbonite for questID:", questID)
		end
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
			RQE:RemoveMapPin()

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
end


-- Function: RemoveMapPin
-- Removes an existing map pin.
-- @param mapPinID: The ID of the map pin to remove (note: mapPinID is not needed for clearing the user waypoint)
function RQE:RemoveMapPin()
	-- Check if there is a user waypoint set
	if C_Map.HasUserWaypoint() then
		-- Clear the user waypoint
		C_Map.ClearUserWaypoint()
		RQE.debugLog("Removed user waypoint")
	else
		RQE.debugLog("No user waypoint to remove")
	end
end


---------------------------
-- 3. Event Handlers
---------------------------

-- Function: OnCoordinateClicked
-- Triggered when a coordinate is clicked on the map.
-- This version also creates waypoints using TomTom if available.
-- @param stepIndex: Index of the quest step
function RQE:OnCoordinateClicked()
	local stepIndex = RQE.AddonSetStepIndex or 1
	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	if not questID then
		RQE.debugLog("No super-tracked quest.")
		return -- Exit the function if questID is nil
	end

	-- Fetch the coordinates using the shared function
	local x, y, mapID = RQE:GetStepCoordinates(stepIndex)

	if not x or not y or not mapID then
		RQE.debugLog("Invalid coordinates. Waypoint creation skipped.")
		return -- Exit if coordinates are invalid
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("OnCoordinateClicked called with questID:", questID, "stepIndex:", stepIndex)
		print("Waypoint coordinates - X:", x, "Y:", y, "MapID:", mapID)
		RQE.isCheckingMacroContents = true
	end

	local questData = RQE.getQuestData(questID)
	if not questData then
		return -- Exit if no data found for the questID
	end

	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local title = "Quest ID: " .. questID .. ", Quest Name: " .. questName

	-- Fetch the description from the specific stepIndex, if available
	local stepData = questData[stepIndex]
	local description = stepData and stepData.description or "No step description available"

	local directionText = RQE.DirectionText

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
		local uid = TomTom:AddWaypoint(mapID, x, y, {
			title = title,
			from = "RQE",
			persistent = nil,
			minimap = true,
			world = true
		})

		if uid then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("Waypoint added successfully with UID:", tostring(uid))
			end
		else
			RQE.debugLog("Failed to add waypoint.")
		end
	else
		RQE.debugLog("TomTom is not available.")
	end
end


---------------------------
-- 4. Finalization
---------------------------

-- Final steps and exporting functions for use in other files