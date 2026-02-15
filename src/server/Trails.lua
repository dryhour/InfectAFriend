local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage.remotes:WaitForChild("TrailPurchaseEquip")
local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthTra")

local syncRemote = Instance.new("RemoteFunction")
syncRemote.Name = "SyncTrailStatus"
syncRemote.Parent = ReplicatedStorage.remotes

local trailStore = DataStoreService:GetDataStore("PlayerTrails")
local playerData = {} -- [player] = { Owned = {}, EquippedName = string, EquippedColorData = table }

-- Helper: Convert ColorSequence to table
local function serializeColorSequence(cs)
	local data = {}
	for _, keypoint in ipairs(cs.Keypoints) do
		table.insert(data, {
			Time = keypoint.Time,
			R = keypoint.Value.R,
			G = keypoint.Value.G,
			B = keypoint.Value.B
		})
	end
	return data
end

-- Helper: Convert table back to ColorSequence
local function deserializeColorSequence(data)
	local keypoints = {}
	for _, point in ipairs(data) do
		table.insert(keypoints, ColorSequenceKeypoint.new(
			point.Time,
			Color3.new(point.R, point.G, point.B)
			))
	end
	return ColorSequence.new(keypoints)
end

-- Trail cleanup
local function clearTrails(char)
	for _, t in pairs(char:GetChildren()) do
		if t:IsA("Trail") and t.Name == "EquippedTrail" then
			t:Destroy()
		end
	end
end

-- Trail creation
local function applyTrail(player, trailColor)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local head = char:WaitForChild("Head")

	clearTrails(char)

	local att0 = Instance.new("Attachment", head)
	local att1 = Instance.new("Attachment", hrp)

	local trail = Instance.new("Trail")
	trail.Name = "EquippedTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.5
	trail.WidthScale = NumberSequence.new(1)
	trail.Color = trailColor
	trail.Parent = char
end

-- Data load
local function loadData(player)
	local key = "user_" .. player.UserId
	local success, data = pcall(function()
		return trailStore:GetAsync(key)
	end)

	local Owned = {}
	local EquippedName = nil
	local EquippedColorData = nil

	if success and type(data) == "table" then
		Owned = data.Owned or {}
		EquippedName = data.EquippedName
		EquippedColorData = data.EquippedColorData
	end

	playerData[player] = {
		Owned = Owned,
		EquippedName = EquippedName,
		EquippedColorData = EquippedColorData
	}
end

-- Data save
local function saveData(player)
	local data = playerData[player]
	if data then
		local key = "user_" .. player.UserId
		pcall(function()
			trailStore:SetAsync(key, {
				Owned = data.Owned,
				EquippedName = data.EquippedName,
				EquippedColorData = data.EquippedColorData
			})
		end)
	end
end

-- Trail rebirth reset
local function resetTrail(player)
	local key = "user_" .. player.UserId

	pcall(function()
		trailStore:RemoveAsync(key)
	end)

	playerData[player] = nil
	saveData(player)
	loadData(player)

	-- Optionally remove trail visual
	local char = player.Character
	if char then clearTrails(char) end
end

rebirthRemote.OnServerEvent:Connect(function(player)
	resetTrail(player)
end)

-- Handle equip/purchase
remote.OnServerEvent:Connect(function(player, trailColor, cost, name)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins then return end

	local data = playerData[player]
	if not data then return end

	local owned = data.Owned

	-- Buy if not owned
	if not owned[name] then
		if coins.Value >= cost then
			coins.Value -= cost
			owned[name] = true
		else
			return -- can't afford
		end
	end

	-- Equip trail
	data.EquippedName = name
	data.EquippedColorData = serializeColorSequence(trailColor)
	applyTrail(player, trailColor)
	saveData(player)
end)

-- Sync remote
syncRemote.OnServerInvoke = function(player)
	local data = playerData[player]
	if data then
		return {
			Owned = data.Owned,
			EquippedName = data.EquippedName
		}
	end
	return {
		Owned = {},
		EquippedName = nil
	}
end

-- Player added
Players.PlayerAdded:Connect(function(player)
	loadData(player)
	task.wait(1)
	local data = playerData[player]
	if data and data.EquippedColorData then
		local cs = deserializeColorSequence(data.EquippedColorData)
		applyTrail(player, cs)
	end
end)

-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	playerData[player] = nil
end)
