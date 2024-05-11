-- DebugLog.lua

RQE = RQE or {}
RQE.Buttons = RQE.Buttons or {}

local headerHeight = 30
local logTable = {}


-- Function to add messages to the log
function RQE.AddToDebugLog(message)
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, message)
    table.insert(logTable, logEntry)
    RQE.UpdateLogFrame()  -- Refresh the log frame each time a new message is added
end


-- Function to display the log
local function DisplayLog()
    -- Code to create or update a custom frame that displays the logTable contents
    -- This is a placeholder for the UI code
end


-- In your Config.lua or where you handle the toggle
-- Assuming you have a button or a command to toggle the display
function RQE.ToggleLogDisplay()
    -- Code to show/hide the log display
    DisplayLog()
end


-- Create a frame for displaying the log
local logFrame = CreateFrame("Frame", "LogFrame", UIParent, "BackdropTemplate")
logFrame:SetSize(300, 400) -- width, height
logFrame:SetPoint("CENTER") -- position
logFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
logFrame:SetMovable(true)
logFrame:EnableMouse(true)
logFrame:SetResizable(true)
logFrame:RegisterForDrag("LeftButton")
logFrame:SetScript("OnDragStart", logFrame.StartMoving)
logFrame:SetScript("OnDragStop", logFrame.StopMovingOrSizing)
logFrame:SetFrameStrata("HIGH")
RQE.DebugLogFrame = logFrame


local header = CreateFrame("Frame", "RQE.LogFrameHeader", logFrame, "BackdropTemplate")
header:SetHeight(headerHeight)
header:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
header:SetPoint("TOPLEFT", logFrame, "TOPLEFT")
header:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT")
header:EnableMouse(true)
header:SetMovable(true)
header:RegisterForDrag("LeftButton")
header:SetScript("OnDragStart", function(self) self:GetParent():StartMoving() end)
header:SetScript("OnDragStop", function(self) self:GetParent():StopMovingOrSizing() end)


local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("CENTER", header, "CENTER")
headerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
headerText:SetText("RQE Debug Log")


-- Create a ScrollFrame as a container for the EditBox
local scrollFrame = CreateFrame("ScrollFrame", nil, logFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(280, 380) -- Same as editBox


-- Adjust the scrollFrame position to be below the header
scrollFrame:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 10, -headerHeight)
scrollFrame:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -10, 10)


-- Replace ScrollingMessageFrame with a MultiLineEditBox
local editBox = CreateFrame("EditBox", nil, logFrame, "InputBoxTemplate")
editBox:SetMultiLine(true)
editBox:SetSize(280, 380)  -- Adjust the height as needed

editBox:SetPoint("TOPLEFT")
editBox:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT")
editBox:SetFontObject("ChatFontNormal")
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

scrollFrame:SetScrollChild(editBox)


-- Add a scroll bar to the edit box
---@class RQESlider : Slider
---@field scrollStep number
local scrollBar = CreateFrame("Slider", nil, scrollFrame) -- Parent changed to scrollFrame
scrollBar:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -10, -30)
scrollBar:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -10, 10)
scrollBar:SetValueStep(1)
scrollBar.scrollStep = 1
scrollBar:SetValue(0)
scrollBar:SetWidth(16)


-- Function to calculate the height of the text in the EditBox
local function CalculateTextHeight(editBox)
    local textString = editBox:GetText()
    local stringWidth = editBox:GetWidth()
    local totalHeight = 0
    local _, fontHeight = editBox:GetFont()

    for line in textString:gmatch("[^\n]+") do
        totalHeight = totalHeight + fontHeight
    end

    return totalHeight
end

-- Function to update the log frame with logTable contents
function RQE.UpdateLogFrame()
    local logText = table.concat(logTable, "\n")
    editBox:SetText(logText)
    -- We need to update the size of the editBox and the scrollFrame here as well
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetHeight(CalculateTextHeight(editBox))  -- CalculateTextHeight needs to be defined correctly
    scrollFrame:UpdateScrollChildRect()  -- This updates the scroll bar to account for the new size of the scroll child
end


-- Create and Display closeButton for DebugLog
local closeButton = CreateFrame("Button", "RQEDebugLogCloseButton", RQE.DebugLogFrame, "UIPanelCloseButton")
closeButton:SetSize(30, 30) -- Set the size of the close button
closeButton:SetPoint("TOPRIGHT", RQE.DebugLogFrame, "TOPRIGHT", 0, 0) -- Position it at the top-right corner

closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up") -- Set the normal texture
closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down") -- Set the pushed texture
closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight") -- Set the highlight texture

closeButton:SetScript("OnClick", function()
    RQE:ToggleDebugLog() -- Hide the debug log frame when the close button is clicked
end)


-- Resize button
local resizeButton = CreateFrame("Button", nil, logFrame)
resizeButton:SetPoint("BOTTOMRIGHT", -6, 7)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")


resizeButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        logFrame:StartSizing("BOTTOMRIGHT")
        self:GetHighlightTexture():Hide()  -- Hide highlight so it doesn't stick while sizing
    end
end)

resizeButton:SetScript("OnMouseUp", function(self, button)
    logFrame:StopMovingOrSizing()
    self:GetHighlightTexture():Show()
    RQE.UpdateLogFrame()  -- Update the contents to fit the new size
end)


-- Make sure the log frame is initially hidden
RQE.UpdateLogFrame()
logFrame:Hide()


-- Now define the SLASH command after the function is defined
SLASH_LOGTOGGLE1 = "/logtoggle"
SlashCmdList["LOGTOGGLE"] = function()
    if logFrame:IsShown() then
        logFrame:Hide()
    else
        logFrame:Show()
        RQE.UpdateLogFrame()
    end
end


-- Function to toggle the log frame visibility
function RQE.DebugLogFrame()
    if logFrame:IsShown() then
        logFrame:Hide()
    else
        RQE.UpdateLogFrame()
        logFrame:Show()
    end
end


-- Adjust the scrollbar (slider) to control the scrollFrame
scrollBar:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value)
end)


-- Update the EditBox height and scrollbar range when text changes
editBox:SetScript("OnTextChanged", function(self)
    -- You'll need to calculate the height based on the content and set it manually
    -- Since GetStringHeight is not available, we'll use GetHeight instead
    local textHeight = self:GetHeight()
    self:SetHeight(textHeight)

    local maxScroll = math.max(textHeight - scrollFrame:GetHeight(), 0)
    --scrollBar:SetMinMaxValues(1, maxScroll)
    scrollBar:SetValue(maxScroll) -- Set to the bottom of the scroll area
end)