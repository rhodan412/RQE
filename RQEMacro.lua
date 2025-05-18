--[[ 

RQEMacro.lua
Handles the creation of the macro button as it relates to quests in the DB file

]]


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

	-- Ensure that `RQE.AddonSetStepIndex` is initialized and maintained properly
	if not RQE.AddonSetStepIndex then
		RQE.debugLog("RQE.AddonSetStepIndex was nil; setting to 1 by default.")
		RQE.AddonSetStepIndex = 1 -- Initialize to the first step by default
	end

	-- Check if a quest is being super-tracked
	RQE.isPlayerSuperTrackingQuest() -- Check to see if anything is being super tracked
	local isSuperTracking = C_SuperTrack.IsSuperTrackingQuest()

	if not RQE.isSuperTracking or not isSuperTracking then
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


-- Function to check if the macro contains any content
function RQE:ShouldClearMacro(macroName)
	local macroIndex = GetMacroIndexByName(macroName)
	if not macroIndex or macroIndex == 0 then
		-- No macro exists
		return false
	end

	-- Fetch the current macro content
	local _, _, macroBody = GetMacroInfo(macroIndex)

	-- Check if macro body has any content
	if macroBody and macroBody ~= "" then
		return true -- Macro has content
	else
		return false -- Macro is empty
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


-- Generates a macro on a searched quest from the DB file if it is valid and player doesn't yet have the searched quest (and wasn't flagged as completed)
function RQE:GenerateNpcMacroIfNeeded(questID)
	-- Check if quest is in player log
	if C_QuestLog.IsQuestFlaggedCompleted(questID) or C_QuestLog.GetLogIndexForQuestID(questID) then
		return -- Player already has or completed the quest
	end

	local questData = RQE.getQuestData(questID)
	if not questData or not questData.npc or #questData.npc == 0 or questData.npc[1] == "" then
		return -- No NPC data to create a macro
	end

	local npcName = questData.npc[1]
	if not npcName or npcName == "" then return end

	-- Generate the macro text
	local macroLines = {
		"#showtooltip item:153541",
		"/tar " .. npcName,
		--'/script SetRaidTarget("target",3)'	-- COMMENTING OUT BECAUSE: the RQE:MarkQuestMobOnMouseover() function is handling the marking itself and the macro should only be designed for the targeting
	}

	print("Creating macro for searched NPC:", npcName)
	RQEMacro:SetQuestStepMacro(questID, 1, macroLines, true)

	C_Timer.After(0.35, function()
		RQE.Buttons.UpdateMagicButtonVisibility()
	end)
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

	local isMacroCorrect = RQE.CheckCurrentMacroContents()

	self:ActuallyClearMacroContentByName(macroName)
end


-- Internal function that actually clears the macro content
function RQEMacro:ActuallyClearMacroContentByName(macroName)
	-- Check for being inside an instance with a raid or party
	local isInInstance, instanceType = IsInInstance()

	-- Adds a check if player is in party or raid instance, if so, will not allow macro check to run further
	if isInInstance and (instanceType == "party" or instanceType == "raid") then
		return
	end

	if InCombatLockdown() then
		return
	end

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
		RQEMacro:UpdateMagicButtonTooltip()
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


-- Function to update the Magic Button Tooltip dynamically
function RQEMacro:UpdateMagicButtonTooltip()
	local MagicButton = RQE.MagicButton -- Reference to the magic button
	if not MagicButton then return end

	-- List of exception itemIDs
	local exceptionItemIDs = {
		[841] = true,
		[2554] = true,
		[4588] = true,
		[4787] = true,
		[5061] = true,
		[5830] = true,
		[23784] = true,
		[28372] = true,
		[28885] = true,
		[30817] = true,
		[118474] = true,
		[153541] = true,
	}

	-- Create or reuse the count text overlay
	if not MagicButton.CountText then
		MagicButton.CountText = MagicButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		MagicButton.CountText:SetPoint("BOTTOMRIGHT", MagicButton, "BOTTOMRIGHT", -5, 5)
		MagicButton.CountText:SetJustifyH("RIGHT")
		MagicButton.CountText:SetText("") -- Initialize empty
	end

	MagicButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

		-- Get the macro index and contents
		local macroIndex = GetMacroIndexByName("RQE Macro")
		if not macroIndex or macroIndex == 0 then
			GameTooltip:SetText("Macro 'RQE Macro' not found.")
			GameTooltip:Show()
			return
		end

		local _, _, macroBody = GetMacroInfo(macroIndex)
		if not macroBody or macroBody == "" then
			GameTooltip:SetText("Macro content not found.")
			GameTooltip:Show()
			return
		end

		-- Debug mode: Show raw macro text
		if debugLevel == "INFO+" or IsShiftKeyDown() then
			GameTooltip:SetText("Macro:\n" .. macroBody, nil, nil, nil, nil, true)
			GameTooltip:Show()
			return
		end

		-- Extract item ID from the macro body for `#showtooltip item:X`
		local itemID = tonumber(macroBody:match("#showtooltip%s+item:(%d+)"))
		if itemID then
			-- Check if the item is an exception
			if exceptionItemIDs[itemID] then
				-- Show the macro body and icon for the exception
				if itemID == 841 then
					GameTooltip:SetText("Pull Timer!\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 2554 then
					GameTooltip:SetText("Turn in the quest\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 4588 then
					GameTooltip:SetText("Kill Mob(s)\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 4787 then
					GameTooltip:SetText("Loot Item from Mob(s)\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 5061 then
					GameTooltip:SetText("Purchase Item(s)\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 30817 then
					GameTooltip:SetText("Purchase Item(s)\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 5830 then
					GameTooltip:SetText("Speak with NPC\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 23784 then
					GameTooltip:SetText("Press this macro to close RQE temporarily and turn in via Blizzard Objective Tracker\n\n", nil, nil, nil, nil, true)
				elseif itemID == 28372 then
					GameTooltip:SetText("Look At/Near an NPC\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 28885 then
					GameTooltip:SetText("Use Emote\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 118474 then
					GameTooltip:SetText("Look Follow/Track an NPC\n\n" .. macroBody, nil, nil, nil, nil, true)
				elseif itemID == 153541 then
					GameTooltip:SetText("Pickup the quest\n\n" .. macroBody, nil, nil, nil, nil, true)
				else
					GameTooltip:SetText("Macro:\n" .. macroBody, nil, nil, nil, nil, true)
					-- GameTooltip:AddLine("\n(Item Exception ID: " .. itemID .. ")", 1, 1, 0)
				end
				GameTooltip:Show()
				return
			else
				-- Display the item tooltip if not an exception
				local itemLink = select(2, C_Item.GetItemInfo(itemID))
				if itemLink then
					GameTooltip:SetHyperlink(itemLink)
					GameTooltip:Show()
					return
				end
			end
		end

		-- Extract item or spell from the macro body if no exception logic applies
		local useTarget = macroBody:match("/use%s+(.+)")
			or macroBody:match("/cast%s+(.+)")
			or macroBody:match("#showtooltip%s+(.+)")

		if useTarget then
			-- Attempt to resolve as an item
			local itemLink = select(2, C_Item.GetItemInfo(useTarget))
			if not itemLink then
				local itemID = tonumber(useTarget) or select(1, C_Item.GetItemInfoInstant(useTarget))
				if itemID then
					itemLink = "item:" .. itemID
				end
			end

			if itemLink then
				GameTooltip:SetHyperlink(itemLink)
				GameTooltip:Show()
				return
			end

			-- Attempt to resolve as a spell
			local spellInfo = C_Spell.GetSpellInfo(useTarget)
			if spellInfo then
				GameTooltip:SetSpellByID(spellInfo.spellID)
				GameTooltip:Show()
				return
			end
		end

		-- Fallback: Show raw macro body if no item or spell is resolved
		GameTooltip:SetText("Macro:\n" .. macroBody, nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)

	MagicButton:SetScript("OnUpdate", function()
		local macroIndex = GetMacroIndexByName("RQE Macro")
		if not macroIndex or macroIndex == 0 then
			MagicButton.CountText:SetText("")
			return
		end

		local _, _, macroBody = GetMacroInfo(macroIndex)
		if not macroBody or macroBody == "" then
			MagicButton.CountText:SetText("")
			return
		end

		-- Extract item ID directly if available
		local itemID = tonumber(macroBody:match("#showtooltip%s+item:(%d+)"))

		-- If no item ID is found, extract the item name from `/use`
		if not itemID then
			local itemName = macroBody:match("/use%s+(.+)")
			if itemName then
				-- Resolve item name to item ID
				itemID = C_Item.GetItemInfoInstant(itemName)
			end
		end

		-- Continue with item count logic if itemID is resolved
		if itemID then
			local itemCount = C_Item.GetItemCount(itemID)
			if not itemCount or itemCount < 1 then
				MagicButton.CountText:SetText("") -- Hide count if less than 1
			else
				if itemCount > 999 then
					itemCount = 999 -- Cap at 999
				end
				MagicButton.CountText:SetText(itemCount) -- Display count
			end
		else
			MagicButton.CountText:SetText("") -- Clear the count if no valid item ID
		end
	end)

	MagicButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end