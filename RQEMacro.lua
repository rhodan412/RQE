-- RQEMacro.lua

RQEMacro = {}
RQEMacro.MAX_ACCOUNT_MACROS, RQEMacro.MAX_CHARACTER_MACROS = 120, 18 -- Adjust these values according to the game's current limits
RQEMacro.QUEST_MACRO_PREFIX = "RQEQuest" -- Prefix for macro names to help identify them


-- Function to create or update a macro for a quest step
function RQEMacro:SetQuestStepMacro(questID, stepIndex, macroContent, perCharacter)
	local macroName = "RQE Macro"  -- Fixed name for all macros created by this function
    local iconFileID = "4640500"   --"INV_MISC_QUESTIONMARK"  -- Default icon, could be dynamic based on content or left as is

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

-- Function to delete a macro by name
function RQEMacro:DeleteMacroByName(name)
    local macroIndex = GetMacroIndexByName(name)
    if macroIndex ~= 0 then
        DeleteMacro(macroIndex)
    end
end
