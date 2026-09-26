-- Profile-specific order for the Quest Tracker's child sections. The existing
-- client layout remains responsible for positioning when no custom order exists.
local RQE = RQE

local retailOrder = {
	"scenario", "campaign", "normal", "world", "bonus", "task", "profession", "achievements",
}
local classicOrder = {
	"scenario", "campaign", "normal", "world", "bonus", "task", "achievements", "profession",
}
local collapsible = {
	campaign = true, normal = true, world = true, bonus = true,
	task = true, profession = true, achievements = true,
}
local collapsedHeight = 32
local sectionBorderPieces = {
	"RQEThemeBorderTL", "RQEThemeBorderTR", "RQEThemeBorderBL", "RQEThemeBorderBR",
	"RQEThemeBorderTop", "RQEThemeBorderBottom", "RQEThemeBorderLeft", "RQEThemeBorderRight",
	"RQEThemeAzureTop", "RQEThemeAzureBottom", "RQEThemeAzureLeft", "RQEThemeAzureRight",
	"RQEThemeGoldTop",
}
local defaults = RQE.UpdateRecipeTrackingAnchor and retailOrder or classicOrder
local valid = {}
for _, key in ipairs(defaults) do valid[key] = true end

local function CopyOrder(order)
	local result = {}
	for index, key in ipairs(order) do result[index] = key end
	return result
end

function RQE:GetTrackerSectionDefaults()
	return CopyOrder(defaults)
end

function RQE:GetTrackerSectionOrder()
	local saved = self.db and self.db.profile and self.db.profile.trackerSectionOrder
	local result, seen = {}, {}
	if type(saved) == "table" then
		for _, key in ipairs(saved) do
			if valid[key] and not seen[key] then
				result[#result + 1], seen[key] = key, true
			end
		end
	end
	for _, key in ipairs(defaults) do
		if not seen[key] then result[#result + 1] = key end
	end
	return result
end

function RQE:HasCustomTrackerSectionOrder()
	local current = self:GetTrackerSectionOrder()
	for index, key in ipairs(defaults) do
		if current[index] ~= key then return true end
	end
	return false
end

function RQE:IsTrackerSectionCollapsed(key)
	local collapsed = self.db and self.db.profile and self.db.profile.trackerSectionCollapsed
	return collapsible[key] and type(collapsed) == "table" and collapsed[key] == true or false
end

function RQE:UsesManagedTrackerSectionLayout()
	if self:HasCustomTrackerSectionOrder() then return true end
	for key in pairs(collapsible) do
		if self:IsTrackerSectionCollapsed(key) then return true end
	end
	return false
end

local function SectionFrames()
	return {
		scenario = RQE.ScenarioChildFrame,
		campaign = RQE.CampaignFrame,
		normal = RQE.QuestsFrame,
		world = RQE.WorldQuestsFrame,
		bonus = RQE.BonusQuestsFrame,
		task = RQE.TaskQuestsFrame,
		profession = RQE.recipeTrackingFrame,
		achievements = RQE.AchievementsFrame,
	}
end

local function TrackedCount(key, frame)
	if key == "achievements" then return tonumber(frame.achieveCount) or 0 end
	if key == "profession" then return tonumber(frame.trackedRecipeCount) or 0 end
	return tonumber(frame.questCount) or 0
end

local function SetSectionBorderVisible(frame, visible)
	for _, key in ipairs(sectionBorderPieces) do
		local piece = frame[key]
		if piece then piece:SetShown(visible) end
	end
	local backdrop = frame.GetBackdrop and frame:GetBackdrop()
	if backdrop and backdrop.edgeFile and frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(1, 1, 1, visible and 1 or 0)
	end
end

function RQE:RefreshTrackerSectionHeaderText(frame, fullText)
	if not frame or not frame.header or not frame.headerFrame then return end
	if fullText ~= nil then frame._rqeFullHeaderText = tostring(fullText) end
	fullText = frame._rqeFullHeaderText or frame.header:GetText() or ""
	local title, header, button = frame.header, frame.headerFrame, frame._rqeCollapseButton
	local buttonWidth = button and button:GetWidth() or 0
	local available = math.max(1, (header:GetWidth() or frame:GetWidth() or 1) - buttonWidth - 48)
	title:ClearAllPoints()
	title:SetPoint("LEFT", header, "LEFT", 18, 0)
	title:SetWidth(available)
	title:SetJustifyH("CENTER")
	title:SetWordWrap(false)
	local measure = frame._rqeHeaderMeasure
	if not measure then
		measure = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		measure:SetAlpha(0)
		measure:SetWidth(10000)
		measure:SetWordWrap(false)
		frame._rqeHeaderMeasure = measure
	end
	local fontPath, fontSize, fontFlags = title:GetFont()
	if fontPath and fontSize then measure:SetFont(fontPath, fontSize, fontFlags) end
	local function widthOf(value)
		measure:SetText(value)
		return (measure.GetUnboundedStringWidth and measure:GetUnboundedStringWidth())
			or measure:GetStringWidth() or 0
	end
	if widthOf(fullText) <= available then
		title:SetText(fullText)
		return
	end
	local suffix = "..."
	if widthOf(suffix) > available then
		title:SetText("")
		return
	end
	local low, high = 0, #fullText
	while low < high do
		local middle = math.floor((low + high + 1) / 2)
		if widthOf(fullText:sub(1, middle) .. suffix) <= available then
			low = middle
		else
			high = middle - 1
		end
	end
	title:SetText(fullText:sub(1, low) .. suffix)
end

local function RefreshSectionPresentation(key, frame)
	if not collapsible[key] or not frame then return end
	local collapsed = RQE:IsTrackerSectionCollapsed(key)
	if frame.SetClipsChildren then frame:SetClipsChildren(collapsed) end
	if collapsed then
		local height = frame:GetHeight()
		if height and height > collapsedHeight then frame._rqeExpandedHeight = height end
		if height ~= collapsedHeight then frame:SetHeight(collapsedHeight) end
	elseif frame._rqeWasCollapsed then
		frame:SetHeight(math.max(80, frame._rqeRenderedHeight or frame._rqeExpandedHeight or 80))
	elseif key == "profession" and frame._rqeRenderedHeight
		and frame:GetHeight() < frame._rqeRenderedHeight then
		frame:SetHeight(frame._rqeRenderedHeight)
	end
	frame._rqeWasCollapsed = collapsed
	if frame._rqeCollapseButton then
		local button = frame._rqeCollapseButton
		local icon = collapsed and "Collapse" or "Expand"
		if button._rqeCollapseIcon ~= icon then
			button._rqeCollapseIcon = icon
			button:SetText(collapsed and "+" or "-")
			if RQE.UI then RQE.UI:StyleIconButton(button, icon, { size = 20 }) end
		end
	end
	SetSectionBorderVisible(frame, not collapsed and TrackedCount(key, frame) > 0)
	RQE:RefreshTrackerSectionHeaderText(frame)
end

function RQE:RefreshTrackerSectionPresentation()
	for key, frame in pairs(SectionFrames()) do
		RefreshSectionPresentation(key, frame)
	end
end

function RQE:SetTrackerSectionCollapsed(key, collapsed)
	if not collapsible[key] or not self.db or not self.db.profile then return end
	local profile = self.db.profile
	if collapsed then
		profile.trackerSectionCollapsed = profile.trackerSectionCollapsed or {}
		profile.trackerSectionCollapsed[key] = true
	elseif profile.trackerSectionCollapsed then
		profile.trackerSectionCollapsed[key] = nil
		if not next(profile.trackerSectionCollapsed) then profile.trackerSectionCollapsed = nil end
	end
	self:RefreshTrackerSectionOrder()
end

local function QueueScrollRange()
	if RQE._trackerOrderRangeQueued then return end
	RQE._trackerOrderRangeQueued = true
	RQE.API.Client.C_Timer.After(0, function()
		RQE._trackerOrderRangeQueued = nil
		if not RQE:UsesManagedTrackerSectionLayout() then return end
		-- The quest renderer first gives Campaign and Normal a coarse height.
		-- Immediately after a collapsed predecessor changes anchors, GetBottom()
		-- can be unavailable during that render, leaving the coarse height in
		-- place. Re-measure once the UI has resolved the new section positions.
		local frames = SectionFrames()
		local lastElements = RQE.TrackerSectionLastElements or {}
		local adjusted = false
		local padding = (RQE.UI and RQE.UI:IsEnabled()) and 18 or 10
		for _, key in ipairs({ "campaign", "normal", "world" }) do
			local frame, lastElement = frames[key], lastElements[key]
			if frame and frame:IsShown() and not RQE:IsTrackerSectionCollapsed(key)
				and lastElement and lastElement:IsShown() then
				local frameTop, elementBottom = frame:GetTop(), lastElement:GetBottom()
				if frameTop and elementBottom then
					local height = math.max(80, frameTop - elementBottom + padding)
					frame._rqeRenderedHeight = height
					if math.abs(frame:GetHeight() - height) > 1 then
						frame:SetHeight(height)
						adjusted = true
					end
				end
			end
		end
		if adjusted then
			RQE:ApplyTrackerSectionOrder()
			return
		end
		if RQE.RefreshQuestTrackerScrollRange then
			RQE.RefreshQuestTrackerScrollRange()
		elseif RQE.QTcontent and RQE.QTScrollFrame and RQE.QMQTslider then
			-- Classic/TBC use a total-height estimate rather than Retail's
			-- measured range. A reordered section can extend below that estimate.
			local top = RQE.QTcontent:GetTop()
			local bottom
			for _, frame in pairs(SectionFrames()) do
				if frame and frame:IsShown() then
					local sectionBottom = frame:GetBottom()
					if sectionBottom and (not bottom or sectionBottom < bottom) then
						bottom = sectionBottom
					end
				end
			end
			local viewport = RQE.QTScrollFrame:GetHeight() or 0
			if top and viewport > 0 then
				local height = math.max(viewport, bottom and (top - bottom + 10) or viewport)
				RQE.QTcontent:SetHeight(height)
				local maximum = math.max(0, height - viewport)
				RQE.QMQTslider:SetMinMaxValues(0, maximum)
				RQE.QMQTslider:SetShown(maximum > 0)
			end
		end
	end)
end

function RQE:ApplyTrackerSectionOrder(...)
	if select("#", ...) > 0 then
		local lastCampaign, lastNormal, lastWorld = ...
		self.TrackerSectionLastElements = {
			campaign = lastCampaign, normal = lastNormal, world = lastWorld,
		}
	end
	if not self:UsesManagedTrackerSectionLayout() or not self.QTcontent then return end

	local frames = SectionFrames()
	local lastElements = self.TrackerSectionLastElements or {}
	local previous, previousKey
	self:RefreshTrackerSectionPresentation()
	-- Detach the entire old chain before assigning the new one. Swapping two
	-- sections otherwise tries to anchor A below B while B still depends on A.
	for _, frame in pairs(frames) do frame:ClearAllPoints() end
	for _, key in ipairs(self:GetTrackerSectionOrder()) do
		local frame = frames[key]
		if frame then
			if previous then
				local element = not self:IsTrackerSectionCollapsed(previousKey) and lastElements[previousKey]
				local frameBottom = previous:GetBottom()
				local elementBottom = element and element:IsShown() and element:GetBottom()
				if frameBottom and elementBottom and elementBottom < frameBottom then
					local inset = (self.UI and self.UI:IsEnabled()) and 46 or 40
					local padding = (self.UI and self.UI:IsEnabled()) and 18 or 10
					frame:SetPoint("TOPLEFT", element, "BOTTOMLEFT", -inset, -(padding + 5))
				else
					local gap = self:IsTrackerSectionCollapsed(previousKey) and 10
						or previousKey == "scenario" and 30 or previousKey == "campaign" and 10 or 5
					frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -gap)
				end
			else
				frame:SetPoint("TOPLEFT", self.QTcontent, "TOPLEFT", 0, 0)
			end
			if frame:IsShown() then previous, previousKey = frame, key end
		end
	end
	self._trackerOrderWasManaged = true
	QueueScrollRange()
end

function RQE:RefreshTrackerSectionOrder()
	self:RefreshTrackerSectionPresentation()
	if self:UsesManagedTrackerSectionLayout() then
		self:ApplyTrackerSectionOrder()
	elseif self._trackerOrderWasManaged then
		self._trackerOrderWasManaged = nil
		self.TrackerSectionLastElements = nil
		if self.ScenarioChildFrame and self.QTcontent then
			self.ScenarioChildFrame:ClearAllPoints()
			self.ScenarioChildFrame:SetPoint("TOPLEFT", self.QTcontent, "TOPLEFT", 0, 0)
		end
		-- The next quest-list render begins with fixed-order SetPoint calls.
		-- Restore the whole default chain first so none of those calls sees a
		-- reversed dependency left by the previous profile's custom order.
		if UpdateFrameAnchors then UpdateFrameAnchors() end
		if UpdateRQEQuestFrame then UpdateRQEQuestFrame() end
		if self.RefreshQuestTrackerScrollRange then self.RefreshQuestTrackerScrollRange() end
	end
end

function RQE:MoveTrackerSectionAt(index, direction)
	local order = self:GetTrackerSectionOrder()
	local destination = index + direction
	if not order[index] or not order[destination] then return end
	order[index], order[destination] = order[destination], order[index]
	self.db.profile.trackerSectionOrder = order
	self:RefreshTrackerSectionOrder()
	LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE_Frame")
end

function RQE:ResetTrackerSectionOrder()
	self.db.profile.trackerSectionOrder = nil
	self:RefreshTrackerSectionOrder()
	LibStub("AceConfigRegistry-3.0"):NotifyChange("RQE_Frame")
end

-- Some sections are created or shown after the main quest-list pass. Reflow
-- after those transitions, without changing the default layout or polling.
local function QueueReflow()
	if not RQE:UsesManagedTrackerSectionLayout() or RQE._trackerOrderReflowQueued then return end
	RQE._trackerOrderReflowQueued = true
	RQE.API.Client.C_Timer.After(0, function()
		RQE._trackerOrderReflowQueued = nil
		RQE:ApplyTrackerSectionOrder()
	end)
end

local function WatchSection(frame)
	if not frame or frame._rqeOrderWatched then return end
	frame._rqeOrderWatched = true
	frame:HookScript("OnShow", QueueReflow)
	frame:HookScript("OnHide", QueueReflow)
	frame:HookScript("OnSizeChanged", QueueReflow)
end

for _, frame in pairs(SectionFrames()) do WatchSection(frame) end

local function InstallCollapseButton(key, frame)
	if not collapsible[key] or not frame or not frame.headerFrame or frame._rqeCollapseButton then return end
	local button = CreateFrame("Button", nil, frame.headerFrame, "UIPanelButtonTemplate")
	button:SetSize(18, 18)
	button:SetPoint("RIGHT", frame.headerFrame, "RIGHT", -21, 0)
	button:SetFrameLevel(frame.headerFrame:GetFrameLevel() + 2)
	button:SetScript("OnClick", function()
		RQE:SetTrackerSectionCollapsed(key, not RQE:IsTrackerSectionCollapsed(key))
	end)
	button:SetScript("OnEnter", function(owner)
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetText((RQE:IsTrackerSectionCollapsed(key) and "Expand " or "Collapse ")
			.. (frame._rqeFullHeaderText or key))
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frame._rqeCollapseButton = button
	frame._rqeFullHeaderText = frame.header and frame.header:GetText() or key
	frame.headerFrame:HookScript("OnSizeChanged", function()
		RQE:RefreshTrackerSectionHeaderText(frame)
	end)
	frame:HookScript("OnSizeChanged", function(owner, _, height)
		if RQE:IsTrackerSectionCollapsed(key) and height ~= collapsedHeight then
			if height and height > collapsedHeight then owner._rqeExpandedHeight = height end
			owner:SetHeight(collapsedHeight)
		elseif not RQE:IsTrackerSectionCollapsed(key) and height and height > collapsedHeight then
			owner._rqeExpandedHeight = height
		end
	end)
	RefreshSectionPresentation(key, frame)
end

for key, frame in pairs(SectionFrames()) do InstallCollapseButton(key, frame) end
if RQE.CreateRecipeTrackingFrame then
	hooksecurefunc(RQE, "CreateRecipeTrackingFrame", function()
		WatchSection(RQE.recipeTrackingFrame)
		InstallCollapseButton("profession", RQE.recipeTrackingFrame)
		QueueReflow()
	end)
end

if RQE.UI and RQE.UI.ApplySavedTheme then
	hooksecurefunc(RQE.UI, "ApplySavedTheme", function()
		RQE:RefreshTrackerSectionPresentation()
	end)
end

-- The existing renderers sometimes restore their fixed anchors as they build
-- rows. Reapply the profile order after each such path finishes, so it also
-- works when a section remains visible throughout a refresh.
hooksecurefunc("UpdateRQETaskQuestFrame", function()
	RQE:RefreshTrackerSectionPresentation()
	RQE:ApplyTrackerSectionOrder()
end)
hooksecurefunc("UpdateRQEWorldQuestFrame", function()
	RQE:RefreshTrackerSectionPresentation()
	RQE:ApplyTrackerSectionOrder()
end)
hooksecurefunc("UpdateRQEAchievementsFrame", function()
	RQE:RefreshTrackerSectionPresentation()
	RQE:ApplyTrackerSectionOrder()
end)
hooksecurefunc("UpdateRQEQuestFrame", function()
	RQE:RefreshTrackerSectionPresentation()
	RQE:ApplyTrackerSectionOrder()
end)
if RQE.RenderRecipeTrackingFrame then
	hooksecurefunc(RQE, "RenderRecipeTrackingFrame", function()
		RQE:RefreshTrackerSectionPresentation()
		RQE:ApplyTrackerSectionOrder()
	end)
end
