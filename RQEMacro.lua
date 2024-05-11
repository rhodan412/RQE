-- RQEMacro.lua

RQEMacro = RQEMacro or {}
RQEMacro.pendingMacroSets = {} -- Queue for macro set operations
RQEMacro.pendingMacroOperations = RQEMacro.pendingMacroOperations or {}
RQEMacro.pendingMacroClears = RQEMacro.pendingMacroClears or {}  -- Queue to hold macro names pending clearance

RQEMacro.MAX_ACCOUNT_MACROS, RQEMacro.MAX_CHARACTER_MACROS = 120, 18 -- Adjust these values according to the game's current limits
RQEMacro.QUEST_MACRO_PREFIX = "RQEQuest" -- Prefix for macro names to help identify them










-- -- Define or update the macro text based on the existing macro
-- local function updateMacroText()
    -- local macroName = "RQE Macro"
    -- local macroIndex = GetMacroIndexByName(macroName)
    -- local macroText = "/run print('Macro not found!')" -- Default message if macro doesn't exist
    -- if macroIndex and macroIndex ~= 0 then
        -- local _, _, macroBody = GetMacroInfo(macroIndex)
        -- macroText = macroBody
    -- end
    -- return macroText
-- end

-- -- Create the secure frame to activate the macro
-- local frame = CreateFrame("Button", "RQEMacroButton", UIParent, "SecureActionButtonTemplate")
-- frame:SetPoint("CENTER") -- Position at the center of the screen
-- frame:SetSize(100, 100) -- Set the size of the button
-- frame:SetAttribute("type", "macro")
-- frame:SetAttribute("macro", "RQE Macro")
-- frame:RegisterForClicks("AnyUp", "AnyDown")



-- -- Update macro text and attribute
-- local function refreshMacroButton()
    -- local macroText = updateMacroText()
    -- frame:SetAttribute("macrotext", macroText)

    -- -- Update tooltip to show current macro
    -- frame:SetScript("OnEnter", function(self)
        -- GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- GameTooltip:SetText("Click to execute the RQE Macro:\n" .. macroText)
        -- GameTooltip:Show()
    -- end)
-- end

-- -- Initial refresh of the button macro text
-- refreshMacroButton()

-- -- Optional: Add a visual appearance
    -- -- Set the button's appearance
    -- frame:SetNormalTexture(iconID)  -- Example texture ID, replace with actual macro icon or path
    -- farme:SetHighlightTexture(iconID, "ADD")
	
-- frame:SetScript("OnLeave", function(self)
    -- GameTooltip:Hide()
-- end)

-- -- Refresh the macro button whenever macros are updated
-- local updateFrame = CreateFrame("Frame")
-- updateFrame:RegisterEvent("UPDATE_MACROS")
-- updateFrame:SetScript("OnEvent", refreshMacroButton)



-- -- Create the main frame for the button
-- local button = CreateFrame("Button", "RQEMacroButton", UIParent, "GameMenuButtonTemplate")
-- button:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- You can adjust the position as needed
-- button:SetSize(140, 40) -- Set the width and height of the button
-- button:SetText("Run RQE Macro") -- Set the text you want on the button

-- -- Optional: Add a tooltip
-- button:SetScript("OnEnter", function(self)
    -- GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    -- GameTooltip:SetText("Click to execute the RQE Macro")
    -- GameTooltip:Show()
-- end)
-- button:SetScript("OnLeave", function(self)
    -- GameTooltip:Hide()
-- end)

-- -- The script that runs when the button is clicked
-- button:SetScript("OnClick", function()
    -- -- Execute the macro named "RQE Macro"
    -- local macroIndex = GetMacroIndexByName("RQE Macro")
    -- if macroIndex and macroIndex > 0 then
        -- RunMacro(macroIndex)
    -- else
        -- print("Macro 'RQE Macro' not found.")
    -- end
-- end)


-- -- Making the button more visible and interactive
-- button:EnableMouse(true)
-- button:SetMovable(true)
-- button:RegisterForDrag("LeftButton")
-- button:SetScript("OnDragStart", button.StartMoving)
-- button:SetScript("OnDragStop", button.StopMovingOrSizing)






-- Function for Updating the RQE Magic Button Icon to match with RQE macro
RQE.Buttons.UpdateMagicButtonIcon = function()
    local macroIndex = GetMacroIndexByName("RQE Macro")
    if macroIndex and macroIndex > 0 then
        local _, iconID = GetMacroInfo(macroIndex)
        if iconID then
            local MagicButton = RQE.MagicButton --_G["RQEMagicButton"]
            if MagicButton then
                MagicButton:SetNormalTexture(iconID)
                MagicButton:SetHighlightTexture(iconID, "ADD")
            end
        end
    end
end


-- Function to create or update a macro for a quest step
function RQEMacro:SetQuestStepMacro(questID, stepIndex, macroContent, perCharacter)
    local macroName = "RQE Macro"
    local iconFileID = "INV_MISC_QUESTIONMARK"
    local macroBody = type(macroContent) == "table" and table.concat(macroContent, "\n") or macroContent

    if InCombatLockdown() then
        -- Queue the macro set operation for after combat
        table.insert(self.pendingMacroSets, {
            name = macroName,
            iconFileID = iconFileID,
            body = macroBody,
            perCharacter = perCharacter
        })
    else
        -- Not in combat, set the macro immediately
        return self:SetMacro(macroName, iconFileID, macroBody, perCharacter)
    end
end


-- Updated to use the existing structure
function RQEMacro:SetMacro(name, iconFileID, body, perCharacter)
    if InCombatLockdown() then
        -- Queue the macro operation for after combat
        table.insert(self.pendingMacroOperations, {name = name, iconFileID = iconFileID, body = body, perCharacter = perCharacter})
        return
    end

    self:ActuallySetMacro(name, iconFileID, body, perCharacter)
end

-- Internal function that actually creates the macro content
function RQEMacro:ActuallySetMacro(name, iconFileID, body, perCharacter)
    local macroIndex = GetMacroIndexByName(name)
    if macroIndex == 0 then -- Macro doesn't exist, create a new one
        local numAccountMacros, numCharacterMacros = GetNumMacros()
        if perCharacter and numCharacterMacros < self.MAX_CHARACTER_MACROS then
            macroIndex = CreateMacro(name, iconFileID, body, 1)
        elseif not perCharacter and numAccountMacros < self.MAX_ACCOUNT_MACROS then
            macroIndex = CreateMacro(name, iconFileID, body, nil)
        else
            RQE.debugLog("Cannot create macro. Maximum number of macros reached.")
            return nil
        end
    else -- Macro exists, update it
        EditMacro(macroIndex, name, iconFileID, body)
    end
    return macroIndex
end


-- Function to clear a specific macro by name
function RQEMacro:ClearMacroContentByName(macroName)
    if InCombatLockdown() then
        -- Queue the macro clear request for after combat
        table.insert(self.pendingMacroClears, macroName)
        return
    end

    self:ActuallyClearMacroContentByName(macroName)
end

-- Internal function that actually clears the macro content
function RQEMacro:ActuallyClearMacroContentByName(macroName)
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex ~= 0 then
        -- Macro found, clear its content
        EditMacro(macroIndex, nil, nil, " ")
    else
        -- Macro not found, log this
        RQE.debugLog("Macro not found: " .. macroName)
    end
end


-- Function to delete a macro by name
function RQEMacro:DeleteMacroByName(name)
    local macroIndex = GetMacroIndexByName(name)
    if macroIndex ~= 0 then
        DeleteMacro(macroIndex)
    end
end


-- Event frame for capturing macro updates
RQE.Buttons.EventFrame = CreateFrame("Frame")
RQE.Buttons.EventFrame:RegisterEvent("UPDATE_MACROS")
RQE.Buttons.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UPDATE_MACROS" then
        RQE.Buttons.UpdateMagicButtonIcon()
    end
end)


-- Handle the queued macro creation and clear requests after combat
RQEMacro.macroClearEventFrame = CreateFrame("Frame")
RQEMacro.macroClearEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
RQEMacro.macroClearEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Process queued macro set/update operations
        for _, macroData in ipairs(RQEMacro.pendingMacroSets) do
            RQEMacro:ActuallySetMacro(macroData.name, macroData.iconFileID, macroData.body, macroData.perCharacter)
        end
        wipe(RQEMacro.pendingMacroSets)

        for _, op in ipairs(RQEMacro.pendingMacroOperations) do
            RQEMacro:ActuallySetMacro(op.name, op.iconFileID, op.body, op.perCharacter)
        end
        wipe(RQEMacro.pendingMacroOperations)

        -- Process queued macro clear operations
        for _, macroName in ipairs(RQEMacro.pendingMacroClears) do
            RQEMacro:ActuallyClearMacroContentByName(macroName)
        end
        wipe(RQEMacro.pendingMacroClears)
    end
end)