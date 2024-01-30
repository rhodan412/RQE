-- DebugLog.lua

RQE = RQE or {}

local logTable = {}

-- Function to add messages to the log
function RQE.AddToDebugLog(message)
    table.insert(logTable, message)
    -- Print to console for immediate feedback (optional)
    --print("Debug Log: " .. message)
end

-- Add a test message using the RQE table
--RQE.AddToDebugLog("This is a test log message")

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
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
logFrame:SetMovable(true)
logFrame:EnableMouse(true)
logFrame:RegisterForDrag("LeftButton")
logFrame:SetScript("OnDragStart", logFrame.StartMoving)
logFrame:SetScript("OnDragStop", logFrame.StopMovingOrSizing)

-- Make sure the log frame is initially hidden
logFrame:Hide()

-- Replace ScrollingMessageFrame with a MultiLineEditBox
local editBox = CreateFrame("EditBox", nil, logFrame, "InputBoxTemplate")
editBox:SetMultiLine(true)
editBox:SetSize(280, 1000) -- Starting width and height, will be adjusted
editBox:SetPoint("TOP", 0, -10)
editBox:SetFontObject("ChatFontNormal")
editBox:SetAutoFocus(false) -- don't automatically focus
editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end) -- lose focus on Esc

-- Create a ScrollFrame as a container for the EditBox
local scrollFrame = CreateFrame("ScrollFrame", nil, logFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(280, 380) -- Same as editBox
scrollFrame:SetPoint("TOP", 0, -10)
scrollFrame:SetScrollChild(editBox)

-- Add a scroll bar to the edit box
local scrollBar = CreateFrame("Slider", nil, scrollFrame) -- Parent changed to scrollFrame
scrollBar:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -10, -30)
scrollBar:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -10, 10)
scrollBar:SetMinMaxValues(1, 100)
scrollBar:SetValueStep(1)
scrollBar.scrollStep = 1
scrollBar:SetValue(0)
scrollBar:SetWidth(16)


-- -- Create a scrolling message frame inside the log frame
-- local messageFrame = CreateFrame("ScrollingMessageFrame", nil, logFrame)
-- messageFrame:SetSize(280, 380) -- width, height
-- messageFrame:SetPoint("CENTER", 0, 0)
-- messageFrame:SetFontObject("GameFontNormal")
-- messageFrame:SetJustifyH("LEFT")
-- messageFrame:SetMaxLines(500)
-- messageFrame:EnableMouseWheel(true)
-- messageFrame:SetScript("OnMouseWheel", function(self, delta)
    -- if delta > 0 then
        -- self:ScrollUp()
    -- else
        -- self:ScrollDown()
    -- end
-- end)

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
local function UpdateLogFrame()
    local logText = table.concat(logTable, "\n")
    editBox:SetText(logText)
    
    -- Calculate the total height of the text
    local textHeight = CalculateTextHeight(editBox)
    local maxScroll = math.max(textHeight - editBox:GetHeight(), 1)
    scrollBar:SetMinMaxValues(1, maxScroll)
    scrollBar:SetValue(maxScroll) -- Scroll to the bottom
end

-- Function to toggle the log frame visibility
function ToggleLogFrame()
    if logFrame:IsShown() then
        logFrame:Hide()
    else
        UpdateLogFrame()
        logFrame:Show()
    end
end

-- Adjust the scrollbar (slider) to control the scrollFrame
scrollBar:SetScript("OnValueChanged", function(self, value)
    scrollFrame:SetVerticalScroll(value)
end)

-- Update the EditBox height and scrollbar range when text changes
editBox:SetScript("OnTextChanged", function(self)
    -- Calculate the required height for the editBox
    local textHeight = CalculateTextHeight(self)
    self:SetHeight(textHeight)

    -- Update the scroll bar range
    local maxScroll = math.max(textHeight - scrollFrame:GetHeight(), 0)
    --scrollBar:SetMinMaxValues(1, maxScroll)
	slider:SetMinMaxValues(0, content:GetHeight())
end)


SLASH_LOGTOGGLE1 = "/logtoggle"
SlashCmdList["LOGTOGGLE"] = ToggleLogFrame
