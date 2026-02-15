local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")

local replicated_maps = rs:WaitForChild("game_maps")
local workspace_maps = workspace:WaitForChild("game_maps")
local remotes = rs:WaitForChild("remotes")

local CountdownEvent = remotes:WaitForChild("CountdownEvent")
local AnimateSpinner = remotes:WaitForChild("AnimateSpinner") -- RemoteEvent

local res = rs:WaitForChild("remotes").gamemode_selection

local exploded = false

local stunamount = 6

local function emit_particle(particle, amount)
	spawn(function()
		repeat wait(0.01) until particle
		particle:Emit(amount)
	end)
end

function main_sound(found_sound, part_to_play_in)
	local sound: Sound = found_sound:Clone()
	sound.Parent = part_to_play_in
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function parry_effect(character)
	local fx = rs.tag_effects.tagged.default

	local hit = fx.Parry:Clone()
	hit.Anchored = false
	local weld = Instance.new("Weld", hit)
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hit

	hit.Position = character.HumanoidRootPart.Position
	
	hit.Attachment.Flash.Enabled = false
	emit_particle(hit.Attachment.Flash,15)
	
	hit.Attachment.Hit.Enabled = false
	emit_particle(hit.Attachment.Hit,15)
	
	hit.Attachment.Vortex.Enabled = false
	emit_particle(hit.Attachment.Vortex,15)
	
	hit.Attachment.Vortex2.Enabled = false
	emit_particle(hit.Attachment.Vortex2,15)
	
	hit.Attachment.vroom.Enabled = false
	emit_particle(hit.Attachment.vroom,15)
	
	hit.Parent = workspace.Fx
	local info = TweenInfo.new(.4)
	game:GetService('TweenService'):Create(hit.Attachment.light, info, {Brightness = 0}):Play()
	game.Debris:AddItem(hit,1)
end

local location = game:GetService('ServerScriptService'):WaitForChild('Ragdoll')
local module = require(location)
local function ragdoll(character, parry)
	local tagValues = character:FindFirstChild("tag_values")
	-- print(1)
	if not tagValues then return end

	-- print(2)
	local stunnedFolder = tagValues:FindFirstChild("stunned")
	if not stunnedFolder then return end
	
	if parry then
		parry_effect(character)
		local s = game:GetService('SoundService').ui_sounds.parry:Clone()
		s.Parent = character.HumanoidRootPart
		s:Play()
		task.delay(1, function()
			s:Destroy()
		end)
	end
	
	-- print(3)

	-- Prevent multiple ragdolls or overlap with stun
	if stunnedFolder:FindFirstChild("Stun") or tagValues:FindFirstChild("Ragdolled") then return end

	-- print(4)
	-- Mark as ragdolled
	local ragdollFlag = Instance.new("BoolValue")
	ragdollFlag.Name = "Ragdolled"
	ragdollFlag.Parent = tagValues
	game.Debris:AddItem(ragdollFlag, stunamount + 1)

	-- Add Stun Value
	
	-- STUN EFFECT
	local function applyStunEffect(character, stunamount)
		local head = character:FindFirstChild("Head")
		if not head then return end

		local stun_effect = rs.tag_effects.tagged.default.DizzyEffect:Clone()
		stun_effect.Anchored = true
		stun_effect.CanCollide = false
		stun_effect.Transparency = 0
		stun_effect.Parent = workspace:FindFirstChild("Fx") or workspace

		local dizzy_particle = stun_effect:FindFirstChild("dizzy_particle")
		local TweenService = game:GetService("TweenService")
		local RunService = game:GetService("RunService")

		local angle = 0
		local heightAmplitude = 0.5
		local baseHeight = 2
		local radius = 0.1
		local startTime = tick()
		local flashTimer = 0

		local connection
		connection = RunService.Heartbeat:Connect(function(dt)
			local elapsed = tick() - startTime
			if elapsed >= stunamount then
				connection:Disconnect()

				if dizzy_particle then
					dizzy_particle.Enabled = false
				end

				task.delay(2, function()
					if stun_effect then
						stun_effect:Destroy()
					end
				end)
				return
			end

			angle += dt * math.pi * 2
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local y = math.sin(elapsed * math.pi * 2) * heightAmplitude + baseHeight
			stun_effect.Position = head.Position + Vector3.new(x, y, z)
			stun_effect.Orientation = Vector3.new(0, math.deg(angle), 0)

			flashTimer += dt
			if flashTimer >= 0.5 then
				flashTimer = 0
				stun_effect.Transparency = 1
			end
		end)
	end
	
	local stun = Instance.new("BoolValue")
	stun.Name = "Stun"
	stun.Value = false
	stun.Parent = stunnedFolder
	game.Debris:AddItem(stun, stunamount)

	applyStunEffect(character, stunamount)
	print("ragdolled")
	module.Ragdoll(character, stunamount)
	
	
	
	

end

local activeLoop
local running = false

local function startRagdollLoop(eventName)
	-- Stop previous loop if one is running
	running = false
	if activeLoop then
		-- wait for previous thread to stop
		task.wait(0.1)
	end

	if eventName == "Earthquake" or eventName == "Sand Storm" then
		running = true

		activeLoop = task.spawn(function()
			while running and rs.Event.Value == eventName do
				task.wait(20)

				local allPlayers = Players:GetPlayers()
				if #allPlayers == 0 then continue end

				local randomPlayer = allPlayers[math.random(1, #allPlayers)]
				local character = randomPlayer.Character
				if not character then continue end

				local main_values = character:FindFirstChild("main_values")
				local ingame = main_values and main_values:FindFirstChild("INGAME")

				if ingame and ingame.Value then
					ragdoll(character)
				end
			end

			activeLoop = nil
		end)
	end
end


-- Listen for changes to the event
rs:WaitForChild("Event").Changed:Connect(function(value)
	
	local Players = game:GetService("Players")

	if value == "Low Gravity" then
		for _, plr in pairs(Players:GetPlayers()) do
			local character = plr.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.JumpPower > 0 then
					humanoid.JumpPower = 50 * plr:WaitForChild('stats').jump.Value
				end
			end
		end
	elseif value == "Default" then
		for _, plr in pairs(Players:GetPlayers()) do
			local character = plr.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.JumpPower > 0 then
					humanoid.JumpPower = 50 * plr:WaitForChild('stats').jump.Value
				end
			end
		end
	end

	
	startRagdollLoop(value)
end)




----------SETTINGS---------
local numGamemodesVoting = 3
local voteTime = 10
---------------------------

local plrVotes = {}

function explode()
	local radius = 5
	local explosionFolder = rs:WaitForChild("explosions")
	
	exploded = true
	
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end

		local tag_values = char:FindFirstChild("tag_values")
		if not tag_values then continue end		

		local main_values = char:FindFirstChild("main_values")
		if not main_values then return end
		if not main_values.INGAME.Value then return end

		tag_values.can_tag.Value = false
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if not char then continue end
		
		rs.remotes.player_remotes.addShake:FireClient(player, {player}, true)

		local tag_values = char:FindFirstChild("tag_values")
		if not tag_values then continue end		
		
		local main_values = char:FindFirstChild("main_values")
		if not main_values then return end
		if not main_values.INGAME.Value then return end

		if tag_values:FindFirstChild("tagger") and tag_values.tagger.Value == true then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			
			tag_values.can_tag.Value = false

			task.spawn(function()
				ragdoll(char)
			end)

			-- Read equipped explosion name from player's StringValue
			local equippedExplosionName = "Default"
			local equippedVal = player:FindFirstChild("EquippedExplosionName")
			if equippedVal and equippedVal.Value ~= "" then
				equippedExplosionName = equippedVal.Value
			end

			local explosionTemplate = explosionFolder:FindFirstChild(equippedExplosionName)

			if explosionTemplate then
				local explosionEffect = explosionTemplate:Clone()
				explosionEffect.Parent = hrp

				-- Play sound
				local sound = explosionEffect:FindFirstChildOfClass("Sound")
				if sound then
					sound:Play()
				end

				-- Play all particle emitters
				for _, desc in ipairs(explosionEffect:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then
						desc.Parent = hrp
						desc.Enabled = false
						desc:Emit(100)
						game:GetService("Debris"):AddItem(desc, 5)
					end
				end

				-- Affect nearby players
				for _, otherPlayer in pairs(Players:GetPlayers()) do
					if otherPlayer ~= player then
						local otherChar = otherPlayer.Character
						if otherChar and otherChar:FindFirstChild("HumanoidRootPart") and otherChar:FindFirstChild("tag_values") then
							local dist = (otherChar.HumanoidRootPart.Position - hrp.Position).Magnitude
							if dist <= radius then
								local otherTagValues = otherChar.tag_values
								local tagger = otherTagValues:FindFirstChild("tagger")
								local canTag = otherTagValues:FindFirstChild("can_tag")
								if tagger then tagger.Value = true end
								if canTag then canTag.Value = false end
								task.spawn(function()
									ragdoll(otherChar)
								end)
							end
						end
					end
				end

				-- Disable tagging for original tagger
				local canTag = tag_values:FindFirstChild("can_tag")
				if canTag then canTag.Value = false end

				game:GetService("Debris"):AddItem(explosionEffect, 5)
			else
				warn("Equipped explosion not found for player", player.Name, ":", equippedExplosionName)
			end
		end
	end

end

function addVote(plr:Player, mapName:string)

	plrVotes[plr] = mapName
	res:WaitForChild("Voted"):FireAllClients(plrVotes)
end

function removePlayerVote(plr:Player)

	plrVotes[plr] = nil
	res:WaitForChild("Voted"):FireAllClients(plrVotes)
end

res:WaitForChild("Voted").OnServerEvent:Connect(addVote)

game.Players.PlayerRemoving:Connect(removePlayerVote)

local gameState = "Intermission"

local function teleportPlayer(player, folderOrPart)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local targetPart
	if folderOrPart:IsA("Folder") then
		local children = folderOrPart:GetChildren()
		if #children == 0 then return end
		targetPart = children[math.random(1, #children)]
	elseif folderOrPart:IsA("BasePart") then
		targetPart = folderOrPart
	else
		return
	end

	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and targetPart then
		hrp.CFrame = CFrame.new(targetPart.Position)
	end

end

local function teleportAllPlayers(folderOrPart)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local afkValue = char and char:FindFirstChild("main_values") and char.main_values:FindFirstChild("AFK")
		if char and afkValue and afkValue.Value == false then
			teleportPlayer(player, folderOrPart)
		end
	end
end


local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		if gameState == "Time Left" and workspace_maps:FindFirstChild("current_map") then
			local spawn = workspace_maps.current_map:WaitForChild("spawn_point")
			teleportPlayer(player, spawn)
		end
	end)
end

local function parrying_effect(character)
	local fx = rs.tag_effects.tagged.default

	local hit = fx.Parrying:Clone()
	hit.Anchored = false
	local weld = Instance.new("Weld", hit)
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hit

	hit.Position = character.HumanoidRootPart.Position
	
	local amount = 5

	hit.Attachment.Beams.Enabled = false
	emit_particle(hit.Attachment.Beams,amount)

	hit.Attachment.Center1.Enabled = false
	emit_particle(hit.Attachment.Center1,amount)

	hit.Attachment.Center2.Enabled = false
	emit_particle(hit.Attachment.Center2,amount)

	hit.Attachment.Circle.Enabled = false
	emit_particle(hit.Attachment.Circle,amount)

	hit.Attachment.Traces.Enabled = false
	emit_particle(hit.Attachment.Traces,amount)

	hit.Parent = workspace.Fx
	local info = TweenInfo.new(.4)
	game:GetService('TweenService'):Create(hit.Attachment.light, info, {Brightness = 0}):Play()
	game.Debris:AddItem(hit,1)
end

rs.useParry.OnServerEvent:Connect(function(plr, cooldown)
	local char = plr and plr.Character
	local mainv = char and char:FindFirstChild('main_values')
	parrying_effect(plr.Character)
	if char and mainv then
		mainv.PARRYING.Value = true
		task.delay(cooldown, function()
			if mainv then
				mainv.PARRYING.Value = false
			end
		end)
	end
end)

local plrs = game:GetService('Players')

local function AllInfectedcountdown(time, message)
	for i = time, 0, -1 do
		CountdownEvent:FireAllClients(message)
		task.wait(1)
	end
end

local function countdown(time, message)
	gameState = message
	local players = plrs:GetPlayers()
	local cancelled = false
	
	local all_infected = false

	local playing = {}
	for _, player in pairs(players) do
		if player.Character and player.Character.main_values.AFK.Value == false then
			local tag_values = player.Character:WaitForChild('tag_values', .2)
			if tag_values then
				table.insert(playing, player)
				if tag_values.tagger.Value == false then
					tag_values.time_survived.Value = time
				end
			end
		end
	end
	
	for i = time, 0, -1 do
		
		local total_players = 0
		local infected = 0
		for _, player in pairs(playing) do
			if player and player.Character then
				local tag_values = player.Character:FindFirstChild('tag_values')
				if tag_values then
					total_players += 1
					if tag_values.tagger.Value then
						infected += 1
					end
				end
			end
		end

		if infected == total_players and infected > 0 and 
			message ~= 'Intermission'
		then
			all_infected = true
			cancelled = true
		end
		
		if cancelled then break end
		CountdownEvent:FireAllClients(message .. ": " .. i, time)
		task.wait(1)
		
		if rs.FinisherBeingUsed.Value then
			repeat wait(.5) until rs.FinisherBeingUsed.Value == false
			cancelled = true
		end
		
		local generators_active = 0
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant:IsA("BoolValue") and descendant.Name == "GeneratorActive" and descendant.Value then
				generators_active += 1
			end
		end
		
		if 
			workspace:FindFirstChild("ExplosionUsed")
			or generators_active >= 3
		then
			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("BoolValue") and descendant.Name == "GeneratorActive" and descendant.Value then
					descendant.Value = false
				end
			end
			if 
				workspace:FindFirstChild("ExplosionUsed")
			then
				workspace:FindFirstChild("ExplosionUsed"):Destroy()
			end
			CountdownEvent:FireAllClients("0:00", 0)
			cancelled = true
			break
		end
		
		for _, player in pairs(game.Players:GetPlayers()) do
			if player.Character then
				local tag_values = player.Character:FindFirstChild('tag_values')
				if tag_values then
					if tag_values.tagger.Value == false then
						tag_values.total_time.Value = time
						tag_values.time_survived.Value -= 1
					end
				end
			end
		end
	end
	if all_infected then
		AllInfectedcountdown(1, "No Survivors")
	end
	cancelled = false
end

Players.PlayerAdded:Connect(onPlayerAdded)

local ss = game:GetService('SoundService')
local repeats = 0
local intermission_time = 15
local intermission_text = "Intermission"

local debris = game:GetService('Debris')

local GearTemplate = rs.Templates.Gear
local CoinScriptTemplate = rs.Templates.Coin.Spin

local function replaceCoins(current_map)
	for _, coin in pairs(current_map:GetChildren()) do
		if coin.Name == "Coin" then
			local coinScript = CoinScriptTemplate:Clone()
			coinScript.Parent = coin
			coinScript.Enabled = true
		end
	end
	for count = 1, 3 do
		local first_coin = current_map:FindFirstChild('Coin')
		if first_coin then
			local coinPosition = first_coin.Position
			first_coin:Destroy()
			local Gear = GearTemplate:Clone()
			Gear.Parent = current_map
			Gear:PivotTo(CFrame.new(coinPosition))
		end
	end
end

local function createMap(map)
	for _, model in pairs(map:GetChildren()) do
		if model.Name ~= "spawn_point" then
			model:Destroy()
		end
	end
	local gridPartPos = rs.GridParts.GridPart.Position
	
	local function randomCoinSpawn()
		for count = 1, 15 do
			local xMin, xMax = gridPartPos.X - (3*32) + 5, gridPartPos.X - 5
			local zMin, zMax = gridPartPos.Z - (3*32) + 5, gridPartPos.Z - 5

			local xRange = math.random(math.min(xMin, xMax), math.max(xMin, xMax))
			local zRange = math.random(math.min(zMin, zMax), math.max(zMin, zMax))

			local coin = rs.Templates.Coin:Clone()
			coin.Parent = map

			local rayOrigin = Vector3.new(xRange, 500, zRange)
			local rayDirection = Vector3.new(0, -1000, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {map}
			raycastParams.FilterType = Enum.RaycastFilterType.Include

			local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			local yPos = result and result.Position.Y + 5 or 0

			coin.Position = Vector3.new(xRange, yPos, zRange)
		end
	end
	
	local sp = map:FindFirstChild('spawn_point')
	if sp then
		for _, spawn_point in pairs(sp:GetChildren()) do
			spawn_point:Destroy()
		end
	end
	
	local mapSets = rs:WaitForChild("MapSets"):GetChildren()
	if #mapSets == 0 then
		warn("No map sets available!")
		return
	end

	local randomMapSet = mapSets[math.random(1, #mapSets)]:GetChildren()
	if #randomMapSet == 0 then
		warn("Selected map set is empty!")
		return
	end

	local origin = Vector3.new(0, 50, 0)
	local ray = RaycastParams.new()
	ray.FilterDescendantsInstances = {map}
	ray.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), ray)
	if not result then return end

	local groundY = 19.191
	local gridPartOrigin = Vector3.new(gridPartPos.X, 
		groundY, gridPartPos.Z)

	for x = 1, 4 do
		for z = 1, 4 do
			local pos = gridPartOrigin - Vector3.new(32 * (x - 1), 0, 32 * (z - 1))
			local template = randomMapSet[math.random(1, #randomMapSet)]
			local model = template:Clone()
			model.Parent = map

			local spawn_point = Instance.new("Part")
			spawn_point.Name = "spawn_point"
			spawn_point.Parent = sp
			spawn_point.Size = Vector3.new(1, 1, 1)
			spawn_point.Transparency = 1
			spawn_point.CanCollide = false
			spawn_point.Anchored = true

			local rotation = CFrame.Angles(0, math.rad(math.random(0, 3) * 90), 0)
			local boundingCFrame, boundingSize = model:GetBoundingBox()
			local bottomY = boundingCFrame.Position.Y - (boundingSize.Y / 2)
			local yOffset = pos.Y - bottomY
			local finalCFrame = CFrame.new(Vector3.new(pos.X, groundY, pos.Z)) * rotation
			
			-- model:PivotTo(finalCFrame)
			local Generator = model:FindFirstChild("Generator")
			if Generator then
				local mainGen = Generator.Generator
				local ProximityPrompt = script.GenProximityPrompt:Clone()
				ProximityPrompt.Name = "ProximityPrompt"
				local ExistingPrompt = mainGen:FindFirstChild("ProximityPrompt")
				if ExistingPrompt then
					ExistingPrompt:Destroy()
				end
				ProximityPrompt.Parent = mainGen
				ProximityPrompt.Triggered:Connect(function(p)
					local hidden_leaderstats = p:FindFirstChild('hidden_leaderstats')
					local currentKey = hidden_leaderstats and hidden_leaderstats:FindFirstChild('CurrentKey')
					local used = hidden_leaderstats and hidden_leaderstats:FindFirstChild('Used')
					local key = (currentKey.Value ~= "" and currentKey.Value) or nil
					if key then
						local HasRed = mainGen:FindFirstChild("HasRed")
						local HasBlue = mainGen:FindFirstChild("HasBlue")
						local function update()
							local sound = script.Insert:Clone()
							sound.Parent = mainGen
							sound:Play()
							task.delay(1, function()
								sound:Destroy()
							end)
							currentKey.Value = ''
						end
						if HasBlue and HasRed then
							local generatorLabel = mainGen:FindFirstChild("GeneratorLabel")
							if string.find(key, "Red") and not HasRed.Value then
								used.Value = true
								HasRed.Value = true
								local Part = Generator.Model.Red
								Part.Transparency = .7
								Part.Material = Enum.Material.Glass
								if generatorLabel then
									generatorLabel.Red.Text = "1/1 🟥"
								end
								update()
							elseif string.find(key, "Blue") and not HasBlue.Value then
								used.Value = true
								HasBlue.Value = true
								local Part = Generator.Model.Blue
								Part.Transparency = .7
								Part.Material = Enum.Material.Glass
								if generatorLabel then
									generatorLabel.Blue.Text = "1/1 🟦"
								end
								update()
							end
							if HasRed.Value and HasBlue.Value then
								local leaderstats = p:FindFirstChild('leaderstats')
								if leaderstats then
									local coins = leaderstats:FindFirstChild("Coins")
									if coins then
										coins.Value += 100
										if p:GetAttribute("Has2xCash") then
											coins.Value += 100
										end
										local clientRemote = rs.remotes.player_remotes.client_sound
										local sound = game:GetService("SoundService").ui_sounds.coins
										clientRemote:FireClient(p, sound)
									end
								end
								local activeSound = mainGen:WaitForChild("Active")
								local startSound = mainGen:WaitForChild("Start")
								activeSound:Play()
								startSound:Play()
								ProximityPrompt:Destroy()
								if generatorLabel then
									generatorLabel:Destroy()
								end
								local smoke = script.Smoke:Clone()
								smoke.Parent = mainGen
								mainGen.GeneratorActive.Value = true
							end
						end
					end
				end)
			end
			
			local Switch = model:FindFirstChild("Switch")
			if Switch then
				local ProximityPrompt = script.LeverProximityPrompt:Clone()
				ProximityPrompt.Name = "ProximityPrompt"
				ProximityPrompt.Parent = Switch.ProxPart
				ProximityPrompt.Triggered:Connect(function()
					ProximityPrompt.Enabled = false
					Switch.Switch:Play()
					Switch.Off.Transparency = 1
					Switch.On.Transparency = 0
					local Door = model:WaitForChild("Door")
					Door.Open:Play()
					Door:Destroy()
					for _, wire in pairs(model:GetChildren()) do
						if wire.Name == "Wire" then
							wire.Transparency = 0
							wire.Color = Color3.new(0, 1, 1)
							wire.Material = Enum.Material.Neon
						end
					end
				end)
			end
			
			local FloorPart = model:FindFirstChild("FloorPart")
			if FloorPart then
				model.PrimaryPart = FloorPart
				model:SetPrimaryPartCFrame(finalCFrame)
			end

			spawn_point.Position = finalCFrame.Position + Vector3.new(0, 32, 0)
		end
	end
	
	local mapChildren = map:GetChildren()
	
	local generators, buttonsRed, buttonsBlue = (function()
		local generator = 0
		local buttons = {
			RedKey = 0,
			BlueKey = 0
		}

		for _, gridPart in pairs(mapChildren) do
			if gridPart.Name == "GridPart" then
				if gridPart:FindFirstChild('Generator') then
					generator += 1
				end
				for _, obj in ipairs(gridPart:GetChildren()) do
					if obj.Name == "RedKey" or obj.Name == "BlueKey" then
						local emitter = obj:FindFirstChild("Emitter")
						obj.Transparency = 0
						if emitter then
							emitter.Enabled = true
						end
						buttons[obj.Name] += 1
					end
				end

			end
		end

		return generator, buttons.RedKey, buttons.BlueKey
	end)()
	
	while generators > 3 or buttonsRed > 3 or buttonsBlue > 3 do
		wait(.01)
		local GridPart = mapChildren[math.random(1, #mapChildren)]
		if GridPart and GridPart.Name == "GridPart" then
			if generators > 3 and math.random(1, 2) == 1 then
				local gen = GridPart:FindFirstChild('Generator')
				if gen then
					gen:Destroy()
					generators -= 1
				end
			else
				if buttonsRed > 3 and math.random(1, 2) == 1 then
					local redkey = GridPart:FindFirstChild('RedKey')
					if redkey then
						redkey:Destroy()
						buttonsRed -= 1
					end
				elseif buttonsBlue > 3 then
					local bluekey = GridPart:FindFirstChild('BlueKey')
					if bluekey then
						bluekey:Destroy()
						buttonsBlue -= 1
					end
				end
			end
		end
	end
	
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local function keyHolding(object: Part, rootPart: Part, currentKey:StringValue, originalPart, used)
		object.Parent = workspace.Fx
		object.Anchored = true

		local offset = CFrame.new(0, 2, 3)

		local tweenInfo = TweenInfo.new(
			0.25, -- Tween duration
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out
		)

		-- Disconnect any existing connection to prevent stacking
		if object:FindFirstChild("UpdateConnection") then
			object:FindFirstChild("UpdateConnection"):Destroy()
		end

		local update = Instance.new("BindableEvent")
		update.Name = "UpdateConnection"
		update.Parent = object
		
		local resetted = false
		
		local function reset()
			if update and originalPart and not resetted then
				resetted = true
				update:Destroy()
				if object then
					object:Destroy()
				end
				if used and used.Value then
					used.Value = false
				else
					originalPart.Transparency = 0
					originalPart.Emitter.Enabled = true
					originalPart.ProximityPrompt.Enabled = true
				end
			end
		end

		update.Event:Connect(function()
			if not object or not object.Parent or not rootPart or not rootPart.Parent then
				reset()
				return
			end

			local targetCFrame = rootPart.CFrame * offset
			local tween = TweenService:Create(object, tweenInfo, {CFrame = targetCFrame})
			tween:Play()
		end)
		
		if currentKey then
			currentKey.Changed:Connect(function(value)
				if value == "" then
					reset()
				end
			end)
			currentKey.Destroying:Connect(function()
				reset()
			end)
		else
			reset()
		end

		local hb
		hb = RunService.Heartbeat:Connect(function()
			if not currentKey or not currentKey.Parent then
				hb:Disconnect()
				reset()
				return
			end

			local player = currentKey.Parent.Parent
			if not player or not player.Character then
				hb:Disconnect()
				reset()
				return
			end

			local tagValues = player.Character:FindFirstChild("tag_values")
			if not tagValues then
				hb:Disconnect()
				reset()
				return
			end

			local isTagger = tagValues:FindFirstChild("tagger")
			if not isTagger or isTagger.Value then
				hb:Disconnect()
				reset()
				return
			end

			if update and update.Parent then
				update:Fire()
			else
				hb:Disconnect()
			end
		end)

		currentKey.Destroying:Connect(function()
			if hb then
				hb:Disconnect()
			end
		end)

	end

	
	(function()
		for _, gridPart in pairs(mapChildren) do
			if gridPart.Name == "GridPart" then
				local rk = gridPart:FindFirstChild('RedKey')
				local bk = gridPart:FindFirstChild('BlueKey')
				if rk and rk.Transparency == 0 then
					local ProximityPrompt = script.ColProximityPrompt:Clone()
					ProximityPrompt.Name = "ProximityPrompt"
					ProximityPrompt.Parent = rk
					ProximityPrompt.Triggered:Connect(function(p)
						local hidden_leaderstats = p:FindFirstChild('hidden_leaderstats')
						local currentKey = hidden_leaderstats and hidden_leaderstats:FindFirstChild('CurrentKey')
						local used = hidden_leaderstats and hidden_leaderstats:FindFirstChild('Used')
						local key = (currentKey.Value ~= "" and currentKey.Value) or nil
						if not key then
							currentKey.Value = 'Red'
							ProximityPrompt.Enabled = false
							rk.Transparency = 1
							rk.Emitter.Enabled = false
							
							local collect = script.Collect:Clone()
							collect.Parent = rk
							collect:Play()
							task.delay(1, function()
								collect:Destroy()
							end)
							
							local char = p and p.Character
							local rootpart = char and char:FindFirstChild('HumanoidRootPart')
							if rootpart then
								keyHolding(script.Keys.Red:Clone(), rootpart, currentKey, rk, used)
							end
						end
					end)
				end
				if bk and bk.Transparency == 0 then
					local ProximityPrompt = script.ColProximityPrompt:Clone()
					ProximityPrompt.Name = "ProximityPrompt"
					ProximityPrompt.Parent = bk
					ProximityPrompt.Triggered:Connect(function(p)
						local hidden_leaderstats = p:FindFirstChild('hidden_leaderstats')
						local currentKey = hidden_leaderstats and hidden_leaderstats:FindFirstChild('CurrentKey')
						local used = hidden_leaderstats and hidden_leaderstats:FindFirstChild('Used')
						local key = (currentKey.Value ~= "" and currentKey.Value) or nil
						if not key then
							currentKey.Value = 'Blue'
							ProximityPrompt.Enabled = false
							bk.Transparency = 1
							bk.Emitter.Enabled = false
							
							local collect = script.Collect:Clone()
							collect.Parent = bk
							collect:Play()
							task.delay(1, function()
								collect:Destroy()
							end)
							
							local char = p and p.Character
							local rootpart = char and char:FindFirstChild('HumanoidRootPart')
							if rootpart then
								keyHolding(script.Keys.Blue:Clone(), rootpart, currentKey, bk, used)
							end
						end
					end)
				end
			end
		end
	end)()
	
	randomCoinSpawn()
end

local lastMapName
function chooseMap()
	local maps = replicated_maps:GetChildren()
	if #maps == 0 then
		return nil
	end

	local filtered = {}

	for _, map in ipairs(maps) do
		if map.Name ~= lastMapName then
			table.insert(filtered, map)
		end
	end

	local options = #filtered > 0 and filtered or maps
	local chosen = options[math.random(1, #options)]
	lastMapName = chosen.Name

	if workspace_maps:FindFirstChild("current_map") then
		workspace_maps.current_map:Destroy()
	end
	
	local clone = chosen:Clone()
	clone.Name = "current_map"
	clone.Parent = workspace_maps
	
	createMap(clone)

	replaceCoins(clone)

	return clone
end

rs.ragdoll.OnServerEvent:Connect(function(plr, parry)
	ragdoll(plr.Character, parry)
end)

while true do
	rs.InGame.Value = false
	rs.Event.Value = "Default"
	
	if repeats >= 9999 then
		repeats = 0
		intermission_time = 30
		intermission_text = "???"
	end
	countdown(intermission_time, intermission_text)
	
	local active_players = 0
	local players = Players:GetChildren()
	for _, plr in pairs(players) do
		local character = plr.Character or plr.CharacterAdded:Wait()
		local mainValues = character:FindFirstChild("main_values") or character:WaitForChild("main_values", 5) -- waits up to 5 seconds

		if mainValues then
			local afkValue = mainValues:FindFirstChild("AFK") or mainValues:WaitForChild("AFK", 5)
			if afkValue and afkValue.Value == false then
				active_players += 1
			end
		end
	end
	
	if active_players >= 2 then
		repeats += 1

		local clone = chooseMap()
		
		countdown(4, "Loading Maps")
		
		if math.random(1, 3) == 3 then
			local events = rs.Event.Events:GetChildren()
			local randomEvent = events[math.random(1, #events)]

			ss.ui_sounds.event_ping:Play()

			rs.Event.Value = randomEvent.Name
		end
		
		rs.InGame.Value = true

		local spawnpoint = clone:WaitForChild("spawn_point")
		teleportAllPlayers(spawnpoint)
		rs.game_settings.game_started.Value = true
		
		local round_time = 150
		countdown(round_time, "Explosion in")
		
		rs.disableUI:FireAllClients(true)
		
		repeat wait(.5) until rs.FinisherBeingUsed.Value == false
		
		if not exploded then
			task.spawn(explode)
		end
		exploded = false
		
		ss.ui_sounds.tung:Play()
		countdown(5, "Game Ended")
		
		-- task.wait(5)
		local spawnpoint = workspace:WaitForChild("spawn_point")
		teleportAllPlayers(spawnpoint)
		
		CountdownEvent:FireAllClients("Round Over")
		rs.game_settings.game_started.Value = false
	end

	gameState = "Intermission"
end

