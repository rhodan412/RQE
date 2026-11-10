--[[

QuestTools.lua
Shared quest selection, styled filter and context menus, and copyable quest-reference links

]]


--------------------------------------------------
-- #1. 🧰 Shared Quest-Tool State & Helpers
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Namespace, Menu State & Restorable Selection Fields
	-------------------------------------------------------

	-- Shared quest-selection and right-click menus, plus copyable reference links.
	-- Quest ordering and search matching remain owned by each client's tracker.
	local RQE = RQE
	local menus = {}
	local stateKeys = {
		"ShowAllQuestLogQuests", "ZoneQuestFilterMapID", "HiddenQuestLogQuests",
		"ShowOnlyAllCompleteVirtualQuests", "AllCompleteVirtualQuestWatches",
		"ClassicVirtualQuestWatches", "ClassicManualVirtualQuestWatches",
		"AutoQuestProgressVirtualWatches", "AutoQuestProgressWatchTokens",
		"QuestTrackerSearchResults", "QuestTrackerSearchRestoreState", "QuestMenuSelection",
	}

	-------------------------------------------------------
	-- #1b. Shared Data & Client API Helpers
	-------------------------------------------------------

	-- Creates a recursive copy so saved selection snapshots cannot be changed through shared table references.
	local function Copy(value)
		if type(value) ~= "table" then return value end
		local result = {}
		for key, child in pairs(value) do result[key] = Copy(child) end
		return result
	end

	-- Reports whether the active client uses RQE's virtual quest-watch compatibility layer.
	local function LegacyTracker()
		return type(RQE.AddClassicVirtualQuestWatch) == "function"
	end

	-- Resolves and invokes an optional client API without assuming it exists on every supported client.
	local function ClientCall(path, ...)
		local fn = RQE.API.ResolveClientAPI(path)
		if type(fn) == "function" then return fn(...) end
	end

	-- Collects ordinary quest-log entries while excluding headers, tasks, and world quests.
	local function QuestLogEntries()
		local result = {}
		for index = 1, RQE.API.GetNumQuestLogEntries() or 0 do
			local info = RQE.API.GetQuestLogInfo(index)
			local id = info and tonumber(info.questID)
			if id and not info.isHeader and not info.isTask
				and not (RQE.API.IsWorldQuest and RQE.API.IsWorldQuest(id)) then
				result[#result + 1] = info
			end
		end
		return result
	end

	-- Determines turn-in readiness through the best available client API, with objective completion as a fallback.
	local function ReadyForTurnIn(info)
		if info.isComplete == -1 then return false end
		local ready = ClientCall("C_QuestLog.ReadyForTurnIn", info.questID)
		if ready ~= nil then return ready == true or ready == 1 end
		local complete = ClientCall("C_QuestLog.IsComplete", info.questID)
		if complete ~= nil then return complete == true or complete == 1 end
		if info.isComplete == true or info.isComplete == 1 then return true end
		local objectives = RQE.API.GetQuestObjectives(info.questID) or {}
		if #objectives == 0 then return false end
		for _, objective in ipairs(objectives) do
			if objective.finished ~= true and objective.finished ~= 1 then return false end
		end
		return true
	end

	local instanceTags = { [62] = true, [81] = true, [85] = true,
		[88] = true, [89] = true, [98] = true, [288] = true }
	local autoCategoryChoices = {
		{ key = "campaign", text = "Auto-track Campaign", kind = "campaign", retailOnly = true },
		{ key = "meta", text = "Auto-track Meta", kind = "meta", retailOnly = true },
		{ key = "frequency", text = "Auto-track Daily / Weekly", kind = "frequency" },
		{ key = "instance", text = "Auto-track Instance", kind = "instance" },
	}

	-- Retail meta quests have their own classification, independent of daily/weekly frequency.
	local function IsRetailMetaQuest(questID)
		return RQE.IsRetail and ClientCall("C_QuestLog.IsMetaQuest", questID) == true
	end

	-- Identifies quests marked as daily or weekly repeatable quests.
	local function IsDailyOrWeeklyQuest(info)
		local frequency = info.frequency
		local daily = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily or 1
		local weekly = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Weekly or 2
		return frequency == daily or frequency == weekly
	end



--------------------------------------------------
-- #2. 🎯 Quest Matching & Watch Selection
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Quest-Log Matching & Result Counts
	-------------------------------------------------------

	-- Builds a quest-ID set matching the requested menu filter across supported clients.
	function RQE:GetQuestMenuMatches(kind, value)
		local result = {}
		local zoneSet = {}
		if kind == "zone" and value then
			self.ScanAndCacheZoneQuests()
			for _, id in ipairs(self.ZoneQuests[value] or {}) do zoneSet[id] = true end
		end
		if kind == "line" then
			local line = self.QuestLines and self.QuestLines[value]
			for _, id in ipairs(line and line.quests or {}) do zoneSet[id] = true end
		end
		for _, info in ipairs(QuestLogEntries()) do
			local id, matches = info.questID, false
			if kind == "all" then matches = true
			elseif kind == "zone" then matches = zoneSet[id] == true
			elseif kind == "ready" then matches = ReadyForTurnIn(info)
			elseif kind == "incomplete" then matches = not ReadyForTurnIn(info)
			elseif kind == "frequency" then matches = IsDailyOrWeeklyQuest(info)
			elseif kind == "meta" then matches = IsRetailMetaQuest(id)
			elseif kind == "meta-frequency" then
				matches = RQE.IsRetail and (IsDailyOrWeeklyQuest(info) or IsRetailMetaQuest(id))
			elseif kind == "campaign" then
				local campaignID = ClientCall("C_CampaignInfo.GetCampaignID", id) or info.campaignID
				matches = value and campaignID == value or (not value
					and (ClientCall("C_CampaignInfo.IsCampaignQuest", id) == true
						or (tonumber(campaignID) or 0) > 0))
			elseif kind == "instance" then
				local tag = ClientCall("C_QuestLog.GetQuestTagInfo", id)
				local questType = ClientCall("C_QuestLog.GetQuestType", id)
				matches = instanceTags[tag and tag.tagID] or instanceTags[questType] or false
			elseif kind == "type" then
				local questType = ClientCall("C_QuestLog.GetQuestType", id)
				matches = value == "Misc" and (questType == 0 or questType == 261
					or questType == 270 or questType == 282) or questType == value
			elseif kind == "line" then
				matches = zoneSet[id] == true
			end
			if matches then result[id] = true end
		end
		return result
	end

	-- Counts the keys in a set-style table for live menu result totals.
	local function Count(set)
		local count = 0
		for _ in pairs(set) do count = count + 1 end
		return count
	end

	-- Auto categories are profile choices; unsupported Retail categories never activate on legacy clients.
	function RQE:HasAutoQuestCategories()
		local enabled = self.db and self.db.profile and self.db.profile.autoTrackQuestCategories or {}
		for _, choice in ipairs(autoCategoryChoices) do
			if (not choice.retailOnly or self.IsRetail) and enabled[choice.key] then return true end
		end
		return false
	end

	-- Returns the auto quest category matches.
	function RQE:GetAutoQuestCategoryMatches()
		local selected = {}
		local enabled = self.db.profile.autoTrackQuestCategories or {}
		for _, choice in ipairs(autoCategoryChoices) do
			if (not choice.retailOnly or self.IsRetail) and enabled[choice.key] then
				for questID in pairs(self:GetQuestMenuMatches(choice.kind)) do selected[questID] = true end
			end
		end
		return selected
	end

	-- Checks whether two quest-ID sets contain the same entries.
	local function SameSet(a, b)
		for id in pairs(a or {}) do if not b[id] then return false end end
		for id in pairs(b or {}) do if not a or not a[id] then return false end end
		return true
	end

	-------------------------------------------------------
	-- #2b. Native & Legacy Watch Synchronization
	-------------------------------------------------------

	-- Captures Blizzard's currently watched quest IDs as a set.
	local function NativeWatches()
		local result = {}
		for index = 1, ClientCall("C_QuestLog.GetNumQuestWatches") or 0 do
			local id = ClientCall("C_QuestLog.GetQuestIDForQuestWatchIndex", index)
			if id then result[id] = true end
		end
		return result
	end

	-- Diffs the desired selection against native watches without disturbing unrelated tracker sources.
	local function SetNativeWatches(selected, previousSelection)
		local watched = NativeWatches()
		local inLog = {}
		-- Only player-log quests belong to this menu; other tracker sources retain
		-- their watches. Apply a diff so unchanged watches do not generate events.
		for _, info in ipairs(QuestLogEntries()) do
			local id = info.questID
			inLog[id] = true
			if watched[id] and not selected[id] then ClientCall("C_QuestLog.RemoveQuestWatch", id)
			elseif selected[id] and not watched[id] then ClientCall("C_QuestLog.AddQuestWatch", id) end
		end
		-- A removed quest may linger in Blizzard's watched list briefly. Only
		-- clean up IDs previously selected by this automatic category mode.
		for id in pairs(previousSelection or {}) do
			if not inLog[id] and not RQE.API.IsOnQuest(id)
				and watched[id] and not selected[id] then
				ClientCall("C_QuestLog.RemoveQuestWatch", id)
			end
		end
	end

	-- Checks whether native quest watches still match the saved selection.
	local function NativeSelectionMatches(selected, previousSelection)
		local watched = NativeWatches()
		for _, info in ipairs(QuestLogEntries()) do
			local id = info.questID
			if (watched[id] == true) ~= (selected[id] == true) then return false end
		end
		for id in pairs(previousSelection or {}) do
			if watched[id] and not selected[id] and not RQE.API.IsOnQuest(id) then return false end
		end
		return true
	end

	-- Saves the explicit virtual-watch selection after legacy restoration has completed.
	local function PersistLegacySelection()
		if LegacyTracker() and RQECharacterDB and not RQE.PendingTrackerStateRestore then
			RQECharacterDB.rqeQuestMenuSelection = Copy(RQE.QuestMenuSelection)
		end
	end

	-- Rebuilds the tracker after a selection change while preserving focus, scroll position, and saved watches.
	local function RefreshTracker(focused)
		RQE:ClearRQEQuestFrame()
		UpdateRQEQuestFrame()
		if SortQuestsByProximity then SortQuestsByProximity() end
		-- Membership changes do not request a different helper quest or route.
		if focused and focused > 0 and RQE.API.IsOnQuest(focused)
			and RQE.API.GetSuperTrackedQuestID() ~= focused and RQE.AutoSetSuperTrackedQuestID then
			RQE:AutoSetSuperTrackedQuestID(focused)
		end
		if RQE.QuestScrollFrameToTop then RQE.QuestScrollFrameToTop(true) end
		if RQE.SaveTrackedQuestsToCharacter then RQE:SaveTrackedQuestsToCharacter() end
		PersistLegacySelection()
	end

	-------------------------------------------------------
	-- #2c. Selection Capture, Application & Restoration
	-------------------------------------------------------

	-- Snapshots native and RQE tracking state so an explicit menu selection can later be restored.
	function RQE:CaptureQuestMenuTracking()
		local snapshot = { nativeWatches = NativeWatches(),
			autoTrackZoneQuests = self.db.profile.autoTrackZoneQuests,
			autoTrackQuestCategories = Copy(self.db.profile.autoTrackQuestCategories),
			lastAction = self.QuestMenuLastAction }
		for _, key in ipairs(stateKeys) do snapshot[key] = Copy(self[key]) end
		self.QuestMenuRestoreState = snapshot
	end

	-- Restores RQE-owned selection fields and automatic-zone state from a captured snapshot.
	local function RestoreSnapshotFields(snapshot)
		for _, key in ipairs(stateKeys) do RQE[key] = Copy(snapshot[key]) end
		RQE.db.profile.autoTrackZoneQuests = snapshot.autoTrackZoneQuests
		RQE.db.profile.autoTrackQuestCategories = Copy(snapshot.autoTrackQuestCategories) or {}
		RQE.QuestMenuLastAction = snapshot.lastAction
		if RQE.UpdateQuestTrackerSearchRestoreButton then RQE:UpdateQuestTrackerSearchRestoreButton() end
	end

	-- Disables automatic and search-driven membership before applying an explicit selection.
	local function PrepareManualSelection()
		RQE.db.profile.autoTrackZoneQuests = false
		RQE.db.profile.autoTrackQuestCategories = {}
		RQE.AutoQuestCategorySelected = nil
		RQE.QuestTrackerSearchResults, RQE.QuestTrackerSearchRestoreState = nil, nil
		if RQE.UpdateQuestTrackerSearchRestoreButton then RQE:UpdateQuestTrackerSearchRestoreButton() end
	end

	-- Reconcile only ordinary quest-log membership; world quests and bonus objectives remain independent.
	function RQE:ReconcileAutoQuestCategories(force)
		if not self:HasAutoQuestCategories() or self.db.profile.autoTrackZoneQuests then return false end
		if ClientCall("InCombatLockdown") then
			self.AutoQuestCategoryRefreshPending = true
			return false
		end
		self.AutoQuestCategoryRefreshPending = false
		local selected = self:GetAutoQuestCategoryMatches()
		local focused = self.API.GetSuperTrackedQuestID and self.API.GetSuperTrackedQuestID()
		if LegacyTracker() then
			-- An explicit empty selection must still replace nil, which otherwise
			-- falls through to native and virtual quest watches on legacy clients.
			if not force and self.QuestMenuSelection ~= nil
				and SameSet(self.QuestMenuSelection, selected) then return false end
			self.QuestMenuSelection = selected
			self.ClassicVirtualQuestWatches = Copy(selected)
			self.ClassicManualVirtualQuestWatches = Copy(selected)
			self.AutoQuestProgressVirtualWatches, self.AutoQuestProgressWatchTokens = {}, {}
			self.HiddenQuestLogQuests = {}
			self.ShowAllQuestLogQuests, self.ZoneQuestFilterMapID = false, nil
			self.ShowOnlyAllCompleteVirtualQuests = false
		else
			if not force and NativeSelectionMatches(selected, self.AutoQuestCategorySelected) then
				self.AutoQuestCategorySelected = Copy(selected)
				return false
			end
			SetNativeWatches(selected, self.AutoQuestCategorySelected)
			self.AutoQuestCategorySelected = Copy(selected)
		end
		RefreshTracker(focused)
		return true
	end

	-- Queues the auto quest category refresh.
	function RQE:QueueAutoQuestCategoryRefresh(delay)
		if not self:HasAutoQuestCategories() or self.db.profile.autoTrackZoneQuests
			or self.AutoQuestCategoryRefreshQueued then return end
		self.AutoQuestCategoryRefreshQueued = true
		-- Clears the queued flag and reconciles automatic quest-category tracking.
		self.API.Client.C_Timer.After(delay or 0.4, function()
			self.AutoQuestCategoryRefreshQueued = false
			self:ReconcileAutoQuestCategories()
		end)
	end

	-- Toggles the auto quest category.
	function RQE:ToggleAutoQuestCategory(key)
		if ClientCall("InCombatLockdown") then return false end
		local choice
		for _, candidate in ipairs(autoCategoryChoices) do
			if candidate.key == key then choice = candidate; break end
		end
		if not choice or (choice.retailOnly and not self.IsRetail) then return false end
		local profile = self.db.profile
		local currentlyEnabled = profile.autoTrackQuestCategories
			and profile.autoTrackQuestCategories[key] == true
		if not currentlyEnabled and not self:HasAutoQuestCategories() then
			self:CaptureQuestMenuTracking()
		end
		if profile.autoTrackZoneQuests then self:SetAutoTrackZoneQuestsEnabled(false) end
		profile.autoTrackQuestCategories = profile.autoTrackQuestCategories or {}
		profile.autoTrackQuestCategories[key] = not currentlyEnabled or nil
		self.QuestMenuLastAction = choice.text
		self.QuestTrackerSearchResults, self.QuestTrackerSearchRestoreState = nil, nil
		if self.UpdateQuestTrackerSearchRestoreButton then self:UpdateQuestTrackerSearchRestoreButton() end
		if self:HasAutoQuestCategories() then self:ReconcileAutoQuestCategories(true) end
		if not self:HasAutoQuestCategories() then self.AutoQuestCategorySelected = nil end
		return true
	end

	-- All zone controls, including settings panels, disable the category checkboxes on either toggle.
	local originalZoneSetter = RQE.SetAutoTrackZoneQuestsEnabled
	-- Enables or disables automatic tracking of the current zone's quests.
	function RQE:SetAutoTrackZoneQuestsEnabled(enabled)
		self.db.profile.autoTrackQuestCategories = {}
		self.AutoQuestCategorySelected = nil
		if originalZoneSetter then return originalZoneSetter(self, enabled) end
		self.db.profile.autoTrackZoneQuests = enabled == true
		if enabled then self.DisplayCurrentZoneQuests() end
	end

	-- Applies a filter result as the native or virtual quest selection and refreshes the tracker.
	function RQE:ApplyQuestMenuSelection(kind, value, label)
		if ClientCall("InCombatLockdown") then
			print("RQE quest tracking changes are unavailable during combat.")
			return false
		end
		local selected = kind == "none" and {} or self:GetQuestMenuMatches(kind, value)
		local focused = self.API.GetSuperTrackedQuestID and self.API.GetSuperTrackedQuestID()
		self:CaptureQuestMenuTracking()
		PrepareManualSelection()
		self.QuestMenuLastAction = label
		if LegacyTracker() then
			-- Use a dedicated RQE-only source rather than filling Classic's limited
			-- native tracker. The existing distance comparator consumes this source.
			self.QuestMenuSelection = selected
			self.ClassicVirtualQuestWatches = Copy(selected)
			self.ClassicManualVirtualQuestWatches = Copy(selected)
			-- Explicit selections are persistent watches; an older progress-watch
			-- expiry must not remove them after this menu has claimed the quest.
			self.AutoQuestProgressVirtualWatches, self.AutoQuestProgressWatchTokens = {}, {}
			self.HiddenQuestLogQuests = {}
			self.ShowAllQuestLogQuests, self.ZoneQuestFilterMapID = false, nil
			self.ShowOnlyAllCompleteVirtualQuests = false
		else
			SetNativeWatches(selected)
		end
		RefreshTracker(focused)
		return true
	end

	-- Restores the tracking snapshot captured before the most recent explicit menu selection.
	function RQE:RestoreQuestMenuTracking()
		local snapshot = self.QuestMenuRestoreState
		if not snapshot or ClientCall("InCombatLockdown") then return false end
		local focused = self.API.GetSuperTrackedQuestID and self.API.GetSuperTrackedQuestID()
		SetNativeWatches(snapshot.nativeWatches)
		RestoreSnapshotFields(snapshot)
		self.QuestMenuRestoreState = nil
		if self:HasAutoQuestCategories() then self:ReconcileAutoQuestCategories(true)
		else
			RefreshTracker(focused)
			if self.db.profile.autoTrackZoneQuests then self.DisplayCurrentZoneQuests() end
		end
		return true
	end



--------------------------------------------------
-- #3. 🔗 Existing Tracker Integration Hooks
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Filter & Shortcut Wrappers
	-------------------------------------------------------

	-- Existing header shortcuts and filters retain their implementations. Leaving
	-- an explicit menu selection releases only the additional virtual source.
	for _, name in ipairs({ "filterAllTrackedQuests", "filterAllCompleteQuests", "filterCompleteQuests",
		"filterDailyWeeklyQuests", "filterByZone", "filterByCampaign", "filterByQuestType",
		"filterByQuestLine", "TrackQuestsNotInDB" }) do
		local original = RQE[name]
		if type(original) == "function" then
			-- Clears automatic category selection before applying a manual quest filter.
			RQE[name] = function(...)
				RQE.QuestMenuSelection = nil
				RQE.db.profile.autoTrackQuestCategories = {}
				RQE.AutoQuestCategorySelected = nil
				PersistLegacySelection()
				return original(...)
			end
		end
	end

	-------------------------------------------------------
	-- #3b. Legacy Virtual-Watch Wrappers
	-------------------------------------------------------

	for _, name in ipairs({ "AddClassicVirtualQuestWatch", "RemoveClassicVirtualQuestWatch", "UntrackQuestEverywhere" }) do
		local original = RQE[name]
		if type(original) == "function" then
			local adds = name == "AddClassicVirtualQuestWatch"
			-- Keeps manual quest selection synchronized with explicit watch changes.
			RQE[name] = function(self, id, ...)
				local questID = tonumber(id)
				local temporary = adds and select(1, ...) == true
				if questID and self.QuestMenuSelection and not self.PendingTrackerStateRestore and not temporary then
					self.QuestMenuSelection[questID] = adds and true or nil
					PersistLegacySelection()
				end
				return original(self, id, ...)
			end
		end
	end



--------------------------------------------------
-- #4. 🖼️ Styled Menu Framework
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Menu Tree Lifecycle & Interaction
	-------------------------------------------------------

	-- Provides a cross-client mouse-over check for visible menu frames.
	local function MouseOver(frame)
		if not frame or not frame:IsShown() then return false end
		if frame.IsMouseOver then return frame:IsMouseOver() end
		return ClientCall("MouseIsOver", frame) == true
	end

	-- Closes every root and child menu managed by the shared quest-tool menu system.
	function RQE:CloseQuestFilterMenus()
		for _, menu in pairs(menus) do menu:Hide() end
	end

	-- Reports whether the filter launcher or any open menu in its flyout tree is under the cursor.
	local function TreeHovered()
		if MouseOver(RQE.QTQuestFilterButton) then return true end
		if MouseOver(RQE.TargetNPCButton) then return true end
		for _, menu in pairs(menus) do if MouseOver(menu) then return true end end
		return false
	end

	-- Registers a named frame for Blizzard's global Escape-key closure behavior.
	local function RegisterEscape(frame)
		UISpecialFrames = UISpecialFrames or {}
		for _, name in ipairs(UISpecialFrames) do if name == frame:GetName() then return end end
		UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
	end

	-- Routes deferred menu work through the client-compatible timer wrapper.
	local function After(delay, callback)
		RQE.API.Client.C_Timer.After(delay, callback)
	end

	-------------------------------------------------------
	-- #4b. Menu Theme Colors & Styling
	-------------------------------------------------------

	-- Returns the active theme's menu background and accent colors, with neutral Basic fallbacks.
	local function MenuColors()
		if RQE.UI and RQE.UI:IsEnabled() then
			local c = RQE.UI.Colors
			if c and c.charcoal and c.gold then
				return c.charcoal[1], c.charcoal[2], c.charcoal[3], c.gold[1], c.gold[2], c.gold[3]
			end
		end
		-- Basic uses the original tooltip border and a neutral, dark menu palette.
		return 0.025, 0.025, 0.025, 0.78, 0.78, 0.78
	end

	-- Applies active-theme colors to a menu and each visible row state.
	local function StyleMenu(menu)
		local r, g, b, hr, hg, hb = MenuColors()
		menu:SetBackdropColor(r, g, b, 0.97)
		for _, row in ipairs(menu.rows) do
			row.highlight:SetColorTexture(hr, hg, hb, 0.16)
			row.line:SetColorTexture(hr, hg, hb, 0.25)
			if row.RQEMenuKind == "heading" then row.label:SetTextColor(hr, hg, hb)
			elseif row.disabled then row.label:SetTextColor(0.5, 0.53, 0.58)
			else row.label:SetTextColor(0.94, 0.94, 0.9) end
		end
	end

	-------------------------------------------------------
	-- #4c. Menu Creation & Flyout Positioning
	-------------------------------------------------------

	-- Creates or reuses a pooled scrollable menu frame for the requested role.
	local function GetMenu(key)
		if menus[key] then return menus[key] end
		local menu = CreateFrame("Frame", "RQEQuestFilter" .. key .. "Menu", UIParent, "BackdropTemplate")
		menu:Hide()
		menu:SetFrameStrata("DIALOG")
		menu:SetFrameLevel(100)
		menu:SetClampedToScreen(true)
		menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 } })
		menu.scroll = CreateFrame("ScrollFrame", nil, menu)
		menu.scroll:SetPoint("TOPLEFT", 6, -6)
		menu.scroll:SetPoint("BOTTOMRIGHT", -6, 6)
		menu.content = CreateFrame("Frame", nil, menu.scroll)
		menu.scroll:SetScrollChild(menu.content)
		menu.rows = {}
		menu:EnableMouse(true)
		menu:EnableMouseWheel(true)
		-- Moves the scroll position in response to the mouse wheel.
		menu:SetScript("OnMouseWheel", function(_, delta)
			local range = math.max(0, menu.content:GetHeight() - menu.scroll:GetHeight())
			menu.scroll:SetVerticalScroll(math.max(0, math.min(range, menu.scroll:GetVerticalScroll() - delta * 54)))
		end)
		-- Closes the quest filter menus.
		menu:SetScript("OnLeave", function()
			-- Closes the quest filter menus.
			After(0.3, function() if not TreeHovered() then RQE:CloseQuestFilterMenus() end end)
		end)
		-- Closes child flyout menus when their parent menu is hidden.
		menu:SetScript("OnHide", function()
			for _, child in pairs(menus) do if child.parentMenu == menu then child:Hide() end end
		end)
		RegisterEscape(menu)
		menus[key] = menu
		if RQE.UI then RQE.UI:StylePanel(menu, 0.97, "menu") end
		return menu
	end

	local BuildMenu

	-- Converts an anchor's horizontal bounds into UIParent coordinate space.
	local function HorizontalBounds(anchor)
		local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
		return (anchor:GetLeft() or 0) * scale, (anchor:GetRight() or 0) * scale
	end

	-- Positions and opens a root menu or nested flyout while preventing ancestor overlap.
	local function ShowMenu(menu, anchor, parent)
		local left, right = HorizontalBounds(parent or anchor)
		local screenWidth = UIParent:GetWidth()
		local direction = parent and parent.openDirection
		if parent then
			-- Descendants continue away from the root. Reversing an individual
			-- flyout would place it over an ancestor, even with room on that side.
			if not direction then
				direction = right + menu:GetWidth() + 4 <= screenWidth and "right" or "left"
			end
			local available = direction == "left" and left - 4 or screenWidth - right - 4
			if parent.parentMenu and available < menu:GetWidth() then
				-- On a narrow screen, replace the intermediate column and provide a
				-- back row instead of clamping the next column over the main menu.
				local previous = parent
				local items = { { text = "< Back to " .. previous.anchorRow.item.text, backMenu = previous } }
				for _, item in ipairs(menu.items) do items[#items + 1] = item end
				parent, anchor = previous.parentMenu, previous.anchorRow
				left, right = HorizontalBounds(parent)
				available = direction == "left" and left - 4 or screenWidth - right - 4
				BuildMenu(menu, items, math.max(1, available))
				menu.parentMenu = parent
				previous:Hide()
			elseif available < menu:GetWidth() then
				local otherAvailable = direction == "left" and screenWidth - right - 4 or left - 4
				if otherAvailable > available then
					direction = direction == "left" and "right" or "left"
					available = otherAvailable
				end
				BuildMenu(menu, menu.items, math.max(1, available))
			end
		end
		for _, other in pairs(menus) do
			if other ~= menu and other.parentMenu == parent then other:Hide() end
		end
		menu.parentMenu = parent
		menu.openDirection = direction
		menu:SetFrameLevel(parent and parent:GetFrameLevel() + 10 or 100)
		menu:ClearAllPoints()
		if parent then
			local uiScale = UIParent:GetEffectiveScale()
			local topOffset = (anchor:GetTop() or 0) * anchor:GetEffectiveScale() / uiScale
				- (parent:GetTop() or 0) * parent:GetEffectiveScale() / uiScale
			if direction == "right" then
				menu:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, topOffset)
			else menu:SetPoint("TOPRIGHT", parent, "TOPLEFT", -4, topOffset) end
		else
			local fitsRight = left + menu:GetWidth() <= screenWidth
			local openAbove = menu.rootAtCursor and (anchor:GetBottom() or 0) < menu:GetHeight() + 4
			if openAbove then
				if fitsRight then menu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
				else menu:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 4) end
			elseif fitsRight then
				menu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
			else menu:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4) end
		end
		menu:Show()
	end

	-------------------------------------------------------
	-- #4d. Menu Row Construction & Layout
	-------------------------------------------------------

	-- Builds or refreshes pooled rows, sizing the menu and wiring actions, tooltips, and flyouts.
	BuildMenu = function(menu, items, maximumWidth)
		menu.items = items
		for _, row in ipairs(menu.rows) do row:Hide() end
		local width, y = 244, 0
		for index, item in ipairs(items) do
			local row = menu.rows[index]
			if not row then
				row = CreateFrame("Button", nil, menu.content)
				row.RQEControlTooltip = true
				row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				row.label:SetPoint("LEFT", 22, 0)
				row.label:SetJustifyH("LEFT")
				row.label:SetWordWrap(false)
				row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
				row.detail:SetPoint("RIGHT", -22, 0)
				row.arrow = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				row.arrow:SetPoint("RIGHT", -6, 0)
				row.arrow:SetText(">")
				row.check = row:CreateTexture(nil, "OVERLAY")
				row.check:SetSize(16, 16)
				row.check:SetPoint("LEFT", 3, 0)
				row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
				row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
				row.highlight:SetAllPoints()
				row.line = row:CreateTexture(nil, "ARTWORK")
				row.line:SetColorTexture(0.5, 0.5, 0.5, 0.25)
				row.line:SetHeight(1)
				row.line:SetPoint("LEFT", 6, 0)
				row.line:SetPoint("RIGHT", -6, 0)
				-- Shows this control's tooltip while the pointer is over it.
				row:SetScript("OnEnter", function(self)
					if self.tooltip then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						if self.previewTooltip then
							GameTooltip:SetText(self.item.text or "Template")
							GameTooltip:AddLine(self.tooltip, 1, 0.82, 0, true)
						else
							GameTooltip:SetText(self.tooltip)
						end
						GameTooltip:Show()
					end
				end)
				-- Hides the tooltip when the pointer leaves this control.
				row:SetScript("OnLeave", function()
					GameTooltip:Hide()
					-- Closes the quest filter menus.
					After(0.3, function() if not TreeHovered() then RQE:CloseQuestFilterMenus() end end)
				end)
				menu.rows[index] = row
			end
			row.item, row.RQEMenuKind, row.disabled = item, item.kind, item.disabled
			row.previewTooltip = item.previewTooltip
			row.tooltip = item.tooltip
			row.label:SetWidth(10000)
			row.label:SetText(item.text or "")
			row.detail:SetText(item.count ~= nil and tostring(item.count) or "")
			local measured = row.label:GetStringWidth() + (row.detail:GetStringWidth() or 0) + 70
			width = math.max(width, measured)
			local height = item.kind == "separator" and 9 or item.kind == "heading" and 24 or 24
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetHeight(height)
			row.label:SetShown(item.kind ~= "separator")
			row.line:SetShown(item.kind == "separator")
			row.detail:SetShown(item.count ~= nil)
			row.arrow:SetShown(item.submenu ~= nil)
			row.check:SetShown(item.checked == true)
			if item.disabled or item.kind == "heading" or item.kind == "separator" then row:Disable()
			else row:Enable() end
			-- Opens the clicked flyout submenu or executes its available action.
			row:SetScript("OnClick", function(self)
				local entry = self.item
				if entry.backMenu then
					menu:Hide()
					local previous = entry.backMenu
					ShowMenu(previous, previous.anchorRow, previous.parentMenu)
				elseif entry.submenu then
					local child = GetMenu(entry.submenu)
					if child:IsShown() and child.anchorRow == self then child:Hide(); return end
					child.anchorRow = self
					-- Refreshes the layout.
					child.RefreshLayout = function()
						for _, descendant in pairs(menus) do
							if descendant.parentMenu == child then descendant:Hide() end
						end
						if child:IsShown() and child.anchorRow and child.anchorRow.item then
							BuildMenu(child, child.anchorRow.item.build())
						end
					end
					BuildMenu(child, entry.build())
					ShowMenu(child, self, menu)
				elseif entry.action then
					entry.action()
					if entry.keepOpen then
						local scroll = menu.scroll:GetVerticalScroll()
						if menu.RefreshLayout then menu:RefreshLayout() end
						menu.scroll:SetVerticalScroll(scroll)
					else
						RQE:CloseQuestFilterMenus()
					end
				end
			end)
			row:Show()
			y = y + height
		end
		width = math.min(width, 430, UIParent:GetWidth() - 24, maximumWidth and maximumWidth - 12 or 430)
		width = math.max(1, width)
		menu:SetWidth(width + 12)
		menu.content:SetSize(width, math.max(1, y))
		menu:SetHeight(math.min(y + 12, UIParent:GetHeight() - 36))
		for index, item in ipairs(items) do
			local row = menu.rows[index]
			row:SetWidth(width)
			row.label:SetWidth(math.max(1, width - 54 - row.detail:GetStringWidth()))
			if row.label.IsTruncated and row.label:IsTruncated() then row.tooltip = item.tooltip or item.text end
		end
		menu.scroll:SetVerticalScroll(0)
		StyleMenu(menu)
	end



--------------------------------------------------
-- #5. 📋 Quest Filter Menu
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Reusable Filter Row Adapters
	-------------------------------------------------------

	-- Creates a filter row with its live match count, availability, tooltip, and selection callback.
	local function SelectionRow(text, kind, value)
		local count = Count(RQE:GetQuestMenuMatches(kind, value))
		return { text = text, count = count, disabled = count == 0,
			tooltip = kind == "instance"
				and "Track dungeon, raid, delve, and scenario quests currently in your quest log. Outdoor group quests are excluded."
				or "Select matching quests currently in your quest log once. This replaces the quest-log selection and turns Auto-track current zone off.",
			-- Applies the quest menu selection.
			action = function() RQE:ApplyQuestMenuSelection(kind, value, text) end }
	end

	-- Adapts an existing client filter action to the shared menu and restoration workflow.
	local function ExistingFilterRow(item, kind)
		if kind and not item.disabled then
			local id = tonumber(item.text:match("^(%d+):"))
			local row = SelectionRow(item.text, kind, id or "Misc")
			return row
		end
		return { text = item.text, disabled = item.disabled,
			-- Captures the quest menu tracking.
			action = function()
				if ClientCall("InCombatLockdown") then return end
				local previousRestore = RQE.QuestMenuRestoreState
				RQE:CaptureQuestMenuTracking()
				local snapshot = RQE.QuestMenuRestoreState
				PrepareManualSelection()
				RQE.QuestMenuSelection = nil
				PersistLegacySelection()
				RQE.QuestMenuLastAction = item.text
				local result = item.func()
				if item.preserveOnFalse and result == false then
					RestoreSnapshotFields(snapshot)
					RQE.QuestMenuRestoreState = previousRestore
					PersistLegacySelection()
				end
			end }
	end

	-- Runs an optional cache scan and converts a client filter list into shared menu rows.
	local function ExistingList(builder, scanner, kind)
		if scanner then scanner() end
		local items = {}
		for _, item in ipairs(builder()) do items[#items + 1] = ExistingFilterRow(item, kind) end
		return items
	end

	-- Checks whether the optional RQE Contribution addon is currently available.
	local function ContributionLoaded()
		return ClientCall("C_AddOns.IsAddOnLoaded", "RQE_Contribution") == true
			or (RQE.API.IsAddOnLoaded and RQE.API.IsAddOnLoaded("RQE_Contribution") == true)
	end

	-------------------------------------------------------
	-- #5b. Main Quest Filter Composition
	-------------------------------------------------------

	-- Composes the complete quest-filter menu from shared choices and client-provided filters.
	local function MainMenuItems()
		local mapID = ClientCall("C_Map.GetBestMapForUnit", "player")
		local items = {
			{ text = "Track quests", kind = "heading" },
			SelectionRow("All quests", "all"),
			SelectionRow("Current zone", "zone", mapID),
			{ text = "Campaign", count = Count(RQE:GetQuestMenuMatches("campaign")),
				-- Builds the campaign menu list.
				submenu = "Campaign", build = function()
					local campaigns = { SelectionRow("All campaign quests", "campaign") }
					RQE.ScanAndCacheCampaigns()
					for _, item in ipairs(RQE.BuildCampaignMenuList()) do
						campaigns[#campaigns + 1] = ExistingFilterRow(item, "campaign")
					end
					return campaigns
				end },
			SelectionRow("Daily / Weekly", "frequency"),
			SelectionRow("Instance", "instance"),
			SelectionRow("Incomplete", "incomplete"),
			SelectionRow("Ready for turn-in", "ready"),
			-- Builds the additional quest-filter submenu categories.
			{ text = "More filters", submenu = "MoreFilters", build = function()
				return {
					-- Builds a flyout list from the existing quest-filter menu provider.
					{ text = "Zone quests", submenu = "Zone", build = function()
						return ExistingList(RQE.BuildZoneQuestMenuList, RQE.ScanAndCacheZoneQuests)
					end },
					-- Builds a flyout list from the existing quest-filter menu provider.
					{ text = "Quest type", submenu = "Type", build = function()
						return ExistingList(RQE.BuildQuestTypeMenuList, RQE.ScanQuestTypes, "type")
					end },
					-- Builds a flyout list from the existing quest-filter menu provider.
					{ text = "Quest line", submenu = "Line", build = function()
						return ExistingList(RQE.BuildQuestLineMenuList, RQE.RequestAndCacheQuestLines, "line")
					end },
				}
			end },
			{ kind = "separator" },
			{ text = "Automatic", kind = "heading" },
			{ text = "Auto-track current zone", keepOpen = true, checked = RQE.db.profile.autoTrackZoneQuests,
				tooltip = "Keep the current zone's quest selection updated using RQE's existing automatic zone tracking.",
				-- Captures the quest menu tracking.
				action = function()
					local enabled = not RQE.db.profile.autoTrackZoneQuests
					if ClientCall("InCombatLockdown") then return end
					if enabled then
						RQE:CaptureQuestMenuTracking()
						PrepareManualSelection()
						RQE.QuestMenuSelection = nil
						PersistLegacySelection()
					end
					if RQE.SetAutoTrackZoneQuestsEnabled then RQE:SetAutoTrackZoneQuestsEnabled(enabled)
					else
						RQE.db.profile.autoTrackZoneQuests = enabled
						if enabled then RQE.DisplayCurrentZoneQuests() end
					end
				end },
			-- Builds the menu explaining the current automatic quest-sorting behavior.
			{ text = "Sorting", submenu = "Sorting", build = function()
				return {
					{ text = "RQE automatic proximity order", kind = "heading",
						tooltip = "RQE keeps its existing client-specific proximity ordering and distance fallbacks." },
					{ text = "Existing sorting remains active", disabled = true },
				}
			end },
			{ kind = "separator" },
			{ text = "Restore previous tracking", disabled = not RQE.QuestMenuRestoreState,
				-- Restores the quest menu tracking.
				action = function() RQE:RestoreQuestMenuTracking() end },
			{ text = "Untrack quest-log quests",
				-- Applies the quest menu selection.
				action = function() RQE:ApplyQuestMenuSelection("none", nil, "Untrack quest-log quests") end },
		}
		if RQE.IsRetail then
			-- Keep the Retail-only choices directly below Campaign and above Daily / Weekly.
			table.insert(items, 5, SelectionRow("Meta", "meta"))
			table.insert(items, 6, SelectionRow("Meta / Daily / Weekly", "meta-frequency"))
		end
		local sortingIndex
		for index, item in ipairs(items) do
			if item.text == "Sorting" then sortingIndex = index; break end
		end
		for _, choice in ipairs(autoCategoryChoices) do
			if not choice.retailOnly or RQE.IsRetail then
				local key = choice.key
				table.insert(items, sortingIndex, {
					text = choice.text, keepOpen = true,
					checked = (RQE.db.profile.autoTrackQuestCategories or {})[key] == true,
					tooltip = "Keep matching quests in your quest log tracked as quests are accepted or removed.",
					-- Toggles the auto quest category.
					action = function() RQE:ToggleAutoQuestCategory(key) end,
				})
				sortingIndex = sortingIndex + 1
			end
		end
		if ContributionLoaded() then
			-- Builds the Contribution-specific quest tracking and filter actions.
			items[#items + 1] = { text = "Contribution", submenu = "Contribution", build = function()
				local contribution = {
					ExistingFilterRow({ text = "Track quests not in DB", func = RQE.TrackQuestsNotInDB }),
				}
				if RQE_Contribution and type(RQE_Contribution.TrackQuestLogMissingEntries) == "function" then
					contribution[#contribution + 1] = ExistingFilterRow({
							text = "Track quests missing both DBs", preserveOnFalse = true,
							func = RQE_Contribution.TrackQuestLogMissingEntries })
				end
				return contribution
			end }
		end
		return items
	end

	-------------------------------------------------------
	-- #5c. Quest Filter Display
	-------------------------------------------------------

	-- Builds and toggles the quest-filter root menu beneath the tracker filter button.
	function RQE:ShowQuestFilterMenu()
		local menu = GetMenu("Main")
		menu.rootAtCursor = nil
		self.QuestFilterDropDownMenu = menu
		-- Existing Contribution actions refresh the old filter frame through this
		-- method. Keep that integration while rebuilding the new compact rows.
		menu.RefreshLayout = menu.RefreshLayout or function()
			if menu:IsShown() then BuildMenu(menu, MainMenuItems()) end
		end
		if menu:IsShown() then self:CloseQuestFilterMenus(); return end
		self:CloseQuestFilterMenus()
		BuildMenu(menu, MainMenuItems())
		ShowMenu(menu, self.QTQuestFilterButton)
	end

	-- Opens Contribution tools with the same compact, themed rows and flyouts as the filter menu.
	function RQE:ShowTargetNPCMenu()
		if not ContributionLoaded() or not self.TargetNPCButton then return end
		local menu = GetMenu("TargetNPC")
		if menu:IsShown() then self:CloseQuestFilterMenus(); return end
		self:CloseQuestFilterMenus()
		menu.rootAtCursor = nil
		BuildMenu(menu, {
			{ text = "Contribution", kind = "heading" },
			-- Copies a database NPC table, keeping placeholders when target details are unavailable.
			{ text = "Copy target NPC table", action = function()
				self:ShowTargetNPCTableCopy()
			end },
			-- Shows the target NPC copy.
			{ text = "Copy target NPC reference", action = function()
				self:ShowTargetNPCCopy()
			end },
			-- Builds the NPC description-template submenu and its copy actions.
			{ text = "Descriptions", submenu = "TargetNPCDescriptions", build = function()
				local templates = RQE_Contribution and RQE_Contribution.GetStepEditorDescriptionTemplates
					and RQE_Contribution.GetStepEditorDescriptionTemplates() or {}
				-- Orders templates alphabetically by their case-insensitive display names.
				table.sort(templates, function(left, right) return left.name:lower() < right.name:lower() end)
				local rows = {}
				for _, template in ipairs(templates) do
					local selectedTemplate = template
					rows[#rows + 1] = {
						text = selectedTemplate.name, tooltip = selectedTemplate.tooltip or selectedTemplate.text, previewTooltip = true,
						-- Shows the contribution description copy.
						action = function() self:ShowContributionDescriptionCopy(selectedTemplate) end,
					}
				end
				return rows
			end },
			-- Builds the NPC macro-template submenu and its copy actions.
			{ text = "Macros", submenu = "TargetNPCMacros", build = function()
				local templates = RQE_Contribution and RQE_Contribution.GetStepEditorMacroTemplates
					and RQE_Contribution.GetStepEditorMacroTemplates() or {
						{ name = "Speak with Target Macro", body = "#showtooltip item:5830\n/tar NPCNAME\n/run RQE.SelectMultipleGossipOptions(\"NPCNAME\", 0)\n/tm 0\n/tm ~2", primaryNpcPlaceholder = "NPCNAME" },
					}
				templates[#templates + 1] = {
					name = "Cancel Aura",
					body = "#showtooltip item:" .. (RQE.IsRetail and "153541" or "54068") .. "\n/cancelaura SPELLNAME",
				}
				-- Orders templates alphabetically by their case-insensitive display names.
				table.sort(templates, function(left, right) return left.name:lower() < right.name:lower() end)
				local rows = {}
				for _, template in ipairs(templates) do
					local selectedTemplate = template
					rows[#rows + 1] = {
						text = selectedTemplate.name, tooltip = selectedTemplate.tooltip or selectedTemplate.body, previewTooltip = true,
						-- Shows the contribution macro copy.
						action = function() self:ShowContributionMacroCopy(selectedTemplate) end,
					}
				end
				return rows
			end },
			-- Prints the player's continent coordinates for diagnostics.
			{ text = "Copy player locations", action = function()
				RQE.DebugPrintPlayerContinentPosition(nil, "locations")
			end },
			-- Combines the displayed quest's saved location with the player's continent position.
			{ text = "Copy player locations from existing", action = function()
				self:ShowPlayerCoordinatesCopy("locations", true)
			end },
			-- Prints the player's continent coordinates for diagnostics.
			{ text = "Copy player coordinate hotspots", action = function()
				RQE.DebugPrintPlayerContinentPosition(nil, "coordinateHotspots")
			end },
			-- Combines the displayed step's saved coordinates with the player's continent position.
			{ text = "Copy player coordinate hotspots for existing entry", action = function()
				self:ShowPlayerCoordinatesCopy("coordinateHotspots", true)
			end },
			-- Shows the player zone copy.
			{ text = "Copy subzone and zone", action = function()
				self:ShowPlayerZoneCopy()
			end },
		})
		ShowMenu(menu, self.TargetNPCButton)
	end



--------------------------------------------------
-- #6. 🖱️ Styled Quest Context Menus
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Context Item Cleanup & Shared Registries
	-------------------------------------------------------

	-- The right-click menus keep their client-specific callbacks and conditions.
	-- This small description adapter only turns them into the same rows and
	-- flyouts used by the quest filter. Contribution actions are collected into
	-- one flyout while Open Sandbox remains a root action.
	local function CleanContextItems(items)
		local clean = {}
		for _, item in ipairs(items) do
			if item.kind ~= "separator" then
				clean[#clean + 1] = item
			elseif #clean > 0 and clean[#clean].kind ~= "separator" then
				clean[#clean + 1] = item
			end
		end
		if clean[#clean] and clean[#clean].kind == "separator" then
			table.remove(clean)
		end
		return clean
	end

	local questContextActionKeys, questContextActions = {}, {}

	-------------------------------------------------------
	-- #6b. Scenario Card Preview Choices
	-------------------------------------------------------

	local scenarioCardTestChoices = {
		{ "Follower Dungeon", "follower" },
		{ "Normal Dungeon", "normal" },
		{ "Heroic Dungeon", "heroic" },
		{ "Mythic-0 Dungeon", "mythic" },
		{ "Torghast", "torghast" },
		{ "Timed Scenario", "timed" },
		{ "Delves", "delve" },
	}

	-- Builds the Contribution scenario-preview submenu and marks the selected sample.
	local function BuildScenarioCardTestChoices()
		local items = {}
		for _, choice in ipairs(scenarioCardTestChoices) do
			local label, kind = choice[1], choice[2]
			items[#items + 1] = { text = label, checked = RQE.ScenarioCardTestKind == kind,
				-- Selects which scenario-card type the preview displays.
				action = function() RQE:SetScenarioCardTestKind(kind) end }
		end
		return items
	end

	-------------------------------------------------------
	-- #6c. Context Action Registration
	-------------------------------------------------------

	-- Registers or replaces a keyed companion action provider for quest context menus.
	function RQE:RegisterQuestContextAction(key, provider)
		if type(key) ~= "string" or key == "" or type(provider) ~= "function" then return false end
		if not questContextActionKeys[key] then
			questContextActionKeys[key] = #questContextActions + 1
			questContextActions[#questContextActions + 1] = { key = key, provider = provider }
		else
			questContextActions[questContextActionKeys[key]].provider = provider
		end
		return true
	end

	-------------------------------------------------------
	-- #6d. Context Menu Assembly & Display
	-------------------------------------------------------

	-- Adapts a client-built quest context description into the shared themed flyout menu.
	function RQE:ShowStyledContextMenu(builder)
		local raw = {}
		local description = {}
		-- Converts context button requests and separator rows into the shared intermediate item list.
		local function AddButton(text, callback, contribution)
			local item
			if type(text) == "string" and text:match("^|cff[%x]+%-+|r$") then
				item = { kind = "separator" }
			else
				item = { text = text, action = callback, contribution = contribution }
			end
			raw[#raw + 1] = item
			return item
		end
		-- Adds a standard client action to the shared quest context menu.
		function description:CreateButton(text, callback)
			return AddButton(text, callback, false)
		end
		-- Adds an action that will be grouped inside the Contribution flyout.
		function description:CreateContributionButton(text, callback)
			return AddButton(text, callback, true)
		end
		-- Appends valid actions returned by registered companion providers for the selected quest.
		function description:AppendQuestContextActions(questID)
			questID = tonumber(questID)
			if not questID then return end
			for _, registration in ipairs(questContextActions) do
				local ok, text, callback = pcall(registration.provider, questID)
				if ok and type(text) == "string" and text ~= "" and type(callback) == "function" then
					AddButton(text, callback, false)
				end
			end
		end
		builder(UIParent, description)
		for index, item in ipairs(raw) do
			if item.kind == "separator" then
				local before, after = index - 1, index + 1
				while raw[before] and raw[before].kind == "separator" do before = before - 1 end
				while raw[after] and raw[after].kind == "separator" do after = after + 1 end
				item.contribution = raw[before] and raw[before].contribution
					and raw[after] and raw[after].contribution or false
			end
		end

		local root, contribution = {}, {}
		-- Builds the Contribution flyout, including optional scenario-card preview controls.
		local function BuildContextContribution()
			local items = CleanContextItems(contribution)
			if ContributionLoaded() and RQE.IsRetail and RQE.SetScenarioCardTestEnabled then
				if #items > 0 then items[#items + 1] = { kind = "separator" } end
				local enabled = RQE:IsScenarioCardTestEnabled()
				items[#items + 1] = { text = "Test Scenario Cards", checked = enabled, keepOpen = true,
					tooltip = "Show sample scenario cards in the tracker using the selected theme and card style.",
					-- Enables or disables the scenario-card preview mode.
					action = function() RQE:SetScenarioCardTestEnabled(not enabled) end }
				if enabled then
					items[#items + 1] = { text = "Choose card to preview", submenu = "ScenarioCardTest",
						build = BuildScenarioCardTestChoices }
				end
			end
			return items
		end
		local contributionInserted = false
		for _, item in ipairs(raw) do
			if item.contribution then
				contribution[#contribution + 1] = item
				if not contributionInserted then
					root[#root + 1] = { text = "Contribution", submenu = "ContextContribution",
						build = BuildContextContribution }
					contributionInserted = true
				end
			else
				root[#root + 1] = item
			end
		end
		if not contributionInserted and ContributionLoaded() and RQE.IsRetail then
			root[#root + 1] = { text = "Contribution", submenu = "ContextContribution",
				build = BuildContextContribution }
		end
		for index, item in ipairs(root) do
			if item.text == "Open Sandbox" then
				table.remove(root, index)
				table.insert(root, 1, item)
				break
			end
		end

		self:CloseQuestFilterMenus()
		local menu = GetMenu("Context")
		menu.rootAtCursor = true
		BuildMenu(menu, CleanContextItems(root))
		local anchor = self.ContextMenuCursorAnchor
		if not anchor then
			anchor = CreateFrame("Frame", nil, UIParent)
			anchor:SetSize(1, 1)
			self.ContextMenuCursorAnchor = anchor
		end
		local x, y = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		anchor:ClearAllPoints()
		anchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
		ShowMenu(menu, anchor)
	end



--------------------------------------------------
-- #7. 🔗 Quest Reference Links
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Reference Text & URL Helpers
	-------------------------------------------------------

	-- Reusable, movable copy dialog. SetFocus precedes HighlightText, and the
	-- deferred pass runs after the context menu has released keyboard focus.
	local function SelectReferenceText(frame)
		if not frame:IsShown() then return end
		frame.editBox:SetFocus()
		frame.editBox:SetCursorPosition(0)
		frame.editBox:HighlightText()
	end

	-- Defers URL focus and full-text selection until menu focus has been released.
	local function QueueReferenceSelection(frame)
		-- Selects the reference text.
		After(0, function() SelectReferenceText(frame) end)
	end

	-- Resolves a quest title from the client API, quest log, or RQE database.
	local function ReferenceTitle(id)
		local title = RQE.API.GetTitleForQuestID(id)
		if type(title) == "string" and title ~= "" then return title end
		for _, info in ipairs(QuestLogEntries()) do if info.questID == id then return info.title end end
		local data = RQE.getQuestData and RQE.getQuestData(id)
		return data and data.title
	end

	-- Returns the best available title for a numeric quest ID.
	function RQE:GetQuestReferenceTitle(questID)
		questID = tonumber(questID)
		return questID and ReferenceTitle(questID) or nil
	end

	-- Percent-encodes text for safe use in an external quest-search query string.
	local function EncodeQuery(text)
		-- Percent-encodes a character for use in a URL query.
		return text:gsub("[^A-Za-z0-9%-%_%.~]", function(char) return string.format("%%%02X", string.byte(char)) end)
	end

	-------------------------------------------------------
	-- #7b. Copyable Reference Dialog
	-------------------------------------------------------

	-- Keeps source text intact and escapes display pipes so copying preserves literal WoW formatting codes.
	local function SetReferenceCopyValue(frame, value)
		frame.copyValue = value
		frame.copyDisplayValue = value:gsub("|", "||")
		frame.editBox:SetText(frame.copyDisplayValue)
	end

	-- Creates or updates the movable copy dialog and selects the supplied text.
	function RQE:ShowCopyableReferenceText(header, title, value, options)
		if type(header) ~= "string" or header == ""
			or type(value) ~= "string" or value == "" then return end
		self:CloseQuestFilterMenus()
		local frame = self.QuestReferenceLinkFrame
		if not frame then
			frame = CreateFrame("Frame", "RQEQuestReferenceLinkFrame", UIParent, "BackdropTemplate")
			frame:Hide()
			frame:SetPoint("CENTER")
			frame:SetFrameStrata("DIALOG")
			frame:SetClampedToScreen(true)
			frame:SetMovable(true)
			frame:EnableMouse(true)
			frame:RegisterForDrag("LeftButton")
			frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14,
				insets = { left = 4, right = 4, top = 4, bottom = 4 } })
			frame:SetBackdropColor(0.025, 0.035, 0.055, 0.98)
			frame.provider = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			frame.provider:SetPoint("TOPLEFT", 18, -12)
			frame.provider:SetPoint("TOPRIGHT", -38, -12)
			frame.questTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			frame.questTitle:SetPoint("TOPLEFT", frame.provider, "BOTTOMLEFT", 0, -7)
			frame.questTitle:SetPoint("TOPRIGHT", frame.provider, "BOTTOMRIGHT", 0, -7)
			frame.questTitle:SetWordWrap(true)
			frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
			frame.editBox:SetAutoFocus(false)
			frame.editBox:SetFontObject("GameFontHighlight")
			frame.editBox:SetMaxLetters(0)
			frame.editBox:SetHeight(24)
			frame.editBox:SetPoint("TOPLEFT", frame.questTitle, "BOTTOMLEFT", 3, -14)
			frame.editBox:SetPoint("TOPRIGHT", frame.questTitle, "BOTTOMRIGHT", 0, -14)
			frame.editBox:SetHyperlinksEnabled(false)
			-- Selects the edit box text for copying or replacement.
			frame.editBox:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
			-- Queues the reference selection.
			frame.editBox:SetScript("OnMouseUp", function() QueueReferenceSelection(frame) end)
			-- Hides the associated frame or control.
			frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
			-- Hides the associated frame or control.
			frame.editBox:SetScript("OnEnterPressed", function() frame:Hide() end)
			-- Queues the reference selection.
			frame.editBox:SetScript("OnTextChanged", function(box, userInput)
				if userInput and box:GetText() ~= frame.copyDisplayValue then
					box:SetText(frame.copyDisplayValue)
					QueueReferenceSelection(frame)
				end
			end)
			frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			frame.hint:SetPoint("TOPRIGHT", frame.editBox, "BOTTOMRIGHT", 0, -6)
			frame.hint:SetText("Ctrl+C to copy  |  Esc to close")
			frame.macroControls = CreateFrame("Frame", nil, frame)
			frame.macroControls:SetPoint("TOPLEFT", frame.editBox, "BOTTOMLEFT", 0, -10)
			frame.macroControls:SetPoint("TOPRIGHT", frame.editBox, "BOTTOMRIGHT", 0, -10)
			frame.macroIDRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.macroIDRow:SetPoint("TOPLEFT", frame.macroControls, "TOPLEFT")
			frame.macroIDRow:SetPoint("TOPRIGHT", frame.macroControls, "TOPRIGHT")
			frame.macroIDRow:SetHeight(26)
			frame.macroIDLabel = frame.macroIDRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			frame.macroIDLabel:SetSize(68, 22)
			frame.macroIDLabel:SetPoint("LEFT", frame.macroIDRow, "LEFT", 0, 0)
			frame.macroIDInput = CreateFrame("EditBox", nil, frame.macroIDRow, "InputBoxTemplate")
			frame.macroIDInput:SetSize(120, 22)
			frame.macroIDInput:SetPoint("LEFT", frame.macroIDLabel, "RIGHT", 8, 0)
			frame.macroIDInput:SetAutoFocus(false)
			frame.macroIDInput:SetMaxLetters(12)
			frame.macroIDButton = CreateFrame("Button", nil, frame.macroIDRow, "UIPanelButtonTemplate")
			frame.macroIDButton:SetSize(150, 24)
			frame.macroIDButton:SetPoint("LEFT", frame.macroIDInput, "RIGHT", 14, 0)
			frame.macroIDButton.label = frame.macroIDButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			frame.macroIDButton.label:SetPoint("CENTER")
			frame.macroIDButton.label:SetText("Update macro")
			-- Updates the contribution description ID.
			frame.macroIDButton:SetScript("OnClick", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionID(frame)
				else RQE:UpdateContributionMacroID(frame) end
			end)
			-- Updates the contribution description ID.
			frame.macroIDInput:SetScript("OnEnterPressed", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionID(frame)
				else RQE:UpdateContributionMacroID(frame) end
			end)
			-- Releases keyboard focus when Escape is pressed.
			frame.macroIDInput:SetScript("OnEscapePressed", function(box) box:ClearFocus(); SelectReferenceText(frame) end)
			frame.macroQuantityRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.macroQuantityRow:SetHeight(26)
			frame.macroQuantityLabel = frame.macroQuantityRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			frame.macroQuantityLabel:SetSize(68, 22)
			frame.macroQuantityLabel:SetPoint("LEFT", frame.macroQuantityRow, "LEFT", 0, 0)
			frame.macroQuantityLabel:SetText("Quantity")
			frame.macroQuantityInput = CreateFrame("EditBox", nil, frame.macroQuantityRow, "InputBoxTemplate")
			frame.macroQuantityInput:SetSize(120, 22)
			frame.macroQuantityInput:SetPoint("LEFT", frame.macroQuantityLabel, "RIGHT", 8, 0)
			frame.macroQuantityInput:SetAutoFocus(false)
			frame.macroQuantityInput:SetMaxLetters(12)
			-- Updates a manual description count while preserving focus in the quantity input.
			frame.macroQuantityInput:SetScript("OnTextChanged", function(_, userInput)
				if userInput and frame.descriptionState then
					RQE:UpdateContributionDescriptionQuantity(frame, true)
				end
			end)
			frame.macroQuantityButton = CreateFrame("Button", nil, frame.macroQuantityRow, "UIPanelButtonTemplate")
			frame.macroQuantityButton:SetSize(150, 24)
			frame.macroQuantityButton:SetPoint("LEFT", frame.macroQuantityInput, "RIGHT", 14, 0)
			frame.macroQuantityButton.label = frame.macroQuantityButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			frame.macroQuantityButton.label:SetPoint("CENTER")
			frame.macroQuantityButton.label:SetText("Update macro")
			-- Updates the contribution description quantity.
			frame.macroQuantityButton:SetScript("OnClick", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionQuantity(frame)
				else RQE:UpdateContributionMacroQuantity(frame) end
			end)
			-- Updates the contribution description quantity.
			frame.macroQuantityInput:SetScript("OnEnterPressed", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionQuantity(frame)
				else RQE:UpdateContributionMacroQuantity(frame) end
			end)
			-- Releases keyboard focus when Escape is pressed.
			frame.macroQuantityInput:SetScript("OnEscapePressed", function(box) box:ClearFocus(); SelectReferenceText(frame) end)
			frame.descriptionQuantityModeRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.descriptionQuantityModeRow:SetHeight(26)
			frame.descriptionQuantityMode = CreateFrame("CheckButton", nil,
				frame.descriptionQuantityModeRow, "UICheckButtonTemplate")
			frame.descriptionQuantityMode:SetSize(24, 24)
			frame.descriptionQuantityMode:SetPoint("LEFT", frame.descriptionQuantityModeRow, "LEFT", 0, 0)
			frame.descriptionQuantityModeLabel = frame.descriptionQuantityModeRow:CreateFontString(nil,
				"OVERLAY", "GameFontHighlightSmall")
			frame.descriptionQuantityModeLabel:SetPoint("LEFT", frame.descriptionQuantityMode, "RIGHT", 4, 0)
			frame.descriptionQuantityModeLabel:SetText("Use objective remaining")
			-- Switches between the literal remaining-objective token and a manual description count.
			frame.descriptionQuantityMode:SetScript("OnClick", function()
				RQE:UpdateContributionDescriptionQuantityMode(frame)
			end)
			frame.macroObjectRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.macroObjectRow:SetHeight(26)
			frame.macroObjectLabel = frame.macroObjectRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			frame.macroObjectLabel:SetSize(90, 22)
			frame.macroObjectLabel:SetPoint("LEFT", frame.macroObjectRow, "LEFT", 0, 0)
			frame.macroObjectLabel:SetText("Object name")
			frame.macroObjectInput = CreateFrame("EditBox", nil, frame.macroObjectRow, "InputBoxTemplate")
			frame.macroObjectInput:SetSize(208, 22)
			frame.macroObjectInput:SetPoint("LEFT", frame.macroObjectLabel, "RIGHT", 8, 0)
			frame.macroObjectInput:SetAutoFocus(false)
			frame.macroObjectInput:SetMaxLetters(100)
			frame.macroObjectButton = CreateFrame("Button", nil, frame.macroObjectRow, "UIPanelButtonTemplate")
			frame.macroObjectButton:SetSize(150, 24)
			frame.macroObjectButton:SetPoint("LEFT", frame.macroObjectInput, "RIGHT", 14, 0)
			frame.macroObjectButton.label = frame.macroObjectButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			frame.macroObjectButton.label:SetPoint("CENTER")
			frame.macroObjectButton.label:SetText("Update macro")
			-- Updates the contribution description object.
			frame.macroObjectButton:SetScript("OnClick", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionObject(frame)
				else RQE:UpdateContributionMacroObject(frame) end
			end)
			-- Updates the contribution description object.
			frame.macroObjectInput:SetScript("OnEnterPressed", function()
				if frame.descriptionState then RQE:UpdateContributionDescriptionObject(frame)
				else RQE:UpdateContributionMacroObject(frame) end
			end)
			-- Releases keyboard focus when Escape is pressed.
			frame.macroObjectInput:SetScript("OnEscapePressed", function(box) box:ClearFocus(); SelectReferenceText(frame) end)
			frame.macroGossipRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.macroGossipRow:SetHeight(26)
			frame.macroGossipLabel = frame.macroGossipRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			frame.macroGossipLabel:SetSize(90, 22)
			frame.macroGossipLabel:SetPoint("LEFT", frame.macroGossipRow, "LEFT", 0, 0)
			frame.macroGossipLabel:SetText("Gossip options")
			frame.macroGossipInput = CreateFrame("EditBox", nil, frame.macroGossipRow, "InputBoxTemplate")
			frame.macroGossipInput:SetSize(208, 22)
			frame.macroGossipInput:SetPoint("LEFT", frame.macroGossipLabel, "RIGHT", 8, 0)
			frame.macroGossipInput:SetAutoFocus(false)
			frame.macroGossipInput:SetMaxLetters(100)
			frame.macroGossipButton = CreateFrame("Button", nil, frame.macroGossipRow, "UIPanelButtonTemplate")
			frame.macroGossipButton:SetSize(150, 24)
			frame.macroGossipButton:SetPoint("LEFT", frame.macroGossipInput, "RIGHT", 14, 0)
			frame.macroGossipButton.label = frame.macroGossipButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			frame.macroGossipButton.label:SetPoint("CENTER")
			frame.macroGossipButton.label:SetText("Update macro")
			-- Updates the contribution macro gossip.
			frame.macroGossipButton:SetScript("OnClick", function() RQE:UpdateContributionMacroGossip(frame) end)
			-- Updates the contribution macro gossip.
			frame.macroGossipInput:SetScript("OnEnterPressed", function() RQE:UpdateContributionMacroGossip(frame) end)
			-- Releases keyboard focus when Escape is pressed.
			frame.macroGossipInput:SetScript("OnEscapePressed", function(box) box:ClearFocus(); SelectReferenceText(frame) end)
			frame.macroNPCRow = CreateFrame("Frame", nil, frame.macroControls)
			frame.macroNPCRow:SetPoint("TOPRIGHT", frame.macroControls, "TOPRIGHT")
			frame.macroNPCRow:SetHeight(26)
			for _, slot in ipairs({ "primary", "secondary" }) do
				local button = CreateFrame("Button", nil, frame.macroNPCRow, "UIPanelButtonTemplate")
				button:SetSize(150, 24)
				button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				button.label:SetPoint("CENTER")
				-- Updates the contribution description NPC.
				button:SetScript("OnClick", function()
					if frame.descriptionState then RQE:UpdateContributionDescriptionNPC(frame)
					else RQE:UpdateContributionMacroNPC(frame, slot) end
				end)
				frame["macroNPC" .. slot] = button
			end
			frame.macroNPCprimary:SetPoint("LEFT", frame.macroNPCRow, "LEFT", 0, 0)
			frame.macroNPCsecondary:SetPoint("LEFT", frame.macroNPCprimary, "RIGHT", 12, 0)
			frame.macroStatus = frame.macroControls:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			frame.macroStatus:SetPoint("LEFT", frame.macroControls, "LEFT", 0, 0)
			frame.macroStatus:SetText("")
			frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
			frame.closeButton:SetSize(22, 22)
			frame.closeButton:SetPoint("TOPRIGHT", -7, -6)
			-- Hides the associated frame or control.
			frame.closeButton:SetScript("OnClick", function() frame:Hide() end)
			frame:SetScript("OnDragStart", frame.StartMoving)
			-- Stops dragging the frame and retains its final position.
			frame:SetScript("OnDragStop", function()
				frame:StopMovingOrSizing()
				QueueReferenceSelection(frame)
			end)
			-- Queues the reference selection.
			frame:SetScript("OnShow", function() QueueReferenceSelection(frame) end)
			-- Stops moving the copy window and clears its temporary selection state.
			frame:SetScript("OnHide", function()
				frame:StopMovingOrSizing()
				frame.editBox:ClearFocus()
				frame.macroIDInput:ClearFocus()
				frame.macroQuantityInput:ClearFocus()
				frame.macroObjectInput:ClearFocus()
				frame.macroGossipInput:ClearFocus()
				frame.macroState = nil
				frame.descriptionState = nil
			end)
			RegisterEscape(frame)
			self.QuestReferenceLinkFrame = frame
			if self.UI then
				self.UI:StylePanel(frame, 0.98, "menu")
				self.UI:StyleSearchBox(frame.editBox)
				self.UI:StyleSearchBox(frame.macroIDInput)
				self.UI:StyleSearchBox(frame.macroQuantityInput)
				self.UI:StyleSearchBox(frame.macroObjectInput)
				self.UI:StyleSearchBox(frame.macroGossipInput)
				self.UI:StyleTextButton(frame.macroIDButton)
				self.UI:StyleTextButton(frame.macroQuantityButton)
				self.UI:StyleTextButton(frame.macroObjectButton)
				self.UI:StyleTextButton(frame.macroGossipButton)
				self.UI:StyleTextButton(frame.macroNPCprimary)
				self.UI:StyleTextButton(frame.macroNPCsecondary)
				self.UI:StyleIconButton(frame.closeButton, "Close", { size = 22 })
			end
			-- InputBoxTemplate and the themed border share the edit-box edge.
			-- Keep the caret and selected copy text clear of that artwork.
			for _, box in ipairs({ frame.editBox, frame.macroIDInput,
				frame.macroQuantityInput, frame.macroObjectInput, frame.macroGossipInput }) do
				box:SetTextInsets(12, 10, 0, 0)
			end
		end
		local multiline = value:find("\n", 1, true) ~= nil
		frame:SetWidth(math.min(multiline and 960 or 540, UIParent:GetWidth() - 40))
		frame.provider:SetText(header)
		frame.questTitle:SetText(title or "")
		frame.questTitle:SetHeight(frame.questTitle:GetStringHeight())
		frame.editBox:SetMultiLine(multiline)
		frame.editBox:SetHeight(multiline and 170 or 24)
		local macroState = options and options.macroState
		local descriptionState = options and options.descriptionState
		frame.macroState = macroState
		frame.descriptionState = descriptionState
		local idKind = (macroState and macroState.idKind) or (descriptionState and descriptionState.idKind)
		local hasID = idKind ~= nil
		local hasQuantity = (macroState and macroState.hasQuantity) or (descriptionState and descriptionState.hasQuantity)
		local hasObject = (macroState and macroState.hasObject) or (descriptionState and descriptionState.hasObject)
		local hasGossip = macroState and macroState.hasGossip
		local hasDualNPC = macroState and macroState.dualNPC == true
		local hasNPCButton = hasDualNPC or (descriptionState and descriptionState.hasNPCButton)
		local controlsHeight = 0
		frame.macroControls:SetShown(hasID or hasQuantity or hasObject or hasGossip or hasNPCButton or false)
		frame.macroIDRow:SetShown(hasID or false)
		frame.macroQuantityRow:SetShown(hasQuantity or false)
		frame.descriptionQuantityModeRow:SetShown(descriptionState and hasQuantity or false)
		local useObjectiveRemaining = descriptionState and hasQuantity and descriptionState.useObjectiveRemaining or false
		frame.descriptionQuantityMode:SetChecked(useObjectiveRemaining)
		frame.macroQuantityInput:SetEnabled(not useObjectiveRemaining)
		frame.macroQuantityButton:SetEnabled(not useObjectiveRemaining)
		frame.macroQuantityRow:SetAlpha(useObjectiveRemaining and 0.5 or 1)
		frame.macroObjectRow:SetShown(hasObject or false)
		frame.macroGossipRow:SetShown(hasGossip or false)
		frame.macroNPCRow:SetShown(hasNPCButton or false)
		frame.macroNPCsecondary:SetShown(hasDualNPC or false)
		frame.hint:ClearAllPoints()
		if hasID or hasQuantity or hasObject or hasGossip or hasNPCButton then
			local rowTop = 0
			-- Places a visible flyout row and advances the layout cursor.
			local function positionRow(row, visible)
				if not visible then return end
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", frame.macroControls, "TOPLEFT", 0, rowTop)
				row:SetPoint("TOPRIGHT", frame.macroControls, "TOPRIGHT", 0, rowTop)
				rowTop = rowTop - 32
			end
			positionRow(frame.macroIDRow, hasID)
			positionRow(frame.descriptionQuantityModeRow, descriptionState and hasQuantity)
			positionRow(frame.macroQuantityRow, hasQuantity)
			positionRow(frame.macroObjectRow, hasObject)
			positionRow(frame.macroGossipRow, hasGossip)
			positionRow(frame.macroNPCRow, hasNPCButton)
			controlsHeight = -rowTop + 18
			frame.macroControls:SetHeight(controlsHeight)
			frame.macroIDLabel:SetText(hasID and (idKind == "item" and "Item ID" or "Spell ID") or "")
			frame.macroObjectLabel:SetText(descriptionState and descriptionState.objectPlaceholder == "OBJECT/NPC"
				and "Object/NPC" or "Object name")
			frame.macroIDInput:SetText("")
			frame.macroQuantityInput:SetText("")
			frame.macroObjectInput:SetText("")
			frame.macroGossipInput:SetText(macroState and macroState.originalGossipOptions or "")
			frame.macroNPCprimary.label:SetText(descriptionState and descriptionState.npcButtonLabel
				or macroState and macroState.primaryLabel or "First NPC")
			frame.macroNPCsecondary.label:SetText(macroState and macroState.secondaryLabel or "Second NPC")
			local buttonText = descriptionState and "Update description" or "Update macro"
			frame.macroIDButton.label:SetText(buttonText)
			frame.macroQuantityButton.label:SetText(buttonText)
			frame.macroObjectButton.label:SetText(buttonText)
			frame.macroStatus:ClearAllPoints()
			frame.macroStatus:SetPoint("TOPLEFT", frame.macroControls, "TOPLEFT", 0, -controlsHeight + 18)
			frame.macroStatus:SetText("")
			frame.hint:SetPoint("TOPRIGHT", frame.macroControls, "BOTTOMRIGHT", 0, -6)
		else
			frame.hint:SetPoint("TOPRIGHT", frame.editBox, "BOTTOMRIGHT", 0, -6)
		end
		frame:SetHeight((multiline and 252 or 106) + frame.questTitle:GetStringHeight() + (controlsHeight > 0 and controlsHeight + 10 or 0))
		SetReferenceCopyValue(frame, value)
		frame:Show()
		SelectReferenceText(frame)
		QueueReferenceSelection(frame)
		return frame
	end

	-- Keeps existing quest-link callers on the shared copy dialog.
	function RQE:ShowCopyableQuestURL(header, questID, url, title)
		questID = tonumber(questID)
		if not questID then return end
		return self:ShowCopyableReferenceText(header, title or ReferenceTitle(questID)
			or ("Quest " .. questID), url)
	end

	-- Reads a Creature/Vehicle target, optionally retaining its name when the NPC ID is unavailable.
	local function TargetNPC(allowUnknownID)
		local name = ClientCall("UnitName", "target")
		local guid = ClientCall("UnitGUID", "target")
		if (issecretvalue and issecretvalue(name)) or type(name) ~= "string" or name == "" then
			return
		end
		if issecretvalue and issecretvalue(guid) then guid = nil end
		if type(guid) == "string" then
			local unitType = guid:match("^([^-]+)")
			if unitType ~= "Creature" and unitType ~= "Vehicle" then return end
			local npcID = tonumber(guid:match("^[^-]+%-[^-]*%-[^-]*%-[^-]*%-[^-]*%-(%d+)"))
			if npcID and npcID > 0 then return name, npcID end
		end
		if allowUnknownID then
			local isPlayer = ClientCall("UnitIsPlayer", "target")
			if not (issecretvalue and issecretvalue(isPlayer)) and not isPlayer then return name end
		end
	end

	-- Escapes both the NPC name and the outer database macro string without losing quotes.
	local function EscapeLuaString(value)
		local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"')
		return (escaped:gsub("\r", "\\r"):gsub("\n", "\\n"))
	end

	-- Formats a readable target as a paste-ready NPC reference.
	function RQE:ShowTargetNPCCopy()
		if not ContributionLoaded() then return end
		local name, npcID = TargetNPC()
		if not name then print("RQE: Target an NPC to copy its ID and name."); return end
		local escapedName = EscapeLuaString(name)
		self:ShowCopyableReferenceText("Target NPC reference", name,
			string.format("{npc:%d:%s}", npcID, escapedName))
	end

	-- Opens a paste-ready NPC table with an object template or unknown-ID placeholder when needed.
	function RQE:ShowTargetNPCTableCopy()
		if not ContributionLoaded() then return end
		local name, npcID = TargetNPC(true)
		local field = name and "npc" or "object"
		local id = npcID and string.format("%d", npcID) or '"x99"'
		local value = '\t\t\tnpcs = {\n\t\t\t\t{ ' .. field .. ' = "' .. EscapeLuaString(name or "")
			.. '", id = ' .. id .. ' },\n\t\t\t},'
		return self:ShowCopyableReferenceText("Target NPC table", name or "Object template", value)
	end

	-- Ignores icon-only placeholders when deciding whether the macro needs an ID field.
	local function MacroBodyIDKind(body)
		local commands = body
		if commands:find("#showtooltip", 1, true) == 1 then
			commands = commands:match("\n(.*)") or ""
		end
		local hasItemID = commands:find("ITEMID", 1, true) ~= nil
		local hasItemName = commands:find("ITEMNAME", 1, true) ~= nil
		local hasSpellID = commands:find("SPELLID", 1, true) ~= nil
		local hasSpellName = commands:find("SPELLNAME", 1, true) ~= nil
		return (hasItemID or hasItemName) and "item" or (hasSpellID or hasSpellName) and "spell" or nil,
			hasItemName, hasSpellName
	end

	-- Object gossip templates use a literal argument rather than an NPC placeholder.
	local function MacroHasObjectName(body, primary, secondary)
		local argument = body:match('RQE%.SelectMultipleGossipOptions%(%s*"(.-)"%s*,')
		return argument ~= nil and argument ~= primary and argument ~= secondary
	end

	-- The Step Editor labels distinguish the two priority targets from ordinary Kill/Speak slots.
	local function MacroNPCButtonLabel(placeholder, editorLabel)
		local labels = { KILL = "Kill", SPEAK = "Speak", FIRST_KILL = "Kill #1", SECOND_KILL = "Kill #2" }
		return labels[placeholder] or (editorLabel and (editorLabel:gsub("^Populate%s+", ""))) or placeholder
	end

	-- Rebuilds from untouched template text, keeping each authoring field independent.
	local function RenderContributionMacro(state)
		local macro, pending = state.body, {}
		if state.gossipOptions then
			local marker = "\001" .. (#pending + 1) .. "\002"
			local replacements
			macro, replacements = macro:gsub('(RQE%.SelectMultipleGossipOptions%(%s*".-"%s*,%s*)[^)]-(%))',
				-- Protects the matched placeholder while preserving its surrounding macro text.
				function(before, after) return before .. marker .. after end, 1)
			if replacements > 0 then pending[#pending + 1] = { marker, state.gossipOptions } end
		end
		-- Protects matching macro text while template placeholders are substituted.
		local function mask(pattern, value)
			local marker = "\001" .. (#pending + 1) .. "\002"
			macro = macro:gsub(pattern, marker)
			pending[#pending + 1] = { marker, value }
		end
		local npcSlots = {}
		if state.primary and state.npcValues.primary then
			npcSlots[#npcSlots + 1] = { state.primary, state.npcValues.primary }
		end
		if state.secondary and state.npcValues.secondary then
			npcSlots[#npcSlots + 1] = { state.secondary, state.npcValues.secondary }
		end
		-- Orders NPC placeholders longest first to avoid partial replacements.
		table.sort(npcSlots, function(left, right) return #left[1] > #right[1] end)
		for _, slot in ipairs(npcSlots) do
			mask('"' .. slot[1] .. '"', '"' .. EscapeLuaString(slot[2]) .. '"')
			mask(slot[1], slot[2])
		end
		if state.questID then mask("QUESTID", tostring(state.questID)) end
		if state.objectName then
			local marker = "\001" .. (#pending + 1) .. "\002"
			local replacements
			macro, replacements = macro:gsub('(RQE%.SelectMultipleGossipOptions%(%s*")(.-)("%s*,)',
				-- Protects the matched placeholder while preserving both surrounding text parts.
				function(before, _, after) return before .. marker .. after end, 1)
			if replacements > 0 then pending[#pending + 1] = { marker, EscapeLuaString(state.objectName) } end
		end
		if state.idKind == "item" then
			if state.itemID then mask("ITEMID", tostring(state.itemID)) end
			if state.itemName then mask("ITEMNAME", state.itemName) end
		elseif state.idKind == "spell" then
			if state.spellID then mask("SPELLID", tostring(state.spellID)) end
			if state.spellName then mask("SPELLNAME", state.spellName) end
		end
		if state.quantity then mask("NUMBER", tostring(state.quantity)) end
		for _, replacement in ipairs(pending) do
			-- Returns the literal replacement text without pattern-substitution expansion.
			macro = macro:gsub(replacement[1], function() return replacement[2] end)
		end
		return 'macro = { "' .. EscapeLuaString(macro) .. '" },'
	end

	-- Refreshes the contribution macro copy.
	function RQE:RefreshContributionMacroCopy(frame)
		local state = frame and frame.macroState
		if not state or not frame:IsShown() then return end
		SetReferenceCopyValue(frame, RenderContributionMacro(state))
		SelectReferenceText(frame)
		QueueReferenceSelection(frame)
	end

	-- Dual-NPC macros start with separate placeholders; each button fills only its own slot.
	function RQE:UpdateContributionMacroNPC(frame, slot)
		local state = frame and frame.macroState
		if not state or not state.dualNPC or (slot ~= "primary" and slot ~= "secondary") then return end
		local name = TargetNPC()
		if not name then
			frame.macroStatus:SetText("Target an NPC, then press its button.")
			return
		end
		state.npcValues[slot] = name
		frame.macroStatus:SetText((slot == "primary" and state.primaryLabel or state.secondaryLabel) .. ": " .. name)
		self:RefreshContributionMacroCopy(frame)
	end

	-- One ID field updates item or spell placeholders, resolving display names when present.
	function RQE:UpdateContributionMacroID(frame)
		local state = frame and frame.macroState
		if not state or not state.idKind then return end
		local id = tonumber(frame.macroIDInput:GetText())
		if not id or id < 1 or id % 1 ~= 0 then
			frame.macroStatus:SetText("Enter a positive whole-number " .. state.idKind .. " ID.")
			return
		end
		state.lookupSerial = (state.lookupSerial or 0) + 1
		if state.idKind == "spell" then
			state.spellID, state.spellName = id, nil
			if state.hasSpellName and RQE.API.GetSpellPresentation then
				local spellName = RQE.API.GetSpellPresentation(id)
				if type(spellName) == "string" and spellName ~= "" then state.spellName = spellName end
			end
			frame.macroStatus:SetText(state.hasSpellName and not state.spellName
				and "Spell name unavailable; the ID was updated." or ("Updated spell ID " .. id .. "."))
			return self:RefreshContributionMacroCopy(frame)
		end
		state.itemID, state.itemName = id, nil
		frame.macroStatus:SetText(state.hasItemName and "Loading item name..." or ("Updated item ID " .. id .. "."))
		self:RefreshContributionMacroCopy(frame)
		if not state.hasItemName then return end
		local serial = state.lookupSerial
		-- Updates the copy preview after the requested item name becomes available.
		local function itemLoaded(resolvedID, itemName)
			if frame.macroState ~= state or state.lookupSerial ~= serial or state.itemID ~= resolvedID
				or not frame:IsShown() then return end
			if type(itemName) == "string" and itemName ~= "" then
				state.itemName = itemName
				frame.macroStatus:SetText("Updated item: " .. itemName)
			else
				frame.macroStatus:SetText("Item name unavailable; the ID was updated.")
			end
			self:RefreshContributionMacroCopy(frame)
		end
		if RQE_Contribution and RQE_Contribution.GetItemName then
			RQE_Contribution:GetItemName(id, itemLoaded)
		else
			itemLoaded(id, ClientCall("GetItemInfo", id))
		end
	end

	-- Purchase templates share one count field, separate from the item ID.
	function RQE:UpdateContributionMacroQuantity(frame)
		local state = frame and frame.macroState
		if not state or not state.hasQuantity then return end
		local digits = (frame.macroQuantityInput:GetText() or ""):match("^%s*(%d+)%s*$")
		local quantity = digits and tonumber(digits)
		if not quantity or quantity < 1 then
			frame.macroStatus:SetText("Enter a positive whole-number quantity.")
			return
		end
		state.quantity = quantity
		frame.macroStatus:SetText("Updated quantity to " .. quantity .. ".")
		self:RefreshContributionMacroCopy(frame)
	end

	-- Accepts either a bare object name or one enclosed in quotes.
	function RQE:UpdateContributionMacroObject(frame)
		local state = frame and frame.macroState
		if not state or not state.hasObject then return end
		local objectName = (frame.macroObjectInput:GetText() or ""):match("^%s*(.-)%s*$")
		objectName = objectName:match('^"(.*)"$') or objectName:match("^'(.*)'$") or objectName
		if objectName == "" then
			frame.macroStatus:SetText("Enter an object name.")
			return
		end
		state.objectName = objectName
		frame.macroStatus:SetText("Updated object name.")
		self:RefreshContributionMacroCopy(frame)
	end

	-- Updates only the option indices in a gossip call, leaving its target and other author fields intact.
	function RQE:UpdateContributionMacroGossip(frame)
		local state = frame and frame.macroState
		if not state or not state.hasGossip then return end
		local compact = (frame.macroGossipInput:GetText() or ""):gsub("%s+", "")
		if compact == "" or not compact:match("^%d+[%d,]*$")
			or compact:find(",,", 1, true) or compact:sub(-1) == "," then
			frame.macroStatus:SetText("Enter comma-separated gossip indices, such as 0, 2, 4.")
			return
		end
		state.gossipOptions = compact:gsub(",", ", ")
		frame.macroGossipInput:SetText(state.gossipOptions)
		frame.macroStatus:SetText("Updated gossip options to " .. state.gossipOptions .. ".")
		self:RefreshContributionMacroCopy(frame)
	end

	-- Shows the contribution macro copy.
	function RQE:ShowContributionMacroCopy(template)
		if not ContributionLoaded() then return end
		if type(template) ~= "table" or type(template.body) ~= "string" then return end
		local primary, secondary = template.primaryNpcPlaceholder, template.secondaryNpcPlaceholder
		local dualNPC = type(primary) == "string" and primary ~= ""
			and type(secondary) == "string" and secondary ~= "" and secondary ~= primary
		local name = not dualNPC and TargetNPC() or nil
		local idKind, hasItemName, hasSpellName = MacroBodyIDKind(template.body)
		local questID
		if template.body:find("QUESTID", 1, true) and self.API and self.API.GetSuperTrackedQuestID then
			local trackedID = self.API.GetSuperTrackedQuestID()
			if not (issecretvalue and issecretvalue(trackedID)) then
				trackedID = tonumber(trackedID)
				if trackedID and trackedID > 0 and trackedID % 1 == 0 then questID = trackedID end
			end
		end
		local state = {
			body = template.body, primary = primary, secondary = secondary, dualNPC = dualNPC,
			npcValues = { primary = name }, idKind = idKind, questID = questID,
			hasItemName = hasItemName, hasSpellName = hasSpellName,
			hasQuantity = template.body:find("NUMBER", 1, true) ~= nil,
			hasObject = MacroHasObjectName(template.body, primary, secondary),
			hasGossip = template.body:find("RQE.SelectMultipleGossipOptions(", 1, true) ~= nil,
			originalGossipOptions = template.body:match('RQE%.SelectMultipleGossipOptions%(%s*".-"%s*,%s*([^)]-)%)'),
			primaryLabel = MacroNPCButtonLabel(primary, template.primaryButtonText),
			secondaryLabel = MacroNPCButtonLabel(secondary, template.secondaryButtonText),
		}
		return self:ShowCopyableReferenceText(template.name,
			dualNPC and "Choose NPC targets below" or (name or "Macro template"),
			RenderContributionMacro(state), { macroState = state })
	end

	-- Retains the public shortcut for the original Speak macro.
	function RQE:ShowSpeakToNPCMacroCopy()
		local templates = RQE_Contribution and RQE_Contribution.GetStepEditorMacroTemplates
			and RQE_Contribution.GetStepEditorMacroTemplates() or {}
		for _, template in ipairs(templates) do
			if template.name == "Speak with Target Macro" then
				return self:ShowContributionMacroCopy(template)
			end
		end
		return self:ShowContributionMacroCopy({
			name = "Speak with Target Macro",
			body = "#showtooltip item:5830\n/tar NPCNAME\n/run RQE.SelectMultipleGossipOptions(\"NPCNAME\", 0)\n/tm 0\n/tm ~2",
			primaryNpcPlaceholder = "NPCNAME",
		})
	end

	-- Returns a readable finite number for coordinate formatting without inspecting secret values.
	local function CoordinateCopyNumber(value)
		if issecretvalue and issecretvalue(value) then return end
		local number = tonumber(value)
		if number and number == number and number ~= math.huge and number ~= -math.huge then return number end
	end

	-- Resolves the displayed quest and its selected DB step, including searches and virtual supertracking.
	local function CoordinateCopyQuest()
		local questID = CoordinateCopyNumber(RQE.searchedQuestID)
		if not questID or questID <= 0 then questID = CoordinateCopyNumber(RQE.DisplayedQuestID) end
		if not questID or questID <= 0 then questID = CoordinateCopyNumber(RQE.API.GetSuperTrackedQuestID()) end
		if not questID or questID <= 0 then return end
		local data = RQE.getQuestData and RQE.getQuestData(questID)
		if type(data) ~= "table" then return questID end
		local maxStep = 0
		for index, step in pairs(data) do
			if type(index) == "number" and index > maxStep and index % 1 == 0 and type(step) == "table" then
				maxStep = index
			end
		end
		local stepIndex
		if RQE.ManualStepPreview and tonumber(RQE.ManualPreviewQuestID) == questID then
			stepIndex = CoordinateCopyNumber(RQE.ManualPreviewStepIndex)
		elseif tonumber(RQE.CurrentDisplayedQuestID) == questID then
			stepIndex = CoordinateCopyNumber(RQE.CurrentDisplayedStepIndex)
		end
		stepIndex = stepIndex or CoordinateCopyNumber(RQE.AddonSetStepIndex) or 1
		if stepIndex > 0 and maxStep > 0 then stepIndex = math.min(stepIndex, maxStep) end
		return questID, data, stepIndex, maxStep > 0
	end

	-- Copies player positions or a saved quest/step point paired with the player's current continent position.
	function RQE:ShowPlayerCoordinatesCopy(mode, fromExisting)
		if not ContributionLoaded() then return end
		if mode ~= "locations" and mode ~= "coordinateHotspots" then return end
		local header = mode == "locations" and "Player locations" or "Player coordinate hotspots"
		local title = "Current position"
		local sourceMapID, sourceX, sourceY, requireContinent
		if fromExisting then
			header = header .. (mode == "locations" and " from existing" or " for existing entry")
			-- A failed conversion must not leave a previous copy result looking like the new output.
			if self.QuestReferenceLinkFrame then self.QuestReferenceLinkFrame:Hide() end
			local questID, data, stepIndex, hasSteps = CoordinateCopyQuest()
			local source
			if mode == "locations" then
				source = data and data.location
				requireContinent = true
			elseif hasSteps then
				local step = data[stepIndex]
				source = type(step) == "table" and step.coordinates
				requireContinent = true
			end
			if requireContinent then
				if type(source) == "table" then
					sourceMapID = CoordinateCopyNumber(source.mapID)
					sourceX, sourceY = CoordinateCopyNumber(source.x), CoordinateCopyNumber(source.y)
				end
				if not sourceMapID or sourceMapID <= 0 or sourceMapID % 1 ~= 0
					or not sourceX or not sourceY or sourceX < 0 or sourceX > 100 or sourceY < 0 or sourceY > 100 then
					print(mode == "locations" and "RQE: The displayed quest has no valid single location entry to copy."
						or "RQE: The displayed quest step has no valid single coordinates entry to copy.")
					return
				end
				title = (data.title or ("Quest " .. questID))
					.. (mode == "coordinateHotspots" and (" - Step " .. stepIndex) or "")
			end
		end

		local mapID, x, y = self:GetCurrentPlayerMapPosition()
		if fromExisting and not mapID then mapID = ClientCall("C_Map.GetBestMapForUnit", "player") end
		mapID, x, y = CoordinateCopyNumber(mapID), CoordinateCopyNumber(x), CoordinateCopyNumber(y)
		local continentID, map, seen = nil, mapID, {}
		while map and map > 0 and not seen[map] do
			seen[map] = true
			local info = ClientCall("C_Map.GetMapInfo", map)
			if not info then break end
			if info.mapType == 2 then
				continentID = CoordinateCopyNumber(info.mapID) or map
				break
			end
			map = CoordinateCopyNumber(info.parentMapID)
		end
		local cx, cy
		if continentID and (fromExisting or continentID ~= mapID) then
			local continentPosition = ClientCall("C_Map.GetPlayerMapPosition", continentID, "player")
			if continentPosition then cx, cy = continentPosition:GetXY() end
			cx, cy = CoordinateCopyNumber(cx), CoordinateCopyNumber(cy)
		end
		if requireContinent and (not cx or not cy) then
			print("RQE: continentID is n/a for current player position.")
			return
		end
		if sourceMapID then
			mapID, x, y = sourceMapID, sourceX / 100, sourceY / 100
		end
		if not mapID or not x or not y then
			if fromExisting then print("RQE: Unable to determine current map position."); return end
			return self:ShowCopyableReferenceText(header, title, "Unable to determine current map position.")
		end

		local prefix = mode == "locations" and "\t\t\t" or "\t\t\t\t"
		local value
		if cx and cy then
			local rowPrefix = prefix .. "\t"
			if mode == "locations" then
				value = prefix .. "locations = {\n"
					.. string.format("%s{ x = %.2f, y = %.2f, mapID = %d },\n", rowPrefix, x * 100, y * 100, mapID)
					.. string.format("%s{ x = %.2f, y = %.2f, continentID = %d },\n", rowPrefix, cx * 100, cy * 100, continentID)
					.. prefix .. "},"
			else
				local suffix = ", priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },\n"
				value = prefix .. "coordinateHotspots = {\n"
					.. string.format("%s{ x = %.2f, y = %.2f, mapID = %d", rowPrefix, x * 100, y * 100, mapID) .. suffix
					.. string.format("%s{ x = %.2f, y = %.2f, continentID = %d", rowPrefix, cx * 100, cy * 100, continentID) .. suffix
					.. prefix .. "},"
			end
		elseif mode == "locations" then
			value = prefix .. string.format("location = { x = %.2f, y = %.2f, mapID = %d },", x * 100, y * 100, mapID)
		else
			value = prefix .. string.format("coordinates = { x = %.2f, y = %.2f, mapID = %d },", x * 100, y * 100, mapID)
		end
		return self:ShowCopyableReferenceText(header, title, value)
	end

	-- Resolves the same minimap subzone and map zone for both copy actions.
	local function PlayerZoneText()
		local subzone = ClientCall("GetMinimapZoneText")
		local mapID = ClientCall("C_Map.GetBestMapForUnit", "player")
		local mapInfo = mapID and ClientCall("C_Map.GetMapInfo", mapID)
		local zone = mapInfo and mapInfo.name
		if issecretvalue and issecretvalue(subzone) then subzone = nil end
		if issecretvalue and issecretvalue(zone) then zone = nil end
		if type(subzone) ~= "string" or subzone == "" then subzone = nil end
		if type(zone) ~= "string" or zone == "" then
			zone = ClientCall("GetZoneText")
			if issecretvalue and issecretvalue(zone) then zone = nil end
		end
		if type(zone) ~= "string" or zone == "" then zone = nil end
		if subzone and zone and subzone ~= zone then
			return subzone .. ", " .. zone
		end
		return subzone or zone
	end

	-- Copies the minimap label followed by the current map's zone name.
	function RQE:ShowPlayerZoneCopy()
		if not ContributionLoaded() then return end
		local value = PlayerZoneText() or "Unable to determine current subzone or zone."
		return self:ShowCopyableReferenceText("Player subzone and zone", "Current position", value)
	end

	-- Chooses an NPC button label appropriate to the description template.
	local function DescriptionNPCButtonLabel(name, objectPlaceholder)
		if objectPlaceholder == "OBJECT/NPC" then return "Target NPC" end
		if name:find("^Kill") then return "Kill target" end
		if name:find("^Speak") then return "Speak target" end
		if name:find("^Weaken") then return "Weaken target" end
		if name:find("Interact") then return "Interact target" end
		return "NPC target"
	end

	-- Rebuilds the description from its template so each field can be updated separately.
	local function RenderContributionDescription(state)
		local description = state.text
		if state.hasQuantity then
			local quantity = state.useObjectiveRemaining and "{objectiveRemaining}" or tostring(state.quantity or "##")
			-- Replaces the template count before inserting names or other user-supplied text.
			description = description:gsub(state.quantityPlaceholder, function()
				return "|cFFffcc33" .. quantity .. "|r"
			end)
		end
		if state.npcPlaceholder then
			local fallback = state.npcPlaceholder == "NPC" and "NPC" or "NPCNAME"
			local npcReference = state.npcReference or "{npc:NPCID:" .. fallback .. "}"
			description = description:gsub("{npc:NPCID:" .. state.npcPlaceholder .. "}",
				-- Returns the NPC reference.
				function() return npcReference end)
		end
		-- Returns the location.
		description = description:gsub("SUBZONE, ZONE", function() return state.location end)
			-- Substitutes the chosen nearby-body item label in the description.
			:gsub("{item:71967:item}", function()
				return "{item:71967:" .. state.nearBodyItemLabel .. "}"
			end)
		if state.itemID or state.itemName then
			-- Rebuilds an item reference with the chosen item ID and name.
			description = description:gsub("{item:%d+:[^}]+}", function(reference)
				local sourceID, sourceName = reference:match("{item:(%d+):([^}]+)}")
				return "{item:" .. (state.itemID or sourceID) .. ":" .. (state.itemName or sourceName) .. "}"
			end)
		end
		if state.spellID or state.spellName then
			-- Replaces the spell placeholder with the selected spell reference.
			description = description:gsub("{spell:SPELLID:SPELL}", function()
				return "{spell:" .. (state.spellID or "SPELLID") .. ":" .. (state.spellName or "SPELL") .. "}"
			end)
		end
		if state.objectValue and state.objectPlaceholder then
			-- Returns the object value.
			description = description:gsub(state.objectPlaceholder, function() return state.objectValue end)
		end
		return 'description = "' .. EscapeLuaString(description) .. '",'
	end

	-- Refreshes the contribution description copy.
	function RQE:RefreshContributionDescriptionCopy(frame, keepQuantityFocus)
		local state = frame and frame.descriptionState
		if not state or not frame:IsShown() then return end
		SetReferenceCopyValue(frame, RenderContributionDescription(state))
		if not keepQuantityFocus then
			SelectReferenceText(frame)
			QueueReferenceSelection(frame)
		end
	end

	-- Updates the contribution description NPC.
	function RQE:UpdateContributionDescriptionNPC(frame)
		local state = frame and frame.descriptionState
		if not state or not state.hasNPCButton then return end
		local name, npcID = TargetNPC()
		if not name then
			frame.macroStatus:SetText("Target an NPC, then press its button.")
			return
		end
		local reference = string.format("{npc:%d:%s}", npcID, name)
		if state.hasNPC then state.npcReference = reference end
		if state.objectPlaceholder == "OBJECT/NPC" then
			state.objectValue = reference
			frame.macroObjectInput:SetText("")
		end
		frame.questTitle:SetText(name)
		frame.questTitle:SetHeight(frame.questTitle:GetStringHeight())
		frame.macroStatus:SetText("Updated NPC: " .. name)
		self:RefreshContributionDescriptionCopy(frame)
	end

	-- Updates the contribution description ID.
	function RQE:UpdateContributionDescriptionID(frame)
		local state = frame and frame.descriptionState
		if not state or not state.idKind then return end
		local id = tonumber(frame.macroIDInput:GetText())
		if not id or id < 1 or id % 1 ~= 0 then
			frame.macroStatus:SetText("Enter a positive whole-number " .. state.idKind .. " ID.")
			return
		end
		state.lookupSerial = (state.lookupSerial or 0) + 1
		if state.idKind == "spell" then
			state.spellID, state.spellName = id, nil
			if RQE.API.GetSpellPresentation then
				local spellName = RQE.API.GetSpellPresentation(id)
				if type(spellName) == "string" and spellName ~= "" then state.spellName = spellName end
			end
			frame.macroStatus:SetText(state.spellName and ("Updated spell: " .. state.spellName)
				or "Spell name unavailable; the ID was updated.")
			return self:RefreshContributionDescriptionCopy(frame)
		end
		state.itemID, state.itemName = id, nil
		frame.macroStatus:SetText("Loading item name...")
		self:RefreshContributionDescriptionCopy(frame)
		local serial = state.lookupSerial
		-- Updates the copy preview after the requested item name becomes available.
		local function itemLoaded(resolvedID, itemName)
			if frame.descriptionState ~= state or state.lookupSerial ~= serial or state.itemID ~= resolvedID
				or not frame:IsShown() then return end
			if type(itemName) == "string" and itemName ~= "" then
				state.itemName = itemName
				frame.macroStatus:SetText("Updated item: " .. itemName)
			else
				frame.macroStatus:SetText("Item name unavailable; the ID was updated.")
			end
			self:RefreshContributionDescriptionCopy(frame)
		end
		if RQE_Contribution and RQE_Contribution.GetItemName then
			RQE_Contribution:GetItemName(id, itemLoaded)
		else
			itemLoaded(id, ClientCall("GetItemInfo", id))
		end
	end

	-- Resets the description count and enables manual entry when the remaining-objective option is unchecked.
	function RQE:UpdateContributionDescriptionQuantityMode(frame)
		local state = frame and frame.descriptionState
		if not state or not state.hasQuantity then return end
		state.useObjectiveRemaining = frame.descriptionQuantityMode:GetChecked() == true
		state.quantity = nil
		frame.macroQuantityInput:SetText("")
		frame.macroQuantityInput:SetEnabled(not state.useObjectiveRemaining)
		frame.macroQuantityButton:SetEnabled(not state.useObjectiveRemaining)
		frame.macroQuantityRow:SetAlpha(state.useObjectiveRemaining and 0.5 or 1)
		frame.macroStatus:SetText(state.useObjectiveRemaining and "Using the literal {objectiveRemaining} token."
			or "Enter a positive whole-number quantity, or keep ## as a placeholder.")
		self:RefreshContributionDescriptionCopy(frame)
	end

	-- Updates the manual description count without interrupting typing when requested.
	function RQE:UpdateContributionDescriptionQuantity(frame, keepQuantityFocus)
		local state = frame and frame.descriptionState
		if not state or not state.hasQuantity or state.useObjectiveRemaining then return end
		local text = frame.macroQuantityInput:GetText() or ""
		if text:match("^%s*$") then
			state.quantity = nil
			frame.macroStatus:SetText("Keeping ## as the quantity placeholder.")
			return self:RefreshContributionDescriptionCopy(frame, keepQuantityFocus)
		end
		local digits = text:match("^%s*(%d+)%s*$")
		local quantity = digits and tonumber(digits)
		if not quantity or quantity < 1 then
			frame.macroStatus:SetText("Enter a positive whole-number quantity.")
			return
		end
		state.quantity = quantity
		frame.macroStatus:SetText("Updated quantity to " .. quantity .. ".")
		self:RefreshContributionDescriptionCopy(frame, keepQuantityFocus)
	end

	-- Updates the contribution description object.
	function RQE:UpdateContributionDescriptionObject(frame)
		local state = frame and frame.descriptionState
		if not state or not state.hasObject then return end
		local objectName = (frame.macroObjectInput:GetText() or ""):match("^%s*(.-)%s*$")
		objectName = objectName:match('^"(.*)"$') or objectName:match("^'(.*)'$") or objectName
		if objectName == "" then
			frame.macroStatus:SetText("Enter an object or NPC name.")
			return
		end
		state.objectValue = objectName
		frame.macroStatus:SetText("Updated object or NPC name.")
		self:RefreshContributionDescriptionCopy(frame)
	end

	-- The current target and zone are captured on opening; controls can refine the text.
	function RQE:ShowContributionDescriptionCopy(template)
		if not ContributionLoaded() then return end
		if type(template) ~= "table" or type(template.text) ~= "string" then return end
		local name, npcID = TargetNPC()
		local npcPlaceholder = template.text:match("{npc:NPCID:([%u_]+)}")
		local hasNPC = npcPlaceholder ~= nil
		local objectPlaceholder = template.text:find("OBJECT/NPC", 1, true) and "OBJECT/NPC"
			or template.text:find("OBJECT", 1, true) and "OBJECT" or nil
		local quantityPlaceholder = template.text:match("|cFFffcc33{objectiveRemaining}|r")
			or template.text:match("|cFFffcc33##|r") or template.text:match("|cFFffcc33%d+|r")
			or template.text:match("##")
		local state = {
			text = template.text, location = PlayerZoneText() or "SUBZONE, ZONE",
			npcReference = hasNPC and name and string.format("{npc:%d:%s}", npcID, name) or nil,
			npcPlaceholder = npcPlaceholder,
			nearBodyItemLabel = name and "ITEMNAME" or "ITEM",
			hasNPC = hasNPC,
			hasNPCButton = (hasNPC and template.name ~= "Kill Multiple mobs and loot multiple items")
				or objectPlaceholder == "OBJECT/NPC",
			npcButtonLabel = DescriptionNPCButtonLabel(template.name, objectPlaceholder),
			idKind = template.text:find("{spell:SPELLID:SPELL}", 1, true) and "spell"
				or template.text:find("{item:%d+:[^}]+}") and "item" or nil,
			hasQuantity = quantityPlaceholder ~= nil, quantityPlaceholder = quantityPlaceholder,
			useObjectiveRemaining = true,
			hasObject = objectPlaceholder ~= nil, objectPlaceholder = objectPlaceholder,
		}
		return self:ShowCopyableReferenceText(template.name, name or "Description template",
			RenderContributionDescription(state), { descriptionState = state })
	end

	-------------------------------------------------------
	-- #7c. Reference Providers & Convenience Links
	-------------------------------------------------------

	-- Builds the requested Wowhead or Warcraft Wiki URL and opens the shared copy dialog.
	function RQE:ShowQuestReferenceLink(provider, questID)
		questID = tonumber(questID)
		if not questID then return end
		local title = ReferenceTitle(questID)
		if provider ~= "Wowhead" and not title then
			print("Quest title not available for Quest ID: " .. questID)
			return
		end
		local url
		if provider == "Wowhead" then url = "https://www.wowhead.com/quest=" .. questID
		elseif provider == "Warcraft Wiki" then
			url = "https://warcraft.wiki.gg/index.php?search=" .. EncodeQuery(title)
				.. "&title=Special%3ASearch&profile=default&fulltext=1"
		else return end
		local header = provider == "Wowhead" and "Wowhead quest link" or provider .. " quest search"
		return self:ShowCopyableQuestURL(header, questID, url, title)
	end

	-- Opens the selected quest's Wowhead URL in the shared copy dialog.
	function RQE:ShowWowheadLink(questID) self:ShowQuestReferenceLink("Wowhead", questID) end
	-- Opens a Warcraft Wiki search for the selected quest in the shared copy dialog.
	function RQE:ShowWowWikiLink(questID) self:ShowQuestReferenceLink("Warcraft Wiki", questID) end



--------------------------------------------------
-- #8. 🔄 Theme Refresh & Addon Lifecycle
--------------------------------------------------

	-------------------------------------------------------
	-- #8a. Live Quest-Tool Theme Refresh
	-------------------------------------------------------

	-- Reapplies current theme colors to every existing shared quest-tool menu.
	function RQE:RefreshQuestToolTheme()
		for _, menu in pairs(menus) do StyleMenu(menu) end
	end

	-------------------------------------------------------
	-- #8b. Login & Contribution Addon Watcher
	-------------------------------------------------------

	local watcher = CreateFrame("Frame")
	RQE.QuestToolEventWatcher = watcher
	watcher:RegisterEvent("PLAYER_LOGIN")
	watcher:RegisterEvent("ADDON_LOADED")
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:RegisterEvent("QUEST_ACCEPTED")
	watcher:RegisterEvent("QUEST_REMOVED")
	watcher:RegisterEvent("QUEST_TURNED_IN")
	-- Closes the quest filter menus.
	watcher:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_LOGIN" and LegacyTracker() and RQECharacterDB then
			RQE.QuestMenuSelection = Copy(RQECharacterDB.rqeQuestMenuSelection)
		elseif event == "ADDON_LOADED" and select(1, ...) == "RQE_Contribution" then
			RQE:CloseQuestFilterMenus()
		elseif event == "PLAYER_ENTERING_WORLD" then
			local isLogin, isReload = ...
			if isLogin or isReload then RQE:QueueAutoQuestCategoryRefresh(1.5) end
		elseif event == "QUEST_ACCEPTED" then
			RQE:QueueAutoQuestCategoryRefresh(0.5)
			-- RQE's rapid-accept watch repair runs four seconds later. Recheck once
			-- afterward so it cannot leave an unmatched quest in the selected list.
			if RQE:HasAutoQuestCategories() then
				-- Queues the auto quest category refresh.
				RQE.API.Client.C_Timer.After(4.2, function()
					RQE:QueueAutoQuestCategoryRefresh(0)
				end)
			end
		elseif event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" then
			RQE:QueueAutoQuestCategoryRefresh(0.5)
		elseif event == "PLAYER_REGEN_ENABLED" and RQE.AutoQuestCategoryRefreshPending then
			RQE:QueueAutoQuestCategoryRefresh(0)
		end
	end)
