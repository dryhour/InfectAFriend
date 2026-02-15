--// Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--// Remote Setup
local explosionsFolder = ReplicatedStorage:WaitForChild("explosions")
local SpinEvent = Instance.new("RemoteFunction")
SpinEvent.Name = "SpinEvent"
SpinEvent.Parent = ReplicatedStorage

--// DataStore
local spinDataStore = DataStoreService:GetDataStore("PlayerSpinRewards")

--// Config
local COOLDOWN_TIME = 1
local lastSpin = {}

--// Crate Configuration
local CrateData = {
	Common = { Price = 500, CoinChance = 0.5, 
		Possible = {"Retro", "Blue", "Lightning", "Void", "Red"},
		Claws = {"bone", "gla", "gol", "dia", "dem", "ele"}
	},
	Uncommon = { Price = 1000, CoinChance = 0.4, 
		Possible = {"Blue", "Lightning", "Void", "Red", "Magic"},
		Claws = {"glt", "cla", "clo", "dar", "glo", "mag", "fir"}
	},
	Rare = { Price = 5000, CoinChance = 0.3, 
		Possible = {"Lightning", "Void", "Red",  "Magic"},
		Claws = {"con", "wol", "bea", "man", "hma"}
	},
	["Super Rare"] = { Price = 20000, CoinChance = 0.5, 
		Possible = {"Void", "Red", "Magic"},
		Claws = {"neo", "cut", "kit", "pca", "coo", "fcc", "flc"}
	},
	Legendary = { Price = 50000, CoinChance = 0.4, Possible = {"Red", "Magic", "Trickster"} },
	Rainbow = { Price = 100000, CoinChance = 0.3, Possible = {"Magic", "Trickster", "Earthquake"} },
	Mythical = { Price = 1000000, CoinChance = 0.15, ID = 3313800359 }, -- Robux product
	Divine = { Price = 100000000, CoinChance = 0.05, ID = 3313800657 },  -- Robux product
}

local function exponentialDivide(number, amount)
	local result = {}
	local current = number

	for i = 1, amount - 1 do
		table.insert(result, math.floor(current))
		current = current / 2
	end

	-- Ensure the last value is always 1
	table.insert(result, 1)

	return result
end


--// Reward Logic
local function generateSpinResult(crateInfo, player)
	local crateName = crateInfo.Name
	local crate = CrateData[crateName]
	if not crate then return nil end

	local items = {}
	local test = {}
	
	local function setItems()
		if crate.Claws then
			local claws = exponentialDivide(8, #crate.Claws)
			for count = 1, #crate.Claws do
				for num = 1, claws[count] do
					table.insert(test, crate.Claws[count])
					local name = crate.Claws[count]
					local claw =  ReplicatedStorage.Claws:FindFirstChild(name)
					local dname = claw:GetAttribute("DisplayName")
					local color = claw.claws.BrickColor.Name
					table.insert(items, { Type = "Claw", Name = name, DisplayName = dname, color3 = color })
				end
			end
		end
		if crate.Possible then
			local possibles = exponentialDivide(15, #crate.Possible)
			for count = 1, #crate.Possible do
				for num = 1, possibles[count] do
					table.insert(test, crate.Possible[count])
					table.insert(items, { Type = "Explosion", Name = crate.Possible[count] })
				end
			end
		else
			for _, folder in ipairs(explosionsFolder:GetChildren()) do
				if 
					folder:IsA("Folder") 
					and folder.Name ~= "VIP" 
					and folder.Name ~= "Default" 
					and folder.Name ~= "RAINBOW" 
				then
					table.insert(items, { Type = "Explosion", Name = folder.Name })
					table.insert(items, { Type = "Explosion", Name = folder.Name })
				end
			end
		end
	end
	
	setItems()

	-- Add coin filler items
	local fillerCount = math.floor(30 * crate.CoinChance)
	for _ = 1, fillerCount do
		local amount = math.random(15, math.floor(crate.Price * 0.8))
		table.insert(items, { Type = "Coins", Amount = amount })
	end
	
	local abilitiesCount = math.floor(20 * crate.CoinChance)
	for _ = 1, abilitiesCount do
		local amount = math.random(1, 3)
		local ability_type = math.random(1, 6)

		local ability
		if ability_type == 1 then
			ability = "Freeze All"
		elseif ability_type == 2 or ability_type == 3 then
			ability = "Swap"
		else
			ability = "Shield"
		end

		table.insert(items, { Type = ability, Amount = amount })
	end


	-- Shuffle items
	-- Seed the RNG once globally (do this early in your script)
	math.randomseed(os.time() + math.random(1, 1000000))

	-- Fisher-Yates Shuffle
	for i = #items, 2, -1 do
		local j = math.random(1, i)
		items[i], items[j] = items[j], items[i]
	end


	-- Pick final winner
	local winnerIndex = math.random(math.ceil(#items / 5), #items)
	local result = items[winnerIndex]

	-- Save to DataStore
	local key = "Player_" .. player.UserId
	pcall(function()
		local saved = spinDataStore:GetAsync(key) or {}
		table.insert(saved, result)
		spinDataStore:SetAsync(key, saved)
	end)

	return {
		Items = items,
		WinnerIndex = winnerIndex
	}
end

--// RemoteFunction Handler
SpinEvent.OnServerInvoke = function(player, crateInfo)
	if not crateInfo or not crateInfo.Name or not crateInfo.Price then return nil end

	local crate = CrateData[crateInfo.Name]
	if not crate then return nil end

	if lastSpin[player] and tick() - lastSpin[player] < COOLDOWN_TIME then
		return nil
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end

	-- Robux crate
	if crate.ID then
		if not player:GetAttribute("HasPurchased_" .. crateInfo.Name) then
			return nil -- must buy first
		end
	else
		-- Coin crate
		local coins = leaderstats:FindFirstChild("Coins")
		if not coins or coins.Value < crateInfo.Price then return nil end
		coins.Value -= crateInfo.Price
	end

	lastSpin[player] = tick()
	return generateSpinResult(crateInfo, player)
end


