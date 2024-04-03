-- QuestButton.lua

RQE = RQE or {}
RQE.QuestButtons = RQE.QuestButtons or {}


-- Create the Buttons for the Tracked Quests
function RQE:CreateQuestItemButton(index)
    print("Creating Quest Item Button for index:", index)
    local button = CreateFrame("Button", "RQEQuestItemButton" .. index, UIParent, "SecureActionButtonTemplate, SecureHandlerBaseTemplate")
    button:SetSize(36, 36)
    button:SetAttribute("type", "item")
    button:RegisterForClicks("AnyUp")

    -- Setting up the texture for the button
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    button.icon = icon

    questItemButtons[index] = button -- Store the button for future reference
    return button
end


function RQE:FindSuperTrackedQuestItem()
    print("Finding Super Tracked Quest Item")
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    if not superTrackedQuestID then return nil end

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then
                local isQuestItem, questID = C_Container.GetContainerItemQuestInfo(bag, slot)
                if isQuestItem and questID == superTrackedQuestID then
                    return C_Item.GetItemLocation(ItemLocation:CreateFromBagAndSlot(bag, slot)), link
                end
            end
        end
    end
    return nil, nil
end



function RQE:GetQuestItemButton(index)
    if not RQE.QuestButtons[index] then
        RQE.QuestButtons[index] = self:CreateQuestItemButton(index)
    end
    return RQE.QuestButtons[index]
end




-- Position the QuestItemButton to the left of the QuestLogIndexButton(i)
function RQE:PositionQuestItemButtons()
    print("Positioning Quest Item Buttons")
    for i, button in ipairs(RQE.QuestButtons) do -- Updated to use RQE.QuestButtons
        local questLogButton = _G["QuestLogIndexButton" .. i] -- Ensure this matches your naming convention
        if questLogButton then
            button:ClearAllPoints()
            button:SetPoint("LEFT", questLogButton, "RIGHT", 10, 0)
            button:Show()
        else
            button:Hide()
        end
    end
end


function RQE:UpdateQuestItemButtonForSuperTrackedQuest()
    print("Updating Quest Item Button for Super Tracked Quest")
    local superTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
    if not superTrackedQuestID then
        print("No super-tracked quest.")
        return
    end
    
    local itemLocation, link = self:FindSuperTrackedQuestItem()
    if itemLocation then
        local button = self:GetQuestItemButton(1) -- Assuming this is correct
        local icon = C_Item.GetItemIcon(itemLocation)
        if icon then
            print("Setting icon:", icon)
            button.icon:SetTexture(icon)
            button:SetAttribute("item", link)
            button:SetFrameStrata("TOOLTIP")
            button:Show()
        else
            print("ICON NOT FOUND")
        end
    else
        print("ITEM LOCATION MAY NOT EXIST")
    end
end





function RQE:RefreshQuestItemButtons()
    print("Refreshing Quest Item Buttons")
    local numTrackedQuests = GetNumTrackedQuests() -- This placeholder needs your actual implementation
    for i = 1, numTrackedQuests do
        local questID = GetTrackedQuestID(i) -- Adjust to your method
        local button = self:GetQuestItemButton(i)
        -- Assuming UpdateQuestItemButton exists and is adjusted for the RQE namespace
        self:UpdateQuestItemButton(button, questID)
    end
    -- Hide any extra buttons
    for i = numTrackedQuests + 1, #RQE.QuestButtons do
        if RQE.QuestButtons[i] then
            RQE.QuestButtons[i]:Hide()
        end
    end
    self:PositionQuestItemButtons()
end



local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    RQE:UpdateQuestItemButtonForSuperTrackedQuest()
    RQE:PositionQuestItemButtons()
end)