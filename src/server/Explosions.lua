local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local explosionStore = DataStoreService:GetDataStore("PlayerExplosions")

local explosionRemote = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("ExplosionStatusChange")
local giveReward = ReplicatedStorage:WaitForChild("giveReward")

local ExplosionStore = {}
ExplosionStore.cache = {} -- [UserId] -> { Owned = {}, Equipped = "..." }

function ExplosionStore:Load(player, reset)
	local key = "explosions_" .. player.UserId
	local success, data = pcall(function()
		return explosionStore:GetAsync(key)
	end)

	local owned = (success and data and data.Owned) or {}
	local equipped = (success and data and data.Equipped) or ""
	
	if not owned["Default"] then
		owned["Default"] = true
	end

	if equipped == "" then
		equipped = "Default"
	end

	self.cache[player.UserId] = {Owned = owned, Equipped = equipped}
	
	ReplicatedStorage.updateExplosion:FireClient(player, owned, equipped, reset)

	local val = player:FindFirstChild("EquippedExplosionName")
	if not val then
		val = Instance.new("StringValue")
		val.Name = "EquippedExplosionName"
		val.Parent = player
	end
	val.Value = equipped
end

function ExplosionStore:Save(player)
	local data = self.cache[player.UserId]
	if data then
		local key = "explosions_" .. player.UserId
		pcall(function()
			explosionStore:SetAsync(key, {
				Owned = data.Owned,
				Equipped = data.Equipped
			})
		end)
	end
end

function ExplosionStore:Grant(player, name)
	local data = self.cache[player.UserId]
	if data then
		data.Owned[name] = true
	end
	ExplosionStore:Save(player)
	ExplosionStore:Load(player)
	-- ReplicatedStorage.updateExplosion:FireClient(player, name)
end

function ExplosionStore:Equip(player, name)
	local data = self.cache[player.UserId]
	if data then
		data.Owned[name] = true -- auto-own when equipped
		data.Equipped = name

		local val = player:FindFirstChild("EquippedExplosionName")
		if val then
			val.Value = name
		end
	end
end

function ExplosionStore:Remove(player)
	self.cache[player.UserId] = nil
end

local remote = ReplicatedStorage.RebirthExp

function ExplosionStore:Reset(player)
	local key = "explosions_" .. player.UserId

	pcall(function()
		explosionStore:RemoveAsync(key)
	end)

	self.cache[player.UserId] = nil
	self:Load(player, true)
end


remote.OnServerEvent:Connect(function(player)
	ExplosionStore:Reset(player)
end)

-- Handle reward (Coins or Explosion)
giveReward.OnServerEvent:Connect(function(plr, name, ability)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if ability then
		local ability_leaderstats = plr:FindFirstChild("ability_leaderstats")
		local string = string.match(name, "%d+")
		ability_leaderstats[ability].Value += tonumber(string)
	elseif leaderstats and leaderstats:FindFirstChild("Coins") then
		local number_str = string.match(name, "%d+")
		if number_str and tonumber(number_str) then
			local amount = tonumber(number_str)
			leaderstats.Coins.Value += amount
			if plr:GetAttribute("Has2xCash") then
				leaderstats.Coins.Value += amount
			end
		else
			ExplosionStore:Grant(plr, name)
			-- ReplicatedStorage.updateExplosion:FireClient(plr, name)
		end
	end
end)

-- Handle equip request
explosionRemote.OnServerEvent:Connect(function(player, explosionName, status)
	if status == "EQUIPPED" then
		ExplosionStore:Equip(player, explosionName)
	end
end)

-- Load/save on player join/leave
Players.PlayerAdded:Connect(function(p)
	ExplosionStore:Load(p)
end)

Players.PlayerRemoving:Connect(function(p)
	ExplosionStore:Save(p)
	ExplosionStore:Remove(p)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		ExplosionStore:Save(p)
	end
end)

return ExplosionStore
