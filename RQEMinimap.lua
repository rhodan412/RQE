--[[ 

RQEMinimap.lua
Creates minimap button that will toggle the RQEFrame

]]


---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}
RQE.hoverTimers = {}

---@class RQEMinimapButton : Frame
---@field hoverTimer any
local RQEMinimapButton = {}

--------------------------
-- 2. Debug Logic
--------------------------

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

---------------------------
-- 3. Function/Utilities
---------------------------

-- Toggle Debug Log window function
function RQE:ToggleDebugLog()
	if not RQE.DebugLogFrameRef then
		-- Initialize the debug log frame here if it doesn't exist yet
	end
	RQE.DebugLogFrame()
end

-- Open AddOn Settings function
function RQE:OpenSettings()
	-- Force the interface options to open on the AddOns tab
	if SettingsPanel then
		-- Use the new API to open the correct settings panel
		SettingsPanel:OpenToCategory("|cFFCC99FFRhodan's Quest Explorer|r")
	else
		-- Fallback for older versions, force open Interface Options to the AddOns tab
		InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
		InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer") -- Sometimes needs to be called twice due to Blizzard quirk
	end
end


---------------------------
-- 4. Data Broker Handling
---------------------------

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

-- Updated LDB Button OnClick Function
local RQEdataBroker = ldb:NewDataObject("RQE", {
	type = "launcher",
	icon = "Interface\\Addons\\RQE\\Textures\\rhodan.tga",
	OnClick = function(_, button)

		if IsShiftKeyDown() and button == "LeftButton" then
			RQE:ToggleDebugLog()

		elseif button == "LeftButton" then
			--RQE:ToggleFramesAndTracker()
			RQE.ToggleBothFramesfromLDB()

		elseif button == "RightButton" and IsShiftKeyDown() then
			RQE:OpenSettings()

		elseif button == "RightButton" then
			RQE.lastClickedFrame = _G["BazookaHL_RQE"]  -- Set the LDB button as the last clicked frame
			RQE:ShowLDBDropdownMenu()
		end
	end,

	OnEnter = function(display)
		if RQE.hoverTimers[display] then
			RQE:CancelTimer(RQE.hoverTimers[display])
		end
		RQE.hoverTimers[display] = RQE:ScheduleTimer(function()
			RQE:ShowLDBDropdownMenu()
		end, 3)

		GameTooltip:SetOwner(display, "ANCHOR_NONE")
		GameTooltip:SetPoint("BOTTOMLEFT", display, "TOPRIGHT")

		-- Directly define the tooltip here
		GameTooltip:AddLine("Rhodan's Quest Explorer")
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Left-click to toggle frame.", 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine("Right-click to open dropdown menu.", 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine("Shift+Left-click to toggle Debug Log.", 0.8, 0.8, 0.8, true)
		GameTooltip:AddLine("Shift+Right-click to open Settings.", 0.8, 0.8, 0.8, true)

		GameTooltip:Show()
	end,

	OnLeave = function(display)
		if RQE.hoverTimers[display] then
			RQE:CancelTimer(RQE.hoverTimers[display])
			RQE.hoverTimers[display] = nil
		end
		GameTooltip:Hide()
	end,
})


-- Function that toggles RQEFrame and RQEQuestFrame
function RQE.ToggleBothFramesfromLDB()
	if RQEFrame:IsShown() then
		RQE:SaveSuperTrackedQuestToCharacter()
		if not InCombatLockdown() then
			if RQEFrame then
				RQEFrame:Hide()
			end
		end
		RQE.db.profile.enableFrame = false

		C_Map.ClearUserWaypoint()

		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
		end

		if not InCombatLockdown() then
			if RQE.MagicButton then
				RQE.MagicButton:Hide()
			end
		end

		RQE.RQEQuestFrame:Hide()
		RQE.db.profile.enableQuestFrame = false
		RQE.isRQEFrameManuallyClosed = true
		RQE.isRQEQuestFrameManuallyClosed = true

		C_Timer.After(0.5, function()
			if RQE.db.profile.toggleBlizzObjectiveTracker then
				RQE:ToggleObjectiveTracker()
			end
		end)
	else
		RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()

		if not InCombatLockdown() then
			if RQEFrame then
				RQEFrame:Show()
			end
		end
		RQE.db.profile.enableFrame = true

		if not InCombatLockdown() then
			if RQE.MagicButton then
				RQE.MagicButton:Show()
			end
		end

		RQE.RQEQuestFrame:Show()
		RQE.db.profile.enableQuestFrame = true
		RQE.isRQEFrameManuallyClosed = false
		RQE.isRQEQuestFrameManuallyClosed = false
		RQE.Buttons.UpdateMagicButtonVisibility()
	end

	RQE.updateScenarioUI() -- Necessary to check/update if scenario information was present in the RQEQuestFrame, closed and then re-opened outside of a scenario
	--RQE.isPlayerSuperTrackingQuest() -- Check to see if anything is being super tracked

	C_Timer.After(0.1, function()
		if RQE.db.profile.enableFrame then
			RQE:RestoreSuperTrackedQuestForCharacter()
		else
			local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

			if not RQE.isSuperTracking or not isSuperTracking then
				RQE.Buttons.ClearButtonPressed()
			end
		end
	end)
end

---------------------------
-- 5. Minimap Button
---------------------------

-- Creates the Minimap Button
RQE.MinimapButton = CreateFrame("Button", "RQEMinimapButton", Minimap)
RQE.MinimapButton:SetSize(25, 25)
RQE.MinimapButton:SetNormalTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetHighlightTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPushedTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
RQE.MinimapButton:SetFrameStrata("MEDIUM")
RQE.MinimapButton:SetFrameLevel(8)


-- Allow the button to be dragged
RQE.MinimapButton:RegisterForDrag("LeftButton")
RQE.MinimapButton:SetMovable(true)
RQE.MinimapButton:EnableMouse(true)


-- Function to keep the button within the minimap's perimeter
function RQE:UpdateMinimapButtonPosition()
	local x, y = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	x = x / scale
	y = y / scale

	local angle = math.rad(RQE.db.profile.minimapButtonAngle)
	local mx, my = Minimap:GetCenter()
	local radius = (Minimap:GetWidth() / 2) + 5
	local dx = math.cos(angle) * radius
	local dy = math.sin(angle) * radius
	local dist = math.sqrt(dx * dx + dy * dy)

	local minimapRadius = (Minimap:GetWidth() / 2) + 5

	-- Clamp the button position to the minimap's perimeter
	if dist > minimapRadius then
		angle = math.atan2(dy, dx)
		dx = math.cos(angle) * minimapRadius
		dy = math.sin(angle) * minimapRadius
	end

	-- Ensure dx and dy are valid numbers
	if not dx or not dy then
		dx = math.cos(angle) * minimapRadius
		dy = math.sin(angle) * minimapRadius
	end

	RQE.MinimapButton:ClearAllPoints()
	RQE.MinimapButton:SetPoint("CENTER", Minimap, "CENTER", dx, dy)

	return dx, dy
end


---------------------------
-- 6. Event Handler
---------------------------

-- Register the button for clicks
RQE.MinimapButton:RegisterForClicks("AnyUp")

-- Updated Minimap Button OnClick Function
RQE.MinimapButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		if IsShiftKeyDown() then
			RQE:ToggleDebugLog()  -- Shift + Left Click
		else
			--RQE:ToggleFramesAndTracker()
			RQE.ToggleBothFramesfromLDB()
		end
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			RQE:OpenSettings()  -- Shift + Right Click
		else
			RQE.lastClickedFrame = self  -- Set the minimap button as the last clicked frame
			RQE:ShowLDBDropdownMenu()  -- Right Click
		end
	end
end)


-- Function that handles the OnEnter for the MinimapButton
RQE.MinimapButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")

	-- Directly define the tooltip here
	GameTooltip:AddLine("Rhodan's Quest Explorer")
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Left-click to toggle frame.", 0.8, 0.8, 0.8, true)
	GameTooltip:AddLine("Right-click to open dropdown menu.", 0.8, 0.8, 0.8, true)
	GameTooltip:AddLine("Shift+Left-click to toggle Debug Log.", 0.8, 0.8, 0.8, true)
	GameTooltip:AddLine("Shift+Right-click to open Settings.", 0.8, 0.8, 0.8, true)

	GameTooltip:Show()
end)


-- Function that handles the OnLeave for the MinimapButton
RQE.MinimapButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)


-- Function that handles the OnDragStart for the MinimapButton
RQE.MinimapButton:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)


-- Function that handles the OnDragStop for the MinimapButton
RQE.MinimapButton:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()

	-- Calculate the new position after dragging
	local mx, my = Minimap:GetCenter()
	local bx, by = self:GetCenter()
	local dx = bx - mx
	local dy = by - my

	-- Calculate the angle based on the new position
	local angle = math.deg(math.atan2(dy, dx))
	RQE.db.profile.minimapButtonAngle = angle

	-- Update the button's position based on the new angle
	RQE:UpdateMinimapButtonPosition()
end)


---------------------------
-- 7. Menu Creation Functions
---------------------------

-- Custom Mixin for Buttons & Menus
RQE_ButtonMixin = {}

function RQE_ButtonMixin:OnLoad()
	self:SetNormalFontObject("GameFontHighlightSmall")
	self:SetHighlightFontObject("GameFontHighlightSmall")

	local normalTexture = self:CreateTexture(nil, "BACKGROUND")
	normalTexture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
	normalTexture:SetAllPoints(self)
	self:SetNormalTexture(normalTexture)

	local highlightTexture = self:CreateTexture(nil, "BACKGROUND")
	highlightTexture:SetColorTexture(0.2, 0.2, 0.2, 1)
	highlightTexture:SetAllPoints(self)
	self:SetHighlightTexture(highlightTexture)

	local pushedTexture = self:CreateTexture(nil, "BACKGROUND")
	pushedTexture:SetColorTexture(0.05, 0.05, 0.05, 0.8)
	pushedTexture:SetAllPoints(self)
	self:SetPushedTexture(pushedTexture)
end


function RQE_ButtonMixin:OnClick()
	-- Placeholder for button click handling
end


-- Custom Mixin for Menus
RQE_MenuMixin = {}


function RQE_MenuMixin:OnLoad()
	self.buttons = {}
	self:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self:SetBackdropColor(0, 0, 0, 0.8)
end


function RQE_MenuMixin:AddButton(text, onClick, isSubmenu)
	-- Prevent adding the same button multiple times
	for _, button in ipairs(self.buttons) do
		if button:GetText() == text .. (isSubmenu and " >" or "") then
			return
		end
	end

	local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
	Mixin(button, RQE_ButtonMixin)
	button:OnLoad()
	button:SetText(text .. (isSubmenu and " >" or ""))
	button:SetSize(self:GetWidth() - 20, 20)
	button:SetScript("OnClick", onClick)

	if #self.buttons == 0 then
		button:SetPoint("TOP", self, "TOP", 0, -10)
	else
		button:SetPoint("TOP", self.buttons[#self.buttons], "BOTTOM", 0, -5)
	end

	table.insert(self.buttons, button)
	self:SetHeight((#self.buttons * (20 + 5)) + 20)
end


-- Show and Position the Menu
function RQE_MenuMixin:ShowMenu(anchorFrame, isSubmenu)
	self:ClearAllPoints()

	local screenWidth = GetScreenWidth()
	local screenHeight = GetScreenHeight()
	local anchorX, anchorY = anchorFrame:GetCenter()

	local isTopHalf = anchorY > (screenHeight / 2)
	local isLeftHalf = anchorX < (screenWidth / 2)

	-- If the anchor frame is the LDB button
	if not isSubmenu and anchorFrame == _G["BazookaHL_RQE"] then
		-- Directly anchor the main menu below the LDB button, considering screen side
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -5)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, -5)
		end
	-- If the anchor frame is the Minimap button
	elseif not isSubmenu and anchorFrame == RQE.MinimapButton then
		-- Dynamically position relative to the Minimap button
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -5)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, -5)
		end
	elseif isSubmenu then
		-- Adjust the positioning to anchor the submenu to the specific button (anchorFrame)
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 10, -60)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -10, -60)
		end
	else
		-- Fallback positioning for any other cases
		if isLeftHalf then
			self:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, -85)
		else
			self:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -10, -85)
		end
	end

	self:Show()
end


function RQE_MenuMixin:HideMenu()
	self:Hide()
end


function RQE_MenuMixin:ToggleMenu(anchorFrame)
	if self:IsShown() then
		self:HideMenu()
	else
		self:ShowMenu(anchorFrame)
	end
end


-- Create the Dropdown Menu Function
function RQE:ShowLDBDropdownMenu()
	GameTooltip:Hide()

	if not self.CustomMenu then
		self.CustomMenu = CreateFrame("Frame", "RQECustomMenu", UIParent, "BackdropTemplate")
		Mixin(self.CustomMenu, RQE_MenuMixin)
		self.CustomMenu:OnLoad()
		self.CustomMenu:SetSize(150, 100)
		self.CustomMenu:SetFrameStrata("DIALOG")
		self.CustomMenu:Hide()

		-- Keep menu visible when mouse is over it
		self.CustomMenu:SetScript("OnEnter", function(self)
			self:Show()
		end)

		self.CustomMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				-- Check if the frame exists before calling MouseIsOver
				if (self and MouseIsOver(self)) or (RQE.MoreOptionsMenu and MouseIsOver(RQE.MoreOptionsMenu)) then
					-- Do nothing, the mouse is still over the menu or its related submenus
					return
				end

				-- Hide the menus if the mouse is not over them
				self:Hide()
				if RQE.MoreOptionsMenu then RQE.MoreOptionsMenu:Hide() end
			end)
		end)
	end

	-- Ensure buttons are only added once
	if #self.CustomMenu.buttons == 0 then
		self.CustomMenu:AddButton("Toggle Frame(s)", function() RQE.ToggleBothFramesfromLDB() end)
		self.CustomMenu:AddButton("AddOn Settings", function() RQE:OpenSettings() end)
		self.CustomMenu:AddButton("Config Window", function() RQE:ToggleConfigFrame() end)
		self.CustomMenu:AddButton("Debug Log", function() RQE:ToggleDebugLog() end)
		-- self.CustomMenu:AddButton("More Options", function() RQE:ShowMoreOptionsMenu(self.CustomMenu) end, true)	-- THIS IS BEING COMMENTED OUT AS THE SUBCATEGORIES FOR THE IN-GAME CONFIG OPTIONS ARE NOT WORKING YET
	end

	-- Determine the actual frame object
	local anchorFrame = RQE.lastClickedFrame

	if anchorFrame then
		-- Toggle menu visibility using the dynamically determined anchor
		self.CustomMenu:ToggleMenu(anchorFrame)
	end
end


-- More Options Menu Creation
function RQE:ShowMoreOptionsMenu(parentMenu)
	if not self.MoreOptionsMenu then
		self.MoreOptionsMenu = CreateFrame("Frame", "RQEMoreOptionsMenu", UIParent, "BackdropTemplate")
		Mixin(self.MoreOptionsMenu, RQE_MenuMixin)
		self.MoreOptionsMenu:OnLoad()
		self.MoreOptionsMenu:SetSize(150, 100)
		self.MoreOptionsMenu:SetFrameStrata("DIALOG")
		self.MoreOptionsMenu:Hide()

		-- Keep submenu visible when mouse is over it
		self.MoreOptionsMenu:SetScript("OnEnter", function(self)
			self:Show()
			parentMenu:Show()
		end)
		self.MoreOptionsMenu:SetScript("OnLeave", function(self)
			C_Timer.After(0.1, function()
				if not MouseIsOver(self) and not MouseIsOver(parentMenu) then
					self:Hide()
					parentMenu:Hide()
				end
			end)
		end)
	end

	-- Ensure buttons are only added once
	if #self.MoreOptionsMenu.buttons == 0 then
		self.MoreOptionsMenu:AddButton("Frame Settings", function() RQE:OpenFrameSettings() end)
		self.MoreOptionsMenu:AddButton("Font Settings", function() RQE:OpenFontSettings() end)
		self.MoreOptionsMenu:AddButton("Debug Options", function() RQE:OpenDebugOptions() end)
		self.MoreOptionsMenu:AddButton("Profiles", function() RQE:OpenProfiles() end)
		self.MoreOptionsMenu:AddButton("Config Window", function() RQE:ToggleConfigFrame() end)
	end

	-- Toggle More Options menu visibility
	self.MoreOptionsMenu:ClearAllPoints()
	self.MoreOptionsMenu:SetPoint("TOPLEFT", parentMenu, "TOPRIGHT", 0, 0) -- Adjust this to desired position
	self.MoreOptionsMenu:ToggleMenu(parentMenu, true)
end