-- this file contains many images which weren't added to the ImageIds module
-- if you reuse an image from this file please move it to the ImageIds module

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Import = require(ReplicatedStorage.Submodules.OcFramework.Import)
local Fusion = Import("Fusion") ---@module Packages/Fusion
local FusionTypes = Import("FusionTypes") ---@module FusionTypes
local TableUtil = Import("TableUtil") ---@module Packages/TableUtil
local ImageIds = Import("ImageIds") ---@module ImageIds
local TimeScoreFrame = Import("TimeScoreFrame") ---@module TimeScoreFrame
local Top3PlayersFrame = Import("Top3PlayersFrame") ---@module Top3PlayersFrame
local PlayerLevelFrame = Import("PlayerLevelFrame") ---@module PlayerLevelFrame

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local OnEvent = Fusion.OnEvent

local PROFILE_PIC_URL = ImageIds.profilePicUrl

local heavyNormalFont = Font.new("rbxassetid://12187372847", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)

type State<T> = FusionTypes.StateObject<T>

type PlayerMission = {
	name: string,
	text: string,
	icon: string,
	-- obv will want to add more here later
}

type PlayerScoreInfo = {
	name: string,
	time: number,
	userId: number,
	rank: number,
}

type ResultsScreenProps = {
	visible: State<boolean>?,
	onCloseClicked: (() -> ())?,
	roundResults: State<{
		time: number,
		players: { PlayerScoreInfo },
		seekers: { PlayerScoreInfo },
	}>,
	missions: State<{ PlayerMission }>,
	levelInfo: PlayerLevelFrame.PlayerLevelFrameProps,
}

local function cornerRadius1()
	return New("UICorner")({
		CornerRadius = UDim.new(1, 0),
	})
end

local function resultScreen(props: ResultsScreenProps)
	local top3Players = Computed(function()
		local players = props.roundResults:get().players
		return if #players < 3 then players else TableUtil.Truncate(players, 3)
	end)
	local otherPlayers = Computed(function()
		return TableUtil.Filter(props.roundResults:get().players, function(_, index)
			return index > 3
		end)
	end)
	local singleSeeker = Computed(function()
		-- for now we only have one seeker, but this could change
		return props.roundResults:get().seekers[1]
	end)
	return New("ImageLabel")({
		Name = "Results",
		Image = "rbxassetid://93758069832611",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.815, 0.857),
		Visible = props.visible or true,
		ZIndex = 0,
		[Children] = {
			New("Frame")({
				Name = "TopBar",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.0651),
				Size = UDim2.fromScale(1, 0.128),
				[Children] = {
					New("Frame")({
						Name = "Main",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.431, 0.633),
						[Children] = {
							New("UIListLayout")({
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							}),
							New("TextLabel")({
								FontFace = Font.new(
									"rbxassetid://12187372847",
									Enum.FontWeight.Heavy,
									Enum.FontStyle.Normal
								),
								Text = "SCORES & RESULTS",
								TextColor3 = Color3.fromRGB(255, 255, 255),
								TextScaled = true,
								BackgroundTransparency = 1,
								LayoutOrder = 0,
								Size = UDim2.fromScale(0.853, 1.28),
							}),
							TimeScoreFrame({
								time = Computed(function()
									return props.roundResults:get().time
								end),
								size = UDim2.fromScale(0.6, 0.8),
								position = UDim2.fromScale(0.5, 0.5),
							}),
						},
					}),
					New("ImageButton")({
						Name = "CloseButton",
						HoverImage = "rbxassetid://16443341812",
						Image = "rbxassetid://16443321871",
						ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.94, 0.5),
						Size = UDim2.fromScale(0.9, 0.9),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						[OnEvent("Activated")] = function()
							if props.onCloseClicked then
								props.onCloseClicked()
							end
						end,
						[Children] = {
							New("ImageLabel")({
								Name = "ConsoleButton",
								ScaleType = Enum.ScaleType.Fit,
								AnchorPoint = Vector2.new(1, 1),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(1, 1),
								Size = UDim2.fromScale(0.3, 0.3),
								Visible = false,
							}),
						},
					}),
				},
			}),
			New("Frame")({
				Name = "Missions",
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.1,
				Position = UDim2.fromScale(0.0326, 0.18),
				Size = UDim2.fromScale(0.403, 0.606),
				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(0.03, 0),
					}),
					New("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(255, 0, 0),
						Thickness = 3.1,
						Transparency = 0.88,
					}),
					New("TextLabel")({
						Name = "Heading",
						FontFace = heavyNormalFont,
						Text = "REWARDS",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.193, 0.0284),
						Size = UDim2.fromScale(0.661, 0.248),
					}),
					New("ScrollingFrame")({
						Name = "MissionList",
						BottomImage = "http://www.roblox.com/asset/?id=15493656479",
						CanvasSize = UDim2.fromScale(0, 0),
						MidImage = "rbxassetid://15781006432",
						ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0),
						ScrollBarThickness = 11,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						TopImage = "http://www.roblox.com/asset/?id=15493657700",
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0.3),
						Size = UDim2.fromScale(0.95, 0.7),
						[Children] = {
							New("UIListLayout")({
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							ForPairs(props.missions, function(index, value)
								return index,
									New("Frame")({
										Name = value.name,
										BackgroundTransparency = 1,
										LayoutOrder = index,
										Size = UDim2.new(1, 0, 0, 50),
										[Children] = {
											New("UIListLayout")({
												FillDirection = Enum.FillDirection.Horizontal,
												HorizontalAlignment = Enum.HorizontalAlignment.Center,
												SortOrder = Enum.SortOrder.LayoutOrder,
											}),
											New("ImageLabel")({
												Name = "MissionIcon",
												Image = value.icon,
												ScaleType = Enum.ScaleType.Fit,
												BackgroundTransparency = 1,
												Size = UDim2.fromScale(0.25, 1),
											}),
											New("TextLabel")({
												Name = "MissionText",
												FontFace = heavyNormalFont,
												Text = value.text,
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextScaled = true,
												BackgroundTransparency = 1,
												Size = UDim2.fromScale(0.5, 1),
											}),
										},
									})
							end, function(_, destroyThis)
								destroyThis:Destroy()
							end),
						},
					}),
				},
			}),
			New("Frame")({
				Name = "Ranking",
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Position = UDim2.fromScale(0.458, 0.179),
				Size = UDim2.fromScale(0.509, 0.766),
				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(0.025, 0),
					}),
					New("Frame")({
						Name = "SeekerScore",
						BackgroundColor3 = Color3.fromRGB(63, 0, 0),
						BackgroundTransparency = 0.6,
						Position = UDim2.fromScale(0, 0.895),
						Size = UDim2.fromScale(1, 0.107),
						ZIndex = 0,
						[Children] = {
							New("Frame")({
								BackgroundColor3 = Color3.fromRGB(4, 43, 63),
								BackgroundTransparency = 1,
								Position = UDim2.fromScale(0.0532, 0.1),
								Size = UDim2.fromScale(0.871, 0.752),
								[Children] = {
									New("UIListLayout")({
										Padding = UDim.new(0.05, 0),
										FillDirection = Enum.FillDirection.Horizontal,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										SortOrder = Enum.SortOrder.LayoutOrder,
										VerticalAlignment = Enum.VerticalAlignment.Center,
									}),
									New("UICorner")({
										CornerRadius = UDim.new(0.133, 0),
									}),
									New("TextLabel")({
										Name = "Team",
										FontFace = Font.new(
											"rbxassetid://12187372847",
											Enum.FontWeight.Heavy,
											Enum.FontStyle.Normal
										),
										Text = "Seeker",
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextScaled = true,
										TextXAlignment = Enum.TextXAlignment.Right,
										BackgroundTransparency = 1,
										Position = UDim2.fromScale(0.102, -0.103),
										Size = UDim2.fromScale(0.189, 0.936),
									}),
									New("ImageLabel")({
										Name = "PlayerIcon",
										Image = Computed(function()
											if not singleSeeker:get() then
												return "rbxasset://textures/ui/GuiImagePlaceholder.png"
											end
											return string.format(PROFILE_PIC_URL, singleSeeker:get().userId)
										end),
										Position = UDim2.fromScale(0.258, -0.038),
										Size = UDim2.fromScale(0.0953, 1.08),
										[Children] = {
											cornerRadius1(),
										},
									}),
									New("TextLabel")({
										Name = "PlayerName",
										FontFace = Font.new(
											"rbxassetid://12187372847",
											Enum.FontWeight.Heavy,
											Enum.FontStyle.Normal
										),
										Text = Computed(function()
											if not singleSeeker:get() then
												return "No Seeker"
											end
											return singleSeeker:get().name
										end),
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextScaled = true,
										BackgroundTransparency = 1,
										Position = UDim2.fromScale(0.429, 0.167),
										Size = UDim2.fromScale(0.141, 0.667),
									}),
									TimeScoreFrame({
										time = Computed(function()
											if not singleSeeker:get() then
												return 0
											end
											return singleSeeker:get().time
										end),
										size = UDim2.fromScale(0.25, 0.85),
										position = UDim2.fromScale(0.791, 0.167),
									}),
								},
							}),
							New("UICorner")({
								CornerRadius = UDim.new(0.2, 0),
							}),
						},
					}),
					New("ScrollingFrame")({
						Name = "OtherPlayers",
						BottomImage = "http://www.roblox.com/asset/?id=15493656479",
						CanvasSize = UDim2.fromScale(0, 0),
						MidImage = "rbxassetid://15781006432",
						ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0),
						ScrollBarThickness = 11,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						TopImage = "http://www.roblox.com/asset/?id=15493657700",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0, 0.328),
						Size = UDim2.fromScale(0.977, 0.537),
						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.015, 0),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							ForPairs(otherPlayers, function(index, value)
								return index,
									New("Frame")({
										Name = tostring(index),
										BackgroundTransparency = 1,
										LayoutOrder = index,
										Size = UDim2.new(1, 0, 0, 20),
										[Children] = {
											New("UIListLayout")({
												Padding = UDim.new(0.109, 0),
												FillDirection = Enum.FillDirection.Horizontal,
												SortOrder = Enum.SortOrder.LayoutOrder,
												VerticalAlignment = Enum.VerticalAlignment.Center,
											}),
											New("UICorner")({
												CornerRadius = UDim.new(0.123, 0),
											}),
											New("TextLabel")({
												Name = "Rank",
												FontFace = Font.new(
													"rbxassetid://12187372847",
													Enum.FontWeight.Heavy,
													Enum.FontStyle.Normal
												),
												Text = value.rank,
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextScaled = true,
												TextXAlignment = Enum.TextXAlignment.Right,
												BackgroundTransparency = 1,
												Size = UDim2.fromScale(0.146, 0.614),
											}),
											New("ImageLabel")({
												Name = "PlayerIcon",
												Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
												BackgroundTransparency = 1,
												Size = UDim2.fromScale(0.06, 0.86),
												[Children] = {
													cornerRadius1(),
												},
											}),
											New("TextLabel")({
												Name = "Username",
												FontFace = Font.new(
													"rbxassetid://12187372847",
													Enum.FontWeight.Heavy,
													Enum.FontStyle.Normal
												),
												Text = value.name,
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextScaled = true,
												BackgroundTransparency = 1,
												Position = UDim2.fromScale(0.429, 0.167),
												Size = UDim2.fromScale(0.139, 0.614),
											}),
											TimeScoreFrame({
												time = value.time,
												size = UDim2.fromScale(0.25, 0.85),
												position = UDim2.fromScale(0.791, 0.167),
											}),
										},
									})
							end, function(_, destroyThis)
								destroyThis:Destroy()
							end),
						},
					}),
					New("Frame")({
						Name = "Top3Players",
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.0714, -0.0116),
						Size = UDim2.fromScale(0.854, 0.309),
						[Children] = {
							New("UIListLayout")({
								Padding = UDim.new(0.1, 0),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								VerticalAlignment = Enum.VerticalAlignment.Bottom,
							}),
							ForPairs(top3Players, function(index, value)
								return index,
									Top3PlayersFrame({
										rank = index,
										name = value.name,
										time = value.time,
										userId = value.userId,
									})
							end, function(_, destroyThis)
								destroyThis:Destroy()
							end),
						},
					}),
					New("Frame")({
						Name = "Scroll-Bg",
						BackgroundColor3 = Color3.fromRGB(63, 0, 0),
						BackgroundTransparency = 0.6,
						Position = UDim2.fromScale(0.959, 0.346),
						Size = UDim2.fromScale(0.0151, 0.506),
						ZIndex = 0,
						[Children] = {
							New("UICorner")({
								CornerRadius = UDim.new(1.5, 0),
							}),
						},
					}),
					New("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(255, 0, 0),
						Thickness = 3.1,
						Transparency = 0.88,
					}),
					New("Frame")({
						Name = "ScrollBackground",
						BackgroundColor3 = Color3.fromRGB(66, 66, 66),
						BackgroundTransparency = 0.6,
						Position = UDim2.fromScale(0.0489, 0.323),
						Size = UDim2.fromScale(0.893, 0.55),
						ZIndex = 0,
						[Children] = {
							New("UICorner")({
								CornerRadius = UDim.new(0.075, 0),
							}),
						},
					}),
				},
			}),
			PlayerLevelFrame({
				playerIcon = props.levelInfo.playerIcon,
				level = props.levelInfo.level,
				xp = props.levelInfo.xp,
				maxXp = props.levelInfo.maxXp,
				score = props.levelInfo.score,
			}),
			New("UIAspectRatioConstraint")({
				AspectRatio = 1.69,
			}),
		},
	})
end

return resultScreen
