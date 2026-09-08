--[[ 

DebugLog.lua
Handles the debug messages and creation of the debug log frame for copying/pasting

]]


RQE = RQE or {}
RQE.Buttons = RQE.Buttons or {}

local isRetail = RQE.IsRetail == true

local headerHeight = 30
local logTable = {}
local logFrame

-- A capture session begins when RQE gathers quest data and ends whenever the
-- Debug Log is hidden.  This keeps a closed log from retaining or accepting
-- data from an earlier quest-accept sequence.
local captureMode
local captureQuestIDs = {}
local capturedTextQuestIDs = {}
local capturedNPCQuestIDs = {}
local capturePhase
local currentQuestBlockAllowed
local captureGeneration = 0


local function ResetDebugLogCapture()
	captureMode = nil
	captureQuestIDs = {}
	capturedTextQuestIDs = {}
	capturedNPCQuestIDs = {}
	capturePhase = nil
	currentQuestBlockAllowed = nil
end


local function GetTextQuestIDFromLogMessage(message)
	-- CheckMissingQuestTextData emits this exact, green header before its
	-- objectives/description/NPC lines.  Do not treat generic RQE debug text
	-- containing "questID:" as a contribution-data header.
	return tonumber(tostring(message):match("^|cff00ff00questID:%s*(%d+)|r$"))
end


local function IsTextQuestPayload(message)
	-- The contribution addon colourises these lines, but preserve the block if
	-- its presentation colour changes.  The field names are the stable part of
	-- the contribution output format.
	local payload = tostring(message):gsub("^|c%x%x%x%x%x%x%x%x", "")
	return payload:match("^%s*objectivesQuestText%s*=")
		or payload:match("^%s*descriptionQuestText%s*=")
		or payload:match("^%s*npc%s*=")
end


local function GetNPCQuestIDFromLogMessage(message)
	-- CheckMissingNPCOnQuestAccept uses an uncoloured header, so it is handled
	-- only during the explicitly selected NPC capture phase.
	return tonumber(tostring(message):match("^questID:%s*(%d+)$"))
end


local function IsNPCQuestPayload(message)
	return tostring(message):match("^%s*npc%s*=")
end


-- Function to add messages to the log
function RQE.AddToDebugLog(message)
	-- Check if debug logging is enabled via the checkbox
	if not RQE or not RQE.db or not RQE.db.profile or not RQE.db.profile.debugLoggingCheckbox then
		return
	end

	local frameIsShown = logFrame and logFrame:IsShown()
	-- Export actions deliberately write before displaying the frame.  Automatic
	-- quest captures may do the same while their synchronous contribution call
	-- is active.  Outside those cases, a hidden frame cannot retain new data.
	if not frameIsShown and captureMode ~= "all" and not capturePhase then
		return
	end

	if capturePhase == "text" then
		local questID = GetTextQuestIDFromLogMessage(message)
		if questID then
			currentQuestBlockAllowed = captureQuestIDs[questID] and not capturedTextQuestIDs[questID]
			if currentQuestBlockAllowed then
				capturedTextQuestIDs[questID] = true
			end
		elseif not IsTextQuestPayload(message) then
			return
		end

		if currentQuestBlockAllowed ~= true then
			return
		end
	elseif capturePhase == "npc" then
		local questID = GetNPCQuestIDFromLogMessage(message)
		if questID then
			currentQuestBlockAllowed = captureQuestIDs[questID] and not capturedNPCQuestIDs[questID]
			if currentQuestBlockAllowed then
				capturedNPCQuestIDs[questID] = true
			end
		elseif not IsNPCQuestPayload(message) then
			return
		end

		if currentQuestBlockAllowed ~= true then
			return
		end
	end

	local timestamp = date("%Y-%m-%d %H:%M:%S")
	local logEntry
	local playerMapID
	if isRetail then
		playerMapID = C_Map.GetBestMapForUnit("player") or 0
	else
		playerMapID = RQE.API and RQE.API.GetBestMapForUnit
			and RQE.API.GetBestMapForUnit("player")
			or 0
	end
	local isGarrisonMap = (playerMapID == 590 or playerMapID == 582)

	if RQE.db.profile.debugTimeStampCheckbox then
		-- If timestamps are enabled, format normally
		logEntry = string.format("[%s] %s", timestamp, message)
	else
		-- If timestamps are disabled, use [XXX] instead
		logEntry = message
		--logEntry = string.format(message) -- commented out as this type didn't like "%" signs in objective/descriptiontext
	end

	-- Prevent duplicate messages
	local isInScenario
	if isRetail then
		isInScenario = C_Scenario.IsInScenario()
	else
		isInScenario = RQE.API and RQE.API.IsInScenario and RQE.API.IsInScenario() or false
	end
	if isGarrisonMap or (not isInScenario and not IsInInstance()) then
		if logTable[#logTable] ~= logEntry then
			table.insert(logTable, logEntry)
			RQE.UpdateLogFrame()
		end
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
		local ok, safeMessage = pcall(tostring, message)
		if ok and type(safeMessage) == "string" then
			RQE.AddToDebugLog(safeMessage)
		else
			-- avoid recursion: use original AddMessage, not DEFAULT_CHAT_FRAME:AddMessage
			RQE.originalAddMessage(self, "|cffff7f00[RQE]|r Protected chat payload detected; skipped debug logging.", 1, 0.5, 0)
		end
	end

	-- if RQE and RQE.AddToDebugLog then
		-- RQE.AddToDebugLog(message)
	-- end
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
logFrame = CreateFrame("Frame", "LogFrame", UIParent, "BackdropTemplate")
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
RQE.DebugLogFrameRef = logFrame


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
local closeButton = CreateFrame("Button", "RQEDebugLogCloseButton", logFrame, "UIPanelCloseButton")
closeButton:SetSize(30, 30)
closeButton:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", 0, 0)
closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
closeButton:SetScript("OnClick", function()
	logFrame:Hide()
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
		RQE.DebugLogFrame()
	end
end


-- Show and refresh the Debug Log.  Visibility toggling is handled by
-- RQE:ToggleDebugLog(), so producer calls cannot accidentally hide a session.
function RQE.DebugLogFrame()
	RQE.UpdateLogFrame()
	if not logFrame:IsShown() then
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


local function ClearDebugLogContents()
	logTable = {}
	RQE.UpdateLogFrame()
	scrollFrame:SetVerticalScroll(0)
	scrollBar:SetValue(0)
end


-- Function to clear the debug log and invalidate its current capture session.
function RQE:ClearDebugLog()
	captureGeneration = captureGeneration + 1
	ResetDebugLogCapture()
	ClearDebugLogContents()
end


-- Used by RQE's explicit data-export actions, which create output before the
-- frame is shown.
function RQE:BeginDebugLogCapture()
	captureGeneration = captureGeneration + 1
	ResetDebugLogCapture()
	captureMode = "all"
	ClearDebugLogContents()
end


function RQE:EndDebugLogCapture()
	if captureMode == "all" then
		captureMode = nil
	end
end


-- Register a quest with the current automatic quest-data capture session.
-- A hidden Debug Log starts a fresh session; an already-visible one keeps its
-- existing quest IDs so simultaneous accepts are shown together.
function RQE:GetDebugLogCaptureGeneration()
	return captureGeneration
end


function RQE:IsDebugLogQuestCaptureActive()
	return captureMode == "quest"
end


local function RegisterDebugLogQuestCapture(questID)
	if captureMode ~= "quest" then
		ResetDebugLogCapture()
		captureMode = "quest"
		ClearDebugLogContents()
	end

	captureQuestIDs[questID] = true
end


-- Register the accepted quest immediately.  Its delayed data collection can
-- then share one capture session with other quests accepted in the same burst.
function RQE:PrepareDebugLogQuestCapture(questID)
	questID = tonumber(questID)
	if not questID then
		return nil
	end

	RegisterDebugLogQuestCapture(questID)
	return captureGeneration
end


function RQE:BeginDebugLogQuestCapture(questID, generation)
	questID = tonumber(questID)
	if not questID or (generation and generation ~= captureGeneration) then
		return false
	end

	RegisterDebugLogQuestCapture(questID)
	capturePhase = "text"
	currentQuestBlockAllowed = nil
	return true
end


function RQE:BeginDebugLogNPCCapture(questID)
	questID = tonumber(questID)
	if captureMode ~= "quest" or not questID or not captureQuestIDs[questID] then
		return false
	end

	capturePhase = "npc"
	currentQuestBlockAllowed = nil
	return true
end


function RQE:EndDebugLogQuestCapture()
	capturePhase = nil
	currentQuestBlockAllowed = nil
end


-- Every hide path (the close button, minimap toggle, slash command, or another
-- addon) clears the RQE Debug Log and invalidates its capture session.
logFrame:HookScript("OnHide", function()
	RQE:ClearDebugLog()
end)


-- Register the slash command
SLASH_CLEARDEBUG1 = "/rqeclearlog"
SlashCmdList["CLEARDEBUG"] = function(msg)
	RQE:ClearDebugLog()
end