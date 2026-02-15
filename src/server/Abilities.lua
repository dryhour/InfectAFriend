local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local ability = ReplicatedStorage:WaitForChild('useAbility')

local fol = script.AbilityParticles

local location = game:GetService('ServerScriptService'):WaitForChild('Ragdoll')
local module = require(location)

ability.OnServerEvent:Connect(function(plr, abilityName)
	if typeof(abilityName) ~= "string" then return end
	
	if abilityName == "Slip All" or abilityName == "Explode" then
		if abilityName == "Slip All" then
			local stunamount = 4
			local function emit_particle(particle, amount)
				spawn(function()
					repeat wait(0.01) until particle
					particle:Clone():Emit(amount)
				end)
			end

			local function main_sound(found_sound, part_to_play_in)
				local sound: Sound = found_sound:Clone()
				sound.Parent = part_to_play_in
				sound:Play()
				sound.Ended:Connect(function()
					sound:Destroy()
				end)
			end
			local function ragdoll(character)
				local tagValues = character:FindFirstChild("tag_values")
				if not tagValues then return end

				local stunnedFolder = tagValues:FindFirstChild("stunned")
				if not stunnedFolder then return end

				-- Prevent multiple ragdolls or overlap with stun
				if stunnedFolder:FindFirstChild("Stun") or tagValues:FindFirstChild("Ragdolled") then return end

				-- Mark as ragdolled
				local ragdollFlag = Instance.new("BoolValue")
				ragdollFlag.Name = "Ragdolled"
				ragdollFlag.Parent = tagValues
				game.Debris:AddItem(ragdollFlag, stunamount + 1)

				-- Add Stun Value
				task.delay(.05, function()
					local stun = Instance.new("BoolValue")
					stun.Name = "Stun"
					stun.Value = false
					stun.Parent = stunnedFolder
					game.Debris:AddItem(stun, stunamount)
				end)
				local rs = ReplicatedStorage
				main_sound(rs.tag_effects.stun.default.sounds.cartoon_dizzy, character.HumanoidRootPart)

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

				applyStunEffect(character, stunamount)
				module.Ragdoll(character, stunamount)
			end

			for i,p in pairs(Players:GetChildren()) do
				local char = p.Character
				if char and char:FindFirstChild("Humanoid")
					and char.main_values.INGAME.Value == true
					and p ~= plr
					and char.main_values.SHIELD.Value == false
				then
					ragdoll(char)
				end
			end
		elseif abilityName == "Explode" then
			
		end
	else
		local stats = plr:FindFirstChild("ability_leaderstats")
		if not stats then return end

		local stat = stats:FindFirstChild(abilityName)
		if not stat or stat.Value <= 0 then return end

		-- Decrease stat
		stat.Value -= 1

		if abilityName == "Speed Boost" then
			-- TODO: ALREADY IMPLEMENTED, DW ANBOUT SPED BOSt
			local mainValues = plr:FindFirstChild("main_values")
			if mainValues and mainValues:FindFirstChild("SPEEDBOOST") then
				mainValues["SPEEDBOOST"].Value = true
				task.delay(7, function()
					mainValues["SPEEDBOOST"].Value = false
				end)
			end
		-- PARTICLE + Sound
			local character = plr.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local sound = fol["Speed Boost"].sound:Clone()
					sound.Parent = character.PrimaryPart
					sound:Play()
					sound.PlayOnRemove = true
					sound:Destroy()
					
					for i,particle in pairs(fol["Speed Boost"]:GetChildren()) do
						if particle:IsA('ParticleEmitter') then
							particle = particle:Clone()
							particle.Parent = hrp
							particle.Enabled = true
							task.delay(7, function()
								particle.Enabled = false
								wait(1)
								if particle then particle:Destroy() end
							end)
						end
					end
					
				end
			end
			-- end of speed boost
			
			-- add sound in humanoidroot part
			-- TODO : effect around player

		elseif abilityName == "Swap" then
			local otherPlayers = {}
			for _, p in pairs(Players:GetPlayers()) do
				if p.Character then
					local main_values = p.Character:FindFirstChild('main_values')
					if p ~= plr and main_values and main_values.INGAME.Value then
						table.insert(otherPlayers, p)
					end
				end
			end

			if #otherPlayers > 0 then
				local target = otherPlayers[math.random(1, #otherPlayers)]

				local char1 = plr.Character
				local sound1 = fol.Swap.sound:Clone()
				sound1.Parent = char1.PrimaryPart
				sound1:Play()
				sound1.PlayOnRemove = true
				sound1:Destroy()
				for i,particle in pairs(fol.Swap:GetChildren()) do
					if particle:IsA('ParticleEmitter') then
						particle = particle:Clone()
						particle.Parent = char1.HumanoidRootPart
						particle.Enabled = true
						task.delay(3, function()
							particle.Enabled = false
							wait(1)
							if particle then particle:Destroy() end
						end)
					end
				end
				
				local char2 = target.Character
				local sound2 = fol.Swap.sound:Clone()
				sound2.Parent = char2.PrimaryPart
				sound2:Play()
				sound2.PlayOnRemove = true
				sound2:Destroy()
				for i,particle in pairs(fol.Swap:GetChildren()) do
					if particle:IsA('ParticleEmitter') then
						particle = particle:Clone()
						particle.Parent = char2.HumanoidRootPart
						particle.Enabled = true
						task.delay(3, function()
							particle.Enabled = false
							wait(1)
							if particle then particle:Destroy() end
						end)
					end
				end

				if char1 and char2 and char1:FindFirstChild("HumanoidRootPart") and char2:FindFirstChild("HumanoidRootPart") then
					local temp = char1.HumanoidRootPart.Position
					char1.HumanoidRootPart.CFrame = char2.HumanoidRootPart.CFrame
					char2.HumanoidRootPart.CFrame = CFrame.new(temp)
				end
			end


			-- add sound in humanoidroot part
			-- TODO : effect around player
		elseif abilityName == "Dash" then
			local character = plr.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then return end

			local hrp = character.HumanoidRootPart
			local dashDistance = 40
			local dashSpeed = 100 -- studs per second
			local dashDuration = dashDistance / dashSpeed

			-- Check for wall in front
			local direction = hrp.CFrame.LookVector
			local origin = hrp.Position

			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local rayResult = workspace:Raycast(origin, direction * dashDistance, raycastParams)

			local actualDistance = dashDistance
			if rayResult then
				actualDistance = (rayResult.Position - origin).Magnitude - 2 -- leave a 2-stud gap
				if actualDistance <= 0 then
					return -- too close to dash
				end
			end

			-- Use BodyVelocity for the dash
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = direction * (actualDistance / dashDuration)
			bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5) -- lock Y to avoid upward boost
			bodyVelocity.P = 1e5
			bodyVelocity.Parent = hrp

			-- Clean up after dash duration
			task.delay(dashDuration, function()
				bodyVelocity:Destroy()
			end)
			
			local sound = fol["Dash"].sound:Clone()
			sound.Parent = character.PrimaryPart
			sound:Play()
			sound.PlayOnRemove = true
			sound:Destroy()

			for i,particle in pairs(fol.Dash:GetChildren()) do
				if particle:IsA('ParticleEmitter') then
					particle = particle:Clone()
					particle.Parent = hrp
					particle.Enabled = true
					task.delay(3, function()
						particle.Enabled = false
						wait(1)
						if particle then particle:Destroy() end
					end)
				end
			end


		elseif abilityName == "Freeze All" then
			local TweenService = game:GetService("TweenService")
			local Players = game:GetService("Players")

			local icecube = fol["Freeze All"].icecube
			local sound = fol["Freeze All"].sound:Clone()
			sound.Parent = workspace
			sound:Play()
			sound.PlayOnRemove = true
			sound:Destroy()

			for _, p in pairs(Players:GetPlayers()) do
				local char = p.Character
				if char and char:FindFirstChild("Humanoid")
					and char.main_values.INGAME.Value == true
					and p ~= plr
					and char.main_values.SHIELD.Value == false
				then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if not hrp then continue end

					-- Freeze movement
					char.Humanoid.WalkSpeed = 0
					hrp.Anchored = true

					-- Create & place the ice cube in the air first
					local n_ice = icecube:Clone()
					n_ice.Size = Vector3.new(0.5, 0.5, 0.5)
					n_ice.CFrame = CFrame.new(hrp.Position) -- spawn above
					n_ice.Parent = workspace

					-- Tween down into position over 0.4 seconds
					local goalCFrame = CFrame.new(hrp.Position)
					local goalSize = Vector3.new(4, 6, 4)

					local moveTween = TweenService:Create(n_ice, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						CFrame = goalCFrame,
						Size = goalSize
					})
					moveTween:Play()

					-- After it's in place, parent it to the player
					moveTween.Completed:Connect(function()
						n_ice.Parent = hrp
					end)

					-- Unfreeze after 3 seconds
					task.delay(3, function()
						if char and char:FindFirstChild("Humanoid") and hrp then
							char.Humanoid.WalkSpeed = 16
							hrp.Anchored = false
							n_ice:Destroy()
						end
					end)
				end
			end

			
			-- add sound in humanoidroot part
			

		elseif abilityName == "Shield" then
			if plr.Character then
				local mainValues = plr.Character:FindFirstChild("main_values")
				if mainValues and mainValues:FindFirstChild("SHIELD") then
					mainValues.SHIELD.Value = true
					
					for i,particle in pairs(fol.Shield:GetChildren()) do
						if particle:IsA('ParticleEmitter') then
							particle = particle:Clone()
							particle.Parent = plr.Character.HumanoidRootPart
							particle.Enabled = true
							task.delay(7, function()
								particle.Enabled = false
								wait(1)
								if particle then particle:Destroy() end
							end)
						end
					end
					
					-- add sound in humanoidroot part
					-- add shield around player
					task.delay(7, function()
						mainValues.SHIELD.Value = false
						-- remove shield
					end)
				end
			end
		end
	end
end)
