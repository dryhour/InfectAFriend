local rs = game:GetService('ReplicatedStorage')
local db = game:GetService('Debris')
local remotes = rs.remotes
rs.remotes.player_remotes.client_sound.OnClientEvent:Connect(function(plr, sound, part)
	if sound then
		if plr == game.Players.LocalPlayer then
			local new_sound = sound:Clone()
			new_sound.Parent = part
			new_sound:Play()

			db:AddItem(new_sound, 5)
		end
	else
		local new_sound = plr:Clone()
		new_sound.Parent = workspace
		new_sound:Play()

		db:AddItem(new_sound, 5)
	end
end)