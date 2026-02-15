local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local slidingFlag = character:WaitForChild("IsSliding")

-- Config
local forwardBoost = 50     -- how far forward the jump goes
local boostDuration = 0.1   -- how long the boost lasts (in seconds)

local function addForwardBoost()
	local isSliding = slidingFlag.Value
	local boostAmount = isSliding and (forwardBoost * 1.5) or forwardBoost
	
	boostAmount *= player:WaitForChild('stats').lunge.Value

	-- Check for obstacle in front using Raycast
	local rayOrigin = hrp.Position
	local rayDirection = humanoid.MoveDirection.Unit * (boostAmount * 0.2) -- ~10 studs ahead

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if result and result.Instance and not result.Instance:IsA("Terrain") then
		-- Wall or object detected; cancel boost
		return
	end

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(100000, 0, 100000)
	bv.Velocity = humanoid.MoveDirection * boostAmount
	bv.P = 1000
	bv.Parent = hrp

	game.Debris:AddItem(bv, boostDuration)
end


-- Trigger when player jumps
humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping
	and humanoid.MoveDirection.Magnitude > 0 then
		addForwardBoost()
	end
end)

-- Find the Animations folder inside character (or wherever it is)
local jumpAnimation = script:WaitForChild("jump")

-- Load the animation from the Animation object in the folder
local jumpAnimTrack = humanoid:LoadAnimation(jumpAnimation)

humanoid.Jumping:Connect(function(active)
	if active then
		jumpAnimTrack:Play()
	else
		jumpAnimTrack:Stop()
	end
end)

humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		jumpAnimTrack:Stop()
	end
end)
