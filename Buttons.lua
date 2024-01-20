--[[ 

Buttons.lua
Manages button designs for the main frame

]]


---------------------------
-- 1. Global Declarations
---------------------------

RQE = RQE or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

RQE.Buttons = RQE.Buttons or {}
RQE.Frame = RQE.Frame or {}

RQE.debugLog("RQE.content initialized: " .. tostring(RQE.content ~= nil))

---------------------------
-- 2. Utility Functions
---------------------------

-- Function to show tooltips
local function ShowTooltip(self, text)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 33)
    GameTooltip:SetText(text)
    GameTooltip:Show()
end


-- Function to hide tooltips
local function HideTooltip()
    GameTooltip:Hide()
end


-- Local function to create tooltip using ShowTooltip and HideTooltip
local function CreateTooltip(button, text)
    button:SetScript("OnEnter", function(self) ShowTooltip(self, text) end)
    button:SetScript("OnLeave", HideTooltip)
end


-- Waypoint Buttons for Unlisted Quests (those not in the RQEDatabase)
-- Local function to create border
local function CreateBorder(button)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetColorTexture(1, 1, 1, 1)
	border:SetAlpha(0.25)  -- Set the alpha to 0.5 (50% opacity)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", -0.15, 0.15)
    border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0.15, -0.15)
end


-- Add mouseover tooltip and trigger map opening/closing
RQE.UnknownButtonTooltip = function()
    RQE.UnknownQuestButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")

        local unknownQuestID = C_SuperTrack.GetSuperTrackedQuestID()
        local mapID = GetQuestUiMapID(unknownQuestID)
        if mapID == 0 then mapID = nil end

        -- Check if the world map is initially open
        local isWorldMapOpenInitially = WorldMapFrame:IsShown()
        
        if not RQE.x or not RQE.y then
            -- If coordinates are not available, simulate the click behavior
            if mapID ~= nil and mapID ~= 0 then  -- Check if mapID is neither nil nor 0
                C_Timer.After(0.1, function()
                    if not isWorldMapOpenInitially then
                        WorldMapFrame:Hide()
                    end

                    -- Update tooltip text based on new coordinates
                    if RQE.x and RQE.y then
                        local tooltipText = string.format("Coordinates: (%.1f, %.1f) - MapID: %s", RQE.x * 100, RQE.y * 100, tostring(RQE.mapID))
                        GameTooltip:SetText(tooltipText)
                    else
                        GameTooltip:SetText("")
                    end

                    GameTooltip:Show()
                end)
            else
                GameTooltip:SetText("")
                GameTooltip:Show()
            end
        else
            -- If coordinates are already available, just show them
            local tooltipText = string.format("Coordinates: (%.1f, %.1f) - MapID: %s", RQE.x * 100, RQE.y * 100, tostring(RQE.mapID))
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end
    end)
end


-- Hide the tooltip when the mouse leaves
RQE.HideUnknownButtonTooltip = function()
    RQE.UnknownQuestButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end


-- Add a mouse down event to simulate a button press
RQE.UnknownQuestButtonMouseDown = function()
	RQE.UnknownQuestButton:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			RQE.bg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press
		end
	end)
end


-- Add a mouse up event to reset the texture
RQE.UnknownQuestButtonMouseUp = function()
	RQE.UnknownQuestButton:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			RQE.bg:SetAlpha(1)  -- Reset the alpha
		end
	end)
end


-- Add a mouse down event to simulate a button press
RQE.SearchGroupButtonMouseDown = function()
	RQE.SearchGroupButton:SetScript("OnMouseDown", function(self, button)
		RQE.sgbg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press

		if button == "LeftButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			if questID then
				RQE:LFG_Search(questID)
			end
		elseif button == "RightButton" then
			local questID = C_SuperTrack.GetSuperTrackedQuestID()
			RQE:LFG_Create(questID)
			-- Logic for creating a group
		end
	end)

	RQE.SearchGroupButton:SetScript("OnMouseUp", function(self, button)
		RQE.sgbg:SetAlpha(1)  -- Reset the alpha
	end)
end


---------------------------
-- 3. Button Initialization (RQEFrame)
---------------------------

-- Parent function to Create ClearButton
function RQE.Buttons.CreateClearButton(RQEFrame)
    local ClearButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
    ClearButton:SetSize(18, 18)
    ClearButton:SetText("C")
	RQE.ClearButton = ClearButton  -- Store reference for later use

    -- Set the frame strata and level
    ClearButton:SetFrameStrata("MEDIUM")
    ClearButton:SetFrameLevel(3)
	
    -- Nested functions
    ClearButton:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 6, -6)  -- Anchoring
    ClearButton:SetScript("OnClick", function() 
        -- Your code for ClearButton functionality here
		RQE:ClearFrameData()
    end)

    CreateTooltip(ClearButton, "Clear Window")  -- Tooltip
    CreateBorder(ClearButton)  -- Border
    
    return ClearButton
end


-- Parent function to Create ClearWQButton
function RQE.Buttons.ClearWQButton(RQEQuestFrame)
    local ClearWQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
    ClearWQButton:SetSize(18, 18)
    ClearWQButton:SetText("CT")
	RQE.ClearWQButton = ClearWQButton  -- Store reference for later use

    -- Set the frame strata and level
    ClearWQButton:SetFrameStrata("MEDIUM")
    ClearWQButton:SetFrameLevel(3)
	
    -- Nested functions
    ClearWQButton:SetPoint("TOPLEFT", RQEQuestFrame, "TOPLEFT", 6, -6)  -- Anchoring
    ClearWQButton:SetScript("OnClick", function() 
        -- Your code for ClearWQButton functionality here
		RQE:ClearWQTracking()
    end)

    CreateTooltip(ClearWQButton, "Reset WQ Tracking")  -- Tooltip
    CreateBorder(ClearWQButton)  -- Border
    
    return ClearWQButton
end


-- Parent function to create RWButton
function RQE.Buttons.CreateRWButton(RQEFrame)
    local RWButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
    RWButton:SetSize(18, 18)
    RWButton:SetText("RW")
	RQE.RWButton = RWButton

    -- Set the frame strata and level
    RWButton:SetFrameStrata("MEDIUM")
    RWButton:SetFrameLevel(3)
	
    -- Nested functions
    RWButton:SetPoint("TOPLEFT", RQE.ClearButton, "TOPRIGHT", 3, 0)  -- Anchoring
    RWButton:SetScript("OnClick", function() 
        -- Your code for RWButton functionality here
        C_Map.ClearUserWaypoint()
		if IsAddOnLoaded("TomTom") then
			TomTom.waydb:ResetProfile()
		end
    end)
	
    CreateTooltip(RWButton, "Remove Waypoints")
    CreateBorder(RWButton)
	
    return RWButton
end


-- Parent function to create SearchButton
function RQE.Buttons.CreateSearchButton(RQEFrame)
    local SearchButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
    SearchButton:SetSize(18, 18)
    SearchButton:SetText("S")
    RQE.SearchButton = SearchButton  -- Storing the reference in the RQE table

    -- Set the frame strata and level
    SearchButton:SetFrameStrata("MEDIUM")
    SearchButton:SetFrameLevel(3)
    
    -- Nested functions
    SearchButton:SetPoint("TOPLEFT", RQE.RWButton, "TOPRIGHT", 3, 0)  -- Anchoring
    SearchButton:SetScript("OnClick", function() 
        RQE.isSearchFrameShown = not RQE.isSearchFrameShown  -- Toggle the variable
        CreateSearchFrame(RQE.isSearchFrameShown)  -- Pass the updated variable
    end)
    
    CreateTooltip(SearchButton, "Search by Quest ID")
    CreateBorder(SearchButton)

    return SearchButton
end


-- Parent function to show/hide the QuestingModule frame
function RQE.Buttons.CreateQMButton(RQEFrame)
    local QMButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
    QMButton:SetSize(18, 18)
    QMButton:SetText("QF")
    RQE.QMButton = QMButton  -- Storing the reference in the RQE table

    -- Set the frame strata and level
    QMButton:SetFrameStrata("MEDIUM")
    QMButton:SetFrameLevel(3)
    
    -- Nested functions
    QMButton:SetPoint("TOPLEFT", RQE.SearchButton, "TOPRIGHT", 3, 0)  -- Anchoring
    QMButton:SetScript("OnClick", function()
        if RQE.RQEQuestFrame:IsShown() then
            RQE.RQEQuestFrame:Hide()
        else
            RQE.RQEQuestFrame:Show()
        end
    end)
    
    CreateTooltip(QMButton, "Show/Hide Quest Tracker")
    CreateBorder(QMButton)

    return QMButton
end


-- Parent function to create CloseButton
function RQE.Buttons.CreateCloseButton(RQEFrame)
	local CloseButton = CreateFrame("Button", nil, RQEFrame, "UIPanelCloseButton")
	CloseButton:SetSize(18, 18)
	RQE.CloseButton = CloseButton  -- Storing the reference in the RQE table

    -- Set the frame strata and level
    CloseButton:SetFrameStrata("MEDIUM") -- Strata makes it appear behind most frames except actionbars, but actionbars remain clickable despite appearance of UIPanelCloseButton icon "in front" of action bar
    CloseButton:SetFrameLevel(3)
	
    -- Nested functions
    CloseButton:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -6, -6)  -- Anchoring
    CloseButton:SetScript("OnClick", function(self, button)
        RQEFrame:Hide()
    end)
    CreateTooltip(CloseButton, "Close/Hide Frame")
    CreateBorder(CloseButton)
 
    return CloseButton
end


-- Parent function to Create MaximizeButton
function RQE.Buttons.CreateMaximizeButton(RQEFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
    local MaximizeButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	RQE.debugLog("CreateMaximizeButton: Function entered.")
    MaximizeButton:SetSize(18, 18)
    MaximizeButton:SetText("+")
    RQE.MaximizeButton = MaximizeButton  -- Store the reference in the RQE table

    -- Set the frame strata and level
    MaximizeButton:SetFrameStrata("MEDIUM")
    MaximizeButton:SetFrameLevel(3)
	
    MaximizeButton:SetPoint("TOPRIGHT", RQE.CloseButton, "TOPLEFT", -3, 0)
	
    MaximizeButton:SetScript("OnClick", function()
		RQE.debugLog("RQE.content after setting up MaximizeButton: " .. tostring(RQE.content ~= nil))
		RQE.debugLog("RQE.content inside button click: " .. tostring(RQE.content ~= nil))
        RQE.debugLog("Maximize button clicked")
    end)
    
    CreateTooltip(MaximizeButton, "Maximize")
    CreateBorder(MaximizeButton)
	
    RQE.debugLog("CreateMaximizeButton: Function exited.")
    return MaximizeButton
end


-- Parent function to Create MinimizeButton
function RQE.Buttons.CreateMinimizeButton(RQEFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
    local MinimizeButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
	RQE.debugLog("CreateMinimizeButton: Function entered.")
    MinimizeButton:SetSize(18, 18)
    MinimizeButton:SetText("-")
    RQE.MinimizeButton = MinimizeButton  -- Store the reference in the RQE table
	
    -- Set the frame strata and level
    MinimizeButton:SetFrameStrata("MEDIUM")
    MinimizeButton:SetFrameLevel(3)
	
    MinimizeButton:SetPoint("TOPRIGHT", RQE.MaximizeButton, "TOPLEFT", -3, 0)
	
    MinimizeButton:SetScript("OnClick", function()
		RQE.debugLog("RQE.content inside button click: " .. tostring(RQE.content ~= nil))
		RQE.db.profile.enableFrame = false
		RQE:ToggleRQEFrame()
    end)
    
    CreateTooltip(MinimizeButton, "Minimize")
    CreateBorder(MinimizeButton)
	
    RQE.debugLog("CreateMinimizeButton: Function exited.")    
    return MinimizeButton
end

---------------------------
-- 3. Button Initialization (RQEQuestFrame)
---------------------------

-- Parent function to create QTCloseButton for RQEQuestFrame
function RQE.Buttons.CreateQuestCloseButton(RQEQuestFrame)
    local QTCloseButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelCloseButton")
    QTCloseButton:SetSize(18, 18)
    RQE.QTQuestCloseButton = QTCloseButton  -- Storing the reference in the RQE table

    -- Set the frame strata and level
    QTCloseButton:SetFrameStrata("MEDIUM")
    QTCloseButton:SetFrameLevel(3)

    QTCloseButton:SetPoint("TOPRIGHT", RQEQuestFrame, "TOPRIGHT", -6, -6)
    QTCloseButton:SetScript("OnClick", function(self, button)
        RQEQuestFrame:Hide()
    end)
    CreateTooltip(QTCloseButton, "Close/Hide Quest Tracker")
    CreateBorder(QTCloseButton)

    return QTCloseButton
end

-- Parent function to Create QTMaximizeButton for RQEQuestFrame
function RQE.Buttons.CreateQuestMaximizeButton(RQEQuestFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
    local QTMaximizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
    QTMaximizeButton:SetSize(18, 18)
    QTMaximizeButton:SetText("+")
    RQE.QTQuestMaximizeButton = QTMaximizeButton  -- Store the reference in the RQE table

    -- Set the frame strata and level
    QTMaximizeButton:SetFrameStrata("MEDIUM")
    QTMaximizeButton:SetFrameLevel(3)

    QTMaximizeButton:SetPoint("TOPRIGHT", RQE.QTQuestCloseButton, "TOPLEFT", -3, 0)
    QTMaximizeButton:SetScript("OnClick", function()
		RQE.db.profile.enableQuestFrame = false
		RQE.RQEQuestFrame:Show()
		
		-- Set RQE.QTMinimized to false since we're maximizing the frame
		RQE.QTMinimized = false
		
        -- Restore the frame to its original size
        RQEQuestFrame:SetSize(RQE.QToriginalWidth, RQE.QToriginalHeight)
		RQE.QTScrollFrame:Show()
		RQE.QTResizeButton:Show()
    end)
    CreateTooltip(QTMaximizeButton, "Maximize Quest Tracker")
    CreateBorder(QTMaximizeButton)

    return QTMaximizeButton
end


-- Parent function to Create QTMinimizeButton for RQEQuestFrame
function RQE.Buttons.CreateQuestMinimizeButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
    local QTMinimizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
    QTMinimizeButton:SetSize(18, 18)
    QTMinimizeButton:SetText("-")
    RQE.QTQuestMinimizeButton = QTMinimizeButton  -- Store the reference in the RQE table

    -- Set the frame strata and level
    QTMinimizeButton:SetFrameStrata("MEDIUM")
    QTMinimizeButton:SetFrameLevel(3)

    QTMinimizeButton:SetPoint("TOPRIGHT", RQE.QTQuestMaximizeButton, "TOPLEFT", -3, 0)
    QTMinimizeButton:SetScript("OnClick", function()
		RQE.QToriginalWidth, RQE.QToriginalHeight = RQEQuestFrame:GetWidth(), RQEQuestFrame:GetHeight()
		
		-- Set RQE.QTMinimized to false since we're maximizing the frame
		RQE.QTMinimized = true
		
		RQEQuestFrame:SetSize(300, 30)
		
		-- Hide the ScrollFrame if they exist
		if RQE.QTScrollFrame then
			RQE.QTScrollFrame:Hide()
		end
		
		-- Hide the Slider if they exist
		if RQE.QTslider then
			RQE.QTslider:Hide()
		end
		
		-- Hide the resize button
		if RQE.QTResizeButton then
			RQE.QTResizeButton:Hide()
		end	
    end)
    CreateTooltip(QTMinimizeButton, "Minimize Quest Tracker")
    CreateBorder(QTMinimizeButton)

    return QTMinimizeButton
end

---------------------------
-- 4. Finalization
---------------------------

-- Function to create and initialize the SearchBox
function RQE.Buttons.CreateSearchBox(RQEFrame)
    --Ace3 SearchBox
end