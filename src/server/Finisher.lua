local rs = game:GetService("ReplicatedStorage")
local event = rs:WaitForChild("useFinisher")
local using = rs:WaitForChild("FinisherBeingUsed")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local event_folder = workspace.FinisherEvent
local event_parts = event_folder.EventParts
local event_part_spawn = event_folder.EventPartSpawn
local finisher_player_part = event_folder.FinisherPlayerPart

-- Anchor all players' root parts (excluding the triggering player)
local function setAnchor(bool)
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.Anchored = bool
		end
	end
end

-- Move the triggering player to the event part
local function tweenToFinisherPart(char)
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	rootPart.Anchored = true

	local tween = TweenService:Create(rootPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = finisher_player_part.Position
	})
	tween:Play()
	tween.Completed:Wait()
end

event.OnServerEvent:Connect(function(plr, name, charge)
	local char = plr.Character
	if not char then return end
	
	name = string.upper(name)

	using.Value = true
	charge.Value = 0
	rs.disableUI:FireAllClients()
	char.HumanoidRootPart.Anchored = true
	tweenToFinisherPart(char)
	setAnchor(true)

	local finisherSound = workspace.FinisherSounds:FindFirstChild(name)
	if finisherSound then
		finisherSound:Play()
	end
	
	print(name)

	-- Set neutral lighting before effect
	Lighting.FogEnd = 100000
	Lighting.FogColor = Color3.new(1, 1, 1)
	Lighting.TimeOfDay = "14:30:00"

	-- Per Finisher Logic
	if name == "PERMAFROST" then
		local fol = script.AbilityParticles
		local icecube = fol["Freeze All"].icecube
		local sound = fol["Freeze All"].sound:Clone()
		sound.Parent = workspace
		sound:Play()
		sound.PlayOnRemove = true
		sound:Destroy()

		for _, p in pairs(Players:GetPlayers()) do
			local otherChar = p.Character
			local main_values = otherChar and otherChar:FindFirstChild('main_values')
			if otherChar and otherChar:FindFirstChild("Humanoid") and p ~= plr and main_values and main_values.INGAME.Value then
				local hrp = otherChar:FindFirstChild("HumanoidRootPart")
				if not hrp then continue end

				otherChar.Humanoid.WalkSpeed = 0
				hrp.Anchored = true

				local n_ice = icecube:Clone()
				n_ice.Size = Vector3.new(0.5, 0.5, 0.5)
				n_ice.CFrame = hrp.CFrame
				n_ice.Parent = workspace

				local tween = TweenService:Create(n_ice, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
					CFrame = hrp.CFrame,
					Size = Vector3.new(4, 6, 4)
				})
				tween:Play()
				tween.Completed:Connect(function()
					n_ice.Parent = hrp
				end)

				task.delay(3, function()
					if otherChar:FindFirstChild("Humanoid") then
						otherChar.Humanoid.WalkSpeed = 16
						hrp.Anchored = false
						n_ice:Destroy()
					end
				end)
			end
		end

		Lighting.FogEnd = 500
		Lighting.FogColor = Color3.new(0.661158, 0.902846, 1)

	elseif name == "INTO THE VOID" then
		Lighting.FogEnd = 1000
		Lighting.FogColor = Color3.new(0, 0, 0)
		Lighting.TimeOfDay = "00:00:00"

		local blackhole = script.AbilityParticles.BlackHole:Clone()
		blackhole.Parent = workspace
		blackhole.Position = finisher_player_part.Position - Vector3.new(0,15,0)
		Debris:AddItem(blackhole, 10)

		for _, p in pairs(Players:GetPlayers()) do
			local otherChar = p.Character
			local main_values = otherChar and otherChar:FindFirstChild('main_values')
			if otherChar and otherChar:FindFirstChild("Humanoid") and p ~= plr and main_values and main_values.INGAME.Value then
				local hrp = otherChar:FindFirstChild("HumanoidRootPart")
				if hrp then
					local tween = TweenService:Create(hrp, TweenInfo.new(10, Enum.EasingStyle.Linear), {
						Position = blackhole.Position
					})
					tween:Play()
				end
			end
		end

	elseif name == "ERUPTION" or name == "METEOR SHOWER" then
		Lighting.FogEnd = 1000
		Lighting.FogColor = Color3.new(0.496651, 0.384619, 0.405035)

		local count = name == "Volcano" and 100 or 85
		local color = name == "Volcano" and Color3.new(0.185168, 0.208179, 0.193225) or Color3.new(1, 0, 0.0747387)
		local material = name == "Volcano" and Enum.Material.Rock or Enum.Material.CrackedLava
		local sizeMin, sizeMax = name == "Volcano" and 5 or 10, name == "Volcano" and 10 or 20

		task.spawn(function()
			for i = 1, count do
				task.wait(0.1)
				local part = Instance.new("Part")
				local s = math.random(sizeMin, sizeMax)
				part.Size = Vector3.new(s, s, s)
				part.Position = event_part_spawn.Position + Vector3.new(math.random(-50,50), 0, math.random(-50,50))
				part.CanCollide = false
				part.Anchored = false
				part.Color = color
				part.Material = material
				part.Parent = workspace
				Debris:AddItem(part, 4)
			end
		end)

	elseif name == "NIGHT FALL" then
		Lighting.FogEnd = 250
		Lighting.FogColor = Color3.new(0, 0, 0)
		Lighting.TimeOfDay = "00:00:00"

	elseif name == "DISCO" then
		Lighting.FogEnd = 1000

		local rainbowColors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 127, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(75, 0, 130),
			Color3.fromRGB(148, 0, 211),
		}

		local function tweenFogColor(color)
			local tween = TweenService:Create(Lighting, TweenInfo.new(1, Enum.EasingStyle.Linear), {FogColor = color})
			tween:Play()
			tween.Completed:Wait()
		end

		task.spawn(function()
			while using.Value do
				for _, color in ipairs(rainbowColors) do
					if not using.Value then break end
					tweenFogColor(color)
				end
			end
		end)

		for _, p in pairs(Players:GetPlayers()) do
			local char = p.Character
			local main_values = char and char:FindFirstChild('main_values')
			if char and char:FindFirstChild("Humanoid") and p ~= plr and main_values and main_values.INGAME.Value then
				task.spawn(function()
					while using.Value do
						char.Humanoid:PlayEmote("Dance"..math.random(1, 3))
						task.wait(2)
					end
				end)
			end
		end
	end

	-- Finisher wrap-up
	task.wait(10)
	Lighting.FogEnd = 100000
	Lighting.FogColor = Color3.new(1, 1, 1)
	Lighting.TimeOfDay = "14:30:00"
	if finisherSound then
		finisherSound:Stop()
	end
	setAnchor(false)
	using.Value = false
end)
