local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")
local workspace = game.Workspace
local camera = workspace.CurrentCamera

-- Set the initial camera offset
humanoid.CameraOffset = Vector3.new(0, 0, -1)

-- Maintain transparency of body parts (except Head)
for _, v in pairs(char:GetChildren()) do
	if v:IsA("BasePart") and v.Name ~= "Head" then
		v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			v.LocalTransparencyModifier = 0.5
		end)
		v.LocalTransparencyModifier = 0.5
	end
end

-- Jump animation setup
local canJumpAnim = true
local jumAnim = Instance.new("Animation")
jumAnim.AnimationId = `rbxassetid://{script.jump.Value}`

local jumAnimTrack: AnimationTrack = humanoid:LoadAnimation(jumAnim)
jumAnimTrack.Priority = Enum.AnimationPriority.Action

humanoid.StateChanged:Connect(function(_, new)
	if new == Enum.HumanoidStateType.Jumping and canJumpAnim then
		jumAnimTrack:Play()
		task.wait(0.5)
		jumAnimTrack:Stop()
	end
end)

-- Reference to in-game value
local inGameValue = char:WaitForChild("main_values"):WaitForChild("INGAME")

-- Function to update the camera mode and zoom
local function updateCameraMode()
	--[[if inGameValue.Value == true then
		-- player.CameraMode = Enum.CameraMode.LockFirstPerson
		-- player.CameraMinZoomDistance = 0.5
		-- player.CameraMaxZoomDistance = 0.5
		-- humanoid.CameraOffset = Vector3.new(0, 0, -1)
		
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Head" then
				v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
					v.LocalTransparencyModifier = 0.5
				end)
				v.LocalTransparencyModifier = 0.5
			end
		end
	else
		player.CameraMode = Enum.CameraMode.Classic
		humanoid.CameraOffset = Vector3.new(0, 0, 0)

		-- Force zoom distance to 9
		player.CameraMinZoomDistance = 9
		player.CameraMaxZoomDistance = 9

		task.delay(0.1, function()
			-- Now allow zoom range again
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 15
		end)
	end]]
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "Head" then
			v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
				v.LocalTransparencyModifier = 0.5
			end)
			v.LocalTransparencyModifier = 0.5
		end
	end
	player.CameraMode = Enum.CameraMode.Classic
	

	-- Run this inside a loop or in RenderStepped:
	if (camera.CFrame.Position - camera.Focus.Position).Magnitude < 1 then
		-- Player is zoomed in all the way (first-person)
		humanoid.CameraOffset = Vector3.new(0, 0, -1)
	else
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end

	
	
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 15
end


-- Initial camera setup
updateCameraMode()

-- Listen for changes to INGAME
inGameValue:GetPropertyChangedSignal("Value"):Connect(updateCameraMode)

-- Update camera offset based on raycast
RunService.RenderStepped:Connect(function()
	-- if inGameValue.Value ~= true then return end

	local head = char:FindFirstChild("Head")
	if not head then return end

	local rayDirection = head.CFrame.LookVector * 2
	local ignoreList = {char}
	local ray = Ray.new(head.Position, rayDirection)

	local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
	
	if (camera.CFrame.Position - camera.Focus.Position).Magnitude < 1 then
		if hit then
			local distance = (head.Position - pos).magnitude
			humanoid.CameraOffset = Vector3.new(0, 0, -distance)
		else
			humanoid.CameraOffset = Vector3.new(0, 0, -1)
		end
	else
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end
end)
