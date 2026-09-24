--[[
Permanent presentation layer for RQE's configuration interfaces.

This is deliberately independent of the optional Azure & Gold tracker theme.
RQE's standalone AceGUI window uses the ornate addon shell, while Blizzard's
AddOns pages retain their native canvas and border language around the same
icon-led option composition.  Option values, callbacks, profiles, and
client-specific behavior remain owned by the existing Config.lua files.
]]

RQE = RQE or {}
RQE.ConfigUI = RQE.ConfigUI or {}

local ConfigUI = RQE.ConfigUI
local COMPOSED_OPTIONS = setmetatable({}, { __mode = "k" })
local ROOT = "Interface\\AddOns\\RQE\\Media\\UI\\"
local PORTRAIT = "Interface\\AddOns\\RQE\\Textures\\rhodan.tga"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local COLORS = {
	azure = { 0 / 255, 87 / 255, 184 / 255 },
	azureBright = { 35 / 255, 145 / 255, 1 },
	gold = { 255 / 255, 215 / 255, 0 },
	charcoal = { 7 / 255, 11 / 255, 18 / 255 },
	raised = { 18 / 255, 24 / 255, 34 / 255 },
	muted = { 145 / 255, 156 / 255, 174 / 255 },
}

-- Register the shared color-preview controls after the active client Config.lua
-- has populated RQE's named font-color registry.
function ConfigUI:RegisterFontColorWidgets(AceGUI)
	if not AceGUI then return end

	local itemBaseLibrary = LibStub("AceGUI-3.0-DropDown-ItemBase", true)
	local itemWidgetType = "Dropdown-Item-RQEColorPreview"

	if itemBaseLibrary and not AceGUI:GetWidgetVersion(itemWidgetType) then
		local ItemBase = itemBaseLibrary.GetItemBase()

		local function UpdateCheckedState(self)
			if self.value then
				self.check:Show()
			else
				self.check:Hide()
			end
		end

		local function SetValue(self, value)
			self.value = value
			UpdateCheckedState(self)
		end

		local function GetValue(self)
			return self.value
		end

		local function SetText(self, text)
			ItemBase.SetText(self, text)

			local key = RQE.FontColorKeyByLabel[text] or RQE.FontColorKeyByLabel[self.text:GetText()]
			local option = key and RQE.FontColorOptions[key]
			if option then
				local r, g, b = RQE:GetFontColorRGB(key)
				self.preview:SetColorTexture(r, g, b, 1)
				self.preview:Show()
			else
				self.preview:Hide()
			end
		end

		local function OnRelease(self)
			ItemBase.OnRelease(self)
			self:SetValue(nil)
			self.preview:Hide()
		end

		local function OnClick(frame)
			local self = frame.obj
			if self.disabled then return end
			self:SetValue(not self.value)
			self:Fire("OnValueChanged", self.value)
		end

		local function Constructor()
			local self = ItemBase.Create(itemWidgetType)
			local preview = self.frame:CreateTexture(nil, "OVERLAY")
			preview:SetSize(13, 13)
			preview:SetPoint("RIGHT", self.frame, "RIGHT", -8, 0)
			preview:Hide()
			self.preview = preview

			self.text:ClearAllPoints()
			self.text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, 0)
			self.text:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -29, 0)
			self.SetValue = SetValue
			self.GetValue = GetValue
			self.SetText = SetText
			self.OnRelease = OnRelease
			self.frame:SetScript("OnClick", OnClick)
			AceGUI:RegisterAsWidget(self)
			return self
		end

		AceGUI:RegisterWidgetType(itemWidgetType, Constructor, 1 + ItemBase.version)
	end

	-- Decorate AceGUI's standard dropdown so the selected color also retains
	-- a live filled square while remaining fully compatible with AceConfig.
	local dropdownWidgetType = "RQEColorDropdown"
	if not AceGUI:GetWidgetVersion(dropdownWidgetType) then
		local function Constructor()
			local self = AceGUI:Create("Dropdown")
			local BaseOnAcquire = self.OnAcquire
			local BaseOnRelease = self.OnRelease
			local BaseSetText = self.SetText
			local BaseSetValue = self.SetValue

			self.type = dropdownWidgetType
			self.RQEBaseType = "Dropdown"
			self.RQESkipNextAcquire = true

			local preview = self.frame:CreateTexture(nil, "OVERLAY")
			preview:SetSize(13, 13)
			preview:SetPoint("RIGHT", self.button, "LEFT", -3, 2)
			preview:Hide()
			self.colorPreview = preview

			self.text:ClearAllPoints()
			self.text:SetPoint("LEFT", self.dropdown, "LEFT", 25, 2)
			self.text:SetPoint("RIGHT", preview, "LEFT", -5, 0)

			function self:UpdateColorPreview(value)
				local key = RQE.FontColorOptions[value] and value
					or RQE.FontColorKeyByHex[type(value) == "string" and value:lower() or ""]
					or RQE.FontColorKeyByLabel[value]
				if key then
					local r, g, b = RQE:GetFontColorRGB(key)
					self.colorPreview:SetColorTexture(r, g, b, 1)
					self.colorPreview:Show()
				else
					self.colorPreview:Hide()
				end
			end

			self.OnAcquire = function(widget)
				if widget.RQESkipNextAcquire then
					widget.RQESkipNextAcquire = nil
					return
				end
				BaseOnAcquire(widget)
				widget.colorPreview:Hide()
			end

			self.OnRelease = function(widget)
				widget.colorPreview:Hide()
				BaseOnRelease(widget)
			end

			self.SetText = function(widget, text)
				BaseSetText(widget, text)
				widget:UpdateColorPreview(text)
			end

			self.SetValue = function(widget, value)
				BaseSetValue(widget, value)
				widget:UpdateColorPreview(value)
			end

			return self
		end

		AceGUI:RegisterWidgetType(dropdownWidgetType, Constructor, 1)
	end
end

local function colorFont(fontString, color)
	if fontString and fontString.SetTextColor then
		fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
	end
end

local function hideRegion(region)
	if region and region.Hide then region:Hide() end
end

local function ensureTexture(frame, key, layer, subLevel)
	if not frame or not frame.CreateTexture then return nil end
	if not frame[key] then
		frame[key] = frame:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel or 0)
	end
	frame[key]:Show()
	return frame[key]
end

local function setLine(texture, r, g, b, a)
	if not texture then return end
	texture:SetTexture(WHITE)
	texture:SetVertexColor(r, g, b, a or 1)
	texture:SetHorizTile(false)
	texture:SetVertTile(false)
end

local function skinSurface(frame, alpha, inset)
	if not frame or not frame.CreateTexture then return end
	inset = inset or 0
	local background = ensureTexture(frame, "RQEConfigBackground", "BACKGROUND", -7)
	background:SetTexture(WHITE)
	background:SetVertexColor(COLORS.charcoal[1], COLORS.charcoal[2], COLORS.charcoal[3], alpha or 0.9)
	background:ClearAllPoints()
	background:SetPoint("TOPLEFT", inset, -inset)
	background:SetPoint("BOTTOMRIGHT", -inset, inset)

	local top = ensureTexture(frame, "RQEConfigAzureTop", "BORDER", 5)
	local bottom = ensureTexture(frame, "RQEConfigAzureBottom", "BORDER", 5)
	local left = ensureTexture(frame, "RQEConfigAzureLeft", "BORDER", 5)
	local right = ensureTexture(frame, "RQEConfigAzureRight", "BORDER", 5)
	setLine(top, COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 0.95)
	setLine(bottom, COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.95)
	setLine(left, COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.95)
	setLine(right, COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.95)
	top:ClearAllPoints(); top:SetPoint("TOPLEFT", inset + 2, -inset); top:SetPoint("TOPRIGHT", -inset - 2, -inset); top:SetHeight(1)
	bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", inset + 2, inset); bottom:SetPoint("BOTTOMRIGHT", -inset - 2, inset); bottom:SetHeight(1)
	left:ClearAllPoints(); left:SetPoint("TOPLEFT", inset, -inset - 2); left:SetPoint("BOTTOMLEFT", inset, inset + 2); left:SetWidth(1)
	right:ClearAllPoints(); right:SetPoint("TOPRIGHT", -inset, -inset - 2); right:SetPoint("BOTTOMRIGHT", -inset, inset + 2); right:SetWidth(1)

	local gold = ensureTexture(frame, "RQEConfigGoldTop", "BORDER", 6)
	setLine(gold, COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.82)
	gold:ClearAllPoints(); gold:SetPoint("TOPLEFT", inset + 12, -inset - 3); gold:SetPoint("TOPRIGHT", -inset - 12, -inset - 3); gold:SetHeight(1)
end

local function skinEditField(editBox)
	if not editBox then return end
	if editBox.SetBackdrop then
		editBox:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
		editBox:SetBackdropColor(COLORS.charcoal[1], COLORS.charcoal[2], COLORS.charcoal[3], 0.94)
		editBox:SetBackdropBorderColor(COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.95)
	end
	if editBox.SetTextColor then editBox:SetTextColor(1, 1, 1) end
end

local function skinButton(button)
	if not button then return end
	if RQE.UI and RQE.UI._ApplyTextButton then
		RQE.UI:_ApplyTextButton(button)
		return
	end
	colorFont(button.GetFontString and button:GetFontString(), COLORS.gold)
end

local function skinTabs(widget)
	if not widget or not widget.tabs then return end
	for _, tab in ipairs(widget.tabs) do
		colorFont(tab.GetFontString and tab:GetFontString(), COLORS.gold)
		for _, piece in ipairs({ tab.Left, tab.Middle, tab.Right, tab.leftTexture, tab.middleTexture, tab.rightTexture }) do
			if piece then piece:SetVertexColor(0.2, 0.5, 0.82, 1) end
		end
		for _, piece in ipairs({ tab.LeftDisabled, tab.MiddleDisabled, tab.RightDisabled }) do
			if piece then piece:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.88) end
		end
		local highlight = tab.HighlightTexture or tab.highlightTexture
		if highlight then highlight:SetVertexColor(COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 0.9) end
		if tab.SetBackdrop then
			tab:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
			tab:SetBackdropColor(COLORS.raised[1], COLORS.raised[2], COLORS.raised[3], 0.96)
			tab:SetBackdropBorderColor(COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.9)
		end
	end
end

local function watchContainer(widget, mode)
	if not widget then return end
	widget.RQEConfigChildMode = mode or "styled"
	if widget.RQEConfigAddChildWrapped or type(widget.AddChild) ~= "function" then return end
	local originalAddChild = widget.AddChild
	widget.AddChild = function(owner, child, ...)
		local result = originalAddChild(owner, child, ...)
		if owner.RQEConfigChildMode == "native" then
			ConfigUI:UseNativeWidget(child)
		else
			ConfigUI:SkinWidget(child)
		end
		return result
	end
	widget.RQEConfigAddChildWrapped = true
end

local function updateStyledScrollFrame(widget)
	local scrollbar = widget and widget.scrollbar
	local scrollframe = widget and widget.scrollframe
	local content = widget and widget.content
	local outerFrame = widget and widget.frame
	if not scrollbar or not scrollframe or not content or not outerFrame then return end

	-- AceGUI creates this slider from UIPanelScrollBarTemplate. Retain its
	-- value callbacks, but remove the template track and arrow controls.
	local thumb = scrollbar:GetThumbTexture()
	for _, region in ipairs({ scrollbar:GetRegions() }) do
		if region ~= thumb then region:Hide() end
	end
	for _, child in ipairs({ scrollbar:GetChildren() }) do
		if child ~= scrollbar.RQEDragHandle then
			child:Hide()
			if child.Disable then child:Disable() end
		end
	end

	scrollbar:ClearAllPoints()
	scrollbar:SetPoint("TOPRIGHT", outerFrame, "TOPRIGHT", -2, -2)
	scrollbar:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", -2, 2)
	scrollbar:SetWidth(10)
	scrollbar:Show()

	if thumb then
		thumb:SetTexture(WHITE)
		thumb:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1)
		thumb:SetWidth(4)
		local trackHeight = math.max(1, scrollbar:GetHeight())
		local viewportHeight = math.max(0, scrollframe:GetHeight())
		local contentHeight = math.max(0, content:GetHeight())
		local ratio = contentHeight > 0 and math.min(1, viewportHeight / contentHeight) or 1
		thumb:SetHeight(math.min(trackHeight, math.max(32, trackHeight * ratio)))
	end
	RQE.API.ConfigureScrollbarDrag(scrollbar, function(_, delta)
		local handler = scrollframe:GetScript("OnMouseWheel")
		if handler then handler(scrollframe, delta) end
	end)
end

local function restoreNativeScrollFrame(widget)
	local scrollbar = widget and widget.scrollbar
	local scrollframe = widget and widget.scrollframe
	if not scrollbar or not scrollframe then return end
	local thumb = scrollbar:GetThumbTexture()
	local original = widget.RQEConfigOriginalScrollThumb

	for _, region in ipairs({ scrollbar:GetRegions() }) do region:Show() end
	for _, child in ipairs({ scrollbar:GetChildren() }) do
		if child == scrollbar.RQEDragHandle then
			child:Hide()
		else
			if child.Enable then child:Enable() end
			child:Show()
		end
	end
	scrollbar:ClearAllPoints()
	scrollbar:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", scrollframe, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetWidth(16)
	if thumb then
		thumb:SetTexture(original and original.texture or "Interface\\Buttons\\UI-ScrollBar-Knob")
		thumb:SetVertexColor(1, 1, 1, 1)
		if original then thumb:SetSize(original.width, original.height) end
	end
	if widget.scrollBarShown then scrollbar:Show() else scrollbar:Hide() end
end

local function styleScrollFrame(widget)
	if not widget or not widget.scrollbar then return end
	if not widget.RQEConfigScrollbarStyled then
		widget.RQEConfigScrollbarStyled = true
		local originalThumb = widget.scrollbar:GetThumbTexture()
		if originalThumb then
			widget.RQEConfigOriginalScrollThumb = {
				texture = originalThumb:GetTexture(),
				width = originalThumb:GetWidth() > 0 and originalThumb:GetWidth() or 24,
				height = originalThumb:GetHeight() > 0 and originalThumb:GetHeight() or 24,
			}
		end
		local originalFixScroll = widget.FixScroll
		widget.FixScroll = function(owner, ...)
			local result = originalFixScroll(owner, ...)
			if owner.RQEConfigChildMode == "styled" then updateStyledScrollFrame(owner) end
			return result
		end
		if widget.frame and widget.frame.HookScript then
			widget.frame:HookScript("OnShow", function()
				C_Timer.After(0, function()
					if widget.RQEConfigChildMode == "styled" then updateStyledScrollFrame(widget) end
				end)
			end)
		end
	end
	updateStyledScrollFrame(widget)
end

function ConfigUI:SkinWidget(widget)
	if not widget then return end
	watchContainer(widget, "styled")

	local kind = widget.RQEBaseType or widget.type
	if kind == "Button" then
		colorFont(widget.text, COLORS.gold)
	elseif kind == "CheckBox" then
		colorFont(widget.text, { 1, 1, 1 })
		colorFont(widget.desc, COLORS.muted)
		if widget.checkbg then widget.checkbg:SetVertexColor(0.55, 0.78, 1, 1) end
		if widget.check then widget.check:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1) end
		if widget.highlight then widget.highlight:SetVertexColor(COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 0.9) end
	elseif kind == "Slider" then
		colorFont(widget.label, COLORS.gold)
		colorFont(widget.lowtext, { 1, 1, 1 })
		colorFont(widget.hightext, { 1, 1, 1 })
		if widget.slider and widget.slider.SetBackdropColor then
			widget.slider:SetBackdropColor(COLORS.charcoal[1], COLORS.charcoal[2], COLORS.charcoal[3], 0.95)
			widget.slider:SetBackdropBorderColor(COLORS.azure[1], COLORS.azure[2], COLORS.azure[3], 0.9)
			local thumb = widget.slider:GetThumbTexture()
			if thumb then thumb:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1) end
		end
		skinEditField(widget.editbox)
	elseif kind == "Dropdown" then
		colorFont(widget.label, COLORS.gold)
		colorFont(widget.text, { 1, 1, 1 })
		if widget.dropdown and widget.dropdown.GetName then
			local name = widget.dropdown:GetName()
			for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
				local texture = _G[name .. suffix]
				if texture then texture:SetVertexColor(0.16, 0.33, 0.52, 1) end
			end
		end
		if widget.button and widget.button.GetNormalTexture then
			local arrow = widget.button:GetNormalTexture()
			if arrow then arrow:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1) end
		end
	elseif kind == "Heading" then
		colorFont(widget.label, COLORS.gold)
		if widget.left then widget.left:SetVertexColor(COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 1) end
		if widget.right then widget.right:SetVertexColor(COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 1) end
	elseif kind == "InlineGroup" then
		colorFont(widget.titletext, COLORS.gold)
		skinSurface(widget.content and widget.content:GetParent() or widget.frame, 0.82, 0)
	elseif kind == "TabGroup" then
		colorFont(widget.titletext, COLORS.gold)
		skinSurface(widget.border or widget.frame, 0.82, 0)
		if not widget.RQEConfigBuildTabsWrapped and type(widget.BuildTabs) == "function" then
			local originalBuildTabs = widget.BuildTabs
			widget.BuildTabs = function(owner, ...)
				local result = originalBuildTabs(owner, ...)
				skinTabs(owner)
				return result
			end
			widget.RQEConfigBuildTabsWrapped = true
		end
		if not widget.RQEConfigSelectTabWrapped and type(widget.SelectTab) == "function" then
			local originalSelectTab = widget.SelectTab
			widget.SelectTab = function(owner, ...)
				local result = originalSelectTab(owner, ...)
				skinTabs(owner)
				return result
			end
			widget.RQEConfigSelectTabWrapped = true
		end
		skinTabs(widget)
	elseif kind == "EditBox" then
		colorFont(widget.label, COLORS.gold)
		skinEditField(widget.editbox)
	elseif kind == "MultiLineEditBox" then
		colorFont(widget.label, COLORS.gold)
		skinEditField(widget.editBox)
		skinSurface(widget.scrollBG or widget.scrollFrame, 0.88, 0)
	elseif kind == "Keybinding" then
		colorFont(widget.label, COLORS.gold)
		colorFont(widget.button and widget.button.GetFontString and widget.button:GetFontString(), COLORS.gold)
	elseif kind == "ColorPicker" then
		colorFont(widget.text, { 1, 1, 1 })
	elseif kind == "DropdownGroup" then
		colorFont(widget.titletext, COLORS.gold)
		skinSurface(widget.border or widget.frame, 0.82, 0)
		self:SkinWidget(widget.dropdown)
	elseif kind == "ScrollFrame" then
		styleScrollFrame(widget)
	end

	if widget.children then
		for _, child in ipairs(widget.children) do self:SkinWidget(child) end
	end
end

local function hideCustomSurface(frame)
	if not frame then return end
	for _, key in ipairs({
		"RQEConfigBackground", "RQEConfigAzureTop", "RQEConfigAzureBottom",
		"RQEConfigAzureLeft", "RQEConfigAzureRight", "RQEConfigGoldTop",
	}) do
		hideRegion(frame[key])
	end
end

function ConfigUI:UseNativeWidget(widget)
	if not widget then return end
	watchContainer(widget, "native")

	local kind = widget.RQEBaseType or widget.type
	if kind == "Button" then
		colorFont(widget.text, COLORS.gold)
	elseif kind == "CheckBox" then
		colorFont(widget.text, { 1, 1, 1 })
		colorFont(widget.desc, COLORS.muted)
		if widget.checkbg then widget.checkbg:SetVertexColor(1, 1, 1, 1) end
		if widget.check then widget.check:SetVertexColor(1, 1, 1, 1) end
		if widget.highlight then widget.highlight:SetVertexColor(1, 1, 1, 1) end
	elseif kind == "Slider" then
		colorFont(widget.label, COLORS.gold)
		colorFont(widget.lowtext, { 1, 1, 1 })
		colorFont(widget.hightext, { 1, 1, 1 })
		if widget.slider and widget.slider.SetBackdropColor then
			widget.slider:SetBackdropColor(0, 0, 0, 0.5)
			widget.slider:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
			local thumb = widget.slider:GetThumbTexture()
			if thumb then thumb:SetVertexColor(1, 1, 1, 1) end
		end
	elseif kind == "Dropdown" then
		colorFont(widget.label, COLORS.gold)
		colorFont(widget.text, { 1, 1, 1 })
		if widget.dropdown and widget.dropdown.GetName then
			local name = widget.dropdown:GetName()
			for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
				local texture = _G[name .. suffix]
				if texture then texture:SetVertexColor(1, 1, 1, 1) end
			end
		end
		if widget.button and widget.button.GetNormalTexture then
			local arrow = widget.button:GetNormalTexture()
			if arrow then arrow:SetVertexColor(1, 1, 1, 1) end
		end
	elseif kind == "Heading" then
		colorFont(widget.label, COLORS.gold)
		if widget.left then widget.left:SetVertexColor(1, 1, 1, 1) end
		if widget.right then widget.right:SetVertexColor(1, 1, 1, 1) end
	elseif kind == "InlineGroup" then
		colorFont(widget.titletext, COLORS.gold)
		hideCustomSurface(widget.content and widget.content:GetParent() or widget.frame)
	elseif kind == "TabGroup" or kind == "DropdownGroup" then
		hideCustomSurface(widget.border or widget.frame)
	elseif kind == "EditBox" then
		colorFont(widget.label, COLORS.gold)
		if widget.editbox and widget.editbox.SetBackdropColor then
			widget.editbox:SetBackdropColor(0, 0, 0, 0.5)
			widget.editbox:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
		end
	elseif kind == "MultiLineEditBox" then
		colorFont(widget.label, COLORS.gold)
		hideCustomSurface(widget.scrollBG or widget.scrollFrame)
	elseif kind == "Keybinding" then
		colorFont(widget.label, COLORS.gold)
	elseif kind == "ScrollFrame" and widget.scrollbar then
		restoreNativeScrollFrame(widget)
	end

	if widget.children then
		for _, child in ipairs(widget.children) do self:UseNativeWidget(child) end
	end
end

local function sectionTitle(iconName, text)
	return "|T" .. ROOT .. "Icons\\" .. iconName .. ".tga:20:20:0:0|t  " .. text
end

local function createOptionGroup(iconName, name, order)
	return {
		type = "group",
		name = sectionTitle(iconName, name),
		inline = true,
		order = order,
		args = {},
	}
end

local function placeOption(destination, source, used, key, name, order, width)
	local option = source[key]
	if not option then return end
	used[key] = true
	if name then option.name = name end
	if order then option.order = order end
	if width then option.width = width end
	destination[key] = option
end

local function appendRemaining(group, source, used, order)
	for key, option in pairs(source) do
		if not used[key] then
			order = order + 1
			option.order = order
			if option.type == "toggle" and (not option.width or option.width == "half") then
				option.width = 1.5
			end
			group.args[key] = option
		end
	end
	return order
end

local function composeGeneralPage(page)
	local source = page.args
	local used = {}
	local frames = createOptionGroup("Settings", "Frames", 1)
	placeOption(frames.args, source, used, "enableFrame", "Show Quest Helper", 1, 1.25)
	placeOption(frames.args, source, used, "hideRQEFrameWhenEmpty", "Hide Helper when empty", 2, 1.25)
	placeOption(frames.args, source, used, "enableQuestFrame", "Show Quest Tracker", 3, 1.25)
	placeOption(frames.args, source, used, "hideRQEQuestFrameWhenEmpty", "Hide Tracker when empty", 4, 1.3)

	local map = createOptionGroup("Zone", "Map & Minimap", 2)
	placeOption(map.args, source, used, "minimapToggle", "Minimap button", 1, 1.25)
	placeOption(map.args, source, used, "showMapID", "Map ID", 2, 1)
	placeOption(map.args, source, used, "showCoordinates", "Coordinates", 3, 1)
	placeOption(map.args, source, used, "minimapButtonAngle", "Button position", 4, "double")

	local automation = createOptionGroup("TrackerTurnIn", "Quest Automation", 3)
	placeOption(automation.args, source, used, "autoQuestWatch", "Watch new quests", 1, 1.3)
	placeOption(automation.args, source, used, "autoQuestProgress", "Watch recent progress", 2, 1.45)
	placeOption(automation.args, source, used, "removeWQatLogin", "Clear world quests at login", 3, 1.55)
	placeOption(automation.args, source, used, "autoTrackZoneQuests", "Track quests for the current zone", 4, 1.9)
	placeOption(automation.args, source, used, "autoClickWaypointButton", "Advance waypoint automatically", 5, 1.75)

	local tracking = createOptionGroup("SearchGroup", "Smart Tracking", 4)
	placeOption(tracking.args, source, used, "enableAutoSuperTrackSwap", "Nearest quest while moving", 1, 1.55)
	placeOption(tracking.args, source, used, "enableNearestSuperTrack", "Choose a quest when none is focused", 2, 1.9)
	placeOption(tracking.args, source, used, "enableNearestSuperTrackCampaign", "Prefer campaign quests at max level", 3, 1.9)
	placeOption(tracking.args, source, used, "enableNearestSuperTrackCampaignLevelingOnly", "Prefer campaign quests while leveling", 4, 2.05)
	placeOption(tracking.args, source, used, "enableQuestTypeDisplay", "Quest-type badges", 5, 1.3)

	local actions = createOptionGroup("MacroAction", "Integrations & Actions", 5)
	placeOption(actions.args, source, used, "enableTomTomCompatibility", "TomTom waypoints", 1, 1.3)
	placeOption(actions.args, source, used, "enableCarboniteCompatibility", "Carbonite waypoints", 2, 1.4)
	placeOption(actions.args, source, used, "enableQuestAbandonConfirm", "Quick quest abandon", 3, 1.4)
	placeOption(actions.args, source, used, "enableGossipModeAutomation", "Gossip automation", 4, 1.35)
	placeOption(actions.args, source, used, "enableMouseOverMarking", "Mark mouseover targets", 5, 1.5)
	placeOption(actions.args, source, used, "enableTravelSuggestions", "Travel suggestions", 6, 1.3)
	placeOption(actions.args, source, used, "keyBindSetting", "Magic Button key", 7, 1.5)

	local advanced = createOptionGroup("Settings", "Additional Options", 6)
	appendRemaining(advanced, source, used, 0)
	page.name = "General"
	page.args = { frames = frames, map = map, automation = automation, tracking = tracking, actions = actions }
	if next(advanced.args) then page.args.advanced = advanced end
end

local function configurePositionGroup(group, iconName, title)
	if not group or not group.args then return end
	group.name = sectionTitle(iconName, title)
	group.inline = true
	local labels = {
		anchorPoint = "Screen anchor",
		xPos = "Horizontal offset",
		yPos = "Vertical offset",
		MainFrameOpacity = "Background opacity",
		QuestFrameOpacity = "Background opacity",
		frameWidth = "Width",
		frameHeight = "Height",
	}
	local order = { "lockPosition", "anchorPoint", "xPos", "yPos", "MainFrameOpacity", "QuestFrameOpacity", "frameWidth", "frameHeight" }
	for index, key in ipairs(order) do
		local option = group.args[key]
		if option then
			option.name = key == "lockPosition"
				and ("Lock " .. title:gsub(" Layout$", "") .. " position and size")
				or labels[key]
			option.order = index
			option.width = key == "lockPosition" and "full" or 1
		end
	end
end

local function composeFramePage(page)
	local source = page.args
	local used = { framePosition = true, QuestFramePosition = true }
	local behavior = createOptionGroup("ShowAll", "Display Behavior", 1)
	placeOption(behavior.args, source, used, "toggleBlizzObjectiveTracker", "Blizzard Objective Tracker", 1, 1.5)
	placeOption(behavior.args, source, used, "mythicScenarioMode", "Use Blizzard tracker in scenarios", 2, 1.85)
	placeOption(behavior.args, source, used, "enableStepControls", "Manual step navigation", 3, 1.5)
	placeOption(behavior.args, source, used, "useModernTheme", "Azure & Gold tracker frames", 4, 1.6)
	placeOption(behavior.args, source, used, "creatureObjectPreview", "Creature and object previews", 5, "full")
	appendRemaining(behavior, source, used, 5)

	configurePositionGroup(source.framePosition, "WaypointTarget", "Quest Helper Layout")
	configurePositionGroup(source.QuestFramePosition, "QuestWorld", "Quest Tracker Layout")
	source.framePosition.order = 2
	source.QuestFramePosition.order = 3
	page.args = {
		behavior = behavior,
		framePosition = source.framePosition,
		QuestFramePosition = source.QuestFramePosition,
	}
end

local FONT_SIZE_VALUES, FONT_SIZE_ORDER = {}, {}
for size = 8, 24 do
	FONT_SIZE_VALUES[size] = tostring(size)
	FONT_SIZE_ORDER[#FONT_SIZE_ORDER + 1] = size
end

local function composeFontPage(page)
	local source = page.args.fontSizeAndColor and page.args.fontSizeAndColor.args or page.args
	local keys = { "headerText", "QuestIDText", "QuestNameText", "DirectionTextFrame", "QuestDescription" }
	local names = { "Window Headers", "Quest IDs", "Quest Names", "Directions", "Quest Descriptions" }
	local icons = { "Settings", "QuestCampaign", "QuestNormal", "RouteNode", "Look" }
	local args = {
		intro = {
			type = "description",
			name = "Choose a compact preset for each text role. Changes apply immediately.",
			order = 0,
			width = "full",
		},
	}
	for index, key in ipairs(keys) do
		local group = source[key]
		if group and group.args then
			group.name = sectionTitle(icons[index], names[index])
			group.inline = true
			group.order = index
			local size = group.args.fontSize
			if size then
				size.type = "select"
				size.min = nil
				size.softMin = nil
				size.max = nil
				size.softMax = nil
				size.step = nil
				size.bigStep = nil
				size.isPercent = nil
				size.name = "Size"
				size.values = FONT_SIZE_VALUES
				size.sorting = FONT_SIZE_ORDER
				size.width = 0.7
				size.order = 1
			end
			if group.args.fontStyle then
				group.args.fontStyle.name = "Typeface"
				group.args.fontStyle.width = 1.15
				group.args.fontStyle.order = 2
			end
			if group.args.fontColor then
				group.args.fontColor.name = "Color"
				group.args.fontColor.width = 1.15
				group.args.fontColor.order = 3
			end
			args[key] = group
		end
	end
	page.args = args
end

local function addDebugTraceOptions(group, definitions)
	for order, definition in ipairs(definitions) do
		local key, label = definition[1], definition[2]
		group.args[key] = {
			type = "toggle",
			name = label,
			desc = definition[3] or ("Print " .. label .. " diagnostics to chat when this event is available on the current client."),
			order = order + 1,
			width = 1.5,
			get = function() return RQE.db.profile[key] == true end,
			set = function(_, value) RQE.db.profile[key] = value end,
		}
	end
end

local function composeDebugPage(page)
	local source = page.args
	local used = { debug = true }
	local diagnostics = createOptionGroup("Search", "Diagnostics", 1)
	placeOption(diagnostics.args, source, used, "debugMode", "Debug mode", 1, 1.35)
	placeOption(diagnostics.args, source, used, "displayRQEmemUsage", "Memory meter", 2, 1.4)
	placeOption(diagnostics.args, source, used, "displayRQEcpuUsage", "CPU meter", 3, 1.35)
	placeOption(diagnostics.args, source, used, "debugTimeStampCheckbox", "Timestamps", 4, 1.35)
	appendRemaining(diagnostics, source, used, 4)
	local tools = source.debug
	if tools then
		tools.name = sectionTitle("Settings", "Logging & Recovery")
		tools.inline = true
		tools.order = 2
		if tools.args.debugLevel then tools.args.debugLevel.name = "Log level"; tools.args.debugLevel.width = 1 end
		if tools.args.resetFramePosition then tools.args.resetFramePosition.name = "Reset positions"; tools.args.resetFramePosition.width = 1 end
		if tools.args.resetFrameSize then tools.args.resetFrameSize.name = "Reset sizes"; tools.args.resetFrameSize.width = 1 end
	end
	local infoTrace = createOptionGroup("Search", "INFO event tracing", 3)
	infoTrace.hidden = function()
		local profile = RQE.db.profile
		return not profile.debugMode or (profile.debugLevel ~= "INFO" and profile.debugLevel ~= "INFO+")
	end
	infoTrace.args.note = {
		type = "description", name = "Enable only the traces you need; event and payload output can be very frequent.",
		order = 1, width = "full",
	}
	addDebugTraceOptions(infoTrace, {
		{ "showEventDebugInfo", "Event names and memory", "Print event names and RQE memory usage for the filtered event stream." },
		{ "showArgPayloadInfo", "Event arguments / payloads", "Print the event arguments and payloads captured by RQE's event handlers." },
	})

	local function infoPlusOnly()
		local profile = RQE.db.profile
		return not profile.debugMode or profile.debugLevel ~= "INFO+"
	end
	local worldTrace = createOptionGroup("Settings", "INFO+ world and system events", 4)
	worldTrace.hidden = infoPlusOnly
	addDebugTraceOptions(worldTrace, {
		{ "showStartPeriodicCheckInfo", "Periodic checks", "Print the quest selected when StartPeriodicChecks runs." },
		{ "showAddonLoaded", "ADDON_LOADED" },
		{ "showPlayerLogin", "PLAYER_LOGIN" },
		{ "PlayerEnteringWorld", "PLAYER_ENTERING_WORLD" },
		{ "PlayerStartedMoving", "PLAYER_STARTED_MOVING" },
		{ "PlayerStoppedMoving", "PLAYER_STOPPED_MOVING" },
		{ "showPlayerRegenEnabled", "PLAYER_REGEN_ENABLED" },
		{ "showPlayerMountDisplayChanged", "PLAYER_MOUNT_DISPLAY_CHANGED" },
		{ "ZoneChange", "Zone changes / vehicle exit" },
		{ "UpdateInstanceInfo", "UPDATE_INSTANCE_INFO" },
		{ "ClientSceneOpened", "CLIENT_SCENE_OPENED" },
		{ "ClientSceneClosed", "CLIENT_SCENE_CLOSED" },
		{ "showItemCountChanged", "ITEM_COUNT_CHANGED" },
		{ "LFGActiveEntryUpdate", "LFG_LIST_ACTIVE_ENTRY_UPDATE" },
		{ "WorldStateTimerStart", "WORLD_STATE_TIMER_START" },
		{ "WorldStateTimerStop", "WORLD_STATE_TIMER_STOP" },
		{ "JailorsTowerLevelUpdate", "JAILERS_TOWER_LEVEL_UPDATE" },
	})

	local questTrace = createOptionGroup("QuestNormal", "INFO+ quest and achievement events", 5)
	questTrace.hidden = infoPlusOnly
	addDebugTraceOptions(questTrace, {
		{ "QuestAccepted", "QUEST_ACCEPTED" },
		{ "QuestStatusUpdate", "Quest status updates" },
		{ "QuestCurrencyLootReceived", "QUEST_CURRENCY_LOOT_RECEIVED" },
		{ "QuestLogCriteriaUpdate", "QUEST_LOG_CRITERIA_UPDATE" },
		{ "QuestLootReceived", "QUEST_LOOT_RECEIVED" },
		{ "QuestlineUpdate", "QUESTLINE_UPDATE" },
		{ "QuestComplete", "QUEST_COMPLETE" },
		{ "QuestAutocomplete", "QUEST_AUTOCOMPLETE" },
		{ "QuestRemoved", "QUEST_REMOVED" },
		{ "QuestWatchUpdate", "QUEST_WATCH_UPDATE" },
		{ "QuestListWatchListChanged", "QUEST_WATCH_LIST_CHANGED" },
		{ "QuestTurnedIn", "QUEST_TURNED_IN" },
		{ "QuestFinished", "QUEST_FINISHED" },
		{ "showEventAchievementEarned", "ACHIEVEMENT_EARNED" },
		{ "showEventCriteriaEarned", "CRITERIA_EARNED" },
		{ "showTrackedAchievementUpdate", "TRACKED_ACHIEVEMENT_UPDATE" },
	})

	local encounterTrace = createOptionGroup("QuestCampaign", "INFO+ encounters and tracking", 6)
	encounterTrace.hidden = infoPlusOnly
	addDebugTraceOptions(encounterTrace, {
		{ "BossKill", "BOSS_KILL" },
		{ "EncounterEnd", "ENCOUNTER_END" },
		{ "ScenarioCompleted", "SCENARIO_COMPLETED" },
		{ "ScenarioCriteriaUpdate", "SCENARIO_CRITERIA_UPDATE" },
		{ "ScenarioUpdate", "SCENARIO_UPDATE" },
		{ "StartTimer", "START_TIMER" },
		{ "showEventContentTrackingUpdate", "CONTENT_TRACKING_UPDATE" },
		{ "showEventSuperTrackingChanged", "SUPER_TRACKING_CHANGED" },
	})
	page.args = {
		diagnostics = diagnostics, tools = tools, infoTrace = infoTrace,
		worldTrace = worldTrace, questTrace = questTrace, encounterTrace = encounterTrace,
	}
end

function ConfigUI:ComposeOptions(options)
	if not options or COMPOSED_OPTIONS[options] then return end
	COMPOSED_OPTIONS[options] = true
	if options.args.general then composeGeneralPage(options.args.general) end
	if options.args.frame then composeFramePage(options.args.frame) end
	if options.args.font then composeFontPage(options.args.font) end
	if options.args.debug then composeDebugPage(options.args.debug) end
end

local function copyOption(option)
	local result = {}
	for key, value in pairs(option or {}) do result[key] = value end
	return result
end

function ConfigUI:ComposeProfiles(profiles)
	if not profiles then return profiles end
	local source = profiles.args or {}
	local overview = createOptionGroup("GroupBanner", "Current Profile", 1)
	overview.args.summary = {
		type = "description",
		name = "Profiles keep different RQE layouts and behavior sets for different characters or play styles.",
		order = 1,
		width = "full",
	}
	overview.args.current = copyOption(source.current)
	overview.args.current.order = 2
	overview.args.current.width = 2
	overview.args.reset = copyOption(source.reset)
	overview.args.reset.name = "Reset current profile"
	overview.args.reset.order = 3
	overview.args.reset.width = 1

	local selection = createOptionGroup("ShowAll", "Choose or Create", 2)
	selection.args.choose = copyOption(source.choose)
	selection.args.choose.name = "Active profile"
	selection.args.choose.order = 1
	selection.args.choose.width = 1.5
	selection.args.new = copyOption(source.new)
	selection.args.new.name = "New profile"
	selection.args.new.order = 2
	selection.args.new.width = 1.5

	local management = createOptionGroup("Settings", "Copy or Remove", 3)
	management.args.copyfrom = copyOption(source.copyfrom)
	management.args.copyfrom.name = "Copy into active profile"
	management.args.copyfrom.order = 1
	management.args.copyfrom.width = 1.5
	management.args.delete = copyOption(source.delete)
	management.args.delete.name = "Delete profile"
	management.args.delete.order = 2
	management.args.delete.width = 1.5

	return {
		name = profiles.name,
		type = "group",
		handler = profiles.handler,
		args = { overview = overview, selection = selection, management = management },
	}
end

function ConfigUI:OpenOptionsPage(container, appName)
	if not container or not appName then return end
	-- Custom AceGUI containers are not included in AceConfigDialog's automatic
	-- refresh list. Remember the current page, including while its window hides.
	self.optionsContainer, self.optionsAppName = container, appName
	container:ReleaseChildren()
	local page = LibStub("AceGUI-3.0"):Create("ScrollFrame")
	page:SetLayout("Flow")
	page:SetFullWidth(true)
	page:SetFullHeight(true)
	local content = LibStub("AceGUI-3.0"):Create("SimpleGroup")
	content:SetLayout("Flow")
	content:SetFullWidth(true)
	self:SkinWidget(page)
	container:AddChild(page)
	page:AddChild(content)
	LibStub("AceConfigDialog-3.0"):Open(appName, content)
	self:SkinWidget(page)
	local function RefreshPageScroll()
		if not page.frame or not page.frame:IsShown() then return end
		if content.DoLayout then content:DoLayout() end
		if page.DoLayout then page:DoLayout() end
		if page.FixScroll then page:FixScroll() end
		updateStyledScrollFrame(page)
	end
	-- AceConfig finishes sizing several nested groups after Open returns. Force
	-- the initial range once on the next frame and once after that settling pass,
	-- so a small settings window never needs a manual resize to reveal its thumb.
	C_Timer.After(0, RefreshPageScroll)
	C_Timer.After(0.05, RefreshPageScroll)
end

-- Coalesce notifications until the current widget callback has finished before
-- releasing its controls. Read the latest page so a tab change cannot revive it.
function ConfigUI:RefreshStandalonePage()
	if self.refreshQueued then return end
	self.refreshQueued = true
	C_Timer.After(0, function()
		self.refreshQueued = nil
		local container = self.optionsContainer
		if container and container.frame:IsShown() then
			self:OpenOptionsPage(container, self.optionsAppName)
		end
	end)
end

LibStub("AceConfigRegistry-3.0").RegisterCallback(ConfigUI, "ConfigTableChange", function(_, appName)
	if appName == ConfigUI.optionsAppName then ConfigUI:RefreshStandalonePage() end
end)

-- Blizzard's secure menu can open Settings in combat, but an addon shortcut
-- cannot call its protected opener. Queue only the latest requested category.
local settingsEvents = CreateFrame("Frame")
settingsEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
settingsEvents:SetScript("OnEvent", function()
	C_Timer.After(0, function()
		if InCombatLockdown() or not ConfigUI.pendingPanelKey then return end
		local panelKey = ConfigUI.pendingPanelKey
		ConfigUI.pendingPanelKey = nil
		ConfigUI:OpenRegisteredPanel(panelKey)
	end)
end)

function ConfigUI:OpenRegisteredPanel(panelKey)
	panelKey = panelKey or "general"
	if InCombatLockdown() then
		if not self.pendingPanelKey then
			print("RQE: AddOn Settings will open after combat. You can still open them manually through Blizzard's menu.")
		end
		self.pendingPanelKey = panelKey
		return false
	end
	self.pendingPanelKey = nil
	local frame = RQE.optionsFrame
	if panelKey ~= "general" and frame then frame = frame[panelKey] end
	local categoryID = RQE.optionsCategoryIDs and RQE.optionsCategoryIDs[panelKey]

	if categoryID and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(categoryID)
		return true
	elseif categoryID and C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel then
		C_SettingsUtil.OpenSettingsPanel(categoryID)
		return true
	elseif categoryID and SettingsPanel and SettingsPanel.OpenToCategory then
		SettingsPanel:OpenToCategory(categoryID)
		return true
	elseif frame and InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(frame)
		InterfaceOptionsFrame_OpenToCategory(frame)
		return true
	end
	return false
end

local function createPortrait(parent, size, x, y)
	if parent.RQEConfigPortraitFrame then return parent.RQEConfigPortraitFrame end
	local portraitFrame = CreateFrame("Frame", nil, parent)
	portraitFrame:SetSize(size, size)
	portraitFrame:SetPoint("TOPLEFT", x, y)
	local border = portraitFrame:CreateTexture(nil, "BORDER")
	border:SetAllPoints()
	border:SetTexture(WHITE)
	border:SetVertexColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 1)
	local azure = portraitFrame:CreateTexture(nil, "ARTWORK")
	azure:SetPoint("TOPLEFT", 2, -2)
	azure:SetPoint("BOTTOMRIGHT", -2, 2)
	azure:SetTexture(WHITE)
	azure:SetVertexColor(COLORS.azureBright[1], COLORS.azureBright[2], COLORS.azureBright[3], 1)
	local portrait = portraitFrame:CreateTexture(nil, "OVERLAY")
	portrait:SetPoint("TOPLEFT", 4, -4)
	portrait:SetPoint("BOTTOMRIGHT", -4, 4)
	portrait:SetTexture(PORTRAIT)
	portrait:SetTexCoord(0, 1, 0, 1)
	parent.RQEConfigPortraitFrame = portraitFrame
	return portraitFrame
end

function ConfigUI:RegisterOptionsPanel(panel, pageTitle)
	if not panel or panel.RQEConfigPanelStyled then return end
	panel.RQEConfigPanelStyled = true
	-- Blizzard's AddOns pages deliberately retain their native canvas and AceGUI
	-- borders.  Only the option composition is shared with the standalone frame;
	-- the ornate Azure & Gold shell belongs exclusively to RQE's own window.
	local widget = panel.obj
	if widget then
		self:UseNativeWidget(widget)
		if widget.label then widget.label:SetText(pageTitle or "RQE Settings") end
	end
	if panel.HookScript then
		panel:HookScript("OnShow", function(owner)
			if owner.obj then ConfigUI:UseNativeWidget(owner.obj) end
		end)
	end
end

function ConfigUI:SkinConfigFrame(widget)
	if not widget or widget.RQEConfigFrameStyled then return end
	widget.RQEConfigFrameStyled = true
	watchContainer(widget, "styled")
	local frame = widget.frame
	if not frame then return end
	-- A hidden window may have missed registry refreshes while another settings
	-- surface changed profiles. Rebuild its selected page when shown again.
	frame:HookScript("OnShow", function() ConfigUI:RefreshStandalonePage() end)
	skinSurface(frame, 0.96, 2)
	if RQE.UI and RQE.UI._ApplyAceFrame then RQE.UI:_ApplyAceFrame(widget) end

	if widget.titlebg then
		widget.titlebg:ClearAllPoints()
		widget.titlebg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
		widget.titlebg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
		widget.titlebg:SetHeight(52)
		widget.titlebg:SetTexture(ROOT .. "Panels\\Header.tga")
		widget.titlebg:SetTexCoord(0, 1, 0, 1)
	end
	createPortrait(frame, 46, 18, -9)
	if widget.titletext then
		widget.titletext:ClearAllPoints()
		widget.titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 76, -16)
		widget.titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -28, -16)
		widget.titletext:SetJustifyH("LEFT")
		colorFont(widget.titletext, COLORS.gold)
	end
	if widget.content then
		widget.content:ClearAllPoints()
		widget.content:SetPoint("TOPLEFT", 18, -68)
		widget.content:SetPoint("BOTTOMRIGHT", -18, 42)
	end
	if not frame.RQEConfigEscapeHooked and frame.EnableKeyboard and frame.SetPropagateKeyboardInput then
		frame.RQEConfigEscapeHooked = true
		frame:EnableKeyboard(true)
		frame:SetPropagateKeyboardInput(true)
		frame:HookScript("OnKeyDown", function(owner, key)
			if key == "ESCAPE" and owner:IsShown() then
				local canSuppress = not InCombatLockdown()
				if canSuppress then owner:SetPropagateKeyboardInput(false) end
				widget:Hide()
				if canSuppress then
					C_Timer.After(0, function()
						if owner and owner.SetPropagateKeyboardInput then
							owner:SetPropagateKeyboardInput(true)
						end
					end)
				end
			elseif not InCombatLockdown() then
				owner:SetPropagateKeyboardInput(true)
			end
		end)
	end
	colorFont(widget.statustext, COLORS.gold)

	for _, child in ipairs({ frame:GetChildren() }) do
		if child.GetObjectType and child:GetObjectType() == "Button" and child.GetText and child:GetText() and child:GetText() ~= "" then
			skinButton(child)
		end
	end
	self:SkinWidget(widget)
end
