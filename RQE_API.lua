--[[
RQE_API.lua
Centralized API abstraction layer for Rhodan's Quest Explorer (RQE)

This file provides a unified interface for all Blizzard API calls used by the addon.
- Ensures compatibility across different game versions (Retail vs. Classic).
- Simplifies maintenance when APIs are renamed, deprecated, or reworked.
- Wraps API calls into RQE.API.* functions for consistent usage throughout the addon.
- Stores key results in global RQE.* variables for recall without re-calling the API.
- Organized into sections (Quest, Map, Merchant, Scenario, Gossip, etc.) with clear headers.

Usage:
	-- Use the wrapped API instead of direct Blizzard calls:
	local objectives = RQE.API.GetQuestObjectives(questID)
	print(objectives[1].text)

	-- Or recall the last known stored info:
	print(RQE.MerchantInfo.name, RQE.MerchantInfo.price)

]]

-- API.lua
RQE = RQE or {}
RQE.API = RQE.API or {}

-- Detect client build
local version, build, _, tocversion = GetBuildInfo()
local major, minor, patch = string.match(version, "(%d+)%.(%d+)%.?(%d*)")
major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch) or 0

RQE.API.GameVersion = {
	full = version,
	build = build,
	major = major,
	minor = minor,
	patch = patch,
	toc = tocversion,
}


-------------------------------------------------
-- 🏆 Achievements / 📚 Encounter Journal APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local info = RQE.API.GetAchievementInfo(achievementID)	instead of: C_AchievementInfo.GetAchievementInfo(achievementID)
	RQE.API.GetAchievementInfo = function(achievementID)
		return C_AchievementInfo.GetAchievementInfo(achievementID)
	end

	-- Use: RQE.API.OpenEncounterJournal()	instead of: C_EncounterJournal.OpenJournal()
	RQE.API.OpenEncounterJournal = function()
		return C_EncounterJournal.OpenJournal()
	end
else
	RQE.API.GetAchievementInfo = function(achievementID) return nil end
	RQE.API.OpenEncounterJournal = function() return nil end
end


-------------------------------------------------
-- 🧾 Adventure Journal / Factions APIs
-------------------------------------------------

if major >= 11 then
	-- Use: RQE.API.OpenJournal()	instead of: C_AdventureJournal.OpenJournal()
	RQE.API.OpenJournal = function()
		return C_AdventureJournal.OpenJournal()
	end

	-- Use: local info = RQE.API.GetMajorFactionData(factionID)	instead of: C_MajorFactions.GetMajorFactionData(factionID)
	RQE.API.GetMajorFactionData = function(factionID)
		return C_MajorFactions.GetMajorFactionData(factionID)
	end
else
	RQE.API.OpenJournal = function() return nil end
	RQE.API.GetMajorFactionData = function(factionID) return nil end
end


-------------------------------------------------
-- 🎯 Gossip / NPC Interaction APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local options = RQE.API.GetGossipOptions()	instead of: C_GossipInfo.GetOptions()
	RQE.API.GetGossipOptions = function()
		return C_GossipInfo.GetOptions()
	end

	-- Use: RQE.API.SelectGossipOption(optionID)	instead of: C_GossipInfo.SelectOption(optionID)
	RQE.API.SelectGossipOption = function(optionID)
		return C_GossipInfo.SelectOption(optionID)
	end
else
	RQE.API.GetGossipOptions = function() return {} end
	RQE.API.SelectGossipOption = function(optionID) return nil end
end


-------------------------------------------------
-- 📢 Group / LFG APIs
-------------------------------------------------

if major >= 11 then
	-- Use: RQE.API.CreateListing(activityID, groupName, itemLevel, voiceChat, comment, autoAccept)	instead of: C_LFGList.CreateListing(...)
	RQE.API.CreateListing = function(...)
		return C_LFGList.CreateListing(...)
	end

	-- Use: local results = RQE.API.SearchLFGList(searchCategoryID, filters, preferredFilters, languageFilter)	instead of: C_LFGList.Search(...)
	RQE.API.SearchLFGList = function(...)
		return C_LFGList.Search(...)
	end
else
	RQE.API.CreateListing = function(...) return nil end
	RQE.API.SearchLFGList = function(...) return {} end
end


-------------------------------------------------
-- 🗺️ Map APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local mapID = RQE.API.GetBestMapForUnit("player")	instead of: C_Map.GetBestMapForUnit("player")
	RQE.API.GetBestMapForUnit = function(unit)
		return C_Map.GetBestMapForUnit(unit)
	end

	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player")	instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Returns: Vector2D or nil
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		return C_Map.GetPlayerMapPosition(mapID, unit)
	end

	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint()	instead of: C_Map.HasUserWaypoint()
	RQE.API.HasUserWaypoint = function()
		return C_Map.HasUserWaypoint()
	end

	-- Use: RQE.API.ClearUserWaypoint()	instead of: C_Map.ClearUserWaypoint()
	RQE.API.ClearUserWaypoint = function()
		return C_Map.ClearUserWaypoint()
	end

	-- Use: RQE.API.SetUserWaypoint(point)	instead of: C_Map.SetUserWaypoint(point)
	RQE.API.SetUserWaypoint = function(point)
		return C_Map.SetUserWaypoint(point)
	end

	-- Use: local canSet = RQE.API.CanSetUserWaypointOnMap(uiMapID)	instead of: C_Map.CanSetUserWaypointOnMap(uiMapID)
	RQE.API.CanSetUserWaypointOnMap = function(uiMapID)
		return C_Map.CanSetUserWaypointOnMap(uiMapID)
	end

	-- Use: local name = RQE.API.GetAreaInfo(areaID)	instead of: C_Map.GetAreaInfo(areaID)
	RQE.API.GetAreaInfo = function(areaID)
		return C_Map.GetAreaInfo(areaID)
	end

	-- Use: local info = RQE.API.GetMapInfo(uiMapID)	instead of: C_Map.GetMapInfo(uiMapID)
	RQE.API.GetMapInfo = function(uiMapID)
		return C_Map.GetMapInfo(uiMapID)
	end

	-- Use: local info = RQE.API.GetMapChildrenInfo(uiMapID)	instead of: C_Map.GetMapChildrenInfo(uiMapID)
	RQE.API.GetMapChildrenInfo = function(uiMapID, mapType, allDescendants)
		return C_Map.GetMapChildrenInfo(uiMapID, mapType, allDescendants)
	end

	-- Use: local position = RQE.API.GetUserWaypointPositionForMap(uiMapID)	instead of: C_Map.GetUserWaypointPositionForMap(uiMapID)
	RQE.API.GetUserWaypointPositionForMap = function(uiMapID)
		return C_Map.GetUserWaypointPositionForMap(uiMapID)
	end

	-- Use: local point = RQE.API.GetUserWaypoint()	instead of: C_Map.GetUserWaypoint()
	RQE.API.GetUserWaypoint = function()
		return C_Map.GetUserWaypoint()
	end

	-- Use: local link = RQE.API.GetUserWaypointHyperlink()	instead of: C_Map.GetUserWaypointHyperlink()
	RQE.API.GetUserWaypointHyperlink = function()
		return C_Map.GetUserWaypointHyperlink()
	end

	-- Use: local x, y = RQE.API.GetNextWaypointForMap(questID, uiMapID)	instead of: C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
	-- Returns: number x, number y
	RQE.API.GetNextWaypointForMap = function(questID, uiMapID)
		return C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
	end
else
	-- Classic (1.13.2 etc.)
	-- Use: local mapID = RQE.API.GetBestMapForUnit("player")	instead of: C_Map.GetBestMapForUnit("player")
	RQE.API.GetBestMapForUnit = function(unit)
		return C_Map.GetBestMapForUnit(unit)
	end

	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player")	instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Returns: Vector2D or nil
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		return C_Map.GetPlayerMapPosition(mapID, unit)
	end

	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint()	instead of: C_Map.HasUserWaypoint()
	RQE.API.HasUserWaypoint = function()
		return C_Map.HasUserWaypoint()
	end

	-- Use: RQE.API.ClearUserWaypoint()	instead of: C_Map.ClearUserWaypoint()
	RQE.API.ClearUserWaypoint = function()
		return C_Map.ClearUserWaypoint()
	end

	-- Use: RQE.API.SetUserWaypoint(point)	instead of: C_Map.SetUserWaypoint(point)
	RQE.API.SetUserWaypoint = function(point)
		return C_Map.SetUserWaypoint(point)
	end

	-- Use: local x, y = RQE.API.GetNextWaypointForMap(questID, uiMapID)	instead of: C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
	-- Returns: number x, number y
	RQE.API.GetNextWaypointForMap = function(questID, uiMapID)
		return nil, nil
	end

	RQE.API.CanSetUserWaypointOnMap = function(uiMapID) return false end
	RQE.API.GetAreaInfo = function(areaID) return nil end
	RQE.API.GetMapInfo = function(uiMapID) return nil end
	RQE.API.GetMapChildrenInfo = function(uiMapID, mapType, allDescendants) return {} end
	RQE.API.GetUserWaypointPositionForMap = function(uiMapID) return nil end
	RQE.API.GetUserWaypoint = function() return nil end
	RQE.API.GetUserWaypointHyperlink = function() return nil end
end


-------------------------------------------------
-- 🛒 Merchant APIs
-------------------------------------------------

if major >= 11 then
	-- Retail merchant API

	-- Use: local info = RQE.API.GetMerchantItemInfo(index)		instead of: GetMerchantItemInfo(index)
	-- Returns a table: { name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID }
	-- Recalled with either: print("Merchant item:", info.name, info.price, info.numAvailable) - OR - print("Merchant item:", RQE.MerchantInfo.name, RQE.MerchantInfo.price, RQE.MerchantInfo.numAvailable)
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)

		-- Store into addon variable
		RQE.MerchantInfo = {
			name = name,
			texture = texture,
			price = price,
			quantity = quantity,
			numAvailable = numAvailable,
			isPurchasable = isPurchasable,
			isUsable = isUsable,
			extendedCost = extendedCost,
			currencyID = currencyID,
			spellID = spellID,
		}
		return RQE.MerchantInfo
	end

	-- Use: local id = RQE.API.GetBuybackItemID(slot)	instead of: C_MerchantFrame.GetBuybackItemID(slot)
	RQE.API.GetBuybackItemID = function(buybackSlotIndex)
		return C_MerchantFrame.GetBuybackItemID(buybackSlotIndex)
	end

	-- Use: local info = RQE.API.GetMerchantFrameItemInfo(index)	instead of: C_MerchantFrame.GetItemInfo(index)
	RQE.API.GetMerchantFrameItemInfo = function(index)
		return C_MerchantFrame.GetItemInfo(index)
	end

	-- Use: local refundable = RQE.API.IsMerchantItemRefundable(index)	instead of: C_MerchantFrame.IsMerchantItemRefundable(index)
	RQE.API.IsMerchantItemRefundable = function(index)
		return C_MerchantFrame.IsMerchantItemRefundable(index)
	end
else
	-- Classic merchant API (returns fewer values)
	-- Use: local info = RQE.API.GetMerchantItemInfo(index)	instead of: GetMerchantItemInfo(index)
	-- Returns a table: { name, texture, price, quantity, numAvailable, isUsable }
	-- Recalled with either: print("Merchant item:", info.name, info.price, info.numAvailable) - OR - print("Merchant item:", RQE.MerchantInfo.name, RQE.MerchantInfo.price, RQE.MerchantInfo.numAvailable)
	-- info.name is better for functions as self-contained, but can use RQE.MerchantInfo.name if you need to recall last known without running the RQE.API.GetMerchantItemInfo(index) function call
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(index)

		RQE.MerchantInfo = {
			name = name,
			texture = texture,
			price = price,
			quantity = quantity,
			numAvailable = numAvailable,
			isUsable = isUsable,
		}
		return RQE.MerchantInfo
	end

	RQE.API.GetBuybackItemID = function(buybackSlotIndex) return nil end
	RQE.API.GetMerchantFrameItemInfo = function(index) return nil end
	RQE.API.IsMerchantItemRefundable = function(index) return false end
end


-------------------------------------------------
-- 🧭 Quest APIs
-------------------------------------------------

if major >= 11 then
	-- Retail (11.0.5+, 11.2.0, etc.)
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID()	instead of: C_SuperTrack.GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return C_SuperTrack.GetSuperTrackedQuestID()
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries()	instead of: C_QuestLog.GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		return C_QuestLog.GetNumQuestLogEntries()
	end

	-- Use: local objectives = RQE.API.GetQuestObjectives(questID)		instead of: C_QuestLog.GetQuestObjectives(questID)
	RQE.API.GetQuestObjectives = function(questID)
		return C_QuestLog.GetQuestObjectives(questID)
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingQuest()	instead of: C_SuperTrack.IsSuperTrackingQuest()
	RQE.API.IsSuperTrackingQuest = function()
		return C_SuperTrack.IsSuperTrackingQuest()
	end

else

	-- Classic (1.13.2 etc.)
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID()	instead of: GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return GetSuperTrackedQuestID and GetSuperTrackedQuestID() or nil
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries()	instead of: GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		return GetNumQuestLogEntries()
	end

	-- Use: local objectives = RQE.API.GetQuestObjectives(questID)	instead of: GetQuestObjectives(questID)
	RQE.API.GetQuestObjectives = function(questID)
		return GetQuestObjectives(questID)
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingQuest()	instead of: C_SuperTrack.IsSuperTrackingQuest()
	RQE.API.IsSuperTrackingQuest = function()
		return C_SuperTrack.IsSuperTrackingQuest()
	end
end


-------------------------------------------------
-- 🗂️ Quest Line / Task / World Quests APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local info = RQE.API.GetQuestLineInfo(questLineID, uiMapID)	instead of: C_QuestLine.GetQuestLineInfo(...)
	RQE.API.GetQuestLineInfo = function(questLineID, uiMapID)
		return C_QuestLine.GetQuestLineInfo(questLineID, uiMapID)
	end

	-- Use: local info = RQE.API.GetQuestObjectiveInfo_Task(questID, objectiveIndex)	instead of: C_TaskQuest.GetQuestObjectiveInfo(...)
	RQE.API.GetQuestObjectiveInfo_Task = function(questID, objectiveIndex)
		return C_TaskQuest.GetQuestObjectiveInfo(questID, objectiveIndex)
	end

	-- Use: local progress = RQE.API.GetQuestProgressBarInfo(questID)	instead of: C_TaskQuest.GetQuestProgressBarInfo(questID)
	RQE.API.GetQuestProgressBarInfo = function(questID)
		return C_TaskQuest.GetQuestProgressBarInfo(questID)
	end
else
	RQE.API.GetQuestLineInfo = function(questLineID, uiMapID) return nil end
	RQE.API.GetQuestObjectiveInfo_Task = function(questID, objectiveIndex) return nil end
	RQE.API.GetQuestProgressBarInfo = function(questID) return nil end
end


-------------------------------------------------
-- 📜 Quest Log / Quest Info APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local title = RQE.API.GetTitleForQuestID(questID)	instead of: C_QuestLog.GetTitleForQuestID(questID)
	RQE.API.GetTitleForQuestID = function(questID)
		return C_QuestLog.GetTitleForQuestID(questID)
	end

	-- Use: local text = RQE.API.GetNextWaypointText(questID)	instead of: C_QuestLog.GetNextWaypointText(questID)
	RQE.API.GetNextWaypointText = function(questID)
		return C_QuestLog.GetNextWaypointText(questID)
	end

	-- Use: local info = RQE.API.GetQuestLogInfo(questIndex)	instead of: C_QuestLog.GetInfo(questIndex)
	RQE.API.GetQuestLogInfo = function(questIndex)
		return C_QuestLog.GetInfo(questIndex)
	end

	-- Use: local completed = RQE.API.IsQuestFlaggedCompleted(questID)	instead of: C_QuestLog.IsQuestFlaggedCompleted(questID)
	RQE.API.IsQuestFlaggedCompleted = function(questID)
		return C_QuestLog.IsQuestFlaggedCompleted(questID)
	end

	-- Use: local numObjectives = RQE.API.GetNumQuestObjectives(questID)	instead of: C_QuestLog.GetNumQuestObjectives(questID)
	-- Returns: number (leaderboardCount)
	RQE.API.GetNumQuestObjectives = function(questID)
		return C_QuestLog.GetNumQuestObjectives(questID)
	end

	-- Use: local text, _, _, _, _, _, _, _, _, _, _, _ = RQE.API.GetQuestObjectiveInfo(questID, objectiveIndex, false)	instead of: GetQuestObjectiveInfo(...)
	RQE.API.GetQuestObjectiveInfo = function(questID, objectiveIndex, displayProgressText)
		return GetQuestObjectiveInfo(questID, objectiveIndex, displayProgressText)
	end

	-- Use: local itemName, texture, numItems, quality = RQE.API.GetQuestLogRewardInfo(i, questID)	instead of: GetQuestLogRewardInfo(i, questID)
	RQE.API.GetQuestLogRewardInfo = function(index, questID)
		return GetQuestLogRewardInfo(index, questID)
	end

	-- Use: local info = RQE.API.GetQuestRewardSpellInfo(questID, spellID)	instead of: C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
	RQE.API.GetQuestRewardSpellInfo = function(questID, spellID)
		return C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
	end
else

	-- Use: local numObjectives = RQE.API.GetNumQuestObjectives(questID)	instead of: C_QuestLog.GetNumQuestObjectives(questID)
	-- Returns: number (leaderboardCount)
	RQE.API.GetNumQuestObjectives = function(questID)
		return GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(questID) or 0
	end

	-- Classic (1.13.2 etc.)
	RQE.API.GetTitleForQuestID = function(questID) return nil end
	RQE.API.GetNextWaypointText = function(questID) return nil end
	RQE.API.GetQuestLogInfo = function(questIndex) return nil end
	RQE.API.IsQuestFlaggedCompleted = function(questID) return false end
	RQE.API.GetQuestObjectiveInfo = function(questID, objectiveIndex, displayProgressText) return nil end
	RQE.API.GetQuestLogRewardInfo = function(index, questID) return nil end
	RQE.API.GetQuestRewardSpellInfo = function(questID, spellID) return nil end
end


-------------------------------------------------
-- ⚔️ Scenario APIs
-------------------------------------------------

if major >= 11 then
	-- Retail (11.0.5+, 11.2.0, etc.)

	-- Use: local info = RQE.API.GetScenarioInfo()	instead of: C_ScenarioInfo.GetScenarioInfo()
	-- Returns a table: { name, currentStage, numStages, flags, isComplete, xp, money, type, area, uiTextureKit }
	RQE.API.GetScenarioInfo = function()
		local info = C_ScenarioInfo.GetScenarioInfo()
		RQE.ScenarioInfo = info
		return info
	end

	-- Use: local stepInfo = RQE.API.GetScenarioStepInfo([scenarioStepID])	instead of: C_ScenarioInfo.GetScenarioStepInfo([scenarioStepID])
	-- Returns a table: { title, description, numCriteria, stepFailed, isBonusStep, isForCurrentStepOnly, shouldShowBonusObjective, spells, weightedProgress, rewardQuestID, widgetSetID }
	RQE.API.GetScenarioStepInfo = function(scenarioStepID)
		local info = C_ScenarioInfo.GetScenarioStepInfo(scenarioStepID)
		RQE.ScenarioStepInfo = info
		return info
	end

	-- Use: local crit = RQE.API.GetCriteriaInfo(criteriaIndex)	instead of: C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	-- Returns a table: { description, criteriaType, completed, quantity, totalQuantity, flags, assetID, criteriaID, duration, elapsed, failed, isWeightedProgress, isFormatted, quantityString }
	RQE.API.GetCriteriaInfo = function(criteriaIndex)
		local crit = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		RQE.ScenarioCriteriaInfo = crit
		return crit
	end

	-- Use: local crit = RQE.API.GetCriteriaInfoByStep(stepID, criteriaIndex)	instead of: C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
	-- Returns same structure as GetCriteriaInfo
	RQE.API.GetCriteriaInfoByStep = function(stepID, criteriaIndex)
		local crit = C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
		RQE.ScenarioCriteriaByStep = crit
		return crit
	end

	-- Use: local towerType = RQE.API.GetJailersTowerTypeString(runType)	instead of: C_ScenarioInfo.GetJailersTowerTypeString(runType)
	RQE.API.GetJailersTowerTypeString = function(runType)
		local s = C_ScenarioInfo.GetJailersTowerTypeString(runType)
		RQE.JailersTowerTypeString = s
		return s
	end

else
	-- Classic (1.13.2 etc.) – Scenarios don’t exist here, return nil or empty

	RQE.API.GetScenarioInfo = function() return nil end
	RQE.API.GetScenarioStepInfo = function(_) return nil end
	RQE.API.GetCriteriaInfo = function(_) return nil end
	RQE.API.GetCriteriaInfoByStep = function(_, _) return nil end
	RQE.API.GetJailersTowerTypeString = function(_) return nil end
end


-------------------------------------------------
-- 🛠️ TradeSkill / Crafting APIs
-------------------------------------------------

if major >= 11 then
	-- Use: RQE.API.OpenRecipe(recipeID)	instead of: C_TradeSkillUI.OpenRecipe(recipeID)
	RQE.API.OpenRecipe = function(recipeID)
		return C_TradeSkillUI.OpenRecipe(recipeID)
	end

	-- Use: RQE.API.CraftRecipe(recipeID, count)	instead of: C_TradeSkillUI.CraftRecipe(recipeID, count)
	RQE.API.CraftRecipe = function(recipeID, count)
		return C_TradeSkillUI.CraftRecipe(recipeID, count)
	end
else
	RQE.API.OpenRecipe = function(recipeID) return nil end
	RQE.API.CraftRecipe = function(recipeID, count) return nil end
end


-------------------------------------------------
-- 💬 Unit / Buff / Debuff APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = RQE.API.UnitBuff("player", 1)	instead of: UnitBuff("player", 1)
	RQE.API.UnitBuff = function(unit, index)
		return UnitBuff(unit, index)
	end

	-- Use: local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = RQE.API.UnitDebuff("target", 1)	instead of: UnitDebuff("target", 1)
	RQE.API.UnitDebuff = function(unit, index)
		return UnitDebuff(unit, index)
	end

	-- Use: local name = RQE.API.UnitName("target")	instead of: UnitName("target")
	RQE.API.UnitName = function(unit)
		return UnitName(unit)
	end
else
	RQE.API.UnitBuff = function(unit, index) return nil end
	RQE.API.UnitDebuff = function(unit, index) return nil end

	-- Use: local name = RQE.API.UnitName("target")	instead of: UnitName("target")
	RQE.API.UnitName = function(unit)
		return UnitName(unit)
	end
endGetNextWaypoint


-------------------------------------------------
-- 📍 POI APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local info = RQE.API.GetAreaPOIInfo(uiMapID, areaPoiID)	instead of: C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
	-- Returns a table: { areaPoiID, position, name, description, linkedUiMapID, textureIndex, tooltipWidgetSet, iconWidgetSet,
	--	atlasName, uiTextureKit, shouldGlow, factionID, isPrimaryMapForPOI, isAlwaysOnFlightmap, addPaddingAboveTooltipWidgets,
	--	highlightWorldQuestsOnHover, highlightVignettesOnHover, isCurrentEvent }
	-- Recalled with either: print("POI:", info.name, info.description, info.areaPoiID) - OR - print("POI:", RQE.AreaPOIInfo.name, RQE.AreaPOIInfo.description, RQE.AreaPOIInfo.areaPoiID)
	RQE.API.GetAreaPOIInfo = function(uiMapID, areaPoiID)
		local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
		RQE.AreaPOIInfo = poiInfo
		return poiInfo
	end
else
	RQE.API.GetAreaPOIInfo = function(uiMapID, areaPoiID)
		return nil
	end
end


-------------------------------------------------
-- 🛠️ Miscellaneous APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local loadedOrLoading, loaded = RQE.API.IsAddOnLoaded("Blizzard_WorldMap")	instead of: C_AddOns.IsAddOnLoaded("Blizzard_WorldMap")
	-- Returns: boolean loadedOrLoading, boolean loaded
	RQE.API.IsAddOnLoaded = function(name)
		return C_AddOns.IsAddOnLoaded(name)
	end
else
	-- Classic compatibility
	RQE.API.IsAddOnLoaded = function(name)
		return IsAddOnLoaded(name)
	end
end