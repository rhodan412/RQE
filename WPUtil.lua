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

local HBD = LibStub and LibStub("HereBeDragons-2.0", true)


-- Forward declarations for locals referenced before their definitions
local _playerDistanceSqFlexible
local _dbgEligibleBands
local _dbgMarkVisited


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


-- Pretty line for a hotspot (idx + key fields)
local function _fmtHotspot(idx, h)
	return string.format(
		"#%d p=%d map=%s (%.2f, %.2f) minSwitch=%s visitR=%s",
		idx,
		tonumber(h.priority) or -1,
		tostring(h.mapID),
		(h.x or 0) * 100, (h.y or 0) * 100,
		tostring(h.minSwitchYards or "nil"),
		tostring(h.visitedRadius or "nil")
	)
end


-- Debug print tool to show where in band ladder player is (with distances)
-- /run RQE.WPUtil.DebugDumpBands(C_SuperTrack.GetSuperTrackedQuestID(), RQE.AddonSetStepIndex or 1)
function RQE.WPUtil.DebugDumpBands(questID, stepIndex)
	local st = RQE.WPUtil._hotspotState[questID] and RQE.WPUtil._hotspotState[questID][stepIndex]
	local step = RQE.getQuestData(questID) and RQE.getQuestData(questID)[stepIndex]
	local norm = step and RQE.WPUtil.NormalizeCoordinates(step)
	if not norm or not norm.hotspots or #norm.hotspots == 0 then print("No hotspots.") return end

	-- Build band → { minD2, unit } and figure target band with current visited set
	local byBand = {}
	for _,h in ipairs(norm.hotspots) do
		local d2, unit = _playerDistanceSqFlexible(h.mapID, h.x, h.y)
		if d2 then
			local b = byBand[h.priority]
			if not b or d2 < b.minD2 then byBand[h.priority] = { minD2 = d2, unit = unit } end
		end
	end

	local visited = (st and st.visited) or {}
	local target
	for _,p in ipairs(norm.priorityBands) do
		if not visited[p] then target = p; break end
	end
	if not target then target = norm.priorityBands[#norm.priorityBands] end

	-- Compose line
	local parts = {}
	for _,p in ipairs(norm.priorityBands) do
		local tag = (p == target) and "[TARGET]" or (visited[p] and "[VISITED]" or "[LOCKED]")
		local b = byBand[p]
		local dist = b and (b.unit == "yards" and string.format(" d=%.0fyd", math.sqrt(b.minD2))
			or string.format(" d~=%.1f%%", math.sqrt(b.minD2)*100)) or ""
		table.insert(parts, string.format("p=%d%s%s", p, tag, dist))
	end
	print(string.format("|cff00ffffRQE(INFO)|r Q%d S%d bands => %s",
		tonumber(questID) or -1, tonumber(stepIndex) or -1, table.concat(parts, "  ")))
end


-- Emit once when a band becomes visited
function _dbgMarkVisited(questID, stepIndex, p, idx, h)
	if not (RQE and RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+") then return end
	print(string.format(
		"|cff00ffffRQE(INFO)|r Q%d S%d visited band p=%d via hotspot %s",
		tonumber(questID) or -1, tonumber(stepIndex) or -1, tonumber(p) or -1, _fmtHotspot(idx, h)
	))
end


-- Dump current eligible/locked bands (called only when target band changes)
function _dbgEligibleBands(questID, stepIndex, priorityBands, visitedSet, targetBand)
	if not (RQE and RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+") then return end
	local parts = {}
	for p,_ in pairs(priorityBands) do
		local v = visitedSet and visitedSet[p]
		local tag = (p == targetBand) and "[TARGET]" or (v and "[VISITED]" or "[LOCKED]")
		table.insert(parts, string.format("p=%d%s", p, tag))
	end
	table.sort(parts) -- stable-ish print
	print(string.format(
		"|cff00ffffRQE(INFO)|r Q%d S%d bands => %s",
		tonumber(questID) or -1, tonumber(stepIndex) or -1, table.concat(parts, "  ")
	))
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
	if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility and TomTom then
		if TomTom.waydb and TomTom.waydb.ResetProfile then
			TomTom.waydb:ResetProfile()
		end

		if TomTom.AddWaypoint then
			uid = TomTom:AddWaypoint(mapID, xNorm, yNorm, { title = title, from = "RQE", minimap = true, world = true })
			RQE._currentTomTomUID = uid
		end
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
-- step.coordinates = { x=.., y=.., mapID=.. } (legacy)
-- step.coordinates = { {..}, {..}, ... } 		(multi, if you ever store it here)
-- step.coordinateHotspots = { {..}, {..}, ... } 	(preferred multi key)
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
			-- visitedBands = {},	-- [priority] = true once visited
			-- currentIdx = nil, -- index into normalized hotspot list
			-- lastEval = { t=0, mapID=nil, px=nil, py=nil },
			visited = {},			 -- p=>true after visit (your new table name)
			currentIdx = nil,
			lastEval = { t=0, mapID=nil, px=nil, py=nil },
			questID = questID,		-- << add
			stepIndex = stepIndex,	-- << add
			_lastTargetBand = nil,	-- << for debug change detection
		}
		RQE.WPUtil._hotspotState[questID][stepIndex] = st
	end
	return st
end


-- Yard math via HereBeDragons (if present)
-- Tries to resolve HBD once and cache it.
local function _getHBD()
	if RQE._HBD ~= nil then return RQE._HBD end
	local HBD = nil
	if LibStub then
		HBD = LibStub("HereBeDragons-2.0", true)
	end
	-- TomTom ships HBD too; some builds expose it directly
	if not HBD and TomTom and TomTom.HBD then
		HBD = TomTom.HBD
	end
	RQE._HBD = HBD or false
	return RQE._HBD or nil
end


-- Returns dx, dy in YARDS between two points on the SAME map.
-- Args are normalized 0–1 coordinates.
-- World distance in yards^2 between two zone points.
-- Returns dx, dy in yards (not normalized), or nil if we can't translate.
local function _zoneDeltaYards(zm, zx, zy, zm2, zx2, zy2)
	if not (HBD and zm and zx and zy and zm2 and zx2 and zy2) then return nil end
	-- Translate both points into the same world space and measure
	local wx1, wy1 = HBD:GetWorldCoordinatesFromZone(zx, zy, zm)
	local wx2, wy2 = HBD:GetWorldCoordinatesFromZone(zx2, zy2, zm2)
	if not (wx1 and wy1 and wx2 and wy2) then return nil end
	return (wx2 - wx1), (wy2 - wy1)
end


-- Public adapter used by the rest of the file (kept for readability elsewhere)
function RQE.WPUtil.DeltaYards(zm, x1, y1, x2, y2)
	return _zoneDeltaYards(zm, x1, y1, zm, x2, y2)
end


-- Mark current target band as visited if player is within its visitedRadius
local function _updateVisitedBands(st, norm)
	-- st.currentIdx is the hotspot we’re currently targeting
	local idx = st.currentIdx
	if not idx then return end
	local h = norm.hotspots[idx]
	if not h then return end

	local d2, unit = _playerDistanceSqFlexible(h.mapID, h.x, h.y)
	if not d2 then return end

	-- threshold in yards if we have them; otherwise use a conservative normalized fallback
	local thresholdYards = h.visitedRadius or norm.defaults.visitedRadius or 80

	if unit == "yards" then
		if d2 <= (thresholdYards * thresholdYards) then
			st.visited = st.visited or {}
			if not st.visited[h.priority] then
				st.visited[h.priority] = true
				_dbgMarkVisited(st.questID, st.stepIndex, h.priority, idx, h)
			end
		end
	else
		-- Normalized fallback: only mark if extremely close (about 0.25% of the map)
		-- This avoids premature unlocks when we don’t have yard math.
		local normThresh = 0.0025
		if d2 <= (normThresh * normThresh) then
			st.visited = st.visited or {}
			if not st.visited[h.priority] then
				st.visited[h.priority] = true
				_dbgMarkVisited(st.questID, st.stepIndex, h.priority, idx, h)
			end
		end
	end

	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		if unit == "yards" then
			print(string.format("|cff00ffffRQE(INFO)|r visitCheck unit=yards d=%.1f (radius=%.1f)",
				math.sqrt(d2), thresholdYards))
		else
			print(string.format("|cff00ffffRQE(INFO)|r visitCheck unit=norm d~=%.2f%% (norm fallback)",
				math.sqrt(d2) * 100))
		end
	end

	if RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		print(string.format("|cff00ffffRQE(INFO)|r visitCheck unit=%s d=%.1f",
			unit or "nil", (unit=="yards" and math.sqrt(d2) or math.sqrt(d2)*100)))
	end
end


-- Return a set of bands eligible for selection:
--   • all already-visited bands stay eligible
--   • plus the next not-yet-visited band (the “frontier”)
local function _eligibleBands(st, priorityBands)
	-- priorityBands is a sorted array (NormalizeCoordinates guarantees this)
	if not priorityBands or #priorityBands == 0 then return {} end

	local visited = st.visited or {}

	-- 1) Find the next frontier band (lowest p that is NOT visited)
	local frontier
	for _, p in ipairs(priorityBands) do
		if not visited[p] then
			frontier = p
			break
		end
	end
	-- If all are visited, keep the highest band as the "frontier"
	if not frontier then frontier = priorityBands[#priorityBands] end

	-- 2) Allow all visited bands + the frontier band
	local allowed = {}
	for _, p in ipairs(priorityBands) do
		if visited[p] then
			allowed[p] = true
		end
	end
	allowed[frontier] = true

	-- Optional debug (prints once per change)
	if st._lastTargetBand ~= frontier and RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
		_dbgEligibleBands(st.questID, st.stepIndex, priorityBands, visited, frontier)
	end
	st._lastTargetBand = frontier

	return allowed
end


-- Returns squared distance and unit tag: "yards" or "norm"
function _playerDistanceSqFlexible(hmap, hx, hy)
	local pmid, px, py = _playerMapAndXY()
	if not pmid or not px or not py then return nil end

	-- Same-map first choice = yards via HBD
	if pmid == hmap and HBD then
		local dx, dy = RQE.WPUtil.DeltaYards(hmap, px, py, hx, hy)
		if dx and dy then return dx*dx + dy*dy, "yards" end
	end

	-- Fallbacks
	if pmid == hmap then
		local dx, dy = px - hx, py - hy
		return dx*dx + dy*dy, "norm"
	else
		-- cross-map: only yards makes sense
		if HBD then
			local dx, dy = _zoneDeltaYards(pmid, px, py, hmap, hx, hy)
			if dx and dy then return dx*dx + dy*dy, "yards" end
		end
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
					-- same-map but no distance? extremely unlikely; keep author order fallback
					elseif not bestIdx then
						bestIdx = idx
					end
				end
			end
			if bestIdx then
				st.currentIdx = bestIdx
				local now = GetTime and GetTime() or 0
				st.lastEval.t, st.lastEval.mapID, st.lastEval.px, st.lastEval.py = now, pmid, px, py

				-- DEBUG (INFO): first selection
				if RQE and RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
					local h = norm.hotspots[bestIdx]
					print(string.format(
						"|cff00ffffRQE(INFO)|r Q%d S%d select initial target %s",
						st.questID or -1, st.stepIndex or -1, _fmtHotspot(bestIdx, h)
					))
				end

				local c = norm.hotspots[bestIdx]
				return c.mapID, c.x, c.y, bestIdx
			end
		end
	end

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

	-- Decide whether to switch
	local chosenIdx = curIdx
	if not chosenIdx then
		chosenIdx = bestIdx
	else
		local switch = false
		local reason = nil
		if bestIdx then
			local cur = norm.hotspots[curIdx]
			local curD2, curUnit = _playerDistanceSqFlexible(cur.mapID, cur.x, cur.y)

			if bestD2 and curD2 then
				if bestUnit == "yards" and curUnit == "yards" then
					local yardDelta = math.sqrt(curD2) - math.sqrt(bestD2)
					local need = (norm.hotspots[bestIdx].minSwitchYards or norm.defaults.minSwitchYards or 0)
					if yardDelta >= need then
						switch = true
						reason = string.format("closer by %.1f yards (need %.1f)", yardDelta, need)
					end
				else
					-- normalized fallback (same-map or no yard math): switch if clearly closer
					-- factor 0.85 ~= 15% closer; tweak if you want more/less hysteresis
					if bestD2 < (curD2 * 0.85) then
						switch = true
						reason = "normalized distance much lower (>15%)"
					end
				end
			elseif bestD2 and not curD2 then
				-- current is cross-map/unknown; candidate is measurable => switch
				switch = true
				reason = "candidate measurable; current not"
			elseif not bestD2 and not curD2 then
				-- both unknown: prefer lower band, then author order
				if norm.hotspots[bestIdx].priority < norm.hotspots[curIdx].priority then
					switch = true
					reason = "lower priority band"
				end
			end
		end
		if switch then
			-- DEBUG (INFO): switching target
			if RQE and RQE.db and RQE.db.profile and RQE.db.profile.debugLevel == "INFO+" then
				local oldH = norm.hotspots[curIdx]
				local newH = norm.hotspots[bestIdx]
				print(string.format(
					"|cff00ffffRQE(INFO)|r Q%d S%d switch %s  →  %s  (%s)",
					st.questID or -1, st.stepIndex or -1, _fmtHotspot(curIdx, oldH), _fmtHotspot(bestIdx, newH), reason or "reason n/a"
				))
			end
			chosenIdx = bestIdx
		end
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
function RQE.WPUtil.ClearHotspotState(questID, stepIndex, hard)
	-- hard = true  -> wipe everything (use on login/reload/new area)
	-- hard = false -> keep visited ladder; only forget current choice + eval cache
	if not (questID and stepIndex) then
		if hard then RQE.WPUtil._hotspotState = {} end
		return
	end

	local bucket = RQE.WPUtil._hotspotState[questID]
	if not bucket then return end
	local st = bucket[stepIndex]
	if not st then return end

	if hard then
		bucket[stepIndex] = nil
	else
		st.currentIdx = nil
		st.lastEval = { t=0, mapID=nil, px=nil, py=nil }
		-- keep st.visited intact
	end
end


-- Slash command to easier access the dump
SLASH_RQEDUMP1 = "/rqedump"
SlashCmdList.RQEDUMP = function()
	local qid = C_SuperTrack.GetSuperTrackedQuestID()
	local sidx = RQE.AddonSetStepIndex or 1
	if RQE.WPUtil and RQE.WPUtil.DebugDumpBands then
		RQE.WPUtil.DebugDumpBands(qid, sidx)
	end
end