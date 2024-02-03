-- RQEMinimap.lua
-- Creates minimap button that will toggle the RQEFrame


---------------------------
-- 1. Declarations
---------------------------

RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}


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
    -- Assuming RQE.DebugLogFrame is the frame for your debug log window
    if not RQE.DebugLogFrame then
        -- Initialize the debug log frame here if it doesn't exist yet
        -- Example: RQE.DebugLogFrame = CreateFrame("Frame", nil, UIParent)
        -- Add necessary frame setup here (size, position, appearance, etc.)
    end

    -- Check if the frame is currently shown or hidden
	RQE.DebugLogFrame()
end


-- Open Settings function (reuse your existing settings functionality)
function RQE:OpenSettings()
	Settings.OpenToCategory("Rhodan's Quest Explorer")
end


-- Create the dropdown menu
local function CreateDropdownMenu()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Debug Log"
    info.func = ToggleDebugLog
    UIDropDownMenu_AddButton(info)

    info.text = "Settings"
    info.func = OpenSettings
    UIDropDownMenu_AddButton(info)
end


---------------------------
-- 4. Data Broker Handling
---------------------------

-- Assuming RQE is your main addon table
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

-- Create a Data Broker object
RQE.dataBroker = ldb:NewDataObject("RQE", {
    type = "launcher",
	icon = "Interface\\Addons\\RQE\\Textures\\rhodan.tga",  -- Replace with your own icon
    OnClick = function(_, button)
		if IsShiftKeyDown() and button == "LeftButton" then
			-- Show config settings
			RQE:ToggleDebugLog()
			
		elseif button == "LeftButton" then
			-- Existing code for left button click, likely toggling your main frame
			if RQEFrame:IsShown() then
				RQEFrame:Hide()
				RQEQuestFrame:Hide()
			else
				RQE:ClearFrameData() -- Clears frame data when showing the RQEFrame from a hidden setting
				RQEFrame:Show()
				-- Check if enableQuestFrame is true before showing RQEQuestFrame
                if RQE.db.profile.enableQuestFrame then
                    RQEQuestFrame:Show()
                end
			end
			
		elseif button == "RightButton" then
			RQE:OpenSettings()
		end
	end,
	
    OnEnter = function(display)
        if display.hoverTimer then
            RQE:CancelTimer(display.hoverTimer)
        end
        display.hoverTimer = RQE:ScheduleTimer(function()
            RQE:ShowLDBDropdownMenu()
        end, 1.5)  -- 1.5 seconds hover delay
		
	GameTooltip:SetOwner(display, "ANCHOR_NONE")  -- You can change ANCHOR_NONE to another anchor type if needed.
	GameTooltip:SetPoint("BOTTOMLEFT", display, "TOPRIGHT")  -- Adjust this to position the tooltip as desired.
	RQE.dataBroker.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
    end,
	
    OnLeave = function(display)
        if display.hoverTimer then
            RQE:CancelTimer(display.hoverTimer)
            display.hoverTimer = nil
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


-- Function for the toggling of RQEFrame and RQEQuestFrame
function RQE.ToggleBothFramesfromLDB()
	if RQEFrame:IsShown() then
		RQEFrame:Hide()
		RQEQuestFrame:Hide()
	else
		RQE:ClearFrameData() -- Clears frame data when showing the RQEFrame from a hidden setting
		RQEFrame:Show()
		-- Check if enableQuestFrame is true before showing RQEQuestFrame
		if RQE.db.profile.enableQuestFrame then
			RQEQuestFrame:Show()
		end
	end
end


---------------------------
-- 5. Minimap Button
---------------------------

-- Create the minimap button frame
RQE.MinimapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
RQE.MinimapButton:SetSize(25, 25)  -- Set the size of the frame

-- Set up the texture for the button
RQE.MinimapButton:SetNormalTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetHighlightTexture("Interface\\Addons\\RQE\\Textures\\rhodan")
RQE.MinimapButton:SetPushedTexture("Interface\\Addons\\RQE\\Textures\\rhodan")

-- Set the position of the minimap button
RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)


---------------------------
-- 6. Event Handler
---------------------------

-- OnClick handler
RQE.MinimapButton:SetScript("OnClick", function()
    if RQEFrame:IsShown() then
        RQEFrame:Hide()
    else
        RQEFrame:Show()
		RQEQuestFrame:Show()
    end
end)


-- Tooltip scripts
RQE.MinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Rhodan's Quest Explorer", 1, 1, 1)
    GameTooltip:AddLine("Left-click to toggle frame.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)


-- Function to toggle debug log
local function ToggleDebugLog()
    -- Assuming you have a function or a way to toggle the debug log
    RQE:ToggleDebugLog()  -- Replace with actual toggle function
end


---------------------------
-- 7. Menu Creation Functions
---------------------------

-- Function to show dropdown menu
function RQE:ShowLDBDropdownMenu()
    local menuFrame = CreateFrame("Frame", "RQE_LDBDropdownMenu", UIParent, "UIDropDownMenuTemplate")
    local menuList = {
        { text = "Toggle Frame(s)", func = function() RQE.ToggleBothFramesfromLDB() end },
        { text = "Settings", func = function() RQE:OpenSettings() end },
        { text = "Debug Log", func = function() RQE:ToggleDebugLog() end }
    }
    
    EasyMenu(menuList, menuFrame, "cursor", 0 , 0, "MENU")
end


---------------------------
-- 8. Drag n Drop Functions
---------------------------

-- Enabling movement of the Minimap button
RQE.MinimapButton:SetMovable(true)
RQE.MinimapButton:EnableMouse(true)

RQE.MinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

RQE.MinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

RQE.MinimapButton:RegisterForDrag("LeftButton")
