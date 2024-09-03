--[[ 
DatabaseMain.lua
Main Database control file linking all other dbase modules
]]

---------------------------------------------------
-- 1. Global Declarations
---------------------------------------------------

RQE = RQE or {}

RQE.db = RQE.db or {}
RQEDatabase = RQEDatabase or {}
RQE.db.profile = RQE.db.profile or {}

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	print("RQE or RQE.debugLog is not initialized.")
end


---------------------------------------------------
-- 2. Database Access Functions
---------------------------------------------------

-- Function to fetch quest data from the applicable expansion
function RQE.getQuestData(questID)
	if type(questID) ~= "number" then
		RQE.debugLog("Error: questID is not a number, it is: ", tostring(questID))
		-- Further diagnostics to identify the caller or source of the error
		return nil
	end

	-- Get the build info to determine the game version
	local version, build = GetBuildInfo()
	local majorVersion = tonumber(string.match(version, "^%d+"))

	local dbOrder = {}
	if majorVersion >= 11 then
		dbOrder = { "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion >= 10 then
		dbOrder = { "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 9 then
		dbOrder = { "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 8 then
		dbOrder = { "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 7 then
		dbOrder = { "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 6 then
		dbOrder = { "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 5 then
		dbOrder = { "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }

	elseif majorVersion == 4 then
		dbOrder = { "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 3 then
		dbOrder = { "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 2 then
		dbOrder = { "BurningCrusade", "Vanilla" }
	else
		dbOrder = { "Vanilla" }
	end

	for _, dbName in ipairs(dbOrder) do
		if RQEDatabase[dbName] then
			local questData = RQEDatabase[dbName][questID]
			if questData then
				return questData
			end
		else
			RQE.debugLog("Database for " .. dbName .. " not found.")
		end
	end

	RQE.debugLog("Quest ID " .. questID .. " not found in any database.")
	return nil
end
