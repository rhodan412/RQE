--[[

UITheme.lua
Theme registry, native-state restoration, control styling, and live UI theme application

]]


--------------------------------------------------
-- #1. 🎭 Theme Definitions & Card Styles
--------------------------------------------------

	-------------------------------------------------------
	-- #1a. Namespace, Media Paths & Theme Registry
	-------------------------------------------------------

	--[[ RQE tracker themes. The registry keeps each control's native presentation
	so theme changes can restore Basic without rebuilding live quest frames. ]]

	RQE = RQE or {}
	RQE.UI = RQE.UI or {}

	local UI = RQE.UI
	local ROOT = "Interface\\AddOns\\RQE\\Media\\UI\\"
	local WHITE = "Interface\\Buttons\\WHITE8X8"

	-- A future theme only needs these semantic asset keys and its own palette.
	-- Preview textures have transparent padding to 1024x1024; dimensions below
	-- identify the visible area that the settings page displays.
	UI.Themes = UI.Themes or {
		Basic = {
			name = "Basic", native = true,
			description = "Simple black frames, native controls, and Blizzard scenario artwork.",
			previews = {
				helper = { texture = ROOT .. "Previews\\BasicHelper.tga", width = 768, height = 647 },
				tracker = { texture = ROOT .. "Previews\\BasicTracker.tga", width = 645, height = 800 },
			},
		},
		AzureGold = {
			name = "Azure & Gold",
			description = "Azure and gold borders, icon controls, and themed scenario artwork.",
			previews = {
				helper = { texture = ROOT .. "Previews\\AzureGoldHelper.tga", width = 766, height = 646 },
				tracker = { texture = ROOT .. "Previews\\AzureGoldTracker.tga", width = 640, height = 910 },
			},
			colors = {
				azure = { 0 / 255, 87 / 255, 184 / 255 }, -- #0057B8
				azureBright = { 35 / 255, 145 / 255, 1 },
				gold = { 255 / 255, 215 / 255, 0 },	   -- #FFD700
				charcoal = { 9 / 255, 14 / 255, 23 / 255 },
				charcoalRaised = { 18 / 255, 24 / 255, 34 / 255 },
				muted = { 135 / 255, 145 / 255, 160 / 255 },
			},
			textures = {
				header = ROOT .. "Panels\\AzureGold_Header.tga",
				sectionHeader = ROOT .. "Panels\\AzureGold_SectionHeader.tga",
				scenarioTimed = ROOT .. "Panels\\ScenarioTimed.tga",
				scenarioTorghast = ROOT .. "Panels\\ScenarioTorghast.tga",
				scenarioUntimed = ROOT .. "Panels\\ScenarioUntimed.tga",
				dungeonFollower = ROOT .. "Panels\\ScenarioDungeonFollower.tga",
				dungeonNormal = ROOT .. "Panels\\ScenarioDungeonNormal.tga",
				dungeonHeroic = ROOT .. "Panels\\ScenarioDungeonHeroic.tga",
				buttonNormal = ROOT .. "Buttons\\AzureGold_Normal.tga",
				buttonHover = ROOT .. "Buttons\\AzureGold_Hover.tga",
				buttonPressed = ROOT .. "Buttons\\AzureGold_Pressed.tga",
				buttonDisabled = ROOT .. "Buttons\\AzureGold_Disabled.tga",
				buttonWide = ROOT .. "Buttons\\AzureGold_Wide.tga",
				icons = ROOT .. "Icons\\",
				iconPrefix = "AzureGold_",
			},
		},
		RoundTable = {
			name = "Knights of the Round Table",
			focusWaypointOffsetX = 2,
			description = "Engraved steel, burgundy heraldry, and parchment accents for the Quest Helper and Tracker.",
			previews = {
				helper = { texture = ROOT .. "Previews\\RoundTableHelper.tga", width = 771, height = 649 },
				tracker = { texture = ROOT .. "Previews\\RoundTableTracker.tga", width = 657, height = 916 },
			},
			colors = {
				azure = { 112 / 255, 34 / 255, 42 / 255 },
				azureBright = { 193 / 255, 76 / 255, 66 / 255 },
				gold = { 235 / 255, 204 / 255, 151 / 255 },
				charcoal = { 18 / 255, 16 / 255, 15 / 255 },
				charcoalRaised = { 31 / 255, 25 / 255, 22 / 255 },
				muted = { 174 / 255, 157 / 255, 137 / 255 },
				info = { 0.93, 0.82, 0.67 },
			},
			textures = {
				header = ROOT .. "Panels\\RoundTable_Header.tga",
				sectionHeader = ROOT .. "Panels\\RoundTable_SectionHeader.tga",
				scenarioTimed = ROOT .. "Panels\\ScenarioTimed.tga",
				scenarioTorghast = ROOT .. "Panels\\ScenarioTorghast.tga",
				scenarioUntimed = ROOT .. "Panels\\ScenarioUntimed.tga",
				dungeonFollower = ROOT .. "Panels\\ScenarioDungeonFollower.tga",
				dungeonNormal = ROOT .. "Panels\\ScenarioDungeonNormal.tga",
				dungeonHeroic = ROOT .. "Panels\\ScenarioDungeonHeroic.tga",
				buttonNormal = ROOT .. "Buttons\\RoundTable_Normal.tga",
				buttonHover = ROOT .. "Buttons\\RoundTable_Hover.tga",
				buttonPressed = ROOT .. "Buttons\\RoundTable_Pressed.tga",
				buttonDisabled = ROOT .. "Buttons\\RoundTable_Disabled.tga",
				buttonWide = ROOT .. "Buttons\\RoundTable_Wide.tga",
				icons = ROOT .. "Icons\\",
				iconPrefix = "RoundTable_",
			},
		},
		AstralCartographer = {
			name = "Astral Cartographer",
			description = "Celestial maps, silver edging, and cyan starlight for the Quest Helper and Tracker.",
			previews = {
				helper = { texture = ROOT .. "Previews\\AstralCartographerHelper.tga", width = 763, height = 648 },
				tracker = { texture = ROOT .. "Previews\\AstralCartographerTracker.tga", width = 648, height = 912 },
			},
			colors = {
				azure = { 62 / 255, 78 / 255, 157 / 255 },
				azureBright = { 85 / 255, 205 / 255, 235 / 255 },
				gold = { 222 / 255, 226 / 255, 247 / 255 },
				charcoal = { 11 / 255, 13 / 255, 32 / 255 },
				charcoalRaised = { 19 / 255, 23 / 255, 46 / 255 },
				muted = { 155 / 255, 169 / 255, 211 / 255 },
				info = { 0.65, 0.88, 1 },
			},
			textures = {
				header = ROOT .. "Panels\\AstralCartographer_Header.tga",
				sectionHeader = ROOT .. "Panels\\AstralCartographer_SectionHeader.tga",
				scenarioTimed = ROOT .. "Panels\\ScenarioTimed.tga",
				scenarioTorghast = ROOT .. "Panels\\ScenarioTorghast.tga",
				scenarioUntimed = ROOT .. "Panels\\ScenarioUntimed.tga",
				dungeonFollower = ROOT .. "Panels\\ScenarioDungeonFollower.tga",
				dungeonNormal = ROOT .. "Panels\\ScenarioDungeonNormal.tga",
				dungeonHeroic = ROOT .. "Panels\\ScenarioDungeonHeroic.tga",
				buttonNormal = ROOT .. "Buttons\\AstralCartographer_Normal.tga",
				buttonHover = ROOT .. "Buttons\\AstralCartographer_Hover.tga",
				buttonPressed = ROOT .. "Buttons\\AstralCartographer_Pressed.tga",
				buttonDisabled = ROOT .. "Buttons\\AstralCartographer_Disabled.tga",
				buttonWide = ROOT .. "Buttons\\AstralCartographer_Wide.tga",
				icons = ROOT .. "Icons\\",
				iconPrefix = "AstralCartographer_",
		},
		},
		ScarletCrusade = {
			name = "Scarlet Crusade",
			focusWaypointOffsetX = 2,
			description = "Vivid scarlet, bright gold, white steel, and parchment for the Quest Helper and Tracker.",
			previews = {
				helper = { texture = ROOT .. "Previews\\ScarletCrusadeHelper.tga", width = 769, height = 660 },
				tracker = { texture = ROOT .. "Previews\\ScarletCrusadeTracker.tga", width = 649, height = 907 },
			},
			colors = {
				azure = { 196 / 255, 43 / 255, 53 / 255 },
				azureBright = { 1, 67 / 255, 71 / 255 },
				gold = { 1, 217 / 255, 39 / 255 },
				charcoal = { 15 / 255, 18 / 255, 23 / 255 },
				charcoalRaised = { 27 / 255, 29 / 255, 34 / 255 },
				muted = { 1, 1, 1 },
				info = { 244 / 255, 230 / 255, 197 / 255 },
			},
			textures = {
				header = ROOT .. "Panels\\ScarletCrusade_Header.tga",
				sectionHeader = ROOT .. "Panels\\ScarletCrusade_SectionHeader.tga",
				scenarioTimed = ROOT .. "Panels\\ScenarioTimed.tga",
				scenarioTorghast = ROOT .. "Panels\\ScenarioTorghast.tga",
				scenarioUntimed = ROOT .. "Panels\\ScenarioUntimed.tga",
				dungeonFollower = ROOT .. "Panels\\ScenarioDungeonFollower.tga",
				dungeonNormal = ROOT .. "Panels\\ScenarioDungeonNormal.tga",
				dungeonHeroic = ROOT .. "Panels\\ScenarioDungeonHeroic.tga",
				buttonNormal = ROOT .. "Buttons\\ScarletCrusade_Normal.tga",
				buttonHover = ROOT .. "Buttons\\ScarletCrusade_Hover.tga",
				buttonPressed = ROOT .. "Buttons\\ScarletCrusade_Pressed.tga",
				buttonDisabled = ROOT .. "Buttons\\ScarletCrusade_Disabled.tga",
				buttonWide = ROOT .. "Buttons\\ScarletCrusade_Wide.tga",
				icons = ROOT .. "Icons\\",
				iconPrefix = "RoundTable_",
			},
		},
	}
	UI.ThemeOrder = { "Basic", "AstralCartographer", "AzureGold", "RoundTable", "ScarletCrusade" }

	-- Square artwork is center-cropped to fit either main frame without stretching.
	-- Basic deliberately has no picture choices.
	UI.BackgroundPictures = {
		AzureGold = {
			{ id = "royalSilk", name = "Royal Silk", texture = ROOT .. "Backgrounds\\AzureGold_RoyalSilk.tga" },
			{ id = "gildedMap", name = "Gilded Map", texture = ROOT .. "Backgrounds\\AzureGold_GildedMap.tga" },
			{ id = "stainedGlass", name = "Stained Glass", texture = ROOT .. "Backgrounds\\AzureGold_StainedGlass.tga" },
		},
		AstralCartographer = {
			{ id = "starChart", name = "Star Chart", texture = ROOT .. "Backgrounds\\AstralCartographer_StarChart.tga" },
			{ id = "auroraCompass", name = "Aurora Compass", texture = ROOT .. "Backgrounds\\AstralCartographer_AuroraCompass.tga" },
			{ id = "glacialOrrery", name = "Glacial Orrery", texture = ROOT .. "Backgrounds\\AstralCartographer_GlacialOrrery.tga" },
		},
		RoundTable = {
			{ id = "heraldicTapestry", name = "Heraldic Tapestry", texture = ROOT .. "Backgrounds\\RoundTable_HeraldicTapestry.tga" },
			{ id = "illuminatedChronicle", name = "Illuminated Chronicle", texture = ROOT .. "Backgrounds\\RoundTable_IlluminatedChronicle.tga" },
			{ id = "stoneHall", name = "Stone Hall", texture = ROOT .. "Backgrounds\\RoundTable_StoneHall.tga" },
		},
		ScarletCrusade = {
			{ id = "crusaderBanner", name = "Crusader Banner", texture = ROOT .. "Backgrounds\\ScarletCrusade_CrusaderBanner.tga" },
			{ id = "cathedralGlass", name = "Cathedral Glass", texture = ROOT .. "Backgrounds\\ScarletCrusade_CathedralGlass.tga" },
			{ id = "gildedReliquary", name = "Gilded Reliquary", texture = ROOT .. "Backgrounds\\ScarletCrusade_GildedReliquary.tga" },
		},
	}
	UI.BackgroundPictureDefaults = {
		AzureGold = "royalSilk",
		AstralCartographer = "starChart",
		RoundTable = "stoneHall",
		ScarletCrusade = "cathedralGlass",
	}

	-- Resolves a semantic icon name through the selected theme's asset prefix.
	function UI:GetIconTexture(iconName, themeKey)
		local theme = themeKey and self.Themes[themeKey]
		local textures = (theme and theme.textures) or self.Textures
		return textures.icons .. (textures.iconPrefix or "") .. iconName .. ".tga"
	end

	-------------------------------------------------------
	-- #1b. Scenario Card Style Registry
	-------------------------------------------------------

	-- Card styles are independent of the overall tracker theme.  Keep each
	-- activity's choices together so future artwork cannot leak into another
	-- scenario type, and keep saved choices when the player visits Basic.
	UI.CardStyleOrder = { "timed", "heroic", "normal", "follower", "delve", "torghast" }
	UI.CardStyles = {
		AzureGold = {
			torghast = { name = "Torghast", default = "veiledSouls", width = 1024, height = 512, styles = {
				{ id = "frostforgedSteel", name = "Frostforged Steel", texture = ROOT .. "Panels\\ScenarioTorghastFrostforgedSteel.tga" },
				{ id = "soulglass", name = "Soulglass", texture = ROOT .. "Panels\\ScenarioTorghastSoulglass.tga" },
				{ id = "runicBastion", name = "Runic Bastion", texture = ROOT .. "Panels\\ScenarioTorghast.tga" },
				{ id = "mawboundChains", name = "Mawbound Chains", texture = ROOT .. "Panels\\ScenarioTorghastMawboundChains.tga" },
				{ id = "veiledSouls", name = "Veiled Souls", texture = ROOT .. "Panels\\ScenarioTorghastVeiledSouls.tga" },
				{ id = "runicRelay", name = "Runic Relay", texture = ROOT .. "Panels\\ScenarioTorghastRunicRelay.tga" },
			} },
			delve = { name = "Delves", default = "gildedSlate", width = 1024, height = 512, styles = {
				{ id = "azureArchive", name = "Azure Archive", texture = ROOT .. "Panels\\ScenarioDelveAzureArchive.tga" },
				{ id = "gildedSlate", name = "Gilded Slate", texture = ROOT .. "Panels\\ScenarioDelveGildedSlate.tga" },
				{ id = "lapisExpedition", name = "Lapis Expedition", texture = ROOT .. "Panels\\ScenarioUntimed.tga" },
				{ id = "lanternlitDepths", name = "Lanternlit Depths", texture = ROOT .. "Panels\\ScenarioDelveLanternlitDepths.tga" },
				{ id = "crystalSeam", name = "Crystal Seam", texture = ROOT .. "Panels\\ScenarioDelveCrystalSeam.tga" },
				{ id = "emberSprint", name = "Ember Sprint", texture = ROOT .. "Panels\\ScenarioDelveEmberSprint.tga" },
			} },
			timed = { name = "Timed Scenario", default = "hourglassSands", width = 1024, height = 512, styles = {
				{ id = "stormSigil", name = "Storm Sigil", texture = ROOT .. "Panels\\ScenarioTimedStormSigil.tga" },
				{ id = "gildedSpiral", name = "Gilded Spiral", texture = ROOT .. "Panels\\ScenarioTimedGildedSpiral.tga" },
				{ id = "verdantWeave", name = "Verdant Weave", texture = ROOT .. "Panels\\ScenarioTimedVerdantWeave.tga" },
				{ id = "astralClock", name = "Astral Clock", texture = ROOT .. "Panels\\ScenarioTimedAstralClock.tga" },
				{ id = "dawnRun", name = "Dawn Run", texture = ROOT .. "Panels\\ScenarioTimedDawnRun.tga" },
				{ id = "hourglassSands", name = "Hourglass Sands", texture = ROOT .. "Panels\\ScenarioTimedHourglassSands.tga" },
				{ id = "frostwindRush", name = "Frostwind Rush", texture = ROOT .. "Panels\\ScenarioTimedFrostwindRush.tga" },
				{ id = "eclipseMantle", name = "Eclipse Mantle", texture = ROOT .. "Panels\\ScenarioTimedEclipseMantle.tga" },
			} },
			follower = { name = "Follower Dungeon", default = "gatheredCamp", width = 1024, height = 256, styles = {
				{ id = "guidedExpedition", name = "Guided Expedition", texture = ROOT .. "Panels\\ScenarioDungeonFollower.tga" },
				{ id = "companionsBanner", name = "Companion's Banner", texture = ROOT .. "Panels\\ScenarioDungeonFollowerCompanionsBanner.tga" },
				{ id = "waystone", name = "Waystone", texture = ROOT .. "Panels\\ScenarioDungeonFollowerWaystone.tga" },
				{ id = "lanternCompany", name = "Lantern Company", texture = ROOT .. "Panels\\ScenarioDungeonFollowerLanternCompany.tga" },
				{ id = "gatheredCamp", name = "Gathered Camp", texture = ROOT .. "Panels\\ScenarioDungeonFollowerGatheredCamp.tga" },
				{ id = "battlewornAegis", name = "Battleworn Aegis", texture = ROOT .. "Panels\\ScenarioDungeonBattlewornAegis.tga" },
			} },
			normal = { name = "Normal Dungeon", default = "moonlitPassage", width = 1024, height = 256, styles = {
				{ id = "stoneAndBrass", name = "Stone and Brass", texture = ROOT .. "Panels\\ScenarioDungeonNormalStoneAndBrass.tga" },
				{ id = "azureVault", name = "Azure Vault", texture = ROOT .. "Panels\\ScenarioDungeonNormalAzureVault.tga" },
				{ id = "arcaneMap", name = "Arcane Map", texture = ROOT .. "Panels\\ScenarioDungeonNormal.tga" },
				{ id = "moonlitPassage", name = "Moonlit Passage", texture = ROOT .. "Panels\\ScenarioDungeonNormalMoonlitPassage.tga" },
				{ id = "battlewornAegis", name = "Battleworn Aegis", texture = ROOT .. "Panels\\ScenarioDungeonBattlewornAegis.tga" },
			} },
			heroic = { name = "Heroic Dungeon", default = "sunwardCitadel", width = 1024, height = 256, styles = {
				{ id = "obsidiansCrest", name = "Obsidian's Crest", texture = ROOT .. "Panels\\ScenarioDungeonHeroic.tga" },
				{ id = "stormforged", name = "Stormforged", texture = ROOT .. "Panels\\ScenarioDungeonHeroicStormforged.tga" },
				{ id = "royalChallenge", name = "Royal Challenge", texture = ROOT .. "Panels\\ScenarioDungeonHeroicRoyalChallenge.tga" },
				{ id = "sunwardCitadel", name = "Sunward Citadel", texture = ROOT .. "Panels\\ScenarioDungeonHeroicSunwardCitadel.tga" },
				{ id = "azureWaygate", name = "Azure Waygate", texture = ROOT .. "Panels\\ScenarioDungeonHeroicAzureWaygate.tga" },
				{ id = "championsForge", name = "Champion's Forge", texture = ROOT .. "Panels\\ScenarioDungeonHeroicChampionsForge.tga" },
			} },
		},
	}
	-- Reuse the independent card artwork choices while giving each theme its own
	-- defaults and profile selection namespace. Preferred cards for one theme
	-- do not affect another theme's choices.
	local function registerThemeCardDefaults(themeKey, defaults)
		local groups = {}
		for slot, source in pairs(UI.CardStyles.AzureGold) do
			local styles = {}
			for index, style in ipairs(source.styles) do
				styles[index] = { id = style.id, name = style.name, texture = style.texture }
			end
			groups[slot] = {
				name = source.name, default = (defaults and defaults[slot]) or source.default,
				width = source.width, height = source.height, styles = styles,
			}
		end
		UI.CardStyles[themeKey] = groups
	end
	registerThemeCardDefaults("RoundTable", {
		timed = "dawnRun",
		heroic = "championsForge",
		normal = "battlewornAegis",
		follower = "companionsBanner",
		delve = "emberSprint",
		torghast = "mawboundChains",
	})
	registerThemeCardDefaults("AstralCartographer", {
		timed = "frostwindRush",
		follower = "waystone",
		delve = "crystalSeam",
		torghast = "soulglass",
		normal = "moonlitPassage",
		heroic = "azureWaygate",
	})
	registerThemeCardDefaults("ScarletCrusade", {
		timed = "astralClock",
		heroic = "azureWaygate",
		normal = "battlewornAegis",
		follower = "battlewornAegis",
		delve = "gildedSlate",
		torghast = "runicRelay",
	})
	-------------------------------------------------------
	-- #1c. Card Style Lookup, Selection & Refresh
	-------------------------------------------------------

	-- Returns the registered card-style group for a slot and tracker theme.
	function UI:GetCardStyleGroup(slot, themeKey)
		local themeStyles = self.CardStyles[themeKey or self.ActiveTheme or "AzureGold"]
		return themeStyles and themeStyles[slot]
	end

	-- Resolves the profile-selected card style, falling back to the group's configured default.
	function UI:GetCardStyleRecord(slot, themeKey)
		themeKey = themeKey or self.ActiveTheme or "AzureGold"
		local group = self:GetCardStyleGroup(slot, themeKey)
		if not group then return end
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.cardStyles and profile.cardStyles[themeKey]
		local selected = saved and saved[slot] or group.default
		local defaultStyle
		for _, style in ipairs(group.styles) do
			if style.id == group.default then defaultStyle = style end
			if style.id == selected then return style end
		end
		return defaultStyle
	end

	-- Returns the texture path for the resolved card style.
	function UI:GetCardTexture(slot, themeKey)
		local style = self:GetCardStyleRecord(slot, themeKey)
		return style and style.texture
	end

	-- Card picture opacity is independent for each content type and theme.
	-- Each slot currently starts at full strength; only a player's explicit
	-- profile choice takes precedence over a future theme default adjustment.
	UI.ThemeCardPictureOpacityDefaults = {
		Basic = { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 },
		AzureGold = { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 },
		AstralCartographer = { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 },
		RoundTable = { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 },
		ScarletCrusade = { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 },
	}

	function UI:GetCardPictureOpacity(slot, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.cardPictureOpacity
		local themeSaved = type(saved) == "table" and saved[themeKey]
		local defaults = self.ThemeCardPictureOpacityDefaults[themeKey]
		local value = type(themeSaved) == "table" and themeSaved[slot]
			or defaults and defaults[slot]
		return math.max(0, math.min(1, tonumber(value) or 1))
	end

	function UI:SetCardPictureOpacity(slot, value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local validSlot
		for _, cardType in ipairs(self.CardStyleOrder) do
			if cardType == slot then validSlot = true; break end
		end
		if not validSlot or not self.Themes[themeKey] or not (RQE.db and RQE.db.profile) then return false end
		local profile = RQE.db.profile
		profile.cardPictureOpacity = profile.cardPictureOpacity or {}
		profile.cardPictureOpacity[themeKey] = profile.cardPictureOpacity[themeKey] or {}
		profile.cardPictureOpacity[themeKey][slot] = math.max(0, math.min(1, tonumber(value) or 1))
		self:RefreshCardStyles()
		return true
	end

	-- Refreshes live scenario artwork immediately or defers it until combat ends.
	function UI:RefreshCardStyles()
		if RQE.API and RQE.API.Client and RQE.API.Client.InCombatLockdown() then
			self.pendingCardStyleRefresh = true
			return
		end
		self.pendingCardStyleRefresh = nil
		if RQE.UpdateScenarioFrame then RQE.UpdateScenarioFrame() end
	end

	-- Validates and saves a profile card-style selection before refreshing live artwork.
	function UI:SetCardStyle(slot, styleID, themeKey)
		themeKey = themeKey or "AzureGold"
		local group = self:GetCardStyleGroup(slot, themeKey)
		if not group or not (RQE.db and RQE.db.profile) then return false end
		local valid
		for _, style in ipairs(group.styles) do
			if style.id == styleID then valid = true; break end
		end
		if not valid then return false end
		local profile = RQE.db.profile
		profile.cardStyles = profile.cardStyles or {}
		profile.cardStyles[themeKey] = profile.cardStyles[themeKey] or {}
		profile.cardStyles[themeKey][slot] = styleID == group.default and nil or styleID
		self:RefreshCardStyles()
		return true
	end



--------------------------------------------------
-- #2. 📸 Runtime Theme State & Native Snapshots
--------------------------------------------------

	-------------------------------------------------------
	-- #2a. Active Theme, Registries & Profile State
	-------------------------------------------------------

	UI.ActiveTheme = UI.ActiveTheme or "AzureGold"
	UI.Colors = (UI.Themes[UI.ActiveTheme].colors or UI.Themes.AzureGold.colors)
	UI.Textures = (UI.Themes[UI.ActiveTheme].textures or UI.Themes.AzureGold.textures)
	UI.Registry = UI.Registry or {
		panels = {}, headers = {}, iconButtons = {}, textButtons = {}, searchBoxes = {},
		legacyButtons = {}, aceFrames = {}, locationBars = {},
	}
	UI.Registry.locationBars = UI.Registry.locationBars or {}
	UI.Registry.questIndexButtons = UI.Registry.questIndexButtons or {}
	UI.Native = UI.Native or setmetatable({}, { __mode = "k" })

	-- Reports whether AceDB has supplied an active profile that can store theme choices.
	local function profileReady()
		return RQE.db and type(RQE.db.GetCurrentProfile) == "function" and RQE.db.profile
	end

	-- Reports whether the current session is using a non-native tracker theme.
	function UI:IsEnabled()
		return self._sessionThemeEnabled == true
	end

	-- Resolves the active profile's named theme with compatibility for the legacy boolean setting.
	function UI:GetSelectedTheme()
		local profile = RQE.db and RQE.db.profile
		local selected = profile and profile.trackerTheme
		if selected and self.Themes[selected] then return selected end
		return profile and profile.useModernTheme == false and "Basic" or "AzureGold"
	end

	-- Button-surround opacity belongs to the selected overall theme in each
	-- profile. Basic always retains its native button appearance.
	UI.ThemeButtonBorderOpacityDefaults = {
		AzureGold = 0.55, RoundTable = 0.45, AstralCartographer = 0.2, ScarletCrusade = 0.05,
	}
	UI.ThemeFrameBorderOpacityDefaults = {
		Basic = 1, AzureGold = 1, RoundTable = 1, AstralCartographer = 1, ScarletCrusade = 1,
	}
	UI.ThemeFrameBackgroundOpacityDefaults = {
		AzureGold = { main = 0.65, tracker = 0.60 },
		AstralCartographer = { main = 0.65, tracker = 0.60 },
		RoundTable = { main = 0.65, tracker = 0.60 },
		ScarletCrusade = { main = 0.65, tracker = 0.60 },
	}
	UI.ThemeBackgroundPictureOpacityDefaults = {
		AzureGold = { main = 0.20, tracker = 0.30 },
		AstralCartographer = { main = 0.20, tracker = 0.35 },
		RoundTable = { main = 0.15, tracker = 0.15 },
		ScarletCrusade = { main = 0.15, tracker = 0.30 },
	}
	-- Only these RQE-authored tooltip families receive theme pictures. The
	-- tooltip's native dark fill stays untouched for every theme and client.
	UI.ThemeTooltipPictureOpacityDefaults = {
		AzureGold = { questID = 0.35, questName = 0.35, macroBody = 0.45 },
		AstralCartographer = { questID = 0.45, questName = 0.45, macroBody = 0.55 },
		RoundTable = { questID = 0.80, questName = 0.80, macroBody = 0.45 },
		ScarletCrusade = { questID = 0.60, questName = 0.60, macroBody = 0.15 },
	}

	function UI:GetButtonBorderOpacity(themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if themeKey == "Basic" then return 1 end
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.themeButtonBorderOpacity
		local value = type(saved) == "table" and saved[themeKey]
			or self.ThemeButtonBorderOpacityDefaults[themeKey]
		return math.max(0, math.min(1, tonumber(value) or 1))
	end

	function UI:SetButtonBorderOpacity(value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if themeKey == "Basic" or not profileReady() then return false end
		local profile = RQE.db.profile
		profile.themeButtonBorderOpacity = profile.themeButtonBorderOpacity or {}
		profile.themeButtonBorderOpacity[themeKey] = math.max(0, math.min(1, tonumber(value) or 1))
		if RQE.API and RQE.API.Client and RQE.API.Client.InCombatLockdown() then
			self.pendingButtonBorderOpacity = true
		else
			self:RefreshButtonBorderOpacity()
		end
		return true
	end

	-- Frame and header borders have their own per-theme profile setting; icon
	-- button surrounds continue to use ThemeButtonBorderOpacityDefaults.
	function UI:GetFrameBorderOpacity(themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.themeFrameBorderOpacity
		local value = type(saved) == "table" and saved[themeKey]
			or self.ThemeFrameBorderOpacityDefaults[themeKey]
		return math.max(0, math.min(1, tonumber(value) or 1))
	end

	function UI:SetFrameBorderOpacity(value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if not self.Themes[themeKey] or not profileReady() then return false end
		local profile = RQE.db.profile
		profile.themeFrameBorderOpacity = profile.themeFrameBorderOpacity or {}
		profile.themeFrameBorderOpacity[themeKey] = math.max(0, math.min(1, tonumber(value) or 1))
		if RQE.API and RQE.API.Client and RQE.API.Client.InCombatLockdown() then
			self.pendingFrameBorderOpacity = true
		else
			self:RefreshFrameBorderOpacity()
		end
		return true
	end

	-- Picture selection and the two picture opacities are saved per theme and
	-- profile. They never change the existing backdrop alpha settings.
	function UI:GetBackgroundPictureChoices(themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local choices = {}
		for _, choice in ipairs(self.BackgroundPictures[themeKey] or {}) do
			choices[#choices + 1] = {
				id = choice.id, name = choice.name, texture = choice.texture,
				themeName = self.Themes[themeKey].name,
				shortThemeName = self.Themes[themeKey].shortName,
			}
		end
		return choices
	end

	function UI:GetBackgroundPicture(themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local choices = self.BackgroundPictures[themeKey]
		if not choices then return nil end
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.themeBackgroundPictures
		local id = type(saved) == "table" and saved[themeKey]
		local available = self:GetBackgroundPictureChoices(themeKey)
		for _, choice in ipairs(available) do
			if choice.id == id then return choice end
		end
		local defaultID = self.BackgroundPictureDefaults[themeKey] or choices[1].id
		for _, choice in ipairs(available) do
			if choice.id == defaultID then return choice end
		end
		return nil
	end

	function UI:SetBackgroundPicture(id, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if not profileReady() then return false end
		if not self.BackgroundPictures[themeKey] then return false end
		for _, choice in ipairs(self:GetBackgroundPictureChoices(themeKey)) do
			if choice.id == id then
				local profile = RQE.db.profile
				profile.themeBackgroundPictures = profile.themeBackgroundPictures or {}
				profile.themeBackgroundPictures[themeKey] = id
				self:RefreshBackgroundPictures()
				self:RefreshTooltipBackground()
				return true
			end
		end
		return false
	end

	function UI:IsBackgroundPictureEnabled(themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if not self.BackgroundPictures[themeKey] then return false end
		local profile = RQE.db and RQE.db.profile
		local saved = profile and profile.themeBackgroundPictureEnabled
		return type(saved) ~= "table" or saved[themeKey] ~= false
	end

	function UI:SetBackgroundPictureEnabled(enabled, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if not self.BackgroundPictures[themeKey] or not profileReady() then return false end
		local profile = RQE.db.profile
		profile.themeBackgroundPictureEnabled = profile.themeBackgroundPictureEnabled or {}
		profile.themeBackgroundPictureEnabled[themeKey] = enabled and true or false
		self:RefreshBackgroundPictures()
		return true
	end

	function UI:GetBackgroundPictureOpacity(role, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if themeKey == "Basic" then return 0 end
		local profile = RQE.db and RQE.db.profile
		local bank = profile and profile.themeBackgroundPictureOpacity
		local saved = type(bank) == "table" and bank[themeKey]
		local value = type(saved) == "table" and saved[role]
		local defaults = self.ThemeBackgroundPictureOpacityDefaults[themeKey]
		local fallback = defaults and defaults[role] or 0.35
		return math.max(0, math.min(1, tonumber(value) or fallback))
	end

	function UI:SetBackgroundPictureOpacity(role, value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if role ~= "main" and role ~= "tracker" then return false end
		if themeKey == "Basic" or not profileReady() then return false end
		local profile = RQE.db.profile
		profile.themeBackgroundPictureOpacity = profile.themeBackgroundPictureOpacity or {}
		local bank = profile.themeBackgroundPictureOpacity
		bank[themeKey] = bank[themeKey] or {}
		bank[themeKey][role] = math.max(0, math.min(1, tonumber(value) or 0))
		self:RefreshBackgroundPictures()
		return true
	end

	function UI:GetTooltipPictureOpacity(kind, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local defaults = self.ThemeTooltipPictureOpacityDefaults[themeKey]
		local fallback = defaults and defaults[kind]
		if not fallback then return 0 end
		local profile = RQE.db and RQE.db.profile
		local byTheme = profile and profile.themeTooltipOpacity
		local byKind = type(byTheme) == "table" and byTheme[themeKey]
		local saved = type(byKind) == "table" and byKind[kind]
		local value = type(saved) == "table" and saved.picture
		return math.max(0, math.min(1, tonumber(value) or fallback))
	end

	function UI:SetTooltipPictureOpacity(kind, value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local defaults = self.ThemeTooltipPictureOpacityDefaults[themeKey]
		if not (defaults and defaults[kind]) or not profileReady() then return false end
		local profile = RQE.db.profile
		profile.themeTooltipOpacity = profile.themeTooltipOpacity or {}
		local byTheme = profile.themeTooltipOpacity
		byTheme[themeKey] = byTheme[themeKey] or {}
		byTheme[themeKey][kind] = byTheme[themeKey][kind] or {}
		byTheme[themeKey][kind].picture = math.max(0, math.min(1, tonumber(value) or 0))
		self:RefreshTooltipBackground()
		return true
	end

	-- Hide RQE's artwork before the shared GameTooltip is reused elsewhere.
	function UI:ClearTooltipBackground()
		local tooltip = GameTooltip
		if not tooltip or not tooltip.RQEThemeTooltipKind then return end
		if tooltip.RQEThemeTooltipPicture then tooltip.RQEThemeTooltipPicture:Hide() end
		tooltip.RQEThemeTooltipKind = nil
	end

	function UI:LayoutTooltipBackground(tooltip)
		local picture = tooltip and tooltip.RQEThemeTooltipPicture
		if not picture then return end
		local width = math.max(1, tooltip:GetWidth() - 12)
		local height = math.max(1, tooltip:GetHeight() - 12)
		if width > height then
			local inset = (1 - height / width) / 2
			picture:SetTexCoord(0, 1, inset, 1 - inset)
		else
			local inset = (1 - width / height) / 2
			picture:SetTexCoord(inset, 1 - inset, 0, 1)
		end
	end

	function UI:ApplyTooltipBackground(kind)
		local tooltip = GameTooltip
		local themeKey = self:GetSelectedTheme()
		local choice = self:GetBackgroundPicture(themeKey)
		if not tooltip or not choice or not self.ThemeTooltipPictureOpacityDefaults[themeKey]
			or not self.ThemeTooltipPictureOpacityDefaults[themeKey][kind] then
			self:ClearTooltipBackground()
			return
		end
		if not tooltip.RQEThemeTooltipHooked then
			tooltip:HookScript("OnHide", function() UI:ClearTooltipBackground() end)
			if tooltip:HasScript("OnTooltipCleared") then
				tooltip:HookScript("OnTooltipCleared", function() UI:ClearTooltipBackground() end)
			end
			tooltip:HookScript("OnSizeChanged", function(frame) UI:LayoutTooltipBackground(frame) end)
			tooltip.RQEThemeTooltipHooked = true
		end
		local center = tooltip.NineSlice and tooltip.NineSlice.Center
		if not tooltip.RQEThemeTooltipPicture then
			-- NineSlice center artwork is on its child frame, so its picture must
			-- share that parent to render above the dark fill on newer clients.
			local host = center and tooltip.NineSlice or tooltip
			local picture = host:CreateTexture(nil, "BACKGROUND", nil, 1)
			picture:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 6, -6)
			picture:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -6, 6)
			tooltip.RQEThemeTooltipPicture = picture
		end
		tooltip.RQEThemeTooltipKind = kind
		local picture = tooltip.RQEThemeTooltipPicture
		picture:SetTexture(choice.texture)
		picture:SetAlpha(self:GetTooltipPictureOpacity(kind, themeKey))
		self:LayoutTooltipBackground(tooltip)
		picture:Show()
	end

	function UI:RefreshTooltipBackground()
		local tooltip = GameTooltip
		if tooltip and tooltip.RQEThemeTooltipKind and tooltip:IsShown() then
			self:ApplyTooltipBackground(tooltip.RQEThemeTooltipKind)
	end
	end

	-- The old opacity fields remain Basic's native settings. Existing custom
	-- values are carried into the theme active at migration; later themes use
	-- their own starting values until the player adjusts them.
	function UI:InitializeFrameBackgroundOpacityBank()
		if not profileReady() then return end
		local profile = RQE.db.profile
		if profile.themeFrameBackgroundOpacityMigrated then return end
		profile.themeFrameBackgroundOpacity = profile.themeFrameBackgroundOpacity or {}
		local selected = self:GetSelectedTheme()
		if selected ~= "Basic" and not profile.themeFrameBackgroundOpacity[selected] then
			local main = tonumber(profile.MainFrameOpacity) or 0.55
			local tracker = tonumber(profile.QuestFrameOpacity) or 0.55
			local migrated = {}
			if main ~= 0.55 then migrated.main = main end
			if tracker ~= 0.55 then migrated.tracker = tracker end
			if next(migrated) then
				profile.themeFrameBackgroundOpacity[selected] = migrated
			end
		end
		profile.themeFrameBackgroundOpacityMigrated = true
	end

	function UI:GetFrameBackgroundOpacity(role, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		local profile = RQE.db and RQE.db.profile
		if role ~= "main" and role ~= "tracker" then return 0.55 end
		if themeKey == "Basic" then
			local value = profile and profile[role == "main" and "MainFrameOpacity" or "QuestFrameOpacity"]
			return math.max(0, math.min(1, tonumber(value) or 0.55))
		end
		self:InitializeFrameBackgroundOpacityBank()
		local bank = profile and profile.themeFrameBackgroundOpacity
		local saved = type(bank) == "table" and bank[themeKey]
		local value = type(saved) == "table" and saved[role]
		local defaults = self.ThemeFrameBackgroundOpacityDefaults[themeKey]
		local fallback = defaults and defaults[role]
			or profile and profile[role == "main" and "MainFrameOpacity" or "QuestFrameOpacity"]
		return math.max(0, math.min(1, tonumber(value) or tonumber(fallback) or 0.55))
	end

	function UI:SetFrameBackgroundOpacity(role, value, themeKey)
		themeKey = themeKey or self:GetSelectedTheme()
		if (role ~= "main" and role ~= "tracker") or not profileReady() then return false end
		local profile = RQE.db.profile
		value = math.max(0, math.min(1, tonumber(value) or 0.55))
		if themeKey == "Basic" then
			profile[role == "main" and "MainFrameOpacity" or "QuestFrameOpacity"] = value
		else
			self:InitializeFrameBackgroundOpacityBank()
			profile.themeFrameBackgroundOpacity = profile.themeFrameBackgroundOpacity or {}
			local bank = profile.themeFrameBackgroundOpacity
			bank[themeKey] = bank[themeKey] or {}
			bank[themeKey][role] = value
		end
		self:UpdatePanelOpacity()
		return true
	end

	-- Each profile keeps an independent set of font roles for every overall theme.
	-- The active set remains at textSettings so existing frame and settings code
	-- reads and writes the selected theme without changing frame geometry settings.
	local FONT_PATH = "Fonts\\FRIZQT__.TTF"
	local HEADER_PATH = "Fonts\\SKURRI.TTF"
	local CREAM = { 237 / 255, 191 / 255, 89 / 255 }
	local GOLDEN_YELLOW = { 1, 215 / 255, 0 }
	local DARK_ORANGE = { 1, 127 / 255, 0 }
	local CANARY = { 1, 1, 217 / 255 }
	local CARNATION_PINK = { 1, 153 / 255, 204 / 255 }
	local ASTRAL_ICE = { 222 / 255, 226 / 255, 247 / 255 }
	local PARCHMENT_IVORY = { 244 / 255, 230 / 255, 197 / 255 }
	local OLD_STEP_COLOR = { 1, 1, 0.8 }
	local FONT_ROLE_DEFAULTS = {
		headerText = { font = HEADER_PATH, size = 18, color = CREAM },
		sectionHeader = { font = HEADER_PATH, size = 18, color = CREAM },
		QuestIDText = { font = FONT_PATH, size = 15, color = { 1, 1, 0 } },
		QuestNameText = { font = FONT_PATH, size = 15, color = { 1, 1, 0 } },
		StepText = { font = FONT_PATH, size = 12, color = CANARY },
		DirectionTextFrame = { font = FONT_PATH, size = 13, color = { 1, 1, 217 / 255 } },
		QuestDescription = { font = FONT_PATH, size = 14, color = { 102 / 255, 204 / 255, 1 } },
		QuestObjectives = { font = FONT_PATH, size = 13, color = { 0, 1, 153 / 255 } },
	}
	-- A theme can override any combination of font, size, and color for any role.
	-- Unspecified properties retain the established defaults above.
	UI.ThemeFontDefaults = {
		Basic = { StepText = { color = CANARY } },
		AzureGold = { StepText = { color = CANARY } },
		RoundTable = {
			headerText = { color = DARK_ORANGE },
			QuestIDText = { color = CREAM },
			QuestNameText = { color = CREAM },
			StepText = { color = CANARY },
			QuestDescription = { color = CREAM },
		},
		AstralCartographer = {
			headerText = { color = ASTRAL_ICE },
			sectionHeader = { color = ASTRAL_ICE },
			QuestIDText = { color = ASTRAL_ICE },
			QuestNameText = { color = ASTRAL_ICE },
			StepText = { color = ASTRAL_ICE },
		},
		ScarletCrusade = {
			headerText = { color = GOLDEN_YELLOW },
			sectionHeader = { color = CREAM },
			QuestIDText = { color = PARCHMENT_IVORY },
			QuestNameText = { color = GOLDEN_YELLOW },
			StepText = { color = CANARY },
			DirectionTextFrame = { color = PARCHMENT_IVORY },
			QuestDescription = { color = CREAM },
		},
	}

	function UI:GetThemeFontDefault(role, themeKey)
		local fallback = FONT_ROLE_DEFAULTS[role]
		if not fallback then return nil end
		local theme = self.ThemeFontDefaults[themeKey or self:GetSelectedTheme()]
		local override = theme and theme[role] or nil
		return {
			font = override and override.font or fallback.font,
			size = override and override.size or fallback.size,
			color = override and override.color or fallback.color,
		}
	end
	local function copyFontSettings(source, themeKey, saved)
		local result = {}
		for role in pairs(FONT_ROLE_DEFAULTS) do
			local fallback = UI:GetThemeFontDefault(role, themeKey)
			local setting = source and source[role]
			local previous = saved and saved[role]
			local color = setting and setting.color
			local savedColor = previous and previous.color
			result[role] = {
				font = (setting and setting.font) or (previous and previous.font) or fallback.font,
				size = (setting and setting.size) or (previous and previous.size) or fallback.size,
				color = {
					(color and color[1]) or (savedColor and savedColor[1]) or fallback.color[1],
					(color and color[2]) or (savedColor and savedColor[2]) or fallback.color[2],
					(color and color[3]) or (savedColor and savedColor[3]) or fallback.color[3],
				},
			}
		end
		return result
	end
	local function sameFontColor(left, right)
		if type(left) ~= "table" then return false end
		for index = 1, 3 do
			if math.abs((tonumber(left[index]) or -1) - right[index]) > 0.001 then return false end
		end
		return true
	end

	local function migrateCanaryStepDefaults(bank)
		if bank.canaryStepDefaultsV1 then return end
		for _, themeKey in ipairs({ "Basic", "AzureGold" }) do
			local setting = bank[themeKey] and bank[themeKey].StepText
			if setting and sameFontColor(setting.color, OLD_STEP_COLOR) then
				setting.color = { unpack(CANARY) }
			end
		end
		bank.canaryStepDefaultsV1 = true
	end

	-- Existing theme banks contain complete copies of the old defaults. Replace
	-- only untouched Round Table colors, leaving player-selected colors intact.
	local function migrateRoundTableFontColors(bank)
		local round = bank.RoundTable
		if round and not bank.roundTableColorDefaultsV1 then
			for role, newColor in pairs({
				headerText = DARK_ORANGE,
				StepText = CANARY,
				QuestDescription = CREAM,
			}) do
				local setting = round[role]
				local oldColor = role == "StepText" and OLD_STEP_COLOR or FONT_ROLE_DEFAULTS[role].color
				if setting and sameFontColor(setting.color, oldColor) then
					setting.color = { unpack(newColor) }
				end
			end
		end
		bank.roundTableColorDefaultsV1 = true
		if round and not bank.roundTableQuestTitleDefaultsV1 then
			for _, role in ipairs({ "QuestIDText", "QuestNameText" }) do
				local setting = round[role]
				if setting and sameFontColor(setting.color, FONT_ROLE_DEFAULTS[role].color) then
					setting.color = { unpack(CARNATION_PINK) }
				end
			end
		end
		bank.roundTableQuestTitleDefaultsV1 = true
		if round and not bank.roundTableQuestTitleDefaultsV2 then
			for _, role in ipairs({ "QuestIDText", "QuestNameText" }) do
				local setting = round[role]
				if setting and (sameFontColor(setting.color, CARNATION_PINK)
					or sameFontColor(setting.color, FONT_ROLE_DEFAULTS[role].color)) then
					setting.color = { unpack(CREAM) }
				end
			end
		end
		bank.roundTableQuestTitleDefaultsV2 = true
	end

	local function migrateScarletFontDefaults(bank)
		if bank.scarletFontDefaultsV2 then return end
		local scarlet = bank.ScarletCrusade
		if scarlet then
			for role, oldColor in pairs({
				headerText = PARCHMENT_IVORY,
				sectionHeader = PARCHMENT_IVORY,
				QuestNameText = PARCHMENT_IVORY,
				DirectionTextFrame = CANARY,
			}) do
				local setting = scarlet[role]
				if setting and sameFontColor(setting.color, oldColor) then
					setting.color = { unpack(UI.ThemeFontDefaults.ScarletCrusade[role].color) }
				end
			end
		end
		bank.scarletFontDefaultsV2 = true
	end

	function UI:ActivateThemeTextSettings(themeKey)
		if not profileReady() then return end
		local profile = RQE.db.profile
		local profileName = RQE.db:GetCurrentProfile()
		local sameProfile = self._fontActiveProfile == profile
			and self._fontActiveProfileName == profileName
		local sameThemeSession = sameProfile and self._fontActiveTheme == themeKey
		local bank = profile.themeTextSettings
		local newBank = not bank
		if not bank then
			bank = {}
			-- Preserve existing global font choices when profiles first gain the
			-- per-theme bank; Astral and Knights title colors intentionally differ.
			bank.Basic = copyFontSettings(profile.textSettings, "Basic")
			bank.AzureGold = copyFontSettings(profile.textSettings, "AzureGold")
			bank.RoundTable = copyFontSettings(profile.textSettings, "RoundTable")
			bank.AstralCartographer = copyFontSettings(profile.textSettings, "AstralCartographer")
			bank.ScarletCrusade = copyFontSettings(nil, "ScarletCrusade")
			bank.RoundTable.headerText.color = { unpack(DARK_ORANGE) }
			bank.RoundTable.QuestIDText.color = { unpack(CREAM) }
			bank.RoundTable.QuestNameText.color = { unpack(CREAM) }
			bank.RoundTable.StepText.color = { unpack(CANARY) }
			bank.RoundTable.QuestDescription.color = { unpack(CREAM) }
			bank.roundTableColorDefaultsV1 = true
			bank.roundTableQuestTitleDefaultsV1 = true
			bank.roundTableQuestTitleDefaultsV2 = true
			bank.AstralCartographer.headerText.color = { unpack(ASTRAL_ICE) }
			bank.AstralCartographer.sectionHeader.color = { unpack(ASTRAL_ICE) }
			bank.AstralCartographer.QuestIDText.color = { unpack(ASTRAL_ICE) }
			bank.AstralCartographer.QuestNameText.color = { unpack(ASTRAL_ICE) }
			bank.AstralCartographer.StepText.color = { unpack(ASTRAL_ICE) }
			profile.themeTextSettings = bank
		end
		local previous = profile.activeTextSettingsTheme
		if previous and previous ~= themeKey and sameProfile
			and self._fontActiveTheme == previous then
			bank[previous] = copyFontSettings(profile.textSettings, previous, bank[previous])
		end
		-- AceDB removes values matching its global defaults from textSettings
		-- during profile shutdown. Never alias that table to a saved theme bank;
		-- on a fresh activation, use the untouched bank as the source. During an
		-- active session, mirror user edits from the working copy into the bank.
		if sameThemeSession and not newBank and bank[themeKey] then
			bank[themeKey] = copyFontSettings(profile.textSettings, themeKey, bank[themeKey])
		else
			bank[themeKey] = copyFontSettings(bank[themeKey], themeKey)
		end
		migrateCanaryStepDefaults(bank)
		migrateRoundTableFontColors(bank)
		migrateScarletFontDefaults(bank)
		local migrateFontSettings = self.Themes[themeKey] and self.Themes[themeKey].migrateFontSettings
		if migrateFontSettings then migrateFontSettings(bank, sameFontColor) end
		profile.textSettings = copyFontSettings(bank[themeKey], themeKey)
		profile.activeTextSettingsTheme = themeKey
		self._fontActiveProfile = profile
		self._fontActiveProfileName = profileName
		self._fontActiveTheme = themeKey
	end

	function UI:StyleSectionHeaderText(title)
		local settings = RQE.db and RQE.db.profile and RQE.db.profile.textSettings
		local section = settings and settings.sectionHeader or FONT_ROLE_DEFAULTS.sectionHeader
		if not title then return end
		title:SetFont(section.font, section.size, "OUTLINE")
		title:SetTextColor(unpack(section.color))
	end

	-- Step descriptions use one font role in the list and Separate Focus.
	-- Inline |c...|r codes and rich entity links retain their authored colors.
	UI.StepTextRegions = UI.StepTextRegions or setmetatable({}, { __mode = "k" })

	function UI:GetStepTextSettings()
		local settings = RQE.db and RQE.db.profile and RQE.db.profile.textSettings
		return settings and settings.StepText or self:GetThemeFontDefault("StepText")
	end

	function UI:StyleStepText(region)
		if not region then return end
		self.StepTextRegions[region] = true
		local settings = self:GetStepTextSettings()
		if region.GetObjectType and region:GetObjectType() == "SimpleHTML" then
			for _, tag in ipairs({ "p", "h1", "h2" }) do
				region:SetFont(tag, settings.font, settings.size, "")
				region:SetTextColor(tag, unpack(settings.color))
			end
		else
			region:SetFont(settings.font, settings.size)
			region:SetTextColor(unpack(settings.color))
		end
	end

	function UI:RefreshStepTextStyles()
		local settings = self:GetStepTextSettings()
		for region in pairs(self.StepTextRegions) do
			self:StyleStepText(region)
			if region.IsShown and region:IsShown() and region._rqeRichText
				and RQE.RenderTextWithItemsSteps then
				RQE.RenderTextWithItemsSteps(region, region._rqeRichText,
					settings.font, settings.size, settings.color, region._rqeRichParent)
				if region._rqeRichParent == RQE.StepsHoverContainer
					and region.GetObjectType and region:GetObjectType() == "FontString" then
					local visualText = region:GetText() or ""
					local lineBreaks = select(2, visualText:gsub("\n", ""))
					local measuredHeight = region:GetStringHeight() or 0
					region:SetHeight(math.max(20, measuredHeight + 4,
						(lineBreaks + 1) * (settings.size + 2)))
				end
			end
		end
		if RQE.UpdateContentSize then RQE:UpdateContentSize() end
		if RQE.UpdateSeparateContentHeight then RQE.UpdateSeparateContentHeight() end
	end

	function UI:ApplyThemeFonts()
		local profile = RQE.db and RQE.db.profile
		local settings = profile and profile.textSettings
		if not settings then return end
		local selected = self:GetSelectedTheme()
		local window = settings.headerText or FONT_ROLE_DEFAULTS.headerText
		local themed = selected ~= "Basic"
		if RQE.headerText then
			RQE.headerText:SetFont(window.font, math.max(8, window.size - (themed and 1 or 0)), "OUTLINE")
			RQE.headerText:SetTextColor(unpack(window.color))
		end
		if RQE.QuestTrackerHeaderText then
			RQE.QuestTrackerHeaderText:SetFont(window.font, math.max(8, window.size - (themed and 4 or 2)), "OUTLINE")
			RQE.QuestTrackerHeaderText:SetTextColor(unpack(window.color))
		end
		for _, key in ipairs({ "CampaignFrame", "QuestsFrame", "WorldQuestsFrame",
			"BonusQuestsFrame", "TaskQuestsFrame", "AchievementsFrame",
			"recipeTrackingFrame" }) do
			local frame = RQE[key]
			if frame and frame.header then
				self:StyleSectionHeaderText(frame.header)
				if RQE.RefreshTrackerSectionHeaderText and frame.headerFrame then
					RQE:RefreshTrackerSectionHeaderText(frame)
				end
			end
		end
		self:RefreshStepTextStyles()
	end

	local originalConfigurationChanged = RQE.ConfigurationChanged
	function RQE:ConfigurationChanged(...)
		if self.UI and self.db and self.db.profile then
			self.UI:ActivateThemeTextSettings(self.UI:GetSelectedTheme())
		end
		if originalConfigurationChanged then originalConfigurationChanged(self, ...) end
		if self.UI then self.UI:ApplyThemeFonts() end
	end

	-------------------------------------------------------
	-- #2b. Registry Memory & Anchor Helpers
	-------------------------------------------------------

	-- Registers a themed target once and updates its associated refresh metadata when reused.
	local function remember(list, target, data)
		if not target then return end
		for _, entry in ipairs(list) do
			if entry.target == target then
				entry.data = data or entry.data
				return
			end
		end
		table.insert(list, { target = target, data = data or {} })
	end

	-- Captures all anchors from a region so its native placement can be restored.
	local function copyPoints(region)
		local points = {}
		if region and region.GetNumPoints then
			for index = 1, region:GetNumPoints() do
				local point, relativeTo, relativePoint, x, y = region:GetPoint(index)
				points[index] = { point, relativeTo, relativePoint, x, y }
			end
		end
		return points
	end

	-- Replaces a region's anchors with a previously captured point list.
	local function restorePoints(region, points)
		if not region or not region.ClearAllPoints then return end
		region:ClearAllPoints()
		for _, point in ipairs(points or {}) do region:SetPoint(unpack(point, 1, 5)) end
	end

	-------------------------------------------------------
	-- #2c. Region Capture & Restoration
	-------------------------------------------------------

	-- Snapshots a texture or FontString's visual state and anchors.
	local function captureRegion(region)
		local original = { region = region, shown = region:IsShown(), points = copyPoints(region) }
		if region.GetObjectType and region:GetObjectType() == "Texture" then
			original.atlas = region.GetAtlas and region:GetAtlas()
			original.texture = region.GetTexture and region:GetTexture()
			original.texCoord = region.GetTexCoord and { region:GetTexCoord() }
			original.vertexColor = region.GetVertexColor and { region:GetVertexColor() }
			original.desaturated = region.IsDesaturated and region:IsDesaturated()
			original.alpha = region:GetAlpha()
		elseif region.GetObjectType and region:GetObjectType() == "FontString" then
			original.font = region.GetFont and { region:GetFont() }
			original.textColor = region.GetTextColor and { region:GetTextColor() }
		end
		return original
	end

	-- Restores a region's captured artwork, font, color, visibility, and anchors.
	local function restoreRegion(original)
		local region = original.region
		if original.atlas and region.SetAtlas then region:SetAtlas(original.atlas)
		elseif original.texture and region.SetTexture then region:SetTexture(original.texture) end
		if original.texCoord and region.SetTexCoord and #original.texCoord == 4 then region:SetTexCoord(unpack(original.texCoord)) end
		if original.vertexColor and region.SetVertexColor then region:SetVertexColor(unpack(original.vertexColor)) end
		if original.desaturated ~= nil and region.SetDesaturated then region:SetDesaturated(original.desaturated) end
		if original.alpha then region:SetAlpha(original.alpha) end
		if original.font and original.font[1] and region.SetFont then region:SetFont(unpack(original.font)) end
		if original.textColor and region.SetTextColor then region:SetTextColor(unpack(original.textColor)) end
		restorePoints(region, original.points)
		region:SetShown(original.shown)
	end

	-------------------------------------------------------
	-- #2d. Native Control Capture & Restoration
	-------------------------------------------------------

	-- Captures a frame or button's native geometry, backdrop, regions, and state textures once.
	local function captureNative(owner)
		if not owner or UI.Native[owner] then return end
		local original = { width = owner:GetWidth(), height = owner:GetHeight(), points = copyPoints(owner), regions = {} }
		if owner.GetBackdrop then
			local backdrop = owner:GetBackdrop()
			if backdrop then
				-- WoW can retain the table passed to SetBackdrop. Keep an independent
				-- copy so later theme calls cannot change the saved Basic backdrop.
				original.backdrop = {}
				for key, value in pairs(backdrop) do
					if type(value) == "table" then
						local nested = {}
						for nestedKey, nestedValue in pairs(value) do nested[nestedKey] = nestedValue end
						original.backdrop[key] = nested
					else
						original.backdrop[key] = value
					end
				end
			end
			if original.backdrop then
				original.backdropColor = { owner:GetBackdropColor() }
				original.borderColor = { owner:GetBackdropBorderColor() }
			end
		end
		if owner.GetObjectType and owner:GetObjectType() == "Button" then
			original.isButton = true
			original.text = owner:GetText()
			original.normal = owner:GetNormalTexture()
			original.highlight = owner:GetHighlightTexture()
			original.pushed = owner:GetPushedTexture()
			original.disabled = owner:GetDisabledTexture()
			original.buttonAssets = {
				normal = original.normal and original.normal:GetTexture(),
				highlight = original.highlight and original.highlight:GetTexture(),
				pushed = original.pushed and original.pushed:GetTexture(),
				disabled = original.disabled and original.disabled:GetTexture(),
			}
			original.normalFont = owner.GetNormalFontObject and owner:GetNormalFontObject()
			original.highlightFont = owner.GetHighlightFontObject and owner:GetHighlightFontObject()
		end
		if owner.GetRegions then
			for _, region in ipairs({ owner:GetRegions() }) do
				original.regions[#original.regions + 1] = captureRegion(region)
			end
		else
			original.regions[1] = captureRegion(owner)
		end
		if owner.NineSlice then
			original.nineShown = owner.NineSlice:IsShown()
			for _, region in ipairs({ owner.NineSlice:GetRegions() }) do
				original.regions[#original.regions + 1] = captureRegion(region)
			end
		end
		UI.Native[owner] = original
	end

	-- Restores captured native presentation and hides all RQE theme artwork attached to the control.
	local function restoreNative(owner, geometry)
		local original = UI.Native[owner]
		if not original then return end
		if owner.SetBackdrop then
			owner:SetBackdrop(original.backdrop)
			if original.backdropColor then owner:SetBackdropColor(unpack(original.backdropColor)) end
			if original.borderColor then owner:SetBackdropBorderColor(unpack(original.borderColor)) end
		end
		if original.isButton then
			for _, state in ipairs({
				{ "normal", "SetNormalTexture", "GetNormalTexture" },
				{ "highlight", "SetHighlightTexture", "GetHighlightTexture" },
				{ "pushed", "SetPushedTexture", "GetPushedTexture" },
				{ "disabled", "SetDisabledTexture", "GetDisabledTexture" },
			}) do
				local asset = original.buttonAssets[state[1]]
				if asset then
					owner[state[2]](owner, asset)
				else
					local current = owner[state[3]](owner)
					if current then current:SetTexture(nil); current:Hide() end
				end
			end
			owner:SetText(original.text or "")
			if original.normalFont then owner:SetNormalFontObject(original.normalFont) end
			if original.highlightFont then owner:SetHighlightFontObject(original.highlightFont) end
			owner.RQEThemeBlizzardStripped = nil
		end
		for _, region in ipairs(original.regions) do restoreRegion(region) end
		if owner.NineSlice and original.nineShown ~= nil then owner.NineSlice:SetShown(original.nineShown) end
		-- Some controls register additional regions after their first snapshot. Keep
		-- themed artwork hidden after restoring all native regions and button states.
		for _, key in ipairs({
			"RQEThemeBorderTL", "RQEThemeBorderTR", "RQEThemeBorderBL", "RQEThemeBorderBR",
			"RQEThemeBorderTop", "RQEThemeBorderBottom", "RQEThemeBorderLeft", "RQEThemeBorderRight",
			"RQEThemeAzureTop", "RQEThemeAzureBottom", "RQEThemeAzureLeft", "RQEThemeAzureRight",
			"RQEThemeGoldTop", "RQEThemeHeaderBackground", "RQEThemeHeaderLeft", "RQEThemeHeaderMiddle", "RQEThemeHeaderRight",
			"RQEThemeHeaderAccent", "RQEThemeLocationAzure", "RQEThemeLocationGold",
			"RQEThemeIcon", "RQEThemeSearchBackground", "RQEThemeSearchTL", "RQEThemeSearchTR",
			"RQEThemeSearchBL", "RQEThemeSearchBR", "RQEThemeSearchEdgeTop", "RQEThemeSearchEdgeBottom",
			"RQEThemeSearchEdgeLeft", "RQEThemeSearchEdgeRight", "RQEThemeSearchGold",
			"RQEThemeQuestBadge", "RQEThemeQuestActiveGlow", "RQEThemeBackgroundPicture",
		}) do
			if owner[key] and owner[key].Hide then owner[key]:Hide() end
		end
		if geometry then
			owner:SetSize(original.width, original.height)
			restorePoints(owner, original.points)
		end
	end

	-------------------------------------------------------
	-- #2e. Native Artwork Stripping & Button Textures
	-------------------------------------------------------

	-- Safely hides an optional region.
	local function hideRegion(region)
		if region and region.Hide then region:Hide() end
	end

	-- Hides Blizzard NineSlice and legacy edge pieces before custom artwork is applied.
	local function stripNineSlice(owner)
		if not owner then return end
		local nine = owner.NineSlice
		if nine then
			if nine.Hide then nine:Hide() end
			for _, key in ipairs({
				"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
				"TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center",
			}) do
				hideRegion(nine[key])
			end
		end
		for _, key in ipairs({ "Left", "Middle", "Right", "Top", "Bottom" }) do
			hideRegion(owner[key])
		end
	end

	-- Removes Blizzard button textures once so themed button art is not obscured.
	function UI:StripBlizzardButton(button)
		if not button or button.RQEThemeBlizzardStripped then return end
		stripNineSlice(button)
		for _, region in ipairs({ button:GetRegions() }) do
			if region and region.GetObjectType and region:GetObjectType() == "Texture" then region:Hide() end
		end
		button.RQEThemeBlizzardStripped = true
	end

	-- Assigns and normalizes one button-state texture, returning the resulting texture region.
	local function setButtonTexture(button, method, path)
		if not button or not button[method] then return end
		button[method](button, path)
		local texture
		if method == "SetNormalTexture" then texture = button:GetNormalTexture()
		elseif method == "SetHighlightTexture" then texture = button:GetHighlightTexture()
		elseif method == "SetPushedTexture" then texture = button:GetPushedTexture()
		elseif method == "SetDisabledTexture" and button.GetDisabledTexture then texture = button:GetDisabledTexture() end
		if texture then
			texture:Show()
			texture:ClearAllPoints()
			texture:SetAllPoints(button)
			if texture.SetTexCoord then texture:SetTexCoord(0, 1, 0, 1) end
		end
		return texture
	end



--------------------------------------------------
-- #3. 🖼️ Panels, Headers & Location Bars
--------------------------------------------------

	-------------------------------------------------------
	-- #3a. Reusable Panel Asset Helpers
	-------------------------------------------------------

	-- Creates or reuses one sliced panel-border texture.
	local function ensurePanelPiece(frame, key)
		if not frame[key] then
			frame[key] = frame:CreateTexture(nil, "ARTWORK", nil, 1)
		end
		frame[key]:SetTexture(UI.Textures.buttonNormal)
		frame[key]:Show()
		return frame[key]
	end

	-- Creates or reuses a solid-color accent line on a themed frame.
	local function ensureColorLine(frame, key, color)
		if not frame[key] then frame[key] = frame:CreateTexture(nil, "ARTWORK", nil, 3) end
		frame[key]:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
		frame[key]:Show()
		return frame[key]
	end

	local FRAME_BORDER_PIECES = {
		"RQEThemeBorderTL", "RQEThemeBorderTR", "RQEThemeBorderBL", "RQEThemeBorderBR",
		"RQEThemeBorderTop", "RQEThemeBorderBottom", "RQEThemeBorderLeft", "RQEThemeBorderRight",
		"RQEThemeAzureTop", "RQEThemeAzureBottom", "RQEThemeAzureLeft", "RQEThemeAzureRight", "RQEThemeGoldTop",
	}
	local HEADER_BORDER_PIECES = {
		"RQEThemeHeaderLeft", "RQEThemeHeaderMiddle", "RQEThemeHeaderRight", "RQEThemeHeaderAccent",
	}
	local function isFrameBorderRole(role)
		return role == "main" or role == "tracker" or role == "section" or role == "focus"
	end
	local function setBorderPieceOpacity(owner, keys, opacity)
		for _, key in ipairs(keys) do
			local piece = owner[key]
			if piece then piece:SetAlpha(opacity) end
		end
	end
	local function setNativeBorderOpacity(owner, opacity)
		local native = UI.Native[owner]
		local color = native and native.borderColor
		if color and owner.SetBackdropBorderColor then
			owner:SetBackdropBorderColor(color[1], color[2], color[3], (color[4] or 1) * opacity)
		end
	end

	-------------------------------------------------------
	-- #3b. Panel Styling & Opacity
	-------------------------------------------------------

	-- Preserve the artwork's aspect ratio as the Helper and Tracker are resized.
	function UI:LayoutBackgroundPicture(frame)
		local picture = frame and frame.RQEThemeBackgroundPicture
		if not picture then return end
		local width = math.max(1, frame:GetWidth() - 12)
		local height = math.max(1, frame:GetHeight() - 12)
		if width > height then
			local inset = (1 - height / width) / 2
			picture:SetTexCoord(0, 1, inset, 1 - inset)
		else
			local inset = (1 - width / height) / 2
			picture:SetTexCoord(inset, 1 - inset, 0, 1)
		end
	end

	function UI:_ApplyBackgroundPicture(frame, role)
		if role ~= "main" and role ~= "tracker" then return end
		local choice = self:IsEnabled() and self:IsBackgroundPictureEnabled()
			and self:GetBackgroundPicture()
		if not choice then
			if frame.RQEThemeBackgroundPicture then frame.RQEThemeBackgroundPicture:Hide() end
			return
		end
		if not frame.RQEThemeBackgroundPicture then
			local picture = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
			picture:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
			picture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
			frame.RQEThemeBackgroundPicture = picture
			frame:HookScript("OnSizeChanged", function(resized)
				UI:LayoutBackgroundPicture(resized)
			end)
		end
		local picture = frame.RQEThemeBackgroundPicture
		picture:SetTexture(choice.texture)
		picture:SetAlpha(self:GetBackgroundPictureOpacity(role))
		self:LayoutBackgroundPicture(frame)
		picture:Show()
	end

	function UI:RefreshBackgroundPictures()
		for _, entry in ipairs(self.Registry.panels) do
			self:_ApplyBackgroundPicture(entry.target, entry.data.role)
		end
	end

	-- Eight independent slices keep every edge visible on resized/scrolling frames.
	function UI:_ApplyPanel(frame, opacity, role, frameBorder)
		if not frame or not frame.SetBackdrop then return end
		stripNineSlice(frame)
		local c = self.Colors
		frame:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
		frame:SetBackdropColor(c.charcoal[1], c.charcoal[2], c.charcoal[3], tonumber(opacity) or 0.76)
		self:_ApplyBackgroundPicture(frame, role)

		local corner = role == "section" and 9 or 13
		local uv1, uv2 = 0.27, 0.73
		local tl = ensurePanelPiece(frame, "RQEThemeBorderTL")
		local tr = ensurePanelPiece(frame, "RQEThemeBorderTR")
		local bl = ensurePanelPiece(frame, "RQEThemeBorderBL")
		local br = ensurePanelPiece(frame, "RQEThemeBorderBR")
		local top = ensurePanelPiece(frame, "RQEThemeBorderTop")
		local bottom = ensurePanelPiece(frame, "RQEThemeBorderBottom")
		local left = ensurePanelPiece(frame, "RQEThemeBorderLeft")
		local right = ensurePanelPiece(frame, "RQEThemeBorderRight")

		tl:SetTexCoord(0, uv1, 0, uv1); tr:SetTexCoord(uv2, 1, 0, uv1)
		bl:SetTexCoord(0, uv1, uv2, 1); br:SetTexCoord(uv2, 1, uv2, 1)
		top:SetTexCoord(uv1, uv2, 0, uv1); bottom:SetTexCoord(uv1, uv2, uv2, 1)
		left:SetTexCoord(0, uv1, uv1, uv2); right:SetTexCoord(uv2, 1, uv1, uv2)

		for _, piece in ipairs({ tl, tr, bl, br }) do piece:SetSize(corner, corner) end
		tl:ClearAllPoints(); tl:SetPoint("TOPLEFT")
		tr:ClearAllPoints(); tr:SetPoint("TOPRIGHT")
		bl:ClearAllPoints(); bl:SetPoint("BOTTOMLEFT")
		br:ClearAllPoints(); br:SetPoint("BOTTOMRIGHT")
		top:ClearAllPoints(); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT"); top:SetHeight(corner)
		bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT"); bottom:SetHeight(corner)
		left:ClearAllPoints(); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); left:SetWidth(corner)
		right:ClearAllPoints(); right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); right:SetWidth(corner)

		-- Exact palette keylines remain crisp even when the ornate bitmap border is
		-- scaled to a user-resized frame.
		local azTop = ensureColorLine(frame, "RQEThemeAzureTop", { c.azure[1], c.azure[2], c.azure[3], 1 })
		local azBottom = ensureColorLine(frame, "RQEThemeAzureBottom", { c.azure[1], c.azure[2], c.azure[3], 1 })
		local azLeft = ensureColorLine(frame, "RQEThemeAzureLeft", { c.azure[1], c.azure[2], c.azure[3], 1 })
		local azRight = ensureColorLine(frame, "RQEThemeAzureRight", { c.azure[1], c.azure[2], c.azure[3], 1 })
		azTop:ClearAllPoints(); azTop:SetPoint("TOPLEFT", 4, -1); azTop:SetPoint("TOPRIGHT", -4, -1); azTop:SetHeight(1)
		azBottom:ClearAllPoints(); azBottom:SetPoint("BOTTOMLEFT", 4, 1); azBottom:SetPoint("BOTTOMRIGHT", -4, 1); azBottom:SetHeight(1)
		azLeft:ClearAllPoints(); azLeft:SetPoint("TOPLEFT", 1, -4); azLeft:SetPoint("BOTTOMLEFT", 1, 4); azLeft:SetWidth(1)
		azRight:ClearAllPoints(); azRight:SetPoint("TOPRIGHT", -1, -4); azRight:SetPoint("BOTTOMRIGHT", -1, 4); azRight:SetWidth(1)
		local gold = ensureColorLine(frame, "RQEThemeGoldTop", { c.gold[1], c.gold[2], c.gold[3], 0.88 })
		gold:ClearAllPoints(); gold:SetPoint("TOPLEFT", corner, -3); gold:SetPoint("TOPRIGHT", -corner, -3); gold:SetHeight(1)
		if frameBorder then setBorderPieceOpacity(frame, FRAME_BORDER_PIECES, self:GetFrameBorderOpacity()) end
		frame.RQEThemeRole = role or "panel"
	end

	-- Captures, registers, and applies themed panel artwork to a frame.
	function UI:StylePanel(frame, opacity, role)
		captureNative(frame)
		remember(self.Registry.panels, frame, { opacity = opacity, role = role })
		if role == "main" or role == "tracker" then
			opacity = self:GetFrameBackgroundOpacity(role)
		end
		if self:IsEnabled() then
			self:_ApplyPanel(frame, opacity, role, isFrameBorderRole(role))
		elseif isFrameBorderRole(role) then
			setNativeBorderOpacity(frame, self:GetFrameBorderOpacity())
		end
	end

	-- Repaint only frame and header border artwork; the frame fill, theme
	-- pictures, title text, action icons, and icon-button surrounds stay intact.
	function UI:RefreshFrameBorderOpacity()
		local opacity = self:GetFrameBorderOpacity()
		for _, entry in ipairs(self.Registry.panels) do
			if isFrameBorderRole(entry.data.role) then
				if self:IsEnabled() then
					setBorderPieceOpacity(entry.target, FRAME_BORDER_PIECES, opacity)
				else
					setNativeBorderOpacity(entry.target, opacity)
				end
			end
		end
		for _, entry in ipairs(self.Registry.headers) do
			if self:IsEnabled() then
				setBorderPieceOpacity(entry.target, HEADER_BORDER_PIECES, opacity)
				if entry.target.RQEThemeHeaderBackground then
					entry.target.RQEThemeHeaderBackground:SetShown(opacity < 1)
				end
			else
				setNativeBorderOpacity(entry.target, opacity)
			end
		end
	end

	-- Updates a registered panel's saved opacity and reapplies it when the theme is enabled.
	function UI:UpdatePanelOpacity()
		if not profileReady() then return end
		for _, entry in ipairs(self.Registry.panels) do
			local opacity
			if entry.data.role == "main" or entry.data.role == "tracker" then
				opacity = self:GetFrameBackgroundOpacity(entry.data.role)
			end
			if opacity and entry.target.SetBackdropColor then
				if self:IsEnabled() then
					local color = self.Colors.charcoal
					entry.target:SetBackdropColor(color[1], color[2], color[3], opacity)
				else
					entry.target:SetBackdropColor(0, 0, 0, opacity)
				end
			end
		end
	end

	-------------------------------------------------------
	-- #3c. Header Styling
	-------------------------------------------------------

	-- Creates or reuses one texture slice used by a themed header.
	local function ensureHeaderSlice(header, key, path, leftUV, rightUV)
		if not header[key] then header[key] = header:CreateTexture(nil, "ARTWORK", nil, 2) end
		header[key]:SetTexture(path)
		header[key]:SetTexCoord(leftUV, rightUV, 0, 1)
		header[key]:Show()
		return header[key]
	end

	-- Applies the active theme's header slices, accent, height, and text treatment.
	function UI:_ApplyHeader(header, child)
		if not header then return end
		stripNineSlice(header)
		if header.SetBackdrop then header:SetBackdrop(nil) end
		if not child and header.SetHeight and header:GetHeight() < 48 then header:SetHeight(48) end
		-- Header textures contain both the trim and a dark fill. Keep an opaque
		-- fill below them as the border artwork is faded.
		if not header.RQEThemeHeaderBackground then
			header.RQEThemeHeaderBackground = header:CreateTexture(nil, "BACKGROUND")
			header.RQEThemeHeaderBackground:SetAllPoints(header)
		end
		header.RQEThemeHeaderBackground:SetColorTexture(
			self.Colors.charcoalRaised[1], self.Colors.charcoalRaised[2], self.Colors.charcoalRaised[3], 0.9)
		header.RQEThemeHeaderBackground:SetShown(self:GetFrameBorderOpacity() < 1)
		-- Rounded main-frame headers; point-ended child/section headers.
		local path = child and self.Textures.header or self.Textures.sectionHeader
		local left = ensureHeaderSlice(header, "RQEThemeHeaderLeft", path, 0, 0.14)
		local middle = ensureHeaderSlice(header, "RQEThemeHeaderMiddle", path, 0.14, 0.86)
		local right = ensureHeaderSlice(header, "RQEThemeHeaderRight", path, 0.86, 1)
		-- The header texture's left point is deliberately mirrored for the far end.  This
		-- keeps the cap visible at every width instead of stretching/cropping the
		-- narrow right-most pixels of the source artwork.
		if child then right:SetTexCoord(0.14, 0, 0, 1) end
		local sideWidth = child and 28 or 20
		left:ClearAllPoints(); left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(sideWidth)
		right:ClearAllPoints(); right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(sideWidth)
		middle:ClearAllPoints(); middle:SetPoint("TOPLEFT", left, "TOPRIGHT"); middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
		local accent = ensureColorLine(header, "RQEThemeHeaderAccent", {
			self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.92,
		})
		accent:ClearAllPoints(); accent:SetPoint("BOTTOMLEFT", sideWidth, 1); accent:SetPoint("BOTTOMRIGHT", -sideWidth, 1); accent:SetHeight(1)
		setBorderPieceOpacity(header, HEADER_BORDER_PIECES, self:GetFrameBorderOpacity())
	end

	-- Captures and registers a header before applying the active theme.
	function UI:StyleHeader(header, child)
		captureNative(header)
		remember(self.Registry.headers, header, { child = child })
		if self:IsEnabled() then
			self:_ApplyHeader(header, child)
		else
			setNativeBorderOpacity(header, self:GetFrameBorderOpacity())
		end
	end

	-------------------------------------------------------
	-- #3d. Location Information Bar Styling & Layout
	-------------------------------------------------------

	-- Applies themed geometry and accents to the legacy location-information bar.
	function UI:_ApplyLegacyLocationInfoBar(bar)
		if not bar then return end
		bar:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		bar:SetBackdropColor(0.04, 0.04, 0.04, 0.86)
		bar:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.8)
		bar:SetHeight(24)
		if bar.MapIDText then
			bar.MapIDText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			bar.MapIDText:SetTextColor(1, 0.82, 0)
		end
		if bar.CoordinatesText then
			bar.CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			bar.CoordinatesText:SetTextColor(1, 1, 1)
		end
		if bar.StepDistanceText then
			bar.StepDistanceText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			bar.StepDistanceText:SetTextColor(1, 0.82, 0)
		end
	end

	-- Applies themed styling through the layout path supported by the current location bar.
	function UI:_ApplyLocationInfoBar(bar)
		if not bar then return end
		stripNineSlice(bar)
		bar:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
		bar:SetBackdropColor(self.Colors.charcoalRaised[1], self.Colors.charcoalRaised[2], self.Colors.charcoalRaised[3], 0.9)
		bar:SetHeight(28)
		local azure = ensureColorLine(bar, "RQEThemeLocationAzure", {
			self.Colors.azureBright[1], self.Colors.azureBright[2], self.Colors.azureBright[3], 0.9,
		})
		azure:ClearAllPoints(); azure:SetPoint("TOPLEFT", 1, -1); azure:SetPoint("TOPRIGHT", -1, -1); azure:SetHeight(1)
		local gold = ensureColorLine(bar, "RQEThemeLocationGold", {
			self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.78,
		})
		gold:ClearAllPoints(); gold:SetPoint("BOTTOMLEFT", 1, 1); gold:SetPoint("BOTTOMRIGHT", -1, 1); gold:SetHeight(1)
		if bar.MapIDText then
			bar.MapIDText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			bar.MapIDText:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
		end
		if bar.CoordinatesText then
			bar.CoordinatesText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			local info = self.Colors.info or { 0.72, 0.9, 1 }
			bar.CoordinatesText:SetTextColor(info[1], info[2], info[3])
		end
		if bar.StepDistanceText then
			bar.StepDistanceText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
			bar.StepDistanceText:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
		end
	end

	-- Captures and registers a location-information bar before styling it.
	function UI:StyleLocationInfoBar(bar)
		self:_ApplyLegacyLocationInfoBar(bar)
		captureNative(bar)
		remember(self.Registry.locationBars, bar)
		if self:IsEnabled() then self:_ApplyLocationInfoBar(bar) end
	end

	-- Reapplies the active theme to the registered location-information bar.
	function UI:RefreshLocationInfoBar()
		-- Location visibility also changes scroll-frame anchors. Do not apply the
		-- selected profile's bar layout ahead of its combat-deferred frame geometry.
		if RQE.ProfileApplyPending and not RQE.ApplyingProfile then return end
		local mainFrame = RQE.RQEFrame or RQEFrame or _G["RQE.RQEFrame"]
		local bar = RQE.LocationInfoBar
		if not (mainFrame and RQE.ScrollFrame) then return end
		local profile = RQE.db and RQE.db.profile
		local showMap = profile and profile.showMapID == true
		local showCoordinates = profile and profile.showCoordinates == true
		local showBar = bar and (showMap or showCoordinates)
		local themed = self:IsEnabled()
		local layoutKey = table.concat({ themed and "theme" or "legacy", showMap and "map" or "", showCoordinates and "coords" or "" }, ":")
		if bar and bar.RQELocationLayoutKey == layoutKey then return end
		if bar then bar.RQELocationLayoutKey = layoutKey end

		if bar then
			bar:ClearAllPoints()
			if themed then
				bar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -50)
				bar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -20, -50)
				bar:SetHeight(28)
			else
				bar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -32)
				bar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -30, -32)
				bar:SetHeight(24)
			end
			if bar.MapIDText then bar.MapIDText:SetShown(showMap) end
			if bar.CoordinatesText then bar.CoordinatesText:SetShown(showCoordinates) end
			if bar.StepDistanceText then bar.StepDistanceText:SetShown(showCoordinates) end
			bar:SetShown(showBar)
		end

		RQE.ScrollFrame:ClearAllPoints()
		local topOffset
		if themed then topOffset = showBar and -84 or -52
		else topOffset = showBar and -62 or -40 end
		RQE.ScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, topOffset)
		RQE.ScrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", themed and -20 or -30, 10)
		if RQE.slider then
			RQE.slider:ClearAllPoints()
			RQE.slider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -7, topOffset)
			RQE.slider:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -7, 14)
			if RQE.UpdateQuestHelperScrollbarVisual then
				RQE.UpdateQuestHelperScrollbarVisual(RQE.content and RQE.content:GetHeight())
			end
		end
	end



--------------------------------------------------
-- #4. 🎨 Buttons & Input Controls
--------------------------------------------------

	-------------------------------------------------------
	-- #4a. Icon Buttons & Optical Alignment
	-------------------------------------------------------

	-- The generated icon canvases do not all have balanced transparent margins.
	-- These small optical corrections center the visible symbols, rather than
	-- merely centering each full 64x64 source canvas inside its button.
	local ICON_OPTICAL_OFFSETS = {
		Clear = { 0, 3 },
		RemoveWaypoint = { -1, 3 },
		Search = { 0, 3 },
		Contribution = { 1, 4 },
		Completed = { -1, 1 },
		HideCompleted = { -1, 1 },
		Zone = { 0, -1 },
		Filter = { 1, 1 },
		Collapse = { -1, 1 },
		Expand = { 0, 0 },
		Close = { -1, 1 },
		WaypointTarget = { -2, 3 },
		SearchGroup = { 0, 2 },
	}
	local THEME_ICON_OPTICAL_OFFSETS = {
		AstralCartographer = {
			ShowAll = { -2, 0 },
			WaypointTarget = { 0, 3 },
			Waypoint = { -2, -3 },
		},
		RoundTable = {
			RemoveWaypoint = { -3, 3 },
			Contribution = { -1, 3 },
			Close = { -1, 0 },
			Waypoint = { -1, -2 },
			Filter = { -1, 0 },
		},
		ScarletCrusade = {
			RemoveWaypoint = { -3, 3 },
			Contribution = { -1, 3 },
			Close = { -1, 0 },
			Waypoint = { -1, -2 },
			Filter = { -1, 0 },
		},
	}
	-- The Astral tracker shortcuts carry bright artwork to the edge of their
	-- source canvases. Keep a dark gap between that artwork and the button rim;
	-- additive blending preserves the small glyph details inside the inset.
	local ASTRAL_TRACKER_ICON_INSET = {
		ShowAll = 3, Completed = 3,
		HideCompleted = 3, Zone = 3, Filter = 3,
	}
	-- Crop only the tracker-header rendering of the existing 64px assets. This
	-- emphasizes each action symbol without changing the full artwork elsewhere.
	local ASTRAL_TRACKER_ICON_CROP = {
		ShowAll = { 18, 10, 48, 56 },
		Completed = { 17, 10, 50, 54 },
		HideCompleted = { 5, 5, 60, 54 },
		Zone = { 10, 3, 55, 59 },
		Filter = { 9, 8, 57, 56 },
	}
	local BUTTON_BORDER_TARGET_KEYS = {
		-- Quest Helper header controls.
		"ClearButton", "RWButton", "SearchButton", "RQEContributionButton",
		"ContributionWaypointButton", "PrevStepButton", "NextStepButton",
		"HeaderWaypointBackButton", "HeaderWaypointForwardButton", "CloseButton",
		-- Quest Tracker header controls.
		"CQButton", "SCButton", "HQButton", "ZQButton", "QTQuestFilterButton",
		"QTQuestMaximizeButton", "QTQuestMinimizeButton", "QTQuestCloseButton",
		-- Quest Helper content controls marked W, SG, and *.
		"UnknownQuestButton", "SearchGroupButton", "SeparateWaypointButton",
	}

	local function isButtonBorderOpacityTarget(button)
		if button.RQEThemeBorderOpacityTarget then return true end
		for _, key in ipairs(BUTTON_BORDER_TARGET_KEYS) do
			if RQE[key] == button then return true end
		end
		return false
	end

	-- Button state textures can stay shown after SetHighlightTexture/SetPushedTexture.
	-- Drive their alpha from mouse state so they never reveal a square at rest.
	function UI:_UpdateIconBorderHover(button, hovering)
		if not self:IsEnabled() or not button or not isButtonBorderOpacityTarget(button) then return end
		if hovering == nil then hovering = button.IsMouseOver and button:IsMouseOver() end
		local pressed = hovering and button.RQEThemeBorderPressed
		local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
		local pushed = button.GetPushedTexture and button:GetPushedTexture()
		if highlight then highlight:SetAlpha(hovering and not pressed and 1 or 0) end
		if pushed then pushed:SetAlpha(pressed and 1 or 0) end
	end

	-- Only the resting and disabled surrounds follow the slider. Hover and
	-- pressed states show their full themed glow, then return to the saved level.
	function UI:_ApplyIconBorderOpacity(button)
		if not self:IsEnabled() or not button or not isButtonBorderOpacityTarget(button) then return end
		local opacity = self:GetButtonBorderOpacity()
		for _, getter in ipairs({ "GetNormalTexture", "GetDisabledTexture" }) do
			local texture = button[getter] and button[getter](button)
			if texture then texture:SetAlpha(opacity) end
		end
		if not button.RQEThemeBorderHoverHooks then
			button:HookScript("OnEnter", function(owner) self:_UpdateIconBorderHover(owner, true) end)
			button:HookScript("OnLeave", function(owner)
				owner.RQEThemeBorderPressed = nil
				self:_UpdateIconBorderHover(owner, false)
			end)
			button:HookScript("OnMouseDown", function(owner)
				owner.RQEThemeBorderPressed = true
				self:_UpdateIconBorderHover(owner, true)
			end)
			button:HookScript("OnMouseUp", function(owner)
				owner.RQEThemeBorderPressed = nil
				self:_UpdateIconBorderHover(owner)
			end)
			button.RQEThemeBorderHoverHooks = true
		end
		self:_UpdateIconBorderHover(button)
	end

	function UI:_ApplyQuestBadgeBorderOpacity(button)
		if not self:IsEnabled() or not button or not button.RQEThemeQuestKind then return end
		local opacity = button.RQEThemeQuestSupertracked and 1 or self:GetButtonBorderOpacity()
		if button.bg then button.bg:SetAlpha(opacity) end
		if button.RQEThemeQuestActiveGlow then button.RQEThemeQuestActiveGlow:SetAlpha(1) end
		local hover = button.GetHighlightTexture and button:GetHighlightTexture()
		if hover then hover:SetAlpha(1) end
	end

	function UI:RefreshButtonBorderOpacity()
		if not self:IsEnabled() then return end
		for _, entry in ipairs(self.Registry.iconButtons) do
			self:_ApplyIconBorderOpacity(entry.target)
		end
		for _, entry in ipairs(self.Registry.legacyButtons) do
			self:_ApplyIconBorderOpacity(entry.target)
		end
		for _, entry in ipairs(self.Registry.questIndexButtons) do
			self:_ApplyQuestBadgeBorderOpacity(entry.target)
		end
	end

	-- Applies themed state textures, icon artwork, and sizing to an icon button.
	function UI:_ApplyIconButton(button, iconName, options)
		if not button then return end
		options = options or {}
		self:StripBlizzardButton(button)
		local size = tonumber(options.size) or 25
		local inset = tonumber(options.iconInset) or 2
		local iconSize = math.max(1, size - (inset * 2))
		local trackerInset = self.ActiveTheme == "AstralCartographer"
			and ASTRAL_TRACKER_ICON_INSET[iconName]
		if trackerInset then iconSize = math.max(1, size - (trackerInset * 2)) end
		local themeOffsets = (self.Themes[self.ActiveTheme] and self.Themes[self.ActiveTheme].iconOffsets)
			or THEME_ICON_OPTICAL_OFFSETS[self.ActiveTheme]
		local opticalOffset = (themeOffsets and themeOffsets[iconName]) or ICON_OPTICAL_OFFSETS[iconName]
		local offsetX = opticalOffset and opticalOffset[1] or 0
		local offsetY = opticalOffset and opticalOffset[2] or 0
		-- The W control shares WaypointTarget art with the header shortcut, but
		-- only its glyph needs a rightward correction with the heraldic icons.
		if button == RQE.UnknownQuestButton then
			local theme = self.Themes[self.ActiveTheme]
			offsetX = offsetX + (theme and theme.focusWaypointOffsetX or 0)
		end
		button:SetSize(size, size)
		if options.focusInset and button.GetParent then
			button:ClearAllPoints()
			-- Keep the complete control inside the focus panel and clear of both its
			-- left and top borders; the focus text uses the matching inner gutter.
			button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", 10, -6)
		end
		button:SetText("")
		setButtonTexture(button, "SetNormalTexture", self.Textures.buttonNormal)
		setButtonTexture(button, "SetHighlightTexture", self.Textures.buttonHover)
		setButtonTexture(button, "SetPushedTexture", self.Textures.buttonPressed)
		setButtonTexture(button, "SetDisabledTexture", self.Textures.buttonDisabled)
		if not button.RQEThemeIcon then button.RQEThemeIcon = button:CreateTexture(nil, "ARTWORK", nil, 6) end
		button.RQEThemeIcon:ClearAllPoints()
		button.RQEThemeIcon:SetSize(iconSize, iconSize)
		button.RQEThemeIcon:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
		button.RQEThemeIcon:SetTexture(self:GetIconTexture(iconName))
		local iconCrop = trackerInset and ASTRAL_TRACKER_ICON_CROP[iconName]
		if iconCrop then
			button.RQEThemeIcon:SetTexCoord(iconCrop[1] / 64, iconCrop[3] / 64,
				iconCrop[2] / 64, iconCrop[4] / 64)
		else
			button.RQEThemeIcon:SetTexCoord(0, 1, 0, 1)
		end
		-- The first two Astral tracker glyphs include a bright scroll rim in the
		-- source art. Normal blending keeps that rim from masking slider changes.
		local additiveIcon = trackerInset and iconName ~= "ShowAll" and iconName ~= "Completed"
		button.RQEThemeIcon:SetBlendMode(additiveIcon and "ADD" or "BLEND")
		button.RQEThemeIcon:Show()
		if not button.RQEThemeStateHooks then
			button:HookScript("OnDisable", function(owner)
				if owner.RQEThemeIcon and owner.RQEThemeIcon.SetDesaturated then owner.RQEThemeIcon:SetDesaturated(true) end
				if owner.RQEThemeIcon then owner.RQEThemeIcon:SetAlpha(0.45) end
			end)
			button:HookScript("OnEnable", function(owner)
				if owner.RQEThemeIcon and owner.RQEThemeIcon.SetDesaturated then owner.RQEThemeIcon:SetDesaturated(false) end
				if owner.RQEThemeIcon then owner.RQEThemeIcon:SetAlpha(1) end
			end)
			button.RQEThemeStateHooks = true
		end
		button.RQEThemeIcon:SetAlpha(button.IsEnabled and button:IsEnabled() and 1 or 0.45)
		button.RQEThemeIconName = iconName
		self:_ApplyIconBorderOpacity(button)
	end

	-- Captures and registers an icon button before applying the requested themed icon.
	function UI:StyleIconButton(button, iconName, options)
		captureNative(button)
		remember(self.Registry.iconButtons, button, { iconName = iconName, options = options or {} })
		if self:IsEnabled() then self:_ApplyIconButton(button, iconName, options) end
	end

	-------------------------------------------------------
	-- #4b. Text Button Styling
	-------------------------------------------------------

	-- Applies themed state textures and font colors to a text button.
	function UI:_ApplyTextButton(button, options)
		if not button then return end
		self:StripBlizzardButton(button)
		local normal = setButtonTexture(button, "SetNormalTexture", self.Textures.buttonWide)
		local highlight = setButtonTexture(button, "SetHighlightTexture", self.Textures.buttonWide)
		local pushed = setButtonTexture(button, "SetPushedTexture", self.Textures.buttonWide)
		local disabled = setButtonTexture(button, "SetDisabledTexture", self.Textures.buttonWide)
		if normal then normal:SetVertexColor(1, 1, 1, 1) end
		if highlight then highlight:SetVertexColor(self.Colors.azureBright[1], self.Colors.azureBright[2], self.Colors.azureBright[3], 1) end
		if pushed then pushed:SetVertexColor(self.Colors.muted[1], self.Colors.muted[2], self.Colors.muted[3], 1) end
		if disabled then disabled:SetVertexColor(0.34, 0.37, 0.43, 0.72) end
		if button.SetNormalFontObject then button:SetNormalFontObject("GameFontNormal") end
		if button.SetHighlightFontObject then button:SetHighlightFontObject("GameFontHighlight") end
		local font = button.GetFontString and button:GetFontString()
		if font then font:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3]) end
		if options and options.trackerAction then
			-- The wide button texture leaves large transparent margins for larger buttons. Crop
			-- those margins only on these compact controls so the themed border
			-- surrounds the label with visible padding in every button state.
			for _, texture in ipairs({ normal, highlight, pushed, disabled }) do
				if texture then texture:SetTexCoord(0.16, 0.88, 0.03, 0.94) end
			end
		end
	end

	-- Captures and registers a text button before applying themed presentation.
	function UI:StyleTextButton(button, options)
		captureNative(button)
		remember(self.Registry.textButtons, button, options or {})
		if self:IsEnabled() then self:_ApplyTextButton(button, options) end
	end

	-------------------------------------------------------
	-- #4c. Search Box Styling
	-------------------------------------------------------

	-- Replaces native search-box artwork with the active theme's sliced border and accents.
	function UI:_ApplySearchBox(editBox)
		if not editBox then return end
		stripNineSlice(editBox)
		if editBox.CreateTexture then
			if not editBox.RQEThemeSearchBackground then
				editBox.RQEThemeSearchBackground = editBox:CreateTexture(nil, "BACKGROUND", nil, -2)
			end
			editBox.RQEThemeSearchBackground:SetColorTexture(self.Colors.charcoal[1], self.Colors.charcoal[2], self.Colors.charcoal[3], 0.94)
			editBox.RQEThemeSearchBackground:SetAllPoints(editBox)
			editBox.RQEThemeSearchBackground:Show()

			-- Creates or reuses one sliced texture used by the themed search-box border.
			local function searchPiece(key)
				if not editBox[key] then editBox[key] = editBox:CreateTexture(nil, "ARTWORK", nil, 2) end
				editBox[key]:SetTexture(self.Textures.buttonNormal)
				editBox[key]:Show()
				return editBox[key]
			end
			local corner, uv1, uv2 = 7, 0.27, 0.73
			local tl = searchPiece("RQEThemeSearchTL")
			local tr = searchPiece("RQEThemeSearchTR")
			local bl = searchPiece("RQEThemeSearchBL")
			local br = searchPiece("RQEThemeSearchBR")
			local top = searchPiece("RQEThemeSearchEdgeTop")
			local bottom = searchPiece("RQEThemeSearchEdgeBottom")
			local left = searchPiece("RQEThemeSearchEdgeLeft")
			local right = searchPiece("RQEThemeSearchEdgeRight")
			tl:SetTexCoord(0, uv1, 0, uv1); tr:SetTexCoord(uv2, 1, 0, uv1)
			bl:SetTexCoord(0, uv1, uv2, 1); br:SetTexCoord(uv2, 1, uv2, 1)
			top:SetTexCoord(uv1, uv2, 0, uv1); bottom:SetTexCoord(uv1, uv2, uv2, 1)
			left:SetTexCoord(0, uv1, uv1, uv2); right:SetTexCoord(uv2, 1, uv1, uv2)
			for _, piece in ipairs({ tl, tr, bl, br }) do piece:SetSize(corner, corner) end
			tl:ClearAllPoints(); tl:SetPoint("TOPLEFT")
			tr:ClearAllPoints(); tr:SetPoint("TOPRIGHT")
			bl:ClearAllPoints(); bl:SetPoint("BOTTOMLEFT")
			br:ClearAllPoints(); br:SetPoint("BOTTOMRIGHT")
			top:ClearAllPoints(); top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr, "TOPLEFT"); top:SetHeight(corner)
			bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT"); bottom:SetHeight(corner)
			left:ClearAllPoints(); left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT"); left:SetWidth(corner)
			right:ClearAllPoints(); right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT"); right:SetWidth(corner)

			-- A restrained inner gold line ties fields to the other controls without
			-- returning to the plain blue rectangle this replaces.
			local gold = ensureColorLine(editBox, "RQEThemeSearchGold", {
				self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3], 0.72,
			})
			gold:ClearAllPoints(); gold:SetPoint("BOTTOMLEFT", corner, 2); gold:SetPoint("BOTTOMRIGHT", -corner, 2); gold:SetHeight(1)
			for _, key in ipairs({ "RQEThemeSearchTop", "RQEThemeSearchBottom", "RQEThemeSearchLeft", "RQEThemeSearchRight" }) do
				hideRegion(editBox[key])
			end
		end
		if editBox.SetBackdrop then
			editBox:SetBackdrop({ bgFile = WHITE, edgeFile = nil, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
			editBox:SetBackdropColor(self.Colors.charcoal[1], self.Colors.charcoal[2], self.Colors.charcoal[3], 0.94)
		end
	end

	-- Captures and registers an edit box before applying themed search-field presentation.
	function UI:StyleSearchBox(editBox)
		captureNative(editBox)
		remember(self.Registry.searchBoxes, editBox)
		if self:IsEnabled() then self:_ApplySearchBox(editBox) end
	end

	-------------------------------------------------------
	-- #4d. Legacy Action Button Styling
	-------------------------------------------------------

	-- Converts a legacy compound action control into a themed icon button while preserving native state.
	function UI:StyleLegacyActionButton(button, background, label, iconName, options)
		options = options or { size = 30, iconInset = 2 }
		captureNative(button)
		if background then captureNative(background) end
		if label then captureNative(label) end
		remember(self.Registry.legacyButtons, button, {
			background = background, label = label, iconName = iconName, options = options,
		})
		if not self:IsEnabled() then return end
		hideRegion(background); hideRegion(label)
		self:_ApplyIconButton(button, iconName, options)
	end

	-------------------------------------------------------
	-- #4e. Quest Index Badges
	-------------------------------------------------------

	local QUEST_BADGE_ICON = {
		Campaign = "QuestCampaign",
		World = "QuestWorld",
		Daily = "QuestDaily",
		Bonus = "QuestBonus",
		Normal = "QuestNormal",
	}

	-- QuestWorld already has the approved visual footprint. The other source
	-- images contain progressively larger transparent margins, so their texture
	-- boxes are enlarged independently while all row button frames remain 35x35.
	-- Artwork-specific optical offsets can adjust the glyph without moving its
	-- quest-row button or affecting the other badge types.
	local QUEST_BADGE_SIZE = {
		Campaign = { 35, 31 },
		World = { 27, 27 },
		Daily = { 31, 31 },
		Bonus = { 31, 31 },
		Normal = { 33, 31 },
	}
	local QUEST_BADGE_VERTICAL_OFFSETS = {
		AstralCartographer = { Campaign = -2 },
		RoundTable = { Campaign = -2 },
		ScarletCrusade = { Campaign = -2 },
	}

	-- Applies the proper quest-type badge, active glow, or numeric presentation to a tracker index button.
	function UI:StyleQuestIndexButton(button, active, questKind)
		if not button then return end
		captureNative(button)
		remember(self.Registry.questIndexButtons, button)
		if not self:IsEnabled() then return end
		local iconName = questKind and QUEST_BADGE_ICON[questKind]
		button.RQEThemeQuestKind = iconName and true or nil
		button.RQEThemeQuestSupertracked = iconName and active == true or nil
		local bg = button.bg
		if bg then
			-- Quest rows reproduce the normal-plus-additive-highlight composition used
			-- by an actually hovered themed button. Generic numbered waypoint buttons
			-- retain their existing background swap behavior.
			bg:SetTexture(iconName and self.Textures.buttonNormal
				or (active and self.Textures.buttonHover or self.Textures.buttonNormal))
			bg:SetTexCoord(0, 1, 0, 1)
			bg:SetAllPoints(button)
			bg:Show()
		end
		if iconName then
			local hover = setButtonTexture(button, "SetHighlightTexture", self.Textures.buttonHover)
			if hover then hover:SetBlendMode("ADD"); hover:SetAlpha(1) end
			if not button.RQEThemeQuestActiveGlow then
				button.RQEThemeQuestActiveGlow = button:CreateTexture(nil, "OVERLAY", nil, 7)
				button.RQEThemeQuestActiveGlow:SetBlendMode("ADD")
			end
			button.RQEThemeQuestActiveGlow:ClearAllPoints()
			button.RQEThemeQuestActiveGlow:SetAllPoints(button)
			button.RQEThemeQuestActiveGlow:SetTexture(self.Textures.buttonHover)
			button.RQEThemeQuestActiveGlow:SetTexCoord(0, 1, 0, 1)
			button.RQEThemeQuestActiveGlow:SetAlpha(1)
			button.RQEThemeQuestActiveGlow:SetShown(active == true)
			if not button.RQEThemeQuestBadge then
				button.RQEThemeQuestBadge = button:CreateTexture(nil, "ARTWORK", nil, 6)
			end
			local badgeSize = QUEST_BADGE_SIZE[questKind] or QUEST_BADGE_SIZE.World
			local themeBadgeOffsets = (self.Themes[self.ActiveTheme] and self.Themes[self.ActiveTheme].questBadgeOffsets)
				or QUEST_BADGE_VERTICAL_OFFSETS[self.ActiveTheme]
			local badgeOffsetY = themeBadgeOffsets and themeBadgeOffsets[questKind] or 0
			button.RQEThemeQuestBadge:ClearAllPoints()
			button.RQEThemeQuestBadge:SetPoint("CENTER", button, "CENTER", 0, badgeOffsetY)
			button.RQEThemeQuestBadge:SetSize(badgeSize[1], badgeSize[2])
			button.RQEThemeQuestBadge:SetTexture(self:GetIconTexture(iconName))
			button.RQEThemeQuestBadge:Show()
			if button.number then button.number:Hide() end
		else
			if button.RQEThemeQuestActiveGlow then button.RQEThemeQuestActiveGlow:Hide() end
			if button.RQEThemeQuestBadge then button.RQEThemeQuestBadge:Hide() end
			if button.number then
				button.number:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3])
				button.number:Show()
			end
		end
		if iconName then self:_ApplyQuestBadgeBorderOpacity(button) end
	end

	-------------------------------------------------------
	-- #4f. Magic Button Action Icons
	-------------------------------------------------------

	local ACTION_ICON_BY_ITEM = {
		[841] = "PullTimer", [2554] = "TurnIn", [4588] = "Kill", [4787] = "Loot",
		[5061] = "Purchase", [5830] = "Interact", [23784] = "TrackerTurnIn", [2058] = "TrackerTurnIn",
		[28372] = "Look", [11753] = "Look", [28885] = "Emote", [206995] = "Emote",
		[28912] = "Learn", [21561] = "Learn", [45786] = "Settings", [20337] = "Settings",
		[67097] = "CancelAura", [54068] = "CancelAura", [118474] = "Follow", [7270] = "Follow",
		[143680] = "Weaken", [3081] = "Weaken", [153541] = "PickupQuest", [1165] = "PickupQuest",
		[30817] = "Purchase", [4382] = "Purchase",
	}

	-- Chooses and positions themed Magic Button artwork from the active macro action.
	function UI:UpdateMagicButtonActionIcon(button, macroBody)
		if not button then return end
		if not button.RQEThemeActionIcon then
			button.RQEThemeActionIcon = button:CreateTexture(nil, "ARTWORK", nil, 7)
			button.RQEThemeActionIcon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
			button.RQEThemeActionIcon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
		end
		if not self:IsEnabled() then
			button.RQEThemeActionIcon:Hide()
			if button.RQEThemeMagicBackdrop then button.RQEThemeMagicBackdrop:Hide() end
			if button.RQENativeMagicSize then
				button:SetSize(unpack(button.RQENativeMagicSize))
				button.RQEThemeMagicSized = nil
			end
			return
		end
		-- Theme sizing and the surround are installed once during profile startup,
		-- avoiding protected geometry changes when a macro updates in combat later.
		if not button.RQEThemeMagicSized then
			if not button.RQENativeMagicSize then button.RQENativeMagicSize = { button:GetSize() } end
			button:SetSize(38, 38)
			button:SetFrameLevel(math.max(1, button:GetFrameLevel()))
			button.RQEThemeMagicSized = true
		end
		if not button.RQEThemeMagicBackdrop then
			button.RQEThemeMagicBackdrop = CreateFrame("Frame", nil, button:GetParent(), "BackdropTemplate")
			button.RQEThemeMagicBackdrop:SetFrameStrata(button:GetFrameStrata())
			button.RQEThemeMagicBackdrop:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
			button.RQEThemeMagicBackdrop:EnableMouse(false)
			button.RQEThemeMagicBackdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
			button.RQEThemeMagicBackdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
			-- Keep transparent action artwork readable against bright world scenes
			-- without making the detached Magic Button surround fully opaque.
			self:_ApplyPanel(button.RQEThemeMagicBackdrop, 0.68, "section")
			button:HookScript("OnShow", function(owner)
				if UI:IsEnabled() and owner.RQEThemeMagicBackdrop then owner.RQEThemeMagicBackdrop:Show() end
			end)
			button:HookScript("OnHide", function(owner)
				if owner.RQEThemeMagicBackdrop then owner.RQEThemeMagicBackdrop:Hide() end
			end)
		end
		button.RQEThemeMagicBackdrop:SetShown(button:IsShown())
		local itemID = tonumber(tostring(macroBody or ""):match("#showtooltip%s+item:(%d+)"))
		local iconName = itemID and ACTION_ICON_BY_ITEM[itemID]
		if iconName then
			-- Replace the macro's Blizzard icon for mapped exception actions.  Using
			-- the button's own normal/highlight textures prevents the stock icon (and
			-- its highlight copy) from covering a small overlay while preserving the
			-- secure button, macro attributes, clicks, and tooltip scripts unchanged.
			local path = self:GetIconTexture(iconName)
			local normal = setButtonTexture(button, "SetNormalTexture", path)
			local highlight = setButtonTexture(button, "SetHighlightTexture", path)
			-- Generated action art is optically weighted toward its lower handles and
			-- accents. Shift both states upward three pixels so the visible symbol,
			-- rather than only its transparent canvas, is centered in the mount.
			local function centerActionTexture(texture)
				if not texture then return end
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 3)
				texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 3)
			end
			centerActionTexture(normal)
			centerActionTexture(highlight)
			if highlight then highlight:SetBlendMode("ADD"); highlight:SetAlpha(0.35) end
			button.RQEThemeActionIcon:Hide()
			button.RQEThemeUsesActionTexture = true
		else
			-- Blizzard item art fills its square more aggressively than the custom
			-- transparent action symbols. Keep the secure/native icon, but give it a
			-- small visual inset so use-item macros match the themed action scale.
			for _, texture in ipairs({ button:GetNormalTexture(), button:GetHighlightTexture() }) do
				if texture then
					texture:ClearAllPoints()
					texture:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
					texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
				end
			end
			button.RQEThemeActionIcon:Hide()
			button.RQEThemeUsesActionTexture = nil
		end
	end



--------------------------------------------------
-- #5. 📐 Frame & Configuration Layout
--------------------------------------------------

	-------------------------------------------------------
	-- #5a. Quest Helper & Tracker Frame Layout
	-------------------------------------------------------

	-- Applies theme-specific Quest Helper and Tracker geometry to registered layout targets.
	function UI:_ApplyFrameLayout()
		self.LayoutTargets = self.LayoutTargets or {}
		for _, target in ipairs({
			RQE.QuestNameText, RQE.headerText, RQE.QuestTrackerHeaderText,
			RQE.QuestTrackerSearchRow, RQE.QuestTrackerSearchInput,
			RQE.QuestTrackerSearchButton, RQE.QuestTrackerRestoreButton,
			RQE.QTScrollFrame, RQE.QMQTslider, RQE.SeparateFocusSlider,
		}) do
			if target and not self.Native[target] then
				captureNative(target)
				self.LayoutTargets[#self.LayoutTargets + 1] = target
			end
		end
		-- The themed buttons keep their established size; the header grows around
		-- them and the end groups move inside the ornate border/keylines.
		local mainFrame = RQE.RQEFrame or RQEFrame or _G["RQE.RQEFrame"]
		if RQE.RQEFrameHeader then RQE.RQEFrameHeader:SetHeight(48) end
		if RQE.ClearButton and mainFrame then
			RQE.ClearButton:ClearAllPoints()
			RQE.ClearButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -9)
		end
		if RQE.CloseButton and mainFrame then
			RQE.CloseButton:ClearAllPoints()
			RQE.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -14, -9)
		end
		if RQE.QuestNameText and RQE.QuestIDText then
			-- Lower every themed quest-name row equally so quests with and without the
			-- SG control retain one baseline. Legacy construction keeps its original
			-- -8 offset because this layout pass runs only for Azure & Gold.
			RQE.QuestNameText:ClearAllPoints()
			RQE.QuestNameText:SetPoint("TOPLEFT", RQE.QuestIDText, "BOTTOMLEFT", 0, -12)
		end
		self:RefreshLocationInfoBar()
		if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end
		if RQE.UpdateContentSize then RQE:UpdateContentSize() end
		if RQE.SeparateFocusSlider and RQE.SeparateFocusFrame then
			RQE.SeparateFocusSlider:ClearAllPoints()
			RQE.SeparateFocusSlider:SetPoint("TOPRIGHT", RQE.SeparateFocusFrame, "TOPRIGHT", -6, -9)
			RQE.SeparateFocusSlider:SetPoint("BOTTOMRIGHT", RQE.SeparateFocusFrame, "BOTTOMRIGHT", -6, 10)
			if RQE.UpdateSeparateContentHeight then RQE.UpdateSeparateContentHeight() end
		end

		if RQE.RQEQuestFrameHeader then RQE.RQEQuestFrameHeader:SetHeight(48) end
		if RQE.CQButton and RQE.RQEQuestFrame then
			RQE.CQButton:ClearAllPoints()
			RQE.CQButton:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 14, -9)
		end
		if RQE.QTQuestCloseButton and RQE.RQEQuestFrame then
			RQE.QTQuestCloseButton:ClearAllPoints()
			RQE.QTQuestCloseButton:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -14, -9)
		end
		if RQE.QuestTrackerSearchRow and RQE.RQEQuestFrame then
			RQE.QuestTrackerSearchRow:ClearAllPoints()
			RQE.QuestTrackerSearchRow:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 12, -54)
			RQE.QuestTrackerSearchRow:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -30, -54)
			RQE.QuestTrackerSearchRow:SetHeight(32)
		end
		if RQE.QuestTrackerSearchInput then RQE.QuestTrackerSearchInput:SetHeight(28) end
		if RQE.QuestTrackerSearchButton then RQE.QuestTrackerSearchButton:SetHeight(30) end
		if RQE.QuestTrackerRestoreButton then RQE.QuestTrackerRestoreButton:SetHeight(30) end
		if RQE.QTScrollFrame and RQE.RQEQuestFrame then
			RQE.QTScrollFrame:ClearAllPoints()
			-- The viewport remains frameWidth - 40, matching AdjustQuestItemWidths,
			-- but equal outer gutters keep every resizable child section centered.
			RQE.QTScrollFrame:SetPoint("TOPLEFT", RQE.RQEQuestFrame, "TOPLEFT", 20, -90)
			RQE.QTScrollFrame:SetPoint("BOTTOMRIGHT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -20, 10)
		end
		if RQE.QMQTslider and RQE.RQEQuestFrame then
			RQE.QMQTslider:ClearAllPoints()
			RQE.QMQTslider:SetPoint("TOPRIGHT", RQE.RQEQuestFrame, "TOPRIGHT", -7, -90)
			RQE.QMQTslider:SetPoint("BOTTOMRIGHT", RQE.RQEQuestFrame, "BOTTOMRIGHT", -7, 14)
			if RQE.UpdateQuestTrackerScrollbarVisual then
				RQE.UpdateQuestTrackerScrollbarVisual(RQE.QTcontent and RQE.QTcontent:GetHeight())
			end
		end
		if AdjustQuestItemWidths and RQE.RQEQuestFrame then
			AdjustQuestItemWidths(RQE.RQEQuestFrame:GetWidth())
		end
	end

	-------------------------------------------------------
	-- #5b. AceGUI Configuration Frame Styling
	-------------------------------------------------------

	-- Applies themed panel, title, and control styling to an AceGUI configuration frame.
	function UI:_ApplyAceFrame(widget)
		if not widget or not widget.frame then return end
		self:_ApplyPanel(widget.frame, 0.94, "search")
		-- AceGUI exposes the center title texture but not its stock side caps or
		-- Close/status buttons. Replace the center art and discover those controls
		-- by type instead of relying on private field names.
		for _, region in ipairs({ widget.frame:GetRegions() }) do
			if region ~= widget.titlebg and region.GetObjectType
				and region:GetObjectType() == "Texture" and region.GetTexture
				and region:GetTexture() == 131080 then region:Hide() end
		end
		if widget.titlebg then
			widget.titlebg:SetTexture(self.Textures.sectionHeader)
			widget.titlebg:SetTexCoord(0, 1, 0, 1)
			widget.titlebg:SetWidth(math.max(widget.titlebg:GetWidth() or 0, 180))
			widget.titlebg:SetHeight(38)
		end
		for _, child in ipairs({ widget.frame:GetChildren() }) do
			if child.GetObjectType and child:GetObjectType() == "Button" and child.obj == widget then
				if child.GetText and child:GetText() and child:GetText() ~= "" then self:_ApplyTextButton(child)
				else self:_ApplySearchBox(child) end
			end
		end
		if widget.titletext then widget.titletext:SetTextColor(self.Colors.gold[1], self.Colors.gold[2], self.Colors.gold[3]) end
	end

	-- Registers an AceGUI frame and routes it through permanent configuration styling.
	function UI:StyleAceFrame(widget)
		remember(self.Registry.aceFrames, widget)
		self:ApplyConfigFrame(widget)
	end

	-- Applies the fixed Azure and Gold configuration palette without changing the selected tracker theme.
	function UI:ApplyConfigFrame(widget)
		-- Configuration chrome is permanently Azure & Gold, regardless of the
		-- tracker selection. The temporary palette change does not touch the tracker.
		local colors, textures = self.Colors, self.Textures
		self.Colors, self.Textures = self.Themes.AzureGold.colors, self.Themes.AzureGold.textures
		self:_ApplyAceFrame(widget)
		self.Colors, self.Textures = colors, textures
	end

	-------------------------------------------------------
	-- #5c. Contribution & External Controls
	-------------------------------------------------------

	-- Applies the dedicated Contribution icon styling to its launcher button.
	function UI:StyleContributionButton(button)
		self:StyleIconButton(button, "Contribution")
	end

	-- Refreshes Contribution and other externally managed buttons after a theme change.
	function UI:RefreshExternalButtons()
		if RQE.ContributeButton then self:StyleContributionButton(RQE.ContributeButton) end
		if RQE.Buttons and RQE.Buttons.RefreshContributionButton then RQE.Buttons.RefreshContributionButton() end
	end



--------------------------------------------------
-- #6. 🔄 Theme Selection & Lifecycle
--------------------------------------------------

	-------------------------------------------------------
	-- #6a. Profile Theme Selection
	-------------------------------------------------------

	-- Saves a valid tracker theme in the active profile and applies it.
	function UI:SelectTheme(key)
		if not self.Themes[key] or not profileReady() then return false end
		RQE.db.profile.trackerTheme = key
		-- Keep older profiles and external consumers of this saved boolean coherent.
		RQE.db.profile.useModernTheme = key ~= "Basic"
		return self:ApplySavedTheme()
	end

	-------------------------------------------------------
	-- #6b. Saved Theme Application & Restoration
	-------------------------------------------------------

	-- Applies or restores the selected profile theme across every registered control.
	function UI:ApplySavedTheme()
		if not profileReady() then return false end
		local selected = self:GetSelectedTheme()
		if RQE.API and RQE.API.Client and RQE.API.Client.InCombatLockdown()
			then self.pendingTheme = selected; return false end
		self.pendingTheme = nil
		self:ActivateThemeTextSettings(selected)
		if self.appliedTheme == selected then
			-- Profile changes can alter a card style without changing the overall
			-- theme. Refresh its live card even on this otherwise no-op path.
			self:RefreshCardStyles()
			self:RefreshButtonBorderOpacity()
			self:RefreshFrameBorderOpacity()
			self:RefreshBackgroundPictures()
			self:RefreshTooltipBackground()
			self:UpdatePanelOpacity()
			if RQE.RefreshCreatureObjectPreviewTheme then RQE.RefreshCreatureObjectPreviewTheme() end
			RQE:ConfigurationChanged()
			if RQE.SeparateContentFrame and RQE.UpdateSeparateFocusFrame then RQE:UpdateSeparateFocusFrame() end
			return true
		end
		self.ActiveTheme = selected
		local theme = self.Themes[selected]
		self.Colors = theme.colors or self.Themes.AzureGold.colors
		self.Textures = theme.textures or self.Themes.AzureGold.textures
		self._sessionThemeEnabled = not theme.native
		if not self:IsEnabled() then
			for _, list in ipairs({ self.Registry.panels, self.Registry.locationBars, self.Registry.questIndexButtons }) do
				for _, entry in ipairs(list) do restoreNative(entry.target) end
			end
			for _, entry in ipairs(self.Registry.headers) do
				restoreNative(entry.target)
				local native = self.Native[entry.target]
				if native then entry.target:SetHeight(native.height) end
			end
			for _, list in ipairs({ self.Registry.iconButtons, self.Registry.textButtons,
				self.Registry.searchBoxes, self.Registry.legacyButtons }) do
				for _, entry in ipairs(list) do restoreNative(entry.target, true) end
			end
			for _, entry in ipairs(self.Registry.legacyButtons) do
				restoreNative(entry.data.background)
				restoreNative(entry.data.label)
			end
			for _, target in ipairs(self.LayoutTargets or {}) do
				local isText = target == RQE.headerText or target == RQE.QuestTrackerHeaderText
					or target == RQE.QuestNameText
				restoreNative(target, not isText)
				if target == RQE.QuestNameText then restorePoints(target, self.Native[target].points) end
			end
			if RQE.MagicButton then
				if RQE.MagicButton.RQEThemeMagicBackdrop then RQE.MagicButton.RQEThemeMagicBackdrop:Hide() end
				if RQE.MagicButton.RQEThemeActionIcon then RQE.MagicButton.RQEThemeActionIcon:Hide() end
			end
		else
			for _, e in ipairs(self.Registry.panels) do
				local opacity = e.data.opacity
				if e.data.role == "main" or e.data.role == "tracker" then
					opacity = self:GetFrameBackgroundOpacity(e.data.role)
				end
				self:_ApplyPanel(e.target, opacity, e.data.role, isFrameBorderRole(e.data.role))
			end
			for _, e in ipairs(self.Registry.headers) do self:_ApplyHeader(e.target, e.data.child) end
			for _, e in ipairs(self.Registry.iconButtons) do self:_ApplyIconButton(e.target, e.data.iconName, e.data.options) end
			for _, e in ipairs(self.Registry.textButtons) do self:_ApplyTextButton(e.target, e.data) end
			for _, e in ipairs(self.Registry.searchBoxes) do self:_ApplySearchBox(e.target) end
			for _, e in ipairs(self.Registry.legacyButtons) do
				hideRegion(e.data.background); hideRegion(e.data.label)
				self:_ApplyIconButton(e.target, e.data.iconName, e.data.options or { size = 30, iconInset = 2 })
			end
			for _, e in ipairs(self.Registry.locationBars) do self:_ApplyLocationInfoBar(e.target) end
			self:_ApplyFrameLayout()
		end
		self.appliedTheme = selected
		self:RefreshButtonBorderOpacity()
		self:RefreshFrameBorderOpacity()
		self:RefreshTooltipBackground()
		if RQE.RefreshCreatureObjectPreviewTheme then RQE.RefreshCreatureObjectPreviewTheme() end
		RQE:ConfigurationChanged()
		if RQE.SeparateContentFrame and RQE.UpdateSeparateFocusFrame then RQE:UpdateSeparateFocusFrame() end
		self:UpdatePanelOpacity()
		self:RefreshLocationInfoBar()
		if RQE.RefreshObjectiveProgressBarColors then RQE.RefreshObjectiveProgressBarColors() end
		if RQE.LayoutSeparateFocusFrame then RQE:LayoutSeparateFocusFrame() end
		if RQE.UpdateContentSize then RQE:UpdateContentSize() end
		if RQE.Buttons and RQE.Buttons.UpdateHeaderNavigation then RQE.Buttons.UpdateHeaderNavigation() end
		if RQE.Buttons and RQE.Buttons.UpdateQuestTrackerHeaderTitle then RQE.Buttons.UpdateQuestTrackerHeaderTitle() end
		if RQE.Buttons and RQE.Buttons.RefreshLegacyBorders then RQE.Buttons.RefreshLegacyBorders() end
		self:RefreshExternalButtons()
		if RQE.RefreshQuestToolTheme then RQE:RefreshQuestToolTheme() end
		if RQE.Buttons and RQE.Buttons.UpdateMagicButtonIcon then RQE.Buttons.UpdateMagicButtonIcon() end
		C_Timer.After(0, function()
			if RQE.UI ~= self then return end
			if RQE.API and RQE.API.Client and RQE.API.Client.InCombatLockdown() then
				self.pendingTheme = self:GetSelectedTheme()
				self.appliedTheme = nil
				return
			end
			if RQE.RefreshQuestTrackerAfterSearch then RQE:RefreshQuestTrackerAfterSearch() end
			if RQE.UpdateScenarioFrame then RQE.UpdateScenarioFrame() end
		end)
		return true
	end

	-- Companion addons register complete theme definitions after RQE has loaded.
	-- Existing profile tables remain the sole store for player selections.
	function UI:RegisterTheme(key, theme)
		if type(key) ~= "string" or key == "" or type(theme) ~= "table"
			or self.Themes[key] or type(theme.name) ~= "string"
			or type(theme.colors) ~= "table" or type(theme.textures) ~= "table" then
			return false, "Invalid or duplicate theme"
		end
		local cardDefaults = theme.cardDefaults
		local cardStyles = theme.cardStyles
		if type(cardDefaults) ~= "table" or type(cardStyles) ~= "table" then
			return false, "Theme card defaults and styles are required"
		end
		registerThemeCardDefaults(key, cardDefaults)
		for slot, styles in pairs(cardStyles) do
			local group = self.CardStyles[key][slot]
			if not group or type(styles) ~= "table" then
				self.CardStyles[key] = nil
				return false, "Invalid card style slot"
			end
			for _, style in ipairs(styles) do group.styles[#group.styles + 1] = style end
		end
		for slot, group in pairs(self.CardStyles[key]) do
			local found = false
			for _, style in ipairs(group.styles) do
				if style.id == group.default then found = true; break end
			end
			if not found then
				self.CardStyles[key] = nil
				return false, "Unknown default card style for " .. slot
			end
		end
		if theme.defaultBackgroundPicture then
			local found = false
			for _, picture in ipairs(theme.backgroundPictures or {}) do
				if picture.id == theme.defaultBackgroundPicture then found = true; break end
			end
			if not found then
				self.CardStyles[key] = nil
				return false, "Unknown default background picture"
			end
		end
		local defaults = theme.defaults or {}
		self.Themes[key] = theme
		self.BackgroundPictures[key] = theme.backgroundPictures
		self.BackgroundPictureDefaults[key] = theme.defaultBackgroundPicture
		self.ThemeButtonBorderOpacityDefaults[key] = defaults.buttonBorderOpacity or 1
		self.ThemeFrameBorderOpacityDefaults[key] = defaults.frameBorderOpacity or 1
		self.ThemeFrameBackgroundOpacityDefaults[key] = defaults.frameBackgroundOpacity or { main = 0.65, tracker = 0.60 }
		self.ThemeBackgroundPictureOpacityDefaults[key] = defaults.backgroundPictureOpacity or { main = 0.20, tracker = 0.30 }
		self.ThemeTooltipPictureOpacityDefaults[key] = defaults.tooltipPictureOpacity or { questID = 1, questName = 1, macroBody = 1 }
		self.ThemeCardPictureOpacityDefaults[key] = defaults.cardPictureOpacity or { timed = 1, heroic = 1, normal = 1, follower = 1, delve = 1, torghast = 1 }
		self.ThemeFontDefaults[key] = theme.fontDefaults or {}
		table.insert(self.ThemeOrder, key)
		table.sort(self.ThemeOrder, function(left, right)
			if left == "Basic" then return true end
			if right == "Basic" then return false end
			return (self.Themes[left].name or left) < (self.Themes[right].name or right)
		end)
		if profileReady() and RQE.db.profile.trackerTheme == key then self:ApplySavedTheme() end
		local configRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
		if configRegistry then configRegistry:NotifyChange("RQE_Themes") end
		return true
	end

	-- Artwork registered here is selectable in every themed card list. New
	-- themes inherit it because their lists are cloned from Azure & Gold.
	function UI:RegisterSharedCardStyle(slot, style)
		if not self.CardStyles.AzureGold[slot] or type(style) ~= "table"
			or type(style.id) ~= "string" or style.id == ""
			or type(style.name) ~= "string" or type(style.texture) ~= "string" then
			return false, "Invalid shared card style"
		end
		for _, groups in pairs(self.CardStyles) do
			local group = groups[slot]
			if group then
				for _, existing in ipairs(group.styles) do
					if existing.id == style.id and existing.texture ~= style.texture then
						return false, "Card style ID already uses different artwork"
					end
				end
			end
		end
		for _, groups in pairs(self.CardStyles) do
			local group = groups[slot]
			if group then
				local found = false
				for _, existing in ipairs(group.styles) do
					if existing.id == style.id then found = true; break end
				end
				if not found then group.styles[#group.styles + 1] = { id = style.id, name = style.name, texture = style.texture } end
			end
		end
		if profileReady() then self:RefreshCardStyles() end
		local configRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
		if configRegistry then configRegistry:NotifyChange("RQE_Themes") end
		return true
	end

	-------------------------------------------------------
	-- #6c. Login, Addon & Combat Recovery Watcher
	-------------------------------------------------------

	local externalSkinWatcher = CreateFrame("Frame")
	externalSkinWatcher:RegisterEvent("ADDON_LOADED")
	externalSkinWatcher:RegisterEvent("PLAYER_LOGIN")
	externalSkinWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	externalSkinWatcher:SetScript("OnEvent", function(_, event, addonName)
		if event == "PLAYER_REGEN_ENABLED" then
			if UI.pendingTheme then UI:ApplySavedTheme() end
			if UI.pendingButtonBorderOpacity then
				UI.pendingButtonBorderOpacity = nil
				UI:RefreshButtonBorderOpacity()
			end
			if UI.pendingFrameBorderOpacity then
				UI.pendingFrameBorderOpacity = nil
				UI:RefreshFrameBorderOpacity()
			end
			if UI.pendingCardStyleRefresh then UI:RefreshCardStyles() end
		end
		if event == "PLAYER_LOGIN" or addonName == "RQE_Contribution" then UI:RefreshExternalButtons() end
	end)
