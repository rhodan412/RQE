--[[ 

RQE_Sandbox.lua
RQE Contribution Sandbox Editor

]]


--------------------------------------------------
-- 1. Initialize Sandbox
--------------------------------------------------
	
local function InitializeSandbox()
	-------------------------------------------------------
	-- 1a. Persistent SavedVariables Setup
	-------------------------------------------------------
	RQE_SandboxDB = RQE_SandboxDB or {}
	RQE_SandboxDB.entries = RQE_SandboxDB.entries or {}
	RQE_Sandbox = RQE_Sandbox or {}

	RQE_Sandbox.active = RQE_Sandbox.active or false
	RQE_Sandbox.entries = RQE_SandboxDB.entries

	-------------------------------------------------------
	-- 1b. GetDataSource override
	-------------------------------------------------------
	function RQE:GetDataSource(questID)
		if RQE_Sandbox and RQE_Sandbox.active and RQE_Sandbox.entries[questID] then
			return "Sandbox"
		else
			return "Database"
		end
	end

	-------------------------------------------------------
	-- 1c. Helper Functions
	-------------------------------------------------------
	local function SaveSandbox()
		RQE_SandboxDB.entries = RQE_Sandbox.entries
		print("|cff00ff00Sandbox data saved.|r")
	end

	local function TableToLuaString(tbl, indent)
		indent = indent or 0
		local pad = string.rep("\t", indent)
		local lines = {"{"}
		for k, v in pairs(tbl) do
			local key = type(k) == "number" and "["..k.."]" or string.format("[%q]", k)
			if type(v) == "table" then
				table.insert(lines, string.format("%s\t%s = %s", pad, key, TableToLuaString(v, indent + 1)))
			elseif type(v) == "string" then
				table.insert(lines, string.format("%s\t%s = %q,", pad, key, v))
			else
				table.insert(lines, string.format("%s\t%s = %s,", pad, key, tostring(v)))
			end
		end
		table.insert(lines, pad .. "},")
		return table.concat(lines, "\n")
	end

	-------------------------------------------------------
	-- 1d. Editor Frame
	-------------------------------------------------------
	local SandboxFrame = CreateFrame("Frame", "RQE_SandboxEditor", UIParent, "BackdropTemplate")
	SandboxFrame:SetSize(700, 500)
	SandboxFrame:SetPoint("CENTER")
	SandboxFrame:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	SandboxFrame:SetMovable(true)
	SandboxFrame:EnableMouse(true)
	SandboxFrame:RegisterForDrag("LeftButton")
	SandboxFrame:SetScript("OnDragStart", SandboxFrame.StartMoving)
	SandboxFrame:SetScript("OnDragStop", SandboxFrame.StopMovingOrSizing)
	SandboxFrame:Hide()

	SandboxFrame.Title = SandboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	SandboxFrame.Title:SetPoint("TOP", 0, -10)
	SandboxFrame.Title:SetText("|cffFFD100RQE Contribution Sandbox|r")

	-------------------------------------------------------
	-- 1e. Quest ID Input
	-------------------------------------------------------
	local questIDBox = CreateFrame("EditBox", nil, SandboxFrame, "InputBoxTemplate")
	questIDBox:SetSize(120, 25)
	questIDBox:SetPoint("TOPLEFT", 20, -50)
	questIDBox:SetAutoFocus(false)
	questIDBox:SetNumeric(true)
	questIDBox:SetMaxLetters(10)

	local questIDLabel = SandboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	questIDLabel:SetPoint("LEFT", questIDBox, "RIGHT", 10, 0)
	questIDLabel:SetText("Quest ID")

	-------------------------------------------------------
	-- 1f. Edit Box
	-------------------------------------------------------
	local scrollFrame = CreateFrame("ScrollFrame", nil, SandboxFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetSize(650, 350)
	scrollFrame:SetPoint("TOP", 0, -90)

	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(630)
	editBox:SetAutoFocus(false)
	scrollFrame:SetScrollChild(editBox)

	-- Preserve tabs
	editBox:SetScript("OnTabPressed", function(self)
		local pos = self:GetCursorPosition()
		local text = self:GetText()
		self:SetText(text:sub(1, pos) .. "\t" .. text:sub(pos + 1))
		self:SetCursorPosition(pos + 1)
	end)

	-------------------------------------------------------
	-- 1g. Buttons
	-------------------------------------------------------
	local saveBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	saveBtn:SetSize(140, 25)
	saveBtn:SetPoint("BOTTOMLEFT", 20, 20)
	saveBtn:SetText("Save to Sandbox")

	local toggleBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	toggleBtn:SetSize(120, 25)
	toggleBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
	toggleBtn:SetText(RQE_Sandbox.active and "Sandbox ON" or "Sandbox OFF")

	local clearBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	clearBtn:SetSize(120, 25)
	clearBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 10, 0)
	clearBtn:SetText("Clear Sandbox")

	local closeBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	closeBtn:SetSize(80, 25)
	closeBtn:SetPoint("BOTTOMRIGHT", -20, 20)
	closeBtn:SetText("Close")

	-------------------------------------------------------
	-- 1h. Logic
	-------------------------------------------------------
	saveBtn:SetScript("OnClick", function()
		local id = tonumber(questIDBox:GetText())
		local code = editBox:GetText()
		if not id then print("|cffff0000Invalid Quest ID.|r") return end
		if not code or code:trim() == "" then print("|cffff0000No quest data provided.|r") return end

		code = code:gsub("^%s*%[%d+%]%s*=%s*", "")
		code = code:gsub(",%s*$", "")

		local func, err = loadstring("return " .. code)
		if not func then print("|cffff0000Lua Error:|r " .. tostring(err)) return end
		local ok, data = pcall(func)
		if not ok or type(data) ~= "table" then
			print("|cffff0000Error parsing quest data.|r") return
		end

		RQE_Sandbox.entries[id] = data
		SaveSandbox()
		RQE.AddonSetStepIndex = 1
		UpdateFrame()
		RQE.OkayToUpdateSeparateFF = true
		RQE:StartPeriodicChecks()
		print("|cff00ff00Saved Sandbox data for Quest ID:|r", id)
		RQE.OkayToUpdateSeparateFF = false
	end)

	toggleBtn:SetScript("OnClick", function()
		RQE_Sandbox.active = not RQE_Sandbox.active
		toggleBtn:SetText(RQE_Sandbox.active and "Sandbox ON" or "Sandbox OFF")
		SaveSandbox()
	end)

	clearBtn:SetScript("OnClick", function()
		local id = tonumber(questIDBox:GetText())
		if id and RQE_Sandbox.entries[id] then
			RQE_Sandbox.entries[id] = nil
			SaveSandbox()
			RQE.AddonSetStepIndex = 1
			UpdateFrame()
			RQE.OkayToUpdateSeparateFF = true
			RQE:StartPeriodicChecks()
			editBox:SetText("")
			print("|cffff6666Removed Sandbox data for quest ID:|r", id)
		else
			wipe(RQE_Sandbox.entries)
			RQE_SandboxDB.entries = {}
			SaveSandbox()
			editBox:SetText("")
			print("|cffff6666All Sandbox data cleared.|r")
		end
		RQE.OkayToUpdateSeparateFF = false
	end)

	closeBtn:SetScript("OnClick", function() SandboxFrame:Hide() end)

	-------------------------------------------------------
	-- 1i. Load Current Quest Data on Open
	-------------------------------------------------------
	SandboxFrame:SetScript("OnShow", function()
		local questID = C_SuperTrack.GetSuperTrackedQuestID and C_SuperTrack.GetSuperTrackedQuestID()
		questIDBox:SetText(questID or "")
		editBox:SetText("")

		if questID and RQE_Sandbox.entries[questID] then
			local entry = RQE_Sandbox.entries[questID]

			-- If the entry is a full table (as it will be after reload)
			if type(entry) == "table" then
				local ok, text = pcall(TableToLuaString, entry, 1)
				if ok and text then
					editBox:SetText("[" .. questID .. "] = " .. text)
				else
					editBox:SetText("-- Failed to parse Sandbox entry for Quest ID " .. questID)
				end
			elseif type(entry) == "string" then
				-- Just in case we later store as raw text again
				editBox:SetText(entry)
			else
				editBox:SetText("-- Unsupported data type for Quest ID " .. questID)
			end
		else
			editBox:SetText("-- No Sandbox data for the current supertracked quest.")
		end
	end)

	RQE_Sandbox.active = true

	-------------------------------------------------------
	-- 1j. Slash Command
	-------------------------------------------------------
	SLASH_RQESANDBOX1 = "/rqesandbox"
	SlashCmdList["RQESANDBOX"] = function()
		if SandboxFrame:IsShown() then
			SandboxFrame:Hide()
		else
			SandboxFrame:Show()
		end
	end

	print("|cff33ccff[RQE Sandbox Initialized]|r Use /rqesandbox to open the editor.")
end


-------------------------------------------------------
-- 2. Helper functions
-------------------------------------------------------

local function sortKeys(tbl)
	local keys = {}
	for k in pairs(tbl) do table.insert(keys, k) end
	table.sort(keys, function(a, b)
		if type(a) == "number" and type(b) == "number" then return a < b end
		return tostring(a) < tostring(b)
	end)
	return keys
end

-- Update TableToLuaString to use sorted keys
local function TableToLuaString(tbl, indent)
	indent = indent or 0
	local pad = string.rep("\t", indent)
	local lines = {"{"}
	for _, k in ipairs(sortKeys(tbl)) do
		local v = tbl[k]
		local key = type(k) == "number" and "["..k.."]" or string.format("%s = ", tostring(k))
		if type(v) == "table" then
			table.insert(lines, string.format("%s\t%s%s", pad, key, TableToLuaString(v, indent + 1)))
		elseif type(v) == "string" then
			table.insert(lines, string.format("%s\t%s\"%s\",", pad, key, v:gsub("\"", "\\\"")))
		else
			table.insert(lines, string.format("%s\t%s%s,", pad, key, tostring(v)))
		end
	end
	table.insert(lines, pad .. "},")
	return table.concat(lines, "\n")
end


-------------------------------------------------------
-- 3. Load only after RQE_Contribution
-------------------------------------------------------
if C_AddOns.IsAddOnLoaded("RQE_Contribution") then
	InitializeSandbox()
else
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(_, _, addon)
		if addon == "RQE_Contribution" then
			InitializeSandbox()
			f:UnregisterEvent("ADDON_LOADED")
		end
	end)
end
