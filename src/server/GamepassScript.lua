local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- Gamepass IDs
local GAMEPASSES = {
	["2x Cash"] = 1265286543,
	["VIP"] = 1265332324,
	["Starter Pack"] = 1268302427,
	["Premium Pack"] = 1268888426,
}

-- VIP reward settings
local VIP_REWARD_COINS = 10000
local VIP_REWARD_STORE = DataStoreService:GetDataStore("VIPRewardClaimed")

local STARTER_REWARD_COINS = 3000
local STARTER_REWARD_ABILITIES = 2
local STARTER_REWARD_STORE = DataStoreService:GetDataStore("StarterRewardClaimed")

local PREMIUM_REWARD_COINS = 5000
local PREMIUN_REWARD_ABILITIES = 4
local PREMIUM_REWARD_STORE = DataStoreService:GetDataStore("PremiumRewardClaimed")

-- RemoteEvent for client GUI prompt (optional)
local gamepassRewardRemote = Instance.new("RemoteEvent")
gamepassRewardRemote.Name = "GamepassReward"
gamepassRewardRemote.Parent = ReplicatedStorage

-- Give coins helper
local function giveCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value += amount
		end
	end
end

local function giveAbilities(player, amount)
	local leaderstats = player:FindFirstChild("ability_leaderstats")
	if leaderstats then
		local a = leaderstats:FindFirstChild("Speed Boost")
		if a then
			a.Value += amount
		end
		
		local a = leaderstats:FindFirstChild("Swap")
		if a then
			a.Value += amount
		end
		
		local a = leaderstats:FindFirstChild("Dash")
		if a then
			a.Value += amount
		end
		
		local a = leaderstats:FindFirstChild("Freeze All")
		if a then
			a.Value += amount
		end
		
		local a = leaderstats:FindFirstChild("Shield")
		if a then
			a.Value += amount
		end
	end
end

-- Apply gamepass effects and reward logic
local function applyGamepassReward(player, gamepassId)
	if gamepassId == GAMEPASSES["2x Cash"] then
		player:SetAttribute("Has2xCash", true)

	elseif gamepassId == GAMEPASSES["VIP"] then
		player:SetAttribute("IsVIP", true)

		local key = "vip_" .. player.UserId
		local claimed = false

		local success, result = pcall(function()
			return VIP_REWARD_STORE:GetAsync(key)
		end)

		if success and result == true then
			claimed = true
		end

		if not claimed then
			giveCoins(player, VIP_REWARD_COINS)
			local purchaseSuccessRemote = ReplicatedStorage:WaitForChild("CashPurchaseSuccess")
			purchaseSuccessRemote:FireClient(player)
			pcall(function()
				VIP_REWARD_STORE:SetAsync(key, true)
			end)
		end
	elseif gamepassId == GAMEPASSES["Starter Pack"] then
		local key = "sp_" .. player.UserId
		local claimed = false

		local success, result = pcall(function()
			return STARTER_REWARD_STORE:GetAsync(key)
		end)

		if success and result == true then
			claimed = true
		end

		if not claimed then
			giveCoins(player, STARTER_REWARD_COINS)
			giveAbilities(player, STARTER_REWARD_ABILITIES)
			local purchaseSuccessRemote = ReplicatedStorage:WaitForChild("CashPurchaseSuccess")
			purchaseSuccessRemote:FireClient(player)
			pcall(function()
				STARTER_REWARD_STORE:SetAsync(key, true)
			end)
		end
	elseif gamepassId == GAMEPASSES["Premium Pack"] then
		local key = "sp_" .. player.UserId
		local claimed = false

		local success, result = pcall(function()
			return PREMIUM_REWARD_STORE:GetAsync(key)
		end)

		if success and result == true then
			claimed = true
		end

		if not claimed then
			giveCoins(player, PREMIUM_REWARD_COINS)
			giveAbilities(player, PREMIUN_REWARD_ABILITIES)
			local purchaseSuccessRemote = ReplicatedStorage:WaitForChild("CashPurchaseSuccess")
			purchaseSuccessRemote:FireClient(player)
			pcall(function()
				PREMIUM_REWARD_STORE:SetAsync(key, true)
			end)
		end
	end
end

-- Handle post-purchase gamepass
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if wasPurchased then
		applyGamepassReward(player, gamepassId)
	end
end)

-- Handle player join: check previously owned passes
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Has2xCash", false)
	player:SetAttribute("IsVIP", false)

	player:WaitForChild("leaderstats") -- Wait for Coins

	-- Delay to ensure ownership check works
	task.delay(2, function()
		for _, id in pairs(GAMEPASSES) do
			local owns = false
			pcall(function()
				owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if owns then
				applyGamepassReward(player, id)
			end
		end
	end)
end)
