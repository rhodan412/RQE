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

if major >= 3 then
	-- Use: local info = RQE.API.GetAchievementInfo(achievementID) instead of: C_AchievementInfo.GetAchievementInfo(achievementID)
	-- Returns a table:
	-- {
	--   id, name, points, completed, month, day, year, description, flags,
	--   icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic
	-- }
	-- Recall with: print(info.name, info.points, info.completed)
	-- Or: print(RQE.AchievementInfo.name, RQE.AchievementInfo.points)
	RQE.API.GetAchievementInfo = function(achievementID)
		local id, name, points, completed, month, day, year, description, flags, rawIcon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(achievementID)
		local iconFileID, iconPath

		-- Handle pre-7.3 vs post-7.3 behavior
		if type(rawIcon) == "number" then
			iconFileID = rawIcon
			iconPath = nil
		elseif type(rawIcon) == "string" then
			iconPath = rawIcon
			iconFileID = nil
		end

		RQE.AchievementInfo = {
			id = id,
			name = name,
			points = points,
			completed = completed,
			month = month,
			day = day,
			year = year,
			description = description,
			flags = flags,
			icon = iconFileID or rawIcon, -- normalized: prefer fileID
			iconFileID = iconFileID,
			iconPath = iconPath,
			rewardText = rewardText,
			isGuild = isGuild,
			wasEarnedByMe = wasEarnedByMe,
			earnedBy = earnedBy,
			isStatistic = isStatistic,
		}
		return RQE.AchievementInfo
	end
else
	RQE.API.GetAchievementInfo = function(achievementID) return nil end
end


-------------------------------------------------
-- 🧾 Adventure Journal / Factions APIs
-------------------------------------------------

if major >= 10 then
	-- Use: local info = RQE.API.GetMajorFactionData(factionID)	instead of: C_MajorFactions.GetMajorFactionData(factionID)
	-- Returns a table:
	-- {
	--   name, factionID, expansionID, bountySetID, isUnlocked,
	--   unlockDescription, unlockOrder, renownLevel,
	--   renownReputationEarned, renownLevelThreshold,
	--   textureKit, celebrationSoundKit, renownFanfareSoundKitID
	-- }
	-- Recall with: print(info.name, info.renownLevel)
	-- Or: print(RQE.MajorFactionInfo.name, RQE.MajorFactionInfo.renownLevel)
	RQE.API.GetMajorFactionData = function(factionID)
		local data = C_MajorFactions.GetMajorFactionData(factionID)
		if not data then return nil end

		RQE.MajorFactionInfo = {
			name = data.name,
			factionID = data.factionID,
			expansionID = data.expansionID,
			bountySetID = data.bountySetID,
			isUnlocked = data.isUnlocked,
			unlockDescription = data.unlockDescription,
			unlockOrder = data.unlockOrder,
			renownLevel = data.renownLevel,
			renownReputationEarned = data.renownReputationEarned,
			renownLevelThreshold = data.renownLevelThreshold,
			textureKit = data.textureKit,
			celebrationSoundKit = data.celebrationSoundKit,
			renownFanfareSoundKitID = data.renownFanfareSoundKitID,
		}
		return RQE.MajorFactionInfo
	end
else
	RQE.API.GetMajorFactionData = function(factionID) return nil end
end


-------------------------------------------------
-- 🎯 Gossip / NPC Interaction APIs
-------------------------------------------------

if major >= 9 then
	-- Structured gossip API (Shadowlands and later)

	-- Use: local options = RQE.API.GetGossipOptions()
	-- Returns a normalized table of gossip options
	-- Each entry has: {
	--   gossipOptionID, name, icon, rewards, status,
	--   spellID, flags, overrideIconID, selectOptionWhenOnlyOption,
	--   orderIndex
	-- }
	RQE.API.GetGossipOptions = function()
		local raw = C_GossipInfo.GetOptions() or {}
		local options = {}

		for i, v in ipairs(raw) do
			table.insert(options, {
				gossipOptionID = v.gossipOptionID,
				name = v.name,
				icon = v.icon,
				rewards = v.rewards,
				status = v.status,
				spellID = v.spellID,
				flags = v.flags,
				overrideIconID = v.overrideIconID,
				selectOptionWhenOnlyOption = v.selectOptionWhenOnlyOption,
				orderIndex = v.orderIndex,
			})
		end

		RQE.GossipOptions = options
		return options
	end

	-- Wrapper for selecting a gossip option
	-- Use: RQE.API.SelectGossipOption(optionID [, text, confirmed])
	RQE.API.SelectGossipOption = function(optionID, text, confirmed)
		return C_GossipInfo.SelectOption(optionID, text, confirmed)
	end

	-- Added in 10.0.7: Select by orderIndex
	-- Use: RQE.API.SelectGossipOptionByIndex(index [, text, confirmed])
	if C_GossipInfo.SelectOptionByIndex then
		RQE.API.SelectGossipOptionByIndex = function(index, text, confirmed)
			return C_GossipInfo.SelectOptionByIndex(index, text, confirmed)
		end
	else
		RQE.API.SelectGossipOptionByIndex = function(index, text, confirmed)
			return nil
		end
	end
else
	-- Classic gossip API (pre-9.0)
	-- GetGossipOptions() returns alternating pairs of (title, gossipType)
	-- Example: title1, gossip1, title2, gossip2, ...
	RQE.API.GetGossipOptions = function()
		local opts = {}
		local gossipData = { GetGossipOptions() }
		for i = 1, #gossipData, 2 do
			table.insert(opts, {
				name = gossipData[i],		  -- title
				gossipType = gossipData[i+1], -- banker, vendor, trainer, etc.
				index = math.ceil(i/2),	   -- 1-based index
			})
		end
		RQE.GossipOptions = opts
		return opts
	end

	-- Classic selection API
	-- Use: RQE.API.SelectGossipOption(index)
	RQE.API.SelectGossipOption = function(index)
		return SelectGossipOption(index)
	end

	-- No SelectOptionByIndex in Classic
	RQE.API.SelectGossipOptionByIndex = function(index) return nil end
end


-------------------------------------------------
-- 📢 Group / LFG APIs
-------------------------------------------------

if major >= 6 then
	-- Use: local info = RQE.API.CreateListing(createData)
	-- Returns a normalized table with at least:
	-- {
	--   success, activityIDs, questID, isAutoAccept, isCrossFactionListing,
	--   isPrivateGroup, newPlayerFriendly, playstyle,
	--   requiredDungeonScore, requiredItemLevel, requiredPvpRating
	-- }
	-- On 11.1+, also includes Blizzard’s structured fields.
	RQE.API.CreateListing = function(createData)
		local result = C_LFGList.CreateListing(createData)

		-- Normalize into table
		if type(result) == "table" then
			-- 11.1.0+ structured return
			RQE.LFGListingInfo = {
				activityIDs = result.activityIDs,
				questID = result.questID,
				isAutoAccept = result.isAutoAccept,
				isCrossFactionListing = result.isCrossFactionListing,
				isPrivateGroup = result.isPrivateGroup,
				newPlayerFriendly = result.newPlayerFriendly,
				playstyle = result.playstyle,
				requiredDungeonScore = result.requiredDungeonScore,
				requiredItemLevel = result.requiredItemLevel,
				requiredPvpRating = result.requiredPvpRating,
				success = result.success, -- if Blizzard provides this in 11.1+
			}
		else
			-- Pre-11.1 (just boolean success)
			RQE.LFGListingInfo = {
				success = result and true or false,
				activityIDs = createData.activityIDs,
				questID = createData.questID,
				isAutoAccept = createData.isAutoAccept,
				isCrossFactionListing = createData.isCrossFactionListing,
				isPrivateGroup = createData.isPrivateGroup,
				newPlayerFriendly = createData.newPlayerFriendly,
				playstyle = createData.playstyle,
				requiredDungeonScore = createData.requiredDungeonScore,
				requiredItemLevel = createData.requiredItemLevel,
				requiredPvpRating = createData.requiredPvpRating,
			}
		end

		return RQE.LFGListingInfo
	end

	-- Use: local results = RQE.API.SearchLFGList(categoryID, filters, preferredFilters, languageFilter, searchCrossFactionListings, advancedFilter, activityIDsFilter)
	-- Returns a normalized table of results:
	-- Each entry has at least:
	-- {
	--   searchResultID, name, comment, voiceChat, requiredItemLevel,
	--   requiredDungeonScore, requiredPvpRating, isCrossFactionListing,
	--   activityID, leaderName, numMembers, isAutoAccept, isPrivateGroup
	-- }
	-- Later patches (9.2.5, 11.0.7) add cross-faction + activityIDsFilter support.
	RQE.API.SearchLFGList = function(categoryID, filters, preferredFilters, languageFilter, searchCrossFactionListings, advancedFilter, activityIDsFilter)
		local results = C_LFGList.Search(categoryID, filters, preferredFilters, languageFilter, searchCrossFactionListings, advancedFilter, activityIDsFilter)

		-- results is normally an array of searchResultIDs
		local out = {}
		if results then
			for i, v in ipairs(results) do
				table.insert(out, { searchResultID = v })
			end
		end

		RQE.LFGSearchResults = out
		return out
	end
else
	-- Classic fallback (no LFGList APIs in <6)
	RQE.API.CreateListing = function(...) return nil end
	RQE.API.SearchLFGList = function(...) return {} end
end


-------------------------------------------------
-- 🗺️ Map APIs
-------------------------------------------------

if major >= 9 then
	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint()	instead of: C_Map.HasUserWaypoint()
	-- Returns a normalized table:
	-- {
	--   hasWaypoint -- boolean
	-- }
	RQE.API.HasUserWaypoint = function()
		local has = C_Map.HasUserWaypoint()
		RQE.HasWaypointInfo = {
			hasWaypoint = has or false,
		}
		return RQE.HasWaypointInfo
	end

	-- Use: RQE.API.ClearUserWaypoint()	instead of: C_Map.ClearUserWaypoint()
	-- Returns a normalized table:
	-- {
	--   cleared -- boolean (true if call succeeded)
	-- }
	RQE.API.ClearUserWaypoint = function()
		local ok = pcall(C_Map.ClearUserWaypoint) -- safe call, since it may throw if no waypoint set
		RQE.ClearWaypointInfo = {
			cleared = ok and true or false,
		}
		return RQE.ClearWaypointInfo
	end

	-- Use: RQE.API.SetUserWaypoint(point) instead of: C_Map.SetUserWaypoint(point)
	-- Returns a normalized table:
	-- {
	--   success, -- boolean (true if the waypoint was set successfully)
	--   uiMapID, -- number? (from point)
	--   x, y,	-- number? (from point.position:GetXY())
	--   z,	   -- number? (if provided in point)
	-- }
	RQE.API.SetUserWaypoint = function(point)
		local ok = pcall(C_Map.SetUserWaypoint, point)
		local x, y = nil, nil

		if point and point.position and point.position.GetXY then
			x, y = point.position:GetXY()
		end

		RQE.SetWaypointInfo = {
			success = ok and true or false,
			uiMapID = point and point.uiMapID or nil,
			x = x,
			y = y,
			z = point and point.z or nil,
		}
		return RQE.SetWaypointInfo
	end

	-- Use: local canSet = RQE.API.CanSetUserWaypointOnMap(uiMapID)	instead of: C_Map.CanSetUserWaypointOnMap(uiMapID)
	-- Returns a normalized table:
	-- {
	--   uiMapID, -- number
	--   canSet,  -- boolean
	-- }
	RQE.API.CanSetUserWaypointOnMap = function(uiMapID)
		local canSet = C_Map.CanSetUserWaypointOnMap(uiMapID)
		RQE.CanSetWaypointInfo = {
			uiMapID = uiMapID,
			canSet = canSet or false,
		}
		return RQE.CanSetWaypointInfo
	end

	-- Use: local position = RQE.API.GetUserWaypointPositionForMap(uiMapID)	instead of: C_Map.GetUserWaypointPositionForMap(uiMapID)
	-- Returns a normalized table:
	-- {
	--   uiMapID, -- number
	--   x,	   -- number? (0–1 range, nil if no waypoint set)
	--   y,	   -- number? (0–1 range, nil if no waypoint set)
	-- }
	RQE.API.GetUserWaypointPositionForMap = function(uiMapID)
		local pos = C_Map.GetUserWaypointPositionForMap(uiMapID)
		local x, y = nil, nil
		if pos and pos.GetXY then
			x, y = pos:GetXY()
		end

		RQE.UserWaypointPosInfo = {
			uiMapID = uiMapID,
			x = x,
			y = y,
		}
		return RQE.UserWaypointPosInfo
	end

	-- Use: local point = RQE.API.GetUserWaypoint()	instead of: C_Map.GetUserWaypoint()
	-- Returns a normalized table if a waypoint exists:
	-- {
	--   uiMapID, -- number
	--   x,	   -- number (0–1, scaled to map)
	--   y,	   -- number (0–1, scaled to map)
	--   z,	   -- number? (optional floor level)
	-- }
	-- Or returns nil if no waypoint set.
	RQE.API.GetUserWaypoint = function()
		local point = C_Map.GetUserWaypoint()
		if not point then
			RQE.UserWaypointInfo = nil
			return nil
		end

		local x, y = nil, nil
		if point.position and point.position.GetXY then
			x, y = point.position:GetXY()
		end

		RQE.UserWaypointInfo = {
			uiMapID = point.uiMapID,
			x = x,
			y = y,
			z = point.z or nil,
		}
		return RQE.UserWaypointInfo
	end

	-- Use: local link = RQE.API.GetUserWaypointHyperlink()	instead of: C_Map.GetUserWaypointHyperlink()
	-- Returns a normalized table:
	-- {
	--   hyperlink, -- string? (nil if no waypoint set)
	-- }
	RQE.API.GetUserWaypointHyperlink = function()
		local link = C_Map.GetUserWaypointHyperlink()
		RQE.UserWaypointLinkInfo = {
			hyperlink = link or nil,
		}
		return RQE.UserWaypointLinkInfo
	end

elseif major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Use: local info = RQE.API.GetBestMapForUnit("player") instead of: C_Map.GetBestMapForUnit("player")
	-- Returns a normalized table:
	-- {
	--   uiMapID,	 -- number? lowest map ID the unit is on
	--   unit,		-- string  the queried unitToken
	--   mapName,	 -- string? from C_Map.GetMapInfo(uiMapID)
	--   mapType,	 -- number? from C_Map.GetMapInfo
	--   parentMapID, -- number? from C_Map.GetMapInfo
	-- }
	-- Example: print(info.mapName, info.uiMapID)
	RQE.API.GetBestMapForUnit = function(unit)
		local uiMapID = C_Map.GetBestMapForUnit(unit)
		local mapInfo = uiMapID and C_Map.GetMapInfo(uiMapID) or {}

		RQE.BestMapForUnit = {
			uiMapID = uiMapID,
			unit = unit,
			mapName = mapInfo and mapInfo.name or nil,
			mapType = mapInfo and mapInfo.mapType or nil,
			parentMapID = mapInfo and mapInfo.parentMapID or nil,
		}
		return RQE.BestMapForUnit
	end

	-- Returns: Vector2D or nil
	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player")	instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Returns normalized table:
	-- {
	--   x, y,		 -- numbers in 0–1 range
	--   uiMapID,	  -- number
	--   unit,		 -- string
	--   isRestricted, -- boolean (true if nil was returned in restricted zones)
	-- }
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		local pos = C_Map.GetPlayerMapPosition(mapID, unit)
		local x, y = nil, nil
		local restricted = false

		if pos then
			x, y = pos:GetXY()
		else
			restricted = true
		end

		RQE.PlayerMapPosition = {
			x = x,
			y = y,
			uiMapID = mapID,
			unit = unit,
			isRestricted = restricted,
		}
		return RQE.PlayerMapPosition
	end

	-- Use: local name = RQE.API.GetAreaInfo(areaID) instead of: C_Map.GetAreaInfo(areaID)
	-- Returns a normalized table:
	-- {
	--   areaID, -- number
	--   name,   -- string (localized area name)
	-- }
	RQE.API.GetAreaInfo = function(areaID)
		local name = C_Map.GetAreaInfo(areaID)
		RQE.AreaInfo = {
			areaID = areaID,
			name = name,
		}
		return RQE.AreaInfo
	end

	-- Use: local info = RQE.API.GetMapInfo(uiMapID) instead of: C_Map.GetMapInfo(uiMapID)
	-- Returns a normalized table:
	-- {
	--   mapID,		-- number
	--   name,		 -- string
	--   mapType,	  -- Enum.UIMapType
	--   parentMapID,  -- number
	--   flags,		-- number? (added in 9.0.1+, expands in 10.x and 11.x)
	-- }
	RQE.API.GetMapInfo = function(uiMapID)
		local info = C_Map.GetMapInfo(uiMapID)
		if not info then return nil end

		RQE.MapInfo = {
			mapID = info.mapID,
			name = info.name,
			mapType = info.mapType,
			parentMapID = info.parentMapID,
			flags = info.flags or nil,
		}
		return RQE.MapInfo
	end

	-- Use: local info = RQE.API.GetMapChildrenInfo(uiMapID) instead of: C_Map.GetMapChildrenInfo(uiMapID)
	-- Returns an array of normalized tables:
	-- {
	--   mapID,	   -- number
	--   name,		-- string
	--   mapType,	 -- Enum.UIMapType
	--   parentMapID, -- number
	--   flags,	   -- number? (exists 9.0.1+; more values in 10.x, 11.x)
	-- }
	RQE.API.GetMapChildrenInfo = function(uiMapID, mapType, allDescendants)
		local infos = C_Map.GetMapChildrenInfo(uiMapID, mapType, allDescendants)
		local results = {}

		if infos then
			for _, info in ipairs(infos) do
				table.insert(results, {
					mapID = info.mapID,
					name = info.name,
					mapType = info.mapType,
					parentMapID = info.parentMapID,
					flags = info.flags or nil,
				})
			end
		end

		RQE.MapChildrenInfo = results
		return results
	end

elseif major >= 8 then
	-- Use: local x, y = RQE.API.GetNextWaypointForMap(questID, uiMapID) instead of: C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
	-- Returns a normalized table:
	-- {
	--   questID, -- number
	--   uiMapID, -- number
	--   x,	   -- number? (nil if no waypoint)
	--   y,	   -- number? (nil if no waypoint)
	-- }
	RQE.API.GetNextWaypointForMap = function(questID, uiMapID)
		local x, y = C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
		RQE.NextWaypointInfo = {
			questID = questID,
			uiMapID = uiMapID,
			x = x,
			y = y,
		}
		return RQE.NextWaypointInfo
	end

elseif major >= 4 then
	-- Only GetMapNameByID(mapID) exists
	-- Returns a normalized table:
	-- {
	--   mapID, -- number
	--   name,  -- string
	-- }
	RQE.API.GetMapInfo = function(mapID)
		local name = GetMapNameByID(mapID)
		RQE.MapInfo = {
			mapID = mapID,
			name = name,
		}
		return RQE.MapInfo
	end

elseif major >= 1 then
	-- Classic fallback (1.13 re-release + Vanilla-style GetPlayerMapPosition)
	-- Some Classic clients expose C_Map API, others only the old global.
	local hasCMap = C_Map and C_Map.GetPlayerMapPosition

	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		local x, y, restricted
		if hasCMap then
			-- Classic Era with C_Map API
			local pos = C_Map.GetPlayerMapPosition(mapID, unit)
			if pos then
				x, y = pos:GetXY()
			else
				restricted = true
			end
		elseif GetPlayerMapPosition then
			-- Very old Classic fallback
			local px, py = GetPlayerMapPosition(mapID, unit)
			if px and py then
				x, y = px, py
			else
				restricted = true
			end
		end

		RQE.PlayerMapPosition = {
			x = x,
			y = y,
			uiMapID = mapID,
			unit = unit,
			isRestricted = restricted or false,
		}
		return RQE.PlayerMapPosition
	end

else

	-- Classic fallback (<8, but also added in Classic 1.13.x+)
	RQE.API.GetBestMapForUnit = function(unit)
		local uiMapID = C_Map.GetBestMapForUnit(unit)
		local mapInfo = uiMapID and C_Map.GetMapInfo(uiMapID) or {}

		RQE.BestMapForUnit = {
			uiMapID = uiMapID,
			unit = unit,
			mapName = mapInfo and mapInfo.name or nil,
			mapType = mapInfo and mapInfo.mapType or nil,
			parentMapID = mapInfo and mapInfo.parentMapID or nil,
		}
		return RQE.BestMapForUnit
	end

	-- Use: local pos = RQE.API.GetPlayerMapPosition(mapID, "player") instead of: C_Map.GetPlayerMapPosition(mapID, "player")
	-- Pre-1.0 nothing available
	RQE.API.GetPlayerMapPosition = function(mapID, unit)
		return { x = nil, y = nil, uiMapID = mapID, unit = unit, isRestricted = true }
	end

	-- Use: local hasWaypoint = RQE.API.HasUserWaypoint() instead of: C_Map.HasUserWaypoint()
	-- Classic (no API available)
	RQE.API.HasUserWaypoint = function()
		RQE.HasWaypointInfo = {
			hasWaypoint = false,
		}
		return RQE.HasWaypointInfo
	end

	-- Use: RQE.API.ClearUserWaypoint()	instead of: C_Map.ClearUserWaypoint()
	-- Classic (no API available)
	RQE.API.ClearUserWaypoint = function()
		RQE.ClearWaypointInfo = {
			cleared = false,
		}
		return RQE.ClearWaypointInfo
	end

	-- Use: RQE.API.SetUserWaypoint(point) instead of: C_Map.SetUserWaypoint(point)
	-- Classic (no API available)
	RQE.API.SetUserWaypoint = function(point)
		RQE.SetWaypointInfo = {
			success = false,
			uiMapID = point and point.uiMapID or nil,
			x = nil,
			y = nil,
			z = nil,
		}
		return RQE.SetWaypointInfo
	end

	-- Classic (no API available)
	RQE.API.CanSetUserWaypointOnMap = function(uiMapID)
		RQE.CanSetWaypointInfo = {
			uiMapID = uiMapID,
			canSet = false,
		}
		return RQE.CanSetWaypointInfo
	end

	-- Pre-1.13 Vanilla (no API available)
	RQE.API.GetAreaInfo = function(areaID)
		RQE.AreaInfo = {
			areaID = areaID,
			name = nil,
		}
		return RQE.AreaInfo
	end

	RQE.API.GetMapInfo = function(mapID)
		local name = GetMapInfo(mapID)
		RQE.MapInfo = {
			mapID = mapID,
			name = name,
		}
		return RQE.MapInfo
	end

	-- Vanilla / TBC / WotLK (no API available)
	RQE.API.GetMapChildrenInfo = function(uiMapID, mapType, allDescendants)
		RQE.MapChildrenInfo = {}
		return RQE.MapChildrenInfo
	end

	-- Classic / Vanilla (no API available)
	RQE.API.GetUserWaypointPositionForMap = function(uiMapID)
		RQE.UserWaypointPosInfo = {
			uiMapID = uiMapID,
			x = nil,
			y = nil,
		}
		return RQE.UserWaypointPosInfo
	end

	-- Classic / Vanilla (no API available)
	RQE.API.GetUserWaypoint = function()
		RQE.UserWaypointInfo = nil
		return nil
	end

	-- Classic / Vanilla (no API available)
	RQE.API.GetUserWaypointHyperlink = function()
		RQE.UserWaypointLinkInfo = {
			hyperlink = nil,
		}
		return RQE.UserWaypointLinkInfo
	end

	-- Use: local x, y = RQE.API.GetNextWaypointForMap(questID, uiMapID) instead of: C_QuestLog.GetNextWaypointForMap(questID, uiMapID)
	-- Classic / Vanilla (no API available)
	RQE.API.GetNextWaypointForMap = function(questID, uiMapID)
		RQE.NextWaypointInfo = {
			questID = questID,
			uiMapID = uiMapID,
			x = nil,
			y = nil,
		}
		return RQE.NextWaypointInfo
	end
end


-------------------------------------------------
-- 🛒 Merchant APIs
-------------------------------------------------

if major >= 12 then
	-- Use: local info = RQE.API.GetMerchantItemInfo(index) instead of: C_MerchantFrame.GetItemInfo(index)
	-- Returns a table: { name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID }
	-- Recalled with either: print("Merchant item:", info.name, info.price, info.numAvailable) - OR - print("Merchant item:", RQE.MerchantInfo.name, RQE.MerchantInfo.price, RQE.MerchantInfo.numAvailable)
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = C_MerchantFrame.GetItemInfo(index)

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

	-- Use: local info = RQE.API.GetMerchantFrameItemInfo(index) instead of: C_MerchantFrame.GetItemInfo(index)
	-- Returns normalized MerchantItemInfo table
	RQE.API.GetMerchantFrameItemInfo = function(index)
		local info = C_MerchantFrame.GetItemInfo(index)
		if not info then return nil end

		-- Normalize into our addon’s table format
		return {
			name = info.name,
			texture = info.texture,
			price = info.price,
			stackCount = info.stackCount,
			numAvailable = info.numAvailable,
			isPurchasable = info.isPurchasable,
			isUsable = info.isUsable,
			hasExtendedCost = info.hasExtendedCost,
			currencyID = info.currencyID,
			spellID = info.spellID,
			isQuestStartItem = info.isQuestStartItem,
		}
	end

elseif major >= 11 then
	-- Use: local info = RQE.API.GetMerchantItemInfo(index)	instead of: GetMerchantItemInfo(index)
	-- Returns a table: { name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID }
	-- Recalled with either: print("Merchant item:", info.name, info.price, info.numAvailable) - OR - print("Merchant item:", RQE.MerchantInfo.name, RQE.MerchantInfo.price, RQE.MerchantInfo.numAvailable)
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = C_MerchantFrame.GetItemInfo(index)

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

	-- Transition patch (11.0.5+): both APIs exist but GetMerchantItemInfo is deprecated
	RQE.API.GetMerchantFrameItemInfo = function(index)
		local info = C_MerchantFrame.GetItemInfo(index)
		if not info then return nil end

		return {
			name = info.name,
			texture = info.texture,
			price = info.price,
			stackCount = info.stackCount,
			numAvailable = info.numAvailable,
			isPurchasable = info.isPurchasable,
			isUsable = info.isUsable,
			hasExtendedCost = info.hasExtendedCost,
			currencyID = info.currencyID,
			spellID = info.spellID,
			isQuestStartItem = info.isQuestStartItem,
		}
	end

elseif (major > 8) or (major == 8 and minor >= 1) then
	-- Retail 8.1.5 and later
	-- Use: local refundable = RQE.API.IsMerchantItemRefundable(index) instead of: C_MerchantFrame.IsMerchantItemRefundable(index)
	-- Returns: boolean
	RQE.API.IsMerchantItemRefundable = function(index)
		return C_MerchantFrame.IsMerchantItemRefundable(index)
	end

elseif (major > 7) or (major == 7 and minor >= 2) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Post-7.2 Retail and all Classic re-releases (1.13+)
	-- isPurchasable field is available
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)

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

	-- Returns flat values, we normalize into a table
	RQE.API.GetMerchantFrameItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)

		return {
			name = name,
			texture = texture,
			price = price,
			stackCount = quantity,
			numAvailable = numAvailable,
			isPurchasable = isPurchasable,
			isUsable = isUsable,
			hasExtendedCost = extendedCost,
			currencyID = currencyID,
			spellID = spellID,
			isQuestStartItem = false, -- not exposed before 11.x
		}
	end

	-- Retail post-7.2 and Classic re-releases
	-- Use: local id = RQE.API.GetBuybackItemID(slot) instead of: C_MerchantFrame.GetBuybackItemID(slot)
	-- Returns: number buybackItemID
	RQE.API.GetBuybackItemID = function(buybackSlotIndex)
		return C_MerchantFrame.GetBuybackItemID(buybackSlotIndex)
	end

else

	-- Vanilla → Legion pre-7.2
	-- isPurchasable did not exist yet
	-- Use: local info = RQE.API.GetMerchantItemInfo(index)	instead of: GetMerchantItemInfo(index)
	-- Returns a table: { name, texture, price, quantity, numAvailable, isUsable }
	-- Recalled with either: print("Merchant item:", info.name, info.price, info.numAvailable) - OR - print("Merchant item:", RQE.MerchantInfo.name, RQE.MerchantInfo.price, RQE.MerchantInfo.numAvailable)
	-- info.name is better for functions as self-contained, but can use RQE.MerchantInfo.name if you need to recall last known without running the RQE.API.GetMerchantItemInfo(index) function call
	RQE.API.GetMerchantItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)

		RQE.MerchantInfo = {
			name = name,
			texture = texture,
			price = price,
			quantity = quantity,
			numAvailable = numAvailable,
			isUsable = isUsable,
			extendedCost = extendedCost,
			currencyID = currencyID,
			spellID = spellID,
			isPurchasable = true, -- normalize: default true since field didn’t exist yet
		}
		return RQE.MerchantInfo
	end

	-- API not available
	RQE.API.GetBuybackItemID = function(buybackSlotIndex)
		return nil
	end

	-- isPurchasable didn’t exist yet
	RQE.API.GetMerchantFrameItemInfo = function(index)
		local name, texture, price, quantity, numAvailable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)

		return {
			name = name,
			texture = texture,
			price = price,
			stackCount = quantity,
			numAvailable = numAvailable,
			isPurchasable = true, -- normalize: assume true since field didn’t exist yet
			isUsable = isUsable,
			hasExtendedCost = extendedCost,
			currencyID = currencyID,
			spellID = spellID,
			isQuestStartItem = false,
		}
	end

	-- Classic and Retail pre-8.1.5
	RQE.API.IsMerchantItemRefundable = function(index)
		return false
	end
end


-------------------------------------------------
-- 🧭 Quest APIs
-------------------------------------------------

if major >= 9 then
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID() instead of: C_SuperTrack.GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return C_SuperTrack.GetSuperTrackedQuestID()
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries() instead of: C_QuestLog.GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		local numShownEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
		return numShownEntries, numQuests
	end

	-- Use: local objectives = RQE.API.GetQuestObjectives(questID)		instead of: C_QuestLog.GetQuestObjectives(questID)
	RQE.API.GetQuestObjectives = function(questID)
		return C_QuestLog.GetQuestObjectives(questID)
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingQuest()	instead of: C_SuperTrack.IsSuperTrackingQuest()
	RQE.API.IsSuperTrackingQuest = function()
		return C_SuperTrack.IsSuperTrackingQuest()
	end

elseif (major == 8 and minor >= 2) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Retail 8.2.5–8.3.x and Classic 1.13+ → C_QuestSession
	RQE.API.GetSuperTrackedQuestID = function()
		return C_QuestSession.GetSuperTrackedQuest()
	end

elseif major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Retail 8.0+ and Classic re-releases (1.13+) → C_QuestLog
	RQE.API.GetQuestObjectives = function(questID)
		local objectives = C_QuestLog.GetQuestObjectives(questID)
		RQE.QuestObjectives = objectives
		return objectives or {}
	end

else

	-- Classic (1.13.2 etc.)
	-- Use: local questID = RQE.API.GetSuperTrackedQuestID()	instead of: GetSuperTrackedQuestID()
	RQE.API.GetSuperTrackedQuestID = function()
		return GetSuperTrackedQuestID and GetSuperTrackedQuestID() or nil
	end

	-- Use: local numEntries = RQE.API.GetNumQuestLogEntries()	instead of: GetNumQuestLogEntries()
	RQE.API.GetNumQuestLogEntries = function()
		local numEntries, numQuests = GetNumQuestLogEntries()
		return numEntries, numQuests
	end

	-- Vanilla (1.0–1.12) → no objectives API
	RQE.API.GetQuestObjectives = function(questID)
		return {}
	end

	-- Classic (1.13+) and Vanilla (1.0–1.12) → not available
	RQE.API.IsSuperTrackingQuest = function()
		return false
	end
end


-------------------------------------------------
-- 🗂️ Quest Line / Task / World Quests APIs
-------------------------------------------------

if major > 11 then
	-- Use: local info = RQE.API.GetQuestLineInfo(questLineID, uiMapID)	instead of: C_QuestLine.GetQuestLineInfo(...)
	RQE.API.GetQuestLineInfo = function(questLineID, uiMapID)
		return C_QuestLine.GetQuestLineInfo(questLineID, uiMapID)
	end

	-- Use: local ignore = RQE.API.QuestLineIgnoresAccountCompletedFiltering(uiMapID, questLineID)	instead of: C_QuestLine.QuestLineIgnoresAccountCompletedFiltering(uiMapID, questLineID)
	RQE.API.QuestLineIgnoresAccountCompletedFiltering = function(uiMapID, questLineID)
		return C_QuestLine.QuestLineIgnoresAccountCompletedFiltering(uiMapID, questLineID)
	end

elseif (major > 10) or (major == 10 and minor >= 1 and patch >= 5) then
	-- Returns: number[] (list of questIDs)
	-- Use: local questIDs = RQE.API.GetForceVisibleQuests(uiMapID)	instead of: C_QuestLine.GetForceVisibleQuests(uiMapID)
	RQE.API.GetForceVisibleQuests = function(uiMapID)
		return C_QuestLine.GetForceVisibleQuests(uiMapID)
	end

elseif major >= 9 then
	-- Use: local isComplete = RQE.API.IsQuestLineComplete(questLineID)	instead of: C_QuestLine.IsComplete(questLineID)
	RQE.API.IsQuestLineComplete = function(questLineID)
		return C_QuestLine.IsComplete(questLineID)
	end

elseif major > 8 or (major == 8 and minor >= 1) then
	-- Use: RQE.API.RequestQuestLinesForMap(uiMapID)	instead of: C_QuestLine.RequestQuestLinesForMap(uiMapID)
	RQE.API.RequestQuestLinesForMap = function(uiMapID)
		return C_QuestLine.RequestQuestLinesForMap(uiMapID)
	end

elseif major >= 8 then
	-- Battle for Azeroth 8.0 → Dragonflight 10.x
	-- Original form, no `displayableOnly` argument.
	RQE.API.GetQuestLineInfo = function(questLineID, uiMapID)
		return C_QuestLine.GetQuestLineInfo(questLineID, uiMapID)
	end

	-- Use: local questLines = RQE.API.GetAvailableQuestLines(uiMapID)	instead of: C_QuestLine.GetAvailableQuestLines(uiMapID)
	RQE.API.GetAvailableQuestLines = function(uiMapID)
		return C_QuestLine.GetAvailableQuestLines(uiMapID)
	end

	-- Use: local questIDs = RQE.API.GetQuestLineQuests(questLineID)	instead of: C_QuestLine.GetQuestLineQuests(questLineID)
	RQE.API.GetQuestLineQuests = function(questLineID)
		return C_QuestLine.GetQuestLineQuests(questLineID)
	end

elseif major > 6 or (major == 6 and minor >= 2) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Use: local progress = RQE.API.GetQuestProgressBarInfo(questID)	instead of: C_TaskQuest.GetQuestProgressBarInfo(questID)
	RQE.API.GetQuestProgressBarInfo = function(questID)
		return C_TaskQuest.GetQuestProgressBarInfo(questID)
	end

else
	-- Classic (1.13+ re-releases) and Vanilla (1.0–1.12)
	-- Quest lines did not exist.
	RQE.API.GetQuestLineInfo = function(questLineID, uiMapID)
		return nil
	end

	-- Vanilla & early expansions (<6.2) — no Task Quest system
	RQE.API.GetQuestProgressBarInfo = function(questID)
		return nil
	end

	-- Not available in Classic or Vanilla
	RQE.API.GetAvailableQuestLines = function(uiMapID)
		return {}
	end

	-- Not available in Classic or Retail before 10.1.5
	RQE.API.GetForceVisibleQuests = function(uiMapID)
		return {}
	end

	-- Not available in Classic or Vanilla
	RQE.API.GetQuestLineQuests = function(questLineID)
		return {}
	end

	-- Not available in Classic or Vanilla
	RQE.API.IsQuestLineComplete = function(questLineID)
		return false
	end

	-- Not available pre-11 or in Classic/Vanilla
	RQE.API.QuestLineIgnoresAccountCompletedFiltering = function(uiMapID, questLineID)
		return false
	end

	-- Not available pre-8.1, in Classic, or Vanilla
	RQE.API.RequestQuestLinesForMap = function(uiMapID)
		return nil
	end
end


-------------------------------------------------
-- 📜 Quest Log / Quest Info APIs
-------------------------------------------------

if major >= 11 then
	-- Use: local index = RQE.API.GetHeaderIndexForQuest(questID) instead of: C_QuestLog.GetHeaderIndexForQuest(questID)
	RQE.API.GetHeaderIndexForQuest = function(questID)
		return C_QuestLog.GetHeaderIndexForQuest(questID)
	end

	-- Use: local index = RQE.API.GetHeaderIndexForQuest(questID) instead of: C_QuestLog.GetHeaderIndexForQuest(questID)
	-- Returns:
	--   index -- number? : Header index for the given quest, or nil if not found
	--
	-- Use: local currencies = RQE.API.GetQuestRewardCurrencies(questID) instead of: C_QuestLog.GetQuestRewardCurrencies(questID)
	-- Returns a normalized table array of QuestRewardCurrencyInfo:
	-- {
	--   {
	--	 texture,				-- number : fileID of the currency icon
	--	 name,				   -- string : currency name
	--	 currencyID,			 -- number : unique currency ID
	--	 quality,				-- number : quality/rarity of the currency
	--	 baseRewardAmount,	   -- number : base reward amount
	--	 bonusRewardAmount,	  -- number : bonus reward amount
	--	 totalRewardAmount,	  -- number : total (base + bonus) reward amount
	--	 questRewardContextFlags -- Enum.QuestRewardContextFlags? (None, FirstCompletionBonus, RepeatCompletionBonus)
	--   },
	--   ...
	-- }
	RQE.API.GetQuestRewardCurrencies = function(questID)
		local results = {}
		local list = C_QuestLog.GetQuestRewardCurrencies(questID)
		if not list then
			return results
		end

		for i, info in ipairs(list) do
			table.insert(results, {
				texture				= info.texture,
				name				= info.name,
				currencyID			= info.currencyID,
				quality				= info.quality,
				baseRewardAmount	= info.baseRewardAmount,
				bonusRewardAmount	= info.bonusRewardAmount,
				totalRewardAmount	= info.totalRewardAmount,
				questRewardContextFlags	= info.questRewardContextFlags,
			})
		end

		return results
	end

	-- Use: local info = RQE.API.GetQuestRewardCurrencyInfo(questID, currencyIndex, isChoice) instead of: C_QuestLog.GetQuestRewardCurrencyInfo(questID, currencyIndex, isChoice)
	-- Returns a normalized QuestRewardCurrencyInfo table, or nil if unavailable:
	-- {
	--   texture,				-- number : fileID of the currency icon
	--   name,				   -- string : currency name
	--   currencyID,			 -- number : unique currency ID
	--   quality,				-- number : quality/rarity of the currency
	--   baseRewardAmount,	   -- number : base reward amount
	--   bonusRewardAmount,	  -- number : bonus reward amount
	--   totalRewardAmount,	  -- number : total (base + bonus) reward amount
	--   questRewardContextFlags -- Enum.QuestRewardContextFlags? (None, FirstCompletionBonus, RepeatCompletionBonus)
	-- }
	RQE.API.GetQuestRewardCurrencyInfo = function(questID, currencyIndex, isChoice)
		local info = C_QuestLog.GetQuestRewardCurrencyInfo(questID, currencyIndex, isChoice)
		if not info then
			return nil
		end
		return {
			texture			= info.texture,
			name			= info.name,
			currencyID		= info.currencyID,
			quality			= info.quality,
			baseRewardAmount	= info.baseRewardAmount,
			bonusRewardAmount	= info.bonusRewardAmount,
			totalRewardAmount	= info.totalRewardAmount,
			questRewardContextFlags	= info.questRewardContextFlags,
		}
	end

	-- Use: local info = RQE.API.IsMetaQuest(questID) instead of: C_QuestLog.IsMetaQuest(questID)
	-- Returns a normalized table:
	-- {
	--   isMeta, -- boolean : true if the quest is a meta quest, false otherwise
	-- }
	RQE.API.IsMetaQuest = function(questID)
		local isMeta = C_QuestLog.IsMetaQuest(questID)

		RQE.IsMetaQuestInfo = {
			isMeta = isMeta,
		}

		return RQE.IsMetaQuestInfo
	end

elseif major > 10 or (major == 10 and minor >= 1 and rev >= 5) then
	-- Use: local info = RQE.API.IsImportantQuest(questID) instead of: C_QuestLog.IsImportantQuest(questID)
	-- Returns a normalized table:
	-- {
	--   isImportant, -- boolean : true if the quest is flagged as important, false otherwise
	-- }
	RQE.API.IsImportantQuest = function(questID)
		local isImportant = C_QuestLog.IsImportantQuest(questID)

		RQE.IsImportantQuestInfo = {
			isImportant = isImportant,
		}

		return RQE.IsImportantQuestInfo
	end

elseif major >= 10 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and minor >= 14) then
	-- Use C_QuestInfoSystem.GetQuestRewardSpellInfo (10.1+ and Classic 1.14+)
	-- Returns QuestRewardSpellInfo with Enum.QuestCompleteSpellType values
	-- Use: local info = RQE.API.GetQuestRewardSpellInfo(questID, spellID) instead of: C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
	-- Returns a normalized table:
	-- {
	--   texture,			-- number : fileID of the spell icon
	--   name,				-- string : name of the spell
	--   garrFollowerID,	-- number? : garrison follower ID if applicable
	--   isTradeskill,		-- boolean : true if the spell is a tradeskill spell
	--   isSpellLearned,		-- boolean : true if the spell has already been learned
	--   hideSpellLearnText,	-- boolean : whether to hide the "Learned" text
	--   isBoostSpell,			-- boolean : true if the spell is a boost-type spell
	--   genericUnlock,			-- boolean : true if the spell represents a generic unlock
	--   type,					-- Enum.QuestCompleteSpellType : classification of the reward spell
	-- }
	RQE.API.GetQuestRewardSpellInfo = function(questID, spellID)
		local info = C_QuestInfoSystem.GetQuestRewardSpellInfo(questID, spellID)
		if not info then
			return nil
		end

		return {
			texture			= info.texture,			-- fileID
			name			= info.name,			-- string
			garrFollowerID	= info.garrFollowerID,	-- number?
			isTradeskill	= info.isTradeskill,	-- boolean
			isSpellLearned	= info.isSpellLearned,	-- boolean
			hideSpellLearnText = info.hideSpellLearnText, -- boolean
			isBoostSpell	= info.isBoostSpell,	-- boolean
			genericUnlock	= info.genericUnlock,	-- boolean
			type			= info.type,			-- Enum.QuestCompleteSpellType
		}
	end

elseif major >= 10 then
	-- Use: local awards = RQE.API.DoesQuestAwardReputationWithFaction(questID, factionID) instead of: C_QuestLog.DoesQuestAwardReputationWithFaction(...)
	RQE.API.DoesQuestAwardReputationWithFaction = function(questID, factionID)
		return C_QuestLog.DoesQuestAwardReputationWithFaction(questID, factionID)
	end

	-- Use: local reputationRewards = RQE.API.GetQuestLogMajorFactionReputationRewards(questID) instead of: C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
	-- Returns a normalized table of reputation rewards:
	--	{
	--		{
	--			factionID,	 -- number : the ID of the faction
	--			rewardAmount,  -- number : the amount of reputation granted
	--		},
	--	}
	-- Use: local reputationRewards = RQE.API.GetQuestLogMajorFactionReputationRewards(questID)	instead of: C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
	RQE.API.GetQuestLogMajorFactionReputationRewards = function(questID)
		local rewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards(questID)
		if not rewards or #rewards == 0 then
			return {}
		end

		local results = {}
		for _, reward in ipairs(rewards) do
			table.insert(results, {
				factionID		= reward.factionID,		-- number
				rewardAmount	= reward.rewardAmount,	-- number
			})
		end
		return results
	end

	-- Use: local info = RQE.API.UnitIsRelatedToActiveQuest(unit) instead of: C_QuestLog.UnitIsRelatedToActiveQuest(unit)
	-- Returns a normalized table:
	--	{
	--		unit,					-- string : the unit identifier (e.g. "target", "mouseover")
	--		isRelatedToActiveQuest	-- boolean : true if the unit is related to an active quest, false otherwise
	--	}
	RQE.API.UnitIsRelatedToActiveQuest = function(unit)
		local isRelatedToActiveQuest = C_QuestLog.UnitIsRelatedToActiveQuest(unit)

		RQE.UnitIsRelatedToActiveQuestInfo = {
			unit = unit,
			isRelatedToActiveQuest = isRelatedToActiveQuest,
		}

		return RQE.UnitIsRelatedToActiveQuestInfo
	end

elseif major >= 9 and minor >= 1 then
	-- Use: local info = RQE.API.GetQuestLogPortraitGiver(questLogIndex) instead of: C_QuestLog.GetQuestLogPortraitGiver(questLogIndex)
	-- Returns a normalized table:
	--	{
	--		portraitGiver		-- number   : ID of the portrait giver
	--		portraitGiverText	-- string   : description text shown for the portrait giver
	--		portraitGiverName	-- string   : name of the portrait giver
	--		portraitGiverMount	-- number   : mount ID if the portrait giver is mounted
	--		portraitGiverModelSceneID -- number? : optional model scene ID for rendering
	--	}
	RQE.API.GetQuestLogPortraitGiver = function(questLogIndex)
		local portraitGiver, portraitGiverText, portraitGiverName, portraitGiverMount, portraitGiverModelSceneID =
			C_QuestLog.GetQuestLogPortraitGiver(questLogIndex)

		return {
			portraitGiver			= portraitGiver,		-- number
			portraitGiverText		= portraitGiverText,	-- string
			portraitGiverName		= portraitGiverName,	-- string
			portraitGiverMount		= portraitGiverMount,	-- number
			portraitGiverModelSceneID = portraitGiverModelSceneID,	-- number?
		}
	end

elseif major >= 9 then
	-- Retail 9.0+  → C_QuestLog.GetInfo(questLogIndex)
	-- Use: local title = RQE.API.GetTitleForQuestID(questID)	instead of: C_QuestLog.GetTitleForQuestID(questID)
	RQE.API.GetTitleForQuestID = function(questID)
		return C_QuestLog.GetTitleForQuestID(questID)
	end

	-- Use: local info = RQE.API.GetQuestLogInfo(questIndex) instead of: C_QuestLog.GetInfo(questIndex)
	-- Returns a normalized table (QuestInfo):
	--	{
	--		title				-- string	: The title of the quest
	--		questLogIndex		-- number	: The index in the quest log
	--		questID				-- number	: Unique quest ID
	--		campaignID			-- number?	: Campaign association (if any)
	--		level				-- number	: The level of the quest
	--		difficultyLevel		-- number	: Difficulty scaling level
	--		suggestedGroup		-- number	: Suggested group size, 0 if solo
	--		frequency			-- Enum?	: Quest frequency (daily, weekly, etc.)
	--		isHeader			-- boolean	: Whether this entry is a header
	--		useMinimalHeader	-- boolean	: Minimal header style (10.0.2+)
	--		sortAsNormalQuest	-- boolean	: Sort as normal quest (11.0.2+)
	--		isCollapsed			-- boolean	: Whether the header is collapsed
	--		startEvent			-- boolean	: Is started by event
	--		isTask				-- boolean	: Is a task-style quest
	--		isBounty			-- boolean	: Is a bounty quest
	--		isStory				-- boolean	: Is a story quest
	--		isScaling			-- boolean	: Quest scales with level
	--		isOnMap				-- boolean	: Appears on the map
	--		hasLocalPOI			-- boolean	: Has local points of interest
	--		isHidden			-- boolean	: Hidden from the quest log
	--		isAutoComplete		-- boolean	: Automatically completes
	--		overridesSortOrder	-- boolean	: Overrides sorting rules
	--		readyForTranslation	-- boolean?	: True if flagged for localization
	--		isInternalOnly		-- boolean	: For internal/testing only
	--		isAbandonOnDisable		-- boolean	: Abandon when disabled (10.2.7+)
	--		headerSortKey			-- number?	: Header sorting key (11.0.0+)
	--		questClassification		-- Enum?	: Quest classification (11.0.2+)
	--	}
	RQE.API.GetQuestLogInfo = function(questIndex)
		local info = C_QuestLog.GetInfo(questIndex)
		if not info then return nil end

		-- Return as-is, already structured
		return {
			title			= info.title,
			questLogIndex	= info.questLogIndex,
			questID			= info.questID,
			campaignID		= info.campaignID,
			level			= info.level,
			difficultyLevel	= info.difficultyLevel,
			suggestedGroup	= info.suggestedGroup,
			frequency		= info.frequency,
			isHeader		= info.isHeader,
			useMinimalHeader	= info.useMinimalHeader,	-- 10.0.2+
			sortAsNormalQuest	= info.sortAsNormalQuest,	-- 11.0.2+
			isCollapsed		= info.isCollapsed,
			startEvent		= info.startEvent,
			isTask			= info.isTask,
			isBounty		= info.isBounty,
			isStory			= info.isStory,
			isScaling		= info.isScaling,
			isOnMap			= info.isOnMap,
			hasLocalPOI		= info.hasLocalPOI,
			isHidden		= info.isHidden,
			isAutoComplete	= info.isAutoComplete,
			overridesSortOrder	= info.overridesSortOrder,
			readyForTranslation = info.readyForTranslation,
			isInternalOnly		= info.isInternalOnly,
			isAbandonOnDisable	= info.isAbandonOnDisable,	-- 10.2.7+
			headerSortKey	= info.headerSortKey,			-- 11.0.0+
			questClassification	= info.questClassification,	-- 11.0.2+
		}
	end

	-- Use: RQE.API.AbandonQuest()	instead of: C_QuestLog.AbandonQuest()
	RQE.API.AbandonQuest = function()
		return C_QuestLog.AbandonQuest()
	end

	-- Use: local canAbandon = RQE.API.CanAbandonQuest(questID)	instead of: C_QuestLog.CanAbandonQuest(questID)
	RQE.API.CanAbandonQuest = function(questID)
		return C_QuestLog.CanAbandonQuest(questID)
	end

	-- Use: local questID = RQE.API.GetAbandonQuest()	instead of: C_QuestLog.GetAbandonQuest()
	RQE.API.GetAbandonQuest = function()
		return C_QuestLog.GetAbandonQuest()
	end

	RQE.API.GetAllCompletedQuestIDs = function()
		return C_QuestLog.GetAllCompletedQuestIDs()
	end

	-- Use: local questLogIndex = RQE.API.GetLogIndexForQuestID(questID)	instead of: C_QuestLog.GetLogIndexForQuestID(questID)
	RQE.API.GetLogIndexForQuestID = function(questID)
		return C_QuestLog.GetLogIndexForQuestID(questID)
	end

	-- Use: local questID = RQE.API.GetQuestIDForLogIndex(questLogIndex)	instead of: C_QuestLog.GetQuestIDForLogIndex(questLogIndex)
	RQE.API.GetQuestIDForLogIndex = function(questLogIndex)
		return C_QuestLog.GetQuestIDForLogIndex(questLogIndex)
	end

	-- Use: local requiredMoney = RQE.API.GetRequiredMoney(questID)	instead of: C_QuestLog.GetRequiredMoney(questID)
	RQE.API.GetRequiredMoney = function(questID)
		return C_QuestLog.GetRequiredMoney(questID)
	end

	-- Use: local ready = RQE.API.ReadyForTurnIn(questID)	instead of: C_QuestLog.ReadyForTurnIn(questID)
	RQE.API.ReadyForTurnIn = function(questID)
		return C_QuestLog.ReadyForTurnIn(questID)
	end

	-- Use: local isWorldQuest = RQE.API.IsWorldQuest(questID)	instead of: C_QuestLog.IsWorldQuest(questID)
	RQE.API.IsWorldQuest = function(questID)
		return C_QuestLog.IsWorldQuest(questID)
	end

	-- Use: local wasWatched = RQE.API.AddQuestWatch(questID) instead of: C_QuestLog.AddQuestWatch(questID)
	RQE.API.AddQuestWatch = function(questID)
		return C_QuestLog.AddQuestWatch(questID)
	end

	-- Use: local wasWatched = RQE.API.AddWorldQuestWatch(questID [, watchType]) instead of: C_QuestLog.AddWorldQuestWatch(...)
	RQE.API.AddWorldQuestWatch = function(questID, watchType)
		return C_QuestLog.AddWorldQuestWatch(questID, watchType)
	end

	-- Use: local items = RQE.API.GetAbandonQuestItems() instead of: C_QuestLog.GetAbandonQuestItems()
	RQE.API.GetAbandonQuestItems = function()
		return C_QuestLog.GetAbandonQuestItems()
	end

	-- Use: local bounties = RQE.API.GetBountiesForMapID(uiMapID) instead of: C_QuestLog.GetBountiesForMapID(uiMapID)
	-- Returns a list of normalized bounty tables (BountyInfo[]):
	--	{
	--		questID				-- number	: The quest ID tied to the bounty
	--		factionID			-- number	: The faction associated with the bounty
	--		icon				-- number	: FileID for the bounty icon
	--		numObjectives		-- number	: Total number of objectives in the bounty
	--		turninRequirementText	-- string?	: Optional requirement text to complete the bounty
	--	}
	RQE.API.GetBountiesForMapID = function(uiMapID)
		local bounties = C_QuestLog.GetBountiesForMapID(uiMapID)
		if not bounties then return {} end

		local results = {}
		for _, bounty in ipairs(bounties) do
			table.insert(results, {
				questID				= bounty.questID,		-- number
				factionID			= bounty.factionID,		-- number
				icon				= bounty.icon,			-- number (fileID)
				numObjectives		= bounty.numObjectives,	-- number
				turninRequirementText = bounty.turninRequirementText, -- string?
			})
		end
		return results
	end

	-- Use: local info = RQE.API.GetBountySetInfoForMapID(uiMapID) instead of: C_QuestLog.GetBountySetInfoForMapID(uiMapID)
	-- Returns a normalized table with bounty set information:
	--	{
	--		displayLocation	-- Enum.MapOverlayDisplayLocation : Location of the overlay (Default, BottomLeft, TopLeft, BottomRight, TopRight, Hidden)
	--		lockQuestID		-- number	: The quest ID required to unlock the bounty set
	--		bountySetID		-- number	: Unique identifier for the bounty set
	--		isActivitySet	-- boolean	: True if the bounty set represents an activity set
	--	}
	RQE.API.GetBountySetInfoForMapID = function(uiMapID)
		local displayLocation, lockQuestID, bountySetID, isActivitySet = C_QuestLog.GetBountySetInfoForMapID(uiMapID)

		return {
			displayLocation = displayLocation,	-- Enum.MapOverlayDisplayLocation
			lockQuestID		= lockQuestID,		-- number
			bountySetID		= bountySetID,		-- number
			isActivitySet	= isActivitySet,	-- boolean
		}
	end

	-- Use: local info = RQE.API.GetDistanceSqToQuest(questID) instead of: C_QuestLog.GetDistanceSqToQuest(questID)
	-- Returns a normalized table with quest distance information:
	--	{
	--		distanceSq	-- number	: The squared distance to the quest from the player’s current position
	--		onContinent	-- boolean	: True if the quest is on the same continent as the player
	--	}
	RQE.API.GetDistanceSqToQuest = function(questID)
		local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
		return {
			distanceSq	= distanceSq,	-- number
			onContinent	= onContinent,	-- boolean
		}
	end

	-- Use: local numQuestWatches = RQE.API.GetNumQuestWatches() instead of: C_QuestLog.GetNumQuestWatches()
	RQE.API.GetNumQuestWatches = function()
		return C_QuestLog.GetNumQuestWatches()
	end

	-- Use: local numQuestWatches = RQE.API.GetNumWorldQuestWatches() instead of: C_QuestLog.GetNumWorldQuestWatches()
	RQE.API.GetNumWorldQuestWatches = function()
		return C_QuestLog.GetNumWorldQuestWatches()
	end

	-- Use: local info = RQE.API.GetQuestAdditionalHighlights(questID) instead of: C_QuestLog.GetQuestAdditionalHighlights(questID)
	-- Returns a normalized table with additional highlight information for a quest:
	--	{
	--		uiMapID			-- number	: The map ID the highlights apply to
	--		worldQuests		-- boolean	: True if world quests are highlighted
	--		worldQuestsElite	-- boolean	: True if elite world quests are highlighted
	--		dungeons		-- boolean	: True if dungeons are highlighted
	--		treasures		-- boolean	: True if treasures are highlighted
	--	}
	RQE.API.GetQuestAdditionalHighlights = function(questID)
		local uiMapID, worldQuests, worldQuestsElite, dungeons, treasures = C_QuestLog.GetQuestAdditionalHighlights(questID)

		return {
			uiMapID		= uiMapID,			-- number
			worldQuests	= worldQuests,		-- boolean
			worldQuestsElite = worldQuestsElite, -- boolean
			dungeons		= dungeons,		-- boolean
			treasures		= treasures,	-- boolean
		}
	end

	-- Use: local theme = RQE.API.GetQuestDetailsTheme(questID) instead of: C_QuestLog.GetQuestDetailsTheme(questID)
	-- Returns a normalized table describing the visual theme for a quest:
	--	{
	--		background	-- string : Background art for the quest
	--		seal		-- string : Seal graphic associated with the quest
	--		signature	-- string : Signature art for the quest
	--		poiIcon		-- string : POI icon art (added in 9.1+; nil in 9.0.1)
	--	}
	RQE.API.GetQuestDetailsTheme = function(questID)
		local theme = C_QuestLog.GetQuestDetailsTheme(questID)

		if not theme then
			return nil
		end

		-- In 9.0.1, poiIcon did not exist yet
		return {
			background = theme.background or nil,	-- string
			seal		= theme.seal or nil,		-- string
			signature	= theme.signature or nil,	-- string
			poiIcon	= theme.poiIcon or nil,		-- string (added in 9.1+)
		}
	end

	-- Use: local questWatchIndex = RQE.API.GetQuestIDForQuestWatchIndex(questWatchIndex) instead of: C_QuestLog.GetQuestIDForQuestWatchIndex(questWatchIndex)
	RQE.API.GetQuestIDForQuestWatchIndex = function(questWatchIndex)
		return C_QuestLog.GetQuestIDForQuestWatchIndex(questWatchIndex)
	end

	-- Use: local questWatchIndex = RQE.API.GetQuestIDForWorldQuestWatchIndex(questWatchIndex) instead of: C_QuestLog.GetQuestIDForWorldQuestWatchIndex(questWatchIndex)
	RQE.API.GetQuestIDForWorldQuestWatchIndex = function(questWatchIndex)
		return C_QuestLog.GetQuestIDForWorldQuestWatchIndex(questWatchIndex)
	end

	-- Use: local info = RQE.API.GetQuestTagInfo(questID) instead of: C_QuestLog.GetQuestTagInfo(questID)
	-- Returns a normalized table with quest tag details:
	--	{
	--		tagName			-- string	: The human-readable name of the tag
	--		tagID			-- number	: ID for the quest tag
	--		worldQuestType	-- number?	: Enum.QuestTagType value (or 0 if not set)
	--		quality			-- number?	: Enum.WorldQuestQuality value (0 = Common, 1 = Rare, 2 = Epic)
	--		tradeskillLineID	-- number?	: TradeSkillLineID if this is a profession quest
	--		isElite				-- boolean	: True if the quest is elite
	--		displayExpiration	-- boolean	: True if quest expiration should be displayed
	--	}
	RQE.API.GetQuestTagInfo = function(questID)
		local info = C_QuestLog.GetQuestTagInfo(questID)
		if not info then
			return nil
		end

		RQE.QuestTagInfo = {
			tagName		= info.tagName or "",
			tagID		= info.tagID or 0,
			worldQuestType	= info.worldQuestType or 0,
			quality			= info.quality or 0,
			tradeskillLineID	= info.tradeskillLineID or 0,
			isElite			= info.isElite or false,
			displayExpiration	= info.displayExpiration or false,
		}

		return RQE.QuestTagInfo
	end

	-- Use: local info = RQE.API.GetQuestType(questID) instead of: C_QuestLog.GetQuestType(questID)
	-- Returns a normalized table with the quest type:
	--	{
	--		questType -- number : ID representing the quest type
	--	}
	--
	--	Common QuestType IDs:
	--	1   = Group
	--	21  = Class
	--	41  = PvP
	--	62  = Raid
	--	81  = Dungeon
	--	82  = World Event
	--	83  = Legendary
	--	84  = Escort
	--	85  = Heroic
	--	88  = Raid (10)
	--	89  = Raid (25)
	--	98  = Scenario
	--	102 = Account
	--	104 = Side Quest
	--	107 = Artifact
	--	109 = World Quest
	--	110 = Epic World Quest
	--	111 = Elite World Quest
	--	112 = Epic Elite World Quest
	--	113 = PvP World Quest
	--	114 = First Aid World Quest
	--	115 = Pet Battle World Quest
	--	116 = Blacksmithing World Quest
	--	117 = Leatherworking World Quest
	--	118 = Alchemy World Quest
	--	119 = Herbalism World Quest
	--	120 = Mining World Quest
	--	121 = Tailoring World Quest
	--	122 = Engineering World Quest
	--	123 = Enchanting World Quest
	--	124 = Skinning World Quest
	--	125 = Jewelcrafting World Quest
	--	126 = Herbalism World Quest
	--	128 = Emissary World Quest
	--	129 = Archaeology World Quest
	--	130 = Fishing World Quest
	--	131 = Cooking World Quest
	--	135 = Rare World Quest
	--	136 = Rare Elite World Quest
	--	137 = Dungeon World Quest
	--	139 = Legion Invasion World Quest
	--	140 = Rated Reward (PvP)
	--	141 = Raid World Quest
	--	142 = Legion Invasion Elite World Quest
	--	143 = Legionfall Contribution
	--	144 = Legionfall World Quest
	--	145 = Legionfall Dungeon World Quest
	--	146 = Legion Invasion World Quest Wrapper
	--	147 = Warfront - Barrens
	--	148 = Pickpocketing
	--	151 = Magni World Quest - Azerite
	--	152 = Tortollan World Quest
	--	153 = Warfront Contribution
	--	254 = Island Quest
	--	255 = War Mode PvP
	--	256 = PvP Conquest
	--	259 = Faction Assault World Quest
	--	260 = Faction Assault World Elite Quest
	--	261 = Island Weekly Quest
	--	263 = Public Quest
	--	264 = Threat Quest
	--	265 = Hidden Quest
	--	266 = Combat Ally Quest
	--	267 = Professions
	--	268 = Threat Wrapper
	--	270 = Threat Emissary World Quest
	--	271 = Calling Quest
	--	272 = Venthyr Party Quest
	--	273 = Maw Soul Spawn Tracker
	--	278 = PvP Elite World Quest
	--	279 = Forbidden Reach Envoy Task
	--	281 = Dragonrider Racing
	--	282 = Important
	--	283 = Bonus Objective with Completion Toast
	--	284 = Meta Quest
	--	286 = Capstone World Quest
	--	287 = Capstone Blocker
	--	288 = Delve
	--	289 = World Boss
	--	291 = Hidden NYI
	--	292 = Important Quest (No Abandon)
	RQE.API.GetQuestType = function(questID)
		local questType = C_QuestLog.GetQuestType(questID)

		RQE.QuestTypeInfo = {
			questType = questType or 0,
		}

		return RQE.QuestTypeInfo
	end

	-- Use: local info = RQE.API.GetQuestWatchType(questID) instead of: C_QuestLog.GetQuestWatchType(questID)
	-- Returns a normalized table with the quest watch type:
	--	{
	--		watchType -- Enum.QuestWatchType (number)
	--	}
	--
	--	Enum.QuestWatchType Values:
	--	0 = Automatic
	--	1 = Manual
	RQE.API.GetQuestWatchType = function(questID)
		local watchType = C_QuestLog.GetQuestWatchType(questID)

		RQE.QuestWatchTypeInfo = {
			watchType = watchType or nil,	-- Enum.QuestWatchType (0=Automatic, 1=Manual)
		}

		return RQE.QuestWatchTypeInfo
	end

	-- Use: local info = RQE.API.GetSelectedQuest() instead of: C_QuestLog.GetSelectedQuest()
	-- Returns a normalized table with the currently selected quest:
	--	{
	--		questID -- number? (nil if no quest is selected)
	--	}
	RQE.API.GetSelectedQuest = function()
		local questID = C_QuestLog.GetSelectedQuest()

		RQE.SelectedQuestInfo = {
			questID = questID or nil,
		}

		return RQE.SelectedQuestInfo
	end

	-- Use: local info = RQE.API.GetSuggestedGroupSize(questID) instead of: C_QuestLog.GetSuggestedGroupSize(questID)
	-- Returns a normalized table with suggested group size for the quest:
	--	{
	--		questID				-- number : The quest ID queried
	--		suggestedGroupSize	-- number : Suggested number of players (0 if none, defaults to 0 if unavailable)
	--	}
	RQE.API.GetSuggestedGroupSize = function(questID)
		local suggestedGroupSize = C_QuestLog.GetSuggestedGroupSize(questID)

		RQE.SuggestedGroupInfo = {
			questID = questID,
			suggestedGroupSize = suggestedGroupSize or 0,
		}

		return RQE.SuggestedGroupInfo
	end

	-- Use: local info = RQE.API.GetTimeAllowed(questID) instead of: C_QuestLog.GetTimeAllowed(questID)
	-- Returns a normalized table with timing info for the quest:
	--	{
	--		questID		-- number : The quest ID queried
	--		totalTime	-- number : Total allowed time in seconds (0 if unavailable)
	--		elapsedTime	-- number : Time elapsed in seconds (0 if unavailable)
	--	}
	RQE.API.GetTimeAllowed = function(questID)
		local totalTime, elapsedTime = C_QuestLog.GetTimeAllowed(questID)

		RQE.QuestTimeAllowedInfo = {
			questID = questID,
			totalTime = totalTime or 0,
			elapsedTime = elapsedTime or 0,
		}

		return RQE.QuestTimeAllowedInfo
	end

	-- Use: local info = RQE.API.GetTitleForLogIndex(questLogIndex) instead of: C_QuestLog.GetTitleForLogIndex(questLogIndex)
	-- Returns a normalized table with the quest log title info:
	--	{
	--		questLogIndex	-- number  : The quest log index queried
	--		title			-- string? : Title of the quest or header (nil if unavailable)
	--	}
	RQE.API.GetTitleForLogIndex = function(questLogIndex)
		local title = C_QuestLog.GetTitleForLogIndex(questLogIndex)

		RQE.QuestTitleForLogIndexInfo = {
			questLogIndex = questLogIndex,
			title = title,
		}

		return RQE.QuestTitleForLogIndexInfo
	end

	-- Use: local info = RQE.API.IsComplete(questID) instead of: C_QuestLog.IsComplete(questID)
	-- Returns a normalized table with quest completion info:
	--	{
	--		isComplete	-- boolean : True if the quest is in the log and complete, false otherwise
	--	}
	RQE.API.IsComplete = function(questID)
		local isComplete = C_QuestLog.IsComplete(questID)

		RQE.IsCompleteInfo = {
			isComplete = isComplete,
		}

		return RQE.IsCompleteInfo
	end

	-- Use: local info = RQE.API.IsFailed(questID) instead of: C_QuestLog.IsFailed(questID)
	-- Returns a normalized table with quest failure info:
	--	{
	--		isFailed	-- boolean : True if the quest is in the log and has failed, false otherwise
	--	}
	RQE.API.IsFailed = function(questID)
		local isFailed = C_QuestLog.IsFailed(questID)

		RQE.IsFailedInfo = {
			isFailed = isFailed,
		}

		return RQE.IsFailedInfo
	end

	-- Use: local info = RQE.API.IsRepeatableQuest(questID) instead of: C_QuestLog.IsRepeatableQuest(questID)
	-- Returns a normalized table with repeatable quest info:
	--	{
	--		isRepeatable	-- boolean : True if the quest is repeatable, false otherwise
	--	}
	RQE.API.IsRepeatableQuest = function(questID)
		local isRepeatable = C_QuestLog.IsRepeatableQuest(questID)

		RQE.IsRepeatableQuestInfo = {
			isRepeatable = isRepeatable,
		}

		return RQE.IsRepeatableQuestInfo
	end

elseif major > 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major >= 2) then
	-- Retail 8.2.5+ and Classic 1.14+ → C_QuestLog.IsQuestFlaggedCompleted
	-- Use: local completed = RQE.API.IsQuestFlaggedCompleted(questID)	instead of: C_QuestLog.IsQuestFlaggedCompleted(questID)
	RQE.API.IsQuestFlaggedCompleted = function(questID)
		return C_QuestLog.IsQuestFlaggedCompleted(questID)
	end

elseif major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major >= 1 and minor >= 15) then
	-- Retail 8.0.1+ and Classic 1.15+
	-- Use: local quests = RQE.API.GetQuestsOnMap(uiMapID) instead of: C_QuestLog.GetQuestsOnMap(uiMapID)
	-- Returns a normalized table (array) of quests on the given map:
	--	{
	--		{
	--			childDepth		-- number?	: Depth of nested quest entries
	--			questTagType	-- number?	: Enum.QuestTagType
	--			questID			-- number	: The quest’s unique ID
	--			numObjectives	-- number	: Number of objectives for the quest
	--			mapID			-- number	: The UiMapID the quest belongs to
	--			x				-- number	: X coordinate on the map
	--			y				-- number	: Y coordinate on the map
	--			isQuestStart	-- boolean	: Whether this quest starts at this location
	--			isDaily			-- boolean	: Whether the quest is daily
	--			isCombatAllyQuest	-- boolean	: Whether the quest is a combat ally quest
	--			isMeta				-- boolean	: Whether the quest is a meta quest
	--			inProgress			-- boolean	: Whether the quest is currently in progress
	--			isMapIndicatorQuest	-- boolean	: Whether the quest is shown as a map indicator
	--		},
	--	}
	RQE.API.GetQuestsOnMap = function(uiMapID)
		local quests = C_QuestLog.GetQuestsOnMap(uiMapID) or {}
		RQE.QuestsOnMap = {}

		for i, quest in ipairs(quests) do
			local entry = {
				childDepth	= quest.childDepth or 0,
				questTagType	= quest.questTagType or 0,
				questID			= quest.questID or 0,
				numObjectives	= quest.numObjectives or 0,
				mapID			= quest.mapID or uiMapID or 0,
				x				= quest.x or 0,
				y				= quest.y or 0,
				isQuestStart	= quest.isQuestStart or false,
				isDaily			= quest.isDaily or false,
				isCombatAllyQuest	= quest.isCombatAllyQuest or false,
				isMeta			= quest.isMeta or false,
				inProgress		= quest.inProgress or false,
				isMapIndicatorQuest = quest.isMapIndicatorQuest or false,
			}
			table.insert(RQE.QuestsOnMap, entry)
		end

		return RQE.QuestsOnMap
	end

elseif major > 8 or (major == 8 and minor >= 3) then
	-- Use: local maps = RQE.API.GetActiveThreatMaps() instead of: C_QuestLog.GetActiveThreatMaps()
	RQE.API.GetActiveThreatMaps = function()
		return C_QuestLog.GetActiveThreatMaps()
	end

	-- Use: local info = RQE.API.HasActiveThreats() instead of: C_QuestLog.HasActiveThreats()
	-- Returns a normalized table:
	--	{
	--		hasActiveThreats	-- boolean : Whether there are currently any active invasion/threat events
	--	}
	--	Notes:
	--		• Added in Retail 8.3 (Visions of N'Zoth).
	--		• Not available in Classic projects or older client versions.
	RQE.API.HasActiveThreats = function()
		local hasActiveThreats = C_QuestLog.HasActiveThreats()

		RQE.HasActiveThreatsInfo = {
			hasActiveThreats = hasActiveThreats,
		}

		return RQE.HasActiveThreatsInfo
	end

elseif (major > 8 and minor >= 2 and patch >= 5) then
	-- Use: local completed = RQE.API.GetQuestDifficultyLevel(questID)	instead of: C_QuestLog.GetQuestDifficultyLevel(questID)
	RQE.API.GetQuestDifficultyLevel = function(questID)
		return C_QuestLog.GetQuestDifficultyLevel(questID)
	end

	-- Use: local info = RQE.API.IsQuestTrivial(questID) instead of: C_QuestLog.IsQuestTrivial(questID)
	-- Returns a normalized table:
	--	{
	--		isTrivial	-- boolean : Whether the quest is considered trivial (low-level / gray)
	--	}
	--	Arguments:
	--		questID	-- number : The unique ID of the quest
	--	Notes:
	--		• Added in Retail 8.2.5 (Rise of Azshara).
	--		• Not available in Classic projects or earlier client versions.
	RQE.API.IsQuestTrivial = function(questID)
		local isTrivial = C_QuestLog.IsQuestTrivial(questID)

		RQE.IsQuestTrivialInfo = {
			isTrivial = isTrivial,
		}

		return RQE.IsQuestTrivialInfo
	end

elseif major > 8 or (major == 8 and minor >= 2) then
	-- Retail 8.2+ (BfA Rise of Azshara and onward)
	-- Use: local text = RQE.API.GetNextWaypointText(questID)	instead of: C_QuestLog.GetNextWaypointText(questID)
	RQE.API.GetNextWaypointText = function(questID)
		local waypointText = C_QuestLog.GetNextWaypointText(questID)
		return waypointText or nil -- string or nil
	end

	-- Use: local mapID, x, y = RQE.API.GetNextWaypoint(questID) instead of: C_QuestLog.GetNextWaypoint(questID)
	RQE.API.GetNextWaypoint = function(questID)
		return C_QuestLog.GetNextWaypoint(questID)
	end

elseif major > 8 or (major == 8 and minor >= 1) then
	-- Retail 8.1+
	-- Use: local numObjectives = RQE.API.GetNumQuestObjectives(questID)	instead of: C_QuestLog.GetNumQuestObjectives(questID)
	-- Returns: number (leaderboardCount)
	RQE.API.GetNumQuestObjectives = function(questID)
		return C_QuestLog.GetNumQuestObjectives(questID)
	end

elseif major >= 8 then
	-- BfA Patch 8.2.5 (2019-09-24) → Shadowlands prepatch
	-- Used AddQuestWatchForQuestID
	-- Use: local wasWatched = RQE.API.AddQuestWatch(questID)
	RQE.API.AddQuestWatch = function(questID)
		return AddQuestWatchForQuestID(questID)
	end

	-- Use: local info = RQE.API.GetBountySetInfoForMapID(uiMapID) instead of: C_Map.GetBountySetIDForMap(uiMapID)
	-- Returns a normalized table:
	--	{
	--		displayLocation	-- number : Always 0 ("Default"), since C_Map.GetBountySetIDForMap does not provide this
	--		lockQuestID		-- number? : Always nil, not provided by this API
	--		bountySetID		-- number : The bounty set ID for the given map
	--		isActivitySet	-- boolean : Always false, not provided by this API
	--	}
	--	Arguments:
	--		uiMapID	-- number : The map ID to query
	--	Notes:
	--		• Available in Retail 8.0.1 → 8.1.0 (Battle for Azeroth) as C_Map.GetBountySetIDForMap.
	--		• Replaced by C_QuestLog.GetBountySetInfoForMapID in 8.1.0 onward.
	--		• Not available in Classic or earlier versions.
	RQE.API.GetBountySetInfoForMapID = function(uiMapID)
		local bountySetID = C_Map.GetBountySetIDForMap(uiMapID)
		RQE.BountySetInfo = {
			displayLocation = 0,	-- Default
			lockQuestID = nil,		-- Not provided
			bountySetID = bountySetID,
			isActivitySet	= false,	-- Not provided
		}
		return RQE.BountySetInfo
	end

	-- Use: local info = RQE.API.GetZoneStoryInfo(uiMapID) instead of: C_QuestLog.GetZoneStoryInfo(uiMapID)
	-- Returns a normalized table:
	--	{
	--		uiMapID			-- number : The map ID passed to the API
	--		achievementID	-- number : The achievement ID tied to the story progression for this zone
	--		storyMapID		-- number : The map ID representing the story for this zone
	--	}
	--	Arguments:
	--		uiMapID		-- number : The UiMapID of the zone to query
	RQE.API.GetZoneStoryInfo = function(uiMapID)
		local achievementID, storyMapID = C_QuestLog.GetZoneStoryInfo(uiMapID)

		RQE.ZoneStoryInfo = {
			uiMapID = uiMapID,
			achievementID = achievementID,
			storyMapID = storyMapID,
		}

		return RQE.ZoneStoryInfo
	end

elseif major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and minor >= 15) then
	-- Use: local uiMapID = RQE.API.GetMapForQuestPOIs() instead of: C_QuestLog.GetMapForQuestPOIs()
	RQE.API.GetMapForQuestPOIs = function()
		return C_QuestLog.GetMapForQuestPOIs()
	end

elseif major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- BfA 8.x and all Classic re-releases (but not Vanilla)
	RQE.API.GetTitleForQuestID = function(questID)
		return C_QuestLog.GetQuestInfo(questID)
	end

	-- Use: local isOnQuest = RQE.API.IsOnQuest(questID)	instead of: C_QuestLog.IsOnQuest(questID)
	RQE.API.IsOnQuest = function(questID)
		return C_QuestLog.IsOnQuest(questID)
	end

	-- Use: local max = RQE.API.GetMaxNumQuests() instead of: C_QuestLog.GetMaxNumQuests()
	RQE.API.GetMaxNumQuests = function()
		return C_QuestLog.GetMaxNumQuests()
	end

	-- Use: local max = RQE.API.GetMaxNumQuestsCanAccept() instead of: C_QuestLog.GetMaxNumQuestsCanAccept()
	RQE.API.GetMaxNumQuestsCanAccept = function()
		return C_QuestLog.GetMaxNumQuestsCanAccept()
	end

elseif major >= 7 then
	-- Introduced World Quests, but no C_QuestLog version yet
	-- Use: local wasWatched = RQE.API.AddWorldQuestWatch(questID [, watchType]) instead of: C_QuestLog.AddWorldQuestWatch(...)
	RQE.API.AddWorldQuestWatch = function(questID)
		return AddWorldQuestWatch(questID)
	end

	-- Use: local info = RQE.API.GetBountySetInfoForMapID(uiMapID) instead of: GetQuestBountyInfoForMapID(uiMapID)
	-- Returns a normalized table:
	--	{
	--		displayLocation	-- number : Enum.MapOverlayDisplayLocation (0=Default, 1=BottomLeft, 2=TopLeft, 3=BottomRight, 4=TopRight, 5=Hidden)
	--		lockQuestID		-- number : Quest ID that locks this bounty set
	--		bountySetID		-- number : Identifier for the bounty set
	--		isActivitySet	-- boolean : Whether this bounty set is tied to an activity (coerced to false on older builds)
	--	}
	--	Arguments:
	--		uiMapID -- number : UiMapID to query
	--	Notes:
	--		• API available in Retail 7.0.3 (Legion launch).
	--		• Returns bounty set information for the specified map.
	--		• On older builds, isActivitySet may not be returned — wrapper normalizes it to boolean.
	RQE.API.GetBountySetInfoForMapID = function(uiMapID)
		local displayLocation, lockQuestID, bountySetID, isActivitySet = GetQuestBountyInfoForMapID(uiMapID)
		RQE.BountySetInfo = {
			displayLocation = displayLocation or 0,
			lockQuestID	= lockQuestID,
			bountySetID	= bountySetID,
			isActivitySet	= isActivitySet == true,	-- older builds may not return this; coerce to boolean
		}
		return RQE.BountySetInfo
	end

	-- Legion & BfA (7.0.3 → 8.x pre-9)
	-- Use: local info = RQE.API.GetDistanceSqToQuest(questID) instead of: C_TaskQuest.GetDistanceSqToQuest(questID)
	-- Returns a normalized table:
	--	{
	--		distanceSq	-- number : Squared distance from the player to the quest location
	--		onContinent	-- boolean : True if the quest is on the same continent as the player
	--	}
	--	Arguments:
	--		questID -- number : Unique identifier of the quest to check
	--	Notes:
	--		• API available in Retail 7.0.3 (Legion) through 8.x via C_TaskQuest.GetDistanceSqToQuest.
	--		• From 9.0.1 onward, replaced by C_QuestLog.GetDistanceSqToQuest.
	--		• Wrapper returns nil if the API is not available in the current client.
	RQE.API.GetDistanceSqToQuest = function(questID)
		if C_TaskQuest and C_TaskQuest.GetDistanceSqToQuest then
			local distanceSq, onContinent = C_TaskQuest.GetDistanceSqToQuest(questID)
			return {
				distanceSq	= distanceSq,
				onContinent	= onContinent,
			}
		end
		return nil
	end

	-- Legion through BFA (World Quests existed but not namespaced yet)
	RQE.API.GetNumWorldQuestWatches = function()
		return GetNumWorldQuestWatches()
	end

elseif major >= 6 then
	-- Retail (6.0.2+) → GetQuestObjectiveInfo
	-- Use: local info = RQE.API.GetQuestObjectiveInfo(questID, objectiveIndex, displayProgressText) instead of: GetQuestObjectiveInfo(questID, objectiveIndex, displayProgressText)
	-- Returns a normalized table:
	--	{
	--		questID			-- number	: The unique quest identifier
	--		objectiveIndex	-- number	: The index of the objective within the quest
	--		text			-- string	: Description of the objective (e.g. "0/3 Monsters slain")
	--		objectiveType	-- string	: Type of objective ("item", "object", "monster", "reputation", "log", "event", "player", "progressbar", or "unknown")
	--		finished		-- boolean	: True if the objective is completed
	--		fulfilled		-- number	: Amount of progress completed toward the objective
	--		required		-- number	: Total amount required to complete the objective
	--	}
	--	Arguments:
	--		questID				-- number : Unique identifier of the quest
	--		objectiveIndex		-- number : The objective’s index in the quest
	--		displayProgressText	-- boolean : If true, progress text is displayed
	--	Notes:
	--		• API has existed since Vanilla (1.0.0) and remains valid in all versions, including Classic projects.
	--		• Useful for tracking objective details such as kill counts, collection counts, or progress bars.
	RQE.API.GetQuestObjectiveInfo = function(questID, objectiveIndex, displayProgressText)
		local text, objectiveType, finished, fulfilled, required = GetQuestObjectiveInfo(questID, objectiveIndex, displayProgressText)
		RQE.QuestObjectiveInfo = {
			questID		= questID,
			objectiveIndex	= objectiveIndex,
			text		= text or "",
			objectiveType	= objectiveType or "unknown",
			finished		= finished == true,
			fulfilled		= fulfilled or 0,
			required		= required or 0,
		}
		return RQE.QuestObjectiveInfo
	end

elseif major >= 6 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major >= 1 and minor >= 13) then
	-- Warlords+ (6.0) to pre-9.0, Classic 1.13+
	-- Use: local info = RQE.API.GetQuestTagInfo(questID) instead of: GetQuestTagInfo(questID)
	-- Returns a normalized table:
	--	{
	--		tagName			-- string	: Human-readable representation of the tag (e.g. "Group", "Dungeon")
	--		tagID			-- number	: Identifier of the quest tag, or 0 if none
	--		worldQuestType		-- number	: Type of world quest (LE_QUEST_TAG_TYPE_*), or 0 if not a world quest
	--		quality				-- number	: Rarity of the quest (LE_WORLD_QUEST_QUALITY_*), or 0 if none
	--		tradeskillLineID	-- number	: TradeSkillLineID if this is a profession quest, 0 otherwise
	--		isElite				-- boolean	: True if this quest is elite
	--		displayExpiration	-- boolean	: True if quest tag info includes an expiration timer
	--	}
	--	Arguments:
	--		questID		-- number : Unique identifier of the quest
	--	Notes:
	--		• Available from WoW version 6.0.0 up to before 9.0.1, and in all Classic project versions (1.13+).
	--		• In 9.0.1+, this API was replaced by C_QuestLog.GetQuestTagInfo with a structured return table.
	RQE.API.GetQuestTagInfo = function(questID)
		local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(questID)

		RQE.QuestTagInfo = {
			tagName			= tagName or "",
			tagID			= tagID or 0,
			worldQuestType	= worldQuestType or 0,
			quality			= rarity or 0,
			tradeskillLineID	= tradeskillLineIndex or 0,
			isElite			= isElite or false,
			displayExpiration	= displayTimeLeft or false,
		}

		return RQE.QuestTagInfo
	end

	-- Retail 6.x – 8.x and Classic (1.13+)
	-- Use: local info = RQE.API.IsComplete(questID) instead of: IsQuestComplete(questID)
	-- Returns a normalized table:
	--	{
	--		isComplete -- boolean : True if the quest is both in the player's log and marked complete
	--	}
	--	Arguments:
	--		questID -- number : Unique identifier of the quest
	--	Notes:
	--		• Available from WoW version 6.0.0 up to before 9.0.1, and in all Classic project versions (1.13+).
	--		• Will only return true if the quest is in the player’s log and marked complete.
	--		• If the quest was already turned in, this returns false.
	--		• May return true even when GetQuestLogTitle’s "isComplete" return is false, for quests without objectives.
	RQE.API.IsComplete = function(questID)
		local isComplete = IsQuestComplete(questID)

		RQE.IsCompleteInfo = {
			isComplete = isComplete,
		}

		return RQE.IsCompleteInfo
	end

elseif major >= 5 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major == 1) then
	-- Retail 5.0 → 8.2.0 and Classic 1.13.x → IsQuestFlaggedCompleted
	RQE.API.IsQuestFlaggedCompleted = function(questID)
		return IsQuestFlaggedCompleted(questID)
	end

elseif major >= 5 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Classic & Vanilla (1.0.0+), Burning Crusade (2.x), Wrath (3.x), Cata/MoP/WoD/Legion/BFA (up to 8.x)
	-- Use: CanAbandonQuest(questID)
	RQE.API.CanAbandonQuest = function(questID)
		return CanAbandonQuest(questID) or false
	end

elseif major >= 4 then
	-- Cataclysm → MoP (4.x → 6.x)
	-- Use: local info = RQE.API.GetDistanceSqToQuest(questID) instead of: GetDistanceSqToQuest(questID)
	-- Returns a normalized table:
	--	{
	--		distanceSq	-- number  : Squared distance from the player to the quest objective
	--		onContinent	-- boolean : True if the player is on the same continent as the quest objective
	--	}
	--	Arguments:
	--		questID	-- number : The unique quest ID to query
	--	Notes:
	--		• Available from WoW version 4.0.0 up until before 7.0.0.
	--		• Not available in original Vanilla WoW or in Classic projects.
	--		• Returns nil if the API does not exist in the client.
	RQE.API.GetDistanceSqToQuest = function(questID)
		if GetDistanceSqToQuest then
			local distanceSq, onContinent = GetDistanceSqToQuest(questID)
			return {
				distanceSq	= distanceSq,
				onContinent	= onContinent,
			}
		end
		return nil
	end

elseif major >= 4 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Cataclysm 4.0.1+ and Classic Projects (1.13 / 1.14)
	-- Uses the older API GetQuestLogIndexByID
	RQE.API.GetLogIndexForQuestID = function(questID)
		return GetQuestLogIndexByID(questID)
	end

	-- Wrath/Cata+ and Classic projects
	-- Use: local info = RQE.API.GetQuestLogPortraitGiver(questLogIndex) instead of: GetQuestLogPortraitGiver(questLogIndex)
	-- Returns a normalized table:
	--	{
	--		portraitGiver		-- number	: Creature ID or display identifier for the portrait giver
	--		portraitGiverText	-- string	: Description text shown in the quest log
	--		portraitGiverName	-- string	: Name of the NPC or entity associated with the portrait
	--		portraitGiverMount	-- number	: Mount display ID (if any)
	--		portraitGiverModelSceneID -- number? : Optional model scene ID (may be nil on older versions)
	--	}
	--	Arguments:
	--		questLogIndex -- number? : Index of the quest in the quest log (if omitted, defaults to the currently selected quest)
	--	Notes:
	--		• This function existed from WoW version 4.0.0 through 9.0.5 and in all Classic project versions.
	--		• In version 9.1.0 and later (Retail only), replaced by C_QuestLog.GetQuestLogPortraitGiver.
	RQE.API.GetQuestLogPortraitGiver = function(questLogIndex)
		local portraitGiver, portraitGiverText, portraitGiverName, portraitGiverMount, portraitGiverModelSceneID = GetQuestLogPortraitGiver(questLogIndex)

		return {
			portraitGiver		= portraitGiver,		-- number
			portraitGiverText	= portraitGiverText,	-- string
			portraitGiverName	= portraitGiverName,	-- string
			portraitGiverMount	= portraitGiverMount,	-- number
			portraitGiverModelSceneID = portraitGiverModelSceneID, -- number?
		}
	end

elseif major >= 3 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Wrath 3.3.0+ and Classic Projects (1.13 / 1.14)
	-- Uses GetQuestsCompleted(), which returns a dictionary of questID=true
	-- Convert to array to match retail style
	RQE.API.GetAllCompletedQuestIDs = function()
		local completed = {}
		local dict = GetQuestsCompleted() or {}
		for questID in pairs(dict) do
			table.insert(completed, questID)
		end
		table.sort(completed)	-- mimic retail behavior
		return completed
	end

elseif (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) or major < 9 then
	-- Classic re-releases (1.13+) and Retail pre-9  → GetQuestLogTitle(index)
	-- Use: local completed = RQE.API.GetAllCompletedQuestIDs() instead of: GetQuestsCompleted()
	-- Returns a normalized array of completed quest IDs (sorted ascending to mimic Retail behavior).
	--	Arguments:
	--		none
	--	Returns:
	--		completed -- number[] : Array of quest IDs that the player has completed.
	--	Notes:
	--		• Available since Wrath of the Lich King Patch 3.3.0 (2009-12-08) as GetQuestsCompleted().
	--		• In Shadowlands Patch 9.0.1 (2020-10-13), this was replaced by C_QuestLog.GetAllCompletedQuestIDs(), which directly returns a sequential array instead of a keyed dictionary.
	--		• This wrapper normalizes the Classic/Wrath behavior (dictionary keyed by questID = true) into Retail-style behavior (sorted array of questIDs).
	--		• A quest appears in this list only after being completed and turned in, not while it is still in the log.
	RQE.API.GetQuestLogInfo = function(questLogIndex)
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questLogIndex)

		return {
			title			= title,			-- string
			questLogIndex	= questLogIndex,	-- number
			questID			= questID,			-- number
			level			= level,			-- number
			suggestedGroup	= suggestedGroup,	-- number
			frequency		= frequency,		-- number (1=normal, 2=daily, 3=weekly)
			isHeader		= isHeader,			-- boolean
			isCollapsed		= isCollapsed,		-- boolean
			isComplete		= isComplete,		-- number (1=complete, -1=failed, nil otherwise)
			startEvent		= startEvent,		-- boolean
			displayQuestID	= displayQuestID,	-- boolean
			isOnMap			= isOnMap,		-- boolean
			hasLocalPOI		= hasLocalPOI,	-- boolean
			isTask		= isTask,		-- boolean
			isBounty	= isBounty,		-- boolean
			isStory		= isStory,		-- boolean
			isHidden	= isHidden,		-- boolean
			isScaling	= isScaling,	-- boolean
		}
	end

elseif major >= 2 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Classic projects (1.13, 2.5, 3.4, 1.14, etc.) and TBC+ Retail
	-- Only supported the old index-based AddQuestWatch
	-- Use: RQE.API.AddQuestWatch(questIndex)
	RQE.API.AddQuestWatch = function(questIndex)
		return AddQuestWatch(questIndex)
	end

	-- Burning Crusade (2.0.0) → BfA (pre-9) and Classic projects ≥1.14
	-- Use: local info = RQE.API.GetSuggestedGroupSize(questID) instead of: GetQuestLogGroupNum(questID)
	-- Returns a normalized table containing the questID and the suggested group size.
	--	Arguments:
	--		questID -- number : The unique ID of the quest.
	--	Returns:
	--	{
	--		questID				-- number	: The provided questID
	--		suggestedGroupSize	-- number	: The number of players suggested for this quest (0 if solo or undefined)
	--	}
	--	Notes:
	--		• Available since Patch 2.0.1 (2007-12-05) as GetQuestLogGroupNum().
	--		• Works in all Classic projects since 1.14 as well.
	--		• In Retail from Shadowlands Patch 9.0.1 onward, this API was replaced by C_QuestLog.GetSuggestedGroupSize(questID).
	--		• This wrapper normalizes both behaviors into a structured return table.
	RQE.API.GetSuggestedGroupSize = function(questID)
		local suggestedGroup = GetQuestLogGroupNum(questID)

		RQE.SuggestedGroupSizeInfo = {
			questID = questID,
			suggestedGroupSize = suggestedGroup or 0,
		}

		return RQE.SuggestedGroupSizeInfo
	end

elseif major >= 1 and ((WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) or major < 9) then
	-- Wrath (3.3) through BFA, and Classic re-releases
	RQE.API.GetNumQuestWatches = function()
		return GetNumQuestWatches()
	end

elseif major >= 1 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Classic & Vanilla (1.x, 2.x, … up through BfA)
	-- Use: AbandonQuest()
	RQE.API.AbandonQuest = function()
		return AbandonQuest()
	end

	-- Vanilla 1.0.0 → BfA (pre-9) and Classic projects ≥1.13
	-- Use: local info = RQE.API.GetTimeAllowed(questID) instead of: GetQuestTimers()
	-- Returns a normalized table containing quest timer information.
	--	Arguments:
	--		questID -- number : The unique ID of the quest (ignored in Classic/older versions).
	--	Returns:
	--	{
	--		questID		-- number : The provided questID
	--		totalTime	-- number : The total time allowed for the first active timed quest (seconds). 0 if none.
	--		elapsedTime	-- number : Always 0 (GetQuestTimers() does not return elapsed time).
	--	}
	--	Notes:
	--		• GetQuestTimers() has existed since Vanilla (1.0.0).
	--		• It only returns a list of time values (in seconds) for active timed quests, without linking them to questIDs.
	--		• In Classic or older clients, we assume the first timer in the list applies.
	--		• Starting in Retail Patch 9.0.1, the API was replaced with C_QuestLog.GetTimeAllowed(questID), which provides both totalTime and elapsedTime explicitly tied to a questID.
	--		• This wrapper normalizes the Classic behavior into a table for consistency.
	RQE.API.GetTimeAllowed = function(questID)
		local timers = GetQuestTimers() or {}
		local totalTime = timers[1] or 0 -- pick the first timer, since no questID mapping
		local elapsedTime = 0 -- no way to track elapsed via GetQuestTimers

		RQE.QuestTimeAllowedInfo = {
			questID		= questID,
			totalTime	= totalTime,
			elapsedTime	= elapsedTime,
		}

		return RQE.QuestTimeAllowedInfo
	end

elseif WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	-- Classic (1.13.x, 1.14.x) → GetQuestLogLeaderBoard
	-- Use: local info = RQE.API.GetQuestObjectiveInfo(questID, objectiveIndex, false) instead of: GetQuestLogLeaderBoard(objectiveIndex, questLogIndex)
	-- Returns a normalized table with information about a quest objective.
	--	Arguments:
	--		questID			-- number : Unique quest identifier.
	--		objectiveIndex	-- number : The index of the objective to query (1..GetNumQuestLeaderBoards).
	--	_					-- ignored (Classic API does not support displayProgressText).
	--	Returns:
	--	{
	--		questID			-- number : The quest ID
	--		objectiveIndex	-- number : The queried objective index
	--		text			-- string : Text description of the objective (e.g. "0/3 Monsters slain")
	--		objectiveType	-- string : A token describing the type ("item", "monster", "reputation", etc.)
	--		finished		-- boolean: true if completed, false otherwise
	--		fulfilled		-- nil	: Not available pre-6 (Retail 6.0+ adds fulfilled count)
	--		required		-- nil	: Not available pre-6 (Retail 6.0+ adds required count)
	--	}
	--	Notes:
	--		• GetQuestLogLeaderBoard existed since Vanilla (1.0.0) and was used up through WoD (5.x).
	--		• It works with quest log indexes, not questIDs directly, so GetQuestLogIndexByID is used if available.
	--		• Retail 6.0+ introduced GetQuestObjectiveInfo(questID, objectiveIndex, displayComplete), which added fulfilled/required counts and switched to questID-based lookups.
	--		• This wrapper normalizes Classic/older results into a consistent table format.
	RQE.API.GetQuestObjectiveInfo = function(questID, objectiveIndex, _)
		-- In classic, objectives are tied to questLogIndex, not questID directly.
		local questLogIndex = GetQuestLogIndexByID and GetQuestLogIndexByID(questID) or nil
		if not questLogIndex then return nil end
		local description, objectiveType, isCompleted = GetQuestLogLeaderBoard(objectiveIndex, questLogIndex)
		RQE.QuestObjectiveInfo = {
			questID		= questID,
			objectiveIndex	= objectiveIndex,
			text		= description or "",
			objectiveType	= objectiveType or "unknown",
			finished		= isCompleted == true,
			fulfilled		= nil,	-- not provided pre-6
			required		= nil,	-- not provided pre-6
		}
		return RQE.QuestObjectiveInfo
	end

	-- Returns questName (string)
	-- Use: local questName = RQE.API.GetAbandonQuest()
	RQE.API.GetAbandonQuest = function()
		return GetAbandonQuestName()
	end

else

	-- Use: local numObjectives = RQE.API.GetNumQuestObjectives(questID) instead of: C_QuestLog.GetNumQuestObjectives(questID)
	-- Returns: number (leaderboardCount)
	RQE.API.GetNumQuestObjectives = function(questID)
		return GetNumQuestLeaderBoards and GetNumQuestLeaderBoards(questID) or 0
	end

	-- Not available in Vanilla
	RQE.API.GetTitleForQuestID = function(questID)
		return nil
	end

	-- Not available in Classic or Vanilla
	RQE.API.GetNextWaypointText = function(questID)
		return nil
	end

	-- Fallback
	RQE.API.GetQuestLogInfo = function(_) return nil end

	-- Original Vanilla (pre-2.0) → not available
	RQE.API.IsQuestFlaggedCompleted = function(_)
		return false
	end

	-- Original Vanilla (pre-1.13, no questID API available)
	RQE.API.GetQuestObjectiveInfo = function(_, _, _)
		return nil, nil, nil, nil, nil
	end

	-- Use: local info = RQE.API.GetQuestLogRewardInfo(index, questID) instead of: GetQuestLogRewardInfo(index, questID)
	-- Returns a normalized table with information about a quest reward item.
	--	Arguments:
	--		index	-- number : The reward index (1..GetNumQuestLogRewards).
	--		questID	-- number : The unique quest identifier.
	--	Returns:
	--	{
	--		index		-- number : The reward index passed in
	--		questID		-- number : The quest ID queried
	--		itemName	-- string : Name of the reward item
	--		itemTexture	-- string : Texture (icon) of the item
	--		numItems	-- number : How many of this item are rewarded
	--		quality		-- number : Item quality (0 = poor, 1 = common, etc.)
	--		isUsable	-- boolean: Whether the item can be used by the current player
	--		itemID		-- number : Unique identifier for the item
	--		itemLevel	-- number : Item level, scaled for character if applicable
	--	}
	--	Notes:
	--		• GetQuestLogRewardInfo has existed since Vanilla (1.0.0) and still exists today.
	--		• Older client versions did not always return all fields (e.g. itemID/itemLevel were added later).
	--		• This wrapper normalizes the return values into a consistent table for both Classic and Retail.
	RQE.API.GetQuestLogRewardInfo = function(index, questID)
		-- Exists since Vanilla (1.0.0) and still valid
		local itemName, itemTexture, numItems, quality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(index, questID)

		RQE.QuestLogRewardInfo = {
			index	= index,
			questID	= questID,
			itemName	= itemName or "",
			itemTexture	= itemTexture or "",
			numItems	= numItems or 0,
			quality		= quality or 0,
			isUsable	= isUsable == true,
			itemID		= itemID or 0,
			itemLevel	= itemLevel or 0,
		}

		return RQE.QuestLogRewardInfo
	end

	-- Use: local info = RQE.API.GetQuestRewardSpellInfo(rewardIndex, questID) instead of: GetQuestLogRewardSpell(rewardIndex, questID)
	-- Returns a normalized table with information about a spell reward from a quest.
	--	Arguments:
	--		rewardIndex	-- number : Index of the spell reward (1..GetNumRewardSpells).
	--		questID		-- number : Unique quest identifier.
	--	Returns:
	--	{
	--		texture		-- string	: Icon texture path of the spell reward
	--		name		-- string	: Name of the spell reward
	--		isTradeskill		-- boolean	: Whether this is a tradeskill spell
	--		isSpellLearned		-- boolean	: Whether the player has already learned this spell
	--		hideSpellLearnText	-- boolean	: Flag to hide spell learn text
	--		isBoostSpell	-- boolean	: Whether this spell is a boost-type reward
	--		garrFollowerID	-- number	: If the spell grants a Garrison follower, this is its ID
	--		genericUnlock	-- boolean	: Whether this reward represents a generic unlock
	--		type			-- Enum.QuestCompleteSpellType : Always LegacyBehavior (0) in this context
	--		spellID			-- number	: Spell identifier (may be nil in older versions)
	--	}
	--	Notes:
	--		• GetQuestLogRewardSpell has existed since Vanilla and is used in Classic (1.13.x) and Retail before 10.1.
	--		• Retail 10.1+ introduced C_QuestInfoSystem.GetQuestRewardSpellInfo, which provides richer data.
	--		• This wrapper normalizes old return values into a structure similar to the modern QuestRewardSpellInfo.
	RQE.API.GetQuestRewardSpellInfo = function(rewardIndex, questID)
		local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID, genericUnlock, spellID = GetQuestLogRewardSpell(rewardIndex, questID)

		-- Normalize into something similar to QuestRewardSpellInfo
		return {
			texture	= texture,
			name	= name,
			isTradeskill	= isTradeskillSpell,
			isSpellLearned	= isSpellLearned,
			hideSpellLearnText	= hideSpellLearnText,
			isBoostSpell		= isBoostSpell,
			garrFollowerID		= garrFollowerID,
			genericUnlock	= genericUnlock,
			type	= Enum and Enum.QuestCompleteSpellType and Enum.QuestCompleteSpellType.LegacyBehavior or 0,
			spellID = spellID,
		}
	end

	-- No support in pre-1.0 (failsafe)
	RQE.API.AbandonQuest = function() return nil end

	-- No support pre-5.0 (failsafe)
	RQE.API.CanAbandonQuest = function(questID) return false end

	-- Failsafe
	RQE.API.GetAbandonQuest = function() return nil end

	-- Original Vanilla (< 3.3.0) – not available
	RQE.API.GetAllCompletedQuestIDs = function() return {} end

	-- Original Vanilla (< 4.0.1) – no API existed
	RQE.API.GetLogIndexForQuestID = function(questID) return nil end

	-- Classic Projects and Vanilla: API not available
	RQE.API.GetQuestIDForLogIndex = function(questLogIndex) return nil end

	-- Classic Projects and Vanilla: API not available
	-- Always returns 0 (quests in these versions didn’t use this API)
	RQE.API.GetRequiredMoney = function(questID) return 0 end

	-- Classic Projects & Vanilla: API not available
	-- Always return false (quests didn’t expose this API)
	RQE.API.ReadyForTurnIn = function(questID) return false end

	-- Vanilla (1.x): API did not exist - Always return false
	RQE.API.IsOnQuest = function(questID) return false end

	-- Classic projects & Vanilla (no world quest support)
	RQE.API.IsWorldQuest = function(questID) return false end

	-- Vanilla 1.0 → before 1.3 had no AddQuestWatch
	RQE.API.AddQuestWatch = function(questIndex) return false end

	-- Pre-Legion (Classic, BC, Wrath, Cata, MoP, WoD, Vanilla)
	-- World Quests did not exist
	RQE.API.AddWorldQuestWatch = function(questID, watchType) return false end

	-- Pre-10.0 (Shadowlands, BfA, Legion, WoD, MoP, etc., and Classic/Vanilla)
	-- No equivalent function existed
	RQE.API.DoesQuestAwardReputationWithFaction = function(questID, factionID) return false end

	-- Pre-9.0 (BfA, Legion, WoD, MoP, etc., and Classic/Vanilla)
	-- No equivalent API existed
	RQE.API.GetAbandonQuestItems = function() return {} end

	-- Pre-8.3 (including Classic projects and Vanilla)
	-- No equivalent API existed
	RQE.API.GetActiveThreatMaps = function() return {} end

	-- Pre-9.0 (including Classic projects and Vanilla)
	-- API did not exist
	RQE.API.GetBountiesForMapID = function(uiMapID) return {} end

	-- Classic / Vanilla (no bounty system at all)
	RQE.API.GetBountySetInfoForMapID = function(uiMapID)
		return nil
	end

	-- Classic / Vanilla → no API available
	RQE.API.GetDistanceSqToQuest = function(questID)
		return 0, false
	end

	-- Pre-11.0.0 (Dragonflight and earlier, Classic, Vanilla) → not available
	RQE.API.GetHeaderIndexForQuest = function(questID)
		return nil
	end

	-- Not available in Vanilla or Classic before 1.15
	RQE.API.GetMapForQuestPOIs = function()
		return nil
	end

	-- Vanilla: Hard cap at 20 quests
	RQE.API.GetMaxNumQuests = function()
		return 20
	end

	-- Vanilla: Hard cap at 20 quests
	RQE.API.GetMaxNumQuestsCanAccept = function()
		return 20
	end

	-- Classic / Vanilla: Not available
	RQE.API.GetNextWaypoint = function(questID)
		return nil, nil, nil
	end

	-- Pre-1.3 Vanilla (no quest watch system)
	RQE.API.GetNumQuestWatches = function()
		return 0
	end

	-- Classic & Vanilla (no World Quests system)
	RQE.API.GetNumWorldQuestWatches = function()
		return 0
	end

	-- Classic & Vanilla (API not available)
	RQE.API.GetQuestAdditionalHighlights = function(questID)
		return nil
	end

	-- Classic & Vanilla (API not available)
	RQE.API.GetQuestDetailsTheme = function(questID)
		return nil
	end

	-- Classic & Vanilla (API not available)
	RQE.API.GetQuestDifficultyLevel = function(questID)
		return nil
	end

	-- Classic & Vanilla (not available)
	RQE.API.GetQuestIDForQuestWatchIndex = function(questWatchIndex)
		return nil
	end

	-- Classic & Vanilla (not available)
	RQE.API.GetQuestIDForWorldQuestWatchIndex = function(questWatchIndex)
		return nil
	end

	-- Classic & pre-10.0 (not available)
	RQE.API.GetQuestLogMajorFactionReputationRewards = function(questID)
		return {}
	end

	-- Not available in vanilla
	RQE.API.GetQuestLogPortraitGiver = function(questLogIndex)
		return nil
	end

	-- Not available before 11.0 or in Classic/Vanilla
	RQE.API.GetQuestRewardCurrencies = function(questID)
		return {}
	end

	-- Not available before 11.0 or in Classic/Vanilla
	RQE.API.GetQuestRewardCurrencyInfo = function(questID, currencyIndex, isChoice)
		return nil
	end

	-- Vanilla or unsupported
	RQE.API.GetQuestsOnMap = function(uiMapID)
		RQE.QuestsOnMap = {}
		return RQE.QuestsOnMap
	end

	-- Vanilla or unsupported
	RQE.API.GetQuestTagInfo = function(questID)
		RQE.QuestTagInfo = nil
		return RQE.QuestTagInfo
	end

	-- Pre-9.0.1 and Classic/Vanilla: API not available
	RQE.API.GetQuestType = function(questID)
		RQE.QuestTypeInfo = nil
		return RQE.QuestTypeInfo
	end

	-- Pre-9.0.1 and Classic/Vanilla: API not available
	RQE.API.GetQuestWatchType = function(questID)
		RQE.QuestWatchTypeInfo = nil
		return RQE.QuestWatchTypeInfo
	end

	-- Vanilla (1.x) to BfA (pre-9.0.1), including Classic projects
	--	Use: local info = RQE.API.GetSelectedQuest()
	--
	-- Wraps the legacy GetQuestLogSelection API (pre-9.x and Classic).
	-- Returns the currently selected quest log entry as an index, not a questID.
	--
	--	Returns (table, stored in RQE.SelectedQuestInfo):
	--	{
	--		questLogIndex -- number : The quest log index of the selected quest (0 if none selected). Note: this is NOT a questID.
	--	}
	--
	--	Notes:
	--		• Retail 9.x+ clients provide `C_QuestLog.GetSelectedQuest` which returns questID instead.
	--		• On Classic/older clients, only the quest log index is available.
	--		• Code using this function should handle both index and questID paths.
	RQE.API.GetSelectedQuest = function()
		local questSelected = GetQuestLogSelection()

		RQE.SelectedQuestInfo = {
			questLogIndex = questSelected or 0, -- log index, not questID
		}

		return RQE.SelectedQuestInfo
	end

	-- Vanilla (1.0.0–1.12.1), API didn’t exist so default to 0
	--	Use: local info = RQE.API.GetSuggestedGroupSize(questID)
	--
	-- Provides a stubbed structure for suggested group size in environments
	-- where the API is unavailable (e.g., original Vanilla without group size APIs).
	--
	--	Arguments:
	--		questID -- number : The quest identifier.
	--
	--	Returns (table, stored in RQE.SuggestedGroupSizeInfo):
	--	{
	--		questID				-- number : The quest ID passed in.
	--		suggestedGroupSize	-- number : Always 0 (API not available in this version).
	--	}
	--
	--	Notes:
	--		• This function exists as a compatibility shim.
	--		• On older clients without `GetQuestLogGroupNum` or `C_QuestLog.GetSuggestedGroupSize`, it returns 0 so consuming code has a consistent structure.
	RQE.API.GetSuggestedGroupSize = function(questID)
		RQE.SuggestedGroupSizeInfo = {
			questID = questID,
			suggestedGroupSize = 0,
		}

		return RQE.SuggestedGroupSizeInfo
	end

	-- Fallback if neither API exists
	--	Use: local info = RQE.API.GetTimeAllowed(questID)
	--
	-- Stub fallback for environments without quest timer APIs (e.g. Vanilla / Classic
	-- versions before 9.x). Always returns zeroed values.
	--
	--	Arguments:
	--		questID		-- number : The questID (not actually used in this stub).
	--
	--	Returns (table, stored in RQE.QuestTimeAllowedInfo):
	--	{
	--		questID		-- number : The provided questID.
	--		totalTime	-- number : Always 0 (no timing available).
	--		elapsedTime	-- number : Always 0 (no timing available).
	--	}
	--
	--	Notes:
	--		• On Retail 9.x+, `C_QuestLog.GetTimeAllowed(questID)` provides real data.
	--		• On Classic / earlier, only `GetQuestTimers()` exists and cannot map to questIDs.
	--		• This stub ensures consistent return shape for addon code.
	RQE.API.GetTimeAllowed = function(questID)
		RQE.QuestTimeAllowedInfo = {
			questID = questID,
			totalTime = 0,
			elapsedTime = 0,
		}

		return RQE.QuestTimeAllowedInfo
	end

	-- Classic and Pre-9 Retail (no API available)
	RQE.API.GetTitleForLogIndex = function(questLogIndex)
		RQE.QuestTitleForLogIndexInfo = {
			questLogIndex = questLogIndex,
			title = nil,
		}

		return RQE.QuestTitleForLogIndexInfo
	end

	-- Classic / Pre-8 Retail
	RQE.API.GetZoneStoryInfo = function(uiMapID)
		RQE.ZoneStoryInfo = {
			uiMapID = uiMapID,
			achievementID = nil,
			storyMapID = nil,
		}

		return RQE.ZoneStoryInfo
	end

	RQE.API.HasActiveThreats = function()
		RQE.HasActiveThreatsInfo = {
			hasActiveThreats = false,
		}

		return RQE.HasActiveThreatsInfo
	end

	RQE.API.IsComplete = function(questID)
		RQE.IsCompleteInfo = {
			isComplete = false,
		}

		return RQE.IsCompleteInfo
	end

	RQE.API.IsFailed = function(questID)
		RQE.IsFailedInfo = {
			isFailed = false,
		}

		return RQE.IsFailedInfo
	end

	-- Classic / Vanilla / Retail before 10.1.5
	RQE.API.IsImportantQuest = function(questID)
		RQE.IsImportantQuestInfo = {
			isImportant = false,
		}

		return RQE.IsImportantQuestInfo
	end

	RQE.API.IsMetaQuest = function(questID)
		RQE.IsMetaQuestInfo = {
			isMeta = false,
		}

		return RQE.IsMetaQuestInfo
	end

	RQE.API.IsQuestTrivial = function(questID)
		RQE.IsQuestTrivialInfo = {
			isTrivial = false,
		}

		return RQE.IsQuestTrivialInfo
	end

	RQE.API.IsRepeatableQuest = function(questID)
		RQE.IsRepeatableQuestInfo = {
			isRepeatable = false,
		}

		return RQE.IsRepeatableQuestInfo
	end

	RQE.API.UnitIsRelatedToActiveQuest = function(unit)
		RQE.UnitIsRelatedToActiveQuestInfo = {
			unit = unit,
			isRelatedToActiveQuest = false,
		}

		return RQE.UnitIsRelatedToActiveQuestInfo
	end
end


-------------------------------------------------
-- 🤝 Quest Session APIs
-------------------------------------------------

if (major > 8) or (major == 8 and minor >= 2 and patch >= 5) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Retail 8.2.5+ and all Classic re-releases (Party Sync introduced)
	-- Use: local allowed = RQE.API.CanStartQuestSession() instead of: C_QuestSession.CanStart()
	RQE.API.CanStartQuestSession = function()
		return C_QuestSession.CanStart()
	end

	-- Use: local exists = RQE.API.QuestSessionExists()	instead of: C_QuestSession.Exists()
	RQE.API.QuestSessionExists = function()
		return C_QuestSession.Exists()
	end

	-- Use: local hasJoined = RQE.API.QuestSessionHasJoined() instead of: C_QuestSession.HasJoined()
	RQE.API.QuestSessionHasJoined = function()
		return C_QuestSession.HasJoined()
	end

	-- Use: RQE.API.RequestSessionStart() instead of: C_QuestSession.RequestSessionStart()
	RQE.API.RequestSessionStart = function()
		return C_QuestSession.RequestSessionStart()
	end

	-- Use: RQE.API.RequestSessionStop() instead of: C_QuestSession.RequestSessionStop()
	RQE.API.RequestSessionStop = function()
		return C_QuestSession.RequestSessionStop()
	end

else

	-- Original Vanilla (no Party Sync)
	RQE.API.CanStartQuestSession = function()
		return false
	end

	RQE.API.QuestSessionExists = function()
		return false
	end

	RQE.API.QuestSessionHasJoined = function()
		return false
	end

	RQE.API.RequestSessionStart = function()
		return false
	end

	RQE.API.RequestSessionStop = function()
		return false
	end
end


-------------------------------------------------
-- 🗂️ Quest Task APIs
-------------------------------------------------

if (major > 11) or (major == 11 and minor >= 0 and patch >= 5) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and toc >= 11505) then
	-- Retail 11.0.5+ and Classic 1.15.5+ (new GetQuestsOnMap API)
	-- Use: local taskPOIs = RQE.API.GetQuestsOnMap(uiMapID) instead of: C_TaskQuest.GetQuestsOnMap(uiMapID)
	RQE.API.GetQuestsOnMap_Task = function(uiMapID)
		return C_TaskQuest.GetQuestsOnMap(uiMapID)
	end

elseif (major > 10) or (major == 10 and (minor > 2 or (minor == 2 and patch >= 6))) then
	-- Retail 10.2.6+
	-- Use: local widgetSet = RQE.API.GetQuestIconUIWidgetSet(questID) instead of: C_TaskQuest.GetQuestIconUIWidgetSet(questID)
	RQE.API.GetQuestIconUIWidgetSet = function(questID)
		return C_TaskQuest.GetQuestIconUIWidgetSet(questID)
	end

elseif major >= 9 then
	-- Use: local widgetSet = RQE.API.GetQuestTooltipUIWidgetSet(questID) instead of: C_TaskQuest.GetQuestTooltipUIWidgetSet(questID)
	RQE.API.GetQuestTooltipUIWidgetSet = function(questID)
		-- Retail 10.2.6+: uses C_TaskQuest.GetQuestTooltipUIWidgetSet
		if major > 10 or (major == 10 and minor >= 2 and patch >= 6) then
			return C_TaskQuest.GetQuestTooltipUIWidgetSet(questID)
		else
			-- Classic re-releases & Retail 9.x–10.2.5: uses GetUIWidgetSetIDFromQuestID
			return C_TaskQuest.GetUIWidgetSetIDFromQuestID(questID)
		end
	end

elseif major > 8 or (major == 8 and minor >= 3) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
		-- Retail 8.3+ and Classic re-releases
	-- Use: local quests = RQE.API.GetThreatQuests() instead of: C_TaskQuest.GetThreatQuests()
	RQE.API.GetThreatQuests = function()
		return C_TaskQuest.GetThreatQuests()
	end


elseif (major > 8) or (major == 8 and minor >= 1 and patch >= 5) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and toc >= 11400) then
	-- Retail 8.1.5+ and Classic 1.14+
	-- Use: local secondsLeft = RQE.API.GetQuestTimeLeftSeconds(questID) instead of: C_TaskQuest.GetQuestTimeLeftSeconds(questID)
	RQE.API.GetQuestTimeLeftSeconds = function(questID)
		return C_TaskQuest.GetQuestTimeLeftSeconds(questID)
	end

elseif (major >= 8) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and toc >= 11400) then
	-- Retail 8.0+ and Classic 1.14+
	-- Use: local shows = RQE.API.DoesMapShowTaskQuestObjectives(uiMapID) instead of: C_TaskQuest.DoesMapShowTaskQuestObjectives(uiMapID)
	RQE.API.DoesMapShowTaskQuestObjectives = function(uiMapID)
		return C_TaskQuest.DoesMapShowTaskQuestObjectives(uiMapID)
	end

elseif (major >= 7) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and toc >= 11400) then
	-- Retail 7.0+ and Classic 1.14+
	-- Use: local minutesLeft = RQE.API.GetQuestTimeLeftMinutes(questID) instead of: C_TaskQuest.GetQuestTimeLeftMinutes(questID)
	RQE.API.GetQuestTimeLeftMinutes = function(questID)
		return C_TaskQuest.GetQuestTimeLeftMinutes(questID)
	end

	-- Use: local active = RQE.API.IsTaskQuestActive(questID) instead of: C_TaskQuest.IsActive(questID)
	RQE.API.IsTaskQuestActive = function(questID)
		return C_TaskQuest.IsActive(questID)
	end

	-- Use: local title, factionID, capped, displayAsObjective = RQE.API.GetQuestInfoByQuestID(questID) 
	-- instead of: C_TaskQuest.GetQuestInfoByQuestID(questID)
	--
	-- Retrieves metadata for a task/world quest by its questID.
	--
	--	Arguments:
	--		questID -- number : The unique identifier for the quest.
	--
	--	Returns:
	--		title		-- string  : The quest title.
	--		factionID	-- number  : The faction ID associated with the quest.
	--		capped		-- boolean : True if the quest is capped (e.g., reputation cap reached).
	--		displayAsObjective	-- boolean : True if the quest should display as an active objective (only available in 8.3+).
	--
	--	Notes:
	--		• Retail 8.3+ returns all 4 values, including `displayAsObjective`.
	--		• In Classic and Retail <8.3, the API only returns the first 3 values 
	--			(`title, factionID, capped`) — this wrapper strips the 4th return automatically.
	--		• Useful for identifying whether a world quest is capped or should display as an objective.
	RQE.API.GetQuestInfoByQuestID = function(questID)
		local title, factionID, capped, displayAsObjective = C_TaskQuest.GetQuestInfoByQuestID(questID)

		-- displayAsObjective only exists starting in 8.3
		if (major < 8) or (major == 8 and minor < 3) then
			-- Strip 4th return so Classic & <8.3 behave correctly
			return title, factionID, capped
		end

		-- Retail 8.3+ returns all 4 values
		return title, factionID, capped, displayAsObjective
	end

	-- Use: local x, y = RQE.API.GetQuestLocation(questID, uiMapID) instead of: C_TaskQuest.GetQuestLocation(questID, uiMapID)
	-- Returns the normalized location coordinates of a task or world quest.
	--
	--	Arguments:
	--		questID	-- number : The quest identifier (Retail 8.0+ and Classic 1.13+).
	--		uiMapID	-- number : The map identifier for the current zone.
	--
	--	Returns:
	--		x -- number : Normalized horizontal coordinate (0.0 - 1.0)
	--		y -- number : Normalized vertical coordinate (0.0 - 1.0)
	--
	--	Notes:
	--		• Retail 8.0+ and Classic 1.13+ use the (questID, uiMapID) signature.
	--		• In Legion (7.x), the API used (mapID, parentMapID) instead of (questID, uiMapID).
	--		• Coordinates are normalized to the map area, not world-space values.
	RQE.API.GetQuestLocation = function(questID, uiMapID)
		-- In 7.x, function signature used mapID/parentMapID instead of questID/uiMapID
		if major == 7 then
			-- Older API form: (mapID, parentMapID)
			-- Fallback if only questID is provided (to avoid runtime errors)
			local mapID = questID or 0
			local parentMapID = uiMapID or 0
			return C_TaskQuest.GetQuestLocation(mapID, parentMapID)
		else
			-- Retail 8.0+ / Classic 1.13+ use proper (questID, uiMapID)
			return C_TaskQuest.GetQuestLocation(questID, uiMapID)
		end
	end

	-- Retail 7.0+ and Classic re-releases 1.14+
	-- Use: local uiMapID = RQE.API.GetQuestZoneID(questID)	instead of: C_TaskQuest.GetQuestZoneID(questID)
	RQE.API.GetQuestZoneID = function(questID)
		return C_TaskQuest.GetQuestZoneID(questID)
	end

	-- Use: RQE.API.RequestPreloadRewardData(questID) instead of: C_TaskQuest.RequestPreloadRewardData(questID)
	RQE.API.RequestPreloadRewardData = function(questID)
		return C_TaskQuest.RequestPreloadRewardData(questID)
	end

elseif (major > 6) or (major == 6 and minor >= 0) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and toc >= 11400) then
	-- Retail 6.0.2 → 11.0.0, and Classic 1.14.0+ / 2.5.1+ (older GetQuestsForPlayerByMapID API)
	-- Use: local taskPOIs = RQE.API.GetQuestsOnMap(uiMapID) instead of: C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
	RQE.API.GetQuestsOnMap_Task = function(uiMapID)
		return C_TaskQuest.GetQuestsForPlayerByMapID(uiMapID)
	end

else

	-- No Task Quests available (pre-6.0 / Vanilla 1.x)
	RQE.API.GetQuestsOnMap_Task = function(uiMapID)
		return {}
	end

	-- Pre-8.1.5 Retail and Vanilla Classic (no support)
	RQE.API.GetQuestTimeLeftSeconds = function(questID)
		return 0
	end

	-- Pre-7.0 Retail and Vanilla Classic (no support)
	RQE.API.GetQuestTimeLeftMinutes = function(questID)
		return 0
	end

	-- Pre-7.0 Retail and Vanilla Classic (no support)
	RQE.API.IsTaskQuestActive = function(questID)
		return false
	end

	-- Pre-8.0 Retail and Vanilla Classic (not available)
	RQE.API.DoesMapShowTaskQuestObjectives = function(uiMapID)
		return false
	end

	-- Not available in Classic or earlier Retail
	RQE.API.GetQuestIconUIWidgetSet = function(questID)
		return nil
	end

	-- Not available in Vanilla (pre-7.0)
	RQE.API.GetQuestInfoByQuestID = function(questID)
		return nil
	end

	-- Not available in Vanilla (pre-7.0)
	RQE.API.GetQuestLocation = function(questID, uiMapID)
		return nil, nil
	end

	-- Not available in Vanilla (<9)
	RQE.API.GetQuestTooltipUIWidgetSet = function(questID)
		return nil
	end

	-- Not available in Vanilla (<7 or <1.14 Classic)
	RQE.API.GetQuestZoneID = function(questID)
		return nil
	end

	-- Not available in Vanilla (<8.3)
	RQE.API.GetThreatQuests = function()
		return {}
	end

	-- Not available in Vanilla
	RQE.API.RequestPreloadRewardData = function(questID)
		return nil
	end
end


-------------------------------------------------
-- ⚔️ Scenario APIs
-------------------------------------------------

if (major >= 11) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Use: local crit = RQE.API.GetCriteriaInfo(criteriaIndex)	instead of: C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	--	Returns: {
	--		description, criteriaType, completed, quantity, totalQuantity, flags, assetID, criteriaID, duration, elapsed, failed, isWeightedProgress, isFormatted, quantityString (11.0.2+)
	--	}
	RQE.API.GetCriteriaInfo = function(criteriaIndex)
		local info = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
		if not info then return nil end
		local normalized = {
			description		= info.description,
			criteriaType	= info.criteriaType or 0,
			completed		= info.completed or false,
			quantity		= info.quantity or 0,
			totalQuantity	= info.totalQuantity or 0,
			flags		= info.flags or 0,
			assetID		= info.assetID or 0,
			criteriaID	= info.criteriaID,
			duration	= info.duration or 0,
			elapsed		= info.elapsed or 0,
			failed		= info.failed or false,
			isWeightedProgress	= info.isWeightedProgress or false,
			isFormatted		= info.isFormatted or false,
			quantityString	= info.quantityString,	-- may be nil pre-11.0.2
		}
		RQE.ScenarioCriteriaInfo = normalized
		return normalized
	end

elseif (major > 9) or (major == 9 and minor >= 1) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Retail 9.1+ and Classic re-releases
	-- Use: local info = RQE.API.GetScenarioInfo() instead of: C_ScenarioInfo.GetScenarioInfo()
	--	Returns a normalized table with fields:
	--	{
	--		name, currentStage, numStages, flags, isComplete, xp, money, type, area, uiTextureKit
	--	}
	RQE.API.GetScenarioInfo = function()
		local info = C_ScenarioInfo.GetScenarioInfo()
		if not info then return nil end
		RQE.ScenarioInfo = {
			name			= info.name,
			currentStage	= info.currentStage,
			numStages	= info.numStages,
			flags		= info.flags,
			isComplete	= info.isComplete,
			xp		= info.xp,
			money	= info.money,
			type	= info.type,
			area	= info.area,
			uiTextureKit = info.uiTextureKit,
		}
		return RQE.ScenarioInfo
	end

	-- Use: local stepInfo = RQE.API.GetScenarioStepInfo([scenarioStepID]) instead of: C_ScenarioInfo.GetScenarioStepInfo([scenarioStepID])
	--	Returns a normalized table with fields:
	--	{
	--		title, description, numCriteria, stepFailed, isBonusStep, isForCurrentStepOnly, shouldShowBonusObjective, spells = { { spellID, name, icon }, ... }, weightedProgress, rewardQuestID, widgetSetID
	--	}
	RQE.API.GetScenarioStepInfo = function(scenarioStepID)
		local info = C_ScenarioInfo.GetScenarioStepInfo(scenarioStepID)
		if not info then return nil end
		local normalized = {
			title			= info.title,
			description		= info.description,
			numCriteria		= info.numCriteria,
			stepFailed		= info.stepFailed,
			isBonusStep		= info.isBonusStep,
			isForCurrentStepOnly	= info.isForCurrentStepOnly,
			shouldShowBonusObjective	= info.shouldShowBonusObjective,
			spells = {},
			weightedProgress	= info.weightedProgress,
			rewardQuestID		= info.rewardQuestID,
			widgetSetID			= info.widgetSetID,
		}
		-- Normalize spells array
		if info.spells then
			for _, s in ipairs(info.spells) do
				table.insert(normalized.spells, {
					spellID = s.spellID,
					name	= s.name,
					icon	= s.icon,
				})
			end
		end
		RQE.ScenarioStepInfo = normalized
		return normalized
	end

elseif (major == 9) then
	-- Use: local towerType = RQE.API.GetJailersTowerTypeString(runType) instead of: C_ScenarioInfo.GetJailersTowerTypeString(runType)
	-- Returns a string type, depending on Enum.JailersTowerType
	-- Enum.JailersTowerType Values:
	--	0  TwistingCorridors
	--	1  SkoldusHalls
	--	2  FractureChambers
	--	3  Soulforges
	--	4  Coldheart
	--	5  Mortregar
	--	6  UpperReaches
	--	7  ArkobanHall			(9.0.2+)
	--	8  TormentChamberJaina	(9.0.2+)
	--	9  TormentChamberThrall	(9.0.2+)
	--	10 TormentChamberAnduin	(9.0.2+)
	--	11 AdamantVaults			(9.0.2+)
	--	12 ForgottenCatacombs		(9.1.0+)
	--	13 Ossuary			(9.1.0+)
	--	14 BossRush		(9.2.0+)
	RQE.API.GetJailersTowerTypeString = function(runType)
		local s = C_ScenarioInfo.GetJailersTowerTypeString(runType)
		RQE.JailersTowerTypeString = s
		return s
	end

elseif (major == 6) then
	-- Warlords of Draenor 6.0.2+ (step required)
	-- Use: local crit = RQE.API.GetCriteriaInfoByStep(stepID, criteriaIndex)
	RQE.API.GetCriteriaInfo = function(criteriaIndex)
		-- must be called via GetCriteriaInfoByStep in WoD
		return nil, "Use GetCriteriaInfoByStep(stepID, criteriaIndex)"
	end

elseif (major == 5) then
	-- Mists of Pandaria 5.0.4+
	-- Use: local crit = RQE.API.GetCriteriaInfo(criteriaIndex) instead of: C_Scenario.GetCriteriaInfo(criteriaIndex)
	--
	-- Retrieves information about a scenario criteria at the given index.
	--
	--	Arguments:
	--		criteriaIndex -- number : The index of the criteria to query.
	--
	--	Returns (table, stored in RQE.ScenarioCriteriaInfo):
	--	{
	--		description		-- string	: The criteria description text.
	--		criteriaType	-- number	: The type of criteria.
	--		completed		-- boolean	: True if the criteria is completed.
	--		quantity		-- number	: Current progress value.
	--		totalQuantity	-- number	: Required progress value.
	--		flags			-- number	: Criteria flags.
	--		assetID			-- number	: Associated asset identifier.
	--		quantityString	-- string	: Display string for the quantity.
	--		criteriaID	-- number	: The criteria’s unique ID.
	--		duration	-- number	: Time allowed for the criteria (if timed).
	--		elapsed		-- number	: Elapsed time (if timed).
	--		failed		-- boolean	: True if the criteria failed.
	--		isWeightedProgress -- boolean	: Whether progress is weighted.
	--	}
	--
	--	Notes:
	--		• If the criteria index is invalid, the function returns nil.
	--		• Normalized into a table for consistency across versions.
	--		• Also cached in `RQE.ScenarioCriteriaInfo` for reuse.
	RQE.API.GetCriteriaInfo = function(criteriaIndex)
		local description, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, duration, elapsed, criteriaFailed, isWeightedProgress = C_Scenario.GetCriteriaInfo(criteriaIndex)

		if not description then return nil end
		local normalized = {
			description		= description,
			criteriaType	= criteriaType,
			completed		= completed,
			quantity		= quantity,
			totalQuantity	= totalQuantity,
			flags			= flags,
			assetID			= assetID,
			quantityString	= quantityString,
			criteriaID		= criteriaID,
			duration	= duration,
			elapsed		= elapsed,
			failed		= criteriaFailed,
			isWeightedProgress = isWeightedProgress,
		}
		RQE.ScenarioCriteriaInfo = normalized
		return normalized
	end

else
	-- Classic (1.13.2 etc.) – Scenarios don’t exist here, return nil or empty
	-- Pre-9.1 retail and vanilla (no scenarios)
	RQE.API.GetScenarioInfo = function()
		return nil
	end

	-- Pre-9.1 retail and vanilla (no scenarios)
	RQE.API.GetScenarioStepInfo = function(_)
		return nil
	end

	-- Pre-MoP (no scenarios)
	RQE.API.GetCriteriaInfo = function(_)
		return nil
	end

	-- Not available in Classic or Vanilla
	RQE.API.GetJailersTowerTypeString = function(_)
		return nil
	end
end


-------------------------------------------------
-- 🎯 SuperTrack APIs
-------------------------------------------------

if major >= 11 then
	-- Use: RQE.API.ClearAllSuperTracked() instead of: C_SuperTrack.ClearAllSuperTracked()
	RQE.API.ClearAllSuperTracked = function()
		return C_SuperTrack.ClearAllSuperTracked()
	end

	-- Use: local name = RQE.API.GetSuperTrackedItemName() instead of: C_SuperTrack.GetSuperTrackedItemName()
	RQE.API.GetSuperTrackedItemName = function()
		return C_SuperTrack.GetSuperTrackedItemName()
	end

	-- Use: local isTracking = RQE.API.IsSuperTrackingAnything() instead of: C_SuperTrack.IsSuperTrackingAnything()
	-- Returns: Boolean
	-- true if *any* quest, waypoint, or super-tracked entity is active
	RQE.API.IsSuperTrackingAnything = function()
		local isTracking = C_SuperTrack.IsSuperTrackingAnything()
		RQE.SuperTrackIsTracking = isTracking
		return isTracking
	end
else
	RQE.API.ClearAllSuperTracked = function() return nil end
	RQE.API.GetSuperTrackedItemName = function() return nil end
	RQE.API.IsSuperTrackingAnything = function() return false end
end


-------------------------------------------------
-- 🛠️ TradeSkill / Crafting APIs
-------------------------------------------------

if major >= 11 then
	-- Use: RQE.API.OpenRecipe(recipeID) instead of: C_TradeSkillUI.OpenRecipe(recipeID)
	--	Arguments:
	--		recipeID (number) – the spellID/recipeID of the trade skill recipe
	--	Behavior:
	--		Opens the TradeSkillUI with the given recipe highlighted
	RQE.API.OpenRecipe = function(recipeID)
		local ok = C_TradeSkillUI.OpenRecipe(recipeID)
		RQE.OpenedRecipeID = recipeID
		return ok
	end

	-- Use: RQE.API.CraftRecipe(recipeID, count) instead of: C_TradeSkillUI.CraftRecipe(recipeID, count)
	-- Wraps C_TradeSkillUI.CraftRecipe with all arguments including applyConcentration
	RQE.API.CraftRecipe = function(recipeID, count, craftingReagents, recipeLevel, orderID, applyConcentration)
		return C_TradeSkillUI.CraftRecipe(recipeID, count, craftingReagents, recipeLevel, orderID, applyConcentration)
	end

elseif major >= 10 then
	-- Retail (Dragonflight 10.0+)
	-- Added orderID (10.0.2), changed optionalReagents → craftingReagents (10.0.0)
	-- Use: RQE.API.CraftRecipe(recipeID, count, craftingReagents, recipeLevel, orderID) instead of: C_TradeSkillUI.CraftRecipe(recipeID, count)
	RQE.API.CraftRecipe = function(recipeID, count, craftingReagents, recipeLevel, orderID)
		return C_TradeSkillUI.CraftRecipe(recipeID, count, craftingReagents, recipeLevel, orderID)
	end

elseif major >= 7 then
	-- Retail (Legion 7.0+)
	-- First moved from DoTradeSkill → C_TradeSkillUI.CraftRecipe
	-- Use: RQE.API.CraftRecipe(recipeID, count, optionalReagents, recipeLevel)	instead of: C_TradeSkillUI.CraftRecipe(recipeID, count)
	RQE.API.CraftRecipe = function(recipeID, count, optionalReagents, recipeLevel)
		return C_TradeSkillUI.CraftRecipe(recipeID, count, optionalReagents, recipeLevel)
	end

else
	RQE.API.OpenRecipe = function(recipeID) return nil end

	-- Use: RQE.API.CraftRecipe(index, count) instead of: DoTradeSkill(index, count)
	--	Arguments:
	--		index (number) – tradeskill recipe index
	--		count (number) – number of times to craft
	RQE.API.CraftRecipe = function(index, count)
		return DoTradeSkill(index, count)
	end
end


-------------------------------------------------
-- 💬 Unit / Buff / Debuff APIs
-------------------------------------------------

if (major > 10) or (major == 10 and minor >= 2 and patch >= 5) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major >= 1 and minor >= 15) then
	-- Retail (10.2.5+) and Classic 1.15+ → C_UnitAuras.GetBuffDataByIndex
	-- Use: local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = RQE.API.UnitBuff("player", 1) instead of: UnitBuff("player", 1)
	RQE.API.UnitBuff = function(unit, index)
		local aura = C_UnitAuras.GetBuffDataByIndex(unit, index)
		if not aura then return nil end
		-- Normalize return to match old UnitBuff shape
		return aura.name, aura.icon, aura.applications or aura.charges, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId
	end

	-- Use: local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = RQE.API.UnitDebuff("target", 1) instead of: UnitDebuff("target", 1)
	RQE.API.UnitDebuff = function(unit, index)
		local aura = C_UnitAuras.GetDebuffDataByIndex(unit, index)
		if not aura then return nil end
		-- Normalize to match old UnitDebuff returns
		return aura.name, aura.icon, aura.applications or aura.charges, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId
	end

elseif major >= 2 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Burning Crusade → Dragonflight pre-10.2.5, and Classic 1.13–1.14
	RQE.API.UnitBuff = function(unit, index)
		-- Vanilla and Classic both provided UnitBuff
		return UnitBuff(unit, index)
	end

	-- Burning Crusade → Dragonflight pre-10.2.5, Classic 1.13–1.14
	RQE.API.UnitDebuff = function(unit, index)
		return UnitDebuff(unit, index)
	end

elseif major > 1 or (major == 1 and minor >= 12) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Post-1.12 (returns name, realm)
	RQE.API.UnitName = function(unit)
		local name, realm = UnitName(unit)
		return name, realm
	end

elseif major == 1 and minor < 12 then
	-- Vanilla pre-1.12 (returns name only)
	RQE.API.UnitName = function(unit)
		local name = UnitName(unit)
		return name, nil
	end

else
	-- Fallback (pre-1.0 safety net)
	RQE.API.UnitBuff = function(unit, index)
		return nil
	end

	-- Fallback (pre-1.0 safety net)
	RQE.API.UnitDebuff = function(unit, index)
		return nil
	end

	-- Fallback (pre-1.0 safety net)
	RQE.API.UnitName = function(unit)
		return nil, nil
	end
end


-------------------------------------------------
-- 📍 POI APIs
-------------------------------------------------

if major >= 8 or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
	-- Post-8.0 (BfA+) and Classic re-releases (1.13+)
	-- Use: local info = RQE.API.GetAreaPOIInfo(uiMapID, areaPoiID)	instead of: C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
	-- Returns AreaPOIInfo table with fields evolving across versions:
	--	{
	--		areaPoiID, position, name, description, linkedUiMapID (11.0.0),
	--		textureIndex, tooltipWidgetSet (10.2.6, renamed from widgetSetID),
	--		iconWidgetSet (10.2.6), atlasName, uiTextureKit (9.0.1),
	--		shouldGlow (9.0.5), factionID (10.0.2), isPrimaryMapForPOI (10.0.2),
	--		isAlwaysOnFlightmap (10.0.2), addPaddingAboveTooltipWidgets (10.2.6, renamed from addPaddingAboveWidgets),
	--		highlightWorldQuestsOnHover, highlightVignettesOnHover,
	--		isCurrentEvent (11.0.0)
	--	}
	-- As of 11.1.0: uiMapID argument became optional.
	RQE.API.GetAreaPOIInfo = function(uiMapID, areaPoiID)
		local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
		RQE.AreaPOIInfo = poiInfo
		return poiInfo
	end

elseif major >= 1 and major < 8 then
	-- Pre-8.0 (Vanilla → Legion, original only; not classic projects)
	-- Use: local type, name, description, textureIndex, x, y, mapLinkID, showInBattleMap, graveyardID, areaID, poiID, isObjectIcon, atlasName, displayAsBanner, mapFloor (7.3+), textureKitPrefix (7.3+) = GetMapLandmarkInfo(landmarkIndex)
	--
	--	Notes:
	--		• Added in 1.1.0.
	--		• In 7.0.3, `type` became the first return value (previously `name` was first).
	--		• In 7.3.0, `mapFloor` and `textureKitPrefix` were added.
	--		• Removed in 8.0.1 (replaced with C_AreaPoiInfo).
	RQE.API.GetAreaPOIInfo = function(uiMapID, areaPoiID)
		-- Fallback wrapper for older expansions
		local type, name, description, textureIndex, x, y, mapLinkID, showInBattleMap, graveyardID, areaID, poiID, isObjectIcon, atlasName, displayAsBanner, mapFloor, textureKitPrefix = GetMapLandmarkInfo(areaPoiID)

		return {
			type = type,
			name = name,
			description = description,
			textureIndex = textureIndex,
			x = x,
			y = y,
			mapLinkID = mapLinkID,
			showInBattleMap = showInBattleMap,
			graveyardID = graveyardID,
			areaID = areaID,
			poiID = poiID,
			isObjectIcon = isObjectIcon,
			atlasName = atlasName,
			displayAsBanner = displayAsBanner,
			mapFloor = mapFloor,
			textureKitPrefix = textureKitPrefix,
		}
	end
else
	-- Unsupported environments (failsafe)
	RQE.API.GetAreaPOIInfo = function(uiMapID, areaPoiID)
		return nil
	end
end


-------------------------------------------------
-- 🛠️ Miscellaneous APIs
-------------------------------------------------

if major > 10 or (major == 10 and minor >= 2) or (WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and major >= 1 and minor >= 15) then
	-- Retail 10.2+ and Classic 1.15+
	-- Use: local loadedOrLoading, loaded = RQE.API.IsAddOnLoaded("Blizzard_WorldMap") instead of: C_AddOns.IsAddOnLoaded("Blizzard_WorldMap")
	-- Returns:
	--   loadedOrLoading (boolean) - true if addon is loaded or loading
	--   loaded (boolean) - true if fully loaded (ADDON_LOADED fired)
	RQE.API.IsAddOnLoaded = function(name)
		return C_AddOns.IsAddOnLoaded(name)
	end

else

	-- Pre-10.2 Retail and Classic 1.13 → used global IsAddOnLoaded
	-- Use: local loaded, finished = RQE.API.IsAddOnLoaded("Blizzard_WorldMap") instead of: IsAddOnLoaded("Blizzard_WorldMap")
	-- Returns:
	--   loaded (boolean) - true if addon is being/has been loaded
	--   finished (boolean) - true if addon finished loading (ADDON_LOADED fired)
	RQE.API.IsAddOnLoaded = function(name)
		return IsAddOnLoaded(name)
	end
end