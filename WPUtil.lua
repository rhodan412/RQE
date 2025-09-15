--[[ 

WPUtil.lua
This add-on file may be used to either store, or call coordinate information from the RQEDatabase file for the purposes of modularity/compartmentalization

]]


--------------------------
-- 1. Declarations
--------------------------

RQE = RQE or {}
RQE.Frame = RQE.Frame or {}
RQE.WPUtil = RQE.WPUtil or {}
RQE.WPUtil._hotspotState = RQE.WPUtil._hotspotState or {}

RQE.posX = nil
RQE.posY = nil


------------------------------------
-- 2. coordinateHotspot Defaults
------------------------------------

-- Soft defaults; can be overridden per step or hotspot
RQE.WPUtil.defaults = RQE.WPUtil.defaults or {
  yardMode           = true,   -- prefer yard deltas if helpers exist
  minSwitchYards     = 20,     -- how much closer (yards) to switch targets
  visitedRadius      = 80,     -- within this many yards => mark band visited
  movementDeltaYards = 8,      -- re-evaluate only if moved at least this much
  evalThrottleSec    = 0.25,   -- evaluate at most 4x/sec
}


---------------------------
-- 3. Debug Logic
---------------------------

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end


-------------------------------
-- 4. Waypoint Logic (Single)
-------------------------------

-- Assume IsWorldMapOpen() returns true if the world map is open, false otherwise
-- Assume CloseWorldMap() closes the world map
RQE.UnknownQuestButtonCalcNTrack = function()
	RQE.UnknownQuestButton:SetScript("OnClick", function()
		if RQE.searchedQuestID then 
			local questID = RQE.searchedQuestID
			if questID then
				local dbEntry = RQE.getQuestData(questID)
				if dbEntry and dbEntry.location then
					local mapID = tonumber(dbEntry.location.mapID)
					if mapID then
						if RQE.db.profile.debugLevel == "INFO+" then
							print("Calling CreateSearchedQuestWaypoint with:", questID, mapID)
						end
						RQE:CreateSearchedQuestWaypoint(questID, mapID)
						return
					end
				end
			end			
		end

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
	local questID = C_SuperTrack.GetSuperTrackedQuestID()

	-- NEW: prefer multi-hotspot selection if present on the step
	local questData = RQE.getQuestData(questID)
	local step = questData and questData[stepIndex]
	if step and (step.coordinateHotspots or (step.coordinates and step.coordinates[1] and type(step.coordinates[1])=="table")) then
		local smap, sx, sy = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
		if smap and sx and sy then
			x, y, mapID = sx, sy, smap
			if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
				print(("Hotspots selected for step %d: map=%s x=%.4f y=%.4f"):format(stepIndex, tostring(mapID), x, y))
			end
		end
	end

	-- Legacy single-point path (your original behavior), only if no hotspot was used
	if not x then
		if step and step.coordinates and step.coordinates.x and step.coordinates.y and step.coordinates.mapID then
			x = step.coordinates.x / 100
			y = step.coordinates.y / 100
			mapID = step.coordinates.mapID
			if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
				print("Using coordinates from RQEDatabase for stepIndex:", stepIndex)
			end
		else
			-- (everything below is exactly your existing fallback chain)
			if RQE.WPxPos and C_QuestLog.IsOnQuest(questID) then
				x = RQE.WPxPos; y = RQE.WPyPos; mapID = RQE.WPmapID
				if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
					print("Using coordinates from RQE.WPxyPos for questID:", questID)
				end
			elseif RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) then
				x = RQE.DatabaseSuperX; y = RQE.DatabaseSuperY; mapID = RQE.DatabaseSuperMapID
				if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
					print("Using coordinates from DatabaseSuper for questID:", questID)
				end
			elseif (not RQE.DatabaseSuperX and RQE.DatabaseSuperY) or (not RQE.superX or not RQE.superY and RQE.superMapID) then
				x, y, mapID = RQE.GetQuestCoordinates(questID)
				if not (x and y and mapID) then
					mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
					if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
						print("Fallback to GetNextWaypoint for coordinates for questID:", questID)
					end
				else
					if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
						print("Using coordinates from GetQuestCoordinates for questID:", questID)
					end
				end
			else
				x = RQE.superX; y = RQE.superY; mapID = RQE.superMapID
				if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
					print("Using coordinates from super tracking for questID:", questID)
				end
			end
		end
	end

	-- Save for waypoint
	RQE.WPxPos = x; RQE.WPyPos = y; RQE.WPmapID = mapID

	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		print("Final waypoint coordinates - X:", RQE.WPxPos, "Y:", RQE.WPyPos, "MapID:", RQE.WPmapID)
	end

	return x, y, mapID
end


-- -- Function to get coordinates for the current stepIndex
-- function RQE:GetStepCoordinates(stepIndex)
	-- local stepIndex = RQE.AddonSetStepIndex or 1
	-- local x, y, mapID
	-- local questID = C_SuperTrack.GetSuperTrackedQuestID()  -- Fetching the current QuestID

	-- -- Fetch the coordinates directly from the step data
	-- local questData = RQE.getQuestData(questID)
	-- if questData and questData[stepIndex] and questData[stepIndex].coordinates then
		-- x = questData[stepIndex].coordinates.x / 100
		-- y = questData[stepIndex].coordinates.y / 100
		-- mapID = questData[stepIndex].coordinates.mapID
		-- if RQE.db.profile.debugLevel == "INFO+" then
			-- print("Using coordinates from RQEDatabase for stepIndex:", stepIndex)
		-- end
	-- else
		-- if RQE.WPxPos and C_QuestLog.IsOnQuest(questID) then
			-- -- If coordinates are available from DatabaseSuper, use them
			-- x = RQE.WPxPos
			-- y = RQE.WPyPos
			-- mapID = RQE.WPmapID
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Using coordinates from RQE.WPxyPos for questID:", questID)
			-- end
		-- elseif RQE.DatabaseSuperX and not C_QuestLog.IsOnQuest(questID) then
			-- -- If coordinates are available from DatabaseSuper, use them
			-- x = RQE.DatabaseSuperX
			-- y = RQE.DatabaseSuperY
			-- mapID = RQE.DatabaseSuperMapID
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Using coordinates from DatabaseSuper for questID:", questID)
			-- end
		-- elseif (not RQE.DatabaseSuperX and RQE.DatabaseSuperY) or (not RQE.superX or not RQE.superY and RQE.superMapID) then
			-- -- Open the quest log details for the super tracked quest to fetch the coordinates
			-- --OpenQuestLogToQuestDetails(questID)

			-- -- Use RQE.GetQuestCoordinates to get the coordinates
			-- x, y, mapID = RQE.GetQuestCoordinates(questID)
			-- if not (x and y and mapID) then
				-- -- Fallback to using C_QuestLog.GetNextWaypoint if coordinates are not available
				-- mapID, x, y = C_QuestLog.GetNextWaypoint(questID)
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("Fallback to GetNextWaypoint for coordinates for questID:", questID)
				-- end
			-- else
				-- if RQE.db.profile.debugLevel == "INFO+" then
					-- print("Using coordinates from GetQuestCoordinates for questID:", questID)
				-- end
			-- end
		-- else
			-- -- If coordinates are available from super tracking, use them
			-- x = RQE.superX
			-- y = RQE.superY
			-- mapID = RQE.superMapID
			-- if RQE.db.profile.debugLevel == "INFO+" then
				-- print("Using coordinates from super tracking for questID:", questID)
			-- end
		-- end
	-- end

	-- -- Save the final coordinates to be used for the waypoint
	-- RQE.WPxPos = x
	-- RQE.WPyPos = y
	-- RQE.WPmapID = mapID

	-- -- Debug print the final coordinates and the method used
	-- if RQE.db.profile.debugLevel == "INFO+" then
		-- print("Final waypoint coordinates - X:", RQE.WPxPos, "Y:", RQE.WPyPos, "MapID:", RQE.WPmapID)
	-- end

	-- return x, y, mapID
-- end


------------------------------
-- 5. Waypoint Logic (Multi)
------------------------------

-- If you expose user options somewhere (RQE.db / RQE.Config), lookup here
local function _getDefault(k)
	-- Example: prefer config if present (safe-guarded)
	local cfg = RQE.Config and RQE.Config.Hotspots
	if cfg and cfg[k] ~= nil then return cfg[k] end
	return (RQE.WPUtil.defaults and RQE.WPUtil.defaults[k]) or nil
end


-- Optional helpers: we try to use your yard math if available, else fall back
local function _playerMapAndXY()
	if RQE.WPUtil.GetPlayerMapAndXY then
		return RQE.WPUtil.GetPlayerMapAndXY()
	end
	-- Fallback: use retail API if available; returns mapID, x, y (normalized)
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not mapID then return nil end
	local pos = C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return mapID, nil, nil end
	return mapID, pos.x, pos.y
end


-- Return squared delta in yards if RQE.WPUtil.DeltaYards exists and map matches.
-- Else return nil (we'll gracefully handle cross-map / no-yard scenarios).
local function _playerDistanceSqYards(mapID, x, y)
	local pmid, px, py = _playerMapAndXY()
	if not pmid or pmid ~= mapID or not px or not py then return nil, pmid, px, py end
	if RQE.WPUtil.DeltaYards then
		local dx, dy = RQE.WPUtil.DeltaYards(mapID, px, py, x, y)
		if dx and dy then return (dx*dx + dy*dy), pmid, px, py end
	end
	-- No yard helper available → we can’t produce yards here
	return nil, pmid, px, py
end


-- Normalize either:
--   step.coordinates = { x=.., y=.., mapID=.. }             (legacy)
--   step.coordinates = { {..}, {..}, ... }                   (multi, if you ever store it here)
--   step.coordinateHotspots = { {..}, {..}, ... }           (preferred multi key)
function RQE.WPUtil.NormalizeCoordinates(step)
	if not step then return nil end
	local raw = step.coordinateHotspots or step.coordinates
	if not raw then return nil end

	-- Resolve step-level defaults
	local yardMode = (step.yardMode ~= nil) and step.yardMode or _getDefault("yardMode")
	local stepMinSwitchYards = tonumber(step.minSwitchYards) or _getDefault("minSwitchYards") or 20
	local stepVisitedRadius  = tonumber(step.visitedRadius)  or _getDefault("visitedRadius")  or 80

	local hotspots = {}
	local isArray = (type(raw) == "table" and raw[1] ~= nil and type(raw[1]) == "table")

	if (not isArray) and type(raw) == "table" and raw.x then
		-- Legacy: one point; DB x/y are likely 0-100 style → normalize to 0-1 here
		table.insert(hotspots, {
			x = tonumber(raw.x) and (tonumber(raw.x) / 100) or nil,
			y = tonumber(raw.y) and (tonumber(raw.y) / 100) or nil,
			mapID = raw.mapID,
			priority       = tonumber(raw.priorityBias) or 1,
			minSwitchYards = tonumber(raw.minSwitchYards) or stepMinSwitchYards,
			visitedRadius  = tonumber(raw.visitedRadius)  or stepVisitedRadius,
			__authorIndex  = 1,
		})
	else
		-- Multi: accept values as in DB; convert x/y from 0-100 to 0-1 for waypoints
		for i,pt in ipairs(raw) do
			table.insert(hotspots, {
				x = tonumber(pt.x) and (tonumber(pt.x) / 100) or nil,
				y = tonumber(pt.y) and (tonumber(pt.y) / 100) or nil,
				mapID = pt.mapID,
				priority       = tonumber(pt.priorityBias) or 1,
				minSwitchYards = tonumber(pt.minSwitchYards) or stepMinSwitchYards,
				visitedRadius  = tonumber(pt.visitedRadius)  or stepVisitedRadius,
				__authorIndex  = i,
			})
		end
	end

	-- Sort by (priority asc, authoring order)
	table.sort(hotspots, function(a,b)
		if a.priority ~= b.priority then return a.priority < b.priority end
		return a.__authorIndex < b.__authorIndex
	end)

	-- Collect bands (priorities)
	local bandSet, bands, maps = {}, {}, {}
	for _,h in ipairs(hotspots) do
		if h.priority then bandSet[h.priority] = true end
		if h.mapID then maps[h.mapID] = true end
	end
	for p,_ in pairs(bandSet) do table.insert(bands, p) end
	table.sort(bands)

	return {
		hotspots = hotspots,
		defaults = {
			yardMode            = yardMode and true or false,
			minSwitchYards      = stepMinSwitchYards,
			visitedRadius       = stepVisitedRadius,
			movementDeltaYards  = _getDefault("movementDeltaYards") or 8,
			evalThrottleSec     = _getDefault("evalThrottleSec") or 0.25,
		},
		priorityBands = bands,
		maps = maps,
	}
end


-- Internal per-step state
local function _stateFor(questID, stepIndex)
	RQE.WPUtil._hotspotState[questID] = RQE.WPUtil._hotspotState[questID] or {}
	local st = RQE.WPUtil._hotspotState[questID][stepIndex]
	if not st then
		st = {
			visitedBands = {},  -- [priority] = true once visited
			currentIdx   = nil, -- index into normalized hotspot list
			lastEval     = { t=0, mapID=nil, px=nil, py=nil },
		}
		RQE.WPUtil._hotspotState[questID][stepIndex] = st
	end
	return st
end


-- Mark current target band as visited if inside its visitedRadius
local function _updateVisitedBands(st, norm)
	if not st.currentIdx then return end
	local h = norm.hotspots[st.currentIdx]; if not h then return end
	local d2 = _playerDistanceSqYards(h.mapID, h.x, h.y)
	if not d2 then return end
	local r = h.visitedRadius or norm.defaults.visitedRadius
	if r and (d2 <= (r*r)) then
		st.visitedBands[h.priority] = true
	end
end


-- Which bands are eligible now?
local function _eligibleBands(st, bands)
	local eligible = {}
	if #bands == 0 then return eligible end
	-- Lowest band is always eligible; unlock consecutive bands once previous visited
	local unlock = true
	for _,p in ipairs(bands) do
		if unlock then eligible[p] = true end
		if not st.visitedBands[p] then unlock = false end
	end
	-- already-visited higher bands always remain eligible
	for p,_ in pairs(st.visitedBands) do eligible[p] = true end
	return eligible
end


-- Decide the best hotspot for a quest/step, honoring bands + yard delta switching
-- Returns: mapID, x (0-1), y (0-1), chosenIndex
function RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
	local norm = RQE.WPUtil.NormalizeCoordinates(step)
	if not norm or not norm.hotspots or #norm.hotspots == 0 then return nil end
	local st = _stateFor(questID, stepIndex)

	-- Throttle by time + movement (only if we can measure movement in yards)
	local now = GetTime and GetTime() or 0
	local throttled = (now - (st.lastEval.t or 0)) < norm.defaults.evalThrottleSec
	local movedFar = true
	do
		local pmid, px, py = _playerMapAndXY()
		local last = st.lastEval
		if throttled and pmid and last.mapID == pmid and last.px and last.py and px and py and RQE.WPUtil.DeltaYards then
			local dx, dy = RQE.WPUtil.DeltaYards(pmid, last.px, last.py, px, py)
			if dx and dy then
				local moved = math.sqrt(dx*dx + dy*dy)
				movedFar = moved >= norm.defaults.movementDeltaYards
			end
		end
	end
	if throttled and not movedFar and st.currentIdx then
		local c = norm.hotspots[st.currentIdx]
		return c.mapID, c.x, c.y, st.currentIdx
	end

	-- Update visited bands based on proximity to current target
	_updateVisitedBands(st, norm)

	local eligibleBands = _eligibleBands(st, norm.priorityBands)
	local curIdx = st.currentIdx
	local curD2 = nil
	if curIdx then
		local cur = norm.hotspots[curIdx]
		curD2 = cur and _playerDistanceSqYards(cur.mapID, cur.x, cur.y) or nil
	end

	-- If we don't currently have a target, strongly prefer a same-map hotspot.
	-- This avoids cross-map ambiguity when yard math isn't available.
	if not st.currentIdx then
		local pmid = select(1, _playerMapAndXY())
		if pmid then
			for idx, h in ipairs(norm.hotspots) do
				if h.mapID == pmid and eligibleBands[h.priority] then
					-- choose the first eligible on the current map (respects priority+author order)
					st.currentIdx = idx
					local c = norm.hotspots[idx]
					local now = GetTime and GetTime() or 0
					local _, px, py = _playerMapAndXY()
					st.lastEval.t, st.lastEval.mapID, st.lastEval.px, st.lastEval.py = now, pmid, px, py
					return c.mapID, c.x, c.y, idx
				end
			end
		end
	end

	-- Scan for best candidate
	local bestIdx, bestD2, bestBand
	for idx, h in ipairs(norm.hotspots) do
		if eligibleBands[h.priority] then
			local d2 = _playerDistanceSqYards(h.mapID, h.x, h.y)
			if d2 then
				if not bestD2 or d2 < bestD2 or (d2 == bestD2 and (h.priority < bestBand or (h.priority == bestBand and h.__authorIndex < norm.hotspots[bestIdx].__authorIndex))) then
					bestIdx, bestD2, bestBand = idx, d2, h.priority
				end
			else
				-- Cross-map: if no current target and nothing else measurable yet, prefer first eligible by author order
				if not curIdx and not bestIdx then
					bestIdx, bestBand = idx, h.priority
				end
			end
		end
	end

	-- Decide whether to switch
	local chosenIdx = curIdx
	if not chosenIdx then
		chosenIdx = bestIdx
	else
		local switch = false
		if bestIdx and bestD2 and curD2 then
			local yardDelta = math.sqrt(curD2) - math.sqrt(bestD2)
			local need = norm.hotspots[bestIdx].minSwitchYards or norm.defaults.minSwitchYards
			if yardDelta >= (need or 0) then switch = true end
		elseif bestIdx and bestD2 and not curD2 then
			-- current is cross-map, candidate is on our map
			switch = true
		elseif bestIdx and not bestD2 and not curD2 then
			-- both cross-map: prefer lower band, then author order (already reflected in bestIdx)
			if norm.hotspots[bestIdx].priority < norm.hotspots[curIdx].priority then switch = true end
		end
		if switch then chosenIdx = bestIdx end
	end

	-- Persist & return
	if chosenIdx then
		local pmid, px, py = _playerMapAndXY()
		st.currentIdx = chosenIdx
		st.lastEval.t, st.lastEval.mapID, st.lastEval.px, st.lastEval.py = now, pmid, px, py
		local c = norm.hotspots[chosenIdx]
		return c.mapID, c.x, c.y, chosenIdx
	end

	return nil
end


-- Helper function to clear sticky state on zone/login change
function RQE.WPUtil.ClearHotspotState(questID, stepIndex)
	if questID and stepIndex then
		if RQE.WPUtil._hotspotState[questID] then
			RQE.WPUtil._hotspotState[questID][stepIndex] = nil
		end
	else
		RQE.WPUtil._hotspotState = {}
	end
end