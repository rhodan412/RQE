# Rhodan's Quest Explorer (RQE)

RQE is a quest helper and tracker for World of Warcraft. It brings the next objective, a waypoint, and practical step-by-step guidance together for quests supported by its database.

[Download on CurseForge](https://www.curseforge.com/wow/addons/rqe-rhodans-quest-explorer) · [Wiki / player guide](https://github.com/rhodan412/RQE/wiki) · [Watch the overview](https://www.youtube.com/watch?v=JKvJi32zfag) · [Report an issue](https://github.com/rhodan412/RQE/issues)

![RQE's Quest Helper, NPC and object previews, and Quest Tracker](https://github.com/user-attachments/assets/9f52c4aa-10c9-4441-8726-9548e6ecbeaa)

*Hover a highlighted NPC or object name in a quest step to see what you are looking for. The Quest Helper and Quest Tracker keep the route and objectives in view.*

## What RQE helps you do

- **Follow guided quest steps.** Read the current objective, location, and instructions for supported quests. Move between steps manually when needed.
- **Find the next destination.** Follow map waypoints and coordinates associated with the active step.
- **Track progress.** Keep quest objectives visible in the Quest Helper and Quest Tracker, and search for a quest even when it is not currently tracked.
- **Watch recipes and achievements.** See tracked profession recipes with their required materials and current counts, alongside achievement criteria and numeric progress.
- **Recognize NPCs and objects.** Mouse over linked names in step descriptions to open a movable preview. Zoom or pan the view when you need a closer look.
- **Use quest-aware controls.** Access helpful targeting and quest-item macros where a step provides them. RQE can update its macro button when a needed quest item becomes available.
- **Choose your layout.** Move, resize, or lock the main frames; adjust fonts, colors, previews, and the Azure & Gold theme in settings.
- **Find a group.** Use the quest interface to find groups for eligible quests.

## Get started

1. [Install RQE from CurseForge](https://www.curseforge.com/wow/addons/rqe-rhodans-quest-explorer) for your WoW client and enable the addon.
2. Track or search for a quest to view its information in RQE. Quests with authored guidance show a sequence of steps and waypoints.
3. Type `/rqe` in chat to see the available commands. Use `/rqe config` for settings or `/rqe toggle` to show or hide the Quest Helper.

RQE has addon builds for Retail, Classic Era/Season of Discovery, Classic Forever, and TBC Anniversary. Guided step coverage varies by quest.

## See it in action

| Quest guidance | Quest search and reference links |
| --- | --- |
| [![Watch the RQE overview](https://github.com/user-attachments/assets/646aaa29-921c-432a-9371-23b054c0669f)](https://www.youtube.com/watch?v=JKvJi32zfag) | [![Watch RQE search Wowhead and Warcraft Wiki](https://github.com/user-attachments/assets/94117e37-7fbf-4d2d-996d-99f303f3ea0e)](https://www.youtube.com/watch?v=0jAIiBSai3I) |

RQE can link tracked quests to Wowhead and Warcraft Wiki and help you inspect quest lines, tooltips, and quest-giver locations.

## More examples

### Profession recipes and achievements

The Quest Tracker gives tracked recipes their own **Profession** section above **Achievements**. It lists each recipe's materials and the amount you own; counts turn green when you have enough to craft one. A tracked recipe keeps the Tracker available even when you have no quests or achievements watched.

Achievement entries show each criterion, including numeric progress and the objective text. Achievements without a usable criterion show their description instead. Completed criteria appear in green.

[![RQE tracked recipes: material counts and item tooltips in the Profession section](https://github.com/user-attachments/assets/5111b1d2-c409-46fc-a07d-f1b751857e16)](https://github.com/user-attachments/assets/5111b1d2-c409-46fc-a07d-f1b751857e16)

[![RQE tracked achievements: completed criteria, numeric progress, and description fallback](https://github.com/user-attachments/assets/58bd5a83-16cb-421d-9966-ae23efdc2240)](https://github.com/user-attachments/assets/58bd5a83-16cb-421d-9966-ae23efdc2240)

Hover a recipe or ingredient for details, and click it to open the profession recipe or inspect an unlearned recipe. Hover an achievement for its category, icon, and criteria summary; click its title to open it. **Shift+left-click** a recipe, ingredient, or achievement title to stop tracking that entry. The [Quest Helper and Tracker guide](https://github.com/rhodan412/RQE/wiki/Quest-Helper-and-Tracker) has more examples.

### Interactive guidance

Click a panel to view it at full size. The [player guide](https://github.com/rhodan412/RQE/wiki) explains the controls in detail.

| Interactive quest-step links | Quest-aware actions |
| --- | --- |
| [![Item and spell tooltips in RQE steps](https://github.com/user-attachments/assets/f011e2db-743d-48ae-9eca-1edbd8d85522)](https://github.com/user-attachments/assets/f011e2db-743d-48ae-9eca-1edbd8d85522) | [![RQE action button and quest macro](https://github.com/user-attachments/assets/3888da5b-bb78-47b0-945a-05cb60ac7fe8)](https://github.com/user-attachments/assets/3888da5b-bb78-47b0-945a-05cb60ac7fe8) |

<details>
<summary>More illustrated features: quest context, search, and settings</summary>

| Quest context and guided steps | Search, filters, and references |
| --- | --- |
| ![Quest Helper and Tracker context](https://github.com/user-attachments/assets/f33a2a80-4a93-4899-b87f-e249385b6d51) | ![Quest search, filters, and reference links](https://github.com/user-attachments/assets/724f5e10-c713-48fb-8f85-d0474501921d) |

![RQE frame, font, and profile settings](https://github.com/user-attachments/assets/c581fe08-874f-4eae-8009-19be32341c67)

</details>


### Azure & Gold interface

The optional Azure & Gold theme gives RQE's frames, sections, and controls a consistent look.

![RQE Azure and Gold theme](https://github.com/user-attachments/assets/20cc73c9-fd9f-4ffc-a3c6-f596f17b79b7)

### A quest item when time matters

In *The Ghostfish*, the caught item must be used quickly. This example shows RQE updating its quest macro button when the item becomes available.

![RQE updating its macro button for The Ghostfish](https://github.com/user-attachments/assets/5f635ddb-a233-493f-b86b-0ff0676a87ab)

<details>
<summary>More screenshots and feature examples</summary>

- [Step-by-step quest guidance](https://github.com/user-attachments/assets/9e549a8a-6529-44dc-84e8-12b3135e13c2)
- [Tracked quests and waypoints](https://github.com/user-attachments/assets/13f32e34-e4ea-48d8-848c-681059b0180c)
- [Switching between Blizzard's tracker and RQE's tracker](https://github.com/user-attachments/assets/6cd710e2-54c2-4452-a5ae-904b244751b6)
- [Group finder for world quests](https://github.com/user-attachments/assets/8637cb2d-dce5-4038-b55b-dfb542446b8d)
- [Quest reward preview](https://github.com/user-attachments/assets/4a43d504-bda1-4693-9289-bc71a494760d)
- [Additional quest tooltips](https://github.com/user-attachments/assets/d0ce9e53-3db8-42a6-a7f6-4ffc71ce5968)
- [Dungeon or scenario boss progress](https://github.com/user-attachments/assets/84f7e7b2-f44a-4c0a-b09c-791150c8429d)
- [Quest search filters](https://github.com/user-attachments/assets/fa2af154-6c85-406d-bff3-496d132bfa20)
- [Search for an untracked quest](https://github.com/user-attachments/assets/636ae204-33e9-4973-b791-e4d14116aeb2)
- [Mythic/Scenario Mode](https://github.com/user-attachments/assets/bcb934dd-d354-407d-882d-a3943d0894cb)
- [Spell and item cooldowns on the macro button](https://github.com/user-attachments/assets/7faca85a-6175-4422-b279-e5779c15f890)
- [Extra Action Button support](https://github.com/user-attachments/assets/93a13e45-9a17-435f-b9c1-e578705f1638)

</details>

## Compatibility and feedback

When RQE and World Quest Tracker are enabled together, some quests may appear as both world quests and regular quests. This has not been reproduced with either addon running alone; there is no confirmed workaround yet.

If you run into a problem or have a feature request, [open a GitHub issue](https://github.com/rhodan412/RQE/issues). Issues are easier for the author to track than CurseForge comments.
