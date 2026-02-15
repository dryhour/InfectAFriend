local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("PlayerMoved")

local lastPos = Vector3.zero
local lastCamRot = Vector3.zero

--[[while true do
	task.wait(1)

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera

	if hrp and camera and character:FindFirstChild('tag_values') then
		local currentPos = hrp.Position
		local currentCamRot = camera.CFrame.Rotation:ToEulerAnglesXYZ()

		-- Send position and camera orientation to server
		remote:FireServer(currentPos, Vector3.new(currentCamRot))
	end
end]]
