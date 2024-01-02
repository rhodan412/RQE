-- RQEMinimap.lua
-- Creates minimap button that will toggle the RQEFrame


RQE = RQE or {}  -- Initialize the RQE table if it's not already initialized
RQE.Frame = RQE.Frame or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end


-- Assuming RQE is your main addon table
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")


-- Create a Data Broker object
RQE.dataBroker = ldb:NewDataObject("RQE", {
    type = "launcher",
    icon = "Interface\\Icons\\Ability_Spy",  -- Replace with your own icon
    OnClick = function(_, button)
		if button == "LeftButton" then
			-- Existing code for left button click, likely toggling your main frame
			if RQEFrame:IsShown() then
				RQEFrame:Hide()
				RQEQuestFrame:Hide()
				--RQE.db.profile.enableFrame = false
				--RQE.db.profile.enableQuestFrame = false
			else
				RQE:ClearFrameData() -- Clears frame data when showing the RQEFrame from a hidden setting
				RQEFrame:Show()
				-- Check if enableQuestFrame is true before showing RQEQuestFrame
                if RQE.db.profile.enableQuestFrame then
                    RQEQuestFrame:Show()
                end
				--RQE.db.profile.enableFrame = true
				--RQE.db.profile.enableQuestFrame = true
			end
			
		elseif button == "RightButton" then
			-- Open the add-on's configuration window
			InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")
			InterfaceOptionsFrame_OpenToCategory("Rhodan's Quest Explorer")  -- Call twice to actually open the page
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Rhodan's Quest Explorer")
        tooltip:AddLine("Left-click to toggle frame.")
    end,
})


-- Create the minimap button frame
RQE.MinimapButton = CreateFrame("Button", "MyMinimapButton", Minimap)
RQE.MinimapButton:SetSize(31, 31)  -- Set the size of the frame


-- Set up the texture for the button
RQE.MinimapButton:SetNormalTexture("Interface\\ICONS\\Ability_Spy")
RQE.MinimapButton:SetHighlightTexture("Interface\\ICONS\\Ability_Spy")
RQE.MinimapButton:SetPushedTexture("Interface\\ICONS\\Ability_Spy")


-- Set the position of the minimap button
RQE.MinimapButton:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)


-- OnClick handler
RQE.MinimapButton:SetScript("OnClick", function()
    if RQEFrame:IsShown() then
        RQEFrame:Hide()
    else
        RQEFrame:Show()
		RQEQuestFrame:Show()
    end
end)


-- Assuming MinimapButton is your minimap button
RQE.MinimapButton:SetMovable(true)
RQE.MinimapButton:EnableMouse(true)

RQE.MinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

RQE.MinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

RQE.MinimapButton:RegisterForDrag("LeftButton")