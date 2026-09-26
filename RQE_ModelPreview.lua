--[[

RQE_ModelPreview.lua
Reusable creature-model and object-image preview window for Rhodan's Quest Explorer.

Testing commands:
	/run RQE.CreatureOrObject(4712, "n")
	/run RQE.NPC(4712)
	/run RQE.CreatureOrObject("F00483", "o")
	/run RQE.Object("F00483", "Bridge to Nowhere")

NPC creature IDs are resolved directly by Blizzard's model widget. Object keys
load cataloged Media/ObjectPreviews images (with legacy <key>.tga fallback) because Blizzard does not
expose an equivalent SetGameObject(objectID) model-widget method.

]]

RQE = RQE or {}

local PREVIEW_WIDTH = 250
local PREVIEW_HEIGHT = 270
local MODEL_INSET = 14
local MODEL_TOP = -48
local LOAD_TIMEOUT = 2
local OBJECT_IMAGE_ROOT = "Interface\\AddOns\\RQE\\Media\\ObjectPreviews\\"
local NPC_VIEW_X = 40
local NPC_VIEW_Y = 32
local MIN_NPC_ZOOM = 0.35
local MAX_NPC_ZOOM = 3
local MIN_OBJECT_ZOOM = 1
local MAX_OBJECT_ZOOM = 5

local previewFrame

local function CancelPreviewLoad(frame)
	if frame.loadTimer then
		frame.loadTimer:Cancel()
		frame.loadTimer = nil
	end
end

local VALID_ANCHOR_POINTS = {
	TOPLEFT = true, TOP = true, TOPRIGHT = true,
	LEFT = true, CENTER = true, RIGHT = true,
	BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local function GetPreviewProfile()
	local profile = RQE.db and RQE.db.profile
	if not profile then return nil end
	if type(profile.creatureObjectPreviewPosition) ~= "table" then
		profile.creatureObjectPreviewPosition = {}
	end
	return profile.creatureObjectPreviewPosition
end

local function GetPreviewLayout()
	local saved = GetPreviewProfile() or {}
	local point = VALID_ANCHOR_POINTS[saved.point] and saved.point or "TOPRIGHT"
	local relativePoint = VALID_ANCHOR_POINTS[saved.relativePoint] and saved.relativePoint or "TOPLEFT"
	local x = tonumber(saved.x) or -12
	local y = tonumber(saved.y) or -105
	local scale = math.max(0.5, math.min(2, tonumber(saved.scale) or 1))
	return point, relativePoint, x, y, scale
end

local function GetAnchorCoordinates(frame, point)
	if not frame then return nil end
	local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	if not (left and right and top and bottom) then return nil end
	local x = point:find("LEFT", 1, true) and left
		or (point:find("RIGHT", 1, true) and right)
		or ((left + right) / 2)
	local y = point:find("TOP", 1, true) and top
		or (point:find("BOTTOM", 1, true) and bottom)
		or ((top + bottom) / 2)
	return x, y
end

local function PrintPreviewMessage(message)
	print("|cff00bfffRQE Model Preview:|r " .. tostring(message))
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function GetCursorInRegionSpace(region)
	-- Previous Blizzard call changed 2026.09.25: local x, y = GetCursorPosition()
	local x, y = RQE.API.Client.GetCursorPosition()
	local scale = region and region:GetEffectiveScale() or 1
	if not scale or scale == 0 then scale = 1 end
	return x / scale, y / scale
end

local function GetModelViewOptions(model)
	local options = type(model.RQEPreviewOptions) == "table" and model.RQEPreviewOptions or {}
	model.RQEPreviewOptions = options
	options.viewX = tonumber(options.viewX) or NPC_VIEW_X
	options.viewY = tonumber(options.viewY) or NPC_VIEW_Y
	options.scale = Clamp(tonumber(options.scale) or 1, MIN_NPC_ZOOM, MAX_NPC_ZOOM)
	return options
end

local function ApplyObjectViewport(frame)
	if not frame or not frame.Content or not frame.Image then return end
	local width = math.max(1, frame.Content:GetWidth() or 1)
	local height = math.max(1, frame.Content:GetHeight() or 1)
	local zoom = Clamp(tonumber(frame.objectZoom) or 1, MIN_OBJECT_ZOOM, MAX_OBJECT_ZOOM)
	local maxX = width * (zoom - 1) * 0.5
	local maxY = height * (zoom - 1) * 0.5
	frame.objectZoom = zoom
	frame.objectPanX = Clamp(tonumber(frame.objectPanX) or 0, -maxX, maxX)
	frame.objectPanY = Clamp(tonumber(frame.objectPanY) or 0, -maxY, maxY)
	frame.Image:ClearAllPoints()
	frame.Image:SetPoint("CENTER", frame.Content, "CENTER", frame.objectPanX, frame.objectPanY)
	frame.Image:SetSize(width * zoom, height * zoom)
end

local function StopViewportDrag(content)
	content.isDraggingView = nil
	content:SetScript("OnUpdate", nil)
end

local function UpdateViewportDrag(content)
	if not content.isDraggingView then return end
	local frame = content:GetParent()
	local cursorX, cursorY = GetCursorInRegionSpace(content)
	local deltaX = cursorX - content.dragCursorX
	local deltaY = cursorY - content.dragCursorY

	if frame.previewKind == "npc" and frame.Model and frame.Model:IsShown() then
		local options = GetModelViewOptions(frame.Model)
		local width = math.max(1, content:GetWidth() or 1)
		local height = math.max(1, content:GetHeight() or 1)
		options.viewX = Clamp(content.dragStartX + deltaX, -width, width)
		options.viewY = Clamp(content.dragStartY + deltaY, -height, height)
		if type(frame.Model.SetViewTranslation) == "function" then
			pcall(frame.Model.SetViewTranslation, frame.Model, options.viewX, options.viewY)
		end
	elseif frame.previewKind == "object" and frame.Image and frame.Image:IsShown() then
		frame.objectPanX = content.dragStartX + deltaX
		frame.objectPanY = content.dragStartY + deltaY
		ApplyObjectViewport(frame)
	end
end

local function SavePreviewFramePosition(frame)
	local saved = GetPreviewProfile()
	if saved and RQEFrame then
		local point, relativePoint = GetPreviewLayout()
		local frameX, frameY = GetAnchorCoordinates(frame, point)
		local relativeX, relativeY = GetAnchorCoordinates(RQEFrame, relativePoint)
		if frameX and relativeX then
			saved.x = math.floor((frameX - relativeX) + 0.5)
			saved.y = math.floor((frameY - relativeY) + 0.5)
			RQE.ApplyCreatureObjectPreviewLayout()
		end
	end
end

local function GetPreviewQuestContext()
	local superTrackedQuestID = RQE.API and RQE.API.GetSuperTrackedQuestID
		and tonumber(RQE.API.GetSuperTrackedQuestID()) or nil
	local questID = tonumber(RQE.CurrentDisplayedQuestID)
		or tonumber(RQE.DisplayedQuestID)
		or tonumber(RQE.searchedQuestID)
		or superTrackedQuestID
	-- AddonSetStepIndex is the authoritative automatic/manual step selection.
	-- Keep stale manual-preview state from masking a later periodic advancement.
	local stepIndex = tonumber(RQE.AddonSetStepIndex)
		or tonumber(RQE.CurrentDisplayedStepIndex)
		or tonumber(RQE.CurrentStepIndex)
		or tonumber(RQE.ManualPreviewStepIndex)
	return questID, stepIndex, superTrackedQuestID
end

local function HasActiveQuestDisplay()
	local searchedQuestID = tonumber(RQE.searchedQuestID)
	local superTrackedQuestID = RQE.API and RQE.API.GetSuperTrackedQuestID
		and tonumber(RQE.API.GetSuperTrackedQuestID())
	local questIDText = RQE.QuestIDText and RQE.QuestIDText:GetText()
	local questNameText = RQE.QuestNameText and RQE.QuestNameText:GetText()
	return (searchedQuestID and searchedQuestID > 0)
		or (superTrackedQuestID and superTrackedQuestID > 0)
		or (type(questIDText) == "string" and questIDText:match("%d+") ~= nil)
		or (type(questNameText) == "string" and questNameText:find("%S") ~= nil)
end

local function CapturePreviewQuestContext(frame, previewKey)
	frame.previewKey = previewKey
	frame.previewQuestID, frame.previewStepIndex, frame.previewSuperTrackedQuestID =
		GetPreviewQuestContext()
	frame.previewSuperTrackCaptured = true
end

local function PreparePreviewIdentity(frame, previewKey)
	if frame:IsShown() and frame.previewKey and frame.previewKey ~= previewKey then
		-- Replacing one hovered entity with another is a complete preview change,
		-- so clear the old model/image and its interaction state first.
		frame:Hide()
	end
	CapturePreviewQuestContext(frame, previewKey)
end

-- Moving between wrapped fragments of the same link must not reload the model
-- or reset the player's pan/zoom. Failed loads remain retryable on the next hover.
local function IsCurrentPreview(frame, key, kind, title, questBound, source)
	if not frame:IsShown() or frame.previewKey ~= key or frame.previewKind ~= kind
		or frame.Title:GetText() ~= title or frame.previewSource ~= source
		or frame.previewRequiresQuest ~= (questBound == true)
		or not (frame.previewReady or frame.loadTimer) then return false end
	local questID, stepIndex, superTrackedQuestID = GetPreviewQuestContext()
	return frame.previewQuestID == questID and frame.previewStepIndex == stepIndex
		and frame.previewSuperTrackedQuestID == superTrackedQuestID
end

local function NormalizePreviewType(previewType)
	if type(previewType) ~= "string" then return nil end
	previewType = string.lower(previewType)
	if previewType == "n" or previewType == "npc" or previewType == "creature" then
		return "npc"
	elseif previewType == "o" or previewType == "object" or previewType == "gameobject" then
		return "object"
	end
end

local function NormalizeObjectKey(value)
	if type(value) == "number" then value = tostring(value) end
	if type(value) ~= "string" then return nil end
	value = value:match("^%s*(.-)%s*$")
	if value == "" or not value:match("^[%a%d]+$") then return nil end
	return value
end

local function NormalizeObjectFileLabel(value)
	if type(value) ~= "string" then return nil end
	value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	value = value:gsub("[%c<>:\"/\\|%?%*]", "_")
	value = value:gsub("%s+", " "):match("^%s*(.-)%s*$")
	value = value:gsub("[%. ]+$", "")
	if value == "" then return nil end
	return value
end

local function AddToSpecialFrames(frameName)
	if type(UISpecialFrames) ~= "table" then return end
	for _, name in ipairs(UISpecialFrames) do
		if name == frameName then return end
	end
	table.insert(UISpecialFrames, frameName)
end

local function CreatePreviewFrame()
	if previewFrame then return previewFrame end

	local template = BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame("Frame", "RQECreatureOrObjectPreviewFrame", UIParent, template)
	frame:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then self:Hide() end
	end)
	frame.contextElapsed = 0
	local function CheckPreviewContext(self, elapsed)
		if not self:IsShown() or not self.previewKey then return end
		self.contextElapsed = (self.contextElapsed or 0) + elapsed
		if self.contextElapsed < 0.10 then return end
		self.contextElapsed = 0

		local questID, stepIndex, superTrackedQuestID = GetPreviewQuestContext()
		local questChanged = self.previewQuestID and questID
			and self.previewQuestID ~= questID
		local stepChanged = self.previewStepIndex and stepIndex
			and self.previewStepIndex ~= stepIndex
		local superTrackChanged = self.previewSuperTrackCaptured
			and self.previewSuperTrackedQuestID ~= superTrackedQuestID
		local questDisplayCleared = self.previewRequiresQuest and not HasActiveQuestDisplay()
		if questChanged or stepChanged or superTrackChanged or questDisplayCleared then
			self:Hide()
		end
	end
	frame:SetScript("OnShow", function(self)
		self.contextElapsed = 0
		self:SetScript("OnUpdate", CheckPreviewContext)
	end)

	if type(frame.SetBackdrop) == "function" then
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0.015, 0.02, 0.035, 0.96)
		frame:SetBackdropBorderColor(1, 0.843, 0, 1)
	end

	frame.Header = CreateFrame("Button", nil, frame, template)
	frame.Header:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
	frame.Header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
	frame.Header:SetHeight(41)
	frame.Header:RegisterForDrag("LeftButton")
	frame.Header:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	frame.Header:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePreviewFramePosition(frame)
	end)
	frame.Header:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then frame:Hide() end
	end)
	if type(frame.Header.SetBackdrop) == "function" then
		frame.Header:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		frame.Header:SetBackdropColor(0.02, 0.055, 0.10, 0.98)
		frame.Header:SetBackdropBorderColor(1, 0.843, 0, 1)
	end
	frame.HeaderAccent = frame.Header:CreateTexture(nil, "ARTWORK")
	frame.HeaderAccent:SetPoint("BOTTOMLEFT", frame.Header, "BOTTOMLEFT", 5, 2)
	frame.HeaderAccent:SetPoint("BOTTOMRIGHT", frame.Header, "BOTTOMRIGHT", -5, 2)
	frame.HeaderAccent:SetHeight(2)
	frame.HeaderAccent:SetColorTexture(0, 0.34, 0.72, 1)

	frame.Title = frame.Header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.Title:SetPoint("CENTER", frame.Header, "CENTER", 0, 1)
	frame.Title:SetPoint("LEFT", frame.Header, "LEFT", 22, 0)
	frame.Title:SetPoint("RIGHT", frame.Header, "RIGHT", -30, 0)
	frame.Title:SetJustifyH("CENTER")
	frame.Title:SetTextColor(1, 0.843, 0)

	frame.CloseButton = CreateFrame("Button", nil, frame.Header, "UIPanelCloseButton")
	frame.CloseButton:SetPoint("TOPRIGHT", frame.Header, "TOPRIGHT", 2, 2)
	frame.CloseButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame.Content = CreateFrame("Frame", nil, frame)
	frame.Content:SetPoint("TOPLEFT", frame, "TOPLEFT", MODEL_INSET, MODEL_TOP)
	frame.Content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -MODEL_INSET, 28)
	if type(frame.Content.SetClipsChildren) == "function" then
		frame.Content:SetClipsChildren(true)
	end
	frame.Content:EnableMouse(true)
	frame.Content:EnableMouseWheel(true)
	frame.Content:RegisterForDrag("LeftButton")
	frame.Content:SetScript("OnDragStart", function(content)
		local cursorX, cursorY = GetCursorInRegionSpace(content)
		content.dragCursorX = cursorX
		content.dragCursorY = cursorY
		if frame.previewKind == "npc" and frame.Model then
			local options = GetModelViewOptions(frame.Model)
			content.dragStartX = options.viewX
			content.dragStartY = options.viewY
		else
			content.dragStartX = tonumber(frame.objectPanX) or 0
			content.dragStartY = tonumber(frame.objectPanY) or 0
		end
		content.isDraggingView = true
		content:SetScript("OnUpdate", UpdateViewportDrag)
	end)
	frame.Content:SetScript("OnDragStop", StopViewportDrag)
	frame.Content:SetScript("OnMouseUp", function(content, button)
		if button == "RightButton" then frame:Hide() end
		if button == "LeftButton" then StopViewportDrag(content) end
	end)
	frame.Content:SetScript("OnMouseWheel", function(_, delta)
		if frame.previewKind == "npc" and frame.Model and frame.Model:IsShown() then
			local options = GetModelViewOptions(frame.Model)
			local factor = delta > 0 and 0.88 or 1.14
			options.scale = Clamp(options.scale * factor, MIN_NPC_ZOOM, MAX_NPC_ZOOM)
			if type(frame.Model.SetCamDistanceScale) == "function" then
				pcall(frame.Model.SetCamDistanceScale, frame.Model, options.scale)
			end
		elseif frame.previewKind == "object" and frame.Image and frame.Image:IsShown() then
			local factor = delta > 0 and 1.15 or (1 / 1.15)
			frame.objectZoom = Clamp((tonumber(frame.objectZoom) or 1) * factor, MIN_OBJECT_ZOOM, MAX_OBJECT_ZOOM)
			ApplyObjectViewport(frame)
		end
	end)
	frame.Content:SetScript("OnSizeChanged", function()
		if frame.previewKind == "object" then ApplyObjectViewport(frame) end
	end)

	frame.Model, frame.ModelFrameType, frame.ModelError = RQE.API.CreateCreaturePreviewModel(frame.Content)
	if frame.Model then
		frame.Model:SetAllPoints(frame.Content)
		frame.Model:EnableMouse(false)
		frame.Model:SetScript("OnModelLoaded", function(model)
			if not frame:IsShown() or frame.previewKind ~= "npc"
				or model.RQEPreviewToken ~= frame.requestToken then return end
			CancelPreviewLoad(frame)
			frame.previewReady = true
			-- Blizzard can replace camera transforms while SetCreature finishes;
			-- apply the compact-window centering only after the model is ready.
			RQE.API.ConfigureCreaturePreviewModel(model, model.RQEPreviewOptions)
			if type(model.RefreshCamera) == "function" then
				pcall(model.RefreshCamera, model)
			end
			frame.Status:Hide()
			model:SetAlpha(1)
		end)
	end

	frame.Image = frame.Content:CreateTexture(nil, "ARTWORK")
	frame.Image:SetAllPoints(frame.Content)
	frame.Image:SetTexCoord(0, 1, 0, 1)
	frame.Image:Hide()

	frame.Status = frame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.Status:SetPoint("CENTER", frame.Content, "CENTER", 0, 0)
	frame.Status:SetPoint("LEFT", frame.Content, "LEFT", 10, 0)
	frame.Status:SetPoint("RIGHT", frame.Content, "RIGHT", -10, 0)
	frame.Status:SetJustifyH("CENTER")
	frame.Status:SetJustifyV("MIDDLE")
	frame.Status:SetTextColor(0.92, 0.92, 0.92)

	frame.Help = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.Help:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
	frame.Help:SetText("Drag view  •  Wheel zoom  •  Title moves window")

	frame:SetScript("OnHide", function(self)
		CancelPreviewLoad(self)
		self:SetScript("OnUpdate", nil)
		self.requestToken = (self.requestToken or 0) + 1
		self.previewReady, self.previewSource = nil, nil
		self.previewKind = nil
		self.previewKey = nil
		self.previewQuestID = nil
		self.previewStepIndex = nil
		self.previewSuperTrackedQuestID = nil
		self.previewSuperTrackCaptured = nil
		self.previewRequiresQuest = nil
		self.contextElapsed = 0
		if self.Content then StopViewportDrag(self.Content) end
		if self.Model then
			self.Model.RQEPreviewToken = nil
			self.Model.RQEPreviewOptions = nil
			self.Model:SetAlpha(0)
			self.Model:Hide()
			RQE.API.ClearCreaturePreviewModel(self.Model)
		end
		if self.Image then
			self.Image:SetTexture(nil)
			self.Image:Hide()
		end
	end)

	frame:Hide()
	AddToSpecialFrames(frame:GetName())
	previewFrame = frame
	RQE.ApplyCreatureObjectPreviewLayout()
	return frame
end

function RQE.IsCreatureObjectPreviewEnabled()
	return not RQE.db or not RQE.db.profile or RQE.db.profile.enableCreatureObjectPreview ~= false
end

function RQE.ApplyCreatureObjectPreviewLayout()
	if not previewFrame then return end
	local point, relativePoint, x, y, scale = GetPreviewLayout()
	previewFrame:SetScale(scale)
	previewFrame:ClearAllPoints()
	if RQEFrame then
		previewFrame:SetPoint(point, RQEFrame, relativePoint, x, y)
	else
		previewFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
	end
end

function RQE.HideCreatureObjectPreview(questOnly)
	if previewFrame and (not questOnly or previewFrame.previewRequiresQuest) then
		previewFrame:Hide()
	end
end

local function BeginPreview(title, previewKey, loader, unavailableMessage, questBound)
	local frame = CreatePreviewFrame()
	if IsCurrentPreview(frame, previewKey, "npc", title, questBound) then return true end
	CancelPreviewLoad(frame)
	RQE.ApplyCreatureObjectPreviewLayout()
	PreparePreviewIdentity(frame, previewKey)
	frame.previewReady, frame.previewSource = false, nil
	frame.requestToken = (frame.requestToken or 0) + 1
	local token = frame.requestToken
	frame.Title:SetText(title)
	frame.previewKind = "npc"
	frame.previewRequiresQuest = questBound == true
	frame.objectZoom, frame.objectPanX, frame.objectPanY = 1, 0, 0
	frame.Status:SetText("Loading preview…")
	frame.Status:Show()
	frame:Show()
	frame.Image:SetTexture(nil)
	frame.Image:Hide()

	if not frame.Model then
		frame.Status:SetText(frame.ModelError or "No compatible model widget is available.")
		return false
	end

	frame.Model.RQEPreviewToken = token
	frame.Model:Show()
	frame.Model:SetAlpha(0)
	local ok, err = loader(frame.Model)
	if not ok then
		frame.Status:SetText(err or unavailableMessage or "The preview could not be loaded.")
		return false
	end

	if not frame.previewReady then
		-- Previous Blizzard call changed 2026.09.25: frame.loadTimer = C_Timer.NewTimer(LOAD_TIMEOUT, function()
		frame.loadTimer = RQE.API.Client.C_Timer.NewTimer(LOAD_TIMEOUT, function()
			if frame.requestToken ~= token then return end
			frame.loadTimer = nil
			if frame:IsShown() and frame.Status:IsShown() then
				frame.Status:SetText(unavailableMessage or "Blizzard returned no displayable model for this ID.")
			end
		end)
	end
	return true
end

local function BeginImagePreview(title, previewKey, texturePaths, unavailableMessage, questBound)
	local frame = CreatePreviewFrame()
	if type(texturePaths) ~= "table" then texturePaths = { texturePaths } end
	local source = table.concat(texturePaths, "\n")
	if IsCurrentPreview(frame, previewKey, "object", title, questBound, source) then return true end
	CancelPreviewLoad(frame)
	RQE.ApplyCreatureObjectPreviewLayout()
	PreparePreviewIdentity(frame, previewKey)
	frame.previewReady, frame.previewSource = false, source
	frame.requestToken = (frame.requestToken or 0) + 1
	frame.Title:SetText(title)
	frame.previewKind = "object"
	frame.previewRequiresQuest = questBound == true
	frame.objectZoom, frame.objectPanX, frame.objectPanY = 1, 0, 0
	frame.Status:SetText(unavailableMessage or "Object preview image is unavailable.")
	frame.Status:Show()
	frame:Show()

	if frame.Model then
		frame.Model.RQEPreviewToken = nil
		frame.Model.RQEPreviewOptions = nil
		frame.Model:SetAlpha(0)
		frame.Model:Hide()
		RQE.API.ClearCreaturePreviewModel(frame.Model)
	end

	for _, texturePath in ipairs(texturePaths) do
		frame.Image:SetTexture(nil)
		local ok, loaded = pcall(frame.Image.SetTexture, frame.Image, texturePath)
		if ok and loaded ~= false then
			frame.previewReady = true
			ApplyObjectViewport(frame)
			frame.Image:Show()
			frame.Status:Hide()
			return true
		end
	end
	frame.Image:Hide()
	return false
end

function RQE.ShowNPCPreview(creatureID, displayName, questBound)
	if not RQE.IsCreatureObjectPreviewEnabled() then return false end
	creatureID = tonumber(creatureID)
	if not creatureID or creatureID <= 0 then return false end
	local title = displayName and displayName ~= "" and (displayName .. " (NPC " .. creatureID .. ")") or ("NPC " .. creatureID)
	return BeginPreview(title, "npc:" .. creatureID, function(model)
		return RQE.API.SetCreaturePreviewModel(model, creatureID)
	end, "Blizzard returned no displayable creature model for NPC " .. creatureID .. ".", questBound)
end

function RQE.ShowObjectImagePreview(objectKey, displayName, texturePath, questBound)
	if not RQE.IsCreatureObjectPreviewEnabled() then return false end
	objectKey = NormalizeObjectKey(objectKey)
	if not objectKey then
		PrintPreviewMessage("Object preview keys may contain only letters and numbers.")
		return false
	end
	-- The catalog is generated offline: the client cannot enumerate image files.
	-- Keep link wording independent from both the texture filename and its title.
	local entry = RQE.ObjectPreviewCatalog and RQE.ObjectPreviewCatalog[objectKey:lower()]
	local previewName = displayName
	if not texturePath and entry and entry.name and entry.name ~= "" then
		previewName = entry.name
	end
	local fileLabel = NormalizeObjectFileLabel(displayName)
	local texturePaths = {}
	if texturePath then
		texturePaths[1] = texturePath
	else
		if entry and entry.file then
			texturePaths[#texturePaths + 1] = OBJECT_IMAGE_ROOT .. entry.file
		end
		-- Preserve unindexed legacy links and key-only images as fallbacks.
		if fileLabel then
			texturePaths[#texturePaths + 1] = OBJECT_IMAGE_ROOT .. objectKey .. " - " .. fileLabel .. ".tga"
		end
		texturePaths[#texturePaths + 1] = OBJECT_IMAGE_ROOT .. objectKey .. ".tga"
	end
	local customKey = objectKey:match("^%a") ~= nil
	local title
	if customKey then
		title = previewName and previewName ~= "" and previewName or "Object Preview"
	else
		title = previewName and previewName ~= "" and (previewName .. "\n(Object " .. objectKey .. ")") or ("Object " .. objectKey)
	end
	local expectedName = entry and entry.file or (objectKey .. (fileLabel and (" - " .. fileLabel) or "") .. ".tga")
	return BeginImagePreview(title, "object:" .. objectKey, texturePaths,
		"No bundled image was found for object " .. objectKey .. ".\nExpected: Media/ObjectPreviews/" .. expectedName,
		questBound)
end

function RQE.CreatureOrObject(id, previewType, displayName)
	local normalizedType = NormalizePreviewType(previewType)
	if not normalizedType then
		PrintPreviewMessage('Quote the type: "n" for NPC or "o" for object. Example: /run RQE.CreatureOrObject(4712, "n")')
		return false
	end

	if normalizedType == "npc" then
		return RQE.ShowNPCPreview(id, displayName)
	elseif normalizedType == "object" then
		return RQE.ShowObjectImagePreview(id, displayName)
	end
end

function RQE.NPC(creatureID)
	return RQE.CreatureOrObject(creatureID, "n")
end

function RQE.Object(objectKey, displayName)
	return RQE.CreatureOrObject(objectKey, "o", displayName)
end
