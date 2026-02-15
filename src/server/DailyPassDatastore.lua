local DSS = game:GetService("DataStoreService")
local dailyStore = DSS:GetDataStore("DailyPassData")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure remotes folder exists
if not ReplicatedStorage:FindFirstChild("remotes") then
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local validateDailyClaim = Instance.new("RemoteFunction")
validateDailyClaim.Name = "validateDailyClaim"
validateDailyClaim.Parent = ReplicatedStorage

local skipClaim = Instance.new("RemoteFunction")
skipClaim.Name = "skipClaim"
skipClaim.Parent = ReplicatedStorage.remotes

-- Converts Color3 or string to "r,g,b"
local function color3ToRGBString255(color)
	if typeof(color) == "string" then
		if color:match("^%d+,%d+,%d+$") then
			return color
		end
		return "0,255,0"
	end
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return r .. "," .. g .. "," .. b
end

-- Infection color cache
local DataStoreService = game:GetService("DataStoreService")
local infectionStore = DataStoreService:GetDataStore("PlayerInfections")

local InfectionStore = {
	cache = {}
}

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

function InfectionStore:Load(player)
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
end

-- Uses cache only
local function getOwnedColors(player)
	InfectionStore:Load(player)
	local owned = {}
	local data = InfectionStore.cache[player.UserId]
	if data and data.Owned then
		owned = data.Owned
	end
	return owned
end

-- Reads all defined possible color strings from UIGradient in StarterGui
local function getAllPossibleColors()
	local colors = {}
	local gui = game.StarterGui.MainUI.CustomOpenFrame.Infections.Infections:GetChildren()

	for _, tb in pairs(gui) do
		if tb:IsA("TextButton") then
			local gradient = tb:FindFirstChild("UIGradient")
			if gradient then
				local colorStr = color3ToRGBString255(gradient.Color.Keypoints[1].Value)
				colors[colorStr] = true
			end
		end
	end

	return colors
end

-- Guarantees no duplicate coin reward values
local function generateUniqueMoneyAmount(usedAmounts, minAmount, maxAmount)
	local amount
	repeat
		amount = math.random(minAmount, maxAmount)
	until not usedAmounts[amount]
	usedAmounts[amount] = true
	return amount
end

-- Generates 5-day reward string
local function generateRewardList(player)
	local maxDays = 5
	local rewards = {}
	local usedMoneyAmounts = {}
	local usedColors = {}

	local ownedColors = getOwnedColors(player)
	local possibleColors = getAllPossibleColors()

	local unownedColors = {}
	for colorStr in pairs(possibleColors) do
		if not ownedColors[colorStr] then
			table.insert(unownedColors, colorStr)
		end
	end

	-- Shuffle unowned colors
	for i = #unownedColors, 2, -1 do
		local j = math.random(1, i)
		unownedColors[i], unownedColors[j] = unownedColors[j], unownedColors[i]
	end

	local colorIndex = 1

	for day = 1, maxDays do
		if day == 2 or day == 4 then
			local amount = generateUniqueMoneyAmount(usedMoneyAmounts, 500, 25000)
			table.insert(rewards, "+" .. amount)
		else
			if colorIndex <= #unownedColors then
				local colorStr = unownedColors[colorIndex]
				if ownedColors[colorStr] then
					local amount = generateUniqueMoneyAmount(usedMoneyAmounts, 20, 2500)
					table.insert(rewards, "+" .. amount)
				else
					table.insert(rewards, colorStr)
					usedColors[colorStr] = true
					colorIndex += 1
				end
			else
				local amount = generateUniqueMoneyAmount(usedMoneyAmounts, 1000, 50000)
				table.insert(rewards, "+" .. amount)
			end
		end
	end

	return table.concat(rewards, "|")
end

local function getClaimedList(claimedDaysValue)
	local claimed = {}
	if claimedDaysValue == "" then return claimed end
	for entry in string.gmatch(claimedDaysValue, "[^,]+") do
		local num = tonumber(entry)
		if num then table.insert(claimed, num) end
	end
	return claimed
end

local function savePlayerData(player)
	local dataFolder = player:FindFirstChild("DailyPassData")
	if dataFolder then
		local key = "dailypass_" .. player.UserId
		pcall(function()
			dailyStore:SetAsync(key, {
				claimed = dataFolder.ClaimedDays.Value,
				rewards = dataFolder.RewardList.Value,
				lastClaimTime = dataFolder.LastClaimTime.Value,
				currentCycle = dataFolder.CurrentCycle.Value
			})
		end)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	local key = "dailypass_" .. player.UserId
	local success, data = pcall(function()
		return dailyStore:GetAsync(key)
	end)

	local folder = Instance.new("Folder")
	folder.Name = "DailyPassData"
	folder.Parent = player

	local claimedDays = Instance.new("StringValue")
	claimedDays.Name = "ClaimedDays"
	claimedDays.Value = (success and data and data.claimed) or ""
	claimedDays.Parent = folder

	local rewardList = Instance.new("StringValue")
	rewardList.Name = "RewardList"
	rewardList.Parent = folder

	local lastClaimTime = Instance.new("NumberValue")
	lastClaimTime.Name = "LastClaimTime"
	lastClaimTime.Value = (success and data and data.lastClaimTime) or 0
	lastClaimTime.Parent = folder

	local currentCycle = Instance.new("NumberValue")
	currentCycle.Name = "CurrentCycle"
	currentCycle.Value = (success and data and data.currentCycle) or os.time()
	currentCycle.Parent = folder

	-- Example mock: populate InfectionStore cache (replace with your actual save system)
	InfectionStore.cache[player.UserId] = {
		Owned = {
			["255,0,0"] = true, -- Red
			["0,255,0"] = true  -- Green
		},
		Equipped = "255,0,0"
	}

	local claimed = getClaimedList(claimedDays.Value)
	if #claimed >= 5 or not (success and data and data.rewards) then
		claimedDays.Value = ""
		currentCycle.Value = os.time()
		rewardList.Value = generateRewardList(player)
	elseif data.rewards then
		local count = 0
		for _ in string.gmatch(data.rewards, "[^|]+") do
			count += 1
		end
		rewardList.Value = (count == 5) and data.rewards or generateRewardList(player)
	end
end)

validateDailyClaim.OnServerInvoke = function(player)
	local dataFolder = player:FindFirstChild("DailyPassData")
	if not dataFolder then return false end

	local claimed = getClaimedList(dataFolder.ClaimedDays.Value)
	if #claimed >= 5 then
		dataFolder.ClaimedDays.Value = ""
		dataFolder.CurrentCycle.Value = os.time()
		dataFolder.RewardList.Value = generateRewardList(player)
		claimed = {}
	end

	local nextDayToClaim
	for i = 1, 5 do
		if not table.find(claimed, i) then
			nextDayToClaim = i
			break
		end
	end
	if not nextDayToClaim then return false end

	local secondsInDay = 24 * 60 * 60
	local timeSinceLastClaim = os.time() - dataFolder.LastClaimTime.Value

	-- Only allow if it's the first claim or 24h has passed
	if (#claimed == 0 and nextDayToClaim == 1) or timeSinceLastClaim >= secondsInDay then
		dataFolder.ClaimedDays.Value = dataFolder.ClaimedDays.Value .. (#dataFolder.ClaimedDays.Value > 0 and "," or "") .. tostring(nextDayToClaim)
		dataFolder.LastClaimTime.Value = os.time()

		if #getClaimedList(dataFolder.ClaimedDays.Value) >= 5 then
			dataFolder.ClaimedDays.Value = ""
			dataFolder.CurrentCycle.Value = os.time()
			dataFolder.RewardList.Value = generateRewardList(player)
		end

		savePlayerData(player)
		return true
	end

	return false
end


skipClaim.OnServerInvoke = function(player)
	local dataFolder = player:FindFirstChild("DailyPassData")
	if not dataFolder then return false end

	local claimed = getClaimedList(dataFolder.ClaimedDays.Value)
	if #claimed >= 5 then
		dataFolder.ClaimedDays.Value = ""
		dataFolder.CurrentCycle.Value = os.time()
		dataFolder.RewardList.Value = generateRewardList(player)
		claimed = {}
	end

	local nextDayToSkip
	for i = 1, 5 do
		if not table.find(claimed, i) then
			nextDayToSkip = i
			break
		end
	end
	if not nextDayToSkip then return false end

	local rewards = {}
	for entry in string.gmatch(dataFolder.RewardList.Value, "[^|]+") do
		table.insert(rewards, entry)
	end
	local rewardStr = rewards[nextDayToSkip]

	dataFolder.ClaimedDays.Value = dataFolder.ClaimedDays.Value .. (#dataFolder.ClaimedDays.Value > 0 and "," or "") .. tostring(nextDayToSkip)
	dataFolder.LastClaimTime.Value = os.time()

	if #getClaimedList(dataFolder.ClaimedDays.Value) >= 5 then
		dataFolder.ClaimedDays.Value = ""
		dataFolder.CurrentCycle.Value = os.time()
		dataFolder.RewardList.Value = generateRewardList(player)
	end

	savePlayerData(player)
	return true, nextDayToSkip, rewardStr
end

game.Players.PlayerRemoving:Connect(savePlayerData)
game:BindToClose(function()
	for _, player in ipairs(game.Players:GetPlayers()) do
		savePlayerData(player)
	end
end)
