-- Shared opt-in navigation for Retail, SoD Classic, and TBC Anniversary; Forever keeps its existing modes.
if not RQE then return end
local gameVersion = RQE.API and RQE.API.GameVersion
if gameVersion and gameVersion.isForever then return end
local legacyClient = gameVersion and (gameVersion.isClassicEra or gameVersion.isTBC) or false
if not RQE.IsRetail and not legacyClient then return end

-- Expose the mode selector only on clients with the complete Hybrid integration loaded.
function RQE:IsHybridNavigationSupported()
	return true
end

-- Read the explicit opt-in without changing any legacy preference combinations.
function RQE:IsHybridStepNavigation()
	return self.db and self.db.profile
		and self.db.profile.stepNavigationMode == "hybrid" or false
end

-- Report old profiles through their existing manual-controls flag.
function RQE:GetStepNavigationMode()
	if self:IsHybridStepNavigation() then return "hybrid" end
	return self.db and self.db.profile.enableStepControls and "manual" or "automatic"
end

-- Return the focused, accepted DB quest; searched pickup previews remain independent.
local function focusedQuest()
	if RQE.CanNavigateSearchedQuestSteps and RQE:CanNavigateSearchedQuestSteps(RQE.searchedQuestID) then return end
	local questID = tonumber(RQE.API.GetSuperTrackedQuestID())
	if questID and questID > 0 and RQE.API.IsOnQuest(questID) then
		local data = RQE.getQuestData(questID)
		if type(data) == "table" and data[1] then return questID, data end
	end
end

-- Restrict DB navigation integration to a live supported quest, preserving ordinary unknown-quest guidance.
function RQE:CanRunHybridNavigation()
	return self:IsHybridStepNavigation() and focusedQuest() ~= nil
end

-- Invalidate queued work whenever the player changes the selected navigation context.
local function invalidateWork()
	RQE._hybridNavigationRevision = (RQE._hybridNavigationRevision or 0) + 1
	if RQE._hybridTimer then RQE._hybridTimer:Cancel() end
	RQE._hybridTimer = nil
end

-- Discard only Hybrid-owned preview state when the mode, profile, or focused quest changes.
function RQE:ResetHybridNavigation()
	local state = self._hybridNavigation
	invalidateWork()
	self._hybridNavigation = nil
	self._hybridApplying, self._hybridEvaluating = nil, nil
	self._hybridPendingQuest, self._hybridResumeAutomatic = nil, nil
	self._hybridPendingUntrack, self._hybridObservedQuestID = nil, nil
	if state and state.previewStep and tonumber(self.ManualPreviewQuestID) == state.questID then
		self:ClearManualStepPreview(false)
	end
end

-- Refresh the existing controls without changing the helper frame's dimensions.
local function refreshControls()
	if RQE.API.Client.InCombatLockdown() then return end
	if RQE.Buttons.UpdateHeaderNavigation then RQE.Buttons.UpdateHeaderNavigation() end
	if RQE.Buttons.RefreshStepNavigationTooltips then RQE.Buttons.RefreshStepNavigationTooltips() end
	local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
	if registry then registry:NotifyChange("RQE_Frame") end
end

-- Set step navigation independently of the existing automatic-waypoint preference.
function RQE:SetStepNavigationMode(mode)
	if mode ~= "automatic" and mode ~= "manual" and mode ~= "hybrid" then return end
	local wasHybrid = self:IsHybridStepNavigation()
	self:ResetHybridNavigation()
	self.db.profile.stepNavigationMode = mode
	if mode ~= "hybrid" then self.db.profile.enableStepControls = mode == "manual" end
	if mode == "hybrid" then
		self:ClearManualStepPreview(false)
		self:QueueHybridPeriodicChecks("mode-selected", 0)
	elseif wasHybrid and mode == "automatic" then
		if self.API.Client.InCombatLockdown() then
			self._hybridResumeAutomatic = {profile = self.db.profile, questID = self.API.GetSuperTrackedQuestID()}
		else
			self:StartPeriodicChecks()
		end
	end
	refreshControls()
end

-- Create an automatic trajectory that never inherits the displayed preview's retry step.
local function navigationState()
	if not RQE:IsHybridStepNavigation() then return end
	local questID = focusedQuest()
	local state = RQE._hybridNavigation
	if not questID then
		if state then RQE:ResetHybridNavigation() end
		return
	end
	if not state or state.questID ~= questID or state.profile ~= RQE.db.profile then
		local previousQuestID = state and state.questID or RQE._hybridObservedQuestID
			or tonumber(RQE.previousSuperTrackedQuestID) or 0
		RQE:ResetHybridNavigation()
		state = {questID = questID, profile = RQE.db.profile, autoStep = 1,
			pendingFreshQuestID = questID,
			pendingFocusMaintenance = {questID = questID, previousQuestID = previousQuestID}}
		RQE._hybridNavigation = state
		RQE._hybridObservedQuestID = questID
	end
	return state
end

-- Identify only Hybrid previews, leaving the legacy Manual counter unchanged.
function RQE:IsHybridManualStepPreview(questID)
	local state = self._hybridNavigation
	return self:IsHybridStepNavigation() and state and state.profile == self.db.profile
		and state.questID == tonumber(questID) and state.questID == focusedQuest()
		and state.previewStep ~= nil or false
end

-- Capture the identity needed by delayed waypoint and macro work.
function RQE:GetHybridCallbackToken()
	if not self:IsHybridStepNavigation() then return end
	return {revision = self._hybridNavigationRevision, profile = self.db.profile,
		questID = tonumber(self.API.GetSuperTrackedQuestID()), step = self.AddonSetStepIndex,
		searchedQuestID = self.searchedQuestID}
end

-- Reject callbacks from a different quest, mode, profile, step, or manual selection.
function RQE:IsHybridCallbackCurrent(token)
	if not token then return not self:IsHybridStepNavigation() end
	return self:IsHybridStepNavigation() and token.revision == self._hybridNavigationRevision
		and token.profile == self.db.profile and token.questID == tonumber(self.API.GetSuperTrackedQuestID())
		and token.searchedQuestID == self.searchedQuestID
		and token.step == self.AddonSetStepIndex
end

-- Commit an accepted step; the common refresh below also runs when the candidate stays unchanged.
local function applyStep(state, stepIndex)
	local questData = RQE.getQuestData(state.questID)
	if not questData or not questData[stepIndex] then return end
	invalidateWork()
	state.previewStep, state.retryBaseline, state.previewEvaluationState = nil, nil, nil
	state.autoStep, state.appliedStep = stepIndex, nil
	state.lastRefreshStep = nil
	RQE:ClearManualStepPreview(false)
	if RQE.ActiveCoordblock and (RQE.ActiveCoordblock.questID ~= state.questID
		or RQE.ActiveCoordblock.stepIndex ~= stepIndex) then RQE:ReleaseActiveCoordblockWaypoint() end
	RQE.AddonSetStepIndex, RQE.CurrentStepIndex, RQE.StoredStepIndex = stepIndex, stepIndex, stepIndex
	RQE.LastClickedIdentifier = stepIndex
	RQE.LastClickedButtonRef = RQE.WaypointButtons and RQE.WaypointButtons[stepIndex] or nil
	RQE.LastClickedWaypointButton = RQE.LastClickedButtonRef
end

-- Compare macro text without calling the legacy inspection helper that can reset the selected step.
local function displayedMacroMatches(step)
	local expected = step.macroArray or step.macro or ""
	if type(expected) == "table" then
		if type(expected[1]) == "table" then
			expected = expected[1].macro or ""
		else
			expected = table.concat(expected, "\n")
		end
	end
	local client = RQE.API.Client
	if not client.GetMacroIndexByName or not client.GetMacroInfo then return false end
	local index = client.GetMacroIndexByName("RQE Macro")
	if not index or index == 0 then return expected == "" end
	local _, _, body = client.GetMacroInfo(index)
	if expected == "" then return not body or body:match("^%s*$") ~= nil end
	return body == expected
end

-- Maintain the displayed step's guidance and macro without changing its preview or automatic baseline.
function RQE:RefreshHybridDisplayedStep()
	local state = navigationState()
	if not state or self._hybridApplying or self.API.Client.InCombatLockdown() then return false end
	local stepIndex = state.previewStep or state.autoStep
	local data = self.getQuestData(state.questID)
	if not data or not data[stepIndex] or self.AddonSetStepIndex ~= stepIndex then return false end
	local client = self.API.Client
	local mapID = client.C_Map and client.C_Map.GetBestMapForUnit("player") or self.mapID
	local previousOverride = self.StepDistanceOverride
	self._hybridApplying = true
	-- Release guards after any renderer failure so a later trigger can repair the same displayed step.
	local ok, refreshed = pcall(function()
		local pending = state.pendingFocusMaintenance
		if pending and self.RefreshHybridFocusMaintenance then
			local handled = self:RefreshHybridFocusMaintenance(pending.questID, pending.previousQuestID)
			if handled then state.pendingFocusMaintenance = nil end
		end
		if UpdateFrame then UpdateFrame(state.questID, data) end
		-- Existing blacklist maintenance can change focus during UpdateFrame.
		if self._hybridNavigation ~= state or focusedQuest() ~= state.questID then return false end
		if self.RefreshQuestHelperDirectionForLocation then self:RefreshQuestHelperDirectionForLocation() end
		if self.UpdateSeparateFocusFrame then self:UpdateSeparateFocusFrame() end
		if self.CheckAndRefreshSeparateFocusFrame then self:CheckAndRefreshSeparateFocusFrame() end
		if self.CheckSeparateFocusHasTextButRQEFrameMissingQuest then
			self:CheckSeparateFocusHasTextButRQEFrameMissingQuest()
		end
		if self._hybridNavigation ~= state or focusedQuest() ~= state.questID then return false end
		if RQEMacro and RQEMacro.CreateMacroForCurrentStep
			and (state.lastRefreshStep ~= stepIndex or not displayedMacroMatches(data[stepIndex])) then
			RQEMacro:CreateMacroForCurrentStep()
		end
		if self.UpdateStepDistance then
			if state.lastRefreshMap ~= mapID or state.lastRefreshStep ~= stepIndex then self.StepDistanceOverride = true end
			self:UpdateStepDistance()
		end
		if self.Buttons.UpdateHeaderNavigation then self.Buttons.UpdateHeaderNavigation() end
		if self.Buttons.RefreshStepNavigationTooltips then self.Buttons.RefreshStepNavigationTooltips() end
		if self.db.profile.autoClickWaypointButton then
			if state.previewStep then
				self:ActivateHybridWaypoint(false)
			elseif self.CreateUnknownQuestWaypoint then
				self:CreateUnknownQuestWaypoint(state.questID, mapID)
			end
		end
		return true
	end)
	self.StepDistanceOverride = previousOverride
	self._hybridApplying = nil
	if not ok then state.lastError = refreshed; return false end
	if not refreshed then self:QueueHybridPeriodicChecks("focus-during-refresh", 0.20); return false end
	state.lastRefreshStep, state.lastRefreshMap = stepIndex, mapID
	if not state.previewStep then state.appliedStep = stepIndex end
	return true
end

-- Record automatic and retry baselines before Core changes the displayed selection.
function RQE:BeginHybridManualPreview(questID, stepIndex)
	local state = navigationState()
	if not state or state.questID ~= tonumber(questID) then return end
	-- An already-selected mounted Classic quest still needs its deferred UI cleanup.
	if not (self._hybridPendingQuest and self._hybridPendingQuest.selectedInCombat) then
		self._hybridPendingQuest = nil
	end
	invalidateWork()
	if self.API.Client.InCombatLockdown() then
		state.pendingManualStep, state.combatPending = stepIndex, true
		return false
	end
	local result = self:EvaluateStepCandidate(state.questID, state.autoStep,
		{state = state.autoEvaluationState, vehicleUpdate = state.vehicleUpdate,
			newlyFocusedQuestID = state.pendingFreshQuestID})
	if result and result.candidate then
		state.autoStep, state.autoEvaluationState = result.candidate, result.evaluationState
		state.pendingFreshQuestID, state.hasEvaluated = nil, true
	end
	state.previewStep = stepIndex
	local retry = self:EvaluateStepCandidate(state.questID, stepIndex, {probeOnly = true})
	state.retryBaseline = retry and retry.retryFailed
	state.previewEvaluationState = retry and retry.evaluationState
	state.appliedStep = nil
	if state.pendingFocusMaintenance then
		local revision = self._hybridNavigationRevision
		-- Finish focus upkeep after Core installs the preview, without evaluating another automatic candidate.
		self.API.Client.C_Timer.After(0, function()
			if self:IsHybridStepNavigation() and self._hybridNavigation == state
				and revision == self._hybridNavigationRevision and state.profile == self.db.profile
				and focusedQuest() == state.questID and state.previewStep == stepIndex then
				self:RefreshHybridDisplayedStep()
			end
		end)
	end
	local settleAt = result and result.settleAt
	if retry and retry.settleAt then settleAt = math.min(settleAt or retry.settleAt, retry.settleAt) end
	if state.vehicleReadyAt then settleAt = math.min(settleAt or state.vehicleReadyAt, state.vehicleReadyAt) end
	if settleAt then self:QueueHybridPeriodicChecks("preview-aura-settle", math.max(0.01,
		settleAt - self.API.Client.GetTime()), questID) end
	return true
end

-- Coalesce triggers while binding their work to the current quest and selection generation.
function RQE:QueueHybridPeriodicChecks(reason, delay, questID)
	local state = navigationState()
	if not state or self._hybridApplying then return end
	if questID and tonumber(questID) ~= state.questID then return end
	state.lastReason = reason
	if reason == "UPDATE_VEHICLE_ACTIONBAR" then
		state.vehicleUpdate, state.vehicleReadyAt = true, self.API.Client.GetTime() + 0.40
		if self._hybridTimer then self._hybridTimer:Cancel(); self._hybridTimer = nil end
	end
	if self._hybridTimer then return end
	local revision = self._hybridNavigationRevision
	local wait = math.max(tonumber(delay) or 0.20, (state.nextCheckAt or 0) - self.API.Client.GetTime(),
		(state.vehicleReadyAt or 0) - self.API.Client.GetTime(), 0)
	-- Reject stale work even when the user reselected the same quest or step.
	self._hybridTimer = self.API.Client.C_Timer.NewTimer(wait, function()
		if not self:IsHybridStepNavigation() or self._hybridNavigation ~= state
			or revision ~= self._hybridNavigationRevision or state.profile ~= self.db.profile
			or focusedQuest() ~= state.questID then return end
		self._hybridTimer = nil
		self:StartHybridPeriodicChecks()
	end)
end

-- Compare automatic results, and separately detect new failures in the previewed step's retry rule.
function RQE:StartHybridPeriodicChecks(newlyFocusedQuestID)
	local state = navigationState()
	if not state or self._hybridApplying or self._hybridEvaluating then return end
	if not state.hasEvaluated and tonumber(newlyFocusedQuestID) == state.questID then
		state.pendingFreshQuestID = state.questID
	end
	if self.API.Client.InCombatLockdown() then state.combatPending = true; return end
	if state.vehicleReadyAt and state.vehicleReadyAt > self.API.Client.GetTime() then
		self:QueueHybridPeriodicChecks("vehicle-settle", state.vehicleReadyAt - self.API.Client.GetTime())
		return
	end
	self._hybridEvaluating = true
	local result, err = self:EvaluateStepCandidate(state.questID, state.autoStep,
		{state = state.autoEvaluationState, newlyFocusedQuestID = state.pendingFreshQuestID,
			vehicleUpdate = state.vehicleUpdate})
	self._hybridEvaluating = nil
	if not result or not result.candidate then state.lastError = err; return end
	state.pendingFreshQuestID, state.hasEvaluated = nil, true
	state.vehicleUpdate, state.vehicleReadyAt = nil, nil
	state.lastError, state.combatPending = nil, nil
	state.nextCheckAt = self.API.Client.GetTime() + 0.20
	local previous = state.autoStep
	state.autoStep, state.autoEvaluationState = result.candidate, result.evaluationState
	local retry, retryChanged
	if state.previewStep then
		retry = self:EvaluateStepCandidate(state.questID, state.previewStep,
			{probeOnly = true, state = state.previewEvaluationState})
		if retry then
			retryChanged = state.retryBaseline == false and retry.retryFailed == true
			if retry.retryFailed ~= nil then state.retryBaseline = retry.retryFailed end
			state.previewEvaluationState = retry.evaluationState
		end
	end
	if not state.previewStep or result.candidate ~= previous then
		if state.previewStep or state.appliedStep ~= result.candidate then applyStep(state, result.candidate) end
	elseif retryChanged and retry.retryTarget and not retry.normalComplete then
		applyStep(state, retry.retryTarget)
	end
	self:RefreshHybridDisplayedStep()
	local settleAt = result.settleAt
	if retry and retry.settleAt then settleAt = math.min(settleAt or retry.settleAt, retry.settleAt) end
	if settleAt then self:QueueHybridPeriodicChecks("aura-settle", math.max(0.01, settleAt - self.API.Client.GetTime())) end
end

-- Return the displayed Hybrid step for explicit waypoint requests without evaluating progression.
function RQE:ActivateHybridWaypoint(manual)
	local state = navigationState()
	if not state or (not manual and not self.db.profile.autoClickWaypointButton) then return end
	if self.API.Client.InCombatLockdown() then
		if manual then state.pendingWaypoint = true end
		return false
	end
	if manual and self.ReleaseManualFlightMasterWaypoint then self:ReleaseManualFlightMasterWaypoint() end
	local stepIndex = state.previewStep or state.autoStep
	if self.SyncCoordOrderWaypoint and self:SyncCoordOrderWaypoint() then return true end
	if self.EnsureWaypointForSupertracked and self:EnsureWaypointForSupertracked() then return true end
	if self.IsCoordblockWaypointProtected and self:IsCoordblockWaypointProtected() then return end
	if self.IsManualFlightMasterWaypointProtected and self:IsManualFlightMasterWaypointProtected() then return end
	local step = self.getQuestData(state.questID)[stepIndex]
	local mapID, x, y
	if self.WPUtil and self.WPUtil.SelectBestHotspot then
		mapID, x, y = self.WPUtil.SelectBestHotspot(state.questID, stepIndex, step)
	end
	if not mapID and step.coordinates and step.coordinates.x then
		mapID = step.coordinates.mapID or step.coordinates.continentID
		x, y = step.coordinates.x, step.coordinates.y
	end
	if not (mapID and x and y and self.Waypoints) then return false end
	x, y = tonumber(x), tonumber(y)
	if not x or not y then return false end
	x, y = x > 1 and x / 100 or x, y > 1 and y / 100 or y
	local title = self:GetWaypointTitle(state.questID, mapID, x, y)
	local uid, usesBlizzard = self.Waypoints:Replace(mapID, x, y, title)
	if uid or usesBlizzard then
		self._currentTomTomUID = uid
		self._lastWP = {mapID = mapID, x = x, y = y, title = title}
		return true
	end
	return false
end

-- Reset a physically selected quest to step 1, then resolve its current automatic result.
function RQE:SelectHybridTrackedQuest(questID)
	questID = tonumber(questID)
	if not self:IsHybridStepNavigation() or not questID or not self.API.IsOnQuest(questID) then return end
	local questData = self.getQuestData(questID)
	if not questData or not questData[1] then return false end
	if self.API.Client.InCombatLockdown() then
		if gameVersion and gameVersion.isClassicEra and self.API.Client.IsMounted
			and self.API.Client.IsMounted() and self.UpdateRQEFrameCombatSafe then
			local previousQuestID = tonumber(self.API.GetSuperTrackedQuestID())
			-- Release preview ownership without removing its waypoint during combat.
			self.ManualStepPreview, self.ManualPreviewQuestID, self.ManualPreviewStepIndex = false, nil, nil
			self:ResetHybridNavigation()
			self.searchedQuestID, self.ManualStepOverrideQLIB = nil, nil
			self.API.SetSuperTrackedQuestID(questID)
			self.DisplayedQuestID = questID
			self.AddonSetStepIndex, self.CurrentStepIndex, self.StoredStepIndex = 1, 1, 1
			self.LastClickedButtonRef, self.LastClickedWaypointButton = nil, nil
			self._coordOrderReselect = nil

			-- Establish the new owner before observers can reconcile the virtual selection.
			local state = navigationState()
			if state then
				state.combatPending = true
				state.pendingFocusMaintenance.previousQuestID = previousQuestID
			end
			self._hybridPendingQuest = {questID = questID, profile = self.db.profile,
				previousQuestID = questID, selectedInCombat = true}
			self:SaveSuperTrackedQuestToCharacter()
			self:UpdateRQEFrameCombatSafe(questID)
			return true
		end
		invalidateWork()
		local state = self._hybridNavigation
		if state then state.pendingManualStep, state.pendingWaypoint = nil, nil end
		self._hybridPendingQuest = {questID = questID, profile = self.db.profile,
			previousQuestID = tonumber(self.API.GetSuperTrackedQuestID())}
		return true
	end
	self:ResetHybridNavigation()
	if self.CancelUnfocusedQuestSelection then self:CancelUnfocusedQuestSelection() end
	self.searchedQuestID, self.ManualStepOverrideQLIB = nil, nil
	self:ClearManualStepPreview(false)
	self:ReleaseActiveCoordblockWaypoint()
	self:ReleaseManualFlightMasterWaypoint()
	self.NearestFlightMasterSet = false
	self.ManualFlightMasterWaypointMapID, self.ManualFlightMasterWaypointQuestID = nil, nil
	self.ManualFlightMasterWaypointStepIndex = nil
	self.ManualSuperTrack, self.ManualSuperTrackedQuestID = true, questID
	self.AddonSetStepIndex, self.CurrentStepIndex, self.StoredStepIndex = 1, 1, 1
	self.LastClickedButtonRef = nil
	self.DisplayedQuestID = questID
	self.DontUpdateFrame, self.ClearButtonPressed = false, false
	self.OkaytoUpdateCreateSteps, self.AllFramesShouldUpdate = true, true
	self._coordOrderReselect = {questID = questID, expiresAt = self.API.Client.GetTime() + 5,
		readyAt = self.API.Client.GetTime(), sameQuest = tonumber(self.API.GetSuperTrackedQuestID()) == questID,
		previousStep = 1, armed = true}
	if legacyClient and self.SyncCarboniteQuestTracking then self:SyncCarboniteQuestTracking(questID, false) end
	self.API.Client.C_SuperTrack.SetSuperTrackedQuestID(questID)
	self:StartHybridPeriodicChecks(questID)
	if legacyClient and self.DisplayClassicQuestLogDetails then self:DisplayClassicQuestLogDetails(questID) end
	self:SaveSuperTrackedQuestToCharacter()
	if UpdateRQEQuestFrame then UpdateRQEQuestFrame() end
	refreshControls()
	return true
end

-- Finish deferred empty-focus upkeep once, allowing nearest selection to replace the cleared quest.
local function refreshUntrackedFocus()
	local pending = RQE._hybridPendingUntrack
	if not pending or RQE.API.Client.InCombatLockdown() then return end
	RQE._hybridPendingUntrack = nil
	if not RQE:IsHybridStepNavigation() or pending.profile ~= RQE.db.profile
		or (tonumber(RQE.API.GetSuperTrackedQuestID()) or 0) ~= 0 then return end
	if RQE.CanNavigateSearchedQuestSteps and RQE:CanNavigateSearchedQuestSteps(RQE.searchedQuestID) then return end
	-- Retain failed maintenance for the next trigger instead of losing the untrack request.
	local ok, err = pcall(function()
		if RQE.RefreshHybridFocusMaintenance
			and not RQE:RefreshHybridFocusMaintenance(0, pending.previousQuestID) then return end
		-- A nearest-quest selection may synchronously start another focus context.
		if (tonumber(RQE.API.GetSuperTrackedQuestID()) or 0) > 0 then
			RQE:QueueHybridPeriodicChecks("nearest-focus", 0.20)
			return
		end
		if RQE.ClearSeparateFocusFrame then RQE:ClearSeparateFocusFrame() end
		if UpdateFrame then UpdateFrame() end
	end)
	if not ok then
		RQE._hybridFocusError = err
		if (tonumber(RQE.API.GetSuperTrackedQuestID()) or 0) == 0 then RQE._hybridPendingUntrack = pending end
	end
end

-- Reconcile a client focus change without invoking the legacy handlers' direct step resets.
function RQE:HandleHybridSuperTracking()
	local questID = tonumber(self.API.GetSuperTrackedQuestID()) or 0
	local state = self._hybridNavigation
	local previousQuestID = state and state.questID or self._hybridObservedQuestID
		or tonumber(self.previousSuperTrackedQuestID)
	local firstObservation = self._hybridObservedQuestID == nil
	local data = questID > 0 and self.getQuestData(questID)
	if questID > 0 and (not self.API.IsOnQuest(questID) or not data or not data[1]) then
		self:ResetHybridNavigation()
		return false
	end
	state = navigationState()
	self.LastSuperTrackedQuestID, self.previousSuperTrackedQuestID = questID, questID
	self.currentSuperTrackedQuestID, self._hybridObservedQuestID = questID, questID
	if state then
		self:QueueHybridPeriodicChecks("focus", 0.20, questID)
	elseif questID == 0 then
		if firstObservation or previousQuestID ~= 0 then
			self._hybridPendingUntrack = {profile = self.db.profile, previousQuestID = previousQuestID}
		end
		refreshUntrackedFocus()
	end
	refreshControls()
	return true
end

-- Observe legacy cached focus changes even when the client emits no native supertracking event.
function RQE:ObserveHybridLegacyFocus()
	if not legacyClient or not self:IsHybridStepNavigation() or self._hybridApplying then return end
	if self.CanNavigateSearchedQuestSteps and self:CanNavigateSearchedQuestSteps(self.searchedQuestID) then return end
	local questID = tonumber(self.API.GetSuperTrackedQuestID()) or 0
	if questID == self._hybridObservedQuestID then return end
	if questID > 0 and not self:CanRunHybridNavigation() and self.API.Client.InCombatLockdown() then return end
	if not self:HandleHybridSuperTracking() then
		-- Cached focus has no guaranteed client event; unknown quests still need their normal renderer.
		if self.handleSuperTracking and tonumber(self.previousSuperTrackedQuestID) ~= questID then
			self.handleSuperTracking()
		end
		self._hybridObservedQuestID = questID
	end
end

-- Observe actual game triggers independently of the previewed step's check type or waypoint preference.
local eventFrame = CreateFrame("Frame")
for _, event in ipairs({"QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "UNIT_QUEST_LOG_CHANGED",
	"BAG_UPDATE_DELAYED", "ITEM_COUNT_CHANGED", "UNIT_AURA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
	"ZONE_CHANGED_NEW_AREA", "PLAYER_MAP_CHANGED", "SCENARIO_UPDATE", "SCENARIO_CRITERIA_UPDATE",
	"QUEST_ACCEPTED", "QUEST_TURNED_IN", "SUPER_TRACKING_CHANGED", "PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_ENABLED", "UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE", "UNIT_SPELLCAST_SUCCEEDED",
	"SPELLS_CHANGED", "MINIMAP_UPDATE_ZOOM", "UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_VEHICLE_ACTIONBAR"}) do
	if legacyClient then
		-- Some Retail-only event names are unavailable on older clients.
		pcall(eventFrame.RegisterEvent, eventFrame, event)
	else
		eventFrame:RegisterEvent(event)
	end
end
if legacyClient then
	for _, event in ipairs({"SUPER_TRACKED_QUEST_CHANGED", "QUEST_REMOVED"}) do
		pcall(eventFrame.RegisterEvent, eventFrame, event)
	end
end
-- Queue relevant observations; unchanged evaluation results leave the manual preview in place.
eventFrame:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_REGEN_ENABLED" then
		local resume = RQE._hybridResumeAutomatic
		RQE._hybridResumeAutomatic = nil
		if resume and resume.profile == RQE.db.profile and RQE:GetStepNavigationMode() == "automatic"
			and resume.questID == RQE.API.GetSuperTrackedQuestID() then RQE:StartPeriodicChecks() end
	end
	if not RQE:IsHybridStepNavigation() then return end
	if event == "PLAYER_REGEN_ENABLED" then
		local pending = RQE._hybridPendingQuest
		RQE._hybridPendingQuest = nil
		-- A later search preview supersedes finalization of an already-selected combat quest.
		local searchOwnsDisplay = pending and pending.selectedInCombat and RQE.CanNavigateSearchedQuestSteps
			and RQE:CanNavigateSearchedQuestSteps(RQE.searchedQuestID)
		if pending and pending.profile == RQE.db.profile
			and not searchOwnsDisplay
			and pending.previousQuestID == tonumber(RQE.API.GetSuperTrackedQuestID()) then
			local selectedState = pending.selectedInCombat and RQE._hybridNavigation
			local ownsSelection = selectedState and selectedState.profile == pending.profile
				and selectedState.questID == pending.questID
			local pendingStep = ownsSelection and selectedState.pendingManualStep
			local pendingWaypoint = ownsSelection and selectedState.pendingWaypoint
			RQE:SelectHybridTrackedQuest(pending.questID)
			-- Keep later actions for the quest already selected during mounted Classic combat.
			local resumedState = RQE._hybridNavigation
			if ownsSelection and resumedState and resumedState.profile == pending.profile
				and resumedState.questID == pending.questID then
				resumedState.pendingManualStep, resumedState.pendingWaypoint = pendingStep, pendingWaypoint
			end
		end
		refreshUntrackedFocus()
		local state = navigationState()
		if state then
			local stepIndex, waypoint = state.pendingManualStep, state.pendingWaypoint
			state.pendingManualStep, state.pendingWaypoint = nil, nil
			if stepIndex then RQE:SetDisplayedStepFromStepsList(stepIndex) end
			if waypoint then RQE:ActivateHybridWaypoint(true) end
		end
		refreshControls()
	end
	if (event == "UNIT_AURA" or event == "UNIT_QUEST_LOG_CHANGED" or event == "UNIT_ENTERED_VEHICLE"
		or event == "UNIT_EXITED_VEHICLE" or event == "UNIT_SPELLCAST_SUCCEEDED") and unit ~= "player" then return end
	if legacyClient then RQE:ObserveHybridLegacyFocus() end
	RQE:QueueHybridPeriodicChecks(event, 0.20)
end)

-- Inspect authored condition fields without duplicating any distance-check evaluation logic.
local function usesDistance(value)
	if type(value) == "string" then return value:find("CheckCoordinateDistance", 1, true) ~= nil end
	if type(value) ~= "table" then return false end
	for _, field in ipairs({"cond", "check", "failedcheck", "checks", "failedchecks"}) do
		if usesDistance(value[field]) then return true end
	end
	for _, entry in ipairs(value) do
		if usesDistance(entry) then return true end
	end
	return false
end

local elapsedSinceCheck = 0
-- Distance requirements need movement observations even when their step is not being previewed.
eventFrame:SetScript("OnUpdate", function(_, elapsed)
	if not RQE:IsHybridStepNavigation() then return end
	elapsedSinceCheck = elapsedSinceCheck + elapsed
	if elapsedSinceCheck < 0.50 then return end
	elapsedSinceCheck = 0
	if legacyClient then RQE:ObserveHybridLegacyFocus() end
	local questID, data = focusedQuest()
	if not questID then return end
	if usesDistance(data) then RQE:QueueHybridPeriodicChecks("distance", 0.20, questID) end
end)
