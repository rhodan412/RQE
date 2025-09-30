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


-------------------------------
-- 2. Waypoint Exclusion Logic
-------------------------------

-- List of quests excluded from waypoint creation
RQE.ExcludedWaypointQuests = {
	--[82957] = true,
	-- Add other questIDs here
}


---------------------------
-- 3. Waypoint Logic
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
-- @param title: Title of the waypoint (optional override)
-- @return: Returns the created waypoint object
function RQE:CreateWaypoint(x, y, mapID, title)
	-- print("~~~ Waypoint Creation Function: 58 ~~~")

	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

	-- If x and y are nil, use stored values from RQE.x and RQE.y
	x = x or RQE.x
	y = y or RQE.y

	-- Normalize once: accept either 0–1 or 0–100
	if x and x > 1 then x = x / 100 end
	if y and y > 1 then y = y / 100 end

	local xNorm = (x and x > 1) and (x / 100) or x
	local yNorm = (y and y > 1) and (y / 100) or y
	if not (mapID and xNorm and yNorm) then return end

	-- Skip if coords haven’t changed meaningfully
	if RQE._lastWP
		and RQE._lastWP.mapID == mapID
		and math.abs(RQE._lastWP.x - xNorm) < 1e-4
		and math.abs(RQE._lastWP.y - yNorm) < 1e-4 then
		return
	end

	-- Default title: use supertracked quest
	local questID  = (C_SuperTrack.IsSuperTrackingQuest() and C_SuperTrack.GetSuperTrackedQuestID())
	local questData = questID and RQE.getQuestData(questID)

	if not title and questData then
		title = questData.title or ("Quest " .. tostring(questID))

		-- Step-specific logic
		local stepIndex = RQE.AddonSetStepIndex or 1
		local step = questData[stepIndex]

		if step then
			-- DirectionText has highest priority (do NOT override with wayText)
			if step.directionText then
				title = questID .. " " .. questData.title .. " - " .. step.directionText
			elseif step.coordinateHotspots then
				-- Look for a matching hotspot with wayText
				for _, hotspot in ipairs(step.coordinateHotspots) do
					local hx = (hotspot.x > 1) and (hotspot.x / 100) or hotspot.x
					local hy = (hotspot.y > 1) and (hotspot.y / 100) or hotspot.y
					if hotspot.mapID == mapID
						and math.abs(hx - xNorm) < 1e-4
						and math.abs(hy - yNorm) < 1e-4 then
						if hotspot.wayText and hotspot.wayText ~= "" then
							title = hotspot.wayText
						else
							-- fallback if wayText is missing or empty
							title = step.description or questData.title or ("Quest " .. tostring(questID))
						end
					end
				end
			end
		end
	end

	-- Create a Map Pin to represent the waypoint
	--self:CreateMapPin(mapID, (x or 0) * 100, (y or 0) * 100)

	RQE.debugLog("Exiting CreateWaypoint Function")

	-- Store last waypoint info
	RQE._lastWP = { mapID = mapID, x = xNorm, y = yNorm, title = title }

	-- Create with TomTom (if loaded)
	if TomTom and TomTom.AddWaypoint then
		return TomTom:AddWaypoint(mapID, xNorm, yNorm, { title = title or "Waypoint" })
	elseif Nx and Nx.WaypointAdd then
		return Nx:WaypointAdd(mapID, xNorm, yNorm, title or "Waypoint")
	end
end


-- Main function to determine which method to use based on waypoint text
function RQE:CreateUnknownQuestWaypoint(questID, mapID)
	-- print("~~~ Waypoint Creation Function: 92 ~~~")

	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

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

		if RQE.searchedQuestID then
				RQE:CreateSearchedQuestWaypoint(questID, mapID)
			return
		end

		if waypointText then
			RQE.DontPrintTransitionBits = true
			RQE:FindQuestZoneTransition(questID)
			RQE.DontPrintTransitionBits = false
			--RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID)
		else
			RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID)
		end
	end)
end


-- Create a Waypoint when searching for a quest based on the location coordinates in the DB file
function RQE:CreateSearchedQuestWaypoint(questID, mapID)
	-- print("~~~ Waypoint Creation Function: 132 ~~~")

	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

	local dbEntry = RQE.getQuestData(questID)
	if not dbEntry then
		RQE.debugLog("No DB entry found for QuestID:", questID)
		return
	end

	local isComplete = C_QuestLog.IsQuestFlaggedCompleted(questID)
	local isInLog = C_QuestLog.GetLogIndexForQuestID(questID)

	if isComplete then
		RQE.debugLog("QuestID", questID, "is already completed.")
		return
	end

	if isInLog then
		RQE.debugLog("QuestID", questID, "is in player log, skipping location-based waypoint.")
		return
	end

	if not dbEntry.location then
		RQE.debugLog("No location field for QuestID:", questID)
		return
	end

	local x = tonumber(dbEntry.location.x)
	local y = tonumber(dbEntry.location.y)
	local finalMapID = mapID or tonumber(dbEntry.location.mapID)

	if not x or not y or not finalMapID then
		RQE.debugLog("Invalid coordinates for QuestID:", questID)
		return
	end

	-- print("~~~ Waypoint Set: 152 ~~~")
	local label = "Waypoint for " .. (dbEntry.title or ("Quest ID: " .. questID))

	-- ✅ Prefer wrapper function if it exists
	if RQE.CreateWaypoint then
		RQE:CreateWaypoint(x, y, finalMapID, label)
	else
		-- ✅ Fallback to TomTom if available
		if TomTom and TomTom.AddWaypoint then
			RQE._currentTomTomUID = RQE.Waypoints:Replace(finalMapID, x, y, label)
			-- TomTom:AddWaypoint(finalMapID, x, y, {
				-- title = label,
				-- from = "RQE",
				-- persistent = nil,
				-- minimap = true,
				-- world = true
			-- })

			if RQE.db.profile.debugLevel == "INFO+" then
				print("TomTom Waypoint created for QuestID:", questID, "at", x, y, "on MapID:", finalMapID)
			end
		else
			RQE.debugLog("No TomTom or CreateWaypoint available.")
		end
	end

	-- Store for internal use if needed
	RQE.WPxPos = x
	RQE.WPyPos = y
	RQE.WPmapID = finalMapID

	if RQE.db.profile.debugLevel == "INFO+" then
		local mapInfo = C_Map.GetMapInfo(mapID)
		if mapInfo then
			if not mapInfo then return "Unknown", "Unknown" end

			local zoneName = mapInfo.name or "Unknown"

			local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID or 0)
			local continentName = parentMapInfo and parentMapInfo.name or "Unknown"
			print("Travel to " .. zoneName .. ", " .. continentName)
		end
	end
end


-- Create a Waypoint when there is Direction Text available
function RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID)
	-- print("~~~ Waypoint Creation Function: 276 ~~~")

	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

	if not RQEFrame:IsShown() then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("Frame is hidden and won't display waypoint information for NoDirectionText")
		end
		return
	end

	-- 1) Resolve questID if omitted
	if not questID then
		-- Check if RQE.QuestIDText exists and has text
		if RQE.QuestIDText and RQE.QuestIDText:GetText() then
			questID = tonumber(RQE.QuestIDText:GetText():match("%d+"))
		else
			return -- Exit if questID and QuestIDText are both unavailable
		end
	end

	-- local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	-- local waypointTitle = RQE:GetWaypointTitle(questID, mapID, (x and x/100) or nil, (y and y/100) or nil)	--local waypointTitle = questID > 0 and string.format('QID: %d, "%s"', questID, questName or "Unknown") or "Unknown Quest"
	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("waypointTitle - 302: " .. tostring(waypointTitle))
	-- end

	-- 2) Exclusions / hidden quest type
	local qType = C_QuestLog.GetQuestType(questID)
	if (RQE.ExcludedWaypointQuests and RQE.ExcludedWaypointQuests[questID]) or qType == 265 then
		if RQE.db.profile.debugLevel == "INFO" then
			print(questID .. " is excluded (explicitly or by quest type 265); waypoint will not be generated")
		end
		return 
	end

	-- 3) Prefer caller/player map
	mapID = mapID or RQE.WPmapID or C_Map.GetBestMapForUnit("player")
	if not mapID then
		return
	end

	-- 4) Utility to accept either normalized (0..1) or percent (0..100)
	local xPct, yPct
	local function setFrom(posX, posY, mid)
		if not posX or not posY then return false end
		posX, posY = tonumber(posX), tonumber(posY)
		if not posX or not posY then return false end
		if posX <= 1 and posY <= 1 then
			xPct, yPct = posX * 100, posY * 100
		else
			xPct, yPct = posX, posY
		end
		if mid then mapID = mid end
		return true
	end

	-- 5) FAST PATH: coords stashed by your transition finder (percent)
	if RQE.WPxPos and RQE.WPyPos then
		setFrom(RQE.WPxPos, RQE.WPyPos, RQE.WPmapID or mapID)
		--print(("Using stashed transition coords %.2f, %.2f on map %d"):format(xPct or -1, yPct or -1, mapID))
	end

	-- 6) FALLBACK A: exact quest waypoint for this map
	if not (xPct and yPct) then
		local xn, yn = C_QuestLog.GetNextWaypointForMap(questID, mapID)
		if xn and yn then
			setFrom(xn, yn, mapID)
			--print(("Using GetNextWaypointForMap -> %.2f, %.2f on map %d"):format(xPct, yPct, mapID))
		end
	end

	-- 7) FALLBACK B: generic next waypoint (vec or areaPoiID)
	if not (xPct and yPct) then
		local wpMapID, wpData = C_QuestLog.GetNextWaypoint(questID)
		if wpMapID then
			if type(wpData) == "table" then
				if wpData.x and wpData.y then
					setFrom(wpData.x, wpData.y, wpMapID)
				elseif wpData.position and wpData.position.x and wpData.position.y then
					setFrom(wpData.position.x, wpData.position.y, wpMapID)
				end
				-- if RQE.db.profile.debugLevel == "INFO" then
					-- if xPct and yPct then
						-- print(("GetNextWaypoint(table) -> %.2f, %.2f on map %d"):format(xPct, yPct, mapID))
					-- end
				-- end
			elseif type(wpData) == "number" then
				local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(wpMapID, wpData)
				if poiInfo and poiInfo.position then
					setFrom(poiInfo.position.x, poiInfo.position.y, wpMapID)
					-- if RQE.db.profile.debugLevel == "INFO" then
						-- print(("GetNextWaypoint(poi %d) -> %.2f, %.2f on map %d"):format(wpData, xPct, yPct, mapID))
					-- end
				end
			end
		end
	end

	-- 8) FALLBACK C: DB quest.location
	if not (xPct and yPct) then
		local qd = RQE.getQuestData and RQE.getQuestData(questID)
		if qd and qd.location then
			if setFrom(qd.location.x, qd.location.y, qd.location.mapID or mapID) then
				print(("Using DB location -> %.2f, %.2f on map %d"):format(xPct, yPct, mapID))
			end
		end
	end

	if not (mapID and xPct and yPct) then
		if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
			print(("Unable to determine coords for quest %d."):format(questID))
		end
		return
	end

	-- 9) Build title lines for arrow (single-line) + multiline preview for debug
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local blizzWaypointText = C_QuestLog.GetNextWaypointText(questID)

	-- Bail out early if there is no actual direction text
	if (not blizzWaypointText or blizzWaypointText == "") and (not RQE.DirectionText or RQE.DirectionText == "" or RQE.DirectionText == "No direction available.") then
		return RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID)
	end

	-- Helper to trim overly long strings so the arrow doesn't hard-truncate mid-word
	local function ellipsize(s, max)
		if not s or s == "" then return nil end
		if #s <= max then return s end
		return s:sub(1, max - 1) .. "…"
	end

	-- What we *show* on the arrow: single line (TomTom can't do newlines)
	-- Keep this concise to avoid visual truncation.
	local arrowTitle
	do
		-- Keep the quest name fairly short; put the guidance after an em dash.
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~~~ wayText fix: 417 ~~~~")
		end
		local left  = ("QID %d — %s"):format(questID, ellipsize(questName, 28))
		local right = blizzWaypointText and ellipsize(blizzWaypointText, 48) or nil

		if right and right ~= "" then
			arrowTitle = ("%s — %s"):format(left, right)
		else
			arrowTitle = left
		end
	end

	-- What we *print* for debugging: multi-line (so you can verify the full text)
	local debugTitle = arrowTitle
	if blizzWaypointText and blizzWaypointText ~= "" then
		-- Build a clean two-line preview for chat/debug
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~~~ wayText fix: 432 ~~~~")
		end
		debugTitle = ("QID %d — %s\n%s"):format(questID, questName, blizzWaypointText)
	end

	-- If you also have RQE.DirectionText and it's different, append only to debug
	if RQE.DirectionText
	   and RQE.DirectionText ~= ""
	   and RQE.DirectionText ~= "No direction available."
	   and RQE.DirectionText ~= blizzWaypointText
	then
		debugTitle = debugTitle .. "\n" .. RQE.DirectionText
	end

	-- Use arrowTitle for the waypoint itself
	local waypointTitle = RQE:GetWaypointTitle(questID, mapID, xNorm, yNorm, arrowTitle)	--local waypointTitle = arrowTitle
	if RQE.db.profile.debugLevel == "INFO+" then
		print("waypointTitle - 451: " .. tostring(waypointTitle))
	end

	-- -- Optional: print the multi-line preview so you can confirm it's correct
	-- if RQE.db and RQE.db.profile and (RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+") then
		-- print("Waypoint title preview:\n" .. debugTitle)
	-- end

	-- 10) Place waypoint(s)
	C_Map.ClearUserWaypoint()

	local isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		-- Important: clear TomTom's prior waypoints so the new title takes effect
		if TomTom.waydb and TomTom.waydb.ResetProfile then
			TomTom.waydb:ResetProfile()
			RQE._currentTomTomUID = nil
		end
		RQE.Waypoints:Replace(mapID, xPct / 100, yPct / 100, waypointTitle)
		--TomTom:AddWaypoint(mapID, xPct / 100, yPct / 100, { title = waypointTitle })
	else
		if RQE.db.profile.debugLevel == "INFO+" then
			print("TomTom not available or disabled.")
		end
	end

	local isCarboniteLoaded = C_AddOns.IsAddOnLoaded("Carbonite")
	if isCarboniteLoaded and RQE.db and RQE.db.profile and RQE.db.profile.enableCarboniteCompatibility then
		Nx:TTAddWaypoint(mapID, xPct / 100, yPct / 100, { opt = waypointTitle })
	end

	-- 11) Clear stash to avoid reuse
	RQE.WPxPos, RQE.WPyPos, RQE.WPmapID = nil, nil, nil
end


-- Create a Waypoint when there is No Direction Text available
function RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID)
	-- print("~~~ Waypoint Creation Function: 401 ~~~")
	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end
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
			local questType = C_QuestLog.GetQuestType(questID)
			if RQE.ExcludedWaypointQuests[questID] or questType == 265 then		-- Prevents a waypoint from being created 'hidden' type quests
				if RQE.db.profile.debugLevel == "INFO" then
					print(questID .. " is excluded (explicitly or by quest type 265); waypoint will not be generated")
				end
				return 
			end

			-- print("~~~ Waypoint Set: 394 ~~~")

			if RQE.db.profile.debugLevel == "INFO+" then
				print("~~~~ wayText fix: 596 ~~~~")
			end

			local waypointTitle = RQE:GetWaypointTitle(questID, mapID, (x and x/100) or nil, (y and y/100) or nil)	--local waypointTitle = questID > 0 and ("QID: " .. questID .. ", Quest Name: " .. (questName or "Unknown")) or "Unknown Quest"
			if RQE.db.profile.debugLevel == "INFO+" then
				print("waypointTitle - 606: " .. tostring(waypointTitle))
			end
			--waypointTitle = "Quest ID: " .. questID .. ", Quest Name: " .. questName

			x = tonumber(x) or 0
			y = tonumber(y) or 0

			RQE.infoLog("Before clearing user waypoint: x =", x, "y =", y, "mapID =", mapID)

			C_Map.ClearUserWaypoint()

			local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
			if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
				TomTom.waydb:ResetProfile()
				RQE._currentTomTomUID = nil
			end

			C_Timer.After(0.5, function()
				if RQE.DirectionText and RQE.DirectionText ~= "No direction available." then
					waypointTitle = waypointTitle .. "\n" .. RQE.DirectionText
				end

				local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
				if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
					if mapID and x and y then
						RQE.infoLog("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
						RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, x, y, waypointTitle)
						--TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
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
	-- print("~~~ Waypoint Creation Function: 559 ~~~")
	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

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
	-- print("~~~ Waypoint Set: 483 ~~~")
	-- Decide final waypoint title with centralized logic
	waypointTitle = RQE:GetWaypointTitle(questID, mapID, x / 100, y / 100, waypointTitle)	--waypointTitle = waypointTitle or string.format('QID: %d, "%s"', questID, questName or "Unknown")
	if RQE.db.profile.debugLevel == "INFO+" then
		print("waypointTitle - 706: " .. tostring(waypointTitle))
	end

	RQE.infoLog("Attempting to set waypoint for:", questName, "at coordinates:", x, ",", y, "on mapID:", mapID)

	-- Clear any existing waypoint
	C_Map.ClearUserWaypoint()

	-- Check if TomTom is loaded and compatibility is enabled
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		TomTom.waydb:ResetProfile()
		RQE._currentTomTomUID = nil
		C_Timer.After(0.5, function()
			if mapID and x and y then
				RQE.infoLog("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, x, y, waypointTitle)
				--TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
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
	-- print("~~~ Waypoint Creation Function: 645 ~~~")
	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

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

	-- Get normalized coords for either legacy or hotspots
	local x, y, mapID = RQE:GetStepCoordinates(stepIndex)
	--local x, y, mapID = stepData.coordinates.x, stepData.coordinates.y, stepData.coordinates.mapID
	if not (x and y and mapID) then
		print("Invalid coordinates for questID:", questID, "stepIndex:", stepIndex)
		return
	end

	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	-- print("~~~ Waypoint Set: 549 ~~~")
	local waypointTitle = RQE:GetWaypointTitle(questID, mapID, (x and x/100) or nil, (y and y/100) or nil)	--local waypointTitle = string.format('QID: %d, "%s"', questID, questName or "Unknown")
	if RQE.db.profile.debugLevel == "INFO+" then
		print("waypointTitle - 790: " .. tostring(waypointTitle))
	end

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
		RQE._currentTomTomUID = nil
	end

	-- Set a timer to handle waypoint setting (with delay for compatibility reasons)
	C_Timer.After(0.5, function()
		if RQE.DescriptionText and RQE.DescriptionText ~= "No direction available." then
			waypointTitle = waypointTitle .. "\n" .. RQE.DescriptionText -- Append DirectionText on a new line if available
			if RQE.db.profile.debugLevel == "INFO+" then
				print("waypointTitle - 819: " .. tostring(waypointTitle))
			end
		end

		-- Add waypoint for TomTom if available and enabled
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			if mapID and x and y then -- Check if x and y are not nil
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Adding waypoint to TomTom: mapID =", mapID, "x =", x, "y =", y, "title =", waypointTitle)
				end
				RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, x, y, waypointTitle)
				--TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointTitle })
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
	-- print("~~~ Waypoint Creation Function: 726 ~~~")
	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

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
		RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, x, y, waypointText)
		--TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointText })
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
	-- print("~~~ Waypoint Creation Function: 797 ~~~")
	if RQE.db.profile.enableTravelSuggestions then
		if RQE.NearestFlightMasterSet then return end
	else
		RQE.NearestFlightMasterSet = false
	end

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
	--C_Map.ClearUserWaypoint()

	-- Create a new user waypoint
	local waypointData = {
		uiMapID = mapID,
		position = CreateVector2D(x / 100, y / 100),
		name = waypointText
	}
	--C_Map.SetUserWaypoint(waypointData)
	--C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	-- TomTom Integration (if enabled)
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		RQE._currentTomTomUID = RQE.Waypoints:Replace(mapID, x, y, waypointText)
		--TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = waypointText })
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
-- 4. Event Handlers
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

	-- print("~~~ Waypoint Set: 1111 ~~~")

	-- Always resolve the base title using our centralized logic
	-- local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	-- local title = RQE:GetWaypointTitle(questID, mapID, x, y)	
	local title = RQE:GetWaypointTitle(questID, mapID, x, y)
	-- local title = string.format('QID: %d, "%s"', questID, questName or "Unknown")
	if RQE.db.profile.debugLevel == "INFO+" then
		print("waypointTitle - 1113: " .. tostring(title))
	end

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
		local uid = RQE.Waypoints:Replace(mapID, x, y, title)
		-- local uid = TomTom:AddWaypoint(mapID, x, y, {
			-- title = title,
			-- from = "RQE",
			-- persistent = nil,
			-- minimap = true,
			-- world = true
		-- })

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


-- Force the waypoint for the currently super-tracked quest using the intended priority.
function RQE:ForceWaypointForSupertracked(qid, mapID)
	-- print("~~~ Waypoint Creation Function: 1137 ~~~")
	if not (C_SuperTrack.IsSuperTrackingQuest and C_SuperTrack.IsSuperTrackingQuest()) then return end
	qid   = qid   or C_SuperTrack.GetSuperTrackedQuestID()
	mapID = mapID or C_Map.GetBestMapForUnit("player")
	if not qid or not mapID then return end

	-- Clear any stale state so we never “stick” on the last quest
	RQE._currentHotspotIdx = nil
	RQE._lastWP = nil
	RQE.WPxPos, RQE.WPyPos, RQE.WPmapID = nil, nil, nil
	local _, ttLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if ttLoaded and RQE._currentTomTomUID and TomTom and TomTom.RemoveWaypoint then
		TomTom:RemoveWaypoint(RQE._currentTomTomUID)
		RQE._currentTomTomUID = nil
	end

	-- 1) If Blizzard supplies direction text, use the direction-text flow
	local dtxt = C_QuestLog.GetNextWaypointText(qid)
	if dtxt and dtxt ~= "" then
		return RQE:CreateUnknownQuestWaypointWithDirectionText(qid, mapID)
	end

	-- 2–3) Otherwise prefer DB step hotspots/coordinates
	local qd = RQE.getQuestData and RQE.getQuestData(qid)
	local step = qd and qd[RQE.AddonSetStepIndex or 1]

	if step and step.coordinateHotspots then
		-- Use your existing hotspot selector (falls back to single coords if needed)
		return RQE:EnsureWaypointForSupertracked()
	elseif step and step.coordinates and step.coordinates.x and step.coordinates.y and step.coordinates.mapID then
		return RQE:CreateWaypoint(step.coordinates.x, step.coordinates.y, step.coordinates.mapID)
	end

	-- 4) DB entry exists but no step lines → Blizzard fallback
	do
		local bx, by = C_QuestLog.GetNextWaypointForMap(qid, mapID)
		if bx and by then return RQE:CreateWaypoint(bx, by, mapID) end
		local gx, gy, gMap = C_QuestLog.GetNextWaypoint(qid)
		if gx and gy and gMap then return RQE:CreateWaypoint(gx, gy, gMap) end
	end

	-- 5) No DB and no Blizzard waypoint → nothing to do
end


-- Centralized function to decide what the waypoint title should be
function RQE:GetWaypointTitle(questID, mapID, xNorm, yNorm)
	-- print("~~ RQE:GetWaypointTitle running ~~")

	-- Build a sane default up-front
	local questData = questID and RQE.getQuestData(questID)
	local qname = (questID and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)) or (questData and questData.title) or "Waypoint"
	local defaultTitle = string.format('QID: %d, "%s"', questID or -1, qname)

	if not questData then return defaultTitle end

	local stepIndex = RQE.AddonSetStepIndex or 1
	local step = questData[stepIndex]

	-- 1) Direction text has top priority
	if step and step.directionText and step.directionText ~= "" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~~~ wayText fix: 1224 ~~~~")
		end
		return string.format("QID %d — %s — %s", questID, questData.title or "Quest", step.directionText)
	end

	-- 1a) Use the *currently selected* hotspot index → robust, no float compare needed
	--	 (EnsureWaypointForSupertracked sets RQE._currentHotspotIdx right before calling us)
	if step and step.coordinateHotspots and RQE._currentHotspotIdx then
		local norm = RQE.WPUtil.NormalizeCoordinates(step)
		local cur  = norm and norm.hotspots and norm.hotspots[RQE._currentHotspotIdx]
		if cur and cur.__authorIndex and step.coordinateHotspots[cur.__authorIndex] then
			local hOrig = step.coordinateHotspots[cur.__authorIndex]
			if hOrig.wayText and hOrig.wayText ~= "" then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("~~~~ wayText fix: 1247 (via currentIdx) ~~~~")
				end
				if RQE.db.profile.debugLevel == "INFO+" then
					print("waypointTitle - 1250: " .. tostring(hOrig.wayText))
				end
				return hOrig.wayText
			end
		end
	end

	-- 2) Match coordinateHotspots and use wayText (fallback if no currentIdx or no wayText on that hotspot)
	if step and step.coordinateHotspots and xNorm and yNorm then
		for _, hotspot in ipairs(step.coordinateHotspots) do
			local hx = (hotspot.x > 1) and (hotspot.x / 100) or hotspot.x
			local hy = (hotspot.y > 1) and (hotspot.y / 100) or hotspot.y
			-- Slightly looser epsilon to avoid float drift
			if hotspot.mapID == mapID
			   and math.abs(hx - xNorm) < 5e-4
			   and math.abs(hy - yNorm) < 5e-4
			   and hotspot.wayText
			   and hotspot.wayText ~= "" then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("~~~~ wayText fix: 1221 (via coord match) ~~~~")
				end
				return hotspot.wayText
			end
		end
	end

	-- 3) Blizzard fallback (if available)
	local blizzText = C_QuestLog.GetNextWaypointText and C_QuestLog.GetNextWaypointText(questID)
	if blizzText and blizzText ~= "" then
		if RQE.db.profile.debugLevel == "INFO+" then
			print("~~~~ wayText fix: 1263 ~~~~")
		end
		return string.format("QID %d — %s — %s", questID, questData.title or "Quest", blizzText)
	end

	-- 4) Default to quest title with QID
	local questName = (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)) or (questData and questData.title) or "Unknown"
	return defaultTitle or string.format('QID: %d, "%s"', questID, questName)
end



--------------------------
-- 5. Finalization
--------------------------

-- Final steps and exporting functions for use in other files