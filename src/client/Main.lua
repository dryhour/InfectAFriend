local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- // Player & Character
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")
local camera = workspace.CurrentCamera

-- // Animations
local runAnim = humanoid:LoadAnimation(script:WaitForChild("anims"):WaitForChild("run"))
runAnim.Priority = Enum.AnimationPriority.Movement
runAnim:AdjustWeight(0)

-- Add sliding flag to character
local slidingFlag = character:FindFirstChild("IsSliding") or Instance.new("BoolValue")
slidingFlag.Name = "IsSliding"
slidingFlag.Value = false
slidingFlag.Parent = character

local slideAnim = script:WaitForChild("slide_anim")
local slideTrack = humanoid:LoadAnimation(slideAnim)

-- // Run Settings
local maxSpeed = 45 -- *1.25
local minSpeed = 20
local boostedMaxSpeed = 80 -- *1.25

local taggerSpeedBoost = 1.5
local eventSpeedBoost = 1.5

local function isTagger()
	local tagger = character:FindFirstChild("tag_values") 
		and character.tag_values:FindFirstChild("tagger")
	return tagger and tagger.Value == true or false
end

local main_values = character:WaitForChild("main_values")
local ingame = main_values:WaitForChild("INGAME")

local function isInGame()
	return ingame.Value == true
end

local acceleration = 1
local currentSpeed = minSpeed

local weight = 0
local targetWeight = 0

-- // FOV Settings
local maxFOV = 90
local minFOV = 70

-- // Slide Settings
local sliding = false
local maxSlideTime = 2
local accelerationRate = 50
local slideForce = 60
local velocityObject
local slideConn
local shakeConn
local slideStartTime
local playing = false
local weightTween

-- // Camera Offsets
local originalLookVector = nil
local originalCameraOffset = nil
local slideCameraConn

-- // FOV Update
local function updateFOV(target)
	TweenService:Create(camera, TweenInfo.new(0.25), {FieldOfView = target}):Play()
end

-- // Smooth animation weight tweener
local function tweenRunAnimWeight(toWeight)
	if weightTween then weightTween:Cancel() end
	weightTween = TweenService:Create(runAnim, TweenInfo.new(0.25), {WeightCurrent = toWeight})
	weightTween:Play()
end

-- // Camera Shake
local function startShake()
	shakeConn = RunService.RenderStepped:Connect(function()
		if not sliding then return end
		local shakeOffset = Vector3.new(
			math.noise(tick() * 20, 0, 0),
			math.noise(0, tick() * 20, 0),
			0
		) * 0.2
		camera.CFrame = CFrame.new(head.Position + shakeOffset, head.Position + head.CFrame.LookVector)
	end)
end

local function stopShake()
	if shakeConn then shakeConn:Disconnect() end
end

-- // Slide Camera
local function startSlideCamera(slideDirection)
	if not originalCameraOffset then
		originalCameraOffset = head.CFrame:ToObjectSpace(camera.CFrame)
	end

	local maxTiltAngle = math.rad(10)
	local tiltAngle = math.clamp(-slideDirection.X * maxTiltAngle, -maxTiltAngle, maxTiltAngle)

	if slideCameraConn then slideCameraConn:Disconnect() end

	slideCameraConn = RunService.RenderStepped:Connect(function()
		if not sliding then return end
		local tiltCFrame = CFrame.Angles(0, 0, tiltAngle)
		camera.CFrame = head.CFrame * tiltCFrame * originalCameraOffset
	end)
end

local function stopSlideCamera()
	if slideCameraConn then slideCameraConn:Disconnect() end
	slideCameraConn = nil

	if originalCameraOffset then
		camera.CFrame = head.CFrame * originalCameraOffset
	end
end

-- // Cancel Slide
local function cancelSlide()
	if not sliding then return end
	sliding = false
	slidingFlag.Value = false
	if velocityObject then velocityObject:Destroy() end
	if slideTrack.IsPlaying then slideTrack:Stop(0.15) end
	if slideConn then slideConn:Disconnect() end
	stopShake()
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	humanoid.AutoRotate = true
	originalLookVector = nil
	hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
end

-- // Perform Slide
local function performSlide()
	if sliding or humanoid.MoveDirection.Magnitude == 0 then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	slidingFlag.Value = true

	local forward = hrp.CFrame.LookVector
	local moveDir = humanoid.MoveDirection.Unit
	local dot = forward:Dot(moveDir)
	if dot < 0.5 then return end

	sliding = true
	slideStartTime = tick()
	humanoid.AutoRotate = false
	slideTrack:Play()

	originalLookVector = forward

	startSlideCamera(moveDir)
	startShake()

	local currentVelocity = hrp.Velocity
	local currentSpeed = Vector3.new(currentVelocity.X, 0, currentVelocity.Z).Magnitude

	velocityObject = Instance.new("BodyVelocity")
	velocityObject.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocityObject.P = 1000
	velocityObject.Velocity = moveDir * currentSpeed
	velocityObject.Parent = hrp

	slideConn = RunService.Heartbeat:Connect(function(dt)
		if not sliding then return end

		currentSpeed = math.min(currentSpeed + accelerationRate * dt, slideForce)
		velocityObject.Velocity = moveDir * currentSpeed

		local rightVector = Vector3.new(originalLookVector.Z, 0, -originalLookVector.X)
		local leanAmount = math.clamp(moveDir:Dot(rightVector), -1, 1)
		local maxLeanAngle = math.rad(20)
		local leanAngle = leanAmount * maxLeanAngle

		local lookCFrame = CFrame.new(hrp.Position, hrp.Position + originalLookVector)
		local leanCFrame = lookCFrame * CFrame.Angles(0, 0, -leanAngle)
		hrp.CFrame = leanCFrame

		local targetFOV = math.clamp(minFOV + ((currentSpeed - minSpeed) / (maxSpeed - minSpeed)) * (maxFOV - minFOV) + 10, minFOV, maxFOV + 10)
		updateFOV(targetFOV)

		if tick() - slideStartTime > maxSlideTime then
			cancelSlide()
		end
	end)
end

-- // Input Handling

local disable_sliding = true

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if disable_sliding then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		performSlide()
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if disable_sliding then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		cancelSlide()
	end
end)

humanoid.StateChanged:Connect(function(_, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		cancelSlide()
	end
end)

-- // Run Logic
local event = game:GetService('ReplicatedStorage').Event
RunService.Heartbeat:Connect(function(dt)
	if sliding then return end

	if humanoid.FloorMaterial == Enum.Material.Air then
		cancelSlide()
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0
	local bf_effectiveMaxSpeed = isTagger() and maxSpeed * taggerSpeedBoost or maxSpeed

	local is_event = (isInGame() and event.Value == "Super Speed")
	if is_event then
		-- print("ISEVENT!!!")
	end
	local effectiveMaxSpeed = is_event and (bf_effectiveMaxSpeed * eventSpeedBoost) or bf_effectiveMaxSpeed
	effectiveMaxSpeed *= player:WaitForChild('stats').speed.Value

	acceleration = 1
	if moving and humanoid.WalkSpeed > 0 then
		acceleration *= player:WaitForChild('stats').acceleration.Value -- ex. 1 * 1.05
		currentSpeed = math.clamp(currentSpeed + acceleration, minSpeed, effectiveMaxSpeed)
		targetWeight = 1
	else
		currentSpeed = math.clamp(currentSpeed - acceleration * 2, minSpeed, effectiveMaxSpeed)
		targetWeight = 0
	end

	weight = weight + (targetWeight - weight) * math.clamp(dt * 10, 0, 1)
	runAnim:AdjustWeight(weight)

	if humanoid.WalkSpeed > 0 then
		humanoid.WalkSpeed = math.clamp(currentSpeed, minSpeed, effectiveMaxSpeed)
	end

	local targetFOV = minFOV + ((currentSpeed - minSpeed) / (maxSpeed - minSpeed)) * (maxFOV - minFOV)
	updateFOV(targetFOV)

	if moving and humanoid.WalkSpeed > 0 then
		if not playing then
			runAnim:Play()
			playing = true
		end
		runAnim:AdjustSpeed(currentSpeed / (45 / 1.2))
	else
		if playing and weight < 0.05 then
			runAnim:Stop(0.1)
			runAnim:AdjustSpeed(0)
			playing = false
		end
	end
end)

-- // SPEEDBOOST Listener
local mainValues = character:WaitForChild("main_values")
local speedBoostValue = mainValues:WaitForChild("SPEEDBOOST")

-- Default values
local baseMaxSpeed = maxSpeed -- ← Adjust this as you like

-- Function to update max speed
local function updateSpeedBoost()
	if speedBoostValue.Value == true then
		maxSpeed = boostedMaxSpeed
	else
		maxSpeed = baseMaxSpeed
	end
end

-- Initial check
updateSpeedBoost()

-- Listen for changes
speedBoostValue:GetPropertyChangedSignal("Value"):Connect(updateSpeedBoost)
