--[[

TrackerSync.lua
Shared tracker membership reconciliation, render ownership, and deferred recovery

]]


--------------------------------------------------
-- #1. Tracker Synchronization State
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Runtime State & Membership Helpers
	-------------------------------------------------------

	-- Tracker membership recovery only. Objective, distance, and scenario updates
	-- continue through their existing render/event paths, even with unchanged IDs.
	local RQE = RQE
	local state = { records = {}, builds = {}, worldRows = {}, generation = 0, pending = false, queued = false }
	RQE.TrackerSyncStats = { checks = 0, repairs = 0, normalRenders = 0, worldRenders = 0 }

	local function SameSet(a, b)
		for key, value in pairs(a) do if b[key] ~= value then return false end end
		for key, value in pairs(b) do if a[key] ~= value then return false end end
		return true
	end

	local function AddID(set, questID)
		questID = tonumber(questID)
		if questID and questID > 0 then set[questID] = true end
	end



--------------------------------------------------
-- #2. Tracking Inputs
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Client Sources & Row Readiness
	-------------------------------------------------------

	-- Inputs are unordered membership/readiness, never distances, objective counts,
	-- focus, or coordinates. Legacy display sources retain the sorter's precedence.
	local function ReadInputs(kind)
		local api, client = RQE.API, RQE.API.Client
		local snapshot, ready, candidates = {}, {}, {}
		local legacy = RQE.TrackerSyncLegacySources
		local log = client.C_QuestLog
		if kind == "world" then
			local count = api.GetNumWorldQuestWatches or log.GetNumWorldQuestWatches
			local getID = api.GetQuestIDForWorldQuestWatchIndex or log.GetQuestIDForWorldQuestWatchIndex
			snapshot.count = count()
			for i = 1, snapshot.count do AddID(candidates, getID(i)) end
			-- An existing renderer deliberately returns early in a raid. Revisit that
			-- deferred result when group context changes, rather than every sync tick.
			snapshot.raid = client.IsInRaid()
		else
			local function AddSet(source)
				for id in pairs(source or {}) do AddID(candidates, id) end
			end
			if legacy and RQE.QuestTrackerSearchResults then
				snapshot.mode = "search"; AddSet(RQE.QuestTrackerSearchResults)
			elseif legacy and RQE.QuestMenuSelection then
				snapshot.mode = "menu"; AddSet(RQE.QuestMenuSelection)
			elseif legacy and RQE.ShowOnlyAllCompleteVirtualQuests then
				snapshot.mode = "complete"; AddSet(RQE.AllCompleteVirtualQuestWatches)
			elseif legacy and RQE.ZoneQuestFilterMapID then
				snapshot.mode = "zone"; snapshot.zone = RQE.ZoneQuestFilterMapID
				for _, id in ipairs((RQE.ZoneQuests or {})[snapshot.zone] or {}) do AddID(candidates, id) end
			elseif legacy and RQE.ShowAllQuestLogQuests then
				snapshot.mode = "all"
				for i = 1, api.GetNumQuestLogEntries() do
					local info = api.GetQuestLogInfo(i)
					if info and not info.isHeader then AddID(candidates, info.questID) end
				end
			else
				snapshot.mode = "watched"
				local count = legacy and api.GetNumQuestWatches or log.GetNumQuestWatches
				local getID = legacy and api.GetQuestIDForQuestWatchIndex or log.GetQuestIDForQuestWatchIndex
				snapshot.count = count()
				for i = 1, snapshot.count do AddID(candidates, getID(i)) end
			end
			if legacy then
				if snapshot.mode == "zone" then AddSet(RQE.ClassicManualVirtualQuestWatches)
				elseif snapshot.mode == "watched" or snapshot.mode == "all" then AddSet(RQE.ClassicVirtualQuestWatches) end
			end
		end
		for id in pairs(candidates) do
			local isWorld = api.IsWorldQuest(id) and true or false
			snapshot["q" .. id] = true
			snapshot["w" .. id] = isWorld
			if kind == "world" then
				-- Unknown titles are valid world rows; do not wait on quest text.
				ready[id] = isWorld
			else
				local onQuest = not legacy or api.IsOnQuest(id)
				local hidden = legacy and (RQE.ShowAllQuestLogQuests or RQE.ZoneQuestFilterMapID)
					and RQE.HiddenQuestLogQuests and RQE.HiddenQuestLogQuests[id]
				local getIndex = legacy and api.GetLogIndexForQuestID or log.GetLogIndexForQuestID
				local index = getIndex(id)
				local info = index and api.GetQuestLogInfo(index)
				ready[id] = not isWorld and onQuest and not hidden and info ~= nil and not info.isHeader or false
				snapshot["live" .. id] = onQuest and true or false
				snapshot["hidden" .. id] = hidden and true or false
			end
			snapshot["ready" .. id] = ready[id]
		end
		return snapshot, ready
	end



--------------------------------------------------
-- #3. Render Lifecycle
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Visibility & Interrupted Render Recovery
	-------------------------------------------------------

	local function EnsureShowHook()
		local frame = RQE.RQEQuestFrame
		if frame and frame.HookScript and not frame.rqeTrackerSyncShowHook then
			frame.rqeTrackerSyncShowHook = true
			frame:HookScript("OnShow", function() RQE:ResumeTrackerSync() end)
		end
	end

	local function RecoverUnfinishedBuilds()
		state.buildGuardQueued = false
		for kind, stack in pairs(state.builds) do
			if #stack > 0 then
				local unfinished = stack[#stack]
				local completed = state.records[kind]
				-- A renderer error has already gone to WoW's normal error handler.
				-- Drop its stale scope after the Lua call unwinds, without swallowing
				-- the error or starting an unbounded next-frame render retry loop.
				if completed and completed.generation <= unfinished.generation then
					completed.valid = false
					completed.deferred = nil
				end
				state.builds[kind] = {}
				state.pending = true
			end
		end
	end

	-------------------------------------------------------
	-- #3b. Begin, Register & Complete Render Records
	-------------------------------------------------------

	function RQE:BeginTrackerSyncRender(kind)
		EnsureShowHook()
		local inputs, ready = ReadInputs(kind)
		local stack = state.builds[kind] or {}
		state.builds[kind] = stack
		state.generation = state.generation + 1
		stack[#stack + 1] = { inputs = inputs, ready = ready, expected = {}, rows = {}, generation = state.generation }
		if not state.buildGuardQueued then
			state.buildGuardQueued = true
			self.API.Client.C_Timer.After(0, RecoverUnfinishedBuilds)
		end
	end

	function RQE:SetTrackerSyncExpectedQuests(kind, questIDs)
		local stack = state.builds[kind]
		local build = stack and stack[#stack]
		if not build then return end
		for id in pairs(questIDs or {}) do AddID(build.expected, id) end
	end

	function RQE:RegisterTrackerSyncRow(kind, questID, row, parent)
		local stack = state.builds[kind]
		local build = stack and stack[#stack]
		questID = tonumber(questID)
		if not build or not questID or not row then return end
		row.rqeTrackerSyncQuestID = questID
		build.rows[questID] = { row = row, parent = parent }
	end

	function RQE:CommitTrackerSyncRender(kind)
		local stack = state.builds[kind]
		if not stack or #stack == 0 then return end
		local build = table.remove(stack)
		build.valid = true
		state.records[kind] = build
		for id in pairs(build.expected) do
			if not build.rows[id] then state.pending = true end
		end
		local key = kind == "world" and "worldRenders" or "normalRenders"
		self.TrackerSyncStats[key] = self.TrackerSyncStats[key] + 1
	end

	function RQE:AbortTrackerSyncRender(kind)
		local stack = state.builds[kind]
		if not stack or #stack == 0 then return end
		local build = table.remove(stack)
		-- Keep an explicit deferred record, not a falsely completed row list.
		build.deferred = true
		state.records[kind] = build
		state.pending = true
	end

	function RQE:InvalidateTrackerSyncRows(kind)
		local record = state.records[kind]
		if record then record.valid = false; record.deferred = nil end
	end

	-------------------------------------------------------
	-- #3c. World Quest Pool Ownership
	-------------------------------------------------------

	-- Pool ownership starts before a row can be shown, independently of completed
	-- membership. Even a partially rendered/aborted world row must be cleared later.
	function RQE:OwnTrackerWorldRow(row)
		state.worldRows[row] = true
	end

	function RQE:ClearOwnedTrackerWorldRows()
		for row in pairs(state.worldRows) do
			row:Hide()
			if row.WQuestLevelAndName then row.WQuestLevelAndName:Hide() end
			if row.QuestObjectivesOrDescription then row.QuestObjectivesOrDescription:Hide() end
			if row.RQEProgressBar then row.RQEProgressBar:Hide() end
			-- Track active ownership only; the renderer's separate cache retains
			-- reusable frames without making cleanup grow with session history.
			state.worldRows[row] = nil
		end
	end



--------------------------------------------------
-- #4. Synchronization & Repair
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Eligibility & Completed Row Validation
	-------------------------------------------------------

	local function IsBlocked()
		if RQE.PendingTrackerStateRestore or RQE.API.Client.InCombatLockdown() then return true end
		local frame = RQE.RQEQuestFrame
		if not frame or not frame:IsShown() then return true end
		for _, stack in pairs(state.builds) do if #stack > 0 then return true end end
		return false
	end

	local function NeedsRepair()
		local waiting = false
		for _, kind in ipairs({ "normal", "world" }) do
			local inputs, ready = ReadInputs(kind)
			local record = state.records[kind]
			if not record or not SameSet(inputs, record.inputs) then return true end
			if record.deferred then
				waiting = true
			elseif not record.valid then
				return true
			else
				for id in pairs(record.expected) do
					local owned = record.rows[id]
					if not owned then
						if ready[id] then return true end
						waiting = true
					else
						local row = owned.row
						-- IsShown concerns the row's own flag, not ancestor visibility or
						-- clipping. Section collapse/scrolling must not trigger repairs.
						if row.rqeTrackerSyncQuestID ~= id or (row.questID and tonumber(row.questID) ~= id)
							or row:GetParent() ~= owned.parent or not row:IsShown() then return true end
					end
				end
				for id in pairs(record.rows) do if not record.expected[id] then return true end end
			end
		end
		return false, waiting
	end

	-------------------------------------------------------
	-- #4b. Coalesced Repair Requests
	-------------------------------------------------------

	function RQE:QueueTrackerSyncRepair()
		state.pending = true
		if state.queued or IsBlocked() then return end
		state.queued = true
		self.API.Client.C_Timer.After(0, function()
			state.queued = false
			if IsBlocked() then return end
			local repair, waiting = NeedsRepair()
			state.pending = waiting or false
			if repair then
				RQE.TrackerSyncStats.repairs = RQE.TrackerSyncStats.repairs + 1
				-- Main owns counts/headers and already renders world/task sections.
				-- QuestType would duplicate world rendering and skip an empty list.
				UpdateRQEQuestFrame()
			end
		end)
	end

	-------------------------------------------------------
	-- #4c. Public Checks & Deferred Resumption
	-------------------------------------------------------

	function RQE:CheckWatchedQuestsSync()
		EnsureShowHook()
		self.TrackerSyncStats.checks = self.TrackerSyncStats.checks + 1
		if IsBlocked() then state.pending = true; return end
		local repair, waiting = NeedsRepair()
		state.pending = waiting or false
		if repair then self:QueueTrackerSyncRepair() end
	end

	function RQE:ResumeTrackerSync()
		if state.pending then self:CheckWatchedQuestsSync() end
	end



--------------------------------------------------
-- #5. Event Registration
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Pending-Only Resume Events
	-------------------------------------------------------

	-- No new polling loop. Only already-pending repairs resume on these events;
	-- legacy clients retain their existing disabled-ticker behavior.
	local resumeFrame = CreateFrame("Frame")
	for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "QUEST_LOG_UPDATE", "QUEST_DATA_LOAD_RESULT", "GROUP_ROSTER_UPDATE" }) do
		pcall(resumeFrame.RegisterEvent, resumeFrame, event)
	end
	resumeFrame:SetScript("OnEvent", function() RQE:ResumeTrackerSync() end)
