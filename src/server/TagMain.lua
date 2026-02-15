local rs = game:GetService('ReplicatedStorage')
local g_settings = rs.game_settings
local game_started = g_settings.game_started

local stunamount = 4

rs.afk.OnServerEvent:Connect(function(plr, value)
	plr.Character.main_values.AFK.Value = value
end)

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

local function hit_effect(character)
	local fx = rs.tag_effects.tagged.default

	local hit = fx.Hit:Clone()
	hit.Anchored = false
	local weld = Instance.new("Weld", hit)
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hit

	hit.Position = character.HumanoidRootPart.Position
	hit.Attachment.Flash.Enabled = false

	emit_particle(hit.Attachment.Flash,15)
	hit.Parent = workspace.Fx
	local info = TweenInfo.new(.4)
	game:GetService('TweenService'):Create(hit.Attachment.light, info, {Brightness = 0}):Play()
	game.Debris:AddItem(hit,1)
end

local function game_ended()
	for _, player in pairs(game.Players:GetPlayers()) do
		local tag_values = player.Character:FindFirstChild('tag_values')
		player.Character.main_values.INGAME.Value = false
		if tag_values then
			if tag_values.tagger.Value == true then
				player.hidden_leaderstats['Losses'].Value += 1
			else
				player.leaderstats['Wins'].Value += 1
				local total_time = tag_values.total_time.Value
				local time_survived = tag_values.time_survived.Value
				local amount = 129 * (time_survived/total_time)
				amount = math.abs(math.ceil(amount)) + 7
				
				player.leaderstats.Coins.Value += amount
				if player:GetAttribute("Has2xCash") then
					player.leaderstats.Coins.Value += amount
				end
				player.hidden_leaderstats['Time Survived'].Value += math.abs(math.ceil(time_survived))
				
				local sound = rs.game_sounds.coins
				rs.remotes.player_remotes.client_sound:FireAllClients(player, sound, workspace)
			end
			tag_values.tagger.Value = false
			
			tag_values:Destroy()
		end
	end
	-- destroy effects and reset map
end

local function setup_players()
	local tag_values = rs.tag_values
	for _, player in pairs(game.Players:GetPlayers()) do
		if player.Character and player.Character.main_values.AFK.Value == false then
			player.Character.main_values.INGAME.Value = true
			tag_values:Clone().Parent = player.Character
		end
	end
end

local runner_effect = rs.tag_effects.player_effects.runner.Runner
local tagger_effect = rs.tag_effects.player_effects.tagger.Tagger

local location = game:GetService('ServerScriptService'):WaitForChild('Ragdoll')
local module = require(location)

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
		local stunEffect = stun_effect -- Cache reference
		local headRef = head
		local dizzy = dizzy_particle

		connection = RunService.Heartbeat:Connect(function(dt)
			local now = tick()
			local elapsed = now - startTime

			if elapsed >= stunamount then
				if connection then
					connection:Disconnect()
					connection = nil
				end

				if dizzy then
					dizzy.Enabled = false
				end

				if stunEffect then
					-- Only destroy if it's still in workspace
					task.delay(2, function()
						if stunEffect and stunEffect:IsDescendantOf(workspace) then
							stunEffect:Destroy()
						end
					end)
				end

				return
			end

			-- Animate effect
			angle += dt * math.pi * 2
			flashTimer += dt

			local cosA = math.cos(angle)
			local sinA = math.sin(angle)

			local x = cosA * radius
			local z = sinA * radius
			local y = math.sin(elapsed * math.pi * 2) * heightAmplitude + baseHeight

			stunEffect.Position = headRef.Position + Vector3.new(x, y, z)
			stunEffect.Orientation = Vector3.new(0, math.deg(angle), 0)

			if flashTimer >= 0.5 then
				flashTimer = 0
				stunEffect.Transparency = 1
			end
		end)

	end

	applyStunEffect(character, stunamount)
	module.Ragdoll(character, stunamount)
end

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local runservice = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

local SWITCH_TAGGER_PRODUCT_ID = 3313761605 -- Replace with your actual developer product ID

local function main()
	local current_tagger = g_settings.current_tagger
	if game_started.Value then

		setup_players()
		
		task.wait(2)

		
		local function assignTaggerIfNone()
			local hasTagger = false
			
			local players = game.Players:GetPlayers()

			for _, player in pairs(players) do
				local char = player.Character
				local tagv = char and char:FindFirstChild("tag_values")
				if char and tagv then
					local taggerv = tagv:FindFirstChild("tagger")
					if taggerv and taggerv.Value then
						hasTagger = true
						break
					end
				end
			end

			if not hasTagger then
				-- Collect available players who are not AFK
				local availablePlayers = {}
				for _, player in pairs(players) do
					local char = player.Character
					local mainv = char and char:FindFirstChild("main_values")
					if char and mainv then
						local afk = mainv:FindFirstChild("AFK")
						if afk and afk.Value == false then
							table.insert(availablePlayers, player)
						end
					end
				end

				if #availablePlayers > 0 then
					local newTagger = availablePlayers[math.random(1, #availablePlayers)]
					local char = newTagger.Character
					local tagv = char and char:FindFirstChild("tag_values")
					if char and tagv then
						local taggerv = tagv:FindFirstChild("tagger")
						if taggerv then
							taggerv.Value = true
							tagv.can_tag.Value = true
							g_settings.current_tagger.Value = newTagger.Name

							-- Optional: visual/audio effects
							rs.remotes.player_remotes.addShake:FireAllClients({newTagger})
							-- print("Assigned new tagger: " .. newTagger.Name)
						end
					end
				else
					-- warn("No available players to assign as tagger.")
				end
			end
		end
		
		local function ensureSingleTagger()
			local taggers = {}
			
			local players = game.Players:GetPlayers()

			for _, player in pairs(players) do
				local char = player.Character
				local tagv = char and char:FindFirstChild("tag_values")
				if char and tagv then
					local taggerv = tagv:FindFirstChild("tagger")
					if taggerv and taggerv.Value then
						table.insert(taggers, player)
					end
				end
			end

			if #taggers > 1 then
				local keepTagger = taggers[math.random(1, #taggers)]

				for _, player in pairs(taggers) do
					local char = player.Character
					local tagv = char and char:FindFirstChild("tag_values")
					if player ~= keepTagger and char then
						if tagv then
							tagv.tagger.Value = false
							tagv.can_tag.Value = true
						end
					end
				end

				g_settings.current_tagger.Value = keepTagger.Name
			end
			
			task.delay(1, function()
				assignTaggerIfNone()
			end)
		end
		




		local function trackInfection(player)
			if not player then return end
			local char = player.Character
			if not char then return end

			local tag_values = char:FindFirstChild("tag_values")
			if not tag_values then return end

			local tagger = tag_values:FindFirstChild("tagger")
			if not tagger then return end

			local startTime = tick()
			local MAX_DURATION = 50

			while true do
				-- Break if any condition fails
				if not tagger.Value or not game_started.Value or (tick() - startTime >= MAX_DURATION) then
					break
				end

				-- Minimal checks to avoid errors if character/tagger removed during loop
				if not player.Character or not tagger.Parent then
					break
				end

				task.wait(1)
			end

			if tagger.Value and game_started.Value then
				local success, err = pcall(function()
					-- MarketplaceService:PromptProductPurchase(player, SWITCH_TAGGER_PRODUCT_ID)
				end)
				if not success then
					-- Avoid spamming logs in production
					-- warn("Failed to prompt product purchase:", err)
				end
			end
		end


		
		--[[local remote = rs:WaitForChild("PlayerMoved")
		local afkTimes = {}

		remote.OnServerEvent:Connect(function(player, pos, camRot)
			local data = afkTimes[player]
			local now = tick()

			if not data then
				afkTimes[player] = {
					lastPos = pos,
					lastRot = camRot,
					lastActive = now
				}
			else
				local moved = (pos - data.lastPos).Magnitude > 0.1
				local turned = (camRot - data.lastRot).Magnitude > 0.1

				if moved or turned then
					data.lastActive = now
				end

				data.lastPos = pos
				data.lastRot = camRot
			end
		end)

		-- AFK Checker loop
		task.spawn(function()
			while true do
				task.wait(5)

				local now = tick()

				for player, data in pairs(afkTimes) do
					-- Skip invalid player objects
					if not player or not player:IsDescendantOf(Players) then
						afkTimes[player] = nil
						continue
					end

					local char = player.Character
					if not char then
						continue
					end

					local tag_values = char:FindFirstChild("tag_values")
					if not tag_values then
						continue
					end

					local tagger = tag_values:FindFirstChild("tagger")
					if tagger and tagger.Value == true then
						if now - data.lastActive >= 50 then
							player:Kick("Kicked for being AFK too long.")
							afkTimes[player] = nil
						end
					end
				end
			end
		end)]]




		local function create_tagger()
			local function get_player()
				local players = game.Players:GetPlayers()
				local available_players = {}
				for _, player in ipairs(players) do
					local char = player.Character
					local mainv = char and char:FindFirstChild("main_values")
					if char and mainv then
						local afkValue = mainv:FindFirstChild("AFK")
						if afkValue and afkValue.Value == false then
							table.insert(available_players, player)
						end
					end
				end
				if #available_players > 0 then
					return available_players[math.random(1, #available_players)]
				else
					return nil
				end
			end

			local maxRetries = 20
			local retryDelay = 0.1
			local retries = 0

			local random_tagger = get_player()

			local retries = 0
			local random_tagger = nil

			while not random_tagger and retries < maxRetries do
				task.wait(retryDelay)

				random_tagger = get_player()

				if not random_tagger then
					retries += 1
				end
			end

			
			local rChar = random_tagger and random_tagger.Character
			if random_tagger and rChar then
				current_tagger.Value = random_tagger.Name

				local tag_values = rChar:FindFirstChild("tag_values")
				local taggerv = tag_values and tag_values:FindFirstChild("tagger")
				if tag_values and taggerv then
					taggerv.Value = true
				end

				rs.remotes.player_remotes.addShake:FireAllClients({random_tagger})

				task.spawn(function()
					trackInfection(random_tagger)
				end)
			else
				-- warn("Failed to get a valid random tagger after multiple attempts.")
			end

			return random_tagger
		end

		local random_tagger: Player = create_tagger()

		rs.remotes.player_remotes.tag.OnServerEvent:Connect(function(plr, new_tagger, old_tagger, is_infected)
			if is_infected then
				local hidden = plr:FindFirstChild('hidden_leaderstats')
				if hidden then
					local tags = hidden:FindFirstChild('Tags')
					if tags then
						tags.Value += 1
					end
				end
				random_tagger = Players:GetPlayerFromCharacter(new_tagger)
				local rChar = random_tagger and random_tagger.Character
				if new_tagger and random_tagger and rChar then
					current_tagger.Value = random_tagger.Name
					local tag_values = rChar:FindFirstChild('tag_values')
					local taggerv = tag_values and tag_values:FindFirstChild('tagger')
					if taggerv then
						taggerv.Value = true
						rs.remotes.player_remotes.addShake:FireAllClients({random_tagger})
						task.spawn(function()
							trackInfection(random_tagger)
						end)
						if old_tagger then
							rs.remotes.player_remotes.addShake:FireAllClients({game.Players:GetPlayerFromCharacter(old_tagger)})
							-- local old_tag_values = old_tagger:FindFirstChild('tag_values')
							-- old_tag_values.tagger.Value = false

							-- launch(old_tagger, new_tagger.HumanoidRootPart)
							hit_effect(new_tagger)
							task.spawn(function()
								ragdoll(new_tagger)
							end)
						end
					end
				end
			else
				if new_tagger and new_tagger:FindFirstChild("HumanoidRootPart") and old_tagger then
					-- launch(old_tagger, new_tagger.HumanoidRootPart)
					hit_effect(new_tagger)
					task.spawn(function()
						ragdoll(new_tagger, stunamount, old_tagger)
					end)
				end
			end
		end)

		local TweenService = game:GetService("TweenService")

		local function addTaggerLabel(character)
			-- ensureSingleTagger()
			local head = character:FindFirstChild("Head")
			if not head then return end
			
			local player = Players:GetPlayerFromCharacter(character)

			local function colorFromString(str)
				if typeof(str) == "Color3" then
					return str
				end

				if typeof(str) ~= "string" then
					warn("Expected string in colorFromString, got:", typeof(str))
					return Color3.new(1, 1, 1)
				end

				local components = string.split(str, ",")
				local r, g, b = tonumber(components[1]), tonumber(components[2]), tonumber(components[3])
				if r and g and b then
					return Color3.fromRGB(r, g, b)
				else
					warn("Invalid color string:", str)
					return Color3.new(1, 1, 1)
				end
			end

			local equippedColor = colorFromString(player:WaitForChild("EquippedInfectionColor").Value)

			if not head:FindFirstChild("TaggerLabel") then
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "TaggerLabel"
				billboard.Size = UDim2.new(0, 100, 0, 40)
				billboard.StudsOffset = Vector3.new(0, 3.0, 0)
				billboard.Adornee = head
				billboard.MaxDistance = 70
				billboard.AlwaysOnTop = true
				billboard.Parent = head

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = "INFECTED"
				label.TextColor3 = equippedColor
				label.TextStrokeTransparency = 0.5
				label.TextScaled = true
				label.Font = Enum.Font.FredokaOne
				label.Parent = billboard
			end

			if not character:FindFirstChild("Tagger") then
				local highlight = Instance.new("Highlight")
				highlight.Name = "Tagger"
				highlight.FillColor = equippedColor
				highlight.OutlineColor = equippedColor
				highlight.Enabled = true
				highlight.FillTransparency = 0.2
				highlight.OutlineTransparency = 0.4
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.Parent = character

				local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				local tween = TweenService:Create(highlight, tweenInfo, { FillTransparency = 0.6 })
				tween:Play()
			end
		end

		local function removeTaggerLabel(character)
			local head = character:FindFirstChild("Head")
			if head and head:FindFirstChild("TaggerLabel") then
				head.TaggerLabel:Destroy()
			end
		end

		local players = game.Players:GetPlayers()
		local tagger_check = runservice.Heartbeat:Connect(function()
			for _, player in pairs(players) do
				local character = player.Character
				if character then
					local tag_values = character:FindFirstChild("tag_values")

					if tag_values then
						local isTagger = tag_values.tagger.Value == true
						local hasTagger = character:FindFirstChild("Tagger")
						local hasRunner = character:FindFirstChild("Runner")

						if isTagger and not hasTagger then
							if hasRunner then
								hasRunner:Destroy()
							end
							addTaggerLabel(character)
						elseif not isTagger and not hasRunner then
							if hasTagger then
								hasTagger:Destroy()
							end
							runner_effect:Clone().Parent = character
							removeTaggerLabel(character)
						end

						-- isTagger and
						local can_tag = tag_values.can_tag
						if #tag_values.stunned:GetChildren() <= 0 and game_started.Value == true then
							can_tag.Value = true
						else
							can_tag.Value = false
						end
					else
						local Tagger = character:FindFirstChild("Tagger")
						if Tagger then
							Tagger:Destroy()
						end
						local Runner = character:FindFirstChild("Runner")
						if Runner then
							Runner:Destroy()
						end
						removeTaggerLabel(character)
					end
				end
			end

			game.Players.PlayerRemoving:Connect(function(leavingPlayer)
				local rChar = leavingPlayer.Character
				if not rChar then return end

				local tag_values = rChar:FindFirstChild("tag_values")
				if not (tag_values and tag_values:FindFirstChild("tagger") and tag_values.tagger.Value == true) then return end

				local numOfTaggers = 0

				for _, player in pairs(game.Players:GetPlayers()) do
					if player ~= leavingPlayer then
						local character = player.Character
						if character then
							local otherTagValues = character:FindFirstChild("tag_values")
							if otherTagValues and otherTagValues:FindFirstChild("tagger") then
								if otherTagValues.tagger.Value == true then
									numOfTaggers += 1
								end
							end
						end
					end
				end

				if numOfTaggers > 0 then
					removeTaggerLabel(rChar)
					task.spawn(function()
						random_tagger = create_tagger()
					end)
				end
			end)


			if current_tagger.Value == "" or not random_tagger then
				random_tagger = create_tagger()
			end
		end)
		
		MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
			if wasPurchased then
				local SWITCH_TAGGER_PRODUCT_ID = 3313761605
				if productId == SWITCH_TAGGER_PRODUCT_ID then
					local player = Players:GetPlayerByUserId(userId)
					if player then
						local character = player.Character
						if character then
							local tag_values = character:FindFirstChild("tag_values")
							local taggerv = tag_values.tagger
							if tag_values and taggerv.Value then
								taggerv.Value = false
								tag_values.can_tag.Value = true
								removeTaggerLabel(character)

								local new_tagger = create_tagger()
								if new_tagger then
									print(player.Name .. " paid to switch tagger to " .. new_tagger.Name)
								else
									warn("No new tagger available after purchase")
								end
							end
						end
					end
				end
			end
		end)

		--[[MarketplaceService.ProcessReceipt = function(receiptInfo)
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			
			local SWITCH_TAGGER_PRODUCT_ID = 3313761605
			if receiptInfo.ProductId == SWITCH_TAGGER_PRODUCT_ID then
				
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end]]--
	end
end


game_started.Changed:Connect(function(game_value)
	if game_value then
		main()
	else
		game_ended()
	end
end)