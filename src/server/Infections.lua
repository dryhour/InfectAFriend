local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local infectionStore = DataStoreService:GetDataStore("PlayerInfections")

local infectionRemote = ReplicatedStorage.remotes:WaitForChild("InfectionStatusChange")
local updateInfection = ReplicatedStorage:WaitForChild("updateInfection")
local updateDailyInfection = ReplicatedStorage:WaitForChild("updateDailyInfection")

local InfectionStore = {}
InfectionStore.cache = {}

local DEFAULT_COLOR = "0,255,0"

local function sanitizeColorString(color)
	if typeof(color) == "Color3" then
		return string.format("%d,%d,%d", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
	elseif typeof(color) == "ColorSequence" then
		local c = color.Keypoints[1].Value
		return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	elseif typeof(color) == "string" and color:match("^%d+,%d+,%d+$") then
		return color
	end
	return DEFAULT_COLOR
end

function InfectionStore:Load(player, reset)
	local key = "infections_" .. player.UserId
	local success, data = pcall(function()
		return infectionStore:GetAsync(key)
	end)

	local rawOwned = (success and data and data.Owned) or {}
	local rawEquipped = (success and data and data.Equipped) or DEFAULT_COLOR

	local owned = {}

	for k, v in pairs(rawOwned) do
		if v then
			local cleanKey = sanitizeColorString(k)
			owned[cleanKey] = true
		end
	end

	local equipped = sanitizeColorString(rawEquipped)

	if not owned[DEFAULT_COLOR] then
		owned[DEFAULT_COLOR] = true
	end

	if equipped == "" then
		equipped = DEFAULT_COLOR
	end

	self.cache[player.UserId] = {Owned = owned, Equipped = equipped}

	local r, g, b = unpack(string.split(equipped, ","))
	local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))

	updateInfection:FireClient(player, owned, color, reset)
	updateDailyInfection:FireClient(player, owned, color)

	local val = player:FindFirstChild("EquippedInfectionColor")
	if not val then
		val = Instance.new("StringValue")
		val.Name = "EquippedInfectionColor"
		val.Parent = player
	end
	val.Value = equipped
end

function InfectionStore:Save(player)
	local data = self.cache[player.UserId]
	if data then
		local key = "infections_" .. player.UserId
		local sanitizedOwned = {}
		for colorStr, v in pairs(data.Owned or {}) do
			if v then
				sanitizedOwned[sanitizeColorString(colorStr)] = true
			end
		end
		local sanitizedEquipped = sanitizeColorString(data.Equipped)
		pcall(function()
			infectionStore:SetAsync(key, {
				Owned = sanitizedOwned,
				Equipped = sanitizedEquipped
			})
		end)
	end
end

function InfectionStore:Grant(player, colorString)
	local data = self.cache[player.UserId]
	if data then
		local clean = sanitizeColorString(colorString)
		data.Owned[clean] = true
		self:Save(player)
	end
end

function InfectionStore:Equip(player, colorString)
	local data = self.cache[player.UserId]
	if data then
		local clean = sanitizeColorString(colorString)
		if data.Owned[clean] then
			data.Equipped = clean

			local val = player:FindFirstChild("EquippedInfectionColor")
			if val then
				val.Value = clean
			end

			local r, g, b = unpack(string.split(clean, ","))
			local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
			updateInfection:FireClient(player, data.Owned, color)
			self:Save(player)
		end
	end
end

function InfectionStore:Remove(player)
	self.cache[player.UserId] = nil
end

local remote = ReplicatedStorage.RebirthInf

function InfectionStore:Reset(player)
	local key = "infections_" .. player.UserId

	pcall(function()
		infectionStore:RemoveAsync(key)
	end)

	self.cache[player.UserId] = nil

	self:Load(player, true)
end

remote.OnServerEvent:Connect(function(player)
	InfectionStore:Reset(player)
end)

local giveReward = ReplicatedStorage:WaitForChild("giveInfectionReward")
giveReward.OnServerEvent:Connect(function(plr, colorString)
	local leaderstats = plr:FindFirstChild("leaderstats")
	if not (leaderstats and leaderstats:FindFirstChild("Coins")) then return end

	if string.find(colorString, ",") then
		InfectionStore:Grant(plr, colorString)
		print("granted!")
		local owned = InfectionStore.cache[plr.UserId] and InfectionStore.cache[plr.UserId].Owned or {}
		local r, g, b = unpack(string.split(colorString, ","))
		local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
		
		InfectionStore:Equip(plr, colorString)
		updateInfection:FireClient(plr, owned, color)
		updateDailyInfection:FireClient(plr, owned, color)
	else
		local amount = tonumber(string.match(colorString, "%d+"))
		if amount then
			leaderstats.Coins.Value += amount
			if plr:GetAttribute("Has2xCash") then
				leaderstats.Coins.Value += amount
			end
		end
	end
end)

infectionRemote.OnServerEvent:Connect(function(player, colorString, status)
	if status == "EQUIPPED" then
		InfectionStore:Equip(player, colorString)
	end
end)

Players.PlayerAdded:Connect(function(p)
	InfectionStore:Load(p)
end)

Players.PlayerRemoving:Connect(function(p)
	InfectionStore:Save(p)
	InfectionStore:Remove(p)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		InfectionStore:Save(p)
	end
end)

return InfectionStore