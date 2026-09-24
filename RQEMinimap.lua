--[[ 

RQEMinimap.lua
LibDataBroker launcher, minimap button, frame toggles, and dropdown menus

]]


--------------------------------------------------
-- #1. 🌐 Namespace & Minimap State
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Addon Namespace & Hover Timers
	-------------------------------------------------------

	RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
	RQE.Frame = RQE.Frame or {}
	RQE.hoverTimers = {}

	-------------------------------------------------------
	-- #1b. Client Mode & Minimap Button Type
	-------------------------------------------------------

	local isRetail = RQE.IsRetail == true

	---@class RQEMinimapButton : Frame
	---@field hoverTimer any
	local RQEMinimapButton = {}

--------------------------------------------------
-- #2. 🛠️ Bootstrap Diagnostics
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Debug Logger Availability
	-------------------------------------------------------

	if RQE and RQE.debugLog then
		RQE.debugLog("Message here")
	else
		RQE.debugLog("RQE or RQE.debugLog is not initialized.")
	end

--------------------------------------------------
-- #3. 🧰 Shared Launcher Actions & Pointer Helpers
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Debug Log & Settings Actions
	-------------------------------------------------------

	-- Toggle Debug Log window function
	function RQE:ToggleDebugLog()
		local debugLogFrame = RQE.DebugLogFrameRef
		if debugLogFrame and debugLogFrame:IsShown() then
			debugLogFrame:Hide()
		elseif RQE.DebugLogFrame then
			RQE.DebugLogFrame()
		end
	end

	-- Open AddOn Settings function
	function RQE:OpenSettings()
		if RQE.ConfigUI and RQE.ConfigUI.OpenRegisteredPanel then
			RQE.ConfigUI:OpenRegisteredPanel("general")
		end
	end

	-------------------------------------------------------
	-- #3b. Pointer Detection & Menu Dismissal
	-------------------------------------------------------

	-- Function to safely determine whether the pointer is over a visible frame
	local function isPointerOver(frame)
		if not frame or not frame.IsShown or not frame:IsShown() then return false end
		if isRetail and frame.IsMouseOver then
			return frame:IsMouseOver()
		end
		return MouseIsOver and MouseIsOver(frame) or false
	end

	-- Function to close the main launcher menu and any open More Options submenu
	function RQE:HideLDBDropdownMenus()
		if self.CustomMenu then
			self.CustomMenu.RQEOutsideTime = 0
			self.CustomMenu:Hide()
		end
		if self.MoreOptionsMenu then self.MoreOptionsMenu:Hide() end
	end


--------------------------------------------------
-- #4. 📡 LibDataBroker Launcher
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Broker Object & Mouse Interaction
	-------------------------------------------------------

	local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

	-- Updated LDB Button OnClick Function
	local RQEdataBroker = ldb:NewDataObject("RQE", {
		type = "launcher",
		icon = "Interface\\Addons\\RQE\\Textures\\rhodan.tga",
		-- Handles launcher clicks for frame visibility, logging, settings, and menus
		OnClick = function(display, button)

			if IsShiftKeyDown() and button == "LeftButton" then
				RQE:ToggleDebugLog()

			elseif button == "LeftButton" then
				RQE.ToggleBothFramesfromLDB()

			elseif button == "RightButton" and IsShiftKeyDown() then
				RQE:OpenSettings()

			elseif button == "RightButton" then
				RQE.lastClickedFrame = display  -- Use the actual LDB display that was clicked.
				RQE:ShowLDBDropdownMenu()
			end
		end,

		-- Starts the hover-open timer and displays the launcher control tooltip
		OnEnter = function(display)
			RQE.lastClickedFrame = display
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

		-- Cancels pending hover work and hides the launcher tooltip
		OnLeave = function(display)
			if RQE.hoverTimers[display] then
				RQE:CancelTimer(RQE.hoverTimers[display])
				RQE.hoverTimers[display] = nil
			end
			GameTooltip:Hide()
		end,
	})


	-------------------------------------------------------
	-- #4b. Combined Frame Toggle
	-------------------------------------------------------

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
				RQE._currentTomTomUID = nil
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

		C_Timer.After(0.1, function()
			if RQE.db.profile.enableFrame then
				RQE:RestoreSuperTrackedQuestForCharacter()
			else
				local isSuperTracking = RQE.API.IsSuperTrackingQuest()

				if not RQE.isSuperTracking or not isSuperTracking then
					RQE.Buttons.ClearButtonPressed()
				end
			end
		end)
	end


--------------------------------------------------
-- #5. 🧭 Minimap Button Construction & Position
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Frame, Texture & Hover Appearance
	-------------------------------------------------------

	-- Creates the Minimap Button
	RQE.MinimapButton = CreateFrame("Frame", "RQEMinimapButton", Minimap)
	RQE.MinimapButton:SetSize(25, 25)

	local tex = RQE.MinimapButton:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\Addons\\RQE\\Textures\\rhodan-minimap.tga")
	RQE.MinimapButton.texture = tex

	-- Optional highlight on mouseover
	RQE.MinimapButton:EnableMouse(true)
	RQE.MinimapButton:SetScript("OnEnter", function(self)
		tex:SetVertexColor(1, 1, 1, 1) -- normal
	end)
	RQE.MinimapButton:SetScript("OnLeave", function(self)
		tex:SetVertexColor(0.8, 0.8, 0.8, 1) -- dimmed highlight
	end)

	RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
	RQE.MinimapButton:SetFrameStrata("MEDIUM")
	RQE.MinimapButton:SetFrameLevel(8)


	-------------------------------------------------------
	-- #5b. Drag Registration & Perimeter Positioning
	-------------------------------------------------------

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


--------------------------------------------------
-- #6. 🖱️ Minimap Button Interaction Scripts
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Click Actions
	-------------------------------------------------------

	-- Register Minimap Button OnClick Function
	RQE.MinimapButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				RQE:ToggleDebugLog()  -- Shift + Left Click
			else
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


	-------------------------------------------------------
	-- #6b. Tooltip Hover Behavior
	-------------------------------------------------------

	-- Function that handles the OnEnter for the MinimapButton
	RQE.MinimapButton:SetScript("OnEnter", function(self)
		RQE.lastClickedFrame = self
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


	-------------------------------------------------------
	-- #6c. Dragging & Position Persistence
	-------------------------------------------------------

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


--------------------------------------------------
-- #7. 📋 Dropdown Menu Mixins & Construction
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Button & Menu Mixin Setup
	-------------------------------------------------------

	-- Custom Mixin for Buttons & Menus
	RQE_ButtonMixin = {}

	-- Function to apply the shared normal, highlighted, and pressed button styling
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


	-- Placeholder function available for menu buttons without a specialized click handler
	function RQE_ButtonMixin:OnClick()
		-- Placeholder for button click handling
	end


	-- Custom Mixin for Menus
	RQE_MenuMixin = {}


	-- Function to initialize a menu frame's button list and backdrop styling
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


	-------------------------------------------------------
	-- #7b. Menu Button & Visibility Lifecycle
	-------------------------------------------------------

	-- Function to add one uniquely labeled action or submenu button to the menu
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
		local anchorX = anchorFrame:GetCenter()

		local isLeftHalf = anchorX < (screenWidth / 2)

		-- LDB displays have different frame names across broker bars. Anchor the
		-- main menu to the actual clicked display, just as for the minimap button.
		if not isSubmenu then
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
		end

		self:Show()
	end


	-- Function to hide the current menu frame
	function RQE_MenuMixin:HideMenu()
		self:Hide()
	end


	-- Function to toggle the menu relative to the supplied launcher anchor
	function RQE_MenuMixin:ToggleMenu(anchorFrame)
		if self:IsShown() then
			self:HideMenu()
		else
			self:ShowMenu(anchorFrame)
		end
	end


	-------------------------------------------------------
	-- #7c. Main Launcher Dropdown
	-------------------------------------------------------

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
					local isMouseOverMenu
					local isMouseOverMoreOptions
					if isRetail then
						isMouseOverMenu = self and self:IsMouseOver()
						isMouseOverMoreOptions = RQE.MoreOptionsMenu and RQE.MoreOptionsMenu:IsMouseOver()
					else
						isMouseOverMenu = self and MouseIsOver(self)
						isMouseOverMoreOptions = RQE.MoreOptionsMenu and MouseIsOver(RQE.MoreOptionsMenu)
					end
					if isMouseOverMenu or isMouseOverMoreOptions then
						-- Do nothing, the mouse is still over the menu or its related submenus
						return
					end

					-- Hide the menus if the mouse is not over them
					self:Hide()
					if RQE.MoreOptionsMenu then RQE.MoreOptionsMenu:Hide() end
				end)
			end)

			-- Parent-frame OnLeave is not reliable after the pointer crosses a child
			-- button.  Track the complete menu and its anchor while visible so the
			-- menu always dismisses shortly after the pointer leaves both regions.
			self.CustomMenu:SetScript("OnUpdate", function(menu, elapsed)
				if isPointerOver(menu) or isPointerOver(RQE.lastClickedFrame) or isPointerOver(RQE.MoreOptionsMenu) then
					menu.RQEOutsideTime = 0
					return
				end
				menu.RQEOutsideTime = (menu.RQEOutsideTime or 0) + elapsed
				if menu.RQEOutsideTime >= 0.2 then
					RQE:HideLDBDropdownMenus()
				end
			end)
		end

		-- Ensure buttons are only added once
		if #self.CustomMenu.buttons == 0 then
			self.CustomMenu:AddButton("Toggle Frame(s)", function() RQE:HideLDBDropdownMenus(); RQE.ToggleBothFramesfromLDB() end)
			self.CustomMenu:AddButton("AddOn Settings", function() RQE:HideLDBDropdownMenus(); RQE:OpenSettings() end)
			self.CustomMenu:AddButton("Config Window", function() RQE:HideLDBDropdownMenus(); RQE:ToggleConfigFrame() end)
			self.CustomMenu:AddButton("Debug Log", function() RQE:HideLDBDropdownMenus(); RQE:ToggleDebugLog() end)
		end

		-- Determine the actual frame object
		local anchorFrame = RQE.lastClickedFrame

		if anchorFrame then
			-- Toggle menu visibility using the dynamically determined anchor
			self.CustomMenu:ToggleMenu(anchorFrame)
		end
	end


	-------------------------------------------------------
	-- #7d. More Options Submenu
	-------------------------------------------------------

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
					local isMouseOverMenu
					local isMouseOverParent
					if isRetail then
						isMouseOverMenu = self:IsMouseOver()
						isMouseOverParent = parentMenu:IsMouseOver()
					else
						isMouseOverMenu = MouseIsOver(self)
						isMouseOverParent = MouseIsOver(parentMenu)
					end
					if not isMouseOverMenu and not isMouseOverParent then
						self:Hide()
						parentMenu:Hide()
					end
				end)
			end)
		end

		-- Ensure buttons are only added once
		if #self.MoreOptionsMenu.buttons == 0 then
			self.MoreOptionsMenu:AddButton("Frame Settings", function() RQE:HideLDBDropdownMenus(); RQE:OpenFrameSettings() end)
			self.MoreOptionsMenu:AddButton("Font Settings", function() RQE:HideLDBDropdownMenus(); RQE:OpenFontSettings() end)
			self.MoreOptionsMenu:AddButton("Debug Options", function() RQE:HideLDBDropdownMenus(); RQE:OpenDebugOptions() end)
			self.MoreOptionsMenu:AddButton("Profiles", function() RQE:HideLDBDropdownMenus(); RQE:OpenProfiles() end)
			self.MoreOptionsMenu:AddButton("Config Window", function() RQE:HideLDBDropdownMenus(); RQE:ToggleConfigFrame() end)
		end

		-- Toggle More Options menu visibility
		self.MoreOptionsMenu:ClearAllPoints()
		self.MoreOptionsMenu:SetPoint("TOPLEFT", parentMenu, "TOPRIGHT", 0, 0) -- Adjust this to desired position
		self.MoreOptionsMenu:ToggleMenu(parentMenu, true)
	end
