-- RQEMacro.lua

RQEMacro = {}
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

-- Event frame for capturing macro updates
RQE.Buttons.EventFrame = CreateFrame("Frame")
RQE.Buttons.EventFrame:RegisterEvent("UPDATE_MACROS")
RQE.Buttons.EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UPDATE_MACROS" then
        RQE.Buttons.UpdateMagicButtonIcon()
    end
end)


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
    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex ~= 0 then
        -- Macro found, clear its content
        EditMacro(macroIndex, nil, nil, " ")
    else
        -- Macro not found, you could choose to log this or take no action
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