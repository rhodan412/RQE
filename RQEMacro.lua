--[[ 

RQEMacro.lua
Quest macro generation, deferred updates, Magic Button state, and tooltip behavior

]]


--------------------------------------------------
-- #1. 📦 Macro Namespace, Constants & Queues
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Namespace & Client-Specific Tooltip Marker
	-------------------------------------------------------

	RQEMacro = RQEMacro or {}
	local isRetail = RQE.IsRetail == true
	local cancelAuraTooltipItemID = isRetail and 67097 or 54068

	-------------------------------------------------------
	-- #1b. Cancel-Aura Macro Recognition
	-------------------------------------------------------

	-- The dedicated item marker identifies a cancel-aura macro on each client.
	local function IsCancelAuraTooltipMacro(macroBody)
		return type(macroBody) == "string"
			and tonumber(macroBody:match("^%s*#showtooltip%s+item:(%d+)")) == cancelAuraTooltipItemID
	end

	-- Function to identify macros that contain an executable cancel-aura command
	local function HasCancelAuraCommand(macroBody)
		if type(macroBody) ~= "string" then return false end
		local lowerBody = macroBody:lower()
		return lowerBody:match("^%s*/cancelaura%s+") ~= nil
			or lowerBody:match("[\r\n]%s*/cancelaura%s+") ~= nil
	end

	-------------------------------------------------------
	-- #1c. Deferred Operation Queues & Macro Limits
	-------------------------------------------------------

	RQEMacro.pendingMacroSets = RQEMacro.pendingMacroSets or {} -- Queue for macro set operations
	RQEMacro.pendingMacroOperations = RQEMacro.pendingMacroOperations or {}
	RQEMacro.pendingMacroClears = RQEMacro.pendingMacroClears or {}  -- Queue to hold macro names pending clearance
	RQEMacro.pendingMacroSequence = RQEMacro.pendingMacroSequence or 0

	RQEMacro.MAX_ACCOUNT_MACROS, RQEMacro.MAX_CHARACTER_MACROS = 120, 18 -- Adjust these values according to the game's current limits
	RQEMacro.QUEST_MACRO_PREFIX = "RQEQuest" -- Prefix for macro names to help identify them

	-------------------------------------------------------
	-- #1d. Ordered Queue Insertion
	-------------------------------------------------------

	-- Function to queue protected macro work once while preserving replay order
	local function QueuePendingMacroOperation(self, queue, operation)
		self.pendingMacroSequence = self.pendingMacroSequence + 1
		operation.order = self.pendingMacroSequence
		table.insert(queue, operation)
	end


--------------------------------------------------
-- #2. ✅ Macro Validation & Magic Button State
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Current Quest-Step Macro Validation
	-------------------------------------------------------

	-- Function that forces a check on the RQE Macro
	function RQE.ForceCheckCurrentMacroContents()
		RQE.isCheckingMacroContents = true
		
		local isMacroCorrect = RQE.CheckCurrentMacroContents()
		RQE.CheckCurrentMacroContents()

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.2, function()
		RQE.API.Client.C_Timer.After(0.2, function()
			if RQE.isCheckingMacroContents then
				RQE.isCheckingMacroContents = false
			end
		end)
	end


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
		local isSuperTracking = RQE.API.IsSuperTrackingQuest()

		if not RQE.isSuperTracking or not isSuperTracking then
			RQE.debugLog("No quest is currently being super-tracked.")
			return false
		end

		-- Get the quest ID of the currently super-tracked quest
		local questID = RQE.API.GetSuperTrackedQuestID()
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
		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName("RQE Macro")
		local macroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
		if not macroIndex or macroIndex == 0 then
			RQE.debugLog("Macro 'RQE Macro' not found.")
			return false
		end

		-- Previous Blizzard call changed 2026.09.25: local _, _, currentMacroBody = GetMacroInfo(macroIndex)
		local _, _, currentMacroBody = RQE.API.Client.GetMacroInfo(macroIndex)
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


	-------------------------------------------------------
	-- #2b. Macro Clear Eligibility
	-------------------------------------------------------

	-- Function to check if the macro contains any content
	function RQE:ShouldClearMacro(macroName)
		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName(macroName)
		local macroIndex = RQE.API.Client.GetMacroIndexByName(macroName)
		if not macroIndex or macroIndex == 0 then
			-- No macro exists
			return false
		end

		-- Fetch the current macro content
		-- Previous Blizzard call changed 2026.09.25: local _, _, macroBody = GetMacroInfo(macroIndex)
		local _, _, macroBody = RQE.API.Client.GetMacroInfo(macroIndex)

		-- Check if macro body has any content
		if macroBody and macroBody ~= "" then
			return true -- Macro has content
		else
			return false -- Macro is empty
		end
	end


	-------------------------------------------------------
	-- #2c. Magic Button Icon Synchronization
	-------------------------------------------------------

	-- Function for Updating the RQE Magic Button Icon to match with RQE macro
	RQE.Buttons.UpdateMagicButtonIcon = function()
		-- Previous Blizzard call changed 2026.09.25: if not isRetail and InCombatLockdown() then
		if not isRetail and RQE.API.Client.InCombatLockdown() then
			RQE.RefreshMagicButtonAfterCombat = true
			return
		end

		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName("RQE Macro")
		local macroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
		if macroIndex and macroIndex > 0 then
			-- Previous Blizzard call changed 2026.09.25: local _, iconID, macroBody = GetMacroInfo(macroIndex)
			local _, iconID, macroBody = RQE.API.Client.GetMacroInfo(macroIndex)
			if iconID then
				local MagicButton = RQE.MagicButton --_G["RQEMagicButton"]
				if MagicButton then
					MagicButton:SetNormalTexture(iconID)
					MagicButton:SetHighlightTexture(iconID, "ADD")
					if RQE.UI then RQE.UI:UpdateMagicButtonActionIcon(MagicButton, macroBody) end
				end
			end
		elseif RQE.UI and RQE.MagicButton then
			RQE.UI:UpdateMagicButtonActionIcon(RQE.MagicButton, nil)
		end
	end


--------------------------------------------------
-- #3. 📜 Quest Macro Generation
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Quest-Step Macro Assembly
	-------------------------------------------------------

	-- Function to create or update a macro for a quest step
	function RQEMacro:SetQuestStepMacro(questID, stepIndex, macroContent, perCharacter)
		local macroName = "RQE Macro"
		local iconFileID = "INV_MISC_QUESTIONMARK"
		local macroBody = ""

		-- Case 1: New array macro { { macro="/click ...", spellIDTooltip=215173, iconFileID="Inv_helm_..." } }
		if type(macroContent) == "table" and type(macroContent[1]) == "table" and macroContent[1].macro then
			local entry = macroContent[1]
			macroBody = entry.macro or ""

			-- Choose the icon
			if entry.iconFileID then
				iconFileID = entry.iconFileID
			elseif entry.spellIDTooltip then
				-- Previous Blizzard call changed 2026.09.25: local spellInfo = C_Spell.GetSpellInfo(entry.spellIDTooltip)
				local spellInfo = RQE.API.Client.C_Spell.GetSpellInfo(entry.spellIDTooltip)
				if spellInfo and spellInfo.iconID then
					iconFileID = spellInfo.iconID
				end
			end

		-- Case 2: Legacy macros
		elseif macroContent then
			macroBody = type(macroContent) == "table" and table.concat(macroContent, "\n") or macroContent
		end

		-- Normalize numeric IDs
		if type(iconFileID) == "number" then
			iconFileID = tostring(iconFileID)
		end

		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			if isRetail then
				-- Queue for after combat.
				table.insert(self.pendingMacroSets, {
					name = macroName,
					iconFileID = iconFileID,
					body = macroBody,
					perCharacter = perCharacter
				})
			else
				QueuePendingMacroOperation(self, self.pendingMacroSets, {
					name = macroName,
					iconFileID = iconFileID,
					body = macroBody,
					perCharacter = perCharacter
				})
				return
			end
		else
			return self:SetMacro(macroName, iconFileID, macroBody, perCharacter)
		end

		-- Retail preserves its existing immediate refresh after queueing a macro.
		if isRetail and RQEMacro and RQEMacro.UpdateMagicButtonTooltip then
			RQEMacro:UpdateMagicButtonTooltip()
		end

		return nil
	end


	-------------------------------------------------------
	-- #3b. Classic/TBC Searched Quest Pickup Macro
	-------------------------------------------------------

	-- Classic/TBC searched quests use virtual step 0 while the quest pickup is
	-- pending, so their pickup macro must remain distinct from Retail step 1.
	function RQE:SetSearchedQuestPickupMacro(questID)
		local questData = RQE.getQuestData(questID)
		if not questData or not questData.npc or #questData.npc == 0 or questData.npc[1] == "" then
			return false
		end

		local npcName = questData.npc[1]
		if not npcName or npcName == "" then return false end

		local macroLines = {
			"#showtooltip item:1165",
			"/tar " .. npcName,
			"/tm 3",
		}

		if RQE.db.profile.debugLevel == "INFO+" then
			print("Creating macro for searched NPC:", npcName)
		end
		RQEMacro:SetQuestStepMacro(questID, 0, macroLines, true)

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.35, function()
		RQE.API.Client.C_Timer.After(0.35, function()
			RQE.Buttons.UpdateMagicButtonVisibility()
		end)
		return true
	end


	-------------------------------------------------------
	-- #3c. Retail Searched Quest NPC Macro
	-------------------------------------------------------

	-- Generates a macro on a searched quest from the DB file if it is valid and player doesn't yet have the searched quest (and wasn't flagged as completed)
	function RQE:GenerateNpcMacroIfNeeded(questID)
		-- Check if quest is in player log
		-- Previous Blizzard call changed 2026.09.25: if C_QuestLog.IsQuestFlaggedCompleted(questID) or C_QuestLog.GetLogIndexForQuestID(questID) then
		if RQE.API.Client.C_QuestLog.IsQuestFlaggedCompleted(questID) or RQE.API.Client.C_QuestLog.GetLogIndexForQuestID(questID) then
			return -- Player already has or completed the quest
		end

		if not isRetail then
			return RQE:SetSearchedQuestPickupMacro(questID)
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
			"/tm 3"		-- modified as 12.0 patch broke the function that checks raid icon presence and accuracy before re-marking
		}

		if RQE.db.profile.debugLevel == "INFO+" then
			print("Creating macro for searched NPC:", npcName)
		end
		RQEMacro:SetQuestStepMacro(questID, 1, macroLines, true)

		-- Previous Blizzard call changed 2026.09.25: C_Timer.After(0.35, function()
		RQE.API.Client.C_Timer.After(0.35, function()
			RQE.Buttons.UpdateMagicButtonVisibility()
		end)
	end


--------------------------------------------------
-- #4. 💾 Macro Persistence & Deferred Operations
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Create or Update Macro Content
	-------------------------------------------------------

	-- Updated to use the existing structure
	function RQEMacro:SetMacro(name, iconFileID, body, perCharacter)
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			-- Queue the macro operation for after combat
			if isRetail then
				table.insert(self.pendingMacroOperations, {name = name, iconFileID = iconFileID, body = body, perCharacter = perCharacter})
			else
				QueuePendingMacroOperation(self, self.pendingMacroOperations, {name = name, iconFileID = iconFileID, body = body, perCharacter = perCharacter})
			end
			return
		end

		self:ActuallySetMacro(name, iconFileID, body, perCharacter)
	end


	-- Internal function that actually creates the macro content
	function RQEMacro:ActuallySetMacro(name, iconFileID, body, perCharacter)
		-- Normalize numeric icon IDs
		if type(iconFileID) == "number" then
			iconFileID = tostring(iconFileID)
		end

		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName(name)
		local macroIndex = RQE.API.Client.GetMacroIndexByName(name)
		if macroIndex == 0 then -- Macro doesn't exist, create a new one
			-- Previous Blizzard call changed 2026.09.25: local numAccountMacros, numCharacterMacros = GetNumMacros()
			local numAccountMacros, numCharacterMacros = RQE.API.Client.GetNumMacros()
			if perCharacter and numCharacterMacros < self.MAX_CHARACTER_MACROS then
				-- Previous Blizzard call changed 2026.09.25: macroIndex = CreateMacro(name, iconFileID, body, 1)
				macroIndex = RQE.API.Client.CreateMacro(name, iconFileID, body, 1)
			elseif not perCharacter and numAccountMacros < self.MAX_ACCOUNT_MACROS then
				-- Previous Blizzard call changed 2026.09.25: macroIndex = CreateMacro(name, iconFileID, body, nil)
				macroIndex = RQE.API.Client.CreateMacro(name, iconFileID, body, nil)
			else
				RQE.debugLog("Cannot create macro. Maximum number of macros reached.")
				return nil
			end
		else -- Macro exists, update it
			if not isRetail then
				-- Previous Blizzard call changed 2026.09.25: local _, _, currentBody = GetMacroInfo(macroIndex)
				local _, _, currentBody = RQE.API.Client.GetMacroInfo(macroIndex)
				if currentBody == body then
					return macroIndex
				end
			end

			-- Previous Blizzard call changed 2026.09.25: EditMacro(macroIndex, name, iconFileID, body)
			RQE.API.Client.EditMacro(macroIndex, name, iconFileID, body)
		end
		return macroIndex
	end


	-------------------------------------------------------
	-- #4b. Clear Macro Content
	-------------------------------------------------------

	-- Function to clear a specific macro by name
	function RQEMacro:ClearMacroContentByName(macroName)
		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			-- Queue the macro clear request for after combat
			if isRetail then
				table.insert(self.pendingMacroClears, macroName)
			else
				QueuePendingMacroOperation(self, self.pendingMacroClears, {name = macroName})
			end
			return
		end

		local isMacroCorrect = RQE.CheckCurrentMacroContents()

		self:ActuallyClearMacroContentByName(macroName)
	end


	-- Internal function that actually clears the macro content
	function RQEMacro:ActuallyClearMacroContentByName(macroName)
		-- Check for being inside an instance with a raid or party
		-- Previous Blizzard call changed 2026.09.25: local isInInstance, instanceType = IsInInstance()
		local isInInstance, instanceType = RQE.API.Client.IsInInstance()

		-- Adds a check if player is in party or raid instance, if so, will not allow macro check to run further
		if isInInstance and (instanceType == "party" or instanceType == "raid") then
			return
		end

		-- Previous Blizzard call changed 2026.09.25: if InCombatLockdown() then
		if RQE.API.Client.InCombatLockdown() then
			return
		end

		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName(macroName)
		local macroIndex = RQE.API.Client.GetMacroIndexByName(macroName)
		if macroIndex ~= 0 then
			if not isRetail then
				-- Previous Blizzard call changed 2026.09.25: local _, _, currentBody = GetMacroInfo(macroIndex)
				local _, _, currentBody = RQE.API.Client.GetMacroInfo(macroIndex)
				if not currentBody or currentBody:match("^%s*$") then
					return
				end
			end

			-- Macro found, clear its content
			-- Previous Blizzard call changed 2026.09.25: EditMacro(macroIndex, nil, nil, " ")
			RQE.API.Client.EditMacro(macroIndex, nil, nil, " ")
		else
			-- Macro not found, log this
			RQE.debugLog("Macro not found: " .. macroName)
		end
	end


	-------------------------------------------------------
	-- #4c. Post-Combat Operation Replay
	-------------------------------------------------------

	-- Replays Classic/TBC macro work queued during combat. Their EventManager
	-- calls this from PLAYER_REGEN_ENABLED; Retail keeps its existing queue flow.
	function RQEMacro:ProcessPendingMacroOperations()
		-- Previous Blizzard call changed 2026.09.25: if isRetail or InCombatLockdown() then
		if isRetail or RQE.API.Client.InCombatLockdown() then
			return false
		end

		local pending = {}
		-- Function to append queued set or clear operations to the ordered replay list
		local function AppendOperations(kind, operations)
			for _, operation in ipairs(operations) do
				-- Older sessions may contain a bare macro name in the clear queue.
				if type(operation) == "string" then
					operation = { name = operation }
				end
				table.insert(pending, {
					kind = kind,
					operation = operation,
					order = operation.order or 0,
				})
			end
		end

		AppendOperations("set", self.pendingMacroSets)
		AppendOperations("set", self.pendingMacroOperations)
		AppendOperations("clear", self.pendingMacroClears)

		self.pendingMacroSets = {}
		self.pendingMacroOperations = {}
		self.pendingMacroClears = {}

		table.sort(pending, function(left, right)
			return left.order < right.order
		end)

		for _, entry in ipairs(pending) do
			local operation = entry.operation
			if entry.kind == "clear" then
				self:ActuallyClearMacroContentByName(operation.name)
			else
				self:ActuallySetMacro(operation.name, operation.iconFileID, operation.body, operation.perCharacter)
			end
		end

		return #pending > 0
	end


	-------------------------------------------------------
	-- #4d. Macro Deletion
	-------------------------------------------------------

	-- Function to delete a macro by name
	function RQEMacro:DeleteMacroByName(name)
		-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName(name)
		local macroIndex = RQE.API.Client.GetMacroIndexByName(name)
		if macroIndex ~= 0 then
			-- Previous Blizzard call changed 2026.09.25: DeleteMacro(macroIndex)
			RQE.API.Client.DeleteMacro(macroIndex)
		end
	end


--------------------------------------------------
-- #5. 📡 Macro Update Events
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. UPDATE_MACROS Refresh Hook
	-------------------------------------------------------

	-- Event frame for capturing macro updates
	RQE.Buttons.EventFrame = CreateFrame("Frame")
	RQE.Buttons.EventFrame:RegisterEvent("UPDATE_MACROS")
	RQE.Buttons.EventFrame:SetScript("OnEvent", function(self, event, ...)
		if event == "UPDATE_MACROS" then
			RQE.Buttons.UpdateMagicButtonIcon()
			RQEMacro:UpdateMagicButtonTooltip()
		end
	end)


--------------------------------------------------
-- #6. 💬 Macro Tooltip Helpers
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Wrapped Macro Text Tooltip
	-------------------------------------------------------

	-- Helper to show long macro text in a tooltip without truncating lines.
	local function RQEShowWrappedMacroTooltip(owner, title, macroBody)
		GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
		-- GameTooltip:SetWidth(420)
		GameTooltip:SetMinimumWidth(420)

		-- Clear existing tooltip contents before rebuilding it line-by-line.
		GameTooltip:ClearLines()

		if title and title ~= "" then
			GameTooltip:AddLine(title, 1, 0.82, 0, true)
			GameTooltip:AddLine(" ", 1, 1, 1, true)
		end

		for line in tostring(macroBody or ""):gmatch("([^\n]*)\n?") do
			if line == "" then
				GameTooltip:AddLine(" ", 1, 1, 1, true)
			else
				GameTooltip:AddLine(line, 1, 0.82, 0, true)
			end
		end

		GameTooltip:Show()
	end

	-------------------------------------------------------
	-- #6b. Cancel-Aura Spell Tooltip
	-------------------------------------------------------

	-- Put the action label above Blizzard's spell details for cancel-aura arrays.
	local function RQEShowCancelAuraSpellTooltip(owner, spellID, macroBody)
		GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetMinimumWidth(0)

		-- AddSpellByID appends the native spell tooltip after our first line when
		-- the client provides it, preserving range, channeling, and spell text.
		if type(GameTooltip.AddSpellByID) == "function" then
			GameTooltip:SetText("Cancel Aura:", 1, 0.82, 0)
			GameTooltip:AddSpellByID(spellID)
			if GameTooltip:NumLines() > 1 then
				GameTooltip:Show()
				return
			end
		end

		-- Legacy fallback: retain the native spell tooltip and place the label
		-- above its title inside the first text region.
		GameTooltip:ClearLines()
		GameTooltip:SetSpellByID(spellID)
		local tooltipName = GameTooltip:GetName()
		local titleLine = tooltipName and _G[tooltipName .. "TextLeft1"]
		local spellTitle = titleLine and titleLine:GetText()
		if spellTitle and spellTitle ~= "" then
			titleLine:SetText("|cffffd200Cancel Aura:|r\n" .. spellTitle)
			GameTooltip:Show()
			return
		end

		-- An unknown spell ID can still show the actionable macro text.
		RQEShowWrappedMacroTooltip(owner, "Cancel Aura:", macroBody)
	end


--------------------------------------------------
-- #7. ✨ Magic Button Tooltip & Live Action State
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Dynamic Tooltip, Item Count & Cooldown Updates
	-------------------------------------------------------

	-- Function to update the Magic Button Tooltip dynamically
	function RQEMacro:UpdateMagicButtonTooltip()
		-------------------------------------------------------
		-- #7a.i. Combat Deferral & Button Validation
		-------------------------------------------------------

		-- Previous Blizzard call changed 2026.09.25: if not isRetail and InCombatLockdown() then
		if not isRetail and RQE.API.Client.InCombatLockdown() then
			RQE.RefreshMagicButtonAfterCombat = true
			return
		end

		local MagicButton = RQE.MagicButton -- Reference to the magic button
		if not MagicButton then return end

		-------------------------------------------------------
		-- #7a.ii. Spell-Backed Macro Array Tooltip
		-------------------------------------------------------

		-- >>> NEW: check if current macroArray step defines a spell tooltip
		local questID = RQE.API.GetSuperTrackedQuestID()
		if questID and RQE and RQE.getQuestData then
			local questData = RQE.getQuestData(questID)
			local stepIndex = RQE.AddonSetStepIndex
			local step = questData and stepIndex and questData[stepIndex]

			if step and step.macroArray and type(step.macroArray) == "table" then
				local entry = step.macroArray[1]
				-- Spell-backed arrays take precedence over an item marker; plain
				-- marked macros still use the full macro-text tooltip below.
				if entry and entry.spellIDTooltip then
					local spellID = entry.spellIDTooltip

					-- Read the current macro on hover so UPDATE_MACROS timing cannot
					-- leave an old cancel-aura classification on the button.
					MagicButton:SetScript("OnEnter", function(self)
						GameTooltip:Hide()
						-- Previous Blizzard call changed 2026.09.25: local hoverMacroIndex = GetMacroIndexByName("RQE Macro")
						local hoverMacroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
						local hoverMacroBody
						if hoverMacroIndex and hoverMacroIndex > 0 then
							-- Previous Blizzard call changed 2026.09.25: local _, _, body = GetMacroInfo(hoverMacroIndex)
							local _, _, body = RQE.API.Client.GetMacroInfo(hoverMacroIndex)
							hoverMacroBody = body
						end
						if HasCancelAuraCommand(hoverMacroBody) then
							RQEShowCancelAuraSpellTooltip(self, spellID, hoverMacroBody)
						else
							GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
							GameTooltip:SetSpellByID(spellID)
							GameTooltip:Show()
						end
					end)
					MagicButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

					-- ✅ End here so we don't run the old logic afterward
					return
				end
			end
		end

		-------------------------------------------------------
		-- #7a.iii. Exception Items & Count Overlay
		-------------------------------------------------------

		-- List of exception itemIDs
		local exceptionItemIDs
		if isRetail then
			exceptionItemIDs = {
				[841] = true, [2554] = true, [4588] = true, [4787] = true,
				[5061] = true, [5830] = true, [23784] = true, [28372] = true,
				[28885] = true, [30817] = true, [28912] = true, [45786] = true,
				[67097] = true, [118474] = true, [143680] = true, [153541] = true,
			}
		else
			exceptionItemIDs = {
				[841] = true, [2554] = true, [4588] = true, [4787] = true,
				[5061] = true, [5830] = true, [2058] = true, [11753] = true,
				[206995] = true, [4382] = true, [21561] = true, [20337] = true,
				[7270] = true, [3081] = true, [1165] = true, [54068] = true,
			}
		end

		-- Create or reuse the count text overlay
		if not MagicButton.CountText then
			MagicButton.CountText = MagicButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
			MagicButton.CountText:SetPoint("BOTTOMRIGHT", MagicButton, "BOTTOMRIGHT", -5, 5)
			MagicButton.CountText:SetJustifyH("RIGHT")
			MagicButton.CountText:SetText("") -- Initialize empty
		end

		-------------------------------------------------------
		-- #7a.iv. Hover Tooltip Resolution
		-------------------------------------------------------

		MagicButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

			-- Get the macro index and contents
			-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName("RQE Macro")
			local macroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
			if not macroIndex or macroIndex == 0 then
				GameTooltip:SetText("Macro 'RQE Macro' not found.")
				GameTooltip:Show()
				return
			end

			-- Previous Blizzard call changed 2026.09.25: local _, _, macroBody = GetMacroInfo(macroIndex)
			local _, _, macroBody = RQE.API.Client.GetMacroInfo(macroIndex)
			if not macroBody or macroBody == "" then
				GameTooltip:SetText("Macro content not found.")
				GameTooltip:Show()
				return
			end

			-- Debug mode: Show raw macro text
			-- Previous Blizzard call changed 2026.09.25: if RQE.db.profile.debugLevel == "INFO+" or IsShiftKeyDown() then
			if RQE.db.profile.debugLevel == "INFO+" or RQE.API.Client.IsShiftKeyDown() then
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
						RQEShowWrappedMacroTooltip(self, "Pull Timer!", macroBody)
					elseif itemID == 2554 then
						RQEShowWrappedMacroTooltip(self, "Turn in the quest", macroBody)
					elseif itemID == cancelAuraTooltipItemID and IsCancelAuraTooltipMacro(macroBody) then
						RQEShowWrappedMacroTooltip(self, "Cancel Aura", macroBody)
					elseif itemID == 4588 then
						RQEShowWrappedMacroTooltip(self, "Kill Mob(s)", macroBody)
					elseif itemID == 4787 then
						RQEShowWrappedMacroTooltip(self, "Collect/Loot Item from Mob(s)", macroBody)
					elseif itemID == 5061 then
						RQEShowWrappedMacroTooltip(self, "Purchase Item(s)", macroBody)
					elseif (isRetail and itemID == 30817) or (not isRetail and itemID == 4382) then
						RQEShowWrappedMacroTooltip(self, "Purchase Item(s)", macroBody)
					elseif itemID == 5830 then
						RQEShowWrappedMacroTooltip(self, "Speak/Interact with NPC", macroBody)
					elseif (isRetail and itemID == 23784) or (not isRetail and itemID == 2058) then
						RQEShowWrappedMacroTooltip(self, "Press this macro to close RQE temporarily and turn in via Blizzard Objective Tracker", macroBody)
					elseif (isRetail and itemID == 28372) or (not isRetail and itemID == 11753) then
						RQEShowWrappedMacroTooltip(self, "Look At/Near an NPC", macroBody)
					elseif (isRetail and itemID == 28885) or (not isRetail and itemID == 206995) then
						RQEShowWrappedMacroTooltip(self, "Use Emote", macroBody)
					elseif (isRetail and itemID == 28912) or (not isRetail and itemID == 21561) then
						RQEShowWrappedMacroTooltip(self, "Learn ability", macroBody)
					elseif (isRetail and itemID == 45786) or (not isRetail and itemID == 20337) then
						RQEShowWrappedMacroTooltip(self, "Set CVAR", macroBody)
					elseif (isRetail and itemID == 118474) or (not isRetail and itemID == 7270) then
						RQEShowWrappedMacroTooltip(self, "Look/Follow/Escort/Track an NPC", macroBody)
					elseif (isRetail and itemID == 143680) or (not isRetail and itemID == 3081) then
						RQEShowWrappedMacroTooltip(self, "Weaken", macroBody)
					elseif (isRetail and itemID == 153541) or (not isRetail and itemID == 1165) then
						RQEShowWrappedMacroTooltip(self, "Pickup the quest", macroBody)
					else
						GameTooltip:SetText("Macro:\n" .. macroBody, nil, nil, nil, nil, true)
					end
					GameTooltip:Show()
					return
				else
					-- Display the item tooltip if not an exception
					-- Previous Blizzard call changed 2026.09.25: local itemLink = select(2, C_Item.GetItemInfo(itemID))
					local itemLink = select(2, RQE.API.Client.C_Item.GetItemInfo(itemID))
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
				-- Previous Blizzard call changed 2026.09.25: local itemLink = select(2, C_Item.GetItemInfo(useTarget))
				local itemLink = select(2, RQE.API.Client.C_Item.GetItemInfo(useTarget))
				if not itemLink then
					-- Previous Blizzard call changed 2026.09.25: local itemID = tonumber(useTarget) or select(1, C_Item.GetItemInfoInstant(useTarget))
					local itemID = tonumber(useTarget) or select(1, RQE.API.Client.C_Item.GetItemInfoInstant(useTarget))
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
				-- Previous Blizzard call changed 2026.09.25: local spellInfo = C_Spell.GetSpellInfo(useTarget)
				local spellInfo = RQE.API.Client.C_Spell.GetSpellInfo(useTarget)
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

		-------------------------------------------------------
		-- #7a.v. Cooldown Tooltip Hook
		-------------------------------------------------------

		---------------------------------------------------------------------
		-- Cooldown handler (visual greying + tooltip update)
		---------------------------------------------------------------------
		if not MagicButton.CooldownUpdater then
			MagicButton.CooldownUpdater = CreateFrame("Cooldown", nil, MagicButton, "CooldownFrameTemplate")
			MagicButton.CooldownUpdater:SetAllPoints(MagicButton)
			MagicButton.CooldownUpdater:SetDrawEdge(false)
			MagicButton.CooldownUpdater:SetSwipeColor(0, 0, 0, 0.6)
		end

		-- Hook tooltip refresh so the remaining cooldown shows live
		MagicButton:HookScript("OnEnter", function(self)
			-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName("RQE Macro")
			local macroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
			if not macroIndex or macroIndex == 0 then return end
			-- Previous Blizzard call changed 2026.09.25: local _, _, macroBody = GetMacroInfo(macroIndex)
			local _, _, macroBody = RQE.API.Client.GetMacroInfo(macroIndex)
			if not macroBody or macroBody == "" then return end

			local spellName = macroBody:match("/cast%s+(.+)")
			local itemName = macroBody:match("/use%s+(.+)")

			local cdStart, cdDur, cdEnable

			-- 12.0 fix for tooltips not being able to update when in combat, but this will update once combat ends
			if spellName then
				-- Previous Blizzard call changed 2026.09.25: if not InCombatLockdown() then
				if not RQE.API.Client.InCombatLockdown() then
					-- Previous Blizzard call changed 2026.09.25: local spellInfo = C_Spell.GetSpellInfo(spellName)
					local spellInfo = RQE.API.Client.C_Spell.GetSpellInfo(spellName)
					if spellInfo then
						-- Previous Blizzard call changed 2026.09.25: local cd = C_Spell.GetSpellCooldown(spellInfo.spellID)
						local cd = RQE.API.Client.C_Spell.GetSpellCooldown(spellInfo.spellID)
						if cd and cd.isEnabled then
							cdStart, cdDur, cdEnable = cd.startTime, cd.duration, cd.isEnabled
						end
					end
				end
			elseif itemName then
				-- Previous Blizzard call changed 2026.09.25: cdStart, cdDur, cdEnable = C_Item.GetItemCooldown(itemName)
				cdStart, cdDur, cdEnable = RQE.API.Client.C_Item.GetItemCooldown(itemName)
			end

			if cdEnable and cdDur and cdDur > 1 then
				GameTooltip:AddLine(string.format("|cff00ffffCooldown remaining: %.0f sec|r",
					-- Previous Blizzard call changed 2026.09.25: math.max(0, (cdStart + cdDur) - GetTime())), 1, 1, 1)
					math.max(0, (cdStart + cdDur) - RQE.API.Client.GetTime())), 1, 1, 1)
				GameTooltip:Show()
			end
		end)

		-------------------------------------------------------
		-- #7a.vi. Live Item Count & Cooldown Refresh
		-------------------------------------------------------

		-- ✅ Unified OnUpdate: Handles both item count + cooldown greyout
		MagicButton:SetScript("OnUpdate", function(self, elapsed)
			-- The cooldown widget animates itself; item counts/macro parsing do not
			-- need to run at the rendering frame rate.
			self.rqeStateElapsed = (self.rqeStateElapsed or 0) + elapsed
			if self.rqeStateElapsed < 0.1 then return end
			self.rqeStateElapsed = 0
			-- Previous Blizzard call changed 2026.09.25: local macroIndex = GetMacroIndexByName("RQE Macro")
			local macroIndex = RQE.API.Client.GetMacroIndexByName("RQE Macro")
			if not macroIndex or macroIndex == 0 then
				if self.CountText then self.CountText:SetText("") end
				if self.CooldownUpdater then self.CooldownUpdater:Clear() end
				self:SetAlpha(1)
				return
			end

			-- Previous Blizzard call changed 2026.09.25: local _, _, macroBody = GetMacroInfo(macroIndex)
			local _, _, macroBody = RQE.API.Client.GetMacroInfo(macroIndex)
			if not macroBody or macroBody == "" then
				if self.CountText then self.CountText:SetText("") end
				if self.CooldownUpdater then self.CooldownUpdater:Clear() end
				self:SetAlpha(1)
				return
			end

			----------------------------------------------------------
			-- 🧩 ITEM COUNT HANDLER
			----------------------------------------------------------
			local itemID = tonumber(macroBody:match("#showtooltip%s+item:(%d+)"))
			if not itemID then
				local itemName = macroBody:match("/use%s+(.+)")
				if itemName then
					-- Previous Blizzard call changed 2026.09.25: itemID = C_Item.GetItemInfoInstant(itemName)
					itemID = RQE.API.Client.C_Item.GetItemInfoInstant(itemName)
				end
			end

			if itemID then
				-- Previous Blizzard call changed 2026.09.25: local itemCount = C_Item.GetItemCount(itemID)
				local itemCount = RQE.API.Client.C_Item.GetItemCount(itemID)
				if itemCount and itemCount > 0 then
					if itemCount > 999 then itemCount = 999 end
					self.CountText:SetText(itemCount)
				else
					self.CountText:SetText("")
				end
			else
				self.CountText:SetText("")
			end

			----------------------------------------------------------
			-- 🧩 COOLDOWN & GREYOUT HANDLER
			----------------------------------------------------------
			local spellName = macroBody:match("/cast%s+(.+)")
			local itemName = macroBody:match("/use%s+(.+)")
			local cdStart, cdDur, cdEnable

			-- Fixed display of CD when during combat if the macro is a 'spell' vs an 'item'
			if spellName then
				-- Previous Blizzard call changed 2026.09.25: if not InCombatLockdown() then
				if not RQE.API.Client.InCombatLockdown() then
					-- Previous Blizzard call changed 2026.09.25: local spellInfo = C_Spell.GetSpellInfo(spellName)
					local spellInfo = RQE.API.Client.C_Spell.GetSpellInfo(spellName)
					if spellInfo then
						-- Previous Blizzard call changed 2026.09.25: local cd = C_Spell.GetSpellCooldown(spellInfo.spellID)
						local cd = RQE.API.Client.C_Spell.GetSpellCooldown(spellInfo.spellID)
						if cd and cd.isEnabled then
							cdStart, cdDur, cdEnable = cd.startTime, cd.duration, cd.isEnabled
						end
					end
				else
					if RQE.db.profile.debugLevel == "INFO+" then
						print("|cFFFF3333[RQE] Spell CD not available for RQE Button until after combat has ended|r")
					end
				end
			elseif itemName then
				-- Previous Blizzard call changed 2026.09.25: cdStart, cdDur, cdEnable = C_Item.GetItemCooldown(itemName)
				cdStart, cdDur, cdEnable = RQE.API.Client.C_Item.GetItemCooldown(itemName)
			end

			if cdEnable and cdDur and cdDur > 1 then
				self.CooldownUpdater:SetCooldown(cdStart, cdDur)
				self:SetAlpha(0.5) -- grey out while on cooldown
			else
				self.CooldownUpdater:Clear()
				self:SetAlpha(1)
			end
		end)

		-------------------------------------------------------
		-- #7a.vii. Tooltip Cleanup
		-------------------------------------------------------

		MagicButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
