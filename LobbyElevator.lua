local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Import = require(ReplicatedStorage.Submodules.OcFramework.Import)
local Timer = Import("OcTimer") ---@module OcTimer
local PlaceService = Import("PlaceService") ---@module PlaceService
local OcTeleportService = Import("OcTeleportService") ---@module OcTeleportService
local Signal = Import("Signal") ---@module Signal

local ELEVATOR_COUNTDOWN_BASE = 5
local MAX_PLAYERS = 4
local PLAYER_ENTER_POSITION_OFFSET = CFrame.new(0, -3, 3)
local PLAYER_EXIT_POSITION_OFFSET = CFrame.new(0, -3, -6)
local GAME_ID = PlaceService:GetGamePlaceId(if game.PlaceId == 18744295409 then true else nil)

local LobbyElevator = {}
LobbyElevator.__index = LobbyElevator

export type LobbyElevator = typeof(setmetatable(
	{} :: {
		playerList: { Player },
		onDiedConnections: { [Player]: RBXScriptConnection },
		maxPlayers: number,
		timer: Timer.OcTimer?,
		countdownTime: number,
		model: Model,
		touchPart: BasePart?,
		locked: boolean,
		elevatorLeft: Signal.Signal,
		barrier: Model?,
		safeSpotTeleport: BasePart?,
	},
	LobbyElevator
))

function LobbyElevator.new(model: Model): LobbyElevator
	local maxPlayers = model:GetAttribute("MaxPlayers") or MAX_PLAYERS
	local self = {
		playerList = {},
		onDiedConnections = {},
		maxPlayers = maxPlayers,
		timer = nil,
		countdownTime = maxPlayers * ELEVATOR_COUNTDOWN_BASE,
		model = model,
		touchPart = model:FindFirstChild("TouchPart", true) :: BasePart?,
		locked = false,
		elevatorLeft = Signal.new(),
		barrier = model:FindFirstChild("Barrier", true) :: Model?,
		safeSpotTeleport = workspace:FindFirstChild("SafeSpotTeleport", true) :: BasePart?,
	}

	if not model:GetAttribute("MaxPlayers") then
		model:SetAttribute("MaxPlayers", self.maxPlayers)
	end
	model:SetAttribute("NumPlayers", 0)
	model:SetAttribute("Countdown", self.countdownTime)
	model:SetAttribute("Locked", self.locked)

	if self.touchPart and self.touchPart.Transparency ~= 1 then
		self.touchPart.Transparency = 1
	end

	setmetatable(self, LobbyElevator)

	return self
end

function LobbyElevator:startCountdown()
	if not self.timer and self.model then
		self.timer = Timer.new("ElevatorCountdown" .. tostring(self.model:GetPivot().Position), self.countdownTime)
		self.timer.timerComplete:Once(function()
			self:updateStatus("Elevator is departing...")
			self:endCountdown()
		end)
		self.timer.timerTick:Connect(function(remainingTime)
			self:updateStatus("Elevator is leaving in " .. tostring(remainingTime) .. " seconds")
			self.model:SetAttribute("Countdown", remainingTime)
			if remainingTime == 0 and #self.playerList > 0 then
				self:sendPlayersToGame()
				self.timer = nil
			end
		end)
		self.timer:start()
	end
end

function LobbyElevator:endCountdown()
	if self.timer then
		self.timer:destroy()
		self.timer = nil
	end
end

function LobbyElevator:updateStatus(text: string)
	if self.onTimeUpdated and typeof(self.onTimeUpdated) == "function" then
		self.onTimeUpdated(text)
	end
end

function LobbyElevator:isFull()
	return #self.playerList >= self.maxPlayers or self.locked
end

function LobbyElevator:movePlayer(player: Player, cframeOffset: CFrame)
	local character = player.Character
	local primaryPart = character and character.PrimaryPart
	if primaryPart and self.touchPart then
		primaryPart.Position = (self.touchPart.CFrame * cframeOffset).Position
	end
end

function LobbyElevator:addPlayer(player: Player)
	if self:isFull() then
		return false
	end
	table.insert(self.playerList, player)
	self.model:SetAttribute("NumPlayers", #self.playerList)
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		self.onDiedConnections[player] = humanoid.Died:Once(function()
			self:removePlayer(player)
		end)
	end
	self:movePlayer(player, PLAYER_ENTER_POSITION_OFFSET)
	self:startCountdown()
	return true
end

function LobbyElevator:removePlayer(player: Player)
	local findPlayer = table.find(self.playerList, player)
	if not findPlayer then
		return false
	end
	table.remove(self.playerList, findPlayer)
	self.model:SetAttribute("NumPlayers", #self.playerList)
	if self.onDiedConnections[player] then
		self.onDiedConnections[player]:Disconnect()
		self.onDiedConnections[player] = nil
	end
	self:movePlayer(player, PLAYER_EXIT_POSITION_OFFSET)
	if #self.playerList == 0 then
		self:endCountdown()
	end
	return true
end

function LobbyElevator:sendPlayersToGame()
	if #self.playerList == 0 then
		warn("No players to send to game for elevator " .. self.model.Name)
		return
	end

	self.locked = true
	self.model:SetAttribute("Locked", self.locked)
	--self:updateStatus("The elevator is leaving...")
	self.elevatorLeft:Fire()
	self.playSound("Close")
	self.playAnimation("Close")
	task.wait(9)
	if RunService:IsStudio() then
		warn("Skipping teleporting players to game in studio...")
		self:updateStatus("Skipping teleporting players to game in studio")
		for _, player in pairs(self.playerList) do
			self:movePlayer(player, PLAYER_EXIT_POSITION_OFFSET)
		end
		self.onStudioTeleport()
	else
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		OcTeleportService:teleportPlayersAsync(self.playerList, GAME_ID, {}, options)
		if self.safeSpotTeleport then
			for _, player in pairs(self.playerList) do
				local character = player.Character
				if character then
					character:SetPrimaryPartCFrame(self.safeSpotTeleport.CFrame)
				end
			end
		end
	end
	self.playerList = {}
	self:endCountdown()
	for index, onDiedConnection in pairs(self.onDiedConnections) do
		onDiedConnection:Disconnect()
		self.onDiedConnections[index] = nil
	end
	self.onDiedConnections = {}
	self.playSound("Open")
	self.playAnimation("IdleOpen")
	self.locked = false
	self.model:SetAttribute("Locked", self.locked)
end

function LobbyElevator.playSound(_soundName: string)
	error("This function must be overridden")
end

function LobbyElevator.playAnimation(_animationName: string)
	error("This function must be overridden")
end

function LobbyElevator.onTimeUpdated()
	error("This function must be overridden")
end

function LobbyElevator.onStudioTeleport()
	error("This function must be overridden")
end

return LobbyElevator
