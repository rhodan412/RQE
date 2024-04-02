-- RQEMacro.lua

RQEMacro = RQEMacro or {}
RQEMacro.pendingMacroOperations = RQEMacro.pendingMacroOperations or {}
RQEMacro.pendingMacroClears = RQEMacro.pendingMacroClears or {}  -- Queue to hold macro names pending clearance

RQEMacro.MAX_ACCOUNT_MACROS, RQEMacro.MAX_CHARACTER_MACROS = 120, 18 -- Adjust these values according to the game's current limits
RQEMacro.QUEST_MACRO_PREFIX = "RQEQuest" -- Prefix for macro names to help identify them


-- Function for Updating the RQE Magic Button Icon to match with RQE macro
RQE.Buttons.UpdateMagicButtonIcon = function()
    local macroIndex = GetMacroIndexByName("RQE Macro")
    if macroIndex and macroIndex > 0 then
        local _, iconID = GetMacroInfo(macroIndex)
        if iconID then
            local MagicButton = _G["RQEMagicButton"]
            if MagicButton then
                MagicButton:SetNormalTexture(iconID)
                MagicButton:SetHighlightTexture(iconID, "ADD")
            end
        end
    end
end


-- Function to create or update a macro for a quest step
function RQEMacro:SetQuestStepMacro(questID, stepIndex, macroContent, perCharacter)
	local macroName = "RQE Macro"  -- Fixed name for all macros created by this function
    local iconFileID = "INV_MISC_QUESTIONMARK"  -- Default icon, could be dynamic based on content or left as is

    -- Directly use macroContent if it's already a string; no need for table.concat
    local macroBody = type(macroContent) == "table" and table.concat(macroContent, "\n") or macroContent

    return self:SetMacro(macroName, iconFileID, macroBody, perCharacter)
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


-- Handle the queued macro creation and clear macro requests after combat
RQEMacro.macroOperationEventFrame = CreateFrame("Frame")
RQEMacro.macroOperationEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
RQEMacro.macroOperationEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        for _, op in ipairs(RQEMacro.pendingMacroOperations) do
            RQEMacro:ActuallySetMacro(op.name, op.iconFileID, op.body, op.perCharacter)
        end
        wipe(RQEMacro.pendingMacroOperations)
    end
end)


-- Handle the queued macro clear requests after combat
RQEMacro.macroClearEventFrame = CreateFrame("Frame")
RQEMacro.macroClearEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
RQEMacro.macroClearEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        for _, macroName in ipairs(RQEMacro.pendingMacroClears) do
            RQEMacro:ActuallyClearMacroContentByName(macroName)
        end
        wipe(RQEMacro.pendingMacroClears)
    end
end)