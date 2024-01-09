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
--QMQTslider:Hide()

RQE.QMQTslider = QMQTslider

QMQTslider:SetScript("OnValueChanged", function(self, value)
    RQE.QTScrollFrame:SetVerticalScroll(value)
end)

ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local value = QMQTslider:GetValue()
    if delta > 0 then
        QMQTslider:SetValue(value - 20)
    else
        QMQTslider:SetValue(value + 20)
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

-- -- New function to get World Quest Info
-- function AddWorldQuestToFrame(questID, parentFrame)
    -- -- Assume you have a function or a way to get the correct uiMapID for the given questID
    -- local uiMapID = C_TaskQuest.GetQuestZoneID(questID)

	-- print("QuestID:", questID, "uiMapID:", uiMapID)

    -- -- Check if uiMapID is available
    -- if not uiMapID then
        -- print("Error: uiMapID not available for questID:", questID)
        -- return
    -- end
    
    -- -- Now you can safely call GetQuestLocation
    -- local x, y = C_TaskQuest.GetQuestLocation(questID, uiMapID)
    -- if not x or not y then
        -- print("Error: Could not get location for questID:", questID, "on uiMapID:", uiMapID)
        -- return
    -- end
	
    -- local taskQuestTitle, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID)
    -- local locationX, locationY = C_TaskQuest.GetQuestLocation(questID, uiMapID) -- Ensure uiMapID is correct

    -- local questFrame = CreateFrame("Frame", "WorldQuest" .. questID, parentFrame, "BackdropTemplate")
    -- questFrame:SetSize(200, 30) -- Adjust size as needed
    -- questFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -30 * (questID % 5)) -- Position it; adjust as needed
    -- questFrame:SetBackdrop({ -- Set a backdrop for visibility during debugging
        -- bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        -- edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        -- tile = true, tileSize = 16, edgeSize = 16,
        -- insets = { left = 4, right = 4, top = 4, bottom = 4 }
    -- })
    -- questFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8) -- Dark background for visibility
    -- questFrame:Show() -- Ensure the frame is shown

    -- local titleText = questFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- titleText:SetPoint("LEFT", questFrame, "LEFT", 5, 0)
    -- titleText:SetText(taskQuestTitle)
    -- titleText:Show() -- Ensure the text is shown

    -- print("Adding World Quest to frame:", questID, taskQuestTitle)

    -- -- Debug: Check if the parent frame is visible
    -- if not parentFrame:IsVisible() then
        -- print("Parent frame is not visible.")
    -- end

    -- return questFrame
-- end

-- function RQE.UpdateWorldQuestsFrame(questID, added)
    -- if added then
        -- -- Logic to add the World Quest to the RQE.WorldQuestsFrame
        -- local questFrame = AddWorldQuestToFrame(questID, RQE.WorldQuestsFrame)
        -- -- Position the questFrame within RQE.WorldQuestsFrame
        -- -- ...
    -- else
        -- -- Logic to remove the World Quest from the RQE.WorldQuestsFrame
        -- -- ...
    -- end
-- end

-- Your function to update the RQEQuestFrame
function UpdateRQEQuestFrame()
    local campaignQuestCount, regularQuestCount, worldQuestCount = 0, 0, 0
    local baseHeight = 100 -- Base height when no quests are present
    local questHeight = 50 -- Height per quest
    local spacingBetweenElements = 5

    -- Loop through all tracked quests to count campaign and world quests
    local numTrackedQuests = C_QuestLog.GetNumQuestWatches()
    for i = 1, numTrackedQuests do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if C_CampaignInfo.IsCampaignQuest(questID) then
            campaignQuestCount = campaignQuestCount + 1
        elseif C_QuestLog.IsWorldQuest(questID) then
            worldQuestCount = worldQuestCount + 1
        end
    end

    -- Calculate the number of regular quests
    regularQuestCount = numTrackedQuests - (campaignQuestCount + worldQuestCount)

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
			
        if questIndex then
            local info = C_QuestLog.GetInfo(questIndex)
            if info and not info.isHeader then
                -- Determine the type of the quest (Campaign, World Quest, or Regular)
                local isCampaignQuest = C_CampaignInfo.IsCampaignQuest(questID)
                local isWorldQuest = C_QuestLog.IsWorldQuest(questID)

				-- Check if it's a World Quest
				if isWorldQuest then
					-- Get the World Quest information
					--local questTitle, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID)
					local questTitle = C_TaskQuest.GetQuestInfoByQuestID(questID)
					local worldQuestFrame = CreateWorldQuestFrame(questID, RQE.WorldQuestsFrame, questTitle)
				end
			
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
                        C_QuestLog.RemoveWorldQuestWatch(questID)
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
				if isWorldQuest then
					-- Get world quest title and set level to 'WQ' or similar
					questTitle = C_TaskQuest.GetQuestInfoByQuestID(questID)
					questLevel = "WQ"
				else
					-- Use the regular quest title and level
					questTitle = info.title
					questLevel = info.level
				end
			
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
                        C_QuestLog.RemoveWorldQuestWatch(questID)
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