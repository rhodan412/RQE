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
    RQE.debugLog("Your message here")
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

---------------------------
-- 4. Config Logic
---------------------------

-- Valid Anchor Point Options
local anchorPointOptions = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}


-- Valid Debug Level Options
local debugLevelOptions = {"NONE", "INFO", "DEBUG", "WARNING", "CRITICAL"}

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
					order = 4, -- Adjust the order as needed
				},
				minimapToggle = {
					type = "toggle",
					name = "Show Minimap Button",
					desc = "Toggle the minimap button on or off",
					get = function()
						return RQE.db.profile.showMinimapIcon
					end,
					set = function(_, newValue)
						RQE:ToggleMinimapIcon()
					end,
					order = 5,
				},
				showMapID = {
					type = "toggle",
					name = "Show Current MapID",
					desc = "Toggles the display of the current MapID on the frame.",
					order = 6,  -- Adjust this based on where you want it in the order
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
					order = 7,  -- Adjust this based on where you want it in the order
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
					order = 8,  -- Adjust this based on where you want it in the order
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
					order = 9,  -- Adjust this based on where you want it in the order
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
					order = 10,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.removeWQatLogin end,
					set = function(_, newValue)
						RQE.db.profile.removeWQatLogin = newValue;
					end,
				},
				autoTrackZoneQuests = {
					type = "toggle",
					name = "Auto Track Zone Quests",
					desc = "Updates watch list on zone change to display quests specific to the player's zone",
					order = 11,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.autoTrackZoneQuests end,
					set = function(_, newValue)
						RQE.db.profile.autoTrackZoneQuests = newValue;
					end,
				},
				autoClickWaypointButton = {
					type = "toggle",
					name = "Auto Click Waypoint Button",
					desc = "Automatically click on the Waypoint Button in the Super Tracked frame when you progress through quest objectives",
					order = 12,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.autoClickWaypointButton end,
					set = function(_, newValue)
						RQE.db.profile.autoClickWaypointButton = newValue;
					end,
				},
				enableQuestAbandonConfirm = {
					type = "toggle",
					name = "Auto Abandon Quest",
					desc = "If enabled will hide confirmation pop up when abandoning quest via right-clicking quest in the addon. If disabled, pop up will appear with confirmation to abandon the selected quest",
					order = 13,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.enableQuestAbandonConfirm end,
					set = function(_, newValue)
						RQE.db.profile.enableQuestAbandonConfirm = newValue;
					end,
				},
				enableTomTomCompatibility = {
					type = "toggle",
					name = "Enable TomTom Compatibility",
					desc = "If enabled will create waypoints via TomTom addon (if you have this addon also installed)",
					order = 14,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.enableTomTomCompatibility end,
					set = function(_, newValue)
						RQE.db.profile.enableTomTomCompatibility = newValue;
					end,
				},
				enableCarboniteCompatibility = {
					type = "toggle",
					name = "Enable Carbonite Compatibility",
					desc = "If enabled will create waypoints via Carbonite addon (if you have this addon also installed)",
					order = 15,  -- Adjust this based on where you want it in the order
					get = function() return RQE.db.profile.enableCarboniteCompatibility end,
					set = function(_, newValue)
						RQE.db.profile.enableCarboniteCompatibility = newValue;
					end,
				},
			},
		},
        frame = {
            name = "Frame Settings",
            type = "group",
            args = {
				framePosition = {
					type = "group",
					name = "Main Frame Position",
					inline = true,
					order = 10,  -- Set this order to wherever you want it to appear
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
								RQE:UpdateFrameOpacity()  -- You will need to create this function
							end,
							order = 4,  -- Adjust this number to place it in your preferred order
						},
						frameWidth = {
							type = 'range',
							name = 'Frame Width',
							desc = 'Adjust the width of the super tracking frame.',
							min = 100,  -- Minimum height you allow
							max = 800,  -- Maximum height you allow
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
							min = 100,  -- Minimum height you allow
							max = 800,  -- Maximum height you allow
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
								RQE:UpdateFrameOpacity()  -- You will need to create this function
							end,
							order = 4,  -- Adjust this number to place it in your preferred order
						},
						frameWidth = {
							type = 'range',
							name = 'Frame Width',
							desc = 'Adjust the width of the super tracking frame.',
							min = 100,  -- Minimum height you allow
							max = 800,  -- Maximum height you allow
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
							min = 100,  -- Minimum height you allow
							max = 800,  -- Maximum height you allow
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
					order = 12,  -- Set this order to wherever you want it to appear
					args = {
						headerText = {
							name = "Header Text",
							type = "group",
							order = 1,  -- Set this order to wherever you want it to appear
							args = {
								fontSize = {
									name = "Font Size",
									desc = "Default: 18",
									type = "range",
									min = 8, max = 24, -- step = 1,   COMMENTING OUT AS REDUNDANT
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
					order = 2,  -- Adjust this based on where you want it in the order
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
					order = 3,  -- Set this order to wherever you want it to appear
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
								return not (RQE.db.profile.debugMode and RQE.db.profile.debugLevel == "INFO")
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
								return not (RQE.db.profile.debugMode and RQE.db.profile.debugLevel == "INFO")
							end,
							order = 3,
						},
					},
				},
			},
		},
	},
}