--[[ 

Buttons.lua
Shared button behavior, main-frame controls, quest-tracker menus, and secure quest-item actions

]]


--------------------------------------------------
-- #1. 🌐 Namespace & Client State
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Addon Namespace & Bootstrap Diagnostics
	-------------------------------------------------------

	RQE = RQE or {}

	if RQE and RQE.debugLog then
		RQE.debugLog("Message here")
	else
		RQE.debugLog("RQE or RQE.debugLog is not initialized.")
	end

	RQE.Buttons = RQE.Buttons or {}
	RQE.Frame = RQE.Frame or {}

	-------------------------------------------------------
	-- #1b. Client Compatibility State
	-------------------------------------------------------

	-- RQE_API.lua is loaded before this file and identifies the compatibility family.
	local isRetail = RQE.IsRetail == true

	RQE.debugLog("RQE.content initialized: " .. tostring(RQE.content ~= nil))


--------------------------------------------------
-- #2. 🧰 Shared Button Utilities & Feedback
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Tooltip & Border Primitives
	-------------------------------------------------------

	-- Function to show tooltips
	local function ShowTooltip(self, text)
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 33)
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end


	-- Function to hide tooltips
	local function HideTooltip()
		GameTooltip:Hide()
	end


	-- Local function to create tooltip using ShowTooltip and HideTooltip
	local function CreateTooltip(button, text)
		button:SetScript("OnEnter", function(self) ShowTooltip(self, text) end)
		button:SetScript("OnLeave", HideTooltip)
	end


	-- Waypoint Buttons for Unlisted Quests (those not in the RQEDatabase)
	-- Local function to create border
	local function CreateBorder(button)
		if RQE.UI and RQE.UI:IsEnabled() then return end
		local border = button:CreateTexture(nil, "BACKGROUND")
		border:SetColorTexture(1, 1, 1, 1)
		border:SetAlpha(0.25)  -- Set the alpha to 0.5 (50% opacity)
		border:SetPoint("TOPLEFT", button, "TOPLEFT", -0.15, 0.15)
		border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0.15, -0.15)
	end

	-------------------------------------------------------
	-- #2b. Step Navigation Tooltip Refresh
	-------------------------------------------------------

	-- Refreshes Previous/Next enabled states and any tooltip currently being hovered.
	function RQE.Buttons.RefreshStepNavigationTooltips()
		if RQE.Buttons.UpdateHeaderNavigation then
			RQE.Buttons.UpdateHeaderNavigation()
		end

		-- Function to redraw a hovered navigation button's tooltip after its state changes
		local function RefreshButton(button)
			if not button then return end
			if not button:IsMouseOver() then return end

			local onEnter = button:GetScript("OnEnter")
			if not onEnter then return end

			GameTooltip:Hide()
			onEnter(button)
		end

		RefreshButton(RQE.PrevStepButton)
		RefreshButton(RQE.NextStepButton)
	end

	-------------------------------------------------------
	-- #2c. Unknown Quest Waypoint Tooltip
	-------------------------------------------------------

	-- Add mouseover tooltip and trigger map opening/closing
	RQE.UnknownButtonTooltip = function()
		RQE.UnknownQuestButton:SetScript("OnEnter", function(self)
			RQE.hoveringOnRQEFrameAndButton = true

			local searchedQuestID = RQE.searchedQuestID
			if searchedQuestID then
				local dbEntry = RQE.getQuestData(searchedQuestID)
				local isComplete
				local isInLog

				if isRetail then
					isComplete = C_QuestLog.IsQuestFlaggedCompleted(searchedQuestID)
					isInLog = C_QuestLog.GetLogIndexForQuestID(searchedQuestID)
				else
					isComplete = RQE.API.IsQuestFlaggedCompleted(searchedQuestID)
					isInLog = RQE.API.GetLogIndexForQuestID(searchedQuestID)
				end

				if not isInLog then
					local x, y, mapID, continentID = RQE.GetPrimaryLocation(dbEntry)
					local finalMapID

					if mapID then
						finalMapID = mapID
					elseif continentID then
						-- Only fallback if player is on that continent
						local playerMapID
						local parent

						if isRetail then
							playerMapID = C_Map.GetBestMapForUnit("player")
							parent = playerMapID and C_Map.GetMapInfo(playerMapID).parentMapID
						else
							playerMapID = RQE.API.GetBestMapForUnit("player")
							local mapInfo = playerMapID and RQE.API.GetMapInfo(playerMapID)
							parent = mapInfo and mapInfo.parentMapID
						end
						if parent == continentID then
							finalMapID = continentID
						end
					end

					if x and y and finalMapID then
						local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", x, y, tostring(finalMapID))
						GameTooltip:SetOwner(RQE.UnknownQuestButton, "ANCHOR_NONE")
						GameTooltip:ClearAllPoints()
						GameTooltip:SetPoint("TOPRIGHT", RQE.UnknownQuestButton, "TOPRIGHT", 0, 33)
						GameTooltip:SetText(tooltipText)
						GameTooltip:Show()

						RQE.WPxPos = x
						RQE.WPyPos = y
						RQE.WPmapID = finalMapID

						if RQE.db.profile.debugLevel == "INFO" then
							DEFAULT_CHAT_FRAME:AddMessage("From searchedQuestID fallback | QuestID: " .. searchedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)
						end
					else
						GameTooltip:SetOwner(RQE.UnknownQuestButton, "ANCHOR_NONE")
						GameTooltip:ClearAllPoints()
						GameTooltip:SetPoint("TOPRIGHT", RQE.UnknownQuestButton, "TOPRIGHT", 0, 33)
						GameTooltip:SetText("Coordinates unavailable for searched quest.")
						GameTooltip:Show()
					end
				end
			end

			if RQE.db.profile.autoClickWaypointButton then
				if RQE.db.profile.debugLevel == "INFO" then
					RQE.ClickWButton()
					C_Timer.After(0.3, function()
						C_Timer.After(0.2, function()
							RQE.CheckAndClickSeparateWaypointButtonButton()
							-- Prints the tooltip information for the separate focus waypoint button by duplicating RQE.GetTooltipDataForCButton() function call. The function call can't be performed due to an error.
							if RQE.db.profile.debugLevel == "INFO" then
								local stepIndex = RQE.AddonSetStepIndex or 1  -- Default to step index 1 if none is set
								local questID = RQE.API.GetSuperTrackedQuestID()
								local questData = RQE.getQuestData(questID)  -- Fetch quest data from RQEDatabase

								-- Ensure quest data exists and has the coordinate data
								if questData and questData[stepIndex] then
									local coordsText
									-- One true place to resolve coords (handles hotspots + legacy)
									local sx, sy, smap = RQE:GetStepCoordinates(stepIndex)  -- returns normalized (0–1)
									if sx and sy and smap then
										coordsText = string.format("Coordinates: (%.2f, %.2f) - MapID: %d", sx * 100, sy * 100, smap)
									end

									if coordsText then
										RQE.SeparateFocusCoordData = coordsText

										if RQE.db.profile.debugLevel == "INFO" then
											RQE.AddonSetStepIndex = RQE.AddonSetStepIndex or 1

											if RQE.WCoordData == RQE.SeparateFocusCoordData then
												RQE:KhadgarCoordsMatch(RQE.API.GetSuperTrackedQuestID())
											else
												RQE:CoordsNOMatch(RQE.API.GetSuperTrackedQuestID())
												print("DB Coordinates do NOT Match Blizzard coordinates for quest step!")
											end
										end

										RQE.DontPrintTransitionBits = true
										RQE.ClickUnknownQuestButton()
										RQE.DontPrintTransitionBits = false
										return coordsText
									else
										if RQE.db.profile.debugLevel == "INFO" then
											print("DB Coordinates missing for quest step!")
											RQE:PlayThrottledSound(5927)
										end
										RQE.DontPrintTransitionBits = true
										RQE.ClickUnknownQuestButton()
										RQE.DontPrintTransitionBits = false
										return "No tooltip available."
									end
								end
							end
						end)
					end)
				end
			end
			C_Timer.After(0.2, function()
				GameTooltip:SetOwner(RQE.UnknownQuestButton, "ANCHOR_NONE")
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("TOPRIGHT", RQE.UnknownQuestButton, "TOPRIGHT", 0, 33)

				-- Resets the master waypoint
				RQE.WPxPos = nil
				RQE.WPyPos = nil
				RQE.WPmapID = nil

				local currentSuperTrackedQuestID = RQE.API.GetSuperTrackedQuestID()

				-- Add check to ensure RQE.QuestIDText exists and contains valid text
				local extractedQuestID
				if RQE.QuestIDText and RQE.QuestIDText:GetText() then
					extractedQuestID = RQE.DisplayedQuestID
				end

				RQE.CurrentTrackedQuestID = RQE.searchedQuestID or extractedQuestID or currentSuperTrackedQuestID

				if not RQE.CurrentTrackedQuestID then
					RQE.CurrentTrackedQuestID = 0
				end

				if RQE.CurrentTrackedQuestID then  -- Add a check to ensure questID is not nil
					local mapID = GetQuestUiMapID(RQE.CurrentTrackedQuestID)
					RQE.WPmapID = mapID
					local questData = RQE.getQuestData(RQE.CurrentTrackedQuestID)
					local x, y
					if isRetail then
						x, y = C_QuestLog.GetNextWaypointForMap(RQE.CurrentTrackedQuestID, mapID)
					else
						x, y = RQE.API.GetNextWaypointForMap(RQE.CurrentTrackedQuestID, mapID)
					end
					RQE.WPxPos = x
					RQE.WPyPos = y
					if RQE.WPxPos ~= nil then
						local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", RQE.WPxPos * 100, RQE.WPyPos * 100, tostring(RQE.WPmapID))
						if RQE.db.profile.debugLevel == "INFO" then
							DEFAULT_CHAT_FRAME:AddMessage("QuestID: " .. RQE.CurrentTrackedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)  -- Cyan
							local directionText
							if isRetail then
								directionText = C_QuestLog.GetNextWaypointText(RQE.CurrentTrackedQuestID)
							else
								directionText = RQE.API.GetNextWaypointText(RQE.CurrentTrackedQuestID)
							end

							if directionText then
								DEFAULT_CHAT_FRAME:AddMessage("				coordinateHotspots = {", 0, 1, 1)	-- Cyan color
								DEFAULT_CHAT_FRAME:AddMessage(string.format("					{ x = %.2f, y = %.2f, mapID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35, wayText = %q },", RQE.WPxPos * 100, RQE.WPyPos * 100, tostring(RQE.WPmapID), directionText), 0, 1, 1)	-- Cyan color
								DEFAULT_CHAT_FRAME:AddMessage("				},", 0, 1, 1)	-- Cyan color
							else
								DEFAULT_CHAT_FRAME:AddMessage(string.format("coordinates = { x = %.2f, y = %.2f, mapID = %d },", RQE.WPxPos * 100, RQE.WPyPos * 100, tostring(RQE.WPmapID)), 0, 1, 1)	-- Cyan color
							end

							RQE.WCoordData = tooltipText
						end
					end
					if mapID == 0 then mapID = nil end
				end

				if RQE.DatabaseSuperX then
					-- If coordinates are already available, just show them
					local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", RQE.DatabaseSuperX * 100, RQE.DatabaseSuperY * 100, tostring(RQE.DatabaseSuperMapID))
					if RQE.db.profile.debugLevel == "INFO" then
						DEFAULT_CHAT_FRAME:AddMessage("QuestID: " .. RQE.CurrentTrackedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)  -- Cyan
						RQE.WCoordData = tooltipText
					end
					GameTooltip:SetText(tooltipText)
					GameTooltip:Show()

					-- Saves the coords used to create the tooltip
					RQE.WPxPos = RQE.DatabaseSuperX
					RQE.WPyPos = RQE.DatabaseSuperY
					RQE.WPmapID = RQE.DatabaseSuperMapID

				elseif not RQE.DatabaseSuperX and RQE.DatabaseSuperY or not RQE.superX or not RQE.superY and RQE.superMapID then
					-- Use RQE.GetQuestCoordinates to get the coordinates
					local x, y, mapID = RQE.GetQuestCoordinates(RQE.CurrentTrackedQuestID)
					if x and y and mapID then
						local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", x * 100, y * 100, tostring(mapID))
						if RQE.db.profile.debugLevel == "INFO" then
							DEFAULT_CHAT_FRAME:AddMessage("QuestID: " .. RQE.CurrentTrackedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)  -- Cyan

							-- Extract x, y, and mapID directly from tooltipText (ensures identical Blizzard values)
							local bx, by, bmap = string.match(tooltipText, "%(([%d%.]+),%s*([%d%.]+)%)%s*%-%s*MapID:%s*(%d+)")

							if bx and by and bmap then
								DEFAULT_CHAT_FRAME:AddMessage(string.format("coordinates = { x = %.2f, y = %.2f, mapID = %d },", tonumber(bx), tonumber(by), tonumber(bmap)), 0, 1, 1)	-- Cyan color
								DEFAULT_CHAT_FRAME:AddMessage("				coordinateHotspots = {", 0, 1, 0)  -- Green color
								DEFAULT_CHAT_FRAME:AddMessage(string.format("					{ x = %.2f, y = %.2f, mapID = %d, priorityBias = 1, minSwitchYards = 15, visitedRadius = 35 },", tonumber(bx), tonumber(by), tonumber(bmap)), 0, 1, 0)
								DEFAULT_CHAT_FRAME:AddMessage("				},", 0, 1, 0)
							else
								-- Fallback if parsing fails
								DEFAULT_CHAT_FRAME:AddMessage("QuestID: " .. RQE.CurrentTrackedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)
							end

							RQE.WCoordData = tooltipText
						end
						GameTooltip:SetText(tooltipText)
					else
						-- Fallback to using RQE.GetNextWaypoint if coordinates are not available
						local waypointMapID, waypointX, waypointY
						if isRetail then
							waypointMapID, waypointX, waypointY = C_QuestLog.GetNextWaypoint(RQE.CurrentTrackedQuestID)
						else
							waypointMapID, waypointX, waypointY = RQE.API.GetNextWaypoint(RQE.CurrentTrackedQuestID)
						end
						if waypointX and waypointY and waypointMapID then
							local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", waypointX * 100, waypointY * 100, tostring(waypointMapID))
							if RQE.db.profile.debugLevel == "INFO" then
								RQE.WCoordData = tooltipText
							end
							GameTooltip:SetText(tooltipText)
						else
							GameTooltip:SetText("Coordinates: Not available.")
						end
						-- Saves the coords used to create the tooltip
						RQE.WPxPos = waypointX
						RQE.WPyPos = waypointY
						RQE.WPmapID = waypointMapID
					end
					GameTooltip:Show()
				else
					-- If coordinates are already available, just show them
					local tooltipText = string.format("Coordinates: (%.2f, %.2f) - MapID: %s", RQE.superX * 100, RQE.superY * 100, tostring(RQE.superMapID))
					if RQE.db.profile.debugLevel == "INFO" then
						DEFAULT_CHAT_FRAME:AddMessage("QuestID: " .. RQE.CurrentTrackedQuestID .. " - Coords: " .. tooltipText, 0, 1, 1)  -- Cyan
						RQE.WCoordData = tooltipText
					end
					GameTooltip:SetText(tooltipText)
					GameTooltip:Show()

					-- Saves the coords used to create the tooltip
					RQE.WPxPos = RQE.superX
					RQE.WPyPos = RQE.superY
					RQE.WPmapID = RQE.superMapID
				end
				-- Fixed taint caused when mousing over "W" button while in combat
				if not InCombatLockdown() then
					if not RQE.DontCloseMap then
						WorldMapFrame:Hide()
					end
				end
			end)
		end)
	end

	-------------------------------------------------------
	-- #2d. Coordinate Validation Alerts
	-------------------------------------------------------

	-- Function that handles the alert/sound when the coords match between DB and Blizz
	function RQE:KhadgarCoordsMatch(questID)
		local isContributionLoaded
		if isRetail then
			isContributionLoaded = C_AddOns.IsAddOnLoaded("RQE_Contribution")
		else
			isContributionLoaded = RQE.API.IsAddOnLoaded("RQE_Contribution")
		end
		if not isContributionLoaded then return end

		questID = tonumber(questID) or 0
		if questID then
			local leavemessage = string.format("** Coordinates Match (QID: %d) **", questID)
			RaidNotice_AddMessage(RaidWarningFrame, leavemessage, { r = 1, g = 0, b = 1 })
		else
			local leavemessage = "** Coordinates Match **"
			RaidNotice_AddMessage(RaidWarningFrame, leavemessage, ChatTypeInfo["RAID_WARNING"])
		end

		PlaySound(8959)

		C_Timer.After(0.5, function()
			RQE:PlayThrottledSound(45024)	-- VO_60_SMV_KHADGAR_GREETING (Khadgar: Greeting)
		end)


		if RQEFrame and not RQEFrame:IsMouseOver() then
			return
		end

		C_Timer.After(1.2, function()
			RQE:CheckCoordHotspotsInSteps(questID)
		end)
	end

	-- Function that handles the alert/sound when the coords do not between DB and Blizz
	function RQE:CoordsNOMatch(questID)
		local isContributionLoaded
		if isRetail then
			isContributionLoaded = C_AddOns.IsAddOnLoaded("RQE_Contribution")
		else
			isContributionLoaded = RQE.API.IsAddOnLoaded("RQE_Contribution")
		end
		if not isContributionLoaded then return end

		questID = tonumber(questID) or 0
		if questID then
			local leavemessage = string.format("** NO Coordinates Match (QID: %d) **", questID)
			RaidNotice_AddMessage(RaidWarningFrame, leavemessage, { r = 1, g = 0, b = 0 })
		else
			local leavemessage = "** NO Coordinates Match **"
			RaidNotice_AddMessage(RaidWarningFrame, leavemessage, ChatTypeInfo["RAID_WARNING"])
		end

		PlaySound(8959)

		C_Timer.After(0.5, function()
			RQE:PlayThrottledSound(135755)	-- VO_82_Mechagnome_Citizen_Formal_F_Greetings
		end)

		if RQEFrame and not RQEFrame:IsMouseOver() then
			return
		end

		C_Timer.After(1.2, function()
			RQE:CheckCoordHotspotsInSteps(questID)
		end)
	end

	-- Function that handles the alert when the DB entry contains legacy "coordinates" in any stepIndex
	function RQE:LegacyCoordsDetected(questID)
		local isContributionLoaded
		if isRetail then
			isContributionLoaded = C_AddOns.IsAddOnLoaded("RQE_Contribution")
		else
			isContributionLoaded = RQE.API.IsAddOnLoaded("RQE_Contribution")
		end
		if not isContributionLoaded then return end

		questID = tonumber(questID) or 0
		local leavemessage = string.format("** Legacy Coordinates Detected! (QID: %d) **", questID)

		PlaySound(8959)
		RaidNotice_AddMessage(RaidWarningFrame, leavemessage, { r = 1, g = 1, b = 0 })
		C_Timer.After(0.5, function()
			RQE:PlayThrottledSound(4574)	-- igPVPUpdate
		end)
	end

	-- Function that handles the alert when the DB entry contains legacy "coordinates" in any stepIndex
	function RQE:NoDBEntryForQuest(questID)
		local isChattynatorLoaded
		local isContributionLoaded
		if isRetail then
			isChattynatorLoaded = C_AddOns.IsAddOnLoaded("Chattynator")
			isContributionLoaded = C_AddOns.IsAddOnLoaded("RQE_Contribution")
		else
			isChattynatorLoaded = RQE.API.IsAddOnLoaded("Chattynator")
			isContributionLoaded = RQE.API.IsAddOnLoaded("RQE_Contribution")
		end
		if isChattynatorLoaded then return end
		if not isContributionLoaded then return end

		questID = tonumber(questID) or 0
		local leavemessage = string.format("** No DB Entries for Quest (QID: %d) **", questID)

		RaidNotice_AddMessage(RaidWarningFrame, leavemessage, { r = 1, g = 0, b = 0 })

		C_Timer.After(0.5, function()
			RQE:PlayThrottledSound(3784)	-- AirElemental
		end)
	end

	-- Function that handles the alert when the DB entry contains NO legacy "coordinates" in any stepIndex and only coordinateHotspots
	function RQE:NoLegacyCoordsDetected(questID)
		local isContributionLoaded
		if isRetail then
			isContributionLoaded = C_AddOns.IsAddOnLoaded("RQE_Contribution")
		else
			isContributionLoaded = RQE.API.IsAddOnLoaded("RQE_Contribution")
		end
		if not isContributionLoaded then return end

		questID = tonumber(questID) or 0
		local leavemessage = string.format("** All steps use coordinateHotspots (QID: %d) **", questID)

		PlaySound(8959)
		RaidNotice_AddMessage(RaidWarningFrame, leavemessage, { r = 0, g = 1, b = 0 })

		C_Timer.After(0.5, function()
			RQE:PlayThrottledSound(888)	-- LEVELUP
		end)
	end

	-------------------------------------------------------
	-- #2e. Unknown Quest Button Interaction
	-------------------------------------------------------

	-- Hide the tooltip when the mouse leaves
	RQE.HideUnknownButtonTooltip = function()
		RQE.UnknownQuestButton:SetScript("OnLeave", function()
			RQE.hoveringOnRQEFrameAndButton = false
			GameTooltip:Hide()
		end)
	end

	-- Add a mouse down event to simulate a button press
	RQE.UnknownQuestButtonMouseDown = function()
		RQE.UnknownQuestButton:SetScript("OnMouseDown", function(self, button)
			if button ~= "LeftButton" then return end

			RQE.bg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press

			local questID = RQE.searchedQuestID
			if not questID then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("No searched quest available.")
				end
				return
			end

			local dbEntry = RQE.getQuestData(questID)
			if not dbEntry then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("No DB entry found for quest", questID)
				end
				return
			end

			-- ✅ Figure out which mapID or continentID to use
			local playerMapID = C_Map.GetBestMapForUnit("player")
			local selectedMapID = nil

			-- Single-location quests
			if dbEntry.location then
				selectedMapID = dbEntry.location.mapID or dbEntry.location.continentID

			-- Multi-location quests
			elseif dbEntry.locations then
				local matchedZone = nil
				local continentCandidate = nil

				for _, loc in ipairs(dbEntry.locations) do
					if loc.mapID == playerMapID then
						matchedZone = loc.mapID
						break
					end
				end

				-- ✅ Prefer zone if player is physically in that zone
				if matchedZone then
					selectedMapID = matchedZone
				else
					-- Player not in the quest zone, fallback to continent-level coords
					for _, loc in ipairs(dbEntry.locations) do
						if loc.continentID then
							selectedMapID = loc.continentID
							break
						end
					end
				end
			end

			if not selectedMapID then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("Unable to determine which mapID/continentID to use for quest:", questID)
				end
				return
			end

			-- ✅ Create the waypoint via the proper function
			RQE:CreateSearchedQuestWaypoint(questID, selectedMapID)

			if RQE.db.profile.debugLevel == "INFO+" then
				print(("W-button: CreateSearchedQuestWaypoint called for Quest %d on map %d"):format(questID, selectedMapID))
			end
		end)
	end

	-- Add a mouse up event to reset the texture
	RQE.UnknownQuestButtonMouseUp = function()
		RQE.UnknownQuestButton:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" then
				RQE.bg:SetAlpha(1)  -- Reset the alpha
			end
		end)
	end

	-------------------------------------------------------
	-- #2f. Group Finder Sounds & Button Feedback
	-------------------------------------------------------

	-- Handles the Raid Message Alert and sound when group is forming/no longer forming in LFG
	-- Prevents sound from playing on top of each other if switching between forming group and no longer forming group
	RQE.lastSoundTime = RQE.lastSoundTime or 0
	RQE.soundThrottle = 2 -- seconds between sounds

	-- Function to play an alert sound only when the shared sound cooldown has elapsed
	function RQE:PlayThrottledSound(soundID)
		local timeNow = GetTime() -- Get the current time in seconds
		if (timeNow - self.lastSoundTime) >= self.soundThrottle then
			PlaySound(soundID)
			self.lastSoundTime = timeNow
		end
	end

	-- Function that handles the alert/sound when LFG quest group no longer forming
	function RQE:StopFormingLFG()
		local leavemessage = "LFG Group has been delisted."
		self:PlayThrottledSound(9244)
		RaidNotice_AddMessage(RaidWarningFrame, leavemessage, ChatTypeInfo["RAID_WARNING"])
	end

	-- Function that handles the alert/sound when LFG quest group is forming
	function RQE:FormLFG()
		local createmessage = "Your quest group is forming."
		RaidNotice_AddMessage(RaidWarningFrame, createmessage, ChatTypeInfo["RAID_WARNING"])
	end

	-- Function to attach Search Group press handling for searching, creating, or delisting quest groups
	RQE.SearchGroupButtonMouseDown = function()
		RQE.SearchGroupButton:SetScript("OnMouseDown", function(self, button)
			RQE.sgbg:SetAlpha(0.5)  -- Lower the alpha to simulate a button press

			local questID = RQE.API.GetSuperTrackedQuestID()
			if not questID then
				print("No super-tracked quest to handle LFG.")
				return
			end

			if IsShiftKeyDown() and button == "LeftButton" then
				-- Delist the group if Shift + LeftClick
				RQE:LFG_Delist(questID)
				RQE.LFGActive = false -- Delisting means no active group
			elseif button == "LeftButton" then
				-- Search for groups if LeftClick
				RQE:LFG_Search(questID)
			elseif button == "RightButton" then
				-- Create or delist group if RightClick
				if RQE.LFGActive then
					-- Group is active, delist it
					RQE:LFG_Delist(questID)
					RQE:StopFormingLFG()
					RQE.LFGActive = false -- Mark group as inactive
				else
					-- Group is not active, create a new group
					RQE:LFG_Create(questID)
					
					-- Delay to check if the group was successfully created
					C_Timer.After(2, function()
						-- Check if group was successfully created using C_LFGList.GetActiveEntryInfo()
						local groupInfo = C_LFGList.GetActiveEntryInfo()
						if groupInfo then
							--print("Group successfully created for quest ID:", questID)
							RQE.LFGActive = true -- Mark group as active
							RQE:FormLFG()
						else
							--print("Failed to create a group.")
							RQE.LFGActive = false -- No group formed
							RQE:StopFormingLFG()
						end
					end)
				end
			end
		end)

		RQE.SearchGroupButton:SetScript("OnMouseUp", function(self, button)
			RQE.sgbg:SetAlpha(1)  -- Reset the alpha
		end)
	end


--------------------------------------------------
-- #3. 🪄 Quest Helper Header Controls
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Secure Magic Macro Button
	-------------------------------------------------------

	-- Parent function to Create Magic Button for Super Tracked quest (runs the RQE Macro)
	function RQE.Buttons.CreateMagicButton(RQEFrame)
		local MagicButton = CreateFrame("Button", "RQEMagicButton", UIParent, "SecureActionButtonTemplate")
		MagicButton:SetSize(32, 32)  -- Set the button size
		MagicButton:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", -50, -30)  -- Positioning the button

		-- Storing MagicButton within the RQE table
		RQE.MagicButton = MagicButton

		-- Update the Icon of the Magic Button
		RQE.Buttons.UpdateMagicButtonIcon()

		-- Default icon texture ID or path
		local defaultIconID = 134400 -- This is just an example; replace with a valid default icon ID or path
		local iconID = defaultIconID -- Initialize with default icon

		local macroIndex = GetMacroIndexByName("RQE Macro")
		if macroIndex > 0 then
			local _, macroIconID = GetMacroInfo(macroIndex)
			if macroIconID then
				iconID = macroIconID -- Use the macro's icon if available
			end
		end

		-- Set the button to execute the "RQE Macro"
		MagicButton:SetAttribute("type", "macro")
		MagicButton:SetAttribute("macro", "RQE Macro")
		MagicButton:RegisterForClicks("AnyUp", "AnyDown")

		-- Set the button's appearance
		MagicButton:SetNormalTexture(iconID)  -- Example texture ID, replace with actual macro icon or path
		MagicButton:SetHighlightTexture(iconID, "ADD")

		-- Tooltip
		MagicButton:SetScript("OnEnter", function(self)
			local macroIndex = GetMacroIndexByName("RQE Macro")
			if macroIndex and macroIndex > 0 then
				local _, _, body = GetMacroInfo(macroIndex)
				-- Check if the body has content (not nil and not an empty string)
				if body and string.trim(body) ~= "" then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetText(body, nil, nil, nil, nil, true)
					GameTooltip:Show()
				else
					-- Optionally, clear any existing tooltip since there's no content
					GameTooltip:Hide()
				end
			end
		end)

		-- Local helper function to trim strings (removes whitespace from the beginning and end of a string)
		local function trim(s)
			return s:match("^%s*(.-)%s*$")
		end

		MagicButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		return MagicButton
	end

	-------------------------------------------------------
	-- #3b. Macro Visibility & Override Binding
	-------------------------------------------------------

	-- Update MagicButton based on macro content
	function RQE.Buttons.UpdateMagicButtonVisibility()
		if InCombatLockdown() then
			return
		end

		local macroIndex = GetMacroIndexByName("RQE Macro")
		local MagicButton = RQE.MagicButton -- Assuming MagicButton stored globally in RQE.MagicButton

		-- Check if the RQEFrame is hidden first
		if not RQEFrame or not RQEFrame:IsShown() then
			if RQE.MagicButton then
				RQE.MagicButton:Hide() -- Ensure MagicButton is hidden if RQEFrame is not shown
			end
			return -- Exit the function early if RQEFrame is hidden
		end

		if macroIndex > 0 then
			local _, _, body = GetMacroInfo(macroIndex)
			if body and body:trim() ~= "" then
				if MagicButton then MagicButton:Show() end
			else
				if MagicButton then MagicButton:Hide() end
			end
		else
			if MagicButton then MagicButton:Hide() end
		end
	end

	-- Function to set up an override key binding for macro
	function RQE:SetupOverrideMacroBinding()
		if not self.db then return end
		local profile = self.db.profile
		-- Migrate the legacy field only when there is no explicit modern value.
		-- An empty modern value must remain an intentional unbind.
		if rawget(profile, "keyBindSetting") == nil and rawget(profile, "macroBindingKey") ~= nil then
			profile.keyBindSetting = profile.macroBindingKey
		end
		profile.macroBindingKey = nil
		if InCombatLockdown() then
			self.ReapplyMacroBindingAfterCombat = true
			return
		end
		local ownerFrame = self.MagicButton
		if not ownerFrame then return end
		self.ReapplyMacroBindingAfterCombat = nil

		-- Clear the old profile's override even when unbound or the macro is gone.
		ClearOverrideBindings(ownerFrame)
		local bindingKey = profile.keyBindSetting
		if not bindingKey or bindingKey == "" then return end
		local macroIndex = GetMacroIndexByName("RQE Macro")
		if macroIndex and macroIndex > 0 then
			SetOverrideBindingMacro(ownerFrame, true, bindingKey, macroIndex)
		end
	end

	-- Function to reapply the saved macro binding at login or reload
	function RQE:ReapplyMacroBinding()
		-- The configuration and login paths must use the same canonical field.
		self:SetupOverrideMacroBinding()
	end

	-- Remember to clear the override binding when it's no longer needed or when UI is hidden
	local function ClearOverrideMacroBinding()
		local ownerFrame = RQE.MagicButton -- The same frame binding is set to

		if InCombatLockdown() or not ownerFrame then
			return
		end

		-- This will clear all override bindings associated with the ownerFrame
		ClearOverrideBindings(ownerFrame)
	end

	-------------------------------------------------------
	-- #3c. Clear Button & Confirmation Flow
	-------------------------------------------------------

	-- Parent function to Create ClearButton
	function RQE.Buttons.CreateClearButton(RQEFrame)
		local ClearButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		ClearButton:SetSize(18, 18)
		ClearButton:SetText("C")
		RQE.ClearButton = ClearButton  -- Store reference for later use

		-- Set the frame strata and level
		ClearButton:SetFrameStrata("MEDIUM")
		ClearButton:SetFrameLevel(3)

		-- Nested functions
		ClearButton:SetPoint("TOPLEFT", RQEFrame, "TOPLEFT", 6, -6)  -- Anchoring
		-- Function to clear the active quest window and associated tracking state after confirmation
		local function clearWindowAfterConfirmation()
			-- Code for ClearButton functionality here
			RQE.Buttons.ClearButtonPressed()
			RQE.searchedQuestID = nil
			C_Timer.After(0.3, function()
				RQE:SaveSuperTrackedQuestToCharacter()

				-- Code for RWButton functionality here
				C_Map.ClearUserWaypoint()
				-- Check if TomTom is loaded and compatibility is enabled
				local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
				if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
					TomTom.waydb:ResetProfile()
					RQE._currentTomTomUID = nil
				end
			end)

			-- Reset manually tracked quests
			if RQE.ManuallyTrackedQuests then
				for questID in pairs(RQE.ManuallyTrackedQuests) do
					RQE.ManuallyTrackedQuests[questID] = nil
				end
			end
		end
		ClearButton:SetScript("OnClick", function(_, mouseButton)
			-- Internal clear callers invoke the script without a mouse button; only
			-- the player's physical C press asks to abandon an ordered route.
			if mouseButton and RQE:RequestCoordOrderTrackingConfirmation("clear", nil,
				clearWindowAfterConfirmation) then return end
			clearWindowAfterConfirmation()
		end)

		CreateTooltip(ClearButton, "Clear Window")  -- Tooltip
		CreateBorder(ClearButton)  -- Border
		if RQE.UI then RQE.UI:StyleIconButton(ClearButton, "Clear") end

		return ClearButton
	end

	-- Function to handle the clearing of the RQEFrame when the "C" button is pressed (or similar functionality is desired)
	function RQE.Buttons.ClearButtonPressed()
		RQE.ClearButtonPressed = true	 -- FORCES the next clear (might need to add a check to make sure that the player physically pressed the button for this to actually clear the frame)
		RQE.ActiveCoordblock = nil	 -- C clears the temporary [Active] coordblock label with the window

		-- RESET the throttling system so next update actually fires
		RQE.FrameState = {
			lastQuestID = nil,
			lastQuestName = nil,
			lastObjectives = nil,
			lastNumObjectives = 0,
			lastStepIndex = nil
		}

		RQE:ClearFrameData()
		RQE:ClearWaypointButtonData()
		RQE:ClearSeparateFocusFrame()

		RQE.ManualSuperTrack = nil
		RQE.DontUpdateFrame = false
		RQE.ClearButtonPressed = true
		RQE.isSuperTracking = false			-- This is the variable that gets checked when RQE.isPlayerSuperTrackingQuest() runs
		RQE.CurrentlySuperQuestID = nil		-- This is the variable that gets saved when RQE.isPlayerSuperTrackingQuest() runs and a quest is being super tracked
		RQE:RemoveSuperTrackingFromQuest()
		RQE:UpdateRQEFrameVisibility()

		C_Map.ClearUserWaypoint()
		-- Check if TomTom is loaded and compatibility is enabled
		local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
			TomTom.waydb:ResetProfile()
			RQE._currentTomTomUID = nil
		end

		-- Clearing the frame data a second time
		C_Timer.After(0.2, function()
			RQE.isSuperTracking = false
			RQE.CurrentlySuperQuestID = nil
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQE:RemoveSuperTrackingFromQuest()
		end)

		-- Clearing the frame data a third time
		C_Timer.After(0.3, function()
			RQE.isSuperTracking = false
			RQE.CurrentlySuperQuestID = nil
			RQE:ClearFrameData()
			RQE:ClearWaypointButtonData()
			RQE:RemoveSuperTrackingFromQuest()
		end)

		C_Timer.After(0.2, function()
			RQEMacro:ClearMacroContentByName("RQE Macro")
		end)

		C_Timer.After(0.2, function()
			RQE.Buttons.UpdateMagicButtonVisibility()
		end)
	end

	-------------------------------------------------------
	-- #3d. Recenter Waypoint Button
	-------------------------------------------------------

	-- Parent function to create RWButton
	function RQE.Buttons.CreateRWButton(RQEFrame)
		local RWButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		RWButton:SetSize(18, 18)
		RWButton:SetText("RW")
		RQE.RWButton = RWButton

		-- Set the frame strata and level
		RWButton:SetFrameStrata("MEDIUM")
		RWButton:SetFrameLevel(3)

		-- Nested functions
		RWButton:SetPoint("TOPLEFT", RQE.ClearButton, "TOPRIGHT", 3, 0)  -- Anchoring
		RWButton:SetScript("OnClick", function()
			-- Code for RWButton functionality here
			C_Map.ClearUserWaypoint()
			-- Check if TomTom is loaded and compatibility is enabled
			local _, isTomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
			if isTomTomLoaded and RQE.db.profile.enableTomTomCompatibility then
				TomTom.waydb:ResetProfile()
				RQE._currentTomTomUID = nil
			end
		end)

		CreateTooltip(RWButton, "Remove Waypoints")
		CreateBorder(RWButton)
		if RQE.UI then RQE.UI:StyleIconButton(RWButton, "RemoveWaypoint") end

		return RWButton
	end

	-------------------------------------------------------
	-- #3e. Search & Contribution Launchers
	-------------------------------------------------------

	-- Parent function to create SearchButton
	function RQE.Buttons.CreateSearchButton(RQEFrame)
		local SearchButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		SearchButton:SetSize(18, 18)
		SearchButton:SetText("S")
		RQE.SearchButton = SearchButton  -- Storing the reference in the RQE table

		-- Set the frame strata and level
		SearchButton:SetFrameStrata("MEDIUM")
		SearchButton:SetFrameLevel(3)

		-- Nested functions
		SearchButton:SetPoint("TOPLEFT", RQE.RWButton, "TOPRIGHT", 3, 0)  -- Anchoring
		SearchButton:SetScript("OnClick", function()
			RQE.isSearchFrameShown = not RQE.isSearchFrameShown  -- Toggle the variable
			CreateSearchFrame(RQE.isSearchFrameShown)  -- Pass the updated variable
		end)

		CreateTooltip(SearchButton, "Search by Quest ID")
		CreateBorder(SearchButton)
		if RQE.UI then RQE.UI:StyleIconButton(SearchButton, "Search") end

		return SearchButton
	end

	-- Function to detect the Contribution addon through the API available on the active client
	local function IsContributionAddonLoaded()
		if isRetail then
			return C_AddOns and C_AddOns.IsAddOnLoaded
				and C_AddOns.IsAddOnLoaded("RQE_Contribution")
		end
		return RQE.API and RQE.API.IsAddOnLoaded
			and RQE.API.IsAddOnLoaded("RQE_Contribution")
	end

	-- RQE owns the Contribution launcher so its placement and skin remain stable.
	-- RQE_Contribution continues to own the editor frame and every editor action.
	function RQE.Buttons.CreateContributionButton(RQEFrame)
		if RQE.RQEContributionButton then return RQE.RQEContributionButton end

		local button = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		button:SetSize(18, 18)
		button:SetText("$")
		button:SetFrameStrata("MEDIUM")
		button:SetFrameLevel(3)
		button:SetPoint("TOPLEFT", RQE.SearchButton, "TOPRIGHT", 3, 0)
		button:Hide()
		RQE.RQEContributionButton = button

		button:SetScript("OnClick", function()
			local editor = RQE.ContributeFrame
			if not editor then return end
			local showEditor = not editor:IsShown()
			if showEditor then editor:Show() else editor:Hide() end

			if RQE_Contribution and RQE_Contribution.ToggleContributeButtons then
				RQE_Contribution:ToggleContributeButtons(showEditor)
			end
			if showEditor and C_Timer and C_Timer.After then
				C_Timer.After(2, function()
					if editor:IsShown() and RQE_Contribution
						and RQE_Contribution.SearchQuestIDFieldInStepEditor then
						RQE_Contribution:SearchQuestIDFieldInStepEditor()
					end
				end)
			end
		end)

		CreateTooltip(button, "Show/Hide RQE Contribution Step Editor")
		CreateBorder(button)
		if RQE.UI then RQE.UI:StyleContributionButton(button) end
		return button
	end

	-- Function to show, hide, and restyle the Contribution launcher when its editor becomes available
	function RQE.Buttons.RefreshContributionButton()
		local button = RQE.RQEContributionButton
		if not button then return end

		if IsContributionAddonLoaded() and RQE.ContributeFrame then
			-- During the transition, older Contribution builds may still create
			-- their own launcher. Hide that duplicate and restore RQE's owner.
			local duplicate = RQE.ContributeButton
			if duplicate and duplicate ~= button then duplicate:Hide() end
			RQE.ContributeButton = button
			button:Show()
			if RQE.UI then RQE.UI:StyleContributionButton(button) end
		else
			if RQE.ContributeButton == button then RQE.ContributeButton = nil end
			button:Hide()
		end

		if RQE.Buttons.UpdateHeaderNavigation then
			RQE.Buttons.UpdateHeaderNavigation()
		end
	end

	-------------------------------------------------------
	-- #3f. Displayed Step & Navigation Availability
	-------------------------------------------------------

	-- Returns the currently displayed stepIndex, preferring manual preview over automatic progress.
	function RQE:GetDisplayedStepIndex()
		if isRetail then
			if not RQE.db.profile.enableStepControls then return end
		else
			local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
			if not RQE:CanUseStepControlsForQuest(questID) then return end
		end
		return RQE.ManualPreviewStepIndex
			or RQE.AddonSetStepIndex
			or RQE.CurrentStepIndex
			or 1
	end

	-- Returns whether the manual step controls have a valid adjacent step in each
	-- direction. Searched Classic/TBC quests retain their synthetic pickup step 0.
	local function GetStepNavigationAvailability()
		local questID
		if isRetail then
			questID = RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
		else
			questID = RQE.searchedQuestID or RQE.DisplayedQuestID
				or RQE.API.GetSuperTrackedQuestID()
		end

		local questData = questID and RQE.getQuestData(questID)
		local currentStep = tonumber(RQE:GetDisplayedStepIndex())
		if not questData or not currentStep then return false, false end

		local firstStep = 1
		if not isRetail and RQE.CanNavigateSearchedQuestSteps
			and RQE:CanNavigateSearchedQuestSteps(questID) then
			firstStep = 0
		end

		local previousStep = currentStep - 1
		local canGoBack = currentStep > firstStep
			and (previousStep == 0 or questData[previousStep] ~= nil)
		local canGoForward = questData[currentStep + 1] ~= nil
		return canGoBack, canGoForward
	end

	-------------------------------------------------------
	-- #3g. Quest Helper Close Button
	-------------------------------------------------------

	-- Parent function to create CloseButton
	function RQE.Buttons.CreateCloseButton(RQEFrame)
		local CloseButton = CreateFrame("Button", nil, RQEFrame, "UIPanelCloseButton")
		CloseButton:SetSize(18, 18)
		RQE.CloseButton = CloseButton  -- Storing the reference in the RQE table

		-- Set the frame strata and level
		CloseButton:SetFrameStrata("MEDIUM") -- Strata makes it appear behind most frames except actionbars, but actionbars remain clickable despite appearance of UIPanelCloseButton icon "in front" of action bar
		CloseButton:SetFrameLevel(3)

		-- Nested functions
		CloseButton:SetPoint("TOPRIGHT", RQEFrame, "TOPRIGHT", -6, -6)  -- Anchoring
		CloseButton:SetScript("OnClick", function(self, button)
			RQE.isRQEFrameManuallyClosed = true -- Marking the frame as manually closed
			RQEFrame:Hide()
			RQE.db.profile.enableFrame = false
		end)
		CreateTooltip(CloseButton, "Close/Hide Frame")
		CreateBorder(CloseButton)
		if RQE.UI then RQE.UI:StyleIconButton(CloseButton, "Close") end

		return CloseButton
	end

	-------------------------------------------------------
	-- #3h. Manual Previous & Next Step Controls
	-------------------------------------------------------

	-- Creates the Previous Step button for manual step preview navigation.
	function RQE.Buttons.CreatePreviousStepButton(RQEFrame)
		local PrevStepButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		PrevStepButton:SetSize(18, 18)
		PrevStepButton:SetText("<")
		RQE.PrevStepButton = PrevStepButton

		PrevStepButton:SetFrameStrata("MEDIUM")
		PrevStepButton:SetFrameLevel(3)
		PrevStepButton:SetPoint("TOPRIGHT", RQE.NextStepButton, "TOPLEFT", -3, 0)

		PrevStepButton:SetScript("OnEnter", function(self)
			if isRetail then
				if RQE.db.profile.enableStepControls then
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep - 1

					if targetStep >= 1 then
						GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
						GameTooltip:SetText("Go back to step " .. targetStep)
						GameTooltip:Show()
					end
				end
			else
				local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
				if RQE:CanUseStepControlsForQuest(questID) then
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep - 1

					if targetStep >= 0 and (targetStep >= 1 or RQE:CanNavigateSearchedQuestSteps(questID)) then
						GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
						GameTooltip:SetText("Go back to step " .. targetStep)
						GameTooltip:Show()
					end
				end
			end
		end)

		PrevStepButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		PrevStepButton:SetScript("OnClick", function()
			if isRetail then
				if RQE.db.profile.enableStepControls then
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep - 1

					if targetStep >= 1 then
						RQE:SetDisplayedStepFromStepsList(targetStep)

						C_Timer.After(0.2, function()
							local questID = RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
							if questID then
								RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
							end
						end)
					end
				end
			else
				local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
				if RQE:CanUseStepControlsForQuest(questID) then
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep - 1

					if targetStep >= 0 and (targetStep >= 1 or RQE:CanNavigateSearchedQuestSteps(questID)) then
						RQE:SetDisplayedStepFromStepsList(targetStep)

						C_Timer.After(0.2, function()
							local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
							if questID then
								if RQE:CanNavigateSearchedQuestSteps(questID) then
									RQE:CreateSearchedQuestStepWaypoint(questID, targetStep)
								else
									RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
								end
							end
						end)
					end
				end
			end
		end)

		CreateBorder(PrevStepButton)
		if RQE.UI then RQE.UI:StyleIconButton(PrevStepButton, "PreviousStep") end
		return PrevStepButton
	end

	-- Creates the Next Step button for manual step preview navigation.
	function RQE.Buttons.CreateNextStepButton(RQEFrame)
		local NextStepButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		NextStepButton:SetSize(18, 18)
		NextStepButton:SetText(">")
		RQE.NextStepButton = NextStepButton

		NextStepButton:SetFrameStrata("MEDIUM")
		NextStepButton:SetFrameLevel(3)
		NextStepButton:SetPoint("TOPRIGHT", RQE.CloseButton, "TOPLEFT", -3, 0)

		NextStepButton:SetScript("OnEnter", function(self)
			if isRetail then
				if RQE.db.profile.enableStepControls then
					local questID = RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
					local questData = questID and RQE.getQuestData(questID)
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep + 1

					if questData and questData[targetStep] then
						GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
						GameTooltip:SetText("Advance to step " .. targetStep)
						GameTooltip:Show()
					end
				else
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
					GameTooltip:SetText("Enable stepIndex control from 'Frame' in addon settings")
					GameTooltip:Show()
				end
			else
				local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
				if RQE:CanUseStepControlsForQuest(questID) then
					local questData = questID and RQE.getQuestData(questID)
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep + 1

					if questData and questData[targetStep] then
						GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
						GameTooltip:SetText("Advance to step " .. targetStep)
						GameTooltip:Show()
					end
				end
			end
		end)

		NextStepButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		NextStepButton:SetScript("OnClick", function()
			if isRetail then
				if RQE.db.profile.enableStepControls then
					local questID = RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
					local questData = questID and RQE.getQuestData(questID)
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep + 1

					if questData and questData[targetStep] then
						RQE:SetDisplayedStepFromStepsList(targetStep)

						C_Timer.After(0.2, function()
							local questID = RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
							if questID then
								RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
							end
						end)
					end
				end
			else
				local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
				if RQE:CanUseStepControlsForQuest(questID) then
					local questData = questID and RQE.getQuestData(questID)
					local curStep = RQE:GetDisplayedStepIndex()
					local targetStep = curStep + 1

					if questData and questData[targetStep] then
						RQE:SetDisplayedStepFromStepsList(targetStep)

						C_Timer.After(0.2, function()
							local questID = RQE.searchedQuestID or RQE.DisplayedQuestID or RQE.API.GetSuperTrackedQuestID()
							if questID then
								if RQE:CanNavigateSearchedQuestSteps(questID) then
									RQE:CreateSearchedQuestStepWaypoint(questID, targetStep)
								else
									RQE:CreateUnknownQuestWaypoint(questID, RQE.mapID)
								end
							end
						end)
					end
				end
			end
		end)

		CreateBorder(NextStepButton)
		if RQE.UI then RQE.UI:StyleIconButton(NextStepButton, "NextStep") end
		return NextStepButton
	end

	-------------------------------------------------------
	-- #3i. Contextual Waypoint Header Controls
	-------------------------------------------------------

	-- Creates the combat-safe, contextual waypoint navigator in the RQEFrame header.
	-- These are ordinary addon buttons: they do not inherit protected action state
	-- and can select coordblock/coordOrder entries during combat.
	function RQE.Buttons.CreateHeaderWaypointControls(RQEFrame)
		local BackButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		BackButton:SetSize(18, 18)
		BackButton:SetText("<<")
		BackButton:SetFrameStrata("MEDIUM")
		BackButton:SetFrameLevel(3)
		RQE.HeaderWaypointBackButton = BackButton

		local Status = CreateFrame("Frame", nil, RQEFrame)
		Status:SetSize(48, 18)
		Status:SetFrameStrata("MEDIUM")
		Status:SetFrameLevel(3)
		local StatusText = Status:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		StatusText:SetPoint("CENTER", Status, "CENTER", 0, 0)
		StatusText:SetTextColor(239/255, 191/255, 90/255)
		RQE.HeaderWaypointStatus = Status
		RQE.HeaderWaypointStatusText = StatusText

		local ForwardButton = CreateFrame("Button", nil, RQEFrame, "UIPanelButtonTemplate")
		ForwardButton:SetSize(18, 18)
		ForwardButton:SetText(">>")
		ForwardButton:SetFrameStrata("MEDIUM")
		ForwardButton:SetFrameLevel(3)
		RQE.HeaderWaypointForwardButton = ForwardButton

		BackButton:SetScript("OnClick", function()
			if RQE.SelectHeaderWaypointByOffset then
				RQE:SelectHeaderWaypointByOffset(-1)
			end
		end)
		ForwardButton:SetScript("OnClick", function()
			if RQE.SelectHeaderWaypointByOffset then
				RQE:SelectHeaderWaypointByOffset(1)
			end
		end)
		BackButton:SetScript("OnEnter", function(self)
			local selection = RQE.GetCurrentHeaderWaypointSelection
				and RQE:GetCurrentHeaderWaypointSelection()
			if not selection then return end
			local target = selection.currentPosition > 0
				and selection.currentPosition - 1 or selection.total
			if target >= 1 then
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:SetText("Go back to waypoint " .. target)
				GameTooltip:Show()
			end
		end)
		ForwardButton:SetScript("OnEnter", function(self)
			local selection = RQE.GetCurrentHeaderWaypointSelection
				and RQE:GetCurrentHeaderWaypointSelection()
			if not selection then return end
			local target = selection.currentPosition > 0
				and selection.currentPosition + 1 or 1
			if target <= selection.total then
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:SetText("Advance to waypoint " .. target)
				GameTooltip:Show()
			end
		end)
		BackButton:SetScript("OnLeave", HideTooltip)
		ForwardButton:SetScript("OnLeave", HideTooltip)

		CreateBorder(BackButton)
		CreateBorder(ForwardButton)
		if RQE.UI then
			RQE.UI:StyleIconButton(BackButton, "PreviousWaypoint")
			RQE.UI:StyleIconButton(ForwardButton, "NextWaypoint")
		end
		BackButton:Hide()
		Status:Hide()
		ForwardButton:Hide()
		return BackButton, Status, ForwardButton
	end

	-- Updates visibility, enabled state, and anchoring for both header navigation
	-- groups. Waypoint controls close the gap left by hidden step controls.
	function RQE.Buttons.UpdateHeaderNavigation()
		local closeButton = RQE.CloseButton
		local prevButton = RQE.PrevStepButton
		local nextButton = RQE.NextStepButton
		if not closeButton or not prevButton or not nextButton then return end

		local stepControlsVisible = RQE.db and RQE.db.profile
			and RQE.db.profile.enableStepControls == true
		if stepControlsVisible then
			nextButton:ClearAllPoints()
			nextButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -3, 0)
			prevButton:ClearAllPoints()
			prevButton:SetPoint("TOPRIGHT", nextButton, "TOPLEFT", -3, 0)
			nextButton:Show()
			prevButton:Show()
			local canGoBack, canGoForward = GetStepNavigationAvailability()
			if canGoBack then prevButton:Enable()
			else prevButton:Disable() end
			if canGoForward then nextButton:Enable()
			else nextButton:Disable() end
		else
			nextButton:Hide()
			prevButton:Hide()
		end

		local BackButton = RQE.HeaderWaypointBackButton
		local Status = RQE.HeaderWaypointStatus
		local StatusText = RQE.HeaderWaypointStatusText
		local ForwardButton = RQE.HeaderWaypointForwardButton
		if not (BackButton and Status and StatusText and ForwardButton) then return end

		local selection = RQE.GetCurrentHeaderWaypointSelection
			and RQE:GetCurrentHeaderWaypointSelection()
		local showWaypoints = selection and selection.total and selection.total > 0
		if showWaypoints then
			local rightAnchor = stepControlsVisible and prevButton or closeButton
			ForwardButton:ClearAllPoints()
			ForwardButton:SetPoint("TOPRIGHT", rightAnchor, "TOPLEFT", -3, 0)
			Status:ClearAllPoints()
			Status:SetPoint("TOPRIGHT", ForwardButton, "TOPLEFT", -1, 0)
			BackButton:ClearAllPoints()
			BackButton:SetPoint("TOPRIGHT", Status, "TOPLEFT", -1, 0)

			StatusText:SetText(string.format("WP %d/%d",
				selection.currentPosition or 0, selection.total))
			local current = selection.currentPosition or 0
			if current == 0 or current > 1 then BackButton:Enable()
			else BackButton:Disable() end
			if current == 0 or current < selection.total then ForwardButton:Enable()
			else ForwardButton:Disable() end
			BackButton:Show()
			Status:Show()
			ForwardButton:Show()
		else
			BackButton:Hide()
			Status:Hide()
			ForwardButton:Hide()
		end

		-- Center the title inside the space that remains between the left utility
		-- buttons and whichever navigation group currently begins on the right.
		if RQE.headerText and RQE.RQEFrameHeader then
			local leftAnchor = RQE.ContributeButton or RQE.SearchButton or RQE.RQEFrameHeader
			local rightAnchor
			if showWaypoints then
				rightAnchor = BackButton
			elseif stepControlsVisible then
				rightAnchor = prevButton
			else
				rightAnchor = closeButton
			end

			RQE.headerText:ClearAllPoints()
			RQE.headerText:SetWordWrap(false)
			RQE.headerText:SetJustifyH("CENTER")
			RQE.headerText:SetPoint("LEFT", leftAnchor, "RIGHT", 8, 0)
			RQE.headerText:SetPoint("RIGHT", rightAnchor, "LEFT", -8, 0)
		end
	end


--------------------------------------------------
-- #4. 📜 Quest Tracker Header & Filter Menus
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Tracker Filter Shortcut Buttons
	-------------------------------------------------------

	-- Parent function to create the Show All button.
	function RQE.Buttons.CQButton(RQEQuestFrame)
		local CQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		CQButton:SetSize(18, 18)
		CQButton:SetText("SA")
		RQE.CQButton = CQButton  -- Store reference for later use

		-- Set the frame strata and level
		CQButton:SetFrameStrata("MEDIUM")
		CQButton:SetFrameLevel(3)

		-- Nested functions
		CQButton:SetPoint("TOPLEFT", RQEQuestFrame, "TOPLEFT", 6, -6)  -- Anchoring
		CQButton:SetScript("OnClick", function()
			RQE.filterAllTrackedQuests()
			RQE.QuestScrollFrameToTop(true)
		end)

		CreateTooltip(CQButton, "Show All Quests \n in RQE Quest Tracker")  -- Tooltip
		CreateBorder(CQButton)  -- Border
		if RQE.UI then RQE.UI:StyleIconButton(CQButton, "ShowAll") end

		return CQButton
	end

	-- Parent function to create the Show Completed button.
	function RQE.Buttons.SCButton(RQEQuestFrame)
		local SCButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		SCButton:SetSize(18, 18)
		SCButton:SetText("SC")
		RQE.SCButton = SCButton  -- Store reference for later use

		-- Set the frame strata and level
		SCButton:SetFrameStrata("MEDIUM")
		SCButton:SetFrameLevel(3)

		SCButton:SetPoint("TOPLEFT", RQE.CQButton, "TOPRIGHT", 4, 0)  -- Anchoring
		SCButton:SetScript("OnClick", function()
			if isRetail then
				RQE.filterCompleteQuests()
			else
				RQE.filterAllCompleteQuests()
			end
			RQE.QuestScrollFrameToTop(true)
		end)

		if isRetail then
			CreateTooltip(SCButton, "Show Completed Quests \n in Quest Log")
		else
			CreateTooltip(SCButton, "Show All Completed Quests")
		end
		CreateBorder(SCButton)  -- Border
		if RQE.UI then RQE.UI:StyleIconButton(SCButton, "Completed") end

		return SCButton
	end

	-- Parent function to Create HQButton
	function RQE.Buttons.HQButton(RQEQuestFrame)
		local HQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		HQButton:SetSize(18, 18)
		HQButton:SetText("HC")
		RQE.HQButton = HQButton  -- Store reference for later use

		-- Set the frame strata and level
		HQButton:SetFrameStrata("MEDIUM")
		HQButton:SetFrameLevel(3)

		-- Nested functions
		HQButton:SetPoint("TOPLEFT", RQE.SCButton, "TOPRIGHT", 4, 0) 
		HQButton:SetScript("OnClick", function()
			RQE:HideCompletedWatchedQuests()
			-- RQE.QuestScrollFrameToTop()
			RQE.QuestScrollFrameToTop(true)
		end)

		CreateTooltip(HQButton, "Hide watched Completed Quests")  -- Tooltip
		CreateBorder(HQButton)  -- Border
		if RQE.UI then RQE.UI:StyleIconButton(HQButton, "HideCompleted") end

		return HQButton
	end

	-- Parent function to Create ZQButton
	function RQE.Buttons.ZQButton(RQEQuestFrame)
		local ZQButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		ZQButton:SetSize(18, 18)
		ZQButton:SetText("ZQ")
		RQE.ZQButton = ZQButton  -- Store reference for later use

		-- Set the frame strata and level
		ZQButton:SetFrameStrata("MEDIUM")
		ZQButton:SetFrameLevel(3)

		-- Nested functions
		ZQButton:SetPoint("TOPLEFT", RQE.HQButton, "TOPRIGHT", 4, 0) 
		ZQButton:SetScript("OnClick", function()
			if isRetail then
				RQE.DisplayCurrentZoneQuests()
			else
				RQE.DisplayCurrentZoneQuests(true)
			end
			-- RQE.QuestScrollFrameToTop()
			RQE.QuestScrollFrameToTop(true)
		end)

		CreateTooltip(ZQButton, "Show zone quests")  -- Tooltip
		CreateBorder(ZQButton)  -- Border
		if RQE.UI then RQE.UI:StyleIconButton(ZQButton, "Zone") end

		return ZQButton
	end

	-------------------------------------------------------
	-- #4b. Tracker Header Layout & Window Controls
	-------------------------------------------------------

	-- Centers the Quest Tracker title inside the usable span between the left and
	-- right header-button clusters instead of across the entire frame width.
	function RQE.Buttons.UpdateQuestTrackerHeaderTitle()
		local title = RQE.QuestTrackerHeaderText
		local leftAnchor = RQE.ZQButton
		local rightAnchor = RQE.QTQuestFilterButton
		if not title or not leftAnchor or not rightAnchor then return end

		title:ClearAllPoints()
		title:SetWordWrap(false)
		title:SetJustifyH("CENTER")
		title:SetPoint("LEFT", leftAnchor, "RIGHT", 8, 0)
		title:SetPoint("RIGHT", rightAnchor, "LEFT", -8, 0)
	end


	-- Parent function to create QTCloseButton for RQEQuestFrame
	function RQE.Buttons.CreateQuestCloseButton(RQEQuestFrame)
		local QTCloseButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelCloseButton")
		QTCloseButton:SetSize(18, 18)
		RQE.QTQuestCloseButton = QTCloseButton  -- Storing the reference in the RQE table

		-- Set the frame strata and level
		QTCloseButton:SetFrameStrata("MEDIUM")
		QTCloseButton:SetFrameLevel(3)

		QTCloseButton:SetPoint("TOPRIGHT", RQEQuestFrame, "TOPRIGHT", -6, -6)
		QTCloseButton:SetScript("OnClick", function(self, button)
			RQE.isRQEQuestFrameManuallyClosed = true -- Marking the frame as manually closed
			RQEQuestFrame:Hide()
			RQE.db.profile.enableQuestFrame = false
		end)
		CreateTooltip(QTCloseButton, "Close/Hide Quest Tracker")
		CreateBorder(QTCloseButton)
		if RQE.UI then RQE.UI:StyleIconButton(QTCloseButton, "Close") end

		return QTCloseButton
	end

	-- Parent function to Create QTMaximizeButton for RQEQuestFrame
	function RQE.Buttons.CreateQuestMaximizeButton(RQEQuestFrame, originalWidth, originalHeight, content, ScrollFrame, slider)
		local QTMaximizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		QTMaximizeButton:SetSize(18, 18)
		QTMaximizeButton:SetText("+")
		RQE.QTQuestMaximizeButton = QTMaximizeButton  -- Store the reference in the RQE table

		-- Set the frame strata and level
		QTMaximizeButton:SetFrameStrata("MEDIUM")
		QTMaximizeButton:SetFrameLevel(3)

		QTMaximizeButton:SetPoint("TOPRIGHT", RQE.QTQuestCloseButton, "TOPLEFT", -3, 0)
		QTMaximizeButton:SetScript("OnClick", function()
			RQE.db.profile.enableQuestFrame = true
			RQE.isRQEQuestFrameManuallyClosed = false
			RQE.QTMinimized = false

			local profileSize = RQE.db.profile.QuestFramePosition or {}
			local _, _, _, defaultWidth, defaultHeight = RQE:GetFrameGeometry("RQEQuestFrame", true)
			local restoredWidth = RQE.QToriginalWidth
				or profileSize.frameWidth or RQEQuestFrame:GetWidth() or defaultWidth
			local restoredHeight = RQE.QToriginalHeight
				or (profileSize.frameHeight and profileSize.frameHeight > 30
					and profileSize.frameHeight) or defaultHeight
			RQEQuestFrame:SetSize(restoredWidth, restoredHeight)

			if RQE.QTScrollFrame then RQE.QTScrollFrame:Show() end
			if RQE.QuestTrackerSearchRow then RQE.QuestTrackerSearchRow:Show() end
			if RQE.QMQTslider then
				if RQE.QTSliderWasShown then RQE.QMQTslider:Show()
				else RQE.QMQTslider:Hide() end
			end
			RQE.QTSliderWasShown = nil
			if RQE.QMQTResizeButton then RQE.QMQTResizeButton:Show() end
			QTMaximizeButton:Hide()
			if RQE.QTQuestMinimizeButton then RQE.QTQuestMinimizeButton:Show() end
			RQEQuestFrame:Show()
		end)
		CreateTooltip(QTMaximizeButton, "Maximize Quest Tracker")
		CreateBorder(QTMaximizeButton)
		if RQE.UI then RQE.UI:StyleIconButton(QTMaximizeButton, "Collapse") end
		QTMaximizeButton:Hide()

		return QTMaximizeButton
	end

	-- Parent function to Create QTMinimizeButton for RQEQuestFrame
	function RQE.Buttons.CreateQuestMinimizeButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
		local QTMinimizeButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		QTMinimizeButton:SetSize(18, 18)
		QTMinimizeButton:SetText("-")
		RQE.QTQuestMinimizeButton = QTMinimizeButton  -- Store the reference in the RQE table

		-- Set the frame strata and level
		QTMinimizeButton:SetFrameStrata("MEDIUM")
		QTMinimizeButton:SetFrameLevel(3)

		QTMinimizeButton:SetPoint("TOPRIGHT", RQE.QTQuestCloseButton, "TOPLEFT", -3, 0)
		QTMinimizeButton:SetScript("OnClick", function()
			RQE.QToriginalWidth, RQE.QToriginalHeight = RQEQuestFrame:GetWidth(), RQEQuestFrame:GetHeight()

			-- Set the state before resizing so the compact height is not saved as
			-- the player's normal Quest Tracker height.
			RQE.QTMinimized = true

			-- Preserve the full frame width so both header states line up exactly.
			local collapsedHeight = (RQE.UI and RQE.UI:IsEnabled()) and 48 or 30
			RQEQuestFrame:SetHeight(collapsedHeight)

			-- Hide the ScrollFrame if they exist
			if RQE.QTScrollFrame then
				RQE.QTScrollFrame:Hide()
			end
			if RQE.QuestTrackerSearchRow then
				RQE.QuestTrackerSearchRow:Hide()
			end

			-- Hide the Slider if they exist
			if RQE.QMQTslider then
				RQE.QTSliderWasShown = RQE.QMQTslider:IsShown()
				RQE.QMQTslider:Hide()
			end

			-- Hide the resize button
			if RQE.QMQTResizeButton then
				RQE.QMQTResizeButton:Hide()
			end

			QTMinimizeButton:Hide()
			if RQE.QTQuestMaximizeButton then RQE.QTQuestMaximizeButton:Show() end
		end)
		CreateTooltip(QTMinimizeButton, "Minimize Quest Tracker")
		CreateBorder(QTMinimizeButton)
		if RQE.UI then RQE.UI:StyleIconButton(QTMinimizeButton, "Expand") end

		return QTMinimizeButton
	end

	-------------------------------------------------------
	-- #4c. Filter Menu Mixins & Label Layout
	-------------------------------------------------------

	-- Custom Mixin for Quest Filter Menu Buttons
	RQE_QuestButtonMixin = {}


	-- Function to apply the shared visual states used by quest filter menu buttons
	function RQE_QuestButtonMixin:OnLoad()
		self:SetNormalFontObject("GameFontHighlightSmall")
		self:SetHighlightFontObject("GameFontHighlightSmall")

		local normalTexture = self:CreateTexture(nil, "BACKGROUND")
		normalTexture:SetColorTexture(0.1, 0.1, 0.1, 0.9)
		normalTexture:SetAllPoints(self)
		self:SetNormalTexture(normalTexture)

		local highlightTexture = self:CreateTexture(nil, "BACKGROUND")
		highlightTexture:SetColorTexture(0.2, 0.2, 0.2, 1)
		highlightTexture:SetAllPoints(self)
		self:SetHighlightTexture(highlightTexture)

		local pushedTexture = self:CreateTexture(nil, "BACKGROUND")
		pushedTexture:SetColorTexture(0.05, 0.05, 0.05, 0.8)
		pushedTexture:SetAllPoints(self)
		self:SetPushedTexture(pushedTexture)
		if RQE.UI then RQE.UI:StyleTextButton(self) end
	end

	-- Placeholder function available for quest menu buttons without a specialized click handler
	function RQE_QuestButtonMixin:OnClick()
		-- Placeholder for button click handling
	end

	-- Custom Mixin for Quest Filter Menu
	RQE_QuestMenuMixin = {}

	-- Function to initialize a quest filter menu's button collection and backdrop styling
	function RQE_QuestMenuMixin:OnLoad()
		self.buttons = {}
		self:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		self:SetBackdropColor(0, 0, 0, 0.8)
		if RQE.UI then RQE.UI:StylePanel(self, 0.94, "menu") end
	end

	-- Function to remove the final complete UTF-8 character without splitting a multibyte sequence
	local function TrimLastUTF8Character(text)
		local lastByte = #text
		while lastByte > 1 do
			local byte = text:byte(lastByte)
			if not byte or byte < 128 or byte >= 192 then break end
			lastByte = lastByte - 1
		end
		return text:sub(1, math.max(0, lastByte - 1))
	end

	-- Function to count visible UTF-8 characters rather than encoded bytes
	local function CountUTF8Characters(text)
		local count = 0
		for index = 1, #text do
			local byte = text:byte(index)
			if byte and (byte < 128 or byte >= 192) then count = count + 1 end
		end
		return count
	end

	-- Function to preserve an inline texture while shortening a themed menu label to its width limit
	local function BuildThemedMenuLabel(fullText)
		local texturePrefix, label = fullText:match("^(|T.-|t%s*)(.*)$")
		texturePrefix = texturePrefix or ""
		label = label or fullText
		local characterCount = CountUTF8Characters(label)
		local maximumLabelCharacters = 27
		local shortened = label
		while characterCount > maximumLabelCharacters do
			shortened = TrimLastUTF8Character(shortened)
			characterCount = characterCount - 1
		end
		local truncated = shortened ~= label
		local suffix = truncated and "....." or ""
		return texturePrefix .. shortened .. suffix,
			characterCount + (truncated and 5 or 0), truncated, texturePrefix ~= ""
	end

	-- Function to recalculate menu dimensions and labels for the active visual theme
	function RQE_QuestMenuMixin:RefreshLayout()
		local themed = RQE.UI and RQE.UI:IsEnabled()
		local rowHeight = themed and 30 or 20
		local rowGap = themed and 4 or 5
		local menuWidth
		local maximumButtonWidth = 0

		if themed then
			-- Each entry follows its own label up to a fixed ceiling. This keeps short
			-- submenu entries compact while preventing long database names from making
			-- a menu excessively wide or drawing through the ornate end caps.
			local menuSideGutter = 10
			local minimumButtonWidth = 210
			local maximumAllowedButtonWidth = 448
			local buttonTextPadding = 64
			local estimatedCharacterWidth = 12
			for _, button in ipairs(self.buttons) do
				local fullText = button.RQEFullMenuText or (button.GetText and button:GetText()) or ""
				local displayText, displayCharacters, truncated, hasInlineTexture = BuildThemedMenuLabel(fullText)
				button:SetText(displayText)
				button.RQEMenuTextTruncated = truncated
				local estimatedTextWidth = (displayCharacters * estimatedCharacterWidth)
					+ (hasInlineTexture and 20 or 0)
				button.RQEThemedMenuWidth = math.min(maximumAllowedButtonWidth,
					math.max(minimumButtonWidth, estimatedTextWidth + buttonTextPadding))
				maximumButtonWidth = math.max(maximumButtonWidth, button.RQEThemedMenuWidth)
			end
			menuWidth = maximumButtonWidth + (menuSideGutter * 2)
		else
			menuWidth = math.max(150, self:GetWidth() or 150)
			maximumButtonWidth = menuWidth - 20
			for _, button in ipairs(self.buttons) do
				button:SetText(button.RQEFullMenuText or (button.GetText and button:GetText()) or "")
				button.RQEMenuTextTruncated = nil
			end
		end

		self:SetWidth(menuWidth)
		for index, button in ipairs(self.buttons) do
			local buttonWidth = themed and button.RQEThemedMenuWidth or maximumButtonWidth
			button:ClearAllPoints()
			button:SetSize(buttonWidth, rowHeight)
			local fontString = button.GetFontString and button:GetFontString()
			if themed and fontString then
				fontString:ClearAllPoints()
				fontString:SetPoint("CENTER", button, "CENTER", 0, 0)
				fontString:SetSize(math.max(1, buttonWidth - 54), rowHeight)
				fontString:SetJustifyH("CENTER")
				fontString:SetJustifyV("MIDDLE")
				if fontString.SetWordWrap then fontString:SetWordWrap(false) end
			end
			if index == 1 then
				button:SetPoint("TOP", self, "TOP", 0, -10)
			else
				button:SetPoint("TOP", self.buttons[index - 1], "BOTTOM", 0, -rowGap)
			end
		end

		local rowsHeight = (#self.buttons * rowHeight) + (math.max(0, #self.buttons - 1) * rowGap)
		self:SetHeight(rowsHeight + 20)
	end

	-------------------------------------------------------
	-- #4d. Filter Menu Button Lifecycle
	-------------------------------------------------------

	-- Updated AddButton function to return the created button
	function RQE_QuestMenuMixin:AddButton(text, onClick, isSubmenu)
		local fullText = text .. (isSubmenu and " >" or "")
		for _, button in ipairs(self.buttons) do
			if (button.RQEFullMenuText or button:GetText()) == fullText then
				return
			end
		end

		local button = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
		Mixin(button, RQE_QuestButtonMixin)
		button:OnLoad()
		button.RQEFullMenuText = fullText
		button:SetText(fullText)
		button:SetScript("OnClick", onClick)
		button:HookScript("OnEnter", function(owner)
			if owner.RQEMenuTextTruncated and GameTooltip then
				local tooltipText = (owner.RQEFullMenuText or ""):gsub("|T.-|t%s*", "")
				GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
				-- Retail 12.1 uses the color-object SetText overload; the text-only
				-- form remains compatible with every supported client.
				GameTooltip:SetText(tooltipText)
				GameTooltip:Show()
			end
		end)
		button:HookScript("OnLeave", function(owner)
			if owner.RQEMenuTextTruncated and GameTooltip then GameTooltip:Hide() end
		end)

		table.insert(self.buttons, button)
		self:RefreshLayout()
	end

	-- Show and Position the Menu
	function RQE_QuestMenuMixin:ShowMenu(anchorFrame, isSubmenu)
		self:ClearAllPoints()

		local screenWidth = GetScreenWidth()
		local screenHeight = GetScreenHeight()
		local anchorX, anchorY = anchorFrame:GetCenter()

		local isTopHalf = anchorY > (screenHeight / 2)
		local isLeftHalf = anchorX < (screenWidth / 2)

		if not isSubmenu and anchorFrame == RQE.QTQuestFilterButton then
			-- Directly anchor the main menu below the filter button, considering screen side
			if isLeftHalf then
				self:SetPoint("TOPLEFT", RQE.QTQuestFilterButton, "BOTTOMLEFT", 0, -5)
			else
				self:SetPoint("TOPRIGHT", RQE.QTQuestFilterButton, "BOTTOMRIGHT", 0, -5)
			end
		elseif isSubmenu then
			-- Adjust the positioning to anchor the submenu to the specific button (anchorFrame)
			if isLeftHalf then
				self:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 10, -60)
			else
				self:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -10, -60)
			end
		else
			-- Fallback positioning for any other cases
			if isLeftHalf then
				self:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, -85)
			else
				self:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -10, -85)
			end
		end

		self:Show()
	end

	-- Function to hide the current quest filter menu
	function RQE_QuestMenuMixin:HideMenu()
		self:Hide()
	end

	-- Function to toggle the quest filter menu relative to its launcher anchor
	function RQE_QuestMenuMixin:ToggleMenu(anchorFrame)
		if self:IsShown() then
			self:HideMenu()
		else
			self:ShowMenu(anchorFrame)
		end
	end

	-------------------------------------------------------
	-- #4e. Quest Filter Launcher & Main Menu
	-------------------------------------------------------

	-- Parent function to Create QTFilterButton for RQEQuestFrame
	function RQE.Buttons.CreateQuestFilterButton(RQEQuestFrame, QToriginalWidth, QToriginalHeight, QTcontent, QTScrollFrame, QTslider)
		local QTFilterButton = CreateFrame("Button", nil, RQEQuestFrame, "UIPanelButtonTemplate")
		QTFilterButton:SetSize(18, 18)
		QTFilterButton:SetText("F")
		RQE.QTQuestFilterButton = QTFilterButton

		-- Minimize and Maximize occupy the same header slot, so anchoring to either
		-- keeps the filter and title placement identical in both states.
		QTFilterButton:SetPoint("TOPRIGHT", RQE.QTQuestMaximizeButton, "TOPLEFT", -3, 0)
		QTFilterButton:SetFrameStrata("MEDIUM")
		QTFilterButton:SetFrameLevel(3)

		-- Attach Dropdown Menu to Filter Button Click
		QTFilterButton:SetScript("OnClick", function(self, button, down)
			RQE.ScanQuestTypes()
			RQE:ShowQuestFilterMenu()
		end)

		CreateTooltip(QTFilterButton, "Filter Quests")
		CreateBorder(QTFilterButton)
		if RQE.UI then RQE.UI:StyleIconButton(QTFilterButton, "Filter") end

		return QTFilterButton
	end

	-- Function to close every quest-filter submenu owned by the supplied menu controller
	local function HideQuestFilterSubMenus(owner)
		for _, menuKey in ipairs({ "CampaignSubMenu", "QuestTypeSubMenu", "ZoneQuestSubMenu", "QuestLineSubMenu" }) do
			local menu = owner[menuKey]
			if menu then menu:Hide() end
		end
	end

	-- Create the Dropdown Menu
	function RQE:ShowQuestFilterMenu()
		if not self.QuestFilterDropDownMenu then
			self.QuestFilterDropDownMenu = CreateFrame("Frame", "RQEQuestFilterDropDownMenu", UIParent, "BackdropTemplate")
			Mixin(self.QuestFilterDropDownMenu, RQE_QuestMenuMixin)
			self.QuestFilterDropDownMenu:OnLoad()
			self.QuestFilterDropDownMenu:SetSize(150, 200)
			self.QuestFilterDropDownMenu:SetFrameStrata("DIALOG")
			self.QuestFilterDropDownMenu:Hide()

			-- Initialize the buttons table
			self.QuestFilterDropDownMenu.buttons = {}

			self.QuestFilterDropDownMenu:SetScript("OnEnter", function(self)
				self:Show()
			end)
			self.QuestFilterDropDownMenu:SetScript("OnLeave", function(self)
				C_Timer.After(0.1, function()
					local isMouseOverMenu
					local isMouseOverButton
					if isRetail then
						isMouseOverMenu = self:IsMouseOver()
						isMouseOverButton = RQE.QTQuestFilterButton:IsMouseOver()
					else
						isMouseOverMenu = MouseIsOver(self)
						isMouseOverButton = MouseIsOver(RQE.QTQuestFilterButton)
					end
					if not isMouseOverMenu and not isMouseOverButton then
						self:Hide()
					end
				end)
			end)
		end

		-- Ensure buttons are only added once
		if not self.QuestFilterDropDownMenu.buttons or #self.QuestFilterDropDownMenu.buttons == 0 then
			-- First, ensure all necessary data is up-to-date
			RQE.ScanQuestTypes()
			RQE.ScanAndCacheZoneQuests()
			RQE.ScanAndCacheCampaigns()

			-- Build the sorted menu lists
			local questTypeMenuList = RQE.BuildQuestTypeMenuList()
			local zoneQuestMenuList = RQE.BuildZoneQuestMenuList()
			local campaignMenuList = RQE.BuildCampaignMenuList()
			local questLineMenuList = RQE.BuildQuestLineMenuList()

			-- Add Buttons for Main Menu Items
			self.QuestFilterDropDownMenu:AddButton("Auto-Track Zone Quests", function(button)
				-- Toggle the autoTrackZoneQuests option
				if isRetail then
					RQE.db.profile.autoTrackZoneQuests = not RQE.db.profile.autoTrackZoneQuests
				else
					RQE:SetAutoTrackZoneQuestsEnabled(not RQE.db.profile.autoTrackZoneQuests)
				end

				-- Update the button text to reflect the new state
				if RQE.db.profile.autoTrackZoneQuests then
					button.RQEFullMenuText = "|TInterface\\Buttons\\UI-CheckBox-Check:20|t Auto-Track Zone Quests"
					button:SetText(button.RQEFullMenuText)
					if isRetail then
						RQE.DisplayCurrentZoneQuests()
					end
				else
					button.RQEFullMenuText = "Auto-Track Zone Quests"
					button:SetText(button.RQEFullMenuText)
				end
				local menu = button:GetParent()
				if menu and menu.RefreshLayout then menu:RefreshLayout() end
			end)

			-- Initial state setup for the button
			if RQE.db.profile.autoTrackZoneQuests then
				local autoTrackButton = self.QuestFilterDropDownMenu.buttons[#self.QuestFilterDropDownMenu.buttons]
				autoTrackButton.RQEFullMenuText = "|TInterface\\Buttons\\UI-CheckBox-Check:20|t Auto-Track Zone Quests"
				autoTrackButton:SetText(autoTrackButton.RQEFullMenuText)
				self.QuestFilterDropDownMenu:RefreshLayout()
			end

			self.QuestFilterDropDownMenu:AddButton("Completed Quests", function()
				if isRetail then
					RQE.filterCompleteQuests()
				else
					RQE.filterAllTrackedQuests()
				end
				if RQE.QTScrollFrame and RQE.QMQTslider then
					RQE.QTScrollFrame:SetVerticalScroll(0)
					RQE.QMQTslider:SetValue(0)
				end
			end)

			self.QuestFilterDropDownMenu:AddButton("Daily / Weekly Quests", function()
				RQE.filterDailyWeeklyQuests()
				if RQE.QTScrollFrame and RQE.QMQTslider then
					RQE.QTScrollFrame:SetVerticalScroll(0)
					RQE.QMQTslider:SetValue(0)
				end
			end)

			-- Add Submenus
			self.QuestFilterDropDownMenu:AddButton("Campaign Quests", function()
				-- Hide any other open submenu
				if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
				if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end
				if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end

				self.CampaignSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
			end, true)
			self:CreateCampaignSubMenu()

			self.QuestFilterDropDownMenu:AddButton("Quest Type", function()
				-- Hide any other open submenu
				if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
				if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end
				if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end

				self.QuestTypeSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
			end, true)
			self:CreateQuestTypeSubMenu()

			self.QuestFilterDropDownMenu:AddButton("Zone Quests", function()
				-- Hide any other open submenu
				if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
				if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
				if self.QuestLineSubMenu then self.QuestLineSubMenu:Hide() end

				self.ZoneQuestSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
			end, true)
			self:CreateZoneQuestSubMenu()

			self.QuestFilterDropDownMenu:AddButton("Quest Line", function()
				-- Hide any other open submenu
				if self.CampaignSubMenu then self.CampaignSubMenu:Hide() end
				if self.QuestTypeSubMenu then self.QuestTypeSubMenu:Hide() end
				if self.ZoneQuestSubMenu then self.ZoneQuestSubMenu:Hide() end

				self.QuestLineSubMenu:ToggleMenu(self.QuestFilterDropDownMenu, true)
			end, true)
			self:CreateQuestLineSubMenu()
		end

		-- Closing the filter from its header button closes the complete menu tree,
		-- not only the first tier. Also clear stale submenus before a fresh open.
		if self.QuestFilterDropDownMenu:IsShown() then
			HideQuestFilterSubMenus(self)
			self.QuestFilterDropDownMenu:HideMenu()
		else
			HideQuestFilterSubMenus(self)
			self.QuestFilterDropDownMenu:ShowMenu(self.QTQuestFilterButton)
		end
	end

	-------------------------------------------------------
	-- #4f. Campaign, Type, Zone & Quest-Line Submenus
	-------------------------------------------------------

	-- Create the Campaign Quests Submenu
	function RQE:CreateCampaignSubMenu()
		if not self.CampaignSubMenu then
			self.CampaignSubMenu = CreateFrame("Frame", "RQECampaignSubMenu", UIParent, "BackdropTemplate")
			Mixin(self.CampaignSubMenu, RQE_QuestMenuMixin)
			self.CampaignSubMenu:OnLoad()
			self.CampaignSubMenu:SetSize(150, 200)
			self.CampaignSubMenu:SetFrameStrata("DIALOG")
			self.CampaignSubMenu:Hide()

			-- Keep submenu visible when mouse is over it
			self.CampaignSubMenu:SetScript("OnEnter", function(self)
				self:Show()
			end)

			-- Example for one of the submenus, apply similar logic to others
			self.CampaignSubMenu:SetScript("OnLeave", function(self)
				C_Timer.After(0.1, function()
					local isMouseOverSubMenu
					local isMouseOverParent
					if isRetail then
						isMouseOverSubMenu = self:IsMouseOver()
						isMouseOverParent = self:GetParent():IsMouseOver()
					else
						isMouseOverSubMenu = MouseIsOver(self)
						isMouseOverParent = MouseIsOver(self:GetParent())
					end
					if not isMouseOverSubMenu and not isMouseOverParent then
						self:Hide()
						self:GetParent():Hide() -- Hide the main menu if mouse leaves both
					end
				end)
			end)

			-- Add buttons to the submenu
			for _, item in ipairs(RQE.BuildCampaignMenuList()) do
				self.CampaignSubMenu:AddButton(item.text, item.func)
			end
		end
	end

	-- Create the Quest Type Submenu
	function RQE:CreateQuestTypeSubMenu()
		if not self.QuestTypeSubMenu then
			self.QuestTypeSubMenu = CreateFrame("Frame", "RQEQuestTypeSubMenu", UIParent, "BackdropTemplate")
			Mixin(self.QuestTypeSubMenu, RQE_QuestMenuMixin)
			self.QuestTypeSubMenu:OnLoad()
			self.QuestTypeSubMenu:SetSize(150, 200)
			self.QuestTypeSubMenu:SetFrameStrata("DIALOG")
			self.QuestTypeSubMenu:Hide()

			-- Keep submenu visible when mouse is over it
			self.QuestTypeSubMenu:SetScript("OnEnter", function(self)
				self:Show()
			end)
			self.QuestTypeSubMenu:SetScript("OnLeave", function(self)
				C_Timer.After(0.1, function()
					local isMouseOver
					if isRetail then
						isMouseOver = self:IsMouseOver()
					else
						isMouseOver = MouseIsOver(self)
					end
					if not isMouseOver then
						self:Hide()
					end
				end)
			end)

			-- Add buttons to the submenu
			for _, item in ipairs(RQE.BuildQuestTypeMenuList()) do
				self.QuestTypeSubMenu:AddButton(item.text, item.func)
			end
		end
	end

	-- Create the Zone Quests Submenu
	function RQE:CreateZoneQuestSubMenu()
		if not self.ZoneQuestSubMenu then
			self.ZoneQuestSubMenu = CreateFrame("Frame", "RQEZoneQuestSubMenu", UIParent, "BackdropTemplate")
			Mixin(self.ZoneQuestSubMenu, RQE_QuestMenuMixin)
			self.ZoneQuestSubMenu:OnLoad()
			self.ZoneQuestSubMenu:SetSize(150, 200)
			self.ZoneQuestSubMenu:SetFrameStrata("DIALOG")
			self.ZoneQuestSubMenu:Hide()

			-- Keep submenu visible when mouse is over it
			self.ZoneQuestSubMenu:SetScript("OnEnter", function(self)
				self:Show()
			end)
			self.ZoneQuestSubMenu:SetScript("OnLeave", function(self)
				C_Timer.After(0.1, function()
					local isMouseOver
					if isRetail then
						isMouseOver = self:IsMouseOver()
					else
						isMouseOver = MouseIsOver(self)
					end
					if not isMouseOver then
						self:Hide()
					end
				end)
			end)

			-- Add buttons to the submenu
			for _, item in ipairs(RQE.BuildZoneQuestMenuList()) do
				self.ZoneQuestSubMenu:AddButton(item.text, item.func)
			end
		end
	end

	-- Create the Quest Line Submenu
	function RQE:CreateQuestLineSubMenu()
		if not self.QuestLineSubMenu then
			self.QuestLineSubMenu = CreateFrame("Frame", "RQEQuestLineSubMenu", UIParent, "BackdropTemplate")
			Mixin(self.QuestLineSubMenu, RQE_QuestMenuMixin)
			self.QuestLineSubMenu:OnLoad()
			self.QuestLineSubMenu:SetSize(150, 200)
			self.QuestLineSubMenu:SetFrameStrata("DIALOG")
			self.QuestLineSubMenu:Hide()

			-- Keep submenu visible when mouse is over it
			self.QuestLineSubMenu:SetScript("OnEnter", function(self)
				self:Show()
			end)
			self.QuestLineSubMenu:SetScript("OnLeave", function(self)
				C_Timer.After(0.1, function()
					local isMouseOver
					if isRetail then
						isMouseOver = self:IsMouseOver()
					else
						isMouseOver = MouseIsOver(self)
					end
					if not isMouseOver then
						self:Hide()
					end
				end)
			end)

			-- Add buttons to the submenu
			for _, item in ipairs(RQE.BuildQuestLineMenuList()) do
				self.QuestLineSubMenu:AddButton(item.text, item.func)
			end
		end
	end


--------------------------------------------------
-- #5. 🎒 Secure Quest Item Buttons
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Constants, Pool & Shared State
	-------------------------------------------------------

	-- Active implementation ----------------------------------------------------
	-- Retail exposes tracked quest items directly. Classic Era/SoD and TBC may
	-- not, so those clients also use Questie's sourceItemId data when Questie is
	-- available. The resulting buttons all use secure item attributes and never
	-- consume a character or account macro slot.
	-- This first phase handles quest items only. Spell and ExtraActionButton1
	-- actions require a separate secure-action extension.
	local QUEST_ITEM_BUTTON_SIZE = 32
	local QUEST_ITEM_BUTTON_SPACING = 4
	local QUEST_ITEM_BUTTON_FALLBACK_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"

	-- Keep buttons by quest ID while displayed, then return unused buttons to a
	-- pool. The flags prevent duplicate hooks and combine repeated refresh calls.
	RQE.SpecialQuestItemButtons = RQE.SpecialQuestItemButtons or {
		activeByQuestID = {},
		buttonPool = {},
		allButtons = {},
		actionsPending = false,
		updateScheduled = false,
		hookInstalled = false,
		frameHooksInstalled = false,
	}

	local questItemButtonState = RQE.SpecialQuestItemButtons
	local legacyQuestieDB

	-------------------------------------------------------
	-- #5b. Combat, Quest Log & Inventory Compatibility
	-------------------------------------------------------

	-- Check combat before creating, hiding, moving, or assigning attributes on a
	-- SecureActionButtonTemplate. Visual cooldown and usability updates may run
	-- during combat; protected button changes wait for PLAYER_REGEN_ENABLED.
	local function QuestItemButtonsInCombat()
		return type(InCombatLockdown) == "function" and InCombatLockdown()
	end

	-- Native special-item functions take a quest-log index, not a quest ID. Use
	-- RQE_API.lua's normalized lookup: it selects Retail's native index API and
	-- scans the legacy quest log when SoD/TBC do not expose the same function.
	local function GetRQEQuestLogIndex(questID)
		if not RQE.API or type(RQE.API.GetLogIndexForQuestID) ~= "function" then return nil end
		local questLogIndex = tonumber(RQE.API.GetLogIndexForQuestID(questID))
		return questLogIndex and questLogIndex > 0 and questLogIndex or nil
	end

	-- Questie is optional and only consulted on Classic/SoD and TBC. Cache a
	-- successful import, but retry a missing module in case Questie starts later.
	local function GetQuestieDatabase()
		if isRetail then return nil end
		if legacyQuestieDB then return legacyQuestieDB end

		if QuestieLoader and type(QuestieLoader.ImportModule) == "function" then
			local ok, module = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
			if ok and module then
				legacyQuestieDB = module
			end
		end

		return legacyQuestieDB
	end

	-- Normalize modern C_Container results and older positional bag API returns
	-- to item ID, hyperlink, icon, and stack count.
	local function GetContainerItemDetails(bag, slot)
		if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
			local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
			if itemInfo then
				return itemInfo.itemID, itemInfo.hyperlink, itemInfo.iconFileID, itemInfo.stackCount
			end
		elseif type(GetContainerItemInfo) == "function" then
			local texture, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bag, slot)
			if not itemID and type(link) == "string" then
				itemID = tonumber(link:match("item:(%d+)"))
			end
			return itemID, link, texture, count
		end
	end

	-- Questie's sourceItemId identifies a quest item, but the button is shown only
	-- once the player has that item in a bag and a usable item link can be found.
	local function FindItemInBags(wantedItemID)
		wantedItemID = tonumber(wantedItemID)
		if not wantedItemID then return nil end

		local lastBag = tonumber(NUM_BAG_SLOTS) or 4
		if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
			lastBag = math.max(lastBag, Enum.BagIndex.ReagentBag)
		end

		for bag = 0, lastBag do
			local numSlots = 0
			if C_Container and type(C_Container.GetContainerNumSlots) == "function" then
				numSlots = C_Container.GetContainerNumSlots(bag) or 0
			elseif type(GetContainerNumSlots) == "function" then
				numSlots = GetContainerNumSlots(bag) or 0
			end

			for slot = 1, numSlots do
				local itemID, link, texture, count = GetContainerItemDetails(bag, slot)
				if tonumber(itemID) == wantedItemID then
					return link or ("item:" .. wantedItemID), texture, count, wantedItemID
				end
			end
		end
	end

	-------------------------------------------------------
	-- #5c. Quest Item Resolution, Completion & Counts
	-------------------------------------------------------

	-- Provide the native special-item return shape from Questie's quest record:
	-- link, icon, stack count, show-after-complete flag, and item ID.
	local function GetLegacyQuestItemInfo(questID)
		local questieDB = GetQuestieDatabase()
		if not questieDB or type(questieDB.GetQuest) ~= "function" then return nil end

		local ok, quest = pcall(questieDB.GetQuest, questID)
		if not ok or type(quest) ~= "table" or not quest.sourceItemId then return nil end

		local link, texture, charges, itemID = FindItemInBags(quest.sourceItemId)
		if not link then return nil end
		return link, texture, charges, false, itemID
	end


	-- Prefer Blizzard's quest-log association where it exists. Questie supplies
	-- a fallback on legacy clients when the native function returns no item.
	local function GetSpecialQuestItemInfo(questID, questLogIndex)
		if type(GetQuestLogSpecialItemInfo) == "function" then
			local ok, link, texture, charges, showItemWhenComplete =
				pcall(GetQuestLogSpecialItemInfo, questLogIndex)
			if ok and link then
				return link, texture, charges, showItemWhenComplete,
					tonumber(link:match("item:(%d+)"))
			end
		end

		return GetLegacyQuestItemInfo(questID)
	end

	-- The item disappears on completion unless Blizzard explicitly allows it to
	-- remain. RQE.API.IsComplete normalizes the differing client return shapes.
	local function IsRQEQuestComplete(questID)
		if RQE.API and type(RQE.API.IsComplete) == "function" then
			local ok, result = pcall(RQE.API.IsComplete, questID)
			if ok then
				if type(result) == "table" then
					return result.isComplete == true or result.isComplete == 1
				end
				return result == true or result == 1
			end
		end

		if C_QuestLog and type(C_QuestLog.IsComplete) == "function" then
			local ok, complete = pcall(C_QuestLog.IsComplete, questID)
			if ok then return complete == true or complete == 1 end
		end
		return false
	end


	-- Show quest-log charges when supplied; otherwise read the actual bag count.
	local function GetQuestItemCount(itemLink, itemID, charges)
		if type(charges) == "number" and charges > 0 then
			return charges
		end

		if C_Item and type(C_Item.GetItemCount) == "function" then
			return C_Item.GetItemCount(itemID or itemLink) or 0
		end
		if type(GetItemCount) == "function" then
			return GetItemCount(itemID or itemLink) or 0
		end
		return 0
	end

	-------------------------------------------------------
	-- #5d. Cooldown, Usability & Tooltip State
	-------------------------------------------------------

	-- Prefer a quest-specific cooldown when that API is present; otherwise use
	-- item cooldown APIs. Clear the cooldown display when no cooldown is active.
	local function UpdateQuestItemButtonCooldown(button)
		local questLogIndex = button.questLogIndex
		local ok, startTime, duration, enable
		if questLogIndex and type(GetQuestLogSpecialItemCooldown) == "function" then
			ok, startTime, duration, enable = pcall(GetQuestLogSpecialItemCooldown, questLogIndex)
		elseif button.itemID and C_Item and type(C_Item.GetItemCooldown) == "function" then
			ok, startTime, duration, enable = pcall(C_Item.GetItemCooldown, button.itemID)
		elseif button.itemID and C_Container and type(C_Container.GetItemCooldown) == "function" then
			ok, startTime, duration, enable = pcall(C_Container.GetItemCooldown, button.itemID)
		elseif button.itemID and type(GetItemCooldown) == "function" then
			ok, startTime, duration, enable = pcall(GetItemCooldown, button.itemID)
		end

		if ok and startTime and duration and duration > 0 and enable ~= 0 then
			button.cooldown:SetCooldown(startTime, duration)
		else
			button.cooldown:SetCooldown(0, 0)
		end
	end

	-- Refresh the visible button's usability, range tint, and cooldown without
	-- changing secure attributes. Unknown range leaves the icon normally colored.
	local function UpdateQuestItemButtonState(button)
		if not button:IsShown() then return end

		local usable = true
		if type(IsUsableItem) == "function" and button.itemLink then
			local itemUsable = IsUsableItem(button.itemLink)
			if itemUsable ~= nil then
				usable = itemUsable == true or itemUsable == 1
			end
		end

		local inRange
		if button.questLogIndex and type(IsQuestLogSpecialItemInRange) == "function" then
			local ok, rangeResult = pcall(IsQuestLogSpecialItemInRange, button.questLogIndex)
			if ok then inRange = rangeResult end
		end
		if inRange == nil
			and not isRetail
			and button.itemID
			and C_Item
			and type(C_Item.IsItemInRange) == "function"
			and ((UnitExists("target") and not UnitIsFriend("player", "target")) or not QuestItemButtonsInCombat())
		then
			local ok, rangeResult = pcall(C_Item.IsItemInRange, button.itemID, "target")
			if ok then inRange = rangeResult end
		end

		if button.icon.SetDesaturated then
			button.icon:SetDesaturated(not usable)
		end
		if inRange == 0 or inRange == false then
			button.icon:SetVertexColor(1, 0.25, 0.25)
		elseif usable then
			button.icon:SetVertexColor(1, 1, 1)
		else
			button.icon:SetVertexColor(0.55, 0.55, 0.55)
		end

		UpdateQuestItemButtonCooldown(button)
	end

	-- Tooltip uses the stored item hyperlink for both native and Questie items.
	-- The native quest-log tooltip remains a fallback if no link is available.
	local function QuestItemButtonOnEnter(button)
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		if button.itemLink then
			GameTooltip:SetHyperlink(button.itemLink)
		elseif button.questLogIndex and type(GameTooltip.SetQuestLogSpecialItem) == "function" then
			GameTooltip:SetQuestLogSpecialItem(button.questLogIndex)
		end
		GameTooltip:Show()
	end

	-- Remove the item tooltip as soon as the mouse leaves the button.
	local function QuestItemButtonOnLeave()
		GameTooltip:Hide()
	end

	-------------------------------------------------------
	-- #5e. Secure Button Pool & Container
	-------------------------------------------------------

	-- Reuse a free secure button or create one with icon, count, order number,
	-- cooldown, and tooltip regions. No ordinary Lua OnClick invokes the item:
	-- SecureActionButtonTemplate performs the configured item action itself.
	local function CreateQuestItemButton()
		local container = questItemButtonState.container
		if not container then return nil end

		local button = table.remove(questItemButtonState.buttonPool)
		if not button then
			button = CreateFrame("Button", nil, container, "SecureActionButtonTemplate")
			button:SetSize(QUEST_ITEM_BUTTON_SIZE, QUEST_ITEM_BUTTON_SIZE)

			button.icon = button:CreateTexture(nil, "BORDER")
			button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
			button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			button.icon:SetTexture(QUEST_ITEM_BUTTON_FALLBACK_TEXTURE)

			button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
			local normalTexture = button:GetNormalTexture()
			if normalTexture then
				normalTexture:ClearAllPoints()
				normalTexture:SetPoint("CENTER")
				normalTexture:SetSize(QUEST_ITEM_BUTTON_SIZE + 14, QUEST_ITEM_BUTTON_SIZE + 14)
			end
			button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
			button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

			button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			button.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			button.count:SetJustifyH("RIGHT")

			button.order = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
			button.order:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
			button.order:SetJustifyH("LEFT")

			button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			button.cooldown:SetAllPoints(button.icon)

			button:SetScript("OnEnter", QuestItemButtonOnEnter)
			button:SetScript("OnLeave", QuestItemButtonOnLeave)
			button:SetScript("OnUpdate", function(self, elapsed)
				self.rqeUpdateElapsed = (self.rqeUpdateElapsed or 0) + elapsed
				if self.rqeUpdateElapsed >= 0.2 then
					self.rqeUpdateElapsed = 0
					UpdateQuestItemButtonState(self)
				end
			end)

			questItemButtonState.allButtons[#questItemButtonState.allButtons + 1] = button
		end

		-- SecureActionButtonTemplate can execute on mouse-down when the player's
		-- ActionButtonUseKeyDown setting is enabled. Register both phases so the
		-- item action fires at the client's selected phase, including pooled buttons.
		button:RegisterForClicks("AnyDown", "AnyUp")
		button:SetParent(container)
		button:Show()
		return button
	end

	-- Clear the quest's secure item action and visual state before pooling its
	-- button, so the next quest cannot inherit an old link or cooldown.
	local function ReleaseQuestItemButton(questID)
		local button = questItemButtonState.activeByQuestID[questID]
		if not button then return end

		questItemButtonState.activeByQuestID[questID] = nil
		button:Hide()
		button:ClearAllPoints()
		button:SetAttribute("type", nil)
		button:SetAttribute("item", nil)
		button:SetAttribute("type*", nil)
		button:SetAttribute("item*", nil)
		button:SetAttribute("questLogIndex", nil)
		button:SetAttribute("questID", nil)
		button.questID = nil
		button.questLogIndex = nil
		button.itemLink = nil
		button.itemID = nil
		button.count:SetText("")
		button.order:SetText("")
		button.cooldown:SetCooldown(0, 0)
		questItemButtonState.buttonPool[#questItemButtonState.buttonPool + 1] = button
	end

	-- Place the secure button sidecar on UIParent, immediately outside the upper
	-- left of RQEQuestFrame. This follows tracker movement without making the
	-- tracker itself the parent of protected buttons.
	local function EnsureQuestItemButtonContainer()
		if questItemButtonState.container then return questItemButtonState.container end
		if not RQE.RQEQuestFrame then return nil end

		local container = CreateFrame("Frame", "RQEQuestItemButtonContainer", UIParent)
		container:SetSize(QUEST_ITEM_BUTTON_SIZE, 1)
		container:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPLEFT", -6, -4)
		container:SetFrameStrata(RQE.RQEQuestFrame:GetFrameStrata())
		container:SetFrameLevel(RQE.RQEQuestFrame:GetFrameLevel() + 5)
		container:Hide()
		questItemButtonState.container = container
		return container
	end

	-------------------------------------------------------
	-- #5f. Quest-to-Button Binding
	-------------------------------------------------------

	-- Bind one displayed quest to its item button. The quest ID owns the pooled
	-- button; the log index finds native item data; orderIndex labels the stack.
	-- All secure attributes are assigned only after combat lockdown has ended.
	function RQE.Buttons.CreateOrUpdateQuestItemButton(questID, questLogIndex, orderIndex)
		if QuestItemButtonsInCombat() then
			questItemButtonState.actionsPending = true
			return nil
		end

		questID = tonumber(questID)
		questLogIndex = tonumber(questLogIndex)
		if not questID or not questLogIndex then return nil end

		local itemLink, itemTexture, charges, showItemWhenComplete, itemID =
			GetSpecialQuestItemInfo(questID, questLogIndex)
		if not itemLink or (IsRQEQuestComplete(questID) and not showItemWhenComplete) then
			ReleaseQuestItemButton(questID)
			return nil
		end

		local button = questItemButtonState.activeByQuestID[questID]
		if not button then
			button = CreateQuestItemButton()
			if not button then return nil end
			questItemButtonState.activeByQuestID[questID] = button
		end

		button.questID = questID
		button.questLogIndex = questLogIndex
		button.itemLink = itemLink
		button.itemID = itemID or tonumber(itemLink:match("item:(%d+)"))
		-- Use the secure action's wildcard click attributes and an item:ID token.
		-- This mirrors a /use item:ID action for either mouse button, including on
		-- Classic/TBC clients that do not activate a full item hyperlink reliably.
		local secureItem = button.itemID and ("item:" .. button.itemID) or itemLink
		button:SetAttribute("type", "item")
		button:SetAttribute("item", secureItem)
		button:SetAttribute("type*", "item")
		button:SetAttribute("item*", secureItem)
		button:SetAttribute("questLogIndex", questLogIndex)
		button:SetAttribute("questID", questID)
		button.icon:SetTexture(itemTexture or QUEST_ITEM_BUTTON_FALLBACK_TEXTURE)
		button.count:SetText(GetQuestItemCount(itemLink, button.itemID, charges))
		button.order:SetText(orderIndex or "")
		UpdateQuestItemButtonState(button)
		return button
	end

	-------------------------------------------------------
	-- #5g. Tracker Ordering & Batched Refresh
	-------------------------------------------------------

	-- Use only the currently shown normal/campaign tracker rows. Sort by RQE's
	-- tracker row index so the sidecar follows displayed quest order.
	local function GetOrderedRQEQuestRows()
		local rows = {}
		for index, row in pairs(RQE.QuestLogIndexButtons or {}) do
			if row and row.questID and row.IsShown and row:IsShown() then
				rows[#rows + 1] = {
					index = tonumber(index) or 9999,
					row = row,
				}
			end
		end
		table.sort(rows, function(left, right) return left.index < right.index end)
		return rows
	end

	-- Rebuild the visible sidecar from current tracker rows. Buttons are stacked
	-- from its top edge, numbered by item-button order, and released when their
	-- quest row or special item is no longer present. They are not row-anchored.
	function RQE.Buttons.UpdateQuestItemButtons()
		if QuestItemButtonsInCombat() then
			questItemButtonState.actionsPending = true
			return
		end

		questItemButtonState.actionsPending = false
		local container = EnsureQuestItemButtonContainer()
		if not container then return end

		local seenQuestIDs = {}
		local visibleButtonCount = 0
		for _, rowData in ipairs(GetOrderedRQEQuestRows()) do
			local questID = tonumber(rowData.row.questID)
			local questLogIndex = questID and GetRQEQuestLogIndex(questID)
			if questID and questLogIndex then
				local button = RQE.Buttons.CreateOrUpdateQuestItemButton(
					questID,
					questLogIndex,
					visibleButtonCount + 1
				)
				if button then
					visibleButtonCount = visibleButtonCount + 1
					seenQuestIDs[questID] = true
					button.order:SetText(visibleButtonCount)
					button:ClearAllPoints()
					button:SetPoint(
						"TOP",
						container,
						"TOP",
						0,
						-(visibleButtonCount - 1) * (QUEST_ITEM_BUTTON_SIZE + QUEST_ITEM_BUTTON_SPACING)
					)
				end
			end
		end

		local staleQuestIDs = {}
		for questID in pairs(questItemButtonState.activeByQuestID) do
			if not seenQuestIDs[questID] then
				staleQuestIDs[#staleQuestIDs + 1] = questID
			end
		end
		for _, questID in ipairs(staleQuestIDs) do
			ReleaseQuestItemButton(questID)
		end

		container:SetHeight(math.max(1, visibleButtonCount * (QUEST_ITEM_BUTTON_SIZE + QUEST_ITEM_BUTTON_SPACING)))
		if visibleButtonCount > 0 and RQE.RQEQuestFrame and RQE.RQEQuestFrame:IsShown() then
			container:SetAlpha(1)
			container:Show()
		else
			container:Hide()
		end
	end

	-- Queue one refresh for a burst of tracker, quest-log, or bag updates. A
	-- combat-time refresh marks pending work for the next safe update instead.
	function RQE.Buttons.ScheduleQuestItemButtonUpdate()
		if questItemButtonState.updateScheduled then return end
		questItemButtonState.updateScheduled = true

		-- Function to execute the coalesced quest-item button refresh and release its schedule flag
		local function RunUpdate()
			questItemButtonState.updateScheduled = false
			RQE.Buttons.UpdateQuestItemButtons()
		end

		if C_Timer and type(C_Timer.After) == "function" then
			C_Timer.After(0, RunUpdate)
		else
			RunUpdate()
		end
	end

	-------------------------------------------------------
	-- #5h. Public API, Hooks & Event Refresh
	-------------------------------------------------------

	-- Publish the shared button implementation under RQE's public method names
	-- after QuestingModule.lua has loaded its older experimental definitions.
	local function PublishQuestItemButtonAPI()
		-- QuestingModule.lua contains an older experimental method. Publishing here
		-- after ADDON_LOADED makes this shared, quiet implementation authoritative
		-- on Retail, Classic Era/SoD, and TBC Anniversary.
		RQE.CreateOrUpdateQuestItemButton = function(_, questID, questLogIndex, orderIndex)
			return RQE.Buttons.CreateOrUpdateQuestItemButton(questID, questLogIndex, orderIndex)
		end
		RQE.UpdateQuestItemButtons = function()
			return RQE.Buttons.UpdateQuestItemButtons()
		end
	end

	-- Refresh after the tracker renders and when it shows, hides, or changes size.
	-- Hook flags prevent repeated installation on login/world event sequences.
	local function InstallQuestItemButtonHooks()
		PublishQuestItemButtonAPI()

		if not questItemButtonState.hookInstalled
			and type(UpdateRQEQuestFrame) == "function"
			and type(hooksecurefunc) == "function"
		then
			hooksecurefunc("UpdateRQEQuestFrame", function()
				RQE.Buttons.ScheduleQuestItemButtonUpdate()
			end)
			questItemButtonState.hookInstalled = true
		end

		if RQE.RQEQuestFrame and not questItemButtonState.frameHooksInstalled then
			RQE.RQEQuestFrame:HookScript("OnShow", function()
				RQE.Buttons.ScheduleQuestItemButtonUpdate()
			end)
			RQE.RQEQuestFrame:HookScript("OnHide", function()
				local container = questItemButtonState.container
				if not container then return end
				if QuestItemButtonsInCombat() then
					container:SetAlpha(0)
				else
					container:Hide()
				end
			end)
			RQE.RQEQuestFrame:HookScript("OnSizeChanged", function()
				RQE.Buttons.ScheduleQuestItemButtonUpdate()
			end)
			questItemButtonState.frameHooksInstalled = true
		end
	end

	-- Events catch quest-watch and inventory changes that may occur without an RQE
	-- tracker render. Leaving combat applies any deferred protected updates;
	-- Questie loading clears its cached module so legacy data can be rediscovered.
	local questItemButtonEventFrame = CreateFrame("Frame")
	questItemButtonEventFrame:RegisterEvent("ADDON_LOADED")
	questItemButtonEventFrame:RegisterEvent("PLAYER_LOGIN")
	questItemButtonEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	questItemButtonEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	questItemButtonEventFrame:RegisterEvent("QUEST_LOG_UPDATE")
	questItemButtonEventFrame:RegisterEvent("BAG_UPDATE")
	questItemButtonEventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
	questItemButtonEventFrame:SetScript("OnEvent", function(_, event, addonName)
		if event == "ADDON_LOADED" then
			if addonName == "RQE" then
				InstallQuestItemButtonHooks()
			elseif type(addonName) == "string" and addonName:match("^Questie") then
				legacyQuestieDB = nil
			else
				return
			end
		else
			InstallQuestItemButtonHooks()
		end

		if event == "PLAYER_REGEN_ENABLED" or not QuestItemButtonsInCombat() then
			RQE.Buttons.ScheduleQuestItemButtonUpdate()
		else
			questItemButtonState.actionsPending = true
		end
	end)


--------------------------------------------------
-- #6. 🧩 Quest Tracker Child-Header Controls
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Reserved Child-Header Button Area
	-------------------------------------------------------

	-- Code to be used for any buttons that are placed on the child headers of RQEQuestFrame


--------------------------------------------------
-- #7. 🛠️ Debug Log Frame Controls
--------------------------------------------------

	-------------------------------------------------------
	-- #7a. Debug Log Close Button
	-------------------------------------------------------

	-- Function to create and style the button that closes the Debug Log frame
	function RQE.Buttons.CreateDebugLogCloseButton(logFrame)
		-- Ensure the frame is valid
		if not logFrame then return end

		local closeButton = CreateFrame("Button", nil, logFrame, "UIPanelCloseButton")
		closeButton:SetSize(18, 18)
		closeButton:SetPoint("TOPRIGHT", logFrame, "TOPRIGHT", -6, -6)
		closeButton:SetScript("OnClick", function(self, button)
			logFrame:Hide()
		end)
		if RQE.UI then RQE.UI:StyleIconButton(closeButton, "Close") end
	end


--------------------------------------------------
-- #8. 🔎 Search Box Finalization
--------------------------------------------------

	-------------------------------------------------------
	-- #8a. Search Box Placeholder
	-------------------------------------------------------

	-- Function to create and initialize the SearchBox
	function RQE.Buttons.CreateSearchBox(RQEFrame)
		--Ace3 SearchBox
	end
