-- RQEMacro.lua

RQEMacro = RQEMacro or {}
RQEMacro.pendingMacroSets = {} -- Queue for macro set operations
RQEMacro.pendingMacroOperations = RQEMacro.pendingMacroOperations or {}
RQEMacro.pendingMacroClears = RQEMacro.pendingMacroClears or {}  -- Queue to hold macro names pending clearance

RQEMacro.MAX_ACCOUNT_MACROS, RQEMacro.MAX_CHARACTER_MACROS = 120, 18 -- Adjust these values according to the game's current limits
RQEMacro.QUEST_MACRO_PREFIX = "RQEQuest" -- Prefix for macro names to help identify them


-- Function to check if the current RQE Macro matches the expected contents based on the current super-tracked quest step
function RQE.CheckCurrentMacroContents()
	-- Prevent re-entry if the function is already in progress
	if RQE.isCheckingMacroContents then
		return false
	end

	-- Flag to indicate the function is in progress
	RQE.isCheckingMacroContents = true

	-- Ensure that `RQE.AddonSetStepIndex` is initialized and maintained properly
	if not RQE.AddonSetStepIndex then
		RQE.debugLog("RQE.AddonSetStepIndex was nil; setting to 1 by default.")
		RQE.AddonSetStepIndex = 1 -- Initialize to the first step by default
	end

	-- Check if a quest is being super-tracked
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()
	if not isSuperTracking then
		RQE.debugLog("No quest is currently being super-tracked.")
		return false
	end

	-- Get the quest ID of the currently super-tracked quest
	local questID = C_SuperTrack.GetSuperTrackedQuestID()
	if not questID then
		RQE.debugLog("Super-tracked quest ID not found.")
		return false
	end

	-- Retrieve the quest data from the database
	local questData = RQE.getQuestData(questID)
	if not questData then
		RQE.debugLog("Quest data not found for quest ID:", questID)
		return false
	end

	-- Fetch the current step index the player is on
	local stepIndex = RQE.AddonSetStepIndex
	if not stepIndex or stepIndex < 1 then
		RQE.debugLog("Invalid or missing step index. Defaulting to 1.")
		stepIndex = 1 -- Default to the first step if no valid step index is found
		RQE.AddonSetStepIndex = stepIndex
	end

	RQE.debugLog("Current step index:", stepIndex)

	-- Fetch the macro data for the current step
	local questStep = questData[stepIndex]
	if not questStep or not questStep.macro then
		RQE.debugLog("No macro data found for step index:", stepIndex)
		return false
	end

	-- Combine the macro data into a single string
	local expectedMacroBody = type(questStep.macro) == "table" and table.concat(questStep.macro, "\n") or questStep.macro

	-- Get the current macro contents
	local macroIndex = GetMacroIndexByName("RQE Macro")
	if not macroIndex or macroIndex == 0 then
		RQE.debugLog("Macro 'RQE Macro' not found.")
		return false
	end

	local _, _, currentMacroBody = GetMacroInfo(macroIndex)
	if not currentMacroBody then
		RQE.debugLog("Failed to retrieve current macro contents.")
		return false
	end

	-- Compare the current and expected macro contents
	if currentMacroBody == expectedMacroBody then
		RQE.infoLog("True - Current Macro matches expected contents for stepIndex: " .. tostring(stepIndex))
		return true
	else
		RQE.infoLog("False - Current Macro does not match. Expected for stepIndex: " .. tostring(stepIndex))
		-- Reset the step index to the first step if the macro does not match
		RQE.SetInitialWaypointToOne()
		return false
	end
end


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

	-- if InCombatLockdown() then
		-- -- Queue the macro set operation for after combat
		-- table.insert(self.pendingMacroSets, {
			-- name = macroName,
			-- iconFileID = iconFileID,
			-- body = macroBody,
			-- perCharacter = perCharacter
		-- })
	-- else
		-- Not in combat, set the macro immediately
		return self:SetMacro(macroName, iconFileID, macroBody, perCharacter)
	--end
end


-- Updated to use the existing structure
function RQEMacro:SetMacro(name, iconFileID, body, perCharacter)
	-- if InCombatLockdown() then
		-- -- Queue the macro operation for after combat
		-- table.insert(self.pendingMacroOperations, {name = name, iconFileID = iconFileID, body = body, perCharacter = perCharacter})
		-- return
	-- end

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
	-- if InCombatLockdown() then
		-- -- Queue the macro clear request for after combat
		-- table.insert(self.pendingMacroClears, macroName)
		-- return
	-- end

	local isMacroCorrect = RQE.CheckCurrentMacroContents()

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


-- -- Handle the queued macro creation and clear requests after combat
-- RQEMacro.macroClearEventFrame = CreateFrame("Frame")
-- RQEMacro.macroClearEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- RQEMacro.macroClearEventFrame:SetScript("OnEvent", function(self, event)
	-- if event == "PLAYER_REGEN_ENABLED" then
		-- -- Process queued macro set/update operations
		-- for _, macroData in ipairs(RQEMacro.pendingMacroSets) do
			-- RQEMacro:ActuallySetMacro(macroData.name, macroData.iconFileID, macroData.body, macroData.perCharacter)
		-- end
		-- wipe(RQEMacro.pendingMacroSets)

		-- for _, op in ipairs(RQEMacro.pendingMacroOperations) do
			-- RQEMacro:ActuallySetMacro(op.name, op.iconFileID, op.body, op.perCharacter)
		-- end
		-- wipe(RQEMacro.pendingMacroOperations)

		-- -- Process queued macro clear operations
		-- for _, macroName in ipairs(RQEMacro.pendingMacroClears) do
			-- RQEMacro:ActuallyClearMacroContentByName(macroName)
		-- end
		-- wipe(RQEMacro.pendingMacroClears)
	-- end
-- end)