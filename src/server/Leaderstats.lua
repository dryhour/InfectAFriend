local players = game:GetService('Players')
local DataStoreService = game:GetService("DataStoreService")
local timeStore = DataStoreService:GetDataStore("LastOnlineTime")
local statStore = DataStoreService:GetDataStore("PlayerStats")

-- Ordered DataStores for leaderboard (Wins and Coins)
local winsOrderedStore = DataStoreService:GetOrderedDataStore("PlayerWins")
local coinsOrderedStore = DataStoreService:GetOrderedDataStore("PlayerCoins")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local billboardGui = ReplicatedStorage:WaitForChild("CustomNameTag")
local rs = game:GetService("ReplicatedStorage")

local globalStore = DataStoreService:GetDataStore("GlobalShopData")
local stockResetInterval = 5 * 60
local defaultStock = "111111"

local dailyResetInterval = 8 * 60 * 60
local defaultDaily = "0000"

rs.changeLeaderstat.OnServerEvent:Connect(function(player, stat, delta)
	if stat and typeof(delta) == "number" and stat:IsDescendantOf(player) then
		stat.Value += delta
	end
end)

players.PlayerAdded:Connect(function(player)
	
	local leaderstats = Instance.new('Folder')
	leaderstats.Name = 'leaderstats'
	leaderstats.Parent = player

	local Wins = Instance.new('IntValue')
	Wins.Name = 'Wins'
	Wins.Value = 0
	Wins.Parent = leaderstats

	local Coins = Instance.new('IntValue')
	Coins.Name = 'Coins'
	Coins.Value = 0
	Coins.Parent = leaderstats
	
	local Rebirths = Instance.new('IntValue')
	Rebirths.Name = 'Rebirths'
	Rebirths.Value = 0
	Rebirths.Parent = leaderstats
	
	local hidden_leaderstats = Instance.new('Folder')
	hidden_leaderstats.Name = 'hidden_leaderstats'
	hidden_leaderstats.Parent = player
	
	local CurrentKey = Instance.new('StringValue')
	CurrentKey.Name = 'CurrentKey'
	CurrentKey.Value = ''
	CurrentKey.Parent = hidden_leaderstats
	
	local Used = Instance.new('BoolValue')
	Used.Name = 'Used'
	Used.Value = false
	Used.Parent = hidden_leaderstats
	
	local Gears = Instance.new('IntValue')
	Gears.Name = 'Gears'
	Gears.Value = 0
	Gears.Parent = hidden_leaderstats
	
	local perSecond = Instance.new("IntValue")
	perSecond.Name = "PerSecond"
	perSecond.Parent = hidden_leaderstats
	perSecond.Value = 0
	
	local infection = Instance.new("IntValue")
	infection.Name = "Infection"
	infection.Parent = hidden_leaderstats
	infection.Value = 0
	
	local explosion = Instance.new("IntValue")
	explosion.Name = "Explosion"
	explosion.Parent = hidden_leaderstats
	explosion.Value = 0
	
	local trail = Instance.new("IntValue")
	trail.Name = "Trail"
	trail.Parent = hidden_leaderstats
	trail.Value = 0
	
	local Stock = Instance.new("StringValue")
	Stock.Name = "Stock"
	Stock.Parent = hidden_leaderstats
	Stock.Value = "111111"
	
	local NeedsUpdate = Instance.new("BoolValue")
	NeedsUpdate.Name = "NeedsUpdate"
	NeedsUpdate.Parent = hidden_leaderstats
	NeedsUpdate.Value = false
	
	local StockCycle = Instance.new("NumberValue")
	StockCycle.Name = "StockCycle"
	StockCycle.Parent = hidden_leaderstats
	
	local Daily = Instance.new("StringValue")
	Daily.Name = "Daily"
	Daily.Parent = hidden_leaderstats
	Daily.Value = "0000"

	local DailyNeedsUpdate = Instance.new("BoolValue")
	DailyNeedsUpdate.Name = "DailyNeedsUpdate"
	DailyNeedsUpdate.Parent = hidden_leaderstats
	DailyNeedsUpdate.Value = false

	local DailyCycle = Instance.new("NumberValue")
	DailyCycle.Name = "DailyCycle"
	DailyCycle.Parent = hidden_leaderstats
	
	rs.ChangeStock.OnServerEvent:Connect(function(plr, string)
		if player == plr then
			Stock.Value = string
			-- print(string)
		end
	end)
	
	rs.ChangeDaily.OnServerEvent:Connect(function(plr, string)
		if player == plr then
			Daily.Value = string
			-- print(string)
		end
	end)
	
	task.spawn(function()
		while wait() do
			local currentTime = os.time()
			local success, err = pcall(function()
				globalStore:SetAsync("LastShopResetTime", currentTime)
			end)

			if not success then
				warn("Failed to update global shop reset time:", err)
			end

			wait(stockResetInterval)
		end
	end)
	task.spawn(function()
		while wait() do
			local currentTime = os.time()
			local success, err = pcall(function()
				globalStore:SetAsync("LastDailyResetTime", currentTime)
			end)

			if not success then
				warn("Failed to update global daily reset time:", err)
			end

			wait(dailyResetInterval)
		end
	end)
	
	
	
	

	player.CharacterAdded:Connect(function(character)
		local clonedGui = billboardGui:Clone()
		clonedGui.Parent = character:WaitForChild("Head") -- attach to character's head
		clonedGui.StudsOffset = Vector3.new(0, 3, 0) -- offset
		
		local stats = player:WaitForChild("stats")
		
		task.spawn(function()
			local tags = hidden_leaderstats:WaitForChild("Tags")
			local connection
			local connection2
			local connection3

			-- Reusable function to try increasing charge
			local function tryIncreaseCharge(amount)
				local tag_values = character:FindFirstChild("tag_values")
				if not tag_values then return end

				local charge = tag_values:FindFirstChild("charge")
				if charge and typeof(charge.Value) == "number" and charge.Value < 100 then
					charge.Value = math.min(charge.Value + amount, 100)
				end
			end

			-- Connect tag changed listener
			connection = tags.Changed:Connect(function()
				tryIncreaseCharge(math.floor(10 * stats.finish.Value))
			end)
			connection2 = Gears.Changed:Connect(function()
				tryIncreaseCharge(math.floor(10 * stats.finish.Value))
			end)
			local bf = 0
			connection3 = Coins.Changed:Connect(function(v)
				local perSecondV = perSecond.Value * (1 + (0.25 * Rebirths.Value))
				if math.floor(v - bf) ~= math.floor(perSecondV) then
					-- print(v-bf, perSecondV)
					tryIncreaseCharge(math.floor(10 * stats.finish.Value))
				end
				bf = v
			end)

			-- Charging loop
			while character.Parent do
				tryIncreaseCharge(math.floor(1 * stats.finish.Value))
				task.wait(2)
			end

			-- Cleanup connection if character is removed
			if connection then
				connection:Disconnect()
			end
			if connection2 then
				connection2:Disconnect()
			end
			if connection3 then
				connection3:Disconnect()
			end
		end)

		
		task.spawn(function()
			while wait(1) do
				if not perSecond and not Coins then return end

				local glitch_amount = 1_000_000_000_000_000_000_000
				if Coins.Value >= glitch_amount or Coins.Value < 0 then
					Coins.Value = 0
				end
				
				local stats = player:WaitForChild("stats")

				local perSecondV = perSecond.Value * (1 + (0.25 * Rebirths.Value)) * stats.coins.Value

				Coins.Value += perSecondV
				if (not character or not character:FindFirstChild("tag_values")) then
					rs.PlaySecCoin:FireClient(player)
				end
				local has2x = player:GetAttribute("Has2xCash")
				if has2x then
					Coins.Value += perSecondV
				end
			end
		end)
		
		local Steal = Instance.new("ProximityPrompt")
		Steal.Name = "Steal"
		Steal.MaxActivationDistance = 7
		Steal.Enabled = true
		Steal.ActionText = "Steal?"
		Steal.HoldDuration = 5
		Steal.ClickablePrompt = true
		Steal.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		Steal.Style = Enum.ProximityPromptStyle.Custom
		Steal.Parent = character.HumanoidRootPart
		Steal.RequiresLineOfSight = false
		
		Steal.Triggered:Connect(function(stealer)
			if stealer then
				local stealer_leader = stealer:FindFirstChild("leaderstats")

				if stealer_leader and stealer_leader:FindFirstChild("Coins") then
					local stealamount = stats.steal.Value
					
					local percent = math.floor(math.random(1, 30) * stealamount) / 100
					local random_amount = math.floor(Coins.Value * percent)
					
					stealer_leader.Coins.Value += random_amount
					Coins.Value -= random_amount

					rs.stolenNotif:FireClient(player, stealer.Name, random_amount, true)
					rs.stolenNotifSound:FireClient(stealer)

					Steal.Enabled = false
					task.wait(8)
					Steal.Enabled = true
				end
			end
		end)
		
		Steal.PromptButtonHoldBegan:Connect(function(stealer)
			if stealer then
				local stealer_leader = stealer:FindFirstChild("leaderstats")

				if stealer_leader and stealer_leader:FindFirstChild("Coins") then
					rs.stolenNotif:FireClient(player, stealer.Name, nil, false)
				end
			end
		end)
		
		local mainValues = character:WaitForChild("main_values")
		local inGameValue = mainValues:WaitForChild("INGAME")

		local current = not inGameValue.Value

		inGameValue.Changed:Connect(function()
			local newValue = not inGameValue.Value
			Steal.Enabled = newValue

			if newValue then
				local thisRun = tick()
				current = thisRun

				task.spawn(function()
					while tick() - thisRun < 5 do -- optional timeout safety
						if current ~= thisRun or not inGameValue.Value then
							break
						end
						wait(0.05)
						Steal.Enabled = false
					end
				end)
			else
				Steal.Enabled = false
			end
		end)




		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

		humanoid.HealthChanged:Connect(function(health)
			if health <= 0 then
				warn("PLAYER DIED???")
				humanoid.Health = humanoid.MaxHealth
			elseif health <= 99 then
				warn("PLAYER TOOK DAMAGE??????")
			end
		end)

		local nameLabel = clonedGui:FindFirstChild("NameLabel") -- adjust if your label name is different
		if nameLabel then
			nameLabel.RichText = true
			nameLabel.TextScaled = true

			task.spawn(function()
				while wait(0.05) do
					local isVIP = player:GetAttribute("IsVIP")
					local has2x = player:GetAttribute("Has2xCash")
					local wins = Wins.Value

					local prefix = ""

					if has2x then
						prefix = prefix .. "<font color='rgb(0, 170, 255)'>2x </font>"
					end
					if isVIP then
						prefix = prefix .. "<font color='rgb(255, 255, 0)'>VIP </font>"
					end

					nameLabel.Text = prefix .. player.Name .. " | 👑" .. wins
				end
			end)
		end
		
		local perSecondLabel = clonedGui:FindFirstChild("PerSecondLabel")
		if perSecondLabel then
			perSecondLabel.RichText = true
			perSecondLabel.TextScaled = true

			task.spawn(function()
				while true do
					task.wait(.5)

					local prefix = "(💵"
					local suffix = "/s)"
					local amount = 0
					
					-- print(infection.Value, explosion.Value, trail.Value)

					if infection and explosion and trail and perSecond then
						amount = infection.Value + explosion.Value + trail.Value
						perSecond.Value = amount
						perSecondLabel.Text = prefix .. tostring(amount) .. suffix
					end
				end
			end)
		end
	end)

	local Tags = Instance.new('IntValue')
	Tags.Name = 'Tags'
	Tags.Value = 0
	Tags.Parent = hidden_leaderstats

	local Time = Instance.new('IntValue')
	Time.Name = 'Time Survived'
	Time.Value = 0
	Time.Parent = hidden_leaderstats

	local Losses = Instance.new('IntValue')
	Losses.Name = 'Losses'
	Losses.Value = 0
	Losses.Parent = hidden_leaderstats
	
	
	
	local OwnedClaws = Instance.new('StringValue')
	OwnedClaws.Name = 'OwnedClaws'
	OwnedClaws.Value = ""
	OwnedClaws.Parent = hidden_leaderstats
	
	local EquippedClaw = Instance.new('StringValue')
	EquippedClaw.Name = 'EquippedClaw'
	EquippedClaw.Value = ""
	EquippedClaw.Parent = hidden_leaderstats



	local ability_leaderstats = Instance.new('Folder')
	ability_leaderstats.Name = 'ability_leaderstats'
	ability_leaderstats.Parent = player

	local SpeedBoost = Instance.new('IntValue')
	SpeedBoost.Name = 'Speed Boost'
	SpeedBoost.Value = 2
	SpeedBoost.Parent = ability_leaderstats

	local Swap = Instance.new('IntValue')
	Swap.Name = 'Swap'
	Swap.Value = 2
	Swap.Parent = ability_leaderstats

	local Dash = Instance.new('IntValue')
	Dash.Name = 'Dash'
	Dash.Value = 2
	Dash.Parent = ability_leaderstats

	local FreezeAll = Instance.new('IntValue')
	FreezeAll.Name = 'Freeze All'
	FreezeAll.Value = 2
	FreezeAll.Parent = ability_leaderstats

	local Shield = Instance.new('IntValue')
	Shield.Name = 'Shield'
	Shield.Value = 2
	Shield.Parent = ability_leaderstats
	
	
	
	local stats = Instance.new('Folder')
	stats.Name = 'stats'
	stats.Parent = player

	local speed = Instance.new('NumberValue')
	speed.Name = 'speed' -- done
	speed.Value = 1
	speed.Parent = stats
	
	local parrytime = Instance.new('NumberValue')
	parrytime.Name = 'parrytime' -- done
	parrytime.Value = 1
	parrytime.Parent = stats
	
	local range = Instance.new('NumberValue')
	range.Name = 'range' -- done
	range.Value = 1
	range.Parent = stats
	
	local jump = Instance.new('NumberValue')
	jump.Name = 'jump' -- done
	jump.Value = 1
	jump.Parent = stats
	
	local coins = Instance.new('NumberValue')
	coins.Name = 'coins' -- done
	coins.Value = 1
	coins.Parent = stats
	
	local lunge = Instance.new('NumberValue')
	lunge.Name = 'lunge' -- done
	lunge.Value = 1
	lunge.Parent = stats
	
	local acceleration = Instance.new('NumberValue')
	acceleration.Name = 'acceleration' -- done
	acceleration.Value = 1
	acceleration.Parent = stats
	
	local steal = Instance.new('NumberValue')
	steal.Name = 'steal' -- done
	steal.Value = 1
	steal.Parent = stats
	
	local finish = Instance.new('NumberValue')
	finish.Name = 'finish' -- done
	finish.Value = 1
	finish.Parent = stats
	
	
	
	local abilities = Instance.new('StringValue')
	abilities.Name = 'abilities'
	abilities.Value = ""
	abilities.Parent = stats
	
	local cards = Instance.new('StringValue')
	cards.Name = 'cards'
	cards.Value = ""
	cards.Parent = stats
	
	local choosing = Instance.new('BoolValue')
	choosing.Name = 'choosing'
	choosing.Value = false
	choosing.Parent = stats
	
	local req = Instance.new('StringValue')
	req.Name = 'req'
	req.Value = ""
	req.Parent = stats
	
	
	local rewardEvent = game.ReplicatedStorage:WaitForChild("giveQuestReward")

	rewardEvent.OnServerEvent:Connect(function(player, itemName, amount)
		local folders = {
			player:FindFirstChild("leaderstats"),
			player:FindFirstChild("hidden_leaderstats"),
			player:FindFirstChild("ability_leaderstats"),
		}

		for _, folder in ipairs(folders) do
			if folder then
				local stat = folder:FindFirstChild(itemName)
				if stat then
					stat.Value += amount
					break
				end
			end
		end
	end)
	
	rs.Rebirth.OnServerEvent:Connect(function(p)
		local c = p and p.Character
		if stats then
			local cards_value = stats:WaitForChild('cards').Value
			if stats.choosing.Value == false then
				cards_value = nil
			end
			rs.Cards:FireClient(p, cards_value)
		end
		if player == p then
			Rebirths.Value += 1
			
			Coins.Value = 0
			
			SpeedBoost.Value = 2
			Swap.Value = 2
			Dash.Value = 2
			FreezeAll.Value = 2
			Shield.Value = 2
		end
	end)
	

	-- Load saved data from DataStore
	local success, data = pcall(function()
		return statStore:GetAsync(player.UserId)
	end)

	if success and data then
		Wins.Value = data.Wins or 0
		Coins.Value = data.Coins or 0
		Tags.Value = data.Tags or 0
		Time.Value = data["Time Survived"] or 0
		Losses.Value = data.Losses or 0
		SpeedBoost.Value = data["Speed Boost"] or 2
		Swap.Value = data.Swap or 2
		Dash.Value = data.Dash or 2
		FreezeAll.Value = data["Freeze All"] or 2
		Shield.Value = data.Shield or 2
		
		speed.Value = data.speed or 1
		parrytime.Value = data.parrytime or 1
		range.Value = data.range or 1
		jump.Value = data.jump or 1
		coins.Value = data.coins or 1
		lunge.Value = data.lunge or 1
		acceleration.Value = data.acceleration or 1
		steal.Value = data.steal or 1
		finish.Value = data.finish or 1
		
		OwnedClaws.Value = data.OwnedClaws or ""
		EquippedClaw.Value = data.EquippedClaw or ""
		
		abilities.Value = data.abilities or ""
		cards.Value = data.cards or ""
		req.Value = data.req or ""
		choosing.Value = data.choosing or false
		
		infection.Value = data.Infection or 0
		trail.Value = data.Trail or 0
		explosion.Value = data.Explosion or 0
		
		StockCycle.Value = data.StockCycle or 0
		
		DailyCycle.Value = data.DailyCycle or 0
		
		Rebirths.Value = data.Rebirths or 0
		
		Gears.Value = data.Gears or 0
		
		if not data.firstTime then
			player:SetAttribute('firstTime', true)
		end

		local lastPlayerStockTime = data.LastStockResetTime or 0
		local lastPlayerDailyTime = data.LastDailyResetTime or 0
		local now = os.time()

		if now - lastPlayerStockTime > stockResetInterval then
			-- Player missed a reset while offline
			-- print("missed")
			NeedsUpdate.Value = true
			Stock.Value = defaultStock
		else
			Stock.Value = data.Stock or defaultStock
		end
		
		if now - lastPlayerDailyTime > dailyResetInterval then
			-- Player missed a reset while offline
			print("missed")
			DailyNeedsUpdate.Value = true
			Daily.Value = defaultDaily
		else
			Daily.Value = data.Daily or defaultDaily
		end

		

	else
		warn("Could not load data for", player.Name)
	end
	
	local success2, lastTime = pcall(function()
		return timeStore:GetAsync(player.UserId)
	end)
	
	wait(.5)
	if success2 and lastTime then
		local now = os.time()
		local secondsOffline = math.min(now - lastTime, 24 * 60 * 60)

		local totalEarnings = secondsOffline * perSecond.Value
		local gain = math.floor(totalEarnings * 0.10)

		Coins.Value += gain

	end
	
	player.Character.Humanoid.JumpPower = 50 * player:WaitForChild('stats').jump.Value
end)

local max_time = 5 * 60
local FIXED_START = 1751328000
local function getCycleSeed()
	local now = os.time()
	return math.floor((now - FIXED_START) / max_time)
end

players.PlayerRemoving:Connect(function(player)
	local success, err = pcall(function()
		local leaderstats = player.leaderstats
		local hidden_leaderstats = player.hidden_leaderstats
		local ability_leaderstats = player.ability_leaderstats
		local stats = player.stats
		statStore:SetAsync(player.UserId, {
			Wins = leaderstats.Wins.Value,
			Coins = leaderstats.Coins.Value,
			Tags = hidden_leaderstats.Tags.Value,
			["Time Survived"] = hidden_leaderstats["Time Survived"].Value,
			
			Gears = hidden_leaderstats.Gears.Value,
			
			Losses = hidden_leaderstats.Losses.Value,
			["Speed Boost"] =ability_leaderstats["Speed Boost"].Value,
			Swap = ability_leaderstats.Swap.Value,
			Dash = ability_leaderstats.Dash.Value,
			["Freeze All"] = ability_leaderstats["Freeze All"].Value,
			Shield = ability_leaderstats.Shield.Value,
			
			speed = stats.speed.Value,
			parrytime = stats.parrytime.Value,
			range = stats.range.Value,
			jump = stats.jump.Value,
			coins = stats.coins.Value,
			lunge = stats.lunge.Value,
			acceleration = stats.acceleration.Value,
			steal = stats.steal.Value,
			finish = stats.finish.Value,
			
			OwnedClaws = hidden_leaderstats.OwnedClaws.Value,
			EquippedClaw = hidden_leaderstats.EquippedClaw.Value,
			
			abilities = stats.abilities.Value,
			cards = stats.cards.Value,
			choosing = stats.choosing.Value,
			req = stats.req.Value,
			
			Infection = hidden_leaderstats.Infection.Value,
			Trail = hidden_leaderstats.Trail.Value,
			Explosion = hidden_leaderstats.Explosion.Value,
			
			Stock = hidden_leaderstats.Stock.Value,
			LastStockResetTime = os.time(), -- save the time they last synced stock
			
			StockCycle = getCycleSeed(),
			
			Daily = hidden_leaderstats.Daily.Value,
			LastDailyResetTime = os.time(),
			
			DailyCycle = getCycleSeed(),
			
			Rebirths = leaderstats.Rebirths.Value,
			
			firstTime = true

		})

		-- Update the ordered data stores for leaderboard
		pcall(function()
			winsOrderedStore:SetAsync(tostring(player.UserId), player.leaderstats.Wins.Value)
			coinsOrderedStore:SetAsync(tostring(player.UserId), player.leaderstats.Coins.Value)
		end)
	end)

	local success2, err2 = pcall(function()
		timeStore:SetAsync(player.UserId, os.time())
	end)

	if not success2 then
		warn("Failed to save time:", err2)
	end

	if not success then
		warn("Failed to save data for", player.Name, ":", err)
	end
end)

