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

local isRetail = RQE.IsRetail == true

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


	-- SANDBOX OVERRIDE CHECK. Legacy Runtime is intentionally selected only
	-- while its explicit test toggle is on; otherwise contribution entries
	-- retain their established priority over RQEDatabase.lua.
	local sandboxEntry, sandboxMode
	if RQE_Sandbox and RQE_Sandbox.GetRuntimeEntry then
		sandboxEntry, sandboxMode = RQE_Sandbox.GetRuntimeEntry(questID)
	elseif RQE_Sandbox and RQE_Sandbox.active and RQE_Sandbox.entries then
		-- Compatibility fallback for an older Sandbox file loaded beside this DB.
		sandboxEntry = RQE_Sandbox.entries[questID]
		sandboxMode = "Contribution"
	end
	if RQE.db.profile.debugLevel == "INFO+" then
		local contributionActive = RQE_Sandbox and RQE_Sandbox.active or false
		local legacyActive = RQE_Sandbox and RQE_Sandbox.legacyActive or false
		print("QuestID: " .. questID .. ". Contribution active:", contributionActive, "Legacy active:", legacyActive, "Runtime source:", sandboxMode or "Database", "Entry found:", sandboxEntry ~= nil)
	end


	if sandboxEntry then
		-- Handle possible nested forms (some saves wrap it in another table layer)
		if type(sandboxEntry) == "table" and sandboxEntry.entries then
			sandboxEntry = sandboxEntry.entries
		end

		-- Optional: verify that this is a valid quest-like table
		if type(sandboxEntry) == "table" and (sandboxEntry.title or sandboxEntry[1]) then
			if RQE.db.profile.debugLevel == "INFO+" then
				print("|cff33ff99[RQE " .. tostring(sandboxMode or "Sandbox") .. " Sandbox]|r Using SANDBOX data for questID:", questID)
			end
			return sandboxEntry
		elseif RQE.db.profile.debugLevel == "INFO+" then
			print("|cffff6666[RQE Sandbox]|r Invalid " .. tostring(sandboxMode or "Sandbox") .. " entry structure for questID:", questID)
		end
	end

	if not isRetail and type(RQEDatabase) ~= "table" then
		RQE.debugLog("|cFFFF3333[RQE]|r getQuestData(): RQEDatabase is invalid.")
		return nil
	end

	-- Shared client-aware selector. Retail uses only its Retail-era expansion
	-- sections, so generated data retains Retail map IDs and coordinates.
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
		-- Vanilla is the final Retail-era fallback.  Do not include Anniversary or
		-- Season of Discovery sections here: matching quest IDs can use different
		-- map IDs and coordinates from their Retail equivalents.
		AddDatabaseSection("Vanilla")

		-- Include only Retail-era tables as fallbacks. AddDatabaseSection keeps the
		-- version-appropriate order above intact and prevents duplicates.
		for _, databaseName in ipairs({
			"LastTitan", "Midnight", "WarWithin", "Dragonflight", "Shadowlands",
			"BattleForAzeroth", "Legion", "WarlordsOfDraenor03",
			"WarlordsOfDraenor02", "WarlordsOfDraenor", "MistsOfPandaria",
			"Cataclysm", "Wrath", "BurningCrusade", "Vanilla",
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
end
