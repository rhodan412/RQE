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

-- This section is responsible for initializing and handling the profile logic related to the Add-On's Options system.
-- Initialize profile options
function RQE:InitializeProfileOptions()
    -- Additional logic related to profile options can go here
end


---------------------------
-- 3. Settings Logic
---------------------------

-- This section controls the default settings if the Profile section for the Add-On's configuration doesn't contain that information
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
        enableQuestFrame = {
            type = "toggle",
            name = "Enable Quest Frame",
            desc = "Enable or disable the Quest Frame.",
            get = function(info) return RQE.db.profile.enableQuestFrame end,
            set = function(info, value) 
                RQE.db.profile.enableQuestFrame = value
                RQE:ToggleRQEQuestFrame()
            end,
            order = 2,
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
			order = 3,
		},
		-- Add checkbox for Debug Mode
		debugMode = {
			type = "toggle",
			name = "Enable Debug Mode",
			desc = "Enable or disable debug mode for additional logging.",
			order = 4,
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
		showMapID = {
			type = "toggle",
			name = "Show Current MapID",
			desc = "Toggles the display of the current MapID on the frame.",
			order = 5,  -- Adjust this based on where you want it in the order
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
			order = 6,  -- Adjust this based on where you want it in the order
			get = function() return RQE.db.profile.showCoordinates end,
			set = function(_, newValue) 
				RQE.db.profile.showCoordinates = newValue;
				RQE:UpdateCoordinates();  -- Immediately update the coordinates display
			end,
		},
		autoSortRQEFrame = {
			type = "toggle",
			name = "Auto Populate Frame",
			desc = "Will auto populate the RQEFrame (super tracked frame) by supertracking closest tracked quest (regardless of if you're currently tracking something else).",
			order = 7,  -- Adjust this based on where you want it in the order
			get = function() return RQE.db.profile.autoSortRQEFrame end,
			set = function(_, newValue) 
				RQE.db.profile.autoSortRQEFrame = newValue;
			end,
		},
		framePosition = {
			type = "group",
			name = "Main Frame Position",
			inline = true,
			order = 8,  -- Set this order to wherever you want it to appear
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
			},
		},
		QuestFramePosition = {
			type = "group",
			name = "Quest Frame Position",
			inline = true,
			order = 9,  -- Set this order to wherever you want it to appear
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
			},
		},
		debug = {
			type = "group",
			name = "Debug",
			inline = true,
			order = 10,  -- Set this order to wherever you want it to appear
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
			},
		},
		fontSizeAndColor = {
			type = "group",
			name = "Font Size and Color",
			inline = true,
			order = 11,  -- Set this order to wherever you want it to appear
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
							min = 8, max = 24, step = 1,
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
}