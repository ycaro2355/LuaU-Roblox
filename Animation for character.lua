só serve para light Studio para animação
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local animFolder = ServerStorage:FindFirstChild("RBX_ANIMSAVES")

local remote = ReplicatedStorage:FindFirstChild("AnimationLitePlayRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "AnimationLitePlayRemote"
	remote.Parent = ReplicatedStorage
end

-- 🔥 pega TODAS animações da pasta (sem depender de nome)
local function getAnims()
	local list = {}

	if not animFolder then return list end

	for _, obj in ipairs(animFolder:GetDescendants()) do
		if obj:IsA("KeyframeSequence") then
			table.insert(list, obj)
		end
	end

	-- ordena por número no nome (KF2, KF10 etc)
	table.sort(list, function(a, b)
		local na = tonumber(a.Name:match("%d+")) or 0
		local nb = tonumber(b.Name:match("%d+")) or 0
		return na < nb
	end)

	return list
end

-- 🔥 mapeamento inteligente
local function mapAnimations()
	local a = getAnims()

	local idle, walk, run

	if #a == 0 then
		return nil, nil, nil
	end

	if #a == 1 then
		-- só uma animação → tudo usa ela
		return a[1], a[1], a[1]
	end

	if #a == 2 then
		-- duas → idle + walk (run = walk)
		return a[1], a[2], a[2]
	end

	-- 3 ou mais → padrão
	idle = a[1]
	walk = a[2]
	run  = a[3]

	return idle, walk, run
end

-- 🔥 tocar animação
local function play(character, anim)
	if not character or not anim then return end

	local service = game:GetService("ServerScriptService"):FindFirstChild("AnimationLiteService")
	local event = service and service:FindFirstChild("AnimationLitePlayEvent")

	if event then
		pcall(function()
			event:Fire(character, anim)
		end)
	end
end

local function setupCharacter(_, character)
	task.wait(0.2)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animate = character:FindFirstChild("Animate")
	if animate then animate:Destroy() end

	local idle, walk, run = mapAnimations()

	local current = nil
	local alive = true

	humanoid.Died:Connect(function()
		alive = false
	end)

	RunService.Heartbeat:Connect(function()
		if not character.Parent or not alive then return end

		local speed = humanoid.MoveDirection.Magnitude

		local target

		if speed < 0.1 then
			target = idle or walk
		elseif speed < 0.6 then
			target = walk or idle
		else
			target = run or walk or idle
		end

		if target and target ~= current then
			current = target
			play(character, target)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		setupCharacter(player, char)
	end)
end)

print("✅ Sistema FINAL adaptativo (KF livre)")
