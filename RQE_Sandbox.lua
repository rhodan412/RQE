--[[ 

RQE_Sandbox.lua
RQE Contribution Sandbox Editor

]]


--------------------------------------------------
-- #1. Initialize Sandbox
--------------------------------------------------
	
local function InitializeSandbox()
	-------------------------------------------------------
	-- #1a. Persistent SavedVariables Setup
	-------------------------------------------------------
	RQE_SandboxDB = RQE_SandboxDB or {}
	RQE_SandboxDB.entries = RQE_SandboxDB.entries or {}
	-- Keep raw-Lua legacy tests separate so RQE_Contribution continues to
	-- consume and export only the comment-aware contribution entries table.
	RQE_SandboxDB.legacyEntries = RQE_SandboxDB.legacyEntries or {}
	RQE_Sandbox = RQE_Sandbox or {}

	-- Both stores are available after every login; a user can turn either one
	-- off explicitly, and saving to a store turns that store back on.
	RQE_Sandbox.active = true
	RQE_Sandbox.entries = RQE_SandboxDB.entries
	RQE_Sandbox.legacyEntries = RQE_SandboxDB.legacyEntries
	RQE_Sandbox.legacyActive = true

	-- Returns the exact Sandbox entry the addon should use at runtime. A
	-- deliberately enabled Legacy test takes priority over the contribution
	-- source entry for the same quest, making it possible to test one raw-Lua
	-- step without altering the Contribution editor's source table.
	function RQE_Sandbox.GetRuntimeEntry(questID)
		if RQE_Sandbox.legacyActive and RQE_Sandbox.legacyEntries then
			local legacyEntry = RQE_Sandbox.legacyEntries[questID]
			if legacyEntry then return legacyEntry, "Legacy" end
		end

		if RQE_Sandbox.active and RQE_Sandbox.entries then
			local contributionEntry = RQE_Sandbox.entries[questID]
			if contributionEntry then return contributionEntry, "Contribution" end
		end

		return nil, nil
	end

	-------------------------------------------------------
	-- #1b. GetDataSource override
	-------------------------------------------------------
	function RQE:GetDataSource(questID)
		local sandboxEntry = RQE_Sandbox and RQE_Sandbox.GetRuntimeEntry and RQE_Sandbox.GetRuntimeEntry(questID)
		if sandboxEntry then
			return "Sandbox"
		else
			return "Database"
		end
	end

	-------------------------------------------------------
	-- #1c. Helper Functions
	-------------------------------------------------------
	local function SaveSandbox()
		RQE_SandboxDB.entries = RQE_Sandbox.entries
		RQE_SandboxDB.legacyEntries = RQE_Sandbox.legacyEntries
		print("|cff00ff00Sandbox data saved.|r")
	end

	-- A Contribution Sandbox save should immediately become the editor's
	-- selected source, even when an older normal contribution has the same ID.
	local function RefreshContributionStepEditor(questID)
		if not RQE_Contribution or not RQE_Contribution.RefreshStepEditor then return end
		RQE_Contribution.editorQuestID = questID
		RQE_Contribution.editorDataSource = "sandbox"
		RQE_Contribution:RefreshStepEditor(true)
		if RQE_Contribution.fetchInfoButton then
			RQE_Contribution.fetchInfoButton:Click()
		end
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

	-- Convert escaped pipes back into real WoW codes (so |c... works)
	local function NormalizePipesInString(s)
		if type(s) ~= "string" then return s end
		return s:gsub("||c", "|c"):gsub("||r", "|r"):gsub("||H", "|H"):gsub("||h", "|h")
	end

	local function NormalizePipesInTable(t)
		if type(t) ~= "table" then return end
		for k, v in pairs(t) do
			if type(v) == "string" then
				t[k] = NormalizePipesInString(v)
			elseif type(v) == "table" then
				NormalizePipesInTable(v)
			end
		end
	end

	-- A Lua comment is discarded by loadstring, so a pasted "-- [1] = { ... }"
	-- step would otherwise disappear entirely.  Convert fully commented step
	-- blocks into real data and preserve their intended state for the
	-- Contribution Step Editor/serializer.
	local function CountTableBraces(line)
		local count = 0
		for brace in line:gmatch("[{}]") do
			count = count + (brace == "{" and 1 or -1)
		end
		return count
	end

	-- Older raw-Lua Sandbox snippets sometimes leave a numeric step header
	-- active while commenting every field and its closing brace.  That shape is
	-- valid in Legacy Runtime mode, but is not a complete Lua table once a
	-- following commented step is promoted for Contribution editing.  Convert
	-- only those fully commented bodies to a normal commented step first.
	local function NormalizeLegacyMaskedStepHeaders(code)
		local sourceLines = {}
		code = code:gsub("\r\n", "\n")
		for line in (code .. "\n"):gmatch("(.-)\n") do
			table.insert(sourceLines, line)
		end

		for index, line in ipairs(sourceLines) do
			local indent, stepHeader = line:match("^(%s*)(%[%s*%d+%s*%]%s*=%s*{.*)$")
			if stepHeader then
				local braceDepth = CountTableBraces(stepHeader)
				local hasCommentedCloser = false
				for followingIndex = index + 1, #sourceLines do
					local followingLine = sourceLines[followingIndex]
					if not followingLine:match("^%s*$") then
						local _, commentedContent = followingLine:match("^(%s*)%-%-%s?(.*)$")
						if not commentedContent then break end
						braceDepth = braceDepth + CountTableBraces(commentedContent)
						if braceDepth <= 0 then
							hasCommentedCloser = true
							break
						end
					end
				end
				if hasCommentedCloser then
					sourceLines[index] = indent .. "-- " .. stepHeader
				end
			end
		end

		return table.concat(sourceLines, "\n")
	end

	local function PromoteCommentedSandboxSteps(code)
		local lines = {}
		local inCommentedStep = false
		local braceDepth = 0
		code = code:gsub("\r\n", "\n")

		for line in (code .. "\n"):gmatch("(.-)\n") do
			local indent, stepHeader = line:match("^(%s*)%-%-%s*(%[%s*%d+%s*%]%s*=%s*{.*)$")
			if not inCommentedStep and stepHeader then
				inCommentedStep = true
				braceDepth = CountTableBraces(stepHeader)
				table.insert(lines, indent .. stepHeader)
				table.insert(lines, indent .. "\t_rqeContributionCommented = true,")
			elseif inCommentedStep then
				local lineIndent, uncommentedLine = line:match("^(%s*)%-%-%s?(.*)$")
				local savedLine = uncommentedLine and (lineIndent .. uncommentedLine) or line
				table.insert(lines, savedLine)
				braceDepth = braceDepth + CountTableBraces(savedLine)
				if braceDepth <= 0 then inCommentedStep = false end
			else
				table.insert(lines, line)
			end
		end

		return table.concat(lines, "\n")
	end

	local function SetSandboxStepCommentState(data)
		for stepIndex, stepData in pairs(data) do
			if type(stepIndex) == "number" and type(stepData) == "table" and stepData._rqeContributionCommented == nil then
				stepData._rqeContributionCommented = false
			end
		end
	end

	-------------------------------------------------------
	-- #1c2. Normalized Sandbox chat export
	-------------------------------------------------------
	-- This exporter deliberately does not use the Sandbox frame serializer.
	-- The frame keeps its raw SavedVariables display, while this produces
	-- copy-ready contribution-style Lua without changing any Sandbox data.
	local function EscapeSandboxExportString(value)
		return (tostring(value or "")
			:gsub("\\", "\\\\")
			:gsub("\r", "\\r")
			:gsub("\n", "\\n")
			:gsub("\"", "\\\""))
	end

	local function FormatSandboxExportStringList(values)
		if type(values) ~= "table" then return "" end
		local formattedValues = {}
		for _, value in ipairs(values) do
			table.insert(formattedValues, "\"" .. EscapeSandboxExportString(value) .. "\"")
		end
		return table.concat(formattedValues, ", ")
	end

	local function GetSandboxExportComment(objectivesComment, objectivesQuestText)
		local comment = objectivesComment
		if (not comment or comment == "") and type(objectivesQuestText) == "table" and objectivesQuestText[1] then
			comment = "Objectives: " .. tostring(objectivesQuestText[1])
		end
		if not comment or comment == "" then return "" end
		comment = tostring(comment)
		if not comment:match("^%s*%-%-") then comment = "-- " .. comment end
		return " " .. comment
	end

	local function PrintSandboxExportCoordinate(prefix, coordinate, includeHotspotSettings)
		coordinate = coordinate or {}
		local x = tonumber(coordinate.x) or 0
		local y = tonumber(coordinate.y) or 0
		local idLabel = coordinate.mapID and "mapID" or "continentID"
		local idValue = coordinate.mapID or coordinate.continentID or 0
		local text = string.format("{ x = %.2f, y = %.2f, %s = %s", x, y, idLabel, tostring(idValue))
		if includeHotspotSettings then
			text = text .. string.format(", priorityBias = %s, minSwitchYards = %s, visitedRadius = %s", tostring(coordinate.priorityBias or 1), tostring(coordinate.minSwitchYards or 15), tostring(coordinate.visitedRadius or 35))
			if coordinate.wayText and coordinate.wayText ~= "" then
				text = text .. ", wayText = \"" .. EscapeSandboxExportString(coordinate.wayText) .. "\""
			end
		end
		print(prefix .. text .. " },")
	end

	local function PrintSandboxExportStep(stepIndex, stepData)
		local stepPrefix = stepData._rqeContributionCommented == true and "-- " or ""
		print(string.format("\t\t\t%s[%d] = {", stepPrefix, stepIndex))

		local notation = stepData._rqeContributionNotation and "\t-- " .. EscapeSandboxExportString(stepData._rqeContributionNotation) or ""
		print(string.format("\t\t\t\t%sdescription = \"%s\",%s", stepPrefix, EscapeSandboxExportString(stepData.description or "No Description"), notation))

		local hotspots = stepData.coordinateHotspots or stepData._rqeContributionCommentedHotspots
		local hotspotsPrefix = stepData._rqeContributionCommentedHotspots and "-- " or stepPrefix
		if type(hotspots) == "table" and #hotspots > 0 then
			print("\t\t\t\t" .. hotspotsPrefix .. "coordinateHotspots = {")
			for _, hotspot in ipairs(hotspots) do
				PrintSandboxExportCoordinate("\t\t\t\t\t" .. hotspotsPrefix, hotspot, true)
			end
			print("\t\t\t\t" .. hotspotsPrefix .. "},")
		elseif type(stepData.coordinates) == "table" then
			PrintSandboxExportCoordinate("\t\t\t\t" .. stepPrefix .. "coordinates = ", stepData.coordinates, false)
		end

		local checksPrefix = stepData._rqeContributionCommentedChecks and "-- " or stepPrefix
		if type(stepData.checks) == "table" and #stepData.checks > 0 then
			print("\t\t\t\t" .. checksPrefix .. "checks = {")
			for _, checkData in ipairs(stepData.checks) do
				print(string.format("\t\t\t\t\t%s{ mod = \"%s\", logic = \"%s\", check = { %s }, neededAmt = { %s }, funct = \"%s\" },", checksPrefix, EscapeSandboxExportString(checkData.mod or ""), EscapeSandboxExportString(checkData.logic or "AND"), FormatSandboxExportStringList(checkData.check), FormatSandboxExportStringList(checkData.neededAmt), EscapeSandboxExportString(checkData.funct or "")))
			end
			print("\t\t\t\t" .. checksPrefix .. "},")
		else
			if stepData.check then print(string.format("\t\t\t\t%scheck = { %s },", checksPrefix, FormatSandboxExportStringList(stepData.check))) end
			if stepData.neededAmt then print(string.format("\t\t\t\t%sneededAmt = { %s },", checksPrefix, FormatSandboxExportStringList(stepData.neededAmt))) end
			if stepData.funct then print(string.format("\t\t\t\t%sfunct = \"%s\",", checksPrefix, EscapeSandboxExportString(stepData.funct))) end
		end

		local npcTargets = stepData.npcTargets
		local npcTargetsPrefix = stepPrefix
		if stepData._rqeContributionCommentedNpcTarget then
			npcTargets = { stepData._rqeContributionCommentedNpcTarget }
			npcTargetsPrefix = stepPrefix ~= "" and stepPrefix or "-- "
		end
		if type(npcTargets) == "table" then
			print("\t\t\t\t" .. npcTargetsPrefix .. "npcTargets = {")
			for _, target in ipairs(npcTargets) do
				print(string.format("\t\t\t\t\t%s{ name = \"%s\", marker = %s, mustBeAlive = %s },", npcTargetsPrefix, EscapeSandboxExportString(target.name or ""), tostring(target.marker or 8), tostring(target.mustBeAlive ~= false)))
			end
			print("\t\t\t\t" .. npcTargetsPrefix .. "},")
		end

		local macroData = stepData.macro
		local macroPrefix = stepPrefix
		if stepData._rqeContributionCommentedMacro ~= nil then
			macroData = { stepData._rqeContributionCommentedMacro }
			macroPrefix = stepPrefix ~= "" and stepPrefix or "-- "
		end
		if type(macroData) == "table" then
			print(string.format("\t\t\t\t%smacro = { \"%s\" },", macroPrefix, EscapeSandboxExportString(table.concat(macroData, "\n"))))
		end

		if stepData.objectiveIndex ~= nil then print(string.format("\t\t\t\t%sobjectiveIndex = %s,", stepPrefix, tostring(stepData.objectiveIndex))) end
		print("\t\t\t" .. stepPrefix .. "},")
	end

	local function PrintSandboxExportQuest(questID, questData)
		print(string.format("\t\t[%d] = {", questID))
		print(string.format("\t\t\ttitle = \"%s\",%s", EscapeSandboxExportString(questData.title or "Unknown Title"), GetSandboxExportComment(questData.objectivesComment, questData.objectivesQuestText)))

		if type(questData.locations) == "table" and #questData.locations > 0 then
			print("\t\t\tlocations = {")
			for _, location in ipairs(questData.locations) do
				PrintSandboxExportCoordinate("\t\t\t\t", location, false)
			end
			print("\t\t\t},")
		elseif type(questData.location) == "table" then
			PrintSandboxExportCoordinate("\t\t\tlocation = ", questData.location, false)
		end

		if questData.objectivesQuestText then print(string.format("\t\t\tobjectivesQuestText = { %s },", FormatSandboxExportStringList(questData.objectivesQuestText))) end
		if questData.descriptionQuestText then print(string.format("\t\t\tdescriptionQuestText = { %s },", FormatSandboxExportStringList(questData.descriptionQuestText))) end
		if questData.npc then print(string.format("\t\t\tnpc = { %s },", FormatSandboxExportStringList(questData.npc))) end
		if questData.canEdit ~= nil then print("\t\t\tcanEdit = " .. tostring(questData.canEdit) .. ",") end

		local stepIndices = {}
		for stepIndex, stepData in pairs(questData) do
			if type(stepIndex) == "number" and type(stepData) == "table" then table.insert(stepIndices, stepIndex) end
		end
		table.sort(stepIndices)
		for _, stepIndex in ipairs(stepIndices) do PrintSandboxExportStep(stepIndex, questData[stepIndex]) end
		print("\t\t},")
	end

	function RQE_Sandbox.GetAllSandboxInfo()
		-- Do not include legacyEntries here. This is the contribution-only
		-- export consumed by RQE.GetSandBoxDataForAddon() and RQE_Contribution.
		local entries = RQE_SandboxDB and RQE_SandboxDB.entries
		if type(entries) ~= "table" then
			print("|cffff6666No Sandbox data is available.|r")
			return 0
		end

		local questIDs = {}
		for questID, questData in pairs(entries) do
			if type(questID) == "number" and type(questData) == "table" then table.insert(questIDs, questID) end
		end
		table.sort(questIDs)
		if #questIDs == 0 then
			print("|cffff6666No quests are saved in the Sandbox.|r")
			return 0
		end

		for _, questID in ipairs(questIDs) do PrintSandboxExportQuest(questID, entries[questID]) end
		return #questIDs
	end

	-- Alias for the same convenient /run style used by RQE's other data exports.
	RQE.GetAllSandboxInfo = RQE_Sandbox.GetAllSandboxInfo

	-------------------------------------------------------
	-- #1d. Editor Frame
	-------------------------------------------------------
	local SandboxFrame = CreateFrame("Frame", "RQE_SandboxEditor", UIParent, "BackdropTemplate")
	SandboxFrame:SetSize(700, 560)
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
	SandboxFrame.Title:SetText("|cffFFD100RQE Sandbox|r")

	local contributionTabBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	contributionTabBtn:SetSize(155, 25)
	contributionTabBtn:SetPoint("TOPLEFT", 20, -38)
	contributionTabBtn:SetText("Contribution")

	local legacyTabBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	legacyTabBtn:SetSize(155, 25)
	legacyTabBtn:SetPoint("LEFT", contributionTabBtn, "RIGHT", 10, 0)
	legacyTabBtn:SetText("Legacy Runtime")

	-------------------------------------------------------
	-- #1e. Quest ID Input
	-------------------------------------------------------
	local questIDLabel = SandboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	questIDLabel:SetPoint("TOPLEFT", 20, -75)
	questIDLabel:SetText("Quest ID")

	local questIDBox = CreateFrame("EditBox", nil, SandboxFrame, "InputBoxTemplate")
	questIDBox:SetSize(120, 25)
	-- questIDBox:SetPoint("TOPLEFT", 20, -50)
	questIDBox:SetPoint("LEFT", questIDLabel, "RIGHT", 10, 0)
	questIDBox:SetAutoFocus(false)
	questIDBox:SetNumeric(true)
	questIDBox:SetMaxLetters(10)

	local searchBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	searchBtn:SetSize(80, 25)
	searchBtn:SetPoint("LEFT", questIDBox, "RIGHT", 10, 0)
	searchBtn:SetText("Search")

	local modeHelp = SandboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	modeHelp:SetPoint("TOPLEFT", 20, -105)
	modeHelp:SetWidth(650)
	modeHelp:SetJustifyH("LEFT")

	-------------------------------------------------------
	-- #1f. Edit Box
	-------------------------------------------------------
	local scrollFrame = CreateFrame("ScrollFrame", nil, SandboxFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetSize(650, 330)
	scrollFrame:SetPoint("TOP", 0, -145)

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
	-- #1g. Buttons
	-------------------------------------------------------
	local saveBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	saveBtn:SetSize(130, 25)
	saveBtn:SetPoint("BOTTOMLEFT", 20, 20)
	saveBtn:SetText("Save Contribution")

	local toggleBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	toggleBtn:SetSize(140, 25)
	toggleBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
	toggleBtn:SetText(RQE_Sandbox.active and "Contribution ON" or "Contribution OFF")

	local clearBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	clearBtn:SetSize(110, 25)
	clearBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 10, 0)
	clearBtn:SetText("Clear Sandbox")

	local clearAllBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	clearAllBtn:SetSize(120, 25)
	clearAllBtn:SetPoint("LEFT", clearBtn, "RIGHT", 10, 0)
	clearAllBtn:SetText("Clear Both")

	local closeBtn = CreateFrame("Button", nil, SandboxFrame, "UIPanelButtonTemplate")
	closeBtn:SetSize(80, 25)
	closeBtn:SetPoint("BOTTOMRIGHT", -20, 20)
	closeBtn:SetText("Close")

	local currentSandboxMode = "contribution"

	local function IsContributionSandboxMode()
		return currentSandboxMode == "contribution"
	end

	local function GetCurrentSandboxEntries()
		return IsContributionSandboxMode() and RQE_Sandbox.entries or RQE_Sandbox.legacyEntries
	end

	local function GetCurrentSandboxModeName()
		return IsContributionSandboxMode() and "Contribution Sandbox" or "Legacy Runtime Sandbox"
	end

	local function UpdateModeControls()
		local contributionMode = IsContributionSandboxMode()
		SandboxFrame.Title:SetText(contributionMode and "|cffFFD100RQE Contribution Sandbox|r" or "|cffFFD100RQE Legacy Runtime Sandbox|r")
		local helpText = contributionMode
			and "Contribution mode preserves commented steps for RQE Contribution and RQE.GetSandBoxDataForAddon()."
			or "Legacy Runtime mode uses normal Lua comments: commented code is ignored, remaining active code runs directly, and these tests are never sent to RQE Contribution."
		if contributionMode and RQE_Sandbox.legacyActive then
			helpText = helpText .. " |cffff6666Legacy Runtime is still overriding live data; turn it off from the Legacy Runtime tab.|r"
		end
		modeHelp:SetText(helpText)
		saveBtn:SetText(contributionMode and "Save Contribution" or "Save Legacy")
		toggleBtn:SetText(contributionMode
			and (RQE_Sandbox.active and "Contribution ON" or "Contribution OFF")
			or (RQE_Sandbox.legacyActive and "Legacy ON" or "Legacy OFF"))
		clearBtn:SetText(contributionMode and "Clear Contribution" or "Clear Legacy")
		contributionTabBtn:SetEnabled(not contributionMode)
		legacyTabBtn:SetEnabled(contributionMode)
	end

	local function LoadSandboxEntry(questID)
		questIDBox:SetText(questID or "")
		editBox:SetText("")

		local entries = GetCurrentSandboxEntries()
		local modeName = GetCurrentSandboxModeName()

		if questID and entries[questID] then
			local entry = entries[questID]
			if type(entry) == "table" then
				local ok, text = pcall(TableToLuaString, entry, 1)
				if ok and text then
					editBox:SetText("[" .. questID .. "] = " .. text)
				else
					editBox:SetText("-- Failed to parse " .. modeName .. " entry for Quest ID " .. questID)
				end
			elseif type(entry) == "string" then
				editBox:SetText(entry)
			else
				editBox:SetText("-- Unsupported data type for Quest ID " .. questID)
			end
		else
			editBox:SetText("-- No " .. modeName .. " data for Quest ID " .. tostring(questID or "") .. ".")
		end
	end

	-------------------------------------------------------
	-- #1h. Logic
	-------------------------------------------------------
	saveBtn:SetScript("OnClick", function()
		local id = tonumber(questIDBox:GetText())
		local code = editBox:GetText()
		local contributionMode = IsContributionSandboxMode()
		-- Saving always activates the selected mode before validation/parsing,
		-- matching an ON toggle without reversing an already-ON state.
		if contributionMode then
			RQE_Sandbox.active = true
		else
			RQE_Sandbox.legacyActive = true
		end
		UpdateModeControls()
		if not id then print("|cffff0000Invalid Quest ID.|r") return end
		if not code or code:trim() == "" then print("|cffff0000No quest data provided.|r") return end

		code = code:gsub("^%s*%[%d+%]%s*=%s*", "")
		code = code:gsub(",%s*$", "")
		if contributionMode then
			code = NormalizeLegacyMaskedStepHeaders(code)
			code = PromoteCommentedSandboxSteps(code)
		end

		local func, err = loadstring("return " .. code)
		if not func then print("|cffff0000Lua Error in " .. GetCurrentSandboxModeName() .. ":|r " .. tostring(err)) return end
		local ok, data = pcall(func)
		if not ok or type(data) ~= "table" then
			print("|cffff0000Error parsing " .. GetCurrentSandboxModeName() .. " data.|r") return
		end

		NormalizePipesInTable(data)
		if contributionMode then
			SetSandboxStepCommentState(data)
		end

		GetCurrentSandboxEntries()[id] = data
		SaveSandbox()
		UpdateModeControls()
		if contributionMode then
			RefreshContributionStepEditor(id)
		end
		RQE.AddonSetStepIndex = 1
		UpdateFrame()
		RQE.OkayToUpdateSeparateFF = true
		RQE:StartPeriodicChecks()
		print("|cff00ff00Saved " .. GetCurrentSandboxModeName() .. " data for Quest ID:|r", id)
		RQE.OkayToUpdateSeparateFF = false
		RQE:CheckCoordHotspotsInSteps(id)
	end)

	searchBtn:SetScript("OnClick", function()
		local questID = tonumber(questIDBox:GetText())
		if not questID then
			print("|cffff0000Invalid Quest ID.|r")
			return
		end
		LoadSandboxEntry(questID)
	end)

	toggleBtn:SetScript("OnClick", function()
		if IsContributionSandboxMode() then
			RQE_Sandbox.active = not RQE_Sandbox.active
		else
			RQE_Sandbox.legacyActive = not RQE_Sandbox.legacyActive
		end
		SaveSandbox()
		UpdateModeControls()
		RQE.AddonSetStepIndex = 1
		UpdateFrame()
		RQE.OkayToUpdateSeparateFF = true
		RQE:StartPeriodicChecks()
		RQE.OkayToUpdateSeparateFF = false
	end)

	clearBtn:SetScript("OnClick", function()
		local id = tonumber(questIDBox:GetText())
		local entries = GetCurrentSandboxEntries()
		local contributionMode = IsContributionSandboxMode()
		local modeName = GetCurrentSandboxModeName()
		-- Clearing a mode also disables its runtime override.
		if contributionMode then
			RQE_Sandbox.active = false
		else
			RQE_Sandbox.legacyActive = false
		end

		if id and entries[id] then
			entries[id] = nil
			print("|cffff6666Removed " .. modeName .. " data for quest ID:|r", id)
		else
			wipe(entries)
			print("|cffff6666All " .. modeName .. " data cleared.|r")
		end

		SaveSandbox()
		UpdateModeControls()
		RQE.AddonSetStepIndex = 1
		UpdateFrame()
		RQE.OkayToUpdateSeparateFF = true
		RQE:StartPeriodicChecks()
		RQE.OkayToUpdateSeparateFF = false
		editBox:SetText("")
	end)

	clearAllBtn:SetScript("OnClick", function()
		RQE_Sandbox.active = false
		RQE_Sandbox.legacyActive = false
		wipe(RQE_Sandbox.entries)
		wipe(RQE_Sandbox.legacyEntries)
		SaveSandbox()
		UpdateModeControls()
		RQE.AddonSetStepIndex = 1
		UpdateFrame()
		RQE.OkayToUpdateSeparateFF = true
		RQE:StartPeriodicChecks()
		RQE.OkayToUpdateSeparateFF = false
		editBox:SetText("")
		print("|cffff6666All Contribution and Legacy Sandbox data cleared.|r")
	end)

	local function ShowSandboxMode(mode)
		currentSandboxMode = mode
		UpdateModeControls()
		local questID = tonumber(questIDBox:GetText())
		if not questID then questID = RQE.API.GetSuperTrackedQuestID() end
		LoadSandboxEntry(questID)
	end

	contributionTabBtn:SetScript("OnClick", function() ShowSandboxMode("contribution") end)
	legacyTabBtn:SetScript("OnClick", function() ShowSandboxMode("legacy") end)

	closeBtn:SetScript("OnClick", function() SandboxFrame:Hide() end)

	-------------------------------------------------------
	-- #1i. Load Current Quest Data on Open
	-------------------------------------------------------
	SandboxFrame:SetScript("OnShow", function()
		local questID = RQE.API.GetSuperTrackedQuestID()	--C_SuperTrack.GetSuperTrackedQuestID()
		UpdateModeControls()
		LoadSandboxEntry(questID)
	end)

	RQE_Sandbox.active = true

	-------------------------------------------------------
	-- #1j. Slash Command
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
-- #2. Helper functions
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


-- #3. Initialize independently of RQE_Contribution
-------------------------------------------------------
-- Wait until the login event so DatabaseMain/Config have created RQE.db before
-- the Sandbox's initialization message reaches the DebugLog print hook.
local sandboxLoginInitializer = CreateFrame("Frame")
sandboxLoginInitializer:RegisterEvent("PLAYER_LOGIN")
sandboxLoginInitializer:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	InitializeSandbox()
end)
