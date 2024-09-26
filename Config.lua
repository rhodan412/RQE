--[[ 

Config.lua
This file contains all the configurations for the RQE addon.
It uses the Ace3 library for creating the configuration interface.

]]

---------------------------
-- 1. Library and Main Table
---------------------------

-- Ace3 Libraries
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")

-- Main Table
if not RQE then RQE = {} end

if RQE and RQE.debugLog then
	RQE.debugLog("Message here")
else
	RQE.debugLog("RQE or RQE.debugLog is not initialized.")
end

RQE.Frame = RQE.Frame or {}

RQE.db = RQE.db or {}
RQE.db.profile = RQE.db.profile or {}


---------------------------
-- 2. ProfileManager Logic (Commented out for removal of profile management)
---------------------------

-- This section is responsible for initializing and handling the profile logic related to the Add-On Options system.
-- Initialize profile options
function RQE:InitializeProfileOptions()
	-- Additional logic related to profile options can go here
end


---------------------------
-- 3. Settings Logic
---------------------------

-- This section controls the default settings if the Profile section for the Add-On configuration doesn't contain that information
RQE.Settings = {}

-- Function to open the Frame Settings panel
function RQE:OpenFrameSettings()
	if self.optionsFrame.frame then
		SettingsPanel:OpenToCategory(self.optionsFrame.frame)
		-- print("Opened Frame Settings")
	else
		-- print("Frame Settings not initialized")
	end
end

-- Function to open the Font Settings panel
function RQE:OpenFontSettings()
	if self.optionsFrame.font then
		SettingsPanel:OpenToCategory(self.optionsFrame.font)
		-- print("Opened Font Settings")
	else
		-- print("Font Settings not initialized")
	end
end

-- Function to open the Debug Options panel
function RQE:OpenDebugOptions()
	if self.optionsFrame.debug then
		SettingsPanel:OpenToCategory(self.optionsFrame.debug)
		-- print("Opened Debug Options")
	else
		-- print("Debug Options not initialized")
	end
end

-- Function to open the Profiles panel
function RQE:OpenProfiles()
	if self.optionsFrame.profiles then
		SettingsPanel:OpenToCategory(self.optionsFrame.profiles)
		-- print("Opened Profiles")
	else
		-- print("Profiles not initialized")
	end
end


---------------------------
-- 4. Config Logic
---------------------------

-- Valid Anchor Point Options
local anchorPointOptions = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}


-- Valid Debug Level Options
local debugLevelOptions = {"NONE", "INFO", "INFO+", "DEBUG", "WARNING", "CRITICAL"}

-- Utility function to convert between debug level string and index
local function getDebugLevelIndex(str)
	for i, v in ipairs(debugLevelOptions) do
		if v == str then
			return i
		end
	end
	return 1  -- default to 1 (NONE) if not found
end


-- Utility function to convert between string and index
local function getAnchorPointIndex(str)
	for i, v in ipairs(anchorPointOptions) do
		if v == str then
			return i
		end
	end
	return 1  -- default to 1 if not found
end


-- Main Options Table
RQE.options = {
	name = "Rhodan's Quest Explorer",
	type = "group",
	args = {
		general = {
			name = "Settings",
			type = "group",
			args = {
				enableFrame = {
					type = "toggle",
					name = "Enable Frame",
					desc = "Enable or disable the frame.",
					get = function(info) return RQE.db.profile.enableFrame end,
					set = function(info, value)
						RQE.db.profile.enableFrame = value
						RQE:ToggleRQEFrame()
					end,
					order = 1,
				},
				hideRQEFrameWhenEmpty = {
					type = "toggle",
					name = "Hide SuperTrack Frame When Empty",
					desc = "Automatically hide the SuperTrack Frame when there are no quests being super tracked or searched.",
					get = function(info) return RQE.db.profile.hideRQEFrameWhenEmpty end,
					set = function(info, value)
						RQE.db.profile.hideRQEFrameWhenEmpty = value
						RQE:UpdateRQEFrameVisibility()
					end,
					width = "full",
					order = 2, -- Adjust the order as needed
				},
				enableQuestFrame = {
					type = "toggle",
					name = "Enable Quest Frame",
					desc = "Enable or disable the Quest Frame.",
					get = function(info) return RQE.db.profile.enableQuestFrame end,
					set = function(info, value)
						RQE.db.profile.enableQuestFrame = value
						RQE:ToggleRQEQuestFrame()
					end,
					order = 3,
				},
				hideRQEQuestFrameWhenEmpty = {
					type = "toggle",
					name = "Hide Quest Frame When Empty",
					desc = "Automatically hide the Quest Tracker when no quests or achievements are being watched.",
					get = function(info) return RQE.db.profile.hideRQEQuestFrameWhenEmpty end,
					set = function(info, value)
						RQE.db.profile.hideRQEQuestFrameWhenEmpty = value
						RQE:UpdateRQEQuestFrameVisibility()
					end,
					width = "full",
					order = 4,
				},
				minimapToggle = {
					type = "toggle",
					name = "Show Minimap Button",
					desc = "Toggle the minimap button on or off",
					get = function()
						return RQE.db.profile.showMinimapIcon
					end,
					set = function(_, newValue)
						RQE.db.profile.showMinimapIcon = newValue -- Ensure the profile is updated
						RQE:ToggleMinimapIcon() -- Ensure the minimap icon is toggled according to the new value
					end,
					order = 5,
				},
				minimapButtonAngle = {
					type = "range",
					name = "Minimap Button Position",
					desc = "Set the position of the Minimap button around the Minimap.",
					min = 0,
					max = 360,
					step = 1,
					get = function()
						return RQE.db.profile.minimapButtonAngle
					end,
					set = function(_, newValue)
						RQE.db.profile.minimapButtonAngle = newValue
						RQE:UpdateMinimapButtonPosition()
					end,
					order = 6,
				},
				showMapID = {
					type = "toggle",
					name = "Show Current MapID",
					desc = "Toggles the display of the current MapID on the frame.",
					order = 7,
					get = function() return RQE.db.profile.showMapID end,
					set = function(_, newValue)
						RQE.db.profile.showMapID = newValue;
						RQE:UpdateMapIDDisplay();  -- Immediately update the MapID display
					end,
				},
				showCoordinates = {
					type = "toggle",
					name = "Show Current X, Y",
					desc = "Toggles the display of the current coordinates on the frame.",
					order = 8,
					get = function() return RQE.db.profile.showCoordinates end,
					set = function(_, newValue)
						RQE.db.profile.showCoordinates = newValue;
						RQE:UpdateCoordinates();  -- Immediately update the coordinates display
					end,
				},
				autoQuestWatch = {
					type = "toggle",
					name = "Auto Quest Watch",
					desc = "Automatically track quests as soon as you obtain them and after achieving an objective.\n\n" ..
							"|cFFFF3333If the Auto Quest Watch setting changes 'on its own' check if another quest tracking addon may be interfering with your choice and set it to the same as this setting.|r",
					order = 9,
					get = function() return GetCVarBool("autoQuestWatch") end,  -- Get the current CVAR value
					set = function(_, newValue)
						RQE.db.profile.autoQuestWatch = newValue;
						SetCVar("autoQuestWatch", newValue and "1" or "0")  -- Set the CVAR based on the new value
					end,
				},
				autoQuestProgress = {
					type = "toggle",
					name = "Auto Quest Progress",
					desc = "Quests are automatically watched for 5 minutes when you achieve a quest objective.\n\n" ..
							"|cFFFF3333If the Auto Quest Progress setting changes 'on its own' check if another quest tracking addon may be interfering with your choice and set it to the same as this setting.|r",
					order = 10,
					get = function() return GetCVarBool("autoQuestProgress") end,  -- Get the current CVAR value
					set = function(_, newValue)
						RQE.db.profile.autoQuestProgress = newValue;
						SetCVar("autoQuestProgress", newValue and "1" or "0")  -- Set the CVAR based on the new value
					end,
				},
				removeWQatLogin = {
					type = "toggle",
					name = "Remove WQ after login",
					desc = "Removes all of the WQ on player login",
					order = 11,
					get = function() return RQE.db.profile.removeWQatLogin end,
					set = function(_, newValue)
						RQE.db.profile.removeWQatLogin = newValue;
					end,
				},
				autoTrackZoneQuests = {
					type = "toggle",
					name = "Auto Track Zone Quests",
					desc = "Updates watch list on zone change to display quests specific to the player's zone",
					order = 12,
					get = function() return RQE.db.profile.autoTrackZoneQuests end,
					set = function(_, newValue)
						RQE.db.profile.autoTrackZoneQuests = newValue;
					end,
				},
				autoClickWaypointButton = {
					type = "toggle",
					name = "Auto Click Waypoint Button",
					desc = "Automatically click on the Waypoint Button in the Super Tracked frame when you progress through quest objectives",
					order = 13,
					get = function() return RQE.db.profile.autoClickWaypointButton end,
					set = function(_, newValue)
						RQE.db.profile.autoClickWaypointButton = newValue;
					end,
					width = "full",
				},
				enableQuestAbandonConfirm = {
					type = "toggle",
					name = "Auto Abandon Quest",
					desc = "If enabled will hide confirmation pop up when abandoning quest via right-clicking quest in the addon. If disabled, pop up will appear with confirmation to abandon the selected quest",
					order = 14,
					get = function() return RQE.db.profile.enableQuestAbandonConfirm end,
					set = function(_, newValue)
						RQE.db.profile.enableQuestAbandonConfirm = newValue;
					end,
				},
				enableTomTomCompatibility = {
					type = "toggle",
					name = "Enable TomTom Compatibility",
					desc = "If enabled will create waypoints via TomTom addon (if you have this addon also installed)",
					order = 15,
					get = function() return RQE.db.profile.enableTomTomCompatibility end,
					set = function(_, newValue)
						RQE.db.profile.enableTomTomCompatibility = newValue;
					end,
					width = "full",
				},
				enableCarboniteCompatibility = {
					type = "toggle",
					name = "Enable Carbonite Compatibility",
					desc = "If enabled will create waypoints via Carbonite addon (if you have this addon also installed)",
					order = 16,
					get = function() return RQE.db.profile.enableCarboniteCompatibility end,
					set = function(_, newValue)
						RQE.db.profile.enableCarboniteCompatibility = newValue;
					end,
					width = "full",
				},
				enableNearestSuperTrack = {
					type = "toggle",
					name = "Enable SuperTrack Nearest",
					desc = "Enable SuperTracking nearest when quest frame changes, such as turning in a quest, if not already supertracking",
					order = 17,
					get = function() return RQE.db.profile.enableNearestSuperTrack end,
					set = function(_, newValue)
						RQE.db.profile.enableNearestSuperTrack = newValue;
					end,
					width = "full",
				},
				enableQuestTypeDisplay = {
					type = "toggle",
					name = "Enable Quest Type Display",
					desc = "Enable visual information of the quest type in the Quest Tracker",
					order = 18,
					get = function() return RQE.db.profile.enableQuestTypeDisplay end,
					set = function(_, newValue)
						RQE.db.profile.enableQuestTypeDisplay = newValue;
					end,
					width = "full",
				},
				keyBindSetting = {
					type = "keybinding",
					name = "Key Binding for Macro",
					desc = "Specify the key combination for triggering the RQE Macro MagicButton",
					get = function()
						return RQE.db.profile.keyBindSetting
					end,
					set = function(_, value)
						RQE.db.profile.keyBindSetting = value
						RQE:ReapplyMacroBinding()	-- RQE:SetupOverrideMacroBinding()  -- Update the binding whenever the user changes it
					end,
					order = 19,
				},
			},
		},
		frame = {
			name = "Frame Settings",
			type = "group",
			args = {
				toggleBlizzObjectiveTracker = {
					type = "toggle",
					name = "Toggle Blizz Quest Tracker",
					desc = "Show/Hide Blizzard's Quest Tracker",
					get = function(info) return RQE.db.profile.toggleBlizzObjectiveTracker end,
					set = function(info, value)
						RQE.db.profile.toggleBlizzObjectiveTracker = value
					end,
					width = "full",
					order = 1, -- Adjust the order as needed
				},
				framePosition = {
					type = "group",
					name = "Main Frame Position",
					inline = true,
					order = 10,
					args = {
						anchorPoint = {
							type = 'select',
							name = 'Anchor Point',
							desc = 'The point where the frame will be anchored.',
							values = {
								'TOPLEFT', 'TOP', 'TOPRIGHT',
								'LEFT', 'CENTER', 'RIGHT',
								'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'
							},
							get = function(info)
								local anchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
								local currentAnchorPoint = RQE.db.profile.framePosition.anchorPoint
								for index, anchor in ipairs(anchorPoints) do
									if anchor == currentAnchorPoint then
										return index
									end
								end
								return 1  -- default to 'TOPLEFT' if not found
							end,
							set = function(info, value)
								local anchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
								local chosenAnchorPoint = anchorPoints[value]  -- Convert the numerical index back to the string
								RQE.db.profile.framePosition.anchorPoint = chosenAnchorPoint
								RQE:UpdateFramePosition()
							end,
							order = 1,
						},
						xPos = {
							type = 'range',
							name = 'X Position',
							min = -500,
							max = 500,
							step = 1,
							get = function(info)
								return RQE.db.profile.framePosition.xPos
							end,
							set = function(info, value)
								RQE.db.profile.framePosition.xPos = value
								RQE:UpdateFramePosition()
							end,
							order = 2,
						},
						yPos = {
							type = 'range',
							name = 'Y Position',
							min = -500,
							max = 500,
							step = 1,
							get = function(info)
								return RQE.db.profile.framePosition.yPos
							end,
							set = function(info, value)
								RQE.db.profile.framePosition.yPos = value
								RQE:UpdateFramePosition()
							end,
							order = 3,
						},
						MainFrameOpacity = {
							type = 'range',
							name = 'Quest Helper Opacity',
							desc = 'Adjust the opacity of the main helper frame.',
							min = 0,
							max = 1,
							step = 0.01,
							isPercent = true,
							get = function(info) return RQE.db.profile.MainFrameOpacity end,
							set = function(info, value)
								RQE.db.profile.MainFrameOpacity = value
								RQE:UpdateFrameOpacity()
							end,
							order = 4,
						},
						frameWidth = {
							type = 'range',
							name = 'Frame Width',
							desc = 'Adjust the width of the super tracking frame.',
							min = 100,  -- Minimum height allowed
							max = 800,  -- Maximum height allowed
							step = 1,
							get = function(info)
								return RQE.db.profile.framePosition.frameWidth
							end,
							set = function(info, value)
								RQE.db.profile.framePosition.frameWidth = value
								RQE:UpdateFrameSize()  -- Function to update frame size
							end,
							order = 5,
						},
						frameHeight = {
							type = 'range',
							name = 'Frame Height',
							desc = 'Adjust the height of the super tracking frame.',
							min = 100,  -- Minimum height allowed
							max = 800,  -- Maximum height allowed
							step = 1,
							get = function(info)
								return RQE.db.profile.framePosition.frameHeight
							end,
							set = function(info, value)
								RQE.db.profile.framePosition.frameHeight = value
								RQE:UpdateFrameSize()  -- Function to update frame size
							end,
							order = 6,
						},
					},
				},
				QuestFramePosition = {
					type = "group",
					name = "Quest Frame Position",
					inline = true,
					order = 11,  -- Set this order to wherever you want it to appear
					args = {
						anchorPoint = {
							type = 'select',
							name = 'Anchor Point',
							desc = 'The point where the quest frame will be anchored.',
							values = {
								'TOPLEFT', 'TOP', 'TOPRIGHT',
								'LEFT', 'CENTER', 'RIGHT',
								'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'
							},
							get = function(info)
								local anchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
								local currentAnchorPoint = RQE.db.profile.QuestFramePosition.anchorPoint
								for index, anchor in ipairs(anchorPoints) do
									if anchor == currentAnchorPoint then
										return index
									end
								end
								return 9  -- default to 'BOTTOMRIGHT' if not found
							end,
							set = function(info, value)
								local anchorPoints = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
								local chosenAnchorPoint = anchorPoints[value]  -- Convert the numerical index back to the string
								RQE.db.profile.QuestFramePosition.anchorPoint = chosenAnchorPoint
								RQE:UpdateQuestFramePosition()
							end,
							order = 1,
						},
						xPos = {
							type = 'range',
							name = 'X Position',
							min = -500,
							max = 500,
							step = 1,
							get = function(info)
								return RQE.db.profile.QuestFramePosition.xPos
							end,
							set = function(info, value)
								RQE.db.profile.QuestFramePosition.xPos = value
								RQE:UpdateQuestFramePosition()
							end,
							order = 2,
						},
						yPos = {
							type = 'range',
							name = 'Y Position',
							min = -500,
							max = 500,
							step = 1,
							get = function(info)
								return RQE.db.profile.QuestFramePosition.yPos
							end,
							set = function(info, value)
								RQE.db.profile.QuestFramePosition.yPos = value
								RQE:UpdateQuestFramePosition()
							end,
							order = 3,
						},
						QuestFrameOpacity = {
							type = 'range',
							name = 'Quest Tracker Opacity',
							desc = 'Adjust the opacity of the quest tracking frame.',
							min = 0,
							max = 1,
							step = 0.01,
							isPercent = true,
							get = function(info) return RQE.db.profile.QuestFrameOpacity end,
							set = function(info, value)
								RQE.db.profile.QuestFrameOpacity = value
								RQE:UpdateFrameOpacity()
							end,
							order = 4,
						},
						frameWidth = {
							type = 'range',
							name = 'Frame Width',
							desc = 'Adjust the width of the super tracking frame.',
							min = 100,  -- Minimum height allowed
							max = 800,  -- Maximum height allowed
							step = 1,
							get = function(info)
								return RQE.db.profile.QuestFramePosition.frameWidth
							end,
							set = function(info, value)
								RQE.db.profile.QuestFramePosition.frameWidth = value
								RQE:UpdateQuestFrameSize()  -- Function to update frame size
							end,
							order = 5,
						},
						frameHeight = {
							type = 'range',
							name = 'Frame Height',
							desc = 'Adjust the height of the super tracking frame.',
							min = 100,  -- Minimum height allowed
							max = 800,  -- Maximum height allowed
							step = 1,
							get = function(info)
								return RQE.db.profile.QuestFramePosition.frameHeight
							end,
							set = function(info, value)
								RQE.db.profile.QuestFramePosition.frameHeight = value
								RQE:UpdateQuestFrameSize()  -- Function to update frame size
							end,
							order = 6,
						},
					},
				},
			},
		},
		font = {
			name = "Font Settings",
			type = "group",
			args = {
				fontSizeAndColor = {
					type = "group",
					name = "Font Size and Color",
					inline = true,
					order = 12,
					args = {
						headerText = {
							name = "Header Text",
							type = "group",
							order = 1,
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 18",
									type = "range",
									min = 8, max = 24,
									step = 1,
									get = function(info) return RQE.db.profile.textSettings.headerText.size end,
									set = function(info, val) RQE.db.profile.textSettings.headerText.size = val
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 1,
								},
								fontStyle = {
									name = "Font Style",
									type = "select",
									values = {
										["SKURRI"] = "SKURRI.TTF",
										["FRIZQT__"] = "FRIZQT__.TTF"
									},
									get = function(info)
										if RQE.db.profile.textSettings.headerText.font then
											local value = RQE.db.profile.textSettings.headerText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF")
											return value
										else
											return nil
										end
									end,
									set = function(info, val)
										RQE.db.profile.textSettings.headerText.font = "Fonts\\" .. val .. ".TTF"
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 2,
								},
								fontColor = {
									name = "Font Color",
									desc = "Default: Cream Can",
									type = "select",
									values = {
										["Yellow"] = "Yellow",
										["Green"] = "Green",
										["Cyan"] = "Cyan",
										["Canary"] = "Canary",
										["Cream Can"] = "Cream Can",
										-- Add other named colors here
									},
									get = function(info)
										local color = RQE.db.profile.textSettings.headerText.color
										local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)

										if hexColor == "ffff00" then
											return "Yellow"
										elseif hexColor == "00ff00" then
											return "Green"
										elseif hexColor == "00ff99" then
											return "Cyan"
										elseif hexColor == "ffffd9" then
											return "Canary"
										elseif hexColor == "edbf59" then
											return "Cream Can"
										end
									end,
									set = function(info, val)
										local hexColor
										if val == "Yellow" then
											hexColor = "ffff00"
										elseif val == "Green" then
											hexColor = "00ff00"
										elseif val == "Cyan" then
											hexColor = "00ff99"
										elseif val == "Canary" then
											hexColor = "ffffd9"
										elseif val == "Cream Can" then
											hexColor = "edbf59"
										end

										local r = tonumber(hexColor:sub(1,2), 16) / 255
										local g = tonumber(hexColor:sub(3,4), 16) / 255
										local b = tonumber(hexColor:sub(5,6), 16) / 255
										RQE.db.profile.textSettings.headerText.color = {r, g, b}

										local new_value = val
										RQE:ConfigurationChanged()
									end,
									order = 3,
								},
							},
						},
						QuestIDText = {
							name = "Quest ID Text",
							type = "group",
							order = 2,  -- set an appropriate order
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 15",
									type = "range",
									min = 8,
									max = 24,
									step = 1,
									get = function(info) return RQE.db.profile.textSettings.QuestIDText.size end,
									set = function(info, val) RQE.db.profile.textSettings.QuestIDText.size = val
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
									order = 1,
								},
								fontStyle = {
									name = "Font Style",
									type = "select",
									values = {
										["SKURRI"] = "SKURRI.TTF",
										["FRIZQT__"] = "FRIZQT__.TTF"
									},
									get = function(info)
										if RQE.db.profile.textSettings.QuestIDText.font then
											local value = RQE.db.profile.textSettings.QuestIDText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF")
											return value
										else
											return nil
										end
									end,
									set = function(info, val)
										RQE.db.profile.textSettings.QuestIDText.font = "Fonts\\" .. val .. ".TTF"
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 2,
								},
								fontColor = {
									name = "Font Color",
									desc = "Default: Yellow",
									type = "select",
									values = {
										["Yellow"] = "Yellow",
										["Green"] = "Green",
										["Cyan"] = "Cyan",
										["Canary"] = "Canary",
										["Cream Can"] = "Cream Can",
										-- Add other named colors here
									},
									get = function(info)
										local color = RQE.db.profile.textSettings.QuestIDText.color
										local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)

										if hexColor == "ffff00" then
											return "Yellow"
										elseif hexColor == "00ff00" then
											return "Green"
										elseif hexColor == "00ff99" then
											return "Cyan"
										elseif hexColor == "ffffd9" then
											return "Canary"
										elseif hexColor == "edbf59" then
											return "Cream Can"
										end
									end,
									set = function(info, val)
										local hexColor
										if val == "Yellow" then
											hexColor = "ffff00"
										elseif val == "Green" then
											hexColor = "00ff00"
										elseif val == "Cyan" then
											hexColor = "00ff99"
										elseif val == "Canary" then
											hexColor = "ffffd9"
										elseif val == "Cream Can" then
											hexColor = "edbf59"
										end

										local r = tonumber(hexColor:sub(1,2), 16) / 255
										local g = tonumber(hexColor:sub(3,4), 16) / 255
										local b = tonumber(hexColor:sub(5,6), 16) / 255
										RQE.db.profile.textSettings.QuestIDText.color = {r, g, b}

										local new_value = val
										RQE:ConfigurationChanged()
									end,
									order = 3,
								},
							},
						},
						QuestNameText = {
							name = "Quest Name Text",
							type = "group",
							order = 3,  -- set an appropriate order
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 15",
									type = "range",
									min = 8,
									max = 24,
									step = 1,
									get = function(info) return RQE.db.profile.textSettings.QuestNameText.size end,
									set = function(info, val) RQE.db.profile.textSettings.QuestNameText.size = val
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
									order = 1,
								},
								fontStyle = {
									name = "Font Style",
									type = "select",
									values = {
										["SKURRI"] = "SKURRI.TTF",
										["FRIZQT__"] = "FRIZQT__.TTF"
									},
									get = function(info)
										if RQE.db.profile.textSettings.QuestNameText.font then
											local value = RQE.db.profile.textSettings.QuestNameText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF")
											return value
										else
											return nil
										end
									end,
									set = function(info, val)
										RQE.db.profile.textSettings.QuestNameText.font = "Fonts\\" .. val .. ".TTF"
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 2,
								},
								fontColor = {
									name = "Font Color",
									desc = "Default: Yellow",
									type = "select",
									values = {
										["Yellow"] = "Yellow",
										["Green"] = "Green",
										["Cyan"] = "Cyan",
										["Canary"] = "Canary",
										["Cream Can"] = "Cream Can",
										-- Add other named colors here
									},
									get = function(info)
										local color = RQE.db.profile.textSettings.QuestNameText.color
										local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)

										if hexColor == "ffff00" then
											return "Yellow"
										elseif hexColor == "00ff00" then
											return "Green"
										elseif hexColor == "00ff99" then
											return "Cyan"
										elseif hexColor == "ffffd9" then
											return "Canary"
										elseif hexColor == "edbf59" then
											return "Cream Can"
										end
									end,
									set = function(info, val)
										local hexColor
										if val == "Yellow" then
											hexColor = "ffff00"
										elseif val == "Green" then
											hexColor = "00ff00"
										elseif val == "Cyan" then
											hexColor = "00ff99"
										elseif val == "Canary" then
											hexColor = "ffffd9"
										elseif val == "Cream Can" then
											hexColor = "edbf59"
										end

										local r = tonumber(hexColor:sub(1,2), 16) / 255
										local g = tonumber(hexColor:sub(3,4), 16) / 255
										local b = tonumber(hexColor:sub(5,6), 16) / 255
										RQE.db.profile.textSettings.QuestNameText.color = {r, g, b}

										local new_value = val
										RQE:ConfigurationChanged()
									end,
									order = 3,
								},
							},
						},
						DirectionTextFrame = {
							name = "Direction Text",
							type = "group",
							order = 4,  -- set an appropriate order
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 13",
									type = "range",
									min = 8,
									max = 24,
									step = 1,
									get = function(info) return RQE.db.profile.textSettings.DirectionTextFrame.size end,
									set = function(info, val) RQE.db.profile.textSettings.DirectionTextFrame.size = val
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
									order = 1,
								},
								fontStyle = {
									name = "Font Style",
									type = "select",
									values = {
										["SKURRI"] = "SKURRI.TTF",
										["FRIZQT__"] = "FRIZQT__.TTF"
									},
									get = function(info)
										if RQE.db.profile.textSettings.DirectionTextFrame.font then
											local value = RQE.db.profile.textSettings.DirectionTextFrame.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF")
											return value
										else
											return nil
										end
									end,
									set = function(info, val)
										RQE.db.profile.textSettings.DirectionTextFrame.font = "Fonts\\" .. val .. ".TTF"
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 2,
								},
								fontColor = {
									name = "Font Color",
									desc = "Default: Yellow",
									type = "select",
									values = {
										["Yellow"] = "Yellow",
										["Green"] = "Green",
										["Cyan"] = "Cyan",
										["Canary"] = "Canary",
										["Cream Can"] = "Cream Can",
										-- Add other named colors here
									},
									get = function(info)
										local color = RQE.db.profile.textSettings.DirectionTextFrame.color
										local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)

										if hexColor == "ffff00" then
											return "Yellow"
										elseif hexColor == "00ff00" then
											return "Green"
										elseif hexColor == "00ff99" then
											return "Cyan"
										elseif hexColor == "ffffd9" then
											return "Canary"
										elseif hexColor == "edbf59" then
											return "Cream Can"
										end
									end,
									set = function(info, val)
										local hexColor
										if val == "Yellow" then
											hexColor = "ffff00"
										elseif val == "Green" then
											hexColor = "00ff00"
										elseif val == "Cyan" then
											hexColor = "00ff99"
										elseif val == "Canary" then
											hexColor = "ffffd9"
										elseif val == "Cream Can" then
											hexColor = "edbf59"
										end

										local r = tonumber(hexColor:sub(1,2), 16) / 255
										local g = tonumber(hexColor:sub(3,4), 16) / 255
										local b = tonumber(hexColor:sub(5,6), 16) / 255
										RQE.db.profile.textSettings.DirectionTextFrame.color = {r, g, b}

										local new_value = val
										RQE:ConfigurationChanged()
									end,
									order = 3,
								},
							},
						},
						QuestDescription = {
							name = "Quest Description",
							type = "group",
							order = 5,  -- set an appropriate order
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 14",
									type = "range",
									min = 8,
									max = 24,
									step = 1,
									get = function(info) return RQE.db.profile.textSettings.QuestDescription.size end,
									set = function(info, val) RQE.db.profile.textSettings.QuestDescription.size = val
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
									order = 1,
								},
								fontStyle = {
									name = "Font Style",
									type = "select",
									values = {
										["SKURRI"] = "SKURRI.TTF",
										["FRIZQT__"] = "FRIZQT__.TTF"
									},
									get = function(info)
										if RQE.db.profile.textSettings.QuestDescription.font then
											local value = RQE.db.profile.textSettings.QuestDescription.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF")
											return value
										else
											return nil
										end
									end,
									set = function(info, val)
										RQE.db.profile.textSettings.QuestDescription.font = "Fonts\\" .. val .. ".TTF"
										RQE:ConfigurationChanged()  -- Notify the system that a change has occurred
									end,
								order = 2,
								},
								fontColor = {
									name = "Font Color",
									desc = "Default: Cyan",
									type = "select",
									values = {
										["Yellow"] = "Yellow",
										["Green"] = "Green",
										["Cyan"] = "Cyan",
										["Canary"] = "Canary",
										["Cream Can"] = "Cream Can",
										-- Add other named colors here
									},
									get = function(info)
										local color = RQE.db.profile.textSettings.QuestDescription.color
										local hexColor = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)

										if hexColor == "ffff00" then
											return "Yellow"
										elseif hexColor == "00ff00" then
											return "Green"
										elseif hexColor == "00ff99" then
											return "Cyan"
										elseif hexColor == "ffffd9" then
											return "Canary"
										elseif hexColor == "edbf59" then
											return "Cream Can"
										end
									end,
									set = function(info, val)
										local hexColor
										if val == "Yellow" then
											hexColor = "ffff00"
										elseif val == "Green" then
											hexColor = "00ff00"
										elseif val == "Cyan" then
											hexColor = "00ff99"
										elseif val == "Canary" then
											hexColor = "ffffd9"
										elseif val == "Cream Can" then
											hexColor = "edbf59"
										end

										local r = tonumber(hexColor:sub(1,2), 16) / 255
										local g = tonumber(hexColor:sub(3,4), 16) / 255
										local b = tonumber(hexColor:sub(5,6), 16) / 255
										RQE.db.profile.textSettings.QuestDescription.color = {r, g, b}

										local new_value = val
										RQE:ConfigurationChanged()
									end,
									order = 3,
								},
							},
						},
					},
				},
			},
		},
		debug = {
			name = "Debug Options",
			type = "group",
			args = {
				debugMode = {
					type = "toggle",
					name = "Enable Debug Mode",
					desc = "Enable or disable debug mode for additional logging.",
					order = 1,
					get = function(info)
						return RQE.db.profile.debugMode
					end,
					set = function(info, value)
						RQE.db.profile.debugMode = value
						if not value then
							RQE.db.profile.debugLevel = "NONE"
						end
					end,
				},
				displayRQEmemUsage = {
					type = "toggle",
					name = "Display Memory Usage",
					desc = "Displays the memory usage for the RQE addon",
					order = 2,
					get = function() return RQE.db.profile.displayRQEmemUsage end,
					set = function(_, newValue)
						RQE.db.profile.displayRQEmemUsage = newValue;
						RQE:CheckMemoryUsage();  -- Immediately update the memory usage display
					end,
				},
				debug = {
					type = "group",
					name = "Debug",
					inline = true,
					order = 3,
					hidden = function()
						return not RQE.db.profile.debugMode  -- Hide when Debug Mode is off
					end,
					args = {
						debugLevel = {
							type = 'select',
							name = 'Debug Level',
							desc = 'Set the level of debug logging.',
							values = debugLevelOptions,
							get = function(info)
								return getDebugLevelIndex(RQE.db.profile.debugLevel)  -- Convert string to index
							end,
							set = function(info, value)
								RQE.db.profile.debugLevel = debugLevelOptions[value]  -- Convert index to string
							end,
							order = 1,
						},
						resetFramePosition = {
							type = "execute",
							name = "Reset Position",
							desc = "Reset the position of the frame to its default coded location.",
							func = function()
								RQE:ResetFramePositionToDBorDefault()
								RQE:ResetQuestFramePositionToDBorDefault()
							end,
							hidden = function()
								return not (RQE.db.profile.debugMode and (RQE.db.profile.debugLevel == "INFO") or (RQE.db.profile.debugLevel == "INFO+"))
							end,
							order = 2,
						},
						resetFrameSize = {
							type = "execute",
							name = "Reset Size",
							desc = "Reset the size of the frame to its default coded size.",
							func = function()
								RQE:ResetFrameSizeToDBorDefault()
							end,
							hidden = function()
								return not (RQE.db.profile.debugMode and (RQE.db.profile.debugLevel == "INFO") or (RQE.db.profile.debugLevel == "INFO+"))
							end,
							order = 3,
						},
					},
				},
			},
		},
	},
}

-- Event Manager dealing with opening different panels in the addon options
RQE:RegisterChatCommand("rqe_frame", "OpenFrameSettings")
RQE:RegisterChatCommand("rqe_font", "OpenFontSettings")
RQE:RegisterChatCommand("rqe_debug", "OpenDebugOptions")
RQE:RegisterChatCommand("RQE_Profiles", "OpenProfiles")


---------------------------
-- 5. Config Frame
---------------------------

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Creates the frame to handle the Configuration
function RQE:CreateConfigFrame()
	if not self.configFrame then  -- Check if the frame already exists
		local frame = AceGUI:Create("Frame")
		frame:SetTitle("Rhodan's Quest Explorer Settings")
		frame:SetStatusText("Configure your settings")
		frame:SetCallback("OnClose", function(widget)
			AceGUI:Release(widget)
			self.configFrame = nil  -- Clear the reference when the frame is closed
		end)
		frame:SetLayout("Flow")
		frame:SetWidth(600)  -- Increase the width of the frame
		frame:SetHeight(400)  -- Set a specific height for the frame

		-- Create a hidden frame to handle ESC key closure
		local escFrame = CreateFrame("Frame", "RQEConfigFrameEscHandler", UIParent)
		escFrame:SetAllPoints(frame.frame)
		escFrame:SetScript("OnHide", function()
			if self.configFrame then
				self.configFrame:Hide()
			end
		end)
		table.insert(UISpecialFrames, escFrame:GetName())

		local tabGroup = AceGUI:Create("TabGroup")
		tabGroup:SetLayout("Flow")
		tabGroup:SetFullWidth(true)  -- Ensure it uses the full width of the frame
		tabGroup:SetFullHeight(true) -- Ensure it uses the full height of the frame
		tabGroup:SetTabs({
			{text = "General Settings", value = "general"},
			{text = "Frame Settings", value = "frame"},
			{text = "Font Settings", value = "font"},
			{text = "Debug Options", value = "debug"},
			{text = "Profiles", value = "profiles"}
		})

		tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
			container:ReleaseChildren()
			if group == "general" then
				RQE:AddGeneralSettingsWidgets(container)
			elseif group == "frame" then
				RQE:AddFrameSettingsWidgets(container)
			elseif group == "font" then
				RQE:AddFontSettingsWidgets(container)
			elseif group == "debug" then
				RQE:AddDebugSettingsWidgets(container)
			elseif group == "profiles" then
				RQE:AddProfileSettingsWidgets(container)
			end
		end)

		tabGroup:SelectTab("general")
		frame:AddChild(tabGroup)

		self.configFrame = frame  -- Store the frame reference in RQE
	end
end


-- Function to toggle show/hide the Configuration Frame
function RQE:ToggleConfigFrame()
	if self.configFrame then
		if self.configFrame:IsVisible() then
			self.configFrame:Hide()
		else
			self.configFrame:Show()
		end
	else
		self:CreateConfigFrame()
	end
end


-- Displays the Widget Container General Settings in Config Frame
function RQE:AddGeneralSettingsWidgets(container)
	-- Create a Scroll Frame
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true) -- This will allow the scroll frame to take up the full height of the parent container
	container:AddChild(scrollFrame)

	-- Enable Frame Checkbox
	local enableFrameCheckbox = AceGUI:Create("CheckBox")
	enableFrameCheckbox:SetLabel("Enable Frame")
	enableFrameCheckbox:SetValue(RQE.db.profile.enableFrame)
	enableFrameCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableFrame = value
		RQE:ToggleRQEFrame()
	end)

	-- Add a tooltip description for enableFrameCheckbox (RQE.db.profile.enableFrame)
	enableFrameCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Enable or disable the frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableFrameCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableFrameCheckbox)

	-- Hide SuperTrack Frame When Empty Checkbox
	local hideRQEFrameWhenEmptyCheckbox = AceGUI:Create("CheckBox")
	hideRQEFrameWhenEmptyCheckbox:SetLabel("Hide SuperTrack Frame When Empty")
	hideRQEFrameWhenEmptyCheckbox:SetValue(RQE.db.profile.hideRQEFrameWhenEmpty)
	hideRQEFrameWhenEmptyCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.hideRQEFrameWhenEmpty = value
		RQE:UpdateRQEFrameVisibility()
	end)

	hideRQEFrameWhenEmptyCheckbox:SetFullWidth(false)
	hideRQEFrameWhenEmptyCheckbox:SetWidth(300)

	-- Add a tooltip description for hideRQEFrameWhenEmptyCheckbox (RQE.db.profile.hideRQEFrameWhenEmpty)
	hideRQEFrameWhenEmptyCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Automatically hide the SuperTrack Frame when there are no quests being super tracked or searched.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	hideRQEFrameWhenEmptyCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(hideRQEFrameWhenEmptyCheckbox)

	-- Enable Quest Frame Checkbox
	local enableQuestFrameCheckbox = AceGUI:Create("CheckBox")
	enableQuestFrameCheckbox:SetLabel("Enable Quest Frame")
	enableQuestFrameCheckbox:SetValue(RQE.db.profile.enableQuestFrame)
	enableQuestFrameCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableQuestFrame = value
		RQE:ToggleRQEQuestFrame()
	end)

	-- Add a tooltip description for enableQuestFrameCheckbox (RQE.db.profile.enableQuestFrame)
	enableQuestFrameCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Enable or disable the Quest Frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableQuestFrameCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableQuestFrameCheckbox)

	-- Hide Quest Frame When Empty Checkbox
	local hideRQEQuestFrameWhenEmptyCheckbox = AceGUI:Create("CheckBox")
	hideRQEQuestFrameWhenEmptyCheckbox:SetLabel("Hide Quest Frame When Empty")
	hideRQEQuestFrameWhenEmptyCheckbox:SetValue(RQE.db.profile.hideRQEQuestFrameWhenEmpty)
	hideRQEQuestFrameWhenEmptyCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.hideRQEQuestFrameWhenEmpty = value
		RQE:UpdateRQEQuestFrameVisibility()
	end)

	hideRQEQuestFrameWhenEmptyCheckbox:SetFullWidth(false)
	hideRQEQuestFrameWhenEmptyCheckbox:SetWidth(300)

	-- Add a tooltip description for hideRQEQuestFrameWhenEmptyCheckbox (RQE.db.profile.hideRQEQuestFrameWhenEmpty)
	hideRQEQuestFrameWhenEmptyCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Automatically hide the Quest Tracker when no quests or achievements are being watched.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	hideRQEQuestFrameWhenEmptyCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(hideRQEQuestFrameWhenEmptyCheckbox)

	-- Minimap Button Position Slider
	local minimapButtonAngleSlider = AceGUI:Create("Slider")
	minimapButtonAngleSlider:SetLabel("Minimap Button Position")
	minimapButtonAngleSlider:SetSliderValues(0, 360, 1)
	minimapButtonAngleSlider:SetValue(RQE.db.profile.minimapButtonAngle)
	minimapButtonAngleSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.minimapButtonAngle = value
		RQE:UpdateMinimapButtonPosition()
	end)

	-- Add a tooltip description for the minimapButtonAngleSlider (RQE.db.profile.minimapButtonAngle)
	minimapButtonAngleSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Set the position of the Minimap button around the Minimap.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	minimapButtonAngleSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(minimapButtonAngleSlider)

	-- Add a description label below the slider
	local minimapButtonAngleLabel = AceGUI:Create("Label")
	minimapButtonAngleLabel:SetText("Set the position of the Minimap button around the Minimap.")
	minimapButtonAngleLabel:SetFullWidth(true)
	scrollFrame:AddChild(minimapButtonAngleLabel)

	-- Show Minimap Button Checkbox
	local minimapToggleCheckbox = AceGUI:Create("CheckBox")
	minimapToggleCheckbox:SetLabel("Show Minimap Button")
	minimapToggleCheckbox:SetValue(RQE.db.profile.showMinimapIcon) -- Get the current value from the profile
	minimapToggleCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.showMinimapIcon = value
		RQE:ToggleMinimapIcon()
	end)

	-- Add a tooltip description for minimapToggleCheckbox (RQE.db.profile.showMinimapIcon)
	minimapToggleCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Toggle the minimap button on or off", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	minimapToggleCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(minimapToggleCheckbox)

	-- Show Current MapID Checkbox
	local showMapIDCheckbox = AceGUI:Create("CheckBox")
	showMapIDCheckbox:SetLabel("Show Current MapID")
	showMapIDCheckbox:SetValue(RQE.db.profile.showMapID)
	showMapIDCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.showMapID = value
		RQE:UpdateMapIDDisplay()
	end)

	-- Add a tooltip description for showMapIDCheckbox (RQE.db.profile.showMapID)
	showMapIDCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Toggles the display of the current MapID on the frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	showMapIDCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(showMapIDCheckbox)

	-- Show Current X, Y Checkbox
	local showCoordinatesCheckbox = AceGUI:Create("CheckBox")
	showCoordinatesCheckbox:SetLabel("Show Current X, Y")
	showCoordinatesCheckbox:SetValue(RQE.db.profile.showCoordinates)
	showCoordinatesCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.showCoordinates = value
		RQE:UpdateCoordinates()
	end)

	-- Add a tooltip description for showCoordinatesCheckbox (RQE.db.profile.showCoordinates)
	showCoordinatesCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Toggles the display of the current coordinates on the frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	showCoordinatesCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(showCoordinatesCheckbox)

	-- Auto Quest Watch Checkbox
	local autoQuestWatchCheckbox = AceGUI:Create("CheckBox")
	autoQuestWatchCheckbox:SetLabel("Auto Quest Watch")
	autoQuestWatchCheckbox:SetValue(GetCVarBool("autoQuestWatch"))
	autoQuestWatchCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.autoQuestWatch = value
		SetCVar("autoQuestWatch", value and "1" or "0")
	end)

	-- Add a tooltip description for autoQuestWatchCheckbox (RQE.db.profile.autoQuestWatch)
	autoQuestWatchCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Automatically track quests as soon as you obtain them and after achieving an objective.\n\n|cFFFF3333If the Auto Quest Watch setting changes 'on its own' check if another quest tracking addon may be interfering with your choice and set it to the same as this setting.|r", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	autoQuestWatchCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(autoQuestWatchCheckbox)

	-- Auto Quest Progress Checkbox
	local autoQuestProgressCheckbox = AceGUI:Create("CheckBox")
	autoQuestProgressCheckbox:SetLabel("Auto Quest Progress")
	autoQuestProgressCheckbox:SetValue(GetCVarBool("autoQuestProgress"))
	autoQuestProgressCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.autoQuestProgress = value
		SetCVar("autoQuestProgress", value and "1" or "0")
	end)

	-- Add a tooltip description for autoQuestProgressCheckbox (RQE.db.profile.autoQuestProgress)
	autoQuestProgressCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Quests are automatically watched for 5 minutes when you achieve a quest objective.\n\n|cFFFF3333If the Auto Quest Progress setting changes 'on its own' check if another quest tracking addon may be interfering with your choice and set it to the same as this setting.|r", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	autoQuestProgressCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(autoQuestProgressCheckbox)

	-- Remove WQ after login Checkbox
	local removeWQatLoginCheckbox = AceGUI:Create("CheckBox")
	removeWQatLoginCheckbox:SetLabel("Remove WQ after login")
	removeWQatLoginCheckbox:SetValue(RQE.db.profile.removeWQatLogin)
	removeWQatLoginCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.removeWQatLogin = value
	end)

	-- Add a tooltip description for removeWQatLoginCheckbox (RQE.db.profile.removeWQatLogin)
	removeWQatLoginCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Removes all of the WQ on player login.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	removeWQatLoginCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(removeWQatLoginCheckbox)

	-- Auto Track Zone Quests Checkbox
	local autoTrackZoneQuestsCheckbox = AceGUI:Create("CheckBox")
	autoTrackZoneQuestsCheckbox:SetLabel("Auto Track Zone Quests")
	autoTrackZoneQuestsCheckbox:SetValue(RQE.db.profile.autoTrackZoneQuests)
	autoTrackZoneQuestsCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.autoTrackZoneQuests = value
	end)

	-- Add a tooltip description for autoTrackZoneQuestsCheckbox (RQE.db.profile.autoTrackZoneQuests)
	autoTrackZoneQuestsCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Updates watch list on zone change to display quests specific to the player's zone", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	autoTrackZoneQuestsCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(autoTrackZoneQuestsCheckbox)

	-- Auto Click Waypoint Button Checkbox
	local autoClickWaypointButtonCheckbox = AceGUI:Create("CheckBox")
	autoClickWaypointButtonCheckbox:SetLabel("Auto Click Waypoint Button")
	autoClickWaypointButtonCheckbox:SetValue(RQE.db.profile.autoClickWaypointButton)
	autoClickWaypointButtonCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.autoClickWaypointButton = value
	end)

	-- Add a tooltip description for autoClickWaypointButtonCheckbox (RQE.db.profile.autoClickWaypointButton)
	autoClickWaypointButtonCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Automatically click on the Waypoint Button in the Super Tracked frame when you progress through quest objectives.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	autoClickWaypointButtonCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(autoClickWaypointButtonCheckbox)

	-- Auto Abandon Quest Checkbox
	local enableQuestAbandonConfirmCheckbox = AceGUI:Create("CheckBox")
	enableQuestAbandonConfirmCheckbox:SetLabel("Auto Abandon Quest")
	enableQuestAbandonConfirmCheckbox:SetValue(RQE.db.profile.enableQuestAbandonConfirm)
	enableQuestAbandonConfirmCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableQuestAbandonConfirm = value
	end)

	-- Add a tooltip description for enableQuestAbandonConfirmCheckbox (RQE.db.profile.enableQuestAbandonConfirm)
	enableQuestAbandonConfirmCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("If enabled will hide confirmation pop up when abandoning quest via right-clicking quest in the addon. If disabled, pop up will appear with confirmation to abandon the selected quest", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableQuestAbandonConfirmCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableQuestAbandonConfirmCheckbox)

	-- Enable TomTom Compatibility Checkbox
	local enableTomTomCompatibilityCheckbox = AceGUI:Create("CheckBox")
	enableTomTomCompatibilityCheckbox:SetLabel("Enable TomTom Compatibility")
	enableTomTomCompatibilityCheckbox:SetValue(RQE.db.profile.enableTomTomCompatibility)
	enableTomTomCompatibilityCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableTomTomCompatibility = value
	end)

	enableTomTomCompatibilityCheckbox:SetFullWidth(false)
	enableTomTomCompatibilityCheckbox:SetWidth(300)

	-- Add a tooltip description for enableTomTomCompatibilityCheckbox (RQE.db.profile.enableTomTomCompatibility)
	enableTomTomCompatibilityCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("If enabled will create waypoints via TomTom addon (if you have this addon also installed)", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableTomTomCompatibilityCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableTomTomCompatibilityCheckbox)

	-- Enable Carbonite Compatibility Checkbox
	local enableCarboniteCompatibilityCheckbox = AceGUI:Create("CheckBox")
	enableCarboniteCompatibilityCheckbox:SetLabel("Enable Carbonite Compatibility")
	enableCarboniteCompatibilityCheckbox:SetValue(RQE.db.profile.enableCarboniteCompatibility)
	enableCarboniteCompatibilityCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableCarboniteCompatibility = value
	end)

	enableCarboniteCompatibilityCheckbox:SetFullWidth(false)
	enableCarboniteCompatibilityCheckbox:SetWidth(300)

	-- Add a tooltip description for enableCarboniteCompatibilityCheckbox (RQE.db.profile.enableCarboniteCompatibility)
	enableCarboniteCompatibilityCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("If enabled will create waypoints via Carbonite addon (if you have this addon also installed)", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableCarboniteCompatibilityCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableCarboniteCompatibilityCheckbox)

	-- Enable SuperTrack Nearest Checkbox
	local enableNearestSuperTrack = AceGUI:Create("CheckBox")
	enableNearestSuperTrack:SetLabel("Enable SuperTrack Nearest")
	enableNearestSuperTrack:SetValue(RQE.db.profile.enableNearestSuperTrack)
	enableNearestSuperTrack:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableNearestSuperTrack = value
	end)

	enableNearestSuperTrack:SetFullWidth(false)
	enableNearestSuperTrack:SetWidth(300)

	-- Add a tooltip description for enableNearestSuperTrack (RQE.db.profile.enableNearestSuperTrack)
	enableNearestSuperTrack:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Enable SuperTracking nearest when quest frame changes, such as turning in a quest, if not already supertracking)", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableNearestSuperTrack:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableNearestSuperTrack)

	-- Enable QuestType Display Checkbox
	local enableQuestTypeDisplay = AceGUI:Create("CheckBox")
	enableQuestTypeDisplay:SetLabel("Enable QuestType Info")
	enableQuestTypeDisplay:SetValue(RQE.db.profile.enableQuestTypeDisplay)
	enableQuestTypeDisplay:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.enableQuestTypeDisplay = value
	end)

	enableQuestTypeDisplay:SetFullWidth(false)
	enableQuestTypeDisplay:SetWidth(300)

	-- Add a tooltip description for enableQuestTypeDisplay (RQE.db.profile.enableQuestTypeDisplay)
	enableQuestTypeDisplay:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Enable visual information of the quest type in the Quest Tracker\n\n|cFFFF3333Reload of the UI may be required to get quest anchors to line up properly.|r", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	enableQuestTypeDisplay:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(enableQuestTypeDisplay)

	-- Key Binding for Macro Keybinding
	local keyBindSettingKeybind = AceGUI:Create("Keybinding")
	keyBindSettingKeybind:SetLabel("Key Binding for Macro")
	keyBindSettingKeybind:SetKey(RQE.db.profile.keyBindSetting)
	keyBindSettingKeybind:SetCallback("OnKeyChanged", function(widget, event, key)
		RQE.db.profile.keyBindSetting = key
		RQE:ReapplyMacroBinding()
		RQE:SetupOverrideMacroBinding()
	end)

	-- Add a tooltip description for keyBindSettingKeybind (RQE.db.profile.keyBindSetting)
	keyBindSettingKeybind:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Specify the key combination for triggering the RQE Macro MagicButton", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	keyBindSettingKeybind:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	scrollFrame:AddChild(keyBindSettingKeybind)

	-- Spacer to ensure the scroll goes to the bottom
	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)
	scrollFrame:AddChild(spacer)
end


-- Displays the Widget Container Frame Settings in Config Frame
function RQE:AddFrameSettingsWidgets(container)
	-- Create a Scroll Frame
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true) -- This will allow the scroll frame to take up the full height of the parent container
	container:AddChild(scrollFrame)

	-- Create the Frame Settings
	local framePositionGroup = AceGUI:Create("InlineGroup")
	framePositionGroup:SetTitle("Frame Settings")
	framePositionGroup:SetFullWidth(true)
	framePositionGroup:SetLayout("Flow")
	scrollFrame:AddChild(framePositionGroup)

	-- Add Toggle Blizz Quest Tracker CheckBox to the Frame Settings Widgets
	local toggleBlizzObjectiveTrackerCheckbox = AceGUI:Create("CheckBox")
	toggleBlizzObjectiveTrackerCheckbox:SetLabel("Toggle Blizz Quest Tracker")
	toggleBlizzObjectiveTrackerCheckbox:SetDescription("Show/Hide Blizzard's Quest Tracker")
	toggleBlizzObjectiveTrackerCheckbox:SetValue(RQE.db.profile.toggleBlizzObjectiveTracker)
	toggleBlizzObjectiveTrackerCheckbox:SetFullWidth(true)
	toggleBlizzObjectiveTrackerCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.toggleBlizzObjectiveTracker = value
	end)

	-- Optionally add a tooltip for more information
	toggleBlizzObjectiveTrackerCheckbox:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Toggles the visibility of Blizzard's default quest tracker frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	toggleBlizzObjectiveTrackerCheckbox:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	-- Add the checkbox to the desired group (e.g., framePositionGroup)
	framePositionGroup:AddChild(toggleBlizzObjectiveTrackerCheckbox)

	-- Main Frame Position Group
	local framePositionGroup = AceGUI:Create("InlineGroup")
	framePositionGroup:SetTitle("Main Frame Position")
	framePositionGroup:SetFullWidth(true)
	framePositionGroup:SetLayout("Flow")
	scrollFrame:AddChild(framePositionGroup)

	-- Anchor Points List
	local anchorPoints = {
		TOPLEFT = "TOPLEFT",
		TOP = "TOP",
		TOPRIGHT = "TOPRIGHT",
		LEFT = "LEFT",
		CENTER = "CENTER",
		RIGHT = "RIGHT",
		BOTTOMLEFT = "BOTTOMLEFT",
		BOTTOM = "BOTTOM",
		BOTTOMRIGHT = "BOTTOMRIGHT",
	}

	-- Anchor Point Dropdown for Main Frame
	local anchorPointDropdown = AceGUI:Create("Dropdown")
	anchorPointDropdown:SetLabel("Anchor Point")
	anchorPointDropdown:SetList(anchorPoints)
	anchorPointDropdown:SetValue(RQE.db.profile.framePosition.anchorPoint)
	anchorPointDropdown:SetFullWidth(true)
	anchorPointDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.framePosition.anchorPoint = value
		RQE:UpdateFramePosition()
	end)

	-- Add a tooltip description for anchorPointDropdown (RQE.db.profile.framePosition.anchorPoint)
	anchorPointDropdown:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("The point where the frame will be anchored.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	anchorPointDropdown:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	framePositionGroup:AddChild(anchorPointDropdown)

	-- X Position Slider
	local xPosSlider = AceGUI:Create("Slider")
	xPosSlider:SetLabel("X Position")
	xPosSlider:SetSliderValues(-500, 500, 1)
	xPosSlider:SetValue(RQE.db.profile.framePosition.xPos)
	xPosSlider:SetFullWidth(true)
	xPosSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.framePosition.xPos = value
		RQE:UpdateFramePosition()
	end)
	framePositionGroup:AddChild(xPosSlider)

	-- Y Position Slider
	local yPosSlider = AceGUI:Create("Slider")
	yPosSlider:SetLabel("Y Position")
	yPosSlider:SetSliderValues(-500, 500, 1)
	yPosSlider:SetValue(RQE.db.profile.framePosition.yPos)
	yPosSlider:SetFullWidth(true)
	yPosSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.framePosition.yPos = value
		RQE:UpdateFramePosition()
	end)
	framePositionGroup:AddChild(yPosSlider)

	-- Frame Opacity Slider
	local frameOpacitySlider = AceGUI:Create("Slider")
	frameOpacitySlider:SetLabel("Quest Helper Opacity")
	frameOpacitySlider:SetSliderValues(0, 1, 0.01)
	frameOpacitySlider:SetIsPercent(true)
	frameOpacitySlider:SetValue(RQE.db.profile.MainFrameOpacity)
	frameOpacitySlider:SetFullWidth(true)
	frameOpacitySlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.MainFrameOpacity = value
		RQE:UpdateFrameOpacity()
	end)

	-- Add a tooltip description for frameOpacitySlider (RQE.db.profile.MainFrameOpacity)
	frameOpacitySlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the opacity of the main helper frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	frameOpacitySlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	framePositionGroup:AddChild(frameOpacitySlider)

	-- Frame Width Slider
	local frameWidthSlider = AceGUI:Create("Slider")
	frameWidthSlider:SetLabel("Frame Width")
	frameWidthSlider:SetSliderValues(100, 800, 1)
	frameWidthSlider:SetValue(RQE.db.profile.framePosition.frameWidth)
	frameWidthSlider:SetFullWidth(true)
	frameWidthSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.framePosition.frameWidth = value
		RQE:UpdateFrameSize()
	end)

	-- Add a tooltip description for frameWidthSlider (RQE.db.profile.framePosition.frameWidth)
	frameWidthSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the width of the super tracking frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	frameWidthSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	framePositionGroup:AddChild(frameWidthSlider)

	-- Frame Height Slider
	local frameHeightSlider = AceGUI:Create("Slider")
	frameHeightSlider:SetLabel("Frame Height")
	frameHeightSlider:SetSliderValues(100, 800, 1)
	frameHeightSlider:SetValue(RQE.db.profile.framePosition.frameHeight)
	frameHeightSlider:SetFullWidth(true)
	frameHeightSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.framePosition.frameHeight = value
		RQE:UpdateFrameSize()
	end)

	-- Add a tooltip description for frameHeightSlider (RQE.db.profile.framePosition.frameHeight)
	frameHeightSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the height of the super tracking frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	frameHeightSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	framePositionGroup:AddChild(frameHeightSlider)

	-- Quest Frame Position Group
	local questFramePositionGroup = AceGUI:Create("InlineGroup")
	questFramePositionGroup:SetTitle("Quest Frame Position")
	questFramePositionGroup:SetFullWidth(true)
	questFramePositionGroup:SetLayout("Flow")
	scrollFrame:AddChild(questFramePositionGroup)

	-- Anchor Point Dropdown for Quest Frame
	local questAnchorPointDropdown = AceGUI:Create("Dropdown")
	questAnchorPointDropdown:SetLabel("Anchor Point")
	questAnchorPointDropdown:SetList(anchorPoints)
	questAnchorPointDropdown:SetValue(RQE.db.profile.QuestFramePosition.anchorPoint)
	questAnchorPointDropdown:SetFullWidth(true)
	questAnchorPointDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFramePosition.anchorPoint = value
		RQE:UpdateQuestFramePosition()
	end)

	-- Add a tooltip description for questAnchorPointDropdown (RQE.db.profile.QuestFramePosition.anchorPoint)
	questAnchorPointDropdown:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("The point where the quest frame will be anchored.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questAnchorPointDropdown:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questFramePositionGroup:AddChild(questAnchorPointDropdown)

	-- Quest Frame X Position Slider
	local questXPosSlider = AceGUI:Create("Slider")
	questXPosSlider:SetLabel("X Position")
	questXPosSlider:SetSliderValues(-500, 500, 1)
	questXPosSlider:SetValue(RQE.db.profile.QuestFramePosition.xPos)
	questXPosSlider:SetFullWidth(true)
	questXPosSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFramePosition.xPos = value
		RQE:UpdateQuestFramePosition()
	end)
	questFramePositionGroup:AddChild(questXPosSlider)

	-- Quest Frame Y Position Slider
	local questYPosSlider = AceGUI:Create("Slider")
	questYPosSlider:SetLabel("Y Position")
	questYPosSlider:SetSliderValues(-500, 500, 1)
	questYPosSlider:SetValue(RQE.db.profile.QuestFramePosition.yPos)
	questYPosSlider:SetFullWidth(true)
	questYPosSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFramePosition.yPos = value
		RQE:UpdateQuestFramePosition()
	end)
	questFramePositionGroup:AddChild(questYPosSlider)

	-- Quest Frame Opacity Slider
	local questFrameOpacitySlider = AceGUI:Create("Slider")
	questFrameOpacitySlider:SetLabel("Quest Tracker Opacity")
	questFrameOpacitySlider:SetSliderValues(0, 1, 0.01)
	questFrameOpacitySlider:SetIsPercent(true)
	questFrameOpacitySlider:SetValue(RQE.db.profile.QuestFrameOpacity)
	questFrameOpacitySlider:SetFullWidth(true)
	questFrameOpacitySlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFrameOpacity = value
		RQE:UpdateFrameOpacity()
	end)

	-- Add a tooltip description for questFrameOpacitySlider (RQE.db.profile.QuestFrameOpacity)
	questFrameOpacitySlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the opacity of the quest tracking frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questFrameOpacitySlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questFramePositionGroup:AddChild(questFrameOpacitySlider)

	-- Quest Frame Width Slider
	local questFrameWidthSlider = AceGUI:Create("Slider")
	questFrameWidthSlider:SetLabel("Frame Width")
	questFrameWidthSlider:SetSliderValues(100, 800, 1)
	questFrameWidthSlider:SetValue(RQE.db.profile.QuestFramePosition.frameWidth)
	questFrameWidthSlider:SetFullWidth(true)
	questFrameWidthSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFramePosition.frameWidth = value
		RQE:UpdateQuestFrameSize()
	end)

	-- Add a tooltip description for questFrameWidthSlider (RQE.db.profile.QuestFramePosition.frameWidth)
	questFrameWidthSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the width of the super tracking frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questFrameWidthSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questFramePositionGroup:AddChild(questFrameWidthSlider)

	-- Quest Frame Height Slider
	local questFrameHeightSlider = AceGUI:Create("Slider")
	questFrameHeightSlider:SetLabel("Frame Height")
	questFrameHeightSlider:SetSliderValues(100, 800, 1)
	questFrameHeightSlider:SetValue(RQE.db.profile.QuestFramePosition.frameHeight)
	questFrameHeightSlider:SetFullWidth(true)
	questFrameHeightSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.QuestFramePosition.frameHeight = value
		RQE:UpdateQuestFrameSize()
	end)

	-- Add a tooltip description for questFrameHeightSlider (RQE.db.profile.QuestFramePosition.frameHeight)
	questFrameHeightSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Adjust the height of the super tracking frame.", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questFrameHeightSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questFramePositionGroup:AddChild(questFrameHeightSlider)

	-- Spacer to ensure the scroll goes to the bottom
	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)
	scrollFrame:AddChild(spacer)
end


-- Displays the Widget Container Font Settings in Config Frame
function RQE:AddFontSettingsWidgets(container)
	-- Create a Scroll Frame
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
	container:AddChild(scrollFrame)

	-- Font Size and Color Group
	local fontSizeAndColorGroup = AceGUI:Create("InlineGroup")
	fontSizeAndColorGroup:SetTitle("Font Size and Color")
	fontSizeAndColorGroup:SetFullWidth(true)
	fontSizeAndColorGroup:SetLayout("Flow")
	scrollFrame:AddChild(fontSizeAndColorGroup)

	local colorList = {
		["ffff00"] = "Yellow",
		["00ff00"] = "Green",
		["00ff99"] = "Cyan",
		["ffffd9"] = "Canary",
		["edbf59"] = "Cream Can"
	}

	local function SetColorDropdownValue(color)
		local hexColor = string.format("%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
		return hexColor
	end

	-- Helper function to create font color dropdown
	local function CreateFontColorDropdown(group, label, profilePath)
		local dropdown = AceGUI:Create("Dropdown")
		dropdown:SetLabel(label)
		dropdown:SetList(colorList)
		dropdown:SetValue(SetColorDropdownValue(RQE.db.profile.textSettings[profilePath].color))
		dropdown:SetFullWidth(true)
		dropdown:SetCallback("OnValueChanged", function(widget, event, value)
			local r = tonumber(value:sub(1, 2), 16) / 255
			local g = tonumber(value:sub(3, 4), 16) / 255
			local b = tonumber(value:sub(5, 6), 16) / 255
			RQE.db.profile.textSettings[profilePath].color = { r, g, b }
			RQE:ConfigurationChanged()
		end)
		group:AddChild(dropdown)
	end

	-- Header Text Group
	local headerTextGroup = AceGUI:Create("InlineGroup")
	headerTextGroup:SetTitle("Header Text")
	headerTextGroup:SetFullWidth(true)
	headerTextGroup:SetLayout("Flow")
	fontSizeAndColorGroup:AddChild(headerTextGroup)

	-- Header Text Font Size Slider
	local headerFontSizeSlider = AceGUI:Create("Slider")
	headerFontSizeSlider:SetLabel("Font Size")
	headerFontSizeSlider:SetSliderValues(8, 24, 1)
	headerFontSizeSlider:SetValue(RQE.db.profile.textSettings.headerText.size)
	headerFontSizeSlider:SetFullWidth(true)
	headerFontSizeSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.headerText.size = value
		RQE:ConfigurationChanged()
	end)

	-- Add a tooltip description for headerFontSizeSlider (RQE.db.profile.textSettings.headerText.size)
	headerFontSizeSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Default: 18", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	headerFontSizeSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	headerTextGroup:AddChild(headerFontSizeSlider)

	-- Header Text Font Style Dropdown
	local headerFontStyleDropdown = AceGUI:Create("Dropdown")
	headerFontStyleDropdown:SetLabel("Font Style")
	headerFontStyleDropdown:SetList({
		["SKURRI"] = "SKURRI.TTF",
		["FRIZQT__"] = "FRIZQT__.TTF"
	})
	headerFontStyleDropdown:SetValue(RQE.db.profile.textSettings.headerText.font and RQE.db.profile.textSettings.headerText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF"))
	headerFontStyleDropdown:SetFullWidth(true)
	headerFontStyleDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.headerText.font = "Fonts\\" .. value .. ".TTF"
		RQE:ConfigurationChanged()
	end)
	headerTextGroup:AddChild(headerFontStyleDropdown)

	-- Header Text Font Color Dropdown
	CreateFontColorDropdown(headerTextGroup, "Font Color", "headerText")

	-- Quest ID Text Group
	local questIDTextGroup = AceGUI:Create("InlineGroup")
	questIDTextGroup:SetTitle("Quest ID Text")
	questIDTextGroup:SetFullWidth(true)
	questIDTextGroup:SetLayout("Flow")
	fontSizeAndColorGroup:AddChild(questIDTextGroup)

	-- Quest ID Text Font Size Slider
	local questIDFontSizeSlider = AceGUI:Create("Slider")
	questIDFontSizeSlider:SetLabel("Font Size")
	questIDFontSizeSlider:SetSliderValues(8, 24, 1)
	questIDFontSizeSlider:SetValue(RQE.db.profile.textSettings.QuestIDText.size)
	questIDFontSizeSlider:SetFullWidth(true)
	questIDFontSizeSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestIDText.size = value
		RQE:ConfigurationChanged()
	end)

	-- Add a tooltip description for questIDFontSizeSlider (RQE.db.profile.textSettings.QuestIDText.size)
	questIDFontSizeSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Default: 15", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questIDFontSizeSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questIDTextGroup:AddChild(questIDFontSizeSlider)

	-- Quest ID Text Font Style Dropdown
	local questIDFontStyleDropdown = AceGUI:Create("Dropdown")
	questIDFontStyleDropdown:SetLabel("Font Style")
	questIDFontStyleDropdown:SetList({
		["SKURRI"] = "SKURRI.TTF",
		["FRIZQT__"] = "FRIZQT__.TTF"
	})
	questIDFontStyleDropdown:SetValue(RQE.db.profile.textSettings.QuestIDText.font and RQE.db.profile.textSettings.QuestIDText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF"))
	questIDFontStyleDropdown:SetFullWidth(true)
	questIDFontStyleDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestIDText.font = "Fonts\\" .. value .. ".TTF"
		RQE:ConfigurationChanged()
	end)
	questIDTextGroup:AddChild(questIDFontStyleDropdown)

	-- Quest ID Text Font Color Dropdown
	CreateFontColorDropdown(questIDTextGroup, "Font Color", "QuestIDText")

	-- Quest Name Text Group
	local questNameTextGroup = AceGUI:Create("InlineGroup")
	questNameTextGroup:SetTitle("Quest Name Text")
	questNameTextGroup:SetFullWidth(true)
	questNameTextGroup:SetLayout("Flow")
	fontSizeAndColorGroup:AddChild(questNameTextGroup)

	-- Quest Name Text Font Size Slider
	local questNameFontSizeSlider = AceGUI:Create("Slider")
	questNameFontSizeSlider:SetLabel("Font Size")
	questNameFontSizeSlider:SetSliderValues(8, 24, 1)
	questNameFontSizeSlider:SetValue(RQE.db.profile.textSettings.QuestNameText.size)
	questNameFontSizeSlider:SetFullWidth(true)
	questNameFontSizeSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestNameText.size = value
		RQE:ConfigurationChanged()
	end)

	-- Add a tooltip description for questNameFontSizeSlider (RQE.db.profile.textSettings.QuestNameText.size)
	questNameFontSizeSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Default: 15", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questNameFontSizeSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questNameTextGroup:AddChild(questNameFontSizeSlider)

	-- Quest Name Text Font Style Dropdown
	local questNameFontStyleDropdown = AceGUI:Create("Dropdown")
	questNameFontStyleDropdown:SetLabel("Font Style")
	questNameFontStyleDropdown:SetList({
		["SKURRI"] = "SKURRI.TTF",
		["FRIZQT__"] = "FRIZQT__.TTF"
	})
	questNameFontStyleDropdown:SetValue(RQE.db.profile.textSettings.QuestNameText.font and RQE.db.profile.textSettings.QuestNameText.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF"))
	questNameFontStyleDropdown:SetFullWidth(true)
	questNameFontStyleDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestNameText.font = "Fonts\\" .. value .. ".TTF"
		RQE:ConfigurationChanged()
	end)
	questNameTextGroup:AddChild(questNameFontStyleDropdown)

	-- Quest Name Text Font Color Dropdown
	CreateFontColorDropdown(questNameTextGroup, "Font Color", "QuestNameText")

	-- Direction Text Group
	local directionTextGroup = AceGUI:Create("InlineGroup")
	directionTextGroup:SetTitle("Direction Text")
	directionTextGroup:SetFullWidth(true)
	directionTextGroup:SetLayout("Flow")
	fontSizeAndColorGroup:AddChild(directionTextGroup)

	-- Direction Text Font Size Slider
	local directionFontSizeSlider = AceGUI:Create("Slider")
	directionFontSizeSlider:SetLabel("Font Size")
	directionFontSizeSlider:SetSliderValues(8, 24, 1)
	directionFontSizeSlider:SetValue(RQE.db.profile.textSettings.DirectionTextFrame.size)
	directionFontSizeSlider:SetFullWidth(true)
	directionFontSizeSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.DirectionTextFrame.size = value
		RQE:ConfigurationChanged()
	end)

	-- Add a tooltip description for directionFontSizeSlider (RQE.db.profile.textSettings.DirectionTextFrame.size)
	directionFontSizeSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Default: 13", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	directionFontSizeSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	directionTextGroup:AddChild(directionFontSizeSlider)

	-- Direction Text Font Style Dropdown
	local directionFontStyleDropdown = AceGUI:Create("Dropdown")
	directionFontStyleDropdown:SetLabel("Font Style")
	directionFontStyleDropdown:SetList({
		["SKURRI"] = "SKURRI.TTF",
		["FRIZQT__"] = "FRIZQT__.TTF"
	})
	directionFontStyleDropdown:SetValue(RQE.db.profile.textSettings.DirectionTextFrame.font and RQE.db.profile.textSettings.DirectionTextFrame.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF"))
	directionFontStyleDropdown:SetFullWidth(true)
	directionFontStyleDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.DirectionTextFrame.font = "Fonts\\" .. value .. ".TTF"
		RQE:ConfigurationChanged()
	end)
	directionTextGroup:AddChild(directionFontStyleDropdown)

	-- Direction Text Font Color Dropdown
	CreateFontColorDropdown(directionTextGroup, "Font Color", "DirectionTextFrame")

	-- Quest Description Group
	local questDescriptionGroup = AceGUI:Create("InlineGroup")
	questDescriptionGroup:SetTitle("Quest Description")
	questDescriptionGroup:SetFullWidth(true)
	questDescriptionGroup:SetLayout("Flow")
	fontSizeAndColorGroup:AddChild(questDescriptionGroup)

	-- Quest Description Font Size Slider
	local questDescriptionFontSizeSlider = AceGUI:Create("Slider")
	questDescriptionFontSizeSlider:SetLabel("Font Size")
	questDescriptionFontSizeSlider:SetSliderValues(8, 24, 1)
	questDescriptionFontSizeSlider:SetValue(RQE.db.profile.textSettings.QuestDescription.size)
	questDescriptionFontSizeSlider:SetFullWidth(true)
	questDescriptionFontSizeSlider:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestDescription.size = value
		RQE:ConfigurationChanged()
	end)

	-- Add a tooltip description for questDescriptionFontSizeSlider (RQE.db.profile.textSettings.QuestDescription.size)
	questDescriptionFontSizeSlider:SetCallback("OnEnter", function(widget, event)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText("Default: 14", nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	questDescriptionFontSizeSlider:SetCallback("OnLeave", function(widget, event)
		GameTooltip:Hide()
	end)

	questDescriptionGroup:AddChild(questDescriptionFontSizeSlider)

	-- Quest Description Font Style Dropdown
	local questDescriptionFontStyleDropdown = AceGUI:Create("Dropdown")
	questDescriptionFontStyleDropdown:SetLabel("Font Style")
	questDescriptionFontStyleDropdown:SetList({
		["SKURRI"] = "SKURRI.TTF",
		["FRIZQT__"] = "FRIZQT__.TTF"
	})
	questDescriptionFontStyleDropdown:SetValue(RQE.db.profile.textSettings.QuestDescription.font and RQE.db.profile.textSettings.QuestDescription.font:match("Fonts\\([a-zA-Z0-9_]+)%.TTF"))
	questDescriptionFontStyleDropdown:SetFullWidth(true)
	questDescriptionFontStyleDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db.profile.textSettings.QuestDescription.font = "Fonts\\" .. value .. ".TTF"
		RQE:ConfigurationChanged()
	end)
	questDescriptionGroup:AddChild(questDescriptionFontStyleDropdown)

	-- Quest Description Font Color Dropdown
	CreateFontColorDropdown(questDescriptionGroup, "Font Color", "QuestDescription")

	-- Spacer to ensure the scroll goes to the bottom
	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)
	scrollFrame:AddChild(spacer)
end


-- Displays the Widget Container Debug Options in Config Frame
function RQE:AddDebugSettingsWidgets(container)
	-- Create a Scroll Frame
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true) -- This will allow the scroll frame to take up the full height of the parent container
	container:AddChild(scrollFrame)

	-- Function to refresh the contents of the Debug tab
	local function RefreshDebugTab()
		scrollFrame:ReleaseChildren() -- Clear all current children

		-- Enable Debug Mode Checkbox
		local debugModeCheckbox = AceGUI:Create("CheckBox")
		debugModeCheckbox:SetLabel("Enable Debug Mode")
		debugModeCheckbox:SetValue(RQE.db.profile.debugMode)
		debugModeCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
			RQE.db.profile.debugMode = value
			RQE.db.profile.debugLevel = value and RQE.db.profile.debugLevel or "NONE"
			RefreshDebugTab()
		end)

		-- Add a tooltip description for debugModeCheckbox (RQE.db.profile.debugMode)
		debugModeCheckbox:SetCallback("OnEnter", function(widget, event)
			GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText("Enable or disable debug mode for additional logging.", nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		debugModeCheckbox:SetCallback("OnLeave", function(widget, event)
			GameTooltip:Hide()
		end)

		scrollFrame:AddChild(debugModeCheckbox)

		-- Display Memory Usage Checkbox
		local displayMemoryUsageCheckbox = AceGUI:Create("CheckBox")
		displayMemoryUsageCheckbox:SetLabel("Display Memory Usage")
		displayMemoryUsageCheckbox:SetValue(RQE.db.profile.displayRQEmemUsage)
		displayMemoryUsageCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
			RQE.db.profile.displayRQEmemUsage = value
			RQE:CheckMemoryUsage()  -- Immediately update the memory usage display
		end)

		-- Add a tooltip description for displayMemoryUsageCheckbox (RQE.db.profile.displayRQEmemUsage)
		displayMemoryUsageCheckbox:SetCallback("OnEnter", function(widget, event)
			GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText("Displays the memory usage for the RQE addon", nil, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		displayMemoryUsageCheckbox:SetCallback("OnLeave", function(widget, event)
			GameTooltip:Hide()
		end)

		scrollFrame:AddChild(displayMemoryUsageCheckbox)

		if RQE.db.profile.debugMode then
			-- Debug Logging Toggle
			local debugLoggingCheckbox = AceGUI:Create("CheckBox")
			debugLoggingCheckbox:SetLabel("Debug Logging")
			debugLoggingCheckbox:SetValue(RQE.db.profile.debugLoggingCheckbox)
			debugLoggingCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
				RQE.db.profile.debugLoggingCheckbox = value
			end)

			-- Add a tooltip description for debugLoggingCheckbox (RQE.db.profile.debugLoggingCheckbox)
			debugLoggingCheckbox:SetCallback("OnEnter", function(widget, event)
				GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
				GameTooltip:SetText("Toggles the option to log debug messages", nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)
			debugLoggingCheckbox:SetCallback("OnLeave", function(widget, event)
				GameTooltip:Hide()
			end)

			scrollFrame:AddChild(debugLoggingCheckbox)
		end

		-- Only show these options if Debug Mode is enabled
		if RQE.db.profile.debugMode then
			-- Debug Inline Group (appears when Debug Mode is enabled)
			local debugInlineGroup = AceGUI:Create("InlineGroup")
			debugInlineGroup:SetTitle("Debug")
			debugInlineGroup:SetFullWidth(true)
			debugInlineGroup:SetLayout("Flow")
			scrollFrame:AddChild(debugInlineGroup)

			-- Debug Level Dropdown
			local debugLevelDropdown = AceGUI:Create("Dropdown")
			debugLevelDropdown:SetLabel("Debug Level")
			debugLevelDropdown:SetList(debugLevelOptions)
			debugLevelDropdown:SetValue(getDebugLevelIndex(RQE.db.profile.debugLevel))
			debugLevelDropdown:SetCallback("OnValueChanged", function(widget, event, value)
				RQE.db.profile.debugLevel = debugLevelOptions[value]
				RefreshDebugTab()  -- Refresh the tab after changing the debug level
			end)

			-- Add a tooltip description for debugLevelDropdown (RQE.db.profile.debugLevel)
			debugLevelDropdown:SetCallback("OnEnter", function(widget, event)
				GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
				GameTooltip:SetText("Set the level of debug logging.", nil, nil, nil, nil, true)
				GameTooltip:Show()
			end)
			debugLevelDropdown:SetCallback("OnLeave", function(widget, event)
				GameTooltip:Hide()
			end)

			debugInlineGroup:AddChild(debugLevelDropdown)

			-- Reset Frame Position Button (only shown if debug level is "INFO")
			if RQE.db.profile.debugLevel == "INFO" or RQE.db.profile.debugLevel == "INFO+" then
				local resetFramePositionButton = AceGUI:Create("Button")
				resetFramePositionButton:SetText("Reset Position")
				resetFramePositionButton:SetCallback("OnClick", function()
					RQE:ResetFramePositionToDBorDefault()
					RQE:ResetQuestFramePositionToDBorDefault()
				end)
				debugInlineGroup:AddChild(resetFramePositionButton)

				local resetFrameSizeButton = AceGUI:Create("Button")
				resetFrameSizeButton:SetText("Reset Size")
				resetFrameSizeButton:SetCallback("OnClick", function()
					RQE:ResetFrameSizeToDBorDefault()
				end)
				debugInlineGroup:AddChild(resetFrameSizeButton)
			end

			-- Additional options for "INFO+" level
			if RQE.db.profile.debugLevel == "INFO+" then
				-- Checkbox for displaying specific event debug info
				local showEventDebugInfoCheckbox = AceGUI:Create("CheckBox")
				showEventDebugInfoCheckbox:SetLabel("Show Event Debug Info")
				showEventDebugInfoCheckbox:SetValue(RQE.db.profile.showEventDebugInfo)
				showEventDebugInfoCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showEventDebugInfo = value
				end)

				-- Add tooltip for the Show Event Debug Info checkbox
				showEventDebugInfoCheckbox:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug information for specific events.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showEventDebugInfoCheckbox:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showEventDebugInfoCheckbox)

				-- Checkbox for displaying Argument/Payload returns on event listeners
				local showArgPayloadInfo = AceGUI:Create("CheckBox")
				showArgPayloadInfo:SetLabel("Show Arg/Payload Info")
				showArgPayloadInfo:SetValue(RQE.db.profile.showArgPayloadInfo)
				showArgPayloadInfo:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showArgPayloadInfo = value
				end)

				-- Add tooltip for the Argument/Payload returns checkbox
				showArgPayloadInfo:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Display Argument/Payload Info for events.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showArgPayloadInfo:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showArgPayloadInfo)

				-- Checkbox for displaying RQE:StartPeriodicChecks() returns
				local showStartPeriodicCheckInfo = AceGUI:Create("CheckBox")
				showStartPeriodicCheckInfo:SetLabel("Show StartPeriodicChecks Info")
				showStartPeriodicCheckInfo:SetValue(RQE.db.profile.showStartPeriodicCheckInfo)
				showStartPeriodicCheckInfo:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showStartPeriodicCheckInfo = value
				end)

				-- Add tooltip for the Argument/Payload returns checkbox
				showStartPeriodicCheckInfo:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Display StartPeriodicChecks Info for events.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showStartPeriodicCheckInfo:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showStartPeriodicCheckInfo)

				-- Checkbox for displaying ADDON_LOADED event debug info
				local showAddonLoaded = AceGUI:Create("CheckBox")
				showAddonLoaded:SetLabel("Show ADDON_LOADED Event Info")
				showAddonLoaded:SetValue(RQE.db.profile.showAddonLoaded)
				showAddonLoaded:SetFullWidth(true)	-- Make the checkbox full width
				showAddonLoaded:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showAddonLoaded = value
				end)

				-- Add tooltip for the ADDON_LOADED event checkbox
				showAddonLoaded:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the ADDON LOADED event listener.\n\n|cFF4AA458Fires after an AddOn has been loaded and is typically the first event to fire (running after all .lua files have been run and SavedVariables have loaded).|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showAddonLoaded:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showAddonLoaded)

				-- Checkbox for displaying ACHIEVEMENT_EARNED event debug info
				local showEventAchievementEarned = AceGUI:Create("CheckBox")
				showEventAchievementEarned:SetLabel("Show ACHIEVEMENT_EARNED Event Info")
				showEventAchievementEarned:SetValue(RQE.db.profile.showEventAchievementEarned)
				showEventAchievementEarned:SetFullWidth(true)	-- Make the checkbox full width
				showEventAchievementEarned:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showEventAchievementEarned = value
				end)

				-- Add tooltip for the ACHIEVEMENT_EARNED event checkbox
				showEventAchievementEarned:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the ACHIEVEMENT EARNED event listener.\n\n|cFF4AA458Fired when an achievement is gained.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showEventAchievementEarned:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showEventAchievementEarned)

				-- Checkbox for displaying BOSS_KILL event debug info
				local BossKill = AceGUI:Create("CheckBox")
				BossKill:SetLabel("Show BOSS_KILL Event Info")
				BossKill:SetValue(RQE.db.profile.BossKill)
				BossKill:SetFullWidth(true)	-- Make the checkbox full width
				BossKill:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.BossKill = value
				end)

				-- Add tooltip for the BOSS_KILL event checkbox
				BossKill:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the BOSS KILL event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				BossKill:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(BossKill)

				-- Checkbox for displaying CLIENT_SCENE_CLOSED event debug info
				local ClientSceneClosed = AceGUI:Create("CheckBox")
				ClientSceneClosed:SetLabel("Show CLIENT_SCENE_CLOSED Event Info")
				ClientSceneClosed:SetValue(RQE.db.profile.ClientSceneClosed)
				ClientSceneClosed:SetFullWidth(true)	-- Make the checkbox full width
				ClientSceneClosed:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ClientSceneClosed = value
				end)

				-- Add tooltip for the CLIENT_SCENE_CLOSED event checkbox
				ClientSceneClosed:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the CLIENT SCENE CLOSED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ClientSceneClosed:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ClientSceneClosed)

				-- Checkbox for displaying CLIENT_SCENE_OPENED event debug info
				local ClientSceneOpened = AceGUI:Create("CheckBox")
				ClientSceneOpened:SetLabel("Show CLIENT_SCENE_OPENED Event Info")
				ClientSceneOpened:SetValue(RQE.db.profile.ClientSceneOpened)
				ClientSceneOpened:SetFullWidth(true)	-- Make the checkbox full width
				ClientSceneOpened:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ClientSceneOpened = value
				end)

				-- Add tooltip for the CLIENT_SCENE_OPENED event checkbox
				ClientSceneOpened:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the CLIENT SCENE OPENED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ClientSceneOpened:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ClientSceneOpened)

				-- Checkbox for displaying CONTENT_TRACKING_UPDATE event debug info
				local showEventContentTrackingUpdate = AceGUI:Create("CheckBox")
				showEventContentTrackingUpdate:SetLabel("Show CONTENT_TRACKING_UPDATE Event Info")
				showEventContentTrackingUpdate:SetValue(RQE.db.profile.showEventContentTrackingUpdate)
				showEventContentTrackingUpdate:SetFullWidth(true)	-- Make the checkbox full width
				showEventContentTrackingUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showEventContentTrackingUpdate = value
				end)

				-- Add tooltip for the CONTENT_TRACKING_UPDATE event checkbox
				showEventContentTrackingUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the CONTENT TRACKING UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showEventContentTrackingUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showEventContentTrackingUpdate)

				-- Checkbox for displaying CRITERIA_EARNED event debug info
				local showEventCriteriaEarned = AceGUI:Create("CheckBox")
				showEventCriteriaEarned:SetLabel("Show CRITERIA_EARNED Event Info")
				showEventCriteriaEarned:SetValue(RQE.db.profile.showEventCriteriaEarned)
				showEventCriteriaEarned:SetFullWidth(true)	-- Make the checkbox full width
				showEventCriteriaEarned:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showEventCriteriaEarned = value
				end)

				-- Add tooltip for the CRITERIA_EARNED event checkbox
				showEventCriteriaEarned:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the CRITERIA EARNED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showEventCriteriaEarned:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showEventCriteriaEarned)

				-- Checkbox for displaying ENCOUNTER_END event debug info
				local EncounterEnd = AceGUI:Create("CheckBox")
				EncounterEnd:SetLabel("Show ENCOUNTER_END Event Info")
				EncounterEnd:SetValue(RQE.db.profile.EncounterEnd)
				EncounterEnd:SetFullWidth(true)	-- Make the checkbox full width
				EncounterEnd:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.EncounterEnd = value
				end)

				-- Add tooltip for the ENCOUNTER_END event checkbox
				EncounterEnd:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the ENCOUNTER END event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				EncounterEnd:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(EncounterEnd)

				-- Checkbox for displaying ITEM_COUNT_CHANGED event debug info
				local showItemCountChanged = AceGUI:Create("CheckBox")
				showItemCountChanged:SetLabel("Show ITEM_COUNT_CHANGED Event Info")
				showItemCountChanged:SetValue(RQE.db.profile.showItemCountChanged)
				showItemCountChanged:SetFullWidth(true)	-- Make the checkbox full width
				showItemCountChanged:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showItemCountChanged = value
				end)

				-- Add tooltip for the ITEM_COUNT_CHANGED event checkbox
				showItemCountChanged:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the ITEM COUNT CHANGED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showItemCountChanged:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showItemCountChanged)

				-- Checkbox for displaying JAILERS_TOWER_LEVEL_UPDATE event debug info
				local JailorsTowerLevelUpdate = AceGUI:Create("CheckBox")
				JailorsTowerLevelUpdate:SetLabel("Show JAILERS_TOWER_LEVEL_UPDATE Event Info")
				JailorsTowerLevelUpdate:SetValue(RQE.db.profile.JailorsTowerLevelUpdate)
				JailorsTowerLevelUpdate:SetFullWidth(true)	-- Make the checkbox full width
				JailorsTowerLevelUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.JailorsTowerLevelUpdate = value
				end)

				-- Add tooltip for the JAILERS_TOWER_LEVEL_UPDATE event checkbox
				JailorsTowerLevelUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the JAILERS TOWER LEVEL UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				JailorsTowerLevelUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(JailorsTowerLevelUpdate)

				-- Checkbox for displaying LFG_LIST_ACTIVE_ENTRY_UPDATE event debug info
				local LFGActiveEntryUpdate = AceGUI:Create("CheckBox")
				LFGActiveEntryUpdate:SetLabel("Show LFG_LIST_ACTIVE_ENTRY_UPDATE Event Info")
				LFGActiveEntryUpdate:SetValue(RQE.db.profile.LFGActiveEntryUpdate)
				LFGActiveEntryUpdate:SetFullWidth(true)	-- Make the checkbox full width
				LFGActiveEntryUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.LFGActiveEntryUpdate = value
				end)

				-- Add tooltip for the LFG_LIST_ACTIVE_ENTRY_UPDATE event checkbox
				LFGActiveEntryUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the LFG LIST ACTIVE ENTRY UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				LFGActiveEntryUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(LFGActiveEntryUpdate)

				-- Checkbox for displaying PLAYER_REGEN_ENABLED event debug info
				local showPlayerRegenEnabled = AceGUI:Create("CheckBox")
				showPlayerRegenEnabled:SetLabel("Show PLAYER_REGEN Event Info")
				showPlayerRegenEnabled:SetValue(RQE.db.profile.showPlayerRegenEnabled)
				showPlayerRegenEnabled:SetFullWidth(true)	-- Make the checkbox full width
				showPlayerRegenEnabled:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showPlayerRegenEnabled = value
				end)

				-- Add tooltip for the PLAYER_REGEN_ENABLED event checkbox
				showPlayerRegenEnabled:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER REGEN ENABLED event listener.\n\n|cFF4AA458Fired after ending combat, as regen rates return to normal. Useful for determining when a player has left combat. This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showPlayerRegenEnabled:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showPlayerRegenEnabled)

				-- Checkbox for displaying PLAYER_MOUNT_DISPLAY_CHANGED event debug info
				local showPlayerMountDisplayChanged = AceGUI:Create("CheckBox")
				showPlayerMountDisplayChanged:SetLabel("Show PLAYER_MOUNT Event Info")
				showPlayerMountDisplayChanged:SetValue(RQE.db.profile.showPlayerMountDisplayChanged)
				showPlayerMountDisplayChanged:SetFullWidth(true)	-- Make the checkbox full width
				showPlayerMountDisplayChanged:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showPlayerMountDisplayChanged = value
				end)

				-- Add tooltip for the PLAYER_MOUNT_DISPLAY_CHANGED event checkbox
				showPlayerMountDisplayChanged:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER MOUNT DISPLAY CHANGED event listener.\n\n|cFF4AA458Fired after activating/deactivating a player mount.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showPlayerMountDisplayChanged:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showPlayerMountDisplayChanged)

				-- Checkbox for displaying PLAYER_LOGIN event debug info
				local showPlayerLogin = AceGUI:Create("CheckBox")
				showPlayerLogin:SetLabel("Show PLAYER_LOGIN Event Info")
				showPlayerLogin:SetValue(RQE.db.profile.showPlayerLogin)
				showPlayerLogin:SetFullWidth(true)	-- Make the checkbox full width
				showPlayerLogin:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showPlayerLogin = value
				end)

				-- Add tooltip for the PLAYER_LOGIN event checkbox
				showPlayerLogin:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER LOGIN event listener.\n\n|cFF4AA458Triggered immediately before PLAYER_ENTERING_WORLD on login and UI Reload, but NOT when entering/leaving instances.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showPlayerLogin:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showPlayerLogin)

				-- Checkbox for displaying PLAYER_ENTERING_WORLD event debug info
				local PlayerEnteringWorld = AceGUI:Create("CheckBox")
				PlayerEnteringWorld:SetLabel("Show PLAYER_ENTERING_WORLD Event Info")
				PlayerEnteringWorld:SetValue(RQE.db.profile.PlayerEnteringWorld)
				PlayerEnteringWorld:SetFullWidth(true)	-- Make the checkbox full width
				PlayerEnteringWorld:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.PlayerEnteringWorld = value
				end)

				-- Add tooltip for the PLAYER_ENTERING_WORLD event checkbox
				PlayerEnteringWorld:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER ENTERING WORLD event listener.\n\n|cFF4AA458Fires when the player logs in, /reloads the UI or zones between map instances. Basically whenever the loading screen appears.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				PlayerEnteringWorld:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(PlayerEnteringWorld)

				-- Checkbox for displaying PLAYER_STARTED_MOVING event debug info
				local PlayerStartedMoving = AceGUI:Create("CheckBox")
				PlayerStartedMoving:SetLabel("Show PLAYER_STARTED_MOVING Event Info")
				PlayerStartedMoving:SetValue(RQE.db.profile.PlayerStartedMoving)
				PlayerStartedMoving:SetFullWidth(true)	-- Make the checkbox full width
				PlayerStartedMoving:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.PlayerStartedMoving = value
				end)

				-- Add tooltip for the PLAYER_STARTED_MOVING event checkbox
				PlayerStartedMoving:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER STARTED MOVING event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				PlayerStartedMoving:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(PlayerStartedMoving)

				-- Checkbox for displaying PLAYER_STOPPED_MOVING event debug info
				local PlayerStoppedMoving = AceGUI:Create("CheckBox")
				PlayerStoppedMoving:SetLabel("Show PLAYER_STOPPED_MOVING Event Info")
				PlayerStoppedMoving:SetValue(RQE.db.profile.PlayerStoppedMoving)
				PlayerStoppedMoving:SetFullWidth(true)	-- Make the checkbox full width
				PlayerStoppedMoving:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.PlayerStoppedMoving = value
				end)

				-- Add tooltip for the PLAYER_STOPPED_MOVING event checkbox
				PlayerStoppedMoving:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the PLAYER STOPPED MOVING event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				PlayerStoppedMoving:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(PlayerStoppedMoving)

				-- Checkbox for displaying QUEST_ACCEPTED event debug info
				local QuestAccepted = AceGUI:Create("CheckBox")
				QuestAccepted:SetLabel("Show QUEST_ACCEPTED Event Info")
				QuestAccepted:SetValue(RQE.db.profile.QuestAccepted)
				QuestAccepted:SetFullWidth(true)	-- Make the checkbox full width
				QuestAccepted:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestAccepted = value
				end)

				-- Add tooltip for the QUEST_ACCEPTED event checkbox
				QuestAccepted:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST ACCEPTED event listener.\n\n|cFF4AA458Fires whenever the player accepts a quest.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestAccepted:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestAccepted)

				-- Checkbox for displaying QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE event debug info
				local QuestStatusUpdate = AceGUI:Create("CheckBox")
				QuestStatusUpdate:SetLabel("Show various Quest Status Update Event Info")
				QuestStatusUpdate:SetValue(RQE.db.profile.QuestStatusUpdate)
				QuestStatusUpdate:SetFullWidth(true)	-- Make the checkbox full width
				QuestStatusUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestStatusUpdate = value
				end)

				-- Add tooltip for the QUEST_LOG_UPDATE, QUEST_POI_UPDATE and TASK_PROGRESS_UPDATE event checkbox
				QuestStatusUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST LOG UPDATE, QUEST POI UPDATE and TASK PROGRESS UPDATE event listener.\n\n|cFF4AA458Fires when the quest log updates, or whenever Quest POIs change (For example after accepting an quest).|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestStatusUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestStatusUpdate)

				-- Checkbox for displaying QUEST_CURRENCY_LOOT_RECEIVED event debug info
				local QuestCurrencyLootReceived = AceGUI:Create("CheckBox")
				QuestCurrencyLootReceived:SetLabel("Show QUEST_CURRENCY_LOOT_RECEIVED Event Info")
				QuestCurrencyLootReceived:SetValue(RQE.db.profile.QuestCurrencyLootReceived)
				QuestCurrencyLootReceived:SetFullWidth(true)	-- Make the checkbox full width
				QuestCurrencyLootReceived:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestCurrencyLootReceived = value
				end)

				-- Add tooltip for the QUEST_CURRENCY_LOOT_RECEIVED event checkbox
				QuestCurrencyLootReceived:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST CURRENCY LOOT RECEIVED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestCurrencyLootReceived:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestCurrencyLootReceived)

				-- Checkbox for displaying QUEST_LOG_CRITERIA_UPDATE event debug info
				local QuestLogCriteriaUpdate = AceGUI:Create("CheckBox")
				QuestLogCriteriaUpdate:SetLabel("Show QUEST_LOG_CRITERIA_UPDATE Event Info")
				QuestLogCriteriaUpdate:SetValue(RQE.db.profile.QuestLogCriteriaUpdate)
				QuestLogCriteriaUpdate:SetFullWidth(true)	-- Make the checkbox full width
				QuestLogCriteriaUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestLogCriteriaUpdate = value
				end)

				-- Add tooltip for the QUEST_LOG_CRITERIA_UPDATE event checkbox
				QuestLogCriteriaUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST LOG CRITERIA UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestLogCriteriaUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestLogCriteriaUpdate)

				-- Checkbox for displaying QUEST_LOOT_RECEIVED event debug info
				local QuestLootReceived = AceGUI:Create("CheckBox")
				QuestLootReceived:SetLabel("Show QUEST_LOOT_RECEIVED Event Info")
				QuestLootReceived:SetValue(RQE.db.profile.QuestLootReceived)
				QuestLootReceived:SetFullWidth(true)	-- Make the checkbox full width
				QuestLootReceived:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestLootReceived = value
				end)

				-- Add tooltip for the QUEST_LOOT_RECEIVED event checkbox
				QuestLootReceived:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST LOOT RECEIVED event listener.\n\n|cFF4AA458Fires when player receives loot from quest turn in (Runs once per quest loot received).|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestLootReceived:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestLootReceived)

				-- Checkbox for displaying QUESTLINE_UPDATE event debug info
				local QuestlineUpdate = AceGUI:Create("CheckBox")
				QuestlineUpdate:SetLabel("Show QUESTLINE_UPDATE Event Info")
				QuestlineUpdate:SetValue(RQE.db.profile.QuestlineUpdate)
				QuestlineUpdate:SetFullWidth(true)	-- Make the checkbox full width
				QuestlineUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestlineUpdate = value
				end)

				-- Add tooltip for the QUESTLINE_UPDATE event checkbox
				QuestlineUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUESTLINE UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestlineUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestlineUpdate)

				-- Checkbox for displaying QUEST_COMPLETE event debug info
				local QuestComplete = AceGUI:Create("CheckBox")
				QuestComplete:SetLabel("Show QUEST_COMPLETE Event Info")
				QuestComplete:SetValue(RQE.db.profile.QuestComplete)
				QuestComplete:SetFullWidth(true)	-- Make the checkbox full width
				QuestComplete:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestComplete = value
				end)

				-- Add tooltip for the QUEST_COMPLETE event checkbox
				QuestComplete:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST COMPLETE event listener.\n\n|cFF4AA458Fired after the player hits the 'Continue' button in the quest-information page, before the 'Complete Quest' button. In other words, it fires when you are given the option to complete a quest, but just before you actually complete the quest. .|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestComplete:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestComplete)

				-- Checkbox for displaying QUEST_AUTOCOMPLETE event debug info
				local QuestAutocomplete = AceGUI:Create("CheckBox")
				QuestAutocomplete:SetLabel("Show QUEST_AUTOCOMPLETE Event Info")
				QuestAutocomplete:SetValue(RQE.db.profile.QuestAutocomplete)
				QuestAutocomplete:SetFullWidth(true)	-- Make the checkbox full width
				QuestAutocomplete:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestAutocomplete = value
				end)

				-- Add tooltip for the QUEST_AUTOCOMPLETE event checkbox
				QuestAutocomplete:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST AUTOCOMPLETE event listener.\n\n|cFF4AA458Fires when a quest that can be auto-completed is completed.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestAutocomplete:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestAutocomplete)

				-- Checkbox for displaying QUEST_REMOVED event debug info
				local QuestRemoved = AceGUI:Create("CheckBox")
				QuestRemoved:SetLabel("Show QUEST_REMOVED Event Info")
				QuestRemoved:SetValue(RQE.db.profile.QuestRemoved)
				QuestRemoved:SetFullWidth(true)	-- Make the checkbox full width
				QuestRemoved:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestRemoved = value
				end)

				-- Add tooltip for the QUEST_REMOVED event checkbox
				QuestRemoved:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST REMOVED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestRemoved:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestRemoved)

				-- Checkbox for displaying QUEST_WATCH_UPDATE event debug info
				local QuestWatchUpdate = AceGUI:Create("CheckBox")
				QuestWatchUpdate:SetLabel("Show QUEST_WATCH_UPDATE Event Info")
				QuestWatchUpdate:SetValue(RQE.db.profile.QuestWatchUpdate)
				QuestWatchUpdate:SetFullWidth(true)	-- Make the checkbox full width
				QuestWatchUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestWatchUpdate = value
				end)

				-- Add tooltip for the QUEST_WATCH_UPDATE event checkbox
				QuestWatchUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST WATCH UPDATE event listener.\n\n|cFF4AA458Fires each time the objectives of the quest with the supplied questID update, i.e. whenever a partial objective has been accomplished: killing a mob, looting a quest item etc. UNIT_QUEST_LOG_CHANGED and QUEST_LOG_UPDATE both also seem to fire consistently – in that order – after each QUEST_WATCH_UPDATE.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestWatchUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestWatchUpdate)

				-- Checkbox for displaying QUEST_WATCH_LIST_CHANGED event debug info
				local QuestListWatchListChanged = AceGUI:Create("CheckBox")
				QuestListWatchListChanged:SetLabel("Show QUEST_WATCH_LIST_CHANGED Event Info")
				QuestListWatchListChanged:SetValue(RQE.db.profile.QuestListWatchListChanged)
				QuestListWatchListChanged:SetFullWidth(true)	-- Make the checkbox full width
				QuestListWatchListChanged:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestListWatchListChanged = value
				end)

				-- Add tooltip for the QUEST_WATCH_LIST_CHANGED event checkbox
				QuestListWatchListChanged:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST WATCH LIST CHANGED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestListWatchListChanged:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestListWatchListChanged)

				-- Checkbox for displaying QUEST_TURNED_IN event debug info
				local QuestTurnedIn = AceGUI:Create("CheckBox")
				QuestTurnedIn:SetLabel("Show QUEST_TURNED_IN Event Info")
				QuestTurnedIn:SetValue(RQE.db.profile.QuestTurnedIn)
				QuestTurnedIn:SetFullWidth(true)	-- Make the checkbox full width
				QuestTurnedIn:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestTurnedIn = value
				end)

				-- Add tooltip for the QUEST_TURNED_IN event checkbox
				QuestTurnedIn:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST TURNED IN event listener.\n\n|cFF4AA458This event fires whenever the player turns in a quest, whether automatically with a Task-type quest (Bonus Objectives/World Quests), or by pressing the Complete button in a quest dialog window. .|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestTurnedIn:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestTurnedIn)

				-- Checkbox for displaying QUEST_FINISHED event debug info
				local QuestFinished = AceGUI:Create("CheckBox")
				QuestFinished:SetLabel("Show QUEST_FINISHED Event Info")
				QuestFinished:SetValue(RQE.db.profile.QuestFinished)
				QuestFinished:SetFullWidth(true)	-- Make the checkbox full width
				QuestFinished:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.QuestFinished = value
				end)

				-- Add tooltip for the QUEST_FINISHED event checkbox
				QuestFinished:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the QUEST FINISHED event listener.\n\n|cFF4AA458Fired whenever the quest frame changes (from Detail to Progress to Reward, etc.) or is closed.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				QuestFinished:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(QuestFinished)

				-- Checkbox for displaying SCENARIO_COMPLETED event debug info
				local ScenarioCompleted = AceGUI:Create("CheckBox")
				ScenarioCompleted:SetLabel("Show SCENARIO_COMPLETED Event Info")
				ScenarioCompleted:SetValue(RQE.db.profile.ScenarioCompleted)
				ScenarioCompleted:SetFullWidth(true)	-- Make the checkbox full width
				ScenarioCompleted:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ScenarioCompleted = value
				end)

				-- Add tooltip for the SCENARIO_COMPLETED event checkbox
				ScenarioCompleted:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the SCENARIO COMPLETED event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ScenarioCompleted:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ScenarioCompleted)

				-- Checkbox for displaying SCENARIO_CRITERIA_UPDATE event debug info
				local ScenarioCriteriaUpdate = AceGUI:Create("CheckBox")
				ScenarioCriteriaUpdate:SetLabel("Show SCENARIO_CRITERIA_UPDATE Event Info")
				ScenarioCriteriaUpdate:SetValue(RQE.db.profile.ScenarioCriteriaUpdate)
				ScenarioCriteriaUpdate:SetFullWidth(true)	-- Make the checkbox full width
				ScenarioCriteriaUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ScenarioCriteriaUpdate = value
				end)

				-- Add tooltip for the SCENARIO_CRITERIA_UPDATE event checkbox
				ScenarioCriteriaUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the SCENARIO CRITERIA UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ScenarioCriteriaUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ScenarioCriteriaUpdate)

				-- Checkbox for displaying SCENARIO_UPDATE event debug info
				local ScenarioUpdate = AceGUI:Create("CheckBox")
				ScenarioUpdate:SetLabel("Show SCENARIO_UPDATE Event Info")
				ScenarioUpdate:SetValue(RQE.db.profile.ScenarioUpdate)
				ScenarioUpdate:SetFullWidth(true)	-- Make the checkbox full width
				ScenarioUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ScenarioUpdate = value
				end)

				-- Add tooltip for the SCENARIO_UPDATE event checkbox
				ScenarioUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the SCENARIO UPDATE event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ScenarioUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ScenarioUpdate)

				-- Checkbox for displaying START_TIMER event debug info
				local StartTimer = AceGUI:Create("CheckBox")
				StartTimer:SetLabel("Show START_TIMER Event Info")
				StartTimer:SetValue(RQE.db.profile.StartTimer)
				StartTimer:SetFullWidth(true)	-- Make the checkbox full width
				StartTimer:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.StartTimer = value
				end)

				-- Add tooltip for the START_TIMER event checkbox
				StartTimer:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the START TIMER event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				StartTimer:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(StartTimer)

				-- Checkbox for displaying SUPER_TRACKING_CHANGED event debug info
				local showEventSuperTrackingChanged = AceGUI:Create("CheckBox")
				showEventSuperTrackingChanged:SetLabel("Show SUPER_TRACKING_CHANGED Event Info")
				showEventSuperTrackingChanged:SetValue(RQE.db.profile.showEventSuperTrackingChanged)
				showEventSuperTrackingChanged:SetFullWidth(true)	-- Make the checkbox full width
				showEventSuperTrackingChanged:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showEventSuperTrackingChanged = value
				end)

				-- Add tooltip for the SUPER_TRACKING_CHANGED event checkbox
				showEventSuperTrackingChanged:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the SUPER TRACKING CHANGED event listener.\n\n|cFF4AA458Fired when the actively tracked location is changed.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showEventSuperTrackingChanged:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showEventSuperTrackingChanged)

				-- Checkbox for displaying TRACKED_ACHIEVEMENT_UPDATE event debug info
				local showTrackedAchievementUpdate = AceGUI:Create("CheckBox")
				showTrackedAchievementUpdate:SetLabel("Show TRACKED_ACHIEVEMENT_UPDATE Event Info")
				showTrackedAchievementUpdate:SetValue(RQE.db.profile.showTrackedAchievementUpdate)
				showTrackedAchievementUpdate:SetFullWidth(true)	-- Make the checkbox full width
				showTrackedAchievementUpdate:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.showTrackedAchievementUpdate = value
				end)

				-- Add tooltip for the TRACKED_ACHIEVEMENT_UPDATE event checkbox
				showTrackedAchievementUpdate:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the TRACKED ACHIEVEMENT UPDATE event listener.\n\n|cFF4AA458Fired when a timed event for an achievement begins or ends. The achievement does not have to be actively tracked for this to trigger.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				showTrackedAchievementUpdate:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(showTrackedAchievementUpdate)

				-- Checkbox for displaying UNIT_EXITING_VEHICLE, ZONE_CHANGED, ZONE_CHANGED_INDOORS, and ZONE_CHANGED_NEW_AREA event debug info
				local ZoneChange = AceGUI:Create("CheckBox")
				ZoneChange:SetLabel("Show ZONE CHANGE and UNIT EXIT VEHICLE Event Info")
				ZoneChange:SetValue(RQE.db.profile.ZoneChange)
				ZoneChange:SetFullWidth(true)	-- Make the checkbox full width
				ZoneChange:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.ZoneChange = value
				end)

				-- Add tooltip for the UNIT_EXITING_VEHICLE, ZONE_CHANGED, ZONE_CHANGED_INDOORS, and ZONE_CHANGED_NEW_AREA event checkbox
				ZoneChange:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the UNIT EXITING VEHICLE, ZONE CHANGED, ZONE CHANGED INDOORS, and ZONE CHANGED NEW AREA event listener.\n\n|cFF4AA458Fired as a unit is about to exit a vehicle, as compared to UNIT_EXITED_VEHICLE which happens afterward or Fires when the player enters a subzone or when the player enters a new zone.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				ZoneChange:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(ZoneChange)

				-- Checkbox for displaying UPDATE_INSTANCE_INFO event debug info
				local UpdateInstanceInfo = AceGUI:Create("CheckBox")
				UpdateInstanceInfo:SetLabel("Show UPDATE_INSTANCE_INFO Event Info")
				UpdateInstanceInfo:SetValue(RQE.db.profile.UpdateInstanceInfo)
				UpdateInstanceInfo:SetFullWidth(true)	-- Make the checkbox full width
				UpdateInstanceInfo:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.UpdateInstanceInfo = value
				end)

				-- Add tooltip for the UPDATE_INSTANCE_INFO event checkbox
				UpdateInstanceInfo:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the UPDATE INSTANCE INFO event listener.\n\n|cFF4AA458Fired when data from RequestRaidInfo is available and also when player uses portals.|r", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				UpdateInstanceInfo:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(UpdateInstanceInfo)

				-- Checkbox for displaying WORLD_STATE_TIMER_START event debug info
				local WorldStateTimerStart = AceGUI:Create("CheckBox")
				WorldStateTimerStart:SetLabel("Show WORLD_STATE_TIMER_START Event Info")
				WorldStateTimerStart:SetValue(RQE.db.profile.WorldStateTimerStart)
				WorldStateTimerStart:SetFullWidth(true)	-- Make the checkbox full width
				WorldStateTimerStart:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.WorldStateTimerStart = value
				end)

				-- Add tooltip for the WORLD_STATE_TIMER_START event checkbox
				WorldStateTimerStart:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the WORLD STATE TIMER START event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				WorldStateTimerStart:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(WorldStateTimerStart)

				-- Checkbox for displaying WORLD_STATE_TIMER_STOP event debug info
				local WorldStateTimerStop = AceGUI:Create("CheckBox")
				WorldStateTimerStop:SetLabel("Show WORLD_STATE_TIMER_STOP Event Info")
				WorldStateTimerStop:SetValue(RQE.db.profile.WorldStateTimerStop)
				WorldStateTimerStop:SetFullWidth(true)	-- Make the checkbox full width
				WorldStateTimerStop:SetCallback("OnValueChanged", function(widget, event, value)
					RQE.db.profile.WorldStateTimerStop = value
				end)

				-- Add tooltip for the WORLD_STATE_TIMER_STOP event checkbox
				WorldStateTimerStop:SetCallback("OnEnter", function(widget, event)
					GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
					GameTooltip:SetText("Toggle the display of debug print messages for the WORLD STATE TIMER STOP event listener.", nil, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				WorldStateTimerStop:SetCallback("OnLeave", function(widget, event)
					GameTooltip:Hide()
				end)
				debugInlineGroup:AddChild(WorldStateTimerStop)
			end
		end

		-- Spacer to ensure the scroll goes to the bottom
		local spacer = AceGUI:Create("Label")
		spacer:SetText(" ")
		spacer:SetFullWidth(true)
		scrollFrame:AddChild(spacer)
	end

	-- Initial setup of the Debug tab
	RefreshDebugTab()
end


-- Displays the Widget Container Profiles in Config Frame
function RQE:AddProfileSettingsWidgets(container)
	-- Profile Management Section Label
	local label = AceGUI:Create("Label")
	label:SetText("Profile Management")
	label:SetFullWidth(true)
	container:AddChild(label)

	-- Dropdown for existing profiles
	local profileDropdown = AceGUI:Create("Dropdown")
	profileDropdown:SetLabel("Select Profile")
	local profiles = {}
	local currentProfile = RQE.db:GetCurrentProfile()

	-- Populate profiles dropdown
	for _, profileName in pairs(RQE.db:GetProfiles()) do
		profiles[profileName] = profileName
	end
	profileDropdown:SetList(profiles)
	profileDropdown:SetValue(currentProfile)
	profileDropdown:SetCallback("OnValueChanged", function(widget, event, value)
		RQE.db:SetProfile(value)
	end)
	container:AddChild(profileDropdown)

	-- Button for creating a new profile
	local newProfileButton = AceGUI:Create("Button")
	newProfileButton:SetText("Create New Profile")
	newProfileButton:SetCallback("OnClick", function()
		local newProfileName = "NewProfile"  -- You can prompt the user for this name if you want
		RQE.db:SetProfile(newProfileName)
		profiles[newProfileName] = newProfileName
		profileDropdown:SetList(profiles)
		profileDropdown:SetValue(newProfileName)
	end)
	container:AddChild(newProfileButton)

	-- Button for copying a profile
	local copyProfileButton = AceGUI:Create("Button")
	copyProfileButton:SetText("Copy Current Profile")
	copyProfileButton:SetCallback("OnClick", function()
		local newProfileName = currentProfile .. "_Copy"
		RQE.db:CopyProfile(currentProfile, newProfileName)
		profiles[newProfileName] = newProfileName
		profileDropdown:SetList(profiles)
		profileDropdown:SetValue(newProfileName)
	end)
	container:AddChild(copyProfileButton)

	-- Button for deleting a profile
	local deleteProfileButton = AceGUI:Create("Button")
	deleteProfileButton:SetText("Delete Profile")
	deleteProfileButton:SetCallback("OnClick", function()
		RQE.db:DeleteProfile(currentProfile)
		profiles[currentProfile] = nil
		profileDropdown:SetList(profiles)
		profileDropdown:SetValue(next(profiles))  -- Select the first available profile
	end)
	container:AddChild(deleteProfileButton)

	-- Button for resetting the profile
	local resetProfileButton = AceGUI:Create("Button")
	resetProfileButton:SetText("Reset Profile")
	resetProfileButton:SetCallback("OnClick", function()
		RQE.db:ResetProfile()
	end)
	container:AddChild(resetProfileButton)
end