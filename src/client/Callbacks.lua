local StarterGui = game:GetService("StarterGui")

-- Repeat until it succeeds
task.spawn(function()
	while true do
		local success, err = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if success then break end
		task.wait(0.5)
	end
end)

--[[task.delay(5, function()
	pcall(function()
		game:GetService("AvatarEditorService"):PromptSetFavorite(109061728776302, Enum.AvatarItemType.Asset, true)
	end)
end)]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

local random = math.random(1, 2)

if random == 1 then
	--[[task.delay(7, function()
		-- Function to check whether the player can be prompted to enable notifications
		local function canPromptOptIn()
			local success, result = pcall(function()
				return ExperienceNotificationService:CanPromptOptInAsync()
			end)
			return success and result
		end

		if canPromptOptIn() then
			pcall(function()
				ExperienceNotificationService:PromptOptIn()
			end)

			-- Listen to opt-in prompt closed event
			ExperienceNotificationService.OptInPromptClosed:Connect(function()
				print("Opt-in prompt closed")
			end)
		end
	end)]]
else

	--[[local starterpack_id = 1268302427

	task.delay(7, function()
		print(3)
		local player = Players.LocalPlayer

		if player then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, starterpack_id)
			end)

			if success and not owns then
				pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, starterpack_id)
				end)
			end
		end
	end)]]

end


--[[
task.delay(35, function()
	local Player = game.Players.LocalPlayer
	local SocialService = game:GetService("SocialService")
	local Invite = false
	pcall(function()
		Invite = SocialService:CanSendGameInviteAsync(Player)
	end)
	if Invite then
		SocialService:PromptGameInvite(Player)
	else
		script.OnErrorGui.Enabled = true
	end
end)
]]--