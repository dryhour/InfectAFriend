local rs = game:GetService('ReplicatedStorage')
rs.remotes.player_remotes.addShake.OnClientEvent:Connect(function(players, explosion)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")

	local localPlayer = Players.LocalPlayer
	local camera = workspace.CurrentCamera
	local shakeModule = require(rs.Shake)
	
	-- shakeModule.Shake(5, 0.1, 5)

	--[[for _, player in ipairs(players) do
		if player == localPlayer then
			local originalCFrame = camera.CFrame

			if not explosion then
				shakeModule.Shake(0.75, 0.1, 1)
			else
				for i = 0, 10 do
					task.wait(0.025)
					shakeModule.Shake(5, 0.1, 1)
				end
			end

			-- Tween camera back to original position
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local camPart = Instance.new("Part")
			camPart.Anchored = true
			camPart.CFrame = originalCFrame
			camPart.Transparency = 1
			camPart.CanCollide = false
			camPart.Parent = workspace

			local tween = TweenService:Create(camera, tweenInfo, {CFrame = camPart.CFrame})
			tween:Play()
			tween.Completed:Connect(function()
				camPart:Destroy()
			end)
		end
	end]]--

end)