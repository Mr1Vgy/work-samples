--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Import = require(ReplicatedStorage.Submodules.OcFramework.Import)

--logger
local Logger = Import("Logger") ---@module Submodules/OcFramework/shared/Logger
local LOG_NinjaAbilityCounterStab = Logger.new(Logger.Verbosity.Warn, "NinjaAbilityCounterStab")

--base
local AbilityBase = Import("AbilityBase") ---@module AbilityBase
type AbilityContext = AbilityBase.AbilityContext

local Promise = Import("Promise") ---@module Packages/Promise

local EffectsFolder = ReplicatedStorage:WaitForChild("Effects") -- for now making this the same as Isaac's
local TeleportInEffect = EffectsFolder:WaitForChild("NinjaTeleportInVFX"):FindFirstChildWhichIsA("Attachment")
local TeleportOutEffect = EffectsFolder:WaitForChild("NinjaTeleportOutVFX"):FindFirstChildWhichIsA("Attachment")
local SpeedLines = TeleportOutEffect:FindFirstChild("SpeedLines", true)
local NinjaLog = EffectsFolder:WaitForChild("NinjaLog"):FindFirstChildWhichIsA("BasePart")

local NinjaAbilityCounterStab = setmetatable({}, { __index = AbilityBase })
NinjaAbilityCounterStab.__index = NinjaAbilityCounterStab

-- constants
local DISTANCE = 15 -- distance to teleport in studs

function NinjaAbilityCounterStab.new(player: Player, name: string, action: string, params: any?)
	local self = AbilityBase.new(player, name, action, params)
	setmetatable(self, NinjaAbilityCounterStab)

	self.cooldownTime = params.cooldownTime or 0.5
	self.damage = params.damage or 25
	self.colliderSize = params.colliderSize or Vector3.new(2, 2, 2)

	self.activateOnRelease = true
	self.minimumChargeTime = 2
	self.isCharging = false

	if RunService:IsServer() then
		self:SetupAbilityCollider()
	end

	return self
end

function NinjaAbilityCounterStab:OnActivate(context: AbilityContext?)
	if context.IsCharging then
		self.isCharging = true
		self.isActive = false --override base active behaviour
		self.isOnCooldown = false --override base cooldown behaviour
		if RunService:IsServer() then
			self:RunVFX()
		end
		LOG_NinjaAbilityCounterStab:Debug("Ability charging started:", self.name)
		return
	end

	if context.ActionButtonTriggerCallback then
		context.ActionButtonTriggerCallback()
	end

	if context.ChargeTime >= self.minimumChargeTime then
		-- ability does not activate if the player was not hit
		LOG_NinjaAbilityCounterStab:Warn("Charge time not met")
		if RunService:IsClient() and context.AnimationCancelCallback then
			LOG_NinjaAbilityCounterStab:Debug("Canceling animation")
			context.AnimationCancelCallback()
		end
		self:Finish()
		return
	end

	local wasHit = self.player.Character.Humanoid.Health < self.player.Character.Humanoid.MaxHealth
	-- adding this temporary check to see if the player was hit
	-- we'll need to replace this with a more reliable way to check if the player was hit

	if RunService:IsServer() and context.ChargeTime < self.minimumChargeTime and wasHit then
		LOG_NinjaAbilityCounterStab:Info("Activating Stealth Stab")
		local humanoidRootPart = self.player.Character:WaitForChild("HumanoidRootPart")
		local targetPoint = humanoidRootPart.CFrame * CFrame.new(0, 0, -DISTANCE)

		-- find the nearest player to the target point
		local nearestPlayer = nil
		local nearestDistance = math.huge
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= self.player then
				local character = player.Character
				if character then
					local distance = (character.HumanoidRootPart.Position - targetPoint.Position).Magnitude
					if distance < nearestDistance then
						nearestPlayer = player
						nearestDistance = distance
					end
				end
			end
		end
		if nearestPlayer then
			-- teleport behind the nearest player, otherwise just teleport to the target point if no player is found
			targetPoint = nearestPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
		end

		local partOnGround = NinjaLog:Clone()
		partOnGround.Anchored = true

		-- raycast down to find the spot on the ground
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { self.player.Character }
		local raycastResult = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -20, 0), raycastParams)
		if raycastResult then
			partOnGround.Position = raycastResult.Position
		else
			partOnGround.Position = humanoidRootPart.Position
		end
		partOnGround.Parent = workspace
		self.partOnGround = partOnGround

		self.player.Character.HumanoidRootPart.CFrame = if nearestPlayer
			then CFrame.lookAt(targetPoint.Position, nearestPlayer.Character.HumanoidRootPart.Position)
			else targetPoint
		-- this should rotate the player to face the nearest player, but it's not working
		-- I think because the client camera rotation is overriding it?

		if nearestPlayer and self.abilityHitEvent == nil then
			self.hitBaseParts = {}
			self.abilityHitEvent = self.abilityCollider.Touched:Connect(function(hitPart: BasePart)
				self.abilityCollider.Transparency = 1
				self:HandleHit(hitPart)
			end)
			self:RunEndVFX()
		end
	end
	Promise.delay(self.cooldownTime):andThen(function()
		self:Finish()
	end)
end

function NinjaAbilityCounterStab:OnFinish()
	if RunService:IsServer() then
		if self.partOnGround then
			self.partOnGround:Destroy()
			self.partOnGround = nil
		end

		if self.abilityHitEvent ~= nil then
			self.abilityHitEvent:Disconnect()
			self.abilityHitEvent = nil
		end

		if self.chargingVFX then
			self.chargingVFX:Destroy()
			self.chargingVFX = nil
		end

		-- TODO: make the teleport abilities use a Janitor for better cleanup
		if self.speedLines then
			self.speedLines:Destroy()
			self.speedLines = nil
		end

		LOG_NinjaAbilityCounterStab:Info("Counter Stab Ended")
	end

	self.isCharging = false
end

function NinjaAbilityCounterStab:HandleHit(hitPart: BasePart)
	-- copied from oscar ability punch
	if self.hitBaseParts[hitPart] then
		return
	end
	self.hitBaseParts[hitPart] = true
	LOG_NinjaAbilityCounterStab:Debug("Hit Part:", hitPart.Name)
	self:SingleTargetHit(hitPart, self.damage)
end

function NinjaAbilityCounterStab:SetupAbilityCollider()
	local colliderCFrame = self.rootPart.CFrame + self.rootPart.CFrame.LookVector * self.colliderSize.Z

	self.abilityCollider = self:InitCollider(
		"AbilityCollider_NinjaCounterStab",
		self.colliderSize,
		self.rootPart,
		colliderCFrame,
		Enum.PartType.Block,
		--[[debugCollision?]]
		true
	) :: Part
end

function NinjaAbilityCounterStab:RunVFX()
	if RunService:IsServer() then
		local character = self.player.Character
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local vfxClone = TeleportOutEffect:Clone()
		vfxClone.Parent = humanoidRootPart

		if self.speedLines then
			self.speedLines:Destroy()
			self.speedLines = nil
		end
		self.speedLines = SpeedLines:Clone() -- store this for later so it can be destroyed
		self.speedLines.CFrame = humanoidRootPart.CFrame
		local weld = Instance.new("Weld")
		weld.Parent = self.speedLines
		weld.Part0 = humanoidRootPart
		weld.Part1 = self.speedLines
		self.speedLines.Parent = humanoidRootPart

		for _, child in ipairs(vfxClone:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = true
			end
		end

		self.chargingVFX = vfxClone
	end
end

function NinjaAbilityCounterStab:RunEndVFX()
	if RunService:IsServer() then
		if self.chargingVFX then
			self.chargingVFX:Destroy()
			self.chargingVFX = nil
		end
		local vfxClone = TeleportInEffect:Clone()
		vfxClone.Parent = self.player.Character:WaitForChild("HumanoidRootPart")
		for _, child in ipairs(vfxClone:GetDescendants()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = true
			end
		end

		Promise.delay(1):andThen(function()
			vfxClone:Destroy()
			if self.speedLines then
				self.speedLines:Destroy()
				self.speedLines = nil
			end
		end)
	end
end

return NinjaAbilityCounterStab
