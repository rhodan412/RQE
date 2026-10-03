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
			elseif kind == "frequency" then
				local frequency = info.frequency
				local daily = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily or 1
				local weekly = Enum and Enum.QuestFrequency and Enum.QuestFrequency.Weekly or 2
				matches = frequency == daily or frequency == weekly
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
	local function SetNativeWatches(selected)
		local watched = NativeWatches()
		-- Only player-log quests belong to this menu; other tracker sources retain
		-- their watches. Apply a diff so unchanged watches do not generate events.
		for _, info in ipairs(QuestLogEntries()) do
			local id = info.questID
			if watched[id] and not selected[id] then ClientCall("C_QuestLog.RemoveQuestWatch", id)
			elseif selected[id] and not watched[id] then ClientCall("C_QuestLog.AddQuestWatch", id) end
		end
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
			lastAction = self.QuestMenuLastAction }
		for _, key in ipairs(stateKeys) do snapshot[key] = Copy(self[key]) end
		self.QuestMenuRestoreState = snapshot
	end

	-- Restores RQE-owned selection fields and automatic-zone state from a captured snapshot.
	local function RestoreSnapshotFields(snapshot)
		for _, key in ipairs(stateKeys) do RQE[key] = Copy(snapshot[key]) end
		RQE.db.profile.autoTrackZoneQuests = snapshot.autoTrackZoneQuests
		RQE.QuestMenuLastAction = snapshot.lastAction
		if RQE.UpdateQuestTrackerSearchRestoreButton then RQE:UpdateQuestTrackerSearchRestoreButton() end
	end

	-- Disables automatic and search-driven membership before applying an explicit selection.
	local function PrepareManualSelection()
		RQE.db.profile.autoTrackZoneQuests = false
		RQE.QuestTrackerSearchResults, RQE.QuestTrackerSearchRestoreState = nil, nil
		if RQE.UpdateQuestTrackerSearchRestoreButton then RQE:UpdateQuestTrackerSearchRestoreButton() end
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
		RefreshTracker(focused)
		if self.db.profile.autoTrackZoneQuests then self.DisplayCurrentZoneQuests() end
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
			RQE[name] = function(...)
				RQE.QuestMenuSelection = nil
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
		menu:SetScript("OnMouseWheel", function(_, delta)
			local range = math.max(0, menu.content:GetHeight() - menu.scroll:GetHeight())
			menu.scroll:SetVerticalScroll(math.max(0, math.min(range, menu.scroll:GetVerticalScroll() - delta * 54)))
		end)
		menu:SetScript("OnLeave", function()
			After(0.3, function() if not TreeHovered() then RQE:CloseQuestFilterMenus() end end)
		end)
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
				row:SetScript("OnEnter", function(self)
					if self.tooltip then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(self.tooltip)
						GameTooltip:Show()
					end
				end)
				row:SetScript("OnLeave", function()
					GameTooltip:Hide()
					After(0.3, function() if not TreeHovered() then RQE:CloseQuestFilterMenus() end end)
				end)
				menu.rows[index] = row
			end
			row.item, row.RQEMenuKind, row.disabled = item, item.kind, item.disabled
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
			{ text = "More filters", submenu = "MoreFilters", build = function()
				return {
					{ text = "Zone quests", submenu = "Zone", build = function()
						return ExistingList(RQE.BuildZoneQuestMenuList, RQE.ScanAndCacheZoneQuests)
					end },
					{ text = "Quest type", submenu = "Type", build = function()
						return ExistingList(RQE.BuildQuestTypeMenuList, RQE.ScanQuestTypes, "type")
					end },
					{ text = "Quest line", submenu = "Line", build = function()
						return ExistingList(RQE.BuildQuestLineMenuList, RQE.RequestAndCacheQuestLines, "line")
					end },
				}
			end },
			{ kind = "separator" },
			{ text = "Automatic", kind = "heading" },
			{ text = "Auto-track current zone", keepOpen = true, checked = RQE.db.profile.autoTrackZoneQuests,
				tooltip = "Keep the current zone's quest selection updated using RQE's existing automatic zone tracking.",
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
			{ text = "Sorting", submenu = "Sorting", build = function()
				return {
					{ text = "RQE automatic proximity order", kind = "heading",
						tooltip = "RQE keeps its existing client-specific proximity ordering and distance fallbacks." },
					{ text = "Existing sorting remains active", disabled = true },
				}
			end },
			{ kind = "separator" },
			{ text = "Restore previous tracking", disabled = not RQE.QuestMenuRestoreState,
				action = function() RQE:RestoreQuestMenuTracking() end },
			{ text = "Untrack quest-log quests",
				action = function() RQE:ApplyQuestMenuSelection("none", nil, "Untrack quest-log quests") end },
		}
		if ContributionLoaded() then
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
		return text:gsub("[^A-Za-z0-9%-%_%.~]", function(char) return string.format("%%%02X", string.byte(char)) end)
	end

	-------------------------------------------------------
	-- #7b. Copyable Reference Dialog
	-------------------------------------------------------

	-- Creates or updates the movable copy dialog and selects the supplied quest URL.
	function RQE:ShowCopyableQuestURL(header, questID, url, title)
		questID = tonumber(questID)
		if not questID or type(header) ~= "string" or header == ""
			or type(url) ~= "string" or url == "" then return end
		title = title or ReferenceTitle(questID)
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
			frame.editBox:SetHeight(24)
			frame.editBox:SetPoint("TOPLEFT", frame.questTitle, "BOTTOMLEFT", 3, -14)
			frame.editBox:SetPoint("TOPRIGHT", frame.questTitle, "BOTTOMRIGHT", 0, -14)
			frame.editBox:SetHyperlinksEnabled(false)
			frame.editBox:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
			frame.editBox:SetScript("OnMouseUp", function() QueueReferenceSelection(frame) end)
			frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
			frame.editBox:SetScript("OnEnterPressed", function() frame:Hide() end)
			frame.editBox:SetScript("OnTextChanged", function(box, userInput)
				if userInput and box:GetText() ~= frame.url then
					box:SetText(frame.url)
					QueueReferenceSelection(frame)
				end
			end)
			frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
			frame.hint:SetPoint("TOPRIGHT", frame.editBox, "BOTTOMRIGHT", 0, -6)
			frame.hint:SetText("Ctrl+C to copy  |  Esc to close")
			frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
			frame.closeButton:SetSize(22, 22)
			frame.closeButton:SetPoint("TOPRIGHT", -7, -6)
			frame.closeButton:SetScript("OnClick", function() frame:Hide() end)
			frame:SetScript("OnDragStart", frame.StartMoving)
			frame:SetScript("OnDragStop", function()
				frame:StopMovingOrSizing()
				QueueReferenceSelection(frame)
			end)
			frame:SetScript("OnShow", function() QueueReferenceSelection(frame) end)
			frame:SetScript("OnHide", function() frame:StopMovingOrSizing(); frame.editBox:ClearFocus() end)
			RegisterEscape(frame)
			self.QuestReferenceLinkFrame = frame
			if self.UI then
				self.UI:StylePanel(frame, 0.98, "menu")
				self.UI:StyleSearchBox(frame.editBox)
				self.UI:StyleIconButton(frame.closeButton, "Close", { size = 22 })
			end
		end
		frame:SetWidth(math.min(540, UIParent:GetWidth() - 40))
		frame.provider:SetText(header)
		frame.questTitle:SetText(title or ("Quest " .. questID))
		frame.questTitle:SetHeight(frame.questTitle:GetStringHeight())
		frame:SetHeight(106 + frame.questTitle:GetStringHeight())
		frame.url = url
		frame.editBox:SetText(url)
		frame:Show()
		SelectReferenceText(frame)
		QueueReferenceSelection(frame)
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
	watcher:RegisterEvent("PLAYER_LOGIN")
	watcher:RegisterEvent("ADDON_LOADED")
	watcher:SetScript("OnEvent", function(_, event, addonName)
		if event == "PLAYER_LOGIN" and LegacyTracker() and RQECharacterDB then
			RQE.QuestMenuSelection = Copy(RQECharacterDB.rqeQuestMenuSelection)
		elseif addonName == "RQE_Contribution" then RQE:CloseQuestFilterMenus() end
	end)
