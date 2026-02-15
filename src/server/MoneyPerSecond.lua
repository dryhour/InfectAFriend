local ReplicatedStorage = game:GetService("ReplicatedStorage")

local perSecondRemote = ReplicatedStorage:FindFirstChild("PerSecondRemote") or Instance.new("RemoteEvent")
perSecondRemote.Name = "PerSecondRemote"
perSecondRemote.Parent = ReplicatedStorage

perSecondRemote.OnServerEvent:Connect(function(player, statType, amount)
	local hiddenStats = player:FindFirstChild("hidden_leaderstats")
	if not hiddenStats then return end

	local perSecond = hiddenStats:FindFirstChild("PerSecond")
	if not perSecond then return end
	
	-- print(amount)
	local amount = tonumber(amount:match("%d+"))
	-- print(amount)

	if statType and amount then
		local stat = hiddenStats:FindFirstChild(statType)
		if stat then
			stat.Value = amount
		end
	end
end)