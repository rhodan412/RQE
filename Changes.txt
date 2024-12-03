11.0.5.3

	Core.lua
		- Click "W" Button at start of regularly called RQE:StartPeriodicChecks function in order to initially set the waypoint

	RQEDatabase.lua
		- Removal of quest data not currently in the DB
		- Added side quests of Bastion, Maldraxxus, Ardenweald, and Revendreth to DB
		- Added Night Fae, Venthyr, Kyrian & Necrolord campaign quests to DB
		- Added 'Among the Kyrian' and 'Torghast' chapters of Kyrian campaign to DB


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
		- Added some weekly quests (including more in Dornogol) and cleaned up DB
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
		- Added additional weekly quests in Dornogol

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