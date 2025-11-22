--[[ 

DatabaseMain.lua
Main Database control file linking all other dbase modules

]]


------------------------------
-- #1. Global Declarations
------------------------------

RQE = RQE or {}

RQE.db = RQE.db or {}
RQEDatabase = RQEDatabase or {}
RQE.db.profile = RQE.db.profile or {}

-- Ensure sandbox globals exist
if not RQE_SandboxDB then
	RQE_SandboxDB = { entries = {} }
end
if not RQE_Sandbox then
	RQE_Sandbox = { entries = RQE_SandboxDB.entries, active = false }
end

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	print("RQE or RQE.debugLog is not initialized.")
end


---------------------------------------------------
-- #2. Database Access Functions
---------------------------------------------------

-- Function to fetch quest data from the applicable expansion
function RQE.getQuestData(questID)
	if type(questID) ~= "number" then
		RQE.debugLog("Error: questID is not a number, it is: ", tostring(questID))
		-- Further diagnostics to identify the caller or source of the error
		return nil
	end

	if RQE.db.profile.debugLevel == "INFO+" then
		print("QuestID: " .. questID .. ". Sandbox active:", RQE_Sandbox.active, "Entry found:", RQE_Sandbox.entries[questID] ~= nil)
	end

	-- ✅ SANDBOX OVERRIDE CHECK
	if RQE_Sandbox and RQE_Sandbox.active and RQE_Sandbox.entries then
		local sandboxEntry = RQE_Sandbox.entries[questID]

		if sandboxEntry then
			-- Handle possible nested forms (some saves wrap it in another table layer)
			if type(sandboxEntry) == "table" and sandboxEntry.entries then
				sandboxEntry = sandboxEntry.entries
			end

			-- Optional: verify that this is a valid quest-like table
			if type(sandboxEntry) == "table" and (sandboxEntry.title or sandboxEntry[1]) then
				if RQE.db.profile.debugLevel == "INFO+" then
					print("|cff33ff99[RQE Sandbox]|r Using SANDBOX data for questID:", questID)
				end
				return sandboxEntry
			else
				if RQE.db.profile.debugLevel == "INFO+" then
					print("|cffff6666[RQE Sandbox]|r Invalid Sandbox entry structure for questID:", questID)
				end
			end
		end
	end

	-- Get the build info to determine the game version
	local version, build = GetBuildInfo()
	local majorVersion = tonumber(string.match(version, "^%d+"))
	local wodGarrisonLevel = C_Garrison.GetGarrisonInfo(2)

	local dbOrder = {}
	if majorVersion >= 13 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "LastTitan", "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "LastTitan", "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "LastTitan", "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion >= 12 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "Midnight", "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion >= 11 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "WarWithin", "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion >= 10 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "Dragonflight", "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion == 9 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "Shadowlands", "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion == 8 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "BattleForAzeroth", "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "BattleForAzeroth", "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "BattleForAzeroth", "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion == 7 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "Legion", "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "Legion", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "Legion", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end
	elseif majorVersion == 6 then
		if wodGarrisonLevel == 3 then
			dbOrder = { "WarlordsOfDraenor03", "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		elseif wodGarrisonLevel == 2 then
			dbOrder = { "WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		else
			dbOrder = { "WarlordsOfDraenor", "MistsOfPandaria", "Cataclysm", "Wrath", "BurningCrusade", "Vanilla" }
		end

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

	if type(RQEDatabase) ~= "table" then
		if RQE.db.profile.debugLevel == "INFO" then
			print("|cFFFF3333[RQE]|r getQuestData(): RQEDatabase is invalid type:", type(RQEDatabase))
		end
		return nil
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
