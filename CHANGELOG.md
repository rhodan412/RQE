11.2.7.1

	**HIGHLIGHTS**
		- Increased performance by fixing issue where the RQEFrame (supertracked quest) was being partially overridden/updates when a different quest is being supertracked

	Core.lua
		- Updated RQE.DebugPrintPlayerContinentPosition() to print out location information in the locations array using the current player location from continentID x and y for quests in the DB (2025.12.29.0311)
		- Added timeouts to RQE:ConfirmAndBuyMerchantItem(index, quantity) and C_AuctionHouse.ConfirmCommoditiesPurchase(itemID, quantity) for confirmation popups (2026.01.07.1627)
		- Added function for reseting RQEFrame and RQEQuestFrame to default size/location for debugModes that are not 'NONE' (2026.01.08.0313)

	DebugLog.lua
		- Updated logEntry for message to no longer be a string as % was not carrying over into the quest details popup [author-mode only] (2026.01.07.1627)

	EventManager.lua
		- Removed debug print within the UI_INFO_MESSAGE event function idx of 311 (2025.12.25.0431)
		- Added QUEST_REMOVED event function back in but limited it to only saves the tracked watch list for the player (2025.12.25.0431)
		- Added RQE:StartPerdiodicChecks to UI_INFO_MESSAGE for idx 310 which handles event type quests (2026.01.04.0350)
		- Fixed issue where the RQEFrame (supertracked quest) was being partially overridden/updates when a different quest is being supertracked (2026.01.07.1854)

	QuestingModule.lua
		- Added menu option in RQEQuestFrame right-click to reset frame to default size/location [available if debugMode is set to anything other than 'NONE'] (2026.01.08.0313)

	RQE.toc
		- Updated interface/version# (2025.12.25.0431)

	RQEDatabase.lua
		- Added additional Legion quests to the DB (2025.12.25.0431)
		- Added more Legion world quests to the DB (2025.12.29.0311)
		- Added additional world quests and some Winter's Veil quests updated in the DB (2025.12.30.1725)
		- Updates to The War Within, Battle for Azeroth, and Wrath of the Lich King quests in the DB (2026.01.04.0350)
		- Updates to Borean Tundra, Dragonblight and Howling Fjord alliance quests (2026.01.07.1627)

	RQEFrame.lua
		- Added menu option in RQEFrame right-click to reset frame to default size/location [available if debugMode is set to anything other than 'NONE'] (2026.01.08.0313)



11.2.7.0 (2025.12.13)

	**HIGHLIGHTS**
		- Further improvements to performance with unnecessary frequency of waypoint updates removed
		- Removed debug msgs associated with profile from the addon
		- Fixed issue where previous supertracked quest wasn't restored to the RQEFrame on reload or login
		- Added additional Legion order hall quests and Midnight Beta quests
		- Updated some code in preparation for the 12.0 expansion to make it compatible
		- Added functionality to have class and faction in the step description to decide if it should skip for quests that may have different coord information depending on player class
		- Fixed nil errors associated with the mapID and timers as it relates to the mythic+ dungeons
		- Major improvement updates to reduce CPU load
		- Added/updated many Legion and Wrath of the Lich King quests

	Buttons.lua
		- When the "Clear" frame button is pressed in the RQEFrame, the waypoints are reset (2025.12.08.2356)

	Core.lua
		- Added some notations to RQE:ClickWaypointButtonForIndex/self:ClickWaypointButtonForIndex to denote possible/probably redundancy (2025.11.22.1449)
		- Removed macro check from the RQE:ClickWaypointButtonForIndex(index) function as this was firing too frequently and unnecessarily (2025.11.22.1449)
		- Removed redundant calls to self:ClickWaypointButtonForIndex(stepIndex) within RQE:CheckDBBuff(), RQE:CheckDBDebuff(), RQE:CheckDBZoneChange(), and RQE:CheckDBObjectiveStatus() as this was handled thru RQE:StartPeriodicChecks() already (2025.11.22.1449)
		- Updated RQE:StartPeriodicChecks() to set the RQE.OkayWaypointButtonToMove flag to true when a step advances (2025.11.22.1603)
		- Removed debug messages associated with profile that were being displayed on log in for most player (2025.11.22.1851)
		- Added delay before the supertracked quest would be restored on reload and login (2025.11.22.1851)
		- Added coding to have steps recognize player class and faction (including neutral) in the description similar to 'ALLIANCE:' and 'HORDE:' in the description (2025.12.06.2331)
		- Updated RQE:ClearSeparateFocusFrame() and RQE:ShouldClearFrame() functions to allow for the clearing of the RQEFrame when the current questID in the RQEFrame is 0 or nil or if RQE.AllFramesShouldUpdate is flagged true (2025.12.08.2356)
		- Fixed nil error associated with the OpenQuestLogToQuestDetails() function (2025.12.10.0251)

	EventManager.lua
		- Added RQE.OkayWaypointButtonToMove flag (set to false) to ADDON_LOADED event function (2025.11.22.1603)
		- Added to delay to restoration of watched quests and supertracked quest when PLAYER_LOGIN is fired (2025.11.22.1851)
		- Removed call of restoration of watched quests and supertracked quest in the ADDON_LOADED event function (2025.11.22.1851)
		- Added flags for reload/login/misc to the PLAYER_ENTERING_WORLD which should improve performance when using portals/hearthstone (2025.11.22.1851)
		- Removed some code to RemoveRaidTargets() when events fire as this is going away in patch 12.0 (2025.12.05.0359)
		- Removed situation where RQEQuestFrame (quest tracker) is not being updated in combat as this is generally a very helpful thing as you make progress, but may need to add it take with modifications if problems with lag (2025.12.06.2331)
		- Updated the PLAYER_ENTERING_WORLD event function so that RQE.AllFramesShouldUpdate flag is set to true when player reloads or logs in along with an update to the frames during these situations (2025.12.08.2356)
		- Adds a check to see if the RQEFrame should be cleared (if nothing is being tracked in the RQEFrame) upon the firing of QUEST_LOG_UPDATE or QUEST_WATCH_LIST_CHANGED - but this may be reverted if lag issues (2025.12.08.2356)
		- Updated debug print requirement to be 'INFO' instead of 'INFO+' for the printing of the args for the ITEM_COUNT_CHANGED event function (2025.12.10.0251)
		- Enabled check for macro within with the PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED and UI_INFO_MESSAGE [idx 311] event functions (2025.12.10.0251)
		- Removed RQE.HandleTimerStart(timerID) and RQE.StopTimer() calls within event handling as these are not valid (2025.12.10.0251)
		- Removed QUEST_REMOVED event function as this was acting duplicate with a number of other more reliable events (2025.12.13.0212)
		- Updated UI_INFO_MESSAGE to first check that a quest is being supertracked and for that supertracked quest to be ready for turn in before updating macro to the last step for turn in (2025.12.13.0212)
		- Updated QUEST_LOG_UPDATE to no longer call a check to clear the RQEFrame as this was running in addition to other event functions (2025.12.13.0212)
		- Added check of player configuration settings to see if a quest should be supertracked following QUEST_TURNED_IN (2025.12.13.0212)
		- Removed/commented out calls to ClearSeparateFocusFrame, UpdateFrame [RQEFrame], UpdateRQEQuestFrame and RQE:StartPeriodicChecks when QUEST_TURNED_IN event function fires (2025.12.13.0212)
		- Added a 'return' to the QUEST_FINISHED event function if nothing is being supertracked (2025.12.13.0212)

	QuestingModule.lua
		- Removed calls to save watched quests and supertrack quest when RQE:QuestType fires as this was resulting in the supertracked quest being set to nil before the restoration could happen on reload/login (2025.11.22.1851)
		- After clicking the questlogindexbutton, to supertrack a quest or world quest, the list of tracked quests and supertrack quest is saved for later restoration (2025.12.08.2356)

	RQE.toc
		- Updated interface/version# (2025.12.05.0359)

	RQEDatabase.lua
		- Fixed several quests in Legion DB, including qid 48280 "Visions of Another" that had a mislabeling preventing the entry from being registered properly (2025.11.20.2150)
		- Added additional Legion remix quests and profession quests to the DB (2025.11.20.2150)
		- Updates to several Legion remix quests in the quest DB (2025.11.22.1449)
		- Updated some macros, waypoints for some Legion quests in the DB (2025.11.22.1851)
		- Updated DB to include the Alliance Exile's Reach quests (2025.11.24.1931)
		- Updated DB for many Warrior and Paladin order hall quests (2025.11.24.2108)
		- Added quests for Alliance Housing (2025.12.03.0359)
		- Added additional Beta quests for Midnight expansion to the DB (2025.12.05.0359)
		- Added class order hall quests for Legion DB (2025.12.05.0359)
		- Added many Shaman and Rogue class order hall quests to the DB (2025.12.05.2223)
		- Added many Rogue, Druid and Paladin class order hall quests to the DB (2025.12.06.2331)
		- Updated some Borean Tundra quests in the DB for the Wrath of the Lich King expansion (2025.12.08.2356)
		- Updated coordinate info for a number of quests within the DB for Legion expansion quests (2025.12.10.0251)
		- Updated some Wrath of the Lich King and Legion quests in the DB (2025.12.13.0212)

	RQEFrame.lua
		- Removed RQE:ClickWaypointButtonForIndex(i) call within WaypointButton:SetScript("OnClick", function() as this was causing a loop (2025.11.22.1449)
		- Requires player to be hovering over the stepInded or "W" button in the RQEFrame for TomTom profile to reset, CoordsText to be generated or clicked reducing lag caused from frequent calls to this especially when skyriding between subzones (2025.11.22.1449)
		- Updated function for the clicking (sometimes handled thru different function vs player click) of the "W" or stepsIndex Button to update waypoint also if the RQE.OkayWaypointButtonToMove flag is set to true from the RQE:StartPeriodicChecks() (2025.11.22.1603)

	QuestingModule.lua
		- Removed situation where RQEQuestFrame (quest tracker) is not being updated in combat as this is generally a very helpful thing as you make progress, but may need to add it take with modifications if problems with lag (2025.12.06.2331)

	WaypointManager.lua
		- Removed initial call to reset TomTom profile and set UID to nil every time RQE:CreateUnknownQuestWaypointWithDirectionText fires as this was something that was checked and updated appropriately within the RQE.Waypoints:Replace call a few lines further down (2025.11.22.1449)


11.2.5.6 (2025.11.20)

	**HIGHLIGHTS**
		- Fixed many Legion Argus quests in chapters 1 and 2 including waypoints and steps
		- Steps should not update more reliably without impacting performance since 11.2.5.5 (previous version)

	Core.lua
		- Allowed checks for the correct stepIndex player should be on when objective progress is made as well as quest completion. This will help update the steps during times when it should've but didn't [done w/o impacting performance] (2025.11.20.0149)

	RQE.toc
		- Updated Interface# (2025.11.20.0149)

	RQEDatabase.lua
		- Added most of the Legion Argus campaign quests to the DB (2025.11.20.0149)


11.2.5.5 (2025.11.19)

	**HIGHLIGHTS**
		- Removed debug language "running macro check" from PLAYER_REGEN_ENABLED (fires after combat is over) event and updated function call for better handling
		- Updated call for updating RQEButton (macro button) to be more efficiently handled, removing duplicates and removed from several event functions that were contributing to lag

	Core.lua
		- Added delay within RQE:StartPeriodicChecks() before the call to the RQE:UpdateSeparateFocusFrame() function (2025.11.19.1715)
		- Adjusted RQE.SetInitialWaypointToOne(), RQE.CheckAndSetFinalStep(), RQE:StartPeriodicChecks(), RQE:ClickWaypointButtonForIndex(), and RQE:CheckDBComplete() functions to handling RQEButton (macro) checks before running RQEMacro:CreateMacroForCurrentStep() to update the macro if update is needed - meant to increase efficiency (2025.11.19.1735)
		- Removed macro update within CheckQuestObjectivesAndPlaySound() as the other functions should be able to handle more efficiently - may add this back handling checks if macro isn't being properly updated (2025.11.19.1735)
		- RQEMacro:CreateMacroForCurrentStep() will no longer do macro checks as this is handled prior to the function call as this is handled with RQE.CheckCurrentMacroContents() (2025.11.19.1735)

	EventManager.lua
		- Cleaned up macro creation and removed debug language following combat conclusion (2025.11.19.1715)
		- Updated PLAYER_REGEN_ENABLED, SPELLS_CHANGED, PLAYER_ENTERING_WORLD, SUPER_TRACKING_CHANGED, and UPDATE_INSTANCE_INFO event functions to handling RQEButton (macro) checks before running RQEMacro:CreateMacroForCurrentStep() to update the macro if update is needed - meant to increase efficiency (2025.11.19.1735)
		- Removed duplicate function call for RQEMacro:CreateMacroForCurrentStep() within PLAYER_REGEN_ENABLED and now only fires if the RQE.ClearSeparateFocusFrameAfterCombat flag is set to true (2025.11.19.1735)
		- Removed call for RQEMacro:CreateMacroForCurrentStep() within PLAYER_STARTED_MOVING event function (2025.11.19.1735)

	QuestingModule.lua
		- Updated RQE.ClickQuestLogIndexButton() function to call a check for macro confirmation prior to the call to create/update when fired (2025.11.19.1735)

	RQE.toc
		- Updated Interface# (2025.11.19.1715)

	RQEDatabase.lua
		- Added most of the Legion Argus campaign quests to the DB (2025.11.19.2143)

	RQEFrame.lua
		- Updated RQE.InitializeSeparateFocusWaypoints() function to call a check for macro confirmation prior to the call to create/update when fired (2025.11.19.1735)

	WPUtil.lua
		- Updated RQE.UnknownQuestButtonCalcNTrack click script to call a check for macro confirmation prior to the call to create/update when fired (2025.11.19.1735)


11.2.5.4 (2025.11.18)

	**HIGHLIGHTS**
		- Added ability to click sections in select quests where a waypoint is generated within the RQEFrame
		- Fixed Button taint associated with the RQE.RenderTextWithItems() function
		- Fixed issue with spacing and alignment of both item/spell tooltips and clickable coordinate blocks in the RQEFrame
		- Each step description can now support multiple item/spell tooltips in a description (previously limited to one). If a description line has item/spell tooltip, clickable coordinate block is NOT permitted.
		- Significant performance updates as stepsText and SeparateFocusFrame were being called too frequently mainly from UpdateFrame()	-- REVERTED FOR NOW DUE TO SEPARATEFOCUSFRAME NOT UPDATING CORRECTLY
		- Added campaigns for Val'sharah, Azsuna, Highmountain and Stormheim to include side quests, Suramar campaign w/ side quests and Suramar Insurrection campaign quests to the DB
		- Fixed issue where quantity needed, to be purchased from the auction house, was listed as 0 and wouldn't buy more. Now if this is invalid in this way, it will ask if you want to purchase the full quantity needed
		- Fixed some tainting issues with QuestType, UpdateRQEQuestFrame and UpdateRQEWorldQuestFrame
		- SeparateFocusFrame gets cleared prior to it being updated to prevent text from layering on top of the previous text
		- Taint issues have been eliminated
		- Addon will check if the current step that the player is on is correct when the mapID changes
		- Major improvements to the updating of the SeparateFocusFrame as this was being updated too frequently when it shouldn't have been
		- Major improvements to the updating of the RQEFrame as it was updating far too often and resulting in large lag spikes
		- Significant modifications to the inventory events as a variety of these were causing function to fire that checks if the player is on the correct stepIndex
		- Additional improvements to reduce the firing of the RQE:StartPeriodicChecks() function that is responsible for updating the stepIndex to fire only on objective changes or change to supertracked quest
		- Added many Argus campaign quests to the DB

	Buttons.lua
		- Added flag to set to true whenever the RQE.Buttons.ClearButtonPressed() function fires (2025.11.16.2003)
		- No longer fires RQE:StartPeriodicChecks() when mousing over the "W" button as this wasn't needed since clicking the button would run it anyway (2025.11.17.0033)
		- Reset the FrameState for lastQuestID, lastQuestName, lastObjectives, lastNumObjectives and lastStepIndex when Clear Button is pressed (2025.11.17.0033)
		- Modified RQE.UnknownButtonTooltip for better printing of waypoint information into chat for the coordinateHotspots [author-mode only] (2025.11.17.2256)

	Core.lua
		- Updated RQE.RenderTextWithItems() function to recognize SimpleHTML with the creation of the clickable waypoint within the RQEFrame (2025.11.10.1926)
		- Fixed button taint associated with RQE.RenderTextWithItems() function by changing local hover = CreateFrame("Button", nil, baseParent) to local hover = CreateFrame("Frame", nil, baseParent) (2025.11.10.1926)
		- Added RQE.BuildHTMLFromRichText() function that renders SimpleHTML for tooltip (2025.11.11.0120)
		- Simplified the RQE.RenderTextWithItems() function that deals with the spell/items for the SeparateFocusFrame and also using RQE.BuildHTMLFromRichText() (2025.11.11.0120)
		- Re-created, re-named and modified the original RQE.RenderTextWithItems() to align tooltips properly for the mouse hovering over them in the steps below the SeparateFocusFrame and this is now called RQE.RenderTextWithItemsSteps() to handle the bits that use FontStrings instead of SimpleHTML (2025.11.11.0120)
		- Modified UpdateFrame() to only call RQE:CreateStepsText() is quest progress has taken place or a change of the supertrackedquestID, or when the RQE.OkaytoUpdateCreateSteps flag is true, which was set primarily from PLAYER_ENTERING_WORLD (2025.11.11.0631)
		- Modified RQE:StartPeriodicChecks() function to only call RQE:UpdateSeparateFocusFrame() when either RQE.OkayToUpdateSeparateFF or RQE.OkayToUpdateSeparateFFOnce is true (2025.11.11.0631)
		- Added some debug print functions for testing (2025.11.11.0631)
		- Added RQE:UpdateSeparateFocusFrame() to section that within UpdateFrame() when the create steps gets updated (2025.11.11.2105)
		- Added ApplyInlineMarkup to make SimpleHTML markup friendly (2025.11.12.0402)
		- Modifications to BuildHTMLFromRichText as html coding was displaying in SeparateFocusFrame and not recognizing line breaks, and the color was not showing up in the SeparateFocusFrame or StepsText creation (2025.11.12.0402)
		- Reverted and fixed coding in the RQE:ClearSeparateFocusFrame() function to correctly handle not displaying HTML coding. Subsequent lines in the DB entry follow \n use FontStrings while the first paragraph will use SimpleHTML for coordinate clicking (2025.11.12.2202)
		- Reverted RQE.BuildHTMLFromRichText(raw) to an earlier version (2025.11.12.2202)
		- Modified UpdateFrame() and RQE:StartPeriodicChecks() functions to revert back without the performance enhancements - these will need to be added later after they can be done so safely without causing problems with SeparateFocusFrame and/or StepsText (2025.11.12.2202)
		- Removed taint issues from OpenQuestLogToQuestDetails(questID) as it might sometimes fire during combat (2025.11.13.2156)
		- Added InCombatLockdown() check at the top of the RQE:ClearSeparateFocusFrame() function, to prevent stack overflow, with flag set to true to be re-run after combat ends (2025.11.14.1815)
		- Added variables to the RQE:UpdateMapIDDisplay() function to compare previous and currentmapIDs and if there was a change it will run the RQE:StartPeriodicChecks() function to determine the correct stepIndex (2025.11.16.2003)
		- Added RQE.ClearSeparateFocusHistory table to the top of the file along with setting RQE.lastMapID, RQE._lastSeparateQuestID and RQE._lastSeparateStepIndex as nil in the variables (2025.11.16.2003)
		- Added RQE:LogSeparateFocusClear() function to save data to the RQE.ClearSeparateFocusHistory table (2025.11.16.2003)
		- Added RQE:ShouldClearSeparateFocusFrame() function to save the currently supertracked quest to RQE.CurrentlySuperQuestID variable and make a determination if there was a change to the quest tracking, mapID or stepIndex comparing RQE.ClearSeparateFocusHistory table to current (2025.11.16.2003)
		- Added call within RQE:ClearSeparateFocusFrame() to run RQE:ShouldClearSeparateFocusFrame() function to determine of the SeparateFocusFrame should be cleared and subsequently updated (2025.11.16.2003)
		- Set RQE.StoredStepIndex and RQE.AddonSetStepIndex to nil along with RQE.FrameState table when Core is loaded initially (2025.11.17.0033)
		- Modified UpdateFrame() to call RQE:ShouldUpdateFrame() for determining first if the RQEFrame should be updated or not [the RQEFrame was updating way too frequently and resulting in unnecessary massive lag] (2025.11.17.0033)
		- Added RQE:ShouldUpdateFrame() function to run utility helper functions RQE:GetQuestObjectiveSnapshot() and RQE:CompareObjectiveTables() to determine if the RQEFrame should be updated (2025.11.17.0033)
		- Added RQE:GetQuestObjectiveSnapshot() function to save the current objective progress to a table (2025.11.17.0033)
		- Added RQE:CompareObjectiveTables() function to compare previous objective progress with previous snapshotted progress before returning true/false (2025.11.17.0033)
		- Set flags for RQE.QuestLogIndexButtonPressed to false before returns in the UpdateFrame() function (2025.11.17.0033)
		- Added check to see if objectives changed (for the purpose of running RQE:StartPeriodicChecks() from calls within the event functions (2025.11.17.0426)
		- Added check for finding out if the DirectionText has changed before Updating the RQEFrame (2025.11.17.0426)
		- Modified UpdateFrame() to find out if the flag is set designating the DirectionText has changed and should thus bypass RQE:ShouldUpdateFrame(questID) function and continue the UpdateFrame() function to update the RQEFrame (2025.11.17.0426)
		- Removed RQE.DontUpdateFrame within UpdateFrame() as this was preventing the RQEFrame from updating appropriately when DirectionText changes (2025.11.17.0426)
		- Added RQE:StepUsesZoneChange(step) helper function, called from the ZONE_CHANGED_NEW AREA and ZONE_CHANGED event functions, that checks if the current step of the supertracked quest has CheckDBZoneChange (2025.11.17.0426)
		- Added functionality to print current player's mapID coordinates and continental coordinates in coordinateHotspot format (2025.11.17.2021)
		- Modified the RQE.DebugPrintPlayerContinentPosition function to ignore certain continentIDs that are not true continents (Argus/Shadowlands) from printing those (2025.11.17.2021)
		- Fixed nil errors associated with the modifications to RQE.DebugPrintPlayerContinentPosition(questID) function [author-mode only] (2025.11.17.2256)
		- Adjusted PlaySound for locations array when not yet implemented [author-mode only] (2025.11.18.2138)

	EventManager.lua
		- Set RQE.OkayToUpdateSeparateFF to be false when fired from the ADDON_LOADED event and true when fired from SUPER_TRACKING_CHANGED event (2025.11.11.0631)
		- Set RQE.OkayToUpdateSeparateFFOnce to be true when fired from the ADDON_LOADED, PLAYER_ENTERING_WORLD, SUPER_TRACKING_CHANGED events (2025.11.11.0631)
		- Set RQE.OkaytoUpdateCreateSteps to be true when fired within the PLAYER_ENTERING_WORLD and UI_INFO_MESSAGE if the msgIndex was 311 for quest complete [prior to calling UpdateFrame()] (2025.11.11.0631)
		- Updated call to RQE:UpdateSeparateFocusFrame() within the QUEST_LOG_UPDATE event function of RQE.handleQuestStatusUpdate() to only be called if player is supertracking a quest that isn't ready for turn in and has a needAmt for that step of < 50 and fulfilled < 5 as this was causing a flicker in the SeparateFocusFrame when rapidly progressing through the fulfilled (2025.11.11.0631)
		- Added additional performance improvements and fixes related to the SeparateFocusFrame within QUEST_ACCEPTED, UI_INFO_MESSAGE(311), QUEST_COMPLETE, QUEST_AUTO_COMPLETE, QUEST_REMOVED, QUEST_TURNED_IN, QUEST_FINISHED and QUEST_WATCH_UPDATE, but might remove some to improve performance further if multifirings are taking place too often (2025.11.11.2105)
		- Cleaned up code for the improvements to functionality in QUEST_ACCEPTED and QUEST_COMPLETE to limit frequency of frame updates (2025.11.12.0402)
		- Reverted some of the efficiency fixes as it was causing potential problems for the displaying of the StepsText and SeparateFocusFrame text (2025.11.12.2202)
		- Added check, following PLAYER_REGEN_ENABLED (leaving combat) to see if RQE:QuestType(), UpdateRQEQuestFrame(), and/or UpdateRQEWorldQuestFrame() should be refired (2025.11.13.2156)
		- Updated PLAYER_REGEN_ENABLED to no longer run RQE:QuestType() after combat, as this was redundant, and added RQE:ClearSeparateFocusFrame() function to potential run after combat, if flag is set to true (2025.11.14.1815)
		- Removed SUPER_TRACKING_PATH_UPDATED event function as no longer necessary given the improvements to the SeparateFocusFrame clearing and updating (2025.11.16.2003)
		- Removed code that clears the waypoint data and separate focus frame during PLAYER_LOGIN and ADDON_LOADED (2025.11.16.2003)
		- Removed coding to update tracker visibility in the ADDON_LOADED as this is handled through PLAYER_LOGIN (2025.11.16.2003)
		- Removed coding that makes a check before clearing the RQEFrame within the UPDATE_INSTANCE_INFO as this was returning an error as a result of the change to how the clearing of the SeparateFocusFrame now occurs (2025.11.16.2003)
		- Removed UNIT_MODEL_CHANGE from event function listener (2025.11.17.0033)
		- Updated ITEM_COUNT_CHANGED, MERCHANT_UPDATE, UNIT_INVENTORY_CHANGED, MAIL_SUCCESS, BAG_UPDATE (for reagents), and BAG_NEW_ITEMS_UPDATED to only call RQE:StartPeriodicChecks() function if CheckDBInventory exists in the current step that the player is on [this was causing massive lag anytime something was looted!] (2025.11.17.0033)
		- Removed duplicate call for RQE:StartPeriodicChecks() in the PLAYER_ENTERING_WORLD event function [causing massive lag when changing zones via portal/hearth] (2025.11.17.0033)
		- Updated SUPER_TRACKING_CHANGED to reset RQE.FrameState for the lastQuestID, lastQuestName, lastObjectives, lastNumObjectives and lastStepIndex (2025.11.17.0033)
		- Removed call for the RQE:StartPeriodicChecks() function within ZONE_CHANGED_NEW_AREA as this is now done anytime the mapID changes (2025.11.17.0033)
		- Removed call for RQE:StartPeriodicChecks() within UI_INFO_MESSAGE as this is already handled through a multide of different locations more efficiently and this was resulting in duplicate firing (2025.11.17.0033)
		- Created new flag: RQE.DirectionChangedUpdateRQEFrame to record that DirectionText has changed and UpdateFrame() should fire (2025.11.17.0426)
		- Created new flag: RQE.PeriodicIsFiring that when RQE:StartPeriodicChecks() fires it will allow the firing to click the RQE.WaypointButtons[RQE.AddonSetStepIndex] (2025.11.17.0426)
		- Reset RQE.AddonSetStepIndex flag to 1 when SUPER_TRACKING_CHANGED fires after verifying that the current supertracked quest is different from the previously recorded supertracked quest (2025.11.17.0426)
		- Set macro creation within SUPER_TRACKING_CHANGED if the RQEQuestFrame is hidden [such as during a scenario/instance] (2025.11.17.0426)
		- Modified PLAYER_CONTROL_GAINED, QUEST_WATCH_UPDATE, UNIT_QUEST_LOG_CHANGED, UPDATE_INSTANCE_INFO event functions to check if objective progress has been made from previous snapshot before calling RQE:StartPeriodicChecks() greatly reducing lag and the frequency that this function runs (2025.11.17.0426)
		- Added check within SUPER_TRACKING_CHANGED to not call RQE:StartPeriodicChecks() function unless there was a change to the previously supertracked quest and the current supertracked quest (2025.11.17.0426)
		- Updated GOSSIP_CLOSED, QUEST_CURRENCY_LOOT_RECEIVED, and QUEST_LOOT_RECEIVED to run RemoveRaidTargets() instead of SetRaidTarget("target", 0) when those event functions fire (2025.11.17.2021)
		- Removed RQE:CheckWatchedQuestsSync() in the QUEST_REMOVED event function (2025.11.17.2021)
		- Updated section that prints out coordinateHotspots on QUEST_TURNED_IN event function to use the map coordinates that exist in the DB instead of current player coordinates (2025.11.17.2021)
		- Saved supertracked questID to RQE.LastSuperTrackedQuestID when SUPER_TRACKING_CHANGED event function fires (2025.11.17.2256)
		- Modified QUEST_TURNED_IN event function to RemoveRaidTargets() if the quest turned in was the quest last supertracked via RQE.LastSuperTrackedQuestID (2025.11.17.2256)
		- Removed the 'return' within RQE.ClearSeparateFocusFrameAfterCombat of the PLAYER_REGEN_ENABLED (combat ended) and added a macro check if RQE.ClearSeparateFocusFrameAfterCombat was also flagged during combat (2025.11.18.2138)

	QuestingModule.lua
		- Fixed issue where a world quest had multiple objectiveIndex and would incorrectly sometimes set the stepIndex to 2 when it should be on 1 as that objective wasn't yet completed. This was done by calling RQE:StartPeriodicChecks() within the clicking of the WQuestLogIndexButton (2025.11.11.0631)
		- Fixed issue where steps weren't being created after pressing the QuestLogIndexButton in the quest tracker section of the addon (2025.11.11.2105)
		- Added functionality to clear the SeparateFocusFrame when pressing the QuestLogIndexButton as this was not clearling both SimpleHTML and FontStrings from this frame (2025.11.12.2202)
		- Removed taint issues from RQE:QuestType(), UpdateRQEQuestFrame() and UpdateRQEWorldQuestFrame() as it might sometimes fire during combat and pushed them to fire outside of combat via flag - but this may be reverted (2025.11.13.2156)
		- Removed the firing of RQE:QuestType() if InCombatLockdown() as the UpdateRQEQuestFrame() and UpdateRQEWorldQuestFrame() functions, that are already included in this function will potentially run after combat finishes (2025.11.14.1815)
		- Added flag when QuestLogIndexButton is pressed so that the RQEFrame updates appropriately via UpdateFrame() function (2025.11.17.0033)

	RQE.toc
		- Updated Interface# (2025.11.08.2054)

	RQE_Sandbox.lua
		- Updated so that when Sandbox is saved or cleared it will call the RQE:UpdateSeparateFocusFrame() function (2025.11.11.0631)

	RQEDatabase.lua
		- Added additional Suramar side quests to the DB (2025.11.10.0058)
		- Added remaining campaign and side quest storylines for Suramar to the quest DB except several chapters of 'Insurrection' (2025.11.10.0637)
		- Updated the questDB to include the Jandvik's Jarl questline of Suramar (2025.11.10.1926)
		- Updated half of the "Crafting War" storyline, part of Insurrection, of Suramar quests (2025.11.10.1926)
		- Added part of the "As Strong As Our Will" storyline, which is part of Insurrection to the questDB (2025.11.11.0120)
		- Updated macros for qid 40307 and 40334 (steps 1 thru 3) to have the item used in the descriptionText, that also contains a coords block, placed within the macro (2025.11.11.0631)
		- Completed campaign and side quests of Suramar including Insurrection campaign (2025.11.11.0821)
		- Added continentID for auction house Dragonflight [profession] quests (2025.11.11.2105)
		- Added additional updates to the questDB for the Monk Order Hall (2025.11.12.0402)
		- Added a few quests to the DB for the upcoming Midnight expansion (2025.11.12.2202)
		- Added additional Legion quests including some Druid Order Hall quests to the DB (2025.11.13.2156)
		- Updated some quests in the class order hall of Monk (2025.11.14.1815)
		- Added additional Legion Remix quests to DB (2025.11.15.0052)
		- Added many Rogue and Priest Order Hall quests to the DB (2025.11.15.2012)
		- Added many Paladin Order Hall quests to the DB (2025.11.16.0245)
		- Updated questID 47287 to the DB file (2025.11.16.2003)
		- Removed unnecessary code in the DB that was already commented out (2025.11.17.0033)
		- Added a few additional Legion quests to the DB, including some on Argus and some Druid Order Hall quests (2025.11.17.0426)
		- Added additional Legion quests in Argus (2025.11.17.2021)
		- Added many Argus campaign quests to the DB (2025.11.18.2138)

	RQEFrame.lua
		- Updated RQE.GetSeparateStepText() helper function to handle the SimpleHTML, FontString and plain text formats with older wrapper function (2025.11.10.1926)
		- Updated CreateQuestTooltip, RQE:CreateStepsText and RQE.InitializeSeparateFocusFrame() to utilize the RQE.GetSeparateStepText() helper function and updated to provide clickable blocks to create waypoints [such as if a step first requires you to enter a cave, but has no subzone, zone transition] (2025.11.10.1926)
		- Fixed issue where each description was limited to a single item/spell tooltip. Now additional item/spell tooltips calls will render within the same step's description (2025.11.11.0120)
		- Added additional color choices for the coordinate block to appear in within the RQEFrame (2025.11.11.0120)
		- Updated call within the RQE:CreateStepsText to use the modified older render, that works better when dealing with FontStrings instead of SimpleHTML (2025.11.11.0120)
		- Modified the function call for the RQE:UpdateSeparateFocusFrame() within the RQE.InitializeSeparateFocusFrame() to only fire during initialization such as PLAYER_ENTERING_WORLD (2025.11.11.0631)
		- Updates for preventing the display, within RQE:CreateStepsText and RQE.InitializeSeparateFocusFrame() from showing HTML coding in the SeparateFocusFrame and fix issues with StepsText not creating color variants within the description text of the DB entries (2025.11.12.0402)
		- Reverted changes to the RQE:CreateStepsText and RQE:UpdateSeparateFocusFrame() functions to correctly display the text in the SeparateFocusFrame and StepsText (2025.11.12.2202)
		- Added call to RQE:ClearSeparateFocusFrame() before the frame would get updated to prevent information in SeparateFocusFrame being placed on top of existing text (2025.11.13.2156)
		- Saves the supertracked quest to the RQE.CurrentlySuperQuestID variable when RQE:UpdateSeparateFocusFrame() function fires and before the RQE:ClearSeparateFocusFrame() function is called prior to update (2025.11.16.2003)
		- Fixed anchoring issue with SeparateWaypointButton where the button was lower, in the SeparateFocusFrame, than it should've been. (2025.11.17.2021)

	RQEMinimap.lua
		- Removed potential taint issue with the conversion of RQE.MinimapButton from Button to Frame type (2025.11.13.2156)
		- Adjusted spacing with using tabs vs spaces for a clear handling when updating code (2025.11.17.0033)

	WPUtil.lua
		- Added some commented out information in the event that RQE.UnknownQuestButtonCalcNTrack = function() is causing taint (2025.11.13.2156)


11.2.5.3 (2025.11.08)

	**HIGHLIGHTS**
		- Updated crafting profession quests for Dragonflight to better handle when player has some of the items in their inventory
		- Created RQE_Sandbox [author-mode ONLY] to override the RQEDatabase DB entry with what is used in the sandbox. This will speed up updating of quests in the DB for future versions.
		- Better handling for step transition when dealing with indoor spaces such as order hall with multiple mapIDs
		- Fixed issue where screen would have tinted background when using RQE:ConfirmAndBuyMerchantItem to purchase an item, using macro, from a merchant
		- Added/updates campaign and leveling quests for Val'sharah, Azsuna, Highmountain and Stormheim

	Ace3
		- Library Updates to 12.0 (2025.10.30.0758)

	Core.lua
		- Updates to some debugMode requirements for printing information on location (2025.10.25.0026)
		- Cleaned up unused code (2025.10.25.1924)
		- Added setting within the SelectMultipleGossipOptions to use the target. This is helpful when multiple mobs that start with the same name can be used, such as Empyrean Conjuror and Empyrean Disciple using the macro entry: macro = { "#showtooltip item:5830\n/tar Empyrean\n/run RQE.SelectMultipleGossipOptions(\"\", 0)" }, (2025.10.25.1924)
		- Added setting to print the sandbox for the current supertracked quest if an entry exists [author-mode ONLY] (2025.10.25.1924)
		- Added RQE.CheckScenarioStageCompleted and RQE.CheckDBZoneName conditions [still experimental] (2025.10.26.2233)
		- Updated line spacing within PrintSupertrackedQuest for sandbox (2025.11.03.0311)
		- Fixed issue where screen would have tinted background when using RQE:ConfirmAndBuyMerchantItem to purchase an item, using macro, from a merchant (2025.11.03.1858)
		- Updated some print out related to coordinateHotspots [author-mode ONLY] (2025.11.08.0416)
		- Cleaned up some debug print (2025.11.08.2054)

	DatabaseMain.lua
		- Added option within the RQE.getQuestData(questID) to use information from the sandbox instead of the RQEDatabase file [author-mode ONLY] (2025.10.25.1924)
		- Added type check for getQuestData to prevent errors (2025.11.03.0311)

	EventManager.lua
		- Enabled AREA_POIS_UPDATED and added SUPER_TRACKING_PATH_UPDATED to event functions to update the RQEFrame more effectively as it was noticed that steps weren't updating correctly when transitioning to different maps within indoor spaces (2025.11.03.0311)

	QuestingModule.lua
		- Added options to menu to show the Sandbox window and print information from the supertracked quest if a Sandbox entry exists [author-mode ONLY] (2025.10.25.1924)

	RQE.toc
		- Updated Interface# (2025.10.24.0030)
		- Updated Saved Variables to include RQE_SandboxDB (2025.10.25.1924)

	RQE_Sandbox.lua
		- New file added for the purpose of inputting an entry to take the place of a DB entry from the RQEDatabase file [author-mode ONLY] (2025.10.25.1924)
		- Updated function that when 'Save the Sandbox' is pressed it will set the stepIndex to 1, UpdateFrame() and RQE:StartPeriodicChecks() (2025.10.26.2233)
		- Updated function that when 'Clear Sandbox' is pressed it will set the stepIndex to 1, UpdateFrame() and RQE:StartPeriodicChecks() (2025.10.28.2059)

	RQEDatabase.lua
		- Added additional campaign quests for Hunter order hall to the quest DB (2025.10.24.0030)
		- Updated crafting profession quests for Dragonflight to better handle when player has some of the items in their inventory (2025.10.25.0026)
		- Added early order hall campaign quests for mage (2025.10.25.0026)
		- Added additional quests for the mage order hall campaign (2025.10.26.0308)
		- Added some Warrior order hall quests to the DB (2025.10.26.2233)
		- Added intro Suramar quests to the DB (2025.10.27.0144)
		- Added intro Monk and Priest order hall quests along with several chapters of Suramar campaign to DB (2025.10.28.0558)
		- Added additional Legion expansion and Le'mix quests to DB (2025.10.28.2059)
		- Added additional quests for order hall campaigns in Legion and Suramar quests (2025.10.30.0758)
		- Added additional Suramar quests into the DB [7016/17522] (2025.10.31.0253)
		- Added Warlock, Death Knight and Demon Hunter class order halls & additional Suramar quests into the DB [7044/17530] (2025.11.01.0214)
		- Added many quests in Suramar campaign to the DB (2025.11.03.0311)
		- Updated Suramar and Highmountain quests in the DB (2025.11.03.1858)
		- Added many leveling quests in Highmountain to the DB (2025.11.04.0346)
		- Added remainder of Highmountain leveling campaign quests to the DB [7132/17564] (2025.11.05.0340)
		- Added early available Broken Shore campaign quests to DB for Breaching the Tomb (2025.11.06.0405)
		- Added remainder campaign quests in Val'sharah, Highmountain, and Stormheim to the DB [7203/17622 2026-06-19 WQ: 2601] (2025.11.07.2024)
		- Added most side quests in Highmountain to the quest DB (2025.11.08.0416)
		- Added/updates campaign and leveling quests for Val'sharah, Azsuna, Highmountain and Stormheim [7266/17664 2026-03-12 WQ: 2602] (2025.11.08.2054)

	RQEMacro.lua
		- Fixed icon/item information for 'weaken' tooltip (2025.11.01.0214)

	RQEFrame.lua
		- Added options to menu to show the Sandbox window and print information from the supertracked quest if a Sandbox entry exists [author-mode ONLY] (2025.10.25.1924)

	WaypointManager.lua
		- Updates to some debugMode requirements for printing information on location (2025.10.25.0026)


11.2.5.2 (2025.10.23)

	**HIGHLIGHTS**
		- Added conditionals to the quest checks to see if player has a particular spell known and also if a certain objective has been registered as completed
		- Added conditionals for checking player faction, race and class in deciding if a stepIndex should be advanced to the next step.
		- Added inverse conditionals to check for not faction, not race and not class before deciding if it should advance to the next step.
		- RQE Button will now update the macro and display when inside a raid or dungeon group but only if the player manually presses the button to supertrack a quest
		- Added many order hall campaign quests to the DB

	Core.lua
		- Cleaned up some debug print (2025.10.19.1527)
		- New Conditional Functions:
			• RQE.CheckKnownSpell(self, ...)
				•• Checks if any of the listed spells in the conditional register as known for the player. (2025.10.20.2320)
			• RQE.CheckObjectiveStatus(self, ...)
				•• Checks if any of the listed objectiveIndexes in the conditional register as complete for the supertracked quest. (2025.10.20.2320)
			• RQE.CheckPlayerFaction(self, ...)
				•• Checks if any of the listed faction in the conditional register as the player's faction. (2025.10.21.0257)
			• RQE.CheckPlayerRace(self, ...)
				•• Checks if any of the listed races in the conditional register as the player's race. (2025.10.21.0257)
			• RQE.CheckPlayerClass(self, ...)
				•• Checks if any of the listed classes in the conditional register as the player's class. (2025.10.21.0257)
		- Added new code to the functionMap of RQE:StartPeriodicChecks that is 'CheckDBConditionalsOnly' which does nothing but assesses the conditional (2025.10.21.0257)
		- Added inverse conditionals to: RQE.CheckPlayerFaction(self, ...), RQE.CheckPlayerRace(self, ...) and RQE.CheckPlayerClass(self, ...) that are RQE.CheckNotPlayerFaction(self, ...), RQE.CheckNotPlayerRace(self, ...) and RQE.CheckNotPlayerClass(self, ...) to the listing (2025.10.21.0308)
		- Updated RQEMacro:CreateMacroForCurrentStep() to work inside raid and dungeon groups, but will only update the macro if the player presses the button to supertrack the quest (2025.10.23.0249)

	EventManager.lua
		- Added function call to RQE:StartPeriodicChecks() function within the SPELLS_CHANGED event function (2025.10.20.2320)
		- Added flag to SUPER_TRACKING_CHANGED for the updating of the RQE (macro) button when supertracking a quest as the RQEQuestFrame is not visible (2025.10.23.0249)

	RQE.toc
		- Updated Interface# (2025.10.19.1527)

	RQEDatabase.lua
		- Added additional campaign and Legion remix quests to DB (2025.10.19.1527)
		- Added many Highmountain leveling quests to DB (2025.10.20.0636)
		- Updated more quests in Legion Remix for the infinite research and some world quests (2025.10.22.0036)
		- Added additional order hall campaign quests to the DB [particularly demon hunter, death knight and druid, but more to go for these classes] (2025.10.23.0249)
		- Added some campaign quests for Hunter order hall to the quest DB (2025.10.23.1822)

	RQEMacro.lua
		- Added item:28912 to be used for 'Learn ability' in the tooltip of RQE Button (2025.10.20.2320)


11.2.5.1 (2025.10.18)

	**HIGHLIGHTS**
		- Added smart conditional checking system for quests — steps can now advance automatically based on location, quest state, or map ID.
		- Introduced coordinate-based progression using distance tracking; the addon now detects proximity to specific coordinates and can auto-advance quest steps.
		- Improved movement detection and performance optimization for distance checks, ensuring minimal CPU overhead during player motion.
		- Added support for conditional logic functions like RQE.CheckMap(), RQE.CheckQuestState(), and RQE.CheckCoordinateDistance().
		- Improved internal debug logging to make conditional evaluations more transparent for advanced users.
		- Additions and fixes to the Legion quest DB
		- Added the ability to see spell tooltips in the quest helper frame
		- Improved quest step macro handling for smoother transitions between objectives and final turn-in steps (no more disappearing or outdated macros).
		- Added automatic support for quest steps that use Extra Action Buttons — including proper spell tooltips and class-appropriate icons.
		- Fixed intermittent issues where macros would clear or fail to regenerate when selecting a quest from the Quest Log.
		- Fixed issue where only the first spell tooltip on a single line would appear; multiple spells on the same line now all display correctly.
		- Cooldowns will now appear, for items and spells, inside the RQE Magic/Macro button to the left of the quest helper [RQEFrame].

	Core.lua
		- New Conditional Functionality for Step Logic:
			• Extended RQE:StartPeriodicChecks() to support dynamically parsed conditional expressions defined within quest step data (cond = "RQE.CheckFunction(...)"). (2025.10.14.0142)
			• Added conditional parsing and execution system capable of handling multiple parameters and mixed argument types [numeric or string]. (2025.10.14.0142)
			• Added a detection mechanism that identifies if the active step contains a coordinate-distance conditional (RQE.CheckCoordinateDistance) and flags it accordingly via RQE.isCheckingCoordinateDistanceConditional. (2025.10.14.0142)
			• Reordered and modularized logic flow to ensure coordinate-distance conditionals only activate when relevant to the player’s current step. (2025.10.14.0142)
			• Added per-step detection for the presence of coordinate-distance checks, setting the internal flag at the end of the periodic evaluation for accuracy and efficiency. (2025.10.14.0142)
		- Enhanced Movement-Aware Updates:
			• Updated OnPlayerMoving(self, elapsed) to include support for monitoring coordinate-distance conditionals. (2025.10.14.0142)
			• Added logic to check both RQE.isMonitoringCoordinateDistance and RQE.isCheckingCoordinateDistanceConditional before invoking coordinate-distance updates, significantly reducing unnecessary calls. (2025.10.14.0142)
			• Improved grid-based coordinate change detection using sub-percent (tenths) granularity for smoother, lower-latency triggering of coordinate-based progressions. (2025.10.14.0142)
		- New Conditional Functions:
			• RQE.CheckMap(self, ...)
				•• Checks if the player’s current map matches any in a provided list of map IDs. (2025.10.14.0142)
				•• Supports multiple numeric arguments (e.g., RQE.CheckMap(1, 10, 199)), returning true if the player is in any of those maps. (2025.10.14.0142)
			• RQE.CheckQuestState(self, questID, state)
				•• Evaluates if a specific quest is COMPLETED or INCOMPLETE based on its current state in C_QuestLog. (2025.10.14.0142)
				•• Used as a flexible step conditional within quest logic to manage branching progression. (2025.10.14.0142)
			• RQE.CheckCoordinateDistance(self, x, y, mapID, maxYards)
				•• Determines if the player is within a specified yard distance (maxYards) of a coordinate on a given map. (2025.10.14.0142)
				•• Automatically applies a +10 yard buffer to improve range detection accuracy, allowing database entries to specify the intended distance directly. (2025.10.14.0142)
				•• Utilizes HereBeDragons-2.0 for accurate yard-based distance computation and includes a fallback normalized distance approximation if unavailable. (2025.10.14.0142)
			• RQE:CheckCoordinateDistanceConditional()
				•• Dynamically scans the current step’s checks for coordinate-distance conditionals. (2025.10.14.0142)
				•• Automatically evaluates and advances the current quest step when the player moves within range of the specified coordinates. (2025.10.14.0142)
				•• Includes robust error handling and debug trace support for precise runtime monitoring. (2025.10.14.0142)
		- Modified the RQE.RenderTextWithItems() function to also include functionality on spell tooltips, while retaining ability to see item tooltips, which diverts the function to call RQE.HandleSpellTag() function instead. (2025.10.14.0319)
		- Removed fade on spell tooltip (2025.10.14.0801)
		- Fixed nil error with xNorm, yNorm in the RQE:FindQuestZoneTransition() function (2025.10.14.0801)
		- Updated RQE:CheckDBComplete() to rebuild macros on quest readiness and added throttled logic to prevent macro spam. (2025.10.14.0801)
		- Enhanced RQE.CheckAndSetFinalStep() to ensure macro persistence when switching or re-selecting quests in the Quest Log. (2025.10.14.0801)
		- Added full macroArray compatibility to RQEMacro:CreateMacroForCurrentStep(), allowing hybrid macro definitions with tooltip and icon metadata. (2025.10.14.0801)
		- Extended RQE.RenderTextWithItems() to dynamically handle both {item:id:name} and {spell:id:name} tags with distinct color codes and unified rendering logic. (2025.10.14.1921)
		- Added new handler function RQE.HandleSpellTag(parentFrame, spellID, spellName, cursorX, yOffset, baseParent, lineHeight, width) to manage spell tooltip hover regions using GameTooltip:SetHyperlink("spell:ID") for reliable refresh behavior. (2025.10.14.1921)
		- Updated hover generation logic to measure font width using shared measureFS object, ensuring pixel-accurate hitboxes for multiple spells or items appearing on the same line. (2025.10.14.1921)
		- Refined line-wrapping system to allow spell hover regions to split across lines in the same way as item tooltips, improving multi-line description consistency. (2025.10.14.1921)
		- Fixed bug causing only the first spell tooltip on a line to appear; all subsequent tooltips now render independently and correctly, even without line breaks. (2025.10.14.1921)

	EventManager.lua
		- Added Coordinate-Distance Monitoring State Flags:
			• Introduced two new global flags to coordinate movement and distance evaluation:
				•• RQE.isMonitoringCoordinateDistance – toggled true when the player begins moving (PLAYER_STARTED_MOVING) and false when movement stops (PLAYER_STOPPED_MOVING). (2025.10.14.0142)
				•• RQE.isCheckingCoordinateDistanceConditional – toggled by the step logic in Core.lua to control whether coordinate-distance checks should be performed. (2025.10.14.0142)
			• Integrated initialization of these flags within the ADDON_LOADED event to ensure predictable startup behavior. (2025.10.14.0142)
		- Updated Movement Event Handlers
			• Updated RQE.handlePlayerStartedMoving() to initialize coordinate monitoring and reset last known grid data, activating coordinate-based distance tracking only when relevant. (2025.10.14.0142)
			• Updated RQE.handlePlayerStoppedMoving() to cleanly disable coordinate monitoring and stop OnUpdate loops to conserve system resources. (2025.10.14.0142)
		- Added SPELLS_CHANGED event function for the purpose to update the magic [macro] button when changing between different artifact trees in Legion Remix (2025.10.16.1726)

	README.md
		- Updated to reflect upcoming change of the spell tooltips being visible in the RQEFrame (2025.10.14.0319)

	RQE.toc
		- Updated Interface# and version# (2025.10.14.0142)

	RQEMacro.lua
		- Refactored SetQuestStepMacro() to support both legacy and array-based macros, with automatic spell tooltip and icon assignment. (2025.10.14.0801)
		- Improved UpdateMagicButtonTooltip() to dynamically show spell tooltips for macroArray steps. (2025.10.14.0801)
		- Added normalization for numeric icon IDs to prevent API mismatches during macro creation. (2025.10.14.1959)
		- Updated Magic macro button to include cooldown for both items and spells (2025.10.16.1726)

	RQEDatabase.lua
		- Updated quest DB for more additions to the Legion expansion (2025.10.14.0209)
		- Updates to the quest DB for Legion quests and also added macroArray for questID 42537 to display spell tooltip and ability to click extra action button (2025.10.14.0801)
		- Added additional Legion quests to the DB for Remix (2025.10.14.0801)
		- Updated quests for Legion Remix, including some order hall campaigns, and added some profession quests from Dragonflight to the DB (2025.10.16.2358)
		- Added some world quests and early player housing quests [preliminary] to DB (2025.10.18.1450)

	WaypointManager.lua
		- Modified debug print to require specific debugLevel setting (2025.10.14.0142)


11.2.5.0 (2025.10.13)

	**HIGHLIGHTS**
		- Added functionality for tooltips to appear in the step descriptions in the SeparateFocusFrame and those of the individual steps (2025.10.05.2235)
		- Isolated item tooltip overlays into a dedicated hover container to prevent ghost tooltips from persisting between step updates (2025.10.06.0640)
		- Resolved issue where item tooltips were still present in the main RQEFrame [quest helper] even after tracking a different quest (2025.10.06.2234) 
		- Fixed Initialize/UpdateSeparateFocusFrame function as it was displaying no step information when DirectionText exists starting with a 2/1 denoting steps (2025.10.11.1452)
		- Many Legion Remix quests have been added to the quest DB (2025.10.13.0220)

	Buttons.lua
		- Added coding to display Blizzard's coordinates for step in chat [author-mode only] (2025.10.10.0655)

	Core.lua
		- Added new parsing and rendering system for item tags within quest text:
			• RQE.ParseItemTag(text) – Parses {item:id:name} tags and returns item data in structured form. (2025.10.05.2235)
			• RQE.RenderTextWithItemTags(text) – Converts item tags into formatted text links for display. (2025.10.05.2235)
			• RQE.RenderTextWithItems(parentFrame, rawText, font, fontSize, textColor) – Full rendering function that replaces {item:id:name} tags with clickable hover regions supporting dynamic tooltips, line wrapping, and adaptive alignment within quest descriptions. (2025.10.05.2235)
			• RQE:CreateItemTooltip(frame, itemID) – Generates item tooltips with item counts and contextual info on hover. (2025.10.05.2235)
		- Fixed an issue where steps weren't clearing before they were rendered in UpdateFrame() (2025.10.06.0401)
		- Updated function signature to support a custom hover frame container (2025.10.06.0640)
		- Modified parent assignment logic to prefer the provided hover container over default frame hierarchy (2025.10.06.0640)
		- Improved hover frame input handling to prevent unintended mouse propagation (2025.10.06.0640)
		- Adjusted the tooltip text to be light pink instead of white in order to stand out from the cream color in the description text (2025.10.06.1341)
		- Added RQE.LastMapChangeTime variable for future optimization of QUEST_WATCH_LIST_CHANGED, ZONE_CHANGED_NEW_AREA and RQE:AutoSuperTrackClosestQuest() (2025.10.06.2234)
		- Added functionality to clear the stepsText in frame before CreateStepsText is called within UpdateFrame (2025.10.06.2234)
		- Fixed ghosting of item tooltips in the RQEFrame when a new quest populates the field [still issue with ghosting if frame is cleared until repopulated by a different quest] (2025.10.06.2234)
		- Updated the way that the RQE.infoLog displays including the file name and line number it originates from. Also created RQE.smartPrint as an additional debug bit to show also the function that a print command is called from (2025.10.11.1452)
		- Removed old commented out code within UpdateFrame() function (2025.10.11.1452)

	EventManager.lua
		- Removed call to RQE:ClearStepsTextInFrame() after UpdateFrame() fires within the SUPER_TRACKING_CHANGED event function (2025.10.06.0401)

	QuestingModule.lua
		- Adjusted position of the WQuestLogIndexButton as it was too far to the left and being cut off by frame (2025.10.13.0220)

	RQE.toc
		- Updated Interface# and version# (2025.10.05.0608)

	RQEDatabase.lua
		- Added some quests with the new item tooltip functionality in the descriptions (2025.10.05.2235)
		- Updated all profession quests in Darkmoon Faire quests in the DB (2025.10.06.0640)
		- Updates to location and coordinateHotspots, in Valdrakken, for quest DB (2025.10.08.1314)
		- Added initial Legion Remix quests to the DB (2025.10.08.2214)
		- Updated several quests in DB for Val'sharah as well as completed most of the leveling campaign quests of Azsuna for Legion Remix (2025.10.10.0655)
		- Updated some of the quests in the DB and sorted them (2025.10.10.1427)
		- Added most of the Val'sharah campaign leveling quests and a few of the intro quests in Highmountain to the DB (2025.10.10.0025)
		- Added several world quests to Legion quest DB (2025.10.11.1452)
		- Added early to mid campaign Stormheim (Alliance/Neutral) leveling quests to DB (2025.10.12.0716)
		- Added more Stormheim and other Legion Remix quests to the DB (2025.10.13.0220)

	RQEFrame.lua
		- Added new function RQE.GetSeparateStepText() to standardize how separate step text is retrieved for tooltips and frame rendering, improving maintainability and consistency. (2025.10.05.2235)
		- Updated tooltip and text-rendering logic to use RQE.GetSeparateStepText() instead of directly accessing RQE.SeparateStepText:GetText(), ensuring dynamic compatibility with the new rich-text rendering system. (2025.10.05.2235)
		- Added a dedicated container for hover buttons inside RQE:CreateStepsText(StepsText, CoordsText, MapIDs) to isolate tooltip overlays from the global UI (2025.10.06.0640)
		- Updated the rendering call for quest step text to specify the new container (2025.10.06.0640)
		- Fixed Initialize/UpdateSeparateFocusFrame function as it was displaying no step information when DirectionText exists starting with a 2/1 denoting steps (2025.10.11.1452)
		- Fixed SeparateFocusFrame that was displaying "1/0: No step..." when quest not in DB (2025.10.12.0716)

	WaypointManager.lua
		- Modified debug print to require specific debugLevel setting (2025.10.06.2234)


11.2.0.7 (2025.10.05)

	**HIGHLIGHTS**
		- Fixed RQE:QuestRewardsTooltip() function to include additional choice rewards as these were previously not showing up reliably (2025.09.22)
		- Improved multi-zone quest support: hotspot progress is now preserved when moving between zones (2025.09.23)
		- Fixed step progression with Blizzard waypoints: objectives now advance correctly even when waypointText is present (2025.09.23)
		- Improved waypoint reliability: fallback waypoints are now automatically created from Blizzard’s quest directions (2025.09.23)
		- Objective-aware guidance and marking: hotspots (`oI`) and npcTargets (`obj`) tied to completed objectives are now automatically filtered out, improving accuracy and reducing noise (2025.09.24)
		- Custom waypoint labels: coordinateHotspots may now include a wayText field. If present, the waypoint will display this custom text instead of the default “QID QuestName”. This allows authors to show context-specific guidance like “Collect the Book” or “Open the Chest” right on the map (2025.09.25)
		- Added new file to maintain what the API is with the current Blizzard system to future-proof and add for eventual functionality across other game versions (2025.09.26)
		- Waypoint labels are now more consistent: when Blizzard directions or DB hotspots aren’t available, fallback waypoints always use “QID: ###, Quest Name” instead of sometimes reverting to just the quest name (2025.09.27)
		- Fixed auction house purchase macros: `"x"` quantities are now resolved dynamically from quest objectives, ensuring correct counts across all objectives (2025.09.30)
		- Improved waypoint title handling in WaypointManager.lua: waypoints now consistently use hotspot wayText (via _currentHotspotIdx), correctly fall back when no direction text is available, and no longer revert to raw "QID: ###, Quest Name" strings. (2025.09.30)
		- Improved waypoint stability and accuracy:
			• Added continent-level fallback waypoints when zone locations aren’t available, so guidance never disappears.  
			• Waypoints now respect Blizzard’s built-in directions when present, avoiding confusing switches.  
			• Custom waypoint labels (wayText) are preserved more reliably when moving between hotspots. (2025.10.02)
		- Added functionality to track location by a set location or that of coordinates in an array, to also include mapID and/or continentID (2025.10.02)
		- Improved waypoint accuracy for searched quests: waypoints now correctly prioritize zone locations and only use continent fallbacks when outside the target area. (2025.10.04.1513)
		- Fixed an issue where waypoints sometimes appeared in the wrong map or wouldn’t recreate after the first click. (2025.10.04.1513)
		- Smarter searched-quest behavior: the “W” button now reliably creates or refreshes waypoints for quests you haven’t picked up yet. (2025.10.04.1513)
		- Updated NPC interaction macros to automatically use RQE’s built-in marker system, ensuring more consistent marking of quest givers and targets. (2025.10.04.1513)
		- Improved waypoint creation logic: searched quests without Blizzard direction text now correctly generate fallback waypoints, and tooltip data auto-refreshes for more accurate coordinate display. (2025.10.04.2046)
		- Improved event-type quest handling: RQE now advances steps for quests that are Ready for Turn-In even when objectives never flag as completed [via new CheckDBComplete support in Core.lua]. (2025.10.05.0301)

	Buttons.lua
		- Modified code in the RQE.UnknownButtonTooltip function to use RQE.GetPrimaryLocation instead of dbEntry.location to accommodate a location array in the DB (2025.10.02)
		- Updated RQE.UnknownButtonTooltip to reflect more accurate coordinate with locations array (2025.10.03.1419)
		- Fix for the waypoint creation to direct player to searched quests flagged as not yet picked up & completed in the RQE.UnknownQuestButtonMouseDown function (2025.10.03.1419)
		- Updated RQE.UnknownQuestButtonMouseDown function (2025.10.04.1402)
		- Updated RQE.UnknownQuestButtonMouseDown to correctly handle searched-quest waypoint creation across both mapID and continentID contexts. The function now passes the appropriate map or continent reference into RQE:CreateSearchedQuestWaypoint, ensuring accurate resolution of DB location arrays. (2025.10.04.1513)
		- Replaced redundant final debug print using undefined coordinate variables with context-aware output reflecting the selected map/continentID target for clearer feedback. (2025.10.04.1513)
		- Cleaned up click event logic and ensured that the W-button consistently creates waypoints on repeated clicks, resolving the “only creates once” behavior. (2025.10.04.1513)
		- Cleaned up code (2025.10.04.2046)

	Core.lua
		- Cleaned up spacing in the code (2025.09.22)
		- Resolved an issue in RQE:StartPeriodicChecks() where step progression would not update when waypointText was present. Steps now advance correctly while waypoints continue to follow Blizzard’s provided waypointText. (2025.09.23)
		- Fixed nil error when fetching questName within RQE.ObtainSuperTrackQuestDetails() function (2025.09.23)
		- Added objective-aware NPC marking: `npcTargets` may now include `obj` (objectiveIndex). Mobs tied to completed objectives are skipped automatically (2025.09.24)
		- Introduced local `_IsObjectiveComplete()` to decouple from WPUtil scope and ensure reliable checks (2025.09.24)
		- Filter `npcTargets` when building the current step’s `mobList`; only unfinished-objective entries are included (backwards compatible when `obj` is omitted) (2025.09.24)
		- `TryMarkUnit()` also short-circuits marking if a mob has `obj` and its objective is complete (belt-and-suspenders) (2025.09.24)
		- Reduced mouseover lag: added a small cache of the current step’s `mobList` keyed by `questID`/`stepIndex`; the list rebuilds only when those change (2025.09.24)
		- Removed noisy debug print during list construction; marking/debug output now occurs only when a unit is actually processed (2025.09.24)
		- Updated RQE:SearchPreparePurchaseConfirmAH(): quantity `"x"` is now resolved dynamically using quest objectives (`numFulfilled` / `numRequired`) instead of hard-coded objective #1. The function loops across all objectives to match the relevant item and calculates the remaining needed count correctly. This fixes auction-house macros that previously showed `0` quantity or fractional purchases. (2025.09.30)
		- Added RQE.DebugPrintPlayerContinentPosition() debug function to obtain current player coords as related to the continentID and coords (2025.10.02)
		- Modified code in the RQE.SaveCoordData(), UpdateFrame(), RQE.SearchModule:CreateSearchBox() and RQE:GetClosestFlightMasterToQuest() functions to use RQE.GetPrimaryLocation instead of dbEntry.location to accomodate a location array in the DB (2025.10.02)
		- Updated RQE.SaveCoordData(), UpdateFrame(), RQE.SearchModule:CreateSearchBox() and RQE:GetClosestFlightMasterToQuest(questID) functions to reflect more accurate coordinate with locations array (2025.10.03.1419)
		- Updated RQE.DebugPrintPlayerContinentPosition() function to print location and coordinateHotspots depending on flag from EventManager (2025.10.04.1402)
		- Enhanced RQE.DebugPrintPlayerContinentPosition(questID) to include database coordinate validation, prevent nil formatting errors, and dynamically print location or coordinateHotspots data based on quest state and DB structure. (2025.10.04.2046)
		- Updated RQE.DebugPrintPlayerContinentPosition() to skip coordinateHotspots output when the current quest step already defines them in the DB, preventing redundant prints and ensuring cleaner debug output. (2025.10.04.2148)
		- Improved event-type quest handling: RQE now advances steps for quests that are Ready for Turn-In even when objectives never flag as completed [via new CheckDBComplete support in Core.lua]. (2025.10.05.0301)
		- Cleaned up code and modified check for creating macro to be not in raid from the previous of being not in party OR raid (2025.10.05.0555)

	EventManager.lua
		- Cleaned up spacing in the code (2025.09.22)
		- Updated ZONE_CHANGED_NEW_AREA handling: RQE.WPUtil.ClearHotspotState now performs a full reset of visited hotspot states only for single-zone quest steps. For multi-zone quest steps (DB entries with hotspots across multiple mapIDs), it uses a light reset to preserve visited progress (2025-09-23)
		- Added delayed waypoint creation in EventManager.lua: when a super-tracked quest provides waypointText, RQE now waits 5 seconds before calling CreateUnknownQuestWaypointWithDirectionText, ensuring a fallback waypoint is placed using Blizzard’s direction text. (2025.09.23)
		- Added an UpdateFrame() function call within QUEST_WATCH_LIST_CHANGED event function higher up in the function (2025.09.23)
		- Added forced refresh of supertracked waypoint by removing the simulates RWButton click and then call instead ForceWaypointForSupertracked with a short delay to ensure the correct waypoint is set. (2025.09.27)
		- Added NAVIGATION_DESTINATION_REACHED and NEW_WMO_CHUNK event functions for the updating of the RQEFrame and waypoint via the SeparateButton as DirectionText would get updating [leaving SW Mage Tower/Wizard's Sanctum] and not update waypointText correctly (2025.09.27)
		- Fixed issue with SUPER_TRACKING_CHANGED where RQEFrame bits weren't updating properly when RQEQuestFrame wasn't visible [mythicMode enabled] (2025.09.27)
		- Increased C_Timer in PLAYER_ENTERING_WORLD event function to check if RQE macro is correct with the supertracked quest as this was a problem when dealing with the macro being from a searched quest on previous login (2025.10.03.1419)
		- Added flags and calling of the RQE.DebugPrintPlayerContinentPosition() function during QUEST_ACCEPTED and QUEST_TURNED_IN (2025.10.04.1402)

	QuestingModule.lua
		- Cleaned up spacing in the code (2025.09.22)
		- Fixed RQE:QuestRewardsTooltip() function to include additional choice rewards as these were previously not showing up reliably (2025.09.22)

	RQE.toc
		- Updated version# (2025.09.19)
		- Added RQE_API.lua to the TOC call (2025.09.26)

	RQE_API.lua
		- Added new file to maintain what the API is with the current Blizzard system to future-proof and add for eventual functionality across other game versions (2025.09.26)
		- Added and updated API calls and saving them to a table (2025.09.27)

	RQEFrame.lua
		- Added check for if tracked quest was world quest so that the tooltip would only add an extra line above the RQE.SeparateStepText if it was not a world quest (2025.09.22)

	RQEDatabase.lua
		- Added some additional description and objective text within the DB (2025.09.22)
		- Added additional quests including questID 72396 that has multi-map visited bands support (2025.09.23)
		- Updated some of the profession quests to better handle coordinateHotspots and the applicable waypoint(s) in the DB entries (2025.09.23)
		- Fixed some quests in DB for Elwynn Forest (2025.09.23)
		- Added coding for the oI for coordinateHotspots [see WPUtil.lua] and obj for the npcTargets [see Core.lua] (2025.09.24)
		- Added additional quests in Legion and Duskwood (2025.09.27)
		- Updated profession quests for the coordinateHotspots for Valdrakken (Dragonflight) quests (2025.09.30)
		- Updates to some quests and added 'continentID' to questID 8149 (2025.10.02)
		- Added additional quests with continentIDs for quests in the coordinateHotspots (2025.10.03.1419)
		- Updates to some Duskwood quests to the DB (2025.10.04.1402)
		- Added Westfall quests to DB (2025.10.05.0555)

	RQEMacro.lua
		- Updated RQE:GenerateNpcMacroIfNeeded(questID) to replace legacy /script SetRaidTarget("target",3) line with /run RQE:SetMarkerIfNeeded('target', 8). This change standardizes marker assignment through RQE’s internal handler, ensuring consistent icon logic and compatibility with NPC marker validation routines. (2025.10.04.1513)

	WaypointManager.lua
		- Extended RQE:CreateWaypoint() to support hotspot-specific wayText. If the current step uses coordinateHotspots and the active hotspot includes wayText, that string overrides the default waypoint title. (2025.09.25)
		- Updated RQE:CreateWaypoint(): default title now uses GetWaypointTitle() so fallbacks are always in “QID: ###, Quest Name” format instead of plain questName. (2025.09.27)
		- Adjusted duplicate-coordinate skip logic: waypoint is only skipped if both coordinates and title match, allowing title refresh without coordinate change. (2025.09.27)
		- Updated RQE:GetWaypointTitle() to respect the currently selected hotspot index (RQE._currentHotspotIdx) before falling back to coordinate-matching. This ensures the waypoint label stays stable as the player moves instead of reverting to the quest’s base title. (2025.09.30)
		- Fixed RQE:CreateUnknownQuestWaypointWithDirectionText() running even when no valid direction text was available. Added an early bail-out to re-route to the NoDirectionText handler. (2025.09.30)
		- Updated RQE:OnCoordinateClicked() to use GetWaypointTitle() for all waypoint creation instead of building raw "QID: ###, Quest Name" strings. Prevents title regressions and ensures hotspot wayText is consistently honored. (2025.09.30)
		- Added support for remembering and reusing the last stored wayText from SelectBestHotspot. This ensures waypoint titles remain consistent when switching between continent and zone hotspots, instead of falling back prematurely to quest titles or Blizzard waypoint text. (2025.10.02)
		- Updated RQE:CreateSearchedQuestWaypoint to more accurately create waypoint when pointing to a quest giver for a searched quest that the player doesn't have and is incomplete following the creation of the  locations array (2025.10.03.1419)
		- Updated RQE:CreateWaypoint() to support forced waypoint recreation via the RQE.isForcedWaypoint flag, bypassing duplicate-coordinate suppression for searched quests and manual waypoint triggers. Added corresponding debug output for transparency (2025.10.04.1402)
		- Updated RQE:CreateSearchedQuestWaypoint() to pass mapID into RQE.GetPrimaryLocation() for precise resolution of locations entries, including continentID-based coordinates. Added forced waypoint creation handling to allow multiple re-creations and fixed the “only creates once” behavior for searched quests (2025.10.04.1402)
		- Fixed location prioritization logic in RQE:CreateSearchedQuestWaypoint(questID, mapID) where continent-level coordinates were being used even when the player was inside the specific zone (mapID match). The function now correctly prefers mapID-based waypoints when present and falls back to continentID only when necessary. (2025.10.04.1513)
		- Adjusted continent waypoint creation to use the actual continent mapID rather than the current player zone, preventing misplaced continent-level waypoints. (2025.10.04.1513)
		- Verified consistency with forced waypoint creation via RQE.isForcedWaypoint, ensuring repeated searched-quest clicks always trigger fresh waypoint placement. (2025.10.04.1513)
		- Added conditional direction text handling in RQE:CreateSearchedQuestWaypoint(questID, mapID). The function now checks C_QuestLog.GetNextWaypointText() for valid Blizzard direction text and automatically falls back to RQE:CreateUnknownQuestWaypointNoDirectionText() when none is found. This prevents the creation of empty or misleading waypoints for quests without waypointText. (2025.10.04.2046)
		- Updated RQE:CreateUnknownQuestWaypointNoDirectionText(questID, mapID) to synchronize tooltip coordinate variables (DatabaseSuperX, DatabaseSuperY, and DatabaseSuperMapID) when a waypoint is created. Added automatic tooltip refresh for the “W” button when visible, ensuring coordinate display updates instantly without requiring mouseover. (2025.10.04.2046)

	WPUtil.lua
		- Cleaned up spacing in the code (2025.09.23)
		- Added objective-aware hotspot filtering: hotspots can now include `oI` (objectiveIndex). When the associated objective is complete, those hotspots are automatically excluded from selection (2025.09.24)
		- NormalizeCoordinates now carries `oI` through from DB entries (no change required for legacy `coordinates` or hotspots without `oI`) (2025.09.24)
		- Added helpers `IsObjectiveComplete()` and `FilterEligibleHotspots()`; filtering is applied at the start of `SelectBestHotspot()` (2025.09.24)
		- Rebuilds `priorityBands` after filtering to keep band/debug logic accurate; preserves `minSwitchYards` / `visitedRadius` per hotspot (2025.09.24)
		- Added a safety guard so throttled early-returns don’t reference a filtered-out hotspot (2025.09.24)
		- Fixed a rare crash in SelectBestHotspot: if a hotspot tied to a completed objective was filtered out, the function could still reference an invalid st.currentIdx. The index is now validated after filtering, preventing nil errors and ensuring a new hotspot is properly reselected. (2025.09.24)
		- EnsureWaypointForSupertracked() now passes a title from GetWaypointTitle() instead of nil, preventing unwanted fallbacks to plain questName. (2025.09.27)
		- Updated debug print for the waypointTitle labeled "ttl" within the RQE:EnsureWaypointForSupertracked() function (2025.09.30)
		- Added continent-level fallback resolution for hotspot selection when no same-map hotspot is available. This allows quests to retain meaningful waypoint guidance at the continent scale before zone entry. (2025.10.02)
		- Updated hotspot switching logic to respect Blizzard’s waypointText when available. Now prevents premature switching from continent → zone hotspots unless the player is physically in the destination zone, while still propagating custom wayText when Blizzard does not provide one. (2025.10.02)
		- Persisted last used wayText into _hotspotState when selecting a hotspot. This ensures that EnsureWaypointForSupertracked and GetWaypointTitle can consistently reuse the same text across hotspot transitions, instead of falling back to quest titles. (2025.10.02)
		- Added RQE.GetPrimaryLocation(dbEntry) helper function that is now called within Buttons.lua and Core.lua when tracking the location of the quest start (2025.10.02)
		- Fix to RQE.GetPrimaryLocation helper function for the handling of the location code and locations array (2025.10.03.1419)
		- Extended RQE.GetPrimaryLocation(dbEntry) to accept an optional targetMapID argument, enabling direct resolution of specific map or continent coordinates. Added short-circuit check within iteration loop to immediately return the matching entry. This ensures continent-level waypoints (e.g., mapID 13) resolve correctly when invoked via searched-quest buttons (2025.10.04.1402)
		- Refined RQE.GetPrimaryLocation(dbEntry, targetMapID) to improve map priority resolution logic. The function now strictly prioritizes player mapID matches before evaluating explicit targetMapID and continentID entries, ensuring correct location selection in multi-map DB entries. (2025.10.04.1513)
		- Added internal guards to skip invalid coordinate entries and prevent cross-map preference inversion (ensuring mapID entries always take precedence when both exist). (2025.10.04.1513)
		- Finalized reliable fallback chain: mapID → targetMapID → continentID → first valid, guaranteeing predictable behavior across all search and creation contexts. (2025.10.04.1513)

11.2.0.6 (2025.09.19)

	**HIGHLIGHTS**
		- Players can now use the Blizzard Objective Tracker to super track quests and have the RQEFrame (quest help direction frame) populate correctly (2025.09.19)

	Core.lua
		- Cleaned up old debug code (2025.09.19)
		- Better handling during UpdateFrame of RQEFrame so that the supertracked quest isn't being registered twice in the event handling (2025.09.19)

	EventManager.lua
		- Added coding to SUPER_TRACKING_CHANGED event function to correctly handle super tracking button presses within the default Blizzard Objective Frame (2025.09.19)

	RQE.toc
		- Updated version# (2025.09.15)

	RQEDatabase.lua
		- Updated some side-quest direction for Horrific Vision: Orgrimmar (2025.09.19)

	RQEMacro.lua
		- Cleaned up old debug code (2025.09.19)

	WaypointManager.lua
		- Cleaned up old debug code (2025.09.19)


11.2.0.5 (2025.09.17)

	**HIGHLIGHTS**
		- Waypoints for coordinateHotspots update on player movement to direct player to the correct quest blob for the supertracked quest (2025.09.15)
		- Waypoints in use for coordinateHotspots will now select the best location for doing a quest step and create waypoint to another location on proximity after previous hotspot visited with better drops (2025.09.15)
		- Functionality finally added to quests where auto-completable is available (2025.09.17)

	Buttons.lua
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE.Buttons.ClearButtonPressed() and RQE.Buttons.CreateRWButton(RQEFrame) functions (2025.09.15)

	Core.lua
		- Added call to RQE.CheckAndClickSeparateWaypointButtonButton(), at the top of the StartPerdiodicChecks function call to click the that button when initially run as sometimes a waypoint can be created even if the mapID for waypoint doesn't match that of player currentmapID (2025.09.15)
		- Added functionality to update waypoint location when player moves, but only on the whole number for the x, y coordinates (2025.09.15)
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE:SetTomTomWaypointToClosestFlightMaster() function. (2025.09.15)
		- Modified colorizeObjectives to use hex color helpers, in Core.lua (2025.09.17)
		- Added functionality to show dialog box Auto Complete dialog box when clicking on questID or questName in the RQEFrame/RQEQuestFrame, and objectives in RQEQuestFrame (2025.09.17)
		- Added functions that check to see if any quests, not being watched, have an auto-complete dialog available for immediate turn in and if so will watch quest or quests (2025.09.17)

	EventManager.lua
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE:ToggleFramesAndTracker() functions and VARIABLES_LOADED, QUEST_REMOVED and QUEST_TURNED_IN event functions (2025.09.15)
		- Added coding calls for RQE.WPUtil.ClearHotspotState() to be either hard (true) or soft (false) resets for the visitRadius and unlocked priorityBias (2025.09.15)
		- Removed RQE.WPUtil.ClearHotspotState() function call within QUEST_LOG_CHANGE and placed in SUPER_TRACKING_CHANGED and QUEST_WATCH_LIST_CHANGED as soft resets (2025.09.15)
		- Fixes to better update the scenario/dungeon/mythic frame when leaving an instance (UPDATE_INSTANCE_INFO) or on ZONE_CHANGED, ZONE_CHANGED_NEW_AREA, QUEST_WATCH_LIST_CHANGED (2025.09.16)
		- Added function call to PLAYER_ENTERING_WORLD to watch any quests, not currently watched, that can be immediately turned in (2025.09.17)
		- Fixed issue with hs.mapID being invalid if hs.continentID was used in coordinateHotspots (2025.10.02)

	QuestingModule.lua
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in UpdateRQEQuestFrame() function, after QuestLogIndexButton is pressed. (2025.09.15)
		- Added 'return' to button clicks within RQE.bonusQuestLabel:SetScript("OnMouseDown"... and UpdateRQEQuestFrame() function (2025.09.17)
		- Modified colorizeObjectives to use hex color helpers, in Core.lua (2025.09.17)

	RQE.toc
		- Updated version# (2025.09.15)
		- Added HereBeDragons to the list of libraries for distance calculation (2025.09.15)

	RQEDatabase.lua
		- Added coordinateHotspots in place of coordinates in questID 84776: "A Call to Delves" due to the multiple locations for delves, but only in Isle of Dorn, for now (2025.09.15)
		- Updated questID 90705: "Lorewalking" description to better describe the alternate turn-in locations (2025.09.15)
		- Updated and finished testing questID 52: "Protect the Frontier" with coordinateHotspots and priorityBias functional (2025.09.15)
		- Added additional fixes and updates to the DB which include more of the coordinateHotspots to be used with multiple waypoints for a single objective (2025.09.16)
		- Updated description and macros that used the old 'RQE:BlizzObjectiveTracker()' method to hide the tracker for blizzard tracker to come up for auto-complete quests as this functionality is now part of add-on. (2025.09.17)

	RQEFrame.lua
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE:CreateStepsText(StepsText, CoordsText, MapIDs) function. (2025.09.15)
		- Fixed nil error within waypointText of WaypointButton:SetScript("OnClick", function() within the larger RQE:CreateStepsText() function (2025.09.15)
		- Added 'return' to button clicks within RQE.QuestIDText:SetScript("OnMouseDown"... and RQE.QuestNameText:SetScript("OnMouseDown"... (2025.09.17)
		- RQEFrame quest tooltip now uses the RQE.colorizeObjective function (2025.09.17)

	RQEMinimap.lua
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE.ToggleBothFramesfromLDB() function. (2025.09.15)

	WaypointManager.lua
		- Updated RQE:CreateWaypoint(x, y, mapID, title) function to generate waypoints correctly when dealing with same mapID for coordinateHotspots and commented out the code to generate map pin (2025.09.15)
		- Many examples of 'TomTom:AddWaypoint' being replaced with the RQE.Waypoints:Replace() function call in WPUtil (2025.09.15)
		- Set 'RQE._currentTomTomUID' to nil after TomTom.waydb:ResetProfile() in RQE:CreateUnknownQuestWaypointWithDirectionText(), RQE:CreateUnknownQuestWaypointNoDirectionText() and RQE:CreateUnknownQuestWaypointForEvent(), and RQE:CreateWaypointForStep() functions (2025.09.15)

	WPUtil.lua
		- Added RQE.Waypoints = RQE.Waypoints or {} to list of addon tables (2025.09.15)
		- Added RQE.Waypoints:Replace(mapID, xNorm, yNorm, title) function for replacing waypoints when new waypoints for a supertracked quest are closer (2025.09.15)
		- Added _playerDistanceSqFlexible(hmap, hx, hy) helper to determine squared distance, in yards, to nearest coordinate block (2025.09.15)
		- Significant updates to RQE.WPUtil.SelectBestHotspot(questID, stepIndex, step) function to better handle when coordinateHotspots are on the same mapID as player (2025.09.15)
		- Added temporary RQE:MaybeUpdateWaypointOnSnap(elapsed) function, which after initial testing failed to live up to expectations and was replaced, but keeping this dead function in place, for now (2025.09.15)
		- Added HereBeDragons and local variables to the top of file (2025.09.15)
		- Added RQE.WPUtil.DebugDumpBands for debug langauge on distance to the priorityBias bands within the coordinateHotspots (2025.09.15)
		- Added _fmtHotspot and _dbgMarkVisited to flag when a priorityBias has been unlocked following visitedRadius being reached for previous priorityBias (2025.09.15)
		- Added _dbgEligibleBands and updated _eligibleBands functions to list which priorityBias has been unlocked for waypoint creation (2025.09.15)
		- Added  _getHBD(), _zoneDeltaYards and RQE.WPUtil.DeltaYards to calculate the distance to waypoint associated with the coordinateHotspot used (2025.09.15)
		- Updated RQE.WPUtil.NormalizeCoordinates() as well as _updateVisitedBands to update band unlock (2025.09.15)
		- Updated RQE.WPUtil.SelectBestHotspot() and RQE.WPUtil.ClearHotspotState() functions to better handle the priorityBias and visitedRadius in the DB entries while continuing to work with 'coordinates' (2025.09.15)
		- Added SlashCmdList.RQEDUMP = function() to call debug print out of distance and information on which bands are unlocked (2025.09.15)


11.2.0.4 (2025.09.15)

	**HIGHLIGHTS**
		- Better handling of waypoint creation when waypointText exists directing player to a portal or other transition method between zones (2025.09.12)
		- When quest was complete waypoint wouldn't be created unless player was already in correct zone, but now will provide better waypoint direction to quest turn in when zone transitions/portals exist (2025.09.13)
		- Added variable checks of RQE.DontPrintTransitionBits to ensure that text wasn't excessively/unintentionally printing for transition direction (2025.09.13)
		- Drop-down option exists for player to get directions to closest flight master, but enableTravelSuggestions must be enabled in the configuration settings (2025.09.13)
		- Quest Objectives truncated for better visibility of quest objective step and addon's stepText guidance (2025.09.14)
		- Added new feature to direct player to best coordinates when dealing with multiple quest blobs/turn-in locations for a given quest step (2025.09.15)

	Buttons.lua
		- Fixed nil error of missing RQE.AddonSetStepIndex within RQE.UnknownButtonTooltip = function() and nil check for RQE.WPxPos (2025.09.13)
		- Fixed issue where waypoint was disappearing when mousing over "W" button in RQEFrame when waypointText existed for quest either in or not in DB (2025.09.13)
		- Removed RQE:StartPeriodicChecks() function call within RQE.UnknownButtonTooltip to improve addon performance (2025.09.13)
		- Updated RQE.UnknownButtonTooltip = function() so that coordinates and coordinateHotspots are assessed in determining coordText in the array (2025.09.15)

	Core.lua
		- Updated RQE:StartPeriodicChecks() function to better handle situations with waypointText and CheckDBZoneChange scenarios (2025.09.12)
		- Updated RQE:GetClosestFlightMaster() function to only check the Alliance/Neutral or Horde/Neutral flight paths based on current faction info for taxi suggestion (2025.09.12)
		- Added RQE:FindQuestZoneTransition() function to handle when waypointText exists and points to location other than current step's (see RQE:StartPeriodicChecks() changes) waypoint information (2025.09.12)
		- Added check for waypointText to RQE.CheckAndClickWButton() function and if waypointText exists it will no longer call RQE.CheckAndClickSeparateWaypointButtonButton() function (2025.09.13)
		- Added RQE.getQuestData to the RQE:CheckAndCreateSuperTrackedQuestWaypoint() function (2025.09.13)
		- Modified RQE:StartPeriodicChecks() function to only run the self:ClickWaypointButtonForIndex(finalStepIndex), with quest ready for turn in if there is no waypointText (2025.09.13)
		- Added RQE:AskSetWaypointToClosestFlightMaster() and RQE:SetTomTomWaypointToClosestFlightMaster() functions to provide a pop-up asking player if they want directions to closest flight master (2025.09.13)
		- Modified RQE:GetClosestTrackedQuest(), PrintQuestStepsToChat(questID), RQE:FindQuestZoneTransition(questID) and RQE:GetClosestFlightMasterToQuest(questID) to work with 'coordinates' and 'coordinateHotspots' (2025.09.15)

	EventManager.lua
		- After firing of ZONE_CHANGED_NEW_AREA event function will run the RQE:FindQuestZoneTransition() function to find correct location to place waypoint for next step (2025.09.12)
		- Cleaned up debug language within the ZONE_CHANGED_NEW_AREA event function (2025.09.12)
		- Added call to RQE:FindQuestZoneTransition() function within PLAYER_CONTROL_GAINED event function to check for waypointText for next step upon landing from Taxi (2025.09.13)
		- Added PLAYER_CONTROL_LOST event function to include when waypoints could be created once again following landing from Taxi (2025.09.13)
		- Added helper calls for clearing and adding hotspot coordinate information for updating code prior to creating waypoint on PLAYER_ENTERING_WORLD, ZONE_CHANGED, ZONE_CHANGED_NEW_AREA, QUEST_LOG_UPDATE (2025.09.15)
		- Modified code for QUEST_WATCH_UPDATE to obtain coordinate information when dealing with coordinateHotspots (2025.09.15)

	QuestingModule.lua
		- Cleaned up debug language within the clicking of the QuestLogIndexButton inside the RQEQuestFrame (2025.09.12)
		- Modified the print out following clicking of QuestLogIndexButton to check if enableTravelSuggestions is enabled before running the RQE:RecommendFastestTravelMethod() function (2025.09.12)
		- Added drop-down menu option to RQE Quest Frame to call RQE:SetTomTomWaypointToClosestFlightMaster() function (2025.09.13)

	RQE.toc
		- Updated version# (2025.09.08)

	RQEDatabase.lua
		- Added some Delve quests for The War Within expansion (2025.09.13)
		- Added a few WQ for Legion/Battle for Azeroth and some additional quests in The War Within (2025.09.14)
		- Added coordinateHotspots in place of coordinates in questID 90705: "Lorewalking" due to the multiple turn-in locations which include Stormwind, Orgrimmar and Dornogal (2025.09.15)

	RQEFrame.lua
		- Commented out the RQE:ClickWaypointButtonForNextObjectiveIndex(nextObjectiveIndex, questData) function as this is no longer used (2025.09.12)
		- Modified the RQE.ClickUnknownQuestButton() function for better handling of waypoint creation when waypointText exists (2025.09.12)
		- Removed the RQE:CreateUnknownQuestWaypoint() function call within RQE.ClickUnknownQuestButton() as this now first calls RQE:FindQuestZoneTransition(), which then does waypoint creation (2025.09.12)
		- Added drop-down menu option to RQEFrame to call RQE:SetTomTomWaypointToClosestFlightMaster() function (2025.09.13)
		- Added validation check to see if waypointText exists within the RQE:CreateStepsText(StepsText, CoordsText, MapIDs) function and if not it will C_Map.ClearUserWaypoint() (2025.09.13)
		- Simplified the RQE.ClickUnknownQuestButton() function by removing unnecessary code (2025.09.13)
		- Quest Objectives are truncated (limit to one paragraph and also truncated to limit to set number of characters) so that objective steps and addon's step guidance is better able to be displayed (2025.09.14)
		- Modified the RQE.GetTooltipDataForCButton() function so that tooltip of coordText is correct when hovering over the "*" button in that frame for 'coordinates' and 'coordinateHotspots' (2025.09.15)

	WaypointManager.lua
		- Within the RQE:CreateUnknownQuestWaypoint() function a call is made to RQE:FindQuestZoneTransition() instead of the RQE:CreateUnknownQuestWaypointWithDirectionText() function (2025.09.12)
		- Mostly rewrite of RQE:CreateUnknownQuestWaypointWithDirectionText() to handle waypoint creation when waypointText exists (2025.09.12)
		- Added RQE.NearestFlightMasterSet variable check within functions that create waypoints to ensure that waypoint isn't overridden when player is seeking direction to nearest flight master (2025.09.13)
		- Fixed RQE:CreateUnknownQuestWaypointWithDirectionText(questID, mapID) function as waypoint wasn't being created when flagged C_QuestLog.ReadyForTurnIn() and had waypointText (2025.09.13)
		- Cleaned up waypointTitle so that more information would be shown and now also when waypointText exists will include this information in the waypointTitle (2025.09.13)
		- Fixed waypoint creation in RQE:CreateWaypoint(), RQE:CreateWaypoint(), and RQE:CreateWaypointForStep() functions to work with 'coordinates' and 'coordinateHotspots' array (2025.09.15)

	WPUtil.lua
		- Added RQE.WPUtil and RQE.WPUtil._hotspotState tables (2025.09.15)
		- Added coordinateHotspot Defaults (2025.09.15)
		- Modified RQE:GetStepCoordinates(stepIndex) function to work with either 'coordinates' or 'coordinateHotspots' (2025.09.15)
		- Added helpers to deal with 'coordinateHotspots' functionality (2025.09.15)


11.2.0.3 (2025.09.08)
		
	**HIGHLIGHTS**
		- Adjusted placement of the ObjectiveTrackerFrame to conform with the default location of the RQEQuestFrame (2025.08.23)
		- Added GARRISON_MISSION_COMPLETE_RESPONSE event function with updates to the RQEFrame and RQEQuestFrame (2025.08.23)
		- Added enableMouseOverMarking and enableTravelSuggestions to configuration options (2025.09.08)
		- Added function that checks to see if target has correct raid marker following press of RQE Macro button, and marks target if it doesn't (2025.09.08)
		- Adjusted when and how raid markers clear when pressing RQE Macro button as this was previously resulting in raid marker clearing due to raid marker already being applied on mouseover and target acquisition before mark would've been applied (2025.09.08)

	Config.lua
		- Added enableMouseOverMarking and enableTravelSuggestions options to configuration (2025.09.08)

	Core.lua
		- Fixed error when running the RQE:ConfirmAndPurchaseCommodity(itemID, quantity) function for purchasing an item from the auction house via RQE magic macro button (2025.08.14)
		- Added additional debug info for Saving/Restoring Tracked quests for character (2025.08.22)
		- Adjustment to debug print messages within the RQE:RecommendFastestTravelMethod(questID) function (2025.08.22)
		- Adjusted placement of the ObjectiveTrackerFrame to conform with the default location of the RQEQuestFrame (2025.08.23)
		- Added enableMouseOverMarking and enableTravelSuggestions options to local defaults (2025.09.08)
		- Added helper function to see if quest was being searched/tracked/watched (2025.09.08)
		- Added function that checks to see if target has correct raid marker following press of RQE Macro button, and marks target if it doesn't (2025.09.08)

	EventManager.lua
		- Additional fixes for the scenario frame remaining with completed objectives even after the conclusion of the scenario (2025.08.14)
		- Added RQE.UpdateScenarioFrame() function call to SCENARIO_CRITERIA_UPDATE event function (2025.08.19)
		- Added MINIMAP_UPDATE_ZOOM with proper handle for the CheckDBZoneChange with the MINIMAP_UPDATE_ZOOM event function and created PLAYER_MAP_CHANGED event function (2025.08.23)
		- Added GARRISON_MISSION_COMPLETE_RESPONSE event function with updates to the RQEFrame and RQEQuestFrame (2025.08.23)
		- Update to BAG_UPDATE event function to update RQEQuestFrame (2025.08.23)
		- Added RQE:StartPeriodicChecks() function call to within QUEST_WATCH_LIST_CHANGED, but may remove later (2025.08.28)
		- Added RQE.UpdateScenarioFrame() and RQE.updateScenarioUI() for scenario frame updates to the QUEST_WATCH_LIST_CHANGED event function (2025.08.29)
		- Enabled QUEST_CURRENCY_LOOT_RECEIVED event function (2025.09.08)
		- After GOSSIP_CLOSED fires will only clear the raid marker from target if it has the circle or "2" for the raid marker idx as this corresponds to the gossip choices fired from the RQE Macro button press (2025.09.08)
		- After the firing of ZONE_CHANGE and ZONE_CHANGED_NEW_AREA an update to the scenario frame is fired (2025.09.08)
		- Clears the raid marker on target if quest is no longer being tracked/watched when QUEST_CURRENCY_LOOT_RECEIVED or QUEST_LOOT_RECEIVED event functions fire (2025.09.08)
		- Commented out the code to save event info when QUEST_CURRENCY_LOOT_RECEIVED or QUEST_LOOT_RECEIVED event functions fire (2025.09.08)
		- Removed clearing of raid marker from target when QUEST_FINISHED event function fires as this was clearing the raid marker at an incorrect time (2025.09.08)

	QuestingModule.lua
		- Added additional nil checks within the RQE.UpdateScenarioFrame() function as well as a call to update the RQEQuestFrame (2025.08.15)
		- Removed the RQE.UpdateScenarioFrame() function call when updating the RQE Quest Frame as this was causing increased lag (2025.09.08)

	RQE.toc
		- Updated Interface# and version# (2025.08.14)

	RQEDatabase.lua
		- Added a few profession quests in the K'aresh zone (2025.08.14)
		- Updated info for questID 85949 in the DB (2025.08.15)
		- Added several Legion class order hall quests to the DB (2025.08.18)
		- Added intro to additional Legion class order hall for Druid, Priest, Rogue and Monk to the DB (2025.08.19)
		- Updated K'aresh campaign quests for raid story mode in DB (2025.08.19)
		- Added most of the Warlock class order hall quests to DB (2025.08.20)
		- Added additional class order hall quests to DB (2025.08.22)
		- Updated to Elwynn Forest quest DB (2025.08.23)
		- Updates to world quests in Legion (2025.08.23)
		- Added Eastern Kingdoms Cup courses, some Dragonflight profession quests, and world quests to DB (2025.08.28)
		- Added additional delve and WQ to the quest DB (2025.08.29)
		- Adjusted macros so that a check is carried out of the target before actually applying/improper clearing of marker from target (2025.09.08)

	RQEMacro.lua
		- Enabled the macro creation for setting a raid marker on target if quest is being searched due to the player not having the quest and needing directions for quest pickup (2025.09.08)


11.2.0.2 (2025.08.12)

	**HIGHLIGHTS**
		- Fixed several campaign quests in chapters 1 thru 3 of the K'aresh campaign (2025.08.11)
		- Completed chapter 4 of K'aresh campaign quests in DB for player access (2025.08.12)

	EventManager.lua
		- Update Scenario Frame after a brief delay following a zone change (2025.08.11)

	QuestingModule.lua
		- Fix for scenario frame continuing to exist after scenario is finished (2025.08.09)

	RQE.toc
		- Updated Interface# and version# (2025.08.08)

	RQEDatabase.lua
		- Added/updated world quests in the K'aresh zone (2025.08.09)
		- Fixed several campaign quests in chapters 1 thru 3 of the K'aresh campaign (2025.08.11)
		- Completed chapter 4 of K'aresh campaign quests in DB for player access (2025.08.12)


11.2.0.1 (2025.08.08)

	**HIGHLIGHTS**
		- Fixes to missing definitions with Core, EventManager and RQEMacro that were missing/listed incorrectly (2025.08.08)
		- Completed chapter 3 of K'aresh campaign quests in DB for player access (2025.08.08)

	Core.lua
		- Updated UnitBuff to C_UnitAuras.GetBuffDataByIndex within the RQE.getCurrentBuffs() function (2025.08.08)

	EventManager.lua
		- Updated onTaxi to be OnTaxi for uniformity and added definitions that were missing in functions within the events (2025.08.08)
		- Added currentMinimapZone definition to handleZoneChange (2025.08.08)
		- Added mythicMode definition to updateScenarioUI() (2025.08.08)

	RQE.toc
		- Updated Interface# and version# (2025.08.06)

	RQEDatabase.lua
		- Completed chapter 3 of K'aresh campaign quests in DB for player access (2025.08.08)

	RQEMacro.lua
		- Fixed debugLog definition to be RQE.db.profile.debugLevel within RQEMacro:UpdateMagicButtonTooltip() function (2025.08.08)


11.2.0.0 (2025.08.06)

	**HIGHLIGHTS**
		- Completed chapter 1 and 2 of K'aresh campaign quests in DB for player access (2025.08.06)

	RQE.toc
		- Updated Interface# and version# (2025.08.05)

	RQEDatabase.lua
		- Completed chapter 1 and 2 of K'aresh campaign quests in DB for player access (2025.08.06)


11.1.5.4 (2025.08.04)

	**HIGHLIGHTS**
		- Added Wrath of the Lich King and Battle for Azeroth (Horde) quests to DB (2025.06.14)
		- Added Mists of Pandaria (Horde) quests to DB (2025.07.13)
		- Added Rise of the Red Dawn quests to DB (2025.07.13)
		- Added chapters 4 of 5 on the 11.2 K'aresh campaign quests to DB, but only the preliminary data is within the DB (2025.07.16)
		- Fixed issue with ClearPoints in VARIABLES_LOADED that was preventing RQEFrame from displaying in patch 11.2 (2025.07.13)
		- Fixed issue with ClearAllPoints() within QUEST_WATCH_UPDATE and QUEST_WATCH_UPDATE event functions as it was invalidating frame in 11.2 (2025.07.14)
		- Added Suramar and Argus campaign quests to DB (2025.07.19)

	Core.lua
		- Removed RQE.GetDataForAddon() duplicate function (2025.06.16)
		- Added questID 27779 "Gnomebliteration" stepIndex 1 to the blacklist for improvement (2025.07.03)
		- Fixed RQE:SearchPreparePurchaseConfirmAH that prevented auction purchase macro from purchasing if player had TSM loaded (2025.07.15)

	EventManager.lua
		- Added arg info for UNIT_AURA event function (2025.06.06)
		- Added arg info for OBJECT_ENTERED_AOI and OBJECT_LEFT_AOI event functions (2025.06.08)
		- Fixed issue with ClearPoints in VARIABLES_LOADED that was preventing RQEFrame from displaying in patch 11.2 (2025.07.13)
		- Fixed issue with ClearAllPoints() within QUEST_WATCH_UPDATE and QUEST_WATCH_UPDATE event functions as it was invalidating frame in 11.2 (2025.07.14)
		- Added separate section for UNIT_EXITING_VEHICLE to include function that checks quest progress status (2025.08.04)

	RQE.toc
		- Updated Interface# and version# (2025.06.03)

	RQEDatabase.lua
		- Added remainder of Dragonblight (Horde/Neutral) quests to DB (2025.06.06)
		- Added Grizzly Hills, Storm Peaks and Icecrown (Horde/Neutral) quests to DB (2025.06.06)
		- Added Stormheim (Horde/Neutral) quests to DB (2025.06.06)
		- Added Zuldazar (Horde/Neutral) quests for DB (2025.06.08)
		- Added Nazmir (Horde/Neutral) quests to DB (2025.06.09)
		- Added Vul'dun, start of Nazjatar (Horde) and War Campaign (Horde) quests to DB (2025.06.14)
		- Added Tirisfal Glades, Silverpine Forest, Hillsbrad Foothills, Hinterlands, Western Plaguelands, Burning Steppes, Swamp of Sorrows, Blasted Lands, Badlands, and Arathi Highlands (Horde) quests to DB (2025.06.16)
		- Added Northern Stranglethorn (Horde/Neutral) quests to DB (2025.06.18)
		- Added Cape of Stranglethorn, Northern Barrens, and Durotar (Horde/Neutral) quests to DB (2025.06.19)
		- Added Ashenvale, Southern Barrens, Dustwallow Marsh, and Stonetalon Mountains (Horde/Neutral) quests to DB (2025.06.21)
		- Added Alliance quests for Midsummer Festival (Honor the Flame/Desecrate this Fire) quests to DB (2025.06.23)
		- Added Legion Anduin Wrynn questline to DB (2025.06.23)
		- Added Thousand Needles and Desolace (Horde/Neutral) quests to DB (2025.06.23)
		- Added Feralas (Horde/Neutral) quests to DB (2025.06.25)
		- Added Horde quests for Midsummer Festival (Honor the Flame/Desecrate this Fire) quests to DB (2025.06.25)
		- Added Azshara, Mulgore and Felwood (Horde/Neutral) quests to DB (2025.06.27)
		- Added Mount Hyjal and Vashj'ir (Horde/Neutral) quests to DB (2025.06.28)
		- Added Deepholm (Horde/Neutral) quests to DB (2025.06.29)
		- Added Uldum (Horde/Neutral) quests to DB (2025.07.01)
		- Added Twilight Highlands (Horde/Neutral) quests to DB (2025.07.03)
		- Added The Jade Forest (Horde/Neutral) quests to DB (2025.07.05)
		- Added Valley of the Four Winds (Horde/Neutral) quests to DB (2025.07.10)
		- Added Krasarang Wilds and Kun-lai Summit (Horde/Neutral) quests to DB (2025.07.11)
		- Added Townlong Steppes (Horde/Neutral) quests to DB (2025.07.12)
		- Added Rise of the Red Dawn quests to DB (2025.07.13)
		- Added Dread Wastes (Horde/Neutral) quests to DB (2025.07.13)
		- Added additional side quests for K'aresh to the DB (2025.07.14)
		- Added chapters 4 of 5 on the 11.2 K'aresh campaign quests to DB (2025.07.16)
		- Added Suramar and Argus campaign quests to DB (2025.07.19)
		- Added some Warrior, Hunter, Warlock class quests, from Legion expansion, to DB (2025.07.21)
		- Removed thousands of duplicate quests, mostly from Legion expansion, from the DB (2025.07.22)
		- Added more Warrior, Hunter, Warlock, Death Knight, Demon Hunter, Paladin Legion class order hall quests to DB (2025.07.26)
		- Added some Monk, Mage, and Rogue Legion class order hall quests to DB (2025.07.27)
		- Added additional Legion class order hall quests and updated Cataclysm quest details in DB (2025.08.04)

	RQEMacro.lua
		- Added 'Weaken' to list of macro icons for the RQE Button (2025.07.03)
		- Modified macro information to include option for "Collect" (2025.07.10)
		- Added details to denote the correct tooltip iconID for escort quests (2025.07.13)
		- Modified macro information to include option for "Interact" (2025.07.21)


11.1.5.3 (2025.06.03)

	**HIGHLIGHTS**
		- Search function, within RQE addon, now also includes ability to search through description or objectives in the DB, and also includes clickable custom tooltip for when player is not on the searched quest (2025.05.12)
		- Added RQE:MarkQuestMobOnMouseover() function for the purpose of setting raid marker on mouseover/target of specific mob(s) in DB for the supertracked quest (2025.05.18)
		- Set small delay following PLAYER_ENTERING_WORLD before UpdateRQEQuestFrame() fires as the RQEQuestFrame wasn't updating the quest objectives reliably (2025.05.18)
		- Added suggestedSize and levelText to include suggested group size for a quest within the questLevel brackets if it recommends a group to complete quest (2025.05.18)

	Core.lua
		- Can now use search function to search quest description or quest objectives, in addition to the already existing questID and/or questName (2025.05.12)
		- Added custom tooltip functionality for searched quests so player can see the description and objectives when clicking the questName following a search (2025.05.12)
		- Added & Removed RQE:CraftRecipeSmart(spellID, quantity) as this is a feature that won't work to craft a number of items based on objective status as the C_TradeSkillUI.CraftRecipe API is restricted (2025.05.14)
		- Added RQE:MarkQuestMobOnMouseover() function for the purpose of setting raid marker on mouseover/target of specific mob(s) in DB for the supertracked quest (2025.05.18)
		- Fixed RQE.ObtainSuperTrackQuestDetails() function that was causing nil error when RQEFrame was hidden at times (2025.05.18)
		- Fixed RQE:MarkQuestMobOnMouseover() function to better handle stepIndex by using RQE.AddonSetStepIndex of the supertracked quest (2025.05.18)
		- Added WQ Fetcher for WoD [author-only] (2025.05.24)
		- Modified fetcher for npc name for missing bits in DB [author-only] (2025.05.25)
		- Fixed issue where RQEFrame was coming up intermittently when enableFrame was unchecked (2025.05.25)
		- Fixed taint as it relates to the addon clicking the quest log index button in certain circumstances, now has an InCombat check (2025.05.25)
		- Modified search function to also include searching step descriptions (2025.05.27)
		- Modified TryMarkUnit(unitID, mobList) function to mark an already existing target/mouseover if it should be marked something else, but ignore re-marking if the correct mark already exists on target/mouseover (2025.06.01)
		- Fixed nil error within RQE:GetClosestTrackedQuest() function (2025.06.03)

	EventManager.lua
		- Added some debug and comment lines (2025.05.12)
		- Added UpdateRQEQuestFrame when SCENARIO_COMPLETED event function fires or PLAYER_STARTED_MOVING, as long as player is mounted (2025.05.12)
		- Added PLAYER_TARGET_CHANGED and UPDATE_MOUSEOVER_UNIT event functions that call RQE:MarkQuestMobOnMouseover() when fired (2025.05.18)
		- Set small delay following PLAYER_ENTERING_WORLD before UpdateRQEQuestFrame() fires as the RQEQuestFrame wasn't updating the quest objectives reliably (2025.05.18)
		- Enabled RQE:AutoSuperTrackClosestQuest() in the QUEST_ACCEPTED event function (2025.05.24)
		- Enabled RQE.CheckAndClickWButton() in handleZoneChange event set functions (2025.05.24)
		- Moved isLogin and isReload code within PLAYER_ENTERING_WORLD event function further up in the function (2025.05.27)
		- Added UpdateRQEQuestFrame() to UPDATE_INSTANCE_INFO event function and removed it from PLAYER_ENTERING_WORLD event function (2025.05.27)

	QuestingModule.lua
		- Added suggestedSize and levelText to include suggested group size for a quest within the questLevel brackets if it recommends a group to complete quest (2025.05.18)

	RQE.toc
		- Updated Interface# and version# (2025.05.12)

	RQEDatabase.lua
		- Added additional WQ and description/objectives text to the DB (2025.05.12)
		- Added TBC Hellfire Peninsula Horde quests to the DB (2025.05.14)
		- Added TBC Zangarmarsh, Nagrand, Blade's Edge Mountain and some Shadowmoon Valley Horde quests to the DB (2025.05.16)
		- Added TBC Shadowmoon Valley Horde and some Netherstorm Scryer quests to the DB (2025.05.18)
		- Added some Warlords of Draenor (Tanaan Intro & Frostfire Ridge) and Legion (Horde) quests to DB (2025.05.19)
		- Added Gorgrond and Taladar Horde quests to DB (2025.05.24)
		- Added Spires of Arak and Nagrand and some Eversong Horde quests to DB (2025.05.25)
		- Added Ghostlands and Howling Fjord (Horde) quests to DB (2025.06.01)
		- Added Borean Tundra and some Dragonblight (Horde/Neutral) quests to DB (2025.06.03)

	RQEMacro.lua
		- Removed (commented out) code to set raid marker on target for searched quest as this is instead being handled through the RQE:MarkQuestMobOnMouseover() function (2025.05.18)


11.1.5.2 (2025.05.10)

	**HIGHLIGHTS**
		- Fixed issue where RQEQuestFrame (quest tracker frame) wouldn't update following a scenario and sometimes not update when a quest should be flagged as complete (2025.05.07)

	EventManager.lua
		- Added UpdateRQEQuestFrame(), following brief delay within UNIT_QUEST_LOG_CHANGED and QUEST_WATCH_UPDATE functions (2025.05.07)
		- Enabled the firing of RQE:AutoSuperTrackClosestQuest() when PLAYER_MOUNT_DISPLAY_CHANGED and if player is going from not mounted to mounted (2025.05.10)
		- Added the calling of UpdateRQEQuestFrame() when SCENARIO_COMPLETED and SCENARIO_UPDATE events fire as well as when the RQE.updateScenarioUI() function is called (2025.05.10)
		- Removed the firing of UpdateRQEQuestFrame() and UpdateRQEWorldQuestFrame() functions when QUEST_LOG_UPDATE occurs as this results in intermittent lag spikes (2025.05.10)

	RQE.toc
		- Updated Interface# and version# (2025.05.07)

	RQEDatabase.lua
		- Added additional War Within quests to DB (2025.05.07)


11.1.5.1 (2025.05.07)

	**HIGHLIGHTS**
		- Fix taint related to the clicking of the QuestLogIndexButton in the RQEQuestFrame (2025.04.21)
		- Improved performance related to the checking of the RQEFrame visibility (2025.04.21)
		- Prints questText (descriptionQuestText) and objectivesQuestText in the custom quest tooltip following a print-out on the questline of the specified quest (2025.04.21)
		- Added coding to watch/track quests when rapidly accepted, as this would previously only track a few of the quests (2025.04.26)
		- New Feature: Mythic/Scenario Mode allows the display of the default blizzard tracker when player is in scenario [off by default] allowing player to see countdown timers associated with scenario stages (2025.04.28)
		- Major performance fixes for inefficient code and their firing too often, especially following combat ending (2025.05.07)

	Config.lua
		- Added mythicScenarioMode option to the configuration panels (2025.04.28)
		- Updated enableQuestFrame to immediately run RQE:UpdateTrackerVisibility() instead of RQE:ToggleRQEQuestFrame() when box is checked/unchecked (2025.04.29)

	Core.lua
		- Modified RQE.ObtainSuperTrackQuestDetails() to use the supertrackedquestID if the RQEFrame is not visible when obtaining debug information (2025.04.20)
		- Modified RQE:ShowCustomQuestTooltip(questID) to include the descriptionQuestText and objectivesQuestText, if available, and place in custom quest tooltip when clicking on a quest printed to chat following PrintQuestlineDetails (2025.04.21)
		- Recognizes "x" for the quantity when running/calling RQE:SearchPreparePurchaseConfirmAH(itemID, quantity) function as this will check how many are needed by looking at required and fulfilled quantity for the objective (2025.04.22)
		- Initialized RQE.DelayedQuestWatchCheck() for the purpose of watching quests that are rapidly accepted from an NPC (2025.04.26)
		- Added function to display current visibility of the RQEQuestFrame for new Mythic/Scenario mode (2025.04.28)
		- Fixed track closest watched quest on player movement based on proximity due to change Blizzard made with the release of patch 11.1.5 (2025.04.28)
		- Set mythicScenarioMode to true for local defaults (2025.04.29)
		- Updated RQE:UpdateTrackerVisibility() to include a compatibility fix for Carbonite Quests and ability to hide the RQEQuestFrame by clicking the close button or unchecking the box in the configuration panel (2025.04.29)
		- Added some debug prints within RQE:ToggleRQEQuestFrame() function (2025.04.29)
		- Added failsafe to RQE:UpdateTrackerVisibility() to check to make sure that the player has selected mythicMode before continuing (2025.04.30)
		- Added check to see if player was OnTaxi within the RQE:AutoSuperTrackClosestQuest() and 'returns' if this is the case to minimize lag on taxi (2025.04.30)
		- Added RQE:GetClosestFlightMaster(), RQE:GetClosestFlightMasterToCoords(mapID, targetX, targetY), RQE:GetClosestFlightMasterToQuest(questID), RQE:RecommendFastestTravelMethod(questID), RQE:GetDistance(mapID1, x1, y1, mapID2, x2, y2), and RQE:EstimatePlayerSpeed(sampleTime) for future editions for adding waypoint travel to flight masters if this is closer than flying/walking (2025.04.30)
		- Modified return check within RQE:UpdateTrackerVisibility() function to check if 'InCombatLockdown' AND 'inScenario' (2025.05.03)
		- Fixed 'Carbonite Quests' to be 'Carbonite Quest' within the RQE:UpdateTrackerVisibility() function (2025.05.03)
		- Commented out UpdateRQEQuestFrame() within the RQE:UpdateTrackerVisibility() function to minimize lag when this function fires as this update isn't required with every update event (2025.05.03)
		- Fixed macro check not firing with the RQE:StartPerdiodicChecks() function (2025.05.04)
		- Tweaked the handling of RQE:AutoSuperTrackClosestQuest() - but is broken now since removing QUEST_WATCH_LIST_CHANGED (2025.05.04)
		- Disabled the loading of several ObjectiveTracker bits within the RQE:UpdateTrackerVisibility() function (2025.05.06)
		- Fixed RQE:GetClosestTrackedQuest() and RQE:AutoSuperTrackClosestQuest() functions to integrate into the coordinates within the DB in assisting to determine closest quest and then supertracking it (2025.05.06)
		- Removed/edited debug messages and inefficient code (2025.05.07)

	EventManager.lua
		- Updated ArgPayload to only need debugMode Info instead of Info+ AND the specific event function chosen [ie RQE.db.profile.showEventAchievementEarned] (2025.04.21)
		- Removed RQE:CheckFrameVisibility from PLAYER_REGEN_ENABLED event function and ZONE_CHANGED_NEW_AREA, and modified that it be allowed to fire when PLAYER_STARTED_MOVING has fired (2025.04.21)
		- Check if ClickQuestLogIndexButton function attempted to run while in combat and if so to re-run it for the last quest it attempted to run with (2025.04.21)
		- Added ArgPayload to QUEST_ACCEPTED event function (2025.04.20)
		- Added coding to watch/track quests when rapidly accepted, as this would previously only track a few of the quests (2025.04.26)
		- Added InCombatLockdown() prior to ClearAllPoints from RQEFrame and RQEQuestFrame after QUEST_WATCH_UPDATE event fires (2025.04.26)
		- Modified the coding to display/hide the objective tracker based on new Mythic/Scenario mode (2025.04.28)
		- Removed RQE:AutoSuperTrackClosestQuest() from PLAYER_REGEN_ENABLED and PLAYER_MOUNT_DISPLAY_CHANGED event functions as this was causing a performance/CPU loss when run (2025.04.30)
		- Updated code within the PLAYER_REGEN_ENABLED to only update the scenarioUI if mythicMode is turned off to reduce redundancy. (2025.05.03)
		- Removed ClearAllPoints within PLAYER_REGEN_ENABLED, QUEST_COMPLETE and QUEST_REMOVED (2025.05.03)
		- Updated PLAYER_MOUNT_DISPLAY_CHANGED to reduce firings in order to improve add-on performance (2025.05.03)
		- Adjusted timed delays (2025.05.04)
		- Added macro check within PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED event (2025.05.04)
		- Moved UpdateRQEQuestFrame/UpdateCampaignFrameAnchor functions outside of RQE.updateScenarioUI (2025.05.04)
		- Performance improvements to PLAYER_STOPPED_MOVING, QUEST_ACCEPTED, ZONE_CHANGED... events (2025.05.04)
		- Added debug messages to file (2025.05.04)
		- Modified call to UpdateRQEQuestFrame to instead use RQE:QuestType when QUEST_ACCEPTED fires in order to handle world quests (2025.05.04)
		- Major update to QUEST_WATCH_LIST_CHANGED event function to clean up order and improve performance. It will only handle the bulk of the updates if following UNIT_QUEST_LOG_CHANGED fires and only the one time (2025.05.04)
		- Removed QUEST_WATCH_LIST_CHANGED event function from being listened to in order to further increase addon performance (2025.05.04)
		- Updated PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED event function (2025.05.04)
		- Enabled, once again, the QUEST_WATCH_LIST_CHANGED event function (2025.05.06)
		- Improved performance in the modification of the PLAYER_REGEN_ENABLED, PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED, PLAYER_STARTED_MOVING and QUEST_WATCH_UPDATE event function (2025.05.06)
		- Cleaned up function to update the scenario frame by only allowing this event function to be carried out if mythicMode is disabled (2025.05.06)
		- Removed redundant code from within RQE:ToggleFramesAndTracker() and PLAYER_REGEN_ENABLED event function (2025.05.07)
		- Added call to UpdateRQEQuestFrame() within UI_INFO_MESSAGE, if certain messageType fires, and QUEST_WATCH_UPDATE as the frame wasn't being updated immediately after a quest had been flagged as complete (2025.05.07)

	QuestingModule.lua
		- Checks if InCombatLockdown() when QuestLogIndexButton registers a click and then "refuses" to accept the click if the player isn't mousing over the RQEQuestFrame (2025.04.21)
		- Moved RQE.ClickQuestLogIndexButton(questID) and RQE.ClickRandomQuestLogIndexButton(bigQuestID) from RQEFrame.lua to QuestingModule.lua (2025.04.21)
		- Added helper function to verify that batch of accepted quests are watched/tracked properly (2025.04.26)
		- Added numQuestCurrencies for the purpose of reward tooltip (2025.04.26)
		- Updated DB record of saved tracked and saved supertracked quests player currently has (2025.04.26)
		- Failsafe to check to ensure that the player is mousing over RQEQuestFrame before accepting a mouse click (2025.04.26)
		- Fix to issue being generated where quests were removed from watch list when holding shift and turning in a quest (2025.04.28)
		- Added functionality to check RQEQuestFrame visibility based on mythicScenarioMode (2025.04.28)
		- Fixed issue with the QuestLogIndexButton click not working if mythicScenarioMode is enabled by changing OnClick to OnMouseDown (2025.04.29)
		- Added RQE:RecommendFastestTravelMethod() [author-mode only] (2025.04.30)
		- Modification to RQE:QuestRewardsTooltip(tooltip, questID) function to include profession skill points (2025.05.04)
		- Added RQE:CheckWatchedQuestsSync() function that checks the tracked quests and compares with the quests listed in the RQEQuestFrame to ensure that all applicably tracked quests are being properly shown (2025.05.04)
		- Ensured that the RQE:CheckWatchedQuestsSync() function only fires when player is not in combat, not casting, not channeling, not moving and the player is hovering over the WorldMapFrame or the RQEQuestFrame and still no more than once per second (2025.05.04)
		- Modified function that handles RQE:CheckWatchedQuestsSync() to include if the world map frame is open or the classic quest log frame (assuming player has this addon) is also open (2025.05.06)

	RQE.toc
		- Updated Interface# and version# (2025.04.28)

	RQEDatabase.lua
		- Changed objectivesText to instead be objectivesQuestText (2025.04.21)
		- Added additional alliance/neutral quests to DB for Mists of Pandaria expansion (2025.04.21)
		- Added 11.1.5 Sureki (Hallowfall) and Radiant (Azj-Kahet) Incursion quests to DB (2025.04.26)
		- Added additional WQ to the DB (2025.04.28)
		- Added additional weekly profession Valdrakken quests to the DB (2025.04.30)
		- Added additional notations to quests in DB for the objectiveText, descriptionText and npc info (2025.05.03)
		- Fixes/adjustments to quest in Darkmoon Faire within quest DB (2025.05.04)
		- Added some additional objectiveText, descriptionText and npc info to the quest DB (2025.05.06)

	RQEFrame.lua
		- Moved RQE.ClickQuestLogIndexButton(questID) and RQE.ClickRandomQuestLogIndexButton(bigQuestID) from RQEFrame.lua to QuestingModule.lua (2025.04.21)
		- Added a check for MagicButton visibility after RQE:CheckFrameVisibility has run (2025.04.21)
		- Modified RQE:CheckFrameVisibility to run continuously as long as player is not in combat and not moving (2025.04.21)
		- Increased the timer from 0 to 1.5 seconds when firing RQE:CheckFrameVisibility() function and also requiring player not be inside a scenario or moving (2025.05.06)

	RQEMacro.lua
		- Removed code to check macro after PLAYER_REGEN_ENABLED as this firing was causing massive lag as a result of inefficient code that wasn't needed, as the proper checks are already being handled at the proper events (2025.05.07)


11.1.0.6 (2025.04.20)

	**HIGHLIGHTS**
		- Fixed issue of StepsText table and DB being nil, particularly on fresh installs (2025.04.20)

	Core.lua
		- Added DB tables to the top of global declarations before AceDB initializes (2025.04.20)
		- Created helper function for default frame positions (2025.04.20)

	EventManager.lua
		- Moved code to initialize StepsText table further up in the VARIABLES_LOADED event function (2025.04.20)

	RQE.toc
		- Updated Interface# and version# (2025.04.18)

	RQEDatabase.lua
		- Added additional WQ to DB of quests (2025.04.20)

	RQEFrame.lua
		- Ensure that StepsText table is initialized when UpdateContentSize function is called (2025.04.20)
		- Fail safe to make sure the framePosition is properly loaded, even if the DB file doesn't yet exist (2025.04.20)


11.1.0.5 (2025.04.18)

	**HIGHLIGHTS**
		- Fixed RQE:StartPeriodicChecks(), RQE:CheckDBObjectiveStatus and RQE:CheckDBComplete to properly handle updates when quest is ready for turn in as this was giving a false positive previously with some quests (2025.03.28)
		- Fixed issue where searching for a quest and populating the RQEFrame wouldn't work unless a quest was already being supertracked (2025.03.30)
		- Performance improvement when using the search box to travel to a location to pick up a quest (2025.03.30)
		- Added directionText to UpdateFrame that would direct the player to the zone and continent if searching for a quest that isn't complete, isn't in their log but is present in the DB (2025.03.30)
		- Added special tooltip that would display quest information when clicking on a questName in the chat log after player opts to print specific questline (2025.03.30)
		- Added functionality that allows players to search for a questID (provided they have TomTom), using the "S" button, and if the quest is in the DB it will direct player where to go - but player needs to be on the continent for the waypoint arrow to appear (2025.03.30)
		- Fixed issue where dropdown menu wasn't appearing on right-clicking of the QuestLevelAndName string (2025.03.30)
		- Fixed issue where TrackClosestQuest wasn't working correctly and would not track the closest (2025.04.01)
		- Added function that first obtains the index from the itemID when purchasing an item. This will allow for greater reliability for when an objective/macro requires the purchase of an item from a merchant (2025.04.01)
		- Changed DB entries with RQE:ConfirmAndBuyMerchantItem(itemIndex, quantity) to instead use RQE:BuyItemByItemID(itemID, quantity) (2025.04.01)
		- Fix made for recipe tracking as it was listing some duplicate names based on if they had different itemIDs for other qualities (2025.04.09)
		- Creates a macro for a quest to target and mark the quest giver on a searched quest that the player hasn't yet completed (2025.04.12)
		- Fixed issue where world quests were automatically being supertracked when the RQEFrame was empty and overriding potentially waypoint (2025.04.13)
		- Fixed issue where world quests that were automatically tracked wouldn't disappear when leaving the world quest's blob (2025.04.13)
		- Fixed bug caused when RQEFrame is checking visibility status when combat is taking place (2025.04.17)

	Buttons.lua
		- Creates tooltip for the location of where to pick up a searched quest if the player doesn't have this quest in their log, hasn't completed it, and it is present in the DB file of the addon (2025.03.30)

	Core.lua
		- Added functionality to obtain WQ information, but this requires the author-only RQE Contribution addon (2025.03.28)
		- Fixed RQE:StartPeriodicChecks(), RQE:CheckDBObjectiveStatus and RQE:CheckDBComplete to properly handle updates when quest is ready for turn in as this was giving a false positive previously with some quests (2025.03.28)
		- Added function [RQE.ObtainSuperTrackQuestDetails()] to obtain quest details of super tracked quests for purpose of adding additional quests to the DB (2025.03.29)
		- Additional fix to RQE:CheckDBObjectiveStatus as some quests were still not properly advancing (2025.03.29)
		- Updated RQE:CheckDBObjectiveStatus handling of the progress bar to fall back to neededAmt 1 meaning 100% and 0.01 meaning 1% (2025.03.30)
		- Fixed issue where searching for a quest and populating the RQEFrame wouldn't work unless a quest was already being supertracked (2025.03.30)
		- Added flags to prevent UpdateFrame from running if searched quest was being displayed in the RQEFrame, but the flag does turn off when a non-searched quest populates the frame (2025.03.30)
		- Added directionText to UpdateFrame that would direct the player to the zone and continent if searching for a quest that isn't complete, isn't in their log but is present in the DB (2025.03.30)
		- Added special tooltip that would display quest information when clicking on a questName in the chat log after player opts to print specific questline (2025.03.30)
		- Fixes to the way quest information is gathered from contribution addon (2025.03.30)
		- Added brief delay before printing out quest information following a search as it was coming back "Unknown Quest" (2025.03.30)
		- Fixed issue where TrackClosestQuest wasn't working correctly and would not track the closest (2025.04.01)
		- Added function that first obtains the index from the itemID when purchasing an item. This will allow for greater reliability for when an objective/macro requires the purchase of an item from a merchant (2025.04.01)
		- Modification to RQE:GetClosestTrackedQuest() to print what the closest quest is to act as a debug tool (2025.04.03)
		- Adjustment to PrintQuestlineDetails function with delay timers (2025.04.03)
		- Added functions to track certain quests as based on the DB - this is an author-only function (2025.04.09)
		- Added brief delay in RQE:StartPeriodicChecks before checking the macro for the current step (2025.04.09)
		- Additional fix RQE:CheckDBObjectiveStatus to handle additional quest types to ensure that they advance in counter quests following a single count in the first objective, but haven't tested progress bar type quests (2025.04.09)
		- Fixed tracking of recipes to no longer list duplicate names based on those items that have different itemIDs based on quality, but still not listing 'Sparks' in the recipe being tracked (2025.04.09)
		- Generates macro when the player presses "Track" after searching for a quest that targets and marks the quest giver (2025.04.12)
		- Fixed issue where world quests were automatically being supertracked when the RQEFrame was empty and overriding potentially waypoint (2025.04.13)
		- Function to gather missing objectiveText and descriptionText for DB [author-only] (2025.04.16)
		- Added check for Contribution sister-companion add-on before running function to obtain objectiveText and descriptionText for DB [author-only] (2025.04.17)

	EventManager.lua
		- Updated GOSSIP_CONFIRM_CANCEL, GOSSIP_SHOW, MAIL_SUCCESS, BOSS_KILL to check if a quest is being super tracked before continuing through event function in order to improve performance (2025.03.28)
		- Updated QUEST_ACCEPTED and QUEST_DETAIL to print out information if the quest is present in the DB or not and # of steps when these two functions fire (2025.03.28)
		- Created flags that prevent the RQEFrame from updating when a quest is being searched unless the frame is cleared, or the player has picked up the quest that was being searched for (2025.03.30)
		- Removed 'return' of RQE.HasDragonraceAura from QUEST_LOG_UPDATE and QUEST_WATCH_LIST_CHANGED as this was preventing some quests from updating RQEFrame during dragonriding/skyriding races with objectives (2025.03.30)
		- Added functionality to track nearest, if that option is selected, after the firing of certain messageType within the UI_INFO_MESSAGE event (2025.04.01)
		- Increased delay slightly before the firing of RQE:StartPeriodicChecks in the ITEM_COUNT_CHANGED event (2025.04.09)
		- Fixed issue where world quests that were automatically tracked wouldn't disappear when leaving the world quest's blob (2025.04.13)
		- Added check for combat before allowing toggle of RQE Objective Tracker (2025.04.17)
		- Added visibility display for RQEFrame/RQEQuestFrame when PLAYER_REGEN_ENABLED [combat ending], PLAYER_STARTED_MOVING, and ZONE_CHANGED_NEW_AREA (2025.04.17)

	QuestingModule.lua
		- Added functionality to obtain WQ information, but this requires the author-only RQE Contribution addon (2025.03.28)
		- Added flags that when the questLogIndexButton, in the RQEQuestFrame, are pressed the flag that prevents the UpdateFrame from updating, in Core.lua, is set to false (2025.03.30)
		- Clears RQEFrame, if the frame is populated by a searched quest when the player clicks on different quest in the RQEQuestFrame (2025.03.30)
		- Fixed issue where dropdown menu wasn't appearing on right-clicking of the QuestLevelAndName string (2025.03.30)
		- Added additional menu items [author-only] to track specific quests based on their status in the DB (2025.04.09)
		- Removed requirement of IF.. THEN statement relating to the creation of macro after PLAYER_MOUNT_DISPLAY_CHANGED (2025.04.16)
		- Call for a function after PLAYER_LOGIN and QUEST_ACCEPTED to gather objectiveText and descriptionText for DB [author-only] (2025.04.16)
		- Added call to update macro after a brief delay of PLAYER_ENTERING_WORLD event function fires (2025.04.16)
		- Removed UpdateRQEQuestFrameVisibility from UpdateRQEQuestFrame as this was being called too often (2025.04.17)

	RQE.toc
		- Updated version# (2025.03.26)

	RQEDatabase.lua
		- Finished proofing campaign quests in Hallowfall and some of Azj-Kahet (2025.03.27)
		- Added a number of Dragonflight dungeon quests to DB (2025.03.27)
		- Added more WQ from Legion, Battle for Azeroth, Shadowlands, Dragonflight and The War Within (2025.03.28)
		- Added Forbidden Reach and Zaralek Cavern quests to DB from Dragonflight expansion (2025.03.29)
		- Added Emerald Dream campaign quests to DB (2025.03.30)
		- Added post-Emerald Dream (Amirdrassil) quests to the DB (2025.03.30)
		- Added a few more WQ and dragonriding/skyriding quests from Dragonflight to DB (2025.03.30)
		- Corrected mapID information for many WQ that were stored in DB (2025.03.30)
		- Added additional Thaldraszus side-quests, from Dragonflight expansion, into the DB (2025.04.01)
		- Changed DB entries with RQE:ConfirmAndBuyMerchantItem(itemIndex, quantity) to instead use RQE:BuyItemByItemID(itemID, quantity) (2025.04.01)
		- Added more preliminary world quests to DB as well as more Dragonflight quests (2025.04.03)
		- Added additional WQ to the DB along with alliance quests for The Jade Forest zone of the Mists of Pandaria expansion (2025.04.09)
		- Added remaining of The Jade Forest zone to DB (2025.04.10)
		- Added Valley of the Four Winds and Krasarang Wilds alliance quests to DB (2025.04.10)
		- Added many alliance quests of Kun-Lai Summit to the quest DB (2025.04.12)
		- Added additional WQ to the quest DB (2025.04.13)
		- Added Townlong Steppes [alliance/neutral] quests to DB (2025.04.16)
		- Added some Dread Wastes [alliance/neutral] quests to DB (2025.04.17)
		- Added additional WQ to the quest DB (2025.04.18)

	RQEFrame.lua
		- Added additional menu items [author-only] to track specific quests based on their status in the DB (2025.04.09)
		- Modified function for checking RQEFrame and RQEQuestFrame to fire when a function is called or every 10 seconds, instead of firing OnUpdate [as this was previously firing too often] (2025.04.17)

	RQEMacro.lua
		- Creates a macro for a quest to target and mark the quest giver on a searched quest that the player hasn't yet completed (2025.04.12)

	RQEMinimap.lua
		- Added combat check before allowing toggle (RQE Minimap/LDB button) to successfully toggle hiding/showing the RQEFrame (2025.04.17)

	WaypointManager.lua
		- Added function that creates a waypoint to where the player should pick up a quest that they don't have, and haven't completed, if they are using the search "S" function for the quest (2025.03.30)
		- Added functionality to prevent a waypoint from being created for hidden questTypes (2025.04.16)

	WPUtil.lua
		- Calls a function to create a waypoint if the RQEFrame is populated by a searched quest that the player doesn't have. This waypoint is created to direct the player to the location of where to pick up the quest (2025.03.30)


11.1.0.4 (2025.03.26)

	**HIGHLIGHTS**
		- Modified code to now accept multiple gossip options instead of just the first one allowing smoother control when multiple options appear in sequence when completing a quest (2025.03.24)
		- Fixed issue where waypoints and steps were being hidden when a quest was present in the DB and direction text is available (2025.03.25)
		- Fixed issue where CheckScenarioStage and CheckScenarioCriteria weren't working as intended (2025.03.26)
		- Fixed coordinates on campaign quests at The Ringing Deeps as coordinates off likely following Patch 11.1 Undermined (2025.03.26)
		- Fixed issue where Print Questline wasn't working when chosen in the RQEFrame (2025.03.26)

	**Libraries**
		- Updated LibDBIcon-1.0 and LibSharedMedia-3.0 (2025.03.23)

	Core.lua
		- Fixed wording for WowheadLink and wowWiki frames dialog box button to state 'Highlight Text' instead of 'Copy to Clipbaord' for accuracy/clarity (2025.03.20)
		- Fixed taint related to RQE:AutoSuperTrackClosestQuest() attempting to fire sometimes during combat (2025.03.23)
		- Modified code to now accept multiple gossip options instead of just the first one (2025.03.24)
		- Added delay before firing function that clicks the "W" button when RQE:AutoSuperTrackClosestQuest fires (2025.03.24)
		- Fixed section of code within RQE that caused the hiding of quest steps if quest in different zone/direction text is list (2025.03.25)
		- Fixed issue where CheckScenarioStage and CheckScenarioCriteria weren't working when under the 'checks' system and now only works under the 'check' system (2025.03.26)

	EventManager.lua
		- Set delay prior to running function that auto super track nearest quest after combat ends (2025.03.20)
		- Increased delay, after combat ending, before RQE:AutoSuperTrackClosestQuest() fires (2025.03.23)
		- Added RQE.CheckAndClickWButton(), after brief delay and not in scenario, following the firing of UPDATE_INSTANCE_INFO event (2025.03.24)
		- Added RQE:AutoSuperTrackClosestQuest, after brief delay, following the firing of QUEST_TURNED_IN event (2025.03.24)
		- Added additional commented lines for clarity as well as arg print option for UI_INFO_MESSAGE event (2025.03.25)
		- Added a save tracked quests to character profile when UI_INFO_MESSAGE event fires (2025.03.25)
		- Added a macro check following a brief delay when UPDATE_INSTANCE_INFO fires (2025.03.26)

	QuestingModule.lua
		- Changed "Stop Tracking" to "Untrack Quest" in the drop down menu when right-clicking on a quest in the RQEQuestFrame (2025.03.24)

	RQE.toc
		- Updated version# (2025.03.19)

	RQEDatabase.lua
		- Added Alliance and neutral Legion quests to DB excluding Suramar (2025.03.20)
		- Added Waking Shores quests to DB (2025.03.22)
		- Added Ohn'aharan Plains, Azure Span and Thaldraszus campaign/story quests, along with many side quests to DB (2025.03.23)
		- Added additional Dragonflight expansion side quests to DB (2025.03.24)
		- Fixes for The War Within quests' coding in DB (2025.03.25)
		- Updates to DB for Isle of Dorn quests and WQ in War Within, Dragonflight and Shadowlands (2025.03.26)
		- Finished proofing campaign quests in Isle of Dorn (2025.03.26)
		- Fixed coordinates on campaign quests at The Ringing Deeps as coordinates off likely following Patch 11.1 Undermined (2025.03.26)

	RQEFrame.lua
		- Changed "Stop Tracking" to "Untrack Quest" in the drop down menu when right-clicking on a quest in the RQEFrame (2025.03.24)
		- Fixed issue where Print Questline wasn't working when chosen in the RQEFrame (2025.03.26)
		- Added "View Quest" option in the RQEFrame right-click dropdown options (2025.03.26)

	WaypointManager.lua
		- Fix issue with waypoint being cleared when using waypoint system to travel to separate zone with direction text (2025.03.25)


11.1.0.3 (2025.03.19)

	**HIGHLIGHTS**
		- Added CPU profiling for RQE addon with display of % of current CPU usage (2025.03.08)
		- Added/Fixed LibDataBroker library in anticipation of 11.1.5 patch (2025.03.11)
		- Made fixes to the Undermine campaign quest DB (2025.03.12)
		- Fixed issue with RQE:GetBonusQuestsInCurrentZone() function as bonus quests weren't showing up in the frame (2025.03.14)
		- Added delay before running RQE.PrintQuestlineDetails after selected from right-click menu so that info is populated properly (2025.03.14)
		- Added ability to read progress bar percent to better direct player to waypoints when this is the objective type (2025.03.16)
		- Major fix/update to OnInit to correctly save/restore DB profiles as profiles weren't being correctly restored (2025.03.19)
		- Added option to supertrack the nearest quest even if player is already supertracking a question. This is an experimental feature (2025.03.19)
		- Added feature that creates a waypoint if direction text exists directing the player to travel to a portal to reach the next step, including an exclusion list of questIDs (2025.03.19)

	Config.lua
		- Added checkboxes to toggle CPU profiling/check to the settings pane and addon-specific configuration window (2025.03.08)
		- Added option to include timestamps with the debug log (2025.03.13)
		- Added enableAutoSuperTrackSwap option (experimental feature) to update the player's supertracked quest with the nearest quest, even if an existing quest is currently being super tracked (2025.03.19)

	Core.lua
		- Added CPU profiling for RQE addon with display of % of current CPU usage (2025.03.08)
		- Added code to make it easier to obtain data from the contribution companion addon (2025.03.09)
		- Set debug timestamps to be on by default (2025.03.13)
		- Fixed issue with RQE:GetBonusQuestsInCurrentZone() function as bonus quests weren't showing up in the frame (2025.03.14)
		- Added delay before running RQE.PrintQuestlineDetails after selected from right-click menu so that info is populated properly (2025.03.14)
		- Added ability to read progress bar percent to better direct player to waypoints when this is the objective type (2025.03.16)
		- Additional fixes for the RQE.PrintQuestlineDetails to prevent/minimize chance of questTitles not properly loading (2025.03.16)
		- Major fix/update to OnInit to correctly save/restore DB profiles as profiles weren't being correctly restored (2025.03.19)
		- Added option to supertrack the nearest quest even if player is already supertracking a question. This is an experimental feature (2025.03.19)

	DatabaseMain.lua
		- Set up for game version checks of the upcoming Midnight and future Last Titan expansions (2025.03.13)

	DebugLog.lua
		- Modification to print time stamps in debug log if checked in config (2025.03.13)
		- Fixed debug log for printing only message when timestamps are not selected (2025.03.14)
		- Fixed debug log to not print duplicate data (2025.03.14)

	EventManager.lua
		- Updates call to check CPU usage in the same circumstances as a memory usage update check occurs (2025.03.08)
		- Fix for profiles not being properly restored on reload and login (2025.03.19)

	QuestingModule.lua
		- Removed old code that had been commented out relating to a long, old method for bonus quests in the tracker (2025.03.14)
		- Additional fixes for the RQE.PrintQuestlineDetails to prevent/minimize chance of questTitles not properly loading (2025.03.16)

	RQE.toc
		- Updated interface# (2025.03.05)

	RQEDatabase.lua
		- Added Azuremyst Isle and Bloodmyst Isle quests to DB (2025.03.06)
		- Added Darkshore quests to DB (2025.03.08)
		- Added Ashenvale, Stonetalon Mountains, Desolace and some Feralas quests to DB (2025.03.09)
		- Added Feralas, Winterspring and part of Southern Barrens quests to DB (2025.03.09)
		- Added Southern Barrens, Dustwallow Marsh, and Thousand Needles quests to DB (2025.03.10)
		- Added preliminary for final campaign chapter of Undermine quests to DB (2025.03.11)
		- Made fixes to the Undermine campaign quest DB (2025.03.12)
		- Added preliminary side quests for Isle of Dorn, Ringing Deeps, Hallowfall and Azj-Kahet (2025.03.16)
		- Added Teldrassil and Felwood (Alliance/Neutral) quests to DB (2025.03.17)
		- Added some Alliance and neutral Stormheim (Legion) quests to DB (2025.03.19)

	RQEFrame.lua
		- Added display (above mem usage) to show the CPU usage of the addon (2025.03.08)
		- Fixed world quest for Undermine world boss (2025.03.11)

	WaypointManager.lua
		- Added feature that creates a waypoint if direction text exists directing the player to travel to a portal to reach the next step (2025.03.19)
		- Added a questID exclusion list for quests where direction text exists directing player to portal, for example in the event that something is needed to be done in a given zone before proceeding (2025.03.19)


11.1.0.2 (2025-03-05)

	**HIGHLIGHTS**
		- Updated Undermine campaign quests in DB to include the 5 available chapters of 6 (2025.03.01)
		- Added questID 85088 for the Undermine zone world boss (2025.03.05)

	RQE.toc
		- Updated interface# (2025.03.01)
		- Added category information for addon (2025.03.01)

	RQEDatabase.lua
		- Updated Undermine campaign quests in DB to include the 5 available chapters of 6 (2025.03.01)
		- Fixed questID 29520 to check inventory/zoneID before advancing in one of the steps (2025.03.02)
		- Fixed questID 29517 to check objective status rather than item that doesn't go into bags (2025.03.02)
		- Added rest of Tanaris (neutral/Alliance), Un'Goro Crater, Silithus and most of Azuremyst Isle quests to DB (2025.03.03)
		- Added preliminary additional side quests of Undermine to DB (2025.03.04)
		- Fixed and added several Undermine campaign quests in DB (2025.03.05)
		- Fixed several Undermine quests in DB (2025.03.05)

	RQEFrame.lua
		- Added questID 85088 for the Undermine zone world boss (2025.03.05)


11.1.0.1 (2025-03-01)

	**HIGHLIGHTS**
		- Updated most quests in Cataclysm (alliance) to include waypoints, macros and quest tips! (2025.02.10)
		- Super tracked quest is restored when the RQEFrame is re-enabled (2025.02.11)
		- Added functionality for sorting non-world quests in the RQEQuestFrame when UpdateRQEQuestFrame() function is called (2025.02.12)
		- Added Undermine campaign chapters to DB (2025.02.12)
		- Cleaned up available Undermine campaign quests in the DB (2025.03.01)

	**Misc/Experimental**
		- Experimental addition modification to CheckDBZoneChange and CheckDBObjectiveStatus but commented out for now until can perfect (2025.02.11)

	Buttons.lua
		- Fixed nil error associated with currentSuperTrackedQuestID in the "W" button tooltip (2025.02.09)
		- Removed code that was saving character's supertracked quest when the clear button was pressed (2025.02.11)

	Core.lua
		- Added/modified some debug language for when quest player was supertracking are saved to the savedvariables DB file (2025.02.11)
		- UpdateFrame() is now called after RQE:RestoreSuperTrackedQuestForCharacter() to ensure proper updates to the frame (2025.02.11)
		- Removed old commented out bits related to quest step automation (2025.02.11)

	EventManager.lua
		- Removed code that was saving character's supertracked quest when SUPER_TRACKING_CHANGED event fires as this was causing the function to fire too frequently (2025.02.11)
		- Added functionality for sorting non-world quests in the RQEQuestFrame when UpdateRQEQuestFrame() function is called within event handling (2025.02.12)
		- Added PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED event (2025.02.12)
		- Updated some commented out code for UNIT_QUEST_LOG_CHANGED for clarification (2025.02.24)

	QuestingModule.lua
		- Added functionality to provide a print-out of quests in current player zone of sorted quest list (2025.02.12)
		- Added functionality to sort non-world quests for tracked quests in player zone for the RQEQuestFrame and quests not in the zone are listed below the sorted ones (2025.02.12)

	RQE.toc
		- Updated version# (2025.02.02)
		- Updated info in notes to detail info on compatibility issues (2025.02.07)
		- Updated interface#  (2025.03.01)

	RQEDatabase.lua
		- Added 'Lingering Shadows' preliminary quests to DB (2025.02.05)
		- Added Mount Hyjal and Deepholm preliminary quests to DB (2025.02.05)
		- Updated Vashj'ir, Deepholm, Uldum and Twilight Highlands (alliance/neutral) quests to DB (2025.02.08)
		- Added Elwynn Forest, Westfall and Redridge Mountains quests to DB (2025.02.10)
		- Added Swamp of Sorrows, Burning Steppes and Blasted Lands (alliance/neutral) quests to DB (2025.02.11)
		- Updates to Love Is In The Air event quests (2025.02.11)
		- Added preliminary quests to Undermine to DB (2025.02.12)
		- Added Stranglethorn zones (alliance/neutral) quests to DB (2025.02.12)
		- Added Loch Modan, Badlands and some Dun Morogh zones (alliance/neutral) quests to DB (2025.02.13)
		- Added rest of Dun Morogh, Wetlands and some of Arathi Highlands (alliance/neutral) quests to DB (2025.02.14)
		- Added rest of Arathi Highlands and Hinterlands (alliance/neutral) quests to DB (2025.02.15)
		- Added Western Plaguelands and Eastern Plaguelands (alliance/neutral) quests to DB (2025.02.16)
		- Added some Dustwallow Marsh and Tanaris (alliance/neutral) quests to DB (2025.02.19)
		- Added rest of campaign quests for Undermine zone to DB (2025.02.24)
		- Added detail to most of the Undermine campaign chapters to DB (2025.02.28)
		- Added more Tanaris quests and cleaned up all available campaign chapters for Undermine patch (2025.03.01)

	RQEFrame.lua
		- Fixed nil error by ensuring that RQE>QuestLogIndexButton exists (2025.02.12)

	RQEMacro.lua
		- Added RQE Button tooltip text for when quest item is to be looted from a mob (2025.02.24)

	RQEMinimap.lua
		- When RQEFrame is restored via RQE.ToggleBothFramesfromLDB() or LDB/minimap button press it will now properly restore the quest that was saved to what the player was supertracking (2025.02.11)
		- Added functionality to save currently super tracked quest, if the RQEFrame is shown, prior to disabling of the RQEFrame (2025.02.11)


11.0.7.6 (2025-02-02)

	**HIGHLIGHTS**
		- Updated many quests in Burning Crusade (alliance) to include waypoints, macros and quest tips! (2025.01.02)
		- Ensure that the waypoint associated with the quest step, if listed in DB guide file and having steps is clicked instead of the "W" Blizzard waypoint (2025.01.03)
		- DB should now work with AND, OR, NOT and combo checks as well as multiple types of functional checks before advancing stepIndex (2025.01.06)
		- Cleaned up ZONE_CHANGED event function as too much unnecessary calls were firing whenever this event fired. This was especially noticeable in places like SW City where ZONE_CHANGE can fire quite frequently causing momentarily annoying freeze of character (2025.01.07)
		- CheckDBInventory successfully works for both 'check' and 'checks' (2025.01.07)
		- Added RQE:CombineCheckResults functionality to examine the DB logic checks on how handling quests in terms of AND, OR and NOT instead of just AND between the various logics (2025.01.08)
		- Updated tooltip display for RQE Magic Button and itemCount to be displayed with button (2025.01.18)
		- Added string for subzones on CheckDBZoneChange within the RQE:CheckDBZoneChange function (2025.01.24)
		- Added better handling for CheckDBComplete to not automatically enable without that funct in last stepIndex, in order to allow better guidance out of caves/undergrounds (2025.01.26)
		- Added functionality to save/restore the watched/tracked quests on character-basis (2025.01.28)
		- Fixed UNIT_AURA event to work better and print out more info for debugging (2025.01.29)
		- Improved handling of quests, particularly in certain caves or across multiple zones for waypoint guidance, such as Darkmoon Faire quests where you need to collect profession materials outside of the Darkmoon Faire. (2025.02.02)

	Buttons.lua
		- Modified RQE.UnknownButtonTooltip function to run RQE.CheckAndClickSeparateWaypointButtonButton() after RQE.ClickWButton() and RQE:StartPeriodicChecks() and also providing tooltip information if INFO debug option is set (2025.01.03)
		- Plays certain sound whether the waypoint information in the DB exists, matches or doesn't match the stored Blizzard waypoint for the super tracked quest (only on INFO debug level) (2025.01.03)
		- Modified the C_Timer.After in the RQE.UnknownButtonTooltip function (2025.01.03)
		- Cleaned up unused code (2025.01.12)
		- Removed duplicate call to save super tracked quest when frame cleared by button press (2025.01.28)

	Config.lua
		- Updated config to allow 'Show Event Debug Info' when Debug Mode is now either INFO or INFO+ (2025.01.13)
		- Updated config to allow 'Show Arg/Payload Info' when Debug Mode is now either INFO or INFO+ (2025.01.26)

	Core.lua
		- Created function aimed at clicking the RQE.SeparateWaypointButton (2025.01.03)
		- Fixed error related to the click of the RQE.SeparateWaypointButton (2025.01.03)
		- Fix to RQEMacro:CreateMacroForCurrentStep() function that allows for update to occur in instance if this was shortly after a zone change event occurred (2025.01.04)
		- Slight modification to RQE:StartPeriodicChecks() so that funct checks work correctly with CheckDBZone and CheckDBInventory (although CheckDBInventory won't handle failedchecks in DB, so these won't be used for the foreseeable future) (2025.01.04)
		- Slight modification to the RQE:CheckDBZoneChange function (will revert back to 11.0.7.5 addon version if needed) (2025.01.04)
		- Redesigned RQE:ClickWaypointButtonForIndex(index) function to look and handle when description starts out with 'ALLIANCE:' or 'HORDE:' (2025.01.06)
		- Updated RQE:CheckDBInventory(questID, stepIndex) function to handle ANDs and ORs for array of inventory items (2025.01.06)
		- Possible fix for RQE:CheckObjectiveProgress(questID, stepIndex) in the handling of advancement beyond the stepIndex that it should be (2025.01.06)
		- Added macro creation/check toward the end of the UpdateFrame function (2025.01.06)
		- Modified CheckDBInventory function to handle AND, OR, NOT, combo logic (2025.01.06)
		- Large re-work of RQE:StartPeriodicChecks() (along with subsequent related functions for evaluating the checks and funct) and subsequent functions that now will hopefully handle array checks and check with AND, OR and NOT logic (2025.01.06)
		- Modified RQE:StartPeriodicChecks() and subsequent related functions to better with single check, but still need to test the 'checks' versions - CheckDBInventory and CheckDBObjectiveStatus seem to function as well as ever (2025.01.06)
		- Changed CheckObjectiveProgress to CheckDBObjectiveStatus function call for ease of use (2025.01.07)
		- Updated RQE:CheckDBObjectiveStatus/RQE:CheckObjectiveProgress function as it wasn't working when objectiveIndex was not in the same numerically ascending order as the stepIndex (2025.01.07)
		- Fixed functionality in RQE:StartPeriodicChecks to handle the CheckDBInventory for both check and checks (2025.01.07)
		- Updates to RQE:EvaluateStepChecks to include more debug for future checks analysis/debugging (2025.01.07)
		- Modified RQE:CraftSpecificItem to only run if INFO+ debugMode is set as this only deals with printing the schematic/recipe materials (2025.01.07)
		- Updated RQE:CheckDBObjectiveStatus(questID, stepIndex, check, neededAmt) function to work for not just check but also checks (2025.01.07)
		- Added RQE:CombineCheckResults functionality to examine the DB logic checks on how handling quests in terms of AND, OR and NOT instead of just AND between the various logics (2025.01.08)
		- Updated RQE:StartPeriodicChecks() so that it would work with the RQE:CombineCheckResults function call (2025.01.08)
		- Fixed RQE:CheckDBObjectiveStatus function call to that it would work with the 'check' and 'checks' in the DB along with the modifiers (2025.01.08)
		- Updated RQE:CheckDBZoneChange() function call to that it would work with the 'check' and 'checks' in the DB (2025.01.08)
		- Removed call to update the macro when UpdateFrame fires as this was causing unreasonable lag (2025.01.08)
		- Updated functions that call CheckDBBuff, CheckDBDebuff, CheckScenarioStage and CheckScenarioCriteria DB functions to also handle 'checks' in addition to the 'check' as it existed (2025.01.08)
		- Added functionality to RQE:StartPeriodicChecks() function for failedfunct (2025.01.09)
		- Updated RQE:CheckFactionGroupAlliance and RQE:CheckFactionGroupHorde, but not reliably working (2025.01.09)
		- Reverted to an earlier RQE:StartPeriodicChecks() and commented out failedfunct section for now until can work reliably, but these checks can be handled through the 'checks' (2025.01.10)
		- Cleaned up unused code (2025.01.12)
		- Removed debug statement no longer needed (2025.01.16)
		- Added section that displays available quests from NPC when interacting (only prints when debugMode is INFO or INFO+ (2025.01.16)
		- Updated function selecting Gossip options to apply if the npcName used in the function call is 'target' then it will just use the current targetName (2025.01.18)
		- Added sound (INFO debugMode only) for when a quest is picked up that has no steps listed but is in the DB (2025.01.24)
		- Added string for subzones on CheckDBZoneChange within the RQE:CheckDBZoneChange function (2025.01.24)
		- Added placeholder for CheckDBModel for purposes of firing when the UNIT_MODEL_CHANGED fires (2025.01.26)
		- Added better handling for CheckDBComplete to not advance automatically to this stepIndex if CheckDBComplete doesn't exist for final step to better handle for zone requirements to more easily navigate out of caves where the exit isn't obvious (2025.01.26)
		- Added functionality to save/restore the watched/tracked quests on character-basis (2025.01.28)

	EventManager.lua
		- Changed info that allows viewing showEventDebugInfo to be debugMode INFO (user would still need to switch to INFO+ in order to toggle this option, but could then switch back to INFO (2025.01.07)
		- Fixed LUA typo errors by removing the double not not associated with RQE.ScrollFrameToTop() (2025.01.07)
		- Added MAIL_SUCCESS event to run the RQE:StartPeriodicChecks when mail item has been received, in the event that you pick up a quest item from there (2025.01.08)
		- Cleaned up code within UNIT_QUEST_LOG_CHANGED and QUEST_ACCEPTED to limit the circumstances of when RQE:StartPeriodicChecks() should be called, thus improving lag after quest acceptance (2025.01.08)
		- Fixed UNIT_AURA sometimes not recognizing that progress had been made on a quest, set it so that it wouldn't continuously fire whenever an aura change is detected on nearby players (2025.01.09)
		- Added RQE:StartPeriodicChecks() function call to ZONE_CHANGED/ZONE_CHANGED_INDOORS event function and removed LastAcceptQuest check for this function running within ITEM_COUNT_CHANGED as it wasn't firing reliably while working on quest (2025.01.10)
		- Cleaned up unused code (2025.01.12)
		- Added Scenario check to the top of SCENARIO_UPDATE function to prevent unnecessary running of rest of function (2025.01.12)
		- Reordered/cleaned up code within ZONE_CHANGED, ZONE_CHANGED_INDOORS and ZONE_CHANGED_NEW_AREA (2025.01.12)
		- Modified code to ZONE_CHANGED, ZONE_CHANGED_INDOORS and ZONE_CHANGED_NEW_AREA to check to see if CheckDBZoneChange is present in the current step of DB before calling RQE:StartPeriodicChecks (2025.01.12)
		- Modified SCENARIO_UPDATE to run if Scenario Child Frame is visible, as this would otherwise result in Scenario Child Frame remaining after concluding/leaving scenario/dungeon (2025.01.13)
		- Updated BAG_NEW_ITEMS_UPDATED to include a check for 'CheckDBInventory' under 'check' or 'checks' within the DB of the current super tracked quest and stepIndex (2025.01.15)
		- Will print the questLink on QUEST_ACCEPTED if debugMode is either INFO or INFO+ (2025.01.15)
		- Display of GOSSIP_SHOW for event function and will call function for the purpose of printing available quests from that NPC (2025.01.16)
		- Updated ITEM_COUNT_CHANGED, BAG_NEW_ITEMS_UPDATED, BAG_UPDATE, MERCHANT_UPDATE and UNIT_INVENTORY_CHANGED to require CheckDBInventory before firing RQE:StartPeriodicChecks() (2025.01.18)
		- Added QUEST_DETAIL to called events for the purpose of displaying the questID of the currently displayed quest from the NPC quest-giver (2025.01.18)
		- Call to compare RQE.totalStepforQuest and RQE.StepIndexForCoordMatch to determine on SUPER_TRACKING_CHANGED if DB entry details are incomplete (2025.01.24)
		- Fixed ITEM_COUNT_CHANGED, BAG_NEW_ITEMS_UPDATED and BAG_UPDATE to check if CheckDBInventory exists in any of the 'check' or 'checks' within the current supertracked quest of the other stepIndex (2025.01.25)
		- Added UNIT_MODEL_CHANGED for purposes when disguise occurs but UNIT_AURA doesn't call RQE:StartPeriodicChecks function (2025.01.26)
		- Updated BAG_UPDATE to now call RQE:StartPeriodicChecks (2025.01.27)
		- Added functionality to save/restore the watched/tracked quests on character-basis (2025.01.28)
		- Fixed UNIT_AURA event function to print out more info if showArgPayloadInfo is enabled and should work better now (2025.01.29)
		- Fixed timer delay before RQE:StartPeriodicChecks function is called in some circumstances (2025.02.02)

	QuestingModule.lua
		- Fixed issue related to bonus quests check firing too often, thus improving lag between zone changes as well as periodic gameplay when a primary function is called (2025.01.08)
		- Updated a notification for Currently Tracked Achievements but set the printing ability only to be if Tracked Achievements were greater than 0 (2025.01.09)
		- Modified QuestTypeLabel to be RQE.QuestTypeLabel so that it could be properly referenced as an anchor point for QuestObjectivesOrDescription (2025.01.12)
		- Updated the QuestLogIndexButton:SetScript Click event to have a 0.2 sec delay before firing RQE:StartPeriodicChecks (2025.01.15)

	RQE.toc
		- Updated version# (2025.01.09)

	RQEDatabase.lua
		- Added remainder of quests in Terokkar Forest quests (2025.01.02)
		- Added DB quests for alliance Nagrand quests (2025.01.03)
		- Added some aldor-side and neutral Netherstorm quests to DB (2025.01.03)
		- Updated ordering and spacing of quests in DB which should now correctly reflect quests with fewer digits than other questIDs (2025.01.03)
		- Updated quests in Darkmoon Faire to handle more advanced quest steps for obtaining items from vendors associated with profession quests (2025.01.06)
		- Updated Darkmoon Faire coordinates (2025.01.06)
		- Fixed notations for the AND, NOT, OR, combo logic in the DB (2025.01.06)
		- Updated some Aldor Netherstorm quests to DB (2025.01.07)
		- Updated DB coord information for a number of profession quest dailies (2025.01.07)
		- Updated questID 70563 to include the 'checks' feature for this quest - the original CheckDBObjectiveStatus would work just fine, but this was necessary in order to ensure that the checks for CheckDBInventory was functional (2025.01.07)
		- Updated many daily fishing/cooking quests in the DB (2025.01.09)
		- Updated daily cooking quests in the DB for Shattrath City (2025.01.13)
		- Updated DB to include preliminary info on War Campaign of TWW (2025.01.13)
		- Updated some Aldor/Alliance-Neutral Shadowmoon Valley quests to DB (2025.01.15)
		- Updated Alliance quests in Borean Tundra to DB (2025.01.18)
		- Updated Alliance quests in Howling Fjord to DB (2025.01.25)
		- Updated Alliance quests in Dragonblight to DB (2025.01.27)
		- Updated Alliance quests in Grizzly Hills to DB (2025.01.29)
		- Added most Lunar Festival 'Elder' quests to DB (2025.01.29)
		- Updated Alliance quests in Sholazar Basin to DB (2025.01.31)
		- Added some Alliance quests in The Storm Peaks to DB (2025.01.31)
		- Added some of the 11.1 quests to DB including Dalaran finale and early intro of Undermine (2025.01.31)
		- Updated The Darkmoon Faire profession quests in the DB (2025.02.02)

	RQEFrame.lua
		- Fixed some options within RQE.ClickRandomQuestLogIndexButton function to call RQE.CheckAndClickWButton() instead of immediately clicking the "W" button. This is because the function call performs various checks to make sure if it is first necessary to click the button (2025.01.03)
		- Changed dynamic padding of RQEFrame's QuestNameText to allow for better wrap for longer quest titles (2025.01.03)
		- Added RQE.totalStepforQuest to addon table for totalSteps for quest contribution purposes (2025.01.24)
		- Fixed nil error for the RQE.SeparateStepText (2025.02.02)

	RQEMacro.lua
		- Added better visibility for displaying tooltip of item associated with Magic Button macro, and works with spells too that are in the macro (2025.01.06)
		- Added counter to Magic Button for items in inventory to better keep track (2025.01.06)
		- Updated macro to display tooltip when itemID is listed in the 'use' and 'cast' showtooltip while maintaining previous functionality for 'use' & gives itemCount if no itemID is present following the '#showtooltip' (2025.01.18)
		- Added some more context to other exceptionItemIDs (2025.01.19)
		- Updated itemCount to display if an item has at least 1 and less than 999 as it was 2 (2025.01.24)
		- Added new icon for emote usage to the exception table of the macro showtooltip (2025.01.25)

	WaypointManager.lua
		- Cleaned up unused code (2025.01.12)


11.0.7.5 (2025-01-02)

	**HIGHLIGHTS**
		- Updated RQE:CheckDBZoneChange() function to handle for multiple mapID checks in DB for a single CheckDBZoneChange check
		- Fixed issue where objective progress wasn't reliably advancing to next steps with data in DB
		- Added information to tooltip to display step information when hovering over the QuestID/Name in RQEFrame as well as when hovering over the step frame
		- Modified colors and better handling for quest complete as some quests weren't showing that it was complete when it actually was (such as Escort quests)

	Buttons.lua
		- Added failsafe code that when obtaining coordinate info from "W" button's tooltip that it will run RQE:StartPeriodicChecks() shortly thereafter (This only is applicable for author purposes with INFO debug requirement)

	Config.lua
		- Updated tooltip for debug menu in config panel to reflect that the INFO and INFO+ options are designed for author use only due to the amount of information that would be useless for the users/players

	Core.lua
		- Added utility function for table.includes
		- Cleaned up spacing in code
		- Updated RQE:CheckDBZoneChange() function to handle for multiple mapID checks in DB for a single CheckDBZoneChange check
		- Added information to tooltip to display step information when hovering over the QuestID/Name in RQEFrame as well as when hovering over the step frame
		- Modified colors and better handling for quest complete as some quests weren't showing that it was complete when it actually was (such as Escort quests)

	EventManager.lua
		- Added slight delay before running RQE:StartPeriodicChecks() function after PLAYER_LOGIN event fires
		- Fixed issue where objective progress wasn't reliably advancing to next steps with data in DB

	QuestingModule.lua
		- Modified colors and better handling for quest complete as some quests weren't showing that it was complete when it actually was (such as Escort quests)

	RQEDatabase.lua
		- Added/updated quests for legendary Battle for Azeroth cloak, "Ashjra'kamas, Shroud of Resolve"
		- Added some Hero Call quests to DB along with their updates
		- Added some Cata quests for Mount Hyjal zone to DB
		- Updated iconID to use "item:28372" instead of "item:118474" for SetRaidTarget(\"target\",7) macros
		- Updated DB for Alliance Hellfire Peninsula & Zangarmarsh quests
		- Updated DB quests for some of alliance Terokkar Forest quests

	RQEFrame.lua
		- Added information to tooltip to display step information when hovering over the QuestID/Name in RQEFrame as well as when hovering over the step frame
		- Modified colors and better handling for quest complete as some quests weren't showing that it was complete when it actually was (such as Escort quests)


11.0.7.4 (2024-12-28)

	*HIGHLIGHTS*
		- Ace3 Library Updates
		- Players can now click waypoint button of their choice to act as failsafe (even if the addon doesn't recognize that the player is on that step).
		- Updated info for failedfunct in DB (some quests have steps listed that have player fly to a new zone that aren't specifically part of the objectives) so that conditions no longer being met will revert player to earlier, more appropriate stepIndex

	Ace3
		- Library Updates

	Core.lua
		- Set RQE:StartPeriodicChecks() function call to not run if the player is on a taxi
		- Modified RQE:StartPeriodicChecks() function debug msgs
		- Updated failedfunct checks in RQE:StartPeriodicChecks() function
		- Corrected RQE:CheckDBZoneChange() function to now properly/better handle situation with failedfunct calls

	EventManager.lua
		- Commented information in code to state what event is firing when a call is being made within to the RQE:StartPeriodicChecks() function

	RQEDatabase.lua
		- Updated some code in the DB to include failedchecks in order to revert back to earlier stepIndex when a condition is no longer being met that advanced the quest to a new step

	RQEFrame.lua
		- Updated some debug to print info only if certain debug level is set in the configuration


11.0.7.4-Beta (2024-12-27)

	Core.lua
		- Commented out RQE:UpdateWaypointForStep(questID, stepIndex) function as this doesn't link to anything
		- Fixed memUsageText/RQE.memUsageText

	EventManager.lua
		- Added RQE.WaypointButtonHover true/false variable to ADDON_LOADED event function (used within RQEFrame.lua file)

	RQEFrame.lua
		 - Utilized RQE.WaypointButtonHover true/false respectively on WaypointButton:SetScript("OnEnter", function(self) and WaypointButton:SetScript("OnLeave", function()
		 - Added functionality to custom-click a stepIndex that the addon doesn't recognize you on to update waypoint, macros, etc


11.0.7.4-Alpha (2024-12-27)

	Buttons.lua
		- Moved waypointX, waypointY and waypointMapID within the RQE.UnknownButtonTooltip function so that these would be recognized and saved appropriately to the addon table

	Core.lua
		- Changed RQE:OnCoordinateClicked(stepIndex) function calls to RQE:OnCoordinateClicked() as the function doesn't have anything passed to it within the function itself
		- Removed duplicate RQE:TableToString function
		- Created addon table variable for the highestCompletedObjectiveIndex to be saved as RQE.highestCompletedObjectiveIndex
		- Created addon table variable for the memUsageText to be saved as RQE.memUsageText
		- Changed C_QuestLog.AddQuestWatch(RQE.BlackListedQuestID, 1) API call to C_QuestLog.AddQuestWatch(RQE.BlackListedQuestID) as watchType isn't being used in this case

	QuestingModule.lua
		- Created local variable of receipeName to be included in RQE:CreateRecipeTrackingFrame function call that is temporarily not used until it can be cleaned up
		- Uncommented section for the numTrackedBonusQuests and have this saved to the RQE addon table
		- Changed function call from UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement, lastBonusQuestElement) to UpdateChildFramePositions(lastCampaignElement, lastQuestElement, lastWorldQuestElement) as the lastBonusQuestElement isn't used with the bonus quests appearing within the Normal Quest Child Frame

	RQEDatabase.lua
		- Modified macro icons and waypoint/description information for the Shadowlands leveling campaign quests

	RQEFrame.lua
		- Changed RQE:OnCoordinateClicked(stepIndex) function calls to RQE:OnCoordinateClicked() as the function doesn't have anything passed to it within the function itself
		- Within checkRQEFrames:SetScript OnUpdate modified RQEQuestFrame (show/hide) to be RQE.RQEQuestFrame so that it would be recognizable

	WaypointManager.lua
		- Changed waypointTitle to title in the variable within the RQE:CreateWaypoint(x, y, mapID, title) function so that it would be better recognized


11.0.7.3 (2024-12-25)

	*HIGHLIGHTS*
		- Combined Campaign/Meta quests to be added under the previously called 'Campaign' Header and renamed to be 'Campaign/Meta'
		- Added functionality to track Bonus Quests of the player's current zone to the section under "Normal Quests"
		- Added "macro = { "" }," to quest steps, in the DB, that didn't already have a macro set as this would clear the macro when a new step was reached
		- Fixed LFG Creation tool for world boss resulting from a change to the API in 11.0.7 that changed activityID to activityIDs

	Buttons.lua
		- Additional debug tool added with mousing over the "W" Button to get chat to print out the waypoint, after it clicks the "W" Button

	Core.lua
		- Fixed nil error for questData.location at RQE.SaveCoordData function
		- Added RQE:GetBonusQuestsInCurrentZone() function to retrieve bonus quests that are in the player's current zone
		- Added RQE:GetAllQuestsInCurrentZone() and RQE:InspectTaskPOIs() functions for the sake of debugging only

	EventManager.lua
		- Changed local isTaskQuest = C_QuestLog.IsQuestTask(questID) to local isTaskQuest = C_QuestLog.IsQuestTask(questID) or C_QuestLog.IsThreatQuest(questID) within QUEST_WATCH_UPDATE event function

	QuestingModule.lua
		- Combined Campaign/Meta quests to be added under the previously called 'Campaign' Header and renamed to be 'Campaign/Meta'
		- Added functionality to track Bonus Quests of the player's current zone to the section under "Normal Quests"
		- Adjusted position of RQE.ClearBonusQuestElements() and RQE.AddBonusQuestToFrame() functions, within the file for better organization
		- Added functionality to click Bonus Quest so that it would open the quest details and map associated with that

	RQE.toc
		- Updated version#

	RQEDatabase.lua
		- Updated data for 'Legacy of the Vrykul' world quest in DB
		- Updated step info for 'Peak Precision' quest in DB
		- Updated description info for stepIndex 2 for the quest 'To the Siren Isle!' in DB
		- Updated step information for some quests in Tiragarde Sound (Battle for Azeroth expansion)
		- Added some end-game initial quests for Battle for Azeroth & some Legion zone breadcrumb quests to DB
		- Added "macro = { "" }," to quest steps, in the DB, that didn't already have a macro set as this would clear the macro when a new step was reached
		- Added some Cata and updated some Shadowlands quests in DB
		- Updated waypoint, macro, step info for DB on Shadowlands quests
		- Added additional details for Shadowlands quests and Winter Veil to DB

	RQEFrame.lua
		- Adds debug info to print coordText on mouse-over of the SeparateFocusFrameButton (removed for now)
		- Fixed RQE:LFG_Create(questID) due to an API change with C_LFGList.GetSearchResultInfo that changed activityID to activityIDs

	WaypointManager.lua
		- Fixed RQE:CreateWaypoint function designed to create custom waypoint if we have the x, y and mapID info (this is currently only utilized by manually running the function and isn't tied into any functions for auto running)


11.0.7.2 (2024-12-18)

	*HIGHLIGHTS*
		- Fix for hiding or closing RQE Frames, Hide Frames option in right click frame menu, and fix for Blizz Objective Tracker not showing up on press of LDB
		- Added initial quests for Siren Isle to DB

	Buttons.lua
		- Added setting to 'check' the enableFrame or enableQuestFrame when closing one of the frames with the "x" or close button

	Core.lua
		- Updated C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID) to be C_TaskQuest.GetQuestsOnMap(uiMapID) as the old was deprecated with patch 11.0.5 and will be removed in patch 12.0, being replaced by the new API variant
		- Updated GetMerchantItemInfo(index) to be C_MerchantFrame.GetItemInfo(index) as the old was deprecated with patch 11.0.5 and will be removed in patch 12.0, being replaced by the new API variant

	EventManager.lua
		- Added function that temporarily hides the RQEFrame and RQEQuestFrame for 10 seconds on right-click menu in these frames
		- Modified the macro update when PLAYER_MOUNT_DISPLAY_CHANGED

	QuestingModule.lua
		- Added option to Hide RQE Objective Tracker by right-clicking on quest in this frame

	RQE.toc
		- Update Interface version

	RQEDatabase.lua
		- Added additional Battle For Azeroth (alliance) quests to DB
		- Added some Twilight Highlands (Cataclysm/Alliance) quests to DB
		- Added initial quests for Siren Isle to DB

	RQEFrame.lua
		- Added option to Hide RQE Objective Tracker by right-clicking on quest in this frame for 10 seconds
		- Added option to Print Questline (if available) by right-clicking on quest in this frame

	RQEMinimap.lua
		- Fixed issue where closing the frames from the LDB button resulted in the Blizzard Objective Tracker not being displayed


11.0.7.1 (2024-12-15)

	Config.lua
		- Modified the supertracking toggles to be independent of each other and also added additional tooltip info for enableNearestSuperTrack

	Core.lua
		- Modified RQE.CheckAndClickWButton() to better check if there is data in the RQEDatabase if not, the "W" Button won't be pressed
		- Modified RQE:GetClosestTrackedQuest() to check that quest is being watched and added failsafe to supertrack a quest that returns as being part of that zone if nothing is still supertracked
		- Added RQE:CheckMemoryUsage() to RQE:StartPeriodicChecks() to get a better idea, for debugging, add-on's performance
		- Only print schematics (reagents needed) if debug is set to INFO+
		- Modified code within RQE.CheckAndClickWButton() to only fire in more specific circumstances by adding a flag
		- Added flag to avoid multi clicking the "W" button when stepIndex was 1, but that stepIndex required multi steps (such as the step requiring killing 12 bears before advancing to stepIndex 2)
		- Check added to make sure quest is being supertracked before attempting to click the "W" button
		- Removed a RQEMacro:ClearMacroContentByName("RQE Macro") as this was resulting in macro clearing at inappropriate times

	DebugLog.lua
		- Removed debug print when DebugLog is cleared

	EventManager.lua
		- Added functionality to UNIT_INVENTORY_CHANGED and PLAYER_ENTERING_WORLD to run RQE:StartPeriodicChecks() as long as player isn't in combat
		- Removed RQE:ClickWaypointButtonForIndex(1) from RQE.handleSuperTracking() as this was overriding the waypoint location of what is specified in the DB when step 1 waypoint location differs from the waypoint under the "W" Button
		- Removed set to Waypoint Step One after SUPER_TRACKING_CHANGED as this might interfere with method to properly set stepIndex
		- Moved RQE:StartPeriodicChecks() into  nested check to first see if something was being supertracked in the PLAYER_ENTERING_WORLD event
		- Updates player coordinates (above RQEFrame) after PLAYER_MOUNT_DISPLAY_CHANGED (mounting/dismounting), PLAYER_CONTROL_GAINED (post-taxi with slight delay), & UPDATE_INSTANCE_INFO events (such as new dungeon/jumping into the Maw)
		- Updates player mapID (above RQEFrame) after UPDATE_INSTANCE_INFO event
		- Added BAG_NEW_ITEMS_UPDATED to better handle for CheckDBInventory check in DB
		- Set RQE:StartPeriodicChecks() to run after combat finishes
		- Added call to update mapID and coordinates to area above RQEFrame on zone change
		- Added flags for click of the "W" button within the RQEFrame so that it fires at more appropriate times and nixing much of the potential redundancy (including one that checks numfullfilled vs required to avoid clicking button multiple times when the stepIndex remains at 1)
		- Added function to close the RQEFrame and RQEQuestFrame and show the Blizzard Objective Tracker so that players could use run macro to complete quests that were completed via the Blizzard Objective Tracker

	RQE.toc
		- Update version# with the upcoming release of patch 11.0.7

	RQEDatabase.lua
		- Removal of quest data not currently in the DB
		- Added side quests of Bastion, Maldraxxus, Ardenweald, and Revendreth to DB
		- Added Night Fae, Venthyr, Kyrian & Necrolord campaign quests to DB
		- Added additional callings for the 4 covenants (Shadowlands) to DB
		- Added 'Among the Kyrian' and 'Torghast' chapters of Kyrian campaign to DB
		- Added Chains of Domination Korthia campaign (Shadowlands) to DB
		- Added remainder of Zereth Mortis campaign quests to DB
		- Fixed some quests for the Darkmoon Faire for the CheckDBObjectiveStatus and CheckDBComplete as well as cleaned up for Blacksmithing quest in Darkmoon Faire to better handle item count checks
		- Added Enchanting weekly Dornogal questID 84084 to DB
		- Changed some questTitles in DB to move the type of quest to commented out lines when it comes to the profession of the Darkmoon Faire quests
		- Modified questID 29509 to include CheckDBInventory for cleaner macros
		- Updated waypoints, macros, etc for Maw and some Bastion campaign quests in DB
		- Updated Bastion, Maldraxxus, Ardenweald and Revendreth leveling campaign quests to DB
		- Added many of the initial quests for Battle for Azeroth to the DB

	RQEFrame.lua
		- Modified totalHeight of the RQEFrame content to handle larger numbers of quest steps

	QuestingModule.lua
		- Better handle if mouse is over the RQEQuestFrame when handling updates - this GREATLY improves memory performance from ~20mb to 7mb

	WPUtil.lua
		- Commented out/removed code that dealt with opening the quest details/map when determining coordinates for quest (this is no longer needed as the DB will contain most of these waypoints and keeping this was resulting in complication of the map opening at inappropriate times.


11.0.5.2 (2024-11-26)

	Core.lua
		- Function that checks to see if quest is in the DB already and if it needs to be updated with new quest details

	DatabaseMain.lua
		- Added code to distinguish between quests in the various levels of the Warlords of Draenor garrison (as there are different pickup/turn-in coordinates for these quests based on garrison level)

	EventManager.lua
		- Function call that checks to see if quest is in the DB already
		- Cleaned up old/unused debug code

	RQEDatabase.lua
		- Added Borean Tundra, Howling Fjord, Grizzly Hills, Sholazar Basin, Storm Peaks Icecrown, Dragonblight, and Zul'Drak (Alliance) quests
		- Added Shadowmoon Valley (Warlords of Draenor-Alliance), Gorgrond, Talador, Spires of Arak and Nagrand quests to DB
		- Added Maw introduction quests from Shadowlands expansion, as well as Bastion, Maldraxxus, Ardenweald and Revendreth campaign quests
		- Added 'Cursed Tome' quest picked up from Shadowmoon Valley (Draenor) which is part of the Legion expansion of quests
		- Added many horde zone intro quests to DB
		- Added some weekly quests (including more in Dornogal) and cleaned up DB
		- Added some raid quests to DB for Castle Nathria and Sanctum of Domination

	RQEFrame.lua
		- Modified SearchGroup search section to work better for world quests (such as world bosses)
		- Fixed SearchGroup for LFG to better work between the various world bosses as some weren't showing up in the search

	WaypointManager.lua
		- Fixed nil error related to Waypoint creation system when questID is unknown/unlisted


11.0.2.47 (2024-10-29)

	Core.lua
		- Added function that checks to see if questData or steps exist in the RQEFrame and if not function will continue where it will click the "W" button in the RQEFrame
		- Added function in preparation of tracking certain event quests (such as the pumpkin quests)
		- Fixed table index nil error for taskPOI.questId
		- Require that the RQEFrame be shown before it will track nearest quest (this was a fix for a nil error)

	EventManager.lua
		- Clicks "W" Button upon PLAYER_ENTERING_WORLD, PLAYER_LOGIN, QUEST_WATCH_UPDATE, UNIT_QUEST_LOG_CHANGED, and ZONE_CHANGED_NEW_AREA if autoClickWaypointButton is a selected option by the player
		- Require that the RQEFrame be shown before it will track nearest quest (this was a fix for a nil error)

	QuestingModule.lua
		- Added RQE.CheckAndClickWButton() function call to be run when the QuestLogIndexButton in the RQEQuestFrame is pressed by player

	RQEDatabase.lua
		- Updates/Additions to quests in the DB
		- Cleaning up TBC and Wrath quests in the DB
		- Added Hero's Call (Hero's Call Board) quests to the DB
		- Added many Hellfire Peninsula, Zangarmarsh, Nagrand, Terokkar Forest, Netherstorm, and Shadowmoon Valley (Alliance) quests
		- Added Candy Buckets across Azeroth (more to come)
		- Added additional weekly quests in Dornogal

	RQEFrame.lua
		- Added function in preparation of tracking certain event quests (such as the pumpkin quests)

	WaypointManager.lua
		- Fixed nil error related to RQE.QuestIDText or missing questID at time of extractedQuestID


11.0.2.46 (2024-10-15)

	Buttons.lua
		- Added RQE.hoveringOnRQEFrameAndButton to be marked true/false based on if the player is hovering over the RQE.UnknownQuestButton within the RQEFrame or not
		- Added RQE:SaveSuperTrackedQuestToCharacter() when ClearButton is pressed in the RQEFrame
		- Cleared commented out function that has been resolved already
		- Fixed issue where groups for World Bosses either prevented existing groups from being located or your current group from being visible
		- Modified tooltip over the "W" button as it was using continentID instead of mapID to display waypoint tooltip (not impacting waypoint creation, only the tooltip itself)

	Config.lua
		- Added enableNearestSuperTrackCampaignLevelingOnly option to the settings panel and configuration frame

	Core.lua
		- Added (preliminary) function for the purpose of adding tradeskill tracking to the RQEQuestFrame (currently not clickable, only shows up in the RQEQuestFrame)
		- Added code to re-supertrack world quests in addition to the campaign/regular quests that could be re-supertracked as last quest, but runs a check to make sure that that WQ is available
		- Added RQE.CheckQuestInfoExists() for the purpose of clearing the Focus Frame when it should be blank as nothing is being tracked
		- Added function to print the mapID, x and y position for the C_QuestLog.GetNextWaypointForMap, using the GetQuestUiMapID to obtain a quests appropriate mapID
		- Adjusted frameHeight, frameWidth, xPos and yPos of RQEFrame and RQEQuestFrame
		- Modified RQE:GetClosestTrackedQuest() to take into account for campaign quests at max level vs leveling up (an option for the player to potentially level up through the campaign but super track the nearest quest in general at max level)
		- Set enableNearestSuperTrackCampaignLevelingOnly option as 'false' by default

	EventManager.lua
		- Added check to potentially clear macro and FocusFrame on ZONE_CHANGE... and QUEST_WATCH_LIST_CHANGED
		- Added check to find if Focus Frame should be cleared as nothing is being super tracked when UPDATE_INSTANCE_INFO event function is fired
		- Added check to RQE:StartUpdatingCoordinates() within PLAYER_STARTED_MOVING event only if this is selected (in order to save on memory usage)
		- Added event function to listen for TRACKED_RECIPE_UPDATE for the tracking of the tradeskill in the RQEQuestFrame
		- Fix for UNIT_AURA to change filter to arg5 (previously had two arg4)
		- Added RQE:UpdateContentSize() to PLAYER_STARTED_MOVING and SUPER_TRACKING_CHANGED event functions
		- Adjusted yPos of RQEQuestFrame
		- Fixed QUEST_ACCEPTED to now automatically track all quests (such as Meta) when they are accepted
		- Removed section of ClearMacroContents within PLAYER_STARTED_MOVING as this is redundant and accomplished further down in the code
		- Set RQE.hoveringOnRQEFrameAndButton as 'false' by default on ADDON_LOADED event
		- Set restoration of Frame Position for the RQEFrame on ADDON_LOADED to prevent frame from sometimes glitching out and moving to inappropriate location and changing your positional preference

	QuestingModule.lua
		- Adjusted yPos of RQEQuestFrame
		- Added child frame for the tracking of tradeskill in the RQEQuestFrame

	RQEDatabase.lua
		- Added MANY more side quests for TWW expansion

	RQEFrame.lua
		- Adjusted frameHeight, frameWidth, xPos and yPos of RQEFrame and its anchor point
		- Modified totalHeight calculation within RQE:UpdateContentSize(), which is responsible for handling the height of the RQEFrame and allow proper scroll function
		- Fixed issue where groups for World Bosses either prevented existing groups from being located or your current group from being visible
		- Fix for the RQEFrame to update the correct frame size and position on resize and dragging as this SetScript was missing

	RQEMacro.lua
		- LUA error fix: Add-on will not clear the macro if player is inside an raid or dungeon group while inside an instance or in combat

	WPUtil.lua
		- Run RQE:StartPeriodicChecks() when player manually presses the "W" button in the RQEFrame (this prevents this weighty function from being called automatically through other functions firing that interact with the RQE.UnknownQuestButtonCalcNTrack function


11.0.2.45 (2024-10-04)

	Buttons.lua
		- Modified function behind the button click for the 'Search Group' button (this is used to create/list or search for groups for quests of such things like World Bosses

	Core.lua
		- Added qualityString for criteriaInfo for GetCriteriaInfoByStep and GetCriteriaInfo

	EventManager.lua
		- Added RQE:UpdateMapIDDisplay() to PLAYER_CONTROL_GAINED event (follows after getting off taxi)

	QuestingModule.lua
		- Nil fix for criteriaInfo within UpdateScenarioFrame function

	RQEDatabase.lua
		- Added more quests to DB

	RQEFrame.lua
		- Modified the functions that control the searching for and creation of group for the world boss that is called when the button is clicked from Buttons.lua that was edited in this update
		- Ensured that the questID used was not looking at a global questID potentially causing conflicts with other add-ons


11.0.2.44 (2024-10-02)

	Core.lua
		- Created ability to restore last super tracked quest on login of character (questID is saved anytime there is a super track change to the character-specific DB and restored on login) as long as player still has that quest
		- Fix made for the CreteMacroForCurrentStep call within RQE:ClickWaypointButtonForIndex(index) function to have the appropriate flag usage
		- Temporarily had SearchBox and SearchButton initialized in InitializeFrame, within Core.lua but moved back to RQEFrame.lua
	
	EventManager.lua
		- Added flags for QUEST_WATCH_UPDATE and SUPER_TRACKING_CHANGED that prevent UNIT_QUEST_LOG_UPDATE from firing immediately after (some quests may not fire QUEST_WATCH_UPDATE when progress is made, but UNIT_QUEST_LOG_UPDATE does fire). Flags are reset at start with QUEST_LOG_UPDATE if they exists.
		- Added additional flags for ITEM_COUNT_CHANGED
		- Added macro check to PLAYER_STARTED_MOVING if not flying, mounted or using taxi and if the macro is empty and removed it from PLAYER_REGEN_ENABLED (leaving combat) as this was causing lag after combat ended.
		- Cleaned up code under ADDON_LOADED & SUPER_TRACKING_CHANGED event functions
		- Created events on PLAYER_LOGIN to restore last super tracked quest

	QuestingModule.lua
		- Added method for the saving of super tracked quest when super tracking has been changed under the UpdateRQEQuestFrame() and UpdateRQEWorldQuestFrame() functions

	RQE.toc
		- Reordering of load list

	RQEFrame.lua
		- Added method for the saving of super tracked quest when super tracking has been changed under the RQE.ClickUnknownQuestButton() function


11.0.2.43 (2024-09-28)

	Config.lua
		- Added enableNearestSuperTrackCampaign options
		- Added showPlayerMountDisplayChanged and separated it from showPlayerRegenEnabled
		- Added enableGossipModeAutomation to allow/disallow for function of macro operation with Gossip function calls

	Core.lua
		- Added enableGossipModeAutomation to local defaults with turned off as this is fairly experimental and may result in some breakage if changes are made by Blizzard in the future to the index or NPC names
		- Added failsafe that UpdateFrame won't fire unless something is being super tracked. This should improve the overall efficiency of the add-on's operation
		- Added failsafe to RQEMacro:CreateMacroForCurrentStep() when CheckQuestObjectivesAndPlaySound() fires a sound for objective complete or quest complete
		- Reverted bits of the file to 11.0.2.41 to fix SeparateFocusFrame waypoint button being missing and re-enabled the performance fixes from 11.0.2.42
		- Set default to display 'showPlayerMountDisplayChanged' as false in local defaults

	EventManager.lua
		- Added RQE:GetClosestTrackedQuest() / RQE.TrackClosestQuest() to various events as well as a timed delay to the one associated with the PLAYER_ENTERING_WORLD
		- Added UPDATE_SHAPESHIFT_COOLDOWN and UPDATE_SHAPESHIFT_FORM to check for macro if not in combat, not in instance and macro is empty to ensure that it gets updated just as is done with PLAYER_MOUNT_DISPLAY_CHANGED for non-druids (commented this out for now until I can get better addon performance with this enabled)
		- Added UNIT_ENTERING_VEHICLE to check quest step status/macro operation when entering another player's vehicle to accommodate for similar circumstance as PLAYER_MOUNT_DISPLAY_CHANGED if not doing 2-player/multi-mount mounting
		- Separated PLAYER_MOUNT_DISPLAY_CHANGED from PLAYER_REGEN_ENABLED and added failsafe to new PLAYER_MOUNT_DISPLAY_CHANGED event handler to check macro contents if they are correct with quest's current step

	QuestingModule.lua
		- Commented out BonusObjectiveChildFrame for now as it was improperly operating
		- Reverted to pre-BonusObjectiveChildFrame for anchor update functions

	RQEDatabase.lua
		- Added RQE.SelectGossipOption to macro section for questID 78631 for testing and eventual expansion (along with other additional quests following this)
		- Fixed neededAmt for questID 78383's objectiveIndex 2 as it was stuck and wouldn't advance the WaypointButton further

	RQEFrame.lua
		- Fixed issue where the SeparateFocusFrame was extending beyond the RQEFrame and preventing clicks of the buttons in the RQEQuestFrame or interacting with some of the top-most quests in that frame


11.0.2.42 (2024-09-26)

	- Performances fixes as add-on would lag spike between some quest objectives


11.0.2.41 (2024-09-26)

	Buttons.lua
		- Created system of saving waypoint information to a variable to be used in waypoint creation under the automation system
		- Fixed macro not being cleared when the "C" ClearButton was pressed within the RQEFrame
		- Modified code for the "C" Clear Button to better handle clearing the frame (focus frame, in particular) when pressed.
		- Moved "C" ClearButton script function outside of the button so that it could be more easily called
		- Removed SetPropagateMouse code

	Config.lua
		- Utilized different method for calling function to ensure persistent update of the RQEMagicButton key binding between sessions

	Core.lua
		- Added check for if player was in party/raid instance and if so, not to update/check macro (prior to this existing there was a momentary bump in lag whenever it checked which was more noticeable in these environments)
		- Added function that is responsible for checking and tracking closest quest
		- Added nil check for questData within the RQE:CheckScenarioStage(questID, stepIndex) function
		- Changed way that isSuperTracking is handled by running a function that checks the RQEFrame, but kept the original method of API in case RQEFrame is empty but quest is being super tracked
		- Created separate function that creates a tooltip as this needed to be able to accommodate for the Bonus Objective quests
		- Creates/checks macro status when RQE:StartPeriodicChecks runs to see if it has the correct macro in place
		- Moved RQE.InitializeSeparateFocusFrame() function call outside of the debug statement so that it would fire appropriately
		- Removed SetPropagateMouse code
		- Fix for WQ not being removed when it should've been cleared from the RQEQuestFrame
		- Fixed text that gets used when checking the add-on memory usage above the RQEFrame
		- Start of work in adding counter for the bonus quests to be counted in the world quest frame
		- Adjusted x, y of RQEFrame and RQEQuestFrame default location to not interfere with default minimap location

	DebugLog.lua
		- Removed SetPropagateMouse code

	EventManager.lua
		- Added calls to start/stop/update timer that would give timer in scenario that persists between reloads
		- Added check when PLAYER_STARTED_MOVING that if not in a scenario and nothing super tracked it will clear the RQEFrame and macro if it exists
		- Added enableNearestSuperTrack for PLAYER_ENTERING_WORLD event
		- Added functionality for the RQEFrame to scroll to top under zone change occurs as long as player isn't mousing over the RQEFrame at the time
		- Added modification to have dynamic height for scenario child frame based on number of criteria
		- Added some calls to add/remove non-world quests when QUEST_ACCEPTED and QUEST_REMOVED fire to act as a failsafe
		- Code cleanup
		- Fixed bug that resulted in WQ being tracked that shouldn't be and proper removal when leaving the area of those automatically accepted WQ
		- Fixed error with ToggleFramesAndTracker attempting to run while in combat
		- Fixed to be sure to run UpdateRQEWorldQuestFrame() when a quest is accepted as normal triggers don't fire with bonus objectives
		- Removed (commented out) enableNearestSuperTrack for PLAYER_LOGIN event as this is now covered by the optimal PLAYER_ENTERING_WORLD
		- Simulated click of "C" ClearButton when quest turned in and nothing is being super tracked
		- Utilized different method for calling function to ensure persistent update of the RQEMagicButton key binding between sessions

	QuestingModule.lua
		- Added Bonus Objectives child frame & GatherAndSortBonusQuestsByProximity
		- Added check for scenario to update the frame when the RQEFrame/RQEQuestFrame are re-opened
		- Added dynamic height adjustment for scenario child frame
		- Added functionality to track bonus objectives when player is at that location
		- Added questClassification to better understand if a freshly acquired quest was a bonus quest or something else
		- Corrected anchoring of child frames
		- Fix made that was preventing bonus objective quests from showing up in the RQE Quest Tracker or being removed when either QUEST_ACCEPTED or QUEST_REMOVED events fired
		- Modified height and position of the child frames, adjusted anchoring with child frames
		- Modified position of the QuestLevel and Name associated with the Bonus Objective quest
		- Modified the size of the child frames
		- Removed some debug messages
		- Reverted GatherAndSortWorldQuestsByProximity function to older version as Bonus Objectives are placed in their own child frame
		- Timer associated with scenario will persist between /reloads and reads how long player has been inside that instance/scenario

	RQEDatabase.lua
		- Added some non-campaign leveling quests from Isle of Dorn to the DB
		- Updated waypoints on some quests in Hallowfall

	RQEFrame.lua
		- Added visible slider with animation as aid/option for scrolling the RQEFrame
		- Fixed SeparateFocusFrame so that it would no longer be moveable
		- Modified InitializeSeparateFocusFrame to display how many stepIndex (waypoint buttons) exist for a particular quest to better aid player in where they are in the chain of events for super tracked quest.
		- Modified the totalHeight of RQE.content in the RQE:UpdateContentSize() function as it was too large making scrolling a bit of a headache
		- Removed SetPropagateMouse code
		- Renamed the RQEFrame header to be "RQE Quest Helper" to better describe its function

	RQEMacro.lua
		- Fix 'EditMacro' error received, script rang too long
		- Fix for RQEMagicButton keybinding not working

	RQEMinimap.lua
		- Fix issue with RQE:ToggleFramesAndTracker() being protected and unable to close, thru toggle during combat.
		- Added another method to check the text of the RQEFrame for possible super track questID

	WaypointManager.lua
		- Added code to save x, y and mapID into addon table when RQE:OnCoordinateClicked(stepIndex) function fires as a means to attempt to correct issue where waypoint created was from previous stepIndex's waypoint from the DB

	WPUtil.lua
		- Added system to save coordinate data to a specific variable as the quest progress moves through the objectives


11.0.2.40 (2024-09-14)

	Buttons.lua
		- Modified code for the "C" Clear Button to better handle clearing the frame (focus frame, in particular) when pressed.
		- Removed SetPropagateMouse code

	Core.lua
		- Added nil check to RQE:ClearSeparateFocusFrame() to make sure it first exists
		- Modified and fixed RQE:ClearSeparateFocusFrame() to obtain questID (current supertracked questID), stepIndex and stepData as some variables were returning nil

	DebugLog.lua
		- Removed SetPropagateMouse code

	EventManager.lua
		- Fixed nil error with waypoint click in QUEST_WATCH_UPDATE and SUPER_TRACKING_CHANGED events
		- Added RQE:StartPeriodicChecks() for CheckDBZoneChange (tested with questID 79197) to run after ZONE_CHANGED_NEW_AREA event (which ticks when mapID changes)
		- Added enableNearestSuperTrack for QUEST_WATCH_LIST_CHANGED event
		- Fixed PLAYER_LOGIN event for DB file fetching in Saved Variables

	RQEDatabase.lua
		- Added quests from Hallowfall and Azj-Kahet to DB
		- Fix of some spelling errors
		- Fix questID 78642 in the database in terms of values

	RQEMacro.lua
		- Fix 'EditMacro' error received


11.0.2.39 (2024-09-13)

	Core.lua
		- Fixed RQE:StartPeriodicChecks() as CheckDBObjectiveStatus wasn't updating the waypoint and now it is. Tentative switch for CheckScenarioStage and CheckScenarioCriteria but will need further testing to be sure same fix worked
		- Modified waypoint creation to correctly 'click' the applicable waypoint - this was previously clicking earlier 'clicked' waypoints in the RQEFrame

	EventManager.lua
		- Modified ITEM_COUNT_CHANGED, BAG_UPDATE, MERCHANT_UPDATE, and UNIT_INVENTORY_CHANGED events to use string.find just as was done in the RQE:StartPeriodicChecks() function in Core.lua
		- Fixed nil error with waypoint click in SUPER_TRACKING_CHANGED event

	RQEDatabase.lua
		- Modified waypoint coordinate for a few quests in Ringing Deeps

	WaypointManager.lua
		- Created backup method for waypoint creation (for testing purposes)


11.0.2.38 (2024-09-12)

	Core.lua
		- Removed flags in RQEMacro:CreateMacroForCurrentStep() and RQE:StartPeriodicChecks() as not working as desired
		- Added 'CheckScenarioStage' and 'CheckScenarioCriteria' as options for auto waypoint/stepIndex advancement
		- Added RQE:UpdateSeparateFocusFrame() to end of RQE:StartPeriodicChecks()

	EventManager.lua
		- Fixed nil error caused on lines 1780 and 2455: RQE.WaypointButtons[RQE.AddonSetStepIndex]:Click()
		- Validation to stepData.funct before use in UNIT_AURA
		- Added RQE:StartPeriodicChecks() to SCENARIO_UPDATE event
		- Added RQE:StartPeriodicChecks() to UNIT_QUEST_LOG_CHANGED event
		- Removed (commented out) several RQE:UpdateSeparateFocusFrame() as this was added to end of RQE:StartPeriodicChecks()

	QuestingModule.lua
		- Code cleanup

	RQEDatabase.lua
		- Modifications to some of the Darkmoon Faire profession weekly quests
		- Fixed questID 78741 check funct used in step 2
		- Updated questID 78642 to include those steps from that scenario quest

	RQEFrame.lua
		- Code cleanup


11.0.2.37 (2024-09-05)

	Buttons.lua
		- Added flag for RQE.ClearButtonPressed

	Config.lua
		- Added option to debug settings to show debug messages from StartPeriodicChecks function

	Core.lua
		- Added flag priority for RQE:StartPeriodicChecks() function to limit the number of calls to this function to determine if it is time to advance the stepIndex (waypoint button denoted by a number in the RQEFrame/super-track frame)
		- Added flag system for RQEMacro:CreateMacroForCurrentStep() for efficiency and went different code slightly with RQE:StartPeriodicChecks(), while code is new and works in current form, flags are not yet properly in place. The RQE:StartPeriodicChecks() will be ready for the update once flags are ready
		- Fixed issue with RQEQuestFrame:IsShown and RQEQuestFrame:Show to be RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsShown()

	DebugLog.lua
		- Cleaned up code

	EventManager.lua
		- Created system of flags before and after the event firings call the RQE:StartPeriodicChecks() function to check if it should advance the stepIndex
		- Added ability to remove Raid Marker from target when QUEST_ACCEPTED or QUEST_FINISHED fires
		- Added additional requirements for selection before some Scenario-type debugs would print to chat
		- Changed RQEQuestFrame and not RQEQuestFrame:IsShown() to be RQE.RQEQuestFrame and not RQE.RQEQuestFrame:IsShown()
		- Cleaned up code

	RQEDatabase.lua
		- Added some additional description to some quests to make it easier to understand location of certain NPCs/objects, etc

	RQEMacro.lua
		- Fixed stack overflow LUA error from the RQE.CheckCurrentMacroContents() function
		- Removed old code relating to combat checks since macros update just fine while in combat

	WaypointManager.lua
		- Fixed error of DatabaseSuperX, DatabaseSuperY being saved as globals vs more efficient addon namespace

	Misc.
		- Switched many macro creation functions to the newer RQEMacro:CreateMacroForCurrentStep() function call that does a more efficient job and has checks to make sure that the macro is correct. If correct, it won't run further - making add-on more efficient at handling memory resources and lag
		- Added note of compatibility issue between RQE and World Quest Tracker add-on in the TOC. A notation is currently listed on the RQE Curseforge page. This is something that doesn't exist if either RQE or WQT are used, but manifests in the form of some quests being listed as world quests when they shouldn't be. Problem goes away when WQT is disabled.


11.0.2.36 (2024-09-04)

	Config.lua
		- Added DebugLog Toggle in Debug Setting in Configuration Frame

	Core.lua
		- Created flags between QUEST_ACCEPTED and SUPER_TRACKING_CHANGED
		- Added RQEMacro:CreateMacroForCurrentStep() function that creates macros based on current step of current super tracked quest and, before proceeding, checks to see if current macro (if exists) matches what it should be

	DebugLog.lua
		- Added functionality to only send info to debug log for storage if box is checked in Configuration Frame
		- Added ability to clear Debug Log via slash command

	EventManager.lua
		- Added flags between QUEST_ACCEPTED and SUPER_TRACKING_CHANGED to increase efficiency/performance of add-on
		- Re-enabled functionality to supertrack nearest tracked (watched quest). This was a feature in 11.0.2.35 release from 2004-09-02, but had been temporarily purged to conduct fixes to performance and bugs

	QuestingModule.lua
		- Reverted to QuestingModule from 2024-09-02.1726 as WQ were being hidden and made slight changes so some non-world quests wouldn't be counted but WQ would remain counted and listed

	RQEFrame.lua
		- Cleared out some of the code that was used in the creation of macros that was duplicative and potentially impacting add-on performance
		- Added functionality that requires modifier key be held to scroll master status frame when hovering over it, otherwise the RQEFrame (super track frame remains focus of scrolling)

	RQEMacro.lua
		- Cleared unused debug msg
		- Fixed RQE.CheckCurrentMacroContents() function so it once again checks to see if existing macro is the expected macro

	WaypointManager.lua
		- Cleared unused debug msg


11.0.2.35 (2024-09-02)

	Buttons.lua
		- Added RQE:ClearSeparateFocusFrame functionality to the ClearButton in the RQEFrame

	Config.lua
		- Added additional options for debugging in Config Frame.
		- Added option that super track the nearest quest, if super track frame is empty when QUEST_FINISHED event fires (default: on). Placed this option in settings panel and configuration frame
		- Modified order numbers to accommodate addition of Blizzard objective frame toggle option

	Core.lua
		- Updated debug prints with RQE.CheckThatQuestStep() -- this is a 'disconnected function' that is able to only be run using the in-game /run command in order to act as a debugging tool for quest progression
		- Added new setting to save Waypoint value (RQE.AddonSetStepIndex) to prevent RQEFrame from overriding when autoClickWaypoint is actively assisting player in quest step guidance (this would manifest by going to inappropriate waypoint buttons as quest progression occurred).
		- Added additional 'defaults' to set for the additional config options added to the Config Frame.
		- Added function to get the nearest super track questID
		- Added RQE:ClearSeparateFocusFrame function to clear the newly created master status frame within the RQEFrame

	DebugLog.lua
		- DEFAULT_CHAT_FRAME:AddMessage() will now be displayed in the DebugLog

	EventManager.lua
		- Commented out most of the code within RQE.handleUnitQuestLogChange function as much of what is done here is already handled through the QUEST_WATCH_UPDATE event that gets fired before it
		- Optimized QUEST_WATCH_UPDATE event listener to improve efficiency of the add-on as increased lag was sometimes noticed when this event fired as a result of a quest being completed.
		- Settings added for when RQE.AddonSetStepIndex should be initialized and reset
		- Added better visibility to debug messages based on new setting added to 'Debug' section of the Config Frame.
		- Removed (commented out) many events that are redundant and were causing massive performance issues (particularly as player would progress through more and more quests)
		- Added code to set super track to nearest quest, if enableNearestSuperTrack is enabled (default: on) when QUEST_FINISHED event fires

	QuestingModule.lua
		- Added fix for WQ header being displayed when none are selected (some quests were returning with the C_QuestLog.GetNumWorldQuestWatches() API even though they weren't actually WQ as determined thru C_QuestLog.IsWorldQuest(questID)
		- Commented out defunct code

	RQEDatabase.lua
		- Modified some quests in the neededAmt and objectiveIndex as some quests with multiple steps associated with a single objective need to start off a neededAmt of 0, some with a neededAmt of 1 (based on how the add-on is reading this step/its 'objective')
		- Improvements to the information from the pre-Isle of Dorn quests

	RQEFrame.lua
		- Switched some debug code to only print if INFO+ debug level is active
		- Created a master status frame that states which stepIndex you're on and what the stepIndex description reads (to avoid need to scroll with each stepIndex progression made)

	WaypointManager.lua
		- Added nil checks

	Misc.:
		- Cleaned up code (including spacing and indents).


11.0.2.34 (2024-09-01)

	Core.lua
		- Major improvements to the performance of the add-on
		- Corrected for nil error in RQE:CheckObjectiveProgress function
		- Many debugs added to solve issue with quest steps not advancing when the quest steps are listed in the RQEDatabase
		- Implemented new changes into the RQE:StartPeriodicChecks()
		- Cleaned up code and debug msgs to be swapped over the RQE.debugLog/RQE.infoLog instead of print

	EventManager.lua
		- Improved performance as associated with the SCENARIO_CRITERIA_UPDATE listener running too often and using a lot of resources (particularly loading screens when zoning out of story instances)
		- Added a display memUsageText with each event listener that fires to check if certain events are causing problems
		- Removed extra bits of RQE:StartPeriodicChecks() from some of the listeners that were slowing performance of the add-on by doing redundant/repeat checks of this hog of a function

	RQEDatabase.lua
		- Many updates for quests (some quests need to have their first neededAmt of the first objectiveIndex set to 0 instead of 1, more changes may be further needed as debugging continues)
		- Modifications to some quests to fix waypoints

	RQEFrame.lua
		- Fix to performance problems and with quests not advancing properly from one stepIndex to the next


11.0.2.33-beta (2024-09-01)

	Core.lua
		- Implemented new changes from RQE.CheckThatQuestStep() into the RQE:StartPeriodicChecks()
		- Major improvements to the performance of the add-on

	EventManager.lua
		- Added a display memUsageText with each event listener that fires to check if certain events are causing problems
		- Removed extra bits of RQE:StartPeriodicChecks() from some of the listeners that were slowing performance of the add-on by doing redundant/repeat checks of this hog of a function

	RQEDatabase.lua
		- Many updates for quests (some quests need to have their first neededAmt of the first objectiveIndex set to 0 instead of 1, more changes may be further needed as debugging continues)

	RQEFrame.lua
		- Commented out the added debug print msgs as they are no longer needed (or at least not at this time since seemingly fixing the quest advancement and performance problems)


11.0.2.33-alpha (2024-09-01)

	Core.lua
		- Corrected for nil error in RQE:CheckObjectiveProgress function
		- Many debugs added to solve issue with quest steps not advancing when the quest steps are listed in the RQEDatabase

	EventManager.lua
		- Improved performance as associated with the SCENARIO_CRITERIA_UPDATE listener running too often and using a lot of resources (particularly loading screens when zoning out of story instances)
		- Added several print debugs associated with 'RQE.LastClickedButtonRef.stepIndex being set to 1' (this is temporary)

	RQEDatabase.lua
		- Modifications to some quests to fix waypoints

	RQEFrame.lua
		- Potential fix in place to keep RQE.LastClickedButtonRef and WaypointButton.stepIndex from resetting to "1" when in the middle of a quest (this is having the effect of setting the stepIndex/waypoint button to 1 and preventing advancement without a reload


11.0.2.32 (2024-08-31)

	Buttons.lua
		- Removed unneeded code for preventing some code from running during combat - this appeared to be an error when this is actually taint and most of what I run should be fine to update their own frames in or out of combat

	Config.lua
		- Removed some debug print lines

	Core.lua
		- Removed unneeded code meant to prevent taint (handling different way for now)
		- Add ability to select specific gossip option based on macro in the RQEDatabase (when available)

	DebugLog.lua
		- Reverted to a previous version of the DebugLog before I did button checks to determine cause of taint.

	EventManager.lua
		- Added GOSSIP_CLOSED, GOSSIP_CONFIRM, GOSSIP_CONFIRM_CANCEL, and GOSSIP_SHOW events along with set up for the add-on to automatically chose gossip option for an NPC based on macro in RQEDatabase
		- Removed unneeded code meant to prevent taint

	QuestingModule.lua
		- Removed some code that was setting RQE.shouldCheckFinalStep flag to false when may be causing problems with advancing steps
		- Removed unneeded code meant to prevent taint

	RQEDatabase.lua
		- Added more code and detail to The Rising Deeps (now all three chapters are in the RQEDatabase and able to be accessed by the RQEFrame when super tracked
		- Added initial steps into Hallow Fall zone to the database

	RQEFrame.lua
		- Add additional bits to run function to update frame size when number of steps may exceed window size of the frame.
		- Removed unneeded code meant to prevent taint

	RQEMacro.lua
		- Code clean-up

	Taintless.XML
		- Added to file to reduce issues with such things like Button and Frame Pass-Thru errors that don't effect the overall functionality of the add-on, but are a nuisance unless you have BugSack/BugGrabber addons
		
	WPUtil.lua
		- Removed unneeded code meant to prevent taint


11.0.2.31 (2024-08-30)

	Buttons.lua
	Core.lua
		- Fix of error stemming from UpdateFrame function, in Core.lua that some bits weren't allowed to be fired in combat - this this function is now fixed
		- Updated function name for the colorize objective function in Core

	EventManager.lua
		- Added flags to be checked following combat ending to see if functions need to be run that were attempted to have been run while combat took place

	QuestingModule.lua
	RQEFrame.lua
		- Updated function name for the colorize objective function
		- Added InCombatLocked at top of colorize function located here


11.0.2.30 (2024-08-29)

	Core.lua
		- Set a number of flags to default values that will trigger if certain functions fire during an event while combat is in progress. That flag is then checked to re-run the paused function once combat terminates
		- Sorted list of flags

	EventManager.lua
		- Fix to propagate error related to RQE:QuestTypes() firing during SUPER_TRACKING_CHANGED event - made so it would re-run function after combat ends
		- Added additional checks after combat ends (PLAYER_REGEN_ENABLED event) to re-run functions if flag passes as true because an earlier attempt, during combat, was made to run said function

	QuestingModule.lua
		- Added Rewards Tooltip for the RQEFrame (SuperTrack quest frame) and the RQEQuestFrame (quest tracker)
		- Fix to propagate error with setting anchor points (RQE.RQEQuestFrameSetChildFramePoints() function) of child frames while in combat (with reset flag after combat ends)
		- Moved a number of lines of code dealing with child frame anchors of the RQEQuestFrame (scenario, campaign, regular, world quest, achievement) to function outside of previous UpdateRQEQuestFrame() function with call after combat flag/check
		- Added code to prevent PropagateMouseClicks when combat is in process for QuestLogIndexButton button clicks

	RQEDatabase.lua
		- Added more quests, including for 2 of the 3 campaign chapters for "The Ringing Deeps" zone

	RQEFrame.lua
		- Set code/checks to prevent/delay adjustment of frame width of the RQEFrame (SuperTrack frame) to run after combat ends, should they be called when combat is in process


11.0.2.29 (2024-08-29)

	Core.lua
	QuestingModule.lua
		- Fix implemented following the API change from 11.0 where scenario criteria was no longer available


11.0.2.28 (2024-08-29)

	EventManager.lua
		- Added functionality to automatically track a quest when QUEST_ACCEPTED fires (not sure why this wasn't the case before)

	RQEDatabase.lua
		- 78715: updates to waypoints on consoles
		- 80321: updates to waypoints for Khadgar's Portal in Dalaran before porting to Khaz Algar "shores"
		- 78462: Added some more info to description


11.0.2.27b (2024-08-28)

	Core.lua
		- Made it default that autoClickWaypointButton is true as this is of paramount importance in use of the walk thru guide!

	Misc.:
		- Reverted some code due to pass-thru error by commenting it out as this didn't fix the problem that came with 11.0 api passthru button changes


11.0.2.27 (2024-08-28)

	Buttons.lua
		- Misc. code clean-up and spacing

	Core.lua
		- Added RQE:CheckObjectiveProgress function for purposes of checking what stepIndex player should be on for a given quest
		- Update to StartPeriodicChecks to include potential for CheckDBObjectiveStatus in the RQEDatabase

	DebugLog.lua
		- Added debug coding for button click checks (disabled for players as not relevant)

	DatabaseMain.lua
	RQEDatabase.lua
		- Include WarWithin for examining of information from the RQEDatabase
		- Added campaign quests through Isle of Dorn and part of The Ringing Deeps (including waypoints and macros)

	EventManager.lua
	RQEFrame.lua
		- Update the content height of the RQEFrame after a brief delay following ADDON_LOADED and SUPER_TRACKING_CHANGED events in order to populate for quests with many steps
		- Added RQE:UpdateContentSize to when using scrollwheel as some quests with >7 objectives were being cut off/hidden unless frame were resized
		- Prevent WaypointButton (stepIndex# buttons) from being updated while in combat as may have been responsible for button passthru error

	QuestingModule.lua
		- Prevent WaypointButton (stepIndex# buttons) from being updated while in combat as may have been responsible for button passthru error

	RQEMacro.lua
		- Modified code for RQE.MagicButton macro

	WPUtil.lua
		- Prevent UnknownQuestButton "W" from being updated while in combat as may have been responsible for button passthru error


11.0.2.26 (2024-08-22)

	EventManager.lua
		- Fix made for ObjectiveTracker continuing to show up constantly
		- Removed many lines previously added for HideObjectiveTracker that existed before the fix went in place with this version
		- Added some additional functions for payload information temporarily (these are commented out and are not running on release client)


11.0.2.25 (2024-08-19)

	EventManager.lua
		- Additional placements of HideObjectiveTracker() function -- additions were needed following 11.0
		- Cleaned up code

11.0.2.24 (2024-08-19)

	Core.lua
		- Fixed coding so that the Minimap button would reflect properly the checkbox in the SettingsPanel and ConfigFrame


11.0.2.23 (2024-08-19)

	- Massive code cleanup (removed/re-worded comment lines)

	Config.lua
		- Added minimapButtonAngle for minimap button position as it relates to minimap (also included this setting in the ConfigFrame)
	
	Core.lua
		Variables removed no longer used:
		- Removed RQE.OverrideHasProgress, RQE.hasClickedQuestButton, RQE.AutoWaypointHasBeenClicked and RQE.canUpdateFromCriteria
		
		Functions removed no longer used:
		- RQE.CheckMouseHoverForTooltip, RQE.ScanAndCacheZoneQuests (duplicate), RQE:HighlightCurrentStepWaypointButton
		
		Re-enabled function for debug purposes later on:
		- AutoWatchQuestsWithProgress, RQE:DetermineCurrentStepIndex, RQE.PrintQuestLineInfo

	RQEFrame.lua
		Functions removed no longer used:
		- RQE:UpdateQuestDescription, RQE:GetCurrentObjectiveIndex

	RQEMinimap.lua
		- Modified tooltip for minimap and LDB buttons
		- Renamed minimap button
		- Created new function RQE:UpdateMinimapButtonPosition to update location on minimap and to also snap button to minimap
		- Transferred dynamic anchoring for menu system to minimap button that already existed in the LDB button
		- Moved section #8 'drag n drop' to section #6 'event handler'


11.0.2.22 (2024-08-18)

	Config.lua
		- Updates to Config Frame window
		- Fixed issue where config setting names were being truncated

	RQEMinimap.lua
		- Update to LDB & Minimap dropdown
		- Switched coding to Toggle Config Window instead of Creating (as this was previously resulting in duplication of window)
		- Commented out section in the dropdown for RQE:ShowMoreOptionsMenu as these options, to trigger settings opening for subcategories are not yet functional


11.0.2.21 (2024-08-17)

	RQEFrame.lua
		- API updates to change IsAddOnLoaded to C_AddOns.IsAddOnLoaded within RQE:CreateStepsText function

	RQEMinimap.lua
		- Update to LDB & Minimap buttons to reflect Shift-Right-Click option to toggle settings directly
		- Added 'Config Window' to More Options in LDB menu


11.0.2.2 (2024-08-17)

	Config.lua
		- Experimental: Update to OpenFrameSettings() function to include changes allegedly made with 11.0 API to open subcategories

	Core.lua
		- API updates to change IsAddOnLoaded to C_AddOns.IsAddOnLoaded

	EventManager.lua
		- Better DB check in PLAYER_LOGIN event

	QuestingModule.lua
		- API updates to change IsAddOnLoaded to C_AddOns.IsAddOnLoaded

	RQEMinimap.lua
		- Fix to LDBdatabroker as buttons weren't clicking before
		- Fix to Minimap Button as buttons weren't clicking before

	RQE.toc
		- Included 110005 in the accepted Game versions


11.0.2.1 (2024-08-14)

	Initial Release