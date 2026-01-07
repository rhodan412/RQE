--[[ 

DebugLog.lua
Handles the debug messages and creation of the debug log frame for copying/pasting

]]


RQE = RQE or {}
RQE.Buttons = RQE.Buttons or {}


local headerHeight = 30
local logTable = {}


-- Function to add messages to the log
function RQE.AddToDebugLog(message)
	-- Check if debug logging is enabled via the checkbox
	if not RQE.db.profile.debugLoggingCheckbox then
		return
	end

	local timestamp = date("%Y-%m-%d %H:%M:%S")
	local logEntry

	if RQE.db.profile.debugTimeStampCheckbox then
		-- If timestamps are enabled, format normally
		logEntry = string.format("[%s] %s", timestamp, message)
	else
		-- If timestamps are disabled, use [XXX] instead
		logEntry = message
		--logEntry = string.format(message) -- commented out as this type didn't like "%" signs in objective/descriptiontext
	end

	-- Prevent duplicate messages
	if logTable[#logTable] ~= logEntry then
		table.insert(logTable, logEntry)
		RQE.UpdateLogFrame()
	end
end


-- Create a backup of the original AddMessage function
if not RQE.originalAddMessage then
	RQE.originalAddMessage = DEFAULT_CHAT_FRAME.AddMessage
end


-- Create a new function to hook the default AddMessage
function DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b, ...)
	-- Call the original function to print to the default chat frame
	RQE.originalAddMessage(self, message, r, g, b, ...)

	-- Also log the message to the Debug Log frame if logging is enabled
	if RQE and RQE.AddToDebugLog then
		RQE.AddToDebugLog(message)
	end
end


-- Function to display the log
local function DisplayLog()
	-- Code to create or update a custom frame that displays the logTable contents
end


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
local scrollBar = CreateFrame("Slider", nil, scrollFrame)
scrollBar:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -10, -30)
scrollBar:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -10, 10)
scrollBar:SetValueStep(1)
scrollBar.scrollStep = 1
scrollBar:SetValue(0)
scrollBar:SetWidth(16)


-- Function to calculate the height of the text in the EditBox
local function CalculateTextHeight(editBox)
	local textString = editBox:GetText()
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
	editBox:SetWidth(scrollFrame:GetWidth())
	editBox:SetHeight(CalculateTextHeight(editBox))
	scrollFrame:UpdateScrollChildRect()
end


-- Create and display closeButton for DebugLog
local closeButton = CreateFrame("Button", "RQEDebugLogCloseButton", RQE.DebugLogFrame, "UIPanelCloseButton")
closeButton:SetSize(30, 30)
closeButton:SetPoint("TOPRIGHT", RQE.DebugLogFrame, "TOPRIGHT", 0, 0)
closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
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
		self:GetHighlightTexture():Hide()
	end
end)


resizeButton:SetScript("OnMouseUp", function(self)
	logFrame:StopMovingOrSizing()
	self:GetHighlightTexture():Show()
	RQE.UpdateLogFrame()
end)


-- Make sure the log frame is initially hidden
RQE.UpdateLogFrame()
logFrame:Hide()


-- Define the SLASH command to toggle the log
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
	local textHeight = self:GetHeight()
	self:SetHeight(textHeight)
	local maxScroll = math.max(textHeight - scrollFrame:GetHeight(), 0)
	scrollBar:SetValue(maxScroll)
end)


-- Function to clear the debug log
function RQE:ClearDebugLog()
	logTable = {}
end


-- Register the slash command
SLASH_CLEARDEBUG1 = "/rqeclearlog"
SlashCmdList["CLEARDEBUG"] = function(msg)
	RQE:ClearDebugLog()
end