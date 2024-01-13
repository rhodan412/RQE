-- QuestingModule.lua
-- For advanced quest tracking features linked with RQEFrame

-- Initialize RQE global table
RQE = RQE or {}
RQE.modules = RQE.modules or {}

if RQE and RQE.debugLog then
    RQE.debugLog("Your message here")
else
    print("RQE or RQE.debugLog is not initialized.")
end

-- Assuming AceGUI is already loaded and RQE is initialized
local AceGUI = LibStub("AceGUI-3.0")


-- Create the frame
RQE.RQEQuestFrame = CreateFrame("Frame", "RQEQuestFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local frame = RQE.RQEQuestFrame

-- Frame properties
local xPos, yPos
if RQE and RQE.db and RQE.db.profile and RQE.db.profile.QuestFramePosition then
    xPos = RQE.db.profile.QuestFramePosition.xPos or -40  -- Default x position
    yPos = RQE.db.profile.QuestFramePosition.yPos or 125  -- Default y position
else
    xPos = -40  -- Default x position if db is not available
    yPos = 125  -- Default y position if db is not available
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
--RQEQuestFrame:SetBackdropColor(0, 0, 0, 0.5)  -- this was before the change to allow the user to make the QuestingFrame opacity change


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
end)
RQE.QTResizeButton = resizeBtn


-- Title text in a custom header
local header = CreateFrame("Frame", "RQEFrameHeader", RQEQuestFrame, "BackdropTemplate")
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
--QMQTslider:Show()

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


-- Create buttons using functions from Buttons.lua for RQEQuestFrame
RQE.Buttons.CreateQuestCloseButton(RQEQuestFrame)
RQE.Buttons.CreateQuestMaximizeButton(RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)
RQE.Buttons.CreateQuestMinimizeButton(RQEQuestFrame, RQE.QToriginalWidth, RQE.QToriginalHeight, RQE.QTcontent, RQE.QTScrollFrame, RQE.QMQTslider)


local function CreateChildFrame(name, parent, offsetX, offsetY, width, height)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetSize(width, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, offsetY)
    return frame
end

-- Create the first child frame, anchored to the content frame
RQE.CampaignFrame = CreateChildFrame("RQECampaignFrame", content, 0, 0, content:GetWidth(), 200)

-- Create the second child frame, anchored below the CampaignFrame
RQE.QuestsFrame = CreateChildFrame("RQEQuestsFrame", content, 0, -200, content:GetWidth(), 200) -- Adjust the Y-offset based on your layout

-- Create the third child frame, anchored below the QuestsFrame
RQE.WorldQuestsFrame = CreateChildFrame("RQEWorldQuestsFrame", content, 0, -400, content:GetWidth(), 200) -- Adjust the Y-offset based on your layout

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

-- Create headers for each child frame
RQE.CampaignFrame.header = CreateChildFrameHeader(RQE.CampaignFrame, "Campaign")
RQE.QuestsFrame.header = CreateChildFrameHeader(RQE.QuestsFrame, "Quests")
RQE.WorldQuestsFrame.header = CreateChildFrameHeader(RQE.WorldQuestsFrame, "World Quests")

-- Initialize with default values
RQE.CampaignFrame.questCount = RQE.CampaignFrame.questCount or 0
RQE.QuestsFrame.questCount = RQE.QuestsFrame.questCount or 0
RQE.WorldQuestsFrame.questCount = RQE.WorldQuestsFrame.questCount or 0

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


-- Function to create and position the ScrollFrame's child frames
function SortQuestsByProximity()
    -- Logic to sort quests based on proximity
    C_QuestLog.SortQuestWatches()
end


-- Define the function to save frame position
function SaveQuestFramePosition()
    local point, relativeTo, relativePoint, xOfs, yOfs = RQEQuestFrame:GetPoint()
    RQE.db.profile.QuestFramePosition.xPos = xOfs
    RQE.db.profile.QuestFramePosition.yPos = yOfs
    RQE.db.profile.QuestFramePosition.anchorPoint = relativePoint
end


-- Calls function to save Quest Frame Position OnDragStop
RQEQuestFrame:SetScript("OnDragStop", function()
    RQEQuestFrame:StopMovingOrSizing()
    SaveQuestFramePosition()  -- This will save the current frame position
end)


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
function AddQuestRewardsToTooltip(tooltip, questID, isBonus)
    local SelectedQuestID = C_QuestLog.GetSelectedQuest()  -- backup selected Quest
    C_QuestLog.SetSelectedQuest(questID)  -- for num Choices

    local xp = GetQuestLogRewardXP(questID)
    local money = GetQuestLogRewardMoney(questID)
    local artifactXP = GetQuestLogRewardArtifactXP(questID)
    local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID)
    local numQuestRewards = GetNumQuestLogRewards(questID)
    local numQuestSpellRewards, questSpellRewards = C_QuestInfoSystem.GetQuestRewardSpells(questID)
    local numQuestChoices = GetNumQuestLogChoices(questID, true)
    local honor = GetQuestLogRewardHonor(questID)
    local majorFactionRepRewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
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
    if C_CampaignInfo.IsCampaignQuest(questID) then
        return "Campaign"
    elseif C_QuestLog.IsWorldQuest(questID) then
        return "World Quest"
    elseif C_QuestLog.IsQuestTrivial(questID) then
        return "Trivial"
    elseif C_QuestLog.IsThreatQuest(questID) then
        return "Bonus Quest"
    elseif C_QuestLog.IsRepeatableQuest(questID) then
        return "Repeatable"
    else
        return "Regular Quest"
    end
end


-- Set ChildFrames to Default Anchors
local function ResetChildFramesToDefault()
    -- Resetting child frames to default positions
    RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -5)
    RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -5)
end


-- Adjust Set Point Anchor of Child Frames based on LastElements
function UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)
    -- Reset positions to default first
	ResetChildFramesToDefault()

    -- Adjusting Quests child frame position based on last campaign element
    if lastCampaignElement then
        RQE.QuestsFrame:SetPoint("TOPLEFT", lastCampaignElement, "BOTTOMLEFT", -40, -15)
    end

    -- Adjusting WorldQuests child frame position based on last quest element
    if lastQuestElement then
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", lastQuestElement, "BOTTOMLEFT", -40, -15)
    elseif lastCampaignElement then
        -- If there are no regular quests, but there are campaign quests
        RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -15)
    end
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
    local baseHeight = 100 -- Base height when no quests are present
    local questHeight = 50 -- Height per quest
    local spacingBetweenElements = 5

    -- Loop through all tracked quests to count campaign and world quests
    local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
	local worldQuestCount = C_QuestLog.GetNumWorldQuestWatches()
    for i = 1, numTrackedQuests do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if C_CampaignInfo.IsCampaignQuest(questID) then
            campaignQuestCount = campaignQuestCount + 1
        end
    end

    -- Calculate the number of regular quests
    regularQuestCount = numTrackedQuests - campaignQuestCount

    -- Calculate frame heights
    local campaignHeight = baseHeight + (campaignQuestCount * questHeight)
    local regularHeight = baseHeight + (regularQuestCount * questHeight)
    local worldQuestHeight = baseHeight + (worldQuestCount * questHeight)

    -- Update frame heights
    RQE.CampaignFrame:SetHeight(campaignHeight)
    RQE.QuestsFrame:SetHeight(regularHeight)
    RQE.WorldQuestsFrame:SetHeight(worldQuestHeight)

    -- Update total content height
    local totalHeight = campaignHeight + regularHeight + worldQuestHeight
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

    -- Initialize default positions
    RQE.QuestsFrame:SetPoint("TOPLEFT", RQE.CampaignFrame, "BOTTOMLEFT", 0, -10)
    RQE.WorldQuestsFrame:SetPoint("TOPLEFT", RQE.QuestsFrame, "BOTTOMLEFT", 0, -10)

    -- Separate variables to track the last element in each child frame
    local lastCampaignElement, lastQuestElement, lastWorldQuestElement = nil, nil, nil
		
		-- Loop through all tracked quests
		for i = 1, numTrackedQuests do
		local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
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

				-- Call the function to update child frame positions
				UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)

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
						RQE.infoLog("Untracking quest:", info.title)  -- Optional: print a message to the chat
					else
						-- Existing code to set as super-tracked
						C_SuperTrack.SetSuperTrackedQuestID(questID)
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
				QuestObjectives:SetHeight(0)  -- Auto height
				QuestObjectives:SetText(objectivesText)

				RQE.QuestLogIndexButtons[i].QuestObjectives = QuestObjectives

				-- Create or reuse the QuestLevelAndName label
				local QuestLevelAndName = RQE.QuestLogIndexButtons[i].QuestLevelAndName or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal", content)
				QuestLogIndexButton.QuestLevelAndName = QuestLevelAndName
				QuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
				QuestLevelAndName:SetTextColor(209/255, 125/255, 255/255)  -- Heliotrope
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
				QuestLevelAndName:SetWidth(RQEQuestFrame:GetWidth() - 30)  -- -10 for padding
				QuestLevelAndName:SetHeight(0)  -- Auto height
				QuestLevelAndName:EnableMouse(true)

				QuestLevelAndName:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)

				-- Quest Type
				local questTypeText = GetQuestType(questID)
				local QuestTypeLabel = QuestLogIndexButton.QuestTypeLabel or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				QuestTypeLabel:SetPoint("TOPLEFT", QuestLevelAndName, "BOTTOMLEFT", 0, -5)
				QuestTypeLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
				QuestTypeLabel:SetTextColor(153/255, 255/255, 255/255)  -- Light Blue
				QuestTypeLabel:SetText(questTypeText)
				QuestLogIndexButton.QuestTypeLabel = QuestTypeLabel

				-- Create or reuse the QuestObjectivesOrDescription label
				local QuestObjectivesOrDescription = RQE.QuestLogIndexButtons[i].QuestObjectivesOrDescription or QuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				QuestObjectivesOrDescription:SetPoint("TOPLEFT", QuestTypeLabel, "BOTTOMLEFT", 0, -5)  -- 10 units of vertical spacing
				QuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
				QuestObjectivesOrDescription:SetJustifyH("LEFT")
				QuestObjectivesOrDescription:SetJustifyV("TOP")
				QuestObjectivesOrDescription:SetHeight(0)  -- Auto height
				QuestObjectivesOrDescription:EnableMouse(true)

				-- Update the last element tracker for the correct type
				if isCampaignQuest then
					lastCampaignElement = QuestObjectivesOrDescription
				elseif isWorldQuest then
					lastWorldQuestElement = QuestObjectivesOrDescription
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

					-- Add objectives
					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(objectivesText)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
					end

					-- Add Rewards
					GameTooltip:AddLine("Rewards: ")
					AddQuestRewardsToTooltip(GameTooltip, questID, isBonus)
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

					if objectivesText and objectivesText ~= "" then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine("Objectives:")

						local colorizedObjectives = colorizeObjectives(objectivesText)
						GameTooltip:AddLine(colorizedObjectives, 1, 1, 1, true)
					end

					-- Add Rewards
					AddQuestRewardsToTooltip(GameTooltip, questID, isBonus)
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
				else
					-- Debug or error log
					print("Debug: QuestLevelAndName or QuestObjectivesOrDescription is nil.")
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

    -- After adding all quest items, update the total height of the content frame
    content:SetHeight(totalHeight)

    -- Call the function to reposition child frames again at the end
    UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement)

    UpdateHeader(RQE.CampaignFrame, "Campaign", RQE.CampaignFrame.questCount)
    UpdateHeader(RQE.QuestsFrame, "Quests", RQE.QuestsFrame.questCount)
    UpdateHeader(RQE.WorldQuestsFrame, "World Quests", RQE.WorldQuestsFrame.questCount)

    -- Update scrollbar range and visibility
    local scrollFrameHeight = RQE.QTScrollFrame:GetHeight()
    if totalHeight > scrollFrameHeight then
        RQE.QMQTslider:SetMinMaxValues(0, totalHeight - scrollFrameHeight)
        RQE.QMQTslider:Show()
    else
        RQE.QMQTslider:Hide()
    end
end


-- Function to update the RQE.WorldQuestFrame with tracked World Quests
function UpdateRQEWorldQuestFrame()
    -- Define padding value
    local padding = 25 -- Example padding value
	local yOffset = -45 -- Y offset for the first element
	
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
    local lastElement
	
    -- Loop through each tracked World Quest
    for i = 1, numTrackedWorldQuests do
        -- Get the quest ID of the tracked World Quest
        local questID = C_QuestLog.GetQuestIDForWorldQuestWatchIndex(i)
			
        if questID and C_QuestLog.IsWorldQuest(questID) then
            -- Get the quest title and other necessary details
            local questTitle = C_QuestLog.GetTitleForQuestID(questID)
            -- Create or reuse the World Quest Log Index Button
            local WQuestLogIndexButton = RQE.WorldQuestsFrame["WQButton" .. i] or CreateFrame("Button", "WQButton" .. i, RQE.WorldQuestsFrame)
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
					RQE.infoLog("Untracking quest:", questTitle)  -- Replace 'info.title' with 'questTitle'
				else
					-- Existing code to set as super-tracked
					C_SuperTrack.SetSuperTrackedQuestID(questID)
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
            local objectivesText = objectivesTable and "" or "No objectives available."
            for _, objective in ipairs(objectivesTable or {}) do
                objectivesText = objectivesText .. objective.text .. "\n"
            end

            -- Create QuestObjectives label
            local WQuestObjectives = WQuestLogIndexButton.QuestObjectives or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            WQuestObjectives:SetPoint("TOPLEFT", WQuestLevelAndName, "BOTTOMLEFT", 0, -5)
            WQuestObjectives:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            WQuestObjectives:SetWordWrap(true)
            WQuestObjectives:SetHeight(0)
            WQuestObjectives:SetText(objectivesText)
            WQuestLogIndexButton.QuestObjectives = WQuestObjectives
			
            -- Create or update the quest title label
            local WQuestLevelAndName = WQuestLogIndexButton.WQuestLevelAndName or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            WQuestLevelAndName:SetPoint("TOP", RQE.WorldQuestsFrame, "BOTTOM", 0, -5)
            WQuestLevelAndName:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            WQuestLevelAndName:SetText("[WQ] " .. questTitle)
            WQuestLogIndexButton.WQuestLevelAndName = WQuestLevelAndName

			-- Untrack World Quest
			WQuestLevelAndName:SetScript("OnMouseDown", function(self, button)
				if IsShiftKeyDown() and button == "LeftButton" then
					-- Untrack the quest
					C_QuestLog.RemoveQuestWatch(questID)
					RQE:ClearRQEQuestFrame()
					QuestType()
				end
			end)
			
            -- Create QuestObjectivesOrDescription label
            local WQuestObjectivesOrDescription = WQuestLogIndexButton.QuestObjectivesOrDescription or WQuestLogIndexButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            WQuestObjectivesOrDescription:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            WQuestObjectivesOrDescription:SetJustifyH("LEFT")
            WQuestObjectivesOrDescription:SetJustifyV("TOP")
            WQuestObjectivesOrDescription:SetHeight(0)
            WQuestObjectivesOrDescription:SetText(questObjectivesText)
            WQuestLogIndexButton.QuestObjectivesOrDescription = WQuestObjectivesOrDescription

			-- Position QuestObjectivesOrDescription based on whether WQuestObjectives has text
			if WQuestObjectives:GetText() ~= "" then
				WQuestObjectivesOrDescription:SetPoint("TOPLEFT", WQuestObjectives, "BOTTOMLEFT", 0, -5)
			else
				WQuestObjectivesOrDescription:SetPoint("TOPLEFT", WQuestLevelAndName, "BOTTOMLEFT", 0, -5)
			end

			-- Untrack World Quest
			WQuestLogIndexButton:SetScript("OnMouseDown", function(self, button)
				if IsShiftKeyDown() and button == "LeftButton" then
					-- Untrack the quest
					C_QuestLog.RemoveQuestWatch(questID)
				end
			end)

        -- Positioning logic for WQuestLevelAndName
		if i == 1 then
			WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", 35, yOffset)
		else
			local previousWQButton = RQE.WorldQuestsFrame["WQButton" .. (i-1)]
			if previousWQButton and previousWQButton.WQuestLevelAndName then
				WQuestLevelAndName:SetPoint("TOPLEFT", previousWQButton.WQuestLevelAndName, "BOTTOMLEFT", 0, -padding)
			else
				WQuestLevelAndName:SetPoint("TOPLEFT", RQE.WorldQuestsFrame, "TOPLEFT", 35, yOffset - (i * padding))
			end
		end

		WQuestLogIndexButton:SetPoint("RIGHT", WQuestLevelAndName, "LEFT", -5, 0)

        -- Position WQuestLogIndexButton relative to WQuestLevelAndName
        WQuestLogIndexButton:SetPoint("RIGHT", WQuestLevelAndName, "LEFT", -5, 0)

            -- Show the elements
            WQuestLevelAndName:Show()
            WQuestObjectivesOrDescription:Show()
            WQuestLogIndexButton:Show()

            lastElement = WQuestLevelAndName

            -- Show the button
            WQuestLogIndexButton:Show()
			
            lastElement = WQuestObjectivesOrDescription  -- Update the last element for next iteration
			
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

				-- Add rewards (you'll need to define this function according to your requirements)
				GameTooltip:AddLine("Rewards: ")
				AddQuestRewardsToTooltip(GameTooltip, questID)
				GameTooltip:AddLine(" ")  -- Blank line
				
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
	
			WQuestLogIndexButton:SetScript("OnLeave", function(self)
				GameTooltip:Hide()  -- Hide the tooltip when the mouse leaves the button
			end)
		
            -- Save the button in a table for future reference
            RQE.WorldQuestsFrame["WQButton" .. i] = WQuestLogIndexButton

			-- Adjust RQE.WorldQuestsFrame size based on the number of buttons
			if lastElement then
				local newHeight = lastElement:GetBottom() - RQE.WorldQuestsFrame:GetTop() - padding
				RQE.WorldQuestsFrame:SetHeight(math.abs(newHeight))
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
                else
                    -- Debug log for elements that don't match the criteria
                    print("Element skipped:", i, type(WQuestLogIndexButton.GetName), type(WQuestLogIndexButton:GetName()))
                end
            end
        end
    end
end


-- Event to update text widths when the frame is resized
RQEQuestFrame:SetScript("OnSizeChanged", function(self, width, height)
	AdjustQuestItemWidths(width)
end)


-- Function used to adjust the Questing Frame width
function AdjustQuestItemWidths(frameWidth)
    for i, button in pairs(RQE.QuestLogIndexButtons or {}) do
        if button.QuestLevelAndName then  -- Check if QuestLevelAndName is initialized
            button.QuestLevelAndName:SetWidth(frameWidth - 80)  -- Adjust the padding as needed
            button.QuestLevelAndName:SetWordWrap(true)  -- Ensure word wrap
            button.QuestLevelAndName:SetHeight(0)
        end

        if button.QuestObjectivesOrDescription then  -- Check if QuestObjectivesOrDescription is initialized
            button.QuestObjectivesOrDescription:SetWidth(frameWidth - 80)  -- Adjust the padding as needed
            button.QuestObjectivesOrDescription:SetWordWrap(true)  -- Ensure word wrap
            button.QuestObjectivesOrDescription:SetHeight(0)
        end
    end
end


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

    local menuFrame = CreateFrame("Frame", "RQEQuestDropdown", UIParent, "UIDropDownMenuTemplate")
    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end