local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SocialService = game:GetService("SocialService")

local debounce = true

local touchPart = workspace:WaitForChild("OtherStuff"):WaitForChild("FriendInviter"):WaitForChild("Touch")

touchPart.Touched:Connect(function(hit)
	if not debounce then return end

	local character = player.Character or player.CharacterAdded:Wait()
	if hit:IsDescendantOf(character) then
		debounce = false

		local Invite = false
		pcall(function()
			Invite = SocialService:CanSendGameInviteAsync(player)
		end)
		if Invite then
			SocialService:PromptGameInvite(player)
		else
			script.OnErrorGui.Enabled = true
		end

		task.delay(2, function()
			debounce = true
		end)
	end
end)
