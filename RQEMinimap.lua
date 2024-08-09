-- RQEMinimap.lua
-- Creates minimap button that will toggle the RQEFrame

---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}
RQE.hoverTimers = {}

---@class RQEMinimapButton : Frame
---@field hoverTimer any
local RQEMinimapButton = {}

---------------------------
-- 2. Debug Logic
---------------------------

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
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

RQE.dataBroker = ldb:NewDataObject("RQE", {
    type = "launcher",
    icon = "Interface\\Addons\\RQE\\Textures\\rhodan.tga",
    OnClick = function(_, button)
        if button == "RightButton" then
            RQE:ShowLDBDropdownMenu()
        elseif IsShiftKeyDown() and button == "LeftButton" then
            RQE:ToggleDebugLog()
        elseif button == "LeftButton" then
            if RQEFrame:IsShown() then
                RQEFrame:Hide()
                if RQE.MagicButton then
                    RQE.MagicButton:Hide()
                end
                RQE.RQEQuestFrame:Hide()
                RQE.isRQEFrameManuallyClosed = true
                RQE.isRQEQuestFrameManuallyClosed = true
                RQE.Buttons.UpdateMagicButtonVisibility()
            else
                RQE:ClearFrameData()
                RQE:ClearWaypointButtonData()
                RQEFrame:Show()
                UpdateFrame()
                if RQE.MagicButton then
                    RQE.MagicButton:Show()
                end
                if RQE.db.profile.enableQuestFrame then
                    RQE.RQEQuestFrame:Show()
                end
                RQE.isRQEFrameManuallyClosed = false
                RQE.isRQEQuestFrameManuallyClosed = false
                RQE.Buttons.UpdateMagicButtonVisibility()
            end
        end
    end,

    OnEnter = function(display)
        if RQE.hoverTimers[display] then
            RQE:CancelTimer(RQE.hoverTimers[display])
        end
        RQE.hoverTimers[display] = RQE:ScheduleTimer(function()
            RQE:ShowLDBDropdownMenu()
        end, 1.5)
        
        GameTooltip:SetOwner(display, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOMLEFT", display, "TOPRIGHT")
        RQE.dataBroker.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end,

    OnLeave = function(display)
        if RQE.hoverTimers[display] then
            RQE:CancelTimer(RQE.hoverTimers[display])
            RQE.hoverTimers[display] = nil
        end
        GameTooltip:Hide()
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Rhodan's Quest Explorer")
        tooltip:AddLine("Left-click to toggle frame.")
        tooltip:AddLine("Right-click to Settings.")
        tooltip:AddLine("Shift+Left-click to toggle Debug Log.")
    end,
})

function RQE.ToggleBothFramesfromLDB()
    if RQEFrame:IsShown() then
        RQEFrame:Hide()
        if RQE.MagicButton then
            RQE.MagicButton:Hide()
        end
        RQE.RQEQuestFrame:Hide()
        RQE.isRQEFrameManuallyClosed = true
        RQE.isRQEQuestFrameManuallyClosed = true
    else
        RQE:ClearFrameData()
        RQE:ClearWaypointButtonData()
        if RQE.db.profile.enableFrame then
            RQEFrame:Show()
            if RQE.MagicButton then
                RQE.MagicButton:Show()
            end
        end
        if RQE.db.profile.enableQuestFrame then
            RQE.RQEQuestFrame:Show()
        end
        RQE.isRQEFrameManuallyClosed = false
        RQE.isRQEQuestFrameManuallyClosed = false
        RQE.Buttons.UpdateMagicButtonVisibility()
    end
end

---------------------------
-- 5. Minimap Button
---------------------------

RQE.MinimapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
RQE.MinimapButton:SetSize(25, 25)
RQE.MinimapButton:SetNormalTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetHighlightTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPushedTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)

---------------------------
-- 6. Event Handler
---------------------------

RQE.MinimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        RQE:ShowLDBDropdownMenu()
    elseif button == "LeftButton" then
        if RQEFrame:IsShown() then
            RQEFrame:Hide()
            if RQE.MagicButton then
                RQE.MagicButton:Hide()
            end
        else
            RQEFrame:Show()
            if RQE.MagicButton then
                RQE.MagicButton:Show()
            end
            RQE.RQEQuestFrame:Show()
        end
        RQE.Buttons.UpdateMagicButtonVisibility()
    end
end)

RQE.MinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Rhodan's Quest Explorer", 1, 1, 1)
    GameTooltip:AddLine("Left-click to toggle frame.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)

RQE.MinimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

---------------------------
-- 7. Menu Creation Functions
---------------------------

-- function RQE:ShowLDBDropdownMenu()
    -- local menuFrame = CreateFrame("Frame", "RQEDropDownMenu", UIParent, "UIDropDownMenuTemplate")
    -- UIDropDownMenu_Initialize(menuFrame, function(self, level, menuList)
        -- local info = UIDropDownMenu_CreateInfo()
        -- if level == 1 then
            -- info.text, info.isTitle, info.notCheckable = "Menu", true, true
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Toggle Frame(s)", true
            -- info.func = function() RQE.ToggleBothFramesfromLDB() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "AddOn Settings", true
            -- info.func = function() RQE:OpenSettings() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Debug Log", true
            -- info.func = function() RQE:ToggleDebugLog() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.hasArrow, info.notCheckable = "More Options", true, true
            -- info.menuList = "MoreOptionsMenu"
            -- UIDropDownMenu_AddButton(info, level)
        -- elseif menuList == "MoreOptionsMenu" then
            -- -- After adding the buttons, adjust the position of the More Options submenu
            -- C_Timer.After(0.1, function()
                -- local dropdownList = _G["DropDownList2"]  -- DropDownList2 is usually the second level menu
                -- local mainDropdownList = _G["DropDownList1"]  -- DropDownList1 is the main menu

                -- if dropdownList and mainDropdownList then
                    -- dropdownList:ClearAllPoints()
                    -- -- Anchor to the bottom left of the main menu with a slight offset down and to the right
                    -- dropdownList:SetPoint("TOPRIGHT", mainDropdownList, "BOTTOMLEFT", 10, -10)
                -- end
            -- end)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.isTitle, info.notCheckable = "More Options Menu", true, true
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Frame Settings", true
            -- info.func = function() RQE:OpenFrameSettings() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Font Settings", true
            -- info.func = function() RQE:OpenFontSettings() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Debug Options", true
            -- info.func = function() RQE:OpenDebugOptions() end
            -- UIDropDownMenu_AddButton(info, level)

            -- info = UIDropDownMenu_CreateInfo()
            -- info.text, info.notCheckable = "Profiles", true
            -- info.func = function() RQE:OpenProfiles() end
            -- UIDropDownMenu_AddButton(info, level)
        -- end
    -- end, "MENU")
    -- ToggleDropDownMenu(1, nil, menuFrame, "cursor", 3, -3)
-- end


-- function RQE:ShowLDBDropdownMenu()
	-- -- Create the main menu frame
	-- local menuFrame = CreateFrame("Frame", "RQECustomMenu", UIParent, "BackdropTemplate")
	-- menuFrame:SetSize(150, 140)  -- Increased height for more room
	-- -- Anchor the menu to the LDB button icon
	-- menuFrame:SetPoint("TOPRIGHT", "BazookaHL_RQE", "BOTTOMLEFT", -10, -5)
	-- menuFrame:SetBackdrop({
		-- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		-- edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		-- tile = true,
		-- tileSize = 16,
		-- edgeSize = 16,
		-- insets = { left = 4, right = 4, top = 4, bottom = 4 }
	-- })
	-- menuFrame:SetFrameStrata("DIALOG")
	-- menuFrame:SetFrameLevel(10)
	-- menuFrame:Hide()

    -- -- Function to toggle the visibility of the menu
    -- function menuFrame:Toggle()
        -- if self:IsShown() then
            -- self:Hide()
        -- else
            -- self:Show()
        -- end
    -- end

    -- -- Keep menu visible when mouse is over it
    -- menuFrame:SetScript("OnEnter", function(self)
        -- self:Show()
    -- end)
    -- menuFrame:SetScript("OnLeave", function(self)
        -- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
            -- if not MouseIsOver(self) then
                -- self:Hide()
            -- end
        -- end)
    -- end)

    -- -- Create the "Menu" title
    -- local title = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- title:SetPoint("TOP", menuFrame, "TOP", 0, -10)
    -- title:SetText("Menu")

    -- -- Create a button for toggling frames
    -- local toggleFramesButton = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
    -- toggleFramesButton:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 10, -30)
    -- toggleFramesButton:SetSize(130, 20)
    -- toggleFramesButton:SetText("Toggle Frame(s)")
    -- toggleFramesButton:SetScript("OnClick", function()
        -- RQE.ToggleBothFramesfromLDB()
    -- end)

    -- -- Keep menu visible when mouse is over buttons
    -- toggleFramesButton:SetScript("OnEnter", function(self)
        -- menuFrame:Show()
    -- end)
    -- toggleFramesButton:SetScript("OnLeave", function(self)
        -- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
            -- if not MouseIsOver(menuFrame) then
                -- menuFrame:Hide()
            -- end
        -- end)
    -- end)

	-- -- Create a button for AddOn settings
	-- local settingsButton = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
	-- settingsButton:SetPoint("TOPLEFT", toggleFramesButton, "BOTTOMLEFT", 0, -5)
	-- settingsButton:SetSize(130, 20)
	-- settingsButton:SetText("AddOn Settings")
	-- settingsButton:SetScript("OnClick", function()
		-- RQE:OpenSettings()
	-- end)
	-- settingsButton:SetScript("OnEnter", function(self)
		-- menuFrame:Show()
	-- end)
	-- settingsButton:SetScript("OnLeave", function(self)
		-- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
			-- if not MouseIsOver(menuFrame) then
				-- menuFrame:Hide()
			-- end
		-- end)
	-- end)

	-- -- Create a button for Debug Log
	-- local debugLogButton = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
	-- debugLogButton:SetPoint("TOPLEFT", settingsButton, "BOTTOMLEFT", 0, -5)
	-- debugLogButton:SetSize(130, 20)
	-- debugLogButton:SetText("Debug Log")
	-- debugLogButton:SetScript("OnClick", function()
		-- RQE:ToggleDebugLog()
	-- end)
	-- debugLogButton:SetScript("OnEnter", function(self)
		-- menuFrame:Show()
	-- end)
	-- debugLogButton:SetScript("OnLeave", function(self)
		-- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
			-- if not MouseIsOver(menuFrame) then
				-- menuFrame:Hide()
			-- end
		-- end)
	-- end)

    -- -- Create a button for the "More Options" submenu
    -- local moreOptionsButton = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
    -- moreOptionsButton:SetPoint("TOPLEFT", debugLogButton, "BOTTOMLEFT", 0, -5)
    -- moreOptionsButton:SetSize(130, 20)
    -- moreOptionsButton:SetText("More Options")
    -- moreOptionsButton:SetScript("OnClick", function()
        -- -- Create and show the More Options submenu
        -- local moreOptionsFrame = CreateFrame("Frame", "RQEMoreOptionsMenu", UIParent, "BackdropTemplate")
        -- moreOptionsFrame:SetSize(150, 120)
        -- moreOptionsFrame:SetPoint("TOPRIGHT", menuFrame, "BOTTOMLEFT", 10, -10)
        -- moreOptionsFrame:SetBackdrop({
            -- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            -- edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            -- tile = true,
            -- tileSize = 16,
            -- edgeSize = 16,
            -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
        -- })
        -- moreOptionsFrame:SetFrameStrata("DIALOG")
        -- moreOptionsFrame:SetFrameLevel(11)
        -- moreOptionsFrame:Show()

        -- -- Keep submenu visible when mouse is over it
        -- moreOptionsFrame:SetScript("OnEnter", function(self)
            -- menuFrame:Show()
            -- self:Show()
        -- end)
        -- moreOptionsFrame:SetScript("OnLeave", function(self)
            -- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
                -- if not MouseIsOver(self) and not MouseIsOver(menuFrame) then
                    -- self:Hide()
                    -- menuFrame:Hide()
                -- end
            -- end)
        -- end)

        -- -- Add buttons to the More Options submenu
        -- local function createMoreOptionsButton(text, onClick)
            -- local button = CreateFrame("Button", nil, moreOptionsFrame, "UIPanelButtonTemplate")
            -- button:SetSize(130, 20)
            -- button:SetText(text)
            -- button:SetScript("OnClick", function()
                -- onClick()
            -- end)
            -- return button
        -- end

        -- local frameSettingsButton = createMoreOptionsButton("Frame Settings", function() RQE:OpenFrameSettings() end)
        -- frameSettingsButton:SetPoint("TOPLEFT", moreOptionsFrame, "TOPLEFT", 10, -10)
        
        -- local fontSettingsButton = createMoreOptionsButton("Font Settings", function() RQE:OpenFontSettings() end)
        -- fontSettingsButton:SetPoint("TOPLEFT", frameSettingsButton, "BOTTOMLEFT", 0, -5)
        
        -- local debugOptionsButton = createMoreOptionsButton("Debug Options", function() RQE:OpenDebugOptions() end)
        -- debugOptionsButton:SetPoint("TOPLEFT", fontSettingsButton, "BOTTOMLEFT", 0, -5)
        
        -- local profilesButton = createMoreOptionsButton("Profiles", function() RQE:OpenProfiles() end)
        -- profilesButton:SetPoint("TOPLEFT", debugOptionsButton, "BOTTOMLEFT", 0, -5)

        -- -- Keep the submenu visible when hovering over its buttons
        -- local buttons = {frameSettingsButton, fontSettingsButton, debugOptionsButton, profilesButton}
        -- for _, button in ipairs(buttons) do
            -- button:SetScript("OnEnter", function(self)
                -- menuFrame:Show()
                -- moreOptionsFrame:Show()
            -- end)
            -- button:SetScript("OnLeave", function(self)
                -- C_Timer.After(0.3, function()  -- Increased delay for more tolerance
                    -- if not MouseIsOver(self) and not MouseIsOver(menuFrame) and not MouseIsOver(moreOptionsFrame) then
                        -- menuFrame:Hide()
                        -- moreOptionsFrame:Hide()
                    -- end
                -- end)
            -- end)
        -- end
    -- end)

    -- -- Toggle the main menu visibility
    -- menuFrame:Toggle()
-- end





-- RQE_CustomMenuMixin = {};

-- function RQE_CustomMenuMixin:OnLoad()
    -- self.buttons = {};
    -- self.menuWidth = 150;  -- Define the default width for the menu
    -- self.buttonHeight = 20;
-- end

-- function RQE_CustomMenuMixin:AddButton(text, onClick)
    -- local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
    -- button:SetSize(self.menuWidth - 20, self.buttonHeight);
    -- button:SetText(text);
    -- button:SetScript("OnClick", onClick);

    -- if #self.buttons == 0 then
        -- button:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -30);
    -- else
        -- button:SetPoint("TOPLEFT", self.buttons[#self.buttons], "BOTTOMLEFT", 0, -5);
    -- end

    -- table.insert(self.buttons, button);

    -- -- Update the menu size dynamically
    -- self:SetHeight(#self.buttons * (self.buttonHeight + 5) + 40);
-- end

-- function RQE_CustomMenuMixin:ShowMenu(anchorFrame)
    -- self:ClearAllPoints();
    -- self:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMLEFT", -10, -5);
    -- self:Show();
-- end

-- function RQE_CustomMenuMixin:HideMenu()
    -- self:Hide();
-- end

-- function RQE_CustomMenuMixin:ToggleMenu(anchorFrame)
    -- if self:IsShown() then
        -- self:HideMenu();
    -- else
        -- self:ShowMenu(anchorFrame);
    -- end
-- end


-- function RQE:ShowLDBDropdownMenu()
    -- -- Create or get the custom menu frame
    -- if not self.CustomMenu then
        -- self.CustomMenu = CreateFrame("Frame", "RQECustomMenu", UIParent, "BackdropTemplate");
        -- Mixin(self.CustomMenu, RQE_CustomMenuMixin);
        -- self.CustomMenu:OnLoad();
        -- self.CustomMenu:SetBackdrop({
            -- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            -- edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            -- tile = true,
            -- tileSize = 16,
            -- edgeSize = 16,
            -- insets = { left = 4, right = 4, top = 4, bottom = 4 },
        -- });
        -- self.CustomMenu:SetBackdropColor(0, 0, 0, 0.9);
        -- self.CustomMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1);
        -- self.CustomMenu:SetWidth(self.CustomMenu.menuWidth);
        -- self.CustomMenu:Hide();
    -- end

    -- -- Add buttons to the menu
    -- self.CustomMenu:AddButton("Toggle Frame(s)", function() RQE.ToggleBothFramesfromLDB() end);
    -- self.CustomMenu:AddButton("AddOn Settings", function() RQE:OpenSettings() end);
    -- self.CustomMenu:AddButton("Debug Log", function() RQE:ToggleDebugLog() end);
    -- self.CustomMenu:AddButton("More Options", function() RQE:ShowMoreOptionsMenu(self.CustomMenu) end);

    -- -- Toggle the menu visibility
    -- self.CustomMenu:ToggleMenu("BazookaHL_RQE");
-- end

-- function RQE:ShowMoreOptionsMenu(parentMenu)
    -- -- Create or get the More Options menu frame
    -- if not self.MoreOptionsMenu then
        -- self.MoreOptionsMenu = CreateFrame("Frame", "RQEMoreOptionsMenu", UIParent, "BackdropTemplate");
        -- Mixin(self.MoreOptionsMenu, RQE_CustomMenuMixin);
        -- self.MoreOptionsMenu:OnLoad();
        -- self.MoreOptionsMenu:SetBackdrop({
            -- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            -- edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            -- tile = true,
            -- tileSize = 16,
            -- edgeSize = 16,
            -- insets = { left = 4, right = 4, top = 4, bottom = 4 },
        -- });
        -- self.MoreOptionsMenu:SetBackdropColor(0, 0, 0, 0.9);
        -- self.MoreOptionsMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1);
        -- self.MoreOptionsMenu:SetWidth(self.MoreOptionsMenu.menuWidth);
        -- self.MoreOptionsMenu:Hide();
    -- end

    -- -- Add buttons to the More Options menu
    -- self.MoreOptionsMenu:AddButton("Frame Settings", function() RQE:OpenFrameSettings() end);
    -- self.MoreOptionsMenu:AddButton("Font Settings", function() RQE:OpenFontSettings() end);
    -- self.MoreOptionsMenu:AddButton("Debug Options", function() RQE:OpenDebugOptions() end);
    -- self.MoreOptionsMenu:AddButton("Profiles", function() RQE:OpenProfiles() end);

    -- -- Toggle the More Options menu visibility
    -- self.MoreOptionsMenu:ToggleMenu(parentMenu);
-- end


-- Custom Mixin for Buttons
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


function RQE_MenuMixin:ShowMenu(anchorFrame, isSubmenu)
    self:ClearAllPoints()

    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    local anchorX, anchorY = anchorFrame:GetCenter()

    -- Determine the quadrant based on anchor frame's position
    local isTopHalf = anchorY > (screenHeight / 2)
    local isLeftHalf = anchorX < (screenWidth / 2)

    if isSubmenu then
        -- Submenu positioning based on the quadrant
        if isTopHalf and isLeftHalf then
            -- Top-left quadrant
            self:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, 0)
        elseif isTopHalf and not isLeftHalf then
            -- Top-right quadrant
            self:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -10, 0)
        elseif not isTopHalf and isLeftHalf then
            -- Bottom-left quadrant
            self:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", 10, 0)
        elseif not isTopHalf and not isLeftHalf then
            -- Bottom-right quadrant
            self:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMLEFT", -10, 0)
        end
    else
        -- Main menu positioning based on screen boundaries
        if isLeftHalf then
            self:SetPoint("TOPLEFT", anchorFrame, "BOTTOMRIGHT", 10, -10)
        else
            self:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMLEFT", -10, -10)
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
                if not MouseIsOver(self) and not MouseIsOver(RQE.MoreOptionsMenu) then
                    self:Hide()
                    if RQE.MoreOptionsMenu then RQE.MoreOptionsMenu:Hide() end
                end
            end)
        end)
    end
    
    -- Ensure buttons are only added once
    if #self.CustomMenu.buttons == 0 then
        self.CustomMenu:AddButton("Toggle Frame(s)", function() RQE.ToggleBothFramesfromLDB() end)
        self.CustomMenu:AddButton("AddOn Settings", function() RQE:OpenSettings() end)
        self.CustomMenu:AddButton("Debug Log", function() RQE:ToggleDebugLog() end)
        self.CustomMenu:AddButton("More Options", function() RQE:ShowMoreOptionsMenu(self.CustomMenu) end, true)
    end
    
    -- Retrieve the actual frame object
    local anchorFrame = _G["BazookaHL_RQE"]
    if anchorFrame then
        -- Toggle menu visibility
        self.CustomMenu:ToggleMenu(anchorFrame)
    else
        print("Error: BazookaHL_RQE frame not found.")
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
    end
    
    -- Toggle More Options menu visibility
    self.MoreOptionsMenu:ToggleMenu(parentMenu, true)
end


---------------------------
-- 8. Drag n Drop Functions
---------------------------

RQE.MinimapButton:SetMovable(true)
RQE.MinimapButton:EnableMouse(true)

-- Enable mouse input propagation
RQE.MinimapButton:SetPropagateMouseClicks(true)
RQE.MinimapButton:SetPropagateMouseMotion(true)

RQE.MinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

RQE.MinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

RQE.MinimapButton:RegisterForDrag("LeftButton")
