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

	-- Shared client-aware selector. Retail retains its own expansion/map-ID
	-- precedence and never consults Anniversary or SoD override sections.
	local version = GetBuildInfo()
	local majorText, minorText, patchText = tostring(version):match("^(%d+)%.(%d+)%.?(%d*)")
	local majorVersion = tonumber(majorText) or 0
	local minorVersion = tonumber(minorText) or 0
	local patchVersion = tonumber(patchText) or 0

	local function GetRetailDatabaseOrder()
		local databaseOrder = {}
		local addedSections = {}
		local function AddDatabaseSection(name)
			if addedSections[name] then return end
			addedSections[name] = true
			databaseOrder[#databaseOrder + 1] = name
		end

		if majorVersion >= 13 then AddDatabaseSection("LastTitan") end
		if majorVersion >= 12 then AddDatabaseSection("Midnight") end
		if majorVersion >= 11 then AddDatabaseSection("WarWithin") end
		if majorVersion >= 10 then AddDatabaseSection("Dragonflight") end
		if majorVersion >= 9 then AddDatabaseSection("Shadowlands") end
		if majorVersion >= 8 then AddDatabaseSection("BattleForAzeroth") end
		if majorVersion >= 7 then AddDatabaseSection("Legion") end

		if majorVersion >= 6 then
			local garrisonInfo = C_Garrison and C_Garrison.GetGarrisonInfo and C_Garrison.GetGarrisonInfo(2)
			local wodGarrisonLevel = type(garrisonInfo) == "table" and garrisonInfo.level or tonumber(garrisonInfo)
			if wodGarrisonLevel == 3 then
				AddDatabaseSection("WarlordsOfDraenor03")
			elseif wodGarrisonLevel == 2 then
				AddDatabaseSection("WarlordsOfDraenor02")
			else
				AddDatabaseSection("WarlordsOfDraenor")
			end
		end

		if majorVersion >= 5 then AddDatabaseSection("MistsOfPandaria") end
		if majorVersion >= 4 then AddDatabaseSection("Cataclysm") end
		if majorVersion >= 3 then AddDatabaseSection("Wrath") end
		if majorVersion >= 2 then AddDatabaseSection("BurningCrusade") end
		-- Retail can use every database section.  Keep its original Retail map-ID
		-- sections first, then use the Anniversary/SoD sections only as fallbacks.
		AddDatabaseSection("Vanilla")
		AddDatabaseSection("WrathAnniversary")
		AddDatabaseSection("BurningCrusadeAnniversary")
		AddDatabaseSection("VanillaSoD")

		-- Include tables for every version as a fallback.  AddDatabaseSection keeps
		-- the version-appropriate order above intact and prevents duplicates.
		for _, databaseName in ipairs({
			"LastTitan", "Midnight", "WarWithin", "Dragonflight", "Shadowlands",
			"BattleForAzeroth", "Legion", "WarlordsOfDraenor03",
			"WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria",
			"Cataclysm", "Wrath", "WrathAnniversary", "BurningCrusade",
			"BurningCrusadeAnniversary", "Vanilla", "VanillaSoD",
		}) do
			AddDatabaseSection(databaseName)
		end
		return databaseOrder
	end

	local databaseOrder
	if majorVersion >= 4 then
		databaseOrder = GetRetailDatabaseOrder()
	elseif majorVersion == 3 and (minorVersion > 5 or (minorVersion == 5 and patchVersion > 0)) then
		-- databaseOrder = { "WrathAnniversary", "Wrath", "BurningCrusade", "Vanilla" }
		-- databaseOrder = { "WrathAnniversary", "Wrath", "BurningCrusadeAnniversary", "BurningCrusade", "VanillaSoD", "Vanilla" }
		databaseOrder = { "WrathAnniversary", "BurningCrusadeAnniversary", "VanillaSoD" }
	elseif majorVersion == 3 then
		databaseOrder = { "Wrath", "BurningCrusade", "Vanilla" }
	elseif majorVersion == 2 and minorVersion >= 5 then
		-- databaseOrder = { "BurningCrusadeAnniversary", "BurningCrusade", "Vanilla" }
		databaseOrder = { "BurningCrusadeAnniversary", "VanillaSoD" }
	elseif majorVersion == 2 then
		databaseOrder = { "BurningCrusade", "Vanilla" }
	elseif majorVersion == 1 and minorVersion >= 15 then
		-- databaseOrder = { "VanillaSoD", "Vanilla" }
		databaseOrder = { "VanillaSoD" }
	else
		databaseOrder = { "Vanilla" }
	end

	for _, databaseName in ipairs(databaseOrder) do
		local database = RQEDatabase[databaseName]
		local questData = type(database) == "table" and database[questID] or nil
		if questData then
			return questData
		end
	end

	RQE.debugLog("Quest ID " .. questID .. " was not found in the supported database sections or active sandbox.")
	return nil

	--[[
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
	]]
end