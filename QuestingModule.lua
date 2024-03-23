--[[ 

QuestingModule.lua
For advanced quest tracking features linked with RQEFrame

]]

---------------------------
-- 1. Global Declarations
---------------------------

-- Initialize RQE global table
RQE = RQE or {}
RQE.modules = RQE.modules or {}
RQE.WorldQuestsInfo = RQE.WorldQuestsInfo or {}
RQE.TrackedQuests = RQE.TrackedQuests or {}
RQE.TrackedAchievementIDs = RQE.TrackedAchievementIDs or {}
	
-- Initialization of RQE.ManuallyTrackedQuests
if not RQE.ManuallyTrackedQuests then
    RQE.ManuallyTrackedQuests = {}
end

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    print("RQE or RQE.debugLog is not initialized.")
end

-- Assuming AceGUI is already loaded and RQE is initialized
local AceGUI = LibStub("AceGUI-3.0")


---------------------------
-- 2. Frame Creation/Initialization
---------------------------

-- Create the frame
RQE.RQEQuestFrame = CreateFrame("Frame", "RQEQuestFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local frame = RQE.RQEQuestFrame

-- Frame properties
local xPos, yPos
if RQE and RQE.db and RQE.db.profile and RQE.db.profile.QuestFramePosition then
    xPos = RQE.db.profile.QuestFramePosition.xPos or -40  -- Default x position
    yPos = RQE.db.profile.QuestFramePosition.yPos or 150  -- Default y position
else
    xPos = -40  -- Default x position if db is not available
    yPos = 150  -- Default y position if db is not available
end

RQEQuestFrame:SetSize(325, 450)
RQEQuestFrame:SetPoint("CENTER", UIParent, "CENTER", xPos, yPos)
RQEQuestFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 5,
    insets = { left = 0, right = 0, top = 1, bottom = 0 }
})
RQEQuestFrame:SetBackdropColor(0, 0, 0, RQE.db.profile.QuestFrameOpacity)

-- Create the ScrollFrame
local ScrollFrame = CreateFrame("ScrollFrame", nil, RQEQuestFrame)
ScrollFrame:SetPoint("TOPLEFT", RQEQuestFrame, "TOPLEFT", 10, -40)  -- Adjusted Y-position
ScrollFrame:SetPoint("BOTTOMRIGHT", RQEQuestFrame, "BOTTOMRIGHT", -30, 10)
ScrollFrame:EnableMouseWheel(true)
ScrollFrame:SetClipsChildren(true)  -- Enable clipping
--ScrollFrame:Hide()
RQE.QTScrollFrame = ScrollFrame

-- Create the content frame
local content = CreateFrame("Frame", nil, ScrollFrame)
content:SetSize(360, 600)  -- Set the content size here
ScrollFrame:SetScrollChild(content)
content:SetAllPoints()
RQE.QTcontent = content

-- Make it draggable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Make it resizable
frame:SetResizable(true)

-- Create a resize button
local resizeBtn = CreateFrame("Button", nil, frame)
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT")
resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeBtn:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" then
    frame:StartSizing()
  end
end)
resizeBtn:SetScript("OnMouseUp", function(self, button)
  frame:StopMovingOrSizing()
  AdjustQuestItemWidths()
end)
RQE.QTResizeButton = resizeBtn

-- Title text in a custom header
local header = CreateFrame("Frame", "RQEQuestFrameHeader", RQEQuestFrame, "BackdropTemplate")
header:SetHeight(30)
header:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
header:SetPoint("TOPLEFT", 0, 0)
header:SetPoint("TOPRIGHT", 0, 0)

-- Create header text
local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("CENTER", header, "CENTER")
headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
headerText:SetTextColor(239/255, 191/255, 90/255)
headerText:SetText("RQE Quest Tracker")
headerText:SetWordWrap(true)

RQE.debugLog("Frame size: Width = " .. frame:GetWidth() .. ", Height = " .. frame:GetHeight())

-- Create the Slider (Scrollbar)
local QMQTslider = CreateFrame("Slider", nil, ScrollFrame, "UIPanelScrollBarTemplate")
QMQTslider:SetPoint("TOPLEFT", RQEQuestFrame, "TOPRIGHT", -20, -20)
QMQTslider:SetPoint("BOTTOMLEFT", RQEQuestFrame, "BOTTOMRIGHT", -20, 20)
QMQTslider:SetMinMaxValues(0, content:GetHeight())
QMQTslider:SetValueStep(1)
QMQTslider.scrollStep = 1
QMQTslider:Hide()

RQE.QMQTslider = QMQTslider

QMQTslider:SetScript("OnValueChanged", function(self, value)
    RQE.QTScrollFrame:SetVerticalScroll(value)
end)

ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local value = QMQTslider:GetValue()
    if delta > 0 then
        QMQTslider:SetValue(value - 50) -- A Change from 20 to 40 on both slider SetValues increases the scroll speed
    else
        QMQTslider:SetValue(value + 50)
    end
end)


---------------------------
-- 3. Child Frames
---------------------------

local function CreateChildFrame(name, parent, offsetX, offsetY, width, height)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, offsetY)
    return frame
end


-- Create the ScenarioChildFrame, anchored to the content frame
RQE.ScenarioChildFrame = CreateChildFrame("RQEScenarioChildFrame", content, 0, 0, content:GetWidth(), 200)

-- Create the Campaign Child frame, anchored to the content frame/Scenario Frame if available
RQE.CampaignFrame = CreateChildFrame("RQECampaignFrame", content, 0, 0, content:GetWidth(), 200)

-- Create the second child frame, anchored below the CampaignFrame
RQE.QuestsFrame = CreateChildFrame("RQEQuestsFrame", content, 0, -200, content:GetWidth(), 200) -- Adjust the Y-offset based on your layout

-- Create the third child frame, anchored below the QuestsFrame
RQE.WorldQuestsFrame = CreateChildFrame("RQEWorldQuestsFrame", content, 0, -400, content:GetWidth(), 200) -- Adjust the Y-offset based on your layout

-- Create the third child frame, anchored below the QuestsFrame
RQE.AchievementsFrame = CreateChildFrame("RQEAchievementsFrame", content, 0, -400, content:GetWidth(), 200) -- Adjust the Y-offset based on your layout

-- Initialize with default values
RQE.CampaignFrame.questCount = RQE.CampaignFrame.questCount or 0
RQE.QuestsFrame.questCount = RQE.QuestsFrame.questCount or 0
RQE.WorldQuestsFrame.questCount = RQE.WorldQuestsFrame.questCount or 0
RQE.AchievementsFrame.achieveCount = RQE.AchievementsFrame.achieveCount or 0


-- Function to create a header for a child frame
local function CreateChildFrameHeader(childFrame, title)
    local header = CreateFrame("Frame", nil, childFrame, "BackdropTemplate")
    header:SetHeight(30)
    header:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
    header:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", childFrame, "TOPRIGHT", 0, 0)

    -- Create header text
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("CENTER", header, "CENTER")
    headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
    headerText:SetTextColor(239/255, 191/255, 90/255)
    headerText:SetText(title)
    headerText:SetWordWrap(true)

    return headerText  -- Return the FontString instead of the frame
end


-- Update the Campaign frame anchor dynamically based on the state of the ScenarioChild being is present or not
function RQE.UpdateCampaignFrameAnchor()
    if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If ScenarioChildFrame is present and shown, anchor CampaignFrame to ScenarioChildFrame
        RQE.CampaignFrame:ClearAllPoints()  -- Clear existing points
        RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        -- If ScenarioChildFrame is not present or not shown, anchor CampaignFrame to content
        RQE.CampaignFrame:ClearAllPoints()  -- Clear existing points
        RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
end


-- Create headers for each child frame
RQE.CampaignFrame.header = CreateChildFrameHeader(RQE.CampaignFrame, "Campaign")
RQE.QuestsFrame.header = CreateChildFrameHeader(RQE.QuestsFrame, "Quests")
RQE.WorldQuestsFrame.header = CreateChildFrameHeader(RQE.WorldQuestsFrame, "World Quests")
RQE.AchievementsFrame.header = CreateChildFrameHeader(RQE.AchievementsFrame, "Achievements")


-- ScenarioChildFrame header
-- Function to create a unique header for the ScenarioChildFrame
local function CreateUniqueScenarioHeader(scenarioFrame, title)
    local header = CreateFrame("Frame", nil, scenarioFrame, "BackdropTemplate")
	header:SetFrameStrata("LOW") -- or "LOW" if you want it above the background but below medium elements
    header:SetHeight(115)  -- Setting a custom height for the scenario header
    header:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    header:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
    header:SetPoint("TOPLEFT", scenarioFrame, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", scenarioFrame, "TOPRIGHT", 0, 0)

    -- Create header text
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("CENTER", header, "CENTER", 0, -10)  -- Adjust Y offset to vertically center the text in the taller header
    headerText:SetFont("Fonts\\SKURRI.TTF", 18, "OUTLINE")
    headerText:SetTextColor(239/255, 191/255, 90/255)
    headerText:SetText(title)
    headerText:SetWordWrap(true)

    scenarioFrame.header = header  -- Assign the header to the scenario frame
    return header  -- Return the new header frame
end


-- Use the function to create a unique header for the ScenarioChildFrame
RQE.ScenarioChildFrame = RQE.ScenarioChildFrame or CreateFrame("Frame", "RQEScenarioChildFrame", UIParent)
CreateUniqueScenarioHeader(RQE.ScenarioChildFrame, "")


local function UpdateHeader(frame, baseTitle, questCount)
    local maxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()
    local numShownEntries, numQuestsInLog = C_QuestLog.GetNumQuestLogEntries()
    local titleText = baseTitle
    if frame == RQE.QuestsFrame then
        titleText = titleText .. " (" .. questCount .. "/" .. numQuestsInLog .. "/" .. maxQuests .. ")"
    else
        titleText = titleText .. " (" .. questCount .. ")"
    end
    frame.header:SetText(titleText)
end


---------------------------
-- 4. Child Frame Anchors
---------------------------

function UpdateFrameAnchors()
    -- Clear all points to prevent any previous anchoring affecting the new setup
    RQE.CampaignFrame:ClearAllPoints()
    RQE.QuestsFrame:ClearAllPoints()
    RQE.WorldQuestsFrame:ClearAllPoints()
	RQE.AchievementsFrame:ClearAllPoints()
    
    -- Anchor CampaignFrame
    if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
    
    -- Anchor QuestsFrame
    if RQE.CampaignFrame:IsShown() then
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
    
    -- Anchor WorldQuestsFrame
    if RQE.QuestsFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.CampaignFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    -- Anchor AchievementsFrame based on visibility of other frames
    if RQE.WorldQuestsFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.QuestsFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.CampaignFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
end


-- Make the function global or move it outside where it is defined so it can be accessed by UpdateFrameAnchors
function ResetChildFramesToDefault()
    -- CampaignFrame positioning
    if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.CampaignFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.CampaignFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    -- QuestsFrame positioning
    if RQE.CampaignFrame:IsShown() then
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    -- WorldQuestsFrame positioning
    if RQE.QuestsFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.CampaignFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    -- AchievementsFrame positioning
    if RQE.WorldQuestsFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.QuestsFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
    elseif RQE.CampaignFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
end


-- Adjust Set Point Anchor of Child Frames based on LastElements
function UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
    -- Reset positions to default first
    ResetChildFramesToDefault()

    -- Adjusting Quests child frame position based on last campaign element
    if lastCampaignElement then
        RQE.QuestsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -40, -15)
    elseif not RQE.CampaignFrame:IsShown() and RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If there are no campaign quests but ScenarioChildFrame is shown
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    elseif not RQE.CampaignFrame:IsShown() then
        -- If there are no campaign quests, anchor QuestsFrame to content
        RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

    -- Adjusting World Quests child frame position based on last campaign element
    if lastQuestElement then
        -- If there's a last element in the regular quests frame, anchor to it
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", lastQuestElement, "BOTTOMLEFT", -40, -15)
    elseif lastCampaignElement then
        -- If there's no last regular quest element but a last campaign element, anchor to it
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -40, -15)
    elseif RQE.CampaignFrame:IsShown() and not lastCampaignElement then
        -- If the Campaign frame is shown but there's no last campaign element, anchor to the Campaign frame
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -15)
    elseif RQE.QuestsFrame:IsShown() and not lastQuestElement then
        -- If the Quests frame is shown but there's no last quest element, anchor to the Quests frame
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If the ScenarioChildFrame is shown, anchor to it
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        -- If neither Campaign nor Regular Quests frames have elements, anchor to the content
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
	
    -- Adjust AchievementsFrame position based on the presence of WorldQuest elements
    if RQE.WorldQuestsFrame:IsShown() and lastWorldQuestElement then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", lastWorldQuestElement, "BOTTOMLEFT", -40, -15)
    elseif not RQE.WorldQuestsFrame:IsShown() and lastQuestElement then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", lastQuestElement, "BOTTOMLEFT", -40, -15)
    elseif not RQE.WorldQuestsFrame:IsShown() and lastCampaignElement then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -40, -15)
    elseif RQE.WorldQuestsFrame:IsShown() or RQE.QuestsFrame:IsShown() then
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame or RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
	elseif RQE.ScenarioChildFrame:IsShown() then
		RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -15)
	else
		RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
end


---------------------------
-- 5. Button Creation
---------------------------

-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Right Side)
RQE.Buttons.CreateQuestCloseButton(RQEQuestFrame)
RQE.Buttons.CreateQuestMaximizeButton(RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)
RQE.Buttons.CreateQuestMinimizeButton(RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)
RQE.Buttons.CreateQuestFilterButton(RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)

-- Create buttons using functions from Buttons.lua for RQEQuestFrame (Left Side)
RQE.Buttons.ClearWQButton(RQEQuestFrame, "TOPLEFT")


---------------------------
-- 6. Event Handlers
---------------------------

-- Event to update text widths when the frame is resized
RQEQuestFrame:SetScript("OnSizeChanged", function(self, width, height)
    AdjustQuestItemWidths(width)
	SaveQuestFrameSize()
end)


-- Calls function to save Quest Frame Position OnDragStop
RQEQuestFrame:SetScript("OnDragStop", function()
    RQEQuestFrame:StopMovingOrSizing()
    SaveQuestFramePosition()  -- This will save the current frame position
end)


-- Define the function to save frame position
function SaveQuestFramePosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = RQEQuestFrame:GetPoint()
    RQE.db.profile.QuestFramePosition.xPos = xOfs
    RQE.db.profile.QuestFramePosition.yPos = yOfs
    RQE.db.profile.QuestFramePosition.anchorPoint = relativePoint
end


-- Define the function to save frame position
function SaveQuestFrameSize()
    local width, height = RQEQuestFrame:GetSize()
    RQE.db.profile.QuestFramePosition.frameWidth = width
    RQE.db.profile.QuestFramePosition.frameHeight = height
end


-- Function used to adjust the Questing Frame width
function AdjustQuestItemWidths(frameWidth)
    -- Fallback: If frameWidth is not provided, use the width of a specific frame, e.g., RQEQuestFrame
    if not frameWidth then
        frameWidth = RQEQuestFrame:GetWidth() -- Adjust RQEQuestFrame to your specific frame
    end
	
    -- Define base parameters for dynamic padding calculation
    local baseWidth = 400
    local paddingMultiplier = (frameWidth - baseWidth) / 400
    
    -- Define base padding for different elements
    local basePadding = {
		-- Quest Base Padding
        QuestLevelAndName = 100,
        QuestObjectives = 110,
        QuestObjectivesOrDescription = 110,
		QuestTypeLabel = 130,

		-- World Quest Base Padding
        WQuestLevelAndName = 100,  -- Specific to WQuestLevelAndName
        WQuestObjectives = 110,  -- Specific to WQuestObjectives
        WQuestObjectivesOrDescription = 110,  -- Specific to WQuestObjectivesOrDescription
        WorldQuestTimeLeft = 45,
        WorldQuestDistance = 65,
		
		-- Scenario Base Padding
        ScenarioChildFrameBody = 75,  -- Added base padding for RQE.ScenarioChildFrame.body
		ScenarioChildFrameScenarioTitle = 55,  -- Added base padding for RQE.ScenarioChildFrame.scenarioTitle
		ScenarioChildFrameTitle = 75,  -- Added base padding for RQE.ScenarioChildFrame.title
		ScenarioTimerFrame = 15,
		
		TextPadding = 90,
        TimerFramePadding = 10, -- Additional padding for the timer frame if needed
    }
	
	-- Adjust widths for elements in RQE.QuestLogIndexButtons
	for i, button in ipairs(RQE.QuestLogIndexButtons or {}) do
		if button.QuestLevelAndName then
			button.QuestLevelAndName:SetWidth(frameWidth - (basePadding.QuestLevelAndName * (1 + paddingMultiplier)))
		end

		if button.QuestObjectives then
			-- Adjust the width of QuestObjectives, considering the base padding and padding multiplier
			local dynamicPadding = basePadding.QuestObjectives * (1 + paddingMultiplier)
			button.QuestObjectives:SetWidth(frameWidth - dynamicPadding)
		end

		if button.QuestObjectivesOrDescription then
			-- Adjust the width of QuestObjectivesOrDescription, considering the base padding and padding multiplier
			local dynamicPadding = basePadding.QuestObjectivesOrDescription * (1 + paddingMultiplier)
			button.QuestObjectivesOrDescription:SetWidth(frameWidth - dynamicPadding)
		end
	end
	
    -- Dynamic padding calculation for newly added elements
    local textPadding = basePadding.TextPadding * (1 + paddingMultiplier)
    local timerFramePadding = basePadding.TimerFramePadding * (1 + paddingMultiplier)
	
    -- Adjust widths for child frames and their headers
    local childFrames = {
        RQE.ScenarioChildFrame,
        RQE.CampaignFrame,
        RQE.QuestsFrame,
        RQE.WorldQuestsFrame,
        RQE.AchievementsFrame,
    }
	
	-- Adjust width for each element
    for _, WQuestLogIndexButton in pairs(WQuestLogIndexButtons or {}) do
        -- Adjust WQuestLevelAndName width for each WQuestLogIndexButton
        if WQuestLogIndexButton.WQuestLevelAndName then
            local dynamicPadding = basePadding.WQuestLevelAndName * (1 + paddingMultiplier)
            WQuestLogIndexButton.WQuestLevelAndName:SetWidth(frameWidth - dynamicPadding)
        end
		
        -- Adjust WQuestObjectives width for each WQuestLogIndexButton
        if WQuestLogIndexButton.QuestObjectives then
            local dynamicPadding = basePadding.WQuestObjectives * (1 + paddingMultiplier)
            WQuestLogIndexButton.QuestObjectives:SetWidth(frameWidth - dynamicPadding)
        end	
	
        -- Adjust WQuestObjectivesOrDescription width for each WQuestLogIndexButton
        if WQuestLogIndexButton.QuestObjectivesOrDescription then
            local dynamicPadding = basePadding.WQuestObjectivesOrDescription * (1 + paddingMultiplier)
            WQuestLogIndexButton.QuestObjectivesOrDescription:SetWidth(frameWidth - dynamicPadding)
        end
		
        -- Adjust WorldQuestTimeLeft width for each WQuestLogIndexButton
        if WQuestLogIndexButton.WQuestTimeLeft then
            local dynamicPadding = basePadding.WorldQuestTimeLeft * (1 + paddingMultiplier)
            WQuestLogIndexButton.WQuestTimeLeft:SetWidth(frameWidth - dynamicPadding)
        end
		
        -- Adjust WorldQuestDistance width for each WQuestLogIndexButton
        if WQuestLogIndexButton.WQuestDistance then
            local dynamicPadding = basePadding.WorldQuestDistance * (1 + paddingMultiplier)
            WQuestLogIndexButton.WQuestDistance:SetWidth(frameWidth - dynamicPadding)
        end
    end
	
    -- Adjust widths for elements in RQE.QuestLogIndexButtons
    for i, button in pairs(RQE.QuestLogIndexButtons or {}) do
        if button.QuestLevelAndName then
            button.QuestLevelAndName:SetWidth(frameWidth - (basePadding.QuestLevelAndName * (1 + paddingMultiplier)))
        end

        if button.QuestObjectivesOrDescription then
            button.QuestObjectivesOrDescription:SetWidth(frameWidth - (basePadding.QuestObjectivesOrDescription * (1 + paddingMultiplier)))
        end
		
        if button.QuestTypeLabel then
            button.QuestTypeLabel:SetWidth(frameWidth - (basePadding.QuestTypeLabel * (1 + paddingMultiplier)))
        end
    end

    -- Adjust width for RQE.ScenarioChildFrame.body using dynamic padding if not nil
    if RQE.ScenarioChildFrame.body then
        RQE.ScenarioChildFrame.body:SetWidth(frameWidth - (basePadding.ScenarioChildFrameBody * (1 + paddingMultiplier)))
    end

	-- Adjust width for RQE.ScenarioChildFrame.scenarioTitle using dynamic padding if not nil
    if RQE.ScenarioChildFrame.scenarioTitle then
        RQE.ScenarioChildFrame.scenarioTitle:SetWidth(frameWidth - (basePadding.ScenarioChildFrameScenarioTitle * (1 + paddingMultiplier)))
    end
	
	-- Adjust width for RQE.ScenarioChildFrame.title using dynamic padding if not nil
    if RQE.ScenarioChildFrame.title then
        RQE.ScenarioChildFrame.title:SetWidth(frameWidth - (basePadding.ScenarioChildFrameTitle * (1 + paddingMultiplier)))
    end

	-- Adjust width for RQE.ScenarioChildFrame.timerFrame using dynamic padding if not nil
    if RQE.ScenarioChildFrame.timerFrame then
        RQE.ScenarioChildFrame.timerFrame:SetWidth(frameWidth - (basePadding.ScenarioTimerFrame * (1 + paddingMultiplier)))
    end
	
    for _, childFrame in ipairs(childFrames) do
        if childFrame then
            -- Set the child frame's width
            childFrame:SetWidth(frameWidth)
            
            -- Assuming each childFrame has a 'header' frame and 'headerText' as described
            if childFrame.header then
                -- Adjust the header frame's width to match the child frame
                childFrame.header:SetWidth(frameWidth)

                -- If there's a text element within the header, adjust its width considering padding
                if childFrame.header.headerText then
                    childFrame.header.headerText:SetWidth(frameWidth - textPadding)
                end
            end
        end
    end

    -- Example adjustment for RQE.AchievementsFrame specific elements
    -- Assuming criteriaText and achievementHeader are directly accessible here
    if RQE.AchievementsFrame.criteriaText then
        RQE.AchievementsFrame.criteriaText:SetWidth(frameWidth - textPadding)
    end
    if RQE.AchievementsFrame.achievementHeader then
        RQE.AchievementsFrame.achievementHeader:SetWidth(frameWidth - textPadding)
    end
end


---------------------------
-- 8. Utility Functions
---------------------------

-- [Utility functions like AdjustQuestItemWidths, SaveQuestFramePosition, colorizeObjectives, RQE:QuestRewardsTooltip, etc.]

-- Function to create and position the ScrollFrame's child frames
function SortQuestsByProximity()
    -- Logic to sort quests based on proximity
    C_QuestLog.SortQuestWatches()
	GatherAndSortWorldQuestsByProximity()
end


-- Function to gather and sort World Quests by proximity
function GatherAndSortWorldQuestsByProximity()
    local worldQuests = {}
    local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()

    for i = 1, numTrackedWorldQuests do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID and C_QuestLog.IsWorldQuest(questID) then
            local distanceSq = C_QuestLog.GetDistanceSqToQuest(questID)
            table.insert(worldQuests, { questID = questID, distanceSq = distanceSq or math.huge })
        end
    end

    table.sort(worldQuests, function(a, b) return a.distanceSq < b.distanceSq end)
    return worldQuests
end


-- Function to Show Right-Click Dropdown Menu
function ShowQuestDropdown(self, questID)
    local menu = {}

    -- Check if the player is in a group and the quest is shareable
    local isPlayerInGroup = IsInGroup()
    local isQuestShareable = C_QuestLog.IsPushableQuest(questID)
    
    if isPlayerInGroup and isQuestShareable then
        table.insert(menu, { text = "Share Quest", func = function() C_QuestLog.SetSelectedQuest(questID); QuestLogPushQuest(); end })
    end

    -- Always include the other options
    table.insert(menu, { text = "Stop Tracking", func = function() C_QuestLog.RemoveQuestWatch(questID) end })
    table.insert(menu, { text = "Abandon Quest", func = function() C_QuestLog.SetAbandonQuest(); C_QuestLog.AbandonQuest(); end })
	table.insert(menu, { text = "View Quest", func = function() OpenQuestLogToQuestDetails(questID) end })
	
    -- Check if the quest is part of a questline
    local uiMapID = C_Map.GetBestMapForUnit("player") -- Assuming questline relevance to the current map
    local questLineInfo = C_QuestLine.GetQuestLineInfo(questID, uiMapID)
    if questLineInfo and questLineInfo.questLineID then
        table.insert(menu, { text = "Print Questline", func = function() RQE.PrintQuestlineDetails(questLineInfo.questLineID) end })
    end
	
	table.insert(menu, { text = "Show Wowhead Link", func = function() RQE:ShowWowheadLink(questID) end })
	table.insert(menu, { text = "Search Warcraft Wiki", func = function() RQE:ShowWowWikiLink(questID) end })
	
    local menuFrame = CreateFrame("Frame", "RQEQuestDropdown", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end


---------------------------
-- 9. Scenario Frame Handling
---------------------------

-- [Functions related to the scenario frame, such as RQE.InitializeScenarioFrame, RQE.UpdateScenarioFrame]

-- Function to initiate the Scenario Frame
function RQE.InitializeScenarioFrame()
    -- Create the ScenarioChildFrame if not already done
    -- Only create the ScenarioChildFrame if it does not already exist
    if not RQE.ScenarioChildFrame then
        -- Create the ScenarioChildFrame if it does not already exist
        RQE.ScenarioChildFrame = CreateFrame("Frame", "RQEScenarioChildFrame", UIParent)
        RQE.ScenarioChildFrame:SetSize(400, 200) -- Set the size as needed
        RQE.ScenarioChildFrame:SetPoint("CENTER") -- Position it at the center, or change as needed
    end

    if not RQE.ScenarioChildFrame.scenarioTitle then
        -- Create the scenarioTitle as a FontString within the ScenarioChildFrame
        RQE.ScenarioChildFrame.scenarioTitle = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		RQE.ScenarioChildFrame.scenarioTitle:ClearAllPoints()
		RQE.ScenarioChildFrame.scenarioTitle:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.header, "TOPLEFT", 10, -10)
		RQE.ScenarioChildFrame.scenarioTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		-- Ensure the text fits nicely and is readable
		RQE.ScenarioChildFrame.scenarioTitle:SetJustifyH("LEFT")
		RQE.ScenarioChildFrame.scenarioTitle:SetJustifyV("TOP")
		RQE.ScenarioChildFrame.scenarioTitle:SetWordWrap(true)  -- Ensure word wrap
		RQE.ScenarioChildFrame.scenarioTitle:SetHeight(0)

    end

    if not RQE.ScenarioChildFrame.stage then
        -- Create the stage as a FontString within the ScenarioChildFrame
        RQE.ScenarioChildFrame.stage = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		RQE.ScenarioChildFrame.stage:ClearAllPoints()
		RQE.ScenarioChildFrame.stage:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.scenarioTitle, "TOPLEFT", 0, -40)
		RQE.ScenarioChildFrame.stage:SetFont("Fonts\\SKURRI.TTF", 16, "OUTLINE")
		-- Ensure the text fits nicely and is readable
		RQE.ScenarioChildFrame.stage:SetJustifyH("LEFT")
		RQE.ScenarioChildFrame.stage:SetJustifyV("TOP")
		RQE.ScenarioChildFrame.stage:SetWordWrap(true)  -- Ensure word wrap
		RQE.ScenarioChildFrame.stage:SetHeight(0)
    end
	
    -- Ensure that scenarioTitle is a valid FontString object before creating title
    if not RQE.ScenarioChildFrame.title then
        -- Create the title as a FontString below the scenarioTitle
        RQE.ScenarioChildFrame.title = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		RQE.ScenarioChildFrame.title:ClearAllPoints()
        RQE.ScenarioChildFrame.title:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.stage, "TOPLEFT", 0, -25)
		RQE.ScenarioChildFrame.title:SetFont("Fonts\\SKURRI.TTF", 17, "OUTLINE")
		RQE.ScenarioChildFrame.title:SetJustifyH("LEFT")
		RQE.ScenarioChildFrame.title:SetJustifyV("TOP")
		RQE.ScenarioChildFrame.title:SetWordWrap(true)  -- Ensure word wrap
		RQE.ScenarioChildFrame.title:SetHeight(0)
    end
	
	-- Create a new frame for the timer
    RQE.ScenarioChildFrame.timerFrame = CreateFrame("Frame", nil, RQE.ScenarioChildFrame, "BackdropTemplate")
    RQE.ScenarioChildFrame.timerFrame:SetSize(100, 50)
    RQE.ScenarioChildFrame.timerFrame:SetPoint("BOTTOMRIGHT", RQE.ScenarioChildFrame.header, "BOTTOMRIGHT", -10, 10)
    RQE.ScenarioChildFrame.timerFrame:SetFrameStrata("MEDIUM")
	RQE.ScenarioChildFrame.timerFrame:SetFrameLevel(RQE.ScenarioChildFrame:GetFrameLevel() + 2)
    RQE.ScenarioChildFrame.timerFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 0.1,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    RQE.ScenarioChildFrame.timerFrame:SetBackdropColor(0, 0, 0, 0)

    -- Ensure the timer frame is on top of other elements
    RQE.ScenarioChildFrame.timerFrame:SetFrameLevel(RQE.ScenarioChildFrame:GetFrameLevel() + 1)

    -- Create the FontString for the timer within the timer frame
	RQE.ScenarioChildFrame.timer = RQE.ScenarioChildFrame.timer or RQE.ScenarioChildFrame.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	RQE.ScenarioChildFrame.timer:SetAllPoints()
	RQE.ScenarioChildFrame.timer:SetJustifyH("CENTER")
	RQE.ScenarioChildFrame.timer:SetJustifyV("MIDDLE")
	RQE.ScenarioChildFrame.timer:SetText("Initial Timer")
	RQE.ScenarioChildFrame.timer:SetHeight(0)
	RQE.ScenarioChildFrame.timer:SetWordWrap(true)
	RQE.ScenarioChildFrame.timer:SetTextColor(1, 1, 0, 1)

    -- Show the timer frame and its text
    RQE.ScenarioChildFrame.timerFrame:Show()
    RQE.ScenarioChildFrame.timer:Show()

    if not RQE.ScenarioChildFrame.body then
        -- Create the body as a FontString below the header
        RQE.ScenarioChildFrame.body = RQE.ScenarioChildFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        RQE.ScenarioChildFrame.body:ClearAllPoints()
		RQE.ScenarioChildFrame.body:SetPoint("TOPLEFT", RQE.ScenarioChildFrame.header, "BOTTOMLEFT", 10, -15)  -- Assuming the header is around 60px in height plus a 30px gap
		RQE.ScenarioChildFrame.body:SetFont("Fonts\\FRIZQT__.TTF", 14, "MONOCHROME")
        RQE.ScenarioChildFrame.body:SetText("Initial Body Text")
		RQE.ScenarioChildFrame.body:SetJustifyH("LEFT")
		RQE.ScenarioChildFrame.body:SetJustifyV("TOP")
		RQE.ScenarioChildFrame.body:SetWordWrap(true)  -- Ensure word wrap
		RQE.ScenarioChildFrame.body:SetHeight(0)
		-- Set the color of the body FontString to white (r, g, b, alpha)
		RQE.ScenarioChildFrame.body:SetTextColor(1, 1, 1, 0.9) -- White color
	end

    -- Update scenarioTitle and stage based on Torghast information
    if IsInJailersTower() and RQE.TorghastType and RQE.TorghastLayerNum and RQE.TorghastFloorID then
        local torghastTypeString = RQE.ConvertTorghastTypeToString(RQE.TorghastType)
        RQE.ScenarioChildFrame.scenarioTitle:SetText("Torghast, Tower of the Damned\n" .. torghastTypeString)
        RQE.ScenarioChildFrame.stage:SetText("Layer " .. RQE.TorghastLayerNum .. " - Floor " .. RQE.TorghastFloorID)
    end
end


-- Function to update the scenario frame with the latest information
function RQE.UpdateScenarioFrame()
    -- Get the full scenario information once at the beginning of the function
    local scenarioName, currentStage, numStages, flags, _, _, completed, xp, money, scenarioType, _, textureKit = C_Scenario.GetInfo()
	--local scenarioName, currentStage, numStages, isComplete = C_Scenario.GetInfo()
    local scenarioStepInfo = C_Scenario.GetStepInfo()
    local _, _, numCriteria = C_Scenario.GetStepInfo()

	-- Assuming currentStage is the stepID and you want the first criteria
	local stepID = currentStage
	local criteriaIndex = 1
	local duration, elapsed = select(10, C_Scenario.GetCriteriaInfoByStep(stepID, criteriaIndex))

	--local duration, elapsed = select(10, C_Scenario.GetCriteriaInfo(1))
	RQE.infoLog("[UpdateScenarioFrame, String] Duration is " .. tostring(duration))
	RQE.infoLog("[UpdateScenarioFrame, String] Elapsed is " .. tostring(elapsed))
	
    -- Check if we have valid timer information
    if duration and elapsed then
        local timeLeft = duration - elapsed
        RQE.ScenarioChildFrame.timer:SetText(SecondsToTime(timeLeft))
    else
        RQE.ScenarioChildFrame.timer:SetText("No Timer Available")
    end

    -- Check if we have valid scenario information
    if scenarioStepInfo and type(scenarioStepInfo) == "table" then
        if scenarioStepInfo.title then
            RQE.ScenarioChildFrame.title:SetText(scenarioStepInfo.title)
        else
            RQE.ScenarioChildFrame.title:SetText("Title is not available")
        end
    end

    -- Check if we have valid scenario information
    if scenarioName and scenarioStepInfo then
        -- Update the scenarioTitle with the scenario name
        RQE.ScenarioChildFrame.scenarioTitle:SetText(scenarioName)
		--RQE.ScenarioChildFrame.scenarioTitle:SetWordWrap(true)
        
        -- Update the stage with the current stage and total stages
        RQE.ScenarioChildFrame.stage:SetText("Stage " .. currentStage .. " of " .. numStages)
		--RQE.ScenarioChildFrame.stage:SetWordWrap(true)
        
        -- Update the title with the scenario step title
        RQE.ScenarioChildFrame.title:SetText(scenarioStepInfo)--(scenarioStepInfo.title)
        
        -- Update the main frame with criteria
        local criteriaText = ""
		for criteriaIndex = 1, numCriteria do
			local criteriaString, _, completed, quantity, totalQuantity = C_Scenario.GetCriteriaInfo(criteriaIndex)
			if completed then
				criteriaText = criteriaText .. "|cff00ff00" .. criteriaString .. " (" .. quantity .. "/" .. totalQuantity .. ")" .. "|r\n" -- Green color for completed
			else
				criteriaText = criteriaText .. criteriaString .. " (" .. quantity .. "/" .. totalQuantity .. ")\n" -- Default color for not completed
			end
		end
		
        RQE.ScenarioChildFrame.body:SetText(criteriaText)

        -- Update the timer, if applicable
        local duration, elapsed = select(10, C_Scenario.GetCriteriaInfo(1))

        if duration and elapsed then
            local timeLeft = duration - elapsed
            RQE.ScenarioChildFrame.timer:SetText(SecondsToTime(timeLeft))
        else
            RQE.ScenarioChildFrame.timer:SetText("No Timer Available")
        end
        
        -- Display the frame if it's not already shown
        RQE.ScenarioChildFrame:Show()
    else
        RQE.debugLog("No active scenario or scenario information is not available.")
        -- Hide the scenario frame since we're not in a scenario
        RQE.ScenarioChildFrame:Hide()
    end
end

---------------------------
-- 10. Timer Functionality
---------------------------

local timerFrame = CreateFrame("Frame", nil, RQE.ScenarioChildFrame)
timerFrame:SetSize(100, 10) -- Adjust size as needed
timerFrame:SetPoint("TOP", RQE.ScenarioChildFrame.header, "TOP", 95, -45)


-- Create a FontString for the timer text
local timerText = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timerText:SetAllPoints(timerFrame)
timerText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")  -- Increase font size to 20, adjust as needed
timerText:SetTextColor(1, 1, 1, 1) -- Sets timerText color to white

local startTime
local function UpdateTimer(self, elapsed)
    if startTime then
        local currentTime = GetTime()
        local elapsedTime = currentTime - startTime
        local hours = math.floor(elapsedTime / 3600)
        local minutes = math.floor(elapsedTime / 60) % 60
        local seconds = elapsedTime % 60
        timerText:SetText(string.format("%02d:%02d:%02d", hours, minutes, seconds))
    end
end


-- Start the timer
function RQE.StartTimer()
    startTime = GetTime()
    timerFrame:SetScript("OnUpdate", UpdateTimer)
	timerFrame:Show()
end


-- Stop the timer
function RQE.StopTimer()
    startTime = nil
    timerFrame:SetScript("OnUpdate", nil)
    timerText:SetText("00:00:00")
	timerFrame:Hide()
end


---------------------------
-- 11. Quest Frame Updates
---------------------------

-- [Functions for updating the quest frames, such as UpdateRQEQuestFrame, UpdateRQEWorldQuestFrame, RQE:ClearRQEQuestFrame, etc.]

-- Function used to clear the Questing Frame
function RQE:ClearRQEQuestFrame()
    -- Clearing regular quest buttons
    for i, QuestLogIndexButton in pairs(RQE.QuestLogIndexButtons or {}) do
        if QuestLogIndexButton then
            QuestLogIndexButton:Hide()
            if QuestLogIndexButton.QuestLevelAndName then
                QuestLogIndexButton.QuestLevelAndName:Hide()
            end
            if QuestLogIndexButton.QuestObjectivesOrDescription then
                QuestLogIndexButton.QuestObjectivesOrDescription:Hide()
            end
        end
    end
end


-- Function used to clear the World Quest Frame
function RQE:ClearRQEWorldQuestFrame()
    -- Ensure that RQE.WorldQuestsFrame exists and is a table
    if RQE.WorldQuestsFrame and type(RQE.WorldQuestsFrame) == "table" then
        -- Iterate over all elements in RQE.WorldQuestsFrame
        for i, WQuestLogIndexButton in pairs(RQE.WorldQuestsFrame) do
            -- Check if each element is a valid table
            if WQuestLogIndexButton and type(WQuestLogIndexButton) == "table" then
                -- Check if the element has a GetName method and a name that matches the pattern
                if WQuestLogIndexButton.GetName and WQuestLogIndexButton:GetName() and WQuestLogIndexButton:GetName():find("WQButton") then
                    WQuestLogIndexButton:Hide()
                    -- Hide sub-elements of the World Quest Button
                    if WQuestLogIndexButton.WQuestLevelAndName then
                        WQuestLogIndexButton.WQuestLevelAndName:Hide()
                    end
                    if WQuestLogIndexButton.QuestObjectivesOrDescription then
                        WQuestLogIndexButton.QuestObjectivesOrDescription:Hide()
                    end
                end
            end
        end
    end
end


-- Function to clear the Achievement Frame but preserve the header
function RQE:ClearAchievementFrame()
    -- Check if the achievements frame exists
    if RQE.AchievementsFrame then
        -- If there is a header that you want to preserve, reference it before clearing
        local header = RQE.AchievementsFrame.header
        
        -- Iterate through all child frames and hide them
        local children = {RQE.AchievementsFrame:GetChildren()}
        for _, child in ipairs(children) do
            if child ~= header then -- Skip the header if you want to preserve it
                child:Hide()
                child:SetParent(nil)
            end
        end
        
        -- Clear all font strings in the frame
        local regions = {RQE.AchievementsFrame:GetRegions()}
        for _, region in ipairs(regions) do
            if region:GetObjectType() == "FontString" then
                region:Hide()
            end
        end
    end
	RQE.AchievementsFrame.header = CreateChildFrameHeader(RQE.AchievementsFrame, "Achievements")
end


-- Function to Colorize the Quest Tracker Module
local function colorizeObjectives(objectivesText)
    local objectives = { strsplit("\n", objectivesText) }
    local colorizedText = ""

    for _, objective in ipairs(objectives) do
        local current, total = objective:match("(%d+)/(%d+)")  -- Extract current and total progress
        current, total = tonumber(current), tonumber(total)

        if current and total then
            if current >= total then
                -- Objective complete, colorize in green
                colorizedText = colorizedText .. "|cff00ff00" .. objective .. "|r\n"
            elseif current > 0 then
                -- Objective partially complete, colorize in yellow
                colorizedText = colorizedText .. "|cffffff00" .. objective .. "|r\n"
            else
                -- Objective has not started or no progress, leave as white
                colorizedText = colorizedText .. "|cffffffff" .. objective .. "|r\n"
            end
        else
            -- Objective text without progress numbers, leave as is
            colorizedText = colorizedText .. objective .. "\n"
        end
    end

    return colorizedText
end


-- Function to Add Reward Data to the Game Tooltip
function RQE:QuestRewardsTooltip(tooltip, questID, isBonus)
    local SelectedQuestID = C_QuestLog.GetSelectedQuest()  -- backup selected Quest
    C_QuestLog.SetSelectedQuest(questID)  -- for num Choices

    local xp = GetQuestLogRewardXP(questID)
	local rewardTitle = GetQuestLogRewardTitle()
	local skillPoints = GetQuestLogRewardSkillPoints()
    local money = GetQuestLogRewardMoney(questID)
    local artifactXP = GetQuestLogRewardArtifactXP(questID)
    local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID)
    local numQuestRewards = GetNumQuestLogRewards(questID)
    local numQuestSpellRewards, questSpellRewards = C_QuestInfoSystem.GetQuestRewardSpells(questID)
    local numQuestChoices = GetNumQuestLogChoices(questID, true)
    local honor = GetQuestLogRewardHonor(questID)
    local majorFactionRepRewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID) or C_QuestOffer.GetQuestOfferMajorFactionReputationRewards(questID)
    local rewardsTitle = REWARDS..":"

    if not isBonus then
        if numQuestChoices == 1 then
            tooltip:AddLine(" ")
            tooltip:AddLine(rewardsTitle)
        elseif numQuestChoices > 1 then
            tooltip:AddLine(" ")
            tooltip:AddLine(CHOOSE_ONE_REWARD..":")
            rewardsTitle = OTHER.." "..rewardsTitle
        end

        -- choices
        for i = 1, numQuestChoices do
            local lootType = GetQuestLogChoiceInfoLootType(i)
            local text, color
            if lootType == 0 then
                -- item
                local name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i)
                if numItems > 1 then
                    text = format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(numItems), name)
                elseif name and texture then
                    text = format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name)
                end
                color = isUsable and ITEM_QUALITY_COLORS[quality] or colorNotUsable
            elseif lootType == 1 then
                -- currency
                local name, texture, amount, currencyID, quality = GetQuestLogRewardCurrencyInfo(i, questID, true)
                amount = FormatLargeNumber(amount)
                text = format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(amount), name)
                color = ITEM_QUALITY_COLORS[quality]
            end
            if text and color then
                tooltip:AddLine(text, color.r, color.g, color.b)
            end
        end
    end

	-- xp
	if xp > 0 then
		tooltip:AddLine(format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, FormatLargeNumber(xp).."|c0000ff00"), 1, 1, 1)
		if isWarModeDesired and isQuestWorldQuest and questHasWarModeBonus then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT:format(C_PvP.GetWarModeRewardBonus()))
		end
	end

	-- honor
	if honor > 0 then
		tooltip:AddLine(format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, "Interface\\ICONS\\Achievement_LegionPVPTier4", honor, HONOR), 1, 1, 1)
	end

	-- money
	if money > 0 then
		tooltip:AddLine(GetCoinTextureString(money, 12), 1, 1, 1)
		if isWarModeDesired and isQuestWorldQuest and questHasWarModeBonus then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT:format(C_PvP.GetWarModeRewardBonus()))
		end
	end

	-- spells	
	if questSpellRewards then     -- Check if questSpellRewards is not nil
		if #questSpellRewards > 0 then
			for _, spellID in ipairs(questSpellRewards) do
				local spellInfo = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
				local knownSpell = IsSpellKnownOrOverridesKnown(spellID)
				if spellInfo and spellInfo.texture and spellInfo.name and not knownSpell and (not spellInfo.isBoostSpell or IsCharacterNewlyBoosted()) and (not spellInfo.garrFollowerID or not C_Garrison.IsFollowerCollected(spellInfo.garrFollowerID)) then
					tooltip:AddLine(format(BONUS_OBJECTIVE_REWARD_FORMAT, spellInfo.texture, spellInfo.name), 1, 1, 1)
				end
			end
		end
	end

	-- items
	for i = 1, numQuestRewards do
		local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i, questID)
		local text
		if numItems > 1 then
			text = format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(numItems), name)
		elseif texture and name then
			text = format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name)
		end
		if text then
			local color = isUsable and ITEM_QUALITY_COLORS[quality] or colorNotUsable
			tooltip:AddLine(text, color.r, color.g, color.b)
		end
	end

	-- artifact power
	if artifactXP > 0 then
		tooltip:AddLine(format(BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT, FormatLargeNumber(artifactXP)), 1, 1, 1)
	end

	-- currencies
	if numQuestCurrencies > 0 then
		QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip)
	end

	-- reputation
	if majorFactionRepRewards then
		for i, rewardInfo in ipairs(majorFactionRepRewards) do
			local majorFactionData = C_MajorFactions.GetMajorFactionData(rewardInfo.factionID)
			local text = FormatLargeNumber(rewardInfo.rewardAmount).." "..format(QUEST_REPUTATION_REWARD_TITLE, majorFactionData.name)
			tooltip:AddLine(text, 1, 1, 1)
		end
	end

	-- war mode bonus (quest only)
	if isWarModeDesired and not isQuestWorldQuest and questHasWarModeBonus then
		tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT:format(C_PvP.GetWarModeRewardBonus()))
	end

    C_QuestLog.SetSelectedQuest(SelectedQuestID)  -- restore selected Quest
end


-- Determine QuestType Function
function GetQuestType(questID)
    if C_QuestLog.ReadyForTurnIn(questID) then
		return "|cFF00FF00QUEST COMPLETE|r"  -- Orange color for completed quests
    elseif C_CampaignInfo.IsCampaignQuest(questID) then
        return "Campaign"
    elseif C_QuestLog.IsWorldQuest(questID) then
        return "World Quest"
    elseif C_QuestLog.IsQuestTrivial(questID) then
        return "Trivial"
    elseif C_QuestLog.IsThreatQuest(questID) then
        return "Bonus Quest"
    elseif C_QuestLog.IsRepeatableQuest(questID) then
        return "Repeatable"
    elseif QuestIsWeekly(questID) then
        return "Weekly Quest"
    elseif QuestIsDaily(questID) then
        return "Daily Quest"
    elseif C_QuestLog.IsThreatQuest(questID) then
        return "Threat Quest"
    else
        return "Regular Quest"
    end
end


-- Function to get the zone name for a given quest
function GetQuestZone(questID)
    local mapID = GetQuestUiMapID(questID, ignoreWaypoints)
    if mapID then
        local mapInfo = C_Map.GetMapInfo(mapID)
        if mapInfo and mapInfo.name then
            return mapInfo.name
        end
	elseif ( mapID ~= 0 ) then
		QuestMapFrame:GetParent():SetMapID(mapID)
    end	
	
    local uiMapID, worldQuests, worldQuestsElite, dungeons, treasures = C_QuestLog.GetQuestAdditionalHighlights(questID)
    if uiMapID then
        local mapInfo = C_Map.GetMapInfo(uiMapID)
        if mapInfo and mapInfo.name then
            return mapInfo.name
        end
    end

    local fallbackZoneID = C_TaskQuest.GetQuestZoneID(questID)
    if fallbackZoneID then
        local fallbackMapInfo = C_Map.GetMapInfo(fallbackZoneID)
        if fallbackMapInfo and fallbackMapInfo.name then
            return fallbackMapInfo.name
        end
    end

    local waypointZoneID = C_QuestLog.GetNextWaypoint(questID)
    if waypointZoneID then
        local waypointMapInfo = C_Map.GetMapInfo(waypointZoneID)
        if waypointMapInfo and waypointMapInfo.name then
            return waypointMapInfo.name
        end
    end

    -- Fallback to a pre-compiled quest-zone list
    if RQE.ZoneQuests and RQE.ZoneQuests[questID] then
        return RQE.ZoneQuests[questID]
    end

    return "Unknown Zone"
end


-- Function to determine if each quest belongs to World Quest or Non-World Quest
function QuestType()
    local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
    local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
    local regularQuestUpdated = false
    local worldQuestUpdated = false

    -- Loop through all tracked quests for regular and campaign quests
    for i = 1, numTrackedQuests do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID and not C_QuestLog.IsWorldQuest(questID) then
            regularQuestUpdated = true
        end
    end
	
    -- Loop through all tracked World Quests
    for i = 1, numTrackedWorldQuests do
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
        if questID then
            worldQuestUpdated = true
        end
    end

    -- Update frames if needed
    if regularQuestUpdated then
        UpdateRQEQuestFrame()
    end
    if worldQuestUpdated then
        UpdateRQEWorldQuestFrame()
    end
end


-- Your function to update the RQEQuestFrame
function UpdateRQEQuestFrame()
    local campaignQuestCount, regularQuestCount, worldQuestCount = 0, 0, 0
	RQE.campaignQuestCount = campaignQuestCount
	RQE.regularQuestCount = regularQuestCount
	RQE.worldQuestCount = worldQuestCount
	RQE.AchievementsFrame.achieveCount = 0
    local baseHeight = 175 -- Base height when no quests are present
    local questHeight = 65 -- Height per quest
    local spacingBetweenElements = 5
    local extraHeightForScenario = 50
	
    -- Check if ScenarioChildFrame is present and visible
    if RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- Here you could access the numCriteria from the ScenarioChildFrame if it's stored there
        -- For example, if you have RQE.ScenarioChildFrame.numCriteria set somewhere
        local numCriteria = RQE.ScenarioChildFrame.numCriteria or 0
        extraHeightForScenario = numCriteria * questHeight
    end
	
    -- Loop through all tracked quests to count campaign and world quests
    local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
	RQE.worldQuestCount = C_QuestLog.GetNumWorldQuestWatches()
	
    for i = 1, numTrackedQuests do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if C_CampaignInfo.IsCampaignQuest(questID) then
            RQE.campaignQuestCount = RQE.campaignQuestCount + 1
        elseif C_QuestLog.IsWorldQuest(questID) then
			worldQuestCounter = worldQuestCounter + 1
		end
    end

    -- Calculate the number of regular quests
    RQE.regularQuestCount = numTrackedQuests - RQE.campaignQuestCount

    -- Calculate frame heights
    local campaignHeight = baseHeight + (RQE.campaignQuestCount * questHeight)
    local regularHeight = baseHeight + (RQE.regularQuestCount * questHeight) + extraHeightForScenario
    local worldQuestHeight = baseHeight + (RQE.worldQuestCount * questHeight)
	local achievementHeight = baseHeight + (RQE.AchievementsFrame.achieveCount * 40)
	
    -- Update frame heights
    RQE.CampaignFrame:SetHeight(campaignHeight)
    RQE.QuestsFrame:SetHeight(regularHeight)
    RQE.WorldQuestsFrame:SetHeight(worldQuestHeight)
	RQE.AchievementsFrame:SetHeight(achievementHeight)

    -- Update total content height
    local totalHeight = campaignHeight + regularHeight + worldQuestHeight + achievementHeight
    RQE.QTcontent:SetHeight(totalHeight)

    -- Store quest count in each frame for reference
    RQE.CampaignFrame.questCount = campaignQuestCount
    RQE.QuestsFrame.questCount = regularQuestCount
    RQE.WorldQuestsFrame.questCount = worldQuestCount

    -- Let's assume you have stored your quest title FontStrings in a table
    for _, fontString in pairs(RQEQuestFrame.questTitles or {}) do
        fontString:Hide()
    end

    RQEQuestFrame.questTitles = RQEQuestFrame.questTitles or {}

    -- Get the number of tracked quests
    local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
	--local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
 
    -- Initialize the table to hold the QuestLogIndexButtons if it doesn't exist
    RQE.QuestLogIndexButtons = RQE.QuestLogIndexButtons or {}

    -- Create a variable to hold the last QuestObjectivesOrDescription
    local lastQuestObjectivesOrDescription = nil

	-- Create the Set Point for the Regular Quests Child Frame
    if RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
        -- If CampaignFrame is present and shown, anchor QuestsFrame to CampaignFrame
        RQE.QuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If CampaignFrame is not shown but ScenarioChildFrame is, anchor QuestsFrame to ScenarioChildFrame
        RQE.QuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        -- If neither is present or shown, anchor QuestsFrame to content
        RQE.QuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.QuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
		
	-- Create the Set Point for the World Quests Child Frame
    if RQE.QuestsFrame and RQE.QuestsFrame:IsShown() then
        -- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
        RQE.WorldQuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
        -- If QuestsFrame is not shown but CampaignFrame is, anchor WorldQuestsFrame to CampaignFrame
        RQE.WorldQuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If none of the quest frames are shown but ScenarioChildFrame is, anchor WorldQuestsFrame to ScenarioChildFrame
        RQE.WorldQuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        -- If no other frames are present or shown, anchor WorldQuestsFrame to content
        RQE.WorldQuestsFrame:ClearAllPoints()  -- Clear existing points
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end

	-- Create the Set Point for the World Quests Child Frame
    if RQE.WorldQuestsFrame and RQE.WorldQuestsFrame:IsShown() then
        -- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
        RQE.AchievementsFrame:ClearAllPoints()  -- Clear existing points
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.QuestsFrame and RQE.QuestsFrame:IsShown() then
        -- If QuestsFrame is present and shown, anchor WorldQuestsFrame to QuestsFrame
        RQE.AchievementsFrame:ClearAllPoints()  -- Clear existing points
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.CampaignFrame and RQE.CampaignFrame:IsShown() then
        -- If QuestsFrame is not shown but CampaignFrame is, anchor WorldQuestsFrame to CampaignFrame
        RQE.AchievementsFrame:ClearAllPoints()  -- Clear existing points
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -30)
    elseif RQE.ScenarioChildFrame and RQE.ScenarioChildFrame:IsShown() then
        -- If none of the quest frames are shown but ScenarioChildFrame is, anchor WorldQuestsFrame to ScenarioChildFrame
        RQE.AchievementsFrame:ClearAllPoints()  -- Clear existing points
        RQE.AchievementsFrame:SetPoint("TOPLEFT", RQE.ScenarioChildFrame, "BOTTOMLEFT", 0, -30)
    else
        -- If no other frames are present or shown, anchor WorldQuestsFrame to content
        RQE.AchievementsFrame:ClearAllPoints()  -- Clear existing points
        RQE.AchievementsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    end
		
    -- Separate variables to track the last element in each child frame
    local lastCampaignElement, lastQuestElement, lastWorldQuestElement = nil, nil, nil
		
		-- Loop through all tracked quests
		for i = 1, numTrackedQuests do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
		local directionText = C_QuestLog.GetNextWaypointText(questID)
		RQE.QuestDirectionText = directionText
		local questIndex = C_QuestLog.GetLogIndexForQuestID(questID)
		local isQuestComplete = C_QuestLog.IsComplete(questID)
		local isSuperTracked = C_SuperTrack.GetSuperTrackedQuestID() == questID
			
		if questIndex and not C_QuestLog.IsWorldQuest(questID) then
			local info = C_QuestLog.GetInfo(questIndex)
		
			if info and not info.isHeader then
				-- Determine the type of the quest (Campaign, World Quest, or Regular)
				local isCampaignQuest = C_CampaignInfo.IsCampaignQuest(questID)
			
				local parentFrame
				local lastElement
				if isCampaignQuest then
					parentFrame = RQE.CampaignFrame
					lastElement = lastCampaignElement
				elseif isWorldQuest then
					parentFrame = RQE.WorldQuestsFrame
					lastElement = lastWorldQuestElement
				else
					parentFrame = RQE.QuestsFrame
					lastElement = lastQuestElement
				end

				-- Create or reuse the QuestLogIndexButton
				local QuestLogIndexButton = RQE.QuestLogIndexButtons[i] or CreateFrame("Button", nil, content)
				QuestLogIndexButton:SetSize(35, 35)

				-- Create or update the background texture
				local bg = QuestLogIndexButton.bg or QuestLogIndexButton:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints()
				if isSuperTracked then
					bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
				else
					bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
				end
				QuestLogIndexButton.bg = bg  -- Save for future reference

				-- Create or update the number label
				local number = QuestLogIndexButton.number or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
				number:SetPoint("CENTER", QuestLogIndexButton, "CENTER")
				number:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				number:SetTextColor(1, 0.7, 0.2)
				number:SetText(questIndex)
				QuestLogIndexButton.number = number  -- Save for future reference

				-- Quest Watch List
				QuestLogIndexButton:SetScript("OnClick", function(self, button)
					if IsShiftKeyDown() and button == "LeftButton" then
						-- Untrack the quest
						C_QuestLog.RemoveQuestWatch(questID)
					else
						-- Get the currently super tracked quest ID
						local currentSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()

						-- Clear any existing super tracking
						C_SuperTrack.ClearSuperTrackedContent()

						-- Super track the new quest
						-- This will re-super track the quest even if it's the same as the currently super tracked quest
						C_SuperTrack.SetSuperTrackedQuestID(questID)
						UpdateFrame()
					end
				end)

				-- Save the button in the table for future reference
				RQE.QuestLogIndexButtons[i] = QuestLogIndexButton

				-- Fetch Quest Description
				local _, questObjectivesText = GetQuestLogQuestText(questIndex)

				-- Fetch Quest Objectives
				local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
				local objectivesText = objectivesTable and "" or "No objectives available."

				if objectivesTable then
					for _, objective in pairs(objectivesTable) do
						objectivesText = objectivesText .. objective.text .. "\n"
					end
				end

				local questTitle, questLevel
			
				-- Use the regular quest title and level
				questTitle = info.title
				questLevel = info.level
			
				-- Create or reuse the QuestObjectives label
				local QuestObjectives = RQE.QuestLogIndexButtons[i].QuestObjectives or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				QuestObjectives:SetPoint("TOPLEFT", QuestLevelAndName, "BOTTOMLEFT", 0, -5)
				QuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				QuestObjectives:SetWordWrap(true)
				QuestObjectives:SetWidth(RQEQuestFrame:GetWidth() - 110)
				QuestObjectives:SetHeight(0)  -- Auto height
				QuestObjectives:SetText(objectivesText)

				RQE.QuestLogIndexButtons[i].QuestObjectives = QuestObjectives

				-- Create or reuse the QuestLevelAndName label
				local QuestLevelAndName = RQE.QuestLogIndexButtons[i].QuestLevelAndName or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal", content)
				QuestLogIndexButton.QuestLevelAndName = QuestLevelAndName
				QuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
				--QuestLevelAndName:SetTextColor(209/255, 125/255, 255/255)  -- Heliotrope
				QuestLevelAndName:SetTextColor(137/255, 95/255, 221/255)  -- Medium Purple
				--QuestLevelAndName:SetText("[" .. info.level .. "] " .. info.title)  -- Concatenated quest level and name
				QuestLevelAndName:SetText(string.format("[%s] %s", questLevel, questTitle))

				-- Quest Details and Menu
				QuestLevelAndName:SetScript("OnMouseDown", function(self, button)
					if IsShiftKeyDown() and button == "LeftButton" then
						-- Untrack the quest
						C_QuestLog.RemoveQuestWatch(questID)
					elseif button == "LeftButton" then
						OpenQuestLogToQuestDetails(questID)
					elseif button == "RightButton" then
						ShowQuestDropdown(self, questID)
					end
				end)

				-- Anchor logic based on the quest type and index of lastelement/first
				if lastElement then
					QuestLevelAndName:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -15)
				else
					QuestLevelAndName:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 40, -40)
				end
				QuestLogIndexButton:SetPoint("RIGHT", QuestLevelAndName, "LEFT", -5, 0)

				-- Set Justification and Word Wrap
				QuestLevelAndName:SetJustifyH("LEFT")
				QuestLevelAndName:SetJustifyV("TOP")
				QuestLevelAndName:SetWordWrap(true)
				QuestLevelAndName:SetWidth(RQEQuestFrame:GetWidth() - 100)
				QuestLevelAndName:SetHeight(0)  -- Auto height
				QuestLevelAndName:EnableMouse(true)

				QuestLevelAndName:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)

				-- Quest Type
				local questTypeText = GetQuestType(questID)
				local questZoneText = GetQuestZone(questID)
				local QuestTypeLabel = QuestLogIndexButton.QuestTypeLabel or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				QuestTypeLabel:SetPoint("TOPLEFT", QuestLevelAndName, "BOTTOMLEFT", 0, -5)
				QuestTypeLabel:SetWordWrap(true)
				QuestTypeLabel:SetJustifyH("LEFT")
				QuestTypeLabel:SetJustifyV("TOP")
				QuestTypeLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
				--QuestTypeLabel:SetTextColor(153/255, 255/255, 255/255)  -- Light Blue
				QuestTypeLabel:SetTextColor(250/255, 128/255, 115/255)  -- Salmon

				-- Update the quest type label text
				QuestTypeLabel:SetText(questTypeText .. " @ " .. questZoneText)
				QuestLogIndexButton.QuestTypeLabel = QuestTypeLabel

				-- Create or reuse the QuestObjectivesOrDescription label
				local QuestObjectivesOrDescription = RQE.QuestLogIndexButtons[i].QuestObjectivesOrDescription or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				QuestObjectivesOrDescription:SetPoint("TOPLEFT", QuestTypeLabel, "BOTTOMLEFT", 0, -5)  -- 10 units of vertical spacing
				QuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				QuestObjectivesOrDescription:SetJustifyH("LEFT")
				QuestObjectivesOrDescription:SetJustifyV("TOP")
				QuestObjectivesOrDescription:SetWidth(RQEQuestFrame:GetWidth() - 110)
				QuestObjectivesOrDescription:SetHeight(0)  -- Auto height
				QuestObjectivesOrDescription:SetWordWrap(true)
				QuestObjectivesOrDescription:EnableMouse(true)

				-- Update the last element tracker for the correct type
				if isCampaignQuest then
					lastCampaignElement = QuestObjectivesOrDescription
				else  -- Regular quest
					lastQuestElement = QuestObjectivesOrDescription
				end

				QuestObjectivesOrDescription:SetScript("OnMouseDown", function(self, button)
					if button == "RightButton" then
						ShowQuestDropdown(self, questID)
					end
				end)

				-- Tooltip on mouseover
				QuestLevelAndName:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_LEFT", -50, -40)
					GameTooltip:SetMinimumWidth(350)
					GameTooltip:SetHeight(0)
					GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
					GameTooltip:SetText(info.title)

					GameTooltip:AddLine(" ")

					-- Add description
					local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
					if questLogIndex then
						local _, questObjectives = GetQuestLogQuestText(questLogIndex)
						local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
						GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
					end

					-- Add Direction Text
					local directionText = C_QuestLog.GetNextWaypointText(questID)
					RQE.infoLog("Debug - QuestID:", questID, "Direction Text:", directionText)
					if directionText and directionText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Next Step: " .. directionText, 0.81, 0.5, 1, true)
					else
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Next Step: [No additional information]", 0.81, 0.5, 1, true)
					end
					
					-- Add objectives
					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(objectivesText)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
					end

					-- Add Rewards
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Rewards: ")
					RQE:QuestRewardsTooltip(GameTooltip, questID, isBonus)
					GameTooltip:AddLine(" ")

					-- Party Members' Quest Progress
					if IsInGroup() then
						local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
						if tooltipData and tooltipData.lines then
							local player_name = UnitName("player")
							local isFirstPartyMember = true
							local skipPlayerLines = false
							local skipQuestNameLine = false  -- Flag to skip quest name lines

							for _, line in ipairs(tooltipData.lines) do
								if line.type == Enum.TooltipDataLineType.QuestTitle then  -- Assuming quest titles have this type
									skipQuestNameLine = true
								end

								if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText == player_name then
									skipPlayerLines = true
									isFirstPartyMember = false
								end

								if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText ~= player_name then
									skipPlayerLines = false
									skipQuestNameLine = false  -- Reset for the next quest
									if isFirstPartyMember then
										GameTooltip:AddLine(" ")
										isFirstPartyMember = false
									end
								end

								if not skipPlayerLines and not skipQuestNameLine then
									local text = line.leftText
									local r, g, b = line.leftColor:GetRGB()
									GameTooltip:AddLine(text, r, g, b, true)
								end
							end
						end
					end
					
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82) -- Aquamarine
					GameTooltip:Show()
				end)

				QuestObjectivesOrDescription:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_LEFT", -50, -40)
					GameTooltip:SetMinimumWidth(350)
					GameTooltip:SetHeight(0)
					GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
					GameTooltip:SetText(info.title)

					GameTooltip:AddLine(" ")

					-- Add description
					local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
					if questLogIndex then
						local _, questObjectives = GetQuestLogQuestText(questLogIndex)
						local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
						GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
					end
				
					-- Add Direction Text
					local directionText = C_QuestLog.GetNextWaypointText(questID)
					RQE.infoLog("Debug - QuestID:", questID, "Direction Text:", directionText)  -- Debug print
					if directionText and directionText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Next Step: " .. directionText, 0.81, 0.5, 1, true)
					else
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Next Step: [No additional information]", 0.81, 0.5, 1, true)
					end
	
					-- Add objectives
					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(objectivesText)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
					end

					-- Add Rewards
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Rewards: ")
					RQE:QuestRewardsTooltip(GameTooltip, questID, isBonus)
					GameTooltip:AddLine(" ")

					-- Party Members' Quest Progress
					if IsInGroup() then
						local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
						if tooltipData and tooltipData.lines then
							local player_name = UnitName("player")
							local isFirstPartyMember = true
							local skipPlayerLines = false
							local skipQuestNameLine = false  -- Flag to skip quest name lines

							for _, line in ipairs(tooltipData.lines) do
								if line.type == Enum.TooltipDataLineType.QuestTitle then  -- Assuming quest titles have this type
									skipQuestNameLine = true
								end

								if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText == player_name then
									skipPlayerLines = true
									isFirstPartyMember = false
								end

								if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText ~= player_name then
									skipPlayerLines = false
									skipQuestNameLine = false  -- Reset for the next quest
									if isFirstPartyMember then
										GameTooltip:AddLine(" ")
										isFirstPartyMember = false
									end
								end

								if not skipPlayerLines and not skipQuestNameLine then
									local text = line.leftText
									local r, g, b = line.leftColor:GetRGB()
									GameTooltip:AddLine(text, r, g, b, true)
								end
							end
						end
					end

					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82) -- Aquamarine
					GameTooltip:Show()
				end)

				-- Moved this block of code after the creation of QuestLevelAndName and QuestObjectivesOrDescription
				if QuestLevelAndName and QuestObjectivesOrDescription then
					local questLevelAndNameHeight = QuestLevelAndName:GetStringHeight()
					local questObjectivesOrDescriptionHeight = QuestObjectivesOrDescription:GetStringHeight()
					-- Your other code here, like calculating total height or setting positions
				end

				-- Check if objectivesText is blank
				if objectivesText and objectivesText ~= "" then
					-- Colorize each objective individually
					local colorizedObjectives = colorizeObjectives(objectivesText)
					QuestObjectivesOrDescription:SetText(colorizedObjectives)
				else
					-- If there are no objectives, set the text as is (fallback)
					QuestObjectivesOrDescription:SetText(questObjectivesText)
				end

				-- Save the FontString in a table for future reference
				RQE.QuestLogIndexButtons[i].QuestObjectivesOrDescription = QuestObjectivesOrDescription

				-- Show the label
				QuestObjectivesOrDescription:Show()

				-- Save the FontString in a table for future reference
				RQE.QuestLogIndexButtons[i].QuestLevelAndName = QuestLevelAndName

				-- Show the labels
				QuestLevelAndName:Show()

				-- Save the button in the table for future reference
				QuestLogIndexButton:Show()

				-- Update lastQuestObjectivesOrDescription for the next iteration
				lastQuestObjectivesOrDescription = QuestObjectivesOrDescription

				local elementHeight = QuestLogIndexButton:GetHeight()
				totalHeight = totalHeight + elementHeight + spacingBetweenElements
			end
		end
	end

	-- Check if any of the child frames should have their visibility removed as no quests being tracked
    RQE.CampaignFrame:SetShown(RQE.campaignQuestCount > 0)
    RQE.QuestsFrame:SetShown(RQE.regularQuestCount > 0)
    RQE.WorldQuestsFrame:SetShown(RQE.worldQuestCount > 0)
	
    -- After adding all quest items, update the total height of the content frame
    content:SetHeight(totalHeight)

    -- Call the function to reposition child frames again at the end
	UpdateFrameAnchors()
    UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)

	--UpdateHeader(RQE.ScenarioChildFrame, "", RQE.ScenarioChildFrame.questCount)  -- Add this line
    -- UpdateHeader(RQE.CampaignFrame, "Campaign", RQE.CampaignFrame.questCount)
    -- UpdateHeader(RQE.QuestsFrame, "Quests", RQE.QuestsFrame.questCount)
    -- UpdateHeader(RQE.WorldQuestsFrame, "World Quests", RQE.WorldQuestsFrame.questCount)

    UpdateHeader(RQE.CampaignFrame, "Campaign", RQE.campaignQuestCount)
    UpdateHeader(RQE.QuestsFrame, "Quests", RQE.regularQuestCount)
    UpdateHeader(RQE.WorldQuestsFrame, "World Quests", RQE.worldQuestCount)
	
    -- Update scrollbar range and visibility
    local scrollFrameHeight = RQE.QTScrollFrame:GetHeight()
    if totalHeight > scrollFrameHeight then
        RQE.QMQTslider:SetMinMaxValues(0, totalHeight - scrollFrameHeight)
        RQE.QMQTslider:Show()
    else
        RQE.QMQTslider:Hide()
    end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
end


-- Function to update the RQE.WorldQuestFrame with tracked World Quests
function UpdateRQEWorldQuestFrame()
    -- Define padding value
    local padding = 10 -- Example padding value
	local yOffset = -45 -- Y offset for the first element
	local sortedWorldQuests = GatherAndSortWorldQuestsByProximity()
	
    -- Hide all existing World Quest buttons first
    for i = 1, 50 do -- Assuming you won't have more than 50 World Quests tracked at once
        local button = RQE.WorldQuestsFrame["WQButton" .. i]
        if button then
            button:Hide()
            button.WQuestLevelAndName:Hide()
            button.QuestObjectivesOrDescription:Hide()
        end
    end

    -- Get the number of tracked World Quests
    local numTrackedWorldQuests = C_QuestLog.GetNumWorldQuestWatches()
    local lastWorldQuestElement = nil
	local usedQuestIDs = {}  -- Table to keep track of used quest IDs
	
    -- Loop through each tracked World Quest
    for i, questInfo in ipairs(sortedWorldQuests) do
        local questID = questInfo.questID
			
		-- Define WQuestLogIndexButton outside the if block
		local WQuestLogIndexButton = RQE.WorldQuestsFrame["WQButton" .. questID]

		if questID and C_QuestLog.IsWorldQuest(questID) and not usedQuestIDs[questID] then
			usedQuestIDs[questID] = true

			if not WQuestLogIndexButton then
				WQuestLogIndexButton = CreateFrame("Button", "WQButton" .. questID, RQE.WorldQuestsFrame)
				WQuestLogIndexButton:SetSize(35, 35)

				-- Create or update the background texture
				local bg = WQuestLogIndexButton.bg or WQuestLogIndexButton:CreateTexture(nil, "BACKGROUND")
				WQbg = bg
				WQbg:SetAllPoints()
				if isSuperTracked then
					bg:SetTexture("Interface\\AddOns\\RQE\\Textures\\UL_Sky_Floor_Light.blp")
				else
					bg:SetTexture("Interface\\Artifacts\\Artifacts-PerkRing-Final-Mask")
				end
				WQuestLogIndexButton.bg = WQbg  -- Save for future reference
			end
			
            -- Create or update the number label
            local WQnumber = WQuestLogIndexButton.number or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            WQnumber:SetPoint("CENTER", WQuestLogIndexButton, "CENTER")
            WQnumber:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            WQnumber:SetTextColor(1, 0.7, 0.2)
            WQnumber:SetText("WQ")
            WQuestLogIndexButton.number = WQnumber

			-- Modify the OnClick event
			WQuestLogIndexButton:SetScript("OnClick", function(self, button)
				if IsShiftKeyDown() and button == "LeftButton" then
					-- Untrack the quest
					C_QuestLog.RemoveWorldQuestWatch(questID)
					RQE.TrackedQuests[questID] = nil -- Update the tracking table
				else
					-- Existing code to set as super-tracked
					C_SuperTrack.SetSuperTrackedQuestID(questID)
					RQE.ManuallyTrackedQuests[questID] = true -- Set the manual tracking state
				end
			end)

			-- Add a mouse down event to simulate a button press
			WQuestLogIndexButton:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then
					self.bg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press
				end
			end)

			-- Add a mouse up event to reset the texture
			WQuestLogIndexButton:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" then
					self.bg:SetAlpha(1)  -- Reset the alpha
				end
			end)

			-- Fetch Quest Description and Objectives
			local _, questObjectivesText = GetQuestLogQuestText(questID)
			local objectivesTable = C_QuestLog.GetQuestObjectives(questID)
			local objectivesText = ""
			if objectivesTable then
				for _, objective in ipairs(objectivesTable) do
					objectivesText = objectivesText .. objective.text .. "\n"
				end
			end

			-- Apply colorization to objectivesText
			objectivesText = colorizeObjectives(objectivesText)

			-- Create or update the quest title label
			local WQuestLevelAndName = WQuestLogIndexButton.WQuestLevelAndName or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			WQuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
			WQuestLevelAndName:SetHeight(0)
			WQuestLevelAndName:SetJustifyH("LEFT")
			WQuestLevelAndName:SetJustifyV("TOP")
			WQuestLevelAndName:SetWidth(RQEQuestFrame:GetWidth() - 100)

			-- Retrieve the quest title using the quest ID
			local questTitle = C_QuestLog.GetTitleForQuestID(questID)

			-- Check if questTitle is not nil before setting the text
			if questTitle and questTitle ~= "" then
				WQuestLevelAndName:SetText("[WQ] " .. questTitle)
			else
				WQuestLevelAndName:SetText("[WQ] Unknown Quest")  -- Placeholder text or handle the case as needed
			end

			WQuestLogIndexButton.WQuestLevelAndName = WQuestLevelAndName

            -- Create QuestObjectives label
            local WQuestObjectives = WQuestLogIndexButton.QuestObjectives or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            WQuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            WQuestObjectives:SetWordWrap(true)
			WQuestObjectives:SetWidth(RQEQuestFrame:GetWidth() - 110)
            WQuestObjectives:SetHeight(0)
            WQuestObjectives:SetJustifyH("LEFT")
            WQuestObjectives:SetJustifyV("TOP")
            WQuestObjectives:SetText(objectivesText)
            WQuestLogIndexButton.QuestObjectives = WQuestObjectives
			
			-- Untrack World Quest
			WQuestLevelAndName:SetScript("OnMouseDown", function(self, button)
				if IsShiftKeyDown() and button == "LeftButton" then
					-- Untrack the quest
					C_QuestLog.RemoveQuestWatch(questID)
					RQE:ClearRQEQuestFrame()
					RQE:ClearWQTracking()
				elseif button == "RightButton" then
					ShowQuestDropdown(self, questID)
				end
			end)
				
			-- Position WQuestLogIndexButton relative to WQuestLevelAndName
			WQuestLogIndexButton:SetPoint("RIGHT", WQuestLevelAndName, "LEFT", -5, 0)

			-- Function to format time left based on seconds
			local function FormatTimeLeft(secondsLeft)
				if not secondsLeft then return "No time left info" end
				local days = math.floor(secondsLeft / (24 * 60 * 60))
				local hours = math.floor((secondsLeft % (24 * 60 * 60)) / (60 * 60))
				local minutes = math.floor((secondsLeft % (60 * 60)) / 60)
				local seconds = secondsLeft % 60

				local timeStrings = {}
				if days > 0 then table.insert(timeStrings, days .. " days") end
				if hours > 0 then table.insert(timeStrings, hours .. " hours") end
				if minutes > 0 or (days == 0 and hours == 0) then
					table.insert(timeStrings, minutes .. " min")
				end
				if secondsLeft < 60 then
					table.insert(timeStrings, seconds .. " sec")
				end

				return table.concat(timeStrings, ", ")
			end
		
			local WQuestTimeLeft = WQuestLogIndexButton.WQuestTimeLeft or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			WQuestTimeLeft:SetPoint("TOPLEFT", WQuestLevelAndName, "BOTTOMLEFT", 0, -5)
			WQuestTimeLeft:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			WQuestTimeLeft:SetTextColor(0.98, 0.5, 0.45)  -- Set the text color to Salmon
			WQuestTimeLeft:SetJustifyH("LEFT")
			--WQuestTimeLeft:SetWidth(RQE.WorldQuestsFrame:GetWidth() - 45)
			WQuestLogIndexButton.WQuestTimeLeft = WQuestTimeLeft
	
			-- Get the time left for the World Quest
			local secondsLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID)
			local timeLeftString = FormatTimeLeft(secondsLeft)  -- Ensure it always returns a string
			WQuestTimeLeft:SetText(timeLeftString)
			WQuestTimeLeft:Show()
			
			-- Inside your loop for updating World Quest frames:
			local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
			RQE.debugLog("DEBUG: Processing QuestID:", questID, "OnContinent:", onContinent, "DistanceSq:", distanceSq)
			local questDistanceText = "Distance: N/A"  -- Default text if distance is not available

			if distanceSq then  -- This condition now checks only for a valid distanceSq value
				local distance = math.sqrt(distanceSq)
				questDistanceText = string.format("Distance: %.2f", distance)
				RQE.debugLog("DEBUG: questDistance is " .. questDistanceText .. " for questID " .. questID)
			end

			-- Create or update the distance label
			local WQuestDistance = WQuestLogIndexButton.WQuestDistance or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			WQuestDistance:SetPoint("TOPLEFT", WQuestTimeLeft, "BOTTOMLEFT", 0, -5)
			WQuestDistance:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			WQuestDistance:SetJustifyH("LEFT")
			--WQuestDistance:SetWidth(RQE.WorldQuestsFrame:GetWidth() - 65)
			WQuestDistance:SetText(questDistanceText)
			WQuestLogIndexButton.WQuestDistance = WQuestDistance
			WQuestDistance:Show()

			-- Create QuestObjectivesOrDescription label
			local WQuestObjectivesOrDescription = WQuestLogIndexButton.QuestObjectivesOrDescription or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			WQuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
			WQuestObjectivesOrDescription:SetJustifyH("LEFT")
			WQuestObjectivesOrDescription:SetJustifyV("TOP")
			WQuestObjectivesOrDescription:SetHeight(0)
			WQuestObjectivesOrDescription:SetWordWrap(true)
			WQuestObjectivesOrDescription:SetWidth(RQEQuestFrame:GetWidth() - 110)
			WQuestObjectivesOrDescription:SetText(questObjectivesText)
			WQuestLogIndexButton.QuestObjectivesOrDescription = WQuestObjectivesOrDescription

			WQuestObjectivesOrDescription:SetScript("OnMouseDown", function(self, button)
				if button == "RightButton" then
					ShowQuestDropdown(self, questID)
				end
			end)
				
			-- Update the last element tracker for the correct type
			if isWorldQuest then
				lastWorldQuestElement = WQuestObjectivesOrDescription
			end
				
			-- Set position of the WQuestObjectives based on TimeLeft
			WQuestObjectives:SetPoint("TOPLEFT", WQuestDistance, "BOTTOMLEFT", 0, -5)
						
			-- Untrack World Quest
			WQuestLogIndexButton:SetScript("OnMouseDown", function(self, button)
				if IsShiftKeyDown() and button == "LeftButton" then
					-- Untrack the quest
					C_QuestLog.RemoveQuestWatch(questID)
				end
			end)

			-- Positioning logic for WQuestLevelAndName
			if i == 1 then
				-- If this is the first world quest, position it at the top left of the frame
				WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", 35, yOffset)
			else
				-- For the second and subsequent world quests, position them relative to the last world quest element
				if lastWorldQuestElement then
					WQuestLevelAndName:SetPoint("TOPLEFT", lastWorldQuestElement, "BOTTOMLEFT", 0, -padding)
				else
					-- Fallback to the top left position if for some reason the last element doesn't exist
					-- This should not happen if your world quest elements are handled correctly
					WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", 35, yOffset - (i * padding))
				end
			end
			
            -- Show the elements
            WQuestLevelAndName:Show()
            WQuestObjectivesOrDescription:Show()
            WQuestLogIndexButton:Show()
			WQuestObjectives:Show()
			
            --lastElement = WQuestObjectives  -- Update the last element for next iteration
			lastWorldQuestElement = WQuestObjectives  -- Update the last element for next iteration
			
			-- Set the mouseover tooltip for the World Quest button
			WQuestLevelAndName:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")  -- Anchor the tooltip to the cursor
				GameTooltip:ClearLines()

				-- Add the quest title
				GameTooltip:AddLine(questTitle)
				GameTooltip:AddLine(" ")  -- Blank line

					-- Add description
					local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)  -- Use questID instead of self.questID
					if questLogIndex then
						local _, questObjectives = GetQuestLogQuestText(questLogIndex)
						local descriptionText = questObjectives and questObjectives ~= "" and questObjectives or "No description available."
						GameTooltip:AddLine(descriptionText, 1, 1, 1, true)
					end

					-- Add objectives
					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(objectivesText)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
					end

					-- Add Rewards
					GameTooltip:AddLine("Rewards: ")
					RQE:QuestRewardsTooltip(GameTooltip, questID, isBonus)
					GameTooltip:AddLine(" ")

				-- Add time left
				local timeLeftString = FormatTimeLeft(C_TaskQuest.GetQuestTimeLeftSeconds(questID))  -- Make sure FormatTimeLeft function is defined as previously described
				if timeLeftString and timeLeftString ~= "" then
					GameTooltip:AddLine("Time Left: " .. timeLeftString, 1, 0.08, 0.58) -- Pink color
					GameTooltip:AddLine(" ")  -- Blank line
				end
				
				-- Add the quest ID
				GameTooltip:AddLine("Quest ID: " .. questID, 0.49, 1, 0.82)  -- Aquamarine color

				GameTooltip:Show()
			end)

			-- Party Members' Quest Progress
			if IsInGroup() then
				local tooltipData = C_TooltipInfo.GetQuestPartyProgress(questID)
				if tooltipData and tooltipData.lines then
					local player_name = UnitName("player")
					local isFirstPartyMember = true
					local skipPlayerLines = false
					local skipQuestNameLine = false  -- Flag to skip quest name lines

					for _, line in ipairs(tooltipData.lines) do
						if line.type == Enum.TooltipDataLineType.QuestTitle then  -- Assuming quest titles have this type
							skipQuestNameLine = true
						end

						if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText == player_name then
							skipPlayerLines = true
							isFirstPartyMember = false
						end

						if line.type == Enum.TooltipDataLineType.QuestPlayer and line.leftText ~= player_name then
							skipPlayerLines = false
							skipQuestNameLine = false  -- Reset for the next quest
							if isFirstPartyMember then
								GameTooltip:AddLine(" ")
								isFirstPartyMember = false
							end
						end

						if not skipPlayerLines and not skipQuestNameLine then
							local text = line.leftText
							local r, g, b = line.leftColor:GetRGB()
							GameTooltip:AddLine(text, r, g, b, true)
						end
					end
				end
			end
	
			WQuestLevelAndName:SetScript("OnLeave", function(self)
				GameTooltip:Hide()  -- Hide the tooltip when the mouse leaves the button
			end)
		
            -- Save the button in a table for future reference
            RQE.WorldQuestsFrame["WQButton" .. i] = WQuestLogIndexButton

			-- Adjust RQE.WorldQuestsFrame size based on the number of buttons
			if lastWorldQuestElement and lastWorldQuestElement:IsShown() then
				local bottomPosition = lastWorldQuestElement:GetBottom()
				if bottomPosition then
					local topPosition = RQE.WorldQuestsFrame:GetTop()
					if topPosition then
						local newHeight = bottomPosition - topPosition - padding
						RQE.WorldQuestsFrame:SetHeight(math.abs(newHeight))
					end
				end
			end
        end
    end
end


-- Function to add/remove tracked achievements into table
function RQE.UpdateTrackedAchievements(contentType, id, tracked)
    if contentType == 2 then -- Assuming "2" signifies an achievement
        if tracked then
            if not tContains(RQE.TrackedAchievementIDs, id) then
                table.insert(RQE.TrackedAchievementIDs, id)
            end
        else
            for i, trackedID in ipairs(RQE.TrackedAchievementIDs) do
                if trackedID == id then
                    table.remove(RQE.TrackedAchievementIDs, i)
                    break
                end
            end
        end
    end
    -- Call the update function to refresh the UI
    RQE.UpdateTrackedAchievementList()
end


-- Function to fetch and update the list of tracked achievements
function RQE.UpdateTrackedAchievementList()
    local achievementIDs = C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)
    RQE.TrackedAchievementIDs = achievementIDs -- Assuming RQE.TrackedAchievementIDs is initialized as a table somewhere
    -- Optionally, call a function to update your UI with the new list
    UpdateRQEAchievementsFrame()
end


-- Function to count the number of tracked achievements
function RQE.GetNumTrackedAchievements()
    -- Assuming RQE.TrackedAchievementIDs is a table that contains the achievement IDs that are being tracked
    local count = 0
    if RQE and RQE.TrackedAchievementIDs then
        for _ in pairs(RQE.TrackedAchievementIDs) do
            count = count + 1
        end
    end
    return count
end


-- Function to Update Achievements Frame
function UpdateRQEAchievementsFrame()
	RQE.AchievementsFrame.achieveCount = RQE.GetNumTrackedAchievements()
    -- Print the IDs of tracked achievements for debugging
    RQE.infoLog("Currently Tracked Achievements:")
    for _, achievementID in ipairs(RQE.TrackedAchievementIDs) do
        RQE.infoLog("- Achievement ID:", achievementID)
    end

    -- Clear the achievement ID list before updating
    RQE:ClearAchievementFrame()
	
    -- Initialize or clear the table that keeps track of achievement ID widgets
    RQE.AchievementsIDWidgets = RQE.AchievementsIDWidgets or {}
	
	-- Sets initial y-offset slightly below top of frame
    local offsetY = -45 -- Starting offset for the first achievement
    local spacing = 7 -- Space between achievements
    local textPadding = 55 -- Adjust this value to control word wrap width
	local availableWidth = RQE.AchievementsFrame:GetWidth() - textPadding
	
    -- Loop through each tracked achievement ID and display it along with the description
    for _, achievementID in ipairs(RQE.TrackedAchievementIDs) do
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(achievementID)

        if id then
            -- Create the header for each achievement
            local achievementHeader = RQE.AchievementsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            achievementHeader:SetPoint("TOPLEFT", RQE.AchievementsFrame, "TOPLEFT", 10, offsetY)
            achievementHeader:SetText("[" .. id .. "] " .. name)
            achievementHeader:SetTextColor(1, 0.5, 0.3) -- Tan color for the achievement ID and name
            --achievementHeader:SetWidth(RQE.AchievementsFrame:GetWidth() - textPadding)
            achievementHeader:SetJustifyH("LEFT")
            
            -- Set up the tooltip for the achievement header
			achievementHeader:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(name, 1, 1, 0, 1) -- Yellow title
				if rewardText and rewardText ~= "" then
					GameTooltip:AddLine(rewardText, 0, 0.5, 1, 1) -- Light Blue reward text
					GameTooltip:AddLine(" ") -- Spacer
				end
				GameTooltip:AddLine(description, 1, 0.7, 0.7, true) -- Light Pink description
				GameTooltip:AddLine(" ") -- Spacer
				
                -- Add criteria info
                local numCriteria = GetAchievementNumCriteria(id)
                for criteriaIndex = 1, numCriteria do
                    local criteriaString, criteriaType, criteriaCompleted = GetAchievementCriteriaInfo(id, criteriaIndex)
                    if criteriaCompleted then
                        GameTooltip:AddLine("- " .. criteriaString, 0, 1, 0) -- Green for completed criteria
                    else
                        GameTooltip:AddLine("- " .. criteriaString, 1, 1, 1) -- White for incomplete criteria
                    end
                end

				GameTooltip:AddLine(" ")
                if wasEarnedByMe then
					GameTooltip:AddLine("Achivement completed by " .. UnitName("player"), 0, 1, 0, true) -- Green Text
				else
                    GameTooltip:AddLine("In progress by " .. UnitName("player"), 0, 1, 0, true)
                end
                GameTooltip:AddLine("Achievement ID: " .. id, 1, 0.75, 0.35, true)
                GameTooltip:Show()
            end)
            achievementHeader:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

			-- Set up the clickable action for the achievement header
			achievementHeader:EnableMouse(true)
			achievementHeader:SetScript("OnMouseUp", function(self, button)
				if button == "LeftButton" then
					if not IsAddOnLoaded("Blizzard_AchievementUI") then
						LoadAddOn("Blizzard_AchievementUI")
					end
					if AchievementFrame then
						if not AchievementFrame:IsShown() then
							AchievementFrame_ToggleAchievementFrame()
						end
						AchievementFrame_SelectAchievement(id)
					end
				end
			end)
		
            offsetY = offsetY - achievementHeader:GetStringHeight() - spacing -- Adjust offsetY for the header and additional spacing

            -- Loop through criteria
            local numCriteria = GetAchievementNumCriteria(id)
            for criteriaIndex = 1, numCriteria do
                local criteriaString, criteriaType, criteriaCompleted = GetAchievementCriteriaInfo(id, criteriaIndex)

                -- Create a FontString for each criteria
                local criteriaText = RQE.AchievementsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                --criteriaText:SetWidth(RQE.AchievementsFrame:GetWidth() - textPadding)
				criteriaText:SetWidth(availableWidth)
                criteriaText:SetJustifyH("LEFT")
                criteriaText:SetPoint("TOPLEFT", RQE.AchievementsFrame, "TOPLEFT", 10, offsetY)
				criteriaText:SetHeight(criteriaText:GetStringHeight())
				criteriaText:SetWordWrap(true)

                -- Set color based on completion status
                if criteriaCompleted then
                    criteriaText:SetTextColor(0, 1, 0) -- Green color for completed criteria
                else
                    criteriaText:SetTextColor(1, 1, 1) -- White color for incomplete criteria
                end

                criteriaText:SetText("- " .. criteriaString)
                offsetY = offsetY - criteriaText:GetStringHeight() - spacing -- Adjust offsetY for each criteria line and additional spacing
            end

            -- Add extra spacing between different achievements
            offsetY = offsetY - spacing
        end
    end

    -- After creating each new FontString, insert it into RQE.AchievementsIDWidgets:
    table.insert(RQE.AchievementsIDWidgets, achievementHeader)

	-- Check if any achievements in the Achievement Frame are being tracked/watched
	RQE.AchievementsFrame:SetShown(RQE.AchievementsFrame.achieveCount > 0)
	
    -- Update the scroll frame range if necessary
    if RQE.AchievementsFrame.scrollFrame then
        RQE.AchievementsFrame.scrollFrame:SetVerticalScrollRange(math.abs(offsetY))
    end
	
	-- Visibility Update Check for RQEQuestFrame
	RQE:UpdateRQEQuestFrameVisibility()
end