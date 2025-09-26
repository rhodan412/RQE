-- RQE_API.lua

-- API.lua
RQE = RQE or {}
RQE.API = {}

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
-- Quest APIs
-------------------------------------------------

if major >= 11 then
	-- Retail (11.0.5+, 11.2.0, etc.)
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID()    instead of: C_SuperTrack.GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return C_SuperTrack.GetSuperTrackedQuestID()
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries()    instead of: C_QuestLog.GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		return C_QuestLog.GetNumQuestLogEntries()
	end

	-- Use: local objectives = RQE.API.GetQuestObjectives(questID)		instead of: C_QuestLog.GetQuestObjectives(questID)
	RQE.API.GetQuestObjectives = function(questID)
		return C_QuestLog.GetQuestObjectives(questID)
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingQuest()    instead of: C_SuperTrack.IsSuperTrackingQuest()
	RQE.API.IsSuperTrackingQuest = function()
		return C_SuperTrack.IsSuperTrackingQuest()
	end

else

	-- Classic (1.13.2 etc.)
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID()    instead of: GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return GetSuperTrackedQuestID and GetSuperTrackedQuestID() or nil
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries()    instead of: GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		return GetNumQuestLogEntries()
	end

	-- Use: local objectives = RQE.API.GetQuestObjectives(questID)    instead of: GetQuestObjectives(questID)
	RQE.API.GetQuestObjectives = function(questID)
		return GetQuestObjectives(questID)
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingQuest()    instead of: C_SuperTrack.IsSuperTrackingQuest()
	RQE.API.IsSuperTrackingQuest = function()
		return C_SuperTrack.IsSuperTrackingQuest()
	end
end


-------------------------------------------------
-- Map APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local mapID = RQE.API.GetBestMapForUnit("player")    instead of: C_Map.GetBestMapForUnit("player")
	RQE.API.GetBestMapForUnit = function(unit)
		return C_Map.GetBestMapForUnit(unit)
	end

	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player")    instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Returns: Vector2D or nil
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		return C_Map.GetPlayerMapPosition(mapID, unit)
	end

	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint()    instead of: C_Map.HasUserWaypoint()
	RQE.API.HasUserWaypoint = function()
		return C_Map.HasUserWaypoint()
	end

	-- Use: RQE.API.ClearUserWaypoint()    instead of: C_Map.ClearUserWaypoint()
	RQE.API.ClearUserWaypoint = function()
		return C_Map.ClearUserWaypoint()
	end

	-- Use: RQE.API.SetUserWaypoint(point)    instead of: C_Map.SetUserWaypoint(point)
	RQE.API.SetUserWaypoint = function(point)
		return C_Map.SetUserWaypoint(point)
	end
else
	-- Classic (1.13.2 etc.)
	-- Use: local mapID = RQE.API.GetBestMapForUnit("player")    instead of: C_Map.GetBestMapForUnit("player")
	RQE.API.GetBestMapForUnit = function(unit)
		return C_Map.GetBestMapForUnit(unit)
	end

	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player")    instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Returns: Vector2D or nil
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		return C_Map.GetPlayerMapPosition(mapID, unit)
	end

	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint()    instead of: C_Map.HasUserWaypoint()
	RQE.API.HasUserWaypoint = function()
		return C_Map.HasUserWaypoint()
	end

	-- Use: RQE.API.ClearUserWaypoint()    instead of: C_Map.ClearUserWaypoint()
	RQE.API.ClearUserWaypoint = function()
		return C_Map.ClearUserWaypoint()
	end

	-- Use: RQE.API.SetUserWaypoint(point)    instead of: C_Map.SetUserWaypoint(point)
	RQE.API.SetUserWaypoint = function(point)
		return C_Map.SetUserWaypoint(point)
	end
end


-------------------------------------------------
-- Merchant APIs
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
else
	-- Classic merchant API (returns fewer values)
	-- Use: local info = RQE.API.GetMerchantItemInfo(index)    instead of: GetMerchantItemInfo(index)
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
end


-------------------------------------------------
-- Scenario APIs
-------------------------------------------------

if major >= 11 then
	-- Retail (11.0.5+, 11.2.0, etc.)

	-- Use: local info = RQE.API.GetScenarioInfo()    instead of: C_ScenarioInfo.GetScenarioInfo()
	-- Returns a table: { name, currentStage, numStages, flags, isComplete, xp, money, type, area, uiTextureKit }
	RQE.API.GetScenarioInfo = function()
		local info = C_ScenarioInfo.GetScenarioInfo()
		RQE.ScenarioInfo = info
		return info
	end

	-- Use: local stepInfo = RQE.API.GetScenarioStepInfo([scenarioStepID])    instead of: C_ScenarioInfo.GetScenarioStepInfo([scenarioStepID])
	-- Returns a table: { title, description, numCriteria, stepFailed, isBonusStep, isForCurrentStepOnly, shouldShowBonusObjective, spells, weightedProgress, rewardQuestID, widgetSetID }
	RQE.API.GetScenarioStepInfo = function(scenarioStepID)
		local info = C_ScenarioInfo.GetScenarioStepInfo(scenarioStepID)
		RQE.ScenarioStepInfo = info
		return info
	end

	-- Use: local crit = RQE.API.GetCriteriaInfo(criteriaIndex)    instead of: C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	-- Returns a table: { description, criteriaType, completed, quantity, totalQuantity, flags, assetID, criteriaID, duration, elapsed, failed, isWeightedProgress, isFormatted, quantityString }
	RQE.API.GetCriteriaInfo = function(criteriaIndex)
		local crit = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		RQE.ScenarioCriteriaInfo = crit
		return crit
	end

	-- Use: local crit = RQE.API.GetCriteriaInfoByStep(stepID, criteriaIndex)    instead of: C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
	-- Returns same structure as GetCriteriaInfo
	RQE.API.GetCriteriaInfoByStep = function(stepID, criteriaIndex)
		local crit = C_ScenarioInfo.GetCriteriaInfoByStep(stepID, criteriaIndex)
		RQE.ScenarioCriteriaByStep = crit
		return crit
	end

	-- Use: local towerType = RQE.API.GetJailersTowerTypeString(runType)    instead of: C_ScenarioInfo.GetJailersTowerTypeString(runType)
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
-- Miscellaneous
-------------------------------------------------

if major >= 11 then
	-- Use: local name = RQE.API.UnitName("target")    instead of: UnitName("target")
	RQE.API.UnitName = function(unit)
		return UnitName(unit)
	end
else
	-- Use: local name = RQE.API.UnitName("target")    instead of: UnitName("target")
	RQE.API.UnitName = function(unit)
		return UnitName(unit)
	end
end