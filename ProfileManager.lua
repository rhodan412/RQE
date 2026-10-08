--[[

ProfileManager.lua
Shared profile application, frame geometry restoration, and persistence safeguards

]]


--------------------------------------------------
-- #1. 🧭 Profile Runtime State & Validation
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Application & Restoration Flags
	-------------------------------------------------------

	-- Frames are constructed before AceDB and the game world are ready. Never
	-- persist that provisional layout, including when login/reload enters combat.
	RQE.ProfileApplyPending = true
	RQE.ProfileWorldReady = false
	RQE.PendingTrackerStateRestore = true

	-------------------------------------------------------
	-- #1b. Supported Frame Anchors
	-------------------------------------------------------

	local validAnchors = {
		TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true,
		RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
	}


--------------------------------------------------
-- #2. 💾 Frame Geometry Persistence
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Geometry Save Guard
	-------------------------------------------------------

	-- Only live, fully restored geometry belongs in the active profile. In
	-- particular, OnSizeChanged fires synchronously while applying another profile.
	function RQE:CanSaveFrameGeometry()
		return self.ProfileWorldReady and self.db and self.db.profile
			and not self.ProfileApplyPending and not self.ApplyingProfile
			-- Previous Blizzard call changed 2026.09.25: and self.AppliedProfile == self.db.profile and not InCombatLockdown()
			and self.AppliedProfile == self.db.profile and not RQE.API.Client.InCombatLockdown()
	end


--------------------------------------------------
-- #2b. Login Frame Settings Restore Point
--------------------------------------------------

	-- Restore Frame Settings layout controls while retaining the current locks.
	-- Themes/fonts, quest state, automation, key bindings, diagnostics, and
	-- profile assignments are outside this restore point.
	local loginFrameSettingKeys = {
		"framePosition", "QuestFramePosition",
		"enableFrame", "enableQuestFrame", "hideRQEFrameWhenEmpty", "hideRQEQuestFrameWhenEmpty",
		"enableCreatureObjectPreview", "creatureObjectPreviewPosition",
	}

	-- Copy values without AceDB metatables or references to mutable live settings.
	local function CopyLoginFrameValue(value)
		if type(value) ~= "table" then return value end
		local copy = {}
		for key, child in pairs(value) do copy[key] = CopyLoginFrameValue(child) end
		return copy
	end

	-- PLAYER_ENTERING_WORLD distinguishes a character login from /reload. Retain
	-- a separate character-saved copy across reloads; replace it only on login.
	function RQE:InitializeLoginFrameSettings(isInitialLogin, isReloadingUi)
		if self.LoginFrameSettings then return true end
		if not self.db or not self.db.profile then return false end
		RQECharacterDB = RQECharacterDB or {}
		local saved = RQECharacterDB.loginFrameSettings
		if not isInitialLogin and isReloadingUi and type(saved) == "table"
			and saved.version == 1 and type(saved.settings) == "table" then
			self.LoginFrameSettings = CopyLoginFrameValue(saved)
			return true
		end

		local settings = {}
		for _, key in ipairs(loginFrameSettingKeys) do
			settings[key] = CopyLoginFrameValue(self.db.profile[key])
		end
		-- The Frame Settings opacity sliders are stored per theme. Capture their
		-- effective values, then restore them for whichever theme is selected later.
		-- The getter's legacy migration is data-only, including during combat.
		if self.UI and self.UI.GetFrameBackgroundOpacity then
			settings.MainFrameOpacity = self.UI:GetFrameBackgroundOpacity("main")
			settings.QuestFrameOpacity = self.UI:GetFrameBackgroundOpacity("tracker")
		else
			settings.MainFrameOpacity = self.db.profile.MainFrameOpacity
			settings.QuestFrameOpacity = self.db.profile.QuestFrameOpacity
		end
		-- Freeze resolved defaults as well as explicit settings, rather than
		-- sampling provisional frame geometry during the loading screen.
		for frameName, key in pairs({ RQEFrame = "framePosition", RQEQuestFrame = "QuestFramePosition" }) do
			local anchor, x, y, width, height = self:GetFrameGeometry(frameName)
			settings[key] = settings[key] or {}
			settings[key].anchorPoint = validAnchors[anchor] and anchor or self.FrameGeometryDefaults[frameName].anchorPoint
			settings[key].xPos, settings[key].yPos = x, y
			settings[key].frameWidth, settings[key].frameHeight = width, height
		end
		self.LoginFrameSettings = { version = 1, settings = settings }
		RQECharacterDB.loginFrameSettings = CopyLoginFrameValue(self.LoginFrameSettings)
		return true
	end

	-- Restore into the active account-wide AceDB profile. A fresh copy on every
	-- use keeps this restore point unchanged by later moves, sliders, or themes.
	function RQE:RestoreLoginFrameSettings()
		local snapshot = self.LoginFrameSettings
		if not snapshot or not self.db or not self.db.profile then
			print("RQE: Frame settings from login are not available yet.")
			return false
		end
		for _, key in ipairs(loginFrameSettingKeys) do
			-- Also remove overrides that did not exist at login.
			self.db.profile[key] = CopyLoginFrameValue(snapshot.settings[key])
		end
		local theme = self.UI and self.UI.GetSelectedTheme and self.UI:GetSelectedTheme() or "Basic"
		if theme == "Basic" then
			self.db.profile.MainFrameOpacity = snapshot.settings.MainFrameOpacity
			self.db.profile.QuestFrameOpacity = snapshot.settings.QuestFrameOpacity
		else
			-- Update only the selected theme's frame backgrounds. Theme selection,
			-- fonts, artwork, and the opacity settings for other themes stay intact.
			if self.UI.InitializeFrameBackgroundOpacityBank then self.UI:InitializeFrameBackgroundOpacityBank() end
			local profile = self.db.profile
			profile.themeFrameBackgroundOpacity = profile.themeFrameBackgroundOpacity or {}
			profile.themeFrameBackgroundOpacity[theme] = profile.themeFrameBackgroundOpacity[theme] or {}
			local opacity = profile.themeFrameBackgroundOpacity[theme]
			opacity.main, opacity.tracker = snapshot.settings.MainFrameOpacity, snapshot.settings.QuestFrameOpacity
		end
		self.ProfileSettingsChanged = true
		self:RequestProfileApply()
		if RQE.API.Client.InCombatLockdown() then
			print("RQE: Frame settings from login restored; frames will update after combat.")
		else
			print("RQE: Restored frame settings from login.")
		end
		return true
	end


--------------------------------------------------
-- #3. 🎛️ Guarded Profile Application
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Full Profile Restore
	-------------------------------------------------------

	-- Apply the selected profile as one guarded operation. Read both layouts before
	-- touching either frame; resize callbacks must not mutate our source values.
	function RQE:ApplyCurrentProfile()
		if self.ApplyingProfile or not self.ProfileWorldReady or not self.db
			-- Previous Blizzard call changed 2026.09.25: or not RQEFrame or not self.RQEQuestFrame or InCombatLockdown() then
			or not RQEFrame or not self.RQEQuestFrame or RQE.API.Client.InCombatLockdown() then
			return false
		end

		local profile = self.db.profile
		self.ApplyingProfile = true
		local success, err = pcall(function()
			local helper = { self:GetFrameGeometry("RQEFrame") }
			local tracker = { self:GetFrameGeometry("RQEQuestFrame") }
			-- Restores one frame's validated anchor and saved dimensions during the guarded profile application.
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
			if self.SetRQEFrameLocked then
				self.SetRQEFrameLocked(profile.lockRQEFrame == true, false)
			end
			if self.SetRQEQuestFrameLocked then
				self.SetRQEQuestFrameLocked(profile.lockRQEQuestFrame == true, false)
			end
			-- Minimize is session state, not a different saved full-size layout.
			-- Refresh its expansion cache when switching profiles while collapsed.
			if self.QTMinimized then
				self.QToriginalWidth, self.QToriginalHeight = tracker[4], tracker[5]
				self.RQEQuestFrame:SetHeight((self.UI and self.UI:IsEnabled()) and 48 or 30)
			end

			-- A profile can select a different tracker theme; apply it before the
			-- profile's fonts and opacity so no reload is needed.
			if self.UI and self.UI.ApplySavedTheme then
				self.UI:ApplySavedTheme()
			end
			self:ApplyUISettings()
			self:ConfigurationChanged()
			if self.RefreshTrackerSectionOrder then self:RefreshTrackerSectionOrder() end
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
			if self.ApplyCreatureObjectPreviewLayout then self.ApplyCreatureObjectPreviewLayout() end
			if profile.enableCreatureObjectPreview == false and self.HideCreatureObjectPreview then
				self.HideCreatureObjectPreview()
			end
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
				for _, name in ipairs({ "RQE_Main", "RQE_Frame", "RQE_Themes", "RQE_Font", "RQE_Debug", "RQE_Profiles" }) do
					registry:NotifyChange(name)
				end
			end
		end)
		self.ApplyingProfile = false
		if not success then
			-- Leave the save guard armed on failure; never commit half-restored UI.
			-- Previous Blizzard call changed 2026.09.25: geterrorhandler()(err)
			RQE.API.Client.geterrorhandler()(err)
			return false
		end
		if self.db.profile ~= profile then return false end
		self.AppliedProfile = profile
		self.ProfileSettingsChanged = nil
		self.ProfileApplyPending = false
		return true
	end

	-------------------------------------------------------
	-- #3b. Profile Apply Requests
	-------------------------------------------------------

	-- Used by startup, profile callbacks, and configuration geometry edits. A
	-- combat-delayed request deliberately keeps no reference to the old profile.
	function RQE:RequestProfileApply()
		self.ProfileApplyPending = true
		return self:ApplyCurrentProfile()
	end


--------------------------------------------------
-- #4. 🔄 World Entry & Combat Recovery
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Profile Lifecycle Event Frame
	-------------------------------------------------------

	-- Keep restoration independent of the large gameplay event handlers: an
	-- unrelated login error must not consume the only opportunity to retry it.
	local profileEvents = CreateFrame("Frame")
	profileEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
	profileEvents:RegisterEvent("PLAYER_REGEN_ENABLED")

	-------------------------------------------------------
	-- #4b. Deferred Profile & Character-State Restoration
	-------------------------------------------------------

	profileEvents:SetScript("OnEvent", function(_, event, isInitialLogin, isReloadingUi)
		if event == "PLAYER_ENTERING_WORLD" then
			RQE:InitializeLoginFrameSettings(isInitialLogin, isReloadingUi)
			RQE.ProfileWorldReady = true
			RQE.ProfileApplyPending = true
			if not RQE.CharacterStateRestoreScheduled then
				RQE.CharacterStateRestoreScheduled = true
				-- Schedule before any gameplay refresh can fail in combat. Quest-log
				-- restoration starts after world entry, not while still loading.
				-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.6, function()
				RQE.API.Client.C_Timer.After(0.6, function()
					RQE:RestoreTrackedQuestsForCharacter()
					RQE:RestoreSuperTrackedQuestForCharacter()
				end)
			end
		end
		-- Allow Blizzard's world/layout initialization to finish first. The guard
		-- stays armed while queued, and combat is checked again at execution time.
		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0, function()
		RQE.API.Client.C_Timer.After(0, function()
			if RQE.ProfileApplyPending then RQE:ApplyCurrentProfile() end
			-- Previous Blizzard call changed 2026.09.25: if RQE.ReapplyMacroBindingAfterCombat and not InCombatLockdown() then
			if RQE.ReapplyMacroBindingAfterCombat and not RQE.API.Client.InCombatLockdown() then
				RQE:SetupOverrideMacroBinding()
			end
		end)
	end)
