--[[

RQE_ModelPreview.lua
Reusable creature-model and object-image preview window, interaction controls, and quest-context lifecycle

]]

--------------------------------------------------
-- #1. 🧰 Preview Constants & Saved Layout
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. File Notes, Namespace & Preview Constants
	-------------------------------------------------------

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
	local MIN_NPC_ZOOM = 0.35
	local MAX_NPC_ZOOM = 3
	local NPC_ROTATION_STEP = math.pi / 4
	local NPC_ROTATION_HOLD_DELAY = 0.25
	local NPC_ROTATION_HOLD_SPEED = math.pi / 2
	local NPC_CONTROL_ROW_HEIGHT = 28
	local MIN_OBJECT_ZOOM = 1
	local MAX_OBJECT_ZOOM = 5

	local previewFrame

	-------------------------------------------------------
	-- #1b. Load Cancellation & Saved Position State
	-------------------------------------------------------

	-- Cancels and clears the pending model-load timeout for a preview frame.
	local function CancelPreviewLoad(frame)
		if frame.loadTimer then
			frame.loadTimer:Cancel()
			frame.loadTimer = nil
		end
	end

	-------------------------------------------------------
	-- #1c. Anchor & Layout Resolution
	-------------------------------------------------------

	local VALID_ANCHOR_POINTS = {
		TOPLEFT = true, TOP = true, TOPRIGHT = true,
		LEFT = true, CENTER = true, RIGHT = true,
		BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
	}

	-- Returns the active profile's preview-position table, creating it when necessary.
	local function GetPreviewProfile()
		local profile = RQE.db and RQE.db.profile
		if not profile then return nil end
		if type(profile.creatureObjectPreviewPosition) ~= "table" then
			profile.creatureObjectPreviewPosition = {}
		end
		return profile.creatureObjectPreviewPosition
	end

	-- Resolves validated preview anchors, offsets, and scale from the active profile.
	local function GetPreviewLayout()
		local saved = GetPreviewProfile() or {}
		local point = VALID_ANCHOR_POINTS[saved.point] and saved.point or "TOPRIGHT"
		local relativePoint = VALID_ANCHOR_POINTS[saved.relativePoint] and saved.relativePoint or "TOPLEFT"
		local x = tonumber(saved.x) or -12
		local y = tonumber(saved.y) or -105
		local scale = math.max(0.5, math.min(2, tonumber(saved.scale) or 1))
		return point, relativePoint, x, y, scale
	end

	-- Calculates the screen coordinates represented by a requested frame anchor point.
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

--------------------------------------------------
-- #2. 🖱️ Viewport Interaction & Quest Context
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Shared Math, Cursor & Model View Helpers
	-------------------------------------------------------

	-- Prints a consistently prefixed model-preview status message to chat.
	local function PrintPreviewMessage(message)
		print("|cff00bfffRQE Model Preview:|r " .. tostring(message))
	end

	-- Constrains a numeric value to the supplied minimum and maximum.
	local function Clamp(value, minimum, maximum)
		return math.max(minimum, math.min(maximum, value))
	end

	-- Converts the current cursor position into the effective coordinate space of a region.
	local function GetCursorInRegionSpace(region)
		-- Previous Blizzard call changed 2026.09.25: local x, y = GetCursorPosition()
		local x, y = RQE.API.Client.GetCursorPosition()
		local scale = region and region:GetEffectiveScale() or 1
		if not scale or scale == 0 then scale = 1 end
		return x / scale, y / scale
	end

	-- Initializes and returns the model's persistent pan and zoom options.
	local function GetModelViewOptions(model)
		local options = type(model.RQEPreviewOptions) == "table" and model.RQEPreviewOptions or {}
		model.RQEPreviewOptions = options
		options.viewX = tonumber(options.viewX) or 0
		options.viewY = tonumber(options.viewY) or 0
		options.scale = Clamp(tonumber(options.scale) or 1, MIN_NPC_ZOOM, MAX_NPC_ZOOM)
		return options
	end

	-- Stops hold updates, retaining click suppression until release or the next fresh press.
	local function StopNPCRotationHold(button, cancelClick)
		if cancelClick and button.rotationPressToken then button.suppressRotationClick = true end
		button.rotationPressStart = nil
		button.rotationLastElapsed = nil
		button:SetScript("OnUpdate", nil)
	end

	-- Reserves an NPC-only control row and enables rotation only for a ready, supported model.
	local function UpdateNPCRotationControls(frame)
		if not frame.RotationControls then return end
		local isNPC = frame.previewKind == "npc"
		local extraHeight = isNPC and NPC_CONTROL_ROW_HEIGHT or 0
		-- Grow the NPC window with the row so its original model viewport and framing stay intact.
		frame:SetHeight(PREVIEW_HEIGHT + extraHeight)
		frame.Content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -MODEL_INSET, 28 + extraHeight)
		frame.RotationControls:SetShown(isNPC)
		local enabled = isNPC and frame.previewReady and frame.Model and frame.Model:IsShown()
			and type(frame.Model.SetFacing) == "function" and not frame.rotationUnavailable
		for _, button in ipairs(frame.RotationControls.Buttons) do
			if enabled then
				button:Enable()
			else
				StopNPCRotationHold(button, true)
				button:Disable()
			end
			button:SetAlpha(enabled and 1 or 0.35)
		end
	end

	-- Turns the ready NPC by the requested angle, or restores its default facing without changing pan or zoom.
	local function RotateNPCPreview(frame, delta)
		local model = frame.Model
		if not frame:IsShown() or frame.previewKind ~= "npc" or not frame.previewReady
			or not model or not model:IsShown() or frame.rotationUnavailable then return end
		local options = GetModelViewOptions(model)
		local facing = RQE.API.DEFAULT_CREATURE_PREVIEW_FACING
		if delta then
			facing = ((tonumber(options.facing) or facing) + delta + math.pi) % (2 * math.pi) - math.pi
		end
		if RQE.API.SetCreaturePreviewFacing(model, facing) then
			options.facing = facing
		else
			frame.rotationUnavailable = true
			UpdateNPCRotationControls(frame)
		end
	end

	-- Applies only time beyond the hold delay, including the final interval before release.
	local function ApplyNPCRotationHold(button)
		if not button.rotationPressStart then return end
		local frame = button:GetParent():GetParent()
		if not button:IsEnabled() or not frame:IsShown() or frame.previewKind ~= "npc"
			or not frame.previewReady or frame.rotationUnavailable
			or button.rotationPressToken ~= frame.requestToken
			or not frame.Model or not frame.Model:IsShown() then
			StopNPCRotationHold(button, true)
			return
		end
		local elapsed = math.max(0, RQE.API.Client.GetTime() - button.rotationPressStart)
		local heldTime = math.max(0, elapsed - NPC_ROTATION_HOLD_DELAY)
		local previousHeldTime = math.max(0, (button.rotationLastElapsed or 0) - NPC_ROTATION_HOLD_DELAY)
		button.rotationLastElapsed = elapsed
		if elapsed >= NPC_ROTATION_HOLD_DELAY then button.suppressRotationClick = true end
		if heldTime > previousHeldTime then
			local direction = button.rotationDelta / NPC_ROTATION_STEP
			RotateNPCPreview(frame, direction * NPC_ROTATION_HOLD_SPEED * (heldTime - previousHeldTime))
		end
	end

	-- Advances a held arrow while the physical mouse button remains down.
	local function UpdateNPCRotationHold(button)
		if not RQE.API.Client.IsMouseButtonDown("LeftButton") then
			StopNPCRotationHold(button, true)
			return
		end
		ApplyNPCRotationHold(button)
	end

	-------------------------------------------------------
	-- #2b. Object Viewport & Drag Handling
	-------------------------------------------------------

	-- Applies clamped zoom and pan values to the object preview texture.
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

	-- Ends active viewport dragging and removes its per-frame update handler.
	local function StopViewportDrag(content)
		content.isDraggingView = nil
		content:SetScript("OnUpdate", nil)
	end

	-- Updates creature translation or object-image panning while the viewport is dragged.
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

	-------------------------------------------------------
	-- #2c. Preview Window Position Persistence
	-------------------------------------------------------

	-- Stores the preview window's current position relative to the Quest Helper frame.
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

	-------------------------------------------------------
	-- #2d. Quest Context Capture & Preview Identity
	-------------------------------------------------------

	-- Returns the quest, step, and super-tracked IDs that identify the current preview context.
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

	-- Reports whether a searched, super-tracked, or visibly displayed quest still exists.
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

	-- Associates a preview request with the current quest and step context.
	local function CapturePreviewQuestContext(frame, previewKey)
		frame.previewKey = previewKey
		frame.previewQuestID, frame.previewStepIndex, frame.previewSuperTrackedQuestID =
			GetPreviewQuestContext()
		frame.previewSuperTrackCaptured = true
	end

	-- Clears a replaced preview and captures identity data for the incoming request.
	local function PreparePreviewIdentity(frame, previewKey)
		if frame:IsShown() and frame.previewKey and frame.previewKey ~= previewKey then
			-- Replacing one hovered entity with another is a complete preview change,
			-- so clear the old model/image and its interaction state first.
			frame:Hide()
		end
		CapturePreviewQuestContext(frame, previewKey)
	end

	-- Moving between wrapped fragments of the same link must not reload the model
	-- or reset the player's pan, zoom, or rotation. Failed loads remain retryable on the next hover.
	local function IsCurrentPreview(frame, key, kind, title, questBound, source)
		if not frame:IsShown() or frame.previewKey ~= key or frame.previewKind ~= kind
			or frame.Title:GetText() ~= title or frame.previewSource ~= source
			or frame.previewRequiresQuest ~= (questBound == true)
			or not (frame.previewReady or frame.loadTimer) then return false end
		local questID, stepIndex, superTrackedQuestID = GetPreviewQuestContext()
		return frame.previewQuestID == questID and frame.previewStepIndex == stepIndex
			and frame.previewSuperTrackedQuestID == superTrackedQuestID
	end

--------------------------------------------------
-- #3. 🧹 Preview Input Normalization
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Preview Type & Object-Key Normalization
	-------------------------------------------------------

	-- Normalizes supported NPC and object type aliases into stable preview kinds.
	local function NormalizePreviewType(previewType)
		if type(previewType) ~= "string" then return nil end
		previewType = string.lower(previewType)
		if previewType == "n" or previewType == "npc" or previewType == "creature" then
			return "npc"
		elseif previewType == "o" or previewType == "object" or previewType == "gameobject" then
			return "object"
		end
	end

	-- Validates and trims an object-preview catalog key.
	local function NormalizeObjectKey(value)
		if type(value) == "number" then value = tostring(value) end
		if type(value) ~= "string" then return nil end
		value = value:match("^%s*(.-)%s*$")
		if value == "" or not value:match("^[%a%d]+$") then return nil end
		return value
	end

	-- Sanitizes a display label for use in legacy object-preview filenames.
	local function NormalizeObjectFileLabel(value)
		if type(value) ~= "string" then return nil end
		value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		value = value:gsub("[%c<>:\"/\\|%?%*]", "_")
		value = value:gsub("%s+", " "):match("^%s*(.-)%s*$")
		value = value:gsub("[%. ]+$", "")
		if value == "" then return nil end
		return value
	end

	-------------------------------------------------------
	-- #3b. Special-Frame Registration
	-------------------------------------------------------

	-- Registers the named preview frame for Blizzard's global Escape-key handling.
	local function AddToSpecialFrames(frameName)
		if type(UISpecialFrames) ~= "table" then return end
		for _, name in ipairs(UISpecialFrames) do
			if name == frameName then return end
		end
		table.insert(UISpecialFrames, frameName)
	end

--------------------------------------------------
-- #4. 🖼️ Preview Frame Construction
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Frame, Controls & Context Lifecycle
	-------------------------------------------------------

	-- Colors the shared NPC/object viewer from the selected tracker palette.
	-- Basic and Azure & Gold keep the viewer's established appearance.
	local function ApplyPreviewTheme(frame)
		if not frame or not frame.Header then return end
		local selected = RQE.UI and RQE.UI.GetSelectedTheme and RQE.UI:GetSelectedTheme()
		local theme = RQE.UI and RQE.UI.Themes and RQE.UI.Themes[selected]
		local colors = selected ~= "Basic" and selected ~= "AzureGold"
			and theme and theme.colors
		if colors then
			local body, raised, edge, accent = colors.charcoal, colors.charcoalRaised,
				colors.gold, colors.azureBright
			if frame.SetBackdropColor then frame:SetBackdropColor(body[1], body[2], body[3], 0.96) end
			if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1) end
			if frame.Header.SetBackdropColor then
				frame.Header:SetBackdropColor(raised[1], raised[2], raised[3], 0.98)
			end
			if frame.Header.SetBackdropBorderColor then
				frame.Header:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
			end
			frame.HeaderAccent:SetColorTexture(accent[1], accent[2], accent[3], 1)
			frame.Title:SetTextColor(edge[1], edge[2], edge[3])
		else
			if frame.SetBackdropColor then frame:SetBackdropColor(0.015, 0.02, 0.035, 0.96) end
			if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(1, 0.843, 0, 1) end
			if frame.Header.SetBackdropColor then frame.Header:SetBackdropColor(0.02, 0.055, 0.10, 0.98) end
			if frame.Header.SetBackdropBorderColor then frame.Header:SetBackdropBorderColor(1, 0.843, 0, 1) end
			frame.HeaderAccent:SetColorTexture(0, 0.34, 0.72, 1)
			frame.Title:SetTextColor(1, 0.843, 0)
		end
	end

	-- Refreshes the creature object preview theme.
	function RQE.RefreshCreatureObjectPreviewTheme()
		ApplyPreviewTheme(previewFrame)
	end

	-- Hides only the tooltip owned by a rotation button when the pointer or preview leaves it.
	local function HideRotationButtonTooltip(button)
		if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
	end

	-- Cancels a departed or hidden arrow press and releases its owned tooltip.
	local function CancelNPCRotationButton(button)
		StopNPCRotationHold(button, true)
		HideRotationButtonTooltip(button)
	end

	-- Creates an icon button that turns the NPC or restores its original facing.
	local function CreateNPCRotationButton(frame, offset, label, texture, pushedTexture, delta)
		local button = CreateFrame("Button", nil, frame.RotationControls)
		button:SetSize(24, 24)
		button:SetPoint("CENTER", frame.RotationControls, "CENTER", offset, 0)
		button:SetNormalTexture(texture)
		button:SetPushedTexture(pushedTexture or texture)
		button:SetDisabledTexture(texture)
		button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		button:RegisterForClicks("LeftButtonUp")
		button.rotationDelta = delta
		if delta then
			-- Starts timing a fresh arrow press against the current preview request.
			button:SetScript("OnMouseDown", function(self, mouseButton)
				if mouseButton ~= "LeftButton" or not self:IsEnabled() or not frame.previewReady then return end
				self.suppressRotationClick = nil
				self.rotationPressToken = frame.requestToken
				self.rotationPressStart = RQE.API.Client.GetTime()
				self.rotationLastElapsed = 0
				self:SetScript("OnUpdate", UpdateNPCRotationHold)
			end)
			-- Finishes the held interval without allowing release to add an extra click step.
			button:SetScript("OnMouseUp", function(self, mouseButton)
				if mouseButton ~= "LeftButton" then return end
				ApplyNPCRotationHold(self)
				StopNPCRotationHold(self, false)
			end)
		end
		-- Applies one step for a short click, suppresses a completed hold, or restores the front view.
		button:SetScript("OnClick", function(self)
			if delta then
				ApplyNPCRotationHold(self)
				local suppressed = self.suppressRotationClick
					or (self.rotationPressToken and self.rotationPressToken ~= frame.requestToken)
				StopNPCRotationHold(self, false)
				self.rotationPressToken, self.suppressRotationClick = nil, nil
				if suppressed then return end
			end
			RotateNPCPreview(frame, delta)
		end)
		-- Explains the rotation direction or default-facing reset above the hovered icon.
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(label, 1, 0.843, 0)
			if delta then
				GameTooltip:AddLine("Click: turn 45 degrees.\nHold: rotate continuously.", 1, 1, 1)
			end
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", CancelNPCRotationButton)
		button:SetScript("OnHide", CancelNPCRotationButton)
		button:Disable()
		button:SetAlpha(0.35)
		return button
	end

	-- Creates the reusable preview window, interaction controls, model widget, and image region.
	local function CreatePreviewFrame()
		if previewFrame then return previewFrame end

		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		local frame = CreateFrame("Frame", "RQECreatureOrObjectPreviewFrame", UIParent, template)
		frame:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		-- Closes the model preview when the frame is right-clicked.
		frame:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" then self:Hide() end
		end)
		frame.contextElapsed = 0
		-- Closes a quest-bound preview when its quest, step, tracking, or display context changes.
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
		-- Applies the preview theme.
		frame:SetScript("OnShow", function(self)
			ApplyPreviewTheme(self)
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
		-- Starts moving the frame when dragging is allowed.
		frame.Header:SetScript("OnDragStart", function()
			frame:StartMoving()
		end)
		-- Stops dragging the frame and retains its final position.
		frame.Header:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			SavePreviewFramePosition(frame)
		end)
		-- Closes the preview when its header is right-clicked.
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
		-- Hides the associated frame or control.
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
		-- Records cursor and model-view state at the start of a preview drag.
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
		-- Stops the viewport drag.
		frame.Content:SetScript("OnMouseUp", function(content, button)
			if button == "RightButton" then frame:Hide() end
			if button == "LeftButton" then StopViewportDrag(content) end
		end)
		-- Applies the object viewport.
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
		-- Applies the object viewport.
		frame.Content:SetScript("OnSizeChanged", function()
			if frame.previewKind == "object" then ApplyObjectViewport(frame) end
		end)

		frame.Model, frame.ModelFrameType, frame.ModelError = RQE.API.CreateCreaturePreviewModel(frame.Content)
		if frame.Model then
			frame.Model:SetAllPoints(frame.Content)
			frame.Model:EnableMouse(false)
			-- Finishes the matching model load and reapplies its requested framing.
			frame.Model:SetScript("OnModelLoaded", function(model)
				if not frame:IsShown() or frame.previewKind ~= "npc"
					or model.RQEPreviewToken ~= frame.requestToken then return end
				CancelPreviewLoad(frame)
				frame.previewReady = true
				-- Blizzard can replace camera transforms while SetCreature finishes;
				-- apply the compact-window centering only after the model is ready.
				RQE.API.ConfigureCreaturePreviewModel(model, model.RQEPreviewOptions)
				frame.Status:Hide()
				model:SetAlpha(1)
				UpdateNPCRotationControls(frame)
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

		frame.RotationControls = CreateFrame("Frame", nil, frame)
		frame.RotationControls:SetSize(88, 24)
		frame.RotationControls:SetPoint("BOTTOM", frame, "BOTTOM", 0, 28)
		frame.RotateLeftButton = CreateNPCRotationButton(frame, -32, "Rotate left",
			"Interface\\Buttons\\UI-RotationLeft-Button-Up", "Interface\\Buttons\\UI-RotationLeft-Button-Down",
			-NPC_ROTATION_STEP)
		frame.ResetFacingButton = CreateNPCRotationButton(frame, 0, "Restore front view (keeps pan and zoom)",
			"Interface\\Buttons\\UI-RefreshButton")
		frame.RotateRightButton = CreateNPCRotationButton(frame, 32, "Rotate right",
			"Interface\\Buttons\\UI-RotationRight-Button-Up", "Interface\\Buttons\\UI-RotationRight-Button-Down",
			NPC_ROTATION_STEP)
		frame.RotationControls.Buttons = { frame.RotateLeftButton, frame.ResetFacingButton, frame.RotateRightButton }
		frame.RotationControls:Hide()

		-- Stops preview dragging and cancels pending model loading when hidden.
		frame:SetScript("OnHide", function(self)
			CancelPreviewLoad(self)
			self:SetScript("OnUpdate", nil)
			self.requestToken = (self.requestToken or 0) + 1
			self.previewReady, self.previewSource = nil, nil
			self.previewKind = nil
			self.rotationUnavailable = nil
			UpdateNPCRotationControls(self)
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
		ApplyPreviewTheme(frame)
		RQE.ApplyCreatureObjectPreviewLayout()
		return frame
	end

--------------------------------------------------
-- #5. ⚙️ Preview Availability & Layout
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Enablement, Placement & Visibility
	-------------------------------------------------------

	-- Reports whether creature and object previews are enabled for the active profile.
	function RQE.IsCreatureObjectPreviewEnabled()
		return not RQE.db or not RQE.db.profile or RQE.db.profile.enableCreatureObjectPreview ~= false
	end

	-- Applies the saved scale and Quest Helper-relative placement to the preview window.
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

	-- Hides the preview window, optionally only when it is bound to a quest.
	function RQE.HideCreatureObjectPreview(questOnly)
		if previewFrame and (not questOnly or previewFrame.previewRequiresQuest) then
			previewFrame:Hide()
		end
	end

--------------------------------------------------
-- #6. 🔄 Preview Loading
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Creature Model Loading
	-------------------------------------------------------

	-- Initializes an NPC model request, manages loading state, and reports unavailable models.
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
		frame.rotationUnavailable = nil
		UpdateNPCRotationControls(frame)
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
			-- Shows the unavailable-model message if the current preview load times out.
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

	-------------------------------------------------------
	-- #6b. Object Image Loading
	-------------------------------------------------------

	-- Initializes an object-image request and tries each catalog or legacy texture path in order.
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
		UpdateNPCRotationControls(frame)
		frame.previewRequiresQuest = questBound == true
		frame.objectZoom, frame.objectPanX, frame.objectPanY = 1, 0, 0
		frame.Status:SetText(unavailableMessage or "Object preview image is unavailable.")
		if unavailableMessage == "" then
			frame.Status:Hide()
		else
			frame.Status:Show()
		end
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

--------------------------------------------------
-- #7. 🔗 Public Preview API
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. NPC Preview Requests
	-------------------------------------------------------

	-- Validates an NPC ID and opens its Blizzard creature-model preview.
	function RQE.ShowNPCPreview(creatureID, displayName, questBound)
		if not RQE.IsCreatureObjectPreviewEnabled() then return false end
		creatureID = tonumber(creatureID)
		if not creatureID or creatureID <= 0 then return false end
		local title = displayName and displayName ~= "" and (displayName .. " (NPC " .. creatureID .. ")") or ("NPC " .. creatureID)
		-- Sets the creature preview model.
		return BeginPreview(title, "npc:" .. creatureID, function(model)
			return RQE.API.SetCreaturePreviewModel(model, creatureID)
		end, "Blizzard returned no displayable creature model for NPC " .. creatureID .. ".", questBound)
	end

	-------------------------------------------------------
	-- #7b. Object Image Preview Requests
	-------------------------------------------------------

	-- Resolves catalog and fallback textures before opening an object's image preview.
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
		-- An unknown-object placeholder intentionally has no picture; other missing assets retain their notice.
		local unavailableMessage = objectKey:lower() == "x99" and ""
			or ("No bundled image was found for object " .. objectKey .. ".\nExpected: Media/ObjectPreviews/" .. expectedName)
		return BeginImagePreview(title, "object:" .. objectKey, texturePaths,
			unavailableMessage, questBound)
	end

	-------------------------------------------------------
	-- #7c. Generic & Convenience Entry Points
	-------------------------------------------------------

	-- Dispatches a generic preview request to the NPC or object implementation.
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

	-- Provides a concise convenience entry point for NPC model previews.
	function RQE.NPC(creatureID)
		return RQE.CreatureOrObject(creatureID, "n")
	end

	-- Provides a concise convenience entry point for object image previews.
	function RQE.Object(objectKey, displayName)
		return RQE.CreatureOrObject(objectKey, "o", displayName)
	end

