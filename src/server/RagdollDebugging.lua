local Players = game:GetService("Players")

-- Settings
local CHECK_INTERVAL = 5 -- seconds
local RAGDOLL_TIMEOUT = 7 -- seconds before forcing rejoin if stuck
local REQUIRED_PARTS = {
	"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", -- R6
	-- For R15 rigs, add:
	-- "UpperTorso", "LowerTorso", "LeftUpperArm", etc.
}

-- Utility: Check for missing parts
local function isCharacterBroken(character)
	for _, name in ipairs(REQUIRED_PARTS) do
		if not character:FindFirstChild(name) then
			return true
		end
	end
	return false
end

-- Utility: Check if still ragdolled
local function isRagdolled(humanoid)
	return humanoid.PlatformStand or humanoid:GetState() == Enum.HumanoidStateType.Physics
end

-- Track players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end

		local ragdollStart = nil

		-- Monitor ragdoll state
		coroutine.wrap(function()
			while false and character.Parent and humanoid.Health > 0 do
				local broken = isCharacterBroken(character)
				local ragdolling = isRagdolled(humanoid)

				if broken then
					warn(player.Name .. " kicked due to breaking: ragdoll issue.")
					player:Kick("Your character broke due to a ragdoll issue. Please rejoin.")
					break
				end

				if ragdolling then
					if not ragdollStart then
						ragdollStart = tick()
					elseif tick() - ragdollStart > RAGDOLL_TIMEOUT then
						warn(player.Name .. " kicked due to ragdoll issue.")
						player:Kick("You were stuck in ragdoll. Please rejoin.")
						break
					end
				else
					ragdollStart = nil -- reset timer if recovered
				end

				task.wait(CHECK_INTERVAL)
			end
		end)()
	end)
end)
