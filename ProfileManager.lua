---------------------------------------------------
-- Shared Profile Application and Persistence Guards
---------------------------------------------------

-- Frames are constructed before AceDB and the game world are ready. Never
-- persist that provisional layout, including when login/reload enters combat.
RQE.ProfileApplyPending = true
RQE.ProfileWorldReady = false
RQE.PendingTrackerStateRestore = true

local validAnchors = {
	TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true,
	RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

-- Only live, fully restored geometry belongs in the active profile. In
-- particular, OnSizeChanged fires synchronously while applying another profile.
function RQE:CanSaveFrameGeometry()
	return self.ProfileWorldReady and self.db and self.db.profile
		and not self.ProfileApplyPending and not self.ApplyingProfile
		and self.AppliedProfile == self.db.profile and not InCombatLockdown()
end


-- Apply the selected profile as one guarded operation. Read both layouts before
-- touching either frame; resize callbacks must not mutate our source values.
function RQE:ApplyCurrentProfile()
	if self.ApplyingProfile or not self.ProfileWorldReady or not self.db
		or not RQEFrame or not self.RQEQuestFrame or InCombatLockdown() then
		return false
	end

	local profile = self.db.profile
	self.ApplyingProfile = true
	local success, err = pcall(function()
		local helper = { self:GetFrameGeometry("RQEFrame") }
		local tracker = { self:GetFrameGeometry("RQEQuestFrame") }
		local function RestoreGeometry(frame, geometry, frameName)
			local anchor, x, y, width, height = unpack(geometry)
			-- Retain position validation from the old individual restore paths.
			-- A malformed anchor must not prevent all remaining settings applying.
			if not validAnchors[anchor] then
				anchor = self.FrameGeometryDefaults[frameName].anchorPoint
			end
			frame:ClearAllPoints()
			frame:SetPoint(anchor, UIParent, anchor, x, y)
			frame:SetSize(width, height)
		end

		RestoreGeometry(RQEFrame, helper, "RQEFrame")
		RestoreGeometry(self.RQEQuestFrame, tracker, "RQEQuestFrame")
		-- Minimize is session state, not a different saved full-size layout.
		-- Refresh its expansion cache when switching profiles while collapsed.
		if self.QTMinimized then
			self.QToriginalWidth, self.QToriginalHeight = tracker[4], tracker[5]
			self.RQEQuestFrame:SetHeight((self.UI and self.UI:IsEnabled()) and 48 or 30)
		end

		-- Theme selection retains its existing reload requirement. Apply the
		-- session theme once, then restore the selected profile's fonts/opacity.
		if not self.ProfileThemeApplied and self.UI and self.UI.ApplySavedTheme then
			self.UI:ApplySavedTheme()
			self.ProfileThemeApplied = true
		end
		self:ApplyUISettings()
		self:ConfigurationChanged()
		self:UpdateCoordinates()
		self:ToggleMinimapIcon()
		self:UpdateMinimapButtonPosition()
		-- Close-button session flags must not overrule a newly selected profile.
		self.isRQEFrameManuallyClosed = not profile.enableFrame
		self.isRQEQuestFrameManuallyClosed = not profile.enableQuestFrame
		-- Scenario mode can replace Show with a no-op. Remove the previous
		-- profile's suppression before the selected profile decides visibility.
		if self.RQEQuestFrame._originalShow then
			self.RQEQuestFrame.Show = self.RQEQuestFrame._originalShow
			self.RQEQuestFrame._originalShow = nil
		end
		self.forceHideRQEQuestFrame = false
		self:CheckFrameVisibility()
		self:UpdateTrackerVisibility()
		self.Buttons.UpdateHeaderNavigation()
		self:SetupOverrideMacroBinding()
		-- Diagnostic tickers read the new profile themselves. Clear stale text
		-- immediately when disabled without changing the global CPU-profiling CVar.
		if not profile.displayRQEmemUsage and RQEFrame.MemoryUsageText then
			RQEFrame.MemoryUsageText:SetText("")
		end
		if not profile.displayRQEcpuUsage and RQEFrame.CPUUsageText then
			RQEFrame.CPUUsageText:SetText("")
		end

		-- Refresh actual registered pages after profile changes, but do not
		-- rebuild the controls underneath a player dragging a geometry slider.
		if self.AppliedProfile ~= profile or self.ProfileSettingsChanged then
			local registry = LibStub("AceConfigRegistry-3.0")
			for _, name in ipairs({ "RQE_Main", "RQE_Frame", "RQE_Font", "RQE_Debug", "RQE_Profiles" }) do
				registry:NotifyChange(name)
			end
		end
	end)
	self.ApplyingProfile = false
	if not success then
		-- Leave the save guard armed on failure; never commit half-restored UI.
		geterrorhandler()(err)
		return false
	end
	if self.db.profile ~= profile then return false end
	self.AppliedProfile = profile
	self.ProfileSettingsChanged = nil
	self.ProfileApplyPending = false
	return true
end


-- Used by startup, profile callbacks, and configuration geometry edits. A
-- combat-delayed request deliberately keeps no reference to the old profile.
function RQE:RequestProfileApply()
	self.ProfileApplyPending = true
	return self:ApplyCurrentProfile()
end


-- Keep restoration independent of the large gameplay event handlers: an
-- unrelated login error must not consume the only opportunity to retry it.
local profileEvents = CreateFrame("Frame")
profileEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
profileEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
profileEvents:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		RQE.ProfileWorldReady = true
		RQE.ProfileApplyPending = true
		if not RQE.CharacterStateRestoreScheduled then
			RQE.CharacterStateRestoreScheduled = true
			-- Schedule before any gameplay refresh can fail in combat. Quest-log
			-- restoration starts after world entry, not while still loading.
			C_Timer.After(0.6, function()
				RQE:RestoreTrackedQuestsForCharacter()
				RQE:RestoreSuperTrackedQuestForCharacter()
			end)
		end
	end
	-- Allow Blizzard's world/layout initialization to finish first. The guard
	-- stays armed while queued, and combat is checked again at execution time.
	C_Timer.After(0, function()
		if RQE.ProfileApplyPending then RQE:ApplyCurrentProfile() end
		if RQE.ReapplyMacroBindingAfterCombat and not InCombatLockdown() then
			RQE:SetupOverrideMacroBinding()
		end
	end)
end)
