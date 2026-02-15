local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local purchaseSuccessRemote = ReplicatedStorage:WaitForChild("CashPurchaseSuccess")

local productRewards = {
	[3311084938] = 500,
	[3311085203] = 1000,
	[3311086029] = 5000,
	[3311086411] = 10000,
	[3311086741] = 25000,
	[3311383483] = 5000,
}

local CrateData = {
	Mythical = { Price = 20, CoinChance = 0.2, ID = 3313800359 },
	Divine = { Price = 25, CoinChance = 0.1, ID = 3313800657 },
}

local AbilityData = {
	SlipAll = { ID = 3314674788 },
	Explode = { ID = 3314675369 }
}

ReplicatedStorage.setFalse.OnServerEvent:Connect(function(player, crateAttr)
	player:SetAttribute(crateAttr, false)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	--print("ProcessReceipt called")
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		--print("No player found")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	--print("Player found:", player.Name)
	
	local SWITCH_TAGGER_PRODUCT_ID = 3313761605
	if receiptInfo.ProductId == SWITCH_TAGGER_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	local SKIP_DAY = 3315499148
	if receiptInfo.ProductId == SKIP_DAY then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Check for crate purchase (sets HasPurchased attribute)
	for crateName, crate in pairs(CrateData) do
		if crate.ID == receiptInfo.ProductId then
			--print("Crate purchase detected:", crateName)
			player:SetAttribute("HasPurchased_" .. crateName, true)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	
	for abilityName, ability in pairs(AbilityData) do
		if ability.ID == receiptInfo.ProductId then
			if ability.ID == 3314675369 then
				local eU = Instance.new('Folder')
				eU.Name = 'ExplosionUsed'
				eU.Parent = workspace
			end
			--print("Crate purchase detected:", crateName)
			player:SetAttribute("HasPurchased_" .. abilityName, true)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- Check for coin rewards purchase
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Coins") then
		--print("No leaderstats or Coins found")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local reward = productRewards[receiptInfo.ProductId]
	if reward then
		--print("Coin reward detected:", reward)
		leaderstats.Coins.Value += reward

		-- Notify client of purchase success (play sound, UI update, etc)
		pcall(function()
			purchaseSuccessRemote:FireClient(player)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	--print("No matching product found")
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
