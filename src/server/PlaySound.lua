local rs = game:GetService('ReplicatedStorage')
local db = game:GetService('Debris')
local remotes = rs.remotes
local global_remotes = remotes.global_remotes

global_remotes.play_sound.OnServerEvent:Connect(function(plr, sound, part)
	local new_sound = sound:Clone()
	new_sound.Parent = part
	new_sound:Play()
	
	db:AddItem(new_sound, 5)
end)