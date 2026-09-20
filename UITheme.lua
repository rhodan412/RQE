--[[
RQE presentation-only theme support.

Every public Style* function records its target before it attempts to skin it.
Most RQE frames are constructed before AceDB restores the selected profile, so
the deferred registry is what makes "theme off + reload" preserve the original
Blizzard/RQE appearance exactly. No click handlers, secure attributes, quest
state, waypoint state, or visibility rules are owned here.
]]

RQE = RQE or {}
RQE.UI = RQE.UI or {}

local UI = RQE.UI
local ROOT = "Interface\\AddOns\\RQE\\Media\\UI\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- A future theme only needs these semantic asset keys and its own palette.
UI.Themes = UI.Themes or {
	AzureGold = {
		colors = {
			azure = { 0 / 255, 87 / 255, 184 / 255 }, -- #0057B8
			azureBright = { 35 / 255, 145 / 255, 1 },
			gold = { 255 / 255, 215 / 255, 0 },       -- #FFD700
			charcoal = { 9 / 255, 14 / 255, 23 / 255 },
			charcoalRaised = { 18 / 255, 24 / 255, 34 / 255 },
			muted = { 135 / 255, 145 / 255, 160 / 255 },
		},
		textures = {
			header = ROOT .. "Panels\\Header.tga",
			sectionHeader = ROOT .. "Panels\\SectionHeader.tga",
			buttonNormal = ROOT .. "Buttons\\Normal.tga",
			buttonHover = ROOT .. "Buttons\\Hover.tga",
			buttonPressed = ROOT .. "Buttons\\Pressed.tga",
			buttonDisabled = ROOT .. "Buttons\\Disabled.tga",
			buttonWide = ROOT .. "Buttons\\Wide.tga",
			icons = ROOT .. "Icons\\",
		},
	},
}

UI.ActiveTheme = UI.ActiveTheme or "AzureGold"
UI.Colors = UI.Themes[UI.ActiveTheme].colors
UI.Textures = UI.Themes[UI.ActiveTheme].textures
UI.Registry = UI.Registry or {
	panels = {}, headers = {}, iconButtons = {}, textButtons = {}, searchBoxes = {},
	legacyButtons = {}, aceFrames = {}, locationBars = {},
}
UI.Registry.locationBars = UI.Registry.locationBars or {}

local function profileReady()
	return RQE.db and type(RQE.db.GetCurrentProfile) == "function" and RQE.db.profile
end

function UI:IsEnabled()
	return self._sessionThemeEnabled == true
end

local function remember(list, target, data)
	if not target then return end
	for _, entry in ipairs(list) do
		if entry.target == target then
			entry.data = data or entry.data
			return
		end
	end
	table.insert(list, { target = target, data = data or {} })
end

local function hideRegion(region)
	if region and region.Hide then region:Hide() end
end

local function stripNineSlice(owner)
	if not owner then return end
	local nine = owner.NineSlice
	if nine then
		if nine.Hide then nine:Hide() end
		for _, key in ipairs({
			"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
			"TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center",
		}) do
			hideRegion(nine[key])
		end
	end
	for _, key in ipairs({ "Left", "Middle", "Right", "Top", "Bottom" }) do
		hideRegion(owner[key])
	end
end

function UI:StripBlizzardButton(button)
	if not button or button.RQEThemeBlizzardStripped then return end
	stripNineSlice(button)
	for _, region in ipairs({ button:GetRegions() }) do
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:Hide() end
	end
	button.RQEThemeBlizzardStripped = true
end

local function setButtonTexture(button, method, path)
	if not button or not button[method] then return end
	button[method](button, path)
	local texture
	if method == "SetNormalTexture" then texture = button:GetNormalTexture()
	elseif method == "SetHighlightTexture" then texture = button:GetHighlightTexture()
	elseif method == "SetPushedTexture" then texture = button:GetPushedTexture()
	elseif method == "SetDisabledTexture" and button.GetDisabledTexture then texture = button:GetDisabledTexture() end
	if texture then
		texture:Show()
		texture:ClearAllPoints()
		texture:SetAllPoints(button)
		if texture.SetTexCoord then texture:SetTexCoord(0, 1, 0, 1) end
	end
	return texture
end

local function ensurePanelPiece(frame, key)
	if not frame[key] then
		frame[key] = frame:CreateTexture(nil, "ARTWORK", nil, 1)
		frame[key]:SetTexture(UI.Textures.buttonNormal)
	end
	frame[key]:Show()
	return frame[key]
end

local function ensureColorLine(frame, key, color)
	if not frame[key] then frame[key] = frame:CreateTexture(nil, "ARTWORK", nil, 3) end
	frame[key]:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
	frame[key]:Show()
	return frame[key]
end

-- Eight independent slices keep every edge visible on resized/scrolling frames.
function UI:_ApplyPanel(frame, opacity, role)
	if not frame or not frame.SetBackdrop then return end
	stripNineSlice(frame)
	local c = self.Colors
	frame:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
	frame:SetBackdropColor(c.charcoal[1], c.charcoal[2], c.charcoal[3], tonumber(opacity) or 0.76)

	local corner = role == "section" and 9 or 13
	local uv1, uv2 = 0.27, 0.73
	local tl = ensurePanelPiece(frame, "RQEThemeBorderTL")
	local tr = ensurePanelPiece(frame, "RQEThemeBorderTR")
	local bl = ensurePanelPiece(frame, "RQEThemeBorderBL")
	local br = ensurePanelPiece(frame, "RQEThemeBorderBR")
	local top = ensurePanelPiece(frame, "RQEThemeBorderTop")
	local bottom = ensurePanelPiece(frame, "RQEThemeBorderBottom")
	local left = ensurePanelPiece(frame, "RQEThemeBorderLeft")
	local right = ensurePanelPiece(frame, "RQEThemeBorderRight")

	tl:SetTexCoord(0, uv1, 0, uv1); tr:SetTexCoord(uv2, 1, 0, uv1)
	bl:SetTexCoord(0, uv1, uv2, 1); br:SetTexCoord(uv2, 1, uv2, 1)
	top:SetTexCoord(uv1, uv2, 0, uv1); bottom:SetTexCoord(uv1, uv2, uv2, 1)
	left:SetTexCoord(0, uv1, uv1, uv2); right:SetTexCoord(uv2, 1, uv1, uv2)

	for _, piece in ipairs({ tl, tr, bl, br }) do piece:SetSize(corner, corner) end
	tl:ClearAllPoints(); tl:SetPoint("TOPLEFT")
	tr:ClearAllPoints(); tr:SetPoint("TOPRIGHT")
	bl:ClearAllPoints(); bl:SetPoint("BOTTOMLEFT")
	br:ClearAllPoints(); br:SetPoint("BOTTOMRIGHT")
	top:ClearAllPoints(); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT"); top:SetHeight(corner)
	bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT"); bottom:SetHeight(corner)
	left:ClearAllPoints(); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); left:SetWidth(corner)
	right:ClearAllPoints(); right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); right:SetWidth(corner)

	-- Exact palette keylines remain crisp even when the ornate bitmap border is
	-- scaled to a user-resized frame.
	local azTop = ensureColorLine(frame, "RQEThemeAzureTop", { c.azure[1], c.azure[2], c.azure[3], 1 })
	local azBottom = ensureColorLine(frame, "RQEThemeAzureBottom", { c.azure[1], c.azure[2], c.azure[3], 1 })
	local azLeft = ensureColorLine(frame, "RQEThemeAzureLeft", { c.azure[1], c.azure[2], c.azure[3], 1 })
	local azRight = ensureColorLine(frame, "RQEThemeAzureRight", { c.azure[1], c.azure[2], c.azure[3], 1 })
	azTop:ClearAllPoints(); azTop:SetPoint("TOPLEFT", 4, -1); azTop:SetPoint("TOPRIGHT", -4, -1); azTop:SetHeight(1)
	azBottom:ClearAllPoints(); azBottom:SetPoint("BOTTOMLEFT", 4, 1); azBottom:SetPoint("BOTTOMRIGHT", -4, 1); azBottom:SetHeight(1)
	azLeft:ClearAllPoints(); azLeft:SetPoint("TOPLEFT", 1, -4); azLeft:SetPoint("BOTTOMLEFT", 1, 4); azLeft:SetWidth(1)
	azRight:ClearAllPoints(); azRight:SetPoint("TOPRIGHT", -1, -4); azRight:SetPoint("BOTTOMRIGHT", -1, 4); azRight:SetWidth(1)
	local gold = ensureColorLine(frame, "RQEThemeGoldTop", { c.gold[1], c.gold[2], c.gold[3], 0.88 })
	gold:ClearAllPoints(); gold:SetPoint("TOPLEFT", corner, -3); gold:SetPoint("TOPRIGHT", -corner, -3); gold:SetHeight(1)
	frame.RQEThemeRole = role or "panel"
end

function UI:StylePanel(frame, opacity, role)
	remember(self.Registry.panels, frame, { opacity = opacity, role = role })
	if self:IsEnabled() then self:_ApplyPanel(frame, opacity, role) end
end

local function ensureHeaderSlice(header, key, path, leftUV, rightUV)
	if not header[key] then header[key] = header:CreateTexture(nil, "ARTWORK", nil, 2) end
	header[key]:SetTexture(path)
	header[key]:SetTexCoord(leftUV, rightUV, 0, 1)
	header[key]:Show()
	return header[key]
end

function UI:_ApplyHeader(header, child)
	if not header then return end
	stripNineSlice(header)
	if header.SetBackdrop then header:SetBackdrop(nil) end
	if not child and header.SetHeight and header:GetHeight() < 48 then header:SetHeight(48) end
	-- Rounded main-frame headers; point-ended child/section headers.
	local path = child and self.Textures.header or self.Textures.sectionHeader
	local left = ensureHeaderSlice(header, "RQEThemeHeaderLeft", path, 0, 0.14)
	local middle = ensureHeaderSlice(header, "RQEThemeHeaderMiddle", path, 0.14, 0.86)
	local right = ensureHeaderSlice(header, "RQEThemeHeaderRight", path, 0.86, 1)
	-- Header.tga's left point is deliberately mirrored for the far end.  This
	-- keeps the cap visible at every width instead of stretching/cropping the
	-- narrow right-most pixels of the source artwork.
	if child then right:SetTexCoord(0.14, 0, 0, 1) end
	local sideWidth = child and 28 or 20
	left:ClearAllPoints(); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(sideWidth)
	right:ClearAllPoints(); right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(sideWidth)
	middle:ClearAllPoints(); middle:SetPoint("TOPLEFT", left, "TOPRIGHT"); middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
	local accent = ensureColorLine(header, "RQEThemeHeaderAccent", {
		self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.92,
	})
	accent:ClearAllPoints(); accent:SetPoint("BOTTOMLEFT", sideWidth, 1); accent:SetPoint("BOTTOMRIGHT", -sideWidth, 1); accent:SetHeight(1)
end

function UI:StyleHeader(header, child)
	remember(self.Registry.headers, header, { child = child })
	if self:IsEnabled() then self:_ApplyHeader(header, child) end
end

function UI:_ApplyLegacyLocationInfoBar(bar)
	if not bar then return end
	bar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	bar:SetBackdropColor(0.04, 0.04, 0.04, 0.86)
	bar:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
	bar:SetHeight(24)
	if bar.MapIDText then
		bar.MapIDText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.MapIDText:SetTextColor(1, 0.82, 0)
	end
	if bar.CoordinatesText then
		bar.CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.CoordinatesText:SetTextColor(1, 1, 1)
	end
	if bar.StepDistanceText then
		bar.StepDistanceText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.StepDistanceText:SetTextColor(1, 0.82, 0)
	end
end

function UI:_ApplyLocationInfoBar(bar)
	if not bar then return end
	stripNineSlice(bar)
	bar:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
	bar:SetBackdropColor(self.Colors.charcoalRaised[1], self.Colors.charcoalRaised[2], self.Colors.charcoalRaised[3], 0.9)
	bar:SetHeight(28)
	local azure = ensureColorLine(bar, "RQEThemeLocationAzure", {
		self.Colors.azureBright[1], self.Colors.azureBright[2], self.Colors.azureBright[3], 0.9,
	})
	azure:ClearAllPoints(); azure:SetPoint("TOPLEFT", 1, -1); azure:SetPoint("TOPRIGHT", -1, -1); azure:SetHeight(1)
	local gold = ensureColorLine(bar, "RQEThemeLocationGold", {
		self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.78,
	})
	gold:ClearAllPoints(); gold:SetPoint("BOTTOMLEFT", 1, 1); gold:SetPoint("BOTTOMRIGHT", -1, 1); gold:SetHeight(1)
	if bar.MapIDText then
		bar.MapIDText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.MapIDText:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
	end
	if bar.CoordinatesText then
		bar.CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.CoordinatesText:SetTextColor(0.72, 0.9, 1)
	end
	if bar.StepDistanceText then
		bar.StepDistanceText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		bar.StepDistanceText:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
	end
end

function UI:StyleLocationInfoBar(bar)
	remember(self.Registry.locationBars, bar)
	self:_ApplyLegacyLocationInfoBar(bar)
	if self:IsEnabled() then self:_ApplyLocationInfoBar(bar) end
end

function UI:RefreshLocationInfoBar()
	local mainFrame = RQE.RQEFrame or RQEFrame or _G["RQE.RQEFrame"]
	local bar = RQE.LocationInfoBar
	if not (mainFrame and RQE.ScrollFrame) then return end
	local profile = RQE.db and RQE.db.profile
	local showMap = profile and profile.showMapID == true
	local showCoordinates = profile and profile.showCoordinates == true
	local showBar = bar and (showMap or showCoordinates)
	local themed = self:IsEnabled()
	local layoutKey = table.concat({ themed and "theme" or "legacy", showMap and "map" or "", showCoordinates and "coords" or "" }, ":")
	if bar and bar.RQELocationLayoutKey == layoutKey then return end
	if bar then bar.RQELocationLayoutKey = layoutKey end

	if bar then
		bar:ClearAllPoints()
		if themed then
			bar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -50)
			bar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -50)
			bar:SetHeight(28)
		else
			bar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -32)
			bar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -30, -32)
			bar:SetHeight(24)
		end
		if bar.MapIDText then bar.MapIDText:SetShown(showMap) end
		if bar.CoordinatesText then bar.CoordinatesText:SetShown(showCoordinates) end
		if bar.StepDistanceText then bar.StepDistanceText:SetShown(showCoordinates) end
		bar:SetShown(showBar)
	end

	RQE.ScrollFrame:ClearAllPoints()
	local topOffset
	if themed then topOffset = showBar and -84 or -52
	else topOffset = showBar and -62 or -40 end
	RQE.ScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, topOffset)
	RQE.ScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", themed and -20 or -30, 10)
end

-- The generated icon canvases do not all have balanced transparent margins.
-- These small optical corrections center the visible symbols, rather than
-- merely centering each full 64x64 source canvas inside its button.
local ICON_OPTICAL_OFFSETS = {
	Clear = { 0, 3 },
	RemoveWaypoint = { -1, 3 },
	Search = { 0, 3 },
	Contribution = { 1, 4 },
	Completed = { -1, 1 },
	HideCompleted = { -1, 1 },
	Zone = { 0, -1 },
	Filter = { 1, 1 },
	Collapse = { -1, 1 },
	Expand = { 0, 0 },
	Close = { -1, 1 },
	WaypointTarget = { -2, 3 },
	SearchGroup = { 0, 2 },
}

function UI:_ApplyIconButton(button, iconName, options)
	if not button then return end
	options = options or {}
	self:StripBlizzardButton(button)
	local size = tonumber(options.size) or 25
	local inset = tonumber(options.iconInset) or 2
	local iconSize = math.max(1, size - (inset * 2))
	local opticalOffset = ICON_OPTICAL_OFFSETS[iconName]
	local offsetX = opticalOffset and opticalOffset[1] or 0
	local offsetY = opticalOffset and opticalOffset[2] or 0
	button:SetSize(size, size)
	if options.focusInset and button.GetParent then
		button:ClearAllPoints()
		-- Keep the complete control inside the focus panel and clear of both its
		-- left and top borders; the focus text uses the matching inner gutter.
		button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", 10, -6)
	end
	button:SetText("")
	setButtonTexture(button, "SetNormalTexture", self.Textures.buttonNormal)
	setButtonTexture(button, "SetHighlightTexture", self.Textures.buttonHover)
	setButtonTexture(button, "SetPushedTexture", self.Textures.buttonPressed)
	setButtonTexture(button, "SetDisabledTexture", self.Textures.buttonDisabled)
	if not button.RQEThemeIcon then button.RQEThemeIcon = button:CreateTexture(nil, "ARTWORK", nil, 6) end
	button.RQEThemeIcon:ClearAllPoints()
	button.RQEThemeIcon:SetSize(iconSize, iconSize)
	button.RQEThemeIcon:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
	button.RQEThemeIcon:SetTexture(self.Textures.icons .. iconName .. ".tga")
	button.RQEThemeIcon:Show()
	if not button.RQEThemeStateHooks then
		button:HookScript("OnDisable", function(owner)
			if owner.RQEThemeIcon and owner.RQEThemeIcon.SetDesaturated then owner.RQEThemeIcon:SetDesaturated(true) end
			if owner.RQEThemeIcon then owner.RQEThemeIcon:SetAlpha(0.45) end
		end)
		button:HookScript("OnEnable", function(owner)
			if owner.RQEThemeIcon and owner.RQEThemeIcon.SetDesaturated then owner.RQEThemeIcon:SetDesaturated(false) end
			if owner.RQEThemeIcon then owner.RQEThemeIcon:SetAlpha(1) end
		end)
		button.RQEThemeStateHooks = true
	end
	button.RQEThemeIcon:SetAlpha(button.IsEnabled and button:IsEnabled() and 1 or 0.45)
	button.RQEThemeIconName = iconName
end

function UI:StyleIconButton(button, iconName, options)
	remember(self.Registry.iconButtons, button, { iconName = iconName, options = options or {} })
	if self:IsEnabled() then self:_ApplyIconButton(button, iconName, options) end
end

function UI:_ApplyTextButton(button)
	if not button then return end
	self:StripBlizzardButton(button)
	local normal = setButtonTexture(button, "SetNormalTexture", self.Textures.buttonWide)
	local highlight = setButtonTexture(button, "SetHighlightTexture", self.Textures.buttonWide)
	local pushed = setButtonTexture(button, "SetPushedTexture", self.Textures.buttonWide)
	local disabled = setButtonTexture(button, "SetDisabledTexture", self.Textures.buttonWide)
	if normal then normal:SetVertexColor(1, 1, 1, 1) end
	if highlight then highlight:SetVertexColor(0.45, 0.82, 1, 1) end
	if pushed then pushed:SetVertexColor(0.68, 0.78, 0.92, 1) end
	if disabled then disabled:SetVertexColor(0.34, 0.37, 0.43, 0.72) end
	if button.SetNormalFontObject then button:SetNormalFontObject("GameFontNormal") end
	if button.SetHighlightFontObject then button:SetHighlightFontObject("GameFontHighlight") end
	local font = button.GetFontString and button:GetFontString()
	if font then font:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3]) end
end

function UI:StyleTextButton(button)
	remember(self.Registry.textButtons, button)
	if self:IsEnabled() then self:_ApplyTextButton(button) end
end

function UI:_ApplySearchBox(editBox)
	if not editBox then return end
	stripNineSlice(editBox)
	if editBox.CreateTexture then
		if not editBox.RQEThemeSearchBackground then
			editBox.RQEThemeSearchBackground = editBox:CreateTexture(nil, "BACKGROUND", nil, -2)
		end
		editBox.RQEThemeSearchBackground:SetColorTexture(4 / 255, 8 / 255, 15 / 255, 0.94)
		editBox.RQEThemeSearchBackground:SetAllPoints(editBox)
		editBox.RQEThemeSearchBackground:Show()

		local function searchPiece(key)
			if not editBox[key] then editBox[key] = editBox:CreateTexture(nil, "ARTWORK", nil, 2) end
			editBox[key]:SetTexture(self.Textures.buttonNormal)
			editBox[key]:Show()
			return editBox[key]
		end
		local corner, uv1, uv2 = 7, 0.27, 0.73
		local tl = searchPiece("RQEThemeSearchTL")
		local tr = searchPiece("RQEThemeSearchTR")
		local bl = searchPiece("RQEThemeSearchBL")
		local br = searchPiece("RQEThemeSearchBR")
		local top = searchPiece("RQEThemeSearchEdgeTop")
		local bottom = searchPiece("RQEThemeSearchEdgeBottom")
		local left = searchPiece("RQEThemeSearchEdgeLeft")
		local right = searchPiece("RQEThemeSearchEdgeRight")
		tl:SetTexCoord(0, uv1, 0, uv1); tr:SetTexCoord(uv2, 1, 0, uv1)
		bl:SetTexCoord(0, uv1, uv2, 1); br:SetTexCoord(uv2, 1, uv2, 1)
		top:SetTexCoord(uv1, uv2, 0, uv1); bottom:SetTexCoord(uv1, uv2, uv2, 1)
		left:SetTexCoord(0, uv1, uv1, uv2); right:SetTexCoord(uv2, 1, uv1, uv2)
		for _, piece in ipairs({ tl, tr, bl, br }) do piece:SetSize(corner, corner) end
		tl:ClearAllPoints(); tl:SetPoint("TOPLEFT")
		tr:ClearAllPoints(); tr:SetPoint("TOPRIGHT")
		bl:ClearAllPoints(); bl:SetPoint("BOTTOMLEFT")
		br:ClearAllPoints(); br:SetPoint("BOTTOMRIGHT")
		top:ClearAllPoints(); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT"); top:SetHeight(corner)
		bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT"); bottom:SetHeight(corner)
		left:ClearAllPoints(); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); left:SetWidth(corner)
		right:ClearAllPoints(); right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); right:SetWidth(corner)

		-- A restrained inner gold line ties fields to the other controls without
		-- returning to the plain blue rectangle this replaces.
		local gold = ensureColorLine(editBox, "RQEThemeSearchGold", {
			self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.72,
		})
		gold:ClearAllPoints(); gold:SetPoint("BOTTOMLEFT", corner, 2); gold:SetPoint("BOTTOMRIGHT", -corner, 2); gold:SetHeight(1)
		for _, key in ipairs({ "RQEThemeSearchTop", "RQEThemeSearchBottom", "RQEThemeSearchLeft", "RQEThemeSearchRight" }) do
			hideRegion(editBox[key])
		end
	end
	if editBox.SetBackdrop then
		editBox:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
		editBox:SetBackdropColor(4 / 255, 8 / 255, 15 / 255, 0.94)
	end
end

function UI:StyleSearchBox(editBox)
	remember(self.Registry.searchBoxes, editBox)
	if self:IsEnabled() then self:_ApplySearchBox(editBox) end
end

function UI:StyleLegacyActionButton(button, background, label, iconName, options)
	options = options or { size = 30, iconInset = 2 }
	remember(self.Registry.legacyButtons, button, {
		background = background, label = label, iconName = iconName, options = options,
	})
	if not self:IsEnabled() then return end
	hideRegion(background); hideRegion(label)
	self:_ApplyIconButton(button, iconName, options)
end

local QUEST_BADGE_ICON = {
	Campaign = "QuestCampaign",
	World = "QuestWorld",
	Daily = "QuestDaily",
	Bonus = "QuestBonus",
	Normal = "QuestNormal",
}

-- QuestWorld already has the approved visual footprint. The other source
-- images contain progressively larger transparent margins, so their texture
-- boxes are enlarged independently while all row button frames remain 35x35.
-- Positioning stays centered for now; artwork-specific optical offsets are a
-- separate concern.
local QUEST_BADGE_SIZE = {
	Campaign = { 35, 31 },
	World = { 27, 27 },
	Daily = { 31, 31 },
	Bonus = { 31, 31 },
	Normal = { 33, 31 },
}

function UI:StyleQuestIndexButton(button, active, questKind)
	if not self:IsEnabled() or not button then return end
	local iconName = questKind and QUEST_BADGE_ICON[questKind]
	local bg = button.bg
	if bg then
		-- Quest rows reproduce the normal-plus-additive-highlight composition used
		-- by an actually hovered themed button. Generic numbered waypoint buttons
		-- retain their existing background swap behavior.
		bg:SetTexture(iconName and self.Textures.buttonNormal
			or (active and self.Textures.buttonHover or self.Textures.buttonNormal))
		bg:SetTexCoord(0, 1, 0, 1)
		bg:SetAllPoints(button)
		bg:Show()
	end
	if iconName then
		if not button.RQEThemeQuestActiveGlow then
			button.RQEThemeQuestActiveGlow = button:CreateTexture(nil, "OVERLAY", nil, 7)
			button.RQEThemeQuestActiveGlow:SetBlendMode("ADD")
		end
		button.RQEThemeQuestActiveGlow:ClearAllPoints()
		button.RQEThemeQuestActiveGlow:SetAllPoints(button)
		button.RQEThemeQuestActiveGlow:SetTexture(self.Textures.buttonHover)
		button.RQEThemeQuestActiveGlow:SetTexCoord(0, 1, 0, 1)
		button.RQEThemeQuestActiveGlow:SetAlpha(1)
		button.RQEThemeQuestActiveGlow:SetShown(active == true)
		if not button.RQEThemeQuestBadge then
			button.RQEThemeQuestBadge = button:CreateTexture(nil, "ARTWORK", nil, 6)
		end
		local badgeSize = QUEST_BADGE_SIZE[questKind] or QUEST_BADGE_SIZE.World
		button.RQEThemeQuestBadge:ClearAllPoints()
		button.RQEThemeQuestBadge:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.RQEThemeQuestBadge:SetSize(badgeSize[1], badgeSize[2])
		button.RQEThemeQuestBadge:SetTexture(self.Textures.icons .. iconName .. ".tga")
		button.RQEThemeQuestBadge:Show()
		if button.number then button.number:Hide() end
	else
		if button.RQEThemeQuestActiveGlow then button.RQEThemeQuestActiveGlow:Hide() end
		if button.RQEThemeQuestBadge then button.RQEThemeQuestBadge:Hide() end
		if button.number then
			button.number:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
			button.number:Show()
		end
	end
end

local ACTION_ICON_BY_ITEM = {
	[841] = "PullTimer", [2554] = "TurnIn", [4588] = "Kill", [4787] = "Loot",
	[5061] = "Purchase", [5830] = "Interact", [23784] = "TrackerTurnIn", [2058] = "TrackerTurnIn",
	[28372] = "Look", [11753] = "Look", [28885] = "Emote", [206995] = "Emote",
	[28912] = "Learn", [21561] = "Learn", [45786] = "Settings", [20337] = "Settings",
	[67097] = "CancelAura", [54068] = "CancelAura", [118474] = "Follow", [7270] = "Follow",
	[143680] = "Weaken", [3081] = "Weaken", [153541] = "PickupQuest", [1165] = "PickupQuest",
	[30817] = "Purchase", [4382] = "Purchase",
}

function UI:UpdateMagicButtonActionIcon(button, macroBody)
	if not button then return end
	if not button.RQEThemeActionIcon then
		button.RQEThemeActionIcon = button:CreateTexture(nil, "ARTWORK", nil, 7)
		button.RQEThemeActionIcon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
		button.RQEThemeActionIcon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	end
	if not self:IsEnabled() then
		button.RQEThemeActionIcon:Hide()
		if button.RQEThemeMagicBackdrop then button.RQEThemeMagicBackdrop:Hide() end
		return
	end
	-- Theme sizing and the surround are installed once during profile startup,
	-- avoiding protected geometry changes when a macro updates in combat later.
	if not button.RQEThemeMagicSized then
		button:SetSize(38, 38)
		button:SetFrameLevel(math.max(1, button:GetFrameLevel()))
		button.RQEThemeMagicSized = true
	end
	if not button.RQEThemeMagicBackdrop then
		button.RQEThemeMagicBackdrop = CreateFrame("Frame", nil, button:GetParent(), "BackdropTemplate")
		button.RQEThemeMagicBackdrop:SetFrameStrata(button:GetFrameStrata())
		button.RQEThemeMagicBackdrop:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
		button.RQEThemeMagicBackdrop:EnableMouse(false)
		button.RQEThemeMagicBackdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
		button.RQEThemeMagicBackdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
		-- Keep transparent action artwork readable against bright world scenes
		-- without making the detached Magic Button surround fully opaque.
		self:_ApplyPanel(button.RQEThemeMagicBackdrop, 0.68, "section")
		button:HookScript("OnShow", function(owner)
			if UI:IsEnabled() and owner.RQEThemeMagicBackdrop then owner.RQEThemeMagicBackdrop:Show() end
		end)
		button:HookScript("OnHide", function(owner)
			if owner.RQEThemeMagicBackdrop then owner.RQEThemeMagicBackdrop:Hide() end
		end)
	end
	button.RQEThemeMagicBackdrop:SetShown(button:IsShown())
	local itemID = tonumber(tostring(macroBody or ""):match("#showtooltip%s+item:(%d+)"))
	local iconName = itemID and ACTION_ICON_BY_ITEM[itemID]
	if iconName then
		-- Replace the macro's Blizzard icon for mapped exception actions.  Using
		-- the button's own normal/highlight textures prevents the stock icon (and
		-- its highlight copy) from covering a small overlay while preserving the
		-- secure button, macro attributes, clicks, and tooltip scripts unchanged.
		local path = self.Textures.icons .. iconName .. ".tga"
		local normal = setButtonTexture(button, "SetNormalTexture", path)
		local highlight = setButtonTexture(button, "SetHighlightTexture", path)
		-- Generated action art is optically weighted toward its lower handles and
		-- accents. Shift both states upward three pixels so the visible symbol,
		-- rather than only its transparent canvas, is centered in the mount.
		local function centerActionTexture(texture)
			if not texture then return end
			texture:ClearAllPoints()
			texture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 3)
			texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 3)
		end
		centerActionTexture(normal)
		centerActionTexture(highlight)
		if highlight then highlight:SetBlendMode("ADD"); highlight:SetAlpha(0.35) end
		button.RQEThemeActionIcon:Hide()
		button.RQEThemeUsesActionTexture = true
	else
		-- Blizzard item art fills its square more aggressively than the custom
		-- transparent action symbols. Keep the secure/native icon, but give it a
		-- small visual inset so use-item macros match the themed action scale.
		for _, texture in ipairs({ button:GetNormalTexture(), button:GetHighlightTexture() }) do
			if texture then
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
				texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			end
		end
		button.RQEThemeActionIcon:Hide()
		button.RQEThemeUsesActionTexture = nil
	end
end

function UI:_ApplyFrameLayout()
	-- The themed buttons keep their established size; the header grows around
	-- them and the end groups move inside the ornate border/keylines.
	local mainFrame = RQE.RQEFrame or RQEFrame or _G["RQE.RQEFrame"]
	if RQE.RQEFrameHeader then RQE.RQEFrameHeader:SetHeight(48) end
	if RQE.ClearButton and mainFrame then
		RQE.ClearButton:ClearAllPoints()
		RQE.ClearButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -9)
	end
	if RQE.CloseButton and mainFrame then
		RQE.CloseButton:ClearAllPoints()
		RQE.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -14, -9)
	end
	if RQE.QuestNameText and RQE.QuestIDText then
		-- Lower every themed quest-name row equally so quests with and without the
		-- SG control retain one baseline. Legacy construction keeps its original
		-- -8 offset because this layout pass runs only for Azure & Gold.
		RQE.QuestNameText:ClearAllPoints()
		RQE.QuestNameText:SetPoint("TOPLEFT", RQE.QuestIDText, "BOTTOMLEFT", 0, -12)
	end
	self:RefreshLocationInfoBar()
	if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end
	if RQE.UpdateContentSize then RQE:UpdateContentSize() end

	if RQE.RQEQuestFrameHeader then RQE.RQEQuestFrameHeader:SetHeight(48) end
	if RQE.CQButton and RQE.RQEQuestFrame then
		RQE.CQButton:ClearAllPoints()
		RQE.CQButton:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 14, -9)
	end
	if RQE.QTQuestCloseButton and RQE.RQEQuestFrame then
		RQE.QTQuestCloseButton:ClearAllPoints()
		RQE.QTQuestCloseButton:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -14, -9)
	end
	if RQE.QuestTrackerSearchRow and RQE.RQEQuestFrame then
		RQE.QuestTrackerSearchRow:ClearAllPoints()
		RQE.QuestTrackerSearchRow:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 12, -54)
		RQE.QuestTrackerSearchRow:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -30, -54)
		RQE.QuestTrackerSearchRow:SetHeight(28)
	end
	if RQE.QuestTrackerSearchInput then RQE.QuestTrackerSearchInput:SetHeight(28) end
	if RQE.QuestTrackerSearchButton then RQE.QuestTrackerSearchButton:SetHeight(26) end
	if RQE.QuestTrackerRestoreButton then RQE.QuestTrackerRestoreButton:SetHeight(26) end
	if RQE.QTScrollFrame and RQE.RQEQuestFrame then
		RQE.QTScrollFrame:ClearAllPoints()
		-- The viewport remains frameWidth - 40, matching AdjustQuestItemWidths,
		-- but equal outer gutters keep every resizable child section centered.
		RQE.QTScrollFrame:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 20, -90)
		RQE.QTScrollFrame:SetPoint("BOTTOMRIGHT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -20, 10)
	end
	if RQE.QMQTslider and RQE.RQEQuestFrame then
		RQE.QMQTslider:ClearAllPoints()
		RQE.QMQTslider:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPRIGHT", -20, -90)
		RQE.QMQTslider:SetPoint("BOTTOMLEFT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -20, 20)
	end
	if AdjustQuestItemWidths and RQE.RQEQuestFrame then
		AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())
	end
end

function UI:_ApplyAceFrame(widget)
	if not widget or not widget.frame then return end
	self:_ApplyPanel(widget.frame, 0.94, "search")
	-- AceGUI exposes the center title texture but not its stock side caps or
	-- Close/status buttons. Replace the center art and discover those controls
	-- by type instead of relying on private field names.
	for _, region in ipairs({ widget.frame:GetRegions() }) do
		if region ~= widget.titlebg and region.GetObjectType
			and region:GetObjectType() == "Texture" and region.GetTexture
			and region:GetTexture() == 131080 then region:Hide() end
	end
	if widget.titlebg then
		widget.titlebg:SetTexture(self.Textures.sectionHeader)
		widget.titlebg:SetTexCoord(0, 1, 0, 1)
		widget.titlebg:SetWidth(math.max(widget.titlebg:GetWidth() or 0, 180))
		widget.titlebg:SetHeight(38)
	end
	for _, child in ipairs({ widget.frame:GetChildren() }) do
		if child.GetObjectType and child:GetObjectType() == "Button" and child.obj == widget then
			if child.GetText and child:GetText() and child:GetText() ~= "" then self:_ApplyTextButton(child)
			else self:_ApplySearchBox(child) end
		end
	end
	if widget.titletext then widget.titletext:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3]) end
end

function UI:StyleAceFrame(widget)
	remember(self.Registry.aceFrames, widget)
	if self:IsEnabled() then self:_ApplyAceFrame(widget) end
end

function UI:StyleContributionButton(button)
	self:StyleIconButton(button, "Contribution")
end

function UI:RefreshExternalButtons()
	if RQE.ContributeButton then self:StyleContributionButton(RQE.ContributeButton) end
	if RQE.Buttons and RQE.Buttons.RefreshContributionButton then RQE.Buttons.RefreshContributionButton() end
end

-- Called after AceDB restores the profile. Application is one-way for this
-- session; the option's reload guarantees a pristine legacy-mode construction.
function UI:ApplySavedTheme()
	self._sessionThemeEnabled = profileReady() and RQE.db.profile.useModernTheme ~= false
	if not self:IsEnabled() then return end
	for _, e in ipairs(self.Registry.panels) do
		local opacity = e.data.opacity
		if e.data.role == "main" then opacity = RQE.db.profile.MainFrameOpacity
		elseif e.data.role == "tracker" then opacity = RQE.db.profile.QuestFrameOpacity end
		self:_ApplyPanel(e.target, opacity, e.data.role)
	end
	for _, e in ipairs(self.Registry.headers) do self:_ApplyHeader(e.target, e.data.child) end
	for _, e in ipairs(self.Registry.iconButtons) do self:_ApplyIconButton(e.target, e.data.iconName, e.data.options) end
	for _, e in ipairs(self.Registry.textButtons) do self:_ApplyTextButton(e.target) end
	for _, e in ipairs(self.Registry.searchBoxes) do self:_ApplySearchBox(e.target) end
	for _, e in ipairs(self.Registry.legacyButtons) do
		hideRegion(e.data.background); hideRegion(e.data.label)
		self:_ApplyIconButton(e.target, e.data.iconName, e.data.options or { size = 30, iconInset = 2 })
	end
	for _, e in ipairs(self.Registry.locationBars) do self:_ApplyLocationInfoBar(e.target) end
	for _, e in ipairs(self.Registry.aceFrames) do self:_ApplyAceFrame(e.target) end
	self:_ApplyFrameLayout()
	if RQE.headerText then RQE.headerText:SetFont("Fonts\\SKURRI.TTF", 17, "OUTLINE") end
	if RQE.QuestTrackerHeaderText then RQE.QuestTrackerHeaderText:SetFont("Fonts\\SKURRI.TTF", 14, "OUTLINE") end
	if RQE.Buttons and RQE.Buttons.UpdateHeaderNavigation then RQE.Buttons.UpdateHeaderNavigation() end
	if RQE.Buttons and RQE.Buttons.UpdateQuestTrackerHeaderTitle then RQE.Buttons.UpdateQuestTrackerHeaderTitle() end
	self:RefreshExternalButtons()
	if RQE.MagicButton and RQE.Buttons and RQE.Buttons.UpdateMagicButtonIcon then RQE.Buttons.UpdateMagicButtonIcon() end
end

local externalSkinWatcher = CreateFrame("Frame")
externalSkinWatcher:RegisterEvent("ADDON_LOADED")
externalSkinWatcher:RegisterEvent("PLAYER_LOGIN")
externalSkinWatcher:SetScript("OnEvent", function(_, event, addonName)
	if event == "PLAYER_LOGIN" or addonName == "RQE_Contribution" then UI:RefreshExternalButtons() end
end)
