local rs = game:GetService('ReplicatedStorage')
local ss = game:GetService('SoundService')
local ui_sounds = ss:WaitForChild('ui_sounds')
local playSecCoin = rs.PlaySecCoin
playSecCoin.OnClientEvent:Connect(function()
	ui_sounds.pop:Play()
end)