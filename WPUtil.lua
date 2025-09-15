--[[ 

WPUtil.lua
This add-on file may be used to either store, or call coordinate information from the RQEDatabase file for the purposes of modularity/compartmentalization

]]


--------------------------
-- 1. Declarations
--------------------------

RQE = RQE or {}
RQE.Frame = RQE.Frame or {}
RQE.Waypoints = RQE.Waypoints or {}

RQE.WPUtil = RQE.WPUtil or {}
RQE.WPUtil._hotspotState = RQE.WPUtil._hotspotState or {}
RQE._snapState = RQE._snapState or { lastX=nil, lastY=nil, lastMap=nil, lastIdx=nil, acc=0 }

RQE.posX = nil
RQE.posY = nil


------------------------------------
-- 2. coordinateHotspot Defaults
------------------------------------

-- Soft defaults; can be overridden per step or hotspot
RQE.WPUtil.defaults = RQE.WPUtil.defaults or {
	yardMode = true,		-- prefer yard deltas if helpers exist
	minSwitchYards = 20,	 -- how much closer (yards) to switch targets
	visitedRadius = 80,	 	-- within this many yards => mark band visited
	movementDeltaYards = 8,		-- re-evaluate only if moved at least this much
	evalThrottleSec	= 0.25,		-- evaluate at most 4x/sec
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

		local superQuest = C_SuperTrack.GetSuperTrackedQuestID()	-- Fetching the current QuestID
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
	-- local questID = C_SuperTrack.GetSuperTrackedQuestID()	-- Fetching the current QuestID

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


-- Centralized replace helper for TomTom/Blizzard pins
function RQE.Waypoints:Replace(mapID, xNorm, yNorm, title)
	-- Normalize safety: require numbers in 0–1
	if not (mapID and xNorm and yNorm) then return end
	if xNorm > 1 or yNorm > 1 then
		-- If percent slipped through, normalize
		xNorm, yNorm = xNorm / 100, yNorm / 100
	end

	-- Remove previous TomTom waypoint (if any)
	local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
		if RQE._currentTomTomUID and TomTom and TomTom.RemoveWaypoint then
			TomTom:RemoveWaypoint(RQE._currentTomTomUID)
			RQE._currentTomTomUID = nil
		elseif RQE._currentTomTomUID and TomTom and TomTom.ClearWaypoint then
			-- older TomTom fallback
			TomTom:ClearWaypoint(nil, RQE._currentTomTomUID)
			RQE._currentTomTomUID = nil
		end
	end

	-- Clear Blizzard user pin (keeps the in-game map nice & tidy)
	if C_Map and C_Map.ClearUserWaypoint then
		C_Map.ClearUserWaypoint()
	end

	local uid

	-- Add TomTom waypoint
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility and TomTom and TomTom.AddWaypoint then
		TomTom.waydb:ResetProfile()
		local uid = TomTom:AddWaypoint(mapID, xNorm, yNorm, { title = title, from = "RQE", minimap = true, world = true })
		RQE._currentTomTomUID = uid
	end

	-- -- Optionally show a Blizzard user pin (comment this block out if you don’t want it)
	-- if C_Map and UiMapPoint and C_Map.SetUserWaypoint then
		-- local point = UiMapPoint.CreateFromCoordinates(mapID, xNorm, yNorm)
		-- C_Map.SetUserWaypoint(point)
	-- end
	return uid
end


-- Ensures the arrow points at the *current* chosen hotspot; switches only if the chosen index changed
function RQE:EnsureWaypointForSupertracked()
	if not (C_SuperTrack.IsSuperTrackingQuest and C_SuperTrack.IsSuperTrackingQuest()) then return end
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then return end

	local stepIndex = RQE.AddonSetStepIndex or 1
	local questData = RQE.getQuestData and RQE.getQuestData(questID)
	local step = questData and questData[stepIndex]
	if not step then return end

	-- Ask selector which hotspot is “best” *right now*
	local mapID, xNorm, yNorm, idx = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
	if not (mapID and xNorm and yNorm and idx) then
		-- fallback to legacy single coords
		if step.coordinates and step.coordinates.x and step.coordinates.y and step.coordinates.mapID then
			mapID = step.coordinates.mapID
			xNorm, yNorm = step.coordinates.x / 100, step.coordinates.y / 100
			idx = 0
		else
			return
		end
	end

	-- Don’t touch the waypoint if we’re still targeting the same hotspot
	if RQE._currentHotspotIdx == idx and RQE._lastWP and
	   RQE._lastWP.mapID == mapID and
	   math.abs(RQE._lastWP.x - xNorm) < 1e-4 and
	   math.abs(RQE._lastWP.y - yNorm) < 1e-4 then
		return
	end

	-- Switch: replace the live waypoint
	RQE._currentHotspotIdx = idx
	RQE:CreateWaypoint(xNorm, yNorm, mapID, nil)
end


-- Normalize either:
--	step.coordinates = { x=.., y=.., mapID=.. } (legacy)
--	step.coordinates = { {..}, {..}, ... } 		(multi, if you ever store it here)
--	step.coordinateHotspots = { {..}, {..}, ... } 	(preferred multi key)
function RQE.WPUtil.NormalizeCoordinates(step)
	if not step then return nil end
	local raw = step.coordinateHotspots or step.coordinates
	if not raw then return nil end

	-- Resolve step-level defaults
	local yardMode = (step.yardMode ~= nil) and step.yardMode or _getDefault("yardMode")
	local stepMinSwitchYards = tonumber(step.minSwitchYards) or _getDefault("minSwitchYards") or 20
	local stepVisitedRadius	= tonumber(step.visitedRadius) or _getDefault("visitedRadius") or 80

	local hotspots = {}
	local isArray = (type(raw) == "table" and raw[1] ~= nil and type(raw[1]) == "table")

	if (not isArray) and type(raw) == "table" and raw.x then
		-- Legacy: one point; DB x/y are likely 0-100 style → normalize to 0-1 here
		table.insert(hotspots, {
			x = tonumber(raw.x) and (tonumber(raw.x) / 100) or nil,
			y = tonumber(raw.y) and (tonumber(raw.y) / 100) or nil,
			mapID = raw.mapID,
			priority = tonumber(raw.priorityBias) or 1,
			minSwitchYards = tonumber(raw.minSwitchYards) or stepMinSwitchYards,
			visitedRadius = tonumber(raw.visitedRadius) or stepVisitedRadius,
			__authorIndex = 1,
		})
	else
		-- Multi: accept values as in DB; convert x/y from 0-100 to 0-1 for waypoints
		for i,pt in ipairs(raw) do
			table.insert(hotspots, {
				x = tonumber(pt.x) and (tonumber(pt.x) / 100) or nil,
				y = tonumber(pt.y) and (tonumber(pt.y) / 100) or nil,
				mapID = pt.mapID,
				priority = tonumber(pt.priorityBias) or 1,
				minSwitchYards = tonumber(pt.minSwitchYards) or stepMinSwitchYards,
				visitedRadius = tonumber(pt.visitedRadius) or stepVisitedRadius,
				__authorIndex = i,
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
			yardMode = yardMode and true or false,
			minSwitchYards = stepMinSwitchYards,
			visitedRadius = stepVisitedRadius,
			movementDeltaYards = _getDefault("movementDeltaYards") or 8,
			evalThrottleSec = _getDefault("evalThrottleSec") or 0.25,
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
			visitedBands = {},	-- [priority] = true once visited
			currentIdx = nil, -- index into normalized hotspot list
			lastEval = { t=0, mapID=nil, px=nil, py=nil },
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


-- Returns squared distance and a unit tag: "yards" or "norm"
local function _playerDistanceSqFlexible(hmap, hx, hy)
	local pmid, px, py = _playerMapAndXY()
	if not pmid or not px or not py then return nil end

	-- Same-map: always computable in normalized space
	if pmid == hmap and px and py and hx and hy then
		local dx, dy = px - hx, py - hy
		return dx*dx + dy*dy, "norm"
	end

	-- Cross-map: try yard math if available
	if RQE.WPUtil and RQE.WPUtil.DeltaYards then
		local dx, dy = RQE.WPUtil.DeltaYards(hmap, hx, hy, px, py)
		if dx and dy then return dx*dx + dy*dy, "yards" end
	end

	return nil
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
		local pmid, px, py = _playerMapAndXY()
		if pmid and px and py then
			local bestIdx, bestD2
			for idx, h in ipairs(norm.hotspots) do
				if h.mapID == pmid and eligibleBands[h.priority] then
					local d2 = _playerDistanceSqFlexible(h.mapID, h.x, h.y)
						if d2 then
							if not bestD2 or d2 < bestD2 then
								bestIdx, bestD2 = idx, d2
							end
						else
							-- same-map but no distance? extremely unlikely; keep author order fallback
							if not bestIdx then bestIdx = idx end
						end
					end
				end
			if bestIdx then
				st.currentIdx = bestIdx
				local now = GetTime and GetTime() or 0
				st.lastEval.t, st.lastEval.mapID, st.lastEval.px, st.lastEval.py = now, pmid, px, py
				local c = norm.hotspots[bestIdx]
				return c.mapID, c.x, c.y, bestIdx
			end
		end
	end

	-- if not st.currentIdx then
		-- local pmid = select(1, _playerMapAndXY())
		-- if pmid then
			-- for idx, h in ipairs(norm.hotspots) do
				-- if h.mapID == pmid and eligibleBands[h.priority] then
					-- -- choose the first eligible on the current map (respects priority+author order)
					-- st.currentIdx = idx
					-- local c = norm.hotspots[idx]
					-- local now = GetTime and GetTime() or 0
					-- local _, px, py = _playerMapAndXY()
					-- st.lastEval.t, st.lastEval.mapID, st.lastEval.px, st.lastEval.py = now, pmid, px, py
					-- return c.mapID, c.x, c.y, idx
				-- end
			-- end
		-- end
	-- end

	-- Scan for best candidate
	local bestIdx, bestD2, bestBand, bestUnit
	for idx, h in ipairs(norm.hotspots) do
		if eligibleBands[h.priority] then
			local d2, unit = _playerDistanceSqFlexible(h.mapID, h.x, h.y)
			if d2 then
				if not bestD2 or d2 < bestD2 or (d2 == bestD2 and (h.priority < bestBand or (h.priority == bestBand and h.__authorIndex < norm.hotspots[bestIdx].__authorIndex))) then
					bestIdx, bestD2, bestBand, bestUnit = idx, d2, h.priority, unit
				end
			else
				-- Cross-map/unknown distance: keep author-order fallback only if nothing else measured yet
				if not curIdx and not bestIdx then
					bestIdx, bestBand = idx, h.priority
				end
			end
		end
	end

	-- -- Scan for best candidate
	-- local bestIdx, bestD2, bestBand
	-- for idx, h in ipairs(norm.hotspots) do
		-- if eligibleBands[h.priority] then
			-- local d2 = _playerDistanceSqYards(h.mapID, h.x, h.y)
			-- if d2 then
				-- if not bestD2 or d2 < bestD2 or (d2 == bestD2 and (h.priority < bestBand or (h.priority == bestBand and h.__authorIndex < norm.hotspots[bestIdx].__authorIndex))) then
					-- bestIdx, bestD2, bestBand = idx, d2, h.priority
				-- end
			-- else
				-- -- Cross-map: if no current target and nothing else measurable yet, prefer first eligible by author order
				-- if not curIdx and not bestIdx then
					-- bestIdx, bestBand = idx, h.priority
				-- end
			-- end
		-- end
	-- end

	-- Decide whether to switch
	local chosenIdx = curIdx
	if not chosenIdx then
		chosenIdx = bestIdx
	else
		local switch = false
		if bestIdx then
			local cur = norm.hotspots[curIdx]
			local curD2, curUnit = _playerDistanceSqFlexible(cur.mapID, cur.x, cur.y)

			if bestD2 and curD2 then
				if bestUnit == "yards" and curUnit == "yards" then
					local yardDelta = math.sqrt(curD2) - math.sqrt(bestD2)
					local need = (norm.hotspots[bestIdx].minSwitchYards or norm.defaults.minSwitchYards or 0)
					if yardDelta >= need then switch = true end
				else
					-- normalized fallback (same-map or no yard math): switch if clearly closer
					-- factor 0.85 ~= 15% closer; tweak if you want more/less hysteresis
					if bestD2 < (curD2 * 0.85) then switch = true end
				end
			elseif bestD2 and not curD2 then
				-- current is cross-map/unknown; candidate is measurable => switch
				switch = true
			elseif not bestD2 and not curD2 then
				-- both unknown: prefer lower band, then author order
				if norm.hotspots[bestIdx].priority < norm.hotspots[curIdx].priority then switch = true end
			end
		end
		if switch then chosenIdx = bestIdx end
	end

	-- -- Decide whether to switch
	-- local chosenIdx = curIdx
	-- if not chosenIdx then
		-- chosenIdx = bestIdx
	-- else
		-- local switch = false
		-- if bestIdx and bestD2 and curD2 then
			-- local yardDelta = math.sqrt(curD2) - math.sqrt(bestD2)
			-- local need = norm.hotspots[bestIdx].minSwitchYards or norm.defaults.minSwitchYards
			-- if yardDelta >= (need or 0) then switch = true end
		-- elseif bestIdx and bestD2 and not curD2 then
			-- -- current is cross-map, candidate is on our map
			-- switch = true
		-- elseif bestIdx and not bestD2 and not curD2 then
			-- -- both cross-map: prefer lower band, then author order (already reflected in bestIdx)
			-- if norm.hotspots[bestIdx].priority < norm.hotspots[curIdx].priority then switch = true end
		-- end
		-- if switch then chosenIdx = bestIdx end
	-- end

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


function RQE:MaybeUpdateWaypointOnSnap(elapsed)
	-- throttle the reevaluation (adjust to taste)
	local ss = RQE._snapState
	ss.acc = (ss.acc or 0) + (elapsed or 0)
	if ss.acc < 0.15 then return end
	ss.acc = 0

	-- must have a super-tracked quest and a current step
	if not C_SuperTrack.IsSuperTrackingQuest() then return end
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then return end
	local stepIndex = RQE.AddonSetStepIndex or 1

	-- figure out current best coords (normalized 0–1) + chosen hotspot index when applicable
	local xNorm, yNorm, mapID, chosenIdx
	do
		local questData = RQE.getQuestData(questID)
		local step = questData and questData[stepIndex]
		if step and step.coordinateHotspots and RQE.WPUtil and RQE.WPUtil.SelectBestHotspot then
			local smap, sx, sy, sidx = RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step)
			if smap and sx and sy then
				xNorm, yNorm, mapID, chosenIdx = sx, sy, smap, sidx
			end
		else
			-- legacy/single or general fallback
			if RQE.GetStepCoordinates then
				local sx, sy, smap = RQE:GetStepCoordinates(stepIndex)
				if sx and sy and smap then
					xNorm, yNorm, mapID = sx, sy, smap
				end
			end
		end
	end

	if not (xNorm and yNorm and mapID) then return end

	-- snapped integer percents (e.g., 42.72 → 42)
	local snapX = math.floor(xNorm * 100 + 0.0001)
	local snapY = math.floor(yNorm * 100 + 0.0001)

	-- only proceed if something *meaningful* changed
	if ss.lastMap == mapID and ss.lastX == snapX and ss.lastY == snapY and ss.lastIdx == chosenIdx then
		return
	end

	-- update stash (normalized)
	RQE.WPxPos, RQE.WPyPos, RQE.WPmapID = xNorm, yNorm, mapID

	-- build a title (reuse your typical format)
	local questName = C_QuestLog.GetTitleForQuestID(questID) or "Unknown"
	local title = string.format('QID: %d, "%s"', questID, questName)

	-- CreateWaypoint expects 0–100 values, so multiply
	if RQE.CreateWaypoint then
		RQE:CreateWaypoint(snapX, snapY, mapID, title)
	elseif TomTom and TomTom.AddWaypoint then
		TomTom:AddWaypoint(mapID, xNorm, yNorm, { title = title })
	end

	-- remember last
	ss.lastMap, ss.lastX, ss.lastY, ss.lastIdx = mapID, snapX, snapY, chosenIdx

	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		print(string.format("Snap update → map:%d x:%d y:%d idx:%s", mapID, snapX, snapY, tostring(chosenIdx)))
	end
end