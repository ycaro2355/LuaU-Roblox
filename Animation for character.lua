local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remote = ReplicatedStorage:FindFirstChild("AnimationLitePlayRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AnimationLitePlayRemote"
	remote.Parent = ReplicatedStorage
end

local serviceFolder = ServerScriptService:FindFirstChild("AnimationLiteService")
local playEventBindable = serviceFolder and serviceFolder:FindFirstChild("AnimationLitePlayEvent")

local animFolder = ServerStorage:FindFirstChild("RBX_ANIMSAVES")

-- 🔥 pega qualquer KeyframeSequence válido
local function getAnyAnimation()
	if not animFolder then return nil end

	for _, obj in ipairs(animFolder:GetDescendants()) do
		if obj:IsA("KeyframeSequence") then
			return obj
		end
	end

	return nil
end

-- 🔥 toca animação
local function playAnim(character, anim, speed)
	if not playEventBindable then return end
	if not character then return end
	if not anim then return end

	pcall(function()
		playEventBindable:Fire(character, anim, speed or 1)
	end)
end

local function setupCharacter(_, character)
	task.wait(0.2)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- remove animação padrão Roblox
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end

	local walking = false
	local alive = true

	humanoid.Died:Connect(function()
		alive = false
		walking = false
	end)

	local walkAnim = getAnyAnimation()

	if not walkAnim then
		warn("❌ Nenhuma KeyframeSequence encontrada em RBX_ANIMSAVES")
		return
	end

	RunService.Heartbeat:Connect(function()
		if not character.Parent or not alive then return end

		local move = humanoid.MoveDirection.Magnitude

		if move > 0.1 then
			if not walking then
				walking = true
				playAnim(character, walkAnim, 1)
			end
		else
			walking = false
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end)

remote.OnServerEvent:Connect(function(player, animName, speed)
	local char = player.Character
	if not char then return end

	-- tenta tocar qualquer animação mesmo sem nome
	local anim = getAnyAnimation()
	playAnim(char, anim, speed)
end)

print("✅ Animation system auto-detect rodando")
