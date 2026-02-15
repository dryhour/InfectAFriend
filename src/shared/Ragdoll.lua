local module = {}
local event = game:GetService('ReplicatedStorage').Event

module.Ragdoll = function(character, stunamount, oldtagger)
	local function RagdollCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		
		print("ragdolled in module")

		-- Prevent accidental death and physics glitches
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.Health = math.max(humanoid.Health, 1)

		-- Remove death sound if present
		for _, obj in character:GetDescendants() do
			if obj:IsA("Sound") and obj.Name == "Died" then
				obj:Destroy()
			end
		end

		-- Clean existing ragdoll parts
		for _, obj in character:GetDescendants() do
			if obj:IsA("BallSocketConstraint") or obj:IsA("Attachment") then
				obj:Destroy()
			end
		end

		-- Replace joints with physics constraints
		for _, joint in character:GetDescendants() do
			if joint:IsA("Motor6D") then
				local part0 = joint.Part0
				local part1 = joint.Part1
				if not part0 or not part1 then continue end

				local a0 = Instance.new("Attachment")
				local a1 = Instance.new("Attachment")
				a0.CFrame = joint.C0
				a1.CFrame = joint.C1
				a0.Parent = part0
				a1.Parent = part1

				local socket = Instance.new("BallSocketConstraint")
				socket.Attachment0 = a0
				socket.Attachment1 = a1
				socket.LimitsEnabled = true
				socket.TwistLimitsEnabled = true
				socket.Parent = joint.Parent

				joint.Enabled = false
			end
		end

		-- Make limbs collide for realism
		task.defer(function()
			for _, part in character:GetChildren() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end)
	end

	local function UnragdollCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50 * game.Players:GetPlayerFromCharacter(character):WaitForChild('stats').jump.Value
			if event.Value == "Low Gravity" then
				humanoid.JumpPower = 50 * game.Players:GetPlayerFromCharacter(character):WaitForChild('stats').jump.Value
			end
			humanoid.AutoRotate = true
		end

		-- Turn off collisions again
		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and part.Name ~= "Head" and part.Name ~= "Torso" then
				part.CanCollide = false
			end
		end

		-- Restore joints and remove ragdoll constraints
		for _, obj in character:GetDescendants() do
			if obj:IsA("BallSocketConstraint") or obj:IsA("Attachment") then
				obj:Destroy()
			elseif obj:IsA("Motor6D") then
				obj.Enabled = true
			end
		end
	end
	
	local function launch(char, enemyHumRoot)
		local bv = Instance.new("BodyVelocity")
		local amount = 8
		if char then
			bv.Velocity = char.HumanoidRootPart.CFrame.LookVector * amount + Vector3.new(0, amount, 0)
		else
			bv.Velocity = Vector3.new(0,5,0)
		end
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Parent = enemyHumRoot

		local bav = Instance.new("BodyAngularVelocity")
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = true
			humanoid.AutoRotate = false
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
		
		local num = 5

		-- Random spin in any direction
		local randomSpin = Vector3.new(
			math.random(-num, num),  -- Random X rotation
			math.random(-num, num),  -- Random Y rotation
			math.random(-num, num)   -- Random Z rotation
		) * math.rad(100) -- Scale rotation to make it more noticeable

		bav.AngularVelocity = randomSpin
		bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		bav.Parent = enemyHumRoot

		game.Debris:AddItem(bv, 0.25)
		game.Debris:AddItem(bav, 0.25)
		
	end
	

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local tagValues = character and character:FindFirstChild("tag_values")
	local stunned = tagValues and tagValues:FindFirstChild("stunned")

	-- 
	if humanoid and stunned then -- and #stunned:GetChildren() == 0 then
		print(oldtagger)
		launch(oldtagger, character.HumanoidRootPart)
		
		local amount = stunamount~=nil and stunamount+1 or 6
		task.delay(amount, function()
			if #stunned:GetChildren() == 0 then
				humanoid.PlatformStand = false
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50 * game.Players:GetPlayerFromCharacter(character):WaitForChild('stats').jump.Value
				if event.Value == "Low Gravity" then
					humanoid.JumpPower = 50 * game.Players:GetPlayerFromCharacter(character):WaitForChild('stats').jump.Value
				end
				humanoid.AutoRotate = true
			end
		end)
		--[[RagdollCharacter(character)
		task.wait(stunamount or 2)
		UnragdollCharacter(character)]]
	end
end

return module
