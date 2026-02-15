local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local finisherStore = DataStoreService:GetDataStore("PlayerFinishers")
local finisherRemote = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("FinisherStatusChange")
local giveReward = ReplicatedStorage:WaitForChild("giveFinisher")
local updateRemote = ReplicatedStorage:WaitForChild("updateFinisher")

local craftTimes = {
	Permafrost = 4 * 60,
	Void = 5 * 60,
	Volcano = 6 * 60,
	Meteor = 15 * 60,
	Darkness = 25 * 60,
	Disco = 30 * 60,
}
local craftPrices = {
	Permafrost = 10,
	Void = 15,
	Volcano = 17,
	Meteor = 20,
	Darkness = 25,
	Disco = 30,
}

local FinisherStore = {}
FinisherStore.cache = {} -- [UserId] = { Owned = {}, Equipped = "", Crafting = {} }

function FinisherStore:Load(player, reset)
	local key = "finishers_" .. player.UserId
	local success, data = pcall(function()
		return finisherStore:GetAsync(key)
	end)

	local owned = (success and data and data.Owned) or {}
	local equipped = (success and data and data.Equipped) or ""
	local crafting = (success and data and data.Crafting) or {}

	-- Ensure player starts with Default
	if not owned["Default"] then
		owned["Default"] = true
	end
	if equipped == "" then
		equipped = "Default"
	end

	-- Auto-complete any finished craftings
	local currentTime = os.time()
	for finisherName, startTime in pairs(crafting) do
		local duration = craftTimes[finisherName]
		if duration and currentTime - startTime >= duration then
			owned[finisherName] = true
			crafting[finisherName] = nil
		end
	end

	self.cache[player.UserId] = {
		Owned = owned,
		Equipped = equipped,
		Crafting = crafting,
	}

	-- Update EquippedFinisherName
	local val = player:FindFirstChild("EquippedFinisherName")
	if not val then
		val = Instance.new("StringValue")
		val.Name = "EquippedFinisherName"
		val.Parent = player
	end
	val.Value = equipped

	updateRemote:FireClient(player, owned, equipped, reset, self.cache[player.UserId].Crafting)
end

function FinisherStore:Save(player)
	local data = self.cache[player.UserId]
	if data then
		local key = "finishers_" .. player.UserId
		pcall(function()
			finisherStore:SetAsync(key, {
				Owned = data.Owned,
				Equipped = data.Equipped,
				Crafting = data.Crafting,
			})
		end)
	end
end

function FinisherStore:Grant(player, name)
	local data = self.cache[player.UserId]
	if data then
		data.Owned[name] = true
		if data.Crafting[name] then
			data.Crafting[name] = nil
		end
	end
	self:Save(player)
	self:Load(player) -- reload to reflect immediately
end

function FinisherStore:Equip(player, name)
	local data = self.cache[player.UserId]
	if data then
		data.Owned[name] = true
		data.Equipped = name

		local val = player:FindFirstChild("EquippedFinisherName")
		if val then
			val.Value = name
		end
	end
end

function FinisherStore:StartCraft(player, name, clientPrice)
	local data = self.cache[player.UserId]
	local duration = craftTimes[name]
	local price = craftPrices[name]

	if not (data and duration and price) then return end
	if data.Owned[name] or data.Crafting[name] then return end

	local gears = player:FindFirstChild("hidden_leaderstats") and player.hidden_leaderstats:FindFirstChild("Gears")
	if not gears or gears.Value < price then return end


	-- Deduct and begin crafting
	gears.Value -= price
	data.Crafting[name] = os.time()
	self:Save(player)
end



function FinisherStore:CompleteCraft(player, name)
	local data = self.cache[player.UserId]
	if data and data.Crafting[name] then
		local startTime = data.Crafting[name]
		local duration = craftTimes[name]
		if startTime and duration and (os.time() - startTime >= duration) then
			data.Crafting[name] = nil
			data.Owned[name] = true
			self:Save(player)
			self:Load(player)
		end
	end
end

function FinisherStore:Remove(player)
	self.cache[player.UserId] = nil
end

-- Reward given manually
giveReward.OnServerEvent:Connect(function(plr, name)
	if name then
		FinisherStore:Grant(plr, name)
	end
end)

-- Finisher status handler (Equip or Craft)
finisherRemote.OnServerEvent:Connect(function(player, action, nameOrPrice)
	if action == "Equip" then
		FinisherStore:Equip(player, nameOrPrice)
	elseif action == "StartCraft" then
		FinisherStore:StartCraft(player, nameOrPrice)
	elseif action == "CraftComplete" then
		FinisherStore:CompleteCraft(player, nameOrPrice)
	end
end)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	FinisherStore:Load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	FinisherStore:Save(player)
	FinisherStore:Remove(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		FinisherStore:Save(player)
	end
end)

return FinisherStore
