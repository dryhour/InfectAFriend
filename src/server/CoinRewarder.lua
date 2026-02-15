local rs = game:GetService("ReplicatedStorage")
local remote = rs.RewardCoins

remote.OnServerEvent:Connect(function(player, amount)
	local leaderstats = player:FindFirstChild('leaderstats')
	if leaderstats then
		leaderstats.Coins.Value += amount
	end
end)