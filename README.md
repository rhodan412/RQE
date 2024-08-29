Rhodan's Quest Explorer (RQE)
=============================

Unlock your full questing potential in World of Warcraft with Rhodan’s Quest Explorer (RQE), your ultimate guide to navigating Azeroth’s challenges more efficiently. RQE not only guides you step-by-step through each quest, but also integrates seamlessly with your game to enhance every part of the questing experience.

**Key Features:**
Detailed Quest Insights: Provides in-depth details for each quest, including objectives, locations, and step-by-step navigation, ensuring you never miss a beat.
Interactive Map Points: Automatically sets waypoints to your next objective, complete with coordinates and customized navigation options.
Customizable User Interface: Adjust the RQE interface to suit your gameplay style, with scalable windows and detailed control over what information is displayed.
Integrated Group Finder: Easily form or join groups with others who are on the same quest, directly from the quest interface.
Advanced Macros: Utilize built-in macros for specific quests, helping you target the right NPC or interact with quest items quickly and efficiently.
Step-by-Step Manual Progression: Manually progress through quest stages with a simple click, giving you control over each step of your quest journey.
Quest Completion Tracking: Keeps track of your quest progress, including any prerequisites or sequential steps needed to unlock further objectives.

Chat commands
-------------

* /rqe - shows the list of options

* /rqe config - activates settings panel
* /rqe toggle - toggle on/off frame

Links
-----

* The latest release is available on [CurseForge]([https://legacy.curseforge.com/wow/addons/rqe-rhodans-quest-explorer](https://legacy.curseforge.com/wow/addons/rqe-rhodans-quest-explorer)

Limitations:
------------
* There is no countdown timer for Scenario stages, so if you're using this to find out how long between stages for super bloom, or whatever - don't hold your breath as this add-on won't do it. This is something that I would love to put in, but this may require a fairly large re-work.
* Currently special quest items/spells (such as the Area52 Special from the quest: "Mission: The Abyssal Shelf") aren't displayed in the Quest Watch frame or Super-Tracked frame (this is something that I am looking to add)

Known Bugs:
-----------
~~* Scenario/Dungeon Objectives are not visible as Blizz never re-implemented/fixed this part of the API since 11.0 (it worked just fine before 11.0). If this starts to work again, I will make sure that this is put back into place~~ FIXED!
~~* Tooltips don't contain quest rewards any longer (again this is an issue that started in 11.0 and I haven't been able to get this part going again)~~ FIX coming in next release (v11.0.2.30)!
~~* ButtonSetPassThrough propagate error~~ FIX coming in next release (v11.0.2.30)!
~~* Some (weekly JC quest in Valdrakken that requires you to craft four gems is the only one that I can think of) custom multi-step quests don't advance stages properly between the stage/waypoint buttons (numbered buttons in the Super-Track Frame) as you craft each of the gems. This means that the RQE Macro doesn't update unless you manually tick the stage button.~~ FIXED!
